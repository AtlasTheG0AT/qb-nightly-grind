# qb-posterhustle

Active money-making QBCore grind: **start a flyer shift** at an office, get an assigned posting spot, **put up flyers**, repeat until quota, then **cash out** for a bonus.

Designed to follow **Nitro Golden Rules**:
- Server-authoritative run state (client only requests actions)
- Per-player busy lock + server-issued tokens
- Server-side rate limiting
- Distance validation + action timeouts
- Optional transactional inventory consumption (when enabled)

## Dependencies
- `qb-core`
- `qb-target` (recommended, used by default)
- `RPEmotes-Reborn` (for emotes)

## Install
1) Copy `qb-posterhustle` into your server resources folder:
   - `resources/[qb]/qb-posterhustle`
2) Add to your `server.cfg`:
   - `ensure qb-posterhustle`
3) Configure locations + emotes in `config.lua`.

## Configuration
### Coords / headings (the obvious Nitro hotspots)
- `Config.Office` (start/cashout/cancel target zone)
- `Config.PosterSpots` (list of `vector3` + `heading`)

### Emotes (RPEmotes-Reborn)
Edit these per step:
- `Config.Emotes.Start` (emote + timeMs)
- `Config.Emotes.Post`
- `Config.Emotes.Cashout`

### Rewards / pacing
- `Config.Run.PostersPerShift`
- `Config.Payout.*`
- `Config.RateLimits.*`

### Optional item requirement / consumption
If you want this loop to consume supplies:
- Set `Config.Items.RequiredSupplyItem` to an item name (ex: `poster_roll`)
- Set `Config.Items.ConsumePerPoster`

If left `false`, no inventory is required/consumed.

## How it works (flow)
1) Player starts a shift at the office.
2) Server assigns a random spot from `Config.PosterSpots` and sets a waypoint.
3) Player posts flyers at the assigned spot (server validates they’re at the right spot and not rate-limited).
4) After `PostersPerShift`, player returns to the office and cashes out a bonus.

## Notes
- If you disable qb-target, you must wire your own entry points and call:
  - `TriggerServerEvent('qb-posterhustle:server:requestAction', action, spotId)`
