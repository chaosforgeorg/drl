table.merge( being,thing )

being.items = thing.children

being.inv = {
	clear = function(self)
		for i in being.inv.items(self) do
			i:destroy()
		end
	end,
	add = function(self,it,params)
		if type(it) == "string" then it = item.new(it) end
		if params then
			for k,v in pairs(params) do
				it[k] = v
			end
		end
		return being.add_inv_item(self, it)
	end,
	size = function(self)
		local result = 0
		for i in being.inv.items(self) do
			result = result + 1
		end
		return result
	end,
	items = being.inv_items,
	empty = function(self)
		for i in being.inv.items(self) do
			return false
		end
		return true
	end,
	seek_ammo = function( self, ammo_nid )
		local ammo   = nil
		local acount = 65000
		for i in being.inv.items(self) do
			if i.itype == ITEMTYPE_AMMO then
				if i.nid == ammo_nid then
					if i.amount <= acount then
						ammo   = i
						acount = i.amount
					end
				end
			end
		end
		return ammo
	end,
	has = function( self, item_id ) 
		for i in being.inv.items(self) do
			if i.id == item_id then
				return true
			end
		end
		return false
	end,
}

setmetatable(being.inv, {
	__newindex = function (self, key, value)
	end,
	__index = function (self, key)
		if type(key) == "string" then
			local itemlist = {}

			--Return every item in the being's inventory with the given sid.
			for item in self:items() do
				if item.id == key then
					table.insert(itemlist, item)
				end
			end

			---@diagnostic disable-next-line: redundant-return-value, deprecated
			return unpack(itemlist)
		end
		return nil
	end,
})

being.ai = {
	__props = {},
}

setmetatable(being.ai, {
	__newindex = function (self, key, value)
		error("being.ai cannot be written to!")
	end,
	__index = function (self, key)
		assert( key ~= "ai_type", "being.ai.ai_type cannot be read!" )
		local this = core.to_object( self )
		return ais[ this.ai_type ].funcs[ key ]
	end,
})

being.eq =  {
	clear = function(self)
		for i=0,MAX_EQ_SIZE-1 do
			being["set_eq_item"]( self, i, nil )
		end
	end,
	empty = function(self)
		local i = -1
		while i < MAX_EQ_SIZE-1 do
			i = i + 1
			local item = being["get_eq_item"](self, i)
			if item then return false end
		end
		return true
	end,
	items = function(self)
		local i = -1
		return function ()
			while i < MAX_EQ_SIZE-1 do
				i = i + 1
				local item = being["get_eq_item"](self, i)
				if item then return item end
			end
		end
	end,

}

setmetatable(being.eq, {
	__newindex = function (self, key, value)
		if type(key) == "string" then key = _G["SLOT_"..string.upper(key)] end
		if type(value) == "string" then value = item.new(value) end
		being["set_eq_item"]( self, key, value )
	end,
	__index = function (self, key)
		if type(key) == "string" then key = _G["SLOT_"..string.upper(key)] end
		return being["get_eq_item"]( self, key )
	end,
})

function being:get_ammo_item( weapon )
	if ( not weapon ) then return nil end
	if weapon == self.eq.weapon and weapon.itype == ITEMTYPE_RANGED and
	  self.eq.prepared and 
	  self.eq.prepared.itype == ITEMTYPE_AMMOPACK and 
	  self.eq.prepared.ammoid == weapon.ammoid then
		return self.eq.prepared
	end
	return self.inv:seek_ammo( weapon.ammoid )
end

function being:flock_target( range, mind, maxd, parea )
	local pos     = self.position
	local id      = self.id
	local flock   = {}
	local closest = nil
	local cdist   = range*2

	for b in level:beings_in_range( pos, range ) do
		if b.id == id and b ~= self and self:in_sight( b ) then
			local c = b.position
			if closest then
				local dist = coord.distance( c, pos )
				if dist < cdist then
					closest = c
					cdist = dist
					if dist == 1 then break end
				end
			else
				closest = c
				cdist = coord.distance( c, pos )
			end
		end
	end

	if closest then
		if cdist >= maxd then
			return closest
		elseif cdist <= mind then
			closest = 2*pos - closest
			area.FULL:clamp_coord(closest)
			if ( not level:get_being(closest) ) or ( not level:is_passable( closest ) ) then
				return closest
			end
		end
	end

	local scan = parea or area.around( pos, range ):clamped( area.FULL )
	return scan:random_coord()
end

function being:msg( msg_player, msg_being )
	if self:is_player() then
		if msg_player then
			ui.msg( msg_player )
		end
	elseif msg_being then
		if self:is_visible() then
			ui.msg( msg_being )
		end
	end
end

function being:phase( cell )
	local target
	if self:is_player() then 
		target = level:random_empty_coord( { EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOLIQUID, EF_NOSPAWN, EF_CANTELE }, level.data.phase_zone )
	else
		target = level:random_empty_coord( { EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN, EF_CANTELE }, level.data.phase_zone )
	end
	if not target then
		target = level:random_empty_coord( { EF_NOBEINGS, EF_NOBLOCK, EF_NOSPAWN, EF_CANTELE }, level.data.phase_zone )
	end
	if cell then
		cell = cells[ cell ].nid
		local targets = {}
		for c in ( level.data.phase_zone or area.FULL_SHRINKED)() do
			if level:get_cell( c ) == cell then
				table.insert( targets, c:clone() )
			end
		end
		if #targets ~= 0 then
			target = level:drop_coord( table.random_pick( targets ), {EF_NOITEMS,EF_NOBEINGS,EF_NOBLOCK,EF_CANTELE}  )
		end
	end
	if target then
		self:relocate( target )
	end
end

function being:spawn( monster )
	local b = level:drop_being( monster, self.position )
	if b then
		b.flags[ BF_NOEXP ] = true
		b.scount = 2900 + math.random( 200 )
	end
end

function being:act( coord )
	local id = level.map[ coord ]
	if not cells[ id ].OnAct then return false end
	return cells[ id ].OnAct( coord.x, coord.y, self )
end

function being:eye_contact( other )
	return level:eye_contact( self, other )
end

function being:in_sight( other )
	local corner_shooting = true
	if other == player then
		if corner_shooting then
			return self:distance_to( other ) <= self.vision and level:eye_contact( self, other ) and ( not player.flags[ BF_INVISIBLE ] )
		else
			return self:is_visible() and self:distance_to( other ) <= self.vision
		end
	else
		return self:distance_to( other ) <= self.vision and level:eye_contact( self, other )
	end
end

function being:is_player()
	return self.__ptr == player.__ptr
end

function being:set_items( set )
	local result = 0
	for i in self.eq:items() do
		if i.__proto.set == set then result = result + 1 end
	end
	return result
end

function being:nuke( time )
	player.nuketime = time or 1
	if not cells[ level.map[ self.position ] ].flags[ CF_CRITICAL ] then
		if cells.nukecell.sprite > 0 then
			level.map[ self.position ] = 'nukecell'
		end
	end
end

function being:pick_item_to_mod( mod, filter )
	if not self:is_player() then return nil end

	local proto     = mod.__proto
	local modletter = proto.mod_letter
	local techbonus = self.techbonus

	local choice = {
		title = "Choose an item to mod",
		entries = {},
		cancel = -1,
	}

	for i = 0,MAX_EQ_SIZE-1 do
		local it = player.eq[i]
		if it and it.itype ~= ITEMTYPE_AMMOPACK then
			local desc
			local ma = it:find_mod_array( modletter, techbonus )
			if ma or ( ( not filter ) or filter(it) ) then
				local cm = it:can_mod( modletter, techbonus )
				if (not ma) and ( not cm ) then
					desc = "Max level of this mod reached!"
				else
					if cm and proto.OnModDescribe then
						desc = "Effect : "..proto.OnModDescribe( mod, it )
					end
					if ma then
						desc = desc or ""
						desc = desc.."\nAssembly possible : {!"..ma.name.."}"
					end
				end
				table.insert( choice.entries, { name = it.desc, value = i, desc = desc } )
			end
		end
	end

	if #choice.entries == 0 then
		ui.msg( "You have no suitable items to modify!" )
		return nil, false
	end

	local slot = ui.choice( choice )
	if slot == -1 then return nil, false end
	local item = player.eq[slot]
	local ma   = item:find_mod_array( modletter, techbonus )
	if ma then
		local entries = {
			{ name = "Assemble "..ma.name, value = 2 },
			{ name = "Apply mod normally", value = 1 },
			{ name = "Cancel", value = -1 },
		}
		if filter and not filter(item) then
			entries = {
				{ name = "Assemble "..ma.name, value = 2 },
				{ name = "Cancel", value = -1 },
			}
		end

		local ma_choice = {
			title = "Special assembly possible!",
			header = "Do you want to assemble the {!"..ma.name.."}?",
			entries = entries,
			cancel = -1,
		}
		local result = ui.choice( ma_choice )
		if result == -1 then return nil, false end
		if result == 2 then
			ui.msg("You assemble the "..ma.name..".")
			item:apply_mod_array( ma )
			return nil, true
		end
	end
	if not item:can_mod( modletter, techbonus ) then
		ui.msg( "This item can't be modified anymore with this mod!" )
		return nil, false
	end
	return item, true
end

function being:apply_timed_perk( id, max_duration, resist )
	if resist and self.resist and self.resist[ resist ] then
		local rvalue = self.resist[ resist ]
		if rvalue > 0 then
			max_duration = math.floor( max_duration * ( 1 - rvalue / 100 ) )
		end
		if max_duration <= 0 then
			return false
		end
	end
	local current = self:get_perk_time( id )
	if current > 0 then
		if current < max_duration then
			self:add_perk( id, max_duration - current )
		end
	else
		self:add_perk( id, max_duration )
	end
	return true
end

function being:full_reload( weapon )
	if not weapon then return false end
	local is_player = self:is_player()
	if weapon.ammo == weapon.ammomax then
		if is_player then
			ui.msg("Your "..weapon.name.." is already fully loaded.")
		end
		return false
	end
	if weapon:has_property( "chamber_empty" ) then weapon.chamber_empty = false end
	local ammo = self:get_ammo_item( weapon )
	if not ammo then
		if is_player then
			ui.msg("You have no more ammo for the "..weapon.name.."!")
		end
		return false
	end
	local pack = ammo.itype == ITEMTYPE_AMMOPACK
	while weapon.ammo < weapon.ammomax do
		if not ammo then ammo = self:get_ammo_item( weapon ) end
		if not ammo then
			if is_player then
				ui.msg("You have no more ammo for the "..weapon.name.."!")
			end
			return false
		end
		self:reload( ammo, true, true )
		ammo = nil
	end
	self:msg("You "..core.iif(pack,"quickly ","").."fully load the "..weapon.name..".", self:get_name( true, true ).." fully loads the "..weapon.name..".")
	return true

end


setmetatable(being,getmetatable(thing))
