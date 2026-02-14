local QBCore = exports['qb-core']:GetCoreObject()

-- Nitro Golden Rules coverage:
-- - Server-authoritative run state (client only requests actions)
-- - Distance checks + action timeouts
-- - Server-side rate limiting
-- - Per-player busy lock with cleanup

local Busy = {}       -- [src] = { action=string, token=string, startedAt=unix, spotId=number }
local LastCall = {}   -- [src] = { start=unix, fix=unix, cashout=unix, cancel=unix }
local Runs = {}       -- [src] = { runId=string, spotId=number, fixes=number }

local function now()
    return os.time()
end

local function notify(src, msg, typ)
    TriggerClientEvent('qb-meterfix:client:notify', src, msg, typ)
end

local function clearBusy(src)
    Busy[src] = nil
end

local function isBusy(src)
    return Busy[src] ~= nil
end

local function ensureRateLimit(src, key, seconds)
    local t = now()
    LastCall[src] = LastCall[src] or {}
    local last = LastCall[src][key] or 0
    if (t - last) < seconds then
        return false
    end
    LastCall[src][key] = t
    return true
end

local function makeToken(src)
    return ('%s:%s:%s'):format(src, now(), math.random(100000, 999999))
end

local function makeRunId(src)
    return ('run:%s:%s:%s'):format(src, now(), math.random(1000, 9999))
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return vector3(c.x, c.y, c.z)
end

local function withinDist(src, targetCoords, dist)
    local c = getPlayerCoords(src)
    if not c then return false end
    return #(c - targetCoords) <= dist
end

local function pickSpot()
    local spots = Config.FixSpots or {}
    if #spots <= 0 then return nil end
    return math.random(1, #spots)
end

local function randBetween(a, b)
    if a > b then a, b = b, a end
    return math.random(a, b)
end

local function getActionConfig(action)
    if action == 'start' then
        return {
            key = 'start',
            rate = (Config.RateLimits and Config.RateLimits.StartSeconds) or 10,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 35,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    elseif action == 'fix' then
        return {
            key = 'fix',
            rate = (Config.RateLimits and Config.RateLimits.FixSeconds) or 8,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 35,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    elseif action == 'cashout' then
        return {
            key = 'cashout',
            rate = (Config.RateLimits and Config.RateLimits.CashoutSeconds) or 10,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 35,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    elseif action == 'cancel' then
        return {
            key = 'cancel',
            rate = 3,
            timeout = 10,
            dist = 25.0,
        }
    end

    return nil
end

local function validateCoordsForAction(src, action, spotId)
    if action == 'start' or action == 'cashout' then
        if not Config.Depot or not Config.Depot.coords then return nil end
        return Config.Depot.coords
    elseif action == 'fix' then
        if type(spotId) ~= 'number' then return nil end
        local spot = Config.FixSpots and Config.FixSpots[spotId]
        if not spot or not spot.coords then return nil end
        return spot.coords
    elseif action == 'cancel' then
        -- cancel can be anywhere-ish; still require they have a run
        return getPlayerCoords(src) or vector3(0, 0, 0)
    end
    return nil
end

local function sendRun(src)
    local r = Runs[src]
    if not r then
        TriggerClientEvent('qb-meterfix:client:setRun', src, nil, nil, 0)
        return
    end
    TriggerClientEvent('qb-meterfix:client:setRun', src, r.runId, r.spotId, r.fixes)
end

local function requireTool(Player)
    local item = Config.Items and Config.Items.RequiredTool
    if not item then return true end
    local it = Player.Functions.GetItemByName(item)
    return it and it.amount and it.amount >= 1
end

AddEventHandler('playerDropped', function()
    local src = source
    Busy[src] = nil
    LastCall[src] = nil
    Runs[src] = nil
end)

RegisterNetEvent('qb-meterfix:server:requestAction', function(action, spotId)
    local src = source

    local cfg = getActionConfig(action)
    if not cfg then return end

    if isBusy(src) then
        notify(src, 'You are already busy.', 'error')
        return
    end

    if not ensureRateLimit(src, cfg.key, cfg.rate) then
        notify(src, 'Slow down (rate limit).', 'error')
        return
    end

    -- Run state validation
    if action == 'start' then
        if Runs[src] then
            notify(src, 'You are already on a shift.', 'error')
            return
        end
    elseif action == 'fix' then
        local r = Runs[src]
        if not r then
            notify(src, 'Start a shift first.', 'error')
            return
        end
        if r.spotId ~= spotId then
            notify(src, 'That is not your assigned meter.', 'error')
            return
        end
    elseif action == 'cashout' then
        local r = Runs[src]
        if not r then
            notify(src, 'No active shift.', 'error')
            return
        end
        local need = (Config.Run and Config.Run.FixesPerShift) or 3
        if (r.fixes or 0) < need then
            notify(src, ('Fix %s more meter(s) before cashout.'):format(need - (r.fixes or 0)), 'error')
            return
        end
    elseif action == 'cancel' then
        if not (Config.Run and Config.Run.AllowCancel) then
            notify(src, 'Cancel is disabled.', 'error')
            return
        end
        if not Runs[src] then
            notify(src, 'No active shift.', 'error')
            return
        end
    end

    local coords = validateCoordsForAction(src, action, spotId)
    if not coords then
        notify(src, 'Invalid location.', 'error')
        return
    end

    if action ~= 'cancel' and not withinDist(src, coords, cfg.dist) then
        notify(src, 'Too far away.', 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if (action == 'start' or action == 'fix') and not requireTool(Player) then
        local tool = Config.Items and Config.Items.RequiredTool
        notify(src, ('You need a %s.'):format(tool), 'error')
        return
    end

    local token = makeToken(src)
    Busy[src] = {
        action = action,
        token = token,
        startedAt = now(),
        spotId = spotId,
    }

    TriggerClientEvent('qb-meterfix:client:beginAction', src, action, token, spotId)
end)

RegisterNetEvent('qb-meterfix:server:completeAction', function(action, token, spotId, cancelled)
    local src = source

    local state = Busy[src]
    if not state then return end

    local cfg = getActionConfig(action)
    if not cfg then clearBusy(src) return end

    if state.action ~= action or state.token ~= token then
        clearBusy(src)
        return
    end

    if cancelled == true then
        clearBusy(src)
        return
    end

    if (now() - (state.startedAt or 0)) > cfg.timeout then
        notify(src, 'Took too long.', 'error')
        clearBusy(src)
        return
    end

    if action ~= 'cancel' then
        local coords = validateCoordsForAction(src, action, spotId)
        if not coords or not withinDist(src, coords, cfg.dist) then
            notify(src, 'Too far away.', 'error')
            clearBusy(src)
            return
        end
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then clearBusy(src) return end

    if action == 'start' then
        local newSpot = pickSpot()
        if not newSpot then
            notify(src, 'No fix spots configured.', 'error')
            clearBusy(src)
            return
        end

        Runs[src] = {
            runId = makeRunId(src),
            spotId = newSpot,
            fixes = 0,
        }

        notify(src, 'Shift started. Head to your assigned broken meter.', 'success')
        sendRun(src)

    elseif action == 'fix' then
        local r = Runs[src]
        if not r then clearBusy(src) return end
        if r.spotId ~= spotId then
            notify(src, 'That is not your assigned meter.', 'error')
            clearBusy(src)
            return
        end

        local pay = randBetween((Config.Payout and Config.Payout.PerFixMin) or 110, (Config.Payout and Config.Payout.PerFixMax) or 165)
        Player.Functions.AddMoney('cash', pay, 'meterfix-per-fix')

        r.fixes = (r.fixes or 0) + 1

        local need = (Config.Run and Config.Run.FixesPerShift) or 3
        if r.fixes >= need then
            notify(src, ('Meter fixed. Earned $%s. Return to the depot to cash out.'):format(pay), 'success')
            r.spotId = nil
            sendRun(src)
        else
            local newSpot = pickSpot()
            r.spotId = newSpot
            notify(src, ('Meter fixed. Earned $%s. New assignment sent. (%s/%s)'):format(pay, r.fixes, need), 'success')
            sendRun(src)
        end

    elseif action == 'cashout' then
        local r = Runs[src]
        if not r then clearBusy(src) return end

        local bonus = randBetween((Config.Payout and Config.Payout.ShiftBonusMin) or 125, (Config.Payout and Config.Payout.ShiftBonusMax) or 220)
        Player.Functions.AddMoney('cash', bonus, 'meterfix-shift-bonus')

        notify(src, ('Shift cashed out. Bonus: $%s.'):format(bonus), 'success')
        Runs[src] = nil
        sendRun(src)

    elseif action == 'cancel' then
        Runs[src] = nil
        notify(src, 'Shift cancelled.', 'primary')
        sendRun(src)
    end

    clearBusy(src)
end)
