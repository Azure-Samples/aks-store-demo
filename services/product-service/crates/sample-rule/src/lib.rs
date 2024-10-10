cargo_component_bindings::generate!();

use bindings::aksstoredemo::rules::logging;
use bindings::exports::aksstoredemo::rules::engine::{Guest, Product, Error};

struct Component;

impl Guest for Component {
    fn execute(input: Product) -> Result<Product, Error> {
        let logger = logging::get_logger();
        logger.log("Hello from the WASM Rules Engine!");
        logger.log("Checking if the product description is longer than 10 characters...");
        if input.description.len() < 10 {
            logger.log("The product description is too short!");
            return Err(Error::InvalidProduct("The product description is too short!".to_string()));
        };
        Ok(input)
    }
}