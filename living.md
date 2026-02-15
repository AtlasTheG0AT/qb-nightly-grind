# Living doc

## Recent changes
- 2026-02-15: Upgraded `qb-couriergrind` with server-owned **courier rep tiers** (metadata-based progression with per-tier payout multipliers) and an optional, configurable **police alert chance** hook (dispatch-agnostic).
- 2026-02-11: Hardened `qb-scraproute` to follow Nitro Golden Rules more strictly: server-approved start/completion flow with tokens, server-side rate limiting, and distance checks.
- 2026-02-12: Added new active grind resource `qb-warehousepack` (pickup boxes -> pack crates -> deliver for cash) with server validation, per-player busy lock, rate limiting, and configurable coords/emotes.
- 2026-02-13: Added new active grind resource `qb-couriergrind` (start route -> pickup package -> deliver to multiple drop-offs for cash) with server-owned run state, distance validation, per-player busy lock, rate limiting, and config hotspots for coords/headings + RPEmotes-Reborn per step.
- 2026-02-14: Added new active grind resource `qb-foragerun` (forage -> clean -> sell) with server-validated actions, per-player busy lock, rate limiting, and configurable coords/headings + RPEmotes-Reborn per step.
- 2026-02-14: Added new active grind resource `qb-meterfix` (start shift -> fix assigned parking meters -> cashout bonus) with server-authoritative run state, distance checks, rate limiting, per-player busy lock, and configurable coords/emotes per step.

## Decisions made
- Kept the existing `qb-scraproute` resource and improved it instead of creating a new one, since it already fits the "active money-making loop" requirement and just needed stronger server authority.
- Implemented a server-driven action lifecycle (`requestAction` -> `beginAction` -> `completeAction`) to avoid trusting the client for timing/reward triggers.
- For the nightly build, shipped a *new* grind loop (`qb-warehousepack`) to diversify money-making options while keeping the same server-authoritative interaction pattern.
- For `qb-couriergrind`, kept the loop intentionally simple (pickup + repeated deliveries) and made the server authoritative over route/step/payout; the client only requests actions by `runId`.
- For `qb-foragerun`, reused the same server-authoritative lifecycle + rollback pattern, but with different gameplay (forage/clean/sell) and a big, obvious `Config.ForageSpots` list for Nitro to populate.
