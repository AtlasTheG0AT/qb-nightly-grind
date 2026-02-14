local QBCore = exports['qb-core']:GetCoreObject()

-- Nitro Golden Rules coverage:
-- - Server-validated interactions (distance checks)
-- - Server-side rate limiting
-- - Per-player busy lock (with timeout + cleanup)
-- - Transactional-ish inventory ops (rollback when possible)
-- - No trusting client for rewards

local Busy = {}      -- [src] = { action=string, token=string, startedAt=unix, spotId=number }
local LastCall = {}  -- [src] = { forage=unix, clean=unix, sell=unix }

local function now()
    return os.time()
end

local function notify(src, msg, typ)
    TriggerClientEvent('qb-foragerun:client:notify', src, msg, typ)
end

local function isBusy(src)
    return Busy[src] ~= nil
end

local function clearBusy(src)
    Busy[src] = nil
end

local function setBusy(src, state)
    Busy[src] = state
end

AddEventHandler('playerDropped', function()
    local src = source
    Busy[src] = nil
    LastCall[src] = nil
end)

local function randBetween(a, b)
    if a > b then a, b = b, a end
    return math.random(a, b)
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

local function invHas(Player, item, amount)
    local it = Player.Functions.GetItemByName(item)
    return it and it.amount and it.amount >= amount
end

local function makeToken(src)
    return ('%s:%s:%s'):format(src, now(), math.random(100000, 999999))
end

local function getActionConfig(action)
    if action == 'forage' then
        return {
            key = 'forage',
            rate = (Config.RateLimits and Config.RateLimits.ForageSeconds) or 18,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 35,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    elseif action == 'clean' then
        return {
            key = 'clean',
            rate = (Config.RateLimits and Config.RateLimits.CleanSeconds) or 12,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 35,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    elseif action == 'sell' then
        return {
            key = 'sell',
            rate = (Config.RateLimits and Config.RateLimits.SellSeconds) or 10,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 30,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    end
    return nil
end

local function validateSpot(action, spotId)
    if action == 'forage' then
        if type(spotId) ~= 'number' then return nil end
        local spot = Config.ForageSpots and Config.ForageSpots[spotId]
        if not spot or not spot.coords then return nil end
        return spot.coords
    elseif action == 'clean' then
        return Config.CleanStation and Config.CleanStation.coords
    elseif action == 'sell' then
        return Config.Buyer and Config.Buyer.coords
    end
    return nil
end

RegisterNetEvent('qb-foragerun:server:requestAction', function(action, spotId)
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

    local coords = validateSpot(action, spotId)
    if not coords then
        notify(src, 'Invalid location.', 'error')
        return
    end

    if not withinDist(src, coords, cfg.dist) then
        notify(src, 'Too far away.', 'error')
        return
    end

    local token = makeToken(src)
    setBusy(src, {
        action = action,
        token = token,
        startedAt = now(),
        spotId = spotId,
    })

    TriggerClientEvent('qb-foragerun:client:beginAction', src, action, token, spotId)
end)

RegisterNetEvent('qb-foragerun:server:completeAction', function(action, token, spotId, cancelled)
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

    local coords = validateSpot(action, spotId)
    if not coords or not withinDist(src, coords, cfg.dist) then
        notify(src, 'Too far away.', 'error')
        clearBusy(src)
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then clearBusy(src) return end

    if action == 'forage' then
        local qty = randBetween(Config.Amounts.ForageMin, Config.Amounts.ForageMax)
        local ok = Player.Functions.AddItem(Config.Items.Raw, qty)
        if ok then
            notify(src, ('Foraged x%s %s'):format(qty, Config.Items.Raw), 'success')
        else
            notify(src, 'Inventory full.', 'error')
        end

    elseif action == 'clean' then
        local need = Config.Amounts.CleanIn
        if not invHas(Player, Config.Items.Raw, need) then
            notify(src, ('Need x%s %s'):format(need, Config.Items.Raw), 'error')
            clearBusy(src)
            return
        end

        if not Player.Functions.RemoveItem(Config.Items.Raw, need) then
            notify(src, 'Could not remove items.', 'error')
            clearBusy(src)
            return
        end

        local out = Config.Amounts.CleanOut
        local ok = Player.Functions.AddItem(Config.Items.Clean, out)
        if not ok then
            Player.Functions.AddItem(Config.Items.Raw, need) -- rollback
            notify(src, 'Inventory full (rolled back).', 'error')
            clearBusy(src)
            return
        end

        notify(src, ('Cleaned x%s %s'):format(out, Config.Items.Clean), 'success')

    elseif action == 'sell' then
        local qty = randBetween(Config.Amounts.SellMin, Config.Amounts.SellMax)
        if not invHas(Player, Config.Items.Clean, qty) then
            notify(src, ('Need x%s %s'):format(qty, Config.Items.Clean), 'error')
            clearBusy(src)
            return
        end

        local each = randBetween(Config.Pay.SellEachMin, Config.Pay.SellEachMax)
        local total = each * qty

        if not Player.Functions.RemoveItem(Config.Items.Clean, qty) then
            notify(src, 'Could not remove items.', 'error')
            clearBusy(src)
            return
        end

        Player.Functions.AddMoney(Config.Pay.Account, total, 'foragerun-sell')
        notify(src, ('Sold x%s for $%s'):format(qty, total), 'success')
    end

    clearBusy(src)
end)

-- Failsafe: clear busy state if it gets stuck
CreateThread(function()
    while true do
        Wait(30 * 1000)
        local t = now()
        for src, state in pairs(Busy) do
            local cfg = getActionConfig(state.action)
            local timeout = cfg and (cfg.timeout + 10) or 60
            if (t - (state.startedAt or 0)) > timeout then
                Busy[src] = nil
            end
        end
    end
end)
