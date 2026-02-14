fx_version 'cerulean'

game 'gta5'

author 'Nitro Nightly Grind (Clawdbot)'
description 'Active city maintenance side job: fix broken parking meters for cash (server-authoritative).'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

lua54 'yes'
