-- General definitions:
-- idle - being is not doing anything in particular (wander)
-- hunt - being is attacking a visible target
-- pursue - being is seaching a not visible target

aitk = {}

function aitk.OnAction( self )
	local safe = 0
	repeat
		local ai        = ais[ self.ai_type ]
		local old_state = self.ai_state
		local new_state = ai.states[ old_state ]( self ) or old_state
		if not core.is_playing() then return end -- gracefully exit if being kills player
		if not self.__ptr then return end -- gracefully exit if being dies
		self.ai_state = new_state
		safe = safe + 1
	until self.scount < 5000 or safe > 1000
	if safe > 1000 then
		error( "AI : "..ais[ self.ai_type ].id.." entered infinite loop!" )
	end
end

function aitk.get_patrol_area( self, range, can_wander )
    if not self.patrol_area then
        if can_wander and (not self:has_property("GROUPED")) and ( math.random(2) == 1 ) then
            self.patrol_area = area.FULL_SHRINKED
        else
            self.patrol_area = area.around( self.position, range ):clamped( area.FULL )
        end
    end
    return self.patrol_area
end

function aitk.scan( self )
    if self.flags[ BF_FRIENDLY ] then
        local dist   = self.vision+1
        local target = nil
        for b in level:beings_in_range( self, self.vision ) do
            if b ~= player and ( not b.flags[ BF_FRIENDLY ] ) then
                local d = self:distance_to( b )
                if self:in_sight( b ) and d < dist then
                    target = b
                    dist   = d
                end
            end
        end
        if target then
            return target.uid
        end            
    else
        local visible = self:in_sight( player )
        if visible then
            return player.uid
        end
        return false
    end
end

function aitk.move_path( self, reattempt )
    local move_check, move_coord = self:path_next()
    if move_check ~= MOVEOK and (move_check ~= MOVEDOOR or (not self.flags[BF_OPENDOORS])) then
        -- try another attempt
        if reattempt and self:path_find( reattempt, 10, 40 ) then
            move_check, move_coord = aitk.move_path( self )
            if move_check then
                return true, move_coord
            end
        end
        return false, nil
    end
    return true, move_coord
end


-- aitk.flock_seek( self, target )
--  * self - being
--  * target - coord
-- direct_seek the target coord. If not possible, seek a coord around
-- self that is closer to the target.
function aitk.flock_seek( self, target )
    if self:direct_seek( target ) == MOVEOK then 
        return true
    end

    local moves = {}
    local dist = self:distance_to( target )
    for c in self.position:around_coords() do
        if coord.distance(c,target) < dist and level:is_empty( c, { EF_NOBEINGS, EF_NOBLOCK } ) then
            table.insert( moves,c:clone() )
        end
    end

    while #moves > 0 do
        if self:direct_seek( table.random_remove( moves ) ) == MOVEOK then
            return true
        end
    end
    return false
end

function aitk.flock_init( self, flock_min, flock_max )
    self:add_property( "ai_state", "idle" )
    self:add_property( "boredom", 6 )
    self:add_property( "flock_min", flock_min or 1 )
    self:add_property( "flock_max", flock_max or 4 )
    self:add_property( "move_to", false )
    self:add_property( "target", false )
    self:add_property( "patrol_area", false )
end

function aitk.flock_on_attacked( self, target )
    if self == target then return end
    if target and target:has_property("master") then return end
    local target = target or uids.get( self.target )
    for b in level:beings_in_range( self, self.flock_max or 4 ) do
        if b.id == self.id then
            if target then
                b.target   = target.uid
            end
            b.boredom  = 0
            b.ai_state = "hunt"
        end
    end
end

function aitk.flock_scan( self )
    self.target = aitk.scan( self )
    if self.target then
        aitk.flock_on_attacked( self, uids.get( self.target ) )
        return true
    end
    return false
end

function aitk.flock_idle( self )
    if aitk.flock_scan( self ) then
        return "hunt"
    end

    if self.flags[ BF_HUNTING ] then
        self.target  = player.uid
        self.boredom = 0
        return "hunt"
    end

    if math.random(30) == 1 then
        self:play_sound( "act" )
    end
    if not self.move_to then
        self.move_to = self:flock_target( self.vision, self.flock_min or 1, self.flock_max or 4, aitk.get_patrol_area( self, 9 ) )
    end

    if not cells[ level.map[self.move_to] ].flags[ CF_HAZARD ] or self.flags[ BF_ENVIROSAFE ] == true then
        if self:direct_seek( self.move_to ) ~= MOVEOK then
            self.scount =  self.scount - 500
            self.move_to = false
            return "idle"
        end
    else
        self.scount =  self.scount - 500
        self.move_to = false
        return "idle"
    end

    if self:distance_to( self.move_to ) == 0 then
        self.move_to = false
    end
    return "idle"
end

function aitk.flock_hunt( self )
    if not self.target then return "idle" end
    local target = uids.get( self.target )
    if not target then
        self.target = false
        return "idle"
    end
    local visible = self:in_sight( target )
    if not visible then
        self.boredom = self.boredom + 1
        if self.boredom > 8 then
            self.target = false
            return "idle"
        end
    else
        self.boredom = 0
    end
    local dist = self:distance_to( target )
    if dist == 1 then
        self:attack( target )
        return "hunt"
    end
    if not aitk.flock_seek( self, target.position ) then
        self.scount = self.scount - 500
    end
    return "hunt"
end

function aitk.try_heal_item( self )
    local item
    for i in self.inv:items() do
		if i and i.flags[ IF_AIHEALPACK ] then
            item = i
			break
		end
	end
    if item then
        self:use( item )
        self.scount = self.scount - 1000
        return true
    end
	return false
end

-- aitk.ammo_check( self )
-- returns has_ammo, needs reload
-- * has_ammo - entity has a weapon with ammo available
-- * needs_reload - entity needs to reload to fire
function aitk.ammo_check( self )
    if self.eq.weapon == nil then return false, false end
    local w = self.eq.weapon
    if w.flags[ IF_NOAMMO ] then return true, false end
    if w.ammo >= math.max( w.shotcost, 1 ) then 
        if w:has_property("pump_action") and w.chamber_empty then return true, true end
        return true, false 
    end
    if self.inv[ items[w.ammoid].id ] then return true, true end
    return false, false
end

-- aitk.inventory_check( self, can_reload )
-- returns action_performed, has_ammo
-- * action_performed - entity has performed an action
-- * has_ammo - entity has a weapon with ammo available
function aitk.inventory_check( self, can_reload )
    local has_ammo, needs_reload = aitk.ammo_check( self )
    if needs_reload and can_reload then
        if self:action_reload() then
            return true, true
        else
            has_ammo = false
        end
    end

    if self.hp < self.hpmax / 2 and aitk.try_heal_item( self ) then
        return true, has_ammo
    end    

    return false, has_ammo
end

function aitk.basic_init( self, use_packs, use_armor )
    self:add_property( "ai_state", "idle" )
    self:add_property( "boredom", 0 )
    self:add_property( "move_to", false )
    self:add_property( "target", false )
    self:add_property( "use_packs", use_packs or false )
    self:add_property( "use_armor", use_armor or false )
    self:add_property( "attackchance", math.min( self.__proto.attackchance * diff[DIFFICULTY].speed, 90 ) )
    self:add_property( "retaliate", false )
    self:add_property( "patrol_area", false )
    self:add_property( "nomelee", false )
end

function aitk.basic_scan( self )
    if self.target then
        local being = uids.get( self.target )
        if being then
            if self:in_sight( being ) then
                return self.target
            end
        else
            self.target = false
        end
    end
    local target = aitk.scan( self )
    if target then self.target = target end
    return target 
end

-- aitk.basic_pursue( self )
-- returns next_state
-- needs a valid set self.move_to
function aitk.basic_pursue( self )
    if aitk.basic_scan( self ) then
        self.move_to = false
        return "hunt"
    end
    if ( not self.move_to ) or self:distance_to( self.move_to ) == 0 then
        self.scount = self.scount - 200
        return "idle"
    end
    local move_check = aitk.move_path( self, self.move_to )
    if aitk.basic_scan( self ) then
        self.move_to = false
        return "hunt"
    end
    if math.random(30) == 1 then self:play_sound( "act" ) end
    if not move_check then
        self.scount = self.scount - 200
        return "idle"
    end
    if self:has_property("boredom") then
        self.boredom = self.boredom + 1
        if self.boredom > 8 then
            return "idle"
        end
    end
    return "pursue"
end

-- aitk.basic_idle( self )
-- returns next_state
function aitk.basic_idle( self )
    if aitk.basic_scan( self ) then
        self.move_to = false
        return "hunt"
    end
    if self.flags[ BF_HUNTING ] then
        self.target  = player.uid
        self.boredom = 0
        return "hunt"
    end
	if math.random(30) == 1 then
		self:play_sound( "act" )
	end
    if self.move_to then
        if self:distance_to( self.move_to ) > 0 then
            if self:direct_seek( self.move_to ) == MOVEOK then
                return "idle"
            end
        end
        self.scount = self.scount - 500
    end
    self.move_to = aitk.get_patrol_area( self, 5, true ):random_coord()
	return "idle"
end

function aitk.basic_on_attacked( self, target )
    if self == target then return end
    if self:has_property("boredom") then self.boredom = 0 end
    if target then 
        if target:has_property("master") then return end
        if target.id == self.id then return end
        if self.flags[ BF_FRIENDLY ] and target == player then return end
        self.target = target.uid
        if self.ai_state == "idle" or ( self.ai_state == "pursue" and self.move_to ~= target.position ) then
            self.move_to = target.position
            self:path_find( self.move_to, 10, 40 )
            self.ai_state = "pursue"
        end
    end
end

-- aitk.basic_smart_idle( self )
-- returns next_state
function aitk.basic_smart_idle( self )
    if aitk.basic_scan( self ) then
        self.move_to = false
        return "hunt"
    end
	if self.flags[ BF_HUNTING ] then
        if self:has_property("boredom") then self.boredom = 0 end
		self.move_to = player.position
        self.target  = player.uid
		self:path_find( self.move_to, 10, 40 )
		return "pursue"
	end
	if math.random(30) == 1 then
		self:play_sound( "act" )
	end
    if self.move_to then
        if self:distance_to( self.move_to ) == 0 then
            local use_armor = self.use_armor
            local use_packs = self.use_packs
            if use_armor or use_packs then
                if self.inv:size() < MAX_INV_SIZE then
                    local item = level:get_item( self.move_to )
                    if item and ( ( use_packs and item.flags[ IF_AIHEALPACK ] ) or 
                                ( use_armor and item.itype == ITEMTYPE_ARMOR and not self.eq.armor ) ) then
                        local is_armor = item.itype == ITEMTYPE_ARMOR
                        self:pickup( self.move_to, true )
                        if is_armor then
                            self:wear( item )
                        end
                    end
                end
            end
            self.move_to = false
        else
            if not aitk.move_path( self, self.move_to ) then
                self.move_to = false
                self.scount = self.scount - 500
            end
        end
    end

    if not self.move_to then
        if aitk.inventory_check( self, true ) then
            return "idle"
        end
        local move_dist = self.vision+1
        local next_move
        local use_armor = self.use_armor
        local use_packs = self.use_packs
        if use_armor or use_packs then
            if not (self.inv:size() >= MAX_INV_SIZE) then
                for item in level:items_in_range( self, self.vision ) do
                    if ( (use_packs and item.flags[ IF_AIHEALPACK ] ) 
                      or (use_armor and item.itype == ITEMTYPE_ARMOR and not self.eq.armor ) ) 
                      and self:in_sight( item ) then
                        local item_dist = self:distance_to( item )
                        if item_dist < move_dist then
                            move_dist = item_dist
                            next_move = item.position
                        end
                    end
                end
            end
        end
        if not next_move then
            next_move = aitk.get_patrol_area( self, 5, true ):random_coord()
        end
        if next_move then
            self.move_to = next_move
            if next_move == self.position then
                self.scount = self.scount - 500
                return "idle"
            end
            if not self:path_find( self.move_to, 10, 40 ) then
                self.scount = self.scount - 1000
                self.move_to = false
            end
        end
    end
	return "idle"
end

function aitk.try_hunt( self )
    if not self.target then return "idle" end
    local target = uids.get( self.target )
    if not target then
        self.target = false
        return "idle"
    end
    local dist    = self:distance_to( target )
    local visible = self:in_sight( target )
    local action, has_ammo = aitk.inventory_check( self, dist > 1 )
    if action then return "hunt" end
    local attackchance = self.attackchance
    if not visible then
        if self:has_property("sneakshot") and dist <= self.vision then 
            attackchance = math.floor( attackchance / 2 )
        else
            if self:has_property("boredom")    then self.boredom = 0 end
            if self:has_property("sequence")   then self.sequence = 0 end
            self.move_to = target.position
            self:path_find( self.move_to, 10, 40 )
            return "pursue"
        end
    end

    local sequence   = 0
    local sequential = nil
    if self:has_property("sequential") then
        sequential = self.sequential
        sequence   = self.sequence
        if sequence == 1 then
            self.sequence = -1
        elseif sequence > 1 or sequence < 0 then
            self.sequence = sequence - 1
            if sequence < -sequential[3] then
                self.sequence = 0
                sequence = 0
            end
        end
    end
    if self.retaliate then attackchance = 100 end
    if self:has_property("attackrange") and self.attackrange < dist then
        attackchance = math.floor( attackchance / 3 )
    end
    if dist == 1 and (not self.nomelee) then
        if sequential then self.sequence = 0 end
        self:attack( target )
        return "hunt"
    elseif has_ammo and sequence >= 0 and ( sequence > 0 or ( math.random(100) <= attackchance ) ) then
        self.retaliate = false
        if self:has_property("on_fire") then
            return self.on_fire
        end
        if sequence == 0 and sequential then
            self.sequence = core.resolve_range( sequential )
        end 
        self:action_fire( target, self.eq.weapon )
        return "hunt"
    end

    if math.random(30) == 1 then self:play_sound( "act" ) end

    return false, dist, target
end

function aitk.evade_hunt( self )
    local action, dist, target = aitk.try_hunt( self )
    if action then return action end

    if self.move_to then
        if self:distance_to( self.move_to ) == 0 then
            self.move_to = false
        else
            if not aitk.move_path( self, self.move_to ) then
                self.move_to = false
            end
            if self.move_to then
                return "hunt"
            end
        end
    end

    -- self.move_to is false
    local s = self.position
    local t = target.position
    local walk
    if dist < 4 then
        walk = s + (s - t)
        area.FULL:clamp_coord( walk )
        if coord.distance( t, s ) >= coord.distance( t, walk ) then
            walk = area.around( s, 1 ):random_edge_coord()
        end
    else
        local v = s - t
        walk = table.random_pick{ t+coord( -v.y, v.x ), t+coord( v.y, -v.x ) }
    end
    area.FULL:clamp_coord( walk )
    self.move_to = walk
    if not self:path_find( self.move_to, 10, 40 ) or ( not aitk.move_path( self ) ) then
        self.scount  = self.scount - 500
        self.move_to = false
        core.log('path fail')
    end
    return "hunt"
end

function aitk.pursue_hunt( self )
    local action, dist, target = aitk.try_hunt( self )
    if action then return action end

    if self.move_to == target.position then
        if aitk.move_path( self, self.move_to ) then
            return "hunt"
        end
    end
    self.move_to = target.position

    if not self:path_find( self.move_to, 10, 40 ) or ( not aitk.move_path( self ) ) then
        self.move_to = false
        if not aitk.flock_seek( self, target.position ) then
            self.scount = self.scount - 1000
        end
    end
    return "hunt"
end

function aitk.ranged_hunt( self )
    local action, dist, target = aitk.try_hunt( self )
    if action then return action end

    local target = target.position
    if dist < 6 and math.random(3) > 1 then
        for _=1,3 do
            local c = area.around( self.position, 1 ):clamped( area.FULL ):random_coord() 
            if level:is_passable( c ) then
                target = c
                break
            end
        end
    end

    if self.move_to == target then
        if aitk.move_path( self, self.move_to ) then
            return "hunt"
        end
    end
    self.move_to = target
    if not self:path_find( self.move_to, 10, 40 ) or ( not aitk.move_path( self ) ) then
        self.move_to = false
        self.scount  = self.scount - 1000
    end
    return "hunt"
end

function aitk.charge_init( self, charge_time )
    self:add_property( "ai_state", "idle" )
    self:add_property( "move_to_target", false )
    self:add_property( "move_to", false )
    self:add_property( "target", false )
    self:add_property( "attackchance", math.min( self.__proto.attackchance * diff[DIFFICULTY].speed, 90 ) )
    self:add_property( "chargetime", charge_time or 30 )
    self:add_property( "basetime", self.movetime )
    self:add_property( "patrol_area", false )
end

function aitk.charge_on_attacked( self, target )
    if self == target then return end
    if self.ai_state == "idle" and target then
        self.target   = target.uid
        self.move_to  = target.position
        self.ai_state = "pursue"
    elseif self.ai_state == "post_charge" then
        self.movetime = self.basetime
        self.ai_state = "idle"
    end
end

function aitk.charge_idle( self )
    if aitk.basic_scan( self ) and self.attackchance <= math.random(100) then
        self.movetime = self.chargetime
        self.move_to_target = player.position
        local v  = player.position - self.position
        local mt = player.position + v
        if self:distance_to( player.position ) < 6  then
            mt = mt + v
        end
        self.move_to        = mt
        return "charge"
    end

    if self.flags[ BF_HUNTING ] then
        self.target  = player.uid
        self.move_to = player.position
        return "pursue"
    end

	if math.random(30) == 1 then
		self:play_sound( "act" )
	end
    if self.move_to then
        if self:distance_to( self.move_to ) > 0 then
            if self:direct_seek( self.move_to ) == MOVEOK then
                return "idle"
            end
        end
        self.scount = self.scount - 500
    end
    self.move_to = aitk.get_patrol_area( self, 7, true ):random_coord()
	return "idle"
end

function aitk.charge_charge( self )
    local move_check,move_coord = self:direct_seek( self.move_to_target, 1.5 )
    if move_check ~= MOVEOK then
        if player.position == move_coord then
            self:attack( move_coord )
       		if ( not core.is_playing() ) or ( not self.__ptr ) then return "idle" end 
        else
            self.scount = self.scount - 500
        end
        self.move_to = false
        self.movetime = self.basetime
        return "idle"
    else
        if move_coord == self.move_to_target then
            return "post_charge"
        end
    end
    return "charge"
end

function aitk.charge_post_charge( self )
    local move_check,move_coord = self:direct_seek( self.move_to, 2.0 )
    if move_check ~= MOVEOK then
        if player.position == move_coord then
            self:attack( move_coord )
       		if ( not core.is_playing() ) or ( not self.__ptr ) then return "idle" end 
        else
            self.scount = self.scount - 500
        end
        self.move_to = false
        self.movetime = self.basetime
        return "idle"
    else
        if move_coord == self.move_to then
            self.scount = self.scount - 500
            self.move_to = false
            self.movetime = self.basetime
            return "idle"
        end
    end
    return "post_charge"
end

function aitk.wait( self )
    self.scount = self.scount - 1000
    if aitk.basic_scan( self ) or self.flags[BF_HUNTING] then
        return "hunt"
    end
	return "wait"
end

function aitk.follow_player_idle( self )
    if aitk.basic_scan( self ) then
        self.move_to = false
        return "hunt"
    end
	if math.random(30) == 1 then
		self:play_sound( "act" )
	end
    if self.move_to then
        if self:distance_to( self.move_to ) == 0 then
            self.move_to = false
        else
            if not aitk.move_path( self, self.move_to ) then
                self.move_to = false
                self.scount  = self.scount - 500
            end
        end
    end

    if not self.move_to then
        local patrol_area = area.around( player.position, 3 ):clamped( area.FULL )
        local next_move   = patrol_area:random_coord()
        if next_move then
            self.move_to = next_move
            if not self:path_find( self.move_to, 10, 40 ) then
                self.scount  = self.scount - 1000
                self.move_to = false
            end
        end
    end
	return "idle"
end
