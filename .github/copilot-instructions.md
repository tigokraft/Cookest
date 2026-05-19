You are working on the **Cookest API** (Rust, Actix-Web 4, SeaORM, PostgreSQL).

## Mandatory Startup — Run Before Anything Else

**VS Code (MCP available):** Call in order:
1. `vault_read("Agents/context.md")` — live project memory
2. `vault_read("Errors/error-log.md")` — past mistakes to avoid
3. `vault_read("Learnings/learning-log.md")` — past discoveries
4. `get_project_context()` — live system snapshot

**CLI (MCP unavailable):** Use `view` tool instead:
1. `view ../vault/Agents/context.md`
2. `view ../vault/Errors/error-log.md` (last 30 lines)
3. `view ../CONTEXT.md`

Do not skip. These reads take seconds and prevent hours of repeated mistakes.

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

**VS Code:** Use MCP tools:
1. `vault_append("Changes/changelog.md", "## [YYYY-MM-DD] ...\nWhat was done and why")`
2. `vault_write("Sessions/YYYY-MM-DD-topic.md", fullSessionLog)`
3. `vault_append("Errors/error-log.md", ...)` or `vault_append("Learnings/learning-log.md", ...)`

**CLI:** Use bash + edit:
1. `bash printf "\n## [DATE] TOPIC\n- what\n- why\n" >> ../vault/Changes/changelog.md`
2. `create ../vault/Sessions/YYYY-MM-DD-topic.md` with session summary
3. Append to errors/learnings similarly

## CLI Mode

If MCP tools are unavailable (running in the Copilot CLI without MCP):

| VS Code MCP | CLI equivalent |
|---|---|
| `vault_read("Agents/context.md")` | `view ../vault/Agents/context.md` |
| `vault_append("Errors/...", text)` | `bash printf "..." >> ../vault/Errors/error-log.md` |
| `vault_append("Changes/...", text)` | `bash printf "..." >> ../vault/Changes/changelog.md` |
| `query-docs({ libraryId, query })` | `web_fetch` to official docs URL |
| `get_project_context()` | `view ../CONTEXT.md` |

**CLI startup:** `view ../vault/Agents/context.md` then `view ../vault/Errors/error-log.md`
**CLI shutdown:** append to `../vault/Changes/changelog.md`

## Mid-Session Re-Anchor

If this conversation has grown long (15+ messages), re-read `vault/Agents/context.md` (via `vault_read` or `view ../vault/Agents/context.md`) before your next action.
