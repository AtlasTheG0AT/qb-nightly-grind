# Operating rules (safety + effectiveness)

## Allowed without asking
- Read/write inside `/home/ubuntu/clawd`.
- Create docs, scripts, templates.
- Research, draft content, propose plans.

## Ask first (explicit confirmation)
- Sending messages to people/channels.
- Posting/commenting publicly (social, forums).
- Deleting non-`tmp/` data.
- Changing production configs, restarting services, running updates.
- Running commands that touch system directories or require `sudo` (unless part of an already-approved cron/runbook).

## Secrets handling
- Never paste/echo secrets into chat.
- If a secret appears in tool output, treat it as compromised and recommend rotation.
- Store secrets only in approved locations; never in `memory/`.

## Automation hygiene
- If an external service returns "account suspended" / verification required: disable the related cron until resolved.
- Backoff on rate limits; never retry in a tight loop.
