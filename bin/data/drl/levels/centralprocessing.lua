-- CENTRAL PROCESSING  --------------------------------------------------------

register_level "central_processing"
{
	name  = "Central Processing",
	entry = "On @1 he trekked through Central Processing.",
	welcome = "You enter Central Processing. You shudder, thinking about the evil mastermind who planned this.",
	level = 4,

	OnRegister = function ()
		register_item "lever_centralprocessing1"
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
				level:transmute( "wall", "floor", level.data.trap11 )
				level:transmute( "wall", "floor", level.data.trap12 )
				level:transmute( "wall", "floor", level.data.trap13 )
				level:transmute( "wall", "floor", level.data.trap14 )
				level:play_sound( "door.open", level.data.door1_coord )

				ui.msg("North door unlocked.")
				return true
			end,
		}

		register_item "lever_centralprocessing2"
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
				level:play_sound( "door.open", level.data.door2_coord )
				ui.msg("Central area unlocked.")
				return true
			end,
		}

		register_item "lever_centralprocessing3"
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
				level:transmute( "ldoor", "floor", level.data.door3 )
				level:transmute( "wall", "floor", level.data.trap31 )
				level:transmute( "wall", "floor", level.data.trap32 )
				level:transmute( "wall", "floor", level.data.wall22 )
				level:play_sound( "door.open", level.data.door3_coord )
				ui.msg("Processing area unlocked.")
				return true
			end,
		}
	
		register_item "lever_centralprocessing4"
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
				level:transmute( "ldoor", "floor", level.data.door4 )
				level:play_sound( "door.open", level.data.door4_coord )
				ui.msg("East door unlocked.")
				return true
			end,
		}
	
		register_item "lever_centralprocessing5"
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
				level:transmute( "ldoor", "door", level.data.door5 )
				ui.msg("Exit unlocked.")
				return true
			end,
		}
	end,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "wall" )

		level.data.trap11         = area(5,15,5,16)
		level.data.trap12         = area(11,14,14,14)
		level.data.trap13         = area(7,18,8,18)
		level.data.trap14         = area(13,18,14,18)
		level.data.door1          = area(7,6,8,6)
		level.data.door1_coord    = coord(7,6)
		level.data.trap2          = area(11,3,11,4)
		level.data.trap21         = area(6,3,6,4)
		level.data.trapSA         = area(14,3,14,3)
		level.data.trapSA1        = area(15,3,15,3)
		level.data.trapSB         = area(4,3,4,3)
		level.data.trapSB1        = area(4,11,4,11)
		level.data.trapSB2        = area(3,3,3,3)
		level.data.door2          = area(19,11,19,11)
		level.data.door2_coord    = coord(19,11)
		level.data.trap31         = area(32,13,32,13)
		level.data.trap32         = area(34,11,34,11)
		level.data.door3          = area(29,11,29,11)
		level.data.door3_coord    = coord(29,11)
		level.data.wall22         = area(36,19,36,19)
		level.data.door4          = area(53,7,53,7)
		level.data.door4_coord    = coord(53,7)
		level.data.door5          = area(72,11,72,11)
		level.data.door5_coord    = coord(72,11)
		level.data.platform       = area(57,17,57,17)
		level.data.platform_coord = coord(57,17)
		level.data.trapSC         = area(57,16,57,16)
		level.data.trapSC1        = area(57,15,57,15)
		level.data.trap6          = area(64,8,64,8)
		level.data.trap6P         = area(52,6,52,8)
		level.data.trap61         = area(66,5,67,5)
		level.data.trap62         = area(73,5,74,5)
		level.data.trap63         = area(76,8,76,9)
		level.data.trap64         = area(74,11,75,11)
		level.data.trap65         = area(68,11,69,11)
		level.data.room1          = area(7,3,11,4)
		level.data.room2          = area(4,3,5,4)
		level.data.room3          = area(6,15,17,17)
		level.data.room3a         = area(3,15,4,16)
		level.data.room3b         = area(7,19,8,19)
		level.data.room3c         = area(13,19,14,19)
		level.data.room3d         = area(11,13,14,13)
		level.data.room4          = area(20,7,24,15)
		level.data.room5          = area(35,10,50,16)
		level.data.room6          = area(55,17,64,19)
		level.data.room7          = area(57,12,66,14)
		level.data.room8          = area(33,3,57,7)
		level.data.room9          = area(54,6,75,10)
		level.data.room9a         = area(66,2,67,4)
		level.data.room9b         = area(73,2,74,4)
		level.data.room9c         = area(77,8,77,9)
		level.data.room9d         = area(74,12,75,13)
		level.data.room9e         = area(68,12,69,14)
		level.data.roomExit       = area(72,15,74,19)
		level.data.platform_up    = false
		level.data.trap6_triggered = false
		level.data.trap6_expiry   = 0

		local translation = {
			['.'] = "floor",
			['#'] = { "wall",  flags = { LFPERMANENT } },
			['='] = "acid",
			['>'] = "stairs",
			['+'] = { "floor", item = "smed" },
			['g'] = { "floor", item = "lhglobe" },
			['-'] = { "floor", item = "lmed" },
			['~'] = { "floor", item = "barrel" },
			['L'] = { "ldoor",  flags = { LFPERMANENT } },
			['S'] = { "floor", item = "scglobe" },
			['E'] = { "floor", item = "epack" },
			['B'] = { "floor", item = "sboots" },
			['M'] = { "floor", item = "mod_agility"},
			['A'] = { "floor", item = "barmor"},
			['D'] = { "floor", item = "phase"},
			['V'] = { "floor", item = "uballisticarmor"},
			['r'] = { "floor", item = "rocket"},
			['a'] = { "floor", item = "ammo"},
			['s'] = { "floor", item = "shell"},

			['1'] = { "floor", item = "lever_centralprocessing1" },
			['2'] = { "floor", item = "lever_centralprocessing2" },
			['3'] = { "floor", item = "lever_centralprocessing3" },
			['4'] = { "floor", item = "lever_centralprocessing4" },
			['5'] = { "floor", item = "lever_centralprocessing5" },
			['6'] = { "floor", item = "level_centralprocessing6" },

			['h'] = { "floor", being = "former" },
			['H'] = { "floor", being = core.bydiff{ "former","sergeant" } },
			['i'] = { "floor", being = "imp" },
			['j'] = { "floor", being = core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp")},
			['k'] = { "floor", being = core.bydiff{ nil, "imp", "imp", "demon", "nimp" }},
			['O'] = { "floor", being = core.bydiff{ "cacodemon","cacodemon","knight","baron" } },
		}

		local map = [=[
################################################################..#####..###
=#h.#....2===#.################....................#############s.#####h.###
=#k.#.....===#.################.#####a..#####..==..#############..#####..###
=####.####===#g################.......#............#########################
=####LL##E===##################.#####...#####..==..#....................~.##
=####=.=##########.....########............i.......L.#####.####......s....##
=####=...~-#######.###.########.##################.#.......#5....i........#.
=####=.=#ai#######.#i#.#...#....####=.=######.####.#.#####.####.....~.....#H
=.#.s=.=##########.#.#.#...#.#####...a.h.#=.=#...#.#......................##
=A#......s.......L.......#.L.#+h#..#=.=#...s...#.#.###################L#####
###.a=.=##########.#.#.#...###.##.###.##.#=.=###.#...H.........s.#h.##.#..##
#####=.=#....#####.#.#.#...#####=.=#..##.##.##..3#......a.......4#..##.#a.##
######.###########.###.########......##=.=#.##...#......h........#..##.#####
#..#....~s...#ha##.....########.=.=#.....h..##.#######################...###
#.H#.........#.1####.##########.#.##.##=.=#.##.########S##############...###
####~...#~......####...........##....######....#r..j..###.....########.M.###
##################==========####################....Vh......O.########D..###
#####..####h.#####================#.......................r...########.>B###
]=]



		generator.place_tile( translation, map, 2, 2 )

		generator.set_permanence( area.FULL )
		level.data.kill_all  = false

		local id = core.get_unknown_assembly( 0 )
		if id then
			local item = level:drop_item("schematic_0",coord(63,18))
			local ma   = mod_arrays[id]
			item.ammo  = ma.nid
			item.name  = ma.name.." schematics"
		end

--R2-R1                    R9A R9B
--   |                     |   |
--   Entrance-R4---R8----R9....-R9C
--    |       |     |     | | |
--    | R3D   |-R5 R7   R9E | R9D
--    | |     |     |       Exit
--R3A-R3...   \----R6
--    |   |
--    R3B R3C

		level:summon{core.ifdiff(DIFF_VERYHARD, "nimp", "imp"), 1, area = level.data.room8}
		if DIFFICULTY >= DIFF_MEDIUM then
			level:summon{"sergeant", 1, area = level.data.room3b}
			level:summon{"former",   1, area = level.data.room3d}
			level:summon{"imp",      1, area = level.data.room4}
			level:summon{"former",   1, area = level.data.room5}
			level:summon{"imp",      1, area = level.data.room5}
			level:summon{"former",   1, area = level.data.room6}
			level:summon{"former",   1, area = level.data.room7}
			level:summon{core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp"), 1, area = level.data.room9a}
			level:summon{"demon",  1, area = level.data.roomExit}
			if DIFFICULTY >= DIFF_HARD then
				level:summon{"demon",    1, area = level.data.room3b}
				level:summon{"demon",    1, area = level.data.room4}
				level:summon{"former",   1, area = level.data.room5}
				level:summon{"demon",    1, area = level.data.room5}
				level:summon{"sergeant", 1, area = level.data.room5}
				level:summon{"sergeant", 1, area = level.data.room6}
				level:summon{core.ifdiff(DIFF_NIGHTMARE, "nimp", "imp"), 1, area = level.data.room9a}
				level:summon{core.ifdiff(DIFF_VERYHARD, "nimp", "imp"), 1, area = level.data.room9}
				level:summon{"former",   2, area = level.data.room9}
				level:summon{"former",   1, area = level.data.room9d}
				level:summon{"demon",    2, area = level.data.roomExit}
				if DIFFICULTY >= DIFF_VERYHARD then
					level:summon{"imp",      1, area = level.data.room1}
					level:summon{"demon",    1, area = level.data.room3}
					level:summon{"demon",    1, area = level.data.room3}
					level:summon{"demon",    2, area = level.data.room3d}
					level:summon{"demon",    1, area = level.data.room5}
					level:summon{"sergeant", 1, area = level.data.room9}
					level:summon{"demon",    1, area = level.data.room9b}
					level:summon{"demon",    1, area = level.data.room9d}
					level:summon{"demon",    1, area = level.data.room9e}
					level:summon{core.ifdiff(DIFF_NIGHTMARE, "ndemon", "demon"), 2, area = level.data.roomExit}
				end

			end
		end

		level:player(5,11)
	end,

	OnKillAll = function ()
		if not level.data.kill_all then
			level.data.kill_all  = true
			ui.msg("The machinery falls silent.")
			level.status = 4
		end
	end,

	OnEnterLevel = function ()
		level.status = 0
	end,

	OnTick = function ()
		local platform_up = (core.game_time() % 500 > 249)
		if not level.data.platform:contains(player.position) then
			if not level.data.platform_up and platform_up then
				level:transmute( "wall", "floor", level.data.platform)
				level:play_sound( "door.open", level.data.platform_coord )
			elseif level.data.platform_up and not platform_up then
				--Transmute fails if the wall is actually a bloodpool
				--Actually, this 'wall' is a platform, so there is no need to kill the monster. However it will look unusual sitting atop a wall!
				--If killing it is the preferred option, contrary to the intent of the square, refer to toxinrefinery's code.
				level.map[level.data.platform_coord] = "wall"
			end
			level.data.platform_up = platform_up
		end

		if level.data.trap2:contains(player.position) then
			level:transmute( "wall", "floor", level.data.trap21)
		elseif level.data.trapSA:contains(player.position) then
			level:transmute( "wall", "floor", level.data.trapSA1)
		elseif level.data.trapSB:contains(player.position) then
			level:transmute( "wall", "floor", level.data.trapSB1)
			level:transmute( "wall", "floor", level.data.trapSB2)
		elseif level.data.trapSC:contains(player.position) then
			level:transmute( "wall", "floor", level.data.trapSC1)
		elseif level.data.trap6:contains(player.position) and not level.data.trap6_triggered then
			--This avoids the transmute situation if the floor is actually a bloodpool
			for iCoord in level.data.trap6P.coords(level.data.trap6P) do
				level.map[iCoord] = "gwall"
			end
			level.data.trap6_expiry = core.game_time() + 300
			level.data.trap6_triggered = true
			level:play_sound("door.close", level.data.door4_coord)
			level:transmute( "wall", "floor", level.data.trap61)
			level:transmute( "wall", "floor", level.data.trap62)
			level:transmute( "wall", "floor", level.data.trap63)
			level:transmute( "wall", "floor", level.data.trap64)
			level:transmute( "wall", "floor", level.data.trap65)
		end
		if level.data.trap6_expiry > 0 and core.game_time() > level.data.trap6_expiry then
			level:transmute( "gwall", "floor", level.data.trap6P )
			level.data.trap6_expiry = 0
			level:play_sound("door.open", level.data.door4_coord)
		end
	end,

	OnExit = function ()
		if level.data.kill_all  then
			core.special_complete()
			ui.msg("No meat left to process.")
			player:add_history("Nothing stood in his way.")
		else
			ui.msg("Just too many to count.")
			player:add_history("He couldn't quite finish the job.")
		end
	end,


}