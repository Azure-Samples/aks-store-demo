mod rules_engine_state;
mod host;

wasmtime::component::bindgen!({
    path: "rule_engine.wit",
    world: "service-host"
});

use std::path::Path;

use log::info;
use crate::model::Product;
use crate::configuration::Settings;

pub use rules_engine_state::RulesEngineState;
pub use host::LocalWasmtimeHost;
pub use aksstoredemo::rules::types::{Product as WasmProduct, Error};


fn wasm_bin_path_exists(wasm_bin_path: &Path) -> bool {
    let wasm_bin_path_exists = wasm_bin_path.exists();
    info!("WASM rules engine path exists: {}", wasm_bin_path_exists);
    return wasm_bin_path_exists;
}

pub fn validate_product(settings: &Settings, product: &Product) -> Result<Product, Error>{
    
    let wasm_bin_path = settings.wasm_bin_path.clone();
    
    if  settings.wasm_rules_engine_enabled && wasm_bin_path_exists(&wasm_bin_path) {
        let mut host = LocalWasmtimeHost::new(&wasm_bin_path).unwrap();
        let wasm_product: WasmProduct = product.clone().into();
        let wasm_product = host.execute(wasm_product)?;
        let validated_product = wasm_product.into();
        return Ok(validated_product);
    }
    else {
        return Ok(product.clone())
    }
}


