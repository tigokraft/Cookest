# Cookest

Cookest is an AI-assisted meal and kitchen management platform. This repository currently contains the **Rust backend API** that powers authentication, recipes, inventory tracking, meal planning, and AI chat workflows.

> Looking for the frontend? See the **UI branch note** in [UI Branch Overview](#ui-branch-overview).

🇵🇹 Portuguese (Portugal) version: [README.pt-PT.md](README.pt-PT.md).

## What the app does

Cookest combines structured food data and user context to support everyday cooking decisions:

- Account creation and secure sign-in.
- Recipe search and recipe detail retrieval.
- Ingredient search + nutrition metadata.
- Personal inventory management (including expiring-soon items).
- User profile preferences (household size, dietary restrictions, allergies).
- Meal plan generation and shopping list generation.
- Recipe interactions (ratings, favourites, “cooked” history).
- AI chat sessions that can use user context (inventory/preferences/history) to answer cooking questions.

## Tech stack

### Backend (this branch)

- **Language/Framework:** Rust + Actix Web
- **ORM/DB access:** SeaORM
- **Database:** PostgreSQL
- **Auth:** Argon2id password hashing + JWT access/refresh flow
- **Security middleware:** rate limiting, JWT auth middleware, CORS, secure cookie usage
- **AI integration:** Ollama-compatible local model endpoint

## API surface (high-level)

Cookest exposes REST-style endpoints under `/api/*`:

- `/api/auth/*` — register/login/refresh/logout
- `/api/recipes/*` — list recipes + fetch by id/slug
- `/api/ingredients/*` — search ingredients + fetch ingredient details
- `/api/inventory/*` — CRUD inventory and expiring items
- `/api/me/*` — profile, history, favourites
- `/api/meal-plans/*` — generate/current plan/shopping list/mark complete
- `/api/chat/*` — AI chat sessions and messages

For detailed setup and endpoint-oriented guidance, see [`docs/BUILD_AND_USAGE.md`](docs/BUILD_AND_USAGE.md).

## UI Branch Overview

The repository is organized around a stable **main/backend track**, and a separate **UI branch track** for Flutter client work.

- **Main branch focus:** backend API + schema + service logic.
- **UI branch focus:** Flutter application integrating with this API.

Recommended team workflow:

1. Keep API contracts stable in `main`.
2. Develop/polish user-facing screens in the UI branch.
3. Validate integration by pointing the UI branch at a running local API instance.
4. Merge UI updates after endpoint and environment compatibility checks.

If your local checkout only contains backend files, that is expected for this branch.

## Quick start

### 1) Start PostgreSQL

```bash
docker-compose up -d
```

### 2) Configure environment

Copy and edit:

```bash
cp .env.example .env
```

Then ensure values are valid for your local Postgres and JWT setup.

### 3) Run the API

```bash
cargo run
```

Default bind is `127.0.0.1:8080` unless overridden by environment variables.

## Documentation index

- Build, run, and operational docs: [`docs/BUILD_AND_USAGE.md`](docs/BUILD_AND_USAGE.md)
- Database schema + ER diagram: [`docs/database/SCHEMA.md`](docs/database/SCHEMA.md)
- Legacy schema notes: [`DB_SCHEMA.md`](DB_SCHEMA.md)

## Current scope notes

- This branch is API-centric.
- Migrations are applied at startup from SQL statements in `src/main.rs`.
- Ollama is optional; required only for AI chat endpoints.
