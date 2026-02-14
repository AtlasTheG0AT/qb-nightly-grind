# qb-meterfix

Active money-making side job for QBCore: **City Maintenance**.

Players start a shift at the depot, get a server-assigned broken parking meter location, **fix a few meters**, then return to the depot to cash out a shift bonus.

## Features
- Server-authoritative run state (assigned spot + fixes done lives on server)
- Server-validated distance checks + action timeouts
- Server-side rate limiting
- Per-player busy lock
- Config-driven coords + emotes per step
- qb-target zones for depot + all fix spots (only assigned spot is interactable)

## Dependencies
- `qb-core`
- `qb-target` (recommended; can be disabled in config)
- `rpemotes` (optional; emotes are wrapped in `pcall`)

## Installation
1. Copy `qb-meterfix` into your resources folder:
   - `.../resources/[qb]/qb-meterfix`
2. Add to your `server.cfg`:
   ```cfg
   ensure qb-meterfix
   ```
3. Configure locations + payouts in `config.lua`.

## Config
Edit these first:
- `Config.Depot` (where players start/cashout)
- `Config.FixSpots` (list of parking meter locations)
- `Config.Emotes` (Start/Fix/Cashout emotes + durations)
- `Config.Items.RequiredTool` (optional tool item requirement)

## Optional item (required tool)
By default the script requires `maintenance_kit` in inventory.

Add this to `qb-core/shared/items.lua` (example):
```lua
['maintenance_kit'] = {
    name = 'maintenance_kit',
    label = 'Maintenance Kit',
    weight = 500,
    type = 'item',
    image = 'maintenance_kit.png',
    unique = false,
    useable = false,
    shouldClose = false,
    combinable = nil,
    description = 'A basic kit for city maintenance callouts.'
},
```

Or disable the requirement:
```lua
Config.Items.RequiredTool = false
```

## Nitro Golden Rules notes
- Client never grants itself money.
- Server checks: busy lock, rate limits, distance, action timeout, assigned-spot validation.
