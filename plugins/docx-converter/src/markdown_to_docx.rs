use docx_rs::{Docx, Hyperlink, HyperlinkType, Paragraph, Run};
use once_cell::sync::Lazy;
use regex::Regex;

static BOLD_REG: Lazy<regex::Regex> = Lazy::new(|| Regex::new(r"\*{2}(.*?)\*{2}").unwrap());
static ITALIC_REG: Lazy<regex::Regex> = Lazy::new(|| Regex::new(r"\*{1}(.*?)\*{1}").unwrap());
static STRICK_THROUGH_REG: Lazy<regex::Regex> = Lazy::new(|| Regex::new(r"~~(.*?)~~").unwrap());

struct RegMapper {
    reg: Regex,
    style: String,
}

static REG_MAPPER_LIST: Lazy<Vec<RegMapper>> = Lazy::new(|| {
    vec![
        RegMapper {
            reg: BOLD_REG.clone(),
            style: "bold".to_string(),
        },
        RegMapper {
            reg: ITALIC_REG.clone(),
            style: "italic".to_string(),
        },
        RegMapper {
            reg: STRICK_THROUGH_REG.clone(),
            style: "strikethrough".to_string(),
        },
    ]
});

fn add_markdown(docx: Docx, text: &str) -> Docx {
    let mut paragraph = Paragraph::new();
    // TODO : 暂时不支持列表格式
    let mut text = text.trim_start_matches("- ");
    text = text.trim();
    if text.starts_with("#") {
        // title
        let run;
        if text.starts_with("#") {
            // style = Style::new("Heading1", docx_rs::StyleType::Paragraph)
            //     .name(text.trim_start_matches("#"));
            run = Run::new()
                .add_text(text.trim_start_matches("#"))
                .size(48)
                .style("Heading1");
        } else if text.starts_with("##") {
            run = Run::new()
                .add_text(text.trim_start_matches("##"))
                .size(24)
                .style("Heading2");
        } else if text.starts_with("###") {
            run = Run::new()
                .add_text(text.trim_start_matches("###"))
                .size(18)
                .style("Heading3");
        } else {
            run = Run::new().add_text(text);
        }
        paragraph = paragraph.add_run(run);
    }
    // 简单解析 Markdown
    else if text.contains("*") || text.contains("~~") {
        let r = parse_with_attributes(text);
        for (attr, text) in r {
            let mut run = Run::new();
            match attr.as_str() {
                "bold" => run = run.add_text(text).bold(),
                "italic" => run = run.add_text(text).italic(),
                _ => run = run.add_text(text),
            }
            paragraph = paragraph.add_run(run);
        }
    } else if text.contains("[") && text.contains("]") && text.contains("(") && text.contains(")") {
        // 链接
        // TODO
        let link_text = text.split('[').nth(1).unwrap().split(']').next().unwrap();
        let link_url = text.split('(').nth(1).unwrap().split(')').next().unwrap();
        // let run = Run::new().add_text(Link::new(link_url, link_text));
        paragraph = paragraph.add_hyperlink(
            Hyperlink::new(link_url, HyperlinkType::External)
                .add_run(Run::new().add_text(link_text)),
        );
    } else {
        // 普通文本
        let run = Run::new().add_text(text);
        paragraph = paragraph.add_run(run);
    }

    docx.add_paragraph(paragraph)
}

fn parse_with_attributes(text: &str) -> Vec<(String, String)> {
    let mut result = vec![];

    // 当前处理的字符串起始位置
    let mut current_pos = 0;

    // 遍历字符串
    while current_pos < text.len() {
        let mut matched = false;

        // 尝试匹配每一个正则表达式
        for rm in &*REG_MAPPER_LIST {
            if let Some(cap) = rm.reg.captures(&text[current_pos..]) {
                // 获取匹配的起始和结束位置
                let start = cap.get(0).unwrap().start();
                let end = cap.get(0).unwrap().end();

                // 如果匹配的起始位置之前有非匹配内容，先存储非匹配内容
                if start > 0 {
                    result.push((
                        "Plain".to_string(),
                        text[current_pos..current_pos + start].to_string(),
                    ));
                }

                // 存储匹配的内容
                result.push((rm.style.clone(), cap[1].to_string()));

                // 更新当前处理的字符串位置
                current_pos += end;
                matched = true;
                break;
            }
        }

        // 如果没有匹配到任何正则表达式，则将当前字符作为非匹配内容存储
        if !matched {
            result.push((
                "Plain".to_string(),
                text[current_pos..current_pos + 1].to_string(),
            ));
            current_pos += 1;
        }
    }

    result
}

pub fn markdown_to_docx(markdown_str: &str) -> anyhow::Result<Docx> {
    let mut docx = Docx::new();

    for line in markdown_str.lines() {
        println!("line: {}", line);
        docx = add_markdown(docx.clone(), line);
    }

    Ok(docx)
}
