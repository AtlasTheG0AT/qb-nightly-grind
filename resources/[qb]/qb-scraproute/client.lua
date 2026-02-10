local QBCore = exports['qb-core']:GetCoreObject()

local busy = false
local last = {
    pickup = 0,
    process = 0,
    sell = 0,
}

local function now()
    return GetGameTimer()
end

local function cooldownOk(key, seconds)
    return (now() - (last[key] or 0)) >= (seconds * 1000)
end

local function setLast(key)
    last[key] = now()
end

local function notify(msg, typ)
    TriggerEvent('QBCore:Notify', msg, typ or 'primary')
end

local function playEmote(cfg)
    if not cfg or not cfg.emote then return end
    -- RPEmotes Reborn export (commonly: exports['rpemotes']:EmoteCommandStart)
    -- Nitro can adjust if his resource name differs.
    pcall(function()
        exports['rpemotes']:EmoteCommandStart(cfg.emote)
    end)
end

local function stopEmote()
    pcall(function()
        exports['rpemotes']:EmoteCancel(true)
    end)
end

local function doProgress(label, timeMs)
    busy = true
    local ok = exports['qb-core']:Progressbar('qb_scraproute', label, timeMs, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        busy = false
    end, function()
        busy = false
    end)
    return ok
end

RegisterNetEvent('qb-scraproute:client:notify', function(msg, typ)
    notify(msg, typ)
end)

RegisterNetEvent('qb-scraproute:client:pickup', function()
    if busy then return end
    if not cooldownOk('pickup', Config.Cooldowns.PickupSeconds) then
        return notify('Cooldown…', 'error')
    end

    setLast('pickup')
    playEmote(Config.Emotes.Pickup)
    doProgress('Picking up scrap…', Config.Emotes.Pickup.timeMs or 8000)
    stopEmote()

    TriggerServerEvent('qb-scraproute:server:pickup')
end)

RegisterNetEvent('qb-scraproute:client:process', function()
    if busy then return end
    if not cooldownOk('process', Config.Cooldowns.ProcessSeconds) then
        return notify('Cooldown…', 'error')
    end

    setLast('process')
    playEmote(Config.Emotes.Process)
    doProgress('Processing scrap…', Config.Emotes.Process.timeMs or 10000)
    stopEmote()

    TriggerServerEvent('qb-scraproute:server:process')
end)

RegisterNetEvent('qb-scraproute:client:sell', function()
    if busy then return end
    if not cooldownOk('sell', Config.Cooldowns.SellSeconds) then
        return notify('Cooldown…', 'error')
    end

    setLast('sell')
    playEmote(Config.Emotes.Sell)
    doProgress('Selling bundles…', Config.Emotes.Sell.timeMs or 6000)
    stopEmote()

    TriggerServerEvent('qb-scraproute:server:sell')
end)

CreateThread(function()
    Wait(1500)
    if not Config.Target.UseQBTarget then return end

    if not exports['qb-target'] then
        print('[qb-scraproute] qb-target not found; add fallback later')
        return
    end

    -- Pickup spots
    for i, spot in ipairs(Config.PickupSpots) do
        exports['qb-target']:AddBoxZone(
            ('qb_scraproute_pickup_%s'):format(i),
            spot.coords,
            1.2, 1.2,
            {
                name = ('qb_scraproute_pickup_%s'):format(i),
                heading = spot.heading or 0.0,
                debugPoly = Config.Debug,
                minZ = spot.coords.z - 1.0,
                maxZ = spot.coords.z + 1.0,
            },
            {
                options = {
                    {
                        icon = 'fas fa-recycle',
                        label = 'Pick up scrap',
                        action = function()
                            TriggerEvent('qb-scraproute:client:pickup')
                        end,
                    }
                },
                distance = 2.0
            }
        )
    end

    -- Processor
    exports['qb-target']:AddBoxZone(
        'qb_scraproute_processor',
        Config.Processor.coords,
        1.6, 1.6,
        {
            name = 'qb_scraproute_processor',
            heading = Config.Processor.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.Processor.coords.z - 1.0,
            maxZ = Config.Processor.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-industry',
                    label = 'Process scrap',
                    action = function()
                        TriggerEvent('qb-scraproute:client:process')
                    end,
                }
            },
            distance = 2.0
        }
    )

    -- Buyer
    exports['qb-target']:AddBoxZone(
        'qb_scraproute_buyer',
        Config.Buyer.coords,
        1.6, 1.6,
        {
            name = 'qb_scraproute_buyer',
            heading = Config.Buyer.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.Buyer.coords.z - 1.0,
            maxZ = Config.Buyer.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-dollar-sign',
                    label = 'Sell bundles',
                    action = function()
                        TriggerEvent('qb-scraproute:client:sell')
                    end,
                }
            },
            distance = 2.0
        }
    )
end)
