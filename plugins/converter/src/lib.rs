mod delta;
mod docx;
mod docx_to_markdown;
mod markdown_to_docx;
mod test;

pub fn convert_markdown_to_docx(save_path: String, markdown_str: String) -> anyhow::Result<()> {
    let docx = markdown_to_docx::markdown_to_docx(&markdown_str)?;
    let f = std::fs::File::create(save_path)?;
    docx.build().pack(f)?;
    Ok(())
}
