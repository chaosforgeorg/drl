function drl.register_perks()

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
