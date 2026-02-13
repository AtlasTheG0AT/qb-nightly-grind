local QBCore = exports['qb-core']:GetCoreObject()

local CurrentRun = nil
local CurrentDeliveryZone = nil
local PickupZones = {}

local function dbg(...)
    if Config.Debug then
        print('[qb-couriergrind]', ...)
    end
end

local function msNow()
    return GetGameTimer()
end

-- RPEmotes-Reborn helper. Tries a few common hooks without hard dependency.
local function PlayRpEmote(emoteName, duration)
    if not emoteName or emoteName == '' then return end

    -- Preferred: RPEmotes-Reborn export (varies by version)
    if exports['rpemotes'] ~= nil then
        if exports['rpemotes'].EmoteCommandStart ~= nil then
            exports['rpemotes']:EmoteCommandStart(emoteName)
        elseif exports['rpemotes'].EmoteCommand ~= nil then
            exports['rpemotes']:EmoteCommand(emoteName)
        end
    end

    -- Fallback: qb/animations event (some servers bridge RPEmotes)
    TriggerEvent('animations:client:EmoteCommandStart', { emoteName })

    if duration and duration > 0 then
        CreateThread(function()
            Wait(duration)
            -- Try to stop emote cleanly
            if exports['rpemotes'] ~= nil and exports['rpemotes'].EmoteCancel ~= nil then
                exports['rpemotes']:EmoteCancel(true)
            end
            TriggerEvent('animations:client:EmoteCommandStart', { 'c' })
        end)
    end
end

local function Notify(msg, msgType)
    QBCore.Functions.Notify(msg, msgType or 'primary')
end

local function ClearCurrentDeliveryZone()
    if CurrentDeliveryZone and exports['qb-target'] then
        exports['qb-target']:RemoveZone(CurrentDeliveryZone)
    end
    CurrentDeliveryZone = nil
end

local function SetWaypoint(vec)
    SetNewWaypoint(vec.x + 0.0, vec.y + 0.0)
end

local function CreateDeliveryZone(delivery)
    ClearCurrentDeliveryZone()
    if not Config.UseTarget or not exports['qb-target'] then return end

    local zoneName = ('courier-deliver-%s'):format(CurrentRun and CurrentRun.runId or 'none')
    CurrentDeliveryZone = zoneName

    exports['qb-target']:AddBoxZone(zoneName, delivery.coords, 1.6, 1.6, {
        name = zoneName,
        heading = delivery.heading or 0.0,
        debugPoly = Config.Debug,
        minZ = delivery.coords.z - 1.0,
        maxZ = delivery.coords.z + 1.5,
    }, {
        options = {
            {
                icon = Config.Target.Icon,
                label = Config.Target.DeliverLabel,
                action = function()
                    TriggerEvent('qb-couriergrind:client:Deliver')
                end,
            }
        },
        distance = Config.MaxInteractDistance
    })
end

local function SetupPickupZones()
    if not Config.UseTarget or not exports['qb-target'] then return end
    if #PickupZones > 0 then return end

    for i, p in ipairs(Config.Pickups) do
        local zoneName = ('courier-pickup-%d'):format(i)
        PickupZones[#PickupZones + 1] = zoneName

        exports['qb-target']:AddBoxZone(zoneName, p.coords, 2.0, 2.0, {
            name = zoneName,
            heading = p.heading or 0.0,
            debugPoly = Config.Debug,
            minZ = p.coords.z - 1.0,
            maxZ = p.coords.z + 1.5,
        }, {
            options = {
                {
                    icon = Config.Target.Icon,
                    label = Config.Target.StartLabel,
                    action = function()
                        TriggerEvent('qb-couriergrind:client:Start')
                    end,
                    canInteract = function()
                        return CurrentRun == nil
                    end,
                },
                {
                    icon = Config.Target.Icon,
                    label = Config.Target.PickupLabel,
                    action = function()
                        TriggerEvent('qb-couriergrind:client:Pickup')
                    end,
                    canInteract = function()
                        return CurrentRun ~= nil and CurrentRun.stage == 'pickup'
                    end,
                },
            },
            distance = Config.MaxInteractDistance
        })
    end
end

local function Cleanup()
    ClearCurrentDeliveryZone()
    CurrentRun = nil
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Cleanup()
end)

RegisterNetEvent('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    -- remove zones
    if exports['qb-target'] then
        for _, z in ipairs(PickupZones) do
            exports['qb-target']:RemoveZone(z)
        end
    end
    Cleanup()
end)

RegisterNetEvent('qb-couriergrind:client:Start', function()
    if CurrentRun ~= nil then
        Notify(Lang:t('error.busy'), 'error')
        return
    end

    PlayRpEmote(Config.Emotes.start.name, Config.Emotes.start.duration)
    TriggerServerEvent('qb-couriergrind:server:StartRun')
end)

RegisterNetEvent('qb-couriergrind:client:Pickup', function()
    if not CurrentRun or CurrentRun.stage ~= 'pickup' then return end

    PlayRpEmote(Config.Emotes.pickup.name, Config.Emotes.pickup.duration)
    TriggerServerEvent('qb-couriergrind:server:PickupPackage', CurrentRun.runId)
end)

RegisterNetEvent('qb-couriergrind:client:Deliver', function()
    if not CurrentRun or CurrentRun.stage ~= 'deliver' then return end

    PlayRpEmote(Config.Emotes.deliver.name, Config.Emotes.deliver.duration)
    TriggerServerEvent('qb-couriergrind:server:DeliverPackage', CurrentRun.runId)
end)

RegisterNetEvent('qb-couriergrind:client:Cancel', function()
    if not CurrentRun then return end
    TriggerServerEvent('qb-couriergrind:server:CancelRun', CurrentRun.runId)
    Cleanup()
end)

RegisterNetEvent('qb-couriergrind:client:RunStarted', function(payload)
    -- payload: { runId, pickup, delivery, hasVehicle }
    CurrentRun = {
        runId = payload.runId,
        stage = 'pickup',
        delivery = payload.delivery,
        hasVehicle = payload.hasVehicle,
        lastUpdate = msNow(),
    }

    Notify(Lang:t('success.started'), 'success')
    SetWaypoint(payload.pickup.coords)
    Notify(Lang:t('info.waypoint_set'), 'primary')
end)

RegisterNetEvent('qb-couriergrind:client:PickedUp', function(payload)
    if not CurrentRun or CurrentRun.runId ~= payload.runId then return end

    CurrentRun.stage = 'deliver'
    CurrentRun.delivery = payload.delivery

    Notify(Lang:t('success.picked_up'), 'success')
    SetWaypoint(payload.delivery.coords)
    CreateDeliveryZone(payload.delivery)
end)

RegisterNetEvent('qb-couriergrind:client:NextDelivery', function(payload)
    if not CurrentRun or CurrentRun.runId ~= payload.runId then return end

    CurrentRun.stage = 'deliver'
    CurrentRun.delivery = payload.delivery

    Notify(Lang:t('success.delivered'), 'success')
    SetWaypoint(payload.delivery.coords)
    CreateDeliveryZone(payload.delivery)
end)

RegisterNetEvent('qb-couriergrind:client:Finished', function(payload)
    if not CurrentRun or CurrentRun.runId ~= payload.runId then return end

    PlayRpEmote(Config.Emotes.finish.name, Config.Emotes.finish.duration)
    Notify(Lang:t('success.finished'), 'success')
    Cleanup()
end)

RegisterNetEvent('qb-couriergrind:client:RunInvalid', function()
    Notify(Lang:t('error.invalid_job'), 'error')
    Cleanup()
end)

CreateThread(function()
    Wait(1000)
    SetupPickupZones()

    -- Optional commands as fallback if qb-target isn't used
    RegisterCommand('courier', function()
        TriggerEvent('qb-couriergrind:client:Start')
    end)
    RegisterCommand('courierpickup', function()
        TriggerEvent('qb-couriergrind:client:Pickup')
    end)
    RegisterCommand('courierdeliver', function()
        TriggerEvent('qb-couriergrind:client:Deliver')
    end)
    RegisterCommand('couriercancel', function()
        TriggerEvent('qb-couriergrind:client:Cancel')
    end)
end)
