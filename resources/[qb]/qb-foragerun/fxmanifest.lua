fx_version 'cerulean'

game 'gta5'

author 'Nitro Nightly Grind (Clawdbot)'
description 'Active money-making foraging -> cleaning -> selling (server-validated, locked, rate-limited)'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

dependency 'qb-core'
