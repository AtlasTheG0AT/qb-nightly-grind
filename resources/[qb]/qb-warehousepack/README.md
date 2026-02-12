# qb-warehousepack

Active, money-making warehouse packing grind for **QBCore**.

Loop:
1. **Grab boxes** from shelf spots (gives `warehouse_box`)
2. **Pack crates** at the packing station (consumes boxes → gives `packed_crate`)
3. **Deliver crates** at the delivery bay (consumes crates → pays money)

This resource follows Nitro Golden Rules:
- **Server-validated** distance checks + action timeouts
- **Transactional** inventory ops via QBCore player functions
- **Per-player busy lock** (no parallel actions)
- **Rate limiting** on action requests
- **No trusting the client** for rewards

## Installation
1. Copy to:
   `resources/[qb]/qb-warehousepack`
2. Add to your `server.cfg`:
   ```cfg
   ensure qb-warehousepack
   ```
3. Ensure you have:
   - `qb-core`
   - `qb-target` (optional, can be disabled)
   - `rpemotes` (RPEmotes-Reborn) (optional but recommended)

## Items
Make sure these exist in your shared items (or change in `config.lua`):
- `warehouse_box`
- `packed_crate`

## Config
All key edit points are in `config.lua`:
- **Coords lists**
  - `Config.ShelfSpots` (list of `{ coords = vector3(...), heading = ... }`)
  - `Config.PackingStation`
  - `Config.DeliveryBay`
- **RPEmotes-Reborn per step**
  - `Config.Emotes.Pickup`
  - `Config.Emotes.Pack`
  - `Config.Emotes.Deliver`

Example shelf spot:
```lua
Config.ShelfSpots = {
  { coords = vector3(123.4, 456.7, 78.9), heading = 90.0 },
}
```

## Using without qb-target
Set:
```lua
Config.Target.UseQBTarget = false
```
Then call these server events from your own interaction system:
- `qb-warehousepack:server:requestAction(action, spotId)`
  - action: `pickup` | `pack` | `deliver`
  - spotId: shelf index for `pickup`, otherwise `0`

## Notes
- Rewards are **only** granted server-side on valid completion.
- If you change progress durations in emotes, keep `Config.RateLimits.*` >= that duration.
