# Cookest - Personal AI Cooking Assistant

Cookest is a full-stack personal AI cooking assistant application. It helps users plan meals, discover recipes, manage kitchen inventory, and make healthy food choices with the help of an AI chat assistant.

## Architecture

The project is split into two main directories:

1.  **`api/` (Backend)**:
    *   **Language & Framework**: Rust with Actix-Web.
    *   **Database**: PostgreSQL managed via SeaORM and raw SQLX migrations.
    *   **Authentication**: Argon2id password hashing, JWT access tokens, and HttpOnly refresh token rotation.
    *   **AI Integration**: Connects to a local Ollama instance (e.g., `llama3.2`) to provide context-aware AI chat capabilities based on a user's inventory, allergies, and meal plans.

2.  **`UI/` (Frontend)**:
    *   **Framework**: Flutter.
    *   **Target Platforms**: Cross-platform (currently tested on Web/Chrome and macOS Native).
    *   **Features**: User authentication, recipe browsing, meal planning, and an AI chat interface.

## Branches & Workflows

*(Assuming standard Git Flow based on context)*

*   **`main`**: The primary branch containing the stable, production-ready code.
*   **Feature Branches**: For developing new features (the UI and API improvements).

## Running the Project Locally

### 1. Database & AI Services
Ensure you have Docker and Docker Compose installed.
```bash
cd api
docker-compose up -d
```
This starts the `auth_db` PostgreSQL container.

*(Optional)* Start your local Ollama instance if you want to use the AI chat features.

### 2. Backend API
```bash
cd api
# Ensure your .env file is properly configured with your DATABASE_URL
cargo run --release
```
The API will run on `http://127.0.0.1:3000`. It will automatically run database migrations on startup.

### 3. Frontend UI
```bash
cd UI
# To run on Chrome (Fastest for UI development and avoids Apple CodeSign issues)
flutter run -d chrome

# To run on macOS natively (Requires valid code signing / xattr clearing)
flutter run -d macos
```
