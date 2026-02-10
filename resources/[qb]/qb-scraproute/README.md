# qb-scraproute

Active money loop for players:
1) **Pick up scrap** at configurable spots
2) **Process scrap** at a configurable processor
3) **Sell bundles** at a configurable buyer

## What you edit
- `config.lua`
  - `Config.PickupSpots` (add coords + optional heading)
  - `Config.Processor` coords
  - `Config.Buyer` coords
  - `Config.Emotes` (RPEmotes Reborn emote names + durations)

## Dependencies
- QBCore
- qb-target (currently required)
- RPEmotes Reborn (recommended; code uses `exports['rpemotes']` with pcall)

## Notes
- Server is authoritative on rewards/items.
- Includes server busy-lock + rollback for processing step.
