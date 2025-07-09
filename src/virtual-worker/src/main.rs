use serde::{Deserialize, Serialize};
use std::env;
use std::thread;
use std::time::{Duration, Instant};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::blocking::Client::new();

    let order_service_url =
        env::var("MAKELINE_SERVICE_URL").unwrap_or_else(|_| "http://localhost:3001".to_string());

    let orders_per_hour: u64 = env::var("ORDERS_PER_HOUR")
        .unwrap_or_else(|_| "0".to_string())
        .parse()
        .unwrap_or(0);

    if orders_per_hour > 0 {
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

        loop {
            // get orders
            let orders = get_orders(&client, &order_service_url)?;

            // check if we have orders to process
            if orders.len() > 0 {
                println!("Processing orders");
                process_orders(&client, orders, &order_service_url)?;
                println!("Order processing complete");
            } else {
                println!("No orders to process");
            }

            // sleep for the specified duration
            thread::sleep(sleep_duration);
        }
    } else {
        println!("Processing orders");
        let orders = get_orders(&client, &order_service_url)?;
        process_orders(&client, orders, &order_service_url)?;
        println!("Order processing complete");
        std::process::exit(0);
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

fn get_orders(
    client: &reqwest::blocking::Client,
    url: &str,
) -> Result<Vec<Order>, Box<dyn std::error::Error>> {
    let response = client.get(format!("{}/order/fetch", url)).send();

    match response {
        Ok(res) => {
            let res = res.error_for_status()?;

            let json = res.text()?;

            if json.trim().is_empty() || json.trim() == "null" {
                println!("No orders to process");
                return Ok(vec![]);
            }

            let orders: Vec<Order> = match serde_json::from_str(&json) {
                Ok(orders) => orders,
                Err(e) => {
                    println!("Failed to parse JSON: {}", e);
                    return Ok(vec![]);
                }
            };

            if orders.is_empty() {
                println!("No orders to process");
            } else {
                println!("Processing {} orders", orders.len());
            }

            return Ok(orders);
        }
        Err(e) => {
            println!("Failed to fetch orders: {}", e);
        }
    }
    Ok(vec![])
}

fn process_orders(
    client: &reqwest::blocking::Client,
    orders: Vec<Order>,
    url: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    // keep track of how long we've been running
    let start_time = Instant::now();

    // loop through the orders
    for mut order in orders {
        // update order status
        order.status = OrderStatus::Processing as u32;

        // send the order to the order service
        let serialized_order = serde_json::to_string(&order)?;

        let response = client
            .put(format!("{}/order", url))
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
                    order.order_id, elapsed_time, order.status, serialized_order
                );
            }
            Err(err) => {
                println!("Error completing the order: {}", err);
            }
        }
    }
    Ok(())
}
