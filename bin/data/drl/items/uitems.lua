function drl.register_unique_items()

	register_itemset "angelic"
	{
		name    = "Angelic Attire",
		trigger = 2,

		OnEquip = function (self,being)
			local armor = self
			if armor.id ~= "aarmor" then armor = being.eq.armor end
			armor.armor = armor.armor + 4
			if being:is_player() then
				ui.blink( WHITE, 100 )
				ui.msg( "You feel protected!" )
			end
		end,

		OnRemove = function (self,being)
			local armor = self
			if armor.id ~= "aarmor" then armor = being.eq.armor end
			armor.armor = armor.armor - 4
			being:msg( "You feel less protected." )
		end,
	}

	register_itemset "inquisitor"
	{
		name    = "Inquisitor Set",
		trigger = 2,

		OnEquip = function (self,being)
			local armor = self
			local boots = self
			if armor.id ~= "umarmor" then
				armor = being.eq.armor
			else
				boots = being.eq.boots
			end
			armor.resist.fire = armor.resist.fire + 70
			boots.resist.fire = boots.resist.fire + 70
			if being:is_player() then
				ui.blink( WHITE, 100 )
				ui.msg( "You feel protected from unrighteous fire!" )
			end
		end,

		OnRemove = function (self,being)
			local armor = self
			local boots = self
			if armor.id ~= "umarmor" then
				armor = being.eq.armor
			else
				boots = being.eq.boots
			end
			armor.resist.fire = armor.resist.fire - 70
			boots.resist.fire = boots.resist.fire - 70
			being:msg( "You no longer feel protected from unrighteous fire." )
		end,
	}

  --Uniques --

	register_item "unullpointer"
	{
		name     = "Charch's Null Pointer",
		sound_id = "plasma",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PLASMA,
		psprite  = SPRITE_PLAYER_PLASMA,
		level    = 15,
		weight   = 1,
		group    = "plasma",
		desc     = "It feels extremely unstable... what twisted mind could conceive such a weird device?",
		firstmsg = "This seems to be an extremely unstable device!",
		flags    = { IF_UNIQUE },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 60,
		damage        = "0d0",
		damagetype    = DAMAGE_PLASMA,
		acc           = 6,
		reload        = 20,
		shotcost      = 10,
		misascii      = "*",
		miscolor      = MULTIBLUE,
		misdelay      = 10,
		miss_base     = 30,
		miss_dist     = 3,
		missprite     = SPRITE_PLASMASHOT,
		hitsprite     = SPRITE_BLAST,

		OnHitBeing = function(self,being,target)
			target:play_sound("phasing")
			being:msg("Suddenly "..target:get_name(true,false).." crashes!")
			if target:has_property("is_boss") and target.is_boss then
				target.scount = math.max( target.scount - 500, 1000 )
			else
				target.scount = math.max( target.scount - 1000, 1000 )
			end
			level:explosion( target.position, { range = 1, delay = 50, damage = "10d1", color = LIGHTBLUE, sound_id = "soldier.phase", damage_type = DAMAGE_SPLASMA }, self )
			return false
		end,
	}

	register_item "umodstaff"
	{
		name     = "Hell Staff",
		ascii    = "?",
		color    = LIGHTGREEN,
		sprite   = SPRITE_STAFF,
		level    = 15,
		weight   = 4,
		desc     = "Now this is an interesting piece of equipment...",
		flags    = { IF_UNIQUE },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			if not being:is_player() then return false end
			if being:is_affect( "tired" ) then
				ui.msg("You're too tired to use it now.")
				return false
			end;
			being:set_affect( "tired" )
			being:play_sound("phasing")
			ui.msg("You feel yanked in a non-existing direction!")
			being:phase()
			being.scount = being.scount - 1000
			return false
		end,
	}

	register_item "ubutcher"
	{
		name     = "Butcher's Cleaver",
		sound_id = "knife",
		color    = LIGHTGREEN,
		sprite   = SPRITE_CLEAVER,
		psprite  = SPRITE_PLAYER_CLEAVER,
		level    = 1,
		weight   = 2,
		desc     = "Now that is a BIG cleaver. Butcher them!",
		firstmsg = "Aaaah, fresh meat!",
		flags    = { IF_UNIQUE, IF_MODABLE, IF_SINGLEMOD },
		knockmod = -50,

		type        = ITEMTYPE_MELEE,
		damage      = "5d6",
		damagetype  = DAMAGE_MELEE,
		group       = "melee",

		OnCreate = function(self)
			self:add_property( "BLADE", true )
		end,

		OnKill = function ( self, being, target )
			if not being then return end
			if being:is_player() then
				if player:get_trait( traits["blademaster"].nid ) > 0 then return end
				ui.msg("Next!")
			end
			being.scount = 5001
		end,
	}

	register_item "umjoll"
	{
		name     = "Mjollnir",
		sound_id = "knife",
		color    = LIGHTGREEN,
		sprite   = SPRITE_CLEAVER,
		psprite  = SPRITE_PLAYER_CLEAVER,
		level    = 5,
		weight   = 1,
		group    = "melee",
		scavenge = { "umod_onyx" },
		desc     = "Forged by the dwarves Eitri and Brokk, in response to Loki's challenge, Mjollnir is an indestructible war hammer.",
		flags    = { IF_UNIQUE, IF_NODESTROY, IF_MODABLE, IF_SINGLEMOD, IF_EXACTHIT },

		type       = ITEMTYPE_MELEE,
		damage     = "1d25",
		damagetype = DAMAGE_MELEE,
		acc        = 0,
		altfire    = ALT_THROW,
		miscolor   = LIGHTGRAY,
		misdelay   = 50,
		miss_base  = 10,
		miss_dist  = 3,
		range      = 5,
		missprite  = SPRITE_CLEAVER,
		hitsprite  = SPRITE_BLAST,
	}

	register_item "usubtle"
	{
		-- XXX "Subtle Knife" or "The Subtle Knife"?  Something about articles annoy me...
		--name     = "The Subtle Knife",
		name     = "Subtle Knife",
		sound_id = "none",
		color    = LIGHTGREEN,
		sprite   = SPRITE_KNIFE,
		psprite  = SPRITE_PLAYER_KNIFE,
		level    = 15,
		weight   = 1,
		desc     = "A weapon that can cut the very fabric of reality. Too bad it's only eight inches long...",
		firstmsg = "Looks very inconspicious.",
		flags    = { IF_UNIQUE, IF_MODABLE, IF_SINGLEMOD },

		type        = ITEMTYPE_MELEE,
		damage      = "3d5",
		damagetype  = DAMAGE_SPLASMA,
		group       = "melee",
		altfire     = ALT_SCRIPT,
		altfirename = "invoke",

		OnCreate = function(self)
			self:add_property( "BLADE", true )
		end,

		OnAltFire = function(self,being)
			if being:is_affect( "tired" ) then
				ui.msg("You are too tired to invoke the Knife!");
			else
				ui.msg("You feel your health drained!");
				being.hp     = math.max( being.hp - 5, 1 )
				being:set_affect( "tired" )
				being.scount = being.scount - 1000
				for b in level:beings() do
					if not b:is_player() and b:is_visible() then
						level:explosion( b.position, { range = 1, delay = 50, color = BLUE, damage_type = DAMAGE_SPLASMA }, self )
						b:apply_damage( 15, TARGET_INTERNAL, DAMAGE_SPLASMA, self )
					end
				end
			end
			return false
		end,
	}

	register_item "utrigun"
	{
		name     = "Trigun",
		sound_id = "pistol",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PISTOL,
		psprite  = SPRITE_PLAYER_PISTOL,
		level    = 8,
		weight   = 2,
		group    = "pistol",
		desc     = "One of the deadliest weapons ever made. Nyooo >O.o<",
		scavenge = { "umod_nano" },
		flags    = { IF_UNIQUE, IF_MODABLE, IF_SINGLEMOD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 6,
		damage        = "3d6",
		damagetype    = DAMAGE_BULLET,
		acc           = 6,
		fire          = 7,
		reload        = 20,
		altfire       = ALT_AIMED,
		altreload     = RELOAD_SCRIPT,
		altreloadname = "Angel Arm",
		miscolor      = LIGHTGRAY,
		misdelay      = 15,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,

		OnAltReload = function(self,being)
			if being:is_player() and being.hpmax > 10 then
				if ui.confirm( "Do you want to use the dangerous Angel Arm?") then
					ui.msg("You activate the Angel Arm! Your life is drained!")
					player:add_history("He activated the Angel Arm on @1!")
					being.hpmax = math.max( being.hpmax - 5, 10 )
					being.hp = math.max( being.hp - 5, 1 )
					being.scount = being.scount - 1000
					being:nuke(1)
					return true
				end
			end
			return false
		end,
	}

	register_item "ujackal"
	{
		name     = "Anti-Freak Jackal",
		sound_id = "pistol",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PISTOL,
		psprite  = SPRITE_PLAYER_PISTOL,
		level    = 10,
		weight   = 2,
		group    = "pistol",
		desc     = "In the name of God, impure souls of the living dead shall be banished into eternal damnation. Amen.",
		flags    = { IF_UNIQUE, IF_MODABLE, IF_SINGLEMOD },
		scavenge = { "umod_firestorm" },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 6,
		damage        = "5d3",
		damagetype    = DAMAGE_FIRE,
		acc           = 4,
		fire          = 10,
		radius        = 1,
		reload        = 20,
		altfire       = ALT_AIMED,
		altreload     = RELOAD_DUAL,
		miscolor      = LIGHTGRAY,
		misdelay      = 15,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,
		explosion     = {
			delay = 40,
			color = RED,
		},
	}

	register_item "umega"
	{
		name     = "Mega Buster",
		sound_id = "chaingun",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PLASMA,
		psprite  = SPRITE_PLAYER_PLASMA,
		level    = 15,
		weight   = 1,
		group    = "chain",
		desc     = "You suddenly wish to slaughter the forces of Hell to 8-bit chiptune music.",
		flags    = { IF_UNIQUE },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 60,
		damage        = "1d8",
		damagetype    = DAMAGE_BULLET,
		acc           = 2,
		fire          = 10,
		reload        = 35,
		shots         = 3,
		shotcost      = 3,
		miscolor      = WHITE,
		misdelay      = 10,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,

		OnKill = function (self,being,target)
			local damage = DAMAGE_BULLET
			if target.eq.weapon then 
				damage = target.eq.weapon.damagetype
			end

			local morph =
			{
				[DAMAGE_BULLET] = {
					damagetype   = DAMAGE_BULLET,
					blastradius  = 0,
					damage_dice  = 1,
					damage_sides = 8,
					acc          = 2,
					miscolor     = LIGHTGRAY,
					misdelay     = 10,
					miss_base    = 10,
					miss_dist    = 3,
				},
				[DAMAGE_FIRE] = {
					damagetype   = DAMAGE_FIRE,
					blastradius  = 1,
					damage_dice  = 4,
					damage_sides = 2,
					acc          = 0,
					miscolor     = LIGHTGRAY,
					misdelay     = 15,
					miss_base    = 10,
					miss_dist    = 3,
					explosion    = {
						delay = 40,
						color = RED,
					},
				},
				[DAMAGE_ACID] = {
					damagetype   = DAMAGE_ACID,
					blastradius  = 1,
					damage_dice  = 4,
					damage_sides = 2,
					acc          = 0,
					miscolor     = LIGHTGRAY,
					misdelay     = 15,
					miss_base    = 10,
					miss_dist    = 3,
					explosion    = {
						delay = 40,
						color = GREEN,
					},
				},
				[DAMAGE_PLASMA] = {
					damagetype   = DAMAGE_PLASMA,
					blastradius  = 0,
					damage_dice  = 1,
					damage_sides = 10,
					acc          = 1,
					misascii     = "*",
					miscolor     = MULTIBLUE,
					misdelay     = 10,
					miss_base    = 30,
					miss_dist    = 3,
				}
			}
			local final = morph[ damage ] or morph[ DAMAGE_BULLET ]
			if final.damagetype ~= self.damagetype then
				ui.msg("The Mega Buster morphs!")
			end
			if final.explosion then
				self:set_explosion( final.explosion )
				final.explosion = nil
			end
			for k,v in pairs( final ) do
				self[k] = v
			end
		end,
	}

	register_medal "cleric"
	{
		name = "Grammaton Cleric Cross",
		desc = "Mastermind killed with the Cleric Beretta",
		hidden = true,
	}

	register_item "uberetta"
	{
		name     = "Grammaton Cleric Beretta",
		sound_id = "pistol",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PISTOL,
		psprite  = SPRITE_PLAYER_PISTOL,
		level    = 6,
		weight   = 3,
		group    = "pistol",
		desc     = "No. Not without incident.",
		flags    = { IF_UNIQUE },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 18,
		damage        = "2d6",
		damagetype    = DAMAGE_BULLET,
		acc           = 5,
		fire          = 10,
		reload        = 20,
		altreload     = RELOAD_SCRIPT,
		altreloadname = "firemode",
		miscolor      = WHITE,
		misdelay      = 10,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,

		OnKill = function (self,being,target)
			if target.id == "mastermind" and target.is_boss then
				being:add_medal("cleric")
			end
		end,

		OnAltReload = function(self,being)
			if self.acc == 5 then
				ui.msg("You switch to burst mode.");
				self.acc 			= 3
				self.damage_dice 	= 1
				self.damage_sides 	= 8
				self.shots 			= 3
			elseif self.acc == 3 then
				ui.msg("You switch to full auto mode.");
				self.acc 			= 1
				self.damage_dice 	= 1
				self.damage_sides 	= 7
				self.shots 			= 6
			elseif self.acc == 1 then
				ui.msg("You switch to single fire mode.");
				self.acc 			= 5
				self.damage_dice 	= 2
				self.damage_sides 	= 6
				self.shots 			= 0
			end
			being.scount = being.scount - 200
			return true
		end,
	}

	register_item "usjack"
	{
		name     = "Jackhammer",
		sound_id = "ashotgun",
		color    = LIGHTGREEN,
		sprite   = SPRITE_CSHOTGUN,
		psprite  = SPRITE_PLAYER_CSHOTGUN,
		level    = 12,
		weight   = 2,
		group    = "shotgun",
		desc     = "The Pancor Corporation Jackhammer is a 12-gauge, gas-operated automatic weapon.",
		flags    = { IF_UNIQUE, IF_MODABLE, IF_SINGLEMOD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "shell",
		ammomax       = 10,
		damage        = "8d3",
		damagetype    = DAMAGE_SHARPNEL,
		fire          = 10,
		reload        = 25,
		altreload     = RELOAD_SCRIPT,
		altreloadname = "trigger",
		shots         = 3,
		hitsprite     = SPRITE_BLAST,
		range         = 15,
		spread        = 2,
		reduce        = 0.05,

		OnAltReload = function(self,being)
			if self.shots == 3 then
				ui.msg("You relax your trigger finger.");
				self.shots			= 1
			elseif self.shots == 1 then
				ui.msg("You tense up your trigger finger.");
				self. shots			= 3
			end
			-- Just delay the next step nominally so that we don't abuse this
			being.scount = being.scount - 1
			return true
		end,
	}

	register_item "ufshotgun"
	{
		name     = "Frag Shotgun",
		sound_id = "ashotgun",
		color    = LIGHTGREEN,
		sprite   = SPRITE_CSHOTGUN,
		psprite  = SPRITE_PLAYER_CSHOTGUN,
		level    = 10,
		weight   = 3,
		group    = "shotgun",
		desc     = "Advanced pulverization technology converts bullets into shrapnel.",
		flags    = { IF_UNIQUE, IF_MODABLE, IF_SINGLEMOD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 16,
		shotcost      = 2,
		damage        = "6d3",
		damagetype    = DAMAGE_SHARPNEL,
		fire          = 5,
		reload        = 25,
		hitsprite     = SPRITE_BLAST,
		range         = 15,
		spread        = 2,
		reduce        = 0.05,
	}

	register_item "urbazooka"
	{
		name     = "Revenant's Launcher",
		sound_id = "bazooka",
		color    = LIGHTGREEN,
		sprite   = SPRITE_BAZOOKA,
		psprite  = SPRITE_PLAYER_BAZOOKA,
		level    = 12,
		weight   = 2,
		group    = "rocket",
		desc     = "Two can play the homing missile game.",
		scavenge = { "umod_sniper" },
		flags    = { IF_UNIQUE, IF_MODABLE, IF_EXACTHIT },

		type       = ITEMTYPE_RANGED,
		ammo_id    = "rocket",
		ammomax    = 1,
		damage     = "7d6",
		damagetype = DAMAGE_FIRE,
		acc        = 6,
		fire       = 10,
		radius     = 3,
		reload     = 14,
		miscolor   = BROWN,
		misdelay   = 30,
		miss_base  = 30,
		miss_dist  = 5,
		missprite  = SPRITE_ROCKETSHOT,
		hitsprite  = SPRITE_BLAST,
		explosion  = {
			delay = 40,
			color = RED,
		},
	}

	register_item "uacid"
	{
		name     = "Acid Spitter",
		sound_id = "bazooka",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PLASMA,
		psprite  = SPRITE_PLAYER_PLASMA,
		level    = 12,
		weight   = 3,
		group    = "rocket",
		desc     = "Woah, looks cool, but how do I reload it?",
		flags    = { IF_UNIQUE, IF_NOUNLOAD },

		resist = { acid = 75 },

		type       = ITEMTYPE_RANGED,
		ammo_id    = "rocket",
		ammomax    = 10,
		damage     = "10d10",
		damagetype = DAMAGE_ACID,
		acc        = 5,
		fire       = 8,
		radius     = 3,
		reload     = 12,
		shotcost   = 10,
		miscolor   = GREEN,
		misdelay   = 10,
		miss_base  = 30,
		miss_dist  = 5,
		missprite  = SPRITE_ROCKETSHOT,
		hitsprite  = SPRITE_BLAST,
		explosion  = {
			delay = 80,
			color = GREEN,
			content = "acid",
		},

		OnCreate = function( self )
			self.ammo = 0
		end,

		OnPreReload = function( self, being )
			if self.ammo == self.ammomax  then 
				ui.msg("Your weapon is already loaded!")
				return false
			end
			local pos  = being.position
			if level.map[ pos ] == cells[ "acid" ].nid then
				ui.msg("Slurp!")
				self.ammo = math.min( self.ammo + 1, self.ammomax )
				being.scount = being.scount - 1000
				level.map[ pos ] = "water"
			else
				ui.msg("Hmm, there's no magazine here...")
			end
			return false
		end,
	}

	register_item "ubfg10k"
	{
		name     = "BFG 10K",
		sound_id = "plasma",
		color    = LIGHTGREEN,
		sprite   = SPRITE_BFG10K,
		psprite  = SPRITE_PLAYER_BFG9000,
		level    = 20,
		weight   = 1,
		group    = "bfg",
		scavenge = { "umod_nano" },
		desc     = "The Ultimate Big Fucking Gun. Redefines the word \"wallpaper\".",
		flags    = { IF_UNIQUE, IF_SCATTER, IF_MODABLE, IF_SINGLEMOD, IF_EXACTHIT },

		type       = ITEMTYPE_RANGED,
		ammo_id    = "cell",
		ammomax    = 50,
		damage     = "6d4",
		damagetype = DAMAGE_SPLASMA,
		acc        = 3,
		fire       = 10,
		radius     = 2,
		reload     = 20,
		shots      = 5,
		shotcost   = 5,
		altfire    = ALT_CHAIN,
		miscolor   = GREEN,
		misdelay   = 15,
		miss_base  = 30,
		miss_dist  = 5,
		missprite  = SPRITE_BFGSHOT,
		hitsprite  = SPRITE_BLAST,
		explosion  = {
			delay = 25,
			color = GREEN,
			flags = { EFHALFKNOCK, EFNODISTANCEDROP },
		},
	}

	register_item "urailgun"
	{
		name     = "Railgun",
		sound_id = "pistol",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PLASMA,
		psprite  = SPRITE_PLAYER_PLASMA,
		level    = 15,
		weight   = 2,
		scavenge = { "umod_sniper" },
		group    = "plasma",
		desc     = "Groovy! Wait 'til they stand in a row, and watch them being impaled.",
		flags    = { IF_UNIQUE, IF_MODABLE, IF_SINGLEMOD, IF_RAYGUN, IF_PIERCEHIT },

		type       = ITEMTYPE_RANGED,
		ammo_id    = "cell",
		ammomax    = 40,
		damage     = "8d8",
		damagetype = DAMAGE_BULLET,
		acc        = 12,
		fire       = 15,
		reload     = 20,
		shotcost   = 5,
		miscolor   = LIGHTGREEN,
		misdelay   = 50,
		miss_base  = 3,
		miss_dist  = 3,
		missprite = {
			sprite     = SPRITE_CSHOT,
			coscolor   = { 0.0,1.0,0.0,0.3 },
		},
		hitsprite  = SPRITE_BLAST,
	}

	register_item "umarmor"
	{
		name     = "Malek's Armor",
		color    = LIGHTGREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.0,0.4,1.0 },
		pcoscolor= { 1.0,0.0,0.4,1.0 },
		level    = 15,
		weight   = 2,
		desc     = "The personal armor of the most famous Imperial Inquisitor.",
		flags    = { IF_UNIQUE, IF_RECHARGE, IF_NODESTROY },
		set      = "inquisitor",
		scavenge = { "umod_nano" },

		rechargeamount = 5,
		rechargedelay  = 10,

		resist = { acid = 30, fire = 30, plasma = 30 },

		type       = ITEMTYPE_ARMOR,
		armor      = 3,
		movemod    = 20,
	}

	register_item "ucarmor"
	{
		name     = "Cybernetic Armor",
		color    = LIGHTGREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.9,0.9,1.0,1.0 },
		pcoscolor= { 0.9,0.9,1.0,1.0 },
		level    = 10,
		weight   = 2,
		flags    = { IF_UNIQUE, IF_CURSED, IF_NODESTROY, IF_MODABLE },
		desc     = "All those cybernetic dongles look fishy!",

		type       = ITEMTYPE_ARMOR,
		armor      = 7,
		movemod    = -30,
		knockmod   = -30,

		resist = { shrapnel = 20, melee = 20, bullet = 20, acid = 20, fire = 20, plasma = 20  },
	}

	register_item "unarmor"
	{
		name     = "Necroarmor",
		color    = LIGHTGREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.1,0.0,0.0,1.0 },
		pcoscolor= { 0.1,0.0,0.0,1.0 },
		level    = 10,
		weight   = 3,
		desc     = "Something about this armor gives you the chills.",
		flags    = { IF_UNIQUE, IF_NECROCHARGE, IF_NODESTROY },

		rechargeamount = 5,
		rechargedelay  = 0,

		type       = ITEMTYPE_ARMOR,
		armor      = 6,
		movemod    = 10,
		knockmod   = -20,
	}

	register_item "umedparmor"
	{
		name     = "Medical Powerarmor",
		color    = LIGHTGREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.3,0.3,1.0 },
		pcoscolor= { 1.0,0.3,0.3,1.0 },
		level    = 10,
		weight   = 2,
		desc     = "Very handy stuff on the battlefield! Why don't they mass-produce it?",
		flags    = { IF_UNIQUE, IF_NODESTROY },

		type       = ITEMTYPE_ARMOR,
		armor      = 6,
		movemod    = -15,

		OnEquipTick = function(self, being)
			if self.durability > 20 then
				if being.hp < being.hpmax / 2 then
					being.hp = being.hp + 1
					self.durability = self.durability - 1
				end
			end
		end,
	}

	register_item "ulavaarmor"
	{
		name     = "Lava Armor",
		color    = LIGHTGREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.8,0.0,1.0 },
		pcoscolor= { 1.0,0.8,0.0,1.0 },
		level    = 12,
		weight   = 2,
		desc     = "This armor glows!",
		flags    = { IF_UNIQUE, IF_NODESTROY, IF_NOREPAIR },
		scavenge = { "umod_firestorm" },

		resist = { fire = 75, plasma = 50 },

		type       = ITEMTYPE_ARMOR,
		armor      = 4,
		movemod    = -15,
		knockmod   = -20,

		OnEquipTick = function(self, being)
			if self.durability < self.maxdurability then
				if level.map[ being.position ] == cells[ "lava" ].nid then
					self.durability = math.min( self.durability + 5, self.maxdurability )
				end
			end
		end,
	}

	register_item "uenviroboots"
	{
		name     = "Enviroboots",
		color    = LIGHTGREEN,
		sprite   = SPRITE_BOOTS,
		coscolor = { 0.3,1.0,0.3,1.0 },
		level    = 10,
		weight   = 2,
		desc     = "I fear lava nor acid no more!",
		flags    = { IF_UNIQUE, IF_NODURABILITY, IF_PLURALNAME },

		resist = { fire = 100, acid = 100, plasma = 25 },

		type       = ITEMTYPE_BOOTS,
		armor      = 0,
		movemod    = -15,
		knockmod   = -50,
	}

	register_item "unboots"
	{
		name     = "Nyarlaptotep's Boots",
		color    = LIGHTGREEN,
		sprite   = SPRITE_BOOTS,
		coscolor = { 1.0,0.0,0.3,1.0 },
		level    = 15,
		weight   = 2,
		desc     = "The famous boots of the famous Imperial Inquisitor.",
		flags    = { IF_UNIQUE, IF_RECHARGE, IF_NODESTROY, IF_PLURALNAME },
		set      = "inquisitor",

		rechargeamount = 5,
		rechargedelay  = 10,

		resist = { fire = 30, acid = 30, plasma = 30 },

		type       = ITEMTYPE_BOOTS,
		armor      = 6,
		movemod    = 20,
	}

	register_item "ushieldarmor"
	{
		name     = "Shielded Armor",
		color    = LIGHTGREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.5,0.5,1.0,1.0 },
		pcoscolor= { 0.5,0.5,1.0,1.0 },
		level    = 10,
		weight   = 2,
		desc     = "So massive, you no longer fear the little ones!",
		flags    = { IF_UNIQUE, IF_NODURABILITY },
		scavenge = { "umod_onyx" },

		resist = { shrapnel = 90, melee = 90, bullet = 90 },

		type       = ITEMTYPE_ARMOR,
		armor      = 2,
		movemod    = -25,
		knockmod   = -50,
	}

	register_item "uhwpack"
	{
		name     = "Hellwave Pack",
		ascii    = "+",
		color    = LIGHTGREEN,
		sprite   = SPRITE_PHASE,
		sframes  = 2,
		coscolor = { 1.0,0.2,0.2,1.0 },
		level    = 10,
		weight   = 4,
		desc     = "I've got a hell-wave and I'm not afraid to surf it!",
		flags    = { IF_UNIQUE },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			ui.blink(LIGHTRED,50)
			ui.blink(RED,50,50)
			ui.blink(LIGHTRED,50,100)
			level:explosion( being.position , { range = 15, delay = 80, damage = "20d10", color = RED, sound_id = "barrel.explode", damage_type = DAMAGE_FIRE, flags = { EFSELFSAFE } }, self )
			return true
		end,
	}

	register_item "aarmor"
	{
		name     = "Angelic Armor",
		color    = YELLOW,
		sprite   = SPRITE_AARMOR,
		glow     = { 1.0,1.0,0.0,1.0 },
		pglow    = { 1.0,1.0,0.0,1.0 },
		level    = 200,
		weight   = 0,
		set      = "angelic",
		desc     = "This armor looks as if it belonged to an Archangel. You bet his name was Tyrael.",
		firstmsg = "So beautiful...",
		flags    = { IF_UNIQUE, IF_NODESTROY },

		resist = { shrapnel = 50, melee = 50, bullet = 50 },

		type       = ITEMTYPE_ARMOR,
		armor      = 7,
	}

	register_item "uberarmor"
	{
		name     = "Berserker Armor",
		color    = LIGHTGREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.1,0.0,0.0,1.0 },
		pcoscolor= { 0.1,0.0,0.0,1.0 },
		glow     = { 1.0,0.0,0.0,1.0 },
		pglow    = { 1.0,0.0,0.0,1.0 },
		level    = 10,
		weight   = 1,
		desc     = "How in the world could one wear that???",
		flags    = { IF_UNIQUE, IF_CURSED, IF_NODESTROY, IF_NODURABILITY },

		type       = ITEMTYPE_ARMOR,
		armor      = 0,
		movemod    = -70,
		knockmod   = -90,

		resist = { shrapnel = 50, melee = 50, bullet = 50 },

		OnPickupCheck = function (self,being)
			if not being:is_player() then return false end
			return true
		end,

		OnEquipCheck = function (self,being)
			if not being:is_player() then return false end
			if not being.eq.weapon or being.eq.weapon.id ~= "udragon" or (being.hp >= being.hpmax / 2) then
				ui.msg("How am I supposed to wear this thing??")
				return false
			end
			return true
		end,

		OnEquipTick = function(self, being)
			self.armor = math.floor((1-(math.min(being.hp,being.hpmax) / being.hpmax)) * 16) + 4
			if math.random(20) == 1 then
				-- Meh.  Nightmare demons are too easy anyway.  This should convince the player to wear BA only when it is time to summon the Apostle.
				local demon = level:summon( "ncacodemon" )
				if demon then
					demon.flags[ BF_NOEXP ] = true
				end
			end
		end,
	}

	register_medal "dragonslayer"
	{
		name = "Gutts' Heart",
		desc = "Awarded for winning with the Dragonslayer",
		hidden = true,
	}

	-- This is also a rarity
	register_medal "dragonslayed"
	{
		name = "Gutts' Sorrow",
		desc = "Awarded for dying with the Dragonslayer",
		hidden = true,
		condition = function() return player.hp <= 0 and (player.eq.weapon and player.eq.weapon.id == "udragon") end,
	}

	register_item "udragon"
	{
		name     = "Dragonslayer",
		color    = LIGHTGREEN,
		sprite   = SPRITE_DRAGON,
		psprite  = SPRITE_PLAYER_DRAGON,
		glow     = { 1.0,0.0,0.0,1.0 },
		level    = 16,
		weight   = 1,
		group    = "melee",
		desc     = "It was called the Dragonslayer, because no human could wield it...",
		flags    = { IF_UNIQUE, IF_CURSED },
		knockmod = -50,

		type        = ITEMTYPE_MELEE,
		damage      = "9d9",
		damagetype  = DAMAGE_MELEE,
		altfire     = ALT_SCRIPT,
		altfirename = "whirlwind",

		OnCreate = function(self)
			self:add_property( "BLADE", true )
		end,
		
		OnPickupCheck = function (self,being)
			-- XXX Maybe we should allow Barons of Hell to wield it since they are not really human...
			if not being:is_player() then return false end
			if being:is_affect("berserk") and being.eq:empty() then
				return true
			end
			ui.msg("It's too heavy! No human could ever wield this thing...")
			return false
		end,

		OnAltFire = function( self, being )
			if being:is_affect( "tired" ) then
				ui.msg("You're too tired to do that right now!")
			else
				local scount = being.scount
				local pos    = being.position
				local use    = self.usetime
				self.usetime = 4
				ui.msg("Whirlwind!")
				for c in area.around( pos, 1 )() do
					if c ~= pos and area.FULL:contains( c ) then
						being:attack( c )
					end
				end
				self.usetime = use
				being:set_affect( "tired" )
				being.scount = scount - math.max( ( self.usetime * being.firetime * 8 - 5000 ), 8 * being.speed )
			end
			return false
		end,

		OnPickup = function (self,being)
			being:quick_weapon("udragon")
			ui.blink(RED,50)
			ui.blink(LIGHTRED,50,50)
			ui.msg("Release the power of the BERSERKER!")
			being:set_affect( "berserk" )
		end,

		OnKill = function (self,being,target)
			if target.id == "mastermind" and target.is_boss then
				being:add_medal("dragonslayer")
			end
		end,

		OnEquipTick = function(self, being)
			if math.random(40) == 1 then
				-- The DS shouldn't be an easy I-Win! button.  Make YAAM harder.
				local demon = level:summon( "ndemon" )
				if demon then
					demon.flags[ BF_NOEXP ] = true
				end
			end
		end,
	}
end
