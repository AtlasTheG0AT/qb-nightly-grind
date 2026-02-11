# Living doc

## Recent changes
- 2026-02-11: Hardened `qb-scraproute` to follow Nitro Golden Rules more strictly: server-approved start/completion flow with tokens, server-side rate limiting, and distance checks.

## Decisions made
- Kept the existing `qb-scraproute` resource and improved it instead of creating a new one, since it already fits the "active money-making loop" requirement and just needed stronger server authority.
- Implemented a server-driven action lifecycle (`requestAction` -> `beginAction` -> `completeAction`) to avoid trusting the client for timing/reward triggers.
