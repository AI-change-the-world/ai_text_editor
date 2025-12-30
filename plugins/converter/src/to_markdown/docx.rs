//! DOCX 转 Markdown 转换器
//!
//! 基于 docx-rs 实现，支持:
//! - 段落文本提取
//! - 标题识别
//! - 粗体/斜体格式
//! - 列表（有序/无序）
//! - 表格

use std::fs::File;
use std::io::Read;
use std::path::Path;

use docx_rs::{read_docx, DocumentChild, ParagraphChild, RunChild, TableChild, TableRowChild};

use super::ToMarkdown;
use crate::error::{ConvertError, Result};

/// DOCX 转换器
pub struct DocxConverter;

impl ToMarkdown for DocxConverter {
    fn to_markdown<P: AsRef<Path>>(path: P) -> Result<String> {
        Self::convert(path)
    }
}

impl DocxConverter {
    pub fn convert<P: AsRef<Path>>(path: P) -> Result<String> {
        let path = path.as_ref();
        
        let mut file = File::open(path)
            .map_err(|e| ConvertError::IoError(e))?;
        
        let mut buf = Vec::new();
        file.read_to_end(&mut buf)
            .map_err(|e| ConvertError::IoError(e))?;
        
        let docx = read_docx(&buf)
            .map_err(|e| ConvertError::DocxError(format!("解析 DOCX 失败: {}", e)))?;
        
        let mut markdown = String::new();
        let mut list_state = ListState::None;
        
        for child in docx.document.children {
            match child {
                DocumentChild::Paragraph(para) => {
                    let (text, new_state) = process_paragraph(&para, &list_state);
                    
                    // 列表状态变化时添加空行
                    if !matches!((&list_state, &new_state), (ListState::None, ListState::None)) 
                        && std::mem::discriminant(&list_state) != std::mem::discriminant(&new_state) 
                        && !markdown.is_empty() 
                        && !markdown.ends_with("\n\n") {
                        markdown.push('\n');
                    }
                    
                    list_state = new_state;
                    
                    if !text.is_empty() {
                        markdown.push_str(&text);
                        markdown.push('\n');
                        
                        // 非列表项后添加空行
                        if matches!(list_state, ListState::None) {
                            markdown.push('\n');
                        }
                    }
                }
                DocumentChild::Table(table) => {
                    list_state = ListState::None;
                    let table_md = process_table(&table);
                    if !table_md.is_empty() {
                        if !markdown.ends_with("\n\n") && !markdown.is_empty() {
                            markdown.push('\n');
                        }
                        markdown.push_str(&table_md);
                        markdown.push_str("\n\n");
                    }
                }
                _ => {}
            }
        }
        
        Ok(clean_markdown(&markdown))
    }
}


/// 列表状态
#[derive(Debug, Clone, PartialEq)]
enum ListState {
    None,
    Unordered,
    Ordered(u32),
}

/// 处理段落
fn process_paragraph(para: &docx_rs::Paragraph, prev_state: &ListState) -> (String, ListState) {
    let mut text = String::new();
    let mut is_bold_all = false;
    let mut list_state = ListState::None;
    
    // 检查段落样式（标题）
    let heading_level = get_heading_level(para);
    
    // 检查是否是列表
    if let Some(numbering) = &para.property.numbering_property {
        let num_id = numbering.id.as_ref().map(|n| n.id).unwrap_or(0);
        if num_id > 0 {
            // 简单判断：偶数 ID 通常是无序列表，奇数是有序列表
            // 实际上需要查 numbering.xml，这里简化处理
            list_state = if num_id % 2 == 0 {
                ListState::Unordered
            } else {
                match prev_state {
                    ListState::Ordered(n) => ListState::Ordered(n + 1),
                    _ => ListState::Ordered(1),
                }
            };
        }
    }
    
    // 提取文本内容
    for child in &para.children {
        match child {
            ParagraphChild::Run(run) => {
                let run_text = extract_run_text(run);
                if run_text.is_empty() {
                    continue;
                }
                
                // Bold 和 Italic 存在即表示启用
                let is_bold = run.run_property.bold.is_some();
                let is_italic = run.run_property.italic.is_some();
                
                // 检查是否整段都是粗体（可能是标题）
                if text.is_empty() && is_bold {
                    is_bold_all = true;
                } else if !is_bold {
                    is_bold_all = false;
                }
                
                let formatted = format_run_text(&run_text, is_bold, is_italic, heading_level > 0);
                text.push_str(&formatted);
            }
            ParagraphChild::Hyperlink(link) => {
                // 处理超链接
                let mut link_text = String::new();
                for run in &link.children {
                    if let docx_rs::ParagraphChild::Run(r) = run {
                        link_text.push_str(&extract_run_text(r));
                    }
                }
                if !link_text.is_empty() {
                    // 简化处理：只显示文本，不显示链接地址
                    text.push_str(&link_text);
                }
            }
            _ => {}
        }
    }
    
    let text = text.trim().to_string();
    if text.is_empty() {
        return (String::new(), ListState::None);
    }
    
    // 格式化输出
    let result = if heading_level > 0 {
        format!("{} {}", "#".repeat(heading_level as usize), text)
    } else if is_bold_all && text.len() < 80 && !text.ends_with('.') && !text.ends_with('。') {
        // 粗体短文本作为 H4
        format!("#### {}", text)
    } else {
        match &list_state {
            ListState::Unordered => format!("- {}", text),
            ListState::Ordered(n) => format!("{}. {}", n, text),
            ListState::None => text,
        }
    };
    
    (result, list_state)
}

/// 获取标题级别
fn get_heading_level(para: &docx_rs::Paragraph) -> u8 {
    if let Some(style) = &para.property.style {
        let style_id = style.val.to_lowercase();
        if style_id.starts_with("heading") || style_id.starts_with("title") {
            // Heading1, Heading2, etc.
            if let Some(num) = style_id.chars().last().and_then(|c| c.to_digit(10)) {
                return num.min(6) as u8;
            }
            if style_id.contains("title") {
                return 1;
            }
        }
        // 中文样式
        if style_id.contains("标题") {
            if let Some(num) = style_id.chars().find_map(|c| c.to_digit(10)) {
                return num.min(6) as u8;
            }
            return 1;
        }
    }
    0
}

/// 提取 Run 中的文本
fn extract_run_text(run: &docx_rs::Run) -> String {
    let mut text = String::new();
    for child in &run.children {
        match child {
            RunChild::Text(t) => text.push_str(&t.text),
            RunChild::Tab(_) => text.push('\t'),
            RunChild::Break(_) => text.push('\n'),
            _ => {}
        }
    }
    text
}

/// 格式化 Run 文本
fn format_run_text(text: &str, is_bold: bool, is_italic: bool, in_heading: bool) -> String {
    if in_heading || text.trim().is_empty() {
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

/// 处理表格
fn process_table(table: &docx_rs::Table) -> String {
    let mut rows: Vec<Vec<String>> = Vec::new();
    
    for child in &table.rows {
        let TableChild::TableRow(row) = child;
        let mut cells: Vec<String> = Vec::new();
        for cell_child in &row.cells {
            let TableRowChild::TableCell(cell) = cell_child;
            let cell_text = extract_cell_text(cell);
            cells.push(cell_text);
        }
        if !cells.is_empty() {
            rows.push(cells);
        }
    }
    
    if rows.is_empty() {
        return String::new();
    }
    
    // 生成 Markdown 表格
    let col_count = rows.iter().map(|r| r.len()).max().unwrap_or(0);
    let mut result = String::new();
    
    for (i, row) in rows.iter().enumerate() {
        result.push('|');
        for j in 0..col_count {
            let cell = row.get(j).map(|s| s.as_str()).unwrap_or("");
            result.push_str(&format!(" {} |", cell.replace('|', "\\|")));
        }
        result.push('\n');
        
        // 表头分隔行
        if i == 0 {
            result.push('|');
            for _ in 0..col_count {
                result.push_str(" --- |");
            }
            result.push('\n');
        }
    }
    
    result
}

/// 提取单元格文本
fn extract_cell_text(cell: &docx_rs::TableCell) -> String {
    let mut text = String::new();
    for child in &cell.children {
        if let docx_rs::TableCellContent::Paragraph(para) = child {
            for p_child in &para.children {
                if let ParagraphChild::Run(run) = p_child {
                    text.push_str(&extract_run_text(run));
                }
            }
        }
    }
    text.trim().replace('\n', " ")
}

/// 清理 Markdown
fn clean_markdown(text: &str) -> String {
    let mut result = text.to_string();
    while result.contains("\n\n\n") {
        result = result.replace("\n\n\n", "\n\n");
    }
    result.trim().to_string()
}
