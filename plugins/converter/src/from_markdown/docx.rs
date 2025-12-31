//! Markdown 转 DOCX 转换器

use std::fs::File;
use std::path::Path;

use docx_rs::{Docx, Hyperlink, HyperlinkType, Paragraph, Run};
use once_cell::sync::Lazy;
use regex::Regex;

use crate::error::{ConvertError, Result};

// 正则表达式
static BOLD_ITALIC_REG: Lazy<Regex> = Lazy::new(|| Regex::new(r"\*{3}(.+?)\*{3}").unwrap());
static BOLD_REG: Lazy<Regex> = Lazy::new(|| Regex::new(r"\*{2}(.+?)\*{2}").unwrap());
static ITALIC_REG: Lazy<Regex> = Lazy::new(|| Regex::new(r"\*{1}(.+?)\*{1}").unwrap());
static STRIKE_REG: Lazy<Regex> = Lazy::new(|| Regex::new(r"~~(.+?)~~").unwrap());
static LINK_REG: Lazy<Regex> = Lazy::new(|| Regex::new(r"\[([^\]]+)\]\(([^)]+)\)").unwrap());
static HEADING_REG: Lazy<Regex> = Lazy::new(|| Regex::new(r"^(#{1,6})\s+(.+)$").unwrap());

/// Markdown 转 DOCX 转换器
pub struct MarkdownToDocx;

impl MarkdownToDocx {
    /// 转换并保存
    pub fn convert_and_save<P: AsRef<Path>>(save_path: P, markdown_str: &str) -> Result<()> {
        let docx = Self::convert(markdown_str)?;
        let file = File::create(save_path)?;
        docx.build()
            .pack(file)
            .map_err(|e| ConvertError::DocxError(e.to_string()))?;
        Ok(())
    }

    /// 转换为 Docx 对象
    pub fn convert(markdown_str: &str) -> Result<Docx> {
        let mut docx = Docx::new();

        for line in markdown_str.lines() {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }

            docx = Self::process_line(docx, line);
        }

        Ok(docx)
    }

    fn process_line(docx: Docx, line: &str) -> Docx {
        // 检查是否是标题
        if let Some(caps) = HEADING_REG.captures(line) {
            let level = caps.get(1).map(|m| m.as_str().len()).unwrap_or(1);
            let text = caps.get(2).map(|m| m.as_str()).unwrap_or(line);
            return Self::add_heading(docx, text, level);
        }

        // 检查是否是列表项
        let (is_list, content) = if line.starts_with("- ") || line.starts_with("* ") {
            (true, &line[2..])
        } else if line.chars().next().map(|c| c.is_ascii_digit()).unwrap_or(false) 
            && line.contains(". ") 
        {
            let idx = line.find(". ").unwrap_or(0);
            (true, &line[idx + 2..])
        } else {
            (false, line)
        };

        // 处理链接
        if LINK_REG.is_match(content) {
            return Self::add_paragraph_with_links(docx, content, is_list);
        }

        // 处理格式化文本
        Self::add_formatted_paragraph(docx, content, is_list)
    }

    fn add_heading(docx: Docx, text: &str, level: usize) -> Docx {
        let (size, style) = match level {
            1 => (48, "Heading1"),
            2 => (36, "Heading2"),
            3 => (28, "Heading3"),
            4 => (24, "Heading4"),
            5 => (20, "Heading5"),
            _ => (18, "Heading6"),
        };

        let run = Run::new()
            .add_text(text)
            .size(size)
            .bold()
            .style(style);

        docx.add_paragraph(Paragraph::new().add_run(run))
    }

    fn add_paragraph_with_links(docx: Docx, text: &str, _is_list: bool) -> Docx {
        let mut paragraph = Paragraph::new();
        let mut last_end = 0;

        for caps in LINK_REG.captures_iter(text) {
            let full_match = caps.get(0).unwrap();
            let link_text = caps.get(1).map(|m| m.as_str()).unwrap_or("");
            let link_url = caps.get(2).map(|m| m.as_str()).unwrap_or("");

            // 添加链接前的文本
            if full_match.start() > last_end {
                let before = &text[last_end..full_match.start()];
                paragraph = Self::add_formatted_runs(paragraph, before);
            }

            // 添加链接
            paragraph = paragraph.add_hyperlink(
                Hyperlink::new(link_url, HyperlinkType::External)
                    .add_run(Run::new().add_text(link_text).color("0000FF").underline("single")),
            );

            last_end = full_match.end();
        }

        // 添加剩余文本
        if last_end < text.len() {
            paragraph = Self::add_formatted_runs(paragraph, &text[last_end..]);
        }

        docx.add_paragraph(paragraph)
    }

    fn add_formatted_paragraph(docx: Docx, text: &str, _is_list: bool) -> Docx {
        let paragraph = Self::add_formatted_runs(Paragraph::new(), text);
        docx.add_paragraph(paragraph)
    }

    fn add_formatted_runs(mut paragraph: Paragraph, text: &str) -> Paragraph {
        let segments = parse_formatted_text(text);
        
        for (style, content) in segments {
            let mut run = Run::new().add_text(&content);
            
            match style {
                TextStyle::BoldItalic => run = run.bold().italic(),
                TextStyle::Bold => run = run.bold(),
                TextStyle::Italic => run = run.italic(),
                TextStyle::Strikethrough => {
                    // docx-rs 0.4.17 没有 strike() 方法，使用 vanish 或跳过
                    // 暂时保留文本但不添加删除线样式
                }
                TextStyle::Plain => {}
            }
            
            paragraph = paragraph.add_run(run);
        }

        paragraph
    }
}

#[derive(Debug, Clone, PartialEq)]
enum TextStyle {
    Plain,
    Bold,
    Italic,
    BoldItalic,
    Strikethrough,
}

/// 解析格式化文本
fn parse_formatted_text(text: &str) -> Vec<(TextStyle, String)> {
    let mut result = Vec::new();
    let mut remaining = text.to_string();

    while !remaining.is_empty() {
        // 尝试匹配各种格式
        let mut matched = false;

        // 粗斜体 ***text***
        if let Some(caps) = BOLD_ITALIC_REG.captures(&remaining) {
            let full = caps.get(0).unwrap();
            let content = caps.get(1).unwrap().as_str();
            
            if full.start() > 0 {
                result.push((TextStyle::Plain, remaining[..full.start()].to_string()));
            }
            result.push((TextStyle::BoldItalic, content.to_string()));
            remaining = remaining[full.end()..].to_string();
            matched = true;
        }
        // 粗体 **text**
        else if let Some(caps) = BOLD_REG.captures(&remaining) {
            let full = caps.get(0).unwrap();
            let content = caps.get(1).unwrap().as_str();
            
            if full.start() > 0 {
                result.push((TextStyle::Plain, remaining[..full.start()].to_string()));
            }
            result.push((TextStyle::Bold, content.to_string()));
            remaining = remaining[full.end()..].to_string();
            matched = true;
        }
        // 斜体 *text*
        else if let Some(caps) = ITALIC_REG.captures(&remaining) {
            let full = caps.get(0).unwrap();
            let content = caps.get(1).unwrap().as_str();
            
            if full.start() > 0 {
                result.push((TextStyle::Plain, remaining[..full.start()].to_string()));
            }
            result.push((TextStyle::Italic, content.to_string()));
            remaining = remaining[full.end()..].to_string();
            matched = true;
        }
        // 删除线 ~~text~~
        else if let Some(caps) = STRIKE_REG.captures(&remaining) {
            let full = caps.get(0).unwrap();
            let content = caps.get(1).unwrap().as_str();
            
            if full.start() > 0 {
                result.push((TextStyle::Plain, remaining[..full.start()].to_string()));
            }
            result.push((TextStyle::Strikethrough, content.to_string()));
            remaining = remaining[full.end()..].to_string();
            matched = true;
        }

        if !matched {
            // 没有匹配到任何格式，作为纯文本处理
            result.push((TextStyle::Plain, remaining));
            break;
        }
    }

    // 合并相邻的相同样式
    merge_adjacent_styles(result)
}

fn merge_adjacent_styles(segments: Vec<(TextStyle, String)>) -> Vec<(TextStyle, String)> {
    let mut result: Vec<(TextStyle, String)> = Vec::new();
    
    for (style, content) in segments {
        if let Some(last) = result.last_mut() {
            if last.0 == style {
                last.1.push_str(&content);
                continue;
            }
        }
        result.push((style, content));
    }
    
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_plain_text() {
        let result = parse_formatted_text("Hello World");
        assert_eq!(result.len(), 1);
        assert_eq!(result[0], (TextStyle::Plain, "Hello World".to_string()));
    }

    #[test]
    fn test_parse_bold_text() {
        let result = parse_formatted_text("Hello **bold** world");
        assert_eq!(result.len(), 3);
        assert_eq!(result[0], (TextStyle::Plain, "Hello ".to_string()));
        assert_eq!(result[1], (TextStyle::Bold, "bold".to_string()));
        assert_eq!(result[2], (TextStyle::Plain, " world".to_string()));
    }

    #[test]
    fn test_parse_italic_text() {
        let result = parse_formatted_text("Hello *italic* world");
        assert_eq!(result.len(), 3);
        assert_eq!(result[1], (TextStyle::Italic, "italic".to_string()));
    }

    #[test]
    fn test_parse_bold_italic_text() {
        let result = parse_formatted_text("Hello ***both*** world");
        assert_eq!(result.len(), 3);
        assert_eq!(result[1], (TextStyle::BoldItalic, "both".to_string()));
    }

    #[test]
    fn test_heading_regex() {
        assert!(HEADING_REG.is_match("# Title"));
        assert!(HEADING_REG.is_match("## Subtitle"));
        assert!(HEADING_REG.is_match("###### H6"));
        assert!(!HEADING_REG.is_match("Not a heading"));
    }

    #[test]
    fn test_link_regex() {
        let caps = LINK_REG.captures("[text](https://example.com)").unwrap();
        assert_eq!(caps.get(1).unwrap().as_str(), "text");
        assert_eq!(caps.get(2).unwrap().as_str(), "https://example.com");
    }
}
