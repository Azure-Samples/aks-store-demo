use env_logger::Env;
use product_service::configuration::Settings;
use product_service::model::Product;
use product_service::startup::run;

#[ctor::ctor]
fn init() {
    env_logger::init_from_env(Env::default().default_filter_or("warn"));
}

pub fn spawn_app(enable_wasm: bool) -> String {
    let mut settings = Settings::new()
        .set_wasm_rules_engine(enable_wasm)
        .set_port(0);

    let listener = &settings.get_tcp_listener().expect("Failed to bind address");
    let port = listener.local_addr().unwrap().port();
    let app = run(settings).expect("Failed to bind address");
    let _ = actix_web::rt::spawn(app);
    format!("http://127.0.0.1:{}", port)
}

pub fn new_product() -> Product {
    Product {
        id: 0,
        name: "test".to_string(),
        price: 1.0,
        description: "test".to_string(),
        image: "test".to_string(),
    }
}

pub fn new_product_with_longer_description() -> Product {
    Product {
        id: 0,
        name: "test".to_string(),
        price: 1.0,
        description: "This is longer than 10 characters".to_string(),
        image: "test".to_string(),
    }
}

pub fn new_product_with_high_price() -> Product {
    Product {
        id: 0,
        name: "test".to_string(),
        price: 105.0,
        description: "This is longer than 10 characters".to_string(),
        image: "test".to_string(),
    }
}

pub async fn post_product(address: &str, product: &Product) -> reqwest::Response {
    let client = reqwest::Client::new();
    client.post(address).json(product).send().await.unwrap()
}

pub async fn get_products(address: &str) -> reqwest::Response {
    let client = reqwest::Client::new();
    client.get(address).send().await.unwrap()
}

pub async fn get_product(address: &str, id: i32) -> reqwest::Response {
    let client = reqwest::Client::new();
    client
        .get(format!("{}/{}", address, id))
        .send()
        .await
        .unwrap()
}

pub async fn delete_product(address: &str, id: i32) -> reqwest::Response {
    let client = reqwest::Client::new();
    client
        .delete(format!("{}/{}", address, id))
        .send()
        .await
        .unwrap()
}

pub async fn update_product(address: &str, product: &Product) -> reqwest::Response {
    let client = reqwest::Client::new();
    client.put(address).json(product).send().await.unwrap()
}

pub async fn get_health_check(address: &str) -> reqwest::Response {
    let client = reqwest::Client::new();
    client
        .get(format!("{}/health", address))
        .send()
        .await
        .unwrap()
}

pub async fn get_health_check_head(address: &str) -> reqwest::Response {
    let client = reqwest::Client::new();
    client
        .head(format!("{}/health", address))
        .send()
        .await
        .unwrap()
}

pub async fn get_ai_health_check_head(address: &str) -> reqwest::Response {
    let client = reqwest::Client::new();
    client
        .head(format!("{}/ai/health", address))
        .send()
        .await
        .unwrap()
}

pub async fn get_ai_health_check(address: &str) -> reqwest::Response {
    let client = reqwest::Client::new();
    client
        .get(format!("{}/ai/health", address))
        .send()
        .await
        .unwrap()
}
