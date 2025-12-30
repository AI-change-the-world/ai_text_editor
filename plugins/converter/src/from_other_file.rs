use crate::to_markdown::{csv::CsvToMarkdown, pdf::PdfToMarkdown, TToMarkdown};

pub fn convert_to_markdown(s: String) -> anyhow::Result<String> {
    let kind = infer::get_from_path(s.clone())?;
    let mut result: Option<String> = None;
    match kind {
        Some(k) => match k.extension() {
            "csv" => {
                result = Some(CsvToMarkdown::to_markdown(s)?);
            }
            "pdf" => {
                result = Some(PdfToMarkdown::to_markdown(s)?);
            }
            _ => anyhow::bail!("unsupported type: {}", k.extension()),
        },
        None => {
            anyhow::bail!("unknow file type")
        }
    }

    match result {
        Some(r) => {
            return anyhow::Ok(r);
        }
        None => anyhow::Ok("".to_owned()),
    }
}
