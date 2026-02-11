local QBCore = exports['qb-core']:GetCoreObject()

-- Nitro Golden Rules coverage:
-- - Server-validated interactions (distance checks)
-- - Server-side rate limiting
-- - Per-player busy lock (with timeout + cleanup)
-- - Transactional-ish inventory ops (rollback when possible)
-- - No trusting client for rewards

local Busy = {}      -- [src] = { action=string, token=string, startedAt=unix, spotId=number }
local LastCall = {}  -- [src] = { pickup=unix, process=unix, sell=unix }

local function now()
    return os.time()
end

local function notify(src, msg, typ)
    TriggerClientEvent('qb-scraproute:client:notify', src, msg, typ)
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
    -- token doesn't need cryptographic strength; just prevent blind event spam
    return ('%s:%s:%s'):format(src, now(), math.random(100000, 999999))
end

local function getActionConfig(action)
    if action == 'pickup' then
        return {
            key = 'pickup',
            rate = (Config.RateLimits and Config.RateLimits.PickupSeconds) or (Config.Cooldowns and Config.Cooldowns.PickupSeconds) or 30,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 30,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    elseif action == 'process' then
        return {
            key = 'process',
            rate = (Config.RateLimits and Config.RateLimits.ProcessSeconds) or (Config.Cooldowns and Config.Cooldowns.ProcessSeconds) or 15,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 30,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    elseif action == 'sell' then
        return {
            key = 'sell',
            rate = (Config.RateLimits and Config.RateLimits.SellSeconds) or (Config.Cooldowns and Config.Cooldowns.SellSeconds) or 15,
            timeout = (Config.Security and Config.Security.ActionTimeoutSeconds) or 25,
            dist = (Config.Security and Config.Security.InteractionDistance) or 2.5,
        }
    end
    return nil
end

local function validateSpot(action, spotId)
    if action == 'pickup' then
        if type(spotId) ~= 'number' then return nil end
        local spot = Config.PickupSpots and Config.PickupSpots[spotId]
        if not spot or not spot.coords then return nil end
        return spot.coords
    elseif action == 'process' then
        return Config.Processor and Config.Processor.coords
    elseif action == 'sell' then
        return Config.Buyer and Config.Buyer.coords
    end
    return nil
end

RegisterNetEvent('qb-scraproute:server:requestAction', function(action, spotId)
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

    TriggerClientEvent('qb-scraproute:client:beginAction', src, action, token, spotId)
end)

RegisterNetEvent('qb-scraproute:server:completeAction', function(action, token, spotId, cancelled)
    local src = source

    local state = Busy[src]
    if not state then return end

    local cfg = getActionConfig(action)
    if not cfg then clearBusy(src) return end

    -- Strict matching (prevents client firing complete for a different action)
    if state.action ~= action or state.token ~= token then
        -- Suspicious or out-of-order; just clear.
        clearBusy(src)
        return
    end

    if cancelled == true then
        clearBusy(src)
        return
    end

    -- Timeout check
    if (now() - (state.startedAt or 0)) > cfg.timeout then
        notify(src, 'Took too long.', 'error')
        clearBusy(src)
        return
    end

    -- Distance check again at completion
    local coords = validateSpot(action, spotId)
    if not coords or not withinDist(src, coords, cfg.dist) then
        notify(src, 'Too far away.', 'error')
        clearBusy(src)
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then clearBusy(src) return end

    if action == 'pickup' then
        local qty = randBetween(Config.Amounts.PickupMin, Config.Amounts.PickupMax)
        local ok = Player.Functions.AddItem(Config.Items.ScrapRaw, qty)
        if ok then
            notify(src, ('Picked up x%s %s'):format(qty, Config.Items.ScrapRaw), 'success')
        else
            notify(src, 'Inventory full.', 'error')
        end

    elseif action == 'process' then
        local need = Config.Amounts.ProcessIn
        if not invHas(Player, Config.Items.ScrapRaw, need) then
            notify(src, ('Need x%s %s'):format(need, Config.Items.ScrapRaw), 'error')
            clearBusy(src)
            return
        end

        -- transactional-ish: remove then add, rollback if add fails
        if not Player.Functions.RemoveItem(Config.Items.ScrapRaw, need) then
            notify(src, 'Could not remove items.', 'error')
            clearBusy(src)
            return
        end

        local out = Config.Amounts.ProcessOut
        local ok = Player.Functions.AddItem(Config.Items.ScrapProcessed, out)
        if not ok then
            Player.Functions.AddItem(Config.Items.ScrapRaw, need) -- rollback
            notify(src, 'Inventory full (rolled back).', 'error')
            clearBusy(src)
            return
        end

        notify(src, ('Processed x%s %s'):format(out, Config.Items.ScrapProcessed), 'success')

    elseif action == 'sell' then
        local qty = randBetween(Config.Amounts.SellMin, Config.Amounts.SellMax)
        if not invHas(Player, Config.Items.ScrapProcessed, qty) then
            notify(src, ('Need x%s %s'):format(qty, Config.Items.ScrapProcessed), 'error')
            clearBusy(src)
            return
        end

        local payEach = randBetween(Config.Pay.SellPerBundleMin, Config.Pay.SellPerBundleMax)
        local total = payEach * qty

        if not Player.Functions.RemoveItem(Config.Items.ScrapProcessed, qty) then
            notify(src, 'Could not remove items.', 'error')
            clearBusy(src)
            return
        end

        Player.Functions.AddMoney(Config.Pay.Account, total, 'scraproute-sell')
        notify(src, ('Sold x%s for $%s'):format(qty, total), 'success')
    end

    clearBusy(src)
end)

-- Failsafe: clear busy state if it gets stuck (e.g. client crash)
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
