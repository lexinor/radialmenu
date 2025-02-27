local isAttached = false
local stretcherObject = nil
local isLayingOnBed = false
local detachKeys = {157, 158, 160, 164, 165, 73, 36}

-- Add your vehicles here that will allow Ambulance to get a stretcher out.
local allowedStretcherVehicles = {
    "ambulance",
}

-- Functions

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function checkForVehicles()
    local PlayerPos = GetEntityCoords(cache.ped)
    local veh = 0
    for _, v in pairs(allowedStretcherVehicles) do
        veh = GetClosestVehicle(PlayerPos.x, PlayerPos.y, PlayerPos.z, 7.5, GetHashKey(v), 70)
        if veh ~= 0 then
            break
        end
    end
    return veh
end

local function setClosestStretcher()
    local coords = GetEntityCoords(cache.ped)
    local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, `prop_ld_binbag_01`, false, false, false)
    if object == 0 then return end
    stretcherObject = object
end

local function loadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

local function GetClosestPlayer()
    local closestPlayers = ESX.Game.GetPlayersInArea(GetEntityCoords(cache.ped), 5.0)
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(cache.ped)
    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= cache.ped then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
	end
	return closestPlayer, closestDistance
end

local function LayOnStretcher()
    local inBedDicts = "anim@gangops@morgue@table@"
    local inBedAnims = "ko_front"
    local coords = GetEntityCoords(cache.ped)
    local player, distance = GetClosestPlayer()
    if player == -1 then
        loadAnim(inBedDicts)
        if stretcherObject and #(coords - GetEntityCoords(stretcherObject)) <= 3.0 then
            TaskPlayAnim(cache.ped, inBedDicts, inBedAnims, 8.0, 8.0, -1, 69, 1, false, false, false)
            AttachEntityToEntity(cache.ped, stretcherObject, 0, 0, 0.0, 1.0, 0.0, 0.0, 180.0, 0.0, false, false, false, false, 2)
            isLayingOnBed = true
        end
    else
        if distance < 2.0 then
            TriggerServerEvent('radialmenu:Stretcher:BusyCheck', GetPlayerServerId(player), "lay")
        else
            loadAnim(inBedDicts)
            if stretcherObject and #(coords - GetEntityCoords(stretcherObject)) <= 3.0 then
                TaskPlayAnim(cache.ped, inBedDicts, inBedAnims, 8.0, 8.0, -1, 69, 1, false, false, false)
                AttachEntityToEntity(cache.ped, stretcherObject, 0, 0, 0.0, 1.6, 0.0, 0.0, 360.0, 0.0, false, false, false, false, 2)
                isLayingOnBed = true
            end
        end
    end
end

local function getOffStretcher()
    local coords = GetOffsetFromEntityInWorldCoords(stretcherObject, 0.85, 0.0, 0)
    ClearPedTasks(cache.ped)
    DetachEntity(cache.ped, false, true)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z)
    isLayingOnBed = false
end

local function attachToStretcher()
    local closestPlayer, distance = GetClosestPlayer()
    if stretcherObject then
        if closestPlayer == -1 then
            NetworkRequestControlOfEntity(stretcherObject)
            loadAnim("anim@heists@box_carry@")
            TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
            SetTimeout(150, function()
                AttachEntityToEntity(stretcherObject, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.0, -1.0, -0.50, 195.0, 180.0, 180.0, 90.0, false, false, true, false, 2)
            end)
            FreezeEntityPosition(stretcherObject, false)
        else
            if distance < 2.0 then
                TriggerServerEvent('radialmenu:Stretcher:BusyCheck', GetPlayerServerId(closestPlayer), "attach")
            else
                NetworkRequestControlOfEntity(stretcherObject)
                loadAnim("anim@heists@box_carry@")
                TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
                SetTimeout(150, function()
                    AttachEntityToEntity(stretcherObject, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.0, -1.0, -1.0, 195.0, 180.0, 180.0, 90.0, false, false, true, false, 2)
                end)
                FreezeEntityPosition(stretcherObject, false)
            end
        end
    end
end

local function detachStretcher()
    DetachEntity(stretcherObject, false, true)
    ClearPedTasksImmediately(cache.ped)
    isAttached = false
end

-- Events

RegisterNetEvent('radialmenu:client:TakeStretcher', function()
    local vehicle = checkForVehicles()
    if vehicle ~= 0 then
        RequestModel("prop_ld_binbag_01")
        while not HasModelLoaded("prop_ld_binbag_01") do
            Wait(0)
        end
        local obj = CreateObject(`prop_ld_binbag_01`, GetEntityCoords(cache.ped), true)
        if obj ~= 0 then
            SetEntityRotation(obj, 0.0, 0.0, GetEntityHeading(vehicle), false, false)
            FreezeEntityPosition(obj, true)
            PlaceObjectOnGroundProperly(obj)
            stretcherObject = obj
            SetTimeout(200, function()
                attachToStretcher()
                isAttached = true
            end)
        else
            ESX.ShowNotification(Translations[Config.Local].error.obj_not_found, 'error')
        end
    else
        ESX.ShowNotification(Translations[Config.Local].error.not_near_ambulance, 'error')
    end
end)

RegisterNetEvent('radialmenu:client:RemoveStretcher', function()
    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0, 1.5, 0)
    if stretcherObject then
        local bCoords = GetEntityCoords(stretcherObject)
        if #(coords - bCoords) < 3.0 then
            if DoesEntityExist(stretcherObject) then
                DeleteEntity(stretcherObject)
                ClearPedTasks(cache.ped)
                DetachEntity(cache.ped, false, true)
                TriggerServerEvent('radialmenu:server:RemoveStretcher', coords, stretcherObject)
                isAttached = false
                stretcherObject = nil
                isLayingOnBed = false
            end
        else
            ESX.ShowNotification(Translations[Config.Local].error.far_away, 'error')
        end
    end
end)

RegisterNetEvent('radialmenu:client:RemoveStretcherFromArea', function(playerPos, bObject)
    local pos = GetEntityCoords(cache.ped)
    if pos ~= playerPos then
        if stretcherObject then
            if stretcherObject == bObject then
                if #(pos - playerPos) < 10 then
                    if IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'idle', false) then
                        detachStretcher()
                    end
                    if IsEntityPlayingAnim(cache.ped, "anim@gangops@morgue@table@", "ko_front", false) then
                        local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.85, 0.0, 0)
                        ClearPedTasks(cache.ped)
                        DetachEntity(cache.ped, false, true)
                        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z)
                        isLayingOnBed = false
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('radialmenu:Stretcher:client:BusyCheck', function(otherId, type)
    if type == "lay" then
        loadAnim("anim@gangops@morgue@table@")
        if IsEntityPlayingAnim(cache.ped, "anim@gangops@morgue@table@", "ko_front", 3) then
            TriggerServerEvent('radialmenu:server:BusyResult', true, otherId, type)
        else
            TriggerServerEvent('radialmenu:server:BusyResult', false, otherId, type)
        end
    else
        loadAnim('anim@heists@box_carry@')
        if IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 3) then
            TriggerServerEvent('radialmenu:server:BusyResult', true, otherId, type)
        else
            TriggerServerEvent('radialmenu:server:BusyResult', false, otherId, type)
        end
    end
end)

RegisterNetEvent('radialmenu:client:Result', function(isBusy, type)
    local inBedDicts = "anim@gangops@morgue@table@"
    local inBedAnims = "ko_front"
    if type == "lay" then
        if not isBusy then
            NetworkRequestControlOfEntity(stretcherObject)
            loadAnim(inBedDicts)
            TaskPlayAnim(cache.ped, inBedDicts, inBedAnims, 8.0, 8.0, -1, 69, 1, false, false, false)
            AttachEntityToEntity(cache.ped, stretcherObject, 0, 0, 0.0, 1.6, 0.0, 0.0, 360.0, 0.0, false, false, false, false, 2)
            isLayingOnBed = true
        else
            ESX.ShowNotification(Translations[Config.Local].error.stretcher_in_use, "error")
            isLayingOnBed = false
        end
    else
        if not isBusy then
            NetworkRequestControlOfEntity(stretcherObject)
            loadAnim("anim@heists@box_carry@")
            TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
            SetTimeout(150, function()
                AttachEntityToEntity(stretcherObject, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.0, -1.0, -1.0, 195.0, 180.0, 180.0, 90.0, false, false, true, false, 2)
            end)
            FreezeEntityPosition(stretcherObject, false)
            isAttached = true
        else
            ESX.ShowNotification(Translations[Config.Local].error.stretcher_in_use, "error")
            isAttached = false
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if stretcherObject then
            detachStretcher()
            DeleteObject(stretcherObject)
            ClearPedTasksImmediately(cache.ped)
        end
    end
end)

-- Threads

CreateThread(function()
    while true do
        setClosestStretcher()
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(cache.ped)
        if stretcherObject then
            local offsetCoords = GetOffsetFromEntityInWorldCoords(stretcherObject, 0, 0.85, 0)
            local distance = #(pos - offsetCoords)
            if distance <= 1.0 then
                if not isAttached then
                    sleep = 0
                    DrawText3Ds(offsetCoords.x, offsetCoords.y, offsetCoords.z, Translations[Config.Local].general.push_stretcher_button)
                    if IsControlJustPressed(0, 51) then
                        attachToStretcher()
                        isAttached = true
                        sleep = 100
                    end
                    if IsControlJustPressed(0, 74) then
                        FreezeEntityPosition(stretcherObject, true)
                        sleep = 100
                    end
                else
                    sleep = 0
                    DrawText3Ds(offsetCoords.x, offsetCoords.y, offsetCoords.z, Translations[Config.Local].general.stop_pushing_stretcher_button)
                    if IsControlJustPressed(0, 51) then
                        detachStretcher()
                        isAttached = false
                        sleep = 100
                    end
                end

                if not isLayingOnBed then
                    if not isAttached then
                        sleep = 0
                        DrawText3Ds(offsetCoords.x, offsetCoords.y, offsetCoords.z + 0.2, Translations[Config.Local].general.lay_stretcher_button)
                        if IsControlJustPressed(0, 47) or IsDisabledControlJustPressed(0, 47) then
                            LayOnStretcher()
                            sleep = 100
                        end
                    end
                end
            elseif distance <= 2 then
                if not isLayingOnBed then
                    sleep = 0
                    DrawText3Ds(offsetCoords.x, offsetCoords.y, offsetCoords.z, Translations[Config.Local].general.push_position_drawtext)
                else
                    if not isAttached then
                        sleep = 0
                        DrawText3Ds(offsetCoords.x, offsetCoords.y, offsetCoords.z + 0.2, Translations[Config.Local].general.get_off_stretcher_button)
                        if IsControlJustPressed(0, 47) or IsDisabledControlJustPressed(0, 47) then
                            getOffStretcher()
                            sleep = 100
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isAttached then
            sleep = 0
            for _, PressedKey in pairs(detachKeys) do
                if IsControlJustPressed(0, PressedKey) or IsDisabledControlJustPressed(0, PressedKey) then
                    detachStretcher()
                    sleep = 100
                end
            end
            if IsPedShooting(cache.ped) or IsPlayerFreeAiming(PlayerId()) or IsPedInMeleeCombat(cache.ped) or IsEntityDead(cache.ped) or IsPedRagdoll(cache.ped) then
                detachStretcher()
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(1000)
    local pos = GetEntityCoords(cache.ped)
    local object = GetClosestObjectOfType(pos.x, pos.y, pos.z, 5.0, `prop_ld_binbag_01`, false, false, false)
    if object ~= 0 then
        DeleteObject(object)
        ClearPedTasksImmediately(cache.ped)
    end
end)