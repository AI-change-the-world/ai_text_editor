#[cfg(test)]
mod tests {

    use serde::{Deserialize, Serialize};
    use serde_json::Value;

    /// 表示每个 Delta 操作的 insert 字段，可以是一个字符串或一个对象（例如 divider）
    #[derive(Debug, Serialize, Deserialize)]
    #[serde(untagged)]
    pub enum Insert {
        Text(String),
        Object { divider: String },
    }

    /// 表示 Delta 操作中的 attributes 字段
    #[derive(Debug, Serialize, Deserialize)]
    pub struct Attributes {
        /// 例如 header 的值为数字（如 2、3）
        #[serde(skip_serializing_if = "Option::is_none")]
        pub header: Option<u32>,

        /// 例如 bold: true
        #[serde(skip_serializing_if = "Option::is_none")]
        pub bold: Option<bool>,

        /// 例如 italic: true
        #[serde(skip_serializing_if = "Option::is_none")]
        pub italic: Option<bool>,

        /// 例如 list: "bullet" 或 "ordered"
        #[serde(skip_serializing_if = "Option::is_none")]
        pub list: Option<String>,

        /// 例如 link: "https://www.example.com"
        #[serde(skip_serializing_if = "Option::is_none")]
        pub link: Option<String>,

        /// 例如 indent: 1
        #[serde(skip_serializing_if = "Option::is_none")]
        pub indent: Option<u32>,
    }

    /// 表示 JSON 中的每个操作项
    #[derive(Debug, Serialize, Deserialize)]
    pub struct DeltaOperation {
        pub insert: Insert,

        /// attributes 字段是可选的
        #[serde(skip_serializing_if = "Option::is_none")]
        pub attributes: Option<Attributes>,
    }

    #[test]
    fn main() -> anyhow::Result<()> {
        // 示例 JSON 数据
        let json_data = r#"
    [
        {"insert":"ChatGPT Response"},
        {"insert":"\n","attributes":{"header":2}},
        {"insert":{"divider":"hr"}},
        {"insert":"\nWelcome to ChatGPT! Below is an example of a response with Markdown and LaTeX code:\nMarkdown Example"},
        {"insert":"\n","attributes":{"header":3}},
        {"insert":"You can use Markdown to format text easily. Here are some examples:\n"},
        {"insert":"Bold Text","attributes":{"bold":true}},
        {"insert":": "},
        {"insert":"This text is bold","attributes":{"bold":true}},
        {"insert":"\n","attributes":{"list":"bullet"}},
        {"insert":"Italic Text","attributes":{"italic":true}},
        {"insert":": "},
        {"insert":"This text is italicized","attributes":{"italic":true}},
        {"insert":"\n","attributes":{"list":"bullet"}},
        {"insert":"Link","attributes":{"link":"https://www.example.com"}},
        {"insert":": "},
        {"insert":"This is a link","attributes":{"link":"https://www.example.com"}},
        {"insert":"\n","attributes":{"list":"bullet"}},
        {"insert":"Lists:"},
        {"insert":"\n","attributes":{"list":"bullet"}},
        {"insert":"Item 1"},
        {"insert":"\n","attributes":{"indent":1,"list":"ordered"}},
        {"insert":"Item 2"},
        {"insert":"\n","attributes":{"indent":1,"list":"ordered"}},
        {"insert":"Item 3"},
        {"insert":"\n","attributes":{"indent":1,"list":"ordered"}},
        {"insert":"LaTeX Example"},
        {"insert":"\n","attributes":{"header":3}},
        {"insert":"You can also use LaTeX for mathematical expressions. Here's an example:\n"},
        {"insert":"Equation","attributes":{"bold":true}},
        {"insert":": ( f(x) = x^2 + 2x + 1 )"},
        {"insert":"\n","attributes":{"list":"bullet"}},
        {"insert":"Integral","attributes":{"bold":true}},
        {"insert":": ( int_{0}^{1} x^2 , dx )"},
        {"insert":"\n","attributes":{"list":"bullet"}},
        {"insert":"Matrix","attributes":{"bold":true}},
        {"insert":":"},
        {"insert":"\n","attributes":{"list":"bullet"}},
        {"insert":"[ \\begin{bmatrix} 1 & 2 & 3 \\n4 & 5 & 6 \\n7 & 8 & 9 \\end{bmatrix} ]"},
        {"insert":"\nConclusion"},
        {"insert":"\n","attributes":{"header":3}},
        {"insert":"Markdown and LaTeX can be powerful tools for formatting text and mathematical expressions in your Flutter app. If you have any questions or need further assistance, feel free to ask!\n"}
    ]
    "#;

        // 先将整个 JSON 解析为 serde_json::Value
        let data: Value = serde_json::from_str(json_data)?;

        // 假设最外层是一个数组
        let arr = data.as_array().unwrap();

        // 存放成功解析的元素
        let mut operations = Vec::new();

        for (index, item) in arr.iter().enumerate() {
            match serde_json::from_value::<DeltaOperation>(item.clone()) {
                Ok(op) => {
                    operations.push(op);
                }
                Err(e) => {
                    eprintln!("第 {} 个元素解析失败: {}", index, e);
                    // 遇到错误时直接忽略该元素，继续处理后续元素
                    continue;
                }
            }
        }

        // 打印成功解析的元素
        for op in operations {
            println!("{:#?}", op);
        }

        Ok(())
    }

    #[test]
    fn test_doc() -> anyhow::Result<()> {
        let doc = crate::from_other_file::convert_to_markdown(
            "/Users/guchengxi/Desktop/projects/ai_text_editor/plugins/converter/style.docx"
                .to_string(),
        )?;
        println!("{}", doc);
        anyhow::Ok(())
    }
}
