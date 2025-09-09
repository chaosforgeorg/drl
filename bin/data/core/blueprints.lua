core.register_blueprint "requirement"
{
	id             = { true,  core.TSTRING },
	progress       = { false, core.TFUNC },
	description    = { false, core.TFUNC },
}

core.register_blueprint "rank_req"
{
	req    = { true, core.TIDIN("requirements") },
	amount = { false, core.TNUMBER, 1 }, 
	param  = { false, core.TANY },
	param2 = { false, core.TANY },
}

core.register_blueprint "rank"
{
	name           = { true,  core.TSTRING },
	type           = { true,  core.TSTRING },
	reqs           = { true,  core.TARRAY("rank_req") },
	unlocks        = { false, core.TARRAY(core.TSTRING), {} },
	achievement    = { false, core.TSTRING, "" },
}

core.register_blueprint "difficulty"
{
	id            = { true,  core.TSTRING },
	name          = { true,  core.TSTRING },
	desc          = { false, core.TSTRING, "" },
	desc_unlock   = { false, core.TSTRING, "" },
	description   = { true,  core.TSTRING },
	code          = { true,  core.TSTRING },
	accuracybonus = { false, core.TNUMBER, 0 },
	expfactor     = { false, core.TNUMBER, 1 },
	scorefactor   = { false, core.TNUMBER, 1 },
	ammofactor    = { false, core.TNUMBER, 1 },
	powerfactor   = { false, core.TNUMBER, 1 },
	respawn       = { false, core.TBOOL,   false },
	challenge     = { false, core.TBOOL,   true },
	req_skill     = { false, core.TNUMBER, 0 },
	req_exp       = { false, core.TNUMBER, 0 },
	speed         = { false, core.TNUMBER, 1 },
}

core.register_blueprint "trait"
{
	id              = { true,  core.TSTRING },
	name            = { true,  core.TSTRING },
	desc            = { false, core.TSTRING, "" },
	quote           = { false, core.TSTRING, "" },
	author          = { false, core.TSTRING },
	master          = { false, core.TBOOL,   false },
	abbr            = { true,  core.TSTRING },

	OnPick          = { false, core.TFUNC },
	OnAttacked      = { false, core.TFUNC },
	OnPreAction     = { false, core.TFUNC },
	OnPostAction    = { false, core.TFUNC },
	OnDie           = { false, core.TFUNC },
	OnDieCheck      = { false, core.TFUNC },
	OnUseActive     = { false, core.TFUNC },
	OnPickupItem    = { false, core.TFUNC },
	OnPostMove      = { false, core.TFUNC },
	OnKill          = { false, core.TFUNC },
	OnFired         = { false, core.TFUNC },
	OnDamage        = { false, core.TFUNC },
	OnTick          = { false, core.TFUNC },
	OnReceiveDamage = { false, core.TFUNC },
	OnEnterLevel    = { false, core.TFUNC },
	OnCanDualWield  = { false, core.TFUNC },
	OnCanMaxDamage  = { false, core.TFUNC },

	getDamageBonus   = { false, core.TFUNC },
	getToHitBonus    = { false, core.TFUNC },
	getShotsBonus    = { false, core.TFUNC },
	getFireCostBonus = { false, core.TFUNC },
	getDefenceBonus  = { false, core.TFUNC },
	getDodgeBonus    = { false, core.TFUNC },
	getMoveBonus     = { false, core.TFUNC },
	getBodyBonus     = { false, core.TFUNC },
	getResistBonus   = { false, core.TFUNC },
	getDamageMul     = { false, core.TFUNC },
	getFireCostMul   = { false, core.TFUNC },
	getAmmoCostMul   = { false, core.TFUNC },
	getReloadCostMul = { false, core.TFUNC },
}

core.register_blueprint "klass_trait"
{
	id         = { true,  core.TIDIN("traits") },
	max        = { false, core.TNUMBER, 1 },
	max_12     = { false, core.TNUMBER },
	reqlevel   = { false, core.TNUMBER, 0 },
	master     = { false, core.TBOOL,   false },
	requires   = { false, core.TARRAY( core.TTABLE ) },
	blocks     = { false, core.TARRAY( core.TIDIN("traits") ) }
}


core.register_blueprint "klass"
{
	id          = { true,  core.TSTRING },
	name        = { true,  core.TSTRING },
	sname       = { false, core.TSTRING },
	char        = { true,  core.TSTRING },
	desc        = { true,  core.TSTRING },
	hidden      = { false, core.TBOOL, false },
	traits      = { true,  core.TARRAY("klass_trait") },
	core_trait  = { false, core.TIDIN("traits") },

	OnPick      = { false,  core.TFUNC },
	OnUseActive = { false,  core.TFUNC },
}

core.register_blueprint "medal"
{
	id        = { true,  core.TSTRING },
	name      = { true,  core.TSTRING },
	desc      = { true,  core.TSTRING },
	score     = { false, core.TNUMBER, 0 },
	winonly   = { false, core.TBOOL,   false },
	hidden    = { false, core.TBOOL,   false },
	removes   = { false, core.TARRAY( core.TIDIN("medals") ) },
	condition = { false, core.TFUNC },
}

core.register_blueprint "badge"
{
	id          = { true,  core.TSTRING },
	name        = { true,  core.TSTRING },
	desc        = { true,  core.TSTRING },
	level       = { true,  core.TNUMBER },
	set         = { false, core.TSTRING, "" },
	klass       = { false, core.TSTRING, "" },
	achievement = { false, core.TSTRING, "" },
	condition   = { false, core.TFUNC },
}

core.register_blueprint "award_level"
{
	name      = { true, core.TSTRING },
	desc      = { true, core.TSTRING },
}

core.register_blueprint "award"
{
	id        = { true,  core.TSTRING },
	name      = { true,  core.TSTRING },
	module    = { true,  core.TSTRING },
	mname     = { true,  core.TSTRING },
	levels    = { true,  core.TARRAY("award_level") },
}

core.register_blueprint "affect"
{
	id             = { true,  core.TSTRING },
	name           = { true,  core.TSTRING },
	color          = { true,  core.TNUMBER },
	color_expire   = { true,  core.TNUMBER },
	message_init   = { false, core.TSTRING },
	message_ending = { false, core.TSTRING },
	message_done   = { false, core.TSTRING },
	status_effect  = { false, core.TNUMBER },
	status_strength= { false, core.TNUMBER },

	OnAdd          = { false, core.TFUNC },
	OnUpdate       = { false, core.TFUNC },
	OnRemove       = { false, core.TFUNC },

	getDamageBonus   = { false, core.TFUNC },
	getToHitBonus    = { false, core.TFUNC },
	getShotsBonus    = { false, core.TFUNC },
	getFireCostBonus = { false, core.TFUNC },
	getDefenceBonus  = { false, core.TFUNC },
	getDodgeBonus    = { false, core.TFUNC },
	getMoveBonus     = { false, core.TFUNC },
	getBodyBonus     = { false, core.TFUNC },
	getResistBonus   = { false, core.TFUNC },
	getDamageMul     = { false, core.TFUNC },
	getFireCostMul   = { false, core.TFUNC },
	getAmmoCostMul   = { false, core.TFUNC },
	getReloadCostMul = { false, core.TFUNC },
}

core.register_blueprint "missile"
{
	id          = { true,  core.TSTRING },
	sound_id    = { false, core.TSTRING },
	ascii       = { false, core.TSTRING, "-" },
	color       = { true,  core.TNUMBER },
	delay       = { true,  core.TNUMBER },
	miss_base   = { true,  core.TNUMBER },
	miss_dist   = { true,  core.TNUMBER },
	hitdesc     = { false, core.TSTRING, "" },
	flags       = { false, core.TFLAGS,  {} },
	explosion   = { false, core.TTABLE },
	ray_delay   = { false, core.TNUMBER, 0 },
}

core.register_blueprint "ai"
{
	id          = { true,  core.TSTRING },
	states      = { true,  core.TMAP( core.TSTRING, core.TFUNC ) },

	OnCreate    = { true,  core.TFUNC },
	OnAttacked  = { true,  core.TFUNC },
	OnAction    = { false, core.TFUNC },
}

core.register_blueprint "being"
{
	name        = { true,  core.TSTRING },
	name_plural = { false, core.TSTRING },
	id          = { false, core.TSTRING },
	sound_id    = { false, core.TIDIN("beings") },
	ascii       = { true,  core.TSTRING },
	color       = { true,  core.TNUMBER },
	sprite      = { true,  core.TANY  },
	coscolor    = { false, core.TTABLE },
	glow        = { false, core.TTABLE },
	overlay     = { false, core.TTABLE },
	sflags      = { false, core.TFLAGS, {} },
	sframes     = { false, core.TNUMBER, 0 },
	sftime      = { false, core.TNUMBER, FRAME_TIME },
	hp          = { false, core.TNUMBER , 10 },
	armor       = { false, core.TNUMBER , 0 },
	attackchance= { false, core.TNUMBER , 75 },
	accuracy    = { false, core.TNUMBER , 0 },
	strength    = { false, core.TNUMBER , 0 },
	movetime    = { false, core.TNUMBER , 100 },
	firetime    = { false, core.TNUMBER , 100 },
	reloadtime  = { false, core.TNUMBER , 100 },
	speed       = { false, core.TNUMBER , 100 },
	vision      = { false, core.TNUMBER , 0 },
	min_lev     = { false, core.TNUMBER , 0 },
	max_lev     = { false, core.TNUMBER , 10000 },
	corpse      = { true,  core.TANY },
	danger      = { true,  core.TNUMBER },
	weight      = { true,  core.TNUMBER },
	xp          = { false, core.TNUMBER },
	tags        = { false, core.TTABLE, {} },
	flags       = { false, core.TFLAGS, {} },
	ai_type     = { true,  core.TSTRING }, -- TIDIN("ais")
	is_group    = false,
	resist      = { false, core.TTABLE },

	desc            = { true,  core.TSTRING },
	kill_desc       = { false, core.TSTRING },
	kill_desc_melee = { false, core.TSTRING },

	weapon = { false, core.TANY },

	OnCreate        = { false, core.TFUNC },
	OnPreAction     = { false, core.TFUNC },
	OnAction        = { false, core.TFUNC },
	OnPostAction    = { false, core.TFUNC },
	OnAttacked      = { false, core.TFUNC },
	OnKill          = { false, core.TFUNC },
	OnDie           = { false, core.TFUNC },
	OnDieCheck      = { false, core.TFUNC },
	OnPickupItem    = { false, core.TFUNC },
	OnUseActive     = { false, core.TFUNC },
	OnPostMove      = { false, core.TFUNC },
	OnDamage        = { false, core.TFUNC },
	OnTick          = { false, core.TFUNC },
	OnReceiveDamage = { false, core.TFUNC },
	OnEnterLevel    = { false, core.TFUNC },

	getDamageBonus   = { false, core.TFUNC },
	getToHitBonus    = { false, core.TFUNC },
	getShotsBonus    = { false, core.TFUNC },
	getFireCostBonus = { false, core.TFUNC },
	getDefenceBonus  = { false, core.TFUNC },
	getDodgeBonus    = { false, core.TFUNC },
	getMoveBonus     = { false, core.TFUNC },
	getBodyBonus     = { false, core.TFUNC },
	getResistBonus   = { false, core.TFUNC },
	getDamageMul     = { false, core.TFUNC },
	getFireCostMul   = { false, core.TFUNC },
	getAmmoCostMul   = { false, core.TFUNC },
	getReloadCostMul = { false, core.TFUNC },
}

core.register_blueprint "being_group_entry"
{
	being  = { true,  core.TIDIN("beings") },
	amount = { false, core.TANY },
}

core.register_blueprint "being_group"
{
	min_lev  = { false, core.TNUMBER, 0 },
	max_lev  = { false, core.TNUMBER, 10000 },
	weight   = { true,  core.TNUMBER },
	beings   = { true,  core.TARRAY("being_group_entry") },
	tags     = { false, core.TTABLE, {} },
	is_group = true,
}

core.register_blueprint "cell"
{
	name       = { true,  core.TSTRING },
	blname     = { false, core.TSTRING, "" },
	id         = { false, core.TSTRING },
	ascii      = { true,  core.TSTRING },
	asciilow   = { false, core.TSTRING },
	sprite     = { true,  core.TANY },
	sprites    = { false, core.TANY },
	deco       = { false, core.TANY },
	blsprite   = { false, core.TNUMBER },
	sflags     = { false, core.TFLAGS },
	sframes    = { false, core.TNUMBER, 0 },
	sftime     = { false, core.TNUMBER, FRAME_TIME },
	color      = { false, core.TANY, LIGHTGRAY },
	coscolor   = { false, core.TTABLE },
	color_dark = { false, core.TNUMBER, DARKGRAY },
	color_id   = { false, core.TIDIN("cells") },
	blcolor    = { false, core.TNUMBER, 0 },
	armor      = { false, core.TNUMBER, 0 },
	flags      = { false, core.TFLAGS, {} },
	bloodto    = { false, core.TIDIN("cells"), "" },
	destroyto  = { false, core.TIDIN("cells"), "" },
	raiseto    = { false, core.TIDIN("beings"), "" },
	hp         = { false, core.TNUMBER },
	set        = { false, core.TNUMBER },
	move_cost  = { false, core.TNUMBER, 1.0 },

	OnEnter       = { false, core.TFUNC },
	OnExit        = { false, core.TFUNC },
	OnAct         = { false, core.TFUNC },
	OnDescribe    = { false, core.TFUNC },
	OnDestroy     = { false, core.TFUNC },
	OnHazardQuery = { false, core.TFUNC },
}

core.register_blueprint "challenge"
{
	id            = { true,  core.TSTRING },
	name          = { true,  core.TSTRING },
	entryitem     = { false, core.TIDIN("items") },
	description   = { true,  core.TSTRING },
	rating        = { true,  core.TSTRING },
	rank          = { true,  core.TNUMBER },
	abbr          = { true,  core.TSTRING },
	let           = { true,  core.TSTRING },
	removemedals  = { false, core.TARRAY( core.TIDIN("medals") ) },
	win_mortem    = { false, core.TSTRING },
	win_highscore = { false, core.TSTRING },

	secondary          = { false, core.TTABLE },
	arch_name          = { false, core.TSTRING },
	arch_description   = { false, core.TSTRING },
	arch_rating        = { false, core.TSTRING },
	arch_rank          = { false, core.TNUMBER },
	arch_win_mortem    = { false, core.TSTRING },
    arch_win_highscore = { false, core.TSTRING },

	OnCreate         = { false, core.TFUNC },
	OnDie            = { false, core.TFUNC },
	OnDieCheck       = { false, core.TFUNC },
	OnPickup         = { false, core.TFUNC },
	OnPickupCheck    = { false, core.TFUNC },
	OnUse            = { false, core.TFUNC },
	OnUseCheck       = { false, core.TFUNC },
	OnKill           = { false, core.TFUNC },
	OnKillAll        = { false, core.TFUNC },
	OnEnterLevel     = { false, core.TFUNC },
	OnFire           = { false, core.TFUNC },
	OnFired          = { false, core.TFUNC },
	OnExit           = { false, core.TFUNC },
	OnTick           = { false, core.TFUNC },
	OnLoad           = { false, core.TFUNC },
	OnLoaded         = { false, core.TFUNC },
	OnUnLoad         = { false, core.TFUNC },
	OnCreatePlayer   = { false, core.TFUNC },
	OnLevelUp        = { false, core.TFUNC },
	OnPreLevelUp     = { false, core.TFUNC },
	OnWinGame        = { false, core.TFUNC },
	OnMortem         = { false, core.TFUNC },
	OnMortemPrint    = { false, core.TFUNC },
	OnCreateEpisode  = { false, core.TFUNC },
	OnIntro          = { false, core.TFUNC },
	OnGenerate       = { false, core.TFUNC },
}

core.register_blueprint "mod_array"
{
	id           = { true,  core.TSTRING },
	name         = { true,  core.TSTRING },
	mods         = { true,  core.TTABLE},
	desc         = { false, core.TSTRING },
	request_id   = { false, core.TIDIN("items") },
	request_type = { false, core.TNUMBER },
	level        = { false, core.TNUMBER, 0 },

	OnApply      = { true,  core.TFUNC },
	Match        = { false,  core.TFUNC },
}

core.register_blueprint "item"
{
	id             = { false, core.TSTRING },
	name           = { true, core.TSTRING },
	overlay        = { false, core.TTABLE },
	color          = { false, core.TNUMBER, LIGHTGRAY },
	color_id       = { false, core.TANY },
	sprite         = { true, core.TANY },
	coscolor       = { false, core.TTABLE },
	glow           = { false, core.TTABLE },
	sflags         = { false, core.TFLAGS, {} },
	sframes        = { false, core.TNUMBER, 0 },
	sftime         = { false, core.TNUMBER, FRAME_TIME },
	level          = { false, core.TNUMBER, 0 },
	max_level      = { false, core.TNUMBER , 10000 },
	weight         = { true, core.TNUMBER },
	set            = { false, core.TIDIN("itemsets") },
	flags          = { false, core.TFLAGS, {} },
	rechargeamount = { false, core.TNUMBER, 1 },
	rechargedelay  = { false, core.TNUMBER, 5 },
	rechargelimit  = { false, core.TNUMBER, 0 },
	firstmsg       = { false, core.TSTRING },
	resist         = { false, core.TTABLE },
	tags           = { false, core.TTABLE, {} },
	max            = { false, core.TNUMBER, 1 },
    amount         = { false, core.TNUMBER, 1 },
	movemod        = { false, core.TNUMBER, 0 },
	dodgemod       = { false, core.TNUMBER, 0 },
	knockmod       = { false, core.TNUMBER, 0 },
    
	type        = {{
		[ITEMTYPE_ARMOR] = {
			ascii      = { false, core.TSTRING, "[" },
			desc       = { true,  core.TSTRING },
			armor      = { true,  core.TNUMBER },
			pcoscolor  = { false, core.TTABLE },
			pglow      = { false, core.TTABLE },
			durability = { false, core.TNUMBER, 100 },
			spritemod  = { false, core.TNUMBER, 0 },
			scavenge   = { false, core.TARRAY(core.TIDIN("items")) },
		},
		[ITEMTYPE_BOOTS] = {
			ascii      = { false, core.TSTRING, ";" },
			desc       = { true,  core.TSTRING },
			armor      = { true,  core.TNUMBER },
			durability = { false, core.TNUMBER, 100 },
			scavenge   = { false, core.TARRAY(core.TIDIN("items")) },
		},
		[ITEMTYPE_PACK]   = {
			ascii      = { false, core.TSTRING, "+" },
			desc       = { true,  core.TSTRING },
			mod_letter = { false, core.TSTRING },
			dis_exotic = { false, core.TBOOLEAN, false },
			dis_unique = { false, core.TBOOLEAN, false },
			dis_other  = { false, core.TBOOLEAN, false },
			OnUse      = { true,  core.TFUNC },
		},
		[ITEMTYPE_POWER]   = {
			ascii    = { false, core.TSTRING, "^" },
			slevel   = { false, core.TNUMBER },
			OnPickup = { true, core.TFUNC },
		},
		[ITEMTYPE_AMMO]   = {
			ascii   = { false, core.TSTRING, "|" },
			desc    = { true, core.TSTRING },
		},
		[ITEMTYPE_AMMOPACK] = {
			ascii   = { false, core.TSTRING, "!" },
			desc    = { true, core.TSTRING },
			ammo    = { true, core.TNUMBER  },
			ammomax = { true, core.TNUMBER  },
			ammo_id = { true, core.TSTRING  },
		},
		[ITEMTYPE_RANGED] = {
			ascii         = { false, core.TSTRING, "}" },
			sound_id      = { false, core.TID },
			psprite       = { true, core.TNUMBER },
			pdsprite      = { false, core.TNUMBER },
			desc          = { true, core.TSTRING },
			group         = { true, core.TSTRING },
			ammomax       = { true, core.TNUMBER },
			ammo_id       = { true, core.TIDIN("items") },
			damage        = { true, core.TSTRING },
			damagetype    = { true, core.TNUMBER },
			range         = { false, core.TNUMBER, 0 },
			spread        = { false, core.TNUMBER, 0 },
			reduce        = { false, core.TNUMBER, 0.0 },
			acc           = { false, core.TNUMBER, 0 },
			fire          = { false, core.TNUMBER, 10 },
			radius        = { false, core.TNUMBER, 0 },
			reload        = { false, core.TNUMBER, 10 },
			shots         = { false, core.TNUMBER, 0 },
			shotcost      = { false, core.TNUMBER, 0 },
			altfire       = { false, core.TNUMBER, 0 },
			altreload     = { false, core.TNUMBER, 0 },
			altfirename   = { false, core.TSTRING },
			altreloadname = { false, core.TSTRING },
			overcharge    = { false, core.TIDIN("missiles") },
			scavenge      = { false, core.TARRAY(core.TIDIN("items")) },
			hitsprite     = { true, core.TANY },
			missprite     = { false, core.TANY },
			missile       = { false, core.TANY }, -- TODO core.TMISSILE
		},
		[ITEMTYPE_NRANGED] = {
			ascii      = { false, core.TSTRING, "?" },
			sound_id   = { false, core.TID },
			group      = { false, core.TSTRING },
			damage     = { true, core.TSTRING },
			damagetype = { true, core.TNUMBER },
			range      = { false, core.TNUMBER, 0 }, 
			spread     = { false, core.TNUMBER, 0 },
			reduce     = { false, core.TNUMBER, 0.0 },
			acc        = { false, core.TNUMBER, 0 },
			fire       = { false, core.TNUMBER, 10 },
			radius     = { false, core.TNUMBER, 0 },
			shots      = { false, core.TNUMBER, 0 },
			hitsprite  = { true, core.TANY },
			missprite  = { true, core.TANY },
			missile    = { true, core.TANY }, 
		},
		[ITEMTYPE_URANGED] = {
			ascii         = { false, core.TSTRING, "*" },
			sound_id      = { false, core.TID },
			desc          = { true, core.TSTRING },
			group         = { true, core.TSTRING },
			damage        = { true, core.TSTRING },
			damagetype    = { true, core.TNUMBER },
			range         = { true, core.TNUMBER }, -- throwing 
			spread        = { false, core.TNUMBER, 0 },
			reduce        = { false, core.TNUMBER, 0.0 },
			acc           = { false, core.TNUMBER, 0 },
			fire          = { false, core.TNUMBER, 10 },
			radius        = { false, core.TNUMBER, 0 },
			shots         = { false, core.TNUMBER, 0 },
			hitsprite     = { true, core.TANY },
			missprite     = { true, core.TANY },
			missile       = { true, core.TANY }, 
		},
		[ITEMTYPE_MELEE]  = {
			ascii       = { false, core.TSTRING, "\\" },
			sound_id    = { false, core.TSTRING },
			psprite     = { true, core.TNUMBER },
			pdsprite    = { false, core.TNUMBER },
			group       = { true, core.TSTRING },
			desc        = { true, core.TSTRING },
			damage      = { true, core.TSTRING },
			damagetype  = { true, core.TNUMBER },
			range       = { false, core.TNUMBER, 0 }, -- throwing 
			acc         = { false, core.TNUMBER, 0 },
			fire        = { false, core.TNUMBER, 10 },
			altfire     = { false, core.TNUMBER, 0 },
			altfirename = { false, core.TSTRING },
			hitsprite   = { false, core.TANY },
			missprite   = { false, core.TANY },
			missile     = { false, core.TANY, 0 }, 
			scavenge    = { false, core.TARRAY(core.TIDIN("items")) },
		},
		[ITEMTYPE_LEVER] = {
			ascii      = { false, core.TSTRING, "&" },
			sound_id   = { false, core.TSTRING, core.TIDIN("items") },
			color_id   = { true,  core.TANY },
			good       = { true,  core.TSTRING },
			desc       = { true,  core.TSTRING },
			warning    = { false, core.TSTRING },
			fullchance = { false, core.TNUMBER },
		},
		[ITEMTYPE_TELE] = {
			ascii   = { false, core.TSTRING, "*" },
			OnEnter = { true, core.TFUNC },
		},
		[ITEMTYPE_FEATURE] = {
			ascii     = { false, core.TSTRING, "*" },
			armor     = { false, core.TNUMBER },
			hp        = { false, core.TNUMBER },
			OnDestroy = { false, core.TFUNC },
			OnAct     = { false, core.TFUNC },
		},
	}},

	OnCreate      = { false, core.TFUNC },
	OnPickup      = { false, core.TFUNC },
	OnFirstPickup = { false, core.TFUNC },
	OnPickupCheck = { false, core.TFUNC },
	OnUse         = { false, core.TFUNC },
	OnUseCheck    = { false, core.TFUNC },
	OnPreReload   = { false, core.TFUNC },
	OnReload      = { false, core.TFUNC },
	OnAltFire     = { false, core.TFUNC },
	OnAltReload   = { false, core.TFUNC },
	OnEquip       = { false, core.TFUNC },
	OnEquipTick   = { false, core.TFUNC },
	OnEquipCheck  = { false, core.TFUNC },
	OnRemove      = { false, core.TFUNC },
	OnKill        = { false, core.TFUNC },
	OnHitBeing    = { false, core.TFUNC },
	OnEnter       = { false, core.TFUNC },
	OnFired       = { false, core.TFUNC },
	OnFire        = { false, core.TFUNC },
	OnPostMove    = { false, core.TFUNC },
	OnDamage      = { false, core.TFUNC },
	OnDescribe    = { false, core.TFUNC },
	
	OnModDescribe = { false, core.TFUNC },
}

core.register_blueprint "itemset"
{
	id        = { true,  core.TSTRING },
	name      = { true,  core.TSTRING },
	trigger   = { true,  core.TNUMBER },

	OnEquip   = { true,  core.TFUNC },
	OnRemove  = { true,  core.TFUNC },
}

core.register_blueprint "level"
{
	id            = { true,  core.TSTRING },
	name          = { true,  core.TSTRING },
	sname         = { false, core.TSTRING },
	abbr          = { false, core.TSTRING },
	entry         = { false, core.TSTRING },
	welcome       = { false, core.TSTRING },
	level         = { false, core.TANY },

	Create           = { true,  core.TFUNC },
	canGenerate      = { false, core.TFUNC },
	OnRegister       = { false, core.TFUNC },

	OnCreate         = { false, core.TFUNC },
	OnDie            = { false, core.TFUNC },
	OnDieCheck       = { false, core.TFUNC },
	OnPickup         = { false, core.TFUNC },
	OnPickupCheck    = { false, core.TFUNC },
	OnUse            = { false, core.TFUNC },
	OnUseCheck       = { false, core.TFUNC },
	OnKill           = { false, core.TFUNC },
	OnKillAll        = { false, core.TFUNC },
	OnEnterLevel     = { false, core.TFUNC },
	OnFire           = { false, core.TFUNC },
	OnFired          = { false, core.TFUNC },
	OnExit           = { false, core.TFUNC },
	OnTick           = { false, core.TFUNC },
	OnNuked          = { false, core.TFUNC },
}

core.register_blueprint "event"
{
	id         = { true,  core.TSTRING },
	min_dlevel = { false, core.TNUMBER, 0 },
	weight     = { true,  core.TNUMBER },
	tags       = { false, core.TTABLE, {} },
	min_diff   = { false, core.TNUMBER, 0 },
	history    = { false, core.TSTRING },
	message    = { false, core.TSTRING },
	setup      = { true,  core.TFUNC },
	on_tick    = { false, core.TFUNC },
	on_leave   = { false, core.TFUNC },
}

core.register_blueprint "room"
{
	id          = { true,  core.TSTRING },
	weight      = { true,  core.TNUMBER },
	tags        = { false, core.TTABLE, {} },
	min_size    = { false, core.TNUMBER, 4 },
	max_size_x  = { false, core.TNUMBER, 100 },
	max_size_y  = { false, core.TNUMBER, 100 },
	max_area    = { false, core.TNUMBER },
	setup       = { true,  core.TFUNC },
}

