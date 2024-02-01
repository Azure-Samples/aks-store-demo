use actix_web::{error, web, Error, HttpResponse};
use crate::model::Product;
use crate::startup::AppState;
use futures_util::StreamExt;
use crate::localwasmtime::validate_product;

pub async fn update_product(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let mut products = data.products.lock().unwrap();

    // payload is a stream of Bytes objects
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        // limit max size of in-memory payload
        if (body.len() + chunk.len()) > data.settings.max_size {
            return Err(error::ErrorBadRequest("overflow"));
        }
        body.extend_from_slice(&chunk);
    }

    // body is loaded, now we can deserialize serde-json
    let product = serde_json::from_slice::<Product>(&body)?;
    
    match validate_product(&data.settings, &product) {
        Ok(validated_product) => {
            // replace product with same id
            let index = products.iter().position(|p| p.id == product.id).unwrap();
            products[index] = validated_product.clone();

            Ok(HttpResponse::Ok().json(validated_product))
        }
        Err(e) => {
            Ok(HttpResponse::BadRequest().body(e.to_string()))
        }
    }  
}