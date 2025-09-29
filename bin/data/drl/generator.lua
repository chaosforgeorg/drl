require( "drl:archi" )

generator.wall_to_ice = {
	lava   = "water",
	acid   = "water",
	mud    = "water",
	blood  = "water",
}

function generator.run( gen )
	generator.reset()
	core.log("generator.run > generating level type : "..gen.id)
	local room_list = gen.run()

	if gen.fluids then
		if type( gen.fluids ) == "function" then
			gen.fluids() 
		elseif type( gen.fluids ) == "number" then
			if math.random(100) <= gen.fluids then
				generator.generate_fluids()
			end
		else
			generator.generate_fluids()
		end
	end

	if gen.rivers then
		if type( gen.rivers ) == "function" then
			gen.rivers() 
		elseif type( gen.rivers ) == "number" then
			if math.random(100) <= gen.rivers then
				generator.handle_rivers()
			end
		elseif type( gen.rivers ) == "table" then
			if type( gen.rivers[1] ) == "number" then
				if math.random(100) <= gen.rivers[1] then
					generator.handle_rivers( gen.rivers )
				end
			end
		else
			generator.handle_rivers()
		end
	end

	if gen.rooms then
		if type( gen.rooms ) == "function" then
			gen.rooms() 
		elseif type( gen.rooms ) == "table" and room_list then
			local settings = { count = math.random( gen.rooms[1], gen.rooms[2] ) }
			generator.handle_rooms( room_list, settings, room_list )
			generator.restore_walls( generator.styles[ level.style ].wall, generator.cell_sets[ CELLSET_FLUIDS ] )
		end
	end

	if gen.barrels then
		generator.generate_barrels()
	end

	if type( gen.monsters ) == "function" then
		gen.monsters( generator.being_weight() ) 
	elseif gen.monsters > 0.01 then
		level:flood_monsters{ danger = math.ceil( generator.being_weight() * gen.monsters ) }
	end
	if type( gen.items ) == "function" then
		gen.items( generator.item_amount() ) 
	elseif gen.items > 0.01 then
		level:flood_items{ amount = math.ceil( generator.item_amount() * gen.items ) }
	end

	if gen.place_stairs then
		generator.generate_stairs( "stairs" )
		local linfo = player.episode[ level.index ]
		if linfo.special then
			generator.generate_special_stairs( "rstairs", {
				"You feel a breeze of morbid air...",
				"You sense a passage to a place beyond...",
				"You shiver from cold...",
			} )
		end
	end
	if gen.place_player then
		generator.place_player()
	end

	if gen.events then
		if math.min( math.floor( level.danger_level / 2), 20 ) > math.random(100) then
			generator.roll_event()
		end
	end

	if gen.post_run then gen.post_run() end

	core.log("generator.run > level generated successfully.")
end

function generator.being_weight()
	local danger = level.danger_level
	if danger > 16 then
		danger = danger + 2
	elseif danger > 8 then
		danger = danger + 1
	end
	local weight = 0

	    if DIFFICULTY == DIFF_EASY      then weight = math.ceil( danger*2.2+6 )
	elseif DIFFICULTY == DIFF_MEDIUM    then weight = math.ceil( math.sqrt(danger*500)*0.6)
	elseif DIFFICULTY == DIFF_HARD      then weight = math.ceil( math.sqrt(danger)*20)
	elseif DIFFICULTY == DIFF_VERYHARD  then weight = math.ceil( math.sqrt(danger)*32)
	elseif DIFFICULTY == DIFF_NIGHTMARE then weight = math.ceil( math.sqrt(danger)*40)
	else weight = math.ceil( math.sqrt(danger)*40)
	end
	core.log( "generator.being_weight() "..level.danger_level.." > "..weight )
	return weight
end

function generator.item_amount()
	return math.ceil( 21 - math.max( 25-level.danger_level, 0 ) / 3 )
end

function generator.handle_rivers( settings )
	local settings = table.copy( settings or {} )
	settings.bridge = settings.bridge or "bridge"
	settings.no_destroy_items = true
	if not settings.cell then
		settings.cell    = "lava"
		local lvl = level.danger_level + math.random(DIFFICULTY * 2 + 6)
			if lvl < 17 then settings.cell = table.random_pick{ "water", "water", "water", "mud" }
		elseif lvl < 27 then settings.cell = "acid"
		elseif lvl > 50 then settings.cell = table.random_pick{ "lava", "lava", "acid", "blood" } end
	end
	generator.generate_rivers( settings )
end

function generator.generate_lava_dungeon()
	core.log("generator.generate_lava_dungeon()")
	local fluids = {
		"lava",
		"lava",
		"acid",
		"blood"
	}
	local range = 2
	if level.danger_level > 30 then range = 3 end
	if level.danger_level > 40 then range = 4 end
	local fluid = fluids[ math.random( range ) ]

	level:fill( fluid )
	local wall_cell    = generator.styles[ level.style ].wall
	local floor_cell   = generator.styles[ level.style ].floor
	local door_cell    = generator.styles[ level.style ].door
	local lava_nid     = cells[ fluid ].nid
	local wall_nid     = cells[ wall_cell ].nid

	local tries = 3
	local dim_max = coord( 70, 18 )
	local dim_min = coord( 10, 8 )
	local a = area.shrinked( area.FULL, 2 )
	local even_coord = function ( c )
		local result = c:clone()
		if result.x % 2 == 1 then result.x = result.x+1 end
		if result.y % 2 == 1 then result.y = result.y+1 end
		return result
	end

	for i=1,tries do
		local quad = area.random_subarea( a, coord.random( dim_min, dim_max ) ):clamped( a )
		quad.a = even_coord( quad.a )
		quad.b = even_coord( quad.b )

		if math.random(2) == 1 then
			quad:shrink(1)
			level:fill( fluid, quad )
			quad:expand(1)
		end

		for c in quad:edges() do
			if level:get_cell(c) == lava_nid then
				level:set_cell(c, "bridge")			
			end
		end

		for c in quad:corners() do
			level:fill( floor_cell, area.around(c,1) )
		end
	end

	local tries = 8
	local dim_max = coord( 20, 16 )
	local dim_min = coord( 12, 10 )
	local a = area.shrinked( area.FULL, 2 )
	local list = {}
	for i=1,tries do
		local quad = area.random_subarea( a, coord.random( dim_min, dim_max ) ):clamped( a )
		local good = true
		for c in quad() do 
			if level:get_cell(c) == wall_nid then 
				good = false
				break
			end
		end
		if good then
			level:fill( floor_cell, quad )
			quad:shrink(1)
			level:fill( wall_cell, quad )
			level:set_cell( area.random_inner_edge_coord( quad ), door_cell )
			quad:shrink(1)
			level:fill( "crate", quad )
			generator.add_room( list, quad:expanded() )
		end
	end
	level:transmute( "crate", floor_cell )
	return list
end

function generator.generate_caves_dungeon()
	core.log("generator.generate_caves_dungeon()")
	local dlevel = level.danger_level
	local style  = 10
	if dlevel > 8  then style = 11 end
	if dlevel > 16 then style = 12 end
	if dlevel > 30 then style = math.random( 10, 12 ) end
	
	level:set_generator_style( style )

	local wall_cell    = generator.styles[ level.style ].wall
	local floor_cell   = generator.styles[ level.style ].floor

	local amount, step, fluid

	    if dlevel < 7  then amount = math.random(3); step = math.random(40)+22; fluid = table.random_pick{ "water", "water", "water", "mud" }
	elseif dlevel < 12 then amount = math.random(3); step = math.random(40)+42; fluid = "acid"
	else                    amount = math.random(5); step = math.random(50)+42; fluid = "lava"
	end

	if dlevel >= 30 then
		fluid = table.random_pick{ "lava", "lava", "acid", "blood" }
	elseif dlevel > 20 and fluid == "lava" and DIFFICULTY >= DIFF_HARD then
		fluid = math.random{ "lava", "lava", "blood" }
	end

	local drunk = function( amount, step, cell )
		generator.contd_drunkard_walks( amount, step, cell, { floor_cell, fluid }, {wall_cell}, nil, true )
	end

	level:fill( wall_cell )

	generator.run_drunkard_walk( level, area.FULL_SHRINKED, coord( 38, 10 ), math.random(40)+100, floor_cell, nil, true )
	drunk( 5,  math.random(40)+35, floor_cell )
	drunk( amount, step,   fluid )
	drunk( 40, math.random(40)+25, floor_cell )
	drunk( amount, step+20, fluid )

	if math.random(3) == 1 then
		local cell  = "lava"
		if fluid == "blood" then cell = "blood" end
		local lvl = level.danger_level + math.random(DIFFICULTY * 2 + 6)
		    if lvl < 17 then cell = table.random_pick{ "water", "water", "water", "mud" }
		elseif lvl < 27 then cell = "acid" end

		if math.random(3) == 1 then
			generator.horiz_river{ cell = cell, bridge = "bridge" }
		else
			local pos = generator.standard_empty_coord()
			if pos then
				local settings = {
					cell     = cell,
					width    = { 4, 6 },
					position = math.clamp( pos.x, 3, MAXX-3 ),
					bridge   = "bridge",
				}
				generator.vert_river( settings )
			end
		end
	end

	local sets = {
		{ level = { 0,  16 }, weight = 3, list = "lostsoul"},
		{ level = { 7,  20 }, weight = 2, list = {"demon","lostsoul"} },
		{ level = { 5,  22 }, weight = 3, list = "demon"},
		{ level = { 10, 20 }, weight = 2, list = {"demon","cacodemon"} },
		{ level = { 14, 28 }, weight = 1, list = {"lostsoul","demon","cacodemon"} },
		{ level = { 10, 25 }, weight = 3, list = "cacodemon"},
		{ level = { 15, 40 }, weight = 1, list = {"cacodemon","arachno"} },
		{ level = { 16, 50 }, weight = 3, list = "arachno"},
		{ level = { 30, 40 }, weight = 1, list = {"arachno","pain"}, min_diff = 3 },
		{ level = { 20, 99 }, weight = 1, list = { "lostsoul", "pain" } },
		{ level = { 20, 50 }, weight = 1, list = "pain", min_diff = 3 },
		{ level = { 51, 99 }, weight = 1, list = "pain", },
		{ level = { 100 },    weight = 1, list = "npain", },

		{ level = { 50, 250}, weight = 2, list = { "lostsoul", "pain", "agony" }, min_diff = 3 },
		{ level = { 30, 60 }, weight = 2, list = { "ndemon", "demon" } },
		{ level = { 40, 80 }, weight = 2, list = { "narachno", "arachno" } },
		{ level = { 50, 100}, weight = 2, list = { "ncacodemon", "cacodemon" } },

		{ level = { 30 },     weight = 5, list = "ndemon",         history = "On @1 he stumbled into a nightmare demon cave!" },
		{ level = { 40 },     weight = 5, list = "narachno",       history = "On @1 he stumbled into a nightmare arachnotron cave!" },
		{ level = { 50 },     weight = 1, list = "npain",          history = "On @1 he stumbled into a nightmare elemental cave!" },
		{ level = { 60 },     weight = 5, list = "ncacodemon",     history = "On @1 he stumbled into a nightmare cacodemon cave!" },
		{ level = { 70 },     weight = 1, list = "agony",          history = "On @1 he stumbled into a agony elemental cave!", min_diff = 3, feeling = "You hear echoing wails of agony!" },
		{ level = { 80 },     weight = 1, list = "lava_elemental", history = "On @1 he stumbled into a lava elemental cave!", min_diff = 3, feeling = "The cave temperature is insanely hot!" },
	}

	local mlevel = math.max( level.danger_level + (DIFFICULTY - 2)*3, 0 )
	local list   = weight_table.new()
	for _,s in ipairs( sets ) do
		local lmin, lmax = s.level[1] or 0, s.level[2] or 100000
		local dmin       = core.iif( mlevel > 2 * lmin, 0, s.min_diff or 0 )
		if mlevel >= lmin and mlevel <= lmax and DIFFICULTY >= dmin then
			list:add(s,s.weight)
		end
	end
	local set = list:roll()
	local amount  = math.floor( generator.being_weight() * 0.67 )
	if set.history then player:add_history(set.history) end
	level:flood_items{ amount = 10 }

	if type( set.list ) == "string" then
		level:flood_monster{ id = set.list, danger = amount }
	else
		level:flood_monsters{ list = set.list, danger = amount }
	end

  	ui.msg_feel( set.feeling or "Twisted passages carry the smell of death..." )

	generator.set_permanence( area.FULL )
end

function generator.place_blob( start, size, cell )
	local floor_cell = cells[generator.styles[ level.style ].floor ].nid
	local cells = { cell, floor_cell }
	local visit = {}
	table.insert( visit, start )
	for j = 1,size do
		if #visit == 0 then break end
		local idx = math.random( #visit )
		local n   = visit[ idx ]
		table.remove( visit, idx )
		if level:around( n, cells ) == 8 then
			level:set_cell( n, cell ) 
			for c in n:cross_coords() do 
				if level:get_cell( c ) == floor_cell then
					table.insert( visit, c:clone() )
				end
			end
		end
	end
end

function generator.generate_caves_2_dungeon()
	local dlevel = level.danger_level
	local wall_cell  = cells[generator.styles[ level.style ].wall].nid
	local door_cell  = cells[generator.styles[ level.style ].door].nid
	local style  = 10
	if dlevel > 8  then style = 11 end
	if dlevel > 16 then style = 12 end
	if dlevel > 30 then style = math.random( 10, 12 ) end
	level:set_generator_style( style )

	local floor_cell = cells[generator.styles[ level.style ].floor].nid
	local cave_cell  = cells[generator.styles[ level.style ].wall ].nid
	local marker     = cells["crate"].nid
	local fluid      = cells["lava"].nid
	if math.random(4) == 1 then fluid = cells["water"].nid end
	if math.random(4) == 1 then fluid = cells["acid"].nid end
	if dlevel > 30 and math.random(3) == 1 then fluid = cells["blood"].nid end
	local level_area = area.FULL
	local w,h = level_area.b.x, level_area.b.y

	local drunk = function( amount, step, cell )
		generator.contd_drunkard_walks( amount, step, cell, { floor_cell, fluid }, {cave_cell}, nil, true )
	end

	level:fill( cave_cell )
	local sub_area = level_area:shrinked( 7 )
	level:fill( floor_cell, sub_area )
	sub_area:shrink( 4 )
	level:fill( cave_cell, sub_area )

	drunk( 10, math.random(10)+40, floor_cell )
	drunk( 50, math.random(10)+20, floor_cell )

	for c in level_area:shrinked()() do
		if level:get_cell(c) == cave_cell and level:around( c, cave_cell ) < 4 then
			level:set_cell( c, floor_cell )
		end
	end

	for c in level_area:shrinked(2)() do
		if level:get_cell(c) == floor_cell and level:cross_around( c, cave_cell ) > 2 then
			for k in c:cross_coords() do
				level:set_cell( k, marker )
			end
		end
	end

	level:transmute( marker, floor_cell )

	-- rest of the level will be destructible
	generator.set_permanence( area.FULL, true, cave_cell )


	local bcount = math.random(3) + 2
	for i = 1,bcount do
		local start = level:random_square( floor_cell )
		local count = math.random( 5 ) + 5
		generator.place_blob( start, count, marker )
	end

	level:transmute( marker, cave_cell )

	local cmax  = math.random( 5, 7 )
	local count = 0
	for i = 1,1000 do
		local dim = coord( math.random( 7,9 ), math.random( 6,9 ) )
		local a = area.FULL_SHRINKED:random_subarea( dim )
		if level:scan( a, floor_cell ) then
			a:shrink()
			level:fill( wall_cell, a )
			level:set_cell( a:random_inner_edge_coord(), door_cell )
			a:shrink()
			level:fill( marker, a )
			count = count + 1
			if count == cmax then break end
		end
	end

	local bcount = math.random(5) + 10
	for i = 1,bcount do
		local start = level:random_square( floor_cell )
		local count = math.random( 40 ) + 20
		generator.place_blob( start, count, fluid )
	end

	level:transmute( marker, floor_cell )

	for c in level_area:shrinked()() do
		if level:get_cell(c) == fluid and level:around( c, fluid ) < 4 then
			level:set_cell( c, floor_cell )
		end
	end
end

function generator.generate_fluids( drunk_area )
	core.log("generator.generate_fluids()")
	local lvl  = level.danger_level
	local lava = "lava"
	if lvl > 30 then 
		lvl  = math.random(20) + 5
		lava = table.random_pick{ "lava", "lava", "blood" }
	end
	    if lvl < 7   then generator.drunkard_walks( math.random(3)-1, math.random(40)+2, table.random_pick{ "water", "water", "mud" }, nil, nil, drunk_area )
	elseif lvl < 12  then generator.drunkard_walks( math.random(3)-1, math.random(40)+2, "acid", nil, nil, drunk_area )
	elseif lvl < 17  then generator.drunkard_walks( math.random(5)-1, math.random(50)+2, lava, nil, nil, drunk_area )
	else generator.drunkard_walks( math.random(5)+3, math.random(40)+2, lava, nil, nil, drunk_area ) end
end

function generator.generate_barrels()
	core.log("generator.generate_barrels()")
	local lvl = level.danger_level + math.random(5)
	local count = 12
	if math.random(22) == 22 then
		count = 50
		ui.msg_feel( "Khe, he, he, this will be a mess..." )
	end
	local cell1 = "barrel"
	local cell2 = "barrel"

	if lvl > 18 then
		cell1, cell2 = "barreln", "barreln"
		if math.random(4) == 1 then cell1 = "barrela" end
	elseif lvl > 13 then
		cell2 = "barreln"
	elseif lvl > 6 then
		cell2 = "barrela"
	end

	local function barrel_coord()
		return level:random_empty_coord( { EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN, EF_NOLIQUID } )
	end
	

	for i=1,count/2 do
		level:drop_item( cell1, barrel_coord(), true )
		level:drop_item( cell2, barrel_coord(), true )
	end
end
