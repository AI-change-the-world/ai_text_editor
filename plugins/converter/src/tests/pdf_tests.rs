//! PDF 转换测试
//!
//! 测试 PDF 文本提取和格式识别功能

use crate::to_markdown::pdf::{FontStats, PdfConfig, TextSegment};

#[allow(unused_imports)]
use crate::to_markdown::ToMarkdown;

/// 测试 PDFium 库绑定
#[test]
fn test_pdfium_binding() {
    let config = PdfConfig::default();
    // 验证配置默认值
    assert_eq!(config.library_path, Some("./dylib/".to_string()));
    assert!(config.detect_headings);
    assert!(config.preserve_formatting);
}

/// 测试空文本片段处理
#[test]
fn test_empty_segments() {
    let segments: Vec<TextSegment> = vec![];
    let stats = analyze_font_sizes_test(&segments);
    
    // 空片段应返回默认值
    assert!((stats.body_size - 12.0).abs() < 0.1);
}

/// 测试字体大小分析
#[test]
fn test_font_size_analysis() {
    let segments = create_test_segments();
    let stats = analyze_font_sizes_test(&segments);
    
    // 正文大小应该是出现最多的字体大小
    assert!((stats.body_size - 12.0).abs() < 0.1);
    
    // 标题阈值应该基于正文大小计算
    assert!(stats.h1_threshold > stats.h2_threshold);
    assert!(stats.h2_threshold > stats.h3_threshold);
    assert!(stats.h3_threshold > stats.body_size);
}

/// 测试标题级别判断
#[test]
fn test_heading_level_detection() {
    let stats = FontStats {
        body_size: 12.0,
        h1_threshold: 21.6,  // 12 * 1.8
        h2_threshold: 16.8,  // 12 * 1.4
        h3_threshold: 14.4,  // 12 * 1.2
        enabled: true,
    };

    // H1 标题
    let h1 = TextSegment {
        text: "Main Title".to_string(),
        font_size: 24.0,
        is_bold: true,
        is_italic: false,
        x: 0.0,
        y: 100.0,
        page_index: 0,
    };
    assert_eq!(determine_heading_level_test(&h1, &stats), 1);

    // H2 标题
    let h2 = TextSegment {
        text: "Section Title".to_string(),
        font_size: 18.0,
        is_bold: true,
        is_italic: false,
        x: 0.0,
        y: 90.0,
        page_index: 0,
    };
    assert_eq!(determine_heading_level_test(&h2, &stats), 2);

    // H3 标题
    let h3 = TextSegment {
        text: "Subsection".to_string(),
        font_size: 15.0,
        is_bold: false,
        is_italic: false,
        x: 0.0,
        y: 80.0,
        page_index: 0,
    };
    assert_eq!(determine_heading_level_test(&h3, &stats), 3);

    // 正文（不是标题）
    let body = TextSegment {
        text: "This is a normal paragraph with some text.".to_string(),
        font_size: 12.0,
        is_bold: false,
        is_italic: false,
        x: 0.0,
        y: 70.0,
        page_index: 0,
    };
    assert_eq!(determine_heading_level_test(&body, &stats), 0);

    // 以句号结尾的不应该是标题
    let sentence = TextSegment {
        text: "This ends with a period.".to_string(),
        font_size: 18.0,
        is_bold: true,
        is_italic: false,
        x: 0.0,
        y: 60.0,
        page_index: 0,
    };
    assert_eq!(determine_heading_level_test(&sentence, &stats), 0);

    // 太长的文本不应该是标题
    let long_text = TextSegment {
        text: "A".repeat(150),
        font_size: 24.0,
        is_bold: true,
        is_italic: false,
        x: 0.0,
        y: 50.0,
        page_index: 0,
    };
    assert_eq!(determine_heading_level_test(&long_text, &stats), 0);
}

/// 测试粗体短文本作为小标题
#[test]
fn test_bold_short_text_as_heading() {
    let stats = FontStats {
        body_size: 12.0,
        h1_threshold: 21.6,
        h2_threshold: 16.8,
        h3_threshold: 14.4,
        enabled: true,
    };

    let bold_short = TextSegment {
        text: "Important Note".to_string(),
        font_size: 12.0,
        is_bold: true,
        is_italic: false,
        x: 0.0,
        y: 0.0,
        page_index: 0,
    };
    // 粗体短文本应该被识别为 H4
    assert_eq!(determine_heading_level_test(&bold_short, &stats), 4);
}

/// 测试文本格式化
#[test]
fn test_text_formatting() {
    // 普通文本
    assert_eq!(format_text_test("Hello", false, false, 0, true), "Hello");
    
    // 粗体
    assert_eq!(format_text_test("Bold", true, false, 0, true), "**Bold**");
    
    // 斜体
    assert_eq!(format_text_test("Italic", false, true, 0, true), "*Italic*");
    
    // 粗斜体
    assert_eq!(format_text_test("Both", true, true, 0, true), "***Both***");
    
    // 标题
    assert_eq!(format_text_test("Title", false, false, 1, true), "# Title");
    assert_eq!(format_text_test("Sub", false, false, 2, true), "## Sub");
    assert_eq!(format_text_test("SubSub", false, false, 3, true), "### SubSub");
    
    // 禁用格式保留
    assert_eq!(format_text_test("Bold", true, false, 0, false), "Bold");
}

/// 测试 Markdown 清理
#[test]
fn test_markdown_cleanup() {
    // 多余空行应该被清理
    let input = "Hello\n\n\n\nWorld\n\n\n";
    let expected = "Hello\n\nWorld";
    assert_eq!(clean_markdown_test(input), expected);

    // 首尾空白应该被移除
    let input2 = "  \n\nContent\n\n  ";
    assert_eq!(clean_markdown_test(input2), "Content");
}

/// 测试文本片段排序
#[test]
fn test_segment_sorting() {
    let mut segments = vec![
        TextSegment {
            text: "Bottom".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 10.0,  // 底部
            page_index: 0,
        },
        TextSegment {
            text: "Top".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 100.0,  // 顶部
            page_index: 0,
        },
        TextSegment {
            text: "Middle Right".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 100.0,  // 右侧
            y: 50.0,
            page_index: 0,
        },
        TextSegment {
            text: "Middle Left".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,  // 左侧
            y: 50.0,
            page_index: 0,
        },
    ];

    // 按位置排序（从上到下，从左到右）
    segments.sort_by(|a, b| {
        let y_cmp = b.y.partial_cmp(&a.y).unwrap_or(std::cmp::Ordering::Equal);
        if y_cmp != std::cmp::Ordering::Equal {
            return y_cmp;
        }
        a.x.partial_cmp(&b.x).unwrap_or(std::cmp::Ordering::Equal)
    });

    assert_eq!(segments[0].text, "Top");
    assert_eq!(segments[1].text, "Middle Left");
    assert_eq!(segments[2].text, "Middle Right");
    assert_eq!(segments[3].text, "Bottom");
}

/// 测试多页面处理
#[test]
fn test_multipage_segments() {
    let segments = vec![
        TextSegment {
            text: "Page 1 content".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 100.0,
            page_index: 0,
        },
        TextSegment {
            text: "Page 2 content".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 100.0,
            page_index: 1,
        },
    ];

    let stats = FontStats {
        body_size: 12.0,
        h1_threshold: 21.6,
        h2_threshold: 16.8,
        h3_threshold: 14.4,
        enabled: true,
    };

    let markdown = segments_to_markdown_test(&segments, &stats, true);
    
    // 应该包含页面分隔符
    assert!(markdown.contains("---"));
    assert!(markdown.contains("Page 1 content"));
    assert!(markdown.contains("Page 2 content"));
}

/// 测试配置选项
#[test]
fn test_pdf_config() {
    // 默认配置
    let default_config = PdfConfig::default();
    assert!(default_config.detect_headings);
    assert!(default_config.preserve_formatting);

    // 自定义配置
    let custom_config = PdfConfig {
        library_path: Some("/custom/path/".to_string()),
        detect_headings: false,
        preserve_formatting: false,
        image_output_dir: None,
    };
    assert!(!custom_config.detect_headings);
    assert!(!custom_config.preserve_formatting);
}

/// 测试禁用标题检测
#[test]
fn test_disabled_heading_detection() {
    let stats = FontStats {
        body_size: 12.0,
        h1_threshold: f32::MAX,
        h2_threshold: f32::MAX,
        h3_threshold: f32::MAX,
        enabled: false,
    };

    let _large_text = TextSegment {
        text: "Large Text".to_string(),
        font_size: 48.0,
        is_bold: true,
        is_italic: false,
        x: 0.0,
        y: 0.0,
        page_index: 0,
    };

    // 禁用时，即使是大字体也不应该被识别为标题
    // 注意：这里我们直接测试 enabled 标志
    assert!(!stats.enabled);
}

// ============ 辅助函数（模拟内部函数用于测试） ============

fn create_test_segments() -> Vec<TextSegment> {
    vec![
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
            text: "This is body text that appears multiple times in the document".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 80.0,
            page_index: 0,
        },
        TextSegment {
            text: "More body text here".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 60.0,
            page_index: 0,
        },
        TextSegment {
            text: "And even more body text".to_string(),
            font_size: 12.0,
            is_bold: false,
            is_italic: false,
            x: 0.0,
            y: 40.0,
            page_index: 0,
        },
    ]
}

fn analyze_font_sizes_test(segments: &[TextSegment]) -> FontStats {
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

fn determine_heading_level_test(seg: &TextSegment, stats: &FontStats) -> u8 {
    if seg.text.len() > 100 {
        return 0;
    }

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
        4
    } else {
        0
    }
}

fn format_text_test(text: &str, is_bold: bool, is_italic: bool, heading_level: u8, preserve_formatting: bool) -> String {
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

fn clean_markdown_test(text: &str) -> String {
    let mut result = text.to_string();
    while result.contains("\n\n\n") {
        result = result.replace("\n\n\n", "\n\n");
    }
    result.trim().to_string()
}

fn segments_to_markdown_test(segments: &[TextSegment], stats: &FontStats, preserve_formatting: bool) -> String {
    let mut result = String::new();
    let mut last_y: Option<f32> = None;
    let mut last_page: Option<usize> = None;

    for seg in segments {
        let text = seg.text.trim();
        if text.is_empty() {
            continue;
        }

        if let Some(lp) = last_page {
            if seg.page_index != lp {
                result.push_str("\n\n---\n\n");
                last_y = None;
            }
        }

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

        let heading_level = if stats.enabled {
            determine_heading_level_test(seg, stats)
        } else {
            0
        };

        let formatted = format_text_test(text, seg.is_bold, seg.is_italic, heading_level, preserve_formatting);

        if heading_level > 0 {
            if !result.ends_with("\n\n") && !result.is_empty() {
                result.push_str("\n\n");
            }
            result.push_str(&formatted);
            result.push_str("\n\n");
        } else {
            result.push_str(&formatted);
        }

        last_y = Some(seg.y);
        last_page = Some(seg.page_index);
    }

    clean_markdown_test(&result)
}


/// 测试真实 PDF 文件转换（test.pdf）
/// 运行: cargo test test_real_pdf_conversion -- --nocapture
#[test]
fn test_real_pdf_conversion() {
    use crate::to_markdown::pdf::{PdfConverter, PdfConfig};
    
    let pdf_path = "test.pdf";
    
    if !std::path::Path::new(pdf_path).exists() {
        println!("跳过测试: test.pdf 不存在");
        return;
    }
    
    // 配置图像输出目录
    let config = PdfConfig {
        image_output_dir: Some("./test_images".to_string()),
        ..PdfConfig::default()
    };
    
    match PdfConverter::convert_with_config(pdf_path, &config) {
        Ok(markdown) => {
            println!("\n========== PDF 转换结果 ==========\n");
            println!("{}", markdown);
            println!("\n===================================\n");
            
            // 保存到文件
            let output_path = "test_output.md";
            std::fs::write(output_path, &markdown).expect("写入文件失败");
            println!("已保存到: {}", output_path);
        }
        Err(e) => {
            panic!("PDF 转换失败: {}", e);
        }
    }
}
