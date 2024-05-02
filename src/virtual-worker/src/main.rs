use serde::{Deserialize, Serialize};
use std::env;
use std::thread;
use std::time::{Duration, Instant};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let order_service_url =
        env::var("MAKELINE_SERVICE_URL").unwrap_or_else(|_| "http://localhost:3001".to_string());

    let orders_per_hour: u64 = env::var("ORDERS_PER_HOUR")
        .unwrap_or_else(|_| "1".to_string())
        .parse()
        .unwrap_or(1);

    if orders_per_hour == 0 {
        println!("Please set the ORDERS_PER_HOUR environment variable");
        std::process::exit(1);
    }

    println!("Orders to process per hour: {}", orders_per_hour);

    let minutes: f64 = 60.0;
    let seconds: f64 = 60.0;

    // calculate the time between orders in seconds
    let order_processing_interval: f64 = (minutes / (orders_per_hour as f64)) * seconds;
    println!(
        "Order processing interval: {} seconds",
        order_processing_interval
    );

    // time to sleep between orders
    let sleep_duration = Duration::from_secs_f64(order_processing_interval);
    println!("Sleep duration between orders: {:?}", sleep_duration);

    // keep track of how long we've been running
    let start_time = Instant::now();

    loop {
        // fetch the orders
        let client = reqwest::blocking::Client::new();

        let response = client
            .get(format!("{}/order/fetch", order_service_url))
            .send();

        match response {
            Ok(res) => {
                let json = res.text().unwrap();

                if json == "null" {
                    println!("No orders to process");
                } else {
                    println!("Processing orders");

                    let orders: Vec<Order> = match serde_json::from_str(&json) {
                        Ok(orders) => orders,
                        Err(e) => {
                            println!("Failed to parse JSON: {}", e);
                            vec![]
                        }
                    };

                    if orders.len() == 0 {
                        println!("No orders to process");
                    } else {
                        println!("Processing {} orders", orders.len());

                        // loop through the orders
                        for mut order in orders {
                            // update order status
                            order.status = OrderStatus::Processing as u32;

                            // send the order to the order service
                            let serialized_order = serde_json::to_string(&order)?;
                            let client = reqwest::blocking::Client::new();

                            let response = client
                                .put(format!("{}/order", order_service_url))
                                .header("Content-Type", "application/json")
                                .body(serialized_order.clone())
                                .send();

                            match response {
                                Ok(_res) => {
                                    // track the time it takes to generate an order
                                    let elapsed_time = start_time.elapsed();

                                    // print the order details
                                    println!(
                                        "Order {} processed at {:.2?} with status of {}. {}",
                                        order.order_id,
                                        elapsed_time,
                                        order.status,
                                        serialized_order
                                    );
                                }
                                Err(err) => {
                                    println!("Error completing the order: {}", err);
                                }
                            }

                            thread::sleep(sleep_duration);
                        }
                    }
                }
            }
            Err(e) => {
                println!("Failed to fetch orders: {}", e);
                thread::sleep(sleep_duration);
            }
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
struct Order {
    #[serde(rename = "orderId")]
    order_id: String,
    #[serde(rename = "customerId")]
    customer_id: String,
    items: Vec<Item>,
    status: u32,
}

#[derive(Debug, Deserialize, Serialize)]
struct Item {
    #[serde(rename = "productId")]
    product_id: u32,
    quantity: u32,
    price: f32,
}

#[derive(Debug, Deserialize, Serialize)]
enum OrderStatus {
    Pending = 0,
    Processing,
    Complete,
}
