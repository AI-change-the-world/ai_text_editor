//! 错误类型定义

use thiserror::Error;

/// 转换错误类型
#[derive(Error, Debug)]
pub enum ConvertError {
    #[error("不支持的文件类型: {0}")]
    UnsupportedFormat(String),

    #[error("无法识别文件类型")]
    UnknownFormat,

    #[error("文件不存在: {0}")]
    FileNotFound(String),

    #[error("PDF 处理错误: {0}")]
    PdfError(String),

    #[error("DOCX 处理错误: {0}")]
    DocxError(String),

    #[error("CSV 处理错误: {0}")]
    CsvError(String),

    #[error("IO 错误: {0}")]
    IoError(#[from] std::io::Error),

    #[error("其他错误: {0}")]
    Other(String),
}

pub type Result<T> = std::result::Result<T, ConvertError>;

impl From<csv::Error> for ConvertError {
    fn from(e: csv::Error) -> Self {
        ConvertError::CsvError(e.to_string())
    }
}
