fx_version 'cerulean'

game 'gta5'

author 'qb-nightly-grind'
description 'Active warehouse packing grind (pickup -> pack -> deliver) with server validation, busy lock, and rate limits.'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

lua54 'yes'
