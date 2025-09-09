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
	}

	register_missile "mbfg"
	{
		sound_id   = "bfg9000",
		ascii      = "*",
		color      = WHITE,
		delay      = 100,
		miss_base  = 50,
		miss_dist  = 10,
	}

	register_missile "mbfgover"
	{
		sound_id   = "bfg9000",
		ascii      = "*",
		color      = WHITE,
		delay      = 200,
		miss_base  = 50,
		miss_dist  = 10,
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
	}
end
