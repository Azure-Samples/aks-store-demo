use env_logger::Env;
use product_service::{app::run, config::Settings};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let settings = Settings::default();
    env_logger::init_from_env(Env::default().default_filter_or(&settings.log_level));
    run(settings)?.await
}
