# Cookest API — Agent Instructions

You are working on the **Cookest API**, a Rust REST API built with Actix-Web 4, SeaORM, and PostgreSQL.

## Quick Reference

| Attribute | Value |
|-----------|-------|
| Language | Rust 1.78+ |
| Framework | Actix-Web 4 |
| ORM | SeaORM 1.1 |
| Database | PostgreSQL 15+ |
| Auth | Argon2id + JWT |
| AI | Ollama (llava + chat) |

## Documentation

📖 **Full documentation**: https://cookest-docs.vercel.app/docs (or run locally from `../docs/`)

Key pages:
- [Architecture Overview](../docs/content/docs/architecture/overview.mdx)
- [Repository Guide](../docs/content/docs/architecture/repositories.mdx)
- [Backend Getting Started](../docs/content/docs/backend/getting-started.mdx)
- [API Endpoints](../docs/content/docs/backend/endpoints/)
- [Database Schema](docs/database/SCHEMA.md)
- [Best Practices](../docs/content/docs/contributing/best-practices.mdx)
- [Agent Instructions](../docs/content/docs/ai/instructions.mdx)
- [Agentic Skills](../docs/content/docs/ai/skills.mdx)

## Architecture

```
src/
├── handlers/    ← Thin HTTP handlers (validate → call service → respond)
├── services/    ← All business logic (17 service files)
├── entity/      ← SeaORM entity definitions (20+ tables)
├── models/      ← DTOs (request/response types)
├── middleware/   ← JWT auth + rate limiting (governor)
├── validation/   ← Request validation rules
├── config.rs    ← Environment configuration
├── errors.rs    ← AppError definitions
├── db.rs        ← Database initialization
└── main.rs      ← App entry, route registration
```

## Key Rules

1. **Handlers are thin** — validate input, call service, return response
2. **Services own logic** — database queries, algorithms, external API calls
3. **Use `AppError`** for all errors — never `.unwrap()` or `panic!()` in handlers
4. **Pro features return 402** if user tier is insufficient
5. **Admin verification** — always check `is_admin` from DB, never trust JWT alone
6. **Refresh tokens** — stored as `SHA-256(raw_token)`, raw only in httpOnly cookie
7. **Idempotent migrations** — all use `IF NOT EXISTS`

## Commit Format

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `perf`, `build`, `ci`, `chore`  
Scopes: `auth`, `recipe`, `meal-plan`, `chat`, `store`, `subscription`, `middleware`

## MCP Server

For programmatic documentation access, use the MCP server at `../docs/mcp/`.

---

## Session Protocols

### Startup (every session — non-negotiable)

1. `vault_read("Agents/context.md")` — live project memory
2. `vault_read("Errors/error-log.md")` — past mistakes to avoid repeating
3. `vault_read("Learnings/learning-log.md")` — past discoveries to reuse
4. `get_project_context()` — live system snapshot
5. If working with a Rust library: `query-docs` via Context7 (IDs in `vault/Learnings/library-ids.md`)

### Context7 — Use Before Any Library Code

Do NOT guess library APIs from training data. Fetch the current docs:

```
query-docs({ libraryId: "/actix/actix-web", query: "your question" })
query-docs({ libraryId: "/SeaRust/sea-orm", query: "your question" })
```

Key IDs: Actix-Web `/actix/actix-web` · SeaORM `/SeaRust/sea-orm` · Tokio `/tokio-rs/tokio` · Serde `/serde-rs/serde`

### Shutdown (every session — non-negotiable)

1. `vault_append("Changes/changelog.md", entry)` — **append**, never overwrite
2. `vault_write("Sessions/YYYY-MM-DD-topic.md", content)` — session log
3. New routes? Update `API_ROUTES.json` + `agents/api-agent.md`
4. New pattern or bug fix? `vault_append("Learnings/learning-log.md", ...)` or `vault_append("Errors/error-log.md", ...)`
5. `vault/Agents/context.md` stale? Rewrite it with `vault_write`

### Coding Reference

- Patterns to follow: `vault/Patterns/code-patterns.md`
- Best practices: `vault/Patterns/coding-guidelines.md`
- What NOT to do: `vault/Patterns/anti-patterns.md`
- Architecture decisions (WHY): `vault/Decisions/architecture-decisions.md`
