function drl.register_missiles()

	register_missile "mgun"
	{
		sound_id   = "pistol",
		color      = LIGHTGRAY,
		sprite     = SPRITE_SHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 15,
		miss_base  = 10,
		miss_dist  = 3,
	}

	register_missile "mchaingun"
	{
		sound_id   = "chaingun",
		color      = WHITE,
		sprite     = SPRITE_SHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 10,
		miss_base  = 10,
		miss_dist  = 3,
	}

	register_missile "mplasma"
	{
		sound_id   = "plasma",
		ascii      = "*",
		color      = MULTIBLUE,
		sprite     = SPRITE_PLASMASHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 10,
		miss_base  = 30,
		miss_dist  = 3,
	}

	register_missile "mrocket"
	{
		sound_id   = "bazooka",
		color      = BROWN,
		sprite     = SPRITE_ROCKETSHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 30,
		miss_base  = 30,
		miss_dist  = 5,
		explosion  = {
			delay 	= 40,
			color 	= RED,
		},
	}

	register_missile "mrocketjump"
	{
		sound_id   = "bazooka",
		color      = BROWN,
		sprite     = SPRITE_ROCKETSHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 30,
		miss_base  = 30,
		miss_dist  = 5,
		flags      = { MF_EXACT },
		explosion  = {
			delay = 40,
			color = RED,
			flags = { EFSELFKNOCKBACK, EFSELFHALF },
		},
	}

	register_missile "mexplround"
	{
		sound_id   = "pistol",
		color      = LIGHTGRAY,
		sprite     = SPRITE_SHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 15,
		miss_base  = 10,
		miss_dist  = 3,
		explosion  = {
			delay = 40,
			color = RED,
		},
	}

	register_missile "mexplground"
	{
		sound_id   = "pistol",
		color      = LIGHTGRAY,
		sprite     = SPRITE_SHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 15,
		miss_base  = 10,
		miss_dist  = 3,
		explosion  = {
			delay = 40,
			color = GREEN,
		},

	}

	register_missile "mbfg"
	{
		sound_id   = "bfg9000",
		ascii      = "*",
		color      = WHITE,
		sprite     = SPRITE_BFGSHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 100,
		miss_base  = 50,
		miss_dist  = 10,
		flags      = { MF_EXACT },
		explosion  = {
			delay = 33,
			color = GREEN,
			flags = { EFSELFSAFE, EFAFTERBLINK, EFCHAIN, EFHALFKNOCK, EFNODISTANCEDROP },
		},
	}

	register_missile "mbfgover"
	{
		sound_id   = "bfg9000",
		ascii      = "*",
		color      = WHITE,
		sprite     = SPRITE_BFGSHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 200,
		miss_base  = 50,
		miss_dist  = 10,
		flags      = { MF_EXACT },
		explosion  = {
			delay = 33,
			color = GREEN,
			flags = { EFSELFSAFE, EFAFTERBLINK, EFCHAIN, EFHALFKNOCK, EFNODISTANCEDROP },
		},
	}

	register_missile "mblaster"
	{
		sound_id   = "plasma",
		color      = MULTIYELLOW,
		sprite     = SPRITE_SHOT,
		hitsprite  = SPRITE_BLAST,
		delay      = 10,
		miss_base  = 30,
		miss_dist  = 5,
	}

	register_missile "mknife"
	{
		sound_id   = "knife",
		color      = LIGHTGRAY,
		sprite     = SPRITE_KNIFE,
		hitsprite  = SPRITE_BLAST,
		delay      = 50,
		miss_base  = 10,
		miss_dist  = 3,
		flags      = { MF_EXACT },
	}

	register_shotgun "snormal"
	{
		hitsprite  = SPRITE_BLAST,
	}

	register_shotgun "swide"
	{
		hitsprite  = SPRITE_BLAST,
	}

	register_shotgun "sfocused"
	{
		hitsprite  = SPRITE_BLAST,
	}

	register_shotgun "splasma"
	{
		hitsprite  = SPRITE_BLAST,
	}
end
