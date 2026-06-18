use crate::app::AppState;
use crate::models::{Product, ProductPath, StoreError};
use actix_web::{HttpResponse, web};

fn error_response(err: StoreError) -> HttpResponse {
    match err {
        StoreError::NotFound(_) => HttpResponse::NotFound().json(err.to_string()),
        StoreError::Validation(_) => HttpResponse::BadRequest().json(err.to_string()),
    }
}

pub async fn get_product(data: web::Data<AppState>, path: web::Path<ProductPath>) -> HttpResponse {
    let store = match data.store.read() {
        Ok(s) => s,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    match store.find(path.product_id) {
        Ok(product) => HttpResponse::Ok().json(product),
        Err(e) => error_response(e),
    }
}

pub async fn get_products(data: web::Data<AppState>) -> HttpResponse {
    let store = match data.store.read() {
        Ok(s) => s,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };
    HttpResponse::Ok().json(store.list())
}

pub async fn get_metrics(data: web::Data<AppState>) -> HttpResponse {
    let store = match data.store.read() {
        Ok(s) => s,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };
    let count = store.count();
    let metrics = format!(
        "# HELP total_product_count The total number of products in the database\n\
         # TYPE total_product_count gauge\n\
         total_product_count {count}\n"
    );
    HttpResponse::Ok().body(metrics)
}

pub async fn add_product(data: web::Data<AppState>, body: web::Json<Product>) -> HttpResponse {
    let mut store = match data.store.write() {
        Ok(s) => s,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    match store.insert(body.into_inner()) {
        Ok(product) => HttpResponse::Ok().json(product),
        Err(e) => error_response(e),
    }
}

pub async fn add_products(
    data: web::Data<AppState>,
    body: web::Json<Vec<Product>>,
) -> HttpResponse {
    let mut store = match data.store.write() {
        Ok(s) => s,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    for product in body.into_inner() {
        if let Err(e) = store.insert(product) {
            return error_response(e);
        }
    }

    HttpResponse::Ok().into()
}

pub async fn update_product(data: web::Data<AppState>, body: web::Json<Product>) -> HttpResponse {
    let mut store = match data.store.write() {
        Ok(s) => s,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    match store.update(body.into_inner()) {
        Ok(product) => HttpResponse::Ok().json(product),
        Err(e) => error_response(e),
    }
}

pub async fn delete_product(
    data: web::Data<AppState>,
    path: web::Path<ProductPath>,
) -> HttpResponse {
    let mut store = match data.store.write() {
        Ok(s) => s,
        Err(_) => return HttpResponse::InternalServerError().finish(),
    };

    match store.delete(path.product_id) {
        Ok(()) => HttpResponse::Ok().body(""),
        Err(e) => error_response(e),
    }
}
