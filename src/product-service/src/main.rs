use actix_cors::Cors;
use actix_web::middleware::Logger;
use actix_web::{
    error, error::ResponseError, middleware, web, App, Error, HttpResponse, HttpServer,
};
use env_logger::Env;
use futures_util::StreamExt;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::collections::HashMap;
use std::fmt;
use std::sync::Mutex;

const MAX_SIZE: usize = 262_144; // max payload size is 256k

async fn health() -> Result<HttpResponse, Error> {
    let version = std::env::var("APP_VERSION").unwrap_or_else(|_| "0.1.0".to_string());
    let health = json!({"status": "ok", "version": version});
    Ok(HttpResponse::Ok().json(health))
}

async fn get_product(
    data: web::Data<AppState>,
    path: web::Path<ProductInfo>,
) -> Result<HttpResponse, Error> {
    let products = data.products.lock().unwrap();

    // find product by id in products
    let index = products
        .iter()
        .position(|p| p.id == path.product_id)
        .unwrap();

    Ok(HttpResponse::Ok().json(products[index].clone()))
}

async fn get_products(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let products = data.products.lock().unwrap();
    Ok(HttpResponse::Ok().json(products.to_vec()))
}

async fn add_product(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let mut products = data.products.lock().unwrap();
    let new_id = products.len() as i32 + 1;

    // payload is a stream of Bytes objects
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        // limit max size of in-memory payload
        if (body.len() + chunk.len()) > MAX_SIZE {
            return Err(error::ErrorBadRequest("overflow"));
        }
        body.extend_from_slice(&chunk);
    }

    // body is loaded, now we can deserialize serde-json
    let mut product = serde_json::from_slice::<Product>(&body)?;

    // update product id
    product.id = new_id;

    // add product to products
    products.push(product.clone());

    Ok(HttpResponse::Ok().json(product))
}

async fn update_product(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let mut products = data.products.lock().unwrap();

    // payload is a stream of Bytes objects
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        // limit max size of in-memory payload
        if (body.len() + chunk.len()) > MAX_SIZE {
            return Err(error::ErrorBadRequest("overflow"));
        }
        body.extend_from_slice(&chunk);
    }

    // body is loaded, now we can deserialize serde-json
    let product = serde_json::from_slice::<Product>(&body)?;

    // replace product with same id
    let index = products.iter().position(|p| p.id == product.id).unwrap();
    products[index] = product.clone();

    Ok(HttpResponse::Ok().json(product))
}

async fn delete_product(
    data: web::Data<AppState>,
    path: web::Path<ProductInfo>,
) -> Result<HttpResponse, Error> {
    let mut products = data.products.lock().unwrap();

    // find product by id in products
    let index = products
        .iter()
        .position(|p| p.id == path.product_id)
        .unwrap();

    // remove product from products
    products.remove(index);

    Ok(HttpResponse::Ok().body(""))
}

//////////////////////////
// Proxy for AI service
//////////////////////////

#[derive(Debug)]
struct ProxyError(reqwest::Error);

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

fn get_ai_service_url() -> String {
    let ai_service_url = std::env::var("AI_SERVICE_URL").unwrap_or_else(|_| "http://127.0.0.1:5001".to_string());
    ai_service_url.trim_end_matches('/').to_string()
}

async fn ai_health() -> Result<HttpResponse, Error> {
    let client = reqwest::Client::new();
    let resp = client.get(get_ai_service_url() + "/health").send().await.unwrap();
    let status = resp.status();
    if status.is_success() {
        let body: HashMap<String, String> = resp.json().await.map_err(ProxyError::from)?;
        let body_json = serde_json::to_string(&body).unwrap();
        Ok(HttpResponse::Ok().body(body_json))
    } else {
        Ok(HttpResponse::build(actix_web::http::StatusCode::NOT_FOUND).body(""))
    }
}

async fn ai_generate_description(mut payload: web::Payload) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    let client = reqwest::Client::new();
    let resp = client
        .post(get_ai_service_url() + "/generate/description")
        .body(body.to_vec())
        .send()
        .await
        .unwrap();

    let status = resp.status();
    let body: HashMap<String, String> = resp.json().await.map_err(ProxyError::from)?;
    let body_json = serde_json::to_string(&body).unwrap();
    if status.is_success() {
        Ok(HttpResponse::Ok().body(body_json))
    } else {
        Ok(HttpResponse::build(actix_web::http::StatusCode::INTERNAL_SERVER_ERROR).body(body_json))
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let products = vec![
        Product {
            id: 1,
            name: "Contoso Catnip's Friend".to_string(),
            price: 9.99,
            description: "Watch your feline friend embark on a fishing adventure with Contoso Catnip's Friend toy. Packed with irresistible catnip and dangling fish lure.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 2,
            name: "Salty Sailor's Squeaky Squid".to_string(),
            price: 6.99,
            description: "Let your dog set sail with the Salty Sailor's Squeaky Squid. This interactive toy provides hours of fun, featuring multiple squeakers and crinkle tentacles.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 3,
            name: "Mermaid's Mice Trio".to_string(),
            price: 12.99,
            description: "Entertain your kitty with the Mermaid's Mice Trio. These adorable plush mice are dressed as mermaids and filled with catnip to captivate their curiosity.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 4,
            name: "Ocean Explorer's Puzzle Ball".to_string(),
            price: 11.99,
            description: "Challenge your pet's problem-solving skills with the Ocean Explorer's Puzzle Ball. This interactive toy features hidden compartments and treats, providing mental stimulation and entertainment.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 5,
            name: "Pirate Parrot Teaser Wand".to_string(),
            price: 8.99,
            description: "Engage your cat in a playful pursuit with the Pirate Parrot Teaser Wand. The colorful feathers and jingling bells mimic the mischievous charm of a pirate's parrot.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 6,
            name: "Seafarer's Tug Rope".to_string(),
            price: 14.99,
            description: "Tug-of-war meets nautical adventure with the Seafarer's Tug Rope. Made from marine-grade rope, it's perfect for interactive play and promoting dental health in dogs.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 7,
            name: "Seashell Snuggle Bed".to_string(),
            price: 19.99,
            description: "Give your furry friend a cozy spot to curl up with the Seashell Snuggle Bed. Shaped like a seashell, this plush bed provides comfort and relaxation for cats and small dogs.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 8,
            name: "Nautical Knot Ball".to_string(),
            price: 7.99,
            description: "Unleash your dog's inner sailor with the Nautical Knot Ball. Made from sturdy ropes, it's perfect for fetching, tugging, and satisfying their chewing needs.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 9,
            name: "Contoso Claw's Crabby Cat Toy".to_string(),
            price: 3.99,
            description: "Watch your cat go crazy for Contoso Claw's Crabby Cat Toy. This crinkly and catnip-filled toy will awaken their hunting instincts and provide endless entertainment.".to_string(),
            image: "/placeholder.png".to_string()
        },
        Product {
            id: 10,
            name: "Ahoy Doggy Life Jacket".to_string(),
            price: 5.99,
            description: "Ensure your furry friend stays safe during water adventures with the Ahoy Doggy Life Jacket. Designed for dogs, this flotation device offers buoyancy and visibility in style.".to_string(),
            image: "/placeholder.png".to_string()
        }
    ];

    let product_state = web::Data::new(AppState {
        products: Mutex::new(products.to_vec()),
    });

    println!("Listening on http://0.0.0.0:3002");

    env_logger::init_from_env(Env::default().default_filter_or("info"));

    HttpServer::new(move || {
        let cors = Cors::permissive();

        App::new()
            .wrap(cors)
            .wrap(Logger::default())
            .wrap(Logger::new("%a %{User-Agent}i"))
            .wrap(middleware::DefaultHeaders::new().add(("X-Version", "0.2")))
            .app_data(product_state.clone())
            .route("/health", web::get().to(health))
            .route("/health", web::head().to(health))
            .route("/{product_id}", web::get().to(get_product))
            .route("/", web::get().to(get_products))
            .route("/", web::post().to(add_product))
            .route("/", web::put().to(update_product))
            .route("/{product_id}", web::delete().to(delete_product))
            .route("/ai/health", web::get().to(ai_health))
            .route("/ai/health", web::head().to(ai_health))
            .route(
                "/ai/generate/description",
                web::post().to(ai_generate_description),
            )
    })
    .bind(("0.0.0.0", 3002))?
    .run()
    .await
}

struct AppState {
    products: Mutex<Vec<Product>>,
}

#[derive(Serialize, Deserialize, Clone)]
struct Product {
    id: i32,
    name: String,
    price: f32,
    description: String,
    image: String,
}

#[derive(Deserialize)]
struct ProductInfo {
    product_id: i32,
}
