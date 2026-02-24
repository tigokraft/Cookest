pub mod auth;
pub mod recipe;
pub mod ingredient;
pub mod user;

pub use auth::configure as configure_auth;
pub use recipe::configure as configure_recipes;
pub use ingredient::configure as configure_ingredients;
pub use user::configure as configure_user;
