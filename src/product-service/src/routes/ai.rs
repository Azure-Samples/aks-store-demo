//////////////////////////
// Proxy for AI service
//////////////////////////

use std::collections::HashMap;
use std::fmt;
use actix_web::{web, Error, HttpResponse, ResponseError};
use crate::startup::AppState;
use futures_util::StreamExt;

#[derive(Debug)]
pub struct ProxyError(reqwest::Error);

impl fmt::Display for ProxyError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl ResponseError for ProxyError {
    fn error_response(&self) -> HttpResponse {
        HttpResponse::InternalServerError().json(self.0.to_string())
    }
}

impl From<reqwest::Error> for ProxyError {
    fn from(err: reqwest::Error) -> ProxyError {
        ProxyError(err)
    }
}

pub async fn ai_health(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.get(ai_service_url + "/health").send().await {
        Ok(resp) => resp,
        Err(e) => {
            return Ok(HttpResponse::InternalServerError().json(e.to_string()))
        }
    };
    let status = resp.status();
    if status.is_success() {
        let body_text = resp.text().await.map_err(ProxyError::from)?;
        Ok(HttpResponse::Ok().body(body_text))
    } else {
        Ok(HttpResponse::build(actix_web::http::StatusCode::NOT_FOUND).body(""))
    }
}

pub async fn ai_generate_description(data: web::Data<AppState>, mut payload: web::Payload) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.post( ai_service_url + "/generate/description")
    .body(body.to_vec())
    .send()
    .await {
        Ok(resp) => resp,
        Err(e) => {
            return Ok(HttpResponse::InternalServerError().json(e.to_string()))
        }
    };

    let status = resp.status();
    let body: HashMap<String, String> = resp.json().await.map_err(ProxyError::from)?;
    let body_json = serde_json::to_string(&body).unwrap();
    if status.is_success() {
        Ok(HttpResponse::Ok().body(body_json))
    } else {
        Ok(HttpResponse::build(actix_web::http::StatusCode::INTERNAL_SERVER_ERROR).body(body_json))
    }
}

pub async fn ai_generate_image(data: web::Data<AppState>, mut payload: web::Payload) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.post( ai_service_url + "/generate/image")
    .body(body.to_vec())
    .send()
    .await {
        Ok(resp) => resp,
        Err(e) => {
            return Ok(HttpResponse::InternalServerError().json(e.to_string()))
        }
    };

    let status = resp.status();
    let body: HashMap<String, String> = resp.json().await.map_err(ProxyError::from)?;
    let body_json = serde_json::to_string(&body).unwrap();
    if status.is_success() {
        Ok(HttpResponse::Ok().body(body_json))
    } else {
        Ok(HttpResponse::build(actix_web::http::StatusCode::INTERNAL_SERVER_ERROR).body(body_json))
    }
}