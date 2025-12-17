function drl.register_exotic_items()

	-- Item sets --
	register_itemset "gothic"
	{
		name    = "Gothic Arms",
		trigger = 2,

		OnEquip = function (self,being)
			being.flags[ BF_SESSILE ] = true
			being.armor = being.armor + 2
			being.resist.bullet   = (being.resist.bullet or 0) + 40
			being.resist.melee    = (being.resist.melee or 0) + 40
			being.resist.shrapnel = (being.resist.shrapnel or 0) + 40
			being.resist.acid     = (being.resist.acid or 0) + 40
			being.resist.fire     = (being.resist.fire or 0) + 40
			being.resist.plasma   = (being.resist.plasma or 0) + 40
			being:msg( "Suddenly you feel immobilized. You feel like a fortress!" )
		end,

		OnUnequip = function (self,being)
			being.flags[ BF_SESSILE ] = false
			being.armor = being.armor - 2
			being.resist.bullet   = (being.resist.bullet or 0) - 40
			being.resist.melee    = (being.resist.melee or 0) - 40
			being.resist.shrapnel = (being.resist.shrapnel or 0) - 40
			being.resist.acid     = (being.resist.acid or 0) - 40
			being.resist.fire     = (being.resist.fire or 0) - 40
			being.resist.plasma   = (being.resist.plasma or 0) - 40
			being:msg( "You feel more agile and less protected." )
		end,
	}

	register_itemset "phaseshift"
	{
		name    = "Phaseshift Suit",
		trigger = 2,

		OnEquip = function (self,being)
			being.flags[ BF_ENVIROSAFE ] = true
			being.flags[ BF_FLY ] = true
			being:msg( "You start to float!" )
		end,

		OnUnequip = function (self,being)
			being.flags[ BF_ENVIROSAFE ] = false
			being.flags[ BF_FLY ] = false
			being:msg( "You touch the ground." )
		end,
	}

	-- "Normal" exotics

	register_item "chainsaw"
	{
		name     = "chainsaw",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_CHAINSAW,
		psprite  = SPRITE_PLAYER_CHAINSAW,
		level    = 12,
		weight   = 6,
		group    = "melee",
		desc     = "Chainsaw -- cuts through flesh like a hot knife through butter.",
		flags    = { IF_EXOTIC },

		type        = ITEMTYPE_MELEE,
		damage      = "4d6",
		damagetype  = DAMAGE_MELEE,

		OnFirstPickup = function(self,being)
			if not being:is_player() then return end
			ui.blink(LIGHTRED,100)
			-- XXX Should this be given on first pick-up ALWAYS or only when in chain court?
			being:add_perk( "berserk",200*diff[DIFFICULTY].powerfactor)
			if not being.flags[ BF_NOHEAL ] and being.hp < being.hpmax then
				being.hp = being.hpmax
			end
			being:remove_perk( "tired" )
			being:quick_weapon("chainsaw")
			ui.msg("BLOOD! BLOOD FOR ARMOK, GOD OF BLOOD!")
		end
	}

	register_item "bfg9000"
	{
		name     = "BFG 9000",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BFG9000,
		psprite  = SPRITE_PLAYER_BFG9000,
		level    = 20,
		weight   = 4,
		group    = "bfg",
		desc     = "The Big Fucking Gun. Hell wouldn't be fun without it.",
		flags    = { IF_EXOTIC, IF_EXACTHIT },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 100,
		damage        = "10d6",
		damagetype    = DAMAGE_SPLASMA,
		acc           = 5,
		radius        = 8,
		reloadtime    = 20,
		shotcost      = 40,
		misascii      = "*",
		miscolor      = WHITE,
		misdelay      = 100,
		miss_base     = 50,
		miss_dist     = 10,
		missprite     = SPRITE_BFGSHOT,
		hitsprite     = SPRITE_BLAST,
		explosion     = {
			delay     = 33,
			color     = GREEN,
			flags     = { EFSELFSAFE, EFAFTERBLINK, EFCHAIN, EFNODISTANCEDROP },
			knockback = 16,
		},

		OnCreate = function(self)
			self:add_perk( "perk_altreload_overcharge" )
		end,

		OnFirstPickup = function(self,being)
			if not being:is_player() then return end
			being:quick_weapon("bfg9000")
			ui.blink(LIGHTBLUE,100)
			ui.blink(WHITE,100,100)
			ui.blink(LIGHTBLUE,100,200)
			ui.msg("HELL, NOW YOU'LL GET LOOSE!")
		end,
	}

	-- rest of the exotic weapons

	register_item "ublaster"
	{
		name     = "blaster",
		sound_id = "plasma",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_PISTOL,
		psprite  = SPRITE_PLAYER_PISTOL,
		level    = 8,
		weight   = 2,
		group    = "pistol",
		desc     = "This is the standard issue rechargeable energy side-arm. Cool!",
		flags    = { IF_EXOTIC, IF_NORELOAD, IF_NOUNLOAD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 10,
		damage        = "2d4",
		damagetype    = DAMAGE_PLASMA,
		acc           = 3,
		usetime       = 9,
		reloadtime    = 10,
		altfire       = ALT_SCRIPT,
		miscolor      = MULTIYELLOW,
		misdelay      = 10,
		miss_base     = 30,
		miss_dist     = 5,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_altfire_aimed" )
			self:add_perk( "perk_weapon_recharge" )
			self.pp_recharge.delay  = 3
			self.pp_recharge.amount = 1
		end,
	}

	register_item "ucpistol"
	{
		name     = "combat pistol",
		sound_id = "pistol",

		color    = LIGHTMAGENTA,
		sprite   = SPRITE_PISTOL,
		psprite  = SPRITE_PLAYER_PISTOL,
		level    = 4,
		weight   = 6,
		group    = "pistol",
		desc     = "This is the kind of handgun given to your superiors. Doesn't look like they're using it right now...",
		flags    = { IF_EXOTIC, },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 15,
		damage        = "3d3",
		damagetype    = DAMAGE_BULLET,
		acc           = 5,
		reloadtime    = 18,
		altfire       = ALT_SCRIPT,
		miscolor      = LIGHTGRAY,
		misdelay      = 15,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_altfire_aimed" )
		end,
	}

	register_item "uashotgun"
	{
		name     = "assault shotgun",
		sound_id = "ashotgun",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_CSHOTGUN,
		psprite  = SPRITE_PLAYER_CSHOTGUN,
		level    = 6,
		weight   = 6,
		group    = "shotgun",
		desc     = "Big, bad and ugly.",
		flags    = { IF_EXOTIC, IF_SINGLERELOAD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "shell",
		ammomax       = 6,
		damage        = "7d3",
		damagetype    = DAMAGE_SHARPNEL,
		spread        = 2,
		falloff       = 5,
		knockback     = 8,
		range         = 15,
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_pump_action" )
		end,
	}

	register_item "upshotgun"
	{
		name     = "plasma shotgun",
		sound_id = "ashotgun",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_SHOTGUN,
		psprite  = SPRITE_PLAYER_SHOTGUN,
		level    = 12,
		weight   = 4,
		group    = "shotgun",
		desc     = "Plasma shotgun -- the best of two worlds.",
		firstmsg = "Splash and they're dead!",
		flags    = { IF_EXOTIC },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 30,
		shotcost      = 3,
		damage        = "7d3",
		damagetype    = DAMAGE_PLASMA,
		reloadtime    = 20,
		range         = 15,
		spread        = 3,
		falloff       = 5,
		knockback     = 12,
		hitsprite     = SPRITE_BLAST,
	}

	register_item "udshotgun"
	{
		name     = "super shotgun",
		sound_id = "dshotgun",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_DSHOTGUN,
		psprite  = SPRITE_PLAYER_DSHOTGUN,
		level    = 10,
		weight   = 5,
		group    = "shotgun",
		desc     = "After the first hellish invasion, weapon engineers designed the super shotgun as the world's first firearm designed to kill demons. And boy does it do a good job.",
		firstmsg = "This little baby brings back memories!",
		flags    = { IF_EXOTIC, IF_DUALSHOTGUN },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "shell",
		ammomax       = 2,
		damage        = "8d4",
		damagetype    = DAMAGE_SHARPNEL,
		reloadtime    = 15,
		shots         = 2,
		range         = 15,
		spread        = 3,
		falloff       = 7,
		knockback     = 8,
		hitsprite     = SPRITE_BLAST,
	}

	register_item "ulaser"
	{
		name     = "laser rifle",
		sound_id = "plasma",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_PLASMA,
		psprite  = SPRITE_PLAYER_PLASMA,
		level    = 12,
		weight   = 5,
		group    = "plasma",
		desc     = "With no recoil and pinpoint accuracy, it takes a world-class moron to miss while using a laser rifle.",
		firstmsg = "The sniper chain weapon!",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_RANGED,
		ammo_id    = "cell",
		ammomax    = 40,
		damage     = "1d7",
		damagetype = DAMAGE_PLASMA,
		acc        = 8,
		reloadtime = 15,
		shots      = 5,
		altfire    = ALT_SCRIPT,
		miscolor   = MULTIYELLOW,
		misdelay   = 10,
		miss_base  = 10,
		miss_dist  = 3,
		missprite  = {
			sprite = SPRITE_CSHOT,
			coscolor   = { 1.0, 1.0, 0.0, 1.0 },
		},
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_altfire_chainfire" )
		end,
	}

	register_item "utristar"
	{
		name     = "tristar blaster",
		sound_id = "plasma",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_DSHOTGUN,
		psprite  = SPRITE_PLAYER_DSHOTGUN,
		level    = 12,
		weight   = 4,
		group    = "plasma",
		desc     = "Now this is a weird weapon.",
		firstmsg = "Quite bulky!",
		flags    = { IF_EXOTIC, IF_SPREAD },

		type       = ITEMTYPE_RANGED,
		ammo_id    = "cell",
		ammomax    = 45,
		damage     = "4d5",
		damagetype = DAMAGE_PLASMA,
		acc        = 5,
		radius     = 2,
		reloadtime = 15,
		shots      = 3,
		shotcost   = 5,
		misascii   = "*",
		miscolor   = LIGHTBLUE,
		misdelay   = 20,
		miss_base  = 1,
		miss_dist  = 3,
		missprite  = SPRITE_PLASMASHOT,
		hitsprite  = SPRITE_BLAST,
		explosion  = {
			delay = 40,
			color = LIGHTBLUE,
		},
	}

	register_item "uminigun"
	{
		name     = "minigun",
		sound_id = "chaingun",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_CHAINGUN,
		psprite  = SPRITE_PLAYER_CHAINGUN,
		level    = 10,
		weight   = 6,
		group    = "chain",
		desc     = "Spits enough lead into the air to be considered an environmental hazard.",
		flags    = { IF_EXOTIC },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 200,
		damage        = "1d6",
		damagetype    = DAMAGE_BULLET,
		acc           = 1,
		usetime       = 12,
		reloadtime    = 35,
		shots         = 8,
		altfire       = ALT_SCRIPT,
		miscolor      = WHITE,
		misdelay      = 10,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_altfire_chainfire" )
		end,
	}

	register_item "umbazooka"
	{
		name     = "missile launcher",
		sound_id = "bazooka",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BAZOOKA,
		psprite  = SPRITE_PLAYER_BAZOOKA,
		level    = 10,
		weight   = 6,
		group    = "rocket",
		desc     = "The definitive upgrade to the rocket launcher.",
		flags    = { IF_EXOTIC, IF_SINGLERELOAD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "rocket",
		ammomax       = 4,
		damage        = "6d6",
		damagetype    = DAMAGE_FIRE,
		acc           = 10,
		radius        = 3,
		usetime       = 8,
		reloadtime    = 12,
		miscolor      = BROWN,
		misdelay      = 30,
		miss_base     = 30,
		miss_dist     = 5,
		missprite     = SPRITE_ROCKETSHOT,
		hitsprite     = SPRITE_BLAST,
		explosion     = {
			delay 	= 40,
			color 	= RED,
		},

		OnCreate = function(self)
			self:add_perk( "perk_pump_action" )
		end,
	}

	register_item "unplasma"
	{
		name     = "nuclear plasma rifle",
		sound_id = "plasma",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_PLASMA,
		psprite  = SPRITE_PLAYER_PLASMA,
		level    = 15,
		weight   = 4,
		group    = "plasma",
		desc     = "A self-charging plasma rifle -- too bad it can't be manually reloaded.",
		flags    = { IF_EXOTIC, IF_NORELOAD, IF_NOUNLOAD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 24,
		damage        = "1d7",
		damagetype    = DAMAGE_PLASMA,
		acc           = 2,
		reloadtime    = 20,
		shots         = 6,
		altfire       = ALT_SCRIPT,
		misascii      = "*",
		miscolor      = MULTIBLUE,
		misdelay      = 10,
		miss_base     = 30,
		miss_dist     = 3,
		missprite     = SPRITE_PLASMASHOT,
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_altfire_chainfire" )
			self:add_perk( "perk_altreload_nuke" )
			self:add_perk( "perk_weapon_recharge" )
			self.pp_recharge.delay  = 4
			self.pp_recharge.amount = 4
		end,
	}

	register_item "unbfg9000"
	{
		name     = "nuclear BFG 9000",
		sound_id = "bfg9000",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BFG9000,
		psprite  = SPRITE_PLAYER_BFG9000,
		level    = 22,
		weight   = 2,
		group    = "bfg",
		desc     = "A self-charging BFG9000! How much more lucky can you get?",
		flags    = { IF_EXOTIC, IF_NORELOAD, IF_NOUNLOAD, IF_EXACTHIT },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 40,
		damage        = "8d6",
		damagetype    = DAMAGE_SPLASMA,
		acc           = 5,
		radius        = 8,
		usetime       = 15,
		reloadtime    = 20,
		shotcost      = 40,
		misascii      = "*",
		miscolor      = WHITE,
		misdelay      = 100,
		miss_base     = 50,
		miss_dist     = 10,
		missprite     = SPRITE_BFGSHOT,
		hitsprite     = SPRITE_BLAST,
		explosion     = {
			delay     = 33,
			color     = GREEN,
			flags     = { EFSELFSAFE, EFAFTERBLINK, EFCHAIN, EFNODISTANCEDROP },
			knockback = 16,
		},

		OnCreate = function(self)
			self:add_perk( "perk_altreload_nuke" )
			self:add_perk( "perk_weapon_recharge" )
			self.pp_recharge.delay  = 0
			self.pp_recharge.amount = 1
		end,
	}

	register_perk "perk_utrans_hit"
	{
		OnHitBeing = function(self,being,target)
			target:play_sound("phasing")
			being:msg("Suddenly "..target:get_name(true,false).." blinks away!")
			level:explosion( target.position, { range = 2, delay = 50, color = LIGHTBLUE } )
			target:phase()
			return false
		end,
	}

	register_item "utrans"
	{
		name     = "combat translocator",
		sound_id = "plasma",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_PLASMA,
		psprite  = SPRITE_PLAYER_PLASMA,
		level    = 14,
		weight   = 3,
		group    = "plasma",
		desc     = "Now this is a piece of weird technology, wonder how it works?",
		firstmsg = "Well this is a weird device!",
		flags    = { IF_EXOTIC, IF_NONMODABLE },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 60,
		damage        = "0d0",
		damagetype    = DAMAGE_PLASMA,
		acc           = 4,
		reloadtime    = 20,
		shotcost      = 5,
		misascii      = "*",
		miscolor      = MULTIBLUE,
		misdelay      = 10,
		miss_base     = 30,
		miss_dist     = 3,
		altfire       = ALT_SCRIPT,
		altfirename   = "self-target",
		missprite     = SPRITE_PLASMASHOT,
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_utrans_hit" )
		end,

		OnAltFire = function(self,being)
			if self.ammo < 30 then 
				being:msg("You have not enough ammo to self-target!")
			else
				self.ammo = self.ammo - 30
				being:msg("You feel yanked in a non-descript direction!")
				level:explosion( being.position, { range = 2, delay = 50, color = LIGHTBLUE } )
				being:phase();
				being.scount = being.scount - 1000
			end
			return false
		end,
	}

	register_item "unapalm"
	{
		name     = "napalm launcher",
		sound_id = "bazooka",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BAZOOKA,
		psprite  = SPRITE_PLAYER_BAZOOKA,
		level    = 10,
		weight   = 6,
		group    = "rocket",
		desc     = "This will surely make a mess!",
		flags    = { IF_EXOTIC, IF_SINGLERELOAD },

		type       = ITEMTYPE_RANGED,
		ammo_id    = "rocket",
		ammomax    = 1,
		damage     = "7d7",
		damagetype = DAMAGE_FIRE,
		acc        = 10,
		radius     = 2,
		usetime    = 8,
		reloadtime = 12,
		miscolor   = BROWN,
		misdelay   = 10,
		miss_base  = 30,
		miss_dist  = 5,
		missprite  = SPRITE_ROCKETSHOT,
		hitsprite  = SPRITE_BLAST,
		explosion  = {
			delay = 80,
			color = RED,
			content = "lava",
		},
	}

	register_item "uoarmor"
	{
		name     = "onyx armor",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.1,0.1,0.1,1.0 },
		pcoscolor= { 0.1,0.1,0.1,1.0 },
		level    = 7,
		weight   = 4,
		desc     = "This thing looks absurdly resistant.",
		flags    = { IF_EXOTIC, IF_NODURABILITY },

		type       = ITEMTYPE_ARMOR,
		armor      = 2,
		movemod    = -25,
	}

	register_item "uparmor"
	{
		name     = "phaseshift armor",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.2,1.0,0.2,1.0 },
		pcoscolor= { 0.2,1.0,0.2,1.0 },
		level    = 10,
		weight   = 6,
		set      = "phaseshift",
		desc     = "Shiny and high-tech, feels like it almost floats by itself.",
		flags    = { IF_EXOTIC },

		resist = { bullet = 30, melee = 30, shrapnel = 30 },

		type       = ITEMTYPE_ARMOR,
		armor      = 2,
		movemod    = 25,
		knockmod   = 50,
	}

	register_item "upboots"
	{
		name     = "phaseshift boots",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BOOTS,
		coscolor = { 0.2,1.0,0.2,1.0 },
		level    = 8,
		weight   = 6,
		set      = "phaseshift",
		desc     = "Shiny and high-tech, feels like they almost float by themselves.",
		flags    = { IF_EXOTIC, IF_PLURALNAME },

		type       = ITEMTYPE_BOOTS,
		armor      = 4,
		movemod    = 15,
		knockmod   = 20,
	}

	register_item "ugarmor"
	{
		name     = "gothic armor",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.7,0.0,0.0,1.0 },
		pcoscolor= { 0.7,0.0,0.0,1.0 },
		level    = 15,
		weight   = 6,
		set      = "gothic",
		desc     = "It's surprising that one can actually still move in this monolithic thing.",
		flags    = { IF_EXOTIC },

		resist = { bullet = 50, melee = 50, shrapnel = 50 },

		type       = ITEMTYPE_ARMOR,
		armor      = 6,
		durability = 200,
		movemod    = -70,
		knockmod   = -90,
	}

	register_item "ugboots"
	{
		name     = "gothic boots",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BOOTS,
		coscolor = { 0.7,0.0,0.0,1.0 },
		level    = 10,
		weight   = 6,
		set      = "gothic",
		desc     = "It's surprising that one can actually still move in these monolithic boots.",
		flags    = { IF_EXOTIC, IF_PLURALNAME },

		type       = ITEMTYPE_BOOTS,
		armor      = 10,
		durability = 200,
		movemod    = -10,
		knockmod   = -70,
	}

	register_perk "perk_umedarmor"
	{
		OnEquipTick = function(self,being)
			if self.durability > 20 then
				if being.hp < being.hpmax / 2 then
					being.hp = being.hp + 1
					self.durability = self.durability - 1
				end
			end
		end,
	}

	register_item "umedarmor"
	{
		name     = "medical armor",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.2,0.2,1.0 },
		pcoscolor= { 1.0,0.2,0.2,1.0 },
		level    = 5,
		weight   = 6,
		desc     = "Handy stuff on the battlefield, why don't they give it to regular marines?",
		flags    = { IF_EXOTIC },

		resist     = { fire = 15, acid = 15, plasma = 15 },
		type       = ITEMTYPE_ARMOR,
		armor      = 2,
		movemod    = -15,

		OnCreate = function(self)
			self:add_perk( "perk_umedarmor" )
		end,
	}

	register_item "uduelarmor"
	{
		name     = "duelist armor",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.4,0.4,0.4,1.0 },
		pcoscolor= { 0.4,0.4,0.4,1.0 },
		level    = 5,
		weight   = 6,
		desc     = "A little archaic, but a surprisingly well-kept armor.",
		flags    = { IF_EXOTIC },

		resist = { melee = 75, },

		type       = ITEMTYPE_ARMOR,
		armor      = 2,
		movemod    = 15,
		knockmod   = -15,
	}

	register_item "ubulletarmor"
	{
		name     = "bullet-proof vest",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.6,0.6,0.6,1.0 },
		pcoscolor= { 0.6,0.6,0.6,1.0 },
		level    = 2,
		weight   = 6,
		desc     = "Maybe too specialized for most tastes.",
		flags    = { IF_EXOTIC },

		resist = { bullet  = 95 },

		type       = ITEMTYPE_ARMOR,
		armor      = 1,
	}

	register_item "uballisticarmor"
	{
		name     = "ballistic vest",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.2,0.6,0.2,1.0 },
		pcoscolor= { 0.2,0.6,0.2,1.0 },
		level    = 2,
		weight   = 5,
		desc     = "Might serve one well in the beginning.",
		flags    = { IF_EXOTIC },

		resist = { bullet = 50, melee = 50, shrapnel = 50 },

		type       = ITEMTYPE_ARMOR,
		armor      = 1,
	}

	register_item "ueshieldarmor"
	{
		name     = "energy-shielded vest",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.6,0.0,1.0 },
		pcoscolor= { 1.0,0.6,0.0,1.0 },
		level    = 5,
		weight   = 3,
		desc     = "If it just wouldn't be so fragile...",
		flags    = { IF_EXOTIC },

		resist = { fire = 50, acid = 50, plasma = 50 },

		type       = ITEMTYPE_ARMOR,
		armor      = 1,
	}

	register_item "uplasmashield"
	{
		name     = "plasma shield",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.0,1.0,1.0 },
		pcoscolor= { 1.0,0.0,1.0,1.0 },
		level    = 10,
		weight   = 3,
		desc     = "Under some circumstances, this is the best thing... too bad it can't be repaired.",
		flags    = { IF_EXOTIC, IF_NOREPAIR, IF_NONMODABLE, IF_NODEGRADE },

		resist = { plasma  = 95 },

		type       = ITEMTYPE_ARMOR,
		armor      = 0,
	}

	register_item "uenergyshield"
	{
		name     = "energy shield",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.8,0.0,1.0 },
		pcoscolor= { 1.0,0.8,0.0,1.0 },
		level    = 8,
		weight   = 3,
		desc     = "Under some circumstances, this is the best thing... too bad it can't be repaired.",
		flags    = { IF_EXOTIC, IF_NOREPAIR, IF_NONMODABLE, IF_NODEGRADE },

		resist = { fire = 80, acid = 80, plasma = 80 },

		type       = ITEMTYPE_ARMOR,
		armor      = 0,
	}

	register_item "ubalshield"
	{
		name     = "ballistic shield",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.8,0.8,0.3,1.0 },
		pcoscolor= { 0.8,0.8,0.3,1.0 },
		level    = 6,
		weight   = 3,
		desc     = "Under some circumstances, this is the best thing... too bad it can't be repaired.",
		flags    = { IF_EXOTIC, IF_NOREPAIR, IF_NONMODABLE, IF_NODEGRADE },

		resist = { bullet = 95, melee = 95, shrapnel = 95 },

		type       = ITEMTYPE_ARMOR,
		armor      = 0,
	}

	register_item "uacidboots"
	{
		name     = "acid-proof boots",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BOOTS,
		coscolor = { 0.2,1.0,0.0,1.0 },
		level    = 8,
		weight   = 5,
		desc     = "The best thing to carry for an acid-bath.",
		flags    = { IF_EXOTIC, IF_PLURALNAME },

		resist = { acid = 100 },

		type       = ITEMTYPE_BOOTS,
		armor      = 0,
	}

	register_item "ubloodboots"
	{
		name     = "blood boots",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_BOOTS,
		coscolor = { 1.0,0.2,0.0,1.0 },
		level    = 20,
		weight   = 3,
		desc     = "Pair of archaic looking creepy looking boots.",
		flags    = { IF_EXOTIC, IF_PLURALNAME },

		resist = { plasma = 100 },

		type       = ITEMTYPE_BOOTS,
		armor      = 0,
	}

  -- Exotic Mods

	register_item "umod_firestorm"
	{
		name     = "firestorm weapon pack",
		ascii    = "\"",
		color    = RED,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		coscolor = { 1.0,0.0,1.0,1.0 },
		level    = 10,
		weight   = 4,
		desc     = "A modification for rapid or explosive weapons -- increases shots by 2 for rapid, and blast radius by 2 for explosive weapons.",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,
		mod_letter = "F",

		OnUseCheck = function(self,being)
			local function filter( item )
				if item.itype ~= ITEMTYPE_RANGED then return false end
				if item.group ~= "shotgun" and ( item.shots >= 3 ) and ( not item.flags[ IF_SPREAD ]) then
					return true
				elseif ( item.radius >= 3 ) or ( item.flags[ IF_SPREAD ] and ( item.radius >= 2 ) ) then
					return true
				else
					return false
				end
			end
			local item, result = being:pick_item_to_mod( self, filter )
			if not result then return false end
			if item ~= nil then self:add_property("chosen_item", item) end
			return true
		end,

		OnModDescribe = function( self, item )
			if item.group ~= "shotgun" and ( item.shots >= 3 ) and ( not item.flags[ IF_SPREAD ]) then
				return "shots {!"..item.shots.."} -> {!"..(item.shots+2).."}"
			elseif ( item.radius >= 3 ) or ( item.flags[ IF_SPREAD ] and ( item.radius >= 2 ) ) then
				return "blast radius {!"..item.radius.."} -> {!"..(item.radius+2).."}"
			end
			return "unknown"
		end,

		OnUse = function(self,being)
			if not self:has_property( "chosen_item" ) then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			if item.group ~= "shotgun" and ( item.shots >= 3 ) and ( not item.flags[ IF_SPREAD ]) then
				item.shots = item.shots + 2
			elseif ( item.radius >= 3 ) or ( item.flags[ IF_SPREAD ] and ( item.radius >= 2 ) ) then
				item.radius = item.radius + 2
			end
			ui.msg( "You upgrade your weapon!" )
			item:add_mod( 'F', being.techbonus )
			return true
		end,
	}

	register_item "umod_sniper"
	{
		name     = "sniper weapon pack",
		ascii    = "\"",
		color    = MAGENTA,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		coscolor = { 0.0,0.5,0.0,1.0 },
		level    = 10,
		weight   = 4,
		desc     = "A high-tech modification for ranged weapons -- implements an advanced auto-hit mechanism.",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,
		mod_letter = "S",

		OnUseCheck = function(self,being)
			local function filter( item )
				return item.itype == ITEMTYPE_RANGED
			end
			local item, result = being:pick_item_to_mod( self, filter )
			if not result then return false end
			if item ~= nil then self:add_property("chosen_item", item) end
			return true
		end,

		OnModDescribe = function( self, item )
			if item.flags[IF_FARHIT] == true then
				return "remove unseen enemy to-hit penalty"
			else
				return "remove distance to-hit penalty"
			end
			return "unknown"
		end,

		OnUse = function(self,being)
			if not self:has_property( "chosen_item" ) then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			-- A little easter egg for applying S-mod on shotgun/melee
			if item.group == "shotgun" or item.itype ~= ITEMTYPE_RANGED then
				ui.msg( "You suddenly feel a little silly." )
			else
				ui.msg( "You upgrade your weapon!" )
			end
			if item.flags[IF_FARHIT] == true then
				item.flags[IF_UNSEENHIT] = true
			else
				item.flags[IF_FARHIT] = true
			end
			item:add_mod( 'S', being.techbonus )
			return true
		end,
	}

	register_item "umod_nano"
	{
		name     = "nano pack",
		ascii    = "\"",
		color    = GREEN,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		coscolor = { 0.5,0.5,1.0,1.0 },
		level    = 10,
		weight   = 4,
		desc     = "Nanotechnology -- modified weapon reconstructs shot ammo, modified armor/boots reconstruct itself",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,
		mod_letter = "N",

		OnUseCheck = function(self,being)
			local function filter( item )
				if item.itype == ITEMTYPE_MELEE then return false end
				if item:has_property("pp_recharge") then
					local r = item.pp_recharge
					if r.delay == 0 and r.amount >= item.ammomax then return false end
				end
				return true
			end
			local item, result = being:pick_item_to_mod( self, filter )
			if not result then return false end
			if item ~= nil then self:add_property("chosen_item", item) end
			return true
		end,

		OnModDescribe = function( self, item )
			if item:has_property("pp_recharge") then
				local r = item.pp_recharge
				if r.delay == 0 then
					return "recharge amount {!"..r.amount.."} -> {!"..(r.amount+1).."}"
				else
					return "recharge delay {!"..r.delay.."} -> {!"..math.max(0, r.delay-5).."}"
				end
			else
				if item.itype == ITEMTYPE_RANGED then
					return "recharge ammo"
				elseif item.itype == ITEMTYPE_ARMOR or item.itype == ITEMTYPE_BOOTS then
					return "recharge durability"
				end	
			end
			return "unknown"
		end,

		OnUse = function(self,being)
			if not self:has_property( "chosen_item" ) then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			ui.msg( "You upgrade your gear!" )
			item:add_mod( 'N', being.techbonus )
			if item:has_property("pp_recharge") then
				local r = item.pp_recharge
				if r.delay == 0 then
					r.amount = r.amount + 1
				else
					r.delay = math.max(0, r.delay - 5)
				end
			else
				if item.itype == ITEMTYPE_ARMOR or item.itype == ITEMTYPE_BOOTS then
					item:add_perk( "perk_armor_recharge" )
					item.pp_recharge.delay  = 5
					item.pp_recharge.amount = 2
				elseif item.itype == ITEMTYPE_RANGED then
					item:add_perk( "perk_weapon_recharge" )
					item.pp_recharge.delay  = 5
					item.pp_recharge.amount = 1
				end
			end
			return true
		end,
	}

	register_item "umod_onyx"
	{
		name     = "onyx armor pack",
		ascii    = "\"",
		color    = LIGHTGRAY,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		coscolor = { 0.0,0.0,0.0,1.0 },
		level    = 10,
		weight   = 4,
		desc     = "A modification for boots and armors -- makes them indestructible.",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,
		mod_letter = "O",

		OnUseCheck = function(self,being)
			local function filter( item )
				return ( item.itype == ITEMTYPE_ARMOR or item.itype == ITEMTYPE_BOOTS )
			end
			local item, result = being:pick_item_to_mod( self, filter )
			if not result then return false end
			if item ~= nil then self:add_property( "chosen_item", item ) end
			return true
		end,

		OnModDescribe = function( self, item )
			return "make indestructible"
		end,

		OnUse = function(self,being)
			if not self:has_property( "chosen_item" ) then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			ui.msg( "You upgrade your gear!" )
			item.durability = 100
			item.flags[ IF_NODURABILITY ] = true
			item:add_mod( 'O', being.techbonus )
			return true
		end,
	}

	register_item "uswpack"
	{
		name     = "shockwave pack",
		ascii    = "+",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_PHASE,
		sframes  = 2,
		coscolor = { 0.7,0.0,0.0,1.0 },
		level    = 5,
		weight   = 10,
		desc     = "Woah, what a useful device. Just wait for them to surround you...",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			ui.blink(LIGHTRED,50)
			level:explosion( being.position , { range = 6, delay = 50, damage = "10d10", color = RED, sound_id = "barrel.explode", flags = { EFSELFSAFE } }, self )
			return true
		end,
	}

	register_item "ubskull"
	{
		name     = "blood skull",
		ascii    = "+",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_SKULL,
		sframes  = 2,
		coscolor = { 1.0,0.0,0.0,1.0 },
		level    = 5,
		weight   = 8,
		desc     = "This skull gives you the shivers... like it would lust for blood.",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			ui.blink(LIGHTRED,50)
			local p = being.position
			for c in area.around( p, 8 ):clamped( area.FULL ):coords() do
				if coord.distance( c, p ) <= 8 and level:is_corpse( c ) then
					level.map[ c ] = "bloodpool"
					being:play_sound( "gib" )
					being.hp = math.min( being.hp + 5, being.hpmax * 2 )
					being:remove_perk( "tired" )
				end
			end
			return true
		end,
	}

	register_item "ufskull"
	{
		name     = "fire skull",
		ascii    = "+",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_SKULL,
		sframes  = 2,
		coscolor = { 1.0,1.0,0.0,1.0 },
		level    = 7,
		weight   = 8,
		desc     = "This skull gives you the shivers... you feel instability.",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			ui.blink(YELLOW,50)
			local p = being.position
			for c in area.around( p, 8 ):clamped( area.FULL ):coords() do
				if coord.distance( c, p ) <= 8 and level:is_corpse( c ) then
					level.map[ c ] = "bloodpool"
					being:play_sound( "gib" )
					level:explosion( c , { range = 3, delay = 50, damage = "7d7", color = RED, sound_id = "barrel.explode", flags = { EFSELFSAFE } }, self )
				end
			end
			return true
		end,
	}

	register_item "uhskull"
	{
		name     = "hatred skull",
		ascii    = "+",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_SKULL,
		sframes  = 2,
		coscolor = { 0.0,0.0,1.0,1.0 },
		level    = 9,
		weight   = 8,
		desc = "This skull gives you the shivers... as if it were filled with hatred.",
		flags    = { IF_EXOTIC },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			ui.blink(LIGHTRED,50)
			local p = being.position
			local count = 0
			for c in area.around( p, 8 ):clamped( area.FULL ):coords() do
				if coord.distance( c, p ) <= 8 and level:is_corpse( c ) then
					level.map[ c ] = "bloodpool"
					being:play_sound( "gib" )
					count = count + 1
				end
			end
			if count > 0 then
				being:remove_perk( "tired" )
				being:add_perk( "berserk", count * 30 )
			end
			return true
		end,
	}

end
