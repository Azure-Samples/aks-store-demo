use crate::app::AppState;
use actix_web::{Error, HttpResponse, ResponseError, web};
use futures_util::StreamExt;
use serde::Serialize;
use std::fmt;

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
    fn from(err: reqwest::Error) -> Self {
        Self(err)
    }
}

pub async fn ai_health(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let url = format!("{}/health", data.settings.ai_service_url);

    let resp = match data.http_client.get(&url).send().await {
        Ok(resp) => resp,
        Err(e) => return Ok(HttpResponse::InternalServerError().json(e.to_string())),
    };

    if resp.status().is_success() {
        let body_text = resp.text().await.map_err(ProxyError::from)?;
        Ok(HttpResponse::Ok().body(body_text))
    } else {
        Ok(HttpResponse::NotFound().body(""))
    }
}

async fn proxy_post(
    client: &reqwest::Client,
    base_url: &str,
    path: &str,
    payload: &mut web::Payload,
    max_payload: usize,
) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        if body.len() + chunk.len() > max_payload {
            return Ok(HttpResponse::PayloadTooLarge().json("Payload exceeds size limit"));
        }
        body.extend_from_slice(&chunk);
    }

    let url = format!("{base_url}{path}");

    let resp = match client
        .post(&url)
        .header("Content-Type", "application/json")
        .body(body.to_vec())
        .send()
        .await
    {
        Ok(resp) => resp,
        Err(e) => return Ok(HttpResponse::InternalServerError().json(e.to_string())),
    };

    let status = actix_web::http::StatusCode::from_u16(resp.status().as_u16())
        .unwrap_or(actix_web::http::StatusCode::INTERNAL_SERVER_ERROR);
    let body_text = resp.text().await.map_err(ProxyError::from)?;

    Ok(HttpResponse::build(status)
        .content_type("application/json")
        .body(body_text))
}

pub async fn ai_generate_description(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let max = data.settings.ai_max_payload;
    proxy_post(
        &data.http_client,
        &data.settings.ai_service_url,
        "/generate/description",
        &mut payload,
        max,
    )
    .await
}

pub async fn ai_generate_image(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let max = data.settings.ai_max_payload;
    proxy_post(
        &data.http_client,
        &data.settings.ai_service_url,
        "/generate/image",
        &mut payload,
        max,
    )
    .await
}

#[derive(Debug, Serialize)]
struct MessageList {
    messages: Vec<Message>,
}

#[derive(Debug, Serialize)]
struct Message {
    role: String,
    content: String,
}

#[derive(Debug, Clone)]
struct CustomerInteraction {
    question: &'static str,
    answer: &'static str,
}

const INTERACTIONS: &[CustomerInteraction] = &[
    CustomerInteraction {
        question: "Can you tell me about the {}?",
        answer: "The {name} is a high-quality product with excellent features. {description}",
    },
    CustomerInteraction {
        question: "What are the features of the {}?",
        answer: "The {name} is one of our best sellers. Customers love it! {description}",
    },
    CustomerInteraction {
        question: "How much does the {} cost?",
        answer: "The {name} is a popular choice for many customers. {description}",
    },
    CustomerInteraction {
        question: "Why should I buy the {}?",
        answer: "Our customers have rated the {name} highly for its quality. {description}",
    },
    CustomerInteraction {
        question: "What makes the {} special?",
        answer: "The {name} is a top-rated product known for its durability. {description}",
    },
    CustomerInteraction {
        question: "Is the {} worth buying?",
        answer: "The {name} is a must-have item. It's highly recommended. {description}",
    },
    CustomerInteraction {
        question: "What can you tell me about the {}?",
        answer: "The {name} is a premium product that offers great value. {description}",
    },
    CustomerInteraction {
        question: "Give me details about the {}.",
        answer: "Our customers can't get enough of the {name}. {description}",
    },
    CustomerInteraction {
        question: "What is the {} used for?",
        answer: "The {name} is a versatile product that meets various needs. {description}",
    },
    CustomerInteraction {
        question: "Describe the {}.",
        answer: "The {name} is a reliable product that won't disappoint. {description}",
    },
    CustomerInteraction {
        question: "What are the benefits of the {}?",
        answer: "The {name} is a top-of-the-line product that exceeds expectations. {description}",
    },
    CustomerInteraction {
        question: "How does the {} compare to other products?",
        answer: "The {name} is a customer favorite. It's highly rated. {description}",
    },
    CustomerInteraction {
        question: "Is the {} popular among customers?",
        answer: "The {name} is a top choice for customers looking for quality. {description}",
    },
    CustomerInteraction {
        question: "Can you provide more details about the {}?",
        answer: "The {name} is a well-loved product that has received great reviews. {description}",
    },
    CustomerInteraction {
        question: "What are the specifications of the {}?",
        answer: "The {name} is a top performer in its category. {description}",
    },
];

pub async fn ai_tuning_dataset(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let store = data
        .store
        .read()
        .map_err(|_| actix_web::error::ErrorInternalServerError("Lock poisoned"))?;
    let products = store.list();
    let mut response: Vec<MessageList> = Vec::with_capacity(products.len() * INTERACTIONS.len());

    for product in products.iter() {
        for interaction in INTERACTIONS {
            let question = interaction.question.replace("{}", &product.name);
            let answer = interaction
                .answer
                .replace("{name}", &product.name)
                .replace("{description}", &product.description);

            response.push(MessageList {
                messages: vec![
                    Message {
                        role: "user".into(),
                        content: question,
                    },
                    Message {
                        role: "assistant".into(),
                        content: answer,
                    },
                ],
            });
        }
    }

    Ok(HttpResponse::Ok().json(response))
}
