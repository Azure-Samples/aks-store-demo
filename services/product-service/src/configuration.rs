use std::env::var;
use std::path::PathBuf;
use std::net::TcpListener;
pub struct Settings {
    pub max_size: usize,
    pub log_level: String,
    pub port: u16,
    pub wasm_rules_engine_enabled: bool,
    pub wasm_bin_path: PathBuf,
    tcp_listener: Option<TcpListener>,
    pub ai_service_url: String,
}

impl Settings {
    pub fn new() -> Self {
        let wasm_bin_path_env = var("WASM_RULE_ENGINE_PATH").unwrap_or_else(|_| "./tests/rule_engine.wasm".to_string());
        let ai_service_url = std::env::var("AI_SERVICE_URL").unwrap_or_else(|_| "http://127.0.0.1:5001".to_string());
        Settings {
            max_size: 262_144,
            log_level: "info".to_string(),
            port: 3002,
            wasm_rules_engine_enabled: false,
            wasm_bin_path: PathBuf::from(wasm_bin_path_env),
            tcp_listener: None,
            ai_service_url: ai_service_url.trim_end_matches('/').to_string()
        }
    }

    pub fn set_wasm_rules_engine(mut self, enable: bool) -> Self {
        self.wasm_rules_engine_enabled = self.wasm_rules_engine_enabled || enable;
        return self;
    }
    
    pub fn set_port(mut self, port: u16) -> Self {
        self.port = port;
        return self;
    }

    pub fn set_max_size(mut self, max_size: usize) -> Self {
        self.max_size = max_size;
        return self;
    }

    pub fn set_log_level(mut self, log_level: String) -> Self {
        self.log_level = log_level;
        return self;
    }

    pub fn get_tcp_listener(&mut self) -> std::io::Result<TcpListener> {
        if let Some(listener) = &self.tcp_listener {
            return Ok(listener.try_clone()?);
        }
        else {
            let listener = TcpListener::bind(format!("0.0.0.0:{}", self.port))?;
            self.tcp_listener = Some(listener.try_clone()?);
            return Ok(listener);
        }
        
    }




}
