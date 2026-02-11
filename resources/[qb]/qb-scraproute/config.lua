Config = Config or {}

Config.Debug = false

-- Prefer qb-target; if you don't use it, set false and wire your own entrypoints
-- that call the server events (see README).
Config.Target = {
    UseQBTarget = true,
}

-- Money loop (active):
-- 1) Pickup scrap at configured spots
-- 2) Process scrap at processor
-- 3) Sell processed goods at buyer

Config.Items = {
    ScrapRaw = 'scrapmetal',
    ScrapProcessed = 'scrapbundle',
}

-- Server-side rate limits (start requests) per action.
-- Keep these >= the client progress times to reduce spam.
Config.RateLimits = {
    PickupSeconds = 8,
    ProcessSeconds = 10,
    SellSeconds = 6,
}

-- Extra security knobs (server validated)
Config.Security = {
    InteractionDistance = 2.5,      -- max distance from target coords to start/finish
    ActionTimeoutSeconds = 35,      -- if client takes longer than this to complete, server rejects
}

-- RPEmotes Reborn hooks (Nitro can swap names/props anytime)
-- Each step: emote name + duration
Config.Emotes = {
    Pickup = { emote = 'mechanic', timeMs = 8000 },
    Process = { emote = 'weld', timeMs = 10000 },
    Sell = { emote = 'clipboard', timeMs = 6000 },
}

Config.Amounts = {
    PickupMin = 1,
    PickupMax = 3,
    ProcessIn = 2,        -- raw scrap required
    ProcessOut = 1,       -- processed bundle output
    SellMin = 1,
    SellMax = 3,
}

Config.Pay = {
    SellPerBundleMin = 90,
    SellPerBundleMax = 150,
    Account = 'cash', -- or 'bank'
}

-- Spots you will edit:
-- NOTE: keep as vector3 + heading so Nitro can paste coords easily.
Config.PickupSpots = {
    -- { coords = vector3(x, y, z), heading = 0.0 },
}

Config.Processor = {
    coords = vector3(0.0, 0.0, 0.0),
    heading = 0.0,
}

Config.Buyer = {
    coords = vector3(0.0, 0.0, 0.0),
    heading = 0.0,
}
