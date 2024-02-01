use crate::model::ProductInfo;
use crate::startup::AppState;
use actix_web::{web, Error, HttpResponse};

pub async fn get_product(
    data: web::Data<AppState>,
    path: web::Path<ProductInfo>,
) -> Result<HttpResponse, Error> {
    let products = data.products.lock().unwrap();

    // find product by id in products
    let index = products
        .iter()
        .position(|p| p.id == path.product_id);
    if let Some(i) = index {
        return Ok(HttpResponse::Ok().json(products[i].clone()))
    }
    else {
        return Ok(HttpResponse::NotFound().body("Product not found"))
    }
}

pub async fn get_products(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let products = data.products.lock().unwrap();
    Ok(HttpResponse::Ok().json(products.to_vec()))
}