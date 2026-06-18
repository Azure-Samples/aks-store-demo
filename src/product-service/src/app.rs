use actix_cors::Cors;
use actix_web::dev::Server;
use actix_web::middleware::Logger;
use actix_web::{App, HttpServer, middleware, web};

use crate::config::Settings;
use crate::models::{ProductStore, seed_products};
use crate::routes::*;
use std::sync::RwLock;

pub struct AppState {
    pub store: RwLock<ProductStore>,
    pub settings: Settings,
    pub http_client: reqwest::Client,
    pub app_version: String,
}

pub fn run(mut settings: Settings) -> Result<Server, std::io::Error> {
    let store = ProductStore::new(seed_products());
    let listener = settings.tcp_listener()?;
    let port = listener.local_addr().unwrap().port();
    println!("Listening on http://0.0.0.0:{port}");

    let app_version = std::env::var("APP_VERSION").unwrap_or_else(|_| "0.1.0".into());

    let state = web::Data::new(AppState {
        store: RwLock::new(store),
        http_client: reqwest::Client::builder()
            .timeout(settings.ai_request_timeout)
            .build()
            .expect("Failed to build HTTP client"),
        settings,
        app_version,
    });

    let json_limit = 10 * 1024 * 1024;

    let server = HttpServer::new(move || {
        let json_cfg = web::JsonConfig::default().limit(json_limit);

        App::new()
            .wrap(Cors::permissive())
            .wrap(Logger::default())
            .wrap(Logger::new("%a %{User-Agent}i"))
            .wrap(middleware::DefaultHeaders::new().add(("X-Version", "0.2")))
            .app_data(state.clone())
            .app_data(json_cfg)
            .route("/health", web::get().to(health))
            .route("/health", web::head().to(health))
            .route("/ai/health", web::get().to(ai_health))
            .route("/ai/health", web::head().to(ai_health))
            .route("/ai/tuning/dataset", web::get().to(ai_tuning_dataset))
            .route(
                "/ai/generate/description",
                web::post().to(ai_generate_description),
            )
            .route("/ai/generate/image", web::post().to(ai_generate_image))
            .route("/metrics", web::get().to(get_metrics))
            .route("/import", web::post().to(add_products))
            .route("/{product_id}", web::get().to(get_product))
            .route("/", web::get().to(get_products))
            .route("/", web::post().to(add_product))
            .route("/", web::put().to(update_product))
            .route("/{product_id}", web::delete().to(delete_product))
    })
    .listen(listener)?
    .run();

    Ok(server)
}
