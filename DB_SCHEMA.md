# Cookest Database Schema

This document outlines the PostgreSQL database schema for the Cookest API, managed via SeaORM.

## Core Entities

### 1. `users`
**Purpose**: Stores user accounts, authentication details, and profile settings.
*   `id` (UUID, Primary Key)
*   `email` (VARCHAR, Unique)
*   `name` (VARCHAR)
*   `password_hash` (TEXT)
*   `refresh_token_hash` (TEXT, Nullable)
*   `household_size` (INTEGER, Default: 1)
*   `dietary_restrictions` (TEXT[], Array of strings)
*   `allergies` (TEXT[], Array of strings)
*   `avatar_url` (TEXT)
*   `is_email_verified` (BOOLEAN)
*   `two_factor_enabled` (BOOLEAN)
*   `totp_secret` (TEXT, Nullable)
*   `failed_login_attempts` (INTEGER)
*   `locked_until` (TIMESTAMPTZ, Nullable)

### 2. `user_preferences`
**Purpose**: ML vector for personalized recipe and meal plan recommendations.
*   `user_id` (UUID, Primary Key, Foreign Key to `users`)
*   `cuisine_weights` (JSONB)
*   `ingredient_weights` (JSONB)
*   `macro_bias` (JSONB)
*   `difficulty_weights` (JSONB)
*   `preferred_time_min` (INTEGER)
*   `interaction_count` (INTEGER)

---

## Ingredients & Nutrition

### 3. `ingredients`
**Purpose**: Centralized dictionary of raw ingredients.
*   `id` (BIGSERIAL, Primary Key)
*   `name` (TEXT, Unique)
*   `category` (TEXT)
*   `fdc_id` (INTEGER, USDA FoodData Central ID)
*   `off_id` (TEXT, Open Food Facts ID)

### 4. `ingredient_nutrients`
**Purpose**: Nutritional facts per 100g of an ingredient.
*   `id` (BIGSERIAL, Primary Key)
*   `ingredient_id` (BIGINT, Foreign Key to `ingredients`)
*   *Macros*: `calories`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g`, `sugar_g`, etc. (NUMERIC)
*   `micronutrients` (JSONB)

### 5. `portion_sizes`
**Purpose**: Converts descriptive portions (e.g., "1 medium apple") to grams.
*   `id` (BIGSERIAL, Primary Key)
*   `ingredient_id` (BIGINT, Foreign Key to `ingredients`)
*   `description` (TEXT)
*   `weight_grams` (NUMERIC)
*   `unit` (TEXT)

---

## Recipes

### 6. `recipes`
**Purpose**: Core recipe details.
*   `id` (BIGSERIAL, Primary Key)
*   `name` (TEXT)
*   `slug` (TEXT, Unique)
*   `description`, `cuisine`, `category`, `difficulty` (TEXT)
*   `servings`, `prep_time_min`, `cook_time_min`, `total_time_min` (INTEGER)
*   *Dietary flags*: `is_vegetarian`, `is_vegan`, `is_gluten_free`, `is_dairy_free`, `is_nut_free` (BOOLEAN)
*   `average_rating` (NUMERIC), `rating_count` (INTEGER)

### 7. `recipe_ingredients`
**Purpose**: Joins recipes to ingredients with specific quantities.
*   `id` (BIGSERIAL, Primary Key)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)
*   `ingredient_id` (BIGINT, Foreign Key to `ingredients`)
*   `quantity`, `quantity_grams` (NUMERIC)
*   `unit`, `notes` (TEXT)
*   `display_order` (INTEGER)

### 8. `recipe_steps`
**Purpose**: Sequential cooking instructions.
*   `id` (BIGSERIAL, Primary Key)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)
*   `step_number` (INTEGER)
*   `instruction`, `image_url`, `tip` (TEXT)
*   `duration_min` (INTEGER)

### 9. `recipe_images`
**Purpose**: Multiple images per recipe.
*   `id` (BIGSERIAL, Primary Key)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)
*   `url`, `image_type`, `source` (TEXT)
*   `is_primary` (BOOLEAN)
*   `width`, `height` (INTEGER)

### 10. `recipe_nutrition`
**Purpose**: Precomputed/cached nutritional totals for a recipe.
*   `id` (BIGSERIAL, Primary Key)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)
*   `per_serving` (BOOLEAN)
*   *Macros*: `calories`, `protein_g`, `carbs_g`, `fat_g`, etc. (NUMERIC)
*   `micronutrients` (JSONB)

---

## User Interaction

### 11. `user_favorites`
**Purpose**: Recipes saved by users.
*   `id` (BIGSERIAL, Primary Key)
*   `user_id` (UUID, Foreign Key to `users`)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)

### 12. `recipe_ratings`
**Purpose**: 1-5 star ratings and reviews.
*   `id` (BIGSERIAL, Primary Key)
*   `user_id` (UUID, Foreign Key to `users`)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)
*   `rating` (SMALLINT, 1-5)
*   `comment` (TEXT)

### 13. `cooking_history`
**Purpose**: Log of dishes cooked (updates ML affinities).
*   `id` (BIGSERIAL, Primary Key)
*   `user_id` (UUID, Foreign Key to `users`)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)
*   `servings_made` (INTEGER)
*   `inventory_deducted` (BOOLEAN)

---

## Pantry & Planning

### 14. `inventory_items`
**Purpose**: Current user pantry/fridge stock.
*   `id` (BIGSERIAL, Primary Key)
*   `user_id` (UUID, Foreign Key to `users`)
*   `ingredient_id` (BIGINT, Foreign Key to `ingredients`)
*   `custom_name` (TEXT)
*   `quantity` (NUMERIC)
*   `unit` (TEXT)
*   `expiry_date` (DATE)
*   `storage_location` (TEXT)

### 15. `meal_plans`
**Purpose**: Weekly meal schedules.
*   `id` (BIGSERIAL, Primary Key)
*   `user_id` (UUID, Foreign Key to `users`)
*   `week_start` (DATE)
*   `is_ai_generated` (BOOLEAN)

### 16. `meal_plan_slots`
**Purpose**: Specific meals assigned to days in a meal plan.
*   `id` (BIGSERIAL, Primary Key)
*   `meal_plan_id` (BIGINT, Foreign Key to `meal_plans`)
*   `recipe_id` (BIGINT, Foreign Key to `recipes`)
*   `day_of_week` (SMALLINT, 0-6)
*   `meal_type` (TEXT: breakfast, lunch, dinner, snack)
*   `servings_override` (INTEGER)
*   `is_completed` (BOOLEAN)

---

## AI Assistant (Chat)

### 17. `chat_sessions`
**Purpose**: Grouping context for an AI conversation.
*   `id` (BIGSERIAL, Primary Key)
*   `user_id` (UUID, Foreign Key to `users`)
*   `current_recipe_id` (BIGINT, Nullable, Foreign Key to `recipes`)
*   `title` (TEXT)

### 18. `chat_messages`
**Purpose**: Conversation history passed to the LLM.
*   `id` (BIGSERIAL, Primary Key)
*   `session_id` (BIGINT, Foreign Key to `chat_sessions`)
*   `role` (TEXT: 'user', 'assistant', 'system')
*   `content` (TEXT)
*   `tokens_used` (INTEGER)

*(Note: All tables include standard `created_at` and `updated_at` timestamps using `TIMESTAMPTZ`)*
