//! PDF 转 Markdown 转换器
//!
//! 基于 pdfium-render 实现，支持:
//! - 文本提取
//! - 字体大小分析（自动识别标题）
//! - 粗体/斜体检测
//! - 文本位置排序

use std::path::Path;
use pdfium_render::prelude::*;

use super::ToMarkdown;
use crate::error::{ConvertError, Result};

/// PDF 转换器配置
#[derive(Debug, Clone)]
pub struct PdfConfig {
    /// PDFium 库路径（None 则使用默认路径）
    pub library_path: Option<String>,
    /// 是否检测标题
    pub detect_headings: bool,
    /// 是否保留格式（粗体/斜体）
    pub preserve_formatting: bool,
    /// 图像输出目录（None 则不提取图像）
    pub image_output_dir: Option<String>,
}

impl Default for PdfConfig {
    fn default() -> Self {
        Self {
            library_path: Some("./dylib/".to_string()),
            detect_headings: true,
            preserve_formatting: true,
            image_output_dir: None,
        }
    }
}

/// PDF 转换器
pub struct PdfConverter;

impl ToMarkdown for PdfConverter {
    fn to_markdown<P: AsRef<Path>>(path: P) -> Result<String> {
        Self::convert_with_config(path, &PdfConfig::default())
    }
}

impl PdfConverter {
    /// 使用自定义配置转换
    pub fn convert_with_config<P: AsRef<Path>>(path: P, config: &PdfConfig) -> Result<String> {
        let path = path.as_ref();
        let pdfium = Self::bind_pdfium(config)?;
        
        let document = pdfium
            .load_pdf_from_file(path, None)
            .map_err(|e| ConvertError::PdfError(format!("加载 PDF 失败: {}", e)))?;

        let mut all_segments: Vec<TextSegment> = Vec::new();
        let mut all_images: Vec<ImageInfo> = Vec::new();

        for (page_idx, page) in document.pages().iter().enumerate() {
            let segments = extract_page_segments(&page, page_idx)?;
            all_segments.extend(segments);
            
            // 提取图像
            if config.image_output_dir.is_some() {
                let images = extract_page_images(&page, page_idx, config)?;
                all_images.extend(images);
            }
        }

        if all_segments.is_empty() && all_images.is_empty() {
            return Ok(String::new());
        }

        // 按行分组（用于表格检测）
        let lines = group_segments_by_line(&all_segments);
        
        // 检测可能的表格区域
        let table_regions = detect_table_regions(&lines);

        // 合并同行文本
        let merged_segments = merge_line_segments(&all_segments);

        let font_stats = if config.detect_headings {
            analyze_font_sizes(&merged_segments)
        } else {
            FontStats::disabled()
        };

        let markdown = segments_to_markdown_with_images(
            &merged_segments, 
            &font_stats, 
            config.preserve_formatting,
            &table_regions,
            &all_images
        );
        Ok(markdown)
    }

    fn bind_pdfium(config: &PdfConfig) -> Result<Pdfium> {
        let bindings = if let Some(ref lib_path) = config.library_path {
            Pdfium::bind_to_library(Pdfium::pdfium_platform_library_name_at_path(lib_path))
                .or_else(|_| Pdfium::bind_to_system_library())
        } else {
            Pdfium::bind_to_system_library()
        };

        bindings
            .map(Pdfium::new)
            .map_err(|e| ConvertError::PdfError(format!(
                "无法加载 PDFium 库: {}。请确保 PDFium 已安装或指定正确的库路径。", e
            )))
    }
}

/// 文本片段
#[derive(Debug, Clone)]
pub struct TextSegment {
    pub text: String,
    pub font_size: f32,
    pub is_bold: bool,
    pub is_italic: bool,
    pub x: f32,
    pub y: f32,
    pub page_index: usize,
}

/// 图像信息
#[derive(Debug, Clone)]
pub struct ImageInfo {
    pub path: String,      // 保存的文件路径
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub page_index: usize,
}

/// 从页面提取文本片段
fn extract_page_segments(page: &PdfPage, page_index: usize) -> Result<Vec<TextSegment>> {
    let mut segments: Vec<TextSegment> = Vec::new();

    for object in page.objects().iter() {
        if let Some(text_object) = object.as_text_object() {
            let text = text_object.text();
            if text.trim().is_empty() {
                continue;
            }

            let font_size = text_object.unscaled_font_size().value;
            let font = text_object.font();
            let font_name = font.name().to_lowercase();

            let is_bold = font_name.contains("bold")
                || font_name.contains("black")
                || font_name.contains("heavy")
                || font.weight().map_or(false, |w| {
                    matches!(w, PdfFontWeight::Weight700Bold | PdfFontWeight::Custom(_))
                });

            let is_italic = font_name.contains("italic") || font_name.contains("oblique");

            let bounds = text_object
                .bounds()
                .map_err(|e| ConvertError::PdfError(format!("获取文本边界失败: {}", e)))?;

            segments.push(TextSegment {
                text: text.to_string(),
                font_size,
                is_bold,
                is_italic,
                x: bounds.left().value,
                y: bounds.top().value,
                page_index,
            });
        }
    }

    // 按位置排序（从上到下，从左到右）
    segments.sort_by(|a, b| {
        let y_cmp = b.y.partial_cmp(&a.y).unwrap_or(std::cmp::Ordering::Equal);
        if y_cmp != std::cmp::Ordering::Equal {
            return y_cmp;
        }
        a.x.partial_cmp(&b.x).unwrap_or(std::cmp::Ordering::Equal)
    });

    Ok(segments)
}

/// 从页面提取图像
fn extract_page_images(page: &PdfPage, page_index: usize, config: &PdfConfig) -> Result<Vec<ImageInfo>> {
    let mut images: Vec<ImageInfo> = Vec::new();
    
    let output_dir = match &config.image_output_dir {
        Some(dir) => dir,
        None => return Ok(images),
    };
    
    // 确保输出目录存在
    std::fs::create_dir_all(output_dir)
        .map_err(|e| ConvertError::IoError(e))?;
    
    let mut image_index = 0;
    
    for object in page.objects().iter() {
        if let Some(image_object) = object.as_image_object() {
            // 获取图像边界
            let bounds = match image_object.bounds() {
                Ok(b) => b,
                Err(_) => continue,
            };
            
            // 获取图像数据
            let image = match image_object.get_raw_image() {
                Ok(img) => img,
                Err(_) => continue,
            };
            
            // 生成文件名
            let filename = format!("page{}_img{}.png", page_index + 1, image_index);
            let filepath = Path::new(output_dir).join(&filename);
            
            // 保存图像
            if let Err(e) = image.save(&filepath) {
                eprintln!("保存图像失败: {}", e);
                continue;
            }
            
            // 获取绝对路径
            let abs_path = match filepath.canonicalize() {
                Ok(p) => p.to_string_lossy().to_string(),
                Err(_) => filepath.to_string_lossy().to_string(),
            };
            
            images.push(ImageInfo {
                path: abs_path,
                x: bounds.left().value,
                y: bounds.top().value,
                width: bounds.width().value,
                height: bounds.height().value,
                page_index,
            });
            
            image_index += 1;
        }
    }
    
    // 按位置排序
    images.sort_by(|a, b| {
        let y_cmp = b.y.partial_cmp(&a.y).unwrap_or(std::cmp::Ordering::Equal);
        if y_cmp != std::cmp::Ordering::Equal {
            return y_cmp;
        }
        a.x.partial_cmp(&b.x).unwrap_or(std::cmp::Ordering::Equal)
    });
    
    Ok(images)
}

/// 合并同一行的文本片段
fn merge_line_segments(segments: &[TextSegment]) -> Vec<TextSegment> {
    if segments.is_empty() {
        return Vec::new();
    }

    let mut result: Vec<TextSegment> = Vec::new();
    let mut current_line: Vec<&TextSegment> = Vec::new();
    let mut current_y: Option<f32> = None;
    let mut current_page: Option<usize> = None;

    for seg in segments {
        let is_same_line = match (current_y, current_page) {
            (Some(y), Some(page)) => {
                seg.page_index == page && (seg.y - y).abs() < seg.font_size * 0.5
            }
            _ => false,
        };

        if is_same_line {
            current_line.push(seg);
        } else {
            // 处理上一行
            if !current_line.is_empty() {
                result.extend(merge_single_line(&current_line));
            }
            current_line = vec![seg];
            current_y = Some(seg.y);
            current_page = Some(seg.page_index);
        }
    }

    // 处理最后一行
    if !current_line.is_empty() {
        result.extend(merge_single_line(&current_line));
    }

    result
}

/// 合并单行内的文本片段（按格式分组）
fn merge_single_line(line: &[&TextSegment]) -> Vec<TextSegment> {
    if line.is_empty() {
        return Vec::new();
    }

    // 按 x 坐标排序
    let mut sorted: Vec<&TextSegment> = line.to_vec();
    sorted.sort_by(|a, b| a.x.partial_cmp(&b.x).unwrap_or(std::cmp::Ordering::Equal));

    let mut result: Vec<TextSegment> = Vec::new();
    let mut current: Option<TextSegment> = None;
    let mut last_x_end: f32 = 0.0;

    for seg in sorted {
        // 估算上一个片段的结束位置（粗略估计：x + 字符数 * 字体大小 * 0.5）
        let gap = seg.x - last_x_end;
        let has_gap = gap > seg.font_size * 0.3; // 有明显间隔
        
        match &mut current {
            Some(curr) if curr.is_bold == seg.is_bold 
                && curr.is_italic == seg.is_italic 
                && (curr.font_size - seg.font_size).abs() < 1.0 => {
                // 同格式，合并文本（有间隔时加空格）
                if has_gap && !curr.text.ends_with(' ') && !seg.text.starts_with(' ') {
                    curr.text.push(' ');
                }
                curr.text.push_str(&seg.text);
            }
            Some(curr) => {
                // 格式不同，保存当前并开始新的
                result.push(curr.clone());
                current = Some(seg.clone());
            }
            None => {
                current = Some(seg.clone());
            }
        }
        
        // 更新结束位置估计
        last_x_end = seg.x + (seg.text.chars().count() as f32) * seg.font_size * 0.5;
    }

    if let Some(curr) = current {
        result.push(curr);
    }

    result
}

/// 表格区域（y 坐标范围）
#[derive(Debug, Clone)]
struct TableRegion {
    page_index: usize,
    y_start: f32,
    y_end: f32,
}

/// 按行分组文本片段
fn group_segments_by_line(segments: &[TextSegment]) -> Vec<Vec<&TextSegment>> {
    if segments.is_empty() {
        return Vec::new();
    }

    let mut lines: Vec<Vec<&TextSegment>> = Vec::new();
    let mut current_line: Vec<&TextSegment> = Vec::new();
    let mut current_y: Option<f32> = None;
    let mut current_page: Option<usize> = None;

    for seg in segments {
        let is_same_line = match (current_y, current_page) {
            (Some(y), Some(page)) => {
                seg.page_index == page && (seg.y - y).abs() < seg.font_size * 0.5
            }
            _ => false,
        };

        if is_same_line {
            current_line.push(seg);
        } else {
            if !current_line.is_empty() {
                lines.push(current_line);
            }
            current_line = vec![seg];
            current_y = Some(seg.y);
            current_page = Some(seg.page_index);
        }
    }

    if !current_line.is_empty() {
        lines.push(current_line);
    }

    lines
}

/// 检测可能的表格区域
fn detect_table_regions(lines: &[Vec<&TextSegment>]) -> Vec<TableRegion> {
    let mut regions: Vec<TableRegion> = Vec::new();
    
    if lines.len() < 3 {
        return regions;
    }

    let mut i = 0;
    while i < lines.len() {
        // 检查连续几行是否像表格
        let mut table_lines = 0;
        let mut j = i;
        let mut col_counts: Vec<usize> = Vec::new();
        
        while j < lines.len() {
            let line = &lines[j];
            
            // 表格行特征：
            // 1. 同一行有 3 个以上独立的文本片段
            // 2. x 坐标分布较均匀（跨度大）
            if line.len() >= 3 {
                let x_positions: Vec<f32> = line.iter().map(|s| s.x).collect();
                let x_spread = x_positions.iter().cloned().fold(f32::NEG_INFINITY, f32::max)
                    - x_positions.iter().cloned().fold(f32::INFINITY, f32::min);
                
                // x 坐标跨度较大，且列数相近
                if x_spread > 150.0 {
                    col_counts.push(line.len());
                    table_lines += 1;
                    j += 1;
                    continue;
                }
            }
            break;
        }
        
        // 连续 3 行以上像表格，且列数相近，才标记为表格区域
        let is_table = table_lines >= 3 && {
            if col_counts.is_empty() {
                false
            } else {
                // 检查列数是否相近（差异不超过 1）
                let max_cols = *col_counts.iter().max().unwrap_or(&0);
                let min_cols = *col_counts.iter().min().unwrap_or(&0);
                max_cols - min_cols <= 1
            }
        };
        
        if is_table {
            let start_line = &lines[i];
            let end_line = &lines[j - 1];
            
            if let (Some(first), Some(last)) = (start_line.first(), end_line.first()) {
                regions.push(TableRegion {
                    page_index: first.page_index,
                    y_start: first.y + first.font_size,
                    y_end: last.y - last.font_size,
                });
            }
            i = j;
        } else {
            i += 1;
        }
    }
    
    regions
}

/// 检查 y 坐标是否在表格区域内
fn is_in_table_region(seg: &TextSegment, regions: &[TableRegion]) -> bool {
    for region in regions {
        if seg.page_index == region.page_index 
            && seg.y <= region.y_start 
            && seg.y >= region.y_end {
            return true;
        }
    }
    false
}

/// 检查是否是表格区域的开始
fn is_table_region_start(seg: &TextSegment, regions: &[TableRegion]) -> bool {
    for region in regions {
        if seg.page_index == region.page_index 
            && (seg.y - region.y_start).abs() < seg.font_size {
            return true;
        }
    }
    false
}

/// 检查是否是表格区域的结束
fn is_table_region_end(seg: &TextSegment, regions: &[TableRegion]) -> bool {
    for region in regions {
        if seg.page_index == region.page_index 
            && (seg.y - region.y_end).abs() < seg.font_size {
            return true;
        }
    }
    false
}

/// 字体大小统计
#[derive(Debug)]
pub struct FontStats {
    pub body_size: f32,
    pub h1_threshold: f32,
    pub h2_threshold: f32,
    pub h3_threshold: f32,
    pub enabled: bool,
}

impl FontStats {
    fn disabled() -> Self {
        Self {
            body_size: 12.0,
            h1_threshold: f32::MAX,
            h2_threshold: f32::MAX,
            h3_threshold: f32::MAX,
            enabled: false,
        }
    }
}

/// 分析字体大小分布
fn analyze_font_sizes(segments: &[TextSegment]) -> FontStats {
    if segments.is_empty() {
        return FontStats {
            body_size: 12.0,
            h1_threshold: 20.0,
            h2_threshold: 16.0,
            h3_threshold: 14.0,
            enabled: true,
        };
    }

    let mut size_counts: std::collections::HashMap<i32, usize> = std::collections::HashMap::new();
    for seg in segments {
        let size_key = (seg.font_size * 10.0) as i32;
        *size_counts.entry(size_key).or_insert(0) += seg.text.len();
    }

    let body_size_key = size_counts
        .iter()
        .max_by_key(|(_, count)| *count)
        .map(|(size, _)| *size)
        .unwrap_or(120);
    let body_size = body_size_key as f32 / 10.0;

    FontStats {
        body_size,
        h1_threshold: body_size * 1.8,
        h2_threshold: body_size * 1.4,
        h3_threshold: body_size * 1.2,
        enabled: true,
    }
}

/// 将文本片段转换为 Markdown（带表格检测）
#[allow(dead_code)]
fn segments_to_markdown_with_tables(
    segments: &[TextSegment], 
    stats: &FontStats, 
    preserve_formatting: bool,
    table_regions: &[TableRegion]
) -> String {
    let mut result = String::new();
    let mut last_y: Option<f32> = None;
    let mut last_page: Option<usize> = None;
    let mut in_table = false;
    
    // 计算基准 x 坐标（最常见的左边距）
    let base_x = calculate_base_x(segments);

    for seg in segments {
        let text = seg.text.trim();
        if text.is_empty() {
            continue;
        }

        // 页面分隔
        if let Some(lp) = last_page {
            if seg.page_index != lp {
                if in_table {
                    result.push_str("\n<!-- 表格结束 -->\n");
                    in_table = false;
                }
                result.push_str("\n\n---\n\n");
                last_y = None;
            }
        }
        
        // 检测表格区域
        let is_in_table = is_in_table_region(seg, table_regions);
        let is_table_start = is_table_region_start(seg, table_regions);
        let is_table_end = is_table_region_end(seg, table_regions);
        
        // 表格开始标记
        if is_table_start && !in_table {
            if !result.ends_with("\n\n") && !result.is_empty() {
                result.push_str("\n\n");
            }
            result.push_str("<!-- 以下可能是表格内容，请根据需要调整格式 -->\n\n");
            in_table = true;
        }

        // 检测换行
        if let Some(ly) = last_y {
            let y_diff = (ly - seg.y).abs();
            if y_diff > seg.font_size * 1.5 {
                if !result.ends_with("\n\n") {
                    result.push_str("\n\n");
                }
            } else if y_diff > seg.font_size * 0.5 && !result.ends_with('\n') && !result.ends_with(' ') {
                result.push(' ');
            }
        }

        let heading_level = if stats.enabled && !is_in_table {
            determine_heading_level(seg, stats)
        } else {
            0
        };
        
        // 检测是否是列表项（表格内不检测列表）
        let is_list_item = !is_in_table && is_list_item_segment(seg, base_x);
        
        // 检测是否只有标点符号（应该追加到上一行）
        let is_punctuation_only = is_punctuation_only_text(text);

        let formatted = format_text(text, seg.is_bold, seg.is_italic, heading_level, preserve_formatting);

        if is_punctuation_only {
            // 纯标点追加到上一行末尾
            let trailing_newlines = result.chars().rev().take_while(|c| *c == '\n').count();
            for _ in 0..trailing_newlines {
                result.pop();
            }
            result.push_str(&formatted);
            for _ in 0..trailing_newlines {
                result.push('\n');
            }
        } else if heading_level > 0 {
            if !result.ends_with("\n\n") && !result.is_empty() {
                result.push_str("\n\n");
            }
            result.push_str(&formatted);
            result.push_str("\n\n");
        } else if is_list_item {
            // 列表项：确保前面有换行，添加 "- " 前缀
            if !result.ends_with('\n') {
                result.push('\n');
            }
            result.push_str("- ");
            result.push_str(&formatted);
            result.push('\n');
        } else if is_in_table {
            // 表格内容：用 | 分隔
            result.push_str(&formatted);
            result.push_str(" | ");
        } else {
            result.push_str(&formatted);
        }
        
        // 表格结束标记
        if is_table_end && in_table {
            if !result.ends_with('\n') {
                result.push('\n');
            }
            result.push_str("\n<!-- 表格结束 -->\n");
            in_table = false;
        }

        last_y = Some(seg.y);
        last_page = Some(seg.page_index);
    }
    
    // 如果还在表格中，添加结束标记
    if in_table {
        if !result.ends_with('\n') {
            result.push('\n');
        }
        result.push_str("\n<!-- 表格结束 -->\n");
    }

    clean_markdown(&result)
}

/// 将文本片段转换为 Markdown（带表格和图像）
fn segments_to_markdown_with_images(
    segments: &[TextSegment], 
    stats: &FontStats, 
    preserve_formatting: bool,
    table_regions: &[TableRegion],
    images: &[ImageInfo]
) -> String {
    let mut result = String::new();
    let mut last_y: Option<f32> = None;
    let mut last_page: Option<usize> = None;
    let mut in_table = false;
    let mut inserted_images: std::collections::HashSet<usize> = std::collections::HashSet::new();
    
    // 计算基准 x 坐标
    let base_x = calculate_base_x(segments);

    for seg in segments {
        let text = seg.text.trim();
        if text.is_empty() {
            continue;
        }

        // 在当前位置之前插入图像
        for (idx, img) in images.iter().enumerate() {
            if !inserted_images.contains(&idx) 
                && img.page_index == seg.page_index 
                && img.y >= seg.y {
                // 插入图像
                if !result.ends_with("\n\n") && !result.is_empty() {
                    result.push_str("\n\n");
                }
                result.push_str(&format!("![图像]({})\n\n", img.path));
                inserted_images.insert(idx);
            }
        }

        // 页面分隔
        if let Some(lp) = last_page {
            if seg.page_index != lp {
                if in_table {
                    result.push_str("\n<!-- 表格结束 -->\n");
                    in_table = false;
                }
                result.push_str("\n\n---\n\n");
                last_y = None;
            }
        }
        
        // 检测表格区域
        let is_in_table = is_in_table_region(seg, table_regions);
        let is_table_start = is_table_region_start(seg, table_regions);
        let is_table_end = is_table_region_end(seg, table_regions);
        
        // 表格开始标记
        if is_table_start && !in_table {
            if !result.ends_with("\n\n") && !result.is_empty() {
                result.push_str("\n\n");
            }
            result.push_str("<!-- 以下可能是表格内容，请根据需要调整格式 -->\n\n");
            in_table = true;
        }

        // 检测换行
        if let Some(ly) = last_y {
            let y_diff = (ly - seg.y).abs();
            if y_diff > seg.font_size * 1.5 {
                if !result.ends_with("\n\n") {
                    result.push_str("\n\n");
                }
            } else if y_diff > seg.font_size * 0.5 && !result.ends_with('\n') && !result.ends_with(' ') {
                result.push(' ');
            }
        }

        let heading_level = if stats.enabled && !is_in_table {
            determine_heading_level(seg, stats)
        } else {
            0
        };
        
        let is_list_item = !is_in_table && is_list_item_segment(seg, base_x);
        let is_punctuation_only = is_punctuation_only_text(text);

        let formatted = format_text(text, seg.is_bold, seg.is_italic, heading_level, preserve_formatting);

        if is_punctuation_only {
            let trailing_newlines = result.chars().rev().take_while(|c| *c == '\n').count();
            for _ in 0..trailing_newlines {
                result.pop();
            }
            result.push_str(&formatted);
            for _ in 0..trailing_newlines {
                result.push('\n');
            }
        } else if heading_level > 0 {
            if !result.ends_with("\n\n") && !result.is_empty() {
                result.push_str("\n\n");
            }
            result.push_str(&formatted);
            result.push_str("\n\n");
        } else if is_list_item {
            if !result.ends_with('\n') {
                result.push('\n');
            }
            result.push_str("- ");
            result.push_str(&formatted);
            result.push('\n');
        } else if is_in_table {
            result.push_str(&formatted);
            result.push_str(" | ");
        } else {
            result.push_str(&formatted);
        }
        
        if is_table_end && in_table {
            if !result.ends_with('\n') {
                result.push('\n');
            }
            result.push_str("\n<!-- 表格结束 -->\n");
            in_table = false;
        }

        last_y = Some(seg.y);
        last_page = Some(seg.page_index);
    }
    
    // 插入剩余的图像
    for (idx, img) in images.iter().enumerate() {
        if !inserted_images.contains(&idx) {
            if !result.ends_with("\n\n") && !result.is_empty() {
                result.push_str("\n\n");
            }
            result.push_str(&format!("![图像]({})\n\n", img.path));
        }
    }
    
    if in_table {
        if !result.ends_with('\n') {
            result.push('\n');
        }
        result.push_str("\n<!-- 表格结束 -->\n");
    }

    clean_markdown(&result)
}

/// 将文本片段转换为 Markdown（旧版本，保留兼容）
#[allow(dead_code)]
fn segments_to_markdown(segments: &[TextSegment], stats: &FontStats, preserve_formatting: bool) -> String {
    segments_to_markdown_with_images(segments, stats, preserve_formatting, &[], &[])
}

/// 检测文本是否只有标点符号
fn is_punctuation_only_text(text: &str) -> bool {
    if text.is_empty() {
        return true;
    }
    text.chars().all(|c| {
        c.is_whitespace() || 
        c.is_ascii_punctuation() || 
        matches!(c, '、' | '，' | '。' | '；' | '：' | '（' | '）' | '【' | '】') ||
        // 中文引号
        c == '"' || c == '"'
    })
}

/// 计算基准 x 坐标（页面左边距）
fn calculate_base_x(segments: &[TextSegment]) -> f32 {
    if segments.is_empty() {
        return 0.0;
    }
    
    // 统计 x 坐标出现频率（四舍五入到整数）
    let mut x_counts: std::collections::HashMap<i32, usize> = std::collections::HashMap::new();
    for seg in segments {
        let x_key = seg.x as i32;
        *x_counts.entry(x_key).or_insert(0) += 1;
    }
    
    // 找出最小的常见 x 坐标作为基准
    let min_common_x = x_counts.iter()
        .filter(|(_, count)| **count >= 2)  // 至少出现2次
        .map(|(x, _)| *x)
        .min()
        .unwrap_or(0);
    
    min_common_x as f32
}

/// 检测是否是列表项
fn is_list_item_segment(seg: &TextSegment, base_x: f32) -> bool {
    let text = seg.text.trim();
    if text.is_empty() {
        return false;
    }
    
    // 检查是否有缩进
    let has_indent = seg.x > base_x + 10.0;
    
    // 检查是否以列表标记开头
    let first_char = text.chars().next().unwrap();
    
    // 1. emoji 开头
    let starts_with_emoji = is_emoji(first_char);
    
    // 2. 常见列表符号开头
    let starts_with_bullet = matches!(first_char, '•' | '·' | '-' | '◦' | '▪' | '►' | '▸' | '○' | '●' | '◆' | '◇' | '★' | '☆');
    
    // 3. 数字序号开头（如 "1." "2)" "(1)" "①"）
    let starts_with_number = is_numbered_list_start(text);
    
    // 4. 字母序号开头（如 "a." "A)" "(a)"）
    let starts_with_letter = is_lettered_list_start(text);
    
    // 判断逻辑：
    // - 有缩进 + 任意标记 = 列表项
    // - 无缩进但有明确的序号标记（数字/字母 + 分隔符）= 列表项
    if has_indent && (starts_with_emoji || starts_with_bullet || starts_with_number || starts_with_letter) {
        return true;
    }
    
    // 无缩进但有明确序号
    if starts_with_number || starts_with_letter {
        return true;
    }
    
    // 无缩进但以 bullet 符号开头（且不是普通文本中的符号）
    if starts_with_bullet && text.len() > 2 {
        // 检查符号后面是否有空格
        let second_char = text.chars().nth(1);
        if second_char == Some(' ') || second_char == Some('\t') {
            return true;
        }
    }
    
    false
}

/// 检测是否是数字序号开头
fn is_numbered_list_start(text: &str) -> bool {
    let text = text.trim();
    
    // 圆圈数字 ①②③...
    if let Some(first) = text.chars().next() {
        if matches!(first, '①'..='⑳' | '⑴'..='⒇' | '㈠'..='㈩') {
            return true;
        }
    }
    
    // 数字 + 分隔符（1. 2) (3) 1、）
    let patterns = [
        // "1." "12." 
        |s: &str| {
            let parts: Vec<&str> = s.splitn(2, '.').collect();
            parts.len() == 2 && parts[0].chars().all(|c| c.is_ascii_digit()) && !parts[0].is_empty()
        },
        // "1)" "12)"
        |s: &str| {
            let parts: Vec<&str> = s.splitn(2, ')').collect();
            parts.len() == 2 && parts[0].chars().all(|c| c.is_ascii_digit()) && !parts[0].is_empty()
        },
        // "(1)" "(12)"
        |s: &str| {
            s.starts_with('(') && {
                let rest = &s[1..];
                if let Some(end) = rest.find(')') {
                    rest[..end].chars().all(|c| c.is_ascii_digit()) && end > 0
                } else {
                    false
                }
            }
        },
        // "1、" "12、"
        |s: &str| {
            let parts: Vec<&str> = s.splitn(2, '、').collect();
            parts.len() == 2 && parts[0].chars().all(|c| c.is_ascii_digit()) && !parts[0].is_empty()
        },
    ];
    
    patterns.iter().any(|p| p(text))
}

/// 检测是否是字母序号开头
fn is_lettered_list_start(text: &str) -> bool {
    let text = text.trim();
    if text.len() < 2 {
        return false;
    }
    
    let first = match text.chars().next() {
        Some(c) => c,
        None => return false,
    };
    let second = match text.chars().nth(1) {
        Some(c) => c,
        None => return false,
    };
    
    // 单个字母 + 分隔符（a. A) (b)）
    if first.is_ascii_alphabetic() {
        if matches!(second, '.' | ')' | '、') {
            return true;
        }
    }
    
    // (a) (A)
    if first == '(' {
        if let Some(c) = text.chars().nth(1) {
            if c.is_ascii_alphabetic() {
                if text.chars().nth(2) == Some(')') {
                    return true;
                }
            }
        }
    }
    
    false
}

/// 判断标题级别
fn determine_heading_level(seg: &TextSegment, stats: &FontStats) -> u8 {
    if seg.text.len() > 100 {
        return 0;
    }

    let text = seg.text.trim();
    
    // 以句号结尾的不是标题
    if text.ends_with('.') || text.ends_with('。') {
        return 0;
    }
    
    // 纯 emoji 或太短的文本不是标题
    if is_mostly_emoji(text) || count_cjk_and_ascii(text) < 2 {
        return 0;
    }

    if seg.font_size >= stats.h1_threshold {
        1
    } else if seg.font_size >= stats.h2_threshold {
        2
    } else if seg.font_size >= stats.h3_threshold {
        3
    } else if seg.is_bold && seg.text.len() < 60 && count_cjk_and_ascii(text) >= 4 {
        4
    } else {
        0
    }
}

/// 检查文本是否主要由 emoji 组成
fn is_mostly_emoji(text: &str) -> bool {
    let total_chars = text.chars().count();
    if total_chars == 0 {
        return true;
    }
    
    let emoji_count = text.chars().filter(|c| is_emoji(*c)).count();
    // 如果 emoji 占比超过 50%，认为是纯 emoji
    emoji_count * 2 >= total_chars
}

/// 判断字符是否是 emoji
fn is_emoji(c: char) -> bool {
    let code = c as u32;
    // 常见 emoji 范围
    matches!(code,
        0x1F300..=0x1F9FF |  // 杂项符号和象形文字（包含表情、交通符号等）
        0x2600..=0x26FF |    // 杂项符号
        0x2700..=0x27BF |    // 装饰符号
        0x1F1E0..=0x1F1FF    // 旗帜
    )
}

/// 统计中文字符和 ASCII 字母数量
fn count_cjk_and_ascii(text: &str) -> usize {
    text.chars().filter(|c| {
        c.is_ascii_alphabetic() || is_cjk(*c)
    }).count()
}

/// 判断是否是中日韩字符
fn is_cjk(c: char) -> bool {
    let code = c as u32;
    matches!(code,
        0x4E00..=0x9FFF |    // CJK 统一汉字
        0x3400..=0x4DBF |    // CJK 扩展 A
        0x3000..=0x303F      // CJK 标点
    )
}

/// 格式化文本
fn format_text(text: &str, is_bold: bool, is_italic: bool, heading_level: u8, preserve_formatting: bool) -> String {
    if heading_level > 0 {
        let prefix = "#".repeat(heading_level as usize);
        return format!("{} {}", prefix, text);
    }

    if !preserve_formatting {
        return text.to_string();
    }

    if is_bold && is_italic {
        format!("***{}***", text)
    } else if is_bold {
        format!("**{}**", text)
    } else if is_italic {
        format!("*{}*", text)
    } else {
        text.to_string()
    }
}

/// 清理 Markdown
fn clean_markdown(text: &str) -> String {
    let mut result = text.to_string();
    while result.contains("\n\n\n") {
        result = result.replace("\n\n\n", "\n\n");
    }
    result.trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_font_stats_analysis() {
        let segments = vec![
            TextSegment {
                text: "Title".to_string(),
                font_size: 24.0,
                is_bold: true,
                is_italic: false,
                x: 0.0,
                y: 100.0,
                page_index: 0,
            },
            TextSegment {
                text: "Body text that is much longer and represents the main content".to_string(),
                font_size: 12.0,
                is_bold: false,
                is_italic: false,
                x: 0.0,
                y: 80.0,
                page_index: 0,
            },
            TextSegment {
                text: "More body text".to_string(),
                font_size: 12.0,
                is_bold: false,
                is_italic: false,
                x: 0.0,
                y: 60.0,
                page_index: 0,
            },
        ];

        let stats = analyze_font_sizes(&segments);
        assert!((stats.body_size - 12.0).abs() < 0.1);
        assert!(stats.h1_threshold > 20.0);
    }

    #[test]
    fn test_heading_detection() {
        let stats = FontStats {
            body_size: 12.0,
            h1_threshold: 20.0,
            h2_threshold: 16.0,
            h3_threshold: 14.0,
            enabled: true,
        };

        let h1_seg = TextSegment {
            text: "Main Title".to_string(),
            font_size: 24.0,
            is_bold: true,
            is_italic: false,
            x: 0.0,
            y: 0.0,
            page_index: 0,
        };
        assert_eq!(determine_heading_level(&h1_seg, &stats), 1);

        let body_seg = TextSegment {
            text: "Normal paragraph text.".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 0.0,
            page_index: 0,
        };
        assert_eq!(determine_heading_level(&body_seg, &stats), 0);
    }

    #[test]
    fn test_format_text() {
        assert_eq!(format_text("Hello", false, false, 0, true), "Hello");
        assert_eq!(format_text("Bold", true, false, 0, true), "**Bold**");
        assert_eq!(format_text("Italic", false, true, 0, true), "*Italic*");
        assert_eq!(format_text("Both", true, true, 0, true), "***Both***");
        assert_eq!(format_text("Title", false, false, 1, true), "# Title");
        assert_eq!(format_text("Sub", false, false, 2, true), "## Sub");
    }

    #[test]
    fn test_clean_markdown() {
        let input = "Hello\n\n\n\nWorld\n\n\n";
        let expected = "Hello\n\nWorld";
        assert_eq!(clean_markdown(input), expected);
    }
}
