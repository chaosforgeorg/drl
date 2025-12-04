function drl.register_regular_items()

	-- Melee Items --

	register_item "knife"
	{
		name     = "combat knife",
		color    = WHITE,
		sprite   = SPRITE_KNIFE,
		psprite  = SPRITE_PLAYER_KNIFE,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 1,
		weight   = 640,
		group    = "melee",
		desc     = "Not what you'd really like to use, but it's better than your fists.",
		flags    = { IF_THROWDROP, IF_EXACTHIT },

		type        = ITEMTYPE_MELEE,
		damage      = "2d5",
		damagetype  = DAMAGE_MELEE,
		acc         = 1,
		altfire     = ALT_THROW,
		miscolor    = LIGHTGRAY,
		misdelay    = 50,
		miss_base   = 10,
		miss_dist   = 3,
		range       = 5,
		missprite   = SPRITE_KNIFE,
		hitsprite   = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_property( "BLADE", true )
		end,
	}

	-- Armors --

	register_item "garmor"
	{
		name     = "green armor",
		color    = GREEN,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.0,1.0,0.0,1.0 },
		pcoscolor= { 0.0,1.0,0.0,1.0 },
		level    = 1,
		weight   = 400,
		desc     = "Offers little protection, but probably better than none.",

		resist = { bullet   = 15, shrapnel = 15 },

		type       = ITEMTYPE_ARMOR,
		armor      = 1,
		movemod    = -5,
	}

	register_item "barmor"
	{
		name     = "blue armor",
		color    = BLUE,
		sprite   = SPRITE_ARMOR,
		coscolor = { 0.0,0.0,1.0,1.0 },
		pcoscolor= { 0.0,0.0,1.0,1.0 },
		level    = 4,
		weight   = 240,
		desc     = "Better than green armor, but it might not be enough.",

		resist = { plasma = 20 },

		type       = ITEMTYPE_ARMOR,
		armor      = 2,
		movemod    = -10,
	}

	register_item "rarmor"
	{
		name     = "red armor",
		color    = RED,
		sprite   = SPRITE_ARMOR,
		coscolor = { 1.0,0.0,0.0,1.0 },
		pcoscolor= { 1.0,0.0,0.0,1.0 },
		level    = 9,
		weight   = 150,
		desc     = "Nice, red and shiny. Look out for it, because if it's gone, you're gone too.",

		resist = { fire = 25 },

		type       = ITEMTYPE_ARMOR,
		armor      = 4,
		movemod    = -20,
	}

	register_item "sboots"
	{
		name     = "steel boots",
		color    = WHITE,
		sprite   = SPRITE_SBOOTS,
		coscolor = { 1.0,1.0,1.0,1.0 },
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 4,
		weight   = 240,
		desc     = "Just enough to keep your feet warm, but protection is laughable.",

		type       = ITEMTYPE_BOOTS,
		armor      = 1,
		knockmod   = -10,
		flags      = { IF_PLURALNAME },
	}

	register_item "pboots"
	{
		name     = "protective boots",
		color    = GREEN,
		sprite   = SPRITE_BOOTS,
		coscolor = { 0.0,1.0,0.0,1.0 },
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 7,
		weight   = 150,
		desc     = "May help a little while walking through acid, but lava trips will still be hard.",

		resist = { acid = 25 },

		type       = ITEMTYPE_BOOTS,
		armor      = 2,
		knockmod   = -25,

		flags      = { IF_PLURALNAME },
	}

	register_item "psboots"
	{
		name     = "plasteel boots",
		color    = BLUE,
		sprite   = SPRITE_BOOTS,
		coscolor = { 0.0,0.0,1.0,1.0 },
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 11,
		weight   = 80,
		desc     = "The perfect boots for hazardous terrain.",

		resist = { acid = 50, fire = 25, plasma = 10 },

		type       = ITEMTYPE_BOOTS,
		armor      = 2,
		knockmod   = -50,
		flags      = { IF_PLURALNAME },
	}

	-- Powerups --

	register_item "shglobe"
	{
		name     = "Small Health Globe",
		color    = LIGHTRED,
		sprite   = SPRITE_HGLOBE,
		level    = 1,
		weight   = 900,
		flags    = { IF_GLOBE },

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:msg("You feel better.")
			being:remove_perk( "tired" )
			local amount = math.floor( 10 * diff[DIFFICULTY].powerfactor * being:get_property( "MEDKIT_BONUS", 1 ) )
			being.hp = math.min( being.hp +  amount, 2*being.hpmax )
		end,
	}

	register_item "bpack"
	{
		name     = "Berserk Pack",
		color    = RED,
		sprite   = SPRITE_BERSERK,
		level    = 1,
		weight   = 200,

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:add_perk("berserk",core.power_duration(200))
			if (not being.flags[ BF_NOHEAL ]) and being.hp < being.hpmax then
				being.hp = being.hpmax
			end
			being:remove_perk( "tired" )
		end,
	}

	register_item "iglobe"
	{
		name     = "Invulnerability Globe",
		color    = WHITE,
		sprite   = SPRITE_INV,
		sframes  = 2,
		level    = 7,
		weight   = 200,

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:add_perk("inv",core.power_duration(500))
			being:remove_perk( "tired" )
		end,
	}

	register_item "scglobe"
	{
		name     = "Supercharge Globe",
		color    = LIGHTBLUE ,
		sprite   = SPRITE_SUPERCHARGE,
		sframes  = 2,
		level    = 4,
		weight   = 150,
		flags    = { IF_GLOBE },

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:msg("SuperCharge!")
			ui.blink(LIGHTBLUE,100)
			being.hp = 2 * being.hpmax
			being:remove_perk( "tired" )
		end,
	}

	register_item "lhglobe"
	{
		name     = "Large Health Globe",
		color    = RED,
		sprite   = SPRITE_LHGLOBE,
		level    = 6,
		weight   = 330,
		flags    = { IF_GLOBE },

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:msg("You feel like new!")
			being:remove_perk( "tired" )
			local amount = math.floor( 10 * diff[DIFFICULTY].powerfactor * being:get_property( "MEDKIT_BONUS", 1 ) )
			being.hp = math.min( being.hp + amount, 2*being.hpmax )
			if being.hp < being.hpmax then
				being.hp = being.hpmax
			end
		end,
	}

	register_item "msglobe"
	{
		name     = "Megasphere",
		color    = LIGHTMAGENTA,
		sprite   = SPRITE_MEGASPHERE,
		sframes  = 2,
		level    = 16,
		weight   = 60,

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:msg("MegaSphere!")
			ui.blink(LIGHTMAGENTA,100)
			if not being.flags[ BF_NOHEAL ] then
				being.hp = 2*being.hpmax
			end
			being:remove_perk( "tired" )
			if being.eq.armor then being.eq.armor:fix() end
			if being.eq.boots then being.eq.boots:fix() end
		end,
	}

	register_item "map"
	{
		name     = "Computer Map",
		color    = GREEN,
		sprite   = SPRITE_MAP,
		sframes  = 2,
		level    = 1,
		weight   = 200,

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:msg( "Everything seems clear now." )
			ui.blink(WHITE,50)
			for c in area.FULL() do
				local cell = cells[ level.map[ c ] ]
				if cell.flags[ CF_BLOCKMOVE ] or cell.flags[ CF_NOCHANGE ] then
					level.light[ c ][LFEXPLORED] = true
				end
			end
			level.flags[ LF_ITEMSVISIBLE ] = true
			if being:has_property( "MAP_EXPERT" ) then
				being:msg( "You download tracking data to your PDA." )
				level.flags[ LF_BEINGSVISIBLE ] = true
			end
		end,
	}

	register_item "pmap"
	{
		name     = "Tracking Map",
		color    = LIGHTGREEN,
		sprite   = SPRITE_TMAP,
		sframes  = 2,
		level    = 1,
		weight   = 80,

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:msg( "You download tracking data to your PDA." )
			ui.blink(LIGHTGREEN,50)
			for c in area.FULL() do
				local cell = cells[ level.map[ c ] ]
				if cell.flags[ CF_BLOCKMOVE ] or cell.flags[ CF_NOCHANGE ] then
					level.light[ c ][LFEXPLORED] = true
				end
			end
			level.flags[ LF_ITEMSVISIBLE ] = true
			level.flags[ LF_BEINGSVISIBLE ] = true
		end,
	}

	register_item "gpack"
	{
		name     = "Light-Amp Goggles",
		color    = BROWN,
		sprite   = SPRITE_LIGHTAMP,
		sframes  = 2,
		level    = 1,
		weight   = 80,

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			being:add_perk("light",core.power_duration(600))
		end,
	}

	register_item "backpack"
	{
		name     = "Backpack",
		color    = BROWN,
		sprite   = SPRITE_BACKPACK,
		glow     = { 1.0,1.0,0.0,1.0 },
		level    = 200,
		weight   = 0,
		firstmsg = "Duh, I'll ditch my junk here.",
		flags    = { IF_NODESTROY },
		
		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			if being:has_property( "BACKPACK" ) then
				ui.msg("Another backpack? Who needs two anyway.")
				return
			end
			self.flags[ IF_NODESTROY ] = false
			ui.msg("BackPack!")
			ui.blink(YELLOW,50)
			being:add_property( "BACKPACK", 4 )
			being:resort_stacks()
		end,
	}

	register_item "ashard"
	{
		name     = "armor shard",
		color    = YELLOW,
		sprite   = SPRITE_SHARD,
		sframes  = 2,
		level    = 5,
		weight   = 700,

		type    = ITEMTYPE_POWER,

		OnPickup = function(self,being)
			local armor = being.eq.armor
			local boots = being.eq.boots
			if not armor and not boots then
				being:msg( "You have no armor to fix! Nothing happens." )
				return
			end
			local damaged_armor = armor and armor:is_damaged()
			local damaged_boots = boots and boots:is_damaged()
			if not damaged_armor and not damaged_boots then
				being:msg( "You have no armor that needs fixing! Nothing happens." )
				return
			end
			ui.blink( YELLOW, 50 )
			if damaged_armor then
				if armor:fix(25*diff[DIFFICULTY].powerfactor) then
					being:msg( "Your armor looks like new!" )
				else
					being:msg( "Your armor looks better!" )
				end
			end
			if damaged_boots then
				if boots:fix(10*diff[DIFFICULTY].powerfactor) then
					being:msg( "Your boots look like new!" )
				else
					being:msg( "Your boots look better!" )
				end
			end
		end,
	}

	-- Ammo --

	register_item "ammo"
	{
		name     = "10mm ammo",
		color    = LIGHTGRAY,
		sprite   = SPRITE_AMMO,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 1,
		weight   = 500,
		desc     = "10mm ammo, the backbone of your firepower.",

		type    = ITEMTYPE_AMMO,
		amount  = 24,
		max     = 100,
	}

	register_item "shell"
	{
		name     = "shotgun shell",
		color    = DARKGRAY,
		sprite   = SPRITE_SHELL,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 2,
		weight   = 700,
		desc     = "Food for your trusty shotguns.",

		type    = ITEMTYPE_AMMO,
		amount  = 8,
		max     = 50,
	}

	register_item "rocket"
	{
		name     = "rocket",
		color    = BROWN,
		sprite   = SPRITE_ROCKET,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 5,
		weight   = 400,
		desc     = "Rockets -- heavy, big and go boom.",

		type    = ITEMTYPE_AMMO,
		amount  = 3,
		max     = 10,
	}

	register_item "cell"
	{
		name     = "power cell",
		color    = CYAN,
		sprite   = SPRITE_CELL,
		sframes  = 2,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 8,
		weight   = 200,
		desc     = "Power cells, the peak of monster frying technology.",

		type    = ITEMTYPE_AMMO,
		amount  = 20,
		max     = 50,
	}

	register_item "pammo"
	{
		name     = "10mm ammo chain",
		color    = LIGHTGRAY,
		sprite   = SPRITE_PAMMO,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 3,
		weight   = 60,
		desc     = "That reminds you about action films you've seen long ago. Might be useful in the prepared slot.",

		type    = ITEMTYPE_AMMOPACK,
		ammo    = 250,
		ammomax = 250,
		ammo_id = "ammo",
	}

	register_item "pshell"
	{
		name     = "shell box",
		color    = DARKGRAY,
		sprite   = SPRITE_PSHELL,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 4,
		weight   = 60,
		desc     = "Packed shells, like sardines! Might be useful in the prepared slot.",

		type    = ITEMTYPE_AMMOPACK,
		ammo    = 100,
		ammomax = 100,
		ammo_id = "shell",
	}

	register_item "procket"
	{
		name     = "rocket box",
		color    = BROWN,
		sprite   = SPRITE_PROCKET,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 7,
		weight   = 36,
		desc     = "Now this is the REAL 'boombox'! Might be useful in the prepared slot.",

		type    = ITEMTYPE_AMMOPACK,
		ammo    = 25,
		ammomax = 25,
		ammo_id = "rocket",
	}

	register_item "pcell"
	{
		name     = "power battery",
		color    = CYAN,
		sprite   = SPRITE_PCELL,
		sframes  = 2,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 10,
		weight   = 18,
		--desc     = "Ampere-hours of pure energy!",
		desc     = "Joules of energetic fun! Might be useful in the prepared slot.",

		type    = ITEMTYPE_AMMOPACK,
		ammo    = 120,
		ammomax = 120,
		ammo_id = "cell",
	}

	-- Ranged  weapons --

	register_item "pistol"
	{
		name     = "pistol",
		color    = LIGHTGRAY,
		sprite   = SPRITE_PISTOL,
		psprite  = SPRITE_PLAYER_PISTOL,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 1,
		weight   = 70,
		group    = "pistol",
		desc     = "Your trusty 10mm pistol. It may be nice, but better find something stronger.",

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 6,
		damage        = "2d4",
		damagetype    = DAMAGE_BULLET,
		acc           = 4,
		reloadtime    = 12,
		altfire       = ALT_AIMED,
		miscolor      = LIGHTGRAY,
		misdelay      = 15,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,
	}

	register_item "shotgun"
	{
		name     = "shotgun",
		color    = DARKGRAY,
		sprite   = SPRITE_SHOTGUN,
		psprite  = SPRITE_PLAYER_SHOTGUN,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 2,
		weight   = 150,
		group    = "shotgun",
		desc     = "A 12g shotgun -- you gotta love its spread.",
		firstmsg = "Just what I needed!",

		type          = ITEMTYPE_RANGED,
		ammo_id       = "shell",
		ammomax       = 1,
		damage        = "8d3",
		damagetype    = DAMAGE_SHARPNEL,
		range         = 15,
		spread        = 3,
		falloff       = 7,
		knockback     = 8,
		hitsprite     = SPRITE_BLAST,
	}

	register_item "dshotgun"
	{
		name     = "double shotgun",
		color    = WHITE,
		sprite   = SPRITE_DSHOTGUN,
		psprite  = SPRITE_PLAYER_DSHOTGUN,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 4,
		weight   = 100,
		group    = "shotgun",
		desc     = "Double barreled shotgun -- the perfect weapon for a desperado.",
		firstmsg = "Now THIS is what I call a shotgun!",
		flags    = { IF_DUALSHOTGUN },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "shell",
		ammomax       = 2,
		damage        = "9d3",
		damagetype    = DAMAGE_SHARPNEL,
		reloadtime    = 20,
		shots         = 2,
		altfire       = ALT_SINGLE,
		range         = 8,
		spread        = 3,
		falloff       = 10,
		knockback     = 8,
		hitsprite     = SPRITE_BLAST,
	}

	register_item "ashotgun"
	{
		name     = "combat shotgun",
		color    = LIGHTBLUE,
		sprite   = SPRITE_CSHOTGUN,
		psprite  = SPRITE_PLAYER_CSHOTGUN,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 6,
		weight   = 200,
		group    = "shotgun",
		desc     = "Nothing beats the sound of pumping a combat shotgun.",
		firstmsg = "Pump'n'roll!",
		flags    = { IF_SINGLERELOAD },

		type          = ITEMTYPE_RANGED,
		ammo_id       = "shell",
		ammomax       = 5,
		damage        = "7d3",
		damagetype    = DAMAGE_SHARPNEL,
		altreloadname = "full",
		range         = 15,
		spread        = 2,
		falloff       = 5,
		knockback     = 8,
		hitsprite     = SPRITE_BLAST,

		OnCreate = function(self)
			self:add_perk( "perk_altreload_full" )
			self:add_perk( "perk_pump_action" )
		end,
		
		OnAltReload = function( self, being )
			return being:full_reload( self )
		end,
	}

	register_item "bazooka"
	{
		name     = "rocket launcher",
		color    = BROWN,
		sprite   = SPRITE_BAZOOKA,
		psprite  = SPRITE_PLAYER_BAZOOKA,
		--glow     = { 1.0,1.0,1.0,1.0 },
		level    = 7,
		weight   = 200,
		group    = "rocket",
		desc     = "The rocket launcher is the most standard way of blowing things up.",
		firstmsg = "Ride my rocket baby!",

		type          = ITEMTYPE_RANGED,
		ammo_id       = "rocket",
		ammomax       = 1,
		damage        = "6d6",
		damagetype    = DAMAGE_FIRE,
		acc           = 4,
		radius        = 4,
		reloadtime    = 15,
		altfire       = ALT_TARGETSCRIPT,
		altfirename   = "rocketjump",
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

		OnFire = function( self, being )
			self:set_explosion{
				delay 	= 40,
				color 	= RED,
			}
			self.flags[ IF_EXACTHIT ] = false
			self.range   = 0
			return true
		end,
	}

	register_item "chaingun"
	{
		name     = "chaingun",
		color    = LIGHTRED,
		level    = 5,
		weight   = 200,
		psprite  = SPRITE_PLAYER_CHAINGUN,
		sprite   = SPRITE_CHAINGUN,
		--glow     = { 1.0,1.0,1.0,1.0 },
		group    = "chain",
		desc     = "Chaingun directs heavy firepower into your opponent making him do the chaingun cha-cha.",
		firstmsg = "Phobos ReLEADed, oh yeah!",

		type          = ITEMTYPE_RANGED,
		ammo_id       = "ammo",
		ammomax       = 40,
		damage        = "1d6",
		damagetype    = DAMAGE_BULLET,
		acc           = 2,
		reloadtime    = 25,
		shots         = 4,
		altfire       = ALT_CHAIN,
		miscolor      = WHITE,
		misdelay      = 10,
		miss_base     = 10,
		miss_dist     = 3,
		missprite     = SPRITE_SHOT,
		hitsprite     = SPRITE_BLAST,
	}

	register_item "plasma"
	{
		name     = "plasma rifle",
		color    = CYAN,
		level    = 12,
		weight   = 70,
		psprite  = SPRITE_PLAYER_PLASMA,
		sprite   = SPRITE_PLASMA,
		--glow     = { 1.0,1.0,1.0,1.0 },
		group    = "plasma",
		desc     = "A plasma rifle shoots multiple rounds of plasma energy -- frying some demon butt!",
		firstmsg = "Peace through superior firepower!",

		type          = ITEMTYPE_RANGED,
		ammo_id       = "cell",
		ammomax       = 40,
		damage        = "1d7",
		damagetype    = DAMAGE_PLASMA,
		acc           = 2,
		reloadtime    = 20,
		shots         = 6,
		altfire       = ALT_CHAIN,
		altreloadname = "overcharge",
		misascii      = "*",
		miscolor      = MULTIBLUE,
		misdelay      = 10,
		miss_base     = 30,
		miss_dist     = 3,
		missprite     = SPRITE_PLASMASHOT,
		hitsprite     = SPRITE_BLAST,

		OnAltReload = function(self)
			if not self:can_overcharge("This will destroy the weapon after the next shot...") then return false end
			self.shots         = self.shots * 2
			self.ammomax       = self.shots
			self.ammo          = self.shots
			self.damage_sides  = self.damage_sides + 1
			self.altfire       = ALT_NONE
			return true
		end,
	}

	-- Packs --

	register_item "smed"
	{
		name     = "small med-pack",
		ascii    = "+",
		color    = LIGHTRED,
		sprite   = SPRITE_MEDPACK,
		level    = 1,
		weight   = 600,
		desc     = "Great to treat a few burns; for major injuries, better find its larger cousin.",
		flags    = { IF_AIHEALPACK },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			local isPlayer = being:is_player()
			if being.flags[ BF_NOHEAL ] then
				being:msg("Nothing happens.")
			else
				if isPlayer then 
					being:remove_perk( "tired" )
				end
				local overheal = being:has_property("MEDKIT_OVERHEAL")
				if being.hp >= being.hpmax * 2 or ( not overheal and being.hp >= being.hpmax ) then
					being:msg("Nothing happens.")
					return true
				end
				local amount = math.floor( ( (being.hpmax * diff[DIFFICULTY].powerfactor) / 4 + 2 ) * being:get_property( "MEDKIT_BONUS", 1 ) )
				being.hp = math.min( being.hp + amount, being.hpmax * 2 )
				if not overheal then being.hp = math.min( being.hp, being.hpmax ) end
				being:msg("You feel healed.",being:get_name(true,true).." looks healthier!")
			end
			return true
		end,
	}

	register_item "lmed"
	{
		name     = "large med-pack",
		ascii    = "+",
		color    = RED,
		sprite   = SPRITE_LMEDPACK,
		level    = 5,
		weight   = 400,
		desc     = "Your savior in times of need.",
		flags    = { IF_AIHEALPACK },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			local isPlayer = being:is_player()
			if being.flags[ BF_NOHEAL ] then
				being:msg("Nothing happens.")
			else
				if isPlayer then 
					being:remove_perk( "tired" )
				end
				local overheal = being:has_property("MEDKIT_OVERHEAL")
				if being.hp >= being.hpmax * 2 or ( (not overheal) and being.hp >= being.hpmax ) then
					being:msg("Nothing happens.")
					return true
				end
				being.hp = math.min( being.hp + (being.hpmax * diff[DIFFICULTY].powerfactor) / 2 + 2, being.hpmax * 2)
				being.hp = math.max( being.hp, being.hpmax )
				if not overheal then being.hp = math.min( being.hp, being.hpmax ) end
				being:msg("You feel fully healed.",being:get_name(true,true).." looks a lot healthier!")
			end
			return true
		end,
	}

	register_item "phase"
	{
		name     = "phase device",
		ascii    = "+",
		color    = BLUE,
		sprite   = SPRITE_PHASE,
		sframes  = 2,
		coscolor = { 0.0,0.0,0.7,1.0 },
		level    = 5,
		weight   = 200,
		desc     = "Experimental technology -- might save you from a tight spot. Not always though.",
		flags    = { IF_AIHEALPACK },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			being:play_sound("phasing")
			being:msg("You feel yanked in a non-existing direction!","Suddenly "..being:get_name(true,false).." blinks away!")
			level:explosion( being.position, { range = 2, delay = 50, color = LIGHTBLUE } )
			being:phase()
			level:explosion( being.position, { range = 1, delay = 50, color = LIGHTBLUE } )
			being:msg(nil,"Suddenly "..being:get_name(false,false).." appears out of nowhere!")
			return true
		end,
	}

	register_item "hphase"
	{
		name     = "homing phase device",
		ascii    = "+",
		color    = LIGHTBLUE,
		level    = 7,
		weight   = 100,
		sprite   = SPRITE_PHASE,
		sframes  = 2,
		coscolor = { 0.3,0.3,1.0,1.0 },
		desc = "This upgraded phase device will definitely save your skin.",
		flags    = { IF_AIHEALPACK },

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			being:play_sound("phasing")
			being:msg("You feel yanked in a non-existing direction!","Suddenly "..being:get_name(true,false).." blinks away!")
			level:explosion( being.position, { range = 2, delay = 50, color = GREEN } )
			if level.flags[ LF_NOHOMING ] then
				being:phase()
			else
				being:phase( "stairs" )
			end
			level:explosion( being.position, { range = 1, delay = 50, color = GREEN } )
			being:msg(nil,"Suddenly "..being:get_name(false,false).." appears out of nowhere!")
			return true
		end,
	}

	register_item "epack"
	{
		name     = "envirosuit pack",
		ascii    = "+",
		color    = GREEN,
		sprite   = SPRITE_ENVIRO,
		level    = 5,
		weight   = 100,
		desc     = "Planning a lava bath? You'll definitely need this.",

		type = ITEMTYPE_PACK,

		OnUse = function(self,being)
			if being:is_player() then
				being:add_perk("enviro",core.power_duration(700))
			end
			return true
		end,
	}

	register_item "nuke"
	{
		name     = "thermonuclear bomb",
		ascii    = "%",
		color    = LIGHTBLUE,
		level    = 10,
		weight   = 40,
		sprite   = SPRITE_NUKE,
		desc     = "Cool firepower, but how will you save yourself?",
		firstmsg = "\"Handle with care\"... WTF?",
		flags    = {},

		type       = ITEMTYPE_PACK,

		OnUse = function(self,being)
			if being:is_player() then
				if level.flags[ LF_NONUKE ] then
					ui.msg('You arm the thermonuclear bomb and step aside... but nothing happens!');
					return true
				end
				if being.flags[ BF_IMPATIENT ] then
					ui.msg("They told you so many times that patience is a virtue..")
				end
				local floor = level.map[ being.position ]
				if floor == "acid" or floor == "lava" then
					-- Added to make it sound less idiotic when invulnerable
					if not being:is_perk("inv") then
						ui.msg('Somehow, in an instant, you feel like an idiot...');
					end
					being:nuke(1)
					return true
				end
				ui.msg("Warning! Explosion in 10 seconds!")
				being:nuke(100)
			end
			return true
		end,

		OnUseCheck = function(self,being)
			if being.nuketime > 0 then
				ui.msg('ARE YOU OUT OF YOUR MIND???');
				return false
			end
			local floor = level.map[ being.position ]
			if floor == "stairs" or floor == "ystairs" or floor == "rstairs" then
				ui.msg('This thing is huge, better not block the stairs with it...');
				return false
			end
			if not ui.confirm('Are you sure you want activate the thermonuclear bomb?') then
				ui.msg('Ufff... I knew you were a reasonable person.');
				return false
			end
			being:add_history('He nuked @1!')
			return true
		end,
	}

	-- Mods --

	register_item "mod_power"
	{
		name     = "power mod pack",
		ascii    = "\"",
		color    = LIGHTRED,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		coscolor = { 1.0,0.0,0.0,1.0 },
		level    = 7,
		weight   = 120,		
		desc     = "Power modification kit -- increases weapon damage or armor protection.",

		type       = ITEMTYPE_PACK,
		mod_letter = "P",

		OnUseCheck = function(self,being)
			local item, result = being:pick_item_to_mod( self )
			if not result then return false end
			if item ~= nil then self:add_property("chosen_item", item) end
			return true
		end,

		OnModDescribe = function( self, item )
			local function dmgsmtr( bd,bs )
				local bd = item.damage_dice + (bd or 0)
				local bs = item.damage_sides + (bs or 0)
				return "{!"..bd.."d"..bs.."}"
			end			   
			if item.itype == ITEMTYPE_MELEE then
				return "damage "..dmgsmtr().." -> "..dmgsmtr(nil,1)
			elseif item.itype == ITEMTYPE_RANGED then
				if item.damage_sides >= item.damage_dice then
					return "damage "..dmgsmtr().." -> "..dmgsmtr(nil,1)
				else
					return "damage "..dmgsmtr().." -> "..dmgsmtr(1)
				end
			elseif item.itype == ITEMTYPE_ARMOR then
				return "armor value {!"..item.armor.."} -> {!"..(item.armor+2).."}"
			elseif item.itype == ITEMTYPE_BOOTS then
				return "armor value {!"..item.armor.."} -> {!"..(item.armor*2).."}"
			end
			return "unknown"
		end,

		OnUse = function(self,being)
			if not self:has_property("chosen_item") then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			if item.itype == ITEMTYPE_MELEE then
				item.damage_sides = item.damage_sides + 1
			elseif item.itype == ITEMTYPE_RANGED then
				if item.damage_sides >= item.damage_dice then
					item.damage_sides = item.damage_sides + 1
				else
					item.damage_dice = item.damage_dice + 1
				end
			elseif item.itype == ITEMTYPE_ARMOR then
				item.armor = item.armor + 2
			elseif item.itype == ITEMTYPE_BOOTS then
				item.armor = item.armor * 2
			end
			item:add_mod( 'P', being.techbonus )
			return true
		end,
	}

	register_item "mod_tech"
	{
		name     = "technical mod pack",
		ascii    = "\"",
		color    = YELLOW,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		coscolor = { 1.0,1.0,0.0,1.0 },
		level    = 5,
		weight   = 120,
		desc     = "Technical modification kit -- decreases fire time for weapons, or increases armor resistances.",

		type       = ITEMTYPE_PACK,
		mod_letter = "T",

		OnUseCheck = function(self,being)
			local item, result = being:pick_item_to_mod( self )
			if not result then return false end
			if item ~= nil then self:add_property("chosen_item", item) end
			return true
		end,

		OnModDescribe = function( self, item )
			if (item.itype == ITEMTYPE_RANGED) or (item.itype == ITEMTYPE_MELEE) then
				return "use/fire time {!"..(item.usetime/10).."s} -> {!"..(math.floor(item.usetime * 0.85 + 0.49)/10).."s}"
			elseif item.itype == ITEMTYPE_ARMOR or item.itype == ITEMTYPE_BOOTS then
				return 
					"bullet resistance   {!"..(item.resist.bullet or 0).."%} -> {!"..((item.resist.bullet or 0)+ 20).."%}\n"..
					"         melee resistance    {!"..(item.resist.melee or 0).."%} -> {!"..((item.resist.melee or 0)+ 20).."%}\n"..
					"         shrapnel resistance {!"..(item.resist.shrapnel or 0).."%} -> {!"..((item.resist.shrapnel or 0)+ 20).."%}\n"..
					"         acid resistance     {!"..(item.resist.acid or 0).."%} -> {!"..((item.resist.acid or 0)+ 10).."%}\n"..
					"         fire resistance     {!"..(item.resist.fire or 0).."%} -> {!"..((item.resist.fire or 0)+ 10).."%}\n"..
					"         plasma resistance   {!"..(item.resist.plasma or 0).."%} -> {!"..((item.resist.plasma or 0)+ 10).."%}"
			end
			return "unknown"
		end,

		OnUse = function(self,being)
			if not self:has_property("chosen_item") then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			if (item.itype == ITEMTYPE_RANGED) or (item.itype == ITEMTYPE_MELEE) then
				item.usetime = item.usetime * 0.85
			elseif item.itype == ITEMTYPE_ARMOR or item.itype == ITEMTYPE_BOOTS then
				item.resist.bullet   = (item.resist.bullet or 0)   + 20
				item.resist.melee    = (item.resist.melee or 0)    + 20
				item.resist.shrapnel = (item.resist.shrapnel or 0) + 20
				item.resist.acid     = (item.resist.acid or 0)     + 10
				item.resist.fire     = (item.resist.fire or 0)     + 10
				item.resist.plasma   = (item.resist.plasma or 0)   + 10
			end
			item:add_mod( 'T', being.techbonus )
			return true
		end,
	}

	register_item "mod_agility"
	{
		name     = "agility mod pack",
		ascii    = "\"",
		color    = LIGHTCYAN,
		weight   = 120,
		coscolor = { 0.0,1.0,1.0,1.0 },
		level    = 6,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		desc     = "Agility modification kit -- increases weapon accuracy or quickens armor move speed modifier.",

		type       = ITEMTYPE_PACK,
		mod_letter = "A",

		OnUseCheck = function(self,being)
			local item, result = being:pick_item_to_mod( self )
			if not result then return false end
			if item ~= nil then self:add_property("chosen_item", item) end
			return true
		end,

		OnModDescribe = function( self, item )
			local function accstr( bd )
				local bd = item.acc + (bd or 0)
				if bd < 0 then return "{!"..bd.."}" end
				return "{!+"..bd.."}"
			end
			local function movstr( bd )
				local bd = item.movemod + (bd or 0)
				if bd < 0 then return "{!"..bd.."%}" end
				return "{!+"..bd.."%}"
			end

			if item.itype == ITEMTYPE_MELEE or item.itype == ITEMTYPE_RANGED then
				return "accuracy "..accstr().." -> "..accstr(1)
			elseif item.itype == ITEMTYPE_ARMOR then
				return "move speed "..movstr().." -> "..movstr(15)
			elseif item.itype == ITEMTYPE_BOOTS then
				return "move speed "..movstr().." -> "..movstr(10)
			end
			return "unknown"
		end,

		OnUse = function(self,being)
			if not self:has_property("chosen_item") then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			if item.itype == ITEMTYPE_MELEE or item.itype == ITEMTYPE_RANGED then
				item.acc = item.acc + 1
			elseif item.itype == ITEMTYPE_ARMOR then
				item.movemod = item.movemod + 15
			elseif item.itype == ITEMTYPE_BOOTS then
				item.movemod = item.movemod + 10
			end
			item:add_mod( 'A', being.techbonus )
			-- A little easter egg for applying A-mod on shotgun
			if item.group == "shotgun" then
				ui.msg( "You suddenly feel a little silly." )
			end
			return true
		end,
	}

	register_item "mod_bulk"
	{
		name     = "bulk mod pack",
		ascii    = "\"",
		color    = LIGHTBLUE,
		sprite   = SPRITE_MOD,
		sframes  = 2,
		coscolor = { 0.0,0.0,1.0,1.0 },
		level    = 6,
		weight   = 120,
		desc     = "Bulk modification kit -- increases weapon magazine for magazine weapons, decreases reload time for single-shot weapons, or increases armor durability. For melee weapons it increases the damage done.",

		type       = ITEMTYPE_PACK,
		mod_letter = "B",

		OnUseCheck = function(self,being)
			local item, result = being:pick_item_to_mod( self )
			if not result then return false end
			if item ~= nil then self:add_property("chosen_item", item) end
			return true
		end,

		OnModDescribe = function( self, item )
			local function dmgsmtr( bd,bs )
				local bd = item.damage_dice + (bd or 0)
				local bs = item.damage_sides + (bs or 0)
				return "{!"..bd.."d"..bs.."}"
			end	
			local function movstr( bd )
				local bd = item.movemod + (bd or 0)
				if bd < 0 then return "{!"..bd.."%}" end
				return "{!+"..bd.."%}"
			end

			if item.itype == ITEMTYPE_MELEE then
				return "damage "..dmgsmtr().." -> "..dmgsmtr(1)
			elseif item.itype == ITEMTYPE_RANGED and item.ammomax < 3 then
				return "reload time {!"..(item.reloadtime/10).."s} -> {!"..(math.floor(item.reloadtime * 0.75 + 0.5)/10).."s}"
			elseif item.itype == ITEMTYPE_RANGED then
				return "magazine {!"..item.ammomax.."} -> {!"..math.floor(item.ammomax * 1.3 + 0.5).."}"
			elseif item.itype == ITEMTYPE_ARMOR or item.itype == ITEMTYPE_BOOTS then
				return "durability {!"..item.maxdurability.."} -> {!"..(item.maxdurability + 100).."}\n"..
				       "         move speed "..movstr().." -> "..movstr(-10)
			end
			return "unknown"
		end,

		OnUse = function(self,being)
			if not self:has_property("chosen_item") then return true end
			local item = self.chosen_item
			self:remove_property("chosen_item")
			if item.itype == ITEMTYPE_MELEE then
				item.damage_dice = item.damage_dice + 1
			elseif item.itype == ITEMTYPE_RANGED then
				if item.ammomax < 3 then
					item.reloadtime = item.reloadtime * 0.75
				else
					item.ammomax = math.floor(item.ammomax * 1.3 + 0.5)
				end
			elseif item.itype == ITEMTYPE_ARMOR or item.itype == ITEMTYPE_BOOTS then
				item.durability    = item.durability + 100
				item.maxdurability = item.maxdurability + 100
				item.movemod = item.movemod - 10
			end
			item:add_mod( 'B', being.techbonus )
			return true
		end,
	}

	-- barrels --

	register_item "barrel"
	{
		name       = "barrel of fuel",
		ascii      = "0",
		color      = BROWN,
		armor      = 3,
		hp         = 2,
		flags      = { IF_BLOCKMOVE, IF_BLOCKSHOT },
		sprite     = SPRITE_BARREL,

		type       = ITEMTYPE_FEATURE,
		weight     = 0,

		OnAct = function( self, c, being )
			local source = being.position
			local push   = c + (c - source)
			level:push_feature( being, self, c, push, false, true ) 
		end,

		OnDestroy = function(self,c)
			if level:is_visible(c) then ui.msg('The barrel explodes!') end
			level:explosion(c, { range = 4, delay = 40, damage = "5d5", color = RED, sound_id = "barrel.explode" } )
		end
	}

	register_item "barrela"
	{
		name       = "barrel of acid",
		ascii      = "0",
		color      = GREEN,
		armor      = 4,
		hp         = 2,
		flags      = { IF_BLOCKMOVE, IF_BLOCKSHOT },
		sprite     = SPRITE_ACIDBARREL,
		sframes    = 2,

		type       = ITEMTYPE_FEATURE,
		weight     = 0,

		OnAct = function( self, c, being )
			local source = being.position
			local push   = c + (c - source)
			level:push_feature( being, self, c, push, false, true ) 
		end,

		OnDestroy = function(self,c)
			if level:is_visible(c) then ui.msg('The barrel explodes!') end
			level:destroy_to( c, "acid" )
			level:explosion(c, { range = 3, delay = 40, damage = "6d6", color = GREEN, damage_type = DAMAGE_ACID, sound_id = "barrel.explode", flags = { EFRANDOMCONTENT }, content = "acid" } )
		end
	}

	register_item "barreln"
	{
		name       = "barrel of napalm",
		ascii      = "0",
		color      = LIGHTRED,
		armor      = 5,
		hp         = 2,
		flags      = { IF_BLOCKMOVE, IF_BLOCKSHOT },
		sprite     = SPRITE_LAVABARREL,
		sframes    = 2,

		type       = ITEMTYPE_FEATURE,
		weight     = 0,

		OnAct = function( self, c, being )
			local source = being.position
			local push   = c + (c - source)
			level:push_feature( being, self, c, push, false, true ) 
		end,

		OnDestroy = function(self,c)
			if level:is_visible(c) then ui.msg('The barrel explodes!') end
			level:destroy_to( c, "lava" )
			level:explosion(c, { range = 2, delay = 40, damage = "7d7", color = RED, sound_id = "barrel.explode", damage_type = DAMAGE_FIRE, content = "lava" })
		end
	}

	-- features --

	register_item "tree"
	{
		name       = "Phobos tree",
		ascii      = "T",
		color      = BROWN,
		armor      = 5,
		hp         = 5,
		flags      = { IF_BLOCKMOVE, IF_BLOCKSHOT },
		sprite     = SPRITE_TREE,

		type       = ITEMTYPE_FEATURE,
		weight     = 0,
	}


	-- levers --

	register_item "lever_flood_water"
	{
		name     = "lever",
		color_id = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,

		type       = ITEMTYPE_LEVER,
		good       = "neutral",
		desc       = "floods with water",
		warning    = "The air is really humid here...",
		fullchance = 50,

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "target_area", area.FULL_SHRINKED:clone() )
		end,

		OnUse = function(self,being)
			ui.msg("Suddenly water starts gushing from the ground!")
			level:flood( "water", self.target_area )
			return true
		end,

		OnDescribe = item.get_lever_description,
	}
		

	register_item "lever_flood_acid"
	{
		name     = "lever",
		color_id = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,

		type       = ITEMTYPE_LEVER,
		good       = "dangerous",
		desc       = "floods with acid",
		warning    = "In the State of Denmark there was the odor of decay...",
		fullchance = 10,

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "target_area", area.FULL_SHRINKED:clone() )
		end,

		OnUse = function(self,being)
			if self.target_area:size() >= area.FULL_SHRINKED:size() then
				-- Really?  Censoring "f***" when the plot has it?
				ui.msg("WTF?! Acid splashes everywhere!")
				being:add_history("He flooded the entire @1 with acid!")
			else
				ui.msg("Green acid covers the floor!")
			end
			level:flood( "acid", self.target_area )
			return true
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_flood_lava"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "dangerous",
		desc       = "floods with lava",
		warning    = "You feel that smell? That gasoline smell? Oh hell...",
		fullchance = 10,

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "target_area", area.FULL_SHRINKED:clone() )
		end,

		OnUse = function(self,being)
			if self.target_area:size() >= area.FULL_SHRINKED:size() then
				ui.msg("Oh shit... oh shit... OH SHIT!!!!")
				being:add_history("He flooded the entire @1 with lava!")
			else
				ui.msg("The ground explodes in flames!")
			end
			level:flood( "lava", self.target_area )
			return true
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_kill"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "beneficial",
		desc       = "harms creatures",
		warning    = "The smell of a massacre...",
		fullchance = 33,

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "target_area", area.FULL_SHRINKED:clone() )
		end,

		OnUse = function(self,being)
			for c in self.target_area() do
				local target = level:get_being(c)
				if target and not target:is_player() then
					target:apply_damage( 20, TARGET_INTERNAL, DAMAGE_FIRE, nil )
				end
			end
			ui.msg("The smell of blood surrounds you!")
			return true
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_explode"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "neutral",
		desc       = "forces explosions",
		fullchance = 100,

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "target_area", area.FULL_SHRINKED:clone() )
		end,

		OnUse = function(self,being)
			local position = self.position
			for c in self.target_area() do
				local item = level:get_item( c )
				if item and item.hp > 0 then
					level:damage_tile( c, 1000, DAMAGE_PLASMA )
				end
			end
			return true
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_walls"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "dangerous",
		desc       = "destroys walls",
		warning    = "You hear the trumpets of Jericho echoing in the distance...",
		fullchance = 33,

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "target_area", area.FULL_SHRINKED:clone() )
		end,

		OnUse = function(self,being)
			local room = self.target_area:clamped( area.FULL_SHRINKED )
			level:play_sound( "barrel.explode", being.position )
			for c in room() do
				local tile = cells[level.map[c]]
				if tile.set == CELLSET_WALLS or tile.set == CELLSET_DOORS then
					if math.random(10) == 1 then
						level:play_sound( "barrel.explode", c, math.random(500) + 500 )
					end
					generator.destroy_cell( c )
				end
			end
			ui.msg("The walls explode!")
			return true
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_summon"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "dangerous",
		desc       = "summons enemies",

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "charges", math.random(3) )
			self:add_property( "target_area", area.FULL_SHRINKED:clone() )
		end,

		OnUseCheck = function( self )
			if self.charges == 0 then
				ui.msg("Nothing happens.")
				return false
			end
			return true
		end,

		OnUse = function(self,being)
			local amount = math.random(4)+1
			local list   = level:get_being_table( level.danger_level, nil, { is_group = false } )
			for c = 1,amount do
				being:spawn( list:roll().id )
			end
			self.charges = self.charges - 1
			return self.charges == 0
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_repair"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "beneficial",
		desc       = "Armor depot",

		flags  = { IF_FEATURENAME },

		OnCreate = function(self)
			self:add_property( "charges", math.random(3) )
		end,

		OnUseCheck = function(self,being)
			ui.msg("Armor depot. Proceeding with repair of equipped armor...")
			local armor = being.eq.armor
			local boots = being.eq.boots
			if not armor and not boots then
				ui.msg( "You have no armor to fix! Nothing happens." )
				return false
			end
			local damaged_armor = armor and armor:is_damaged()
			local damaged_boots = boots and boots:is_damaged()
			if not damaged_armor and not damaged_boots then
				ui.msg( "You have no armor that needs fixing! Nothing happens." )
				return false
			end
			return true
		end,

		OnUse = function(self,being)
			local armor = being.eq.armor
			local boots = being.eq.boots
			local damaged_armor = armor and armor:is_damaged()
			local damaged_boots = boots and boots:is_damaged()
			self.charges = self.charges - 1
			ui.blink( YELLOW, 50 )
			if damaged_armor then
				if armor:fix(25) then
					ui.msg( "Your armor looks like new!" )
				else
					ui.msg( "Your armor looks better!" )
				end
			end
			if damaged_boots then
				if boots:fix(25) then
					ui.msg( "Your boots look like new!" )
				else
					ui.msg( "Your boots look better!" )
				end
			end
			return self.charges == 0
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_medical"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "beneficial",
		desc       = "MediTech depot",

		flags  = { IF_FEATURENAME },

		OnCreate = function( self )
			self:add_property( "charges", math.random(3) )
		end,

		OnUseCheck = function(self,being)
			if being.flags[ BF_NOHEAL] then
				ui.msg("Nothing happens.")
				return false
			end
			if being.hp >= being.hpmax then
				ui.msg("MediTech depot. Proceeding with treatment...")
				ui.msg("You are at full health. Nothing happens.")
				return false
			end
			return true
		end,

		OnUse = function(self,being)
			ui.msg("MediTech depot. Proceeding with treatment...")
			being:remove_perk( "tired" )
			self.charges = self.charges - 1
			local heal = (being.hpmax * diff[DIFFICULTY].powerfactor) / 4 + 2
			being.hp = math.min( being.hp + heal,being.hpmax )
			ui.msg("You feel healed.")
			return self.charges == 0
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "lever_ammo"
	{
		name     = "lever",
		color    = WHITE,
		sprite   = SPRITE_LEVER,
		weight   = 0,
		color_id = "lever",

		type       = ITEMTYPE_LEVER,
		good       = "beneficial",
		desc       = "ammo dispenser",

		flags  = { IF_FEATURENAME },

		OnCreate = function( self )
			self:add_property( "charges", math.random(3) + 1 )
		end,

		OnUseCheck = function(self,being)
			if not being.eq.weapon then
				ui.msg("Nothing happens.")
				return false
			end
			local weapon = being.eq.weapon
			if weapon.ammoid == 0 then
				ui.msg("Nothing happens.")
				return false
			end
			return true
		end,

		OnUse = function(self,being)
			ui.msg("Ammo dispenser. Dispensing requested ammo...")
			self.charges = self.charges - 1
			local ammo_id = items[being.eq.weapon.ammoid].id
			level:drop_item( ammo_id, being.position, true, true, true )
			return self.charges == 0
		end,

		OnDescribe = item.get_lever_description,
	}

	register_item "schematic_0"
	{
		name     = "schematics",
		color    = LIGHTGREEN,
		sprite   = SPRITE_SCHEMATIC,
		sframes  = 2,
		level    = 9999,
		weight   = 3,
		flags  = { IF_NODESTROY },
		
		type    = ITEMTYPE_POWER,
		slevel  = 0,

		OnPickup = function(self,being)
			self.flags[ IF_NODESTROY ] = false
			ui.blink(LIGHTGREEN,100)
			player:add_assembly(mod_arrays[self.ammo].id)
			ui.msg_enter("You suddenly know how to assemble "..mod_arrays[self.ammo].name.."!")
		end,
	}

	register_item "schematic_1"
	{
		name     = "schematics",
		color    = LIGHTGREEN,
		sprite   = SPRITE_SCHEMATIC,
		sframes  = 2,
		level    = 9999,
		weight   = 2,
		flags  = { IF_NODESTROY },
		
		type    = ITEMTYPE_POWER,
		slevel  = 1,

		OnPickup = function(self,being)
			self.flags[ IF_NODESTROY ] = false
			ui.blink(LIGHTGREEN,100)
			player:add_assembly(mod_arrays[self.ammo].id)
			ui.msg_enter("You suddenly know how to assemble "..mod_arrays[self.ammo].name.."!")
		end,
	}

	register_item "schematic_2"
	{
		name     = "schematics",
		color    = LIGHTGREEN,
		sprite   = SPRITE_SCHEMATIC,
		sframes  = 2,
		level    = 9999,
		weight   = 1,
		flags  = { IF_NODESTROY },
		
		type    = ITEMTYPE_POWER,
		slevel  = 2,

		OnPickup = function(self,being)
			self.flags[ IF_NODESTROY ] = false
			ui.blink(LIGHTGREEN,100)
			player:add_assembly(mod_arrays[self.ammo].id)
			ui.msg_enter("You suddenly know how to assemble "..mod_arrays[self.ammo].name.."!")
		end,
	}


	register_item "lava_element"
	{
		name   = "lava element",
		color  = WHITE,
		level  = 200,
		sprite = SPRITE_LAVAINV,
		sflags = { SF_LARGE },
		weight = 0,
		type   = ITEMTYPE_PACK,
		ascii  = "+",
		flags  = { IF_NODESTROY },
		desc   = "A strange ball of shimmering light.",

		OnUse = function(self,being)
			if being:is_player() then
				being:play_sound( "phasing" )
				being:add_perk("inv",core.power_duration(90))
			end
			return true
		end,
	}
end
