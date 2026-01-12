use secrecy::{ExposeSecret, SecretString};
use std::env;

#[derive(Clone)]
pub struct Config {
    pub database_url: SecretString,
    pub jwt_secret: SecretString,
    pub jwt_access_expiry_seconds: i64,
    pub jwt_refresh_expiry_seconds: i64,
    pub host: String,
    pub port: u16,
    pub cors_origin: String,
}

impl Config {
    pub fn from_env() -> Result<Self, ConfigError> {
        dotenvy::dotenv().ok();

        let database_url = env::var("DATABASE_URL")
            .map_err(|_| ConfigError::Missing("DATABASE_URL"))?;

        let jwt_secret = env::var("JWT_SECRET")
            .map_err(|_| ConfigError::Missing("JWT_SECRET"))?;

        // Validate JWT secret length (minimum 256 bits = 32 bytes)
        if jwt_secret.len() < 32 {
            return Err(ConfigError::InvalidValue(
                "JWT_SECRET must be at least 32 characters (256 bits)",
            ));
        }

        let jwt_access_expiry_seconds: i64 = env::var("JWT_ACCESS_EXPIRY_SECONDS")
            .unwrap_or_else(|_| "900".to_string()) // 15 minutes default
            .parse()
            .map_err(|_| ConfigError::InvalidValue("JWT_ACCESS_EXPIRY_SECONDS must be a number"))?;

        let jwt_refresh_expiry_seconds: i64 = env::var("JWT_REFRESH_EXPIRY_SECONDS")
            .unwrap_or_else(|_| "604800".to_string()) // 7 days default
            .parse()
            .map_err(|_| ConfigError::InvalidValue("JWT_REFRESH_EXPIRY_SECONDS must be a number"))?;

        let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
        
        let port: u16 = env::var("PORT")
            .unwrap_or_else(|_| "8080".to_string())
            .parse()
            .map_err(|_| ConfigError::InvalidValue("PORT must be a valid port number"))?;

        let cors_origin = env::var("CORS_ORIGIN")
            .unwrap_or_else(|_| "http://localhost:3000".to_string());

        Ok(Self {
            database_url: SecretString::from(database_url),
            jwt_secret: SecretString::from(jwt_secret),
            jwt_access_expiry_seconds,
            jwt_refresh_expiry_seconds,
            host,
            port,
            cors_origin,
        })
    }

    pub fn database_url(&self) -> &str {
        self.database_url.expose_secret()
    }

    pub fn jwt_secret(&self) -> &str {
        self.jwt_secret.expose_secret()
    }
}

#[derive(Debug)]
pub enum ConfigError {
    Missing(&'static str),
    InvalidValue(&'static str),
}

impl std::fmt::Display for ConfigError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ConfigError::Missing(var) => write!(f, "Missing environment variable: {}", var),
            ConfigError::InvalidValue(msg) => write!(f, "Invalid configuration: {}", msg),
        }
    }
}

impl std::error::Error for ConfigError {}
