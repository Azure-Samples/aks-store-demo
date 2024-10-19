mod common;
use actix_web::test;
use common::*;
use product_service::model::Product;

// test health check
#[test]
async fn test_health_check() {
    let url = spawn_app(false);

    let res = get_health_check(&url).await;

    assert_eq!(res.status().as_u16(), 200);
    let check = res.text().await.unwrap();
    assert_eq!(check, "{\"status\":\"ok\",\"version\":\"0.1.0\"}");
}

// test health check head
#[test]
async fn test_health_check_head() {
    let url = spawn_app(false);

    let res = get_health_check_head(&url).await;

    assert_eq!(res.status().as_u16(), 200);
}

#[test]
async fn test_ai_health_check_head() {
    let url = spawn_app(false);

    let res = get_ai_health_check_head(&url).await;

    assert_eq!(res.status().as_u16(), 500);
}

#[test]
async fn test_get_ai_health_check() {
    let url = spawn_app(false);

    let res = get_ai_health_check(&url).await;

    assert_eq!(res.status().as_u16(), 500);
}

// test get all products
#[test]
async fn test_get_all_products() {
    let url = spawn_app(false);

    let res = get_products(&url).await;

    assert_eq!(res.status().as_u16(), 200);

    let products = res.json::<Vec<Product>>().await.unwrap();
    assert!(products.len() >= 10);
}

// test get product by id
#[test]
async fn test_get_product_by_id() {
    let url = spawn_app(false);

    let res = get_product(&url, 1).await;

    assert_eq!(res.status().as_u16(), 200);

    let product = res.json::<Product>().await.unwrap();
    assert_eq!(product.id, 1);
}

#[test]
async fn test_add_product() {
    let url = spawn_app(false);

    let res = post_product(&url, &new_product()).await;

    assert_eq!(res.status().as_u16(), 200);

    let return_product = res.json::<Product>().await.unwrap();
    assert!(return_product.id >= 11);
    assert_eq!(return_product.name, "test".to_string());
}

#[test]
async fn test_add_product_with_validation_short_description_length() {
    let url = spawn_app(true);

    let failed_res = post_product(&url, &new_product()).await;

    assert_eq!(failed_res.status().as_u16(), 400);
    assert_eq!(
        failed_res.text().await.unwrap(),
        "Error::InvalidProduct(\"The product description is too short!\")"
    );
}

#[test]
async fn test_add_product_with_validation_long_description_length() {
    let url = spawn_app(true);

    let successful_res = post_product(&url, &new_product_with_longer_description()).await;

    assert_eq!(successful_res.status().as_u16(), 200);
    let return_product = successful_res.json::<Product>().await.unwrap();
    assert!(return_product.id >= 11);
    assert_eq!(return_product.name, "test".to_string());
}

#[test]
async fn test_add_product_with_validation_high_price() {
    let url = spawn_app(true);

    let failed_res = post_product(&url, &new_product_with_high_price()).await;

    assert_eq!(failed_res.status().as_u16(), 400);
    assert_eq!(
        failed_res.text().await.unwrap(),
        "Error::PricingStandardsViolation(\"Price is too high!\")"
    );
}

// test update product
#[test]
async fn test_update_product() {
    let url = spawn_app(false);

    let res = post_product(&url, &new_product()).await;

    assert_eq!(res.status().as_u16(), 200);

    let return_product = res.json::<Product>().await.unwrap();
    assert!(return_product.id >= 11);
    assert_eq!(return_product.name, "test".to_string());

    let updated_product = Product {
        id: return_product.id,
        name: "test2".to_string(),
        price: 2.0,
        description: "test2".to_string(),
        image: "test2".to_string(),
    };

    let res = update_product(&url, &updated_product).await;

    assert_eq!(res.status().as_u16(), 200);

    let return_product = res.json::<Product>().await.unwrap();
    assert_eq!(return_product.id, updated_product.id);
    assert_eq!(return_product.name, updated_product.name);
    assert_eq!(return_product.price, updated_product.price);
    assert_eq!(return_product.description, updated_product.description);
    assert_eq!(return_product.image, updated_product.image);
}

// test delete product
#[test]
async fn test_delete_product() {
    let url = spawn_app(false);

    let res = post_product(&url, &new_product()).await;

    assert_eq!(res.status().as_u16(), 200);

    let return_product = res.json::<Product>().await.unwrap();
    assert!(return_product.id >= 11);
    assert_eq!(return_product.name, "test".to_string());

    let res = delete_product(&url, return_product.id).await;

    assert_eq!(res.status().as_u16(), 200);

    let res = get_product(&url, return_product.id).await;

    assert_eq!(res.status().as_u16(), 404);
}
