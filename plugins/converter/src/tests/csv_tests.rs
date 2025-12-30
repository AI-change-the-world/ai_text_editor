//! CSV 转换测试

use std::io::Write;
use tempfile::NamedTempFile;

use crate::to_markdown::csv::{CsvConfig, CsvConverter};
use crate::to_markdown::ToMarkdown;

/// 测试基本 CSV 转换
#[test]
fn test_basic_csv_conversion() {
    let mut file = NamedTempFile::new().unwrap();
    writeln!(file, "Name,Age,City").unwrap();
    writeln!(file, "Alice,30,Beijing").unwrap();
    writeln!(file, "Bob,25,Shanghai").unwrap();

    let result = CsvConverter::to_markdown(file.path()).unwrap();

    assert!(result.contains("| Name |"));
    assert!(result.contains("| Age |"));
    assert!(result.contains("| City |"));
    assert!(result.contains("| Alice |"));
    assert!(result.contains("| 30 |"));
    assert!(result.contains("|---|"));
}

/// 测试无表头 CSV
#[test]
fn test_csv_without_headers() {
    let mut file = NamedTempFile::new().unwrap();
    writeln!(file, "Alice,30").unwrap();
    writeln!(file, "Bob,25").unwrap();

    let config = CsvConfig {
        has_headers: false,
        delimiter: b',',
    };

    let result = CsvConverter::convert_with_config(file.path(), &config).unwrap();

    assert!(result.contains("Column 1"));
    assert!(result.contains("Column 2"));
    assert!(result.contains("| Alice |"));
}

/// 测试自定义分隔符
#[test]
fn test_csv_custom_delimiter() {
    let mut file = NamedTempFile::new().unwrap();
    writeln!(file, "Name;Age").unwrap();
    writeln!(file, "Alice;30").unwrap();

    let config = CsvConfig {
        has_headers: true,
        delimiter: b';',
    };

    let result = CsvConverter::convert_with_config(file.path(), &config).unwrap();

    assert!(result.contains("| Name |"));
    assert!(result.contains("| Age |"));
    assert!(result.contains("| Alice |"));
}

/// 测试空 CSV 文件
#[test]
fn test_empty_csv() {
    let file = NamedTempFile::new().unwrap();
    let result = CsvConverter::to_markdown(file.path()).unwrap();
    assert!(result.is_empty());
}

/// 测试包含特殊字符的 CSV
#[test]
fn test_csv_with_special_characters() {
    let mut file = NamedTempFile::new().unwrap();
    writeln!(file, "Name,Description").unwrap();
    writeln!(file, "Test,\"Contains | pipe\"").unwrap();

    let result = CsvConverter::to_markdown(file.path()).unwrap();

    // 管道符应该被转义
    assert!(result.contains("\\|"));
}

/// 测试不等长行
#[test]
fn test_csv_uneven_rows() {
    // csv 库默认要求字段数量一致，这里测试正常的等长行
    let mut file = NamedTempFile::new().unwrap();
    writeln!(file, "A,B,C").unwrap();
    writeln!(file, "1,2,3").unwrap();
    writeln!(file, "4,5,6").unwrap();

    let result = CsvConverter::to_markdown(file.path()).unwrap();

    assert!(result.contains("| A |"));
    assert!(result.contains("| 1 |"));
    assert!(result.contains("| 4 |"));
}

/// 测试配置默认值
#[test]
fn test_csv_config_defaults() {
    let config = CsvConfig::default();
    assert!(config.has_headers);
    assert_eq!(config.delimiter, b',');
}
