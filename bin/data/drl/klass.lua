function drl.register_klasses()

	register_klass "marine"
	{
		name       = "Marine",
		char       = "M",
		core_trait = "trait_marine",

		traits    = {
			{ id = "ironman",    max = 3, max_12 = 5 },
			{ id = "finesse",    max = 2, max_12 = 3 },
			{ id = "hellrunner", max = 2, max_12 = 3 },
			{ id = "nails",      max = 2, max_12 = 3 },
			{ id = "bitch",      max = 3, max_12 = 5 },
			{ id = "gun",        max = 3, max_12 = 5 },
			{ id = "reloader",   max = 2, max_12 = 3 },
			{ id = "eagle",      max = 3, max_12 = 5 },
			{ id = "brute",      max = 3, max_12 = 5 },
			{ id = "badass",     max = 2 },

			{ id = "juggler",      requires = {{ "finesse",    1 }},         },
			{ id = "berserker",    requires = {{ "brute",      2 }},         },
			{ id = "dualgunner",   requires = {{ "gun",        2 }},         },
			{ id = "dodgemaster",  requires = {{ "hellrunner", 2 }},         },
			{ id = "intuition",    requires = {{ "eagle",      2 }}, max = 2 },
			{ id = "shottyman",    requires = {{ "reloader",   2 }},         },
			{ id = "triggerhappy", requires = {{ "bitch",      2 }}, max = 2 },
			{ id = "whizkid",      requires = {{ "finesse",    2 }}, max = 2 },

			{ id = "vampyre",      requires = {{ "berserker",    1 }, { "badass",       1 },               }, blocks = { "ironman",    "nails",     "hellrunner", }, reqlevel = 6, master = true },
			{ id = "bulletdance",  requires = {{ "dualgunner",   1 }, { "triggerhappy", 1 },               }, blocks = { "hellrunner", "intuition", "brute",      },               master = true },
			{ id = "armydead",     requires = {{ "shottyman",    1 }, { "badass",       1 },               }, blocks = { "gun",        "eagle",     "bitch",      }, reqlevel = 6, master = true },
			{ id = "ammochain",    requires = {{ "triggerhappy", 2 }, { "reloader",     2 },               }, blocks = { "nails",      "ironman",   "eagle",      },               master = true },
			{ id = "survivalist",  requires = {{ "nails",        2 },                                      }, blocks = { "berserker",  "bitch",                   }, reqlevel = 5, master = true },
		},

		desc = "Marines are the backbone of the UAC, resilient and hardy. They start with 10 more health points, +20% fire/acid/plasma resistance and powerups they use have a +50% duration bonus (+25% on Nightmare).",

		OnPick = function( being )
			if DIFFICULTY >= DIFF_NIGHTMARE then
				being:add_property( "POWER_BONUS", 25 )
			else
				being:add_property( "POWER_BONUS", 50 )
			end
			being.hpmax = being.hpmax + 10
			being.hp    = being.hp + 10

			being.eq.weapon = "pistol"
			being.inv:add( "ammo", { amount = 40 } )
			being.inv:add( "smed" )
			being.inv:add( "smed" )

			being.resist.fire   = 10
			being.resist.acid   = 10
			being.resist.plasma = 10
		end
	}

	register_klass "scout"
	{
		name      = "Scout",
		char      = "S",
		traits    = {
			{ id = "ironman",    max = 3, max_12 = 5 },
			{ id = "finesse",    max = 2, max_12 = 3 },
			{ id = "hellrunner", max = 2, max_12 = 3 },
			{ id = "nails",      max = 2, max_12 = 3 },
			{ id = "bitch",      max = 3, max_12 = 5 },
			{ id = "gun",        max = 3, max_12 = 5 },
			{ id = "reloader",   max = 2, max_12 = 3 },
			{ id = "eagle",      max = 3, max_12 = 5 },
			{ id = "brute",      max = 3, max_12 = 5 },
			{ id = "intuition",  max = 2, },

			{ id = "juggler",      requires = {{ "finesse",    1 }},         },
			{ id = "berserker",    requires = {{ "brute",      2 }},         },
			{ id = "dualgunner",   requires = {{ "gun",        2 }},         },
			{ id = "dodgemaster",  requires = {{ "hellrunner", 2 }},         },
			{ id = "badass",       requires = {{ "nails",      2 }}, max = 2 },
			{ id = "shottyman",    requires = {{ "reloader",   2 }},         },
			{ id = "triggerhappy", requires = {{ "bitch",      2 }}, max = 2 },
			{ id = "whizkid",      requires = {{ "finesse",    2 }}, max = 2 },

			{ id = "blademaster",  requires = {{ "berserker",    1 }, { "brute",       3}, { "hellrunner", 2 }, }, blocks = { "nails",    "bitch", "gun",        },               master = true },
			{ id = "gunkata",      requires = {{ "dualgunner",   1 }, { "dodgemaster", 1},                      }, blocks = { "nails",    "bitch", "brute",      },               master = true },
			{ id = "shottyhead",   requires = {{ "juggler",      1 }, { "shottyman",   1}, { "hellrunner", 1 }, }, blocks = { "nails",    "bitch", "eagle",      },               master = true },
			{ id = "cateye",       requires = {{ "triggerhappy", 1 }, { "intuition",   1},                      }, blocks = { "reloader", "brute", "nails",      }, reqlevel = 6, master = true },
			{ id = "gunrunner",    requires = {{ "hellrunner",   2 },                                           }, blocks = { "nails",   "brute",                }, reqlevel = 5, master = true },
		},

		desc = "Scouts are agile and have the best intel. They are generally 10% faster and inherently know the location of stairs on any given level.",

		OnPick = function( being )
			being.flags[ BF_STAIRSENSE ] = true
			being.speed = being.speed + 10

			being.eq.weapon = "pistol"
			being.inv:add( "ammo", { amount= 20 } )
			being.inv:add( "smed" )
			being.inv:add( "smed" )
		end
	}

	register_klass "technician"
	{
		name      = "Technician",
		char      = "T",
		traits    = {
			{ id = "ironman",    max = 3, max_12 = 5 },
			{ id = "finesse",    max = 2, max_12 = 3 },
			{ id = "hellrunner", max = 2, max_12 = 3 },
			{ id = "nails",      max = 2, max_12 = 3 },
			{ id = "bitch",      max = 3, max_12 = 5 },
			{ id = "gun",        max = 3, max_12 = 5 },
			{ id = "reloader",   max = 2, max_12 = 3 },
			{ id = "eagle",      max = 3, max_12 = 5 },
			{ id = "brute",      max = 3, max_12 = 5 },
			{ id = "whizkid",    max = 2, max_12 = 3 },

			{ id = "juggler",      requires = {{ "finesse",    1 }},         },
			{ id = "berserker",    requires = {{ "brute",      2 }},         },
			{ id = "dualgunner",   requires = {{ "gun",        2 }},         },
			{ id = "dodgemaster",  requires = {{ "hellrunner", 2 }},         },
			{ id = "intuition",    requires = {{ "eagle",      2 }}, max = 2 },
			{ id = "badass",       requires = {{ "nails",      2 }}, max = 2 },
			{ id = "shottyman",    requires = {{ "reloader",   2 }},         },
			{ id = "triggerhappy", requires = {{ "bitch",      2 }}, max = 2 },

			{ id = "malicious",    requires = {{ "dodgemaster",  1 }, { "brute",     2 }, { "finesse", 1 }, }, blocks = { "berserker",    "nails",     "eagle",      },               master = true },
			{ id = "sharpshooter", requires = {{ "gun",          3 }, { "eagle",     3 },                   }, blocks = { "dualgunner",   "nails",     "bitch",      },               master = true },
			{ id = "fireangel",    requires = {{ "dodgemaster",  1 }, { "shottyman", 1 },                   }, blocks = { "gun",          "bitch",     "eagle",      },               master = true },
			{ id = "entrenchment", requires = {{ "triggerhappy", 1 }, { "badass",    1 },                   }, blocks = { "finesse",      "reloader",  "gun",        },               master = true },
			{ id = "scavenger",    requires = {{ "whizkid",      2 },                                       }, blocks = { "triggerhappy", "berserker",               }, reqlevel = 5, master = true },
		},
		desc = "Technicians are masters of equipment and tinkering. They use consumables almost instantly and can hack computer maps for tracking data. Only they can also mod some really unique tech.",

		OnPick = function( being )
			being:add_property( "MAP_EXPERT" )
			being:add_property( "MOD_EXPERT" )
			being.usetime = 10 -- 1/10 of 100
			being.eq.weapon = "pistol"
			being.inv:add( "ammo", { amount = 20 } )
			being.inv:add( "smed" )
			being.inv:add( "smed" )
			being.inv:add( "mod_tech" )
		end
	}

	register_klass "soldat"
	{
		name      = "Soldier",
		char      = "S",
		hidden    = true,

		traits    = {
			{ id = "ironman",    max = 5 },
			{ id = "finesse",    max = 3 },
			{ id = "hellrunner", max = 3 },
			{ id = "nails",      max = 3 },
			{ id = "bitch",      max = 5 },
			{ id = "gun",        max = 5 },
			{ id = "reloader",   max = 3 },
			{ id = "eagle",      max = 5 },
			{ id = "brute",      max = 5 },

			{ id = "juggler",      requires = {{ "finesse",    1 }},         },
			{ id = "berserker",    requires = {{ "brute",      2 }},         },
			{ id = "dualgunner",   requires = {{ "gun",        2 }},         },
			{ id = "dodgemaster",  requires = {{ "hellrunner", 2 }},         },
			{ id = "intuition",    requires = {{ "eagle",      2 }}, max = 2 },
			{ id = "shottyman",    requires = {{ "reloader",   2 }},         },
			{ id = "triggerhappy", requires = {{ "bitch",      2 }}, max = 2 },
			{ id = "badass",       requires = {{ "nails",      2 }}, max = 2 },
		},

		desc = "Soldiers are unnamed and unknown. You don't choose to be a soldier, you just are...",

		OnPick = function( being )
			being.eq.weapon = "pistol"
			being.inv:add( "ammo", { amount = 40 } )
			being.inv:add( "smed" )
			being.inv:add( "smed" )
		end
	}

end
