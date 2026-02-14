local QBCore = exports['qb-core']:GetCoreObject()

local busy = false

local function notify(msg, typ)
    TriggerEvent('QBCore:Notify', msg, typ or 'primary')
end

local function playEmote(cfg)
    if not cfg or not cfg.emote then return end
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

    exports['qb-core']:Progressbar('qb_foragerun', label, timeMs, false, true, {
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

RegisterNetEvent('qb-foragerun:client:notify', function(msg, typ)
    notify(msg, typ)
end)

RegisterNetEvent('qb-foragerun:client:beginAction', function(action, token, spotId)
    if busy then
        TriggerServerEvent('qb-foragerun:server:completeAction', action, token, spotId, true)
        return
    end

    local em = nil
    local label = 'Working…'

    if action == 'forage' then
        em = Config.Emotes.Forage
        label = 'Foraging…'
    elseif action == 'clean' then
        em = Config.Emotes.Clean
        label = 'Cleaning herbs…'
    elseif action == 'sell' then
        em = Config.Emotes.Sell
        label = 'Selling goods…'
    end

    local timeMs = (em and em.timeMs) or 8000

    playEmote(em)
    local ok = doProgress(label, timeMs)
    stopEmote()

    TriggerServerEvent('qb-foragerun:server:completeAction', action, token, spotId, not ok)
end)

local function request(action, spotId)
    if busy then return end
    TriggerServerEvent('qb-foragerun:server:requestAction', action, spotId)
end

CreateThread(function()
    Wait(1500)

    if not Config.Target or not Config.Target.UseQBTarget then return end

    if not exports['qb-target'] then
        print('[qb-foragerun] qb-target not found. Set Config.Target.UseQBTarget=false and wire your own entrypoints.')
        return
    end

    -- Forage spots
    for i, spot in ipairs(Config.ForageSpots) do
        exports['qb-target']:AddBoxZone(
            ('qb_foragerun_forage_%s'):format(i),
            spot.coords,
            1.2, 1.2,
            {
                name = ('qb_foragerun_forage_%s'):format(i),
                heading = spot.heading or 0.0,
                debugPoly = Config.Debug,
                minZ = spot.coords.z - 1.0,
                maxZ = spot.coords.z + 1.0,
            },
            {
                options = {
                    {
                        icon = 'fas fa-leaf',
                        label = 'Forage herbs',
                        action = function()
                            request('forage', i)
                        end,
                    }
                },
                distance = 2.0
            }
        )
    end

    -- Clean station
    exports['qb-target']:AddBoxZone(
        'qb_foragerun_clean',
        Config.CleanStation.coords,
        1.6, 1.6,
        {
            name = 'qb_foragerun_clean',
            heading = Config.CleanStation.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.CleanStation.coords.z - 1.0,
            maxZ = Config.CleanStation.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-soap',
                    label = 'Clean herbs',
                    action = function()
                        request('clean', 0)
                    end,
                }
            },
            distance = 2.0
        }
    )

    -- Buyer
    exports['qb-target']:AddBoxZone(
        'qb_foragerun_buyer',
        Config.Buyer.coords,
        1.6, 1.6,
        {
            name = 'qb_foragerun_buyer',
            heading = Config.Buyer.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.Buyer.coords.z - 1.0,
            maxZ = Config.Buyer.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-dollar-sign',
                    label = 'Sell clean herbs',
                    action = function()
                        request('sell', 0)
                    end,
                }
            },
            distance = 2.0
        }
    )
end)
