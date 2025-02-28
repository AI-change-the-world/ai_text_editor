use chart_core::{
    charts::{bar_chart::BarChartData, graph_chart::GraphChartData, line_chart::LineChartData},
    compose,
    config::OutputFormat,
};

pub fn new_line_chart(
    values: Vec<f32>,
    labels: Vec<String>,
    title: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
) -> Option<Vec<u8>> {
    let line_data = LineChartData {
        x: labels,
        y: values,
    };

    let r = compose(
        "line".to_string(),
        title.unwrap_or("".to_owned()),
        line_data,
        width,
        height,
        Some(OutputFormat::Png),
    );
    match r {
        Ok(_r) => Some(_r),
        Err(_e) => {
            println!("Error: {}", _e);
            None
        }
    }
}

pub fn new_bar_chart(
    labels: Vec<String>,
    values: Vec<f32>,
    title: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
) -> Option<Vec<u8>> {
    let bar_data = BarChartData {
        x: labels,
        y: values,
    };

    let r = compose(
        "bar".to_string(),
        title.unwrap_or("".to_owned()),
        bar_data,
        width,
        height,
        Some(OutputFormat::Png),
    );

    match r {
        Ok(_r) => Some(_r),
        Err(_e) => {
            println!("Error: {}", _e);
            None
        }
    }
}

pub fn new_graph_chart(
    value: String,
    title: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
) -> Option<Vec<u8>> {
    let r = compose(
        "graph".to_owned(),
        title.unwrap_or("".to_owned()),
        GraphChartData { data: value },
        width,
        height,
        Some(OutputFormat::Png),
    );

    match r {
        Ok(_r) => Some(_r),
        Err(_e) => {
            println!("Error: {}", _e);
            None
        }
    }
}
