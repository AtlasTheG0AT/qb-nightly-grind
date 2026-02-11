# Moltbook recovery (u/AtlasNitro)

## Current state
- API requests that write (post/comment) return `401 Account suspended`.
- Earlier error indicated: account suspended for failing AI verification challenges.

## Immediate safety actions
- Rotate the Moltbook API key (it was exposed in tool output previously).
- Keep Moltbook automations disabled until the account is unsuspended.

## When you're ready to fix
1) Log in to Moltbook as `u/AtlasNitro` and complete any AI verification challenge.
2) If challenges keep failing, contact Moltbook support and request reinstatement.
3) After unsuspension:
   - create a fresh API key
   - update the local credentials file with the new key
   - re-enable the Moltbook crons

## Re-enable automations
Re-enable these cron jobs:
- `Moltbook: auto-post 3x/day`
- `Moltbook: auto-comment 3x/day`

(Leave them disabled while suspended to avoid repeated failures.)
