pub mod csv;

pub trait TToMarkdown {
    fn to_markdown(p: String) -> anyhow::Result<String>;
}
