-- CITY OF SKULLS -------------------------------------------------------

register_level "city_of_skulls"
{
	name  = "City of Skulls",
	entry = "On @1 he found the City of Skulls.",
	welcome = "You enter a city made out of bones. You sense a certain tension.",
	level = 12,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "rwall" )

		local translation = {
			['.'] = "floor",
			[','] = { "floor", flags = { LFBLOOD } },
			['#'] = "wall",
			['>'] = "stairs",

			['O'] = { "floor", being = core.ifdiff( 2, "pain" ) },
			['s'] = { "floor", being = "lostsoul" },

			['/'] = { "floor", item = "shell" },
			['|'] = { "floor", item = "ammo" },
			['-'] = { "floor", item = "rocket" },
			['!'] = { "floor", item = "umbazooka" },
		}

		local map = [[
............................,,,,,,,,,,....................,,,...............
...,,,,,,,,,...,,,,,,,,,....,########,.......,,,,,,,,........,,,...,,,......
...,#######,...,#######,....,#|s||s|#,.......,######,.......,,,,,,,,,.......
...,#|s.-/#,...,#|,s-/#,....,#/.s..s#,.......,#|s-/#,.....,,,#######,.......
...,#..O.s#,...,#s.,,s#,....,#s.Os..#,.......,#s.s.#,.......,#!|s-/#,.......
...,#s..s.#,...,#######,....,#.s..s.#,.......,#.s.s#,......,,#s.Os.#,.......
...,#######,...,,,,,,,,,....,########,.......,######,..,,,,.,#.s..s#,.......
...,,,,,,,,,...........,,,..,,,,,,,,,,.......,,,,,,,,.......,#######,.......
.........,,,,,.............................,,...............,,,,,,,,,.......
....,,.......,,,.......,,,.....,,..........,,,.........,,,,.................
.........,,,,,,,,,.........,,,...............................,,,..,,,....>..
..,..,,..,#######,...,,......................,....,,,,,,,,,......,,..,......
...,,....,#.s.s.#,..........,,,,,,,,,,,....,,,....,#######,...,....,........
....,,...,#s|sOs#,...,,.....,#########,...........,#/.s-.#,...,,,,..,.......
.........,#/s-s.#,..........,#s.s.s./#,.......,,..,#s.Os.#,......,,,........
..,,,....,#######,....,,,...,#.s|s-s.#,.....,,,...,#.s|.s#,.......,,........
...,,,...,,,,,,,,,.,,,......,#########,...,,,.....,#######,....,,,..........
...........,...,............,,,,,,,,,,,...........,,,,,,,,,.................
]]

		generator.place_tile( translation, map, 2,2 )
		local lever = level:drop_item( "lever_walls", coord( 35, 11 ) )
		lever.flags[ IF_NODESTROY ]	= true
		generator.set_permanence( area.FULL )
		level:player(2,2)
		level.status = 1
	end,

	OnKillAll = function ()
		if level.status == 3 then return end

		if level.status == 1 and DIFFICULTY < 2 then
			level.status = 3
			ui.msg("That seems to be all of them, hopefully...")
			return
		end

		if level.status == 2 then
			level.status = 3
			ui.msg("That had damn well better be all of them!")
			return
		end

		if DIFFICULTY == 3 then
			ui.msg("Suddenly lost souls appear out of nowhere!")
			level:summon("lostsoul",20)
		end
		if DIFFICULTY > 3 then
			ui.msg("Suddenly pain elementals appear out of nowhere!")
			level:summon("pain",12)
		end

		ui.msg("You hear a howl of agony!")
		local agony = level:summon("agony")
		for i = 1,3 do
			agony.inv:add( item.new(table.random_pick{"ufskull","ubskull","uhskull"}) )
		end
		level.status = 2
	end,

	OnExit = function ()
		if level.status == 3 then
			core.special_complete()
			player:add_history("He wiped out the City of Skulls.")
 	 		player:add_badge("skull1")
			if core.is_challenge("challenge_aora") then player:add_badge("skull2") end
		else
			player:add_history("He fled the City in terror!")
		end
	end,

}

