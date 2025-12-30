//! 将各种格式转换为 Markdown
//!
//! 支持的格式:
//! - PDF (基于 pdfium-render)
//! - CSV
//! - DOCX (基于 docx-rs)

pub mod csv;
pub mod docx;
pub mod pdf;

use std::path::Path;

use crate::error::{ConvertError, Result};

/// 转换器 trait
pub trait ToMarkdown {
    /// 将文件转换为 Markdown 字符串
    fn to_markdown<P: AsRef<Path>>(path: P) -> Result<String>;
}

/// 根据文件类型自动选择转换器
pub fn convert<P: AsRef<Path>>(path: P) -> Result<String> {
    let path = path.as_ref();
    
    if !path.exists() {
        return Err(ConvertError::FileNotFound(path.display().to_string()));
    }

    // 优先通过扩展名判断
    if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
        match ext.to_lowercase().as_str() {
            "pdf" => return pdf::PdfConverter::to_markdown(path),
            "csv" => return csv::CsvConverter::to_markdown(path),
            "docx" => return docx::DocxConverter::to_markdown(path),
            _ => {}
        }
    }

    // 通过文件内容推断类型
    let kind = infer::get_from_path(path)
        .map_err(|e| ConvertError::IoError(e))?;

    match kind {
        Some(k) => match k.extension() {
            "pdf" => pdf::PdfConverter::to_markdown(path),
            "docx" => docx::DocxConverter::to_markdown(path),
            _ => Err(ConvertError::UnsupportedFormat(k.extension().to_string())),
        },
        None => Err(ConvertError::UnknownFormat),
    }
}
