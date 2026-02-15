local QBCore = exports['qb-core']:GetCoreObject()

local Busy = {}
local Cooldowns = {}
local Runs = {}
local RateLimit = {}
local PoliceCooldown = {}

local function now()
    return os.time()
end

local function ms()
    return GetGameTimer()
end

local function dbg(...)
    if Config.Debug then
        print('[qb-couriergrind]', ...)
    end
end

local function randStr(n)
    local chars = {}
    for i = 48, 57 do chars[#chars+1] = string.char(i) end
    for i = 65, 90 do chars[#chars+1] = string.char(i) end
    for i = 97, 122 do chars[#chars+1] = string.char(i) end
    local out = {}
    for _ = 1, n do
        out[#out+1] = chars[math.random(1, #chars)]
    end
    return table.concat(out)
end

local function rateLimitOk(src, key)
    RateLimit[src] = RateLimit[src] or {}
    local t = ms()
    local last = RateLimit[src][key] or 0
    if (t - last) < (Config.EventRateLimitMs or 750) then
        return false
    end
    RateLimit[src][key] = t
    return true
end

local function getPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

local function getRep(ply)
    if not (Config.Rep and Config.Rep.Enabled) then return 0 end
    local key = Config.Rep.MetadataKey or 'courierrep'
    local md = (ply.PlayerData and ply.PlayerData.metadata) or {}
    local rep = tonumber(md[key] or 0) or 0
    return rep
end

local function setRep(ply, rep)
    if not (Config.Rep and Config.Rep.Enabled) then return end
    local key = Config.Rep.MetadataKey or 'courierrep'
    rep = math.max(0, math.floor(rep))
    -- Prefer SetMetaData (persists)
    if ply.Functions and ply.Functions.SetMetaData then
        ply.Functions.SetMetaData(key, rep)
    else
        ply.PlayerData.metadata[key] = rep
    end
end

local function addRep(ply, delta)
    if not (Config.Rep and Config.Rep.Enabled) then return 0 end
    local rep = getRep(ply)
    rep = rep + (delta or 0)
    setRep(ply, rep)
    return rep
end

local function getTierForRep(rep)
    local tier = { name = 'Rookie', minRep = 0, payoutMult = 1.0, alertChanceMult = 1.0 }
    if not (Config.Rep and Config.Rep.Tiers and #Config.Rep.Tiers > 0) then
        return tier
    end

    for _, t in ipairs(Config.Rep.Tiers) do
        if rep >= (t.minRep or 0) and (t.minRep or 0) >= (tier.minRep or 0) then
            tier = t
        end
    end

    tier.payoutMult = tonumber(tier.payoutMult or 1.0) or 1.0
    tier.alertChanceMult = tonumber(tier.alertChanceMult or 1.0) or 1.0
    return tier
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return vector3(c.x, c.y, c.z)
end

local function dist(a, b)
    return #(a - b)
end

local function notify(src, msg, msgType)
    TriggerClientEvent('QBCore:Notify', src, msg, msgType or 'primary')
end

local function chooseRandom(list)
    return list[math.random(1, #list)]
end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function sampleDropoffs(count)
    local idx = {}
    for i = 1, #Config.Dropoffs do idx[#idx+1] = i end
    shuffle(idx)

    local out = {}
    for i = 1, math.min(count, #idx) do
        out[#out+1] = Config.Dropoffs[idx[i]]
    end
    return out
end

local function clearState(src)
    Busy[src] = nil
    Runs[src] = nil
end

local function trySpawnVehicle(src, spawn)
    if not Config.UseJobVehicle then return { ok = true, hasVehicle = false } end

    local model = joaat(Config.JobVehicleModel or 'speedo')
    if not IsModelInCdimage(model) then
        dbg('invalid vehicle model')
        return { ok = false, err = 'no_vehicle_spawn' }
    end

    RequestModel(model)
    local started = GetGameTimer()
    while not HasModelLoaded(model) do
        Wait(10)
        if (GetGameTimer() - started) > 5000 then
            return { ok = false, err = 'no_vehicle_spawn' }
        end
    end

    local coords = spawn.coords
    local heading = spawn.heading or 0.0

    -- Server-side create vehicle
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)
    if not veh or veh == 0 then
        return { ok = false, err = 'no_vehicle_spawn' }
    end

    while not DoesEntityExist(veh) do Wait(0) end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetVehicleDoorsLocked(veh, 1)

    -- Give keys if qb-vehiclekeys exists (most implementations listen client-side)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, GetVehicleNumberPlateText(veh))

    SetModelAsNoLongerNeeded(model)

    return { ok = true, hasVehicle = true, netId = netId }
end

AddEventHandler('playerDropped', function()
    local src = source
    clearState(src)
    Cooldowns[src] = nil
    RateLimit[src] = nil
    PoliceCooldown[src] = nil
end)

-- Default police alert handler (no-op by default).
-- Change `Config.PoliceAlert.ServerEvent` to match your dispatch/police resource.
AddEventHandler('qb-couriergrind:server:PoliceAlert', function(payload)
    dbg('PoliceAlert payload:', json.encode(payload or {}))
end)

RegisterNetEvent('qb-couriergrind:server:StartRun', function()
    local src = source
    if not rateLimitOk(src, 'start') then return end

    if Busy[src] then
        notify(src, Lang:t('error.busy'), 'error')
        return
    end

    local t = now()
    local cd = Cooldowns[src] or 0
    if (t - cd) < (Config.CooldownSeconds or 60) then
        notify(src, Lang:t('error.cooldown'), 'error')
        return
    end

    local ply = getPlayer(src)
    if not ply then return end

    if not Config.Pickups or #Config.Pickups < 1 or not Config.Dropoffs or #Config.Dropoffs < 2 then
        notify(src, 'Courier job is not configured.', 'error')
        return
    end

    Busy[src] = true
    Cooldowns[src] = t

    local pickup = chooseRandom(Config.Pickups)
    local num = math.random(Config.DeliveriesPerRun.min or 4, Config.DeliveriesPerRun.max or 7)
    local route = sampleDropoffs(num)

    local runId = randStr(12) .. tostring(src)

    local spawn = chooseRandom(Config.VehicleSpawns or Config.Pickups)
    local vehicleRes = { ok = true, hasVehicle = false }
    local depositTaken = false

    if Config.UseJobVehicle then
        -- take deposit first (server-side)
        if (Config.VehicleDeposit or 0) > 0 then
            if not ply.Functions.RemoveMoney(Config.PayoutAccount or 'cash', Config.VehicleDeposit, 'courier-vehicle-deposit') then
                Busy[src] = nil
                notify(src, 'Not enough money for vehicle deposit.', 'error')
                return
            end
            depositTaken = true
        end

        vehicleRes = trySpawnVehicle(src, spawn)
        if not vehicleRes.ok then
            Busy[src] = nil
            if depositTaken and (Config.VehicleDeposit or 0) > 0 then
                ply.Functions.AddMoney(Config.PayoutAccount or 'cash', Config.VehicleDeposit, 'courier-vehicle-deposit-refund')
            end
            notify(src, Lang:t('error.no_vehicle_spawn'), 'error')
            return
        end
    end

    local rep = getRep(ply)
    local tier = getTierForRep(rep)

    Runs[src] = {
        runId = runId,
        stage = 'pickup',
        pickup = pickup,
        route = route,
        step = 1,
        startedAt = t,
        depositTaken = depositTaken,
        vehicleNetId = vehicleRes.netId,
        paid = 0,
        repAtStart = rep,
        tierAtStart = tier.name,
    }

    TriggerClientEvent('qb-couriergrind:client:RunStarted', src, {
        runId = runId,
        pickup = pickup,
        delivery = route[1],
        hasVehicle = vehicleRes.hasVehicle,
        vehicleNetId = vehicleRes.netId,
        rep = rep,
        tier = tier.name,
    })
end)

RegisterNetEvent('qb-couriergrind:server:PickupPackage', function(runId)
    local src = source
    if not rateLimitOk(src, 'pickup') then return end

    local run = Runs[src]
    if not run or run.runId ~= runId or run.stage ~= 'pickup' then
        TriggerClientEvent('qb-couriergrind:client:RunInvalid', src)
        clearState(src)
        return
    end

    local ply = getPlayer(src)
    if not ply then return end

    local pcoords = getPlayerCoords(src)
    if not pcoords then return end

    if dist(pcoords, run.pickup.coords) > (Config.MaxInteractDistance or 3.0) then
        notify(src, Lang:t('error.too_far'), 'error')
        return
    end

    -- transactional inventory add (server-side)
    ply.Functions.AddItem(Config.PackageItem, Config.PackageItemAmount or 1, false, {}, 'courier-pickup')
    local itemData = QBCore.Shared.Items[Config.PackageItem]
    if itemData then
        TriggerClientEvent('inventory:client:ItemBox', src, itemData, 'add')
    end

    run.stage = 'deliver'

    TriggerClientEvent('qb-couriergrind:client:PickedUp', src, {
        runId = run.runId,
        delivery = run.route[run.step],
    })
end)

RegisterNetEvent('qb-couriergrind:server:DeliverPackage', function(runId)
    local src = source
    if not rateLimitOk(src, 'deliver') then return end

    local run = Runs[src]
    if not run or run.runId ~= runId or run.stage ~= 'deliver' then
        TriggerClientEvent('qb-couriergrind:client:RunInvalid', src)
        clearState(src)
        return
    end

    local ply = getPlayer(src)
    if not ply then return end

    local target = run.route[run.step]
    if not target then
        TriggerClientEvent('qb-couriergrind:client:RunInvalid', src)
        clearState(src)
        return
    end

    local pcoords = getPlayerCoords(src)
    if not pcoords then return end

    if dist(pcoords, target.coords) > (Config.MaxDeliveryDistance or 4.0) then
        notify(src, Lang:t('error.too_far'), 'error')
        return
    end

    -- transactional inventory remove (server-side)
    local removed = ply.Functions.RemoveItem(Config.PackageItem, Config.PackageItemAmount or 1, false, 'courier-deliver')
    if not removed then
        notify(src, Lang:t('error.no_package'), 'error')
        return
    end
    local itemData = QBCore.Shared.Items[Config.PackageItem]
    if itemData then
        TriggerClientEvent('inventory:client:ItemBox', src, itemData, 'remove')
    end

    -- payout + progression (server-side)
    local repBefore = getRep(ply)
    local tier = getTierForRep(repBefore)

    local basePay = math.random(Config.PayoutPerDelivery.min or 120, Config.PayoutPerDelivery.max or 220)
    local pay = math.floor((basePay * (tier.payoutMult or 1.0)) + 0.5)
    pay = math.max(1, pay)

    ply.Functions.AddMoney(Config.PayoutAccount or 'cash', pay, 'courier-delivery')
    run.paid = (run.paid or 0) + pay

    -- Rep gain after successful delivery
    local repAfter = addRep(ply, Config.Rep and Config.Rep.RepPerDelivery or 0)
    if Config.Rep and Config.Rep.Enabled then
        local tierAfter = getTierForRep(repAfter)
        if tierAfter.name ~= tier.name then
            notify(src, Lang:t('success.tier_up', { tier = tierAfter.name }), 'success')
        end
        notify(src, Lang:t('info.rep_gain', { rep = repAfter, tier = tierAfter.name }), 'primary')
    end

    -- Optional: police alert chance (server-side)
    if Config.PoliceAlert and Config.PoliceAlert.Enabled then
        local tNow = now()
        local last = PoliceCooldown[src] or 0
        if (tNow - last) >= (Config.PoliceAlert.CooldownSeconds or 90) then
            local chance = (Config.PoliceAlert.ChancePerDelivery or 0.0) * (tier.alertChanceMult or 1.0)
            if chance > 0.0 and math.random() < chance then
                PoliceCooldown[src] = tNow

                local payload = {
                    src = src,
                    coords = target.coords,
                    code = (Config.PoliceAlert.Payload and Config.PoliceAlert.Payload.code) or '10-66',
                    title = (Config.PoliceAlert.Payload and Config.PoliceAlert.Payload.title) or 'Suspicious courier activity',
                    tier = tier.name,
                }

                TriggerEvent(Config.PoliceAlert.ServerEvent or 'qb-couriergrind:server:PoliceAlert', payload)
                notify(src, Lang:t('info.police_alerted'), 'error')
            end
        end
    end

    run.step = run.step + 1

    if run.step > #run.route then
        -- refund deposit only on successful finish
        if run.depositTaken and (Config.VehicleDeposit or 0) > 0 then
            ply.Functions.AddMoney(Config.PayoutAccount or 'cash', Config.VehicleDeposit, 'courier-vehicle-deposit-refund')
        end

        TriggerClientEvent('qb-couriergrind:client:Finished', src, { runId = run.runId, paid = run.paid })
        clearState(src)
        return
    end

    -- next stop
    TriggerClientEvent('qb-couriergrind:client:NextDelivery', src, {
        runId = run.runId,
        delivery = run.route[run.step],
    })
end)

RegisterNetEvent('qb-couriergrind:server:CancelRun', function(runId)
    local src = source
    if not rateLimitOk(src, 'cancel') then return end

    local run = Runs[src]
    if not run or run.runId ~= runId then
        TriggerClientEvent('qb-couriergrind:client:RunInvalid', src)
        clearState(src)
        return
    end

    local ply = getPlayer(src)
    if ply and run.depositTaken and (Config.VehicleDeposit or 0) > 0 then
        -- Cancel forfeits deposit by default (discourages spam). If you want refunds on cancel, change here.
    end

    clearState(src)
end)
