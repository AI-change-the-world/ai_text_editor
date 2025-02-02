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

pub fn parse_json_to_delta_list(json_str: &str) -> anyhow::Result<Vec<DeltaOperation>> {
    let data: Value = serde_json::from_str(json_str)?;
    let arr = data.as_array();
    if let Some(arr) = arr {
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
        return Ok(operations);
    }

    anyhow::bail!("Not a valid JSON array");
}
