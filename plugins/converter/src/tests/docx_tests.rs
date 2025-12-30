//! DOCX 转换测试

use crate::from_markdown::docx::MarkdownToDocx;

/// 测试基本 Markdown 转换
#[test]
fn test_basic_markdown_conversion() {
    let markdown = "Hello World";
    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试标题转换
#[test]
fn test_heading_conversion() {
    let markdown = r#"# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6"#;

    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试粗体和斜体
#[test]
fn test_bold_italic_conversion() {
    let markdown = r#"This is **bold** text.
This is *italic* text.
This is ***bold and italic*** text."#;

    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试删除线
#[test]
fn test_strikethrough_conversion() {
    let markdown = "This is ~~deleted~~ text.";
    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试链接
#[test]
fn test_link_conversion() {
    let markdown = "Visit [Example](https://example.com) for more info.";
    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试列表
#[test]
fn test_list_conversion() {
    let markdown = r#"- Item 1
- Item 2
- Item 3

1. First
2. Second
3. Third"#;

    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试混合格式
#[test]
fn test_mixed_formatting() {
    let markdown = r#"# Document Title

This is a paragraph with **bold**, *italic*, and ***both***.

## Section 1

Here's a [link](https://example.com) and some ~~strikethrough~~ text.

### Subsection

- List item with **bold**
- List item with *italic*"#;

    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试空文档
#[test]
fn test_empty_document() {
    let markdown = "";
    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试只有空行的文档
#[test]
fn test_whitespace_only_document() {
    let markdown = "   \n\n   \n";
    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试中文内容
#[test]
fn test_chinese_content() {
    let markdown = r#"# 中文标题

这是一段**粗体**和*斜体*的中文文本。

## 第二节

- 列表项一
- 列表项二"#;

    let result = MarkdownToDocx::convert(markdown);
    assert!(result.is_ok());
}

/// 测试保存到文件
#[test]
fn test_save_to_file() {
    use tempfile::NamedTempFile;

    let markdown = "# Test Document\n\nHello World!";
    let file = NamedTempFile::new().unwrap();
    let path = file.path().with_extension("docx");

    let result = MarkdownToDocx::convert_and_save(&path, markdown);
    assert!(result.is_ok());
    assert!(path.exists());

    // 清理
    std::fs::remove_file(path).ok();
}
