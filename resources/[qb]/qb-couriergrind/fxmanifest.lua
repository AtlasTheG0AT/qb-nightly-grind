fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'

game 'gta5'

name 'qb-couriergrind'
author 'qb-nightly-grind (Nitro nightly build)'
description 'Productive courier route grind: pick up packages, deliver to drop-offs, get paid.'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
}

dependency 'qb-core'
