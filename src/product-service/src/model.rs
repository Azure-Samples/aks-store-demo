use crate::localwasmtime::WasmProduct;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
pub struct Product {
    pub id: i32,
    pub name: String,
    pub price: f32,
    pub description: String,
    pub image: String,
}

#[derive(Deserialize)]
pub struct ProductInfo {
    pub product_id: i32,
}

impl Into<WasmProduct> for Product {
    fn into(self) -> WasmProduct {
        WasmProduct {
            id: self.id,
            name: self.name,
            description: self.description,
            price: self.price,
            image: self.image,
        }
    }
}

impl From<WasmProduct> for Product {
    fn from(product: WasmProduct) -> Self {
        Self {
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            image: product.image,
        }
    }
}
