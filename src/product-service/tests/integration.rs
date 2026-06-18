mod helpers;
use actix_web::test;
use helpers::*;
use product_service::models::Product;

#[test]
async fn test_health_check() {
    let url = spawn_app();

    let res = get_health_check(&url).await;

    assert_eq!(res.status().as_u16(), 200);
    let check = res.text().await.unwrap();
    assert_eq!(check, "{\"status\":\"ok\",\"version\":\"0.1.0\"}");
}

#[test]
async fn test_health_check_head() {
    let url = spawn_app();
    let res = get_health_check_head(&url).await;
    assert_eq!(res.status().as_u16(), 200);
}

#[test]
async fn test_ai_health_check_head() {
    let url = spawn_app();
    let res = get_ai_health_check_head(&url).await;
    assert_eq!(res.status().as_u16(), 500);
}

#[test]
async fn test_get_ai_health_check() {
    let url = spawn_app();
    let res = get_ai_health_check(&url).await;
    assert_eq!(res.status().as_u16(), 500);
}

#[test]
async fn test_get_all_products() {
    let url = spawn_app();
    let res = get_products(&url).await;

    assert_eq!(res.status().as_u16(), 200);
    let products = res.json::<Vec<Product>>().await.unwrap();
    assert_eq!(products.len(), 10);
}

#[test]
async fn test_get_product_by_id() {
    let url = spawn_app();
    let res = get_product(&url, 1).await;

    assert_eq!(res.status().as_u16(), 200);
    let product = res.json::<Product>().await.unwrap();
    assert_eq!(product.id, 1);
}

#[test]
async fn test_get_product_not_found() {
    let url = spawn_app();
    let res = get_product(&url, 999).await;
    assert_eq!(res.status().as_u16(), 404);
}

#[test]
async fn test_add_product() {
    let url = spawn_app();
    let res = post_product(&url, &new_product()).await;

    assert_eq!(res.status().as_u16(), 200);
    let product = res.json::<Product>().await.unwrap();
    assert_eq!(product.id, 11);
    assert_eq!(product.name, "Test Widget");
}

#[test]
async fn test_add_product_empty_name_rejected() {
    let url = spawn_app();
    let mut p = new_product();
    p.name = "".into();
    let res = post_product(&url, &p).await;
    assert_eq!(res.status().as_u16(), 400);
}

#[test]
async fn test_add_product_negative_price_rejected() {
    let url = spawn_app();
    let mut p = new_product();
    p.price = -5.0;
    let res = post_product(&url, &p).await;
    assert_eq!(res.status().as_u16(), 400);
}

#[test]
async fn test_update_product() {
    let url = spawn_app();

    let res = post_product(&url, &new_product()).await;
    assert_eq!(res.status().as_u16(), 200);
    let created = res.json::<Product>().await.unwrap();

    let updated_product = Product {
        id: created.id,
        name: "Updated Widget".into(),
        price: 2.0,
        description: "Updated description".into(),
        image: "/updated.jpg".into(),
    };

    let res = update_product(&url, &updated_product).await;
    assert_eq!(res.status().as_u16(), 200);

    let returned = res.json::<Product>().await.unwrap();
    assert_eq!(returned.name, "Updated Widget");
    assert_eq!(returned.price, 2.0);
}

#[test]
async fn test_update_product_not_found() {
    let url = spawn_app();
    let p = Product {
        id: 999,
        name: "Ghost".into(),
        price: 1.0,
        description: "Does not exist".into(),
        image: "/ghost.jpg".into(),
    };
    let res = update_product(&url, &p).await;
    assert_eq!(res.status().as_u16(), 404);
}

#[test]
async fn test_update_product_invalid_rejected() {
    let url = spawn_app();
    let p = Product {
        id: 1,
        name: "".into(),
        price: 1.0,
        description: "Valid".into(),
        image: "/img.jpg".into(),
    };
    let res = update_product(&url, &p).await;
    assert_eq!(res.status().as_u16(), 400);
}

#[test]
async fn test_delete_product() {
    let url = spawn_app();

    let res = post_product(&url, &new_product()).await;
    assert_eq!(res.status().as_u16(), 200);
    let created = res.json::<Product>().await.unwrap();

    let res = delete_product(&url, created.id).await;
    assert_eq!(res.status().as_u16(), 200);

    let res = get_product(&url, created.id).await;
    assert_eq!(res.status().as_u16(), 404);
}

#[test]
async fn test_delete_product_not_found() {
    let url = spawn_app();
    let res = delete_product(&url, 999).await;
    assert_eq!(res.status().as_u16(), 404);
}
