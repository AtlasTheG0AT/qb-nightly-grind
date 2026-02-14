Config = Config or {}

-- qb-foragerun
-- Active job loop:
-- 1) Forage at Config.ForageSpots (gives raw item)
-- 2) Clean at Config.CleanStation (converts raw -> clean)
-- 3) Sell at Config.Buyer (sells clean item for cash)

Config.Debug = false

Config.Target = {
    UseQBTarget = true, -- if false, wire your own entrypoints and call server event requestAction
}

-- Coords are intentionally obvious so Nitro can drop in lists quickly
Config.ForageSpots = {
    -- { coords = vector3(-560.0, 5355.0, 70.2), heading = 0.0 },
    -- { coords = vector3(-585.0, 5346.0, 70.2), heading = 0.0 },
}

Config.CleanStation = {
    coords = vector3(1392.5, 3605.1, 38.9),
    heading = 200.0,
}

Config.Buyer = {
    coords = vector3(-1194.0, -892.6, 13.9),
    heading = 30.0,
}

Config.Items = {
    Raw = 'foraged_herb',
    Clean = 'clean_herb',
}

Config.Amounts = {
    ForageMin = 1,
    ForageMax = 2,

    CleanIn = 3,  -- raw needed
    CleanOut = 1, -- clean received

    SellMin = 1,
    SellMax = 3,
}

Config.Pay = {
    Account = 'cash',
    SellEachMin = 40,
    SellEachMax = 70,
}

-- Nitro Golden Rules / security knobs
Config.Security = {
    InteractionDistance = 2.5,
    ActionTimeoutSeconds = 35,
}

Config.RateLimits = {
    ForageSeconds = 18,
    CleanSeconds = 12,
    SellSeconds = 10,
}

-- RPEmotes-Reborn (emote name + duration)
-- If your export names differ, adjust client.lua's playEmote/stopEmote.
Config.Emotes = {
    Forage = { emote = 'mechanic', timeMs = 9000 },   -- "searching / picking"
    Clean  = { emote = 'clean',    timeMs = 8000 },   -- "cleaning"
    Sell   = { emote = 'clipboard', timeMs = 6500 },  -- "paperwork / transaction"
}
