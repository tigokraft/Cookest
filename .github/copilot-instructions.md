You are working on the **Cookest API** (Rust, Actix-Web 4, SeaORM, PostgreSQL).

## Mandatory Startup — Run Before Anything Else

Call these MCP tools at the start of every session, in order:

1. `vault_read("Agents/context.md")` — live project memory
2. `vault_read("Errors/error-log.md")` — past mistakes to avoid
3. `vault_read("Learnings/learning-log.md")` — past discoveries
4. `get_project_context()` — live system snapshot

Do not skip. These 4 calls take seconds and prevent hours of repeated mistakes.

## Mandatory — Use Context7 Before Writing Library Code

Before writing code that uses any Rust crate, call Context7:

```
query-docs({ libraryId: "/actix/actix-web", query: "your question" })
query-docs({ libraryId: "/SeaRust/sea-orm", query: "your question" })
query-docs({ libraryId: "/tokio-rs/tokio", query: "your question" })
```

Pre-resolved IDs for all libraries: `vault/Learnings/library-ids.md`
Do not guess library APIs. Training data is outdated. Use Context7 instead.

## Rust Rules (enforced)

1. Handlers are thin: validate → call service → return response. No DB calls in handlers.
2. Return `AppError` from all handlers and services. Never `.unwrap()` or `panic!()`.
3. SeaORM builder pattern. No raw SQL without a comment explaining why.
4. Pro features: check `subscription_tier` in service, return 402 if insufficient.
5. Admin gates: always re-check `is_admin` from DB — never trust JWT alone.
6. No hardcoded strings/numbers: use constants from `config.rs` or `errors.rs`.
7. Check `vault/Patterns/code-patterns.md` for existing patterns before inventing new ones.
8. Check `vault/Patterns/coding-guidelines.md` for full Rust best practices.
9. Check `vault/Patterns/anti-patterns.md` for things that caused bugs in this codebase.

## Mandatory Shutdown — Run at End of Every Session

1. `vault_append("Changes/changelog.md", "## [YYYY-MM-DD] ...\nWhat was done and why")` — append only, never overwrite
2. `vault_write("Sessions/YYYY-MM-DD-topic.md", fullSessionLog)` — session log
3. If new routes were added: update `API_ROUTES.json` + `agents/api-agent.md`
4. If a pattern was discovered or a bug was fixed: `vault_append("Learnings/learning-log.md", ...)` or `vault_append("Errors/error-log.md", ...)`

## Project Context

@AGENTS.md
