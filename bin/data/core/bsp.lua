function generator.bsp_place_wall( self, c, wall_tile, door_tile, e1, e2 )
	local wid = cells[ wall_tile ].nid
	local did = cells[ door_tile ].nid
    core.log('place wall ('..c.x..'x'..c.y..', '..e1.x..'x'..e1.y..', '..e2.x..'x'..e2.y..')' )
    core.log('tiles ('..cells[wall_tile].id..','..cells[door_tile].id..')' )
	self:fill( wid, area( e1, e2 ) )
	self:set_cell( c, did )
end

function generator.bsp_area_split( ar, c, horizontal )
	if horizontal then
		return 
			area( ar.a:clone(), coord( ar.b.x, c.y ) ),
			area( coord( ar.a.x, c.y ), ar.b:clone() )
	else
		return 
			area( ar.a:clone(), coord( c.x, ar.b.y ) ),
			area( coord( c.x, ar.a.y ), ar.b:clone() )
	end
end

function generator.bsp( self, ar, bsp_settings )
	local sareas = { ar }
	local areas  = {}
	local counter = 0
	local limit   = 0

	local settings = bsp_settings or {}
	local grid  = settings.grid or coord(2,2)
	local gmin  = settings.gmin or coord(1,1)
	local cntr  = settings.centering or 4
	local sdiv  = settings.subdiv or 8
	local tiles = settings.tiles or {
		wall  = generator.styles[ level.style ].wall,
		floor = generator.styles[ level.style ].floor,
		door  = generator.styles[ level.style ].door,
	}

	local wid = cells[ tiles.wall ].nid
	local fid = cells[ tiles.floor ].nid
	local did = wid
	if tiles.door then 
		did = cells[ tiles.door ].nid
	end

	repeat
		local arc       = table.remove( sareas, 1 )
		if not arc then
			break
		end
		local arc_s     = arc:shrinked( grid )
		local arh_a     = arc_s.a / grid
		local arh_b     = arc_s.b / grid
		local arh_diff  = arh_b - arh_a
		local split = false
		if arh_diff.x > gmin.x or arh_diff.y > gmin.y then
			local hcntr = cntr / 2
			local arh_diff3 = ( arh_diff + coord(hcntr,hcntr) ) / cntr
			local ar_half  = area( arh_a + arh_diff3, arh_b - arh_diff3 ):clamped( area.FULL )
			if ar_half:proper() then
				local c = ar_half:random_coord() * grid
				local ori = true
				if arc:dim().y < arc:dim().x then
					ori = false
				end
				if not arc_s:contains( c ) then
					--print "fail---------------------------------"
				end
				if ori then
					c = c + coord( 1, 1 )
				end
                core.log(c:tostring())
				if self:get_cell( c ) == fid then
                    core.log('test')
					local e1, e2 = generator.get_endpoint_coords( self, c, ori, fid )
					if e1 then
                    core.log('e1')

						generator.bsp_place_wall( self, c, wid, did, e1, e2 )
						counter = counter + 1
		
						local a1, a2 = generator.bsp_area_split( arc, c, ori )
						local a1p = a1:proper()
						local a2p = a2:proper()

						if a1p then table.insert( sareas, a1 ) end
						if a2p then table.insert( sareas, a2 ) end
						split = a1p and a2p
					end
				end
			end
		end
		if not split then
			table.insert( areas, arc:clone() )
		end
		limit = limit + 1
	until counter > sdiv or limit > 128


	for _,a in ipairs( sareas ) do
		table.insert( areas, a )
	end
	return areas
end

function generator.rbsp( self, larea, rbsp_settings )
	rbsp_settings.tiles = rbsp_settings.tiles or {
		wall  = generator.styles[ level.style ].floor,
		floor = generator.styles[ level.style ].wall,
		door  = generator.styles[ level.style ].door,
	}

	local corridor  = rbsp_settings.corridor or 1
	local room_min  = rbsp_settings.room_min or coord( 2, 2 )
	local corr_mod  = coord( corridor - 1, corridor - 1 )
	local barea     = area( larea.a, larea.b + corr_mod )
	local corridor  = rbsp_settings.corridor or 1
	local ars       = generator.bsp( self, barea:expanded(1), rbsp_settings )
	local rooms     = {}
	for _,a in ipairs( ars ) do
		local aroom     = a:shrinked(1)
		aroom.b = aroom.b - corr_mod
		local size      = aroom.b - aroom.a
		if size.x >= room_min.x and size.y >= room_min.y and aroom:shrinked(2):proper() then
			table.insert( rooms, aroom )
		end
	end
	return rooms
end

function generator.place_doors( self, room, doors )
    local door_cell  = generator.styles[ level.style ].door
    local wall_cell  = generator.styles[ level.style ].wall
    local floor_cell = generator.styles[ level.style ].floor
    local fid = cells[ floor_cell ].nid
    local did = cells[ door_cell ].nid
    local wid = cells[ wall_cell ].nid
    while doors > 0 do
        local c = room:random_inner_edge_coord()
        if self:cross_around( c, wid ) == 2 and self:cross_around( c, fid ) == 2 then
            doors = doors - 1
            self:set_cell( c, did )
        end
    end
    return true
end

function generator.bsp_recursive( self, rooms, bsp_settings )
   	bsp_settings.tiles = bsp_settings.tiles or {
		floor = generator.styles[ self.style ].floor,
		wall  = generator.styles[ self.style ].wall,
		door  = generator.styles[ self.style ].door,
	}

	local rooms_out = {}
	local recursive_mask = {}
	local min      = bsp_settings.rec_min           or ivec2(8,8)
	local single   = bsp_settings.rec_single        or 11
	local doors    = bsp_settings.rec_doors         or 2
	local max_side = bsp_settings.max_reserved_side or 100
	local count    = #rooms
	local reserved_split_settings = {
		grid       = bsp_settings.grid,
		gmin       = bsp_settings.gmin or coord(0,0),
		centering  = 3,
		limit_area = bsp_settings.limit_area,
		tiles      = bsp_settings.tiles,
		subdiv     = 0,
	}

	table.sort( rooms, function(a,b) return a:size() > b:size() end )

	for _,room in ipairs( rooms ) do
		local size      = room.b - room.a
		local match     = false
		local reserved  = false
		local attempt   = count > 0 or bsp_settings.return_all
		local match_bsp = ( size.x >= min.x and size.y >= min.y and ( ( not single ) or ( size.x >= single or size.y >= single ) ) )
		
		if size.x > max_side or size.y > max_side then
			if attempt then
				if not match_bsp then
					reserved = true
				end
			else
				reserved = true
			end
			attempt  = true
		end
		if attempt then
			if reserved or match_bsp then 
				self:fill( bsp_settings.tiles.wall, room )
				self:fill( bsp_settings.tiles.floor, room:shrinked(1) )
				if not generator.place_doors( self, room, doors ) then
					return false
				end
				local settings = bsp_settings
				if reserved then
					settings = reserved_split_settings
				end
				local srooms
				local attempt = 0
				repeat
					attempt = attempt + 1
                    core.log("recursion")
					srooms = generator.bsp( self, room, settings )
                    core.log("recursion_end")

				until #srooms > 1 or attempt > 4

				if #srooms > 1 then
					if bsp_settings.return_all then
						for _,sa in ipairs( srooms ) do
							table.insert( rooms_out, sa )
							recursive_mask[ sa ] = true
						end
					elseif reserved then
						table.sort( srooms, function(a,b) return a:size() > b:size() end )
						local head = table.remove( srooms, 1 )
						table.insert( rooms_out, head )
						recursive_mask[ head ] = true
					end
					match = true
				end
				count = count - 1
			end
		end
		if not match then
			table.insert( rooms_out, room )
		end
	end
	return rooms_out, recursive_mask
end
