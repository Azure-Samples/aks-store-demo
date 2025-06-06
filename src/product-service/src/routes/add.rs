use crate::localwasmtime::validate_product;
use crate::model::Product;
use crate::startup::AppState;
use actix_web::{error, web, Error, HttpResponse};
use futures_util::StreamExt;

pub async fn add_product(
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
        if (body.len() + chunk.len()) > data.settings.max_size {
            return Err(error::ErrorBadRequest("overflow"));
        }
        body.extend_from_slice(&chunk);
    }

    // body is loaded, now we can deserialize serde-json
    let mut product = serde_json::from_slice::<Product>(&body)?;

    // update product id
    product.id = new_id;

    // Add rules engine evaluation here
    match validate_product(&data.settings, &product) {
        Ok(validated_product) => {
            // add product to products
            products.push(validated_product.clone());

            Ok(HttpResponse::Ok().json(validated_product))
        }
        Err(e) => Ok(HttpResponse::BadRequest().body(e.to_string())),
    }
}

pub async fn add_products(
    data: web::Data<AppState>,
    mut payload: web::Payload,
) -> Result<HttpResponse, Error> {
    let mut products = data.products.lock().unwrap();

    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        // limit max size of in-memory payload
        if (body.len() + chunk.len()) > data.settings.max_size {
            return Err(error::ErrorBadRequest("overflow"));
        }
        body.extend_from_slice(&chunk);
    }

    let new_products = serde_json::from_slice::<Vec<Product>>(&body)?;

    for mut product in new_products {
        let new_id = products.len() as i32 + 1;
        product.id = new_id;

        match validate_product(&data.settings, &product) {
            Ok(validated_product) => {
                products.push(validated_product.clone());
            }
            Err(e) => {
                return Ok(HttpResponse::BadRequest().body(e.to_string()));
            }
        }
    }

    Ok(HttpResponse::Ok().into())
}
