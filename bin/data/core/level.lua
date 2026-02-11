function level:flood_tile( pos, cell, destroy )
	local cell_data = cells[ level:get_cell( pos ) ]
	if not cell_data.flags[ CF_CRITICAL ] then
		level:set_cell( pos, cell )
		if destroy then 
			if cell_data.OnDestroy then cell_data.OnDestroy(pos) end
			level:try_destroy_item( pos )
		end
	end
end

function level:flood( tile, flood_area )
	local hazard = cells[tile].flags[ CF_HAZARD ]
	for c in flood_area() do
		level:flood_tile( c, tile, hazard )
	end
	self:recalc_fluids()
end


function level:destroy_to( c, cell_id )
	local cell = cells[ level.map[ c ] ]
	if not cell.flags[ CF_NOCHANGE ] then
		level.map[ c ] = cell_id
		return true
	end
	return false
end

function level:get_being_table( dlevel, weights, reqs, dmod )
	local dmod   = dmod or math.clamp( (DIFFICULTY-2)*3, 0, 6 )
	local danger = dlevel or self.danger_level
	local list   = weight_table.new()

	for _,b in ipairs(beings) do
		if b.weight > 0	and danger+dmod >= b.min_lev and danger <= b.max_lev then
			if core.proto_reqs_met( b, reqs ) then
				local weight = core.proto_weight( b, weights )
				if weight > 0 then
					list:add( b, weight )
				end
			end
		end
	end

	for _,bg in ipairs(being_groups) do
		if bg.weight > 0 and danger+dmod >= bg.min_lev and danger <= bg.max_lev then
			if core.proto_reqs_met( bg, reqs ) then
				local weight = core.proto_weight( bg, weights )
				if weight > 0 then
					list:add( bg )
				end
			end
		end
	end
	return list
end

function level:get_item_table( dlevel, weights, reqs, global )
	local danger       = dlevel or self.danger_level
	local allow_exotic = self.danger_level > DIFFICULTY
	local allow_unique = self.danger_level > DIFFICULTY+3
	if reqs and reqs.tags and reqs.tags == "special" then
		allow_exotic = true
	end
	local list         = weight_table.new()
	local greqs        = nil
	local gweights	   = nil
	if global then
		local linfo = player.episode[ level.index ]
		if linfo then
			greqs    = linfo.reqs
			gweights = linfo.weights
		end
	end
	for _,i in ipairs(items) do
		if i.weight > 0 and danger >= i.level and danger <= i.max_level then
			if (not i.is_exotic or allow_exotic) and (not i.is_unique or allow_unique) then
				if core.proto_reqs_met( i, reqs ) and ( ( not greqs ) or core.proto_reqs_met( i, greqs ) ) then
					if (not i.is_unique or not player.__props.items_found[i.id]) then
						local weight = core.proto_weight( i, weights ) 
						if weight > 0 then
							if gweights then
								weight = weight * core.proto_weight( i, gweights )
							end
							if weight > 0 then
								list:add( i, weight )
							end
						end
					end
				end
			end
		end
	end
	return list
end

function level:flood_monsters( params )
	if not params.danger and not params.amount then 
		error("level:flood_monsters expects at least danger or count!")
	end
	local flags  = params.flags  or { EF_NOBEINGS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }
	local dtotal = params.danger or 100000000
	local count  = params.amount or 100000000 
	local reqs   = params.reqs
	if params.no_groups then 
		reqs = reqs or {}
		reqs.is_group = false
	end
	local list
	if params.list then
		list = weight_table.new()
		for k,v in pairs( params.list ) do
			if type(k) == "string" then
				list:add( beings[k], v )
			else
				list:add( beings[v] )
			end
		end
	else
		list = self:get_being_table( params.level, params.weights, reqs, params.diffmod )
	end

	while (dtotal > 0) and (count > 0) do
		local bp    = list:roll()
		local where = level:random_empty_coord( flags, params.area )
		if not where then 
			core.warning("level:flood_monsters - no empty space found!")
			break
		end
		if not bp then 
			core.warning("level:flood_monsters - no fitting enemy found for given reqs!")
			break
		end
		if bp.is_group then
			for _,group in ipairs(bp.beings) do
				local count = core.resolve_range(group.amount or 1)
				for i=1,count do
					local b = self:drop_being( group.being, where )
					dtotal = dtotal - beings[group.being].danger
					count  = count - 1
					if b then 
						b:add_property( "GROUPED" )
					end
				end
			end
		else
			self:drop_being( bp.id, where )
			dtotal = dtotal - beings[bp.id].danger
			count  = count - 1
		end
	end
end

function level:flood_monster( params )
	if not params.id or (not params.danger and not params.amount) then 
		error("level:flood_monster expects at least id and danger or count!")
	end
	local id     = params.id
	local flags  = params.flags  or { EF_NOBEINGS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }
	local dtotal = params.danger or 100000000
	local count  = params.amount or 100000000 
	while (dtotal > 0) and (count > 0) do
		local being = self:drop_being( id, level:random_empty_coord( flags, params.area ) )
		if not being then return end
		dtotal = dtotal - beings[id].danger
		count  = count - 1
	end
end

function level:flood_items( params )
	params = params or {}
	local amount  = params.amount or params
	local list    = self:get_item_table( params.level or level.danger_level, params.weights, params.reqs )

	while amount > 0 do
		local id = self:roll_item_list( list )
		if id then
			local where = level:random_empty_coord{ EF_NOITEMS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }
			self:drop_item( id, where, true )
			amount = amount - 1
		end
	end
end

function level:roll_being( params )
	local reqs   = params.reqs or {}
	reqs.is_group = false
	local list
	if params.list then
		list = weight_table.new()
		for k,v in pairs( params.list ) do
			if type(k) == "string" then
				list:add( beings[k], v )
			else
				list:add( beings[v] )
			end
		end
	else
		list = self:get_being_table( params.level, params.weights, reqs, params.diffmod )
	end
	return list:roll().id
end

function level:roll_item_list( list )
	if list:size() == 0 then return nil end
	local limit = 100
	repeat
		local ip    = list:roll()
		if ip.is_unique then
			if not self.flags[ LF_UNIQUEITEM ] then 
				self.flags[ LF_UNIQUEITEM ] = true
				return ip.id
			end
		else
			return ip.id
		end
		limit = limit - 1
	until limit <= 0
	core.warning("roll_item_list: only unique items left!")
	return nil	
end


function level:roll_item( params )
	params = params or {}
	local reqs    = params.reqs
	local weights = params.weights
	if params.type then
		reqs = reqs or {}
		reqs.type = params.type
	end
	if params.unique_mod or params.special_mod or params.exotic_mod then
		weights = weights or {}
		weights[ IF_UNIQUE ]  = params.unique_mod
		weights[ IF_EXOTIC ]  = params.exotic_mod
		weights.is_special    = params.special_mod
	end
	return self:roll_item_list( self:get_item_table( params.level, weights, reqs ) )
end

function level:roll_items( params )
	local params = params or {}
	params.weights = params.weights or {}
	local result = {}
	local count  = params.count or 1
	for i=1,count do
		local id = self:roll_item( params )
		if id then
			params.weights[ id ] = 0
			table.insert( result, id )
		end
	end
	return result
end


function level:summon(t,opt)
	local count  = 1
	local where  = nil
	local cid    = nil
	local bid    = nil
	local empty  = { EF_NOBEINGS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }
	local safe   = 0
	local effect = nil
	if type(t) == "string" then 
		bid = t
		count = opt or 1
	elseif type(t) == "table" then 
		bid    = t.id or t[1]
		count  = t.count or t[2] or 1
		cid    = t.cell
		if cid then empty = { EF_NOBEINGS, EF_NOBLOCK } end
		where  = t.area
		empty  = t.empty or empty
		safe   = t.safe or 0
		effect = t.effect or nil
	else
		error( "Bad argument #1 passed to summon!" )
	end
	if not bid then 
		error( "Being id not defined for summon!" )
	end
	if count <= 0 then return nil end
	local last_being = nil
	local c
	for i=1,count or 1 do
		repeat
			if cid then
				c = level:random_empty_coord(empty, cid, where)
			else
				c = level:random_empty_coord(empty, where)
			end
		until ( safe == 0 ) or ( player:distance_to( c ) > safe )
		if c then
			last_being = self:drop_being( bid, c )
			if effect and last_being then
				level:explosion( c, effect )
			end
		end
	end
	return last_being
end

-- Overrides LuaMapNode API!
function level:drop(iid,count)
	if type(iid) == "string" then iid = items[iid].nid end
	local last_item = nil
	for i=1,count or 1 do
		last_item = self:drop_item(iid,level:random_empty_coord{ EF_NOITEMS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }, true, true, true )
	end
	return last_item
end

function level:area_drop(where,iid,count,onfloor,appear)
	if type(iid) == "string" then iid = items[iid].nid end
	onfloor = onfloor or false
	local last_item = nil
	for i=1,count or 1 do
		local pos = level:random_empty_coord( { EF_NOITEMS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }, where )
		if not pos then break end
		last_item = self:drop_item(iid,pos,onfloor,true,appear or false)
	end
	return last_item
end

function level:drop_item_ext( item, c )
	local id = item
	if type(id) == "table"  then id = id[1] end
	if type(id) == "string" then
		assert( items[id], "item "..id.." not defined!" ) 
		id = items[id].nid
	end
	local new_item = self:drop_item(id,c)
	if type(item) == "table" then
		for k,v in pairs(item) do
			if type(k) == "string" then
				new_item[k] = v
			end
		end
	end
	return new_item
end

function level:drop_being_ext( being, c )
	local id = being
	if type(id) == "table"  then id = id[1] end
	if type(id) == "string" then id = beings[id].nid end
	local new_being = self:drop_being(id,c)
	if type(being) == "table" then
		for k,v in pairs(being) do
			if type(k) == "string" then
				new_being[k] = v
			end
		end
	end
	return new_being
end

function level:try_destroy_item( coord )
	local item = self:get_item( coord )
	if item and not item.flags[ IF_UNIQUE ] and not item.flags[ IF_NODESTROY ] then item:destroy() end
end

function level:is_corpse( c )
	local cell = cells[ self.map[ c ] ]
	return cell.flags[ CF_CORPSE ]
end

function level:push_feature( who, what, c, target, quiet, stupid )
	local item_id = what.id
	local name    = what.name
	if not area.FULL:contains(target) then
		if not quiet then ui.msg( "It doesn't seem to move there." ) end
		self:play_sound( item_id .. ".movefail", c )
		return false
	end
	local target_cell_id = self.map[target]
	local target_cell    = cells[target_cell_id]
	if target_cell.flags[CF_HAZARD] then
		if stupid and not quiet then ui.msg( "Oh my, how stupid!" ) end
		self:play_sound( item_id .. ".move", c )
		level:damage_tile( c, 1000, DAMAGE_PLASMA )
		who.scount = who.scount - 1000
		return true
	end
	if target_cell.flags[CF_STAIRS] or target_cell.flags[CF_LIQUID]  then
		if not quiet then ui.msg( "It doesn't seem to move there." ) end
		self:play_sound( item_id .. ".movefail", c )
		return false
	end
	local item = level:get_item( target )
	if ( not level:is_empty( target, { EF_NOBLOCK, EF_NOBEINGS } ) ) or 
	( item and ( item.itype == ITEMTYPE_LEVER or item.itype == ITEMTYPE_TELE or item.itype == ITEMTYPE_FEATURE ) ) then
		if not quiet then ui.msg( "Something's blocking the "..name.."." ) end
		self:play_sound( item_id .. ".movefail", c )
		return false
	end
	self:play_sound( item_id .. ".move", c )
	if not quiet then ui.msg( "You push the "..name.."." ) end
	level:push_item( who, what, c, target )
	return true
end

function level:beings()
	return self:children("being")
end

function level:items()
	return self:children("item")
end

function level:beings_in_range( position, range )
	return self:children_in_range( position, range, ENTITY_BEING )
end

function level:items_in_range( position, range )
	return self:children_in_range( position, range, ENTITY_ITEM )
end

function level:drop_items( what )
	for i in what:children("item") do
		if i.itype == ITEMTYPE_RANGED and (not i.flags[ IF_NOUNLOAD ]) then
			local ammo = i.ammo
			i.ammo = 0
			local ia = self:drop_item( items[ i.ammoid ].id, what.position, true, true, true )
			ia.amount = ammo
		end
		self:drop_item( i, what.position, true, true, true )
	end
end


-- TODO: this depends on player having a proper propety registered!
level.data = setmetatable({}, {
	__newindex = function (_, k,v)
		local l = player.level_data[level.id]
		if not l then 
			player.level_data[level.id] = {}
			l = player.level_data[level.id]
		end
		l[k] = v
	end,
	__index = function (_, k)
		local l = player.level_data[level.id]
		if not l then 
			player.level_data[level.id] = {}
			l = player.level_data[level.id]
		end
		return l[k]
	end,
})

table.merge( level, game_object )
setmetatable( level, getmetatable(game_object) )
