fx_version 'cerulean'
game 'gta5'

author 'BrunelioScripts'
description 'Sistema de Props | QBCORE'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'oxmysql',
    --'es_extended'
}

server_export 'LoadPropsFromDatabase'

sql_files {
    'props.sql'
}
