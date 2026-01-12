//! JWT Authentication Middleware
//! 
//! Extracts and validates JWT from Authorization header
//! Injects authenticated user claims into request extensions

use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error, HttpMessage,
};
use futures::future::{ok, LocalBoxFuture, Ready};
use std::rc::Rc;
use std::sync::Arc;

use crate::errors::AppError;
use crate::services::token::{Claims, TokenService};

/// Middleware factory for JWT authentication
pub struct JwtAuth {
    token_service: Arc<TokenService>,
}

impl JwtAuth {
    pub fn new(token_service: Arc<TokenService>) -> Self {
        Self { token_service }
    }
}

impl<S, B> Transform<S, ServiceRequest> for JwtAuth
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = JwtAuthMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ok(JwtAuthMiddleware {
            service: Rc::new(service),
            token_service: self.token_service.clone(),
        })
    }
}

pub struct JwtAuthMiddleware<S> {
    service: Rc<S>,
    token_service: Arc<TokenService>,
}

impl<S, B> Service<ServiceRequest> for JwtAuthMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = self.service.clone();
        let token_service = self.token_service.clone();

        Box::pin(async move {
            // Extract token from Authorization header
            let auth_header = req
                .headers()
                .get("Authorization")
                .and_then(|h| h.to_str().ok());

            let token = match auth_header {
                Some(header) if header.starts_with("Bearer ") => &header[7..],
                _ => {
                    return Err(AppError::InvalidToken.into());
                }
            };

            // Validate token
            let claims = token_service.validate_access_token(token)?;

            // Store claims in request extensions for handlers to access
            req.extensions_mut().insert(claims);

            // Continue to the handler
            service.call(req).await
        })
    }
}

/// Extractor for authenticated user claims
pub struct AuthenticatedUser(pub Claims);

impl std::ops::Deref for AuthenticatedUser {
    type Target = Claims;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
