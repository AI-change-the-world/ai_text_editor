use std::fs::File;

use csv::ReaderBuilder;

use super::TToMarkdown;

pub struct CsvToMarkdown;

impl TToMarkdown for CsvToMarkdown {
    fn to_markdown(p: String) -> anyhow::Result<String> {
        let mut markdown = String::new();
        let mut rdr = ReaderBuilder::new()
            .has_headers(false)
            .from_reader(File::open(p)?);

        for result in rdr.records() {
            match result {
                Ok(record) => {
                    let rc: String = record
                        .iter()
                        .map(|s| s.as_ref())
                        .collect::<Vec<&str>>()
                        .join(",");
                    markdown.push_str(&rc);
                    markdown.push_str("\n");
                }
                Err(err) => {
                    markdown.push_str(&format!("{:?}\n", err));
                }
            }
        }

        Ok(markdown)
    }
}
