//////////////////////////
// Proxy for AI service
//////////////////////////

use crate::startup::AppState;
use actix_web::{web, Error, HttpResponse, ResponseError};
use futures_util::StreamExt;
use serde::Serialize;
use std::collections::HashMap;
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
    fn from(err: reqwest::Error) -> ProxyError {
        ProxyError(err)
    }
}

pub async fn ai_health(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.get(ai_service_url + "/health").send().await {
        Ok(resp) => resp,
        Err(e) => return Ok(HttpResponse::InternalServerError().json(e.to_string())),
    };
    let status = resp.status();
    if status.is_success() {
        let body_text = resp.text().await.map_err(ProxyError::from)?;
        Ok(HttpResponse::Ok().body(body_text))
    } else {
        Ok(HttpResponse::build(actix_web::http::StatusCode::NOT_FOUND).body(""))
    }
}

pub async fn ai_generate_description(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client
        .post(ai_service_url + "/generate/description")
        .body(body.to_vec())
        .send()
        .await
    {
        Ok(resp) => resp,
        Err(e) => return Ok(HttpResponse::InternalServerError().json(e.to_string())),
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

pub async fn ai_generate_image(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client
        .post(ai_service_url + "/generate/image")
        .body(body.to_vec())
        .send()
        .await
    {
        Ok(resp) => resp,
        Err(e) => return Ok(HttpResponse::InternalServerError().json(e.to_string())),
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

// The section below generates an input dataset of customer interactions for model tuning with KAITO
// The format for this dataset will be converted to parquet and meets the requirements of KAITO as documented here:
// https://github.com/kaito-project/kaito/blob/main/docs/tuning/README.md#input-dataset-format

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
    question: String,
    answer: String,
}
pub async fn ai_tuning_dataset(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let customer_interactions: Vec<CustomerInteraction> = vec![
        CustomerInteraction {
            question: "Can you tell me about the {}?".to_string(),
            answer: "The {name} is a high-quality product with excellent features. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "What are the features of the {}?".to_string(),
            answer: "The {name} is one of our best sellers. Customers love it! {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "How much does the {} cost?".to_string(),
            answer: "The {name} is a popular choice for many customers. {description}".to_string(),
        },
        CustomerInteraction {
            question: "Why should I buy the {}?".to_string(),
            answer: "Our customers have rated the {name} highly for its quality. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "What makes the {} special?".to_string(),
            answer: "The {name} is a top-rated product known for its durability. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "Is the {} worth buying?".to_string(),
            answer: "The {name} is a must-have item. It's highly recommended. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "What can you tell me about the {}?".to_string(),
            answer: "The {name} is a premium product that offers great value. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "Give me details about the {}.".to_string(),
            answer: "Our customers can't get enough of the {name}. {description}".to_string(),
        },
        CustomerInteraction {
            question: "What is the {} used for?".to_string(),
            answer: "The {name} is a versatile product that meets various needs. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "Describe the {}.".to_string(),
            answer: "The {name} is a reliable product that won't disappoint. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "What are the benefits of the {}?".to_string(),
            answer:
                "The {name} is a top-of-the-line product that exceeds expectations. {description}"
                    .to_string(),
        },
        CustomerInteraction {
            question: "How does the {} compare to other products?".to_string(),
            answer: "The {name} is a customer favorite. It's highly rated. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "Is the {} popular among customers?".to_string(),
            answer: "The {name} is a top choice for customers looking for quality. {description}"
                .to_string(),
        },
        CustomerInteraction {
            question: "Can you provide more details about the {}?".to_string(),
            answer:
                "The {name} is a well-loved product that has received great reviews. {description}"
                    .to_string(),
        },
        CustomerInteraction {
            question: "What are the specifications of the {}?".to_string(),
            answer: "The {name} is a top performer in its category. {description}".to_string(),
        },
    ];

    let products = data.products.lock().unwrap();
    let mut response: Vec<MessageList> = Vec::new();
    for product in products.iter() {
        for interaction in customer_interactions.iter() {
            let question = interaction.question.replace("{}", &product.name);
            let answer = interaction
                .answer
                .replace("{name}", &product.name)
                .replace("{description}", &product.description);
            let messages = vec![
                Message {
                    role: "user".to_string(),
                    content: question,
                },
                Message {
                    role: "assistant".to_string(),
                    content: answer,
                },
            ];
            response.push(MessageList { messages });
        }
    }
    return Ok(HttpResponse::Ok().json(response));
}
