mod delta;
mod docx;
mod docx_to_markdown;
mod from_other_file;
mod markdown_to_docx;
mod test;
mod to_markdown;

pub fn convert_markdown_to_docx(save_path: String, markdown_str: String) -> anyhow::Result<()> {
    let docx = markdown_to_docx::markdown_to_docx(&markdown_str)?;
    let f = std::fs::File::create(save_path)?;
    docx.build().pack(f)?;
    Ok(())
}

pub fn convert_other_type_to_markdown(file_path: String) -> anyhow::Result<String> {
    let docx = from_other_file::convert_to_markdown(file_path)?;
    Ok(docx)
}
