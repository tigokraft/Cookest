//! Recipe HTTP handlers
//!
//! Routes:
//! GET  /api/recipes            — list with filters + pagination
//! GET  /api/recipes/search     — search by name (alias, same as ?q=)
//! GET  /api/recipes/:id        — full detail by ID
//! GET  /api/recipes/slug/:slug — full detail by slug

use actix_web::{web, HttpResponse};
use std::sync::Arc;

use crate::errors::AppError;
use crate::models::recipe::RecipeQuery;
use crate::services::RecipeService;

/// GET /api/recipes
/// List all recipes with optional filters and pagination
pub async fn list_recipes(
    recipe_service: web::Data<Arc<RecipeService>>,
    query: web::Query<RecipeQuery>,
) -> Result<HttpResponse, AppError> {
    let result = recipe_service.list_recipes(query.into_inner()).await?;
    Ok(HttpResponse::Ok().json(result))
}

/// GET /api/recipes/:id
/// Get full recipe detail by numeric ID
pub async fn get_recipe(
    recipe_service: web::Data<Arc<RecipeService>>,
    path: web::Path<i64>,
) -> Result<HttpResponse, AppError> {
    let id = path.into_inner();
    let recipe = recipe_service.get_recipe(id).await?;
    Ok(HttpResponse::Ok().json(recipe))
}

/// GET /api/recipes/slug/:slug
/// Get full recipe detail by URL slug
pub async fn get_recipe_by_slug(
    recipe_service: web::Data<Arc<RecipeService>>,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let slug = path.into_inner();
    let recipe = recipe_service.get_recipe_by_slug(&slug).await?;
    Ok(HttpResponse::Ok().json(recipe))
}

/// Configure recipe routes
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/recipes")
            .route("", web::get().to(list_recipes))
            .route("/slug/{slug}", web::get().to(get_recipe_by_slug))
            .route("/{id}", web::get().to(get_recipe)),
    );
}
