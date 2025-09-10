-- CENTRAL PROCESSING  --------------------------------------------------------

register_level "toxin_refinery"
{
	name  = "Toxin Refinery",
	entry = "On @1 he waded into the Toxin Refinery.",
	welcome = "The stench of toxins chokes you briefly.",
	level = 4,

	OnRegister = function ()
		register_item "lever_toxinrefinery1"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY },

			good = "neutral",
			desc = "unlocks door",

			color_id = false,
			sound_id = "lever",

			OnUse = function(self,being)
				level:transmute( "ldoor", "floor", level.data.door1 )
				level:transmute( "wall", "floor", level.data.trap1 )
				level.data.darkness_end_time = core.game_time() + 150
				level.data.old_darkness = player.flags[ BF_DARKNESS ]
				player.flags[ BF_DARKNESS ]   = true
				player.vision = player.vision - level.data.vision_reduction
				ui.msg("Eastern door unlocked.")
				return true
			end,
		}

		register_item "lever_toxinrefinery2"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY },

			good = "neutral",
			desc = "unlocks door",

			color_id = false,
			sound_id = "lever",

			OnUse = function(self,being)
				level:transmute( "ldoor", "floor", level.data.door2 )
				ui.msg("Smoking area unlocked.")
				return true
			end,
		}

		register_item "lever_toxinrefinery3"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY },

			good = "neutral",
			desc = "unlocks door",

			color_id = false,
			sound_id = "lever",

			OnUse = function(self,being)
				level:transmute( "wall", "floor", level.data.door3 )
				level:transmute( "acid", "bridge", level.data.bridge )
				ui.msg("Shortcut unlocked.")
				return true
			end,
		}
	end,
	
	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "wall" )
		level.data.bridge               = area(36,11,36,14)
		level.data.room1                = area(16,3,26,3)
		level.data.room2                = area(12,5,16,8)
		level.data.room3                = area(15,13,22,19)
		level.data.room_entry           = area(31,11,41,16)
		level.data.room4                = area(50,4,67,10)
		level.data.room5                = area(54,13,61,16)
		level.data.room6                = area(71,16,74,19)
		level.data.hallway              = area()
		level.data.door1                = area(39,10,39,10)
		level.data.trap1                = area(13,5,13,6)
		level.data.door2                = area(66,15,66,16)
		level.data.door3                = area(36,10,36,10)
		level.data.secret1              = area(13,14,13,14)
		level.data.secret_trap          = area(32,2,40,3)
		level.data.secret2              = area(35,4,37,5)
		level.data.trap2_trigger        = area(35,5,37,5)
		level.data.trap2_wall1          = area(33,2,38,5)
		level.data.half_wall            = area(14,14,14,14)
		level.data.half_wall_coord      = coord(14,14)
		level.data.half_wall_trigger    = area(26,16,26,16)
		level.data.half_wall_trigger2   = area(10,14,10,14)
		level.data.half_wall_down_time  = 0
		level.data.darkness_end_time    = 0
		level.data.vision_reduction     = 6
		level.data.trap2_triggered      = false

		local translation = {
			['.'] = "floor",
			['#'] = { "wall",  flags = { LFPERMANENT } },
			['='] = "acid",
			['>'] = "stairs",
			['+'] = "door",

			['~'] = { "floor", item = "barrel" },
			['%'] = { "wall", flags = { LFBLOOD } },
			['L'] = { "ldoor",  flags = { LFPERMANENT } },

			['a'] = { "floor", item = "ammo" },
			['s'] = { "floor", item = "shell" },
			['r'] = { "floor", item = "rocket" },

			['G'] = { "floor", item = "garmor" },
			['P'] = { "floor", item = "mod_power" },
			['S'] = { "floor", item = "scglobe" },
			['D'] = { "floor", item = "phase" },
			['M'] = { "floor", item = "lmed" },
			['Z'] = { "floor", item = "umedarmor" },
			['m'] = { "floor", item = "smed" },
			['g'] = { "floor", item = "shglobe" },
			['-'] = { "floor", item = "shell" },

			['1'] = { "floor", item = "lever_toxinrefinery1" },
			['2'] = { "floor", item = "lever_toxinrefinery2" },
			['3'] = { "floor", item = "lever_toxinrefinery3" },

			['h'] = { "floor", being = "former" }, 
			['H'] = { "floor", being = core.bydiff{ "former","former","sergeant" } },
			['i'] = { "floor", being = core.bydiff{ "imp", "imp", "imp", "imp", "nimp" } },
			['d'] = { "floor", being = core.bydiff{ nil, nil, nil, "demon"} },
			['j'] = { "floor", being = core.bydiff{ nil, "imp", "imp", "nimp" } },
			['k'] = { "floor", being = core.bydiff{ "imp", "imp", "imp", "nimp"} },
			['O'] = { "floor", being = core.bydiff{ nil, "cacodemon","knight","baron" } },
		}

		local map = [=[
##############################.........+.Z##################################
##############....h......#####..#####..#.>##################################
##############.####.#.########.h#O.r#h.###############...s...=....##########
##########j#...#####.#########.i#r..#..##########..h....=====#.H..##########
##########k#..s###=.H.=##########%.%########.i.#.....#########....#.P.######
############d..###=.=.=##########%.%######..a=.+...............#..+...######
######3.####g1.###=.=.=##########%.%#####..===.#.....#########....#.>.######
######..=#########=...=##########%.%#....i.===.##.......=====#.H..##########
########=###########.################L###..===.#######.h.....=....##########
#========###########.h......#~.m#===#H.m##..==.#############################
#==....####################.#..##===##.~###..=.+..##########################
#==.M#.######.H......######.+..#=====#.a####...##.##........##.a.###########
#==s.......##..#####.######.#..##===##..#########.......h........###########
#==ai#.######.....##.######.#.H.....~.h.############.h......####L###########
#==....######..##2##........#.~.a..s....###########......a..####..S.#....###
#=======#####....G##.#############+#############################....=....###
#############..#####.############m.-#############################=#=#....###
#############h....a..###########################################........D###
]=]



		generator.place_tile( translation, map, 2, 2 )

		generator.set_permanence( area.FULL )
		level.data.kill_all  = false
		level.data.old_darkness = player.flags [ BF_DARKNESS ]
		level.data.darkness_end_time = 0

		local id = core.get_unknown_assembly( 0 )
		if id then
			local item = level:drop_item("schematic_0",coord(41,2))
			local ma   = mod_arrays[id]
			item.ammo  = ma.nid
			item.name  = ma.name.." schematics"
		end
		--The consequence of a roomier level is granular monster seeding
		if (DIFFICULTY >= DIFF_MEDIUM) then
			level:summon{ core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp"), 1, area = level.data.room2 }
			level:summon{ "former",      1, area = level.data.room1 }
			level:summon{ core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp"), 1, area = level.data.room3 }
			level:summon{ "imp", 1, area = level.data.room3 }
			level:summon{ "imp",         1, area = level.data.room_entry }
			level:summon{ "sergeant",    1, area = level.data.room_entry }
			level:summon{ "former",      1, area = level.data.secret_trap }
			level:summon{ core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp"), 1, area = level.data.secret_trap }
			level:summon{ "former",      1, area = level.data.room4 }
			level:summon{ core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp"), 2, area = level.data.room4 }
			level:summon{ "sergeant",    1, area = level.data.room4 }
			level:summon{ "imp",         1, area = level.data.room5 }
			if (DIFFICULTY >= DIFF_HARD) then
				level:summon{ "sergeant",    1, area = level.data.room1 }
				level:summon{ "former",      2, area = level.data.room4 }
				level:summon{ "sergeant",    1, area = level.data.room2 }
				level:summon{ "imp",         1, area = level.data.room5 }
				level:summon{ "sergeant",    1, area = level.data.room3 }
				level:summon{ "imp",         2, area = level.data.secret2 }
				level:summon{ "demon",       2, area = level.data.secret_trap }
				level:summon{ "imp",         2, area = level.data.room6 }
				if (DIFFICULTY >= DIFF_VERYHARD) then
					level:summon{ "demon",    2, area = level.data.room_entry }
					level:summon{ "demon",    2, area = level.data.secret_trap }
					level:summon{ core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp"), 2, area = level.data.secret_trap }
					level:summon{ "imp",      1, area = level.data.room2 }
					level:summon{ "sergeant", 1, area = level.data.room3 }
					level:summon{ "imp",      2, area = level.data.room4 }
					level:summon{ "former",   1, area = level.data.room6 }
    				level:summon{ "imp",      2, area = level.data.room6 }
				end
			end
		end

		level:player(36,18)
	end,

	OnKillAll = function ()
		if not level.data.kill_all then
			level.data.kill_all  = true
			ui.msg("The acrid smell begins to dissipate.")
			level.status = 4
		end
	end,

	OnEnterLevel = function ()
		level.status = 0
	end,

	OnTick = function ()
		if (level.data.half_wall_down_time > 0) and (core.game_time() >= level.data.half_wall_down_time) and not level.data.half_wall:contains(player.position) then
			local target = level:get_being(level.data.half_wall_coord)
			if target then
				if target:is_player() then return false end
				target:kill()
			end
			--Transmuting fails if the square is actually a bloodpool
			level.map[level.data.half_wall_coord] = "wall"
			level.data.half_wall_down_time = 0
		elseif level.data.half_wall_down_time == 0 and (level.data.half_wall_trigger:contains(player.position) or level.data.half_wall_trigger2:contains(player.position)) then
			level:transmute("wall", "floor", level.data.half_wall)
			level.data.half_wall_down_time = core.game_time() + 150
		end
		if level.data.darkness_end_time > 0 and level.data.darkness_end_time < core.game_time() then
			player.vision = player.vision + level.data.vision_reduction
			player.flags[ BF_DARKNESS ] = level.data.old_darkness
			level.data.darkness_end_time = 0
		end
		if level.data.half_wall:contains(player.position) then
			level:transmute( "wall", "floor", level.data.secret1)
		elseif not level.data.trap2_triggered and level.data.trap2_trigger:contains(player.position) then
			level:play_sound("door.open", player.position)
			level:transmute( "wall", "floor", level.data.trap2_wall1)
			level.data.trap2_triggered = true
		end
	end,

	OnExit = function ()
		if level.data.kill_all  then
			core.special_complete()
			ui.msg("You were a green machine.")
			player:add_history("He was the antidote.")
		else
			ui.msg("That'll set them back a bit.")
			player:add_history("He couldn't quite finish the job.")
		end
		if level.data.darkness_end_time > 0 then
			player.vision = player.vision + level.data.vision_reduction
			player.flags[ BF_DARKNESS ] = level.data.old_darkness
			level.data.darkness_end_time = 0
		end
	end,

}