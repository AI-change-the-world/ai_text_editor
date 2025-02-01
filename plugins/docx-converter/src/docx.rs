use docx_rs::{Docx, Style, StyleType};
use serde::de;

use crate::delta::{DeltaOperation, Insert};

pub fn delta_operation_list_to_docx(delta_list: Vec<DeltaOperation>) -> anyhow::Result<Docx> {
    let mut docx = Docx::new();
    delta_list
        .into_iter()
        .for_each(|delta_op| match delta_op.insert {
            Insert::Text(text) => {
                // docx.add_paragraph(
                //     docx_rs::Paragraph::new().add_run(docx_rs::Run::new().add_text(text)),
                // );
                docx = docx.clone().add_paragraph(
                    docx_rs::Paragraph::new().add_run(docx_rs::Run::new().add_text(text)),
                );
            }
            _ => {}
        });

    anyhow::bail!("not implemented")
}

// fn delta_to_style(delta_op: DeltaOperation) -> anyhow::Result<Style> {
//     // let d = delta_op.insert;
//     let att = delta_op.attributes.unwrap();
//     let mut s = Style::new("Run1", StyleType::Character);
//     if att.header.is_some() {
//         s = s.style("Heading1");
//     } else if att.bold.is_some() {
//         s = s.bold();
//     } else if att.italic.is_some() {
//         s = s.italic();
//     }

//     match delta_op.insert {
//         Insert::Text(e) => s = s.name(e),
//         Insert::Object { divider } => anyhow::bail!("not implemented"),
//     }
//     return Ok(s);
// }

enum DocxElement {
    Paragraph(docx_rs::Paragraph),
    Run(docx_rs::Run),
    Style(Style),
}

fn delta_to_docx_element(delta_op: DeltaOperation) -> anyhow::Result<DocxElement> {
    match delta_op.insert {
        Insert::Text(e) => {
            // let mut s = docx_rs::Run::new();
        }
        Insert::Object { divider: _ } => {
            return Ok(DocxElement::Paragraph(
                docx_rs::Paragraph::new()
                    .add_run(docx_rs::Run::new().add_text("_________________")),
            ));
        }
    }

    anyhow::bail!("not implemented")
}
