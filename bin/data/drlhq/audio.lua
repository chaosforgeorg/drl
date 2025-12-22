
-- High quality remixes of the original D music are a courtesy of Sonic 
-- Clang ( http://sonicclang.ringdev.com/ ) used with permission.

-- D the Roguelike theme, Unholy Cathedral, Final Showdown, Hells 
-- Weapons, Something Wicked, Of Skull And Bone, The Brick Song, and 
-- Too Hot Down Here tracks composed by Simon Volpert (thanks!)

music = {
	start     = "music/d_the_roguelike.mp3",
	bunny     = "music/d1end.mp3",
	intro     = "music/cde1m1.mp3",
	hellgate  = "music/cde1m8.mp3",

	level2    = "music/cde1m2.mp3",
	level3    = "music/cde1m3.mp3",
	level4    = "music/cde1m7.mp3",
	level5    = "music/cde1m5.mp3",
	level6    = "music/cde1m6.mp3",
	level7    = "music/cde1m4.mp3",
	level8    = "music/cde1m8.mp3",
	level9    = "music/cde1m1.mp3",
	level10   = "music/cde1m2.mp3",
	level11   = "music/cde1m3.mp3",
	level12   = "music/cde1m4.mp3",
	level13   = "music/cde1m5.mp3",
	level14   = "music/cde1m6.mp3",
	level15   = "music/cde1m7.mp3",
	level16   = "music/cde1m9.mp3",
	level17   = "music/cde1m2.mp3",
	level18   = "music/cde1m3.mp3",
	level19   = "music/cde1m4.mp3",
	level20   = "music/cde1m5.mp3",
	level21   = "music/cde1m6.mp3",
	level22   = "music/cde1m7.mp3",
	level23   = "music/cde1m9.mp3",
	level24   = "music/cde1m2.mp3",
	level25   = "music/cde1m3.mp3",

	hells_arena       = "music/cde1m9.mp3",
	the_chained_court = "music/rage.mp3",
	military_base     = "music/cde1m9.mp3",
	halls_of_carnage  = "music/cde1m9.mp3",
	hells_armory      = "music/hells_weapons.mp3",
	spiders_lair      = "music/cde1m3.mp3",
	city_of_skulls    = "music/of_skull_and_bone.mp3",
	the_wall          = "music/the_brick_song.mp3",
	unholy_cathedral  = "music/unholy_cathedral.mp3",
	the_mortuary      = "music/something_wicked.mp3",
	the_vaults        = "music/dark_secrets.mp3",
	house_of_pain     = "music/dark_secrets.mp3",
	the_lava_pits     = "music/too_hot_down_here.mp3",
	toxin_refinery    = "music/cde1m3.mp3",
	central_processing= "music/cde1m6.mp3",

	phobos_lab        = "music/cde1m5.mp3",
	deimos_lab        = "music/hells_weapons.mp3",
	containment_area  = "music/the_brick_song.mp3",
	abyssal_plains    = "music/of_skull_and_bone.mp3",
	limbo             = "music/something_wicked.mp3",
	mt_erebus         = "music/too_hot_down_here.mp3",

	tower_of_babel    = "music/cde1m8.mp3",
	hell_fortress     = "music/final_showdown.mp3",
	dis               = "music/cde1m8.mp3",
	victory           = "music/d1readme.mp3",
}

sound = {
	--
	-- Enviroment
	
	-- Sound
	menu     = {
		change = "sound/dspstop.wav",
		pick   = "sound/dspistol.wav",
		cancel = "sound/dsswtchx.wav",
	},
	
	-- Barrel
	
	barrel   = {
		move		= "sound/dsstnmov.wav",
		movefail	= "sound/dsnoway.wav",
		explode		= "sound/dsbarexp.wav",
	},
	
	barrela  = {
		move		= "sound/dsstnmov.wav",
		movefail	= "sound/dsnoway.wav",
		explode		= "sound/dsbarexp.wav",
	},
	
	barreln  = {
		move		= "sound/dsstnmov.wav",
		movefail	= "sound/dsnoway.wav",
		explode		= "sound/dsbarexp.wav",
	},
	
	-- Door
	
	door			= {
		open		= "sound/dsbdopn.wav",
		close		= "sound/dsbdcls.wav",
		fail		= "sound/dsnoway.wav",
	},
	
	-- Teleport
	
	teleport = {
		use			= "sound/dstelept.wav",
	},

	-- Hellgate
	
	hellportal = {
		use			= "sound/dstelept.wav",
	},
	
	-- Levers
	
	lever = {
		use				= "sound/dsswtchn.wav",
	},
	
	-- Gib
	
	gib				= "sound/dsslop.wav",
	
	--
	-- Powerups
	--
	
	-- Small Health Globe
	
	shglobe = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	-- Large Health Globe
	
	lhglobe = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	-- Supercharge Globe
	
	scglobe = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	-- Invulnerability Globe
	
	iglobe = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	-- Armor Shard
	
	ashard = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	-- Berserk Pack
	
	bpack = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	-- Computer Map
	
	map = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	-- Backpack
	
	backpack = {
		powerup		= "sound/dsgetpow.wav",
	},
	
	--
	-- Pickups
	--
	
	-- Small Medkit
	
	smed = {
		pickup		= "sound/dsitemup.wav",
		use			= "sound/dsgetpow.wav",
	},
	
	-- Large Medkit
	
	lmed = {
		pickup		= "sound/dsitemup.wav",
		use			= "sound/dsgetpow.wav",
	},
	
	-- Phase Device
	
	phase = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Homing Phase Device
	
	hphase = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Envirosuit Pack
	
	epack = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Thermonuclear Device
	
	nuke = {
		pickup		= "sound/dsitemup.wav",
		explode		= "sound/dsfirxpl.wav",
	},
	
	-- Power Mod Pack
	
	mod_power = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Agility Mod Pack
	
	mod_agility = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Bulk Mod Pack
	
	mod_bulk = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Technical Mod Pack
	
	mod_tech = {
		pickup		= "sound/dsitemup.wav",
	},
	
	--
	-- Armor and Boots
	--
	
	-- Green Armor
	
	garmor = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Blue Armor
	
	barmor = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Red Armor
	
	rarmor = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Steel Boots
	
	sboots = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Protective Boots
	
	pboots = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Plasteel Boots
	
	psboots = {
		pickup		= "sound/dsitemup.wav",
	},
	
	--
	-- Ammunition
	--
	
	-- 10mm Ammo
	
	ammo = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Shotgun Shell
	
	shell = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Rocket
	
	rocket = {
		pickup		= "sound/dsitemup.wav",
	},
	
	-- Power Cell
	
	cell = {
		pickup		= "sound/dsitemup.wav",
	},
	
	--
	-- Weapons
	--
	
	-- Combat Knife
	
	knife = {
		fire 		= "sound/dspunch.wav",
		pickup		= "sound/dswpnup.wav",
	},
	
	-- Pistol
	
	pistol = {
		fire		= "sound/dspistol.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
	},
	
	-- Shotgun
	
	shotgun = {
		fire		= "sound/dsshotgn.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
	},
	
	-- Combat Shotgun
	
	ashotgun = {
		fire		= "sound/dsshotgn.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
		pump		= "sound/dssgcock.wav",
	},
	
	-- Double Shotgun
	
	dshotgun = {
		fire		= "sound/dsdshtgn.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
	},
	
	--sshotgun = {
	--	fire		= "sound/dsdshtgn.wav",
	--	pickup		= "sound/dswpnup.wav",
	--	reload		= "sound/dswpnup.wav",
	--},
	
	-- Chaingun
	
	chaingun = {
		fire		= "sound/dspistol.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
	},
	
	-- Plasma Rifle
	
	plasma = {
		fire		= "sound/dsplasma.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
	},
	
	-- Rocket Launcher
	
	bazooka = {
		fire		= "sound/dsrlaunc.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
		explode		= "sound/dsrxplod.wav",
	},
	
	--
	-- Creatures
	--
	
	-- Player
	
	soldier = {
		die			= "sound/dspldeth.wav",
		hit			= "sound/dsplpain.wav",
		melee		= "sound/dspunch.wav",
		phase		= "sound/dstelept.wav",
	},
	
	-- Former Human
	
	former = {
		die			= "sound/dspodth1.wav",
		act			= "sound/dsposact.wav",
		hit			= "sound/dspopain.wav",
		melee		= "sound/dspunch.wav",
	},
	
	-- Former Sergeant
	
	sergeant = {
		die			= "sound/dspodth2.wav",
		act			= "sound/dsposact.wav",
		hit			= "sound/dspopain.wav",
		melee		= "sound/dspunch.wav",
	},
	
	-- Former Captain
	
	captain = {
		die			= "sound/dspodth2.wav",
		act			= "sound/dsposact.wav",
		hit			= "sound/dspopain.wav",
		melee		= "sound/dspunch.wav",
	},
	
	-- Former Commando
	
	commando = {
		die			= "sound/dspodth3.wav",
		act			= "sound/dsposact.wav",
		hit			= "sound/dspopain.wav",
		melee		= "sound/dspunch.wav",
	},
	
	-- Imp
	
	imp = {
		die			= "sound/dsbgdth1.wav",
		act			= "sound/dsbgact.wav",
		hit			= "sound/dspopain.wav",
		melee		= "sound/dsclaw.wav",
		fire		= "sound/dsfirsht.wav",
		explode		= "sound/dsfirxpl.wav",
	},
	
	-- Lost Soul
	
	lostsoul = {
		die			= "sound/dsfirxpl.wav",
		act			= "sound/dssklatk.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dssklatk.wav",
	},
	
	-- Pain Elemental
	
	pain = {
		die			= "sound/dspedth.wav",
		act			= "sound/dspesit.wav",
		hit			= "sound/dspepain.wav",
		melee		= "sound/dsclaw.wav";
	},
	
	-- Demon
	
	demon = {
		die			= "sound/dssgtdth.wav",
		act			= "sound/dsdmact.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dssgtatk.wav",
	},
	
	-- Cacodemon
	
	cacodemon = {
		die			= "sound/dscacdth.wav",
		act			= "sound/dscacsit.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dsclaw.wav",
		fire		= "sound/dsfirsht.wav",
		explode		= "sound/dsfirxpl.wav",
	},
	
	-- Arachnotron
	
	arachno = {
		die			= "sound/dsbspdth.wav",
		act			= "sound/dsbspact.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dsclaw.wav",
		fire		= "sound/dsplasma.wav",
	},
	
	-- Hell Knight
	
	knight = {
		die			= "sound/dskntdth.wav",
		act			= "sound/dskntsit.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dsclaw.wav",
		fire		= "sound/dsfirsht.wav",
		explode		= "sound/dsfirxpl.wav",
	},
	
	-- Baron of Hell
	
	baron = {
		die			= "sound/dsbrsdth.wav",
		act			= "sound/dsbrssit.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dsclaw.wav",
		fire		= "sound/dsfirsht.wav",
		explode		= "sound/dsfirxpl.wav",
	},
	
	-- Mancubus
	
	mancubus = {
		die			= "sound/dsmandth.wav",
		act			= "sound/dsmansit.wav",
		hit			= "sound/dsmnpain.wav",
		fire		= "sound/dsfirsht.wav",
		explode		= "sound/dsfirxpl.wav",
	},
	
	-- Revenant
	
	revenant = {
		die			= "sound/dsskedth.wav",
		act			= "sound/dsskesit.wav",
		hit			= "sound/dspopain.wav",
		melee		= "sound/dsskepch.wav",
		fire		= "sound/dsskeatk.wav",
		explode		= "sound/dsbarexp.wav",
	},
	
	-- Arch-vile
	
	arch = {
		die			= "sound/dsvildth.wav",
		act			= "sound/dsvilact.wav",
		hit			= "sound/dsvipain.wav",
		fire		= "sound/dsvilatk.wav",
	},

	-- Shambler
	
	shambler = {
		act			= "sound/dsbrssit.wav",
		die			= "sound/dsbspdth.wav",
		melee		= "sound/dsclaw.wav",
		hit			= "sound/dsdmpain.wav",
		fire		= "sound/dsfirsht.wav",
		explode		= "sound/dsfirxpl.wav",
	},

	-- Lava Elemental
	
	lava_elemental = {
		die			= "sound/dsvildth.wav",
	},

	-- Bruiser Brothers
	
	bruiser = {
		die			= "sound/dsbrsdth.wav",
		act			= "sound/dsbrssit.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dsclaw.wav",
		fire		= "sound/dsfirsht.wav",
		explode		= "sound/dsfirxpl.wav",
	},
	
	-- Cyberdemon
	
	cyberdemon = {
		die			= "sound/dscybdth.wav",
		act			= "sound/dscybsit.wav",
		hit			= "sound/dsdmpain.wav",
		hoof		= "sound/dshoof.wav",
	},
	
	-- JC

	jc = {
		die			= "sound/dspodth1.wav",
		act			= "sound/dsposact.wav",
		hit			= "sound/dspopain.wav",
		melee		= "sound/dspunch.wav",
	},

	-- AoD

	angel = {
		die			= "sound/dsbrsdth.wav",
		act			= "sound/dsbrssit.wav",
		hit			= "sound/dsbrssit.wav",
		melee		= "sound/dsclaw.wav",
		hoof		= "sound/dshoof.wav";
	},
	
	-- Mastermind
	
	mastermind = {
		die			= "sound/dsspidth.wav",
		act			= "sound/dsdmact.wav",
		hit			= "sound/dsdmpain.wav",
		melee		= "sound/dsclaw.wav",
		hoof		= "sound/dsmetal.wav";
	},
	
	--
	-- Exotic Items
	--
	
	-- Exotic #18 (Chainsaw)
	
	chainsaw = {
		fire		= "sound/dssawhit.wav",
		pickup		= "sound/dswpnup.wav",
	},
	
	-- Exotic #19 (BFG 9000)
	
	bfg9000 = {
		fire		= "sound/dsbfg.wav",
		pickup		= "sound/dswpnup.wav",
		reload		= "sound/dswpnup.wav",
		explode		= "sound/dsrxplod.wav",
	},
	
	--
	-- Unique Items
	--
	
	-- Unique #17 (Longinus Spear)
	
	spear = {
		fire		= "sound/dsgetpow.wav",
		pickup		= "sound/dswpnup.wav",
		explode		= "sound/dsrxplod.wav",
	},
	
	--
	-- Default sounds
	--
	
	melee			= "sound/dsclaw.wav",
	reload			= "sound/dswpnup.wav",
	pickup			= "sound/dsitemup.wav",
	fire			= "sound/dsfirsht.wav",
	use				= "sound/dsgetpow.wav",
	explode			= "sound/dsfirxpl.wav",
	powerup			= "sound/dsgetpow.wav",
	phasing			= "sound/dstelept.wav",
}
