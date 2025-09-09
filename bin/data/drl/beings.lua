function drl.register_beings()

	-- former humans ------------------------------------------------------

	register_being "former"
	{
		name         = "former human",
		ascii        = "h",
		color        = LIGHTGRAY,
		sprite       = SPRITE_FORMER,
		sframes      = 2,
		accuracy     = -4,
		speed        = 90,
		min_lev      = 0,
		max_lev      = 12,
		corpse       = true,
		danger       = 1,
		weight       = 10,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_evasive_ai",

		desc            = "Your fellow soldiers who went crazy because of the demonic influence. There's no hope for them anymore... only lead can heal their corrupted souls...",

		OnCreate = function (self)
			self.eq.weapon = "pistol"
			self.inv:add( "ammo" )
		end
	}

	register_being "sergeant"
	{
		name         = "former sergeant",
		ascii        = "h",
		color        = DARKGRAY,
		sprite       = SPRITE_SERGEANT,
		sframes      = 2,
		accuracy     = -2,
		speed        = 70,
		min_lev      = 2,
		max_lev      = 15,
		corpse       = true,
		danger       = 2,
		weight       = 10,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_evasive_ai",

		desc            = "Same as former human soldiers, but meaner and tougher. They'll provide you with an extra hole if you're not careful. They always carry a shotgun, so be on your guard!",
		kill_desc       = "was shot by a former sergeant",
		kill_desc_melee = "was maimed by a former sergeant",

		OnCreate = function (self)
			self.eq.weapon = "shotgun"
			self.inv:add( "shell", { amount = 30 } )
		end
	}

	register_being "captain"
	{
		name         = "former captain",
		ascii        = "h",
		color        = LIGHTRED,
		sprite       = SPRITE_CAPTAIN,
		sframes      = 2,
		speed        = 80,
		min_lev      = 5,
		max_lev      = 15,
		corpse       = true,
		danger       = 3,
		weight       = 10,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_evasive_ai",

		desc            = "Those were once really hardened marines, the tough fighting force of Earth. Now they're on the demonic side. They're really eager to make Swiss cheese out of you with their rapid fire chainguns...",
		kill_desc       = "was perforated by a former captain",
		kill_desc_melee = "was maimed by a former captain",

		OnCreate = function (self)
			self.eq.weapon = "chaingun"
			self.inv:add( "ammo", { amount = 40 } )
		end
	}

	register_being "commando"
	{
		name         = "former commando",
		ascii        = "h",
		color        = LIGHTBLUE,
		sprite       = SPRITE_COMMANDO,
		sframes      = 2,
		hp           = 20,
		armor        = 2,
		strength     = 1,
		accuracy     = 1,
		min_lev      = 12,
		max_lev      = 21,
		corpse       = true,
		danger       = 7,
		weight       = 6,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_evasive_ai",

		desc            = "These guys were evil to begin with. Being warped by Hell's power has only made them worse. Wielding a deadly plasma weapon, they should be treated with care... and lead.",
		kill_desc       = "was melted by former commando's plasma gun",
		kill_desc_melee = "was killed by a former commando",

		OnCreate = function (self)
			self.eq.weapon = "plasma"
		end
	}

	-- demons -------------------------------------------------------------

	register_being "imp"
	{
		name         = "imp",
		ascii        = "i",
		color        = BROWN,
		sprite       = SPRITE_IMP,
		sframes      = 2,
		hp           = 12,
		attackchance = 40,
		strength     = 1,
		accuracy     = 3,
		speed        = 105,
		min_lev      = 0,
		max_lev      = 17,
		corpse       = true,
		danger       = 2,
		weight       = 8,
		flags        = { BF_OPENDOORS },
		ai_type      = "melee_ranged_ai",

		resist = { fire = 25 },

		desc            = "Brown demonic servants from Hell, imps can throw fireballs at you. They're tough, mean and strong, and think only about sending you into oblivion...",
		kill_desc       = "was burned by an imp",
		kill_desc_melee = "was slashed by an imp",

		weapon = {
			damage     = "2d5",
			damagetype = DAMAGE_FIRE,
			radius     = 1,
			missile = {
				sound_id   = "imp",
				ascii      = "*",
				color      = LIGHTRED,
				delay      = 30,
				miss_base  = 50,
				miss_dist  = 5,
			},
			missprite  = SPRITE_FIREBALL,
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = RED,
			},
		},
	}

	register_being "demon"
	{
		name         = "demon",
		ascii        = "c",
		color        = LIGHTMAGENTA,
		sprite       = SPRITE_DEMON,
		sframes      = 2,
		hp           = 25,
		armor        = 2,
		strength     = 3,
		accuracy     = 3,
		speed        = 130,
		vision       = -2,
		min_lev      = 4,
		max_lev      = 20,
		corpse       = true,
		danger       = 4,
		weight       = 6,
		flags        = { BF_CHARGE },
		ai_type      = "flock_ai",

		desc            = "You thought pink is cute? You won't anymore after meeting one of these bastards -- they are strong, tough and eager to rip your head off...",
		kill_desc_melee = "was bitten by a demon",
	}

	register_being "lostsoul"
	{
		name         = "lost soul",
		ascii        = "s",
		color        = YELLOW,
		sprite       = SPRITE_LOSTSOUL,
		corpse       = false,
		sframes      = 2,
		attackchance = 60,
		strength     = 2,
		accuracy     = 12,
		hp           = 10,
		speed        = 100,
		vision       = 0,
		min_lev      = 6,
		max_lev      = 16,
		danger       = 3,
		weight       = 10,
		flags        = { BF_ENVIROSAFE, BF_FLY },
		ai_type      = "charger_ai",

		resist = { fire = 75, bullet = 50 },

		desc            = "Quick flying fiery skull. These are the souls lost in Hell. Let them rest in peace, or rather, in pieces...",
		kill_desc_melee = "was spooked by a lost soul",
	}

	register_being "cacodemon"
	{
		name         = "cacodemon",
		ascii        = "O",
		color        = RED,
		sprite       = SPRITE_CACODEMON,
		sframes      = 2,
		hp           = 40,
		armor        = 1,
		attackchance = 40,
		strength     = 3,
		accuracy     = 4,
		min_lev      = 10,
		max_lev      = 50,
		corpse       = true,
		danger       = 6,
		weight       = 6,
		flags        = { BF_ENVIROSAFE, BF_FLY },
		ai_type      = "melee_ranged_ai",

		desc            = "Big flying red horned heads. They spit huge explosive plasma balls. If you don't have the weapon to handle them, better run...",
		kill_desc       = "was smitten by a cacodemon",
		kill_desc_melee = "got too close to a cacodemon",

		weapon = {
			damage     = "2d6",
			damagetype = DAMAGE_PLASMA,
			radius     = 1,
			missile = {
				sound_id   = "cacodemon",
				ascii      = "*",
				color      = LIGHTMAGENTA,
				delay      = 30,
				miss_base  = 50,
				miss_dist  = 4,
			},
			missprite  = SPRITE_PLASMABALL,
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = MAGENTA,
			},
		},
	}

	register_being "knight"
	{
		name         = "hell knight",
		ascii        = "B",
		color        = BROWN,
		sprite       = SPRITE_KNIGHT,
		sframes      = 2,
		hp           = 50,
		armor        = 1,
		attackchance = 40,
		strength     = 3,
		accuracy     = 6,
		speed        = 110,
		min_lev      = 9,
		max_lev      = 15,
		corpse       = true,
		danger       = 6,
		weight       = 6,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_hybrid_ai",

		resist = { acid = 50 },

		desc            = "These are Hell's warlords. They command hellish armies to battle. Not as tough as Barons but are still a pain in the ass...",
		kill_desc       = "was splayed by a hell knight",
		kill_desc_melee = "was gutted by a hell knight",

		weapon = {
			damage     = "2d6",
			damagetype = DAMAGE_PLASMA,
			radius     = 1,
			missile = {
				sound_id   = "knight",
				ascii      = "*",
				color      = LIGHTMAGENTA,
				delay      = 30,
				miss_base  = 50,
				miss_dist  = 5,
			},
			missprite = {
				sprite     = SPRITE_ACIDSHOT,
				coscolor   = { 1.0, 0.0, 1.0, 1.0 },
			},
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = MAGENTA,
			},
		},
	}

	register_being "baron"
	{
		name         = "baron of hell",
		name_plural  = "barons of hell",
		ascii        = "B",
		color        = LIGHTMAGENTA,
		sprite       = SPRITE_BARON,
		sframes      = 2,
		hp           = 60,
		armor        = 2,
		attackchance = 40,
		strength     = 4,
		accuracy     = 5,
		min_lev      = 12,
		corpse       = true,
		danger       = 10,
		weight       = 6,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_hybrid_ai",

		resist = { acid = 50 },

		desc            = "Huge, almost humanoid, acid ball hurling monsters from your worst nightmares. They are the nobility of Hell.",
		kill_desc       = "was bruised by a baron of hell",
		kill_desc_melee = "was ripped open by a baron of hell",

		weapon = {
			damage     = "4d5",
			damagetype = DAMAGE_ACID,
			radius     = 2,
			missile = {
				sound_id   = "baron",
				ascii      = "*",
				color      = LIGHTGREEN,
				delay      = 35,
				miss_base  = 50,
				miss_dist  = 3,
			},
			missprite = {
				sprite     = SPRITE_ACIDSHOT,
				coscolor   = { 0.0, 1.0, 0.0, 1.0 },
			},
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = GREEN,
			},
		},
	}

	register_being "arachno"
	{
		name         = "arachnotron",
		ascii        = "A",
		color        = YELLOW,
		sprite       = SPRITE_ARACHNO,
		sframes      = 2,
		hp           = 50,
		armor        = 2,
		attackchance = 60,
		strength     = 1,
		accuracy     = 3,
		speed        = 130,
		min_lev      = 13,
		max_lev      = 50,
		corpse       = true,
		danger       = 9,
		weight       = 4,
		ai_type      = "ranged_ai",

		resist = { melee = -100 },

		desc            = "Evil can't get any purer. Spiderdemons equipped with a rapid-fire plasma cannon. Machine and flesh combined, kill on sight...",
		kill_desc       = "let an arachnotron get him",

		weapon = {
			damage     = "1d5",
			damagetype = DAMAGE_PLASMA,
			shots      = 5,
			missile = {
				sound_id   = "arachno",
				ascii      = "*",
				color      = MULTIYELLOW,
				delay      = 7,
				miss_base  = 20,
				miss_dist  = 4,
			},
			missprite  = SPRITE_PLASMASHOT,
			hitsprite  = SPRITE_BLAST,
		},

		OnCreate = function (self)
			self.inv:add( item.new("cell") )
		end
	}

	register_being "pain"
	{
		name         = "pain elemental",
		ascii        = "O",
		color        = BROWN,
		sprite       = SPRITE_PAIN,
		corpse       = false,
		sframes      = 2,
		hp           = 40,
		armor        = 1,
		strength     = 3,
		accuracy     = 2,
		min_lev      = 10,
		max_lev      = 40,
		danger       = 6,
		weight       = 4,
		flags        = { BF_ENVIROSAFE, BF_FLY },
		ai_type      = "spawner_ai",

		desc            = "Pain, pain, pain - this is the only thing these monsters live by, and the only thing they deliver. Wait, look again - they also deliver lost souls!",

		OnCreate = function (self)
			self.spawnlist = { name = "lostsoul", count = 3 }
		end,


		OnDie = function (self,overkill)
			if not overkill then
				for c=1,3 do self:spawn("lostsoul") end
			end
		end,
	}

	register_being "revenant"
	{
		name         = "revenant",
		ascii        = "R",
		color        = WHITE,
		sprite       = SPRITE_REVENANT,
		sframes      = 2,
		hp           = 30,
		armor        = 2,
		attackchance = 50,
		strength     = 3,
		accuracy     = 4,
		speed        = 120,
		min_lev      = 13,
		corpse       = true,
		danger       = 12,
		weight       = 5,
		flags        = { BF_OPENDOORS },
		ai_type      = "ranged_ai",

		resist = { fire = 25, bullet = 50 },

		desc            = "Apparently when a demon dies, they pick him up, dust him off, wire him some combat gear, and send him back into battle. No rest for the wicked, eh? You wish your missiles did what his can do.",
		kill_desc       = "couldn't evade a revenant's fireball",
		kill_desc_melee = "was punched by a revenant",

		weapon = {
			damage     = "5d5",
			damagetype = DAMAGE_FIRE,
			radius     = 1,
			flags      = { IF_EXACTHIT },
			missile = {
				sound_id   = "bazooka",
				color      = YELLOW,
				delay      = 30,
				miss_base  = 30,
				miss_dist  = 6,
			},
			missprite = SPRITE_ROCKETSHOT,
			hitsprite = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = RED,
			},
		},

		OnCreate = function (self)
			self.inv:add( "rocket" )
		end
	}

	register_being "mancubus"
	{
		name         = "mancubus",
		name_plural  = "mancubi",
		ascii        = "M",
		color        = BROWN,
		sprite       = SPRITE_MANCUBUS,
		sframes      = 2,
		hp           = 60,
		armor        = 2,
		attackchance = 50,
		strength     = 4,
		accuracy     = 3,
		speed        = 80,
		min_lev      = 15,
		corpse       = true,
		danger       = 12,
		weight       = 7,
		flags        = { BF_OPENDOORS },
		ai_type      = "sequential_ai",

		desc            = "It's big, it's mean, and it has two rocket launchers. What can be worse?",
		kill_desc       = "rode a mancubus rocket",
		kill_desc_melee = "was squashed by a mancubus",

		weapon = {
			damage     = "4d6",
			damagetype = DAMAGE_FIRE,
			radius     = 2,
			flags      = { IF_SPREAD },
			missile = {
				sound_id   = "mancubus",
				ascii      = "*",
				color      = LIGHTRED,
				delay      = 20,
				miss_base  = 1,
				miss_dist  = 3,
			},
			missprite  = SPRITE_ROCKETSHOT,
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = RED,
			},
		},

		OnCreate = function (self)
			self.inv:add( "rocket" )
		end
	}

	register_being "arch"
	{
		name         = "arch-vile",
		ascii        = "V",
		color        = YELLOW,
		sprite       = SPRITE_ARCHVILE,
		sframes      = 2,
		strength     = 3,
		hp           = 70,
		armor        = 2,
		attackchance = 50,
		accuracy     = 2,
		speed        = 160,
		min_lev      = 16,
		corpse       = "corpse",
		danger       = 14,
		weight       = 4,
		flags        = { BF_OPENDOORS, BF_SELFIMMUNE },
		ai_type      = "archvile_ai",

		desc            = "The worst thing you can encounter. With some unholy power far beyond your grasp they attack you with hellish flame, and can summon back the enemies you've worked so hard to banish!",
		kill_desc       = "was incinerated by an arch-vile",

		weapon = {
			damage     = "20d1",
			damagetype = DAMAGE_FIRE,
			radius     = 1,
			flags      = { IF_AUTOHIT, IF_INSTANTHIT, IF_EXACTHIT },
			missile = {
				sound_id   = "arch",
				color      = YELLOW,
				delay      = 0,
				miss_base  = 10,
				miss_dist  = 10,
				hitdesc    = "You are engulfed in flames!",
			},
			missprite = 0,
			hitsprite = SPRITE_BLAST,
			explosion  = {
				delay = 50,
				color = YELLOW,
				flags = { EFNOKNOCK, EFSELFSAFE },
			},
		},

		OnCreate = function (self)
			self:add_property( "master", true )
		end,
	}

	-- elite formers ------------------------------------------------------

	register_being "eformer"
	{
		name         = "elite former human",
		sound_id     = "former",
		ascii        = "h",
		color        = BROWN,
		sprite       = SPRITE_FORMER,
		sframes      = 2,
		glow         = { 0.0, 0.0, 1.0, 1.0 },
		strength     = 2,
		accuracy     = -2,
		speed        = 100,
		hp           = 20,
		armor        = 2,
		min_lev      = 40,
		max_lev      = 80,
		corpse       = false,
		danger       = 6,
		weight       = 4,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_evasive_ai",

		desc         = "These are the elite among the former humans. As stupid as their regular counterparts, but more resilient and packing quite a punch. Too bad their weapons are set to self-destruct on death.",
		-- Added to make sure we use the right article
		kill_desc       = "was killed by an elite former human",
		kill_desc_melee = "was killed by an elite former human",

		OnCreate = function (self)
			self.eq.weapon = "ucpistol"
			self.eq.weapon.flags[ IF_NODROP ] = true
			self.eq.armor = "garmor"
			self.inv:add( "ammo", { amount = 48 } )
			self.inv:add( "ammo" )
		end
	}

	register_being "esergeant"
	{
		name         = "elite former sergeant",
		sound_id     = "sergeant",
		ascii        = "h",
		color        = YELLOW,
		sprite       = SPRITE_SERGEANT,
		sframes      = 2,
		glow         = { 0.0, 0.0, 1.0, 1.0 },
		strength     = 2,
		speed        = 100,
		hp           = 25,
		armor        = 2,
		min_lev      = 60,
		max_lev      = 90,
		corpse       = false,
		danger       = 8,
		weight       = 3,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_evasive_ai",

		desc            = "These are the elite among the former sergeants. And they carry firepower to boot! Too bad their weapons are set to self-destruct on death.",
		kill_desc       = "was shot by an elite sergeant",
		kill_desc_melee = "was maimed by an elite sergeant",

		OnCreate = function (self)
			local wpammo = table.random_pick{
				{"upshotgun", "cell"},
				{"udshotgun", "shell"},
				{"uashotgun", "shell"}
			}
			self.eq.weapon = wpammo[1]
			self.inv:add( wpammo[2], { amount = 60 } )
			self.eq.weapon.flags[ IF_NODROP ] = true
			self.eq.armor = "garmor"
		end
	}

	register_being "ecaptain"
	{
		name         = "elite former captain",
		sound_id     = "captain",
		ascii        = "h",
		color        = LIGHTMAGENTA,
		sprite       = SPRITE_CAPTAIN,
		sframes      = 2,
		glow         = { 0.0, 0.0, 1.0, 1.0 },
		accuracy     = 1,
		strength     = 2,
		speed        = 90,
		hp           = 25,
		armor        = 2,
		min_lev      = 70,
		corpse       = false,
		danger       = 10,
		weight       = 3,
		flags        = { BF_OPENDOORS },
		ai_type      = "smart_evasive_ai",

		desc            = "These are the elite among the former captains. Beware of the superior firepower! Too bad their weapons are set to self-destruct on death.",
		kill_desc       = "was perforated by an elite captain",
		kill_desc_melee = "was maimed by an elite captain",

		OnCreate = function (self)
			local wpammo = table.random_pick{
				{"uminigun", "ammo", 200 },
				{"ulaser",  "cell", 50 },
			}
			self.eq.weapon = wpammo[1]
			self.inv:add( wpammo[2], { amount = wpammo[3] } )
			self.eq.weapon.flags[ IF_NODROP ] = true
			self.eq.armor = "barmor"
		end
	}

	register_being "ecommando"
	{
		name         = "elite former commando",
		sound_id     = "commando",
		ascii        = "h",
		color        = LIGHTCYAN,
		sprite       = SPRITE_COMMANDO,
		sframes      = 2,
		glow         = { 0.0, 0.0, 1.0, 1.0 },
		hp           = 40,
		armor        = 3,
		strength     = 2,
		accuracy     = 3,
		min_lev      = 80,
		corpse       = false,
		danger       = 14,
		weight       = 2,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE },
		ai_type      = "smart_evasive_ai",

		desc            = "As expected, these ex-human soldiers are the best of the best! Armored, resilient and with superior firepower! Too bad their weapons are set to self-destruct on death.",
		kill_desc       = "was melted by an elite commando's gun",
		kill_desc_melee = "was killed by an elite commando",

		OnCreate = function (self)
			local wpammo = table.random_pick{
				{"utristar",  "cell", 60 },
				{"umbazooka", "rocket", 20 },
				{"unapalm",  "rocket", 12 },
			}
			self.eq.weapon = wpammo[1]
			self.inv:add( wpammo[2], { amount = wpammo[3] } )
			self.eq.weapon.flags[ IF_NODROP ] = true
			self.eq.armor = "barmor"
		end
	}

	-- nightmare demons ---------------------------------------------------

	register_being "nimp"
	{
		name         = "nightmare imp",
		ascii        = "i",
		color        = LIGHTBLUE,
		sprite       = SPRITE_IMP,
		sframes      = 2,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		hp           = 35,
		attackchance = 50,
		strength     = 3,
		accuracy     = 6,
		min_lev      = 30,
		max_lev      = 60,
		corpse       = true,
		danger       = 6,
		weight       = 8,
		speed        = 120,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE },
		ai_type      = "melee_ranged_ai",

		resist = { fire = 50 },

		desc            = "Are you seeing things? What's with the color change? And why is it taking so much longer to kill these things!?",
		kill_desc       = "was burned by a nightmare imp",
		kill_desc_melee = "was eviscerated by a nightmare imp",

		weapon = {
			damage     = "2d6",
			damagetype = DAMAGE_PLASMA,
			radius     = 1,
			missile = {
				sound_id   = "imp",
				ascii      = "*",
				color      = LIGHTMAGENTA,
				delay      = 15,
				miss_base  = 20,
				miss_dist  = 4,
			},
			missprite = SPRITE_FIREBALL,
			hitsprite = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = MAGENTA,
			},
		}
	}

	register_being "ndemon"
	{
		name         = "nightmare demon",
		ascii        = "c",
		color        = LIGHTBLUE,
		sprite       = SPRITE_DEMON,
		sframes      = 2,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		hp           = 80,
		armor        = 3,
		strength     = 5,
		accuracy     = 5,
		speed        = 140,
		min_lev      = 40,
		corpse       = true,
		danger       = 8,
		weight       = 6,
		flags        = { BF_CHARGE, BF_ENVIROSAFE },
		ai_type      = "flock_ai",

		desc            = "You liked it better when these guys were pink. Meet the stronger, tougher, more resilient way to meet your death.",
		kill_desc_melee = "was eaten alive by a nightmare demon",
	}

	register_being "nlostsoul"
	{
		name         = "nightmare soul",
		ascii        = "s",
		color        = LIGHTBLUE,
		sprite       = SPRITE_NLOSTSOUL,
		corpse       = false,
		sframes      = 2,
		attackchance = 70,
		strength     = 3,
		accuracy     = 12,
		speed        = 120,
		hp           = 20,
		vision       = 0,
		danger       = 4,
		weight       = 0,
		min_lev      = 200,
		flags        = { BF_ENVIROSAFE, BF_FLY },
		ai_type      = "charger_ai",

		resist = { fire = 75, bullet = 50 },

		desc            = "The flying bluish skull. Wouldn't be a problem if there weren't so many of these nightmarish things...",
		kill_desc_melee = "was terrified by a nightmare soul",
	}

	register_being "ncacodemon"
	{
		name         = "nightmare cacodemon",
		ascii        = "O",
		color        = LIGHTBLUE,
		sprite       = SPRITE_CACODEMON,
		sframes      = 2,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		hp           = 100,
		armor        = 2,
		attackchance = 50,
		strength     = 4,
		accuracy     = 6,
		speed        = 120,
		min_lev      = 51,
		corpse       = true,
		danger       = 10,
		weight       = 6,
		flags        = { BF_ENVIROSAFE, BF_FLY },
		ai_type      = "ranged_ai",
		resist       = { acid = 50, fire = 50, plasma = 50 },

		desc            = "Hell's latest improvement on demonic warfare - they're stronger, tougher, and angrier than ever.",
		kill_desc       = "was fried by a nightmare cacodemon",
		kill_desc_melee = "was flattened by a nightmare cacodemon",

		weapon = {
			damage     = "3d7",
			damagetype = DAMAGE_PLASMA,
			radius     = 1,
			missile = {
				sound_id   = "cacodemon",
				ascii      = "*",
				color      = LIGHTMAGENTA,
				delay      = 30,
				miss_base  = 30,
				miss_dist  = 4,
			},
			missprite = SPRITE_PLASMABALL,
			hitsprite = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = MAGENTA,
			},
		},
	}

	register_being "nknight"
	{
		name         = "nightmare knight",
		ascii        = "B",
		color        = LIGHTBLUE,
		sprite       = SPRITE_BRUISER,
		sframes      = 2,
		sflags       = { SF_LARGE },
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		hp           = 80,
		armor        = 4,
		attackchance = 60,
		strength     = 5,
		accuracy     = 6,
		speed        = 120,
		min_lev      = 41,
		corpse       = true,
		danger       = 12,
		weight       = 4,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE },
		ai_type      = "smart_hybrid_ai",

		resist = { acid = 75, fire = 25, plasma = 25 },

		desc            = "The nightmare side of the knight and baron strain. You hope it won't get worse than this. You hope...",
		kill_desc       = "was splayed by a nightmare knight",
		kill_desc_melee = "was gutted by a nightmare knight",

		weapon = {
			damage     = "4d6",
			damagetype = DAMAGE_PLASMA,
			radius     = 2,
			missile = {
				sound_id   = "baron",
				ascii      = "*",
				color      = LIGHTMAGENTA,
				delay      = 30,
				miss_base  = 30,
				miss_dist  = 4,
			},
			missprite = {
				sprite = SPRITE_PLASMABALL,
				coscolor   = { 1.0, 0.0, 1.0, 1.0 },
			},
			hitsprite = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = MAGENTA,
			},
		},
	}

	register_being "narachno"
	{
		name         = "nightmare arachnotron",
		ascii        = "A",
		color        = LIGHTBLUE,
		sprite       = SPRITE_ARACHNO,
		sframes      = 2,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		hp           = 80,
		armor        = 2 ,
		attackchance = 60,
		strength     = 2,
		accuracy     = 4,
		speed        = 150,
		min_lev      = 50,
		corpse       = true,
		danger       = 12,
		weight       = 4,
		ai_type      = "sequential_ai",
		flags        = { BF_ENVIROSAFE },

		desc            = "Pure nightmare spiders. You'd wish they weren't there...",
		kill_desc       = "let an nightmare arachnotron get him",

		weapon = {
			damage     = "1d6",
			damagetype = DAMAGE_PLASMA,
			shots      = 6,
			missile = {
				sound_id   = "arachno",
				ascii      = "*",
				color      = LIGHTBLUE,
				delay      = 10,
				miss_base  = 20,
				miss_dist  = 4,
			},
			missprite = SPRITE_PLASMASHOT,
			hitsprite = SPRITE_BLAST,
		},

		OnCreate = function (self)
			self.inv:add( "cell", { amount = 20 } )
		end
	}

	register_being "npain"
	{
		name         = "nightmare elemental",
		ascii        = "O",
		color        = LIGHTBLUE,
		sprite       = SPRITE_PAIN,
		corpse       = false,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		sframes      = 2,
		hp           = 100,
		armor        = 4,
		strength     = 5,
		accuracy     = 4,
		min_lev      = 70,
		danger       = 16,
		weight       = 3,
		flags        = { BF_ENVIROSAFE, BF_FLY },
		ai_type      = "spawner_ai",

		desc            = "Pain, pain, pain, nightmare pain. Oh and nightmare souls...",

		OnCreate = function (self)
			self.spawnlist = { name = "nlostsoul", count = 3 }
		end,

		OnDie = function (self,overkill)
			if not overkill then
				for c=1,3 do self:spawn("nlostsoul") end
			end
		end,
	}

	register_being "nrevenant"
	{
		name         = "nightmare revenant",
		ascii        = "R",
		color        = LIGHTBLUE,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		sprite       = SPRITE_REVENANT,
		sframes      = 2,
		hp           = 50,
		armor        = 3,
		attackchance = 60,
		strength     = 5,
		accuracy     = 6,
		speed        = 160,
		min_lev      = 60,
		corpse       = true,
		danger       = 15,
		weight       = 6,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE },
		ai_type      = "ranged_ai",

		resist = { fire = 25, bullet = 50 },

		desc            = "This revenant has been dusted off and wired up one time too many. And it shows...",
		kill_desc       = "couldn't evade a nightmare revenant's fireball",
		kill_desc_melee = "was mauled by a nightmare revenant",

		weapon = {
			damage     = "6d6",
			damagetype = DAMAGE_FIRE,
			radius     = 1,
			flags      = { IF_EXACTHIT },
			missile = {
				sound_id   = "bazooka",
				color      = YELLOW,
				delay      = 30,
				miss_base  = 30,
				miss_dist  = 5,
			},
			missprite  = SPRITE_ROCKETSHOT,
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = RED,
			},
		},

		OnCreate = function (self)
			self.inv:add( "rocket" )
		end
	}

	register_being "nmancubus"
	{
		name         = "nightmare mancubus",
		name_plural  = "nightmare mancubi",
		ascii        = "M",
		color        = LIGHTBLUE,
		sprite       = SPRITE_MANCUBUS,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		sframes      = 2,
		hp           = 120,
		armor        = 4,
		attackchance = 70,
		strength     = 6,
		accuracy     = 3,
		speed        = 80,
		min_lev      = 75,
		corpse       = true,
		danger       = 15,
		weight       = 4,
		flags        = { BF_OPENDOORS, BF_KNOCKIMMUNE, BF_ENVIROSAFE },
		ai_type      = "sequential_ai",
		resist 	     = { melee = 50, acid = 50 },

		desc            = "What's blue and has two rocket launchers? Something worse.",
		kill_desc       = "rode a nightmare mancubi rocket",
		kill_desc_melee = "was flattened by a nightmare mancubus",

		weapon = {
			damage     = "4d7",
			damagetype = DAMAGE_ACID,
			radius     = 2,
			flags      = { IF_SPREAD },
			missile = {
				sound_id   = "mancubus",
				ascii      = "*",
				color      = GREEN,
				delay      = 20,
				miss_base  = 1,
				miss_dist  = 3,
			},
			missprite  = SPRITE_ROCKETSHOT,
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay   = 40,
				color   = GREEN,
				content = "acid",
			},
		},

		OnCreate = function (self)
			self.inv:add( "rocket" )
		end
	}

	register_being "narch"
	{
		name         = "nightmare arch-vile",
		ascii        = "V",
		color        = LIGHTBLUE,
		sprite       = SPRITE_ARCHVILE,
		sframes      = 2,
		overlay      = { 0.2, 0.2, 1.0, 0.8 },
		hp           = 150,
		armor        = 3,
		attackchance = 60,
		strength     = 4,
		accuracy     = 4,
		speed        = 180,
		min_lev      = 80,
		corpse       = "corpse",
		danger       = 20,
		weight       = 3,
		flags        = { BF_OPENDOORS, BF_SELFIMMUNE, BF_ENVIROSAFE },
		ai_type      = "archvile_ai",

		desc            = "Oh God... *WHY* do they come in the nightmare variety too?",
		kill_desc       = "faced a nightmare arch-vile",

		weapon = {
			damage     = "20d1",
			damagetype = DAMAGE_PLASMA,
			radius     = 2,
			flags      = { IF_AUTOHIT, IF_INSTANTHIT, IF_EXACTHIT },
			missile = {
				sound_id   = "arch",
				color      = LIGHTBLUE,
				delay      = 0,
				miss_base  = 10,
				miss_dist  = 10,
				hitdesc    = "You are engulfed in flames!",
			},
			missprite = 0,
			hitsprite = SPRITE_BLAST,
			explosion  = {
				delay = 50,
				color = BLUE,
				flags = { EFNOKNOCK, EFSELFSAFE },
			},
		},

		OnCreate = function (self)
			self:add_property( "master", true )
		end,
	}

	-- special enemies ----------------------------------------------------

	register_being "bruiser"
	{
		name         = "bruiser brother",
		name_plural  = "bruiser brothers",
		ascii        = "B",
		color        = LIGHTRED,
		sprite       = SPRITE_BRUISER,
		sframes      = 2,
		sflags       = { SF_LARGE },
		hp           = 60,
		armor        = 2,
		attackchance = 40,
		strength     = 4,
		accuracy     = 5,
		min_lev      = 40,
		corpse       = true,
		danger       = 14,
		weight       = 6,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE, BF_HUNTING},
		ai_type      = "smart_hybrid_ai",

		resist = { acid = 50 },

		desc            = "Tough as a dump truck and nearly as big, these Goliaths are the worst things on two legs since Tyrannosaurus Rex.",
		kill_desc       = "was baptised by a bruiser brother",
		kill_desc_melee = "was pounded rather hard by a bruiser brother",

		weapon = {
			damage     = "4d5",
			damagetype = DAMAGE_ACID,
			radius     = 2,
			missile = {
				sound_id   = "baron",
				ascii      = "*",
				color      = LIGHTGREEN,
				delay      = 35,
				miss_base  = 40,
				miss_dist  = 3,
			},
			missprite = {
				sprite     = SPRITE_ACIDSHOT,
				coscolor   = { 0.0, 1.0, 0.0, 1.0 },
			},
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay   = 40,
				color   = GREEN,
			},
		},

		OnCreate = function (self)
	 		self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 3
			self.hp = self.hpmax
		end
	}

	register_being "shambler"
	{
		name         = "shambler",
		name_plural  = "shamblers",
		ascii        = "B",
		color        = WHITE,
		sprite       = SPRITE_SHAMBLER,
		sframes      = 2,
		sflags       = { SF_LARGE },
		hp           = 80,
		armor        = 3,
		attackchance = 75,
		strength     = 4,
		accuracy     = 4,
		min_lev      = 60,
		corpse       = true,
		danger       = 14,
		weight       = 3,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE, BF_HUNTING },
		ai_type      = "teleboss_ai",

		desc            = "Even other monsters fear him, so expect a clobbering. He shrugs off explosions. Good luck.",
		kill_desc       = "was electrocuted by a shambler",
		kill_desc_melee = "was consumed by a shambler",

		weapon = {
			damage     = "4d5",
			damagetype = DAMAGE_PLASMA,
			missile = {
				color     = WHITE,
				delay     = 5,
				miss_base = 10,
				miss_dist = 3,
			},
			missprite = {
				sprite    = SPRITE_CSHOT,
				coscolor  = { 0.2,0.2,0.3,1.0 },
			},
			hitsprite = SPRITE_BLAST,
			flags     = { IF_RAYGUN },
		},

		OnCreate = function (self)
			self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 5
			self.hp = self.hpmax
			self.telechance = 15
			self.teleradius = 8
		end,

		OnAction = function (self)
			if not core.is_playing() then return end
			if self.hp < self.hpmax then
				self.hp = self.hp + 1
			end
			--old explosion was LIGHTBLUE
			if math.random(10) == 1 then
				self:play_sound("act")
			end
		end,
	}

	register_being "lava_elemental"
	{
		name         = "lava elemental",
		name_plural  = "lava elemental",
		ascii        = "E",
		corpse       = false,
		color        = YELLOW,
		sprite       = SPRITE_LAVAELEM,
		sframes      = 2,
		sflags       = { SF_LARGE },
		--overlay      = { 0.4, 0.4, 1.0 },
		hp           = 100,
		armor        = 5,
		attackchance = 30,
		strength     = 6,
		accuracy     = 4,
		min_lev      = 70,
		danger       = 16,
		weight       = 1,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE, BF_FLY },
		ai_type      = "teleboss_ai",

		resist = { fire = 100 },

		desc            = "Big ball of fire...",
		kill_desc       = "was burned by a lava elemental",
		kill_desc_melee = "was burned by a lava elemental",

		weapon = {
			damage     = "5d4",
			damagetype = DAMAGE_FIRE,
			radius     = 3,
			flags      = { IF_EXACTHIT },
			missile = {
				sound_id   = "cacodemon",
				ascii      = "*",
				color      = LIGHTRED,
				delay      = 50,
				miss_base  = 30,
				miss_dist  = 4,
			},
			missprite  = SPRITE_EXPLOSION,
			hitsprite  = SPRITE_BLAST,
			explosion  = {
				delay = 40,
				color = RED,
				flags = { EFRANDOMCONTENT },
				content = "lava",
			},
		},

		OnCreate = function (self)
			self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 5
			self.hp = self.hpmax
			self.telechance = 5
			self.teleradius = 5
		end,

		OnAction = function (self)
			if not core.is_playing() then return end
			if self.hp < self.hpmax then
				self.hp = self.hp + 1
			end
			--old explosion was RED
		end,
	}

	register_being "agony"
	{
		name         = "agony elemental",
		ascii        = "O",
		color        = LIGHTMAGENTA,
		sprite       = SPRITE_AGONY,
		corpse       = false,
		sframes      = 2,
		hp           = 150,
		armor        = 4,
		strength     = 3,
		accuracy     = 2,
		min_lev      = 80,
		danger       = 20,
		weight       = 1,
		flags        = { BF_ENVIROSAFE, BF_FLY },
		ai_type      = "spawner_ai",

		desc            = "Seems like the pain elementals' big momma!",

		OnCreate = function (self)
			self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 5
			self.hp = self.hpmax
			self.spawnlist = {
				{name = "lostsoul", count = 3},
				{name = "pain",     count = 1},
			}
		end,

		OnDie = function (self,overkill)
			if not overkill then
				for c=1,2 do self:spawn("pain") end
				for c=1,6 do self:spawn("lostsoul") end
			end
		end,
	}

	register_being "angel"
	{
		name         = "Angel of Death",
		name_plural  = "Angels of Death",
		ascii        = "A",
		corpse       = false,
		color        = RED,
		sprite       = SPRITE_ANGEL,
		sframes      = 2,
		sflags       = { SF_LARGE },
		hp           = 250,
		armor        = 10,
		strength     = 8,
		accuracy     = 8,
		speed        = 150,
		min_lev      = 200,
		danger       = 40,
		weight       = 0,
		xp           = 1000,
		flags        = { BF_CHARGE, BF_ENVIROSAFE ,BF_HUNTING },
		ai_type      = "angel_ai",

		desc            = "Why doesn't a BFG work when you really need it? As if from a half-forgotten nightmare, you encounter the harbinger of death...",
		kill_desc_melee = "was ripped apart by the Angel of Death",

		OnCreate = function (self)
			self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 10
			self.hp = self.hpmax

			self:add_property( "master", true )
		end,
	}

	register_medal "cyberdemon1"
	{
		name = "Cyberdemon's Head",
		desc = "Killing the Cyberdemon w/o taking damage",
	}

	register_being "cyberdemon"
	{
		name         = "Cyberdemon",
		ascii        = "C",
		color        = BROWN,
		sprite       = SPRITE_CYBERDEMON,
		sframes      = 2,
		sflags       = { SF_LARGE },
		corpse       = true,
		hp           = 200,
		armor        = 4,
		strength     = 8,
		accuracy     = 8,
		speed        = 110,
		vision       = 1,
		min_lev      = 70,
		danger       = 30,
		weight       = 1,
		flags        = { BF_OPENDOORS, BF_ENVIROSAFE, BF_SELFIMMUNE, BF_KNOCKIMMUNE },
		ai_type      = "cyberdemon_ai",

		desc            = "Monster and machine, combined. Equipped with a rocket launcher, this nightmare is the worst thing you can find in Hell. Or at least that is what you hope...",
		kill_desc       = "was splattered by a Cyberdemon",
		kill_desc_melee = "was ripped apart by a Cyberdemon",

		OnCreate = function (self)
			self.eq.weapon = "bazooka"
			for i=1,4 do
				self.inv:add( "rocket", { amount = 10 } )
			end
			self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 10
			self.hp = self.hpmax

			self:add_property( "master", true )
			self:add_property( "is_boss", false )
		end,

		OnDie = function (self)
			if self.is_boss then
				level:explosion( self.position, { range = 17, delay = 40, color = RED, sound_id = "barrel.explode", flags = {EFALWAYSVISIBLE} } )
				ui.msg_enter("The Cyberdemon is dead!")
				if not level.flags[ LF_NUKED ] and statistics.damage_on_level == 0 then
					player:add_medal("cyberdemon1")
				end
			end
		end,
	}

	register_medal "mastermind1"
	{
		name = "Mastermind's Brain",
		desc = "Killing the Mastermind w/o taking damage",
	}

	register_being "mastermind"
	{
		name         = "Spider Mastermind",
		ascii        = "M",
		color        = WHITE,
		sprite       = SPRITE_MASTERMIND,
		sframes      = 2,
		sflags       = { SF_LARGE },
		hp           = 250,
		armor        = 2 ,
		attackchance = 60,
		strength     = 8,
		accuracy     = 4,
		speed        = 150,
		min_lev      = 200,
		corpse       = true,
		danger       = 50,
		weight       = 0,
		flags        = { BF_ENVIROSAFE, BF_SELFIMMUNE, BF_KNOCKIMMUNE },
		ai_type      = "mastermind_ai",

		desc            = "You guess the Arachnotrons had to come from somewhere. Hi, mom. She doesn't have a plasma gun, so thank heaven for small favors. Instead, she has a super-chaingun.",
		kill_desc       = "let the Spider Mastermind pwn him",

		weapon = {
			damage     = "1d6",
			damagetype = DAMAGE_PLASMA,
			shots      = 6,
			flags      = { IF_DESTRUCTIVE },
			missile = {
				sound_id   = "chaingun",
				ascii      = "-",
				color      = YELLOW,
				delay      = 20,
				miss_base  = 20,
				miss_dist  = 4,
			},
			missprite  = SPRITE_SHOT,
			hitsprite  = SPRITE_BLAST,
		},

		OnCreate = function (self)
			self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 10
			self.hp = self.hpmax

			self:add_property( "master", true )
			self:add_property( "is_boss", false )
		end,

		OnDie = function (self)
			if self.is_boss then
				level:explosion( self.position, { range = 17, delay = 40, color = RED, sound_id = "barrel.explode", flags = {EFALWAYSVISIBLE} } )
				self.expvalue = 0
				if not level.flags[ LF_NUKED ] and statistics.damage_on_level == 0 then
					player:add_medal("mastermind1")
				end
			end
		end,
	}

	register_being "jc"
	{
		name         = "John Carmack",
		name_plural  = "FINAL EVIL",
		ascii        = "@",
		color        = LIGHTBLUE,
		sprite       = SPRITE_JC,
		corpse       = false,
		sframes      = 2,
		sflags       = { SF_LARGE },
		hp           = 250,
		armor        = 5,
		strength     = 8,
		accuracy     = 8,
		vision       = 1,
		min_lev      = 200,
		danger       = 50,
		weight       = 0,
		xp           = 0,
		flags        = { BF_OPENDOORS, BF_UNIQUENAME, BF_SELFIMMUNE, BF_KNOCKIMMUNE },
		ai_type      = "jc_ai",

		desc            = "You knew it. This is the true EVIL behind the invasion! This is the true mastermind of Hell! Kill him for he knows not the meaning of mercy! Kill him!! Kill him NOW!!!",
		kill_desc       = "was pwned by John Carmack",

		OnCreate = function (self)
			self.eq.weapon = "bazooka"
			for i=1,3 do
				self.inv:add( "rocket", { amount = 10 } )
			end

			self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 10
			self.hp = self.hpmax

			self:add_property( "master",  true )
			self:add_property( "is_boss", false )
		end,

		OnDie = function (self)
			if self.is_boss then
				level:explosion( self.position, { range = 17, delay = 40, color = BLUE, sound_id = "barrel.explode", flags = {EFALWAYSVISIBLE} } )
				for b in level:beings() do
					if not ( b:is_player() ) and b.id ~= "jc" then
						b:kill()
					end
				end
				ui.msg_enter("Congratulations! You defeated John Carmack!")
			end
		end,
	}

	register_medal "dragonslayer2"
	{
		name = "Apostle Insignia",
		desc = "Awarded for killing the Apostle",
		hidden = true,
	}

	register_being "apostle"
	{
		name         = "Apostle",
		ascii        = "@",
		color        = YELLOW,
		sprite       = SPRITE_APOSTLE,
		sframes      = 2,
		sflags       = { SF_LARGE },
		hp           = 255,
		armor        = 30,
		vision       = 2,
		attackchance = 60,
		strength     = 7,
		accuracy     = 2,
		speed        = 160,
		min_lev      = 200,
		corpse       = "corpse",
		danger       = 0,
		weight       = 0,
		flags        = { BF_OPENDOORS, BF_SELFIMMUNE, BF_KNOCKIMMUNE },
		ai_type      = "archvile_ai",
		sound_id     = "arch",

		resist = { bullet = 75, shrapnel = 75, melee = 75, fire = 75, acid = 75, plasma = 75 },

		desc            = "This seems so unreal, as though from another story...",
		kill_desc       = "was killed by the Apostle",

		weapon = {
			damage     = "40d1",
			damagetype = DAMAGE_PLASMA,
			radius     = 3,
			flags      = { IF_AUTOHIT, IF_INSTANTHIT, IF_EXACTHIT },
			missile = {
				sound_id   = "arch",
				hitdesc    = "You are engulfed in flames!",
				color      = YELLOW,
				delay      = 0,
				miss_base  = 10,
				miss_dist  = 10,
			},
			missprite = 0,
			hitsprite = SPRITE_BLAST,
			explosion  = {
				delay = 50,
				color = YELLOW,
				flags = { EFNOKNOCK, EFSELFSAFE },
			},
		},

		OnCreate = function (self)
			level.flags[ LF_NONUKE ] = true
			self:add_property( "master", true )
			self:add_property( "is_boss", false )
		end,

		OnAction = function (self)
			if not core.is_playing() then return end
			if self.hp < self.hpmax then
				self.hp = self.hp + 1
			end
			if math.random(20) == 1 then
				self:play_sound("phasing")
				level:explosion( self.position, { range = 1, delay = 50, color = LIGHTBLUE } )
				self:phase()
				level:explosion( self.position, { range = 1, delay = 50, color = LIGHTBLUE } )
			end
			if math.random(10) == 1 then
				self:play_sound("act")
			end
		end,

		OnDie = function (self)
			player:add_medal("dragonslayer2")
			if CHALLENGE == "challenge_a100" then
				level.map[ self.position ] = "stairs"
			elseif self.is_boss then
				level:explosion( self.position, { range = 17, delay = 40, color = RED, sound_id = "barrel.explode", flags = {EFALWAYSVISIBLE} } )
				for b in level:beings() do
					if not ( b:is_player() ) and b.id ~= "apostle" then
						b:kill()
					end
				end
				ui.msg_enter("Congratulations! You defeated the Apostle!")
			end
		end,
	}

  	-- enemy groups -------------------------------------------------------

	register_being_group
	{
		min_lev = 7,
		max_lev = 16,
		weight  = 10,
		beings = {
			{ being = "sergeant" },
			{ being = "former", amount = {2,6} }
		}
	}

	register_being_group
	{
		min_lev = 5,
		max_lev = 8,
		weight  = 10,
		beings = {
			{ being = "imp", amount = {3,4} }
		}
	}

	register_being_group
	{
		min_lev = 9,
		max_lev = 12,
		weight  = 10,
		beings = {
			{ being = "knight" },
			{ being = "imp", amount = {2,6} }
		}
	}

	register_being_group
	{
		min_lev = 13,
		max_lev = 21,
		weight  = 10,
		beings = {
			{ being = "baron" },
			{ being = "imp", amount = {4,9} }
		}
	}

	register_being_group
	{
		min_lev = 15,
		max_lev = 21,
		weight  = 10,
		beings = {
			{ being = "commando" },
			{ being = "sergeant", amount = {2,6} }
		}
	}

	register_being_group
	{
		min_lev = 13,
		max_lev = 25,
		weight  = 8,
		beings = {
			{ being = "pain" },
			{ being = "lostsoul", amount = {3,8} }
		}
	}

	register_being_group
	{
		min_lev = 10,
		max_lev = 22,
		weight  = 4,
		beings = {
			{ being = "demon", amount = {4,9} }
		}
	}

	register_being_group
	{
		min_lev = 20,
		max_lev = 60,
		weight  = 4,
		beings = {
			{ being = "baron" },
			{ being = "knight", amount = {2,4} }
		}
	}

	register_being_group
	{
		min_lev = 20,
		weight  = 3,
		beings = {
			{ being = "arachno", amount = {3,6} }
		}
	}

	register_being_group
	{
		min_lev = 20,
		max_lev = 89,
		weight  = 2,
		beings = {
			{ being = "arch",     amount = 2 },
			{ being = "captain",  amount = 4 },
			{ being = "sergeant", amount = 4 },
			{ being = "former",   amount = {3,6} }
		}
	}

	register_being_group
	{
		min_lev = 20,
		max_lev = 69,
		weight  = 5,
		beings = {
			{ being = "baron",    amount = 2 },
			{ being = "captain",  amount = {2,3} },
			{ being = "sergeant", amount = {2,3} }
		}
	}

	register_being_group
	{
		min_lev = 20,
		weight  = 4,
		beings = {
			{ being = "arch",     amount = 2 },
			{ being = "mancubus", amount = {2,5} },
		}
	}

	register_being_group
	{
		min_lev = 20,
		weight  = 4,
		beings = {
			{ being = "arch",     amount = 2 },
			{ being = "revenant", amount = {2,5} },
		}
	}

	register_being_group
	{
		min_lev = 25,
		weight  = 4,
		beings = {
			{ being = "arch",     amount = 2 },
			{ being = "baron",    amount = {3,9} }
		}
	}

	register_being_group  -- Mancubi For Added Fun (MFAF, tm by Malek)
	{
		min_lev = 25,
		weight  = 2,
		beings = {
			{ being = "arch",     amount = 2 },
			{ being = "captain",  amount = {2,8} },
			{ being = "mancubus", amount = {2,3} },
		}
	}

  	-- Ao100+ enemy groups ------------------------------------------------

	register_being_group
	{
		min_lev = 30,
		weight  = 4,
		beings = {
			{ being = "pain", amount = 2 },
			{ being = "cacodemon", amount = {2,5} }
		}
	}

	register_being_group
	{
		min_lev = 30,
		max_lev = 59,
		weight  = 4,
		beings = {
			{ being = "nlostsoul", amount = {4,9} }
		}
	}

	register_being_group
	{
		min_lev = 60,
		weight  = 4,
		beings = {
			{ being = "npain", amount = 2 },
			{ being = "nlostsoul", amount = {4,6} }
		}
	}

	register_being_group
	{
		min_lev = 35,
		max_lev = 49,
		weight  = 4,
		beings = {
			{ being = "ndemon", amount = {3,5} }
		}
	}

	register_being_group
	{
		min_lev = 50,
		weight  = 4,
		beings = {
			{ being = "ndemon", amount = {4,8} }
		}
	}

	register_being_group
	{
		min_lev = 30,
		max_lev = 59,
		weight  = 4,
		beings = {
			{ being = "baron", amount = 2 },
			{ being = "nimp",  amount = {2,6} }
		}
	}

	register_being_group
	{
		min_lev = 60,
		weight  = 4,
		beings = {
			{ being = "nknight", amount = 2 },
			{ being = "nimp",  amount = {4,8} }
		}
	}

	register_being_group
	{
		min_lev = 90,
		weight  = 2,
		beings = {
			{ being = "narch",     amount = 1 },
			{ being = "ecaptain",  amount = {2,3} },
			{ being = "esergeant", amount = {2,3} },
			{ being = "eformer",   amount = {3,6} }
		}
	}

	register_being_group
	{
		min_lev = 70,
		weight  = 3,
		beings = {
			{ being = "nknight",   amount = 2 },
			{ being = "ecaptain",  amount = {2,3} },
			{ being = "esergeant", amount = {2,3} }
		}
	}

	register_being_group
	{
		min_lev = 70,
		weight  = 2,
		beings = {
			{ being = "ecommando", amount = 1 },
			{ being = "ecaptain",  amount = {2,3} },
			{ being = "esergeant", amount = {2,3} }
		}
	}

	register_being_group
	{
		min_lev = 70,
		weight  = 2,
		beings = {
			{ being = "narachno", amount = {3,6} }
		}
	}

	register_being_group
	{
		min_lev = 75,
		weight  = 1,
		beings = {
			{ being = "lava_elemental", amount = {1,3} },
			{ being = "shambler",       amount = {2,3} }
		}
	}

	register_being_group
	{
		min_lev = 80,
		weight  = 2,
		beings = {
			{ being = "cyberdemon", amount = 1 },
			{ being = "baron", amount = {4,8} }
		}
	}

	register_being_group
	{
		min_lev = 85,
		weight  = 2,
		beings = {
			{ being = "agony",      amount = 1 },
			{ being = "ncacodemon", amount = {3,8} }
		}
	}

	register_being_group
	{
		min_lev = 90,
		weight  = 1,
		beings = {
			{ being = "cyberdemon", amount = 1 },
			{ being = "bruiser", amount = {3,6} }
		}
	}

	register_being_group
	{
		min_lev = 95,
		max_lev = 149,
		weight  = 2,
		beings = {
			{ being = "nmancubus", amount = {2,4} },
		}
	}

	register_being_group
	{
		min_lev = 95,
		max_lev = 149,
		weight  = 2,
		beings = {
			{ being = "nrevenant", amount = {2,4} },
		}
	}

	register_being_group
	{
		min_lev = 100,
		weight  = 2,
		beings = {
			{ being = "narch",      amount = 2 },
			{ being = "nmancubus",  amount = {2,4} },
			{ being = "nrevenant",  amount = {2,4} },
		}
	}

	register_being_group
	{
		min_lev = 150,
		weight  = 2,
		beings = {
			{ being = "narch",     amount = 2 },
			{ being = "nmancubus", amount = {2,5} },
		}
	}

	register_being_group
	{
		min_lev = 150,
		weight  = 2,
		beings = {
			{ being = "narch",     amount = 2 },
			{ being = "nrevenant", amount = {2,5} },
		}
	}

end
