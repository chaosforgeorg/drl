function drl.register_affects()
	
	register_perk "tired"
	{
		name           = "tired",
		color          = DARKGRAY,
		color_expire   = DARKGRAY,
		
		OnAdd          = function(self)
			self:remove_perk( "running" )
		end,
		OnRemove       = function(self)
		end,
	}

	register_perk "running"
	{
		name           = "running",
		color          = YELLOW,
		color_expire   = BROWN,

		OnAdd          = function(self)
			self:msg("You start running!")
			self:remove_perk( "tired" )
		end,
		OnRemove       = function(self,silent)
			self:add_perk( "tired" )
			if not silent then
				self:msg("You stop running.")
			end
		end,
		getDodgeBonus = function( self )
			return 20
		end,
		getMoveBonus = function( self )
			return 30
		end,
		getDefenceBonus = function( self, is_melee )
			return 4
		end,
		getToHitBonus = function( self, weapon, is_melee, alt )
			if not self:has_property( "NO_RUN_PENALTY" ) then
				return -2
			end
			return 0
		end,
	}

	register_perk "berserk"
	{
		name           = "berserk",
		color          = LIGHTRED,
		color_expire   = RED,
		status_effect  = STATUSRED,
		status_strength= 5,

		OnAdd          = function(self)
			self:msg("You feel like a killing machine!")
			self:remove_perk( "running", true )
			self.speed = self.speed + 50
			self.resist.bullet = (self.resist.bullet or 0) + 50
			self.resist.melee = (self.resist.melee or 0) + 50
			self.resist.shrapnel = (self.resist.shrapnel or 0) + 50
			self.resist.acid = (self.resist.acid or 0) + 50
			self.resist.fire = (self.resist.fire or 0) + 50
			self.resist.plasma = (self.resist.plasma or 0) + 50
		end,
		OnTick10         = function(self,time)
			self:msg("You need to taste blood!")
			if time == 5 then
				self:msg("You feel your anger slowly wearing off...")
			end
		end,
		OnRemove       = function(self,silent)
			self.speed = self.speed - 50
			self.resist.bullet = (self.resist.bullet or 0) - 50
			self.resist.melee = (self.resist.melee or 0) - 50
			self.resist.shrapnel = (self.resist.shrapnel or 0) - 50
			self.resist.acid = (self.resist.acid or 0) - 50
			self.resist.fire = (self.resist.fire or 0) - 50
			self.resist.plasma = (self.resist.plasma or 0) - 50
			if not silent then
				self:msg("You feel more calm.")
			end
		end,
		getDamageMul = function( self, weapon, is_melee, alt )
			if ( weapon and weapon.itype == ITEMTYPE_MELEE ) or is_melee then
				return 2.0
			end
			return 1.0
		end,
	}

	register_perk "inv"
	{
		name           = "invulnerable",
		color          = WHITE,
		color_expire   = DARKGRAY,
		status_effect  = STATUSINVERT,
		status_strength= 10,

		OnAdd          = function(self)
			self:msg("You feel invincible!")
			self.flags[ BF_INV ] = true
		end,
		OnTick10       = function(self,time)
			if self.hp < self.hpmax and not self.flags[ BF_NOHEAL ] then
				self.hp = self.hpmax
			end
			if time == 5 then
				self:msg("You feel your invincibility slowly wearing off...")
			end
		end,
		OnRemove       = function(self,silent)
			self.flags[ BF_INV ] = false
			if not silent then
				self:msg("You feel vulnerable again.")
			end
		end,
	}

	register_perk "enviro"
	{
		name           = "enviro",
		color          = LIGHTGREEN,
		color_expire   = GREEN,
		status_effect  = STATUSGREEN,
		status_strength= 1,

		OnAdd          = function(self)
			self:msg("You feel protected!")
			self.resist.acid = (self.resist.acid or 0) + 25
			self.resist.fire = (self.resist.fire or 0) + 25
		end,

		OnTick10         = function(self,time)
			if time == 5 then
				self:msg("You feel your protection fading...")
			end
		end,

		OnRemove       = function(self,silent)
			self.resist.acid = (self.resist.acid or 0) - 25
			self.resist.fire = (self.resist.fire or 0) - 25
			if not silent then
				self:msg("You feel less protected.")
			end
		end,
	}

	register_perk "light"
	{
		name           = "light",
		color          = YELLOW,
		color_expire   = BROWN,

		OnAdd          = function(self)
			self:msg("You see further!")
			self.vision = self.vision + 4
		end,
		
		OnTick10         = function(self,time)
			if time == 5 then
				self:msg("You feel your enhanced vision fading...")
			end
		end,

		OnRemove       = function(self,silent)
			self.vision = self.vision - 4
			if not silent then
				self:msg("Your vision fades.")
			end
		end,
	}

end
