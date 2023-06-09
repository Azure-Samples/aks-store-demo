use rand::Rng;
use serde::Serialize;
use std::env;
use std::thread;
use std::time::{Duration, Instant};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let order_service_url =
        env::var("ORDER_SERVICE_URL").unwrap_or_else(|_| "http://localhost:3000".to_string());

    let orders_per_minute: u32 = env::var("ORDERS_PER_MINUTE")
        .unwrap_or_else(|_| "0".to_string())
        .parse()
        .unwrap_or(0);

    if orders_per_minute == 0 {
        println!("Please set the ORDERS_PER_MINUTE environment variable");
        std::process::exit(1);
    }

    // orders per second we need to generate
    let orders_per_second = orders_per_minute / 60;

    // time to sleep between orders
    let sleep_duration = Duration::from_secs(1) / orders_per_second;

    // order counter
    let mut order_counter = 0;

    // keep track of how long we've been running
    let start_time = Instant::now();

    loop {
        order_counter += 1;

        // generate a random customer id
        let customer_id = (rand::thread_rng().gen_range(1000000000..2147483647)).to_string();

        // generate a random number of items to order
        let number_of_items = rand::thread_rng().gen_range(1..5);

        // create a vector to hold the items
        let mut items = Vec::new();

        // generate a random item for each item
        items.append(
            &mut (0..number_of_items)
                .map(|_| {
                    let product_id = rand::thread_rng().gen_range(1..10);
                    let quantity = rand::thread_rng().gen_range(1..5);
                    let price = rand::thread_rng().gen_range(1.0..100.0);

                    Item {
                        product_id,
                        quantity,
                        price,
                    }
                })
                .collect(),
        );

        let order = Order { customer_id, items };
        let serialized_order = serde_json::to_string(&order)?;
        let client = reqwest::blocking::Client::new();
        let response = client
            .post(order_service_url.clone())
            .header("Content-Type", "application/json")
            .body(serialized_order.clone())
            .send()?;

        // track the time it takes to generate an order
        let elapsed_time = start_time.elapsed();

        // print the order details
        println!(
            "Order {} sent at {:.2?} with status of {}. {}",
            order_counter,
            elapsed_time,
            response.status(),
            serialized_order
        );

        thread::sleep(sleep_duration);
    }
}

#[derive(Serialize, Debug)]
struct Order {
    #[serde(rename = "customerId")]
    customer_id: String,
    items: Vec<Item>,
}

#[derive(Serialize, Debug)]
struct Item {
    #[serde(rename = "productId")]
    product_id: u32,
    quantity: u32,
    price: f32,
}
