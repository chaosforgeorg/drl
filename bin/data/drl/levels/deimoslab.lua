-- DEIMOS LAB -----------------------------------------------------------

register_level "deimos_lab"
{
	name  = "Deimos Lab",
	entry = "On @1 he entered Deimos Lab.",
	level = 9,
	welcome = "You arrive at the Deimos Lab entry area.",

	canGenerate = function ()
		return DIFFICULTY > 1
	end,

	OnRegister = function ()

		register_item "lever_deimoslab"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY, IF_FEATURENAME },

			good = "dangerous",
			desc = "opens the lab",

			color_id = false,
			sound_id = "lever",

			OnUse = function(self,being)
				if level.status > 5 then return true end
				level.status = level.status + 1
				if level.status == 2 then
					ui.msg("The walls rise!")
					level:transmute( "rwall", "acid" )
					level:transmute( "acid", "bridge", level.data.bridge )
					level:recalc_fluids()
				elseif level.status == 6 then
					ui.msg("The vault opens!")
					level:play_sound( "shambler.act", player.position, 100 )
					ui.msg("You hear a loud wail!")
					level:transmute( "gwall", "floor", level.data.vault1 )
					level:drop_being("shambler",coord(39,10))
					level:drop_being("shambler",coord(40,11))
					level:recalc_fluids()
				end
				return true
			end,

			OnDescribe = item.get_lever_description,
		}
	end,


	Create = function ()
		core.special_create()
		level:set_generator_style( 2 )
		level:fill( "wall" )
		level.data.vault1 = area(38,9,41,12)
		level.data.vault2 = area(37,10,42,11)
		level.data.bridge = area(47,10,51,11)

		local special = drl.get_special_item( player.name )
		if not special then 
			special = level:roll_item{ level = 15, type = ITEMTYPE_RANGED, reqs = { is_special = true } }
		end

		local mod1,mod2 = generator.roll_pair{"mod_power","mod_agility","mod_bulk","mod_tech"}
		local translation = {
			['.'] = "floor",
			[','] = { "floor", flags = { LFBLOOD } },
			['%'] = { "wall",  style = 1, },
			['#'] = "wall",
			['Z'] = { "rwall", flags = { LFPERMANENT } },
			['V'] = { "gwall", flags = { LFPERMANENT } },
			['+'] = "door",
			['>'] = "stairs",
			['='] = "acid",
			['-'] = "bridge",
			['&'] = { "floor", item = "lever_deimoslab" },
			['X'] = "crate_ammo",
			['Y'] = "crate_armor",

			['7'] = { "floor", item = { "teleport", target = coord(MAXX-1,5)       } },
			['8'] = { "floor", item = { "teleport", target = coord(MAXX-1,MAXY-4)  } },
			['9'] = { "floor", item = { "teleport", target = coord(8,10)  } },
			['0'] = { "floor", item = { "teleport", target = coord(8,11) } },


			['h'] = { "floor", being = core.bydiff{"former", "former", "sergeant", "captain"} },
			['H'] = { "floor", being = core.bydiff{"former", "sergeant", "sergeant", "commando"} },

			['G'] = { "floor", being = "captain" },
			['A'] = { "floor", being = core.ifdiff( 4, "revenant", "arachno" ) },

			['!'] = { "floor", item = "scglobe" },
			['U'] = { "floor", item = level:roll_item{ level = 15, type = ITEMTYPE_RANGED } },
			['I'] = { "floor", item = special },
			['O'] = { "floor", item = level:roll_item{ level = 15, type = ITEMTYPE_RANGED, unique_mod = 6 } },
			['P'] = { "floor", item = level:roll_item{ level = 15, type = ITEMTYPE_RANGED } },
			['{'] = { "floor", item = mod1 },
			['}'] = { "floor", item = mod2 },
			['5'] = { "floor", item = "pammo" },
			['6'] = { "floor", item = "pshell" },
			[']'] = { "floor", item = "garmor" },
			['['] = { "floor", item = "barmor" },
		}

		local map = [=[
.........................====########&.....h......######........#.XX.......9
........................====#########..............####.........#.XX.h......
.......................====##########..##########...##..........+.....YY....
......................====###==================###......YY..#####..H..YY....
.....................====###====================###...h.YY..#5{[############
.....................===###====ZZZZZZZZZZZZZZ====###........#...#===========
......%%+%%%.........===###===ZZ&..........&ZZ===####..XX...#...#===========
.....%%H...%%.h......===###===Z.AVVVVVVVVVVA.Z===####..XX...##++#==#######==
.....%.....7%........===###===Z..VVVVVVVVVV..Z===....G...........--+...UI#!=
.....%.....8%........===###===Z..VVVVVVVVVV..Z===....G...........--+...PO#!=
.....%%H...%%.h......===###===Z.AVVVVVVVVVVA.Z===####..YY...##++#==#######==
......%%+%%%.........===###===ZZ&..........&ZZ===####..YY...#...#===========
.....................===###====ZZZZZZZZZZZZZZ====###........#...#===========
.....................====###====================###...h.XX..#6}]############
......................====###==================###......XX..#####..H..XX....
.......................====##########..##########...##..........+.....XX....
.>......................====#########..............####.........#.YY.h......
.........................====########&.....h......######........#.YY.......0
]=]

		generator.place_tile( translation, map, 2, 2 )

		if DIFFICULTY > 3 then
			level:summon{ "cacodemon", 6 + DIFFICULTY, cell = "acid" }
		else
			level:summon{ "lostsoul", 10 + 2*DIFFICULTY, cell = "acid" }
		end

		level:player(3,3)
	end,

	OnKillAll = function ()
		if level.status == 6 then
			level.status = 7

			player:add_medal("armory1")
			if statistics.damage_on_level == 0 then
				player:add_medal("armory2")
				if player_data.count('player/medals/medal[@id="armory1"]') > 0 then
					player:remove_medal("armory1")
				end
			end

			level:transmute( "gwall", "floor", level.data.vault2 )
			ui.msg("The lab caches open.")

			local reward1,reward2 = generator.roll_pair{ "umod_sniper","umod_firestorm","umod_nano","umod_onyx","ucarmor" }
			local reward3         = table.random_pick{"mod_power","mod_agility","mod_bulk","mod_tech"}
			level:drop_item(reward3,coord(37,10), true, true, true)
			level:drop_item(reward2,coord(42,11), true, true, true)
			level:drop_item(reward1,coord(37,11), true, true, true)

			local id = core.get_unknown_assembly( 1 )
			if id then
				local item = level:drop_item("schematic_1",coord(42,10), true, true, true)
				local ma   = mod_arrays[id]
				item.ammo  = ma.nid
				item.name  = ma.name.." schematics"
			end
		end
	end,

	OnEnterLevel = function ()
		level.status = 0
	end,

	OnExit = function ()
		local result = level.status
			if player.nuketime > 1 then
			ui.msg("Cleansed with fire.")
			player:add_history( "He decided to nuke the forbidden Lab." )
		elseif result == 0 then
			ui.msg("Let it lie, that which is eternally dead...")
			player:add_history("He left the Deimos Lab without drawing too much attention.")
		elseif result < 6 then
			ui.msg("Better safe than sorry.")
			player:add_history("He fought hard, but decided the reward was not worth it.")
		elseif result == 6 then
			ui.msg("This is madness!")
			player:add_history("He fled the lab after unleashing a nightmare!")
		else
			core.special_complete()
			ui.msg("Gotta love the craft...")
			player:add_history("He destroyed the evil within and reaped the rewards!")
		end
	end,

}
