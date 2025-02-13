#[cfg(test)]
mod tests {
    use extractous::{Extractor, PdfParserConfig};

    #[test]
    fn test_read_file() {
        // Get the command-line arguments
        let file_path =
            "/Users/guchengxi/Desktop/projects/ai_text_editor/plugins/docx-converter/test.docx";

        // docx test
        // /Users/guchengxi/Desktop/projects/ai_text_editor/plugins/docx-converter/test.docx
        //
        // /Users/guchengxi/Desktop/projects/test.pdf

        // Extract the provided file content to a string
        let extractor = Extractor::new().set_pdf_config(
            PdfParserConfig::default().set_ocr_strategy(extractous::PdfOcrStrategy::NO_OCR),
        );
        // if you need an xml
        // extractor = extractor.set_xml_output(true);

        let (content, metadata) = extractor.extract_file_to_string(file_path).unwrap();
        println!("{}", content);
        println!("{:?}", metadata);
    }
}
