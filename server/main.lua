local playersInTrunk = {}

-- (Note: Remove or ignore these variables now since the webhook details are set in discord_webhook.lua)
-- local discordWebhook = ''  -- Set your Discord webhook URL here.
-- local botName = ''         -- Set your bot's username here.
-- local embedColor = ''      -- Provide a decimal color value (e.g., 16711680 for red).

lib.locale()

--------------------------------------------
-- Event: Start Carrying
--------------------------------------------
RegisterNetEvent("bc_carryandhideintrunk:carry", function(targetPlayerId)
    local src = source

    if targetPlayerId < 1 then 
        return 
    end

    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetPlayerId)
    local dist = #(GetEntityCoords(targetPed) - GetEntityCoords(srcPed))
    if dist > 10 then 
        DropPlayer(src, 'Exploit')
        return 
    end

    local embeds = {
        {
            ["color"] = 16711680,  -- You can change this or manage it in discord_webhook.lua
            ["title"] = locale('webhook_start_carry_title'),
            ["description"] = locale('webhook_start_carry_msg'),
            ["fields"] = {
                {
                    ["name"] = locale('webhook_lifter_name_and_id'),
                    ["value"] = GetPlayerName(src) .. ' **ID:** ' .. src,
                    ["inline"] = true,
                },
                {
                    ["name"] = locale('webhook_lifted_name_and_id'),
                    ["value"] = GetPlayerName(targetPlayerId) .. ' **ID:** ' .. targetPlayerId,
                    ["inline"] = true,
                },
                {
                    ["name"] = locale('webhook_distance_between_lifter_and_lifted'),
                    ["value"] = tostring(dist),
                    ["inline"] = true,
                },
            },
            ["footer"] = {
                ["text"] = os.date('%d. %m. %Y  o %H:%M', os.time()),
            },
        }
    }

    -- Use the exported function from discord_webhook.lua instead of PerformHttpRequest directly.
    exports['bc_carryandhideintrunk']:sendDiscordLog(embeds)

    TriggerClientEvent("bc_carryandhideintrunk:carry", targetPlayerId, src)
end)

--------------------------------------------
-- Event: Stop Carrying
--------------------------------------------
RegisterNetEvent("bc_carryandhideintrunk:stopCarrying", function(targetPlayerId, networkTargetVehicleId)
    local src = source

    local embeds = {
        {
            ["color"] = 16711680,  -- Example color; adjust as needed.
            ["title"] = locale('webhook_stop_carry_title'),
            ["description"] = locale('webhook_stop_carry_msg'),
            ["fields"] = {
                {
                    ["name"] = locale('webhook_lifter_name_and_id'),
                    ["value"] = GetPlayerName(src) .. ' **ID:** ' .. src,
                    ["inline"] = true,
                },
                {
                    ["name"] = locale('webhook_lifted_name_and_id'),
                    ["value"] = GetPlayerName(targetPlayerId) .. ' **ID:** ' .. targetPlayerId,
                    ["inline"] = true,
                },
            },
            ["footer"] = {
                ["text"] = os.date('%d. %m. %Y  o %H:%M', os.time()),
            },
        }
    }

    exports['bc_carryandhideintrunk']:sendDiscordLog(embeds)
    
    if playersInTrunk[targetPlayerId] then
        playersInTrunk[targetPlayerId] = nil
    end

    TriggerClientEvent("bc_carryandhideintrunk:stopCarrying", targetPlayerId, networkTargetVehicleId)
end)

--------------------------------------------
-- Event: Hide Player in Trunk
--------------------------------------------
RegisterNetEvent("bc_carryandhideintrunk:hidePlayer", function(targetPlayerId, networkTargetVehicleId)
    local src = source

    if targetPlayerId < 1 then 
        return 
    end

    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetPlayerId)
    local dist = #(GetEntityCoords(targetPed) - GetEntityCoords(srcPed))
    if dist > 10 then 
        DropPlayer(src, 'Exploit')
        return 
    end

    local embeds = {
        {
            ["color"] = 16711680,  -- Example embed color.
            ["title"] = locale('webhook_hide_in_trunk_title'),
            ["description"] = locale('webhook_hide_in_trunk_msg'),
            ["fields"] = {
                {
                    ["name"] = locale('webhook_hide_lifter'),
                    ["value"] = GetPlayerName(src) .. ' **ID:** ' .. src,
                    ["inline"] = true,
                },
                {
                    ["name"] = locale('webhook_hide_lifted'),
                    ["value"] = GetPlayerName(targetPlayerId) .. ' **ID:** ' .. targetPlayerId,
                    ["inline"] = true,
                },
                {
                    ["name"] = locale('webhook_hide_vehicle'),
                    ["value"] = tostring(networkTargetVehicleId),
                    ["inline"] = true,
                },
            },
            ["footer"] = {
                ["text"] = os.date('%d. %m. %Y  o %H:%M', os.time()),
            },
        }
    }

    exports['bc_carryandhideintrunk']:sendDiscordLog(embeds)
    
    playersInTrunk[targetPlayerId] = true
    TriggerClientEvent("bc_carryandhideintrunk:hidePlayer", targetPlayerId, networkTargetVehicleId)
end)

--------------------------------------------
-- Event: Add Player to Trunk Listing
--------------------------------------------
RegisterNetEvent("bc_carryandhideintrunk:addPlayerToTrunkListing", function(networkTargetVehicleId)
    if playersInTrunk[networkTargetVehicleId] then return end
    playersInTrunk[networkTargetVehicleId] = true
end)

--------------------------------------------
-- Event: Remove Player from Trunk Listing
--------------------------------------------
RegisterNetEvent("bc_carryandhideintrunk:removeMeFromTrunkListing", function(networkTargetVehicleId)
    local src = source

    if not playersInTrunk[networkTargetVehicleId] then return end
    playersInTrunk[networkTargetVehicleId] = nil
end)

--------------------------------------------
-- Callback: Check if the trunk is empty
--------------------------------------------
lib.callback.register('bc_carryandhideintrunk:checkEmptyTrunk', function(source, networkTargetVehicleId)
    return not playersInTrunk[networkTargetVehicleId]
end)

--------------------------------------------
-- Cleanup on player drop
--------------------------------------------
AddEventHandler("playerDropped", function ()
    local src = source
    if playersInTrunk[src] then
        playersInTrunk[src] = nil
    end
end)

--------------------------------------------
-- Version check for the script
--------------------------------------------
lib.versionCheck('BCScripts/bc_carryandhideintrunk')
