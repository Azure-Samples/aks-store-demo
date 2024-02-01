use product_service::{
    configuration::Settings,
    startup::run
};
use env_logger::Env;

#[actix_web::main]
async fn main() -> std::io::Result<()> {

    let settings = Settings::new()
        .set_wasm_rules_engine(false);
    env_logger::init_from_env(Env::default().default_filter_or(&settings.log_level));
    run(settings)?.await
}
