-- NOTE - the blueprint, storage and constructor are declared here, because core has no notion
-- or how DRL generates levels (barrels etc)

core.declare( "register_generator", core.register_storage( "generators", "generator" ) )

core.register_blueprint "generator"
{
	id           = { true,   core.TSTRING },
	weight       = { true,   core.TTABLE },
	min_dlevel   = { false,  core.TNUMBER, 3 },
	min_diff     = { false,  core.TNUMBER, 0 },
	events       = { false,  core.TBOOL, true },
	place_stairs = { false,  core.TBOOL, true },
	place_player = { false,  core.TBOOL, true },
	monsters     = { false,  core.TANY, 1.0 },
	items        = { false,  core.TANY, 1.0 },
	rooms        = { false,  core.TANY },
	barrels      = { false,  core.TBOOL, false },
	fluids       = { false,  core.TANY, false },
	rivers       = { false,  core.TANY, false },
	run          = { true,   core.TFUNC },
	post_run     = { false,  core.TFUNC },
}

function drl.register_generators()

	register_generator "gen_tiled"
	{
		weight     = { [{1,8}] = 100, 50 },
		min_dlevel = 1,
		rooms      = { 4, 10 },
		barrels    = true,
		fluids     = 60,
		rivers     = 60,

		run        = function() 
			generator.generate_tiled_level()
			return generator.create_room_list()
		end
	}

	register_generator "gen_maze"
	{
		weight     = { 20 },
		monsters   = 1.5,
		items      = 0.8,
		barrels    = true,
		rivers     = 66,
		fluids     = true,

		run        = function() 
			local wall_cell    = generator.styles[ level.style ].wall
			local floor_cell   = generator.styles[ level.style ].floor

			local maze_styles = {
				{granularity = 3, tries = 500, minl = 2, maxl = 4 },
				{granularity = 3, tries = 300, minl = 4, maxl = 12},
				{granularity = 3, tries = 100, minl = 4, maxl = 12},
			}
			local style = table.random_pick( maze_styles )
			for x=1,MAXX do level:set_cell( x, MAXY-1, wall_cell ) end
			generator.maze_dungeon( floor_cell, wall_cell, style.granularity, style.tries, style.minl, style.maxl )

			ui.msg_feel( "Where the hell is the way out of here!?!" )
		end,

		post_run   = function()
			local s = level:find_coord("stairs")
			local p = player.position
			if s and p:distance( s ) <= player.vision and level:eye_contact( p, s ) then
				ui.msg_feel( "...Oh, there it is. D'oh.")
			end
		end,
	}

	register_generator "gen_caves"
	{
		weight   = { [{9,24}] = 30, 20 },
		events   = false,
		monsters = 0,
		items    = 0,

		run      = function() 
			generator.generate_caves_dungeon()
		end
	}

	register_generator "gen_caves_2"
	{
		weight     = { 20 },
		min_dlevel = 8,
		min_diff   = 2,
		rooms      = { 4, 12 },
		barrels    = true,

		run      = function() 
			generator.generate_caves_2_dungeon()
		end
	}

	register_generator "gen_arena"
	{
		weight       = { 6 },
		min_dlevel   = 8,
		min_diff     = 2,
		events       = false,
		place_stairs = false,
		place_player = false,
		barrels      = true,
		items        = 0.67,
		monsters     = 0.67,

		run        = function() 
			generator.generate_fluids()
			generator.generate_fluids()
			generator.generate_fluids()

			local center  = coord( 38,10 )

			local translation = {
				['.'] = generator.styles[ level.style ].floor,
				['#'] = generator.styles[ level.style ].wall,
				['+'] = generator.styles[ level.style ].door,
				['>'] = "stairs",
				['X'] = "wall",
				['%'] = "rwall",
				['@'] = "gwall",
			}
			generator.place_symmetry_quad( table.random_pick( generator.arena_quad_data ), translation )
			local min  = math.min( math.ceil( level.danger_level / 10 ), 4 )
			local max  = math.min( math.ceil( level.danger_level / 4 ), #(generator.arena_data) ) 
			local scheme = math.random( min, max )
			local tile = generator.tile_new( level, generator.arena_data[scheme], translation )
			local tdim = tile:get_size_coord()
			local hdim = coord( math.floor( tdim.x / 2 ), math.floor( tdim.y / 2 ) )
			generator.tile_place( level, center - hdim, tile )
			level.light[ area( center - hdim, center + hdim ) ][ LFNOSPAWN ] = true
			
			local linfo = player.episode[ level.index ]
			if linfo.special then
				generator.generate_special_stairs( "rstairs", "You shiver from cold..." )
			end
		end,

		post_run   = function()
			level:drop_being( player, coord( 38,10 ) )
		  	ui.msg_feel( "Suddenly monsters come from everywhere!" )
			for b in level:beings() do
				if math.random(2) == 1 then
					b.flags[ BF_HUNTING ] = true
				end
			end
		end,
	}

	register_generator "gen_warehouse"
	{
		weight      = { 25 },
		barrels     = true,
		fluids      = 30,
		rivers      = 20,

		run       = function() 
			local wall_cell = generator.styles[ level.style ].wall
			local areas     = {}
			local divs      = table.random_pick{ 1, 2, 2, 2, 2, 3 }
			local divpoint  = 1

			for i=1,divs do
				local newdiv = math.floor( MAXX / (divs+1) )*i + math.random(16)-8
				local where = coord( newdiv, math.random(12)+4 )
				generator.plot_line( level, where, false, wall_cell )
				level:set_cell( where, generator.styles[ level.style ].door )
				table.insert( areas, area( divpoint+1, 2, newdiv-1, MAXY-1 ) )
				divpoint = newdiv
			end
			table.insert( areas, area( divpoint+1, 2, MAXX-1, MAXY-1 ) )

			for _,ar in ipairs(areas) do
				local size = table.random_pick{ 2, 3, 3, 3, 3, 4 }
				local tries = table.random_pick{ 50, 50, 200 }
				if math.random( 3 ) == 1 then
					generator.warehouse_fill( wall_cell, ar, size, tries )
				else
					generator.warehouse_fill( { "crate", "ycrate" }, ar, size, tries, 10, { "crate_ammo", "crate_armor" } )
				end			
			end
		end
	}

	register_generator "gen_archi"
	{
		weight       = { 40 },
		min_dlevel   = 8,
		barrels      = true,
		rivers       = 25,

		run          = function()
			local result = generator.generate_archi_level{ data = { generator.archi_data, generator.archi_data2 } }
			generator.generate_fluids{ area = result:shrinked(1) }
		end,
	}

	register_generator "gen_city"
	{
		weight       = { [{1,8}] = 10, 40 },
		min_dlevel   = 4,
		rooms        = { 4, 12 },
		barrels      = true,
		fluids       = true,

		run          = function() 
			local wall_cell    = generator.styles[ level.style ].wall
			local floor_cell   = generator.styles[ level.style ].floor
			local door_cell    = generator.styles[ level.style ].door

			local tries = 100
			local dim_max = coord( 16, 12 )
			local dim_min = coord( 7, 6 )
			local city = area.shrinked( area.FULL, 2 )

			if math.random(3) == 1 then	generator.handle_rivers{ vertical_only = true } end
		
			local list = {}
			for i=1,tries do
				local room = area.random_subarea( city, coord.random( dim_min, dim_max ) )
				if level:scan(room,floor_cell) then
					room:shrink(1)
					level:fill( wall_cell, room )
					level:set_cell( area.random_inner_edge_coord( room ), door_cell )
					room:shrink(1)
					level:fill( "crate", room )
					generator.add_room( list, room:expanded() )
				end
			end
			level:transmute( "crate", floor_cell )
			return list
		end
	}

	register_generator "gen_single"
	{
		weight       = { 6 },
		min_dlevel   = 16,
		min_diff     = 2,
		items        = 1.5,
		rooms        = { 4, 10 },
		barrels      = true,
		fluids       = true,

		monsters   = function( bweight )
			local intro = {
				imp        = "The walls are scratched and flame-scorched!",
				mancubus   = "You hear deep, guttural noises!",
				revenant   = "Bones clatter all around you!",
				arch       = "You hear crackling flames!",
			}

			local roll    = math.min( level.danger_level + (DIFFICULTY - 2)*3-4, 20) + math.random(10)
			local monster = core.less_than_table( {
					{17,"former"}, {19,"imp"}, {21,"knight"}, {21,"knight"},
					{24,"mancubus"}, {26,"revenant"}, {100,"arch"}
				}, roll )

			if monster == "arch" and math.random(3) == 1 then
				ui.msg_feel( "Hellish magic haunts the air!" )
				level:flood_monster{ danger = bweight / 2, id = "arch" }
				level:flood_monsters{ danger = bweight / 2, list = { "captain", "sergeant", "former", "commando" } }
			elseif monster == "knight" then
				ui.msg_feel( "A battle cry chants in the distance!" )
				level:flood_monsters{ danger = bweight, list = { "baron", "knight", "bruiser" } }
			elseif monster == "former" then
				ui.msg_feel( "You hear many marching feet." )
				level:flood_monsters{ danger = bweight, list = { "former", "sergeant", "captain", "commando" } }
				if DIFFICULTY > 3 then
					level:flood_monsters{ danger = bweight / 8, list = { "esergeant", "eformer" } }
				end
				if DIFFICULTY > 4 or level.danger_level > 60 then
					level:flood_monster{ danger = bweight / 8, id = "ecaptain" }
				end
				if level.danger_level > 100 then
					level:flood_monster{ danger = bweight / 8, id = "ecommando" }
				end
			else
				if intro[monster] then
					ui.msg_feel( intro[monster] )
				end
				level:flood_monster{ id = monster, danger = generator.being_weight() }
			end

			player:add_history("On @1 he stumbled into a complex full of "..beings[monster].name_plural.."!")
		end,
		run        = function() 
			generator.generate_tiled_level()
			return generator.create_room_list()
		end

	}

	register_generator "gen_single_plus"
	{
		weight       = { 1 },
		min_dlevel   = 50,
		min_diff     = 3,
		items        = 2.0,
		rooms        = { 4, 10 },
		barrels      = true,
		fluids       = true,

		monsters   = function( bweight )
			local intro = {
				shambler   = "The air is crackling with electricity!",
				bruiser    = "You hear loud wails that cannot mean anything good!",
				cyberdemon = "Suddenly you have a great urge to turn back! You scream in TERROR!",
			}

			local monster = table.random_pick{"cyberdemon","shambler","bruiser"}
			ui.msg_feel( intro[monster] )
			level:flood_monster{ id = monster, danger = generator.being_weight() }
			player:add_history("On @1 he stumbled into a complex full of "..beings[monster].name_plural.."!")
		end,
		run        = function() 
			generator.generate_tiled_level()
			return generator.create_room_list()
		end
	}

	register_generator "gen_lava"
	{
		weight     = { [{12,20}] = 10, 20 },
		min_dlevel = 12,
		min_diff   = 2,
		rooms      = { 4, 10 },

		run        = function() 
			return generator.generate_lava_dungeon()
		end
	}

end
