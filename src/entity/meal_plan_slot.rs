//! Meal plan slot entity
//! One slot = one meal in the weekly plan

use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "meal_plan_slots")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i64,

    pub meal_plan_id: i64,
    pub recipe_id: i64,

    /// 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
    pub day_of_week: i16,

    /// "breakfast" | "lunch" | "dinner" | "snack"
    #[sea_orm(column_type = "Text")]
    pub meal_type: String,

    /// Override the recipe's default serving count (e.g. for a larger household)
    pub servings_override: Option<i32>,

    /// Whether the user has marked this meal as completed
    pub is_completed: bool,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::meal_plan::Entity",
        from = "Column::MealPlanId",
        to = "super::meal_plan::Column::Id",
        on_update = "Cascade",
        on_delete = "Cascade"
    )]
    MealPlan,

    #[sea_orm(
        belongs_to = "super::recipe::Entity",
        from = "Column::RecipeId",
        to = "super::recipe::Column::Id",
        on_update = "Cascade",
        on_delete = "Restrict"
    )]
    Recipe,
}

impl Related<super::meal_plan::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::MealPlan.def()
    }
}

impl Related<super::recipe::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Recipe.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
