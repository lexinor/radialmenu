
PlayerData = ESX.GetPlayerData()

-- Functions
local function convert(table)
    if table.items then
        local items = {}
        for _, v in pairs(table.items) do
            items[#items+1] = convert(v)
        end
        lib.registerRadial({
            id = table.id..'_menu',
            items = items
        })
        return { id = table.id, label = table.title or table.label, icon = table.icon, menu = table.id..'_menu' }
    end
    local action
    if table.event then
        if table.type == 'client' then
            action = function() TriggerEvent(table.event, table.arg or nil) end
        elseif table.type == 'server' then
            action = function() TriggerServerEvent(table.event, table.arg or nil) end
        elseif table.action then
            action = function() table.action(table.arg) end
        end
    end
    if table.command then
        if table.type == 'command' then
            action = function() ExecuteCommand(table.event) end
        elseif table.type == 'qbcommand' then
            action = function() TriggerServerEvent('QBCore:CallCommand', table.event, table.arg or nil) end
        end
    end
    local onSelect = table.onSelect or function()
        if action then action() end
        if table.shouldClose then lib.hideRadial() end
    end
    return { id = table.id, label = table.title or table.label, icon = table.icon, onSelect = onSelect }
end

local function AddVehicleSeats()
    CreateThread(function()
        while true do
            Wait(50)
            if IsControlJustPressed(0, 23) and not cache.vehicle then
                local vehicle, _ = QBCore.Functions.GetClosestVehicle(GetEntityCoords(cache.ped))
                if vehicle then
                    local vehicleseats = {}
                    local seatTable = {
                        [1] = Lang:t("options.driver_seat"),
                        [2] = Lang:t("options.passenger_seat"),
                        [3] = Lang:t("options.rear_left_seat"),
                        [4] = Lang:t("options.rear_right_seat"),
                    }

                    local AmountOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
                    for i = 1, AmountOfSeats do
                        vehicleseats[#vehicleseats+1] = {
                            id = 'vehicleseat'..i,
                            label = seatTable[i] or Lang:t("options.other_seats"),
                            icon = 'caret-up',
                            onSelect = function()
                                if cache.vehicle then
                                    TriggerEvent('radialmenu:client:ChangeSeat', i, seatTable[i] or Lang:t("options.other_seats"))
                                else
                                    ESX.ShowNotification(Lang:t('error.not_in_vehicle'), 'error')
                                end
                                lib.hideRadial()
                            end,
                        }
                    end
                    lib.registerRadial({
                        id = 'vehicleseatsmenu',
                        items = vehicleseats
                    })
                end
            end
        end
    end)
end

local function SetupVehicleMenu()
    local VehicleMenu = {
        id = 'vehicle',
        label = Lang:t("options.vehicle"),
        icon = 'car',
        menu = 'vehiclemenu'
    }
    
    local vehicleitems = {{
        id = 'vehicle-flip',
        label = Lang:t("options.flip"),
        icon = 'car-burst',
        onSelect = function()
            TriggerEvent('radialmenu:flipVehicle')
            lib.hideRadial()
        end,
    }}
    
    vehicleitems[#vehicleitems+1] = convert(Config.VehicleDoors)
    if Config.EnableExtraMenu then vehicleitems[#vehicleitems+1] = convert(Config.VehicleExtras) end
    
    if Config.VehicleSeats then
        AddVehicleSeats()
        vehicleitems[#vehicleitems+1] = Config.VehicleSeats
    end
    lib.registerRadial({
        id = 'vehiclemenu',
        items = vehicleitems
    })
    lib.addRadialItem(VehicleMenu)
end

local function SetupRadialMenu()
    SetupVehicleMenu()

    for _, v in pairs(Config.MenuItems) do
        lib.addRadialItem(convert(v))
    end
    
    if Config.GangInteractions[PlayerData.gang.name] then
        lib.addRadialItem(convert({
            id = 'ganginteractions',
            label = Lang:t("general.gang_radial"),
            icon = 'skull-crossbones',
            items = Config.GangInteractions[PlayerData.gang.name]
        }))
    end

    if not PlayerData.job.onduty then return end
    if not Config.JobInteractions[PlayerData.job.name] then return end

    lib.addRadialItem(convert({
        id = 'jobinteractions',
        label = Lang:t("general.job_radial"),
        icon = 'briefcase',
        items = Config.JobInteractions[PlayerData.job.name]
    }))
end

local function IsPolice()
    return (PlayerData.job.type == "leo" and PlayerData.job.onduty)
end

local function IsEMS()
    return (PlayerData.job.type == "medic" and PlayerData.job.onduty)
end

-- Events
RegisterNetEvent('radialmenu:client:deadradial', function(isDead)
    if isDead then
        local ispolice, isems = IsPolice(), IsEMS()
        if not ispolice or isems then return lib.disableRadial(true) end
        lib.clearRadialItems()
        lib.addRadialItem({
            id = 'emergencybutton2',
            label = Lang:t("options.emergency_button"),
            icon = 'circle-exclamation',
            onSelect = function (_, _)
                if ispolice then
                    TriggerEvent('police:client:SendPoliceEmergencyAlert')
                elseif isems then
                    TriggerEvent('ambulance:client:SendAmbulanceEmergencyAlert')
                end
                lib.hideRadial()
            end
        })
    else
        lib.clearRadialItems()
        SetupRadialMenu()
        lib.disableRadial(false)
    end
end)

RegisterNetEvent('radialmenu:client:ChangeSeat', function(id, label)
    local Veh = cache.vehicle
    local IsSeatFree = IsVehicleSeatFree(Veh, id - 2)
    local speed = GetEntitySpeed(Veh)
    local HasHarness = exports['qb-smallresources']:HasHarness()
    if HasHarness then
        return ESX.ShowNotification(Lang:t("error.race_harness_on"), 'error')
    end

    if not IsSeatFree then
       return ESX.ShowNotification(Lang:t("error.seat_occupied"), 'error')
    end
    
    local kmh = speed * 3.6
    
    if kmh > 100.0 then
       return ESX.ShowNotification(Lang:t("error.vehicle_driving_fast"), 'error')
    end
    
    SetPedIntoVehicle(cache.ped, Veh, id - 2)
    ESX.ShowNotification(Lang:t("info.switched_seats", {seat = label}))
end)

RegisterNetEvent('qb-radialmenu:trunk:client:Door', function(plate, door, open)
    local veh = cache.vehicle
    if not veh then return end
    
    local pl = QBCore.Functions.GetPlate(veh)
    if pl ~= plate then return end
    
    if open then
        SetVehicleDoorOpen(veh, door, false, false)
    else
        SetVehicleDoorShut(veh, door, false)
    end
end)

RegisterNetEvent('qb-radialmenu:client:noPlayers', function()
    ESX.ShowNotification(Lang:t("error.no_people_nearby"), 'error', 2500)
end)

RegisterNetEvent('qb-radialmenu:client:openDoor', function(id)
    local door = id
    local closestVehicle = cache.vehicle or QBCore.Functions.GetClosestVehicle(GetEntityCoords(cache.ped))
    if closestVehicle ~= 0 then
        if closestVehicle ~= cache.vehicle then
            local plate = QBCore.Functions.GetPlate(closestVehicle)
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', false, plate, door)
                else
                    SetVehicleDoorShut(closestVehicle, door, false)
                end
            else
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', true, plate, door)
                else
                    SetVehicleDoorOpen(closestVehicle, door, false, false)
                end
            end
        else
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                SetVehicleDoorShut(closestVehicle, door, false)
            else
                SetVehicleDoorOpen(closestVehicle, door, false, false)
            end
        end
    else
        ESX.ShowNotification(Lang:t("error.no_vehicle_found"), 'error', 2500)
    end
end)

RegisterNetEvent('radialmenu:client:setExtra', function(id)
    local extra = id
    local veh = cache.vehicle
    if veh ~= nil then
        if GetPedInVehicleSeat(veh, -1) == cache.ped then
            SetVehicleAutoRepairDisabled(veh, true) -- Forces Auto Repair off when Toggling Extra [GTA 5 Niche Issue]
            if DoesExtraExist(veh, extra) then
                if IsVehicleExtraTurnedOn(veh, extra) then
                    SetVehicleExtra(veh, extra, 1)
                    ESX.ShowNotification(Lang:t("error.extra_deactivated", {extra = extra}), 'error', 2500)
                else
                    SetVehicleExtra(veh, extra, 0)
                    ESX.ShowNotification(Lang:t("success.extra_activated", {extra = extra}), 'success', 2500)
                end
            else
                ESX.ShowNotification(Lang:t("error.extra_not_present", {extra = extra}), 'error', 2500)
            end
        else
            ESX.ShowNotification(Lang:t("error.not_driver"), 'error', 2500)
        end
    end
end)

RegisterNetEvent('radialmenu:flipVehicle', function()
    if cache.vehicle then return end
    TriggerEvent('animations:client:EmoteCommandStart', {"mechanic"})
    QBCore.Functions.Progressbar("flipping_car", Lang:t("progress.flipping_car"), Config.Fliptime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(cache.ped))
        if distance <= 15 then
            SetVehicleOnGroundProperly(vehicle)
        end
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end, function() -- Cancel
        ESX.ShowNotification(Lang:t("error.cancel_task"), "error")
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        SetupRadialMenu()
    end
end)

AddEventHandler('onResourceStop', function(resource)
   if resource == GetCurrentResourceName() then
        lib.clearRadialItems()
   end
end)

-- Sets the metadata when the player spawns
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = ESX.GetPlayerData()
    SetupRadialMenu()
end)

-- Sets the playerdata to an empty table when the player has quit or did /logout
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

-- This will update all the PlayerData that doesn't get updated with a specific event other than this like the metadata
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    lib.removeRadialItem('jobinteractions')
    PlayerData.job = job
    if job.onduty and Config.JobInteractions[job.name] then
       lib.addRadialItem(convert({
            id = 'jobinteractions',
            label = Lang:t("general.job_radial"),
            icon = 'briefcase',
            items = Config.JobInteractions[job.name]
        }))
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onduty)
    lib.removeRadialItem('jobinteractions')
    if onduty and Config.JobInteractions[PlayerData.job.name] then
       lib.addRadialItem(convert({
            id = 'jobinteractions',
            label = Lang:t("general.job_radial"),
            icon = 'briefcase',
            items = Config.JobInteractions[PlayerData.job.name]
        }))
    end
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    lib.removeRadialItem('ganginteractions')
    PlayerData.gang = gang
    if Config.GangInteractions[gang.name] and next(Config.GangInteractions[gang.name]) then
        lib.addRadialItem(convert({
            id = 'ganginteractions',
            label = Lang:t("general.gang_radial"),
            icon = 'skull-crossbones',
            items = Config.GangInteractions[gang.name]
        }))
    end
end)

exports('AddOption', function(data, id)
    data.id = data.id or id and id
    lib.addRadialItem(convert(data))
    return data.id
end)

exports('RemoveOption', function(id)
    lib.removeRadialItem(id)
end)
