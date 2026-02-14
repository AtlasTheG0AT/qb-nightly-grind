Config = Config or {}

Config.Debug = false

-- qb-target integration (recommended)
Config.Target = {
    UseQBTarget = true,
}

-- Basic security knobs
Config.Security = {
    InteractionDistance = 2.5,
    ActionTimeoutSeconds = 35,
}

-- Server-side rate limits (seconds)
Config.RateLimits = {
    StartSeconds = 10,
    FixSeconds = 8,
    CashoutSeconds = 10,
}

-- Run settings
Config.Run = {
    FixesPerShift = 3,          -- how many meters to fix before cashout is allowed
    AllowCancel = true,
}

-- Items (optional)
Config.Items = {
    RequiredTool = 'maintenance_kit', -- set to false/nil to disable requirement
}

-- Rewards
Config.Payout = {
    PerFixMin = 110,
    PerFixMax = 165,
    ShiftBonusMin = 125,
    ShiftBonusMax = 220,
}

-- Coords (edit for your city)
Config.Depot = {
    coords = vector3(412.33, -1639.82, 29.29),
    heading = 230.0,
}

-- Emotes (RPEmotes-Reborn). Each step uses an emote + progressbar time.
Config.Emotes = {
    Start = { emote = 'clipboard', timeMs = 4500 },
    Fix = { emote = 'mechanic4', timeMs = 8000 },
    Cashout = { emote = 'clipboard', timeMs = 4500 },
}

-- Broken meter locations. Add/replace with your own list.
-- heading used for qb-target box orientation.
Config.FixSpots = {
    { coords = vector3(215.58, -810.43, 30.73), heading = 340.0 }, -- Legion Square parking
    { coords = vector3(-344.02, -875.41, 31.08), heading = 90.0 }, -- Little Seoul
    { coords = vector3(-1198.27, -893.96, 13.99), heading = 125.0 }, -- Vespucci
    { coords = vector3(1146.20, -326.12, 68.90), heading = 75.0 }, -- Mirror Park
    { coords = vector3(265.67, 216.27, 106.28), heading = 160.0 }, -- Downtown
    { coords = vector3(1690.71, 4822.72, 42.06), heading = 10.0 }, -- Grapeseed
    { coords = vector3(-257.01, 6333.18, 32.43), heading = 45.0 }, -- Paleto
}
