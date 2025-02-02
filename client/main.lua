-- Get QBCore object
local QBCore = exports['qb-core']:GetCoreObject()

-- Shared State Variables
local inTrunk = false
local carrying = false            -- True if the carrier is currently carrying someone
local putSomebodyInTrunk = false
local carryingEntity = nil        -- The ped being carried (on the carrier side)
local beingCarried = false        -- True if the player is being carried (on the carried side)
local disableKeysTemporary = false
local putInSomeoneTrunk = false
local disableCameraTemp = false

lib.locale()

--------------------------------------------
-- Exported Functions
--------------------------------------------
local function isPedOnCarry()
    return beingCarried
end
exports('isPedOnCarry', isPedOnCarry)

--------------------------------------------
-- Utility Functions
--------------------------------------------
local function disableCamera(vehicle)
    disableCameraTemp = true
    DoScreenFadeOut(1)
    Citizen.CreateThread(function()
        while disableCameraTemp do
            Citizen.Wait(1000)  -- Check every second
            if GetVehicleDoorAngleRatio(vehicle, 5) > 0.0 then
                DoScreenFadeIn(1)
            else 
                DoScreenFadeOut(1)
            end
        end
    end)
end

local function disableKeys()
    disableKeysTemporary = true
    Citizen.CreateThread(function()
        while disableKeysTemporary do
            Citizen.Wait(0)
            local controls = { 24, 25, 77, 323, 20, 34, 29, 20, 26, 30, 46, 47, 74, 74, 7, 244, 199, 44, 45, 33, 303, 0, 32, 33, 35, 77, 246, 20, 48, 49, 75, 144, 145, 185, 251 }
            for _, control in ipairs(controls) do
                DisableControlAction(0, control, true)
            end
        end
    end)
end

local function checkTrunkOpen(vehicle)
    local playerPedId = cache.ped
    local doorAngle = GetVehicleDoorAngleRatio(vehicle, 5)
    if doorAngle >= 0.9 then
        if not IsEntityVisible(playerPedId) and not Config.showPlayerInTrunk then
            SetEntityVisible(playerPedId, true, false)
        end
    else
        if IsEntityVisible(playerPedId) and not Config.showPlayerInTrunk then
            SetEntityVisible(playerPedId, false, false)
        end
    end
end

local function startCheckTrunkOpenLoop()
    Citizen.CreateThread(function ()
        while inTrunk do
            Citizen.Wait(0)
            local vehicle = GetEntityAttachedTo(cache.ped)
            if vehicle and DoesEntityExist(vehicle) then
                checkTrunkOpen(vehicle)
            end
        end
    end)
end

--------------------------------------------
-- Trunk Functions
--------------------------------------------
local function hide(playerPedId, data)
    local isEmpty = lib.callback.await('bc_carryandhideintrunk:checkEmptyTrunk', 200, NetworkGetNetworkIdFromEntity(data.entity))
    if not isEmpty then
        return lib.notify({
            title = locale('trunk_occupied_notify_title'),
            description = locale('trunk_occupied_notify_msg'),
            type = 'error'
        })
    end

    TriggerServerEvent("bc_carryandhideintrunk:addPlayerToTrunkListing", NetworkGetNetworkIdFromEntity(data.entity))
    disableKeys()
    if Config.allowBlackout then
        disableCamera(data.entity)
    end
    SetCarBootOpen(data.entity)
    SetEntityCollision(playerPedId, false, false)
    Citizen.Wait(350)
    AttachEntityToEntity(playerPedId, data.entity, -1, 0.0, -1.8, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
    
    RequestAnimDict("timetable@floyd@cryingonbed@base")
    while not HasAnimDictLoaded("timetable@floyd@cryingonbed@base") do
        Citizen.Wait(0)
    end

    TaskPlayAnim(playerPedId, 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(50)

    inTrunk = true
    Citizen.Wait(1500)
    SetVehicleDoorShut(data.entity, 5, false)
    startCheckTrunkOpenLoop()
    Citizen.Wait(250)
    if not Config.showPlayerInTrunk then
        SetEntityVisible(playerPedId, false, 0)
    end
    lib.showTextUI(locale('leave_trunk_textui'))
end

local function leaveTrunk(playerPedId, data)
    disableKeysTemporary = false
    disableCameraTemp = false
    TriggerServerEvent("bc_carryandhideintrunk:removeMeFromTrunkListing", NetworkGetNetworkIdFromEntity(data.entity))
    SetCarBootOpen(data.entity)
    SetEntityCollision(playerPedId, true, true)
    Citizen.Wait(750)
    inTrunk = false
    DetachEntity(playerPedId, true, true)
    ClearPedTasks(playerPedId)
    local behindPos = GetOffsetFromEntityInWorldCoords(data.entity, 0.0, -3.0, 0.0)
    SetEntityCoords(playerPedId, behindPos.x, behindPos.y, behindPos.z, true, true, true, false)
    Citizen.Wait(250)
    SetVehicleDoorShut(data.entity, 5, false)
    Citizen.Wait(250)
    if not Config.showPlayerInTrunk then
        SetEntityVisible(playerPedId, true, 0)
    end
    lib.hideTextUI()
    DoScreenFadeIn(1)
end

--------------------------------------------
-- Carry Functions
--------------------------------------------
local function carryPlayer(data)
    if not data.entity then
        print("carryPlayer: data.entity is nil")
        return
    end

    if IsPedInAnyVehicle(data.entity, false) then
        return lib.notify({
            title = locale("target_in_veh_notify_title"),
            description = locale("target_in_veh_notify_msg"),
            type = "error",
        })
    end

    carrying = true
    carryingEntity = data.entity

    RequestAnimDict("missfinale_c2mcs_1")
    while not HasAnimDictLoaded("missfinale_c2mcs_1") do
        Citizen.Wait(0)
    end

    TriggerServerEvent("bc_carryandhideintrunk:carry", GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity)))
    TaskPlayAnim(cache.ped, "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 8.0, -8.0, 100000, 49, 0, false, false, false)
    lib.showTextUI(locale('stop_carry_textui'))
end

local function hidePlayer(data)
    local isEmpty = lib.callback.await('bc_carryandhideintrunk:checkEmptyTrunk', 200, NetworkGetNetworkIdFromEntity(data.entity))
    if not isEmpty then
        return lib.notify({
            title = locale('trunk_occupied_notify_title'),
            description = locale('trunk_occupied_notify_msg'),
            type = 'error'
        })
    end

    putSomebodyInTrunk = true
    lib.hideTextUI()
    ClearPedTasks(cache.ped)
    TriggerServerEvent("bc_carryandhideintrunk:hidePlayer", GetPlayerServerId(NetworkGetPlayerIndexFromPed(carryingEntity)), NetworkGetNetworkIdFromEntity(data.entity))
end

local function removePlayerFromTrunk(data)
    TriggerServerEvent("bc_carryandhideintrunk:stopCarrying", GetPlayerServerId(NetworkGetPlayerIndexFromPed(carryingEntity)), NetworkGetNetworkIdFromEntity(data.entity))
    ClearPedSecondaryTask(cache.ped)
    carrying = false
    putSomebodyInTrunk = false
    lib.hideTextUI()
end

--------------------------------------------
-- Network Events
--------------------------------------------
RegisterNetEvent("bc_carryandhideintrunk:carry", function(carrierId)
    beingCarried = true
    disableKeys()

    RequestAnimDict("nm")
    while not HasAnimDictLoaded("nm") do
        Citizen.Wait(0)
    end

    local playerPedId = cache.ped
    local carrier = GetPlayerPed(GetPlayerFromServerId(carrierId))
    if not carrier then
        print("Carrier not found")
        return
    end

    TaskPlayAnim(playerPedId, "nm", "firemans_carry", 8.0, -8.0, 100000, 33, 0, false, false, false)
    AttachEntityToEntity(playerPedId, carrier, 0, 0.26, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
end)

RegisterNetEvent("bc_carryandhideintrunk:stopCarrying", function(networkTargetVehicleId)
    beingCarried = false
    disableKeysTemporary = false
    disableCameraTemp = false
    
    local playerPedId = cache.ped

    if putInSomeoneTrunk and networkTargetVehicleId then
        local vehicle = NetworkGetEntityFromNetworkId(networkTargetVehicleId)
        if not vehicle then
            print("Vehicle not found")
        else
            local behindPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.0, 0.0)
            SetEntityCoords(playerPedId, behindPos.x, behindPos.y, behindPos.z, true, true, true, false)
            DoScreenFadeIn(1)
        end
    end

    putInSomeoneTrunk = false
    SetEntityVisible(playerPedId, true, false)
    DetachEntity(playerPedId, true, false)
    ClearPedTasks(playerPedId)
end)

RegisterNetEvent("bc_carryandhideintrunk:hidePlayer", function(vehicleId)
    local playerPedId = cache.ped
    local vehicle = NetworkGetEntityFromNetworkId(vehicleId)
    if not vehicle then
        print("Vehicle entity not found")
        return
    end

    putInSomeoneTrunk = true
    disableKeys()

    if Config.allowBlackout then 
        disableCamera(vehicle)
    end

    DetachEntity(playerPedId, true, false)
    ClearPedSecondaryTask(playerPedId)
    SetCarBootOpen(vehicle)
    SetEntityCollision(playerPedId, false, false)
    Citizen.Wait(350)
    
    AttachEntityToEntity(playerPedId, vehicle, -1, 0.0, -1.8, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
    RequestAnimDict("timetable@floyd@cryingonbed@base")
    while not HasAnimDictLoaded("timetable@floyd@cryingonbed@base") do
        Citizen.Wait(0)
    end
    TaskPlayAnim(playerPedId, 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(50)
    Citizen.Wait(1500)
    SetVehicleDoorShut(vehicle, 5, false)
    Citizen.Wait(250)
    if not Config.showPlayerInTrunk then
        SetEntityVisible(playerPedId, false, 0)
    end
end)

--------------------------------------------
-- Command for Debugging / Detaching
--------------------------------------------
RegisterCommand("detach", function ()
    DetachEntity(cache.ped, true, false)
    ClearPedSecondaryTask(cache.ped)
end, false)

--------------------------------------------
-- Command Option (if enabled)
--------------------------------------------
if Config.allowCarryAsCommand then
    RegisterCommand('carry', function()
        local pedCoords = GetEntityCoords(cache.ped)
        local ped, entity, coords = lib.getClosestPlayer(pedCoords, 5.0, false)
        local data = { entity = entity }
        
        if beingCarried then
            return
        end
        if not carrying then
            carryPlayer(data)
            return
        end
        
        TriggerServerEvent("bc_carryandhideintrunk:stopCarrying", GetPlayerServerId(NetworkGetPlayerIndexFromPed(carryingEntity)))
        ClearPedSecondaryTask(cache.ped)
        carrying = false
        lib.hideTextUI()
    end)
end

--------------------------------------------
-- New Keybind: Cancel Carry (Carried Player)
--------------------------------------------
lib.addKeybind({
    name = 'cancelcarry',
    description = locale('cancel_carry_keybind_description'), -- e.g., "Cancel Carry"
    defaultKey = "X",  -- Carried player uses X to cancel
    onPressed = function(self)
        -- Check if the player's ped is dead
        if IsEntityDead(cache.ped) then
            QBCore.Functions.Notify("You are dead and cannot cancel carry.", "error")
            return
        end

        if beingCarried then
            TriggerServerEvent("bc_carryandhideintrunk:stopCarrying", GetPlayerServerId(PlayerId()), nil)
            ClearPedTasks(cache.ped)
            beingCarried = false
            lib.hideTextUI()
        end
    end,
})


--------------------------------------------
-- New Keybind: Cancel Carry (Carrier)
--------------------------------------------
lib.addKeybind({
    name = 'stopcarry',
    description = locale('stop_carry_keybind_description'), -- e.g., "Stop Carrying"
    defaultKey = Config.stopCarryKeybind,  -- Should be "G" as per your config
    onPressed = function(self)
        print("[bc_carryandhideintrunk] stopcarry key pressed.")
        if not carrying then 
            print("[bc_carryandhideintrunk] Not carrying anyone; aborting stopcarry.")
            return 
        end
        if putSomebodyInTrunk then 
            print("[bc_carryandhideintrunk] Cannot stop carry because putSomebodyInTrunk is true.")
            return 
        end
        if not carryingEntity then
            print("[bc_carryandhideintrunk] carryingEntity is nil; aborting stopcarry.")
            return 
        end
        
        local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(carryingEntity))
        print("[bc_carryandhideintrunk] Triggering stopCarrying for targetServerId: " .. tostring(targetServerId))
        
        -- Trigger the server event to stop carrying
        TriggerServerEvent("bc_carryandhideintrunk:stopCarrying", targetServerId)
        
        -- Clean up local state for the carrier
        ClearPedSecondaryTask(cache.ped)
        carrying = false
        lib.hideTextUI()
    end,
})

--------------------------------------------
-- New Keybind: Leave Trunk (Player in Trunk) with ox_lib Escape Minigame
--------------------------------------------
lib.addKeybind({
    name = 'leavetrunk',
    description = locale('leave_trunk_keybind_description'), -- e.g., "Leave Trunk"
    defaultKey = Config.leaveTrunkKeybind,  -- Should be "E" as per your config
    onPressed = function(self)
        print("[bc_carryandhideintrunk] leavetrunk key pressed.")
        local ped = cache.ped
        -- Check if the player is dead; if so, they cannot attempt to escape.
        if IsEntityDead(ped) then 
            QBCore.Functions.Notify("You are dead and cannot escape the trunk.", "error")
            return 
        end

        if not inTrunk then 
            print("[bc_carryandhideintrunk] Not in trunk; aborting leavetrunk.")
            return 
        end

        local veh = GetEntityAttachedTo(ped)
        if not veh or not DoesEntityExist(veh) then
            veh = lib.getClosestVehicle(GetEntityCoords(ped), 3.0, true)
        end

        if not veh or not DoesEntityExist(veh) then 
            print("[bc_carryandhideintrunk] No vehicle found for trunk leaving.")
            return 
        end

        -- Use ox_lib's taskBar (minigame) to simulate an escape attempt.
        local finished = exports.ox_lib:taskBar({
            duration = 5000,               -- Duration of the minigame (in milliseconds)
            label = "Escaping trunk...",   -- Label shown during the minigame
            useWhileDead = false,          -- Ensure the minigame cannot be used while dead
            canCancel = true,              -- Allow the player to cancel the task
            disable = {
                car = true,
                move = true,
                combat = true,
            },
        })

        if finished == 100 then
            -- If the taskBar finished successfully (returns 100), proceed with trunk escape.
            local data = { entity = veh }
            leaveTrunk(ped, data)
        else
            QBCore.Functions.Notify("Escape attempt failed.", "error")
        end
    end,
})


--------------------------------------------
-- ox_target / qb-target Integration
--------------------------------------------
if Config.enableTargetCarry then
    if Config.targetScript == "ox" then
        -- For picking up (carry) a player:
        exports["ox_target"]:addGlobalPlayer({
            name = 'ox_target:carry',
            icon = 'fa-solid fa-car-rear',
            label = locale('target_carry_player'),
            -- CONFIG: Only allow interaction if the distance is less than Config.carryDistance
            canInteract = function(entity, distance, coords, name, boneId)
                return (distance < Config.carryDistance)
            end,
            onSelect = function(data)
                carryPlayer(data)
            end
        })

        exports["ox_target"]:addGlobalVehicle({
            {
                name = 'ox_target:trunk:hide',
                icon = 'fa-solid fa-car-rear',
                label = locale('target_remove_from_trunk'),
                bones = 'boot',
                canInteract = function(entity, distance, coords, name, boneId)
                    if inTrunk or not carryingEntity then return end
                    if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                    -- CONFIG: Use trunkDistance for trunk interactions.
                    local playerCoords = GetEntityCoords(cache.ped)
                    local targetBonePos = GetEntityBonePosition_2(entity, boneId)
                    return #(playerCoords - targetBonePos) < Config.trunkDistance
                end,
                onSelect = function(data)
                    removePlayerFromTrunk(data)
                end
            },
            {
                name = 'ox_target:trunk:hide',
                icon = 'fa-solid fa-car-rear',
                label = locale('target_put_person_in_trunk'),
                bones = 'boot',
                canInteract = function(entity, distance, coords, name, boneId)
                    if inTrunk or not carrying then return end
                    if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                    local playerCoords = GetEntityCoords(cache.ped)
                    local targetBonePos = GetEntityBonePosition_2(entity, boneId)
                    return #(playerCoords - targetBonePos) < Config.trunkDistance
                end,
                onSelect = function(data)
                    hidePlayer(data)
                end
            },
            {
                name = 'ox_target:trunk:hide',
                icon = 'fa-solid fa-car-rear',
                label = locale('target_hide_in_trunk'),
                bones = 'boot',
                canInteract = function(entity, distance, coords, name, boneId)
                    if inTrunk or carrying or beingCarried or putInSomeoneTrunk then return end
                    if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                    local playerCoords = GetEntityCoords(cache.ped)
                    local targetBonePos = GetEntityBonePosition_2(entity, boneId)
                    return #(playerCoords - targetBonePos) < Config.trunkDistance
                end,
                onSelect = function(data)
                    local playerPedId = cache.ped
                    hide(playerPedId, data)
                end
            },
            {
                name = 'ox_target:trunk:leave',
                icon = 'fa-solid fa-car-rear',
                label = locale('target_leave_trunk'),
                bones = 'boot',
                canInteract = function(entity, distance, coords, name, boneId)
                    if not inTrunk or carrying or putInSomeoneTrunk then return end
                    if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                    local playerCoords = GetEntityCoords(cache.ped)
                    local targetBonePos = GetEntityBonePosition_2(entity, boneId)
                    return #(playerCoords - targetBonePos) < Config.trunkDistance
                end,
                onSelect = function(data)
                    local playerPedId = cache.ped
                    leaveTrunk(playerPedId, data)
                end
            }
        })
    elseif Config.targetScript == "qb" then
        exports["qb-target"]:AddGlobalPlayer({
            options = {
                {
                    icon = 'fa-solid fa-car-rear',
                    label = locale('target_carry_player'),
                    canInteract = function(entity, distance, coords, name, boneId)
                        return (distance < Config.carryDistance)
                    end,
                    action = function(entity, distance, data)
                        carryPlayer({ entity = entity })
                    end
                }
            }
        })

        exports["qb-target"]:AddGlobalVehicle({
            distance = 2.5,
            options = {
                {
                    icon        = 'fa-solid fa-car-rear',
                    label       = locale('target_remove_from_trunk'),
                    canInteract = function(entity, distance, data)
                        if inTrunk or not carryingEntity then return end
                        if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                        local playerCoords = GetEntityCoords(cache.ped)
                        local boneId = GetEntityBoneIndexByName(entity, 'boot')
                        return #(playerCoords - GetEntityBonePosition_2(entity, boneId)) < Config.trunkDistance
                    end,
                    action      = function(entity, distance, data)
                        removePlayerFromTrunk({ entity = entity })
                    end
                },
                {
                    icon        = 'fa-solid fa-car-rear',
                    label       = locale('target_put_person_in_trunk'),
                    canInteract = function(entity, distance, data)
                        if inTrunk or not carrying then return end
                        if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                        local playerCoords = GetEntityCoords(cache.ped)
                        local boneId = GetEntityBoneIndexByName(entity, 'boot')
                        return #(playerCoords - GetEntityBonePosition_2(entity, boneId)) < Config.trunkDistance
                    end,
                    action      = function(entity, distance, data)
                        hidePlayer({ entity = entity })
                    end
                },
                {
                    icon        = 'fa-solid fa-car-rear',
                    label       = locale('target_hide_in_trunk'),
                    canInteract = function(entity, distance, data)
                        if inTrunk or carrying or beingCarried or putInSomeoneTrunk then return end
                        if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                        local playerCoords = GetEntityCoords(cache.ped)
                        local boneId = GetEntityBoneIndexByName(entity, 'boot')
                        return #(playerCoords - GetEntityBonePosition_2(entity, boneId)) < Config.trunkDistance
                    end,
                    action      = function(entity, distance, data)
                        local playerPedId = cache.ped
                        hide(playerPedId, { entity = entity })
                    end
                },
                {
                    icon        = 'fa-solid fa-car-rear',
                    label       = locale('target_leave_trunk'),
                    canInteract = function(entity, distance, data)
                        if not inTrunk or carrying or putInSomeoneTrunk then return end
                        if GetVehicleDoorLockStatus(entity) > 1 or IsVehicleDoorDamaged(entity, 5) then return end
                        local playerCoords = GetEntityCoords(cache.ped)
                        local boneId = GetEntityBoneIndexByName(entity, 'boot')
                        return #(playerCoords - GetWorldPositionOfEntityBone(entity, boneId)) < Config.trunkDistance
                    end,
                    action      = function(entity, distance, data)
                        local playerPedId = cache.ped
                        leaveTrunk(playerPedId, { entity = entity })
                    end
                },
            }
        })
    end
end

