local QBCore = exports['qb-core']:GetCoreObject()

local Busy = {}               -- Busy[src] = true/false
local LastRequestAt = {}      -- LastRequestAt[src][action] = os.time()
local Pending = {}            -- Pending[src] = { action, token, spotId, startedAt, expiresAt }

local function now()
    return os.time()
end

local function randBetween(a, b)
    if a > b then a, b = b, a end
    return math.random(a, b)
end

local function notify(src, msg, typ)
    TriggerClientEvent('qb-warehousepack:client:notify', src, msg, typ or 'primary')
end

local function vec3dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function getActionCoords(action, spotId)
    if action == 'pickup' then
        local spot = Config.ShelfSpots[spotId]
        return spot and spot.coords or nil
    elseif action == 'pack' then
        return Config.PackingStation.coords
    elseif action == 'deliver' then
        return Config.DeliveryBay.coords
    end
    return nil
end

local function rateLimitOk(src, action)
    local secs = 0
    if action == 'pickup' then secs = Config.RateLimits.PickupSeconds end
    if action == 'pack' then secs = Config.RateLimits.PackSeconds end
    if action == 'deliver' then secs = Config.RateLimits.DeliverSeconds end

    LastRequestAt[src] = LastRequestAt[src] or {}
    local last = LastRequestAt[src][action] or 0
    if (now() - last) < secs then
        return false, secs - (now() - last)
    end

    LastRequestAt[src][action] = now()
    return true, 0
end

local function isNear(src, action, spotId)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local target = getActionCoords(action, spotId)
    if not target then return false end

    return vec3dist(coords, target) <= (Config.Security.InteractionDistance or 2.5)
end

local function removeItem(player, item, amount)
    if amount <= 0 then return true end
    return player.Functions.RemoveItem(item, amount, false, true) -- transactional
end

local function addItem(player, item, amount)
    if amount <= 0 then return true end
    return player.Functions.AddItem(item, amount, false, nil, true) -- transactional
end

local function addMoney(player, account, amount)
    player.Functions.AddMoney(account, amount, 'warehousepack')
end

local function clearState(src)
    Busy[src] = nil
    Pending[src] = nil
end

AddEventHandler('playerDropped', function()
    local src = source
    clearState(src)
    LastRequestAt[src] = nil
end)

RegisterNetEvent('qb-warehousepack:server:requestAction', function(action, spotId)
    local src = source

    if type(action) ~= 'string' then return end
    if action ~= 'pickup' and action ~= 'pack' and action ~= 'deliver' then
        return
    end

    if Busy[src] then
        notify(src, 'You are already busy.', 'error')
        return
    end

    local ok, waitLeft = rateLimitOk(src, action)
    if not ok then
        notify(src, ('Slow down. Wait %ss.'):format(waitLeft), 'error')
        return
    end

    if not isNear(src, action, spotId) then
        notify(src, 'Too far away.', 'error')
        return
    end

    -- Sanity check spotId
    if action == 'pickup' then
        if type(spotId) ~= 'number' or not Config.ShelfSpots[spotId] then
            notify(src, 'Invalid shelf.', 'error')
            return
        end
    else
        spotId = 0
    end

    local token = tostring(math.random(100000, 999999)) .. '-' .. tostring(now())
    local startedAt = now()
    local expiresAt = startedAt + (Config.Security.ActionTimeoutSeconds or 45)

    Busy[src] = true
    Pending[src] = {
        action = action,
        token = token,
        spotId = spotId,
        startedAt = startedAt,
        expiresAt = expiresAt,
    }

    TriggerClientEvent('qb-warehousepack:client:beginAction', src, action, token, spotId)
end)

RegisterNetEvent('qb-warehousepack:server:completeAction', function(action, token, spotId, cancelled)
    local src = source

    local pend = Pending[src]
    if not pend then
        Busy[src] = nil
        return
    end

    -- Always clear busy at end, even on failure
    Busy[src] = nil

    if cancelled then
        Pending[src] = nil
        return
    end

    if action ~= pend.action or token ~= pend.token or spotId ~= pend.spotId then
        Pending[src] = nil
        return
    end

    if now() > (pend.expiresAt or 0) then
        Pending[src] = nil
        notify(src, 'Took too long.', 'error')
        return
    end

    if not isNear(src, action, spotId) then
        Pending[src] = nil
        notify(src, 'Too far away.', 'error')
        return
    end

    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        Pending[src] = nil
        return
    end

    -- Award/consume items/money (server authoritative)
    if action == 'pickup' then
        local amt = randBetween(Config.Amounts.PickupMin, Config.Amounts.PickupMax)
        if not addItem(player, Config.Items.Box, amt) then
            notify(src, 'Inventory full.', 'error')
            Pending[src] = nil
            return
        end
        notify(src, ('Got %sx boxes.'):format(amt), 'success')

    elseif action == 'pack' then
        local required = Config.Amounts.PackIn
        local out = Config.Amounts.PackOut

        local boxItem = player.Functions.GetItemByName(Config.Items.Box)
        if not boxItem or (boxItem.amount or 0) < required then
            notify(src, ('Need %sx boxes.'):format(required), 'error')
            Pending[src] = nil
            return
        end

        if not removeItem(player, Config.Items.Box, required) then
            notify(src, 'Could not remove boxes.', 'error')
            Pending[src] = nil
            return
        end

        if not addItem(player, Config.Items.Crate, out) then
            -- refund
            addItem(player, Config.Items.Box, required)
            notify(src, 'Inventory full.', 'error')
            Pending[src] = nil
            return
        end

        notify(src, ('Packed %sx crate(s).'):format(out), 'success')

    elseif action == 'deliver' then
        local deliverAmt = randBetween(Config.Amounts.DeliverMin, Config.Amounts.DeliverMax)

        local crateItem = player.Functions.GetItemByName(Config.Items.Crate)
        local have = crateItem and crateItem.amount or 0
        if have <= 0 then
            notify(src, 'You have no crates to deliver.', 'error')
            Pending[src] = nil
            return
        end

        if deliverAmt > have then deliverAmt = have end

        if not removeItem(player, Config.Items.Crate, deliverAmt) then
            notify(src, 'Could not remove crates.', 'error')
            Pending[src] = nil
            return
        end

        local per = randBetween(Config.Pay.DeliverPerCrateMin, Config.Pay.DeliverPerCrateMax)
        local payout = per * deliverAmt
        addMoney(player, Config.Pay.Account or 'cash', payout)

        notify(src, ('Delivered %sx crates for $%s.'):format(deliverAmt, payout), 'success')
    end

    Pending[src] = nil
end)
