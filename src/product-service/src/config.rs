use std::env;
use std::net::TcpListener;
use std::time::Duration;

pub struct Settings {
    pub max_size: usize,
    pub log_level: String,
    pub port: u16,
    pub ai_service_url: String,
    pub ai_request_timeout: Duration,
    pub ai_max_payload: usize,
    tcp_listener: Option<TcpListener>,
}

impl Default for Settings {
    fn default() -> Self {
        let ai_service_url =
            env::var("AI_SERVICE_URL").unwrap_or_else(|_| "http://127.0.0.1:5001".into());
        let max_size = env::var("PRODUCT_MAX_SIZE_BYTES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(10 * 1024 * 1024);
        let ai_request_timeout = env::var("AI_REQUEST_TIMEOUT_SECS")
            .ok()
            .and_then(|v| v.parse().ok())
            .map(Duration::from_secs)
            .unwrap_or(Duration::from_secs(300));
        let ai_max_payload = env::var("AI_MAX_PAYLOAD_BYTES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(50 * 1024 * 1024); // 50 MB default for image data

        Self {
            max_size,
            log_level: "info".into(),
            port: 3002,
            ai_service_url: ai_service_url.trim_end_matches('/').to_string(),
            ai_request_timeout,
            ai_max_payload,
            tcp_listener: None,
        }
    }
}

impl Settings {
    pub fn with_port(mut self, port: u16) -> Self {
        self.port = port;
        self
    }

    pub fn with_max_size(mut self, max_size: usize) -> Self {
        self.max_size = max_size;
        self
    }

    pub fn with_log_level(mut self, log_level: String) -> Self {
        self.log_level = log_level;
        self
    }

    pub fn tcp_listener(&mut self) -> std::io::Result<TcpListener> {
        if let Some(listener) = &self.tcp_listener {
            listener.try_clone()
        } else {
            let listener = TcpListener::bind(format!("0.0.0.0:{}", self.port))?;
            self.tcp_listener = Some(listener.try_clone()?);
            Ok(listener)
        }
    }
}
