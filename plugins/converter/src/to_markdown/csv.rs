//! CSV 转 Markdown 转换器

use std::fs::File;
use std::path::Path;

use csv::ReaderBuilder;

use super::ToMarkdown;
use crate::error::Result;

/// CSV 转换器配置
#[derive(Debug, Clone)]
pub struct CsvConfig {
    /// 是否将第一行作为表头
    pub has_headers: bool,
    /// 分隔符
    pub delimiter: u8,
}

impl Default for CsvConfig {
    fn default() -> Self {
        Self {
            has_headers: true,
            delimiter: b',',
        }
    }
}

/// CSV 转换器
pub struct CsvConverter;

impl ToMarkdown for CsvConverter {
    fn to_markdown<P: AsRef<Path>>(path: P) -> Result<String> {
        Self::convert_with_config(path, &CsvConfig::default())
    }
}

impl CsvConverter {
    /// 使用自定义配置转换
    pub fn convert_with_config<P: AsRef<Path>>(path: P, config: &CsvConfig) -> Result<String> {
        let file = File::open(path.as_ref())?;
        let mut rdr = ReaderBuilder::new()
            .has_headers(false) // 我们手动处理表头
            .delimiter(config.delimiter)
            .from_reader(file);

        let mut records: Vec<Vec<String>> = Vec::new();
        
        for result in rdr.records() {
            let record = result?;
            let row: Vec<String> = record.iter().map(|s| s.to_string()).collect();
            records.push(row);
        }

        if records.is_empty() {
            return Ok(String::new());
        }

        Ok(records_to_markdown_table(&records, config.has_headers))
    }
}

/// 将记录转换为 Markdown 表格
fn records_to_markdown_table(records: &[Vec<String>], has_headers: bool) -> String {
    if records.is_empty() {
        return String::new();
    }

    let col_count = records.iter().map(|r| r.len()).max().unwrap_or(0);
    if col_count == 0 {
        return String::new();
    }

    let mut result = String::new();

    // 表头
    let header_row = if has_headers {
        &records[0]
    } else {
        // 生成默认表头
        &(0..col_count).map(|i| format!("Column {}", i + 1)).collect::<Vec<_>>()
    };

    result.push('|');
    for (i, cell) in header_row.iter().enumerate() {
        result.push_str(&escape_markdown_table_cell(cell));
        result.push('|');
        if i >= col_count - 1 {
            break;
        }
    }
    // 补齐缺失的列
    for _ in header_row.len()..col_count {
        result.push_str(" |");
    }
    result.push('\n');

    // 分隔行
    result.push('|');
    for _ in 0..col_count {
        result.push_str("---|");
    }
    result.push('\n');

    // 数据行
    let data_start = if has_headers { 1 } else { 0 };
    for row in records.iter().skip(data_start) {
        result.push('|');
        for i in 0..col_count {
            let cell = row.get(i).map(|s| s.as_str()).unwrap_or("");
            result.push_str(&escape_markdown_table_cell(cell));
            result.push('|');
        }
        result.push('\n');
    }

    result.trim_end().to_string()
}

/// 转义 Markdown 表格单元格中的特殊字符
fn escape_markdown_table_cell(text: &str) -> String {
    let escaped = text
        .replace('|', "\\|")
        .replace('\n', " ")
        .replace('\r', "");
    format!(" {} ", escaped.trim())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_records_to_markdown_table_with_headers() {
        let records = vec![
            vec!["Name".to_string(), "Age".to_string()],
            vec!["Alice".to_string(), "30".to_string()],
            vec!["Bob".to_string(), "25".to_string()],
        ];

        let result = records_to_markdown_table(&records, true);
        assert!(result.contains("| Name |"));
        assert!(result.contains("| Alice |"));
        assert!(result.contains("|---|"));
    }

    #[test]
    fn test_records_to_markdown_table_without_headers() {
        let records = vec![
            vec!["Alice".to_string(), "30".to_string()],
            vec!["Bob".to_string(), "25".to_string()],
        ];

        let result = records_to_markdown_table(&records, false);
        assert!(result.contains("Column 1"));
        assert!(result.contains("| Alice |"));
    }

    #[test]
    fn test_escape_markdown_table_cell() {
        assert_eq!(escape_markdown_table_cell("hello"), " hello ");
        assert_eq!(escape_markdown_table_cell("a|b"), " a\\|b ");
        assert_eq!(escape_markdown_table_cell("line1\nline2"), " line1 line2 ");
    }

    #[test]
    fn test_empty_records() {
        let records: Vec<Vec<String>> = vec![];
        assert_eq!(records_to_markdown_table(&records, true), "");
    }
}
