local QBCore = exports['qb-core']:GetCoreObject()

local busy = false
local currentRunId = nil
local currentSpotId = nil
local fixesDone = 0

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

    exports['qb-core']:Progressbar('qb_meterfix', label, timeMs, false, true, {
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

RegisterNetEvent('qb-meterfix:client:notify', function(msg, typ)
    notify(msg, typ)
end)

RegisterNetEvent('qb-meterfix:client:setRun', function(runId, spotId, fixes)
    currentRunId = runId
    currentSpotId = spotId
    fixesDone = fixes or 0

    if spotId and Config.FixSpots and Config.FixSpots[spotId] then
        local c = Config.FixSpots[spotId].coords
        SetNewWaypoint(c.x, c.y)
        notify(('New assignment: broken meter #%s marked on your GPS.'):format(spotId), 'primary')
    else
        notify('Shift ended.', 'primary')
    end
end)

RegisterNetEvent('qb-meterfix:client:beginAction', function(action, token, spotId)
    if busy then
        TriggerServerEvent('qb-meterfix:server:completeAction', action, token, spotId, true)
        return
    end

    local em = nil
    local label = 'Working…'

    if action == 'start' then
        em = Config.Emotes.Start
        label = 'Signing in…'
    elseif action == 'fix' then
        em = Config.Emotes.Fix
        label = 'Fixing meter…'
    elseif action == 'cashout' then
        em = Config.Emotes.Cashout
        label = 'Filing paperwork…'
    end

    local timeMs = (em and em.timeMs) or 6500

    playEmote(em)
    local ok = doProgress(label, timeMs)
    stopEmote()

    TriggerServerEvent('qb-meterfix:server:completeAction', action, token, spotId, not ok)
end)

local function request(action, spotId)
    if busy then return end
    TriggerServerEvent('qb-meterfix:server:requestAction', action, spotId)
end

CreateThread(function()
    Wait(1500)

    if not Config.Target or not Config.Target.UseQBTarget then return end

    if not exports['qb-target'] then
        print('[qb-meterfix] qb-target not found. Set Config.Target.UseQBTarget=false and wire your own entrypoints.')
        return
    end

    -- Depot: start / cashout / cancel
    exports['qb-target']:AddBoxZone(
        'qb_meterfix_depot',
        Config.Depot.coords,
        1.8, 1.8,
        {
            name = 'qb_meterfix_depot',
            heading = Config.Depot.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.Depot.coords.z - 1.0,
            maxZ = Config.Depot.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-clipboard-check',
                    label = 'Start maintenance shift',
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

    -- Fix spots
    for i, spot in ipairs(Config.FixSpots or {}) do
        exports['qb-target']:AddBoxZone(
            ('qb_meterfix_spot_%s'):format(i),
            spot.coords,
            1.2, 1.2,
            {
                name = ('qb_meterfix_spot_%s'):format(i),
                heading = spot.heading or 0.0,
                debugPoly = Config.Debug,
                minZ = spot.coords.z - 1.0,
                maxZ = spot.coords.z + 1.0,
            },
            {
                options = {
                    {
                        icon = 'fas fa-wrench',
                        label = 'Fix broken meter',
                        canInteract = function()
                            return currentRunId ~= nil and currentSpotId == i
                        end,
                        action = function()
                            request('fix', i)
                        end,
                    }
                },
                distance = 2.0
            }
        )
    end
end)
