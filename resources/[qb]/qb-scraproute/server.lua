local QBCore = exports['qb-core']:GetCoreObject()

local Busy = {}
local function isBusy(src)
    return Busy[src] == true
end

local function setBusy(src, val)
    Busy[src] = val and true or nil
end

AddEventHandler('playerDropped', function()
    local src = source
    Busy[src] = nil
end)

local function notify(src, msg, typ)
    TriggerClientEvent('qb-scraproute:client:notify', src, msg, typ)
end

local function randBetween(a, b)
    if a > b then a, b = b, a end
    return math.random(a, b)
end

local function invHas(Player, item, amount)
    local it = Player.Functions.GetItemByName(item)
    return it and it.amount and it.amount >= amount
end

RegisterNetEvent('qb-scraproute:server:pickup', function()
    local src = source
    if isBusy(src) then return end
    setBusy(src, true)

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then setBusy(src, false) return end

    local qty = randBetween(Config.Amounts.PickupMin, Config.Amounts.PickupMax)

    local ok = Player.Functions.AddItem(Config.Items.ScrapRaw, qty)
    if ok then
        notify(src, ('Picked up x%s %s'):format(qty, Config.Items.ScrapRaw), 'success')
    else
        notify(src, 'Inventory full.', 'error')
    end

    setBusy(src, false)
end)

RegisterNetEvent('qb-scraproute:server:process', function()
    local src = source
    if isBusy(src) then return end
    setBusy(src, true)

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then setBusy(src, false) return end

    local need = Config.Amounts.ProcessIn
    if not invHas(Player, Config.Items.ScrapRaw, need) then
        notify(src, ('Need x%s %s'):format(need, Config.Items.ScrapRaw), 'error')
        setBusy(src, false)
        return
    end

    -- transactional-ish: remove then add, rollback if add fails
    if not Player.Functions.RemoveItem(Config.Items.ScrapRaw, need) then
        notify(src, 'Could not remove items.', 'error')
        setBusy(src, false)
        return
    end

    local out = Config.Amounts.ProcessOut
    local ok = Player.Functions.AddItem(Config.Items.ScrapProcessed, out)
    if not ok then
        Player.Functions.AddItem(Config.Items.ScrapRaw, need) -- rollback
        notify(src, 'Inventory full (rolled back).', 'error')
        setBusy(src, false)
        return
    end

    notify(src, ('Processed x%s %s'):format(out, Config.Items.ScrapProcessed), 'success')
    setBusy(src, false)
end)

RegisterNetEvent('qb-scraproute:server:sell', function()
    local src = source
    if isBusy(src) then return end
    setBusy(src, true)

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then setBusy(src, false) return end

    local qty = randBetween(Config.Amounts.SellMin, Config.Amounts.SellMax)

    if not invHas(Player, Config.Items.ScrapProcessed, qty) then
        notify(src, ('Need x%s %s'):format(qty, Config.Items.ScrapProcessed), 'error')
        setBusy(src, false)
        return
    end

    local payEach = randBetween(Config.Pay.SellPerBundleMin, Config.Pay.SellPerBundleMax)
    local total = payEach * qty

    if not Player.Functions.RemoveItem(Config.Items.ScrapProcessed, qty) then
        notify(src, 'Could not remove items.', 'error')
        setBusy(src, false)
        return
    end

    Player.Functions.AddMoney(Config.Pay.Account, total, 'scraproute-sell')
    notify(src, ('Sold x%s for $%s'):format(qty, total), 'success')

    setBusy(src, false)
end)
