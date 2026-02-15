local QBCore = exports['qb-core']:GetCoreObject()

local busy = false
local currentRunId = nil
local currentSpotId = nil
local postersDone = 0

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

    exports['qb-core']:Progressbar('qb_posterhustle', label, timeMs, false, true, {
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

RegisterNetEvent('qb-posterhustle:client:notify', function(msg, typ)
    notify(msg, typ)
end)

RegisterNetEvent('qb-posterhustle:client:setRun', function(runId, spotId, posters)
    currentRunId = runId
    currentSpotId = spotId
    postersDone = posters or 0

    if spotId and Config.PosterSpots and Config.PosterSpots[spotId] then
        local c = Config.PosterSpots[spotId].coords
        SetNewWaypoint(c.x, c.y)
        notify(('New posting assignment: spot #%s marked on your GPS.'):format(spotId), 'primary')
    else
        notify('Shift ended.', 'primary')
    end
end)

RegisterNetEvent('qb-posterhustle:client:beginAction', function(action, token, spotId)
    if busy then
        TriggerServerEvent('qb-posterhustle:server:completeAction', action, token, spotId, true)
        return
    end

    local em, label = nil, 'Working…'

    if action == 'start' then
        em = Config.Emotes.Start
        label = 'Signing for supplies…'
    elseif action == 'post' then
        em = Config.Emotes.Post
        label = 'Putting up flyers…'
    elseif action == 'cashout' then
        em = Config.Emotes.Cashout
        label = 'Turning in proof…'
    end

    local timeMs = (em and em.timeMs) or 6500

    playEmote(em)
    local ok = doProgress(label, timeMs)
    stopEmote()

    TriggerServerEvent('qb-posterhustle:server:completeAction', action, token, spotId, not ok)
end)

local function request(action, spotId)
    if busy then return end
    TriggerServerEvent('qb-posterhustle:server:requestAction', action, spotId)
end

CreateThread(function()
    Wait(1500)

    if not Config.Target or not Config.Target.UseQBTarget then return end

    if not exports['qb-target'] then
        print('[qb-posterhustle] qb-target not found. Set Config.Target.UseQBTarget=false and wire your own entrypoints.')
        return
    end

    -- Office: start / cashout / cancel
    exports['qb-target']:AddBoxZone(
        'qb_posterhustle_office',
        Config.Office.coords,
        1.8, 1.8,
        {
            name = 'qb_posterhustle_office',
            heading = Config.Office.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.Office.coords.z - 1.0,
            maxZ = Config.Office.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-clipboard-check',
                    label = 'Start flyer shift',
                    action = function() request('start', 0) end,
                },
                {
                    icon = 'fas fa-file-invoice-dollar',
                    label = 'Cash out shift',
                    action = function() request('cashout', 0) end,
                },
                {
                    icon = 'fas fa-ban',
                    label = 'Cancel shift',
                    canInteract = function()
                        return Config.Run and Config.Run.AllowCancel and currentRunId ~= nil
                    end,
                    action = function() request('cancel', 0) end,
                },
            },
            distance = 2.0
        }
    )

    -- Poster spots
    for i, spot in ipairs(Config.PosterSpots or {}) do
        exports['qb-target']:AddBoxZone(
            ('qb_posterhustle_spot_%s'):format(i),
            spot.coords,
            1.2, 1.2,
            {
                name = ('qb_posterhustle_spot_%s'):format(i),
                heading = spot.heading or 0.0,
                debugPoly = Config.Debug,
                minZ = spot.coords.z - 1.0,
                maxZ = spot.coords.z + 1.0,
            },
            {
                options = {
                    {
                        icon = 'fas fa-paste',
                        label = 'Put up flyers',
                        canInteract = function()
                            return currentRunId ~= nil and currentSpotId == i
                        end,
                        action = function()
                            request('post', i)
                        end,
                    }
                },
                distance = 2.0
            }
        )
    end
end)
