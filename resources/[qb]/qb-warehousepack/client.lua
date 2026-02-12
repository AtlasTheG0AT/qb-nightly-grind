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

    exports['qb-core']:Progressbar('qb_warehousepack', label, timeMs, false, true, {
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

RegisterNetEvent('qb-warehousepack:client:notify', function(msg, typ)
    notify(msg, typ)
end)

-- Server-approved flow:
-- 1) client requests action (spotId)
-- 2) server validates distance + rate limit + busy lock
-- 3) server tells client to run progress/emote
-- 4) client reports completion; server awards items/money
RegisterNetEvent('qb-warehousepack:client:beginAction', function(action, token, spotId)
    if busy then
        -- Shouldn't happen because server enforces busy lock, but don't stack progressbars.
        TriggerServerEvent('qb-warehousepack:server:completeAction', action, token, spotId, true)
        return
    end

    local em = nil
    if action == 'pickup' then em = Config.Emotes.Pickup end
    if action == 'pack' then em = Config.Emotes.Pack end
    if action == 'deliver' then em = Config.Emotes.Deliver end

    local label = 'Working…'
    if action == 'pickup' then label = 'Grabbing boxes…' end
    if action == 'pack' then label = 'Packing crates…' end
    if action == 'deliver' then label = 'Delivering crates…' end

    local timeMs = (em and em.timeMs) or 8000

    playEmote(em)
    local ok = doProgress(label, timeMs)
    stopEmote()

    TriggerServerEvent('qb-warehousepack:server:completeAction', action, token, spotId, not ok)
end)

local function request(action, spotId)
    if busy then return end
    TriggerServerEvent('qb-warehousepack:server:requestAction', action, spotId)
end

CreateThread(function()
    Wait(1500)

    if not Config.Target or not Config.Target.UseQBTarget then return end

    if not exports['qb-target'] then
        print('[qb-warehousepack] qb-target not found. Set Config.Target.UseQBTarget=false and wire your own entrypoints.')
        return
    end

    -- Shelf spots
    for i, spot in ipairs(Config.ShelfSpots) do
        exports['qb-target']:AddBoxZone(
            ('qb_warehousepack_shelf_%s'):format(i),
            spot.coords,
            1.2, 1.2,
            {
                name = ('qb_warehousepack_shelf_%s'):format(i),
                heading = spot.heading or 0.0,
                debugPoly = Config.Debug,
                minZ = spot.coords.z - 1.0,
                maxZ = spot.coords.z + 1.0,
            },
            {
                options = {
                    {
                        icon = 'fas fa-box',
                        label = 'Grab boxes',
                        action = function()
                            request('pickup', i)
                        end,
                    }
                },
                distance = 2.0
            }
        )
    end

    -- Packing station
    exports['qb-target']:AddBoxZone(
        'qb_warehousepack_pack',
        Config.PackingStation.coords,
        1.6, 1.6,
        {
            name = 'qb_warehousepack_pack',
            heading = Config.PackingStation.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.PackingStation.coords.z - 1.0,
            maxZ = Config.PackingStation.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-boxes-packing',
                    label = 'Pack crates',
                    action = function()
                        request('pack', 0)
                    end,
                }
            },
            distance = 2.0
        }
    )

    -- Delivery bay
    exports['qb-target']:AddBoxZone(
        'qb_warehousepack_deliver',
        Config.DeliveryBay.coords,
        1.8, 1.8,
        {
            name = 'qb_warehousepack_deliver',
            heading = Config.DeliveryBay.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = Config.DeliveryBay.coords.z - 1.0,
            maxZ = Config.DeliveryBay.coords.z + 1.0,
        },
        {
            options = {
                {
                    icon = 'fas fa-truck-loading',
                    label = 'Deliver crates',
                    action = function()
                        request('deliver', 0)
                    end,
                }
            },
            distance = 2.0
        }
    )
end)
