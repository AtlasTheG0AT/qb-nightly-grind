# qb-foragerun

Active money-making loop for QBCore:

1. **Forage** at configured spots → receive `foraged_herb`
2. **Clean** at a station → convert `foraged_herb` → `clean_herb`
3. **Sell** to a buyer NPC/spot → get cash

Built to match **Nitro Golden Rules**:
- Server-validated distance checks on start + completion
- Server-side rate limiting per action
- Per-player busy lock + timeout failsafe
- Transactional-ish inventory operations (rollback on add failure)
- No trusting the client for rewards

## Dependencies
- `qb-core`
- Optional: `qb-target` (set `Config.Target.UseQBTarget=false` if you don’t use it)
- Optional: `RPEmotes-Reborn` (resource name assumed `rpemotes`; adjust `client.lua` if yours differs)

## Install
1. Copy folder to: `resources/[qb]/qb-foragerun`
2. Add to your server config:
   - `ensure qb-foragerun`
3. Add the items (below) to your shared items.

## Items
Add to `qb-core/shared/items.lua` (names are configurable in `config.lua`):

```lua
['foraged_herb'] = {
    name = 'foraged_herb',
    label = 'Foraged Herb',
    weight = 100,
    type = 'item',
    image = 'foraged_herb.png',
    unique = false,
    useable = false,
    shouldClose = true,
    combinable = nil,
    description = 'Freshly foraged herb. Needs cleaning.'
},
['clean_herb'] = {
    name = 'clean_herb',
    label = 'Clean Herb',
    weight = 100,
    type = 'item',
    image = 'clean_herb.png',
    unique = false,
    useable = false,
    shouldClose = true,
    combinable = nil,
    description = 'Cleaned herb ready to sell.'
},
```

## Configure
Open `config.lua`:

### 1) Forage spot list (coords + heading)
```lua
Config.ForageSpots = {
  { coords = vector3(x, y, z), heading = h },
  { coords = vector3(x, y, z), heading = h },
}
```

### 2) Clean station + buyer
```lua
Config.CleanStation = { coords = vector3(x, y, z), heading = h }
Config.Buyer       = { coords = vector3(x, y, z), heading = h }
```

### 3) RPEmotes-Reborn per step
```lua
Config.Emotes = {
  Forage = { emote = 'mechanic', timeMs = 9000 },
  Clean  = { emote = 'clean', timeMs = 8000 },
  Sell   = { emote = 'clipboard', timeMs = 6500 },
}
```

### 4) Rate limits / payouts
- `Config.RateLimits.*Seconds`
- `Config.Pay.*`

## Notes
- This resource intentionally does not spawn peds; Nitro can add NPCs/props via his preferred framework (or place target zones on existing map objects).
- If you don’t run RPEmotes, the script still works; emote calls are wrapped in `pcall`.
