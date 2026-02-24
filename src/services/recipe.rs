//! Recipe service — queries recipes with filtering, pagination, and full detail loads

use sea_orm::{
    ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, QueryOrder, QuerySelect,
    PaginatorTrait, QueryTrait, Condition,
};

use crate::entity::{
    recipe, recipe_ingredient, recipe_step, recipe_image, recipe_nutrition, ingredient,
};
use crate::errors::AppError;
use crate::models::recipe::*;

pub struct RecipeService {
    db: DatabaseConnection,
}

impl RecipeService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    /// List recipes with filters and pagination
    pub async fn list_recipes(
        &self,
        query: RecipeQuery,
    ) -> Result<PaginatedResponse<RecipeListItem>, AppError> {
        let page = query.page.unwrap_or(1).max(1);
        let per_page = query.per_page.unwrap_or(20).min(50);

        let mut condition = Condition::all();

        // Dietary filters
        if query.vegetarian == Some(true) {
            condition = condition.add(recipe::Column::IsVegetarian.eq(true));
        }
        if query.vegan == Some(true) {
            condition = condition.add(recipe::Column::IsVegan.eq(true));
        }
        if query.gluten_free == Some(true) {
            condition = condition.add(recipe::Column::IsGlutenFree.eq(true));
        }
        if query.dairy_free == Some(true) {
            condition = condition.add(recipe::Column::IsDairyFree.eq(true));
        }

        // Text filters
        if let Some(cuisine) = &query.cuisine {
            condition = condition.add(recipe::Column::Cuisine.eq(cuisine));
        }
        if let Some(category) = &query.category {
            condition = condition.add(recipe::Column::Category.eq(category));
        }
        if let Some(difficulty) = &query.difficulty {
            condition = condition.add(recipe::Column::Difficulty.eq(difficulty));
        }
        if let Some(max_time) = query.max_time {
            condition = condition.add(recipe::Column::TotalTimeMin.lte(max_time));
        }

        // Full-text search on name using ILIKE (pg_trgm handles performance)
        if let Some(ref q) = query.q {
            let pattern = format!("%{}%", q);
            condition = condition.add(recipe::Column::Name.like(pattern));
        }

        let paginator = recipe::Entity::find()
            .filter(condition)
            .order_by_asc(recipe::Column::Name)
            .paginate(&self.db, per_page);

        let total = paginator.num_items().await?;
        let recipes = paginator.fetch_page(page - 1).await?;

        // Fetch primary images for each recipe
        let recipe_ids: Vec<i64> = recipes.iter().map(|r| r.id).collect();
        let images = recipe_image::Entity::find()
            .filter(recipe_image::Column::RecipeId.is_in(recipe_ids))
            .filter(recipe_image::Column::IsPrimary.eq(true))
            .all(&self.db)
            .await?;

        let items = recipes
            .into_iter()
            .map(|r| {
                let primary_image = images
                    .iter()
                    .find(|img| img.recipe_id == r.id)
                    .map(|img| img.url.clone());

                RecipeListItem {
                    id: r.id,
                    name: r.name,
                    slug: r.slug,
                    cuisine: r.cuisine,
                    category: r.category,
                    difficulty: r.difficulty,
                    servings: r.servings,
                    total_time_min: r.total_time_min,
                    is_vegetarian: r.is_vegetarian,
                    is_vegan: r.is_vegan,
                    is_gluten_free: r.is_gluten_free,
                    is_dairy_free: r.is_dairy_free,
                    average_rating: r.average_rating,
                    rating_count: r.rating_count,
                    primary_image_url: primary_image,
                }
            })
            .collect();

        Ok(PaginatedResponse {
            data: items,
            total,
            page,
            per_page,
            total_pages: (total as f64 / per_page as f64).ceil() as u64,
        })
    }

    /// Get full recipe detail by ID
    pub async fn get_recipe(&self, id: i64) -> Result<RecipeDetail, AppError> {
        let recipe = recipe::Entity::find_by_id(id)
            .one(&self.db)
            .await?
            .ok_or(AppError::NotFound("Recipe".into()))?;

        // Load ingredients with ingredient names
        let raw_ingredients = recipe_ingredient::Entity::find()
            .filter(recipe_ingredient::Column::RecipeId.eq(id))
            .order_by_asc(recipe_ingredient::Column::DisplayOrder)
            .all(&self.db)
            .await?;

        let ingredient_ids: Vec<i64> = raw_ingredients.iter().map(|i| i.ingredient_id).collect();
        let ingredients_map = ingredient::Entity::find()
            .filter(ingredient::Column::Id.is_in(ingredient_ids))
            .all(&self.db)
            .await?
            .into_iter()
            .map(|ing| (ing.id, ing.name))
            .collect::<std::collections::HashMap<_, _>>();

        let ingredients = raw_ingredients
            .into_iter()
            .map(|ri| RecipeIngredientDetail {
                id: ri.id,
                ingredient_id: ri.ingredient_id,
                ingredient_name: ingredients_map
                    .get(&ri.ingredient_id)
                    .cloned()
                    .unwrap_or_default(),
                quantity: ri.quantity,
                unit: ri.unit,
                quantity_grams: ri.quantity_grams,
                notes: ri.notes,
                display_order: ri.display_order,
            })
            .collect();

        // Load steps
        let steps = recipe_step::Entity::find()
            .filter(recipe_step::Column::RecipeId.eq(id))
            .order_by_asc(recipe_step::Column::StepNumber)
            .all(&self.db)
            .await?
            .into_iter()
            .map(|s| RecipeStepDetail {
                id: s.id,
                step_number: s.step_number,
                instruction: s.instruction,
                duration_min: s.duration_min,
                image_url: s.image_url,
                tip: s.tip,
            })
            .collect();

        // Load images
        let images = recipe_image::Entity::find()
            .filter(recipe_image::Column::RecipeId.eq(id))
            .all(&self.db)
            .await?
            .into_iter()
            .map(|img| RecipeImageDetail {
                id: img.id,
                url: img.url,
                image_type: img.image_type,
                is_primary: img.is_primary,
                width: img.width,
                height: img.height,
            })
            .collect();

        // Load nutrition
        let nutrition = recipe_nutrition::Entity::find()
            .filter(recipe_nutrition::Column::RecipeId.eq(id))
            .one(&self.db)
            .await?
            .map(|n| RecipeNutritionDetail {
                calories: n.calories,
                protein_g: n.protein_g,
                carbs_g: n.carbs_g,
                fat_g: n.fat_g,
                fiber_g: n.fiber_g,
                sugar_g: n.sugar_g,
                sodium_mg: n.sodium_mg,
                saturated_fat_g: n.saturated_fat_g,
                per_serving: n.per_serving,
            });

        Ok(RecipeDetail {
            id: recipe.id,
            name: recipe.name,
            slug: recipe.slug,
            description: recipe.description,
            cuisine: recipe.cuisine,
            category: recipe.category,
            difficulty: recipe.difficulty,
            servings: recipe.servings,
            prep_time_min: recipe.prep_time_min,
            cook_time_min: recipe.cook_time_min,
            total_time_min: recipe.total_time_min,
            is_vegetarian: recipe.is_vegetarian,
            is_vegan: recipe.is_vegan,
            is_gluten_free: recipe.is_gluten_free,
            is_dairy_free: recipe.is_dairy_free,
            is_nut_free: recipe.is_nut_free,
            source_url: recipe.source_url,
            average_rating: recipe.average_rating,
            rating_count: recipe.rating_count,
            ingredients,
            steps,
            images,
            nutrition,
        })
    }

    /// Get recipe by slug
    pub async fn get_recipe_by_slug(&self, slug: &str) -> Result<RecipeDetail, AppError> {
        let recipe = recipe::Entity::find()
            .filter(recipe::Column::Slug.eq(slug))
            .one(&self.db)
            .await?
            .ok_or(AppError::NotFound("Recipe".into()))?;

        self.get_recipe(recipe.id).await
    }
}
