fx_version 'cerulean'

game 'gta5'

author 'Atlas'
description 'Active scrap route loop: pickup -> process -> sell (coords + RPEmotes configurable)'
version '0.1.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

dependency 'qb-core'
