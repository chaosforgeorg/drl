-- MILITARY BASE --------------------------------------------------------

register_level "military_base"
{
	name  = "Military Base",
	entry = "On @1 he marched into the Military Base.",
	welcome = "You enter the Military Base. Arriving here again sure takes you back!",
	level = 7,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "rwall" )

		local mod1,mod2 = generator.roll_pair{"mod_power","mod_agility","mod_bulk","mod_tech"}

		local translation = {
			['.'] = "floor",
			[','] = { "floor", flags = { LFBLOOD } },
			['#'] = { "wall", flags = { LFPERMANENT } },
			['+'] = { "door", flags = { LFPERMANENT } },
			['L'] = { "ldoor", flags = { LFPERMANENT } },
			['%'] = "crate",
			['@'] = "ycrate",
			['$'] = "crate_ammo",
			['&'] = "crate_armor",
			['>'] = "stairs",
			['h'] = { "floor", being = "former" },
			['g'] = { "floor", being = "sergeant" },
			['j'] = { "floor", being = "captain" },
			['H'] = { "floor", being = core.ifdiff( 4, "eformer", "former" ) },
			['G'] = { "floor", being = core.bydiff{ "sergeant", "sergeant", "eformer", "esergeant" } },
			['J'] = { "floor", being = core.bydiff{ "captain", "eformer", "esergeant", "ecaptain", "ecommando" } },
			['M'] = { "floor", being = core.bydiff{ "commando", "esergeant", "ecaptain", "ecommando" } },
			['!'] = { "floor", item = "lhglobe" },
			['"'] = { "floor", item = "epack" },
			[':'] = { "floor", item = "pmap" },
			['}'] = { "floor", item = "ashotgun" },
			['1'] = { "floor", item = mod1 },
			['2'] = { "floor", item = mod2 },

		}

		local map = [=[
##############################################################################
##....########.....j....########.....+.,..+...........&&................%%@@!#
#..............########....j.......,,+,,.,+...$$......&&%%.g.@@......&&h%%@@.#
#.##.....j.....########..........,,..+...,+,..$$.####...%%...@@..$$..&&####$$#
#..##.########.....j....########,....+...,+,.....####%%.h........$$.J..####$$#
##..#############################....#g..g#,...h.####%%..@@....@@....@@####..#
###.g#.........########.........#....#..,.#..&&..####....@@....@@....@@####..#
####.#.....##...H.,,..H..##.....#...h#,...#..&&.......h.%%..g...........%%...#
###..L..#..h...G.,,,,.J......#.1#....#.,..#........@@...%%@@.....G..%%..%%.&&#
##h..L..#..h....,,,,,,.....M.#.!#....#...,#%%..g...@@$$...@@....@@..%%.....&&#
##h..L..#..h....,,>,,,.......#.}#....#.,..#%%........$$.j.!%%...@@......H....#
###..L..#..h...G.,,,,.J......#.2#h...#.,..#....%%...@@...&&%%..%%....G.@@..$$#
####.#.....##...H.,,..H..##.....#....#,...#..@@%%...@@...&&....%%@@....@@..$$#
###.g#.........########.........#....#,...#..@@..h....g..####.G..@@...######+#
##..#############################....#h.,h#.......@@.....####@@.H...$$##!##,.#
#..##.....g....########....g........h#....#.j.....@@.%%..####@@.....$$#"M:#.J#
#.##..########..........########.....#++++#...$$.....%%..####...%%....##,##..#
#.....########..........########....##,,,,##..$$..&&..h....%%..H%%..&&#...J.,#
##........g....########....g.......##......##.....&&.......%%.......&&#..,...#
####################################........##################################
]=]
		generator.place_tile( translation, map, 1, 1 )

		--generator.set_permanence( area.FULL )

		level:player(38,19)
	end,

	OnKillAll = function ()
		level.status = 2
		ui.msg("They can all rest easy now...")
	end,

	OnTick = function ()
		local res = level.status
		if res == 0 and player.x < 6 and player.y > 7 and player.y < 14 then
			local y
			for _, y in ipairs { 9, 10, 11, 12 } do
				level.map[coord(6,y)] = "floor"
				level.map[coord(6,y)] = "door"
			end
			level.status = 1
		end
	end,

	OnEnterLevel = function ()
		level.status = 0
	end,

	OnExit = function ()
		local result = level.status
		if result < 2 then
			ui.msg("Too many memories to go destroying them all...")
			player:add_history("He left without a fuss.")
		else
			core.special_complete()
			ui.msg("Better to end their tortured bodies here and now.")
			player:add_history("He purified his fellow comrades.")
		end
	end,


}
