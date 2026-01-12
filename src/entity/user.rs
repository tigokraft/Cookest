//! User entity for SeaORM
//! 
//! Security notes:
//! - password_hash is never serialized to JSON
//! - refresh_token_hash stored for secure token rotation

use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "users")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    
    #[sea_orm(unique)]
    pub email: String,
    
    /// Argon2id hashed password - NEVER expose this
    #[sea_orm(column_type = "Text")]
    pub password_hash: String,
    
    /// Hashed refresh token for secure token rotation
    #[sea_orm(column_type = "Text", nullable)]
    pub refresh_token_hash: Option<String>,
    
    /// Tracks failed login attempts for account lockout
    pub failed_login_attempts: i32,
    
    /// Account lockout until this time
    pub locked_until: Option<DateTimeWithTimeZone>,
    
    pub created_at: DateTimeWithTimeZone,
    pub updated_at: DateTimeWithTimeZone,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

/// Safe user representation for API responses
#[derive(Debug, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub created_at: DateTimeWithTimeZone,
}

impl From<Model> for UserResponse {
    fn from(user: Model) -> Self {
        Self {
            id: user.id,
            email: user.email,
            created_at: user.created_at,
        }
    }
}
