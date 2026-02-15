Config = Config or {}

Config.Debug = false

-- qb-target integration (recommended)
Config.Target = {
    UseQBTarget = true,
}

-- Basic security knobs
Config.Security = {
    InteractionDistance = 2.5,
    ActionTimeoutSeconds = 40,
}

-- Server-side rate limits (seconds)
Config.RateLimits = {
    StartSeconds = 10,
    PostSeconds = 6,
    CashoutSeconds = 10,
}

-- Run settings
Config.Run = {
    PostersPerShift = 5,
    AllowCancel = true,
}

-- Items (optional)
-- NOTE: leave disabled unless your item set includes these.
Config.Items = {
    -- If set, player must have this item to start and to post.
    RequiredSupplyItem = false, -- e.g. 'poster_roll'

    -- If RequiredSupplyItem is set, how many are consumed per poster.
    ConsumePerPoster = 1,
}

-- Rewards
Config.Payout = {
    PerPosterMin = 65,
    PerPosterMax = 110,
    ShiftBonusMin = 120,
    ShiftBonusMax = 220,
}

-- Office / HQ (edit for your city)
Config.Office = {
    coords = vector3(-1188.78, -897.25, 13.99),
    heading = 307.0,
}

-- Emotes (RPEmotes-Reborn). Each step uses an emote + progressbar time.
Config.Emotes = {
    Start = { emote = 'clipboard', timeMs = 4500 },
    Post = { emote = 'mechanic4', timeMs = 7000 }, -- "hands busy" vibe; swap as desired
    Cashout = { emote = 'clipboard', timeMs = 4500 },
}

-- Poster/flyer locations. Add/replace with your own list.
-- heading used for qb-target box orientation.
Config.PosterSpots = {
    { coords = vector3(-560.90, -208.72, 38.22), heading = 30.0 },   -- Rockford Hills
    { coords = vector3(256.29, -1014.89, 29.27), heading = 70.0 },   -- Pillbox area
    { coords = vector3(115.65, -1035.41, 29.27), heading = 160.0 },  -- Downtown
    { coords = vector3(-1151.77, -1566.07, 4.36), heading = 125.0 }, -- Vespucci beach
    { coords = vector3(-132.02, -1711.49, 29.29), heading = 140.0 }, -- Davis
    { coords = vector3(985.27, -95.18, 74.85), heading = 240.0 },    -- Mirror Park
    { coords = vector3(1723.44, 3795.01, 34.72), heading = 35.0 },   -- Sandy
    { coords = vector3(-223.04, 6232.46, 31.49), heading = 45.0 },   -- Paleto
}
