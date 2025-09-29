register_ai "smart_evasive_ai"
{

	OnCreate = function( self )
		aitk.basic_init( self, true, true )
	end,

	OnAttacked = aitk.basic_on_attacked, 
	states = {
		idle   = aitk.basic_smart_idle,
		pursue = aitk.basic_pursue,
		hunt   = aitk.evade_hunt,
	}
}

register_ai "smart_hybrid_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, true, true )
	end,

	OnAttacked = aitk.basic_on_attacked, 
	states = {
		idle   = aitk.basic_smart_idle,
		pursue = aitk.basic_pursue,
		hunt   = aitk.pursue_hunt,
	}
}

register_ai "charger_ai"
{
	OnCreate = function( self )
		aitk.charge_init( self, 30 )
	end,
	OnAttacked = aitk.charge_on_attacked,
	states = {
		idle        = aitk.charge_idle,
		hunt        = aitk.charge_idle,
		pursue      = aitk.basic_pursue,
		charge      = aitk.charge_charge,
		post_charge = aitk.charge_post_charge,
	}
}

register_ai "flock_ai"
{

	OnCreate = function( self )
		aitk.flock_init( self, 1, 4 )
	end,

	OnAttacked = aitk.flock_on_attacked,
	states = {
		idle = aitk.flock_idle,
		hunt = aitk.flock_hunt,
	}
}

register_ai "melee_ranged_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, false, false )
	end,

	OnAttacked = aitk.basic_on_attacked,
	states = {
		idle   = aitk.basic_smart_idle,
		pursue = aitk.basic_pursue,
		hunt   = aitk.pursue_hunt,
	}
}

register_ai "ranged_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, false, false )
	end,

	OnAttacked = aitk.basic_on_attacked,
	states = {
		idle   = aitk.basic_smart_idle,
		pursue = aitk.basic_pursue,
		hunt   = aitk.ranged_hunt,
	}
}

register_ai "sequential_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, false, false )
		self:add_property( "sequential", {3,5,3} )
		self:add_property( "sequence", 0 )
	end,

	OnAttacked = aitk.basic_on_attacked,
	states = {
		idle   = aitk.basic_smart_idle,
		pursue = aitk.basic_pursue,
		hunt   = aitk.ranged_hunt,
	}
}

register_ai "archvile_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, false, false )
		self:add_property( "attack_to", false )
		self:add_property( "on_fire", "on_fire" )
	end,

	OnAttacked = aitk.basic_on_attacked,

	funcs = {
		resurrect = function( self )
			if math.random(4) == 1 then
				local b = self:resurrect(6)
				if b then
					self:msg("", self:get_name(true,true).. " raises his arms!" )
					b:msg("", b:get_name(true,true).." suddenly rises from the ground!" )
				end
				self.scount = self.scount - 1000
				return true
			end
			return false
		end
	},

	states = {
		idle   = function ( self )
			if self.ai.resurrect( self ) then return "idle" end
			return aitk.basic_smart_idle( self )
		end,
		pursue = function ( self )
			if self.ai.resurrect( self ) then return "pursue" end
			return aitk.basic_pursue( self )
		end,
		hunt   = function( self )
			if self.ai.resurrect( self ) then return "hunt" end
			local action, dist, target = aitk.try_hunt( self )
			if action then return action end
		
			local target = target.position
			if dist < 4  then
				local pos = self.position
				target = pos + (pos - target)
				area.FULL:clamp_coord( target )
			end
			if self.move_to == target then
				if aitk.move_path( self ) then
					return "hunt"
				end
			end
			self.move_to = target
			if not self:path_find( self.move_to, 10, 40 ) or ( not aitk.move_path( self ) ) then
				self.move_to = false
				self.scount  = self.scount - 1000
			end
			return "hunt"
		end,
		on_fire = function( self )
			local target = uids.get( self.target )
			if not target then return "idle" end
			self.attack_to = target.position
			self:msg("", "The " .. self.name .. " raises his arms!" )
			self.scount = self.scount - 2500
			return "fire"
		end,
		fire = function( self )
			local target = uids.get( self.target )
			if target and self:in_sight( target ) then
				self:action_fire( target.position, self.eq.weapon )
			else
				self:action_fire( self.attack_to, self.eq.weapon )
			end
			return "hunt"
		end,
	}
}

register_ai "spawner_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, false, false )
		self:add_property( "sequential", {3,5,3} )
		self:add_property( "sequence", 0 )
		self:add_property( "spawnchance", 25 )
		self:add_property( "spawnlist", false )
	end,

	OnAttacked = function( self, target )
		self.boredom = 0
	end,

	states = {
		idle   = aitk.basic_idle,
		pursue = function( self )
			if ais[ self.ai_type ].states.try_spawn( self ) then 
				return "pursue"
			end
			return aitk.basic_pursue( self )
		end,
		hunt   = function( self )
			if ais[ self.ai_type ].states.try_spawn( self ) then 
				return "hunt"
			end
			local target = player.position
			local dist   = self:distance_to( player )
			if dist < 4  then
				local pos = self.position
				target = pos + (pos - target)
				area.FULL:clamp_coord( target )
			end
			if self:direct_seek( target ) ~= MOVEOK then
				self.scount  = self.scount - 1000
			end
			return "hunt"
		end,
		try_spawn = function( self )
			if self.spawnlist and self.boredom < 4 and math.random(100) <= self.spawnchance then
				local list = self.spawnlist
				if not list.name then
					list = list[ math.random(#list) ]
				end
				local whom = list.name
				local num  = list.count
				for c=1,num do
					self:spawn(whom)
				end
				local spawnname = "a "..beings[whom].name
				if num > 1 then
					spawnname = beings[whom].name_plural
				end
				self:msg("", "The "..self.name.." spawns "..spawnname.."!")
				self.scount  = self.scount - 1000
				self.boredom = self.boredom + 1
				return true
			end
			return false
		end,
	}
}

-- BOSS AIs -------------------------------------------------------------

register_ai "angel_ai"
{

	OnCreate = function( self )
		self:add_property( "ai_state", "wait" )
		self:add_property( "move_to", false )
	end,

	OnAttacked = function( self )
		self.flags[BF_HUNTING] = true
	end,

	states = {
		wait = function( self )
			if self:in_sight( player ) or self.flags[BF_HUNTING] then return "hunt" end
			self.scount = self.scount - 1000
			return "wait"
		end,
		hunt = function( self )
			local target  = player
			local dist    = self:distance_to( target )
			local visible = self:in_sight( target )

			if math.random(30) == 1 then
				self:play_sound( "act" )
			end

			if dist == 1 then
				self:attack( player )
				return "hunt"
			end

			if self.move_to == target.position then
				if aitk.move_path( self ) then
					return "hunt"
				end
			end
			self.move_to = target.position
			if not self:path_find( self.move_to, 20, 50 ) or ( not aitk.move_path( self ) ) then
				self.move_to = false
				if not aitk.flock_seek( self, target.position ) then
					self.scount = self.scount - 1000
				end
			end
			return "hunt"
		end,
	}
}

register_ai "cyberdemon_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, true, true )
		self:add_property( "is_boss", false )
		self:add_property( "sneakshot", true )
		self:add_property( "ammo_regen", 0 )
		self:add_property( "timer", 0 )
	end,

	OnAttacked = function( self ) 
		aitk.basic_on_attacked( self )
		self.retaliate = true
	end,

	states = {
		idle   = function( self ) 
			if self.is_boss then
				self.timer = self.timer + 1
				if self.timer % 20 == 0 then self:play_sound( "act" ) end
				if self.timer > 20 then
					self.flags[ BF_HUNTING ] = true
					self.target  = player.uid
					self.move_to = player.position
					self:path_find( self.move_to, 40, 100 )
					return "pursue"
				end
			end
			ais[ self.ai_type ].states.tick( self )
			return aitk.basic_smart_idle( self )
		end,
		pursue = function( self ) 
			ais[ self.ai_type ].states.tick( self )
			return aitk.basic_pursue( self ) 
		end,
		hunt   = function( self ) 
			ais[ self.ai_type ].states.tick( self )
			return aitk.pursue_hunt( self )
		end,
		tick   = function( self )
			if not self.inv[ "rocket" ] then
				self.ammo_regen = self.ammo_regen + 1
				if self.ammo_regen > 7 then
					self.ammo_regen = 0
					self.inv:add("rocket")
					self.inv:add("rocket")
				end
			end
		end,
	}

}

register_ai "jc_ai"
{

	OnCreate = function( self )
		aitk.basic_init( self, false, false )
		self:add_property( "attacked", false )
		self.ai_state = "wait"
	end,

	OnAttacked = function( self )
		self.attacked = true
		if self.ai_state == "wait" then
			if not self:in_sight( player ) then
				local surround = area.around(player.position,7):clamped( area.FULL_SHRINKED )
				level:summon{ "baron", 6, area = surround }
				ui.msg("A voice bellows: \"Don't think you can surprise me!\"")
			end
			self.ai_state = "hunt"
		end
	end,

	states = {
		wait = aitk.wait,
		hunt = function( self )
			self.target = player.uid
			local target  = player
			local dist    = self:distance_to( target )
			local visible = self:in_sight( target )
			local action, has_ammo = aitk.inventory_check( self, dist > 1 )
			if action then return "hunt" end
		
			if self.attacked and math.random(3) == 1 then
				self.attacked = false
				local tp  = area.around( self.position, 10 ):clamped( area.FULL_SHRINKED ):random_coord()
				local mob = level:get_being( tp )
				if mob then
					if mob:is_player() or mob == self then
						return "hunt"
					else
						mob:kill()
					end
				end
				self:play_sound("phasing")
				level:explosion( self.position, { range = 2, delay = 50, color = LIGHTBLUE } )
				self:relocate( tp )
				level:explosion( self.position, { range = 4, delay = 50, color = LIGHTBLUE } )
				self.scount = self.scount - 1000
				return "hunt"
			end
	
			if (not has_ammo) or (visible and math.random(4) == 1) or (not visible and math.random(8) == 1) then
				local idx = math.max( math.min( 5 - math.floor((self.hp / self.hpmax) * 5), 5 ), 1 )
				if self.hp > self.hpmax then idx = 6 end
				local whom = { "lostsoul", "cacodemon", "knight", "baron", "revenant" , "mancubus" }
				for c=1,8 do self:spawn( whom[idx] ) end
				if self:is_visible() then
					self:msg("","Carmack raises his hands and summons hellspawn!")
				end
				self.scount = self.scount - 2000
				return "hunt"
			end

			if has_ammo then
				local shoot = true
				if not self.attacked then
					if visible then
						shoot = math.random(100) <= self.attackchance
					else
						shoot = math.random(100) <= math.floor(self.attackchance / 2)
					end
				end	
				if dist < 3 then shoot = true end			
				if shoot then
					self:action_fire( player, self.eq.weapon )
					return "hunt"
				end
			end

			if dist > 3 then
                if self:path_find( target.position, 10, 40 ) or ( not aitk.move_path( self ) ) then
					return "hunt"
				end
			end

			local mt = area.around( self.position, 3 ):clamped( area.FULL ):random_coord()
			if self:distance_to( mt ) > 0 then
				if self:direct_seek( mt ) == MOVEOK then
					return "hunt"
				end
			end
			self.scount = self.scount - 1000
			return "hunt"
		end,
	}
}

register_ai "teleboss_ai"
{
	OnCreate = function( self )
		aitk.basic_init( self, false, false )
		self:add_property( "telechance", 10 )
		self:add_property( "teleradius", 5 )
	end,

	OnAttacked = aitk.basic_on_attacked,

	states = {
		idle     = function( self )
			if ais[ self.ai_type ].states.teleport( self ) then return "idle" end
			return aitk.basic_smart_idle( self )
		end,
		pursue    = function( self )
			if ais[ self.ai_type ].states.teleport( self ) then return "idle" end
			return aitk.basic_pursue( self )
		end,
		hunt     = function( self )
			if ais[ self.ai_type ].states.teleport( self ) then return "idle" end
			return aitk.pursue_hunt( self )
		end,
		teleport = function( self )
			if math.random( 100 ) > self.telechance then return false end
			local dist  = self:distance_to( player )
			local p     = player.position
			local s     = self.position
			local phase 
			if dist <= self.teleradius then
				local flee = coord( 2*(s.x-p.x), 2*(s.y-p.y))
				phase = table.random_pick{ p + flee, p - flee }
				area.FULL_SHRINKED:clamp_coord( phase )
				phase = level:drop_coord( phase, { EF_NOBEINGS, EF_NOBLOCK } )
			end

			if not phase then
				local parea = area.around( p, self.teleradius ):clamped( area.FULL_SHRINKED )
				local limit = 0
				repeat
					limit = limit + 1
					if limit > 25 then return false end
					phase = level:random_empty_coord( { EF_NOBEINGS, EF_NOBLOCK }, parea )
				until phase and level:eye_contact( p, phase )
			end

			self:play_sound("phasing")
			level:explosion( self, { range = 2, delay = 50, color = YELLOW } )
			local target = level:drop_coord( phase, { EF_NOBEINGS, EF_NOBLOCK } )
			self:relocate( target )
			level:explosion( self, { range = 1, delay = 50, color = YELLOW } )
			self.scount = self.scount - 1000
			return true
		end,
	}
}

register_ai "mastermind_ai"
{

	OnCreate = function( self )
		aitk.basic_init( self, false, false )
		self:add_property( "stun_time", 0 )
		self:add_property( "previous_hp", self.hpmax )
		self:add_property( "irritated", 0 )
		self.ai_state = "hunt"
	end,

	OnAttacked = function( self )
		if self.stun_time > 0 then return end
		local damage_taken = self.previous_hp - self.hp
		if damage_taken >= 20 then
			self:play_sound( "act" )
			self.stun_time = math.floor(damage_taken/20)
			self:msg("", "The ".. self.name .." flinched!")
			self.ai_state = "stagger"
		end
	end,

	states = {
		stagger = function( self )
			local direction = level:random_empty_coord( { EF_NOBEINGS, EF_NOBLOCK }, area.around( self.position ) )
			self:direct_seek( direction )
			self.previous_hp = self.hp
			self.stun_time = self.stun_time - 1
			if self.stun_time > 0 then
				return "stagger"
			else
				return "hunt"
			end
		end,

		hunt = function( self )
			local dist       = self:distance_to( player )
			local visible    = self:in_sight( player )
			self.previous_hp = self.hp

			if math.random(30) == 1 then
				self:play_sound( "act" )
			end

			if visible then
				if dist == 1 then
					if math.random(100) <= self.attackchance then
						self:action_fire( player, self.eq.weapon )
					else
						self:attack( player )
					end
					self.irritated = 0
				elseif dist < 4 then
					self:action_fire( player, self.eq.weapon )
					self.irritated = 0
				else
					local spray = area.around( player.position, math.floor(dist/3) )
					local num_fire = self.eq.weapon.shots
					self.eq.weapon.shots = 1
					local animseq = 0
					for shot = 1,num_fire do
						local energy = self.scount
						if math.random(2) == 1 then
							self:action_fire( player, self.eq.weapon, animseq )
						else
							local hit = spray:random_coord()
							area.FULL:clamp_coord(hit)
							self:action_fire( hit, self.eq.weapon, animseq )
						end
						if shot ~= 1 then
							self.scount = energy
						end
						animseq = animseq + 60
					end
					self.eq.weapon.shots = num_fire
				end
				return "hunt"
			end
			self.irritated = self.irritated + 1

			if dist > self.vision or self.irritated > 2 then
                if self:path_find( player.position, 40, 200 ) and aitk.move_path( self ) then
					return "hunt"
				end
			end

			local moves = {}
			for c in self.position:around_coords() do
				if player:distance_to(c) == dist and level:is_empty(c, { EF_NOBEINGS, EF_NOBLOCK } ) then
					table.insert(moves,c:clone())
				end
			end
			local best_moves = {}
			for _,c in ipairs( moves ) do
				if level:eye_contact( c, player ) then
					table.insert( best_moves, c )
				end
			end
			if #best_moves > 0 then
				moves = best_moves
			end
			if #moves == 0 then
				move = level:random_empty_coord({ EF_NOBEINGS, EF_NOBLOCK }, area.around( self.position ))
			end

			local move = table.random_pick( moves )
			if self:direct_seek( move ) ~= MOVEOK then
                self.scount = self.scount - 1000
            end
			return "hunt"
		end,
	}
}
