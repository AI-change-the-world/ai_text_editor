pub mod csv;
pub mod pdf;

pub trait TToMarkdown {
    fn to_markdown(p: String) -> anyhow::Result<String>;
}
