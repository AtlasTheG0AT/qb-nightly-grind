# qb-couriergrind

Productive **courier route** grind for QBCore: players **start a route**, **pick up a package**, then **deliver** to multiple drop-offs for money.

Designed for Nitro Golden Rules:
- Server-validated progression (server owns run state)
- Transactional inventory ops (server AddItem/RemoveItem)
- Per-player busy lock (one active run per player)
- Rate-limited sensitive events
- No trusting client for payouts / step completion (server checks distance + runId)

## Dependencies
- `qb-core`
- Recommended: `qb-target` (zones). Resource also provides fallback commands.
- Optional: RPEmotes-Reborn (`rpemotes`) for step animations (resource will *attempt* to call it; otherwise it falls back to common qb animations event).

## Install
1) Copy resource into:
```
resources/[qb]/qb-couriergrind
```

2) Add to your `server.cfg`:
```
ensure qb-couriergrind
```

3) Add the package item to your QBCore items (example for `qb-core/shared/items.lua`):
```lua
['delivery_package'] = {
    name = 'delivery_package',
    label = 'Delivery Package',
    weight = 1500,
    type = 'item',
    image = 'delivery_package.png',
    unique = false,
    useable = false,
    shouldClose = false,
    combinable = nil,
    description = 'A sealed package for courier delivery.'
},
```

## How it works (player flow)
1) Go to a **pickup** location and interact: **Start courier route**
2) Interact again: **Pick up package** (server gives `delivery_package`)
3) Go to the waypoint and **Deliver package** (server removes item + pays)
4) Repeat for the route length

Fallback commands if you don’t use qb-target:
- `/courier` start
- `/courierpickup` pickup
- `/courierdeliver` deliver
- `/couriercancel` cancel

## Configuration (Nitro hotspots)
All config is in `config.lua`.

### Coords + headings
Add more locations by extending these lists:
- `Config.Pickups = { { coords = vector3(...), heading = ... }, ... }`
- `Config.VehicleSpawns = { { coords = vector3(...), heading = ... }, ... }`
- `Config.Dropoffs = { { coords = vector3(...), heading = ... }, ... }`

### RPEmotes-Reborn per step
Edit emotes + durations:
```lua
Config.Emotes = {
  start = { name = 'clipboard', duration = 2500 },
  pickup = { name = 'box', duration = 4500 },
  deliver = { name = 'box', duration = 3500 },
  finish = { name = 'cash', duration = 2500 },
}
```

### Economy
- `Config.PayoutPerDelivery`
- `Config.PayoutAccount`
- `Config.VehicleDeposit`

## Notes / Security
- The server validates pickup/delivery **distance** using server-side player coords.
- The client only requests actions with a `runId`; the server rejects invalid or out-of-order requests.
- Cancel currently **forfeits vehicle deposit** (anti-spam). Change in `server.lua` if you want refunds.
