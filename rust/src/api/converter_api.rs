use converter::convert_markdown_to_docx;

use crate::messages::send_message;

pub fn markdown_to_docx(markdown_text: String, filepath: String) {
    let r = convert_markdown_to_docx(filepath.clone(), markdown_text);
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

// pub fn other_type_to_markdown(file_path: String) -> Option<String> {
//     let r = converter::convert_other_type_to_markdown(file_path);
//     match r {
//         Ok(_r) => Some(_r),
//         Err(_e) => {
//             println!("[rust] Error: {}", _e);
//             return None;
//         }
//     }
// }
