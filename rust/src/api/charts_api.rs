pub fn new_line_chart(
    values: Vec<f32>,
    labels: Vec<String>,
    title: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
) -> Option<Vec<u8>> {
    crate::charts::new_line_chart(values, labels, title, width, height)
}

pub fn new_bar_chart(
    labels: Vec<String>,
    values: Vec<f32>,
    title: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
) -> Option<Vec<u8>> {
    crate::charts::new_bar_chart(labels, values, title, width, height)
}

pub fn new_graph_chart(
    value: String,
    title: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
) -> Option<Vec<u8>> {
    crate::charts::new_graph_chart(value, title, width, height)
}

pub fn new_mind_graph_chart(
    value: String,
    title: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
) -> Option<Vec<u8>> {
    crate::charts::new_mind_graph_chart(value, title, width, height)
}
