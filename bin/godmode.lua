-- ----------------------------------------------------------------------
--  This is the DRL initialization file. Modify at your own risk :). 
--  If you mess up something overwrite with a new godmode.lua.
-- ----------------------------------------------------------------------

-- use F1 to toggle console
--   example commands:
--     player:exit(12) -- exit to level indexed 12
--     player:exit("the_valuts") -- exit to level id "the_valuts"
--     player.inv:add( "barmor") -- add item to inventory


-- code can be assigned to keys, as below (Keytable entries)
--   the default god keybindings are:
--     F2: regenerate level
--     F3: teleport to stairs
--     F4: teleport to next level
--     F5: toggle visibility of all cells
--     F6: give player some advanced stuff
--     F7: teleport to random location on level
--     F8: add 500 experience points
--     SHIFT+F8: kill all monsters on level
--     BACKSPACE: heal player to max HP

dofile "config.lua"

SoundEngine = "DEFAULT"

LockBreak        = false
LockClose        = false
SaveOnCrash      = false
ForceRaw         = true

Keytable = {}

-- God commands
Keytable["BACKSPACE"] = function() 
	ui.msg("Heal!")
	player.hp = player.hpmax 
end
Keytable["F2"] = function() 
	ui.msg("Regenerate!")
	generator.regenerate( true )
end
Keytable["F3"] = function() 
	ui.msg("Home!")
	player:phase("stairs")
end
Keytable["F4"] = function() 
	ui.msg("Next level!")
	player:exit()
end
Keytable["F5"] = function() 
	ui.msg("Visibility! "..player.x.."x"..player.y)
	for c in area.FULL() do
		local cell = cells[ level.map[ c ] ]
		if cell.flags[ CF_BLOCKMOVE ] or cell.flags[ CF_NOCHANGE ] then
			level.light[ c ][LFEXPLORED] = true
		end
	end
	level.flags[ LF_BEINGSVISIBLE ] = not level.flags[ LF_BEINGSVISIBLE ]
	level.flags[ LF_ITEMSVISIBLE  ] = not level.flags[ LF_ITEMSVISIBLE  ]
end
Keytable["F6"]        = function() 
	player.inv:clear()
	ui.msg("idkfa!")
	if rawget(_G,"jhc") then
		player.inv:add( "ashotgun" )
		player.inv:add( "prifle")
		player.inv:add( "glauncher")
		player.inv:add( "launcher")
		player.inv:add( "uni_void")
		player.inv:add( "uni_jackhammer")
		player.inv:add( "barmor")
		for i = 1,3 do
			player.inv:add( "rocket", { ammo = 10 } )
		end
		for i = 1,3 do
			player.inv:add( "ammo_40", { ammo = 15 } )
		end
	else
		player.inv:add( "ashotgun" )
		player.inv:add( "unbfg9000")
		player.inv:add( "uberetta")
		player.inv:add( "uberarmor")
		player.inv:add( "utrigun")
		player.inv:add( "urailgun")
		player.inv:add( "udragon")
		player.inv:add( "nuke" )
	end
	for i = 1,3 do
		player.inv:add( "cell", { ammo = 50 } )
	end
	for i = 1,2 do
		player.inv:add( "shell", { ammo = 50 } )
	end
end
Keytable["F7"] = function() 
	ui.msg("Teleport!")
	player:phase()
end

Keytable["F8"] = function() 
	ui.msg("+5000 Experience!")
	player:add_exp(5000)
end
Keytable["SHIFT+F8"] = function() 
	ui.msg("ARMAGEDDON!")
	local list = {}
	for b in level:beings() do
		if not b:is_player() then
			table.insert( list, b )
		end
	end
	for _,b in ipairs(list) do
		if b.__ptr then
			b:kill()
		end
	end
end 

Keytable["SHIFT+F2"] = function() 
	local function query( c )
		local cell = cells[ level:get_cell( c ) ]
		if not cell.flags[ CF_BLOCKMOVE ] then
			return true
		end
		if cell.flags[ CF_OPENABLE ] then 
			return true
		end
		return false
	end
	local function to( c )
		if not cells[ level:get_cell( c ) ].flags[ CF_NOCHANGE ] then
			level:set_cell( c, "water" )
		end
	end

	local c = level:find_coord( generator.styles[ level.style ].floor )

	generator.flood_fill( level, c, to, query )
end