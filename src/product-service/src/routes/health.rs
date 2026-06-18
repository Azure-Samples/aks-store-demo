use crate::app::AppState;
use actix_web::{HttpResponse, web};
use serde_json::json;

pub async fn health(data: web::Data<AppState>) -> HttpResponse {
    let health = json!({"status": "ok", "version": data.app_version});
    HttpResponse::Ok().json(health)
}
