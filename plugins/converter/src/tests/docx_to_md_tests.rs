//! DOCX 转 Markdown 测试

#[allow(unused_imports)]
use crate::to_markdown::docx::DocxConverter;
#[allow(unused_imports)]
use crate::to_markdown::ToMarkdown;

/// 测试 DOCX 转换器存在
#[test]
fn test_docx_converter_exists() {
    // 验证转换器类型存在
    fn _check<T: crate::to_markdown::ToMarkdown>() {}
    _check::<DocxConverter>();
}

/// 测试不存在的文件
#[test]
fn test_nonexistent_file() {
    let result = DocxConverter::to_markdown("nonexistent.docx");
    assert!(result.is_err());
}

/// 测试真实 DOCX 文件转换
/// 运行: cargo test test_real_docx_to_markdown -- --nocapture
#[test]
fn test_real_docx_to_markdown() {
    let docx_path = "test.docx";
    
    if !std::path::Path::new(docx_path).exists() {
        println!("跳过测试: test.docx 不存在");
        return;
    }
    
    match DocxConverter::to_markdown(docx_path) {
        Ok(markdown) => {
            println!("\n========== DOCX 转换结果 ==========\n");
            println!("{}", markdown);
            println!("\n====================================\n");
            
            // 保存到文件
            let output_path = "test_docx_output.md";
            std::fs::write(output_path, &markdown).expect("写入文件失败");
            println!("已保存到: {}", output_path);
        }
        Err(e) => {
            panic!("DOCX 转换失败: {}", e);
        }
    }
}
