Config = Config or {}

Config.Debug = false

-- Prefer qb-target; if you don't use it, set false and wire your own entrypoints
-- that call the server events (see README).
Config.Target = {
    UseQBTarget = true,
}

-- Items used by the grind (set to items that exist in your shared items).
Config.Items = {
    Box = 'warehouse_box',
    Crate = 'packed_crate',
}

-- Server-side rate limits (start requests) per action.
-- Keep these >= the client progress times to reduce spam.
Config.RateLimits = {
    PickupSeconds = 8,
    PackSeconds = 12,
    DeliverSeconds = 8,
}

-- Extra security knobs (server validated)
Config.Security = {
    InteractionDistance = 2.5,      -- max distance from target coords to start/finish
    ActionTimeoutSeconds = 45,      -- if client takes longer than this to complete, server rejects
}

-- RPEmotes Reborn hooks (Nitro can swap names/props anytime)
-- Each step: emote name + duration
Config.Emotes = {
    Pickup = { emote = 'box', timeMs = 8000 },         -- example: carrying box
    Pack = { emote = 'mechanic', timeMs = 12000 },     -- example: working at table
    Deliver = { emote = 'box', timeMs = 8000 },        -- example: carrying box
}

-- Economy + amounts
Config.Amounts = {
    PickupMin = 1,
    PickupMax = 2,

    PackIn = 2,     -- boxes required
    PackOut = 1,    -- crates produced

    DeliverMin = 1,
    DeliverMax = 2,
}

Config.Pay = {
    DeliverPerCrateMin = 120,
    DeliverPerCrateMax = 200,
    Account = 'cash', -- or 'bank'
}

-- Spots you will edit:
-- NOTE: keep as vector3 + heading so Nitro can paste coords easily.
Config.ShelfSpots = {
    -- { coords = vector3(x, y, z), heading = 0.0 },
}

Config.PackingStation = {
    coords = vector3(0.0, 0.0, 0.0),
    heading = 0.0,
}

Config.DeliveryBay = {
    coords = vector3(0.0, 0.0, 0.0),
    heading = 0.0,
}
