use crate::messages::send_message;

pub fn markdown_to_docx(markdown_text: String, filepath: String) {
    let r = converter::markdown_to_docx(filepath.clone(), &markdown_text);
    match r {
        Ok(_) => {
            send_message(
                format!("File saved to {}", filepath),
                crate::messages::MessageType::Success,
            );
        }
        Err(e) => {
            println!("Error: {}", e);
            send_message(format!("Error: {}", e), crate::messages::MessageType::Error);
        }
    }
}

pub fn other_type_to_markdown(file_path: String) -> Option<String> {
    todo!()
}
