# qb-scraproute

Active money loop for players (no passive needs/mood stuff):
1) **Pick up scrap** at configurable spots
2) **Process scrap** at a configurable processor
3) **Sell bundles** at a configurable buyer

## Golden Rules (Nitro)
This resource is built to be:
- **Server-validated** (distance checks on start + completion)
- **Transactional-ish inventory ops** (rollback when possible)
- **Per-player busy lock** (server authoritative)
- **Rate limited** (server authoritative)
- **No trusting client** for rewards

## Dependencies
Required:
- **qb-core**

Recommended:
- **qb-target** (interaction zones)
- **RPEmotes-Reborn** (animations)

If you don’t use qb-target, set `Config.Target.UseQBTarget = false` and trigger the server events from your own UI/targets.

## Install
1. Drop into your server resources folder:
   `resources/[qb]/qb-scraproute`
2. Add to your `server.cfg`:
   `ensure qb-scraproute`
3. Configure locations + emotes in `config.lua`

## Config (what you edit)
### Coords / headings
- `Config.PickupSpots` (list)
  - `{ coords = vector3(x, y, z), heading = 0.0 }`
- `Config.Processor` (single)
- `Config.Buyer` (single)

### RPEmotes-Reborn per step
- `Config.Emotes.Pickup = { emote = 'mechanic', timeMs = 8000 }`
- `Config.Emotes.Process = { emote = 'weld', timeMs = 10000 }`
- `Config.Emotes.Sell = { emote = 'clipboard', timeMs = 6000 }`

### Security / rate limits
- `Config.RateLimits.*Seconds` (server-side start request rate limit)
- `Config.Security.InteractionDistance` (server-side distance checks)
- `Config.Security.ActionTimeoutSeconds` (server-side completion timeout)

## How it works (events)
Client does **not** award itself anything.

### Start an action
Client requests an action:
- `TriggerServerEvent('qb-scraproute:server:requestAction', 'pickup', spotId)`
- `TriggerServerEvent('qb-scraproute:server:requestAction', 'process', 0)`
- `TriggerServerEvent('qb-scraproute:server:requestAction', 'sell', 0)`

Server validates (distance, rate limit, busy lock) and then tells the client to run emote/progress:
- `qb-scraproute:client:beginAction(action, token, spotId)`

### Complete an action
Client reports completion:
- `TriggerServerEvent('qb-scraproute:server:completeAction', action, token, spotId, cancelled)`

Server validates token + timeout + distance again, then performs inventory/money changes.

## Notes
- Items used:
  - raw: `Config.Items.ScrapRaw` (default `scrapmetal`)
  - processed: `Config.Items.ScrapProcessed` (default `scrapbundle`)
- Add these items to your shared items if you don’t already have them.
