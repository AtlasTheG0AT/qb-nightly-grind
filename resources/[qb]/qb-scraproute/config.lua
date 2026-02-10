Config = Config or {}

Config.Debug = false

-- Prefer qb-target; fallback should be added later if needed.
Config.Target = {
    UseQBTarget = true,
}

-- Money loop:
-- 1) Pickup scrap at these spots
-- 2) Process scrap at processor
-- 3) Sell processed goods at buyer

Config.Items = {
    ScrapRaw = 'scrapmetal',
    ScrapProcessed = 'scrapbundle',
}

Config.Cooldowns = {
    PickupSeconds = 60,
    ProcessSeconds = 30,
    SellSeconds = 30,
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

-- RPEmotes Reborn hooks (Nitro can swap names/props anytime)
Config.Emotes = {
    Pickup = { emote = 'mechanic', timeMs = 8000 },
    Process = { emote = 'weld', timeMs = 10000 },
    Sell = { emote = 'clipboard', timeMs = 6000 },
}

-- Spots you will edit:
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
