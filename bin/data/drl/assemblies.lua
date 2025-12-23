function drl.register_assemblies()

-- Basic assemblies --

	register_mod_array "chainsword"
	{
		name  = "chainsword",
		mods  = { P = 1, B = 1 },
		request_id = "knife",

		OnApply = function (item)
			item.name         = "chainsword"
			item.damage_dice  = 8
			item.damage_sides = 2
			item.acc          = 2
		end,
	}

	register_mod_array "pblade"
	{
		name  = "piercing blade",
		mods  = { P = 1, A = 1 },
		request_type = ITEMTYPE_MELEE,

		OnApply = function (item)
			item.name         = "piercing "..item.name
			item.damagetype   = DAMAGE_IGNOREARMOR
			item.damage_dice  = item.__proto.damage_dice
			item.damage_sides = item.__proto.damage_sides + 1
			item.acc          = item.__proto.acc
		end,
	}

	register_mod_array "speedloader"
	{
		name  = "speedloader pistol",
		mods  = { A = 1, T = 1 },
		request_id = "pistol",

		OnApply = function (item)
			item.name       = "speedloader pistol"
			item.reloadtime = 4
			item.usetime    = item.__proto.usetime
			item.acc        = item.__proto.acc
		end,
	}

	register_mod_array "elephant"
	{
		name  = "elephant gun",
		mods  = { P = 2 },
		request_id = "shotgun",

		OnApply = function (item)
			item.name         = "elephant gun"
			item.reloadtime   = 25
			item.damage_dice  = 12
			item.damage_sides = 3
		end,
	}

	register_mod_array "gatling"
	{
		name  = "gatling gun",
		mods  = { B = 2 },
		request_id = "chaingun",

		OnApply = function (item)
			item.name         = "gatling gun"
			item.shots        = 6
			item.reloadtime   = 30
			item.damage_sides = item.damage_sides + 1
			item.ammomax      = 60
		end,
	}

	register_mod_array "micro"
	{
		name  = "micro launcher",
		mods  = { T = 2 },
		request_id = "bazooka",

		OnApply = function (item)
			item.name         = "micro launcher"
			item.reloadtime   = 8
			item.usetime      = 5
			item.damage_dice  = 5
			item.damage_sides = 5
			item.acc          = 7
			item.radius       = 3
		end,
	}

	register_mod_array "tarmor"
	{
		name  = "tactical armor",
		mods  = { A = 2 },
		request_id = "garmor",

		OnApply = function (item)
			item.name         = "tactical armor"
			item.movemod      = 15
			item.dodgemod     = 10
			item.armor        = 0
			item.resist.shrapnel = 0
			item.resist.bullet   = 0

			item:add_perk( "perk_armor_recharge" )
			item.pp_recharge.amount = 2
			item.pp_recharge.delay  = 10
		end,

		Match = function (item)
			return not item:has_property("pp_recharge")
		end,
	}

	register_mod_array "tboots"
	{
		name  = "tactical boots",
		mods  = { A = 2 },
		request_id = "sboots",

		OnApply = function (item)
			item.name      = "tactical boots"
			item.movemod   = 15
			item.dodgemod  = 0
			item.knockmod  = 0
			item.armor     = 0

			item:add_perk( "perk_armor_recharge" )
			item.pp_recharge.amount = 2
			item.pp_recharge.delay  = 10
		end,

		Match = function (item)
			return not item:has_property("pp_recharge")
		end,
	}

	register_mod_array "nanofiber"
	{
		name  = "nanofiber armor",
		mods  = { P = 1, B = 1 },
		request_type = ITEMTYPE_ARMOR,

		OnApply = function (item)
			item.name    = "nanofiber "..item.name
			item.movemod = item.__proto.movemod
			item.armor   = math.ceil(item.__proto.armor / 2)
			item.resist.bullet = math.ceil((item.__proto.resist.bullet or 0) / 2)
			item.resist.shrapnel = math.ceil((item.__proto.resist.shrapnel or 0) / 2)
			item.resist.melee = math.ceil((item.__proto.resist.melee or 0) / 2)
			item.resist.fire = math.ceil((item.__proto.resist.fire or 0) / 2)
			item.resist.acid = math.ceil((item.__proto.resist.acid or 0) / 2)
			item.resist.plasma = math.ceil((item.__proto.resist.plasma or 0) / 2)
			item.flags[ IF_NODURABILITY ] = true
		end,
	}

	register_mod_array "high"
	{
		name  = "high power weapon",
		mods  = { P = 1, B = 1 },
		request_desc  = "ranged, non-shotgun, magazine > 5",
		request_type = ITEMTYPE_RANGED,

		Match = function (item)
			return item.ammomax > 5 and item.group ~= "shotgun"
		end,

		OnApply = function (item)
			item.name             = "high power "..item.name
			item.ammomax          = item.__proto.ammomax * 0.65
			item.ammo             = math.min( item.ammo, item.ammomax )
			if item.__proto.damage_sides >= item.__proto.damage_dice then
				item.damage_sides = item.__proto.damage_sides + 2
			else
				item.damage_dice  = item.__proto.damage_dice + 2
			end
		end,
	}

	register_mod_array "power"
	{
		name  = "power armor",
		mods  = { P = 1, N = 1 },
		request_desc = "any common armor",

		Match = function (item)
			return not item:has_property("pp_recharge") and item.itype == ITEMTYPE_ARMOR and item.flags[IF_EXOTIC] == false and item.flags[IF_UNIQUE] == false
		end,

		OnApply = function (item)
			item.name             = "powered "..item.name
			item.armor            = item.__proto.armor + 1
			item.movemod          = item.__proto.movemod + 20
			item.knockmod         = -25
			if (item.resist.bullet or 0) > 0 then
				item.resist.bullet   = math.min( (item.resist.bullet or 0) * 5, 95 )
			end
			if (item.resist.shrapnel or 0) > 0 then
				item.resist.shrapnel = math.min( (item.resist.shrapnel or 0) * 5, 95 )
			end
			if (item.resist.fire or 0) > 0 then
				item.resist.fire     = math.min( (item.resist.fire or 0) * 2, 95 )
			end
			if (item.resist.acid or 0) > 0 then
				item.resist.acid     = math.min( (item.resist.acid or 0) * 2, 95 )
			end
			if (item.resist.plasma or 0) > 0 then
				item.resist.plasma   = math.min( (item.resist.plasma or 0) * 3, 95 )
			end
			item.resist.melee        = 25

			item:add_perk( "perk_armor_recharge" )
			item.pp_recharge.amount = 5
			item.pp_recharge.delay  = 10
		end,
	}

	register_mod_array "tshotgun"
	{
		name  = "tactical shotgun",
		mods  = { P = 1, T = 1 },
		request_id = "ashotgun",

		OnApply = function (item)
			item.name         = "tactical shotgun"
			item.reloadtime   = 10
			item.damage_dice  = 8
			item.damage_sides = 3
			item.usetime      = 10
			item.ammomax      = 5
			if item:is_perk("perk_pump_action") then
				item:remove_perk("perk_pump_action")
			end
		end,
	}

	register_mod_array "plate"
	{
		name  = "tower shield",
		mods  = { P = 1, O = 1 },
		request_id = "rarmor",

		OnApply = function (item)
			item.name           = "tower shield"
			item.armor          = 12
			item.durability     = 200
			item.maxdurability  = 200
			item.movemod        = -30
			item.knockmod       = -90
			item.resist.fire       = 0
			item.flags[ IF_NOREPAIR ] = true
			item.flags[ IF_NONMODABLE ] = true
			item.flags[ IF_NODEGRADE ] = true
			item.flags[ IF_NODURABILITY ] = false
		end,
	}

	register_mod_array "fparmor"
	{
		name  = "fireproof armor",
		mods  = { B = 1, T = 1 },
		request_type = ITEMTYPE_ARMOR,

		OnApply = function (item)
			item.name          = "fireproof "..item.name
			item.durability    = 100
			item.maxdurability = 100
			item.movemod       = item.__proto.movemod
			item.knockmod      = item.__proto.knockmod
			item:reset_resistances()
			item.resist.melee     = (item.resist.melee or 0) - 30
			item.resist.fire      =  math.min( (item.resist.fire or 0) + 30, 95 )
		end,
	}

	register_mod_array "fpboots"
	{
		name  = "fireproof boots",
		mods  = { B = 1, T = 1 },
		request_type = ITEMTYPE_BOOTS,

		OnApply = function (item)
			item.name          = "fireproof "..item.name
			item.durability    = 100
			item.maxdurability = 100
			item.knockmod      = item.__proto.knockmod
			item:reset_resistances()
			item.resist.fire      =  math.min( (item.resist.fire or 0) + 30, 95 )
		end,
	}

	register_mod_array "balarmor"
	{
		name  = "ballistic armor",
		mods  = { A = 1, T = 1 },
		request_type = ITEMTYPE_ARMOR,

		OnApply = function (item)
			item.name          = "ballistic "..item.name
			item.movemod       = item.__proto.movemod
			item.knockmod      = item.__proto.knockmod
			item:reset_resistances()
			item.resist.melee     = math.min( (item.resist.melee or 0) + 40, 95 )
			item.resist.bullet    = math.min( (item.resist.bullet or 0) + 40, 95 )
			item.resist.shrapnel  = math.min( (item.resist.shrapnel or 0) + 40, 95 )
			item.resist.fire      = (item.resist.fire or 0) - 20
			item.resist.plasma    = 0
			item.resist.acid      = 0
		end,
	}

	register_mod_array "plasmatic"
	{
		name  = "plasmatic shrapnel",
		mods  = {  P = 1, S = 1 },
		request_desc  = "any shotgun",

		Match = function (item)
			return item.group == "shotgun"
		end,

		OnApply = function (item)
			item.name        = "plasmatic "..item.name
			item.damagetype  = DAMAGE_PLASMA
			item.damage_dice = item.__proto.damage_dice
		end,
	}

	register_mod_array "gboots"
	{
		name  = "grappling boots",
		mods  = { T = 2 },
		request_type = ITEMTYPE_BOOTS,

		OnApply = function (item)
			item.name      = "grappling "..item.name
			item.movemod   = item.__proto.movemod
			item.armor     = item.armor + 1
			item.knockmod  = math.max( -90, item.__proto.knockmod - 50 )
		end,
	}

	register_mod_array "grarmor"
	{
		name  = "grappling armor",
		mods  = { B = 1, A = 1 },
		request_type = ITEMTYPE_ARMOR,

		OnApply = function (item)
			item.name          = "grappling "..item.name
			item.movemod       = item.__proto.movemod
			item.durability    = 100
			item.maxdurability = 100
			item.knockmod      = math.max( -90, item.__proto.knockmod - 50 )
			item:reset_resistances()
			item.resist.melee     = (item.resist.melee or 0) + 30
		end,
	}

	register_mod_array "lavboots"
	{
		name  = "lava boots",
		mods  = { T = 1, O = 1 },
		request_type = ITEMTYPE_BOOTS,

		OnApply = function (item)
			item.name          = "lava "..item.name
			item.movemod       = -20
			item.knockmod      = -30
			item:reset_resistances()
			item.resist.fire      = 100
			item.flags[ IF_NODURABILITY ] = true
		end,
	}

-- Advanced assemblies

	register_mod_array "double"
	{
		name  = "double chainsaw",
		mods  = { P = 2, B = 1 },
		level = 1,
		request_id = "chainsaw",

		OnApply = function (item)
			item.name         = "double chainsaw"
			item.damage_dice  = 4
			item.damage_sides = 12
			item.acc          = -1
		end,
	}

	register_mod_array "tacticalrl"
	{
		name  = "tactical rocket launcher",
		mods  = { B = 3 },
		level = 1,
		request_id = "bazooka",

		OnApply = function (item)
			item.name        = "tactical rocket launcher"
			item.ammomax     = 5
			item.radius      = 2
			item.flags[ IF_AUTOHIT ] = true
		end,
	}

	register_mod_array "storm"
	{
		name  = "storm bolter pistol",
		mods  = { B = 2, T = 1 },
		level = 1,
		request_desc = "any pistol",

		Match = function (item)
			return (item.itype == ITEMTYPE_RANGED) and (item.group == "pistol")
		end,

		OnApply = function (item)
			item.name           = "storm "..item.name
			item.acc            = item.__proto.acc - 2
			item.usetime        = item.__proto.usetime * 0.85
			item.damage_dice    = 1
			item.damage_sides   = item.__proto.damage_dice * item.__proto.damage_sides
			item.shots          = 2
			item.ammomax        = math.floor(item.__proto.ammomax * 1.5)
			item.ammo           = math.min(item.ammo, item.ammomax)
			item.reloadtime     = item.__proto.reloadtime
		end,
	}

	register_mod_array "rifle"
	{
		name  = "assault rifle",
		mods  = { A = 3 },
		level = 1,
		request_desc = "any rapid-fire",

		Match = function (item)
			return (item.itype == ITEMTYPE_RANGED) and (item.group == "chain" or item.group == "plasma") and item.flags[IF_UNIQUE] == false
		end,

		OnApply = function (item)
			item.name         = "assault "..item.name
			item.acc          = item.__proto.acc + 3
			item.shots        = math.ceil(item.__proto.shots / 2)
			item.shotcost     = math.max(item.__proto.shotcost,1) * 2
			item.reloadtime   = item.__proto.reloadtime / 2
			item.damage_dice  = item.__proto.damage_dice + 1
			item.damage_sides = item.__proto.damage_sides - 1
		end,
	}

	register_mod_array "energy"
	{
		name  = "energy pistol",
		mods  = { P = 2, T = 1 },
		level = 1,
		request_desc = "any pistol",

		Match = function (item)
			return (item.itype == ITEMTYPE_RANGED) and (item.group == "pistol")
		end,

		OnApply = function (item)
			item.name         = "energy "..item.name
			item.miscolor     = MULTIYELLOW
			item:set_sprite( "hit", { sprite = SPRITE_BLAST } )
			item.damagetype   = DAMAGE_PLASMA
			item.damage_sides = item.__proto.damage_sides + 1
			item.ammoid       = items["cell"].nid
		end,
	}


	register_mod_array "assault"
	{
		name  = "burst cannon",
		mods  = { P = 1, B = 2 },
		level = 1,
		request_desc = "any rapid-fire",

		Match = function(item)
			return (item.itype == ITEMTYPE_RANGED) and (item.group == "chain" or item.group == "plasma") and item.flags[IF_UNIQUE] == false
		end,

		OnApply = function (item)
			item.name           = "burst "..item.name
			item.acc            = item.__proto.acc - 2
			item.damage_dice    = 1
			item.damage_sides   = item.__proto.damage_sides + 2
			item.shots          = item.__proto.shots + 2
			item.ammomax        = item.__proto.ammomax * 2
			item.reloadtime     = item.__proto.reloadtime * 1.5
		end,
	}

	register_mod_array "vbfg9000"
	{
		name  = "VBFG9000",
		mods  = {P = 3},
		level = 1,
		request_desc = "any BFG9000",

		Match = function(item)
			return (item.itype == ITEMTYPE_RANGED) and (item.group == "bfg") and item.flags[IF_UNIQUE] == false
		end,

		OnApply = function (item)
			if item.name == "nuclear BFG 9000" then
				item.name     = "nuclear VBFG9000"
			else
				item.name     = "VBFG9000"
			end
			item.damage_dice  = item.__proto.damage_dice
			item.damage_sides = item.__proto.damage_sides + 2
			item.misdelay     = 200
			item.shotcost     = item.__proto.shotcost * 1.5
			item.ammomax      = item.__proto.ammomax * 1.5
			item.radius       = 12
		end,
	}

	register_mod_array "envboots"
	{
		name  = "environmental boots",
		level = 1,
		mods  = { B = 2, T = 1 },
		request_type = ITEMTYPE_BOOTS,

		OnApply = function (item)
			item.name          = "environmental "..item.name
			item.movemod       = item.__proto.movemod - 15
			item.knockmod      = item.__proto.knockmod
			item.armor         = item.__proto.armor
			item.maxdurability = item.__proto.durability
			item.durability    = math.min( item.durability, item.maxdurability )
			local presist = item.__proto.resist or {}
			item:reset_resistances()
			item.resist.fire      = math.min( (presist.fire or 0) + 95,   95 )
			item.resist.acid      = math.min( (presist.acid or 0) + 95,   95 )
			item.resist.plasma    = math.min( (presist.plasma or 0) + 20, 95 )
		end,
	}

	register_mod_array "fireshield"
	{
		name  = "fire shield",
		mods  = { B = 1, T = 1, O = 1 },
		level = 1,
		request_id = "rarmor",

		OnApply = function (item)
			item.name          = "fire shield"
			item.movemod       = -20
			item.knockmod      = 0
			item.resist.fire      = 95
			item.maxdurability = 200
			item.durability    = item.maxdurability
			item.flags[ IF_NOREPAIR ] = true
			item.flags[ IF_NONMODABLE ] = true
			item.flags[ IF_NODEGRADE ] = true
			item.flags[ IF_NODURABILITY ] = false
		end,
	}

	register_mod_array "nanoskin"
	{
		name  = "nanofiber skin armor",
		mods  = { P = 2, N = 1 },
		level = 1,
		request_type = ITEMTYPE_ARMOR,

		OnApply = function (item)
			item.name         = "nanoskin "..item.name
			item.armor        = item.__proto.armor
			item.resist.bullet   = math.min( (item.__proto.resist.bullet or 0) + 25, 95 )
			item.resist.shrapnel = math.min( (item.__proto.resist.shrapnel or 0) + 25, 95 )
			item.resist.melee = math.min( (item.__proto.resist.melee or 0) + 25, 95 )
			item.resist.fire = math.min( (item.__proto.resist.fire or 0) + 25, 95 )
			item.resist.acid = math.min( (item.__proto.resist.acid or 0) + 25, 95 )
			item.resist.plasma = math.min( (item.__proto.resist.plasma or 0) + 25, 95 )
			item:add_perk( "perk_armor_recharge" )
			item.pp_recharge.amount = 1
			item.pp_recharge.delay  = 5
			item.flags[ IF_NODESTROY ] = true
			item.flags[ IF_CURSED ]    = true
		end,

		Match = function (item)
			return not item:has_property("pp_recharge")
		end,
	}

	register_mod_array "gravity"
	{
		name  = "antigrav boots",
		mods  = { A = 2, N = 1 },
		level = 1,
		request_type = ITEMTYPE_BOOTS,

		OnApply = function (item)
			item.name    = "antigrav "..item.name
			item.movemod = math.min( item.__proto.movemod + 50, 50 )
			item.flags[ IF_NODESTROY ] = true
		end,
	}

	register_mod_array "hyperblaster"
	{
		name  = "hyperblaster",
		mods  = {A = 1, T = 2},
		level = 1,
		request_id = "plasma",

		OnApply = function (item)
			item.name         = "hyperblaster"
			item.acc          = 4
			item.shots        = 3
			item.damage_dice  = 2
			item.damage_sides = 4
			item.reloadtime   = 25
			item.usetime      = 5
		end,
	}

	register_mod_array "fdshotgun"
	{
		name  = "focused double shotgun",
		mods  = {A = 1, T = 1, P = 1},
		level = 1,
		request_id = "dshotgun",

		OnApply = function (item)
			item.name         = "focused double shotgun"
			item.range        = 15
			item.spread       = 3
			item.falloff      = 7
			item.damage_dice  = 8
			item.damage_sides = 4
			item.reloadtime   = 15
			item.usetime      = 10
		end,
	}

-- Master assemblies

	register_mod_array "nanomanufacture"
	{
		name  = "nanomanufacture ammo",
		mods  = {N = 1, B = 3},
		level = 2,
		request_desc  = "non-sg/non-bfg ranged weapon",

		Match = function (item)
			return item.group ~= "shotgun" and (item.itype == ITEMTYPE_RANGED) and (item.radius < 5)
		end,

		OnApply = function (item)
			item.name  = "nanomachic "..item.name
			item.ammomax = item.__proto.ammomax * 2
			item.ammo = math.min( item.ammo, item.ammomax )
			item.flags[ IF_NOAMMO ]   = true
			item.flags[ IF_NOUNLOAD ] = true
			item.flags[ IF_NORELOAD ] = false
			item:remove_perks_by_tag( "recharge" )
		end,
	}

	register_mod_array "nsharpnel"
	{
		name  = "nano-shrapnel",
		mods  = { P = 3, N = 1 },
		level = 2,
		request_desc  = "any shotgun",

		Match = function (item)
			return item.group == "shotgun"
		end,

		OnApply = function (item)
			item.name         = "nano "..item.name
			item.damage_dice = item.__proto.damage_dice - 3
			item.damagetype   = DAMAGE_IGNOREARMOR
			item.flags[ IF_NOAMMO ] = true
			if item:is_perk("perk_pump_action") then
				item:remove_perk("perk_pump_action")
			end
		end,
	}

	register_mod_array "demolition"
	{
		name  = "demolition ammo",
		mods  = { P = 1, T = 2, F = 1 },
		level = 2,
		request_desc  = "10mm weapon",

		Match = function (item)
			return item.itype == ITEMTYPE_RANGED and items[ item.ammoid ].id == "ammo"
		end,

		OnApply = function (item)
			item.name            = "demolition "..item.name
			item.damage_dice     = math.ceil( item.__proto.damage_dice * item.__proto.damage_sides / 2 )
			item.damage_sides    = 2
			item.usetime         = item.__proto.usetime
			item.radius          = 1
			item.shots           = item.__proto.shots
			item:set_explosion{
				delay = 40,
				color = RED,
			}
			item.damagetype      = DAMAGE_FIRE
		end,
	}

	register_mod_array "cybernano"
	{
		name  = "cybernano armor",
		mods  = {N = 1, P = 2, O = 1},
		level = 2,
		request_type = ITEMTYPE_ARMOR,

		OnApply = function (item)
			item.name       = "cybernano "..item.name
			item.durability = 100
			item.armor      = item.__proto.armor + 4
			item.flags[ IF_NODURABILITY ] = true
			item.flags[ IF_NODESTROY ]    = true
			item.flags[ IF_CURSED ]       = true
		end,
	}

	register_mod_array "biggest"
	{
		name  = "biggest fucking gun",
		mods  = { B = 2, F = 2 },
		level = 2,
		request_desc = "any BFG9000",

		Match = function(item)
			return (item.itype == ITEMTYPE_RANGED) and (item.group == "bfg") and item.flags[IF_UNIQUE] == false
		end,

		OnApply = function (item)
			if item.name == "nuclear BFG 9000" then
				item.name     = "biggest fucking nuclear gun"
			else
				item.name     = "biggest fucking gun"
			end
			item.damage_dice  = item.__proto.damage_dice * 2
			item.damage_sides = item.__proto.damage_sides * 2
			item.misdelay     = 200
			item.shotcost     = item.__proto.shotcost * 2.5
			item.ammomax      = item.__proto.ammomax * 2.5
			item.radius       = 16
		end,
	}

	register_mod_array "ripper"
	{
		name  = "ripper",
		mods  = {P = 2, B = 1, T = 1},
		level = 2,
		request_id = "chainsaw",

		OnApply = function (item)
			item.name         = "ripper"
			item.damage_dice  = 6
			item.damage_sides = 6
			item.usetime      = 5
			item.acc          = -4
		end,
	}

	register_mod_array "cerboots"
	{
		name  = "cerberus boots",
		mods  = { P = 2, T = 1, A = 1 },
		level = 2,
		request_type = ITEMTYPE_BOOTS,

		OnApply = function (item)
			item.name     = "cerberus "..item.name
			item.armor    = 0
			item.movemod  = -20
			item.knockmod = -30
			item:reset_resistances()
			item.resist.fire   = 100
			item.resist.acid   = 100
			item.resist.plasma = math.max( (item.resist.plasma or 0), 50 )
		end,
	}

	register_mod_array "cerarmor"
	{
		name  = "cerberus armor",
		mods  = { P = 2, T = 1, A = 1 },
		level = 2,
		request_type = ITEMTYPE_ARMOR,

		OnApply = function (item)
			item.name       = "cerberus "..item.name
			item.armor      = 0
			item.movemod    = -30
			item.knockmod   = -30
			item:reset_resistances()
			item.resist.fire   = math.max( (item.resist.fire or 0),   70 )
			item.resist.acid   = math.max( (item.resist.acid or 0),   70 )
			item.resist.plasma = math.max( (item.resist.plasma or 0), 50 )
		end,
	}

	register_mod_array "mother"
	{
		name  = "Mother-In-Law",
		mods  = { P = 2, F = 1, N = 1 },
		level = 2,
		request_id = "bazooka",

		OnApply = function (item)
			-- Original mother-in-law is rocket launcher + F1N1P3
			item.name         = "Mother-In-Law"
			--item.desc         = "Simon-v's legendary rocket launcher."
			item.damage_dice  = 6
			item.damage_sides = 9
			item.radius       = 6
			-- This is the behaviour of the N-mod on 0.9.9.1.
			-- shark said that you can get this with N2, but here we are basically allowing a *6*-mod weapon build up
			item:add_perk( "perk_weapon_recharge" )
			item.pp_recharge.delay  = 0
			item.pp_recharge.amount = 1
		end,

		Match = function (item)
			return not item:has_property("pp_recharge")
		end,
	}

end
