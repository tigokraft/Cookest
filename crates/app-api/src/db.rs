//! Database connection bootstrap.
//!
//! Thin wrapper around the shared `establish_connection` helper so that
//! `app-api` only needs to pass its typed [`Config`] rather than raw strings.

use crate::config::Config;
use sea_orm::DatabaseConnection;

/// Build and return a SeaORM [`DatabaseConnection`] pool.
///
/// Reads the database URL from `config` (which in turn came from
/// `APP_DATABASE_URL` or `DATABASE_URL`).  Pool sizing and timeout
/// defaults are set by `cookest_shared::db::establish_connection`;
/// see that crate for tuning knobs.
pub async fn establish_connection(config: &Config) -> Result<DatabaseConnection, sea_orm::DbErr> {
    cookest_shared::db::establish_connection(config.database_url()).await
}
