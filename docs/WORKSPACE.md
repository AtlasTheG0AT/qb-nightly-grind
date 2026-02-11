# Workspace layout + conventions

This repo is the agent's working directory. Keep it predictable, safe, and auditable.

## Directory map

- `docs/` — runbooks, policies, how-to notes
- `scripts/` — maintenance scripts
- `configs/` — sanitized config templates (NO secrets)
- `secrets/` — local secrets (discouraged; if used, chmod 600 and never commit)
- `memory/` — continuity logs (daily notes + structured JSONL logs)
- `projects/` — real deliverables
- `resources/` — shared assets
- `tmp/` — throwaway scratch space (gitignored)

## Logging rules

- Never log API keys, auth headers, cookies, or full credential files.
- Prefer structured logs (JSONL) for things that need to be machine-readable.
- Put failures in daily notes (or `errors.jsonl`) with *sanitized* details:
  - timestamp, action, endpoint, status code, error string (no request/response bodies if they might contain secrets)

## Git rules

- Commit code/docs/scripts/config templates.
- Do NOT commit: `secrets/`, `tmp/`, credential files, `.env`.

## Least privilege

- Use scoped API keys (read vs write) when possible.
- Keep automations disabled when an account is suspended/blocked to avoid repeated failures.
