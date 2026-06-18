use env_logger::Env;
use product_service::app::run;
use product_service::config::Settings;
use product_service::models::Product;
use reqwest::Client;

#[ctor::ctor]
fn init() {
    env_logger::init_from_env(Env::default().default_filter_or("warn"));
}

pub fn spawn_app() -> String {
    let mut settings = Settings::default().with_port(0);

    let listener = &settings.tcp_listener().expect("Failed to bind address");
    let port = listener.local_addr().unwrap().port();
    let app = run(settings).expect("Failed to bind address");
    let _ = actix_web::rt::spawn(app);
    format!("http://127.0.0.1:{port}")
}

pub fn new_product() -> Product {
    Product {
        id: 0,
        name: "Test Widget".into(),
        price: 9.99,
        description: "A great test product".into(),
        image: "/test.jpg".into(),
    }
}

pub fn client() -> Client {
    Client::new()
}

pub async fn post_product(address: &str, product: &Product) -> reqwest::Response {
    client().post(address).json(product).send().await.unwrap()
}

pub async fn get_products(address: &str) -> reqwest::Response {
    client().get(address).send().await.unwrap()
}

pub async fn get_product(address: &str, id: i32) -> reqwest::Response {
    client()
        .get(format!("{address}/{id}"))
        .send()
        .await
        .unwrap()
}

pub async fn delete_product(address: &str, id: i32) -> reqwest::Response {
    client()
        .delete(format!("{address}/{id}"))
        .send()
        .await
        .unwrap()
}

pub async fn update_product(address: &str, product: &Product) -> reqwest::Response {
    client().put(address).json(product).send().await.unwrap()
}

pub async fn get_health_check(address: &str) -> reqwest::Response {
    client()
        .get(format!("{address}/health"))
        .send()
        .await
        .unwrap()
}

pub async fn get_health_check_head(address: &str) -> reqwest::Response {
    client()
        .head(format!("{address}/health"))
        .send()
        .await
        .unwrap()
}

pub async fn get_ai_health_check_head(address: &str) -> reqwest::Response {
    client()
        .head(format!("{address}/ai/health"))
        .send()
        .await
        .unwrap()
}

pub async fn get_ai_health_check(address: &str) -> reqwest::Response {
    client()
        .get(format!("{address}/ai/health"))
        .send()
        .await
        .unwrap()
}
