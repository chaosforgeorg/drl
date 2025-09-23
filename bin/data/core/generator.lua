generator.styles = {}
generator.cell_sets = {}
generator.cell_lists = {}

function generator.cell_set( list )
	local s = {}
	for _,v in ipairs( list ) do
		s[cells[v].nid] = true
	end
	return s
end

function generator.merge_cell_sets( list1, list2 )
	local s = {}
	for k,v in pairs( list1 ) do
		s[k] = v
	end
	for k,v in pairs( list2 ) do
		s[k] = v
	end
	return s
end

function generator.merge_cell_lists( list1, list2 )
	local s = {}
	for _,v in ipairs( list1 ) do
		table.insert( s, v )
	end
	for _,v in ipairs( list2 ) do
		table.insert( s, v )
	end
	return s
end

function generator.scatter(scatter_area,good,fill,count)
	if type(good) == "string" then good = cells[good].nid end
	if type(fill) == "string" then fill = cells[fill].nid end
	for _ = 1, count do
		local c = scatter_area:random_coord()
		if level:get_cell(c) == good then level:set_cell(c, fill) end
	end
end

function generator.scatter_item(scatter_area,good,item_id,count)
	if type(good) == "string" then good = cells[good].nid end
	for _ = 1, count do
		local c = level:random_empty_coord({ EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOLIQUID }, scatter_area )
		if level:get_cell(c) == good then
			level:drop_item( item_id, c, true )
		end
	end
end

function generator.scatter_cross(scatter_area,good,fill,count)
	if type(good) == "string" then good = cells[good].nid end
	if type(fill) == "string" then fill = cells[fill].nid end
	for _ = 1, count do
		local c = scatter_area:random_coord()
		if level:get_cell(c) == good and level:cross_around( c, good ) == 4 then 
			level:set_cell(c, fill)
		end
	end
end

function generator.scatter_cross_item(scatter_area,good,item_id,count)
	if type(good) == "string" then good = cells[good].nid end
	local test = function( c )
		return level:is_empty( c, { EF_NOBLOCK } )
	end

	local function drop( id )
		local attempts = 10 
		repeat
			local c = level:random_empty_coord( { EF_NOITEMS, EF_NOBEINGS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOLIQUID }, good, scatter_area )
			if c then
				if test( coord( c.x-1, c.y ) ) and test( coord( c.x+1, c.y ) ) and
					test( coord( c.x, c.y-1 ) ) and test( coord( c.x, c.y+1 ) ) then
					level:drop_item( id, c, true )
					return true
				end
			end	
			attempts = attempts - 1
		until attempts == 0
		return false
	end

	if type( item_id ) == "table" then
		for _,item in ipairs( item_id ) do
			count = core.resolve_range( item[2] or 1 )
			for i = 1, count do
				drop( item[1] )
			end
		end
	else
		count = core.resolve_range( count or 1 )
		for _ = 1, count do
			drop( item_id )
		end
	end
end

function generator.transmute_style( from, to, fstyle, tstyle, ar )
	local a    = ar or area.FULL
	local from = cells[from].nid
	for c in a() do 
		if level.map[ c ] == from and level:get_raw_style( c ) == fstyle then
			level.map[ c ] = to
			if tstyle then
				level:set_raw_style( c, tstyle )
			end
		end
	end
end

function generator.transmute_to_object( from, object, ar, floor )
	local a     = ar or area.FULL
	local from  = cells[from].nid
	local floor = floor or generator.styles[ level.style ].floor
	for c in a() do 
		if level.map[ c ] == from then
			level.map[ c ] = floor
			level:drop_item_ext( object, c )
		end
	end
end

function generator.scatter_blood(scatter_area,good,count)
	if type(good) == "string" then good = cells[good].nid end
	for c = 1, count do
		local c = scatter_area:random_coord()
		if not good or level:get_cell(c) == good then level.light[ c ][ LFBLOOD ] = true end
	end
end

function generator.roll_pair( list )
	if #list < 2 then return list[1] end
	local roll1 = math.random( #list )
	local roll2
	repeat 
		roll2 = math.random( #list )
	until roll2 ~= roll1
	return list[roll1], list[roll2]
end

function generator.place_dungen_tile( code, tile_object, tile_pos )
	local tile_area   = tile_object:get_area()
	generator.tile_place( level, tile_pos, tile_object )

	for c in tile_area() do
		local char       = string.char( tile_object:get_ascii(c) )
		local tile_entry = code[ char ]
		assert( tile_entry, "Character in map not defined -> "..char)
		if type(tile_entry) ~= "number" then
			local p = tile_pos + c - coord.UNIT
			if tile_entry.being then 
				local b = level:drop_being_ext( tile_entry.being, p )
				if b and tile_entry.armor then
					b.eq.armor = tile_entry.armor
				end
			end
			if tile_entry.item  then 
				local it = level:drop_item_ext( tile_entry.item, p )
				if it and tile_entry.add then
					it:add( item.new( tile_entry.add ) )
				end
			end
			if tile_entry.flags then
				for _, flag in ipairs(tile_entry.flags) do
					level.light[p][flag] = true
				end
			end
			if tile_entry.raw_style then
				level:set_raw_style( p, tile_entry.raw_style )
			end
			if tile_entry.style then
				level:set_raw_style( p, generator.styles[ tile_entry.style ].style )
			end
			if tile_entry.deco then
				level:set_raw_deco( p, tile_entry.deco )
			end
		end
	end
end

function generator.create_translation( code )
	local translation = {}
	for k,v in pairs(code) do
		local value = v
		if type(value) == "table"  then value = value[1] end
		if type(value) == "string" then
				if value == "FLOOR" then value = generator.styles[ level.style ].floor
			elseif value == "WALL"  then value = generator.styles[ level.style ].wall
			elseif value == "DOOR"  then value = generator.styles[ level.style ].door
			else
				assert( cells[value], "No such cell '"..value.."' in translation!" )
				value = cells[value].nid
			end
			translation[k] = value
		end
	end
	return translation
end

function generator.place_tile( code, tile, x, y )
	local translation = generator.create_translation( code )
	local tile_pos  = coord( x, y )
	local tile_object = generator.tile_new( level, tile, translation, true )
	generator.place_dungen_tile( code, tile_object, tile_pos )
end

function generator.place_symmetry_quad( tile, trans )
	local translation = generator.create_translation( trans )
	local tile_object = generator.tile_new( level, tile, translation, true )
	local tile_size   = tile_object:get_size_coord()
	generator.place_dungen_tile( trans, tile_object, coord( 2, 2 ) )
	tile_object:flip_x()
	generator.place_dungen_tile( trans, tile_object, coord( 78 - tile_size.x , 2 ) )
	tile_object:flip_y()
	generator.place_dungen_tile( trans, tile_object, coord( 78 - tile_size.x , 20 - tile_size.y ) )
	tile_object:flip_x()
	generator.place_dungen_tile( trans, tile_object, coord( 2 , 20 - tile_size.y ) )
end

function generator.place_proto_map( where, proto_map, proto_key, code )
	local trans = generator.create_translation( code )
	local proto = generator.tile_new( level, proto_map, {}, true )
	local pdim  = proto:get_size_coord()
	local tpos  = where:clone()
	for py = 1, pdim.y do
		tpos.x = where.x
		local mdim
		for px = 1, pdim.x do
			local map  = proto_key[ string.char( proto:get_ascii( coord(px,py) ) ) ]
			assert( map, "Key has no map!" )
			if type(map) == "table" then
				map = table.random_pick(map)
			end
			local mobj = generator.tile_new( level, map, trans, true )
			mdim = mobj:get_size_coord()
			generator.place_dungen_tile( code, mobj, where + tpos )
			tpos.x = tpos.x + mdim.x
		end
		tpos.y = tpos.y + mdim.y
	end
end


function generator.scatter_put(scatter_area,code,tile,good,count)
	if type(good) == "string" then good = cells[good].nid end

	local translation = generator.create_translation( code )
	local tile_object = generator.tile_new( level, tile, translation, true )
	local tile_size   = tile_object:get_size_coord()
	local tries       = 10000

	repeat
		local c = scatter_area:random_coord()

		if level:scan( area( c, c + tile_size - coord.UNIT ),good ) then
			generator.place_dungen_tile(code,tile_object,c)
			count = count - 1
		end
		tries = tries - 1
	until count == 0 or tries == 0
end

function generator.safe_empty_coord( a )
	local result = level:random_empty_coord({ EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN, EF_NOLIQUID, EF_NOSAFE }, a )
	if not result then
		result = level:random_empty_coord({ EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN, EF_NOLIQUID }, a )
	end
	if not result then
		result = level:random_empty_coord({ EF_NOBEINGS, EF_NOITEMS, EF_NOBLOCK, EF_NOSPAWN }, a )
	end
	if not result and a then 
		return generator.safe_empty_coord()
	end
	return result
end

function generator.standard_empty_coord( param1, param2 )
	return level:random_empty_coord( { EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }, param1, param2 )
end

function generator.set_permanence( ar, val, tile )
	if type(val) ~= "boolean" then val = true end
	if tile then
		tile = cells[ tile ].nid
		for c in level:each( tile, ar ) do
			level.light[ c ][ LFPERMANENT ] = val
		end
	else
		for c in ar:coords() do
			local id = level:get_cell( c )
			if generator.cell_sets[ CELLSET_WALLS ][ id ] then
				level.light[ c ][ LFPERMANENT ] = val
			end
		end
	end
end

function generator.set_blood( ar, val, tile )
	if type(val) ~= "boolean" then val = true end
	if tile then
		tile = cells[ tile ].nid
		for c in level:each( tile, ar ) do
			level.light[ c ][ LFBLOOD ] = val
		end
	else
		level.light[ ar ][ LFBLOOD ] = true
	end
end

function generator.drunkard_walks( amount, steps, cell, ignore, break_on_edge, drunk_area )
	core.log("generator.drunkard_walks("..amount..","..steps..","..cell.."...)")
	if amount <= 0 then return end
	drunk_area = drunk_area or area.FULL_SHRINKED
	for i=1,amount do
		generator.run_drunkard_walk( level, drunk_area, drunk_area:random_coord(), steps, cell, ignore, break_on_edge )
	end
end

function generator.contd_drunkard_walks( amount, steps, cell, edges1, edges2, ignore, break_on_edge, drunk_area )
	core.log("generator.contd_drunkard_walks("..amount..","..steps..","..cell.."...)")
	if amount <= 0 then return end
	drunk_area = drunk_area or area.FULL_SHRINKED
	local c
	for i=1,amount do
		repeat
			c = drunk_area:random_coord()
		until level:cross_around( c, edges1 ) > 0 and
		level:cross_around( c, edges2 ) > 0
		generator.run_drunkard_walk( level, drunk_area, c, steps, cell, ignore, break_on_edge )
	end
end


function generator.plot_lines( where, larea, horiz, cell, block )
	core.log("generator.plot_lines(...)")
	local step = function( point, px, py )
		point.x = point.x + px
		point.y = point.y + py
		if block[ level:get_cell( point ) ] then
			return true
		else
			level:set_cell( point, cell )
			return false
		end
	end
	local hcoord = function( c ) if horiz then return c.x else return c.y end end

	local sx, sy, minv, maxv = 0, 0, 0, 0
	if horiz then
		sx = 1; minv = larea.a.x; maxv = larea.b.x
	else
		sy = 1; minv = larea.a.y; maxv = larea.b.y
	end

	local c
	c = coord.clone( where )
	while hcoord(c) < maxv do if step( c, sx, sy ) then break end end
	c = coord.clone( where )
	while hcoord(c) > minv do if step( c, -sx, -sy ) then break end end
end

function generator.maze_dungeon( floor_cell, wall_cell, granularity, tries, minl, maxl, maze_area )
	core.log("generator.maze_dungeon()")
	if type(floor_cell) == "string" then floor_cell = cells[floor_cell].nid end
	maze_area = maze_area or area.FULL
	local rx = math.floor( ( maze_area.b.x - maze_area.a.x ) / granularity )
	local ry = math.floor( ( maze_area.b.y - maze_area.a.y ) / granularity )
	local rl = math.floor( ( maxl - minl ) / granularity + 1 )
	for i=1,tries do
		local c = coord(
			granularity * math.random( rx ) + maze_area.a.x,
			granularity * math.random( ry ) + maze_area.a.y
		)
		if level:get_cell( c ) == floor_cell and level:cross_around( c, floor_cell ) == 4 then
			local step = coord( 0, 0 )
			local length = minl + granularity * ( math.random( rl ) - 1 )
			if math.random( 2 ) == 1 then
				step.x = math.random(2)*2-3
			else
				step.y = math.random(2)*2-3
			end
			while maze_area:contains( c + step ) and level:get_cell( c + step ) == floor_cell and length > 0 do
				level:set_cell( c, wall_cell )
				c = c + step
				length = length - 1
			end
			level:set_cell( c, wall_cell )
		end
	end
end

function generator.warehouse_fill( wall_cell, fill_area, boxsize, amount, special_chance, special_fill )
	local floor_cell   = generator.styles[ level.style ].floor

	boxsize = boxsize or 2
	amount  = amount or 50
	local dim = coord( boxsize+2, boxsize+2 )
	for i = 1, amount do
		local ar = fill_area:random_subarea( dim )
		if level:scan( ar, floor_cell ) then
			ar:shrink(1)
			local fill_cell = wall_cell
			if special_chance and special_fill and boxsize < 4 then
				local dim = ar:dim()
				local roll = math.random(math.max(100 * (boxsize-1),100))
				if roll <= special_chance then fill_cell = special_fill end
			end
			if type(fill_cell) == "table" then fill_cell = table.random_pick( fill_cell ) end
			level:fill( fill_cell, ar )
		end
	end
end

function generator.read_rooms()
	core.log("generator.add_rooms()")
	local room_list      = {}
	local cell_meta      = generator.merge_cell_sets( generator.cell_sets[ CELLSET_WALLS ], generator.cell_sets[ CELLSET_DOORS ] )
	local cell_meta_list = generator.merge_cell_lists( generator.cell_lists[ CELLSET_WALLS ], generator.cell_lists[ CELLSET_DOORS ] )
	local room_begin = function(c)
		if c.x == MAXX or c.y == MAXY then return false end
		if c.x == 1 then return cell_meta[ level:get_cell( 2, c.y ) ] end
		if c.y == 1 then return cell_meta[ level:get_cell( c.x, 2 ) ] end
		local meta_count = level:cross_around( c, cell_meta_list )
		if meta_count == 4 then return true end
		if meta_count == 3
			and cell_meta[ level:get_cell( c.x + 1, c.y ) ]
			and cell_meta[ level:get_cell( c.x, c.y + 1 ) ]
			then return true end
		return false
	end

	for start in area.coords( area.FULL ) do
		if room_begin( start ) then
			local ec = coord.clone( start )
			repeat
				ec.x = ec.x + 1
			until ec.x == MAXX or cell_meta[ level:get_cell( ec.x, start.y + 1 ) ]
			repeat
				ec.y = ec.y + 1
			until ec.y == MAXY or cell_meta[ level:get_cell( start.x + 1, ec.y ) ]
			table.insert( room_list, area( start, ec ) )
		end
	end
	return room_list
end

function generator.add_room( list, room )
	local r = room:clone()
	local rm = {}
	rm.used  = false
	rm.dims  = area.dim( r )
	rm.size  = rm.dims.x * rm.dims.y
	rm.area  = r
	table.insert( list, rm )
end

function generator.create_room_list( list )
	core.log("generator.add_rooms()")
	local room_list = generator.read_rooms()
	local list = list or {}
	for _,room in ipairs( room_list ) do
		generator.add_room( list, room )	
	end
	return list
end

function generator.get_room( room_list, min_size, max_x, max_y, max_area, class )
	core.log("generator.get_room()")
	local class = class or "any"
	local marea = max_area or 10000
	local choice_list = {}
	for _,rm in ipairs( room_list ) do
		local r = rm.area
		if not rm.used then
			if rm.dims.x >= min_size and rm.dims.y >= min_size and
				rm.dims.x <= max_x and rm.dims.y <= max_y and rm.size <= marea then
				table.insert( choice_list, rm )
			end
		end
	end
	return table.random_pick( choice_list )
end

function generator.restore_walls( wall_cell, skip_cells )
	core.log("generator.restore_walls("..wall_cell..")")
	if skip_cells then
		for c in area.edges( area.FULL ) do
			if not skip_cells[ cells[level:get_cell( c )].id ] then
				level:set_cell( c, wall_cell )
			end
		end
	else
		level:fill_edges( wall_cell )
	end
end

function generator.handle_rooms( room_list, settings )
	core.log("generator.handle_rooms()")
	local settings   = settings or {}
	local count      = settings.count or 1
	if count < 1 or #(room_list) == 0 then return end
	local reqs       = settings.reqs
	local weights    = settings.weights or {}
	local choice = weight_table.new()
	for _,r in ipairs(rooms) do
		if core.tag_reqs_met( r, reqs ) then
			local weight = core.proto_weight( r, weights )
			if weight > 0 then
				choice:add( r, weight )
			end
		end
	end
	if choice:size() == 0 then 
		core.log("generator.handle_rooms() > no rooms available for generation")
		return
	end

	for i = 1,count do
		local room      = choice:roll()
		local room_meta = generator.get_room( room_list, room.min_size, room.max_size_x, room.max_size_y, room.max_area )
		if room_meta then
			core.log("generator.handle_rooms() > setting up room : "..room.id)
			if room.setup( room_meta.area, room_meta, room_list ) then
				room_meta.used = true
			end
		end
	end
end

function generator.roll_event( weights )
	core.log("generator.roll_event()")

	local lvl = level.danger_level
	local choice = weight_table.new()
	for _,e in ipairs(events) do
		if lvl >= e.min_dlevel and DIFFICULTY >= e.min_diff then 
			local weight = e.weight or 1
			if type( weights ) == "table" then
				weight = core.proto_weight( e, weights )
			end
			choice:add( e, weight )
		end
	end
	if choice:size() == 0 then return end
	local event = choice:roll()

	core.log("generator.roll_event() > setting up event : "..event.id)
	level.data.event = {}
	level.data.event.id = event.id
	event.setup()
	generator.OnTick = event.on_tick
	generator.OnExit = event.on_leave
	if event.message then ui.msg_feel( event.message ) end
	if event.history then player:add_history( event.history ) end
end

function generator.on_save()
	generator.OnTick = nil
	generator.OnExit = nil
end

function generator.on_load()
	if level.data.event then
		generator.OnTick = events[ level.data.event.id ].on_tick
		generator.OnExit = events[ level.data.event.id ].on_leave
	end
end

function generator.reset()
	core.log("generator.reset()")
	ui.clear_feel()
	generator.OnKill       = nil
	generator.OnKillAll    = nil
	generator.OnEnterLevel = nil
	generator.OnExit       = nil
	generator.OnTick       = nil

	level:set_generator_style( level.style )
	level:fill( generator.styles[ level.style ].floor )
	level:fill_edges( generator.styles[ level.style ].wall )
end

function generator.place_player()
	core.log("generator.place_player()")
	local safe_zone = 3
	if DIFFICULTY <= DIFF_EASY then
		safe_zone = 7
	elseif DIFFICULTY <= DIFF_MEDIUM then
		safe_zone = 6
	elseif DIFFICULTY <= DIFF_HARD then
		safe_zone = 4
	end

	local pos
	local attempts = 12
	repeat
		pos = generator.safe_empty_coord()
		attempts = attempts - 1
		if attempts % 3 == 0 then
			safe_zone = safe_zone - 1
		end
		local safe = true
		for b in level:beings_in_range( pos, safe_zone ) do
			safe = false
			break
		end
	until safe or attempts == 0 or safe_zone < 2
	level:drop_being( player, pos )
	return pos
end

function generator.generate_stairs( stairs_id )
	core.log("generator.generate_stairs()")
	local pos = generator.standard_empty_coord()
	level:set_cell( pos, stairs_id )
	return pos
end

function generator.generate_special_stairs( stairs_id, feelings )
	core.log("generator.generate_special_stairs()")
	local pos = generator.generate_stairs( stairs_id )
	if feelings then
		if type(feelings) == "string" then feelings = { feelings } end
		ui.msg_feel( table.random_pick( feelings ) )
	end
	return pos
end

function generator.generate_tiled_level( settings )
	core.log("generator.generate_tiled_level()")
	local settings     = settings or {}
	local wall_cell    = settings.wall_cell  or cells[generator.styles[ level.style ].wall].nid
	local door_cell    = settings.door_cell  or cells[generator.styles[ level.style ].door].nid
	local floor_cell   = settings.floor_cell or cells[generator.styles[ level.style ].floor].nid

	local block = generator.cell_set{ wall_cell }

	local plot = function( horiz, where )
		generator.plot_lines( where, area.FULL, horiz, wall_cell, block )
		level:set_cell( where, door_cell )
	end

	local div_point = function( x, yrange, ymult, ymod )
		return coord( x, math.random(yrange)*ymult+ymod )
	end

	local MAX2 = math.floor(MAXX / 2)
	local MAX4 = math.floor(MAXX / 4)
	local MAX8 = math.floor(MAXX / 8)

	local nfirst = settings.subdiv      or 5
	local ndoors = settings.extra_doors or 4
	local pdoors = settings.add_doors   or 8

	if math.random(3) == 1 then
		plot( false, div_point( math.random(MAX4-8)*2+4,       8,2,2 ) )
		plot( false, div_point( math.random(MAX4-8)*2+4+MAX4*2,8,2,2 ) )
	else
		plot( false, div_point( math.random(MAX4-12)*2+4,            8,2,2 ) )
		plot( false, div_point( math.random(MAX4-4)*2 + MAX2 - MAX4, 8,2,2 ) )
		plot( false, div_point( math.random(MAX4-12)*2+8+MAX4*2,     8,2,2 ) )
	end
	for i = 1,4 do
		plot( true, div_point( math.random(MAX8-3)*2+(MAX4+1)*(i-1)+3,4,4,1 ) )
	end

	for i = 1,nfirst do
		if math.random(3) == 3 then
			plot( true, div_point( math.random(MAX2-2)*2+1, 8,2,1 ) )
		else
			plot( false, div_point( math.random(MAX2-2)*2+2, 6,2,2 ) )
		end
	end

	local door_positions = {}
	local priority_doors = {}
	
	for c in area.coords( area.FULL_SHRINKED ) do
		if level:get_cell( c ) == wall_cell
		and level:around( c, door_cell ) == 0 
		and level:cross_around( c, wall_cell ) == 2
		and level:cross_around( c, floor_cell ) == 2
		then
			local walls = level:around( c, wall_cell )
			if walls > 4 then
				if level:around( c, door_cell ) == 0 then
					level:set_cell( c, door_cell )
				end
			elseif walls > 3 then
				table.insert( priority_doors, c:clone() )
			else
				table.insert( door_positions, c:clone() )
			end
		end
	end

	for i = 1,pdoors do
		local pos = table.random_remove( priority_doors )
		if pos and level:around( pos, door_cell ) == 0 then
			level:set_cell( pos, door_cell )
		end
	end

	for i = 1,ndoors do
		local pos = table.random_remove( door_positions )
		if pos and level:around( pos, door_cell ) == 0 then
			level:set_cell( pos, door_cell )
		end
	end

	generator.restore_walls( wall_cell )
end

function generator.generate_archi_level( settings )
	core.log("generator.generate_archi_level()")
	assert( settings, "no settings for archi level!" )
	local data = nil
	local layout = settings.layout
	if settings.size then
		data = settings
	else
		assert( settings.data, "no data for archi level!" )
		if settings.data.size then
			data = settings.data
		else
			data = table.random_pick( settings.data )
			assert( data.size, "malformed data for archi level!" )
		end
	end
	local stop_flip = data.stop_flip or false

	layout = layout or data.layout
	if layout then
		layout = string.gsub( layout, "%s+", "" )
	end

	local wall_cell    = generator.styles[ level.style ].wall
	local translation = {
		["X"] = 0,
		["#"] = wall_cell,
		["."] = generator.styles[ level.style ].floor,
		["+"] = generator.styles[ level.style ].door,
	}

	local blocks = data.blocks
	local bsize  = data.size
	local shift  = data.shift 
	if not blocks then
		blocks = coord( math.floor( (MAXX-1) / (bsize.x-1) ), math.floor( (MAXY-1) / (bsize.y-1) ) )
	end
	if not shift then
		shift = coord( MAXX, MAXY ) - blocks * (bsize - coord.UNIT)
		shift.x = math.max( 1, math.floor( shift.x / 2 ) )
		shift.y = math.max( 1, math.floor( shift.y / 2 ) )
	end
	core.log( "blocks: "..blocks.x.."x"..blocks.y.." size: "..bsize.x.."x"..bsize.y.." shift: "..shift.x..","..shift.y )
	local result = area( shift, shift + blocks * (bsize - coord.UNIT) )

	if not data.no_fill and not data.prefill then
		level:fill( wall_cell )
	end
	if data.prefill then
		level:fill( data.prefill, result )
	end

	if data.trans then
		for k,v in pairs( data.trans ) do translation[k] = v end
	end
	if settings.trans then
		for k,v in pairs( settings.trans ) do translation[k] = v end
	end
	local pure_translation = generator.create_translation( translation )

	for bx=1,blocks.x do
		for by=1,blocks.y do
			local index = nil
			if layout then
				index = bx + (by-1) * blocks.x
				index = string.sub( layout, index, index )
			end
			if index ~= "." then
				local block
				if index then
					block = table.random_pick( data[ index ] )
				else
					block = table.random_pick( data )
				end
				local pos   = coord( (bx-1) * (bsize.x-1) + shift.x, (by-1) * (bsize.y-1) + shift.y )
				local tile  = generator.tile_new( level, block, pure_translation, true )
				if not stop_flip then
					tile:flip_random()
				end
				generator.place_dungen_tile( translation, tile, pos )
			end
		end
	end

	for c in level:each( generator.styles[ level.style ].door ) do
		if level:cross_around( c, wall_cell ) > 2 then
			level:set_cell( c, wall_cell )
		end
	end

	if data.restore_edges then
		for c in area.edges( result ) do 
            level:set_cell( c, data.restore_edges )
        end
	end

	if data.clear_dead_ends then
		generator.clear_dead_ends( data.clear_dead_ends )
	end

	if not data.no_fill and ( not data.restore_edges )  then
		generator.restore_walls( wall_cell )
	end
	if not data.no_fluids then
		generator.generate_fluids(area(shift.x+1, shift.y+1, MAXX - shift.x-1, MAXY - shift.y-1))
	end
	return result
end

function generator.destroy_cell( c )
	local cell = cells[ level.map[c] ]
	local dto  = cell.destroyto
	if dto ~= "" then
		level.map[c] = dto
	else
		level.map[c] = generator.styles[ level.style ].floor
	end
	level.light[c][LFPERMANENT] = false
end

function generator.wallin_cell( c, cell_id )
	local cell = cells[ level.map[c] ]
	local target = level:get_being(c)
	if target then
		if target:is_player() then return false end
		target:kill()
	end
	local item = level:get_item(c)
	if item then item:destroy() end
	level.map[c] = cell_id
	level.light[c][LFPERMANENT] = true
	return true
end

function generator.clear_dead_ends( iterations, ar )
	iterations = iterations or 1
	local ar      = ar or area.FULL_SHRINKED
	local applied = false
	local floor   = generator.styles[ level.style ].floor
	local door    = generator.styles[ level.style ].door
	local wall    = generator.styles[ level.style ].wall
	repeat
		applied = false
		for c in level:each( floor, ar ) do
			if level:cross_around( c, wall ) >= 3 then
				applied = true
				level:set_cell( c, generator.styles[ level.style ].wall )
			end
		end
		for c in level:each( door, ar ) do
			if level:cross_around( c, wall ) >= 3 then
				applied = true
				level:set_cell( c, generator.styles[ level.style ].wall )
			end
		end
		iterations = iterations - 1
	until iterations == 0 or (not applied)

	for c in level:each( door, ar ) do
		if level:cross_around( c, wall ) < 2 then
			level:set_cell( c, floor )
		end
	end
end

function generator.remove_needless_doors()
	core.log("generator.remove_needless_doors()")
	local floor = generator.styles[ level.style ].floor
	local wall  = generator.styles[ level.style ].wall
	local door  = generator.styles[ level.style ].door
	for c in level:each( door, area.FULL_SHRINKED ) do
		local wcaround = level:cross_around( c, wall )
		if wcaround > 2 then
			level:set_cell( c, wall )
		elseif wcaround == 2 then
			if level:around( c, wall ) > 5 then 
				level:set_cell( c, floor )
			end
		end
	end
end

function generator.mirror_horizontally( y_value, x_start )
	core.log("generator.mirror_horizontally()")
	local x_start = x_start or 1
	for x = x_start, MAXX do
		for y = 1, y_value-1 do
			local c1 = coord( x, y )
			local c2 = coord( x, 2 * y_value - y )
			level:set_cell( c2, level:get_cell( c1 ) )
			local item = level:get_item( c1 )
			if item then
				level:drop_item( item.id, c2 )
			end
		end
	end
end

function generator.mirror_vertically( x_value, y_start )
	core.log("generator.mirror_vertically()")
	local y_start = y_start or 1
	for y = y_start, MAXY do
		for x = 1, x_value-1 do
			local c1 = coord( x, y )
			local c2 = coord( 2 * x_value - x, y )
			level:set_cell( c2, level:get_cell( c1 ) )
			local item = level:get_item( c1 )
			if item then
				level:drop_item( item.id, c2 )
			end
		end
	end
end

function generator.mirror_quad( pos )
	core.log("generator.mirror_quad()")
	generator.mirror_horizontally( pos.y )
	generator.mirror_vertically( pos.x )
end

function generator.horiz_river( settings )
	assert( settings )
	assert( settings.cell )
	local cell     = settings.cell 
	local rwidth   = settings.width or { 2, 4 }
	local bridge   = settings.bridge

	local bridges = {}
	local dbridges = {}
	local function bridge_ok( x, y )
		if not bridge then return false end
		local cell = level:get_cell( x, y )
		return generator.cell_sets[ CELLSET_FLOORS ][cell] or generator.cell_sets[ CELLSET_DOORS ][cell]
	end

	local width = core.resolve_range( rwidth )
	local floor = generator.styles[ level.style ].floor
	local y     = 10 + math.random(2*width) - width
	local fill  = cell
	for x = 1,MAXX do
		for w = 1,width do
			level:set_cell( x, w + y, fill )
		end
		if bridge and bridge_ok( x, y ) and bridge_ok( x, y + width + 1 ) then
			table.insert( bridges, coord( x, y ) )
		end
		if math.random(6) == 1 then 
			y = math.clamp( y + math.random(3) - 2, 3, MAXY - width - 2 )
		end
	end

	if bridge and #bridges > 0 then
		local dbridges = {}
		for i,c in ipairs( bridges ) do
			if bridges[i+1] and c.x == bridges[i+1].x-1 then
				table.insert( dbridges, { c, bridges[i+1] } )
			end
		end

		local count  = 0
		local dcount = 0
		if #dbridges == 0 or math.random(3) == 1 then
			count = math.min( #bridges, 3+math.random(3) )
		else
			dcount = 1 + math.random(2)
		end

		while count > 0 and #bridges > 0 do
			count = count - 1
			local c = table.random_remove( bridges )
			for w = 1,width do
				level:set_cell( coord( c.x, c.y + w ), bridge )
			end
		end

		while dcount > 0 and #dbridges > 0 do
			dcount = dcount - 1
			local cc = table.random_remove( dbridges )
			for w = 1,width do
				level:set_cell( coord( cc[1].x, cc[1].y + w ), bridge )
				level:set_cell( coord( cc[2].x, cc[2].y + w ), bridge )
			end
			if cc[1].x < 4 or cc[2].x > MAXX - 4 then
				dcount = dcount + 1
			end
		end
	end

end

function generator.vert_river( settings )
	assert( settings )
	assert( settings.cell )
	local cell     = settings.cell 
	local rwidth   = settings.width or { 2, 4 }
	local position = settings.position
	local bridge   = settings.bridge
	local brange   = settings.bridge_range
	local floor = generator.styles[ level.style ].floor

	local function bridge_ok( x, y )
		if not bridge then return false end
		if brange and type(brange) == "table" then
			if not (y >= brange[1] and y <= brange[2]) then return false end
		end
		local cell = level:get_cell( x, y )
		return generator.cell_sets[ CELLSET_FLOORS ][cell] or generator.cell_sets[ CELLSET_DOORS ][cell]
	end

	local function execute( pos )
		local bridges = {}

		local pos   = pos or ( 18 + math.random(40) )
		local width = core.resolve_range( rwidth )
		local by    = 100
		local fill = cell
		local x    = math.clamp( pos, 3, MAXX - width - 3 )
		local function iteration(y)
			for w = 1,width do
				level:set_cell( coord( w + x, y ), fill )
			end
			if bridge and bridge_ok( x, y ) and bridge_ok( width+x+1, y ) then
				table.insert( bridges, coord( x, y ) )
			end
			if math.random(3) == 1 then 
				x = math.clamp( x + math.random(3) - 2, 3, MAXX - width - 3 )
			end
		end
		for y = 1, MAXY do
			iteration(y)
		end

		if bridge and #bridges > 0 then
			local dbridges = {}
			for i,c in ipairs( bridges ) do
				if bridges[i+1] and c.y == bridges[i+1].y-1 then
					table.insert( dbridges, { c, bridges[i+1] } )
				end
			end

			local count  = 0
			local dcount = 0
			if #dbridges == 0 or math.random(3) == 1 then
				count = math.min( #bridges, 2 )
			else
				dcount = 1
			end

			while count > 0 and #bridges > 0 do
				count = count - 1
				local c = table.random_remove( bridges )
				for w = 1,width do
					level:set_cell( coord( c.x + w, c.y ), bridge )
				end
			end

			while dcount > 0 and #dbridges > 0 do
				dcount = dcount - 1
				local cc = table.random_remove( dbridges )
				for w = 1,width do
					level:set_cell( coord( cc[1].x + w, cc[1].y ), bridge )
					level:set_cell( coord( cc[2].x + w, cc[2].y ), bridge )
				end
				if cc[1].y < 4 or cc[2].y > MAXY - 4 then
					dcount = dcount + 1
				end
			end
		end
	end

	if type(position) == "table" then
		for _,p in ipairs(position) do
			execute(p)
		end
	else
		execute(position)
	end
end

function generator.generate_rivers( settings )
	assert( settings )
	assert( settings.cell )
	local cell          = settings.cell 
	local bridge        = settings.bridge
	local allow_horiz   = not ( settings.vertical_only or false )
	local allow_more    = not ( settings.no_extra      or false )
	local destroy_items = not ( settings.no_destroy_items or false )

	if allow_horiz and math.random(4) == 1 then
		generator.horiz_river{ cell = cell, bridge = bridge }
	else
		local rsettings = {
			cell         = cell,
			width        = {3,5},
			bridge       = bridge,
			bridge_range = settings.vert_bridge,		  
		}

		if allow_more and math.random(3) == 1 then
			if math.random(4) == 1 then
				rsettings.width = {2,4}
				rsettings.position = {
					8  + math.random(20), 
					32 + math.random(16),
					50 + math.random(20)
				}
			else
				rsettings.position = { 
					8  + math.random(22), 
					48 + math.random(22),
				}	
			end
		end
		generator.vert_river( rsettings )
	end

	if destroy_items then
		local floor = generator.styles[ level.style ].floor
		for c in level:each( cell ) do
			local item = level:get_item(c)
			if item then
				if not item.flags[ IF_NODESTROY] then
					item:destroy()
				else
					level:set_cell( c, floor )
				end
			end
		end
		if bridge then
			for c in level:each( bridge ) do
				local item = level:get_item(c)
				if item and ( not item.flags[ IF_NODESTROY] ) then item:destroy() end
			end
		end
	end
end