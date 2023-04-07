fx_version 'cerulean'
game 'gta5'

description 'Qbx-radialmenu'
version '1.0.0'


shared_scripts {
    "@es_extended/imports.lua",
    'config.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

provide 'radialmenu'
lua54 'yes'
