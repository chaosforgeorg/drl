function drl.register_missiles()

	register_missile "mgun"
	{
		sound_id   = "pistol",
		color      = LIGHTGRAY,
		delay      = 15,
		miss_base  = 10,
		miss_dist  = 3,
	}

	register_missile "mchaingun"
	{
		sound_id   = "chaingun",
		color      = WHITE,
		delay      = 10,
		miss_base  = 10,
		miss_dist  = 3,
	}

	register_missile "mplasma"
	{
		sound_id   = "plasma",
		ascii      = "*",
		color      = MULTIBLUE,
		delay      = 10,
		miss_base  = 30,
		miss_dist  = 3,
	}

	register_missile "mrocket"
	{
		sound_id   = "bazooka",
		color      = BROWN,
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
		delay      = 10,
		miss_base  = 30,
		miss_dist  = 5,
	}

	register_missile "mknife"
	{
		sound_id   = "knife",
		color      = LIGHTGRAY,
		delay      = 50,
		miss_base  = 10,
		miss_dist  = 3,
		flags      = { MF_EXACT },
	}
end
