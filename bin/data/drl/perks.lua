function drl.register_perks()

	-- Alt-fire
	
	register_perk "perk_altfire_throw"
	{
		name   = "",
		short  = "throw",
		desc   = "throws the melee weapon at a target",
		color  = LIGHTBLUE,
		tags   = { "altfire" },

		OnAdd = function(self)
			self.flags[ IF_ALTTARGET ] = true
			self.flags[ IF_THROWDROP ] = true
			self.flags[ IF_EXACTHIT  ] = true
		end,

		OnRemove = function(self)
			self.flags[ IF_ALTTARGET ] = false
			self.flags[ IF_THROWDROP ] = false
			self.flags[ IF_EXACTHIT  ] = false
		end,

		OnAltFire = function( self, being, target )
			being:send_missile( target, self )
			being.scount = being.scount - 1000
			return false
		end,
	}

	register_perk "perk_altfire_rocketjump"
	{
		name   = "",
		short  = "rocketjump",
		desc   = "fire at your feet with less damage and more knockback",
		color  = LIGHTBLUE,
		tags   = { "altfire" },

		OnAdd = function(self)
			self:add_property( "pp_rjump", {
				exact = self.flags[ IF_EXACTHIT ],
				range = self.range,
			} )
			-- TODO: should also store explosions once we have a way to to that
			self.flags[ IF_ALTTARGET ] = true
			self.flags[ IF_ALTMANUAL ] = true
		end,

		OnRemove = function(self)
			self:remove_property( "pp_rjump" )
			self.flags[ IF_ALTTARGET ] = false
			self.flags[ IF_ALTMANUAL ] = false
		end,

		OnAltFire = function( self, being )
			self:set_explosion{
				delay 	= 40,
				color 	= RED,
				flags = { EFSELFKNOCKBACK, EFSELFHALF },
			}
			self.flags[ IF_EXACTHIT ] = true
			self.range   = 1
			return true
		end,

		OnFired = function( self, being )
			self:set_explosion{
				delay = 40,
				color = RED,
			}
			self.flags[ IF_EXACTHIT ] = self.pp_rjump.exact
			self.range   = self.pp_rjump.range
			return true
		end,
	}

	register_perk "perk_altfire_single"
	{
		name   = "",
		short  = "single",
		desc   = "fires a single shot",
		color  = LIGHTBLUE,
		tags   = { "altfire" },

		OnAdd = function(self)
			self.flags[ IF_ALTTARGET ] = true
			self:add_property( "pp_altsingle", false )
		end,

		OnRemove = function(self)
			self.flags[ IF_ALTTARGET ] = false
			self:remove_property( "pp_altsingle" )
		end,

		OnAltFire = function( self, being, target )
			self.pp_altsingle = self.shots
			self.shots = 1
			return true
		end,

		OnFired = function( self, being )
			if self.pp_altsingle then
				self.shots = self.pp_altsingle
				self.pp_altsingle = false
			end
			return true
		end,
	}

	register_perk "perk_altfire_aimed"
	{
		name   = "",
		short  = "aimed",
		desc   = "fires an aimed shot with +3 to hit, but double time taken",
		color  = LIGHTBLUE,
		tags   = { "altfire" },

		OnAdd = function(self)
			self:add_property( "pp_aimed", false )
			self.flags[ IF_ALTTARGET ] = true
		end,

		OnRemove = function(self)
			self:remove_property( "pp_aimed" )
			self.flags[ IF_ALTTARGET ] = false
		end,

		OnAltFire = function( self, being, target )
			self.pp_aimed = true
			return true
		end,

		OnFired = function( self, being )
			self.pp_aimed = false
			return true
		end,

		getToHitBonus = function( self, is_melee, alt_fire )
			if self.pp_aimed then
				return 3
			end
			return 0
		end,

		getFireCostMul = function( self, is_melee, alt_fire )
			if self.pp_aimed then
				return 2.0
			end
			return 1.0
		end,
	}

	-- Alt-reload 

	register_perk "perk_altreload_full"
	{
		name   = "",
		short  = "full",
		desc   = "fully reloads the weapon (max 2.5s)",
		color  = LIGHTBLUE,
		tags   = { "altreload" },

		OnAltReload = function(self, being)
			local scount = being.scount
			local result = being:full_reload( self )
			local cost   = scount - being.scount
			if cost > 2500 then
				being.scount = being.scount + ( cost - 2500 )
			end
			return result
		end,
	}

	register_perk "perk_altreload_nuke"
	{
		name   = "",
		short  = "overload",
		desc   = "overloads the nuclear reactor",
		color  = LIGHTBLUE,
		tags   = { "altreload" },

		OnAltReload = function(self, being)
			local floor_cell = cells[ level.map[ being.position ] ]
			if floor_cell.flags[CF_STAIRS] then
				ui.msg("Better not do this on the stairs...")
				return false
			end
			if not self:can_overcharge("This will overload the nuclear reactor...") then return false end
			if floor_cell.flags[CF_HAZARD] then
				ui.msg("Somehow, in an instant, you feel like an idiot...")
				being:nuke(1)
			else
				ui.msg("Warning! Explosion in 10 seconds!")
				being:nuke(100)
			end
			player:add_history("He overloaded a "..self.name.." on @1!")
			being.eq.weapon = nil
			being.scount = being.scount - 1000
			return true
		end,
	}

	register_perk "perk_altreload_overcharge"
	{
		name   = "",
		short  = "overcharge",
		desc   = "boosts the weapon and destroys it after the next shot",
		color  = LIGHTBLUE,
		tags   = { "altreload" },

		OnAltReload = function(self, being)
			if not self:can_overcharge("This will destroy the weapon after the next shot...") then return false end
			if self.radius > 0 then
				-- BFG-style overcharge
				self.misdelay      = 200
				self.radius        = self.radius * 2
				self.damage_dice   = self.damage_dice * 2
				self.shotcost      = self.ammomax
				self.ammomax       = self.shotcost
				self.ammo          = self.shotcost
			else
				-- Plasma-style overcharge
				self.shots         = self.shots * 2
				self.ammomax       = self.shots
				self.ammo          = self.shots
				self.damage_sides  = self.damage_sides + 1
				self.altfire       = ALT_NONE
			end
			return true
		end,
	}

	-- Pump action perk (invisible)

	register_perk "perk_pump_action"
	{
		OnAdd = function(self)
			self:add_property( "pump_action", true )
			self:add_property( "chamber_empty", false )
		end,

		OnRemove = function(self)
			self:remove_property( "pump_action" )
			self:remove_property( "chamber_empty" )
		end,

		OnPostMove = function(self, being, worn)
			if not worn or not self.pump_action then return end
			if self.chamber_empty and self.ammo > 0 then
				level:play_sound( self.id, "pump", being.position )
				self.chamber_empty = false
				if being:is_player() then
					ui.msg( "You pump a shell into the shotgun chamber." )
				end
			end
		end,

		OnFire = function(self, being)
			if not self.pump_action then return true end
			if self.chamber_empty and self.ammo > 0 then
				if being:is_player() then
					ui.msg( "Shell chamber empty - move or reload!" )
				end
				return false
			end
			return true
		end,

		OnFired = function(self, being)
			if not self.pump_action then return end
			self.chamber_empty = true
		end,

		OnPreReload = function(self, being)
			if not self.pump_action then return true end
			if self.flags[ IF_NOAMMO ] or self.ammo > 0 then
				if self.chamber_empty then
					self.chamber_empty = false
					level:play_sound( self.id, "pump", being.position )
					if being:is_player() then
						ui.msg( "You pump a shell into the "..self.name.." chamber." )
					end
					being.scount = being.scount - 200
					return false
				end
			end
			return true
		end,

		OnReload = function(self, being, ammo, is_pack)
			if not self.pump_action then return true end
			being:reload( ammo, true, true ) -- reduces scount
			local pack = ""
			if is_pack then pack = "quickly " end
			being:msg("You "..pack.."load a shell into the "..self.name..".", being:get_name(true,true).." loads a shell into his "..self.name.."." )
			self.chamber_empty = false
			return true
		end,
	}

	-- Generic recharge perks (invisible - no name/desc)

	register_perk "perk_weapon_recharge"
	{
		tags   = { "recharge" },

		OnAdd = function(self)
			self:add_property( "pp_recharge", {
				timer  = 0,
				delay  = 5,
				amount = 1,
				limit  = 0,
			})
		end,

		OnEquipTick = function(self, being)
			local r = self.pp_recharge
			local max = r.limit > 0 and math.min(r.limit, self.ammomax) or self.ammomax
			if self.ammo < max then
				r.timer = r.timer + 1
				if r.timer > r.delay then
					self.ammo = math.min(self.ammo + r.amount, max)
					r.timer = 0
				end
			end
		end,

		OnFire = function(self, being, target)
			self.pp_recharge.timer = 0
		end,

		OnRemove = function(self)
			self:remove_property( "pp_recharge" )
		end,
	}

	register_perk "perk_armor_recharge"
	{
		tags   = { "recharge" },

		OnAdd = function(self)
			self:add_property( "pp_recharge", {
				timer  = 0,
				delay  = 5,
				amount = 1,
				limit  = 0,
			})
		end,

		OnEquipTick = function(self, being)
			local r = self.pp_recharge
			local max = r.limit > 0 and math.min(r.limit, self.maxdurability) or self.maxdurability
			if self.durability < max then
				r.timer = r.timer + 1
				if r.timer > r.delay then
					self.durability = math.min(self.durability + r.amount, max)
					r.timer = 0
				end
			end
		end,

		OnReceiveDamage = function(self, damage, source, attacker)
			self.pp_recharge.timer = 0
		end,

		OnRemove = function(self)
			self:remove_property( "pp_recharge" )
		end,
	}

	-- Necrocharge perk (invisible - drains HP to regenerate durability)

	register_perk "perk_necrocharge"
	{
		tags  = { "recharge" },

		OnAdd = function(self)
			self:add_property( "pp_recharge", {
				timer  = 0,
				delay  = 0,
				amount = 5,
				limit  = 0,
			})
		end,

		OnEquipTick = function(self, being)
			local r = self.pp_recharge
			if being.hp > 1 and self.durability < self.maxdurability then
				r.timer = r.timer + 1
				if r.timer > r.delay then
					local max = r.limit > 0 and math.min(r.limit, self.maxdurability) or self.maxdurability
					self.durability = math.min(self.durability + r.amount, max)
					being.hp = being.hp - 1
					r.timer = 0
				end
			end
		end,

		OnReceiveDamage = function(self, damage, source, attacker)
			self.pp_recharge.timer = 0
		end,

		OnRemove = function(self)
			self:remove_property( "pp_recharge" )
		end,
	}

end
