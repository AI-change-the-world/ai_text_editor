//! 将 Markdown 转换为其他格式
//!
//! 支持的格式:
//! - DOCX

pub mod docx;

use std::path::Path;

use crate::error::Result;

pub use docx::MarkdownToDocx;

/// 将 Markdown 转换为 DOCX 并保存
pub fn to_docx<P: AsRef<Path>>(save_path: P, markdown_str: &str) -> Result<()> {
    MarkdownToDocx::convert_and_save(save_path, markdown_str)
}
