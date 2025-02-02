
-- Set your Discord webhook details here.
local discordWebhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"  -- Replace with your actual webhook URL
local botName = "Log Bot"  -- Customize your bot name here
local embedColor = 16711680  -- Example: 16711680 (red); adjust to your desired decimal color

local function sendDiscordLog(embeds)
    if discordWebhook == "" then
        print("[Discord Log] Webhook URL not set!")
        return
    end

    PerformHttpRequest(discordWebhook, function(err, text, headers)
        if err ~= 200 then
            print("[Discord Log] Error sending webhook: " .. tostring(err))
        end
    end, 'POST', json.encode({
        username = botName,
        embeds = embeds
    }), { ['Content-Type'] = 'application/json' })
end

-- Export the function so it can be used from other server scripts.
exports('sendDiscordLog', sendDiscordLog)
