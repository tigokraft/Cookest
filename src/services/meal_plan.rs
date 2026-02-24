//! Meal Plan Service — AI-assisted weekly meal planning
//!
//! Scoring formula per recipe (weights sum to 100):
//!   ingredient_coverage × 30  — prefer recipes user already has ingredients for
//!   expiry_urgency      × 25  — prioritise ingredients close to expiry
//!   ml_preference       × 25  — learned user taste via PreferenceService
//!   nutrition_balance   × 12  — fill the week's nutritional gaps
//!   variety_bonus       ×  8  — penalise recently cooked recipes

use chrono::{Duration, NaiveDate, Utc};
use sea_orm::{
    ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, QueryOrder,
    ActiveModelTrait, Set,
};
use std::collections::HashMap;
use uuid::Uuid;

use crate::entity::{
    recipe, recipe_ingredient, recipe_nutrition, inventory_item, cooking_history,
    user_favorite, meal_plan, meal_plan_slot,
};
use crate::errors::AppError;
use crate::services::PreferenceService;

/// Ideal daily nutrition targets (per person)
const DAILY_CALORIES: f64 = 2000.0;
const DAILY_PROTEIN_G: f64 = 50.0;
const DAILY_CARBS_G: f64 = 275.0;
const DAILY_FAT_G: f64 = 78.0;
const DAILY_FIBER_G: f64 = 28.0;

/// Score for each candidate recipe
#[derive(Debug)]
struct RecipeScore {
    recipe_id: i64,
    total_score: f64,
    cuisine: Option<String>,
    category: Option<String>,
    total_time_min: Option<i32>,
}

pub struct MealPlanService {
    db: DatabaseConnection,
    preference_service: PreferenceService,
}

impl MealPlanService {
    pub fn new(db: DatabaseConnection) -> Self {
        let pref_db = db.clone();
        Self {
            db,
            preference_service: PreferenceService::new(pref_db),
        }
    }

    /// Generate a full week meal plan for a user and save it to the database
    pub async fn generate_week_plan(
        &self,
        user_id: Uuid,
        household_size: i32,
        week_start: NaiveDate,
    ) -> Result<meal_plan::Model, AppError> {
        // ── 1. Load context data ──────────────────────────────────────────────

        // User's inventory
        let inventory = inventory_item::Entity::find()
            .filter(inventory_item::Column::UserId.eq(user_id))
            .all(&self.db)
            .await?;

        // Ingredients user has (set of ingredient_ids)
        let user_ingredient_ids: std::collections::HashSet<i64> =
            inventory.iter().map(|i| i.ingredient_id).collect();

        // Ingredients expiring within 7 days
        let expiry_threshold = Utc::now().date_naive() + Duration::days(7);
        let expiring_ids: std::collections::HashSet<i64> = inventory
            .iter()
            .filter(|i| {
                i.expiry_date
                    .map(|d| d <= expiry_threshold)
                    .unwrap_or(false)
            })
            .map(|i| i.ingredient_id)
            .collect();

        // Recipes cooked in last 14 days (to apply variety penalty)
        let two_weeks_ago = Utc::now().fixed_offset() - Duration::days(14);
        let recent_recipes: std::collections::HashSet<i64> = cooking_history::Entity::find()
            .filter(cooking_history::Column::UserId.eq(user_id))
            .filter(cooking_history::Column::CookedAt.gte(two_weeks_ago))
            .all(&self.db)
            .await?
            .into_iter()
            .map(|h| h.recipe_id)
            .collect();

        // User's favourite recipes (preference boost)
        let favourite_ids: std::collections::HashSet<i64> = user_favorite::Entity::find()
            .filter(user_favorite::Column::UserId.eq(user_id))
            .all(&self.db)
            .await?
            .into_iter()
            .map(|f| f.recipe_id)
            .collect();

        // All candidate recipes (excluding recently cooked)
        let all_recipes = recipe::Entity::find()
            .order_by_asc(recipe::Column::Id)
            .all(&self.db)
            .await?;

        // Load all recipe ingredients in bulk
        let all_recipe_ids: Vec<i64> = all_recipes.iter().map(|r| r.id).collect();
        let all_recipe_ingredients = recipe_ingredient::Entity::find()
            .filter(recipe_ingredient::Column::RecipeId.is_in(all_recipe_ids.clone()))
            .all(&self.db)
            .await?;

        // Group ingredients by recipe_id
        let mut ingredients_by_recipe: HashMap<i64, Vec<i64>> = HashMap::new();
        for ri in &all_recipe_ingredients {
            ingredients_by_recipe
                .entry(ri.recipe_id)
                .or_default()
                .push(ri.ingredient_id);
        }

        // Load all recipe nutrition in bulk
        let nutrition_by_recipe: HashMap<i64, _> = recipe_nutrition::Entity::find()
            .filter(recipe_nutrition::Column::RecipeId.is_in(all_recipe_ids))
            .all(&self.db)
            .await?
            .into_iter()
            .map(|n| (n.recipe_id, n))
            .collect();

        // ── 2. Score every recipe ─────────────────────────────────────────────

        let mut scored: Vec<RecipeScore> = Vec::new();

        // Track weekly nutrition totals (updated as we select recipes)
        let weekly_calories = 0.0_f64;
        let weekly_protein = 0.0_f64;

        for recipe in &all_recipes {
            // Skip recently cooked (last 7 days — full penalty)
            if recent_recipes.contains(&recipe.id) {
                continue;
            }

            let recipe_ing_ids = ingredients_by_recipe
                .get(&recipe.id)
                .cloned()
                .unwrap_or_default();

            // ── ingredient_coverage (0.0–1.0) ────────────────────────────────
            let total_ings = recipe_ing_ids.len().max(1);
            let owned_ings = recipe_ing_ids
                .iter()
                .filter(|id| user_ingredient_ids.contains(id))
                .count();
            let ingredient_coverage = owned_ings as f64 / total_ings as f64;

            // ── expiry_urgency (0.0–1.0) ──────────────────────────────────────
            let expiring_used = recipe_ing_ids
                .iter()
                .filter(|id| expiring_ids.contains(id))
                .count();
            // The more expiring ingredients a recipe uses, the higher the score
            let expiry_urgency = (expiring_used as f64 / total_ings as f64).min(1.0);

            // ── ml_preference (0.0–1.0) — scored against learned vector ──────
            let ml_preference = self
                .preference_service
                .score_recipe_for_user(user_id, recipe.id)
                .await
                .unwrap_or(0.5); // Default neutral if no preferences yet

            // ── variety_bonus (-0.3–0.1) ──────────────────────────────────────
            let variety_bonus = if recent_recipes.contains(&recipe.id) {
                -0.3
            } else if favourite_ids.contains(&recipe.id) {
                0.1 // Small boost for favourites
            } else {
                0.0
            };

            // ── nutrition_balance (0.0–1.0) ───────────────────────────────────
            // How much does adding this recipe help fill the weekly nutritional gap?
            let nutrition_balance = if let Some(n) = nutrition_by_recipe.get(&recipe.id) {
                // Scale by servings ratio (household_size / recipe.servings)
                let scale = household_size as f64 / recipe.servings.max(1) as f64;
                let cal = f64::try_from(n.calories.unwrap_or_default()).unwrap_or(0.0) * scale;
                let pro = f64::try_from(n.protein_g.unwrap_or_default()).unwrap_or(0.0) * scale;
                let _carb = f64::try_from(n.carbs_g.unwrap_or_default()).unwrap_or(0.0) * scale;
                let _fat = f64::try_from(n.fat_g.unwrap_or_default()).unwrap_or(0.0) * scale;
                let _fib = f64::try_from(n.fiber_g.unwrap_or_default()).unwrap_or(0.0) * scale;

                // Remaining weekly targets (7 meals selected, 21 total slots)
                let cal_gap = (DAILY_CALORIES * 7.0 - weekly_calories).max(0.0);
                let pro_gap = (DAILY_PROTEIN_G * 7.0 - weekly_protein).max(0.0);

                // Normalised score: does this recipe contribute meaningfully?
                let cal_score = (cal / cal_gap.max(1.0)).min(1.0);
                let pro_score = (pro / pro_gap.max(1.0)).min(1.0);
                (cal_score + pro_score) / 2.0
            } else {
                0.5 // No nutrition data — neutral
            };

            // ── Combined weighted score ────────────────────────────────────────
            let total_score = (ingredient_coverage * 0.30)
                + (expiry_urgency * 0.25)
                + (ml_preference * 0.25)
                + (nutrition_balance * 0.12)
                + (variety_bonus * 0.08);

            scored.push(RecipeScore {
                recipe_id: recipe.id,
                total_score,
                cuisine: recipe.cuisine.clone(),
                category: recipe.category.clone(),
                total_time_min: recipe.total_time_min,
            });
        }

        // Sort by score descending
        scored.sort_by(|a, b| b.total_score.partial_cmp(&a.total_score).unwrap());

        // ── 3. Greedy selection — 14 meals (2 per day × 7 days) ──────────────

        let mut selected: Vec<(i64, u8, &str)> = Vec::new(); // (recipe_id, day, meal_type)
        let mut used_recipe_ids: std::collections::HashSet<i64> = std::collections::HashSet::new();
        let mut used_cuisines_today: HashMap<u8, String> = HashMap::new();

        let mut score_iter = scored.iter();

        for day in 0u8..7 {
            // Lunch
            if let Some(recipe) = score_iter.find(|r| {
                !used_recipe_ids.contains(&r.recipe_id)
                    && self.fits_meal_type(&r.category, "lunch")
            }) {
                selected.push((recipe.recipe_id, day, "lunch"));
                used_recipe_ids.insert(recipe.recipe_id);
                if let Some(cuisine) = &recipe.cuisine {
                    used_cuisines_today.insert(day, cuisine.clone());
                }
            }

            // Dinner — ideally different cuisine from lunch
            if let Some(recipe) = score_iter.find(|r| {
                !used_recipe_ids.contains(&r.recipe_id)
                    && self.fits_meal_type(&r.category, "dinner")
                    && r.cuisine.as_ref() != used_cuisines_today.get(&day)
            }) {
                selected.push((recipe.recipe_id, day, "dinner"));
                used_recipe_ids.insert(recipe.recipe_id);
            }
        }

        // ── 4. Save meal plan + slots to database ─────────────────────────────

        // Upsert meal plan for this user/week
        let now = Utc::now().fixed_offset();

        // Delete existing plan for this week if it exists
        if let Some(existing) = meal_plan::Entity::find()
            .filter(meal_plan::Column::UserId.eq(user_id))
            .filter(meal_plan::Column::WeekStart.eq(week_start))
            .one(&self.db)
            .await?
        {
            // Delete all slots first (cascade would handle it, but explicit is safer)
            meal_plan_slot::Entity::delete_many()
                .filter(meal_plan_slot::Column::MealPlanId.eq(existing.id))
                .exec(&self.db)
                .await?;

            meal_plan::Entity::delete_by_id(existing.id)
                .exec(&self.db)
                .await?;
        }

        let plan = meal_plan::ActiveModel {
            user_id: Set(user_id),
            week_start: Set(week_start),
            is_ai_generated: Set(true),
            created_at: Set(now),
            updated_at: Set(now),
            ..Default::default()
        };

        let saved_plan = plan.insert(&self.db).await?;

        // Insert all slots
        for (recipe_id, day, meal_type) in selected {
            let slot = meal_plan_slot::ActiveModel {
                meal_plan_id: Set(saved_plan.id),
                recipe_id: Set(recipe_id),
                day_of_week: Set(day as i16),
                meal_type: Set(meal_type.to_string()),
                servings_override: Set(Some(household_size)),
                is_completed: Set(false),
                ..Default::default()
            };
            slot.insert(&self.db).await?;
        }

        Ok(saved_plan)
    }

    /// Heuristic: which meal types fit a recipe's category
    fn fits_meal_type(&self, category: &Option<String>, meal_type: &str) -> bool {
        match (category.as_deref(), meal_type) {
            (Some("breakfast"), "breakfast") => true,
            (Some("breakfast"), _) => false,
            (Some("dessert"), _) => false,
            (_, "lunch") => true,
            (_, "dinner") => true,
            _ => true,
        }
    }
}
