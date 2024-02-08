cargo_component_bindings::generate!();

use bindings::aksstoredemo::rules::{logging, engine as downstream};
use bindings::exports::aksstoredemo::rules::engine::{Guest, Product, Error};

struct Component;

impl Guest for Component {
    fn execute(input: Product) -> Result<Product, Error> {
        logging::get_logger().log("Checking price to ensure it is lower than $100.00");
        if input.price > 100.0 {
            return Err(Error::PricingStandardsViolation("Price is too high!".to_string()));
        }
        
        downstream::execute(&input)
    }
}