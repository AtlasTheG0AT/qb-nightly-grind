Config = Config or {}

-- Nitro config hotspots:
-- - Add more pickup/dropoff coords (vector3) + headings below.
-- - Tune emotes per step (RPEmotes-Reborn emote names + duration).

Config.Debug = false

-- Anti-exploit + UX
Config.CooldownSeconds = 60
Config.EventRateLimitMs = 750 -- minimum ms between sensitive client->server events per player

-- Inventory + payout
Config.PackageItem = 'delivery_package'
Config.PackageItemAmount = 1
Config.PayoutPerDelivery = { min = 120, max = 220 } -- cash per successful drop (before multipliers)
Config.PayoutAccount = 'cash' -- 'cash' | 'bank'

-- Progression: courier rep tiers (server-owned, stored in player metadata)
-- Notes:
-- - Rep is awarded per successful delivery.
-- - Tier payout multipliers apply per-delivery.
-- - Optional: reduce / increase police alert chance per tier via `alertChanceMult`.
Config.Rep = {
    Enabled = true,
    MetadataKey = 'courierrep',
    RepPerDelivery = 1,
    Tiers = {
        { name = 'Rookie',  minRep = 0,   payoutMult = 1.00, alertChanceMult = 1.00 },
        { name = 'Runner',  minRep = 25,  payoutMult = 1.05, alertChanceMult = 0.95 },
        { name = 'Pro',     minRep = 75,  payoutMult = 1.12, alertChanceMult = 0.90 },
        { name = 'Legend',  minRep = 150, payoutMult = 1.20, alertChanceMult = 0.85 },
    }
}

-- Optional risk: police alert chance on deliveries (server-side)
-- This is intentionally dispatch-script-agnostic. Configure a server event in your police/dispatch.
-- The resource will call: TriggerEvent(Config.PoliceAlert.ServerEvent, payload)
Config.PoliceAlert = {
    Enabled = false,
    ChancePerDelivery = 0.12, -- 0.00 - 1.00
    CooldownSeconds = 90, -- per-player
    ServerEvent = 'qb-couriergrind:server:PoliceAlert', -- change to your dispatch, e.g. 'ps-dispatch:server:notify'
    Payload = {
        code = '10-66',
        title = 'Suspicious courier activity',
    },
}

-- Route settings
Config.DeliveriesPerRun = { min = 4, max = 7 }
Config.MaxInteractDistance = 3.0
Config.MaxDeliveryDistance = 4.0

-- Optional vehicle spawn
Config.UseJobVehicle = true
Config.JobVehicleModel = 'speedo'
Config.VehicleDeposit = 250 -- returned on successful finish (server-side)

-- RPEmotes-Reborn per-step emotes
-- Notes:
-- - Emote names should match RPEmotes emote list (e.g. "box", "clipboard", "mechanic").
-- - Duration is in ms; client will auto-stop after duration.
Config.Emotes = {
    start = { name = 'clipboard', duration = 2500 },
    pickup = { name = 'box', duration = 4500 },
    deliver = { name = 'box', duration = 3500 },
    finish = { name = 'cash', duration = 2500 },
}

-- Target / interaction
Config.UseTarget = true
Config.Target = {
    Icon = 'fas fa-box',
    StartLabel = 'Start courier route',
    PickupLabel = 'Pick up package',
    DeliverLabel = 'Deliver package',
}

-- Pickup locations (go here to start + pick up)
Config.Pickups = {
    { coords = vector3(78.35, 111.93, 81.17), heading = 70.0 }, -- Downtown post / placeholder
}

-- Vehicle spawn points
Config.VehicleSpawns = {
    { coords = vector3(72.69, 118.54, 79.19), heading = 70.0 },
}

-- Delivery drop-offs (route randomly samples from this list)
Config.Dropoffs = {
    { coords = vector3(-35.64, -1445.23, 31.49), heading = 180.0 },
    { coords = vector3(256.83, -1723.39, 29.65), heading = 50.0 },
    { coords = vector3(1259.12, -1761.02, 49.67), heading = 30.0 },
    { coords = vector3(-712.55, -932.42, 19.02), heading = 90.0 },
    { coords = vector3(-1221.28, -908.21, 12.33), heading = 30.0 },
    { coords = vector3(1138.26, -980.52, 46.42), heading = 280.0 },
}
