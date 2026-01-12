use actix_web::{HttpResponse, ResponseError};
use sea_orm::DbErr;
use serde::Serialize;
use std::fmt;
use validator::ValidationErrors;

/// Application error types with security-conscious external messages
#[derive(Debug)]
pub enum AppError {
    /// Database errors - log internally, return generic message
    Database(DbErr),
    /// Validation errors - safe to return details
    Validation(ValidationErrors),
    /// Authentication failed - generic message to prevent enumeration
    AuthenticationFailed,
    /// Invalid token
    InvalidToken,
    /// Token expired
    TokenExpired,
    /// User already exists - generic message to prevent email enumeration
    UserAlreadyExists,
    /// Internal server error
    Internal(String),
    /// Rate limit exceeded
    RateLimitExceeded,
}

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    details: Option<serde_json::Value>,
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::Database(_) => write!(f, "Database error"),
            AppError::Validation(e) => write!(f, "Validation error: {}", e),
            AppError::AuthenticationFailed => write!(f, "Invalid credentials"),
            AppError::InvalidToken => write!(f, "Invalid token"),
            AppError::TokenExpired => write!(f, "Token expired"),
            AppError::UserAlreadyExists => write!(f, "Registration failed"),
            AppError::Internal(_) => write!(f, "Internal server error"),
            AppError::RateLimitExceeded => write!(f, "Too many requests"),
        }
    }
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, error_response) = match self {
            AppError::Database(e) => {
                // Log the actual error internally
                tracing::error!("Database error: {:?}", e);
                (
                    actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                    ErrorResponse {
                        error: "An internal error occurred".to_string(),
                        details: None,
                    },
                )
            }
            AppError::Validation(errors) => {
                // Validation errors are safe to expose
                (
                    actix_web::http::StatusCode::BAD_REQUEST,
                    ErrorResponse {
                        error: "Validation failed".to_string(),
                        details: Some(serde_json::to_value(errors).unwrap_or_default()),
                    },
                )
            }
            AppError::AuthenticationFailed => {
                // Generic message prevents email/password enumeration
                (
                    actix_web::http::StatusCode::UNAUTHORIZED,
                    ErrorResponse {
                        error: "Invalid email or password".to_string(),
                        details: None,
                    },
                )
            }
            AppError::InvalidToken => (
                actix_web::http::StatusCode::UNAUTHORIZED,
                ErrorResponse {
                    error: "Invalid or malformed token".to_string(),
                    details: None,
                },
            ),
            AppError::TokenExpired => (
                actix_web::http::StatusCode::UNAUTHORIZED,
                ErrorResponse {
                    error: "Token has expired".to_string(),
                    details: None,
                },
            ),
            AppError::UserAlreadyExists => {
                // Generic message prevents email enumeration
                // We return 400 rather than 409 to not leak info
                tracing::warn!("Registration attempt with existing email");
                (
                    actix_web::http::StatusCode::BAD_REQUEST,
                    ErrorResponse {
                        error: "Registration failed. Please try again.".to_string(),
                        details: None,
                    },
                )
            }
            AppError::Internal(e) => {
                tracing::error!("Internal error: {}", e);
                (
                    actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                    ErrorResponse {
                        error: "An internal error occurred".to_string(),
                        details: None,
                    },
                )
            }
            AppError::RateLimitExceeded => (
                actix_web::http::StatusCode::TOO_MANY_REQUESTS,
                ErrorResponse {
                    error: "Too many requests. Please try again later.".to_string(),
                    details: None,
                },
            ),
        };

        HttpResponse::build(status).json(error_response)
    }
}

impl From<DbErr> for AppError {
    fn from(err: DbErr) -> Self {
        AppError::Database(err)
    }
}

impl From<ValidationErrors> for AppError {
    fn from(err: ValidationErrors) -> Self {
        AppError::Validation(err)
    }
}
