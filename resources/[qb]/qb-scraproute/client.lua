local QBCore = exports['qb-core']:GetCoreObject()

local busy = false

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

    local finished = false
    local cancelled = false

    exports['qb-core']:Progressbar('qb_scraproute', label, timeMs, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        finished = true
        busy = false
    end, function()
        cancelled = true
        busy = false
    end)

    while busy do
        Wait(50)
    end

    return finished and (not cancelled)
end

RegisterNetEvent('qb-scraproute:client:notify', function(msg, typ)
    notify(msg, typ)
end)

-- Server-approved flow:
-- 1) client requests action (spotId)
-- 2) server validates distance + rate limit + busy lock
-- 3) server tells client to run progress/emote
-- 4) client reports completion; server awards items/money
RegisterNetEvent('qb-scraproute:client:beginAction', function(action, token, spotId)
    if busy then
        -- Shouldn't happen because server enforces busy lock, but don't stack progressbars.
        TriggerServerEvent('qb-scraproute:server:completeAction', action, token, spotId, true)
        return
    end

    local em = nil
    if action == 'pickup' then em = Config.Emotes.Pickup end
    if action == 'process' then em = Config.Emotes.Process end
    if action == 'sell' then em = Config.Emotes.Sell end

    local label = 'Working…'
    if action == 'pickup' then label = 'Picking up scrap…' end
    if action == 'process' then label = 'Processing scrap…' end
    if action == 'sell' then label = 'Selling bundles…' end

    local timeMs = (em and em.timeMs) or 8000

    playEmote(em)
    local ok = doProgress(label, timeMs)
    stopEmote()

    TriggerServerEvent('qb-scraproute:server:completeAction', action, token, spotId, not ok)
end)

local function request(action, spotId)
    if busy then return end
    TriggerServerEvent('qb-scraproute:server:requestAction', action, spotId)
end

CreateThread(function()
    Wait(1500)

    if not Config.Target or not Config.Target.UseQBTarget then return end

    if not exports['qb-target'] then
        print('[qb-scraproute] qb-target not found. Set Config.Target.UseQBTarget=false and wire your own entrypoints.')
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
                            request('pickup', i)
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
                        request('process', 0)
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
                        request('sell', 0)
                    end,
                }
            },
            distance = 2.0
        }
    )
end)
