//! Secure Authentication API with Actix-web
//! 
//! Features:
//! - Argon2id password hashing
//! - JWT with refresh token rotation
//! - Rate limiting
//! - HttpOnly cookies
//! - Security headers

mod config;
mod db;
mod entity;
mod errors;
mod handlers;
mod middleware;
mod models;
mod services;
mod validation;

use actix_cors::Cors;
use actix_web::{http::header, middleware::Logger, web, App, HttpServer};
use std::sync::Arc;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::config::Config;
use crate::handlers::configure_auth;
use crate::middleware::RateLimit;
use crate::services::{AuthService, TokenService};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info,auth_api=debug".to_string()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    tracing::info!("Starting Authentication API");

    // Load configuration
    let config = Config::from_env().expect("Failed to load configuration");

    let bind_address = format!("{}:{}", config.host, config.port);
    let cors_origin = config.cors_origin.clone();

    // Connect to database
    let db = db::establish_connection(&config)
        .await
        .expect("Failed to connect to database");

    // Run migrations
    tracing::info!("Running database migrations...");
    // Note: In production, you'd use sea-orm-cli for migrations
    // For now, we'll create the table directly
    use sea_orm::{ConnectionTrait, Statement};
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Postgres,
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY,
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            refresh_token_hash TEXT,
            failed_login_attempts INTEGER NOT NULL DEFAULT 0,
            locked_until TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        "#.to_string(),
    ))
    .await
    .expect("Failed to run migrations");
    tracing::info!("Migrations complete");

    // Initialize services
    let token_service = Arc::new(TokenService::new(&config));
    let auth_service = Arc::new(AuthService::new(db, TokenService::new(&config)));

    tracing::info!("Server starting on {}", bind_address);

    HttpServer::new(move || {
        // Configure CORS
        let cors = Cors::default()
            .allowed_origin(&cors_origin)
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE", "OPTIONS"])
            .allowed_headers(vec![
                header::AUTHORIZATION,
                header::ACCEPT,
                header::CONTENT_TYPE,
            ])
            .supports_credentials()
            .max_age(3600);

        App::new()
            // Security: Request body size limit (1 MB)
            .app_data(web::JsonConfig::default().limit(1024 * 1024))
            // Logging
            .wrap(Logger::default())
            // CORS
            .wrap(cors)
            // Rate limiting for auth endpoints
            .wrap(RateLimit::strict())
            // Services
            .app_data(web::Data::new(auth_service.clone()))
            .app_data(web::Data::new(token_service.clone()))
            // Routes
            .configure(configure_auth)
            // Health check
            .route("/health", web::get().to(|| async {
                actix_web::HttpResponse::Ok().json(serde_json::json!({
                    "status": "healthy"
                }))
            }))
    })
    .bind(&bind_address)?
    .run()
    .await
}
