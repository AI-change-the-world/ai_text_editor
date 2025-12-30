//! # Converter
//!
//! 文档格式转换库，支持多种格式与 Markdown 的双向转换。
//!
//! ## 支持的转换
//! - PDF -> Markdown
//! - CSV -> Markdown  
//! - DOCX -> Markdown (TODO)
//! - Markdown -> DOCX
//!
//! ## 使用示例
//! ```ignore
//! use converter::{to_markdown, from_markdown};
//!
//! // 将 PDF 转换为 Markdown
//! let markdown = to_markdown("document.pdf")?;
//!
//! // 将 Markdown 转换为 DOCX
//! from_markdown::to_docx("output.docx", &markdown)?;
//! ```

pub mod error;
pub mod to_markdown;
pub mod from_markdown;

// 内部模块
mod delta;

#[cfg(test)]
mod tests;

pub use error::{ConvertError, Result};

/// 将其他格式文件转换为 Markdown
///
/// 根据文件扩展名或内容自动检测文件类型并转换
pub fn to_markdown<P: AsRef<std::path::Path>>(path: P) -> Result<String> {
    to_markdown::convert(path)
}

/// 将 Markdown 转换为 DOCX 并保存
pub fn markdown_to_docx<P: AsRef<std::path::Path>>(
    save_path: P,
    markdown_str: &str,
) -> Result<()> {
    from_markdown::to_docx(save_path, markdown_str)
}
