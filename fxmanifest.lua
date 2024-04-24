fx_version 'adamant'
game 'gta5'
lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
	'client/*.lua',
}

ui_page 'web/web.html'

files {
	'shared/**/*',
	'web/**/*',
}