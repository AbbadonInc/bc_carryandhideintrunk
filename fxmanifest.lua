fx_version "cerulean"

description "bc_carryandhideintrunk"
author "DingoDrama"
version '1.0.1'

use_experimental_fxv2_oal 'yes'
lua54 'yes'

game "gta5"

client_scripts {
    "config.lua",
    "client/main.lua"
}

shared_script '@ox_lib/init.lua'

server_scripts {
    "server/main.lua",
    "server/discord_webhook.lua"  -- Webhook functionality
}

files {
    'locales/*.json'
}

escrow_ignore {
    "**.*",
}
