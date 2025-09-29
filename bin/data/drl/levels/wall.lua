-- THE WALL -------------------------------------------------------------

register_level "the_wall"
{
	name  = "The Wall",
	entry = "On @1 he witnessed the Wall.",
	welcome = "You arrive at the Wall. You feel uneasy.",
	level = 11,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "wall" )

		local translation = {
			['.'] = "floor",
			['#'] = "wall",
			['X'] = { "wall", flags = { LFMARKER1 }},
			['%'] = { "wall", flags = { LFBLOOD } },
			['*'] = "bloodpool",
			[','] = { "floor", flags = { LFBLOOD } },
			['+'] = "door",
			['>'] = "stairs",

			['^'] = { "floor", item = "backpack" },
			['!'] = { "floor", item = "umbazooka" },
			['|'] = { "floor", item = "rocket" },

			['A'] = { "floor", being = core.ifdiff( 4, "arch" ) },
		}

		local map = [[
#########################%%######%%#########################################
#########.....,......,,***%###X##%*,,......................................#
##..|.##........,.....,,**%#XX#XX%*,.,.....................................#
#.|....#.A,.......,....,,,%X#####X,,.......................................#
#...|..#.....,........,,,*X###X##%*,.,.....................................#
#.|....+.........,...,.,**%###X##%**,,,....................................#
#...|..#...,...........,**%##X#X#%**,,.....................................#
#.|....#......,....,..,,,*%##X##XX*,.,.....................................#
#^!.|..#...............,,,X##X###%*,,......................................#
#......#.,...,....,..,.,,*%XX#####,,.,.....................................#
#...|..#..............,,,*%####XX%*,,,.....................................#
#.|....#.......,......,.,,##XX###X*,..,....................................#
#...|..+................,,%X##X##X,,.......................................#
#.|....#.A,.......,.....,,X##X##X%,,.,...........................>.........#
#...|..#........,....,.,,*%#X##X#%*,,,,....................................#
##....##..,...........,,**%##XX##%**,,,,...................................#
#########.....,....,.,,***%######%*,,......................................#
########################%%%######%%%########################################
]]
		generator.place_tile( translation, map, 2, 2 )

		local left    = area( 12, 4, 27, 17 )
		local total   = 11 + DIFFICULTY
		local knights = math.max( 12 - (6 *( DIFFICULTY - 1 ) ), 0 )

		level:summon{ "knight", knights,         area = left }
		level:summon{ "baron",  total - knights, area = left }
		level.data.sound_crack = coord(28, 10)
		
		level:player(70,5)
		level.status = 0
	end,

	OnKillAll = function ()
		if level.status == 2 then return end
		level:transmute_by_flag("wall", "floor", LFMARKER1, area.FULL)
		level:play_sound( "revenant.die", level.data.sound_crack)
		ui.msg("Peace comes back to this evil place. Cracks begin to appear as if in deference to your achievement.")
		level.status = 2
		if CHALLENGE == "challenge_aohu" then
			player:add_medal("everysoldier")
		end
	end,

	OnKill = function ()
		level.status = 1
	end,

	OnExit = function ()
		local result = level.status
		if result == 0 then
			ui.msg("Hearing them scream soothes the soul...")
			player:add_history("Not knowing what to do, he left.")
		elseif result == 1 then
			ui.msg("This must be madness!")
			player:add_history("He broke into the Wall, but gave up against the overwhelming forces.")
		elseif result == 2 then
			core.special_complete()
			ui.msg("All in all, we're just another brick in the wall.")
			player:add_history("He massacred the evil behind the Wall!")
			player:add_badge("wall1")
			if core.is_challenge("challenge_aomr") or core.is_challenge("challenge_aob") or core.is_challenge("challenge_aosh") then
				player:add_badge("wall2")
			end
		end
	end,
}
