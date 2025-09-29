-- HALLS OF CARNAGE -----------------------------------------------------

register_level "halls_of_carnage"
{
	name  = "Halls of Carnage",
	entry = "On @1 he ventured into the Halls of Carnage.",
	welcome = "You enter the Halls of Carnage. You feel you need to run!",
	level = 14,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "rwall" )

		local mod1,mod2 = generator.roll_pair{"mod_power","mod_agility","mod_bulk","mod_tech"}

		local translation = {
			['.'] = "floor",
			[','] = {"floor", flags = {LFBLOOD} },
			['#'] = "wall",
			['%'] = { "wall", flags = { LFBLOOD } },
			['X'] = "rwall",
			['+'] = "door",
			['['] = "ldoor",
			['>'] = "stairs",
			['='] = "lava",
			['6'] = { "floor", being = core.bydiff{"demon","demon","demon","knight","ndemon"}  },
			['8'] = { "floor", being = core.bydiff{"demon","cacodemon","knight","baron","ncacodemon"} },
			['9'] = { "floor", being = core.bydiff{"cacodemon","knight","baron" } },
			['|'] = { "floor", item = "ammo" },
			['}'] = { "floor", item = "ashotgun" },
			['{'] = { "floor", item = "plasma" },
			['^'] = { "floor", item = "lhglobe" },
			[':'] = { "floor", item = "bfg9000" },
			['"'] = { "floor", item = mod1 },
			['?'] = { "floor", item = mod2 },
		}

		local map = [[
.................................#.|.".}.|.#...#..===..X.......6............
...........................................%...#,.===..X..XXXXXXXXX.XXXXXXX.
...#%%##+##........#...###%%##...........,,%...[,.===..[..X.........6.......
...#.,,...#........#.......,,#..........,,,#...#,.===..X..X.XXXX[XXXXXXXX.X.
...#...............#.........#...#####+#%%##...#..===..X..X6X.8........8X.X.
...+...............#.........#.................#..===..X..X.X.XXXXXXX[X.X.X.
...#,..............+...,,,...#.........#.......#..===..X..X.X.X...9...X.[.X6
...#%#........######..#%%##............#...#...#,.===..X..X.X.X.XXXXX9X.X.X|
.,,,..................#......#........,%...#...[,.=^=..[..X.X.X.X|:|X.X.X..?
......................#...,,.%.......,,%...%,..#,.===..X6.X.X.X9X.>.X.X.X.X|
...##%%+######........#...,,,%......,,.#..,%,..#..===..X..X.X.X.X[XXX.X.X.X.
...#..,......+...........,,..#...##%%%##...%...#..===..X..X.X.X.....9.X.[.X.
...#......,..#..........##%%%#.............#...#,.===..X..X.X.XXXXXXXXX.X...
...#.....##%%#........................######...[,.===..[..X.X8.......8..X.X.
......................................#........#,.===..X..X.XXXXXX[XXXXXX.X.
.,,######..........####%%%##+###......+........#..===..X..X6..............X6
.,,+^|..#..........#,,,,,.............#........#..===..X..XXXXX.XXXXX.XXXXX.
.,,#.|..#..........#.,,,.......................#..===..X.........6..........
]]
		generator.place_tile( translation, map, 2, 2 )

		local left   = area( 2,  2, 48, 19 ) 
		local middle = area( 50, 2, 56, 19 ) 

		level:summon{ "former",   8 + DIFFICULTY,   area = left }
		level:summon{ "sergeant", 8 + 2*DIFFICULTY, area = left }
		level:summon{ "lostsoul", 6 + 2*DIFFICULTY, area = middle }

		generator.set_permanence( area( 66,9,70,12 ) )
		level:player(8,18)
		local tick = core.bydiff{ 80, 60, 50, 30, 20 }

		level.data.event = {
			id         = "flood_lava_event",
			timer      = 0,
			step       = tick,
			direction  = 1,
			flood_min  = 0,
			cell		= "lava",
		}
		generator.OnTick = events.flood_lava_event.on_tick
	end,

	OnTick = function()
		generator.OnTick()
	end,

	OnExit = function ()
		if level:get_enemies_left( true ) == 0 then
			core.special_complete()
		end
	end,
}