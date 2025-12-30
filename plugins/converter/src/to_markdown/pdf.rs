use std::path::Path;

use pdfium_render::prelude::*;

use super::TToMarkdown;

/// 文本片段，包含内容和格式信息
#[derive(Debug, Clone)]
struct TextSegment {
    text: String,
    font_size: f32,
    is_bold: bool,
    is_italic: bool,
    x: f32,  // 水平位置
    y: f32,  // 垂直位置
}

pub struct PdfToMarkdown;

impl TToMarkdown for PdfToMarkdown {
    fn to_markdown(p: String) -> anyhow::Result<String> {
        let path = Path::new(&p);
        
        // 绑定 PDFium 库
        // 会自动搜索系统路径，或者你可以指定路径
        let pdfium = Pdfium::new(
            Pdfium::bind_to_library(Pdfium::pdfium_platform_library_name_at_path("./dylib/"))
                .or_else(|_| Pdfium::bind_to_system_library())
                .map_err(|e| anyhow::anyhow!("Failed to bind PDFium library: {}. Please ensure PDFium is installed.", e))?
        );
        
        let document = pdfium.load_pdf_from_file(path, None)
            .map_err(|e| anyhow::anyhow!("Failed to load PDF: {}", e))?;
        
        let mut all_segments: Vec<TextSegment> = Vec::new();
        
        // 遍历所有页面
        for page in document.pages().iter() {
            let segments = extract_page_segments(&page)?;
            all_segments.extend(segments);
        }
        
        // 分析字体大小分布，确定标题阈值
        let font_stats = analyze_font_sizes(&all_segments);
        
        // 转换为 Markdown
        let markdown = segments_to_markdown(&all_segments, &font_stats);
        
        Ok(markdown)
    }
}

/// 从页面提取文本片段
fn extract_page_segments(page: &PdfPage) -> anyhow::Result<Vec<TextSegment>> {
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
            
            // 判断是否粗体（通过字体名称或字重）
            let is_bold = font_name.contains("bold") 
                || font_name.contains("black")
                || font_name.contains("heavy")
                || font.weight().map_or(false, |w| matches!(w, 
                    PdfFontWeight::Weight700Bold 
                    | PdfFontWeight::Custom(_)
                ));
            
            // 判断是否斜体
            let is_italic = font_name.contains("italic") 
                || font_name.contains("oblique");
            
            // 获取位置
            let bounds = text_object.bounds()
                .map_err(|e| anyhow::anyhow!("Failed to get text bounds: {}", e))?;
            
            segments.push(TextSegment {
                text: text.to_string(),
                font_size,
                is_bold,
                is_italic,
                x: bounds.left().value,
                y: bounds.top().value,
            });
        }
    }
    
    // 按位置排序（从上到下，从左到右）
    segments.sort_by(|a, b| {
        // 先按 y 坐标降序（PDF 坐标系 y 轴向上）
        let y_cmp = b.y.partial_cmp(&a.y).unwrap_or(std::cmp::Ordering::Equal);
        if y_cmp != std::cmp::Ordering::Equal {
            return y_cmp;
        }
        // 再按 x 坐标升序
        a.x.partial_cmp(&b.x).unwrap_or(std::cmp::Ordering::Equal)
    });
    
    Ok(segments)
}

/// 字体大小统计信息
struct FontStats {
    body_size: f32,      // 正文字体大小
    h1_threshold: f32,   // 一级标题阈值
    h2_threshold: f32,   // 二级标题阈值
    h3_threshold: f32,   // 三级标题阈值
}

/// 分析字体大小分布
fn analyze_font_sizes(segments: &[TextSegment]) -> FontStats {
    if segments.is_empty() {
        return FontStats {
            body_size: 12.0,
            h1_threshold: 20.0,
            h2_threshold: 16.0,
            h3_threshold: 14.0,
        };
    }
    
    // 统计字体大小出现频率
    let mut size_counts: std::collections::HashMap<i32, usize> = std::collections::HashMap::new();
    for seg in segments {
        let size_key = (seg.font_size * 10.0) as i32; // 精确到0.1
        *size_counts.entry(size_key).or_insert(0) += seg.text.len();
    }
    
    // 找出最常见的字体大小（正文大小）
    let body_size_key = size_counts.iter()
        .max_by_key(|(_, count)| *count)
        .map(|(size, _)| *size)
        .unwrap_or(120);
    let body_size = body_size_key as f32 / 10.0;
    
    // 基于正文大小设置标题阈值
    FontStats {
        body_size,
        h1_threshold: body_size * 1.8,
        h2_threshold: body_size * 1.4,
        h3_threshold: body_size * 1.2,
    }
}

/// 将文本片段转换为 Markdown
fn segments_to_markdown(segments: &[TextSegment], stats: &FontStats) -> String {
    let mut result = String::new();
    let mut last_y: Option<f32> = None;
    
    for seg in segments {
        let text = seg.text.trim();
        if text.is_empty() {
            continue;
        }
        
        // 检测换行（y 坐标变化较大）
        if let Some(ly) = last_y {
            let y_diff = (ly - seg.y).abs();
            if y_diff > seg.font_size * 1.5 {
                // 段落分隔
                if !result.ends_with("\n\n") {
                    result.push_str("\n\n");
                }
            } else if y_diff > seg.font_size * 0.5 {
                // 行内换行
                if !result.ends_with('\n') && !result.ends_with(' ') {
                    result.push(' ');
                }
            }
        }
        
        // 判断标题级别
        let heading_level = determine_heading_level(seg, stats);
        
        // 格式化文本
        let formatted = format_text(text, seg.is_bold, seg.is_italic, heading_level);
        
        if heading_level > 0 {
            // 标题前后需要空行
            if !result.ends_with("\n\n") && !result.is_empty() {
                result.push_str("\n\n");
            }
            result.push_str(&formatted);
            result.push_str("\n\n");
        } else {
            result.push_str(&formatted);
        }
        
        last_y = Some(seg.y);
    }
    
    // 清理多余空行
    clean_markdown(&result)
}

/// 判断标题级别（0 表示非标题）
fn determine_heading_level(seg: &TextSegment, stats: &FontStats) -> u8 {
    // 太长的文本不太可能是标题
    if seg.text.len() > 100 {
        return 0;
    }
    
    // 以句号结尾的不太可能是标题
    let text = seg.text.trim();
    if text.ends_with('.') || text.ends_with('。') {
        return 0;
    }
    
    if seg.font_size >= stats.h1_threshold {
        1
    } else if seg.font_size >= stats.h2_threshold {
        2
    } else if seg.font_size >= stats.h3_threshold {
        3
    } else if seg.is_bold && seg.text.len() < 60 {
        // 粗体短文本可能是小标题
        4
    } else {
        0
    }
}

/// 格式化文本（添加 Markdown 标记）
fn format_text(text: &str, is_bold: bool, is_italic: bool, heading_level: u8) -> String {
    let mut result = text.to_string();
    
    if heading_level > 0 {
        // 标题
        let prefix = "#".repeat(heading_level as usize);
        result = format!("{} {}", prefix, result);
    } else {
        // 普通文本，添加粗体/斜体标记
        if is_bold && is_italic {
            result = format!("***{}***", result);
        } else if is_bold {
            result = format!("**{}**", result);
        } else if is_italic {
            result = format!("*{}*", result);
        }
    }
    
    result
}

/// 清理 Markdown 文本
fn clean_markdown(text: &str) -> String {
    let mut result = text.to_string();
    
    // 移除连续的多个空行
    while result.contains("\n\n\n") {
        result = result.replace("\n\n\n", "\n\n");
    }
    
    result.trim().to_string()
}
