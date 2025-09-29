function drl.register_challenges()

-- <action> [on <difficulty>][<special conditions>] (for badges)

--EASY: Shotgunnery, Max Carnage, Pacifism
--MEDIUM: Berserk, Marskmanship, Red Alert
--HARD: Light Travel, Impatience, 100
--VERY HARD: Confidence, Darkness, Overconfidence
--BLADE: Purity, Masochism, Humanity

-- CHALLENGE BERSERK --

	register_badge "berserker1"
	{
		name  = "Berserker Bronze Badge",
		desc  = "Reach level 9 on Angel of Berserk",
		level = 1,
	}

	register_badge "berserker2"
	{
		name  = "Berserker Silver Badge",
		desc  = "Complete Angel of Berserk (AoB)",
		level = 2,
	}

	register_badge "berserker3"
	{
		name  = "Berserker Gold Badge",
		desc  = "Complete AoB on HMP",
		level = 3,
	}

	register_badge "berserker4"
	{
		name  = "Berserker Platinum Badge",
		desc  = "Complete AoB on UV/75% kills",
		level = 4,
	}

	register_badge "berserker5"
	{
		name  = "Berserker Diamond Badge",
		desc  = "Complete AoB on N!/60% kills",
		level = 5,
	}

	register_badge "berserker6"
	{
		name  = "Berserker Angelic Badge",
		desc  = "Complete AoB+AoMs on N!",
		level = 6,
	}

	register_medal "gargulec1"
	{
		name  = "Gargulec Medal",
		desc  = "Complete AoB/100% kills",
		hidden  = true,
	}

	register_medal "gargulec2"
	{
		name  = "Gargulec Cross",
		desc  = "Win Angel of Berserk on UV/100% kills",
		hidden  = true,
		removes = { "gargulec1" },
	}


	register_challenge "challenge_aob"
	{
		name        = "Angel of Berserk",
		entryitem   = "knife",
		description = "A challenge for the true berserker! You don't have a gun at the start and can't use weapons except melee weapons! To make things a little easier, large health globes will act like berserk packs for you.",
		rating      = "MEDIUM",
		rank        = 1,
		abbr        = "AoB",
		let         = "B",
		removemedals = { "pistols", "shotguns" },
		secondary   = { "AoCn", "AoOC", "A100", "AoLT", "AoI", "AoP", "AoRA", "AoD", "AoMs" },

		OnCreatePlayer = function ()
			player.inv:clear()
			player.eq:clear()
			player.eq.armor = "barmor"
			player.inv:add("lmed")
			player.inv:add("lmed")
			if player.klass == klasses.technician.nid then
				player.inv:add("mod_tech")
			end
		end,

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.rocket = nil
				level.data.final_reward.bazooka = nil
				if level.data.final_reward.lmed then
					level.data.final_reward.lmed = level.data.final_reward.lmed + 1
				end
				level.data.final_reward.hphase = 1
			end
		end,
		
		OnFire = function (item,being)
			if not being:is_player() then return true end
			if not item then return true end
			if item.itype == ITEMTYPE_MELEE then return true end
			ui.msg("You pull the trigger, but nothing happens. You're a berserker, dumbass!")
			return false
		end,

		OnPickup = function(item,being)
			if not being:is_player() then return end
			if item.id == "lhglobe" then player:set_affect("berserk",20) end
		end,

		OnMortem = function ()
			if player.level_index >= 9  then player:add_badge("berserker1") end
			if player:has_won() then

				if statistics.unique_kills == statistics.max_unique_kills then
					player:add_medal("gargulec1")
				end
				player:add_badge("berserker2")
				if DIFFICULTY >= DIFF_HARD  then
					player:add_badge("berserker3")
				end
				if DIFFICULTY >= DIFF_VERYHARD and statistics.unique_kills >= statistics.max_unique_kills * 0.75 then
					player:add_badge("berserker4")
					if statistics.unique_kills == statistics.max_unique_kills then
						player:add_medal("gargulec2")
						player:remove_medal("gargulec1")
					end
				end
				if DIFFICULTY >= DIFF_NIGHTMARE and statistics.unique_kills >= statistics.max_unique_kills * 0.6 then
					player:add_badge("berserker5")
				end
				if SCHALLENGE == "challenge_aoms" and DIFFICULTY >= DIFF_NIGHTMARE then
					player:add_badge("berserker6")
				end
			end
		end,
	}

-- CHALLENGE MARKSMAN --

	register_badge "marksman1"
	{
		name  = "Marksman Bronze Badge",
		desc  = "Reach level 16 on Angel of Marksmanship",
		level = 1,
	}

	register_badge "marksman2"
	{
		name  = "Marksman Silver Badge",
		desc  = "Complete Angel of Marksmanship (AoMr)",
		level = 2,
	}

	register_badge "marksman3"
	{
		name  = "Marksman Gold Badge",
		desc  = "Complete AoMr on UV",
		level = 3,
	}

	register_badge "marksman4"
	{
		name  = "Marksman Platinum Badge",
		desc  = "Complete AoMr on UV/100% kills",
		level = 4,
	}

	register_badge "marksman5"
	{
		name  = "Marksman Diamond Badge",
		desc  = "Complete AoMr on N!",
		level = 5,
	}

	register_badge "marksman6"
	{
		name  = "Marksman Angelic Badge",
		desc  = "Complete AoMr+AoD on N!/75% kills",
		level = 6,
	}

	register_challenge "challenge_aomr"
	{
		name        = "Angel of Marksmanship",
		description = "Fans of pistols, unite! This challenge doesn't allow you to use any weapon besides a pistol (or two if you know how)!",
		rating      = "MEDIUM",
		rank        = 1,
		abbr        = "AoMr",
		let         = "R",
		secondary   = { "AoCn", "AoOC", "A100", "AoLT", "AoI", "AoP", "AoRA", "AoD", "AoMs" },
		removemedals = { "pistols" },

		OnCreatePlayer = function ()
			player.inv:add( table.random_pick({"mod_agility","mod_bulk","mod_tech"}) )
		end,

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.rocket = nil
				level.data.final_reward.bazooka = nil
				level.data.final_reward.pammo = 1
				level.data.final_reward.mod_power = 1
			end
		end,
		
		OnFire = function (item,being)
			if not being:is_player() then return true end
			if not item then return true end
			if item.group == "pistol" then return true end
			ui.msg("This weapon isn't worthy of a marksman!")
			return false
		end,

		OnMortem = function ()
			if player.level_index >= 16 then player:add_badge("marksman1") end
			if player:has_won() then
				player:add_badge("marksman2")
				if DIFFICULTY >= DIFF_VERYHARD  then
					player:add_badge("marksman3")
					if statistics.unique_kills == statistics.max_unique_kills then
						player:add_badge("marksman4")
					end
				end
				if DIFFICULTY >= DIFF_NIGHTMARE then
					player:add_badge("marksman5")
					if SCHALLENGE == "challenge_aod" and statistics.unique_kills >= statistics.max_unique_kills * 0.75 then
						player:add_badge("marksman6")
					end
				end
			end
		end,
	}

-- CHALLENGE SHOTGUNNERY --

	register_badge "shotgun1"
	{
		name  = "Shottyman Bronze Badge",
		desc  = "Reach level 16 on Angel of Shotgunnery",
		level = 1,
	}

	register_badge "shotgun2"
	{
		name  = "Shottyman Silver Badge",
		desc  = "Complete Angel of Shotgunnery (AoSh)",
		level = 2,
	}

	register_badge "shotgun3"
	{
		name  = "Shottyman Gold Badge",
		desc  = "Complete AoSh on UV",
		level = 3,
	}

	register_badge "shotgun4"
	{
		name  = "Shottyman Platinum Badge",
		desc  = "Complete AoSh on N!",
		level = 4,
	}

	register_badge "shotgun5"
	{
		name  = "Shottyman Diamond Badge",
		desc  = "Complete AoSh on N!/80% kills",
		level = 5,
	}

	register_badge "shotgun6"
	{
		name  = "Shottyman Angelic Badge",
		desc  = "Complete AoSh+AoOC on N!/75% kills",
		level = 6,
	}

	register_challenge "challenge_aosh"
	{
		name        = "Angel of Shotgunnery",
		description = "It's time to kick ass and chew bubblegum -- only shotguns and fists are the true weapons of the Army of the Dead!",
		rating      = "EASY",
		rank        = 2,
		abbr        = "AoSh",
		let         = "S",
		secondary   = { "AoCn", "AoOC", "A100", "AoLT", "AoI", "AoP", "AoRA", "AoD", "AoMs" },
		removemedals = { "shotguns" },

		OnCreatePlayer = function ()
			player.inv:clear()
			player.eq:clear()
			player.eq.weapon = "shotgun"
			player.inv:add( "shell", { amount = 50 } )
			player.inv:add( "smed" )
			player.inv:add( "smed" )
			if player.klass == klasses.technician.nid then
				player.inv:add("mod_tech")
			end
		end,

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.rocket = nil
				level.data.final_reward.bazooka = nil
				level.data.final_reward.pshell = 1
				level.data.final_reward.dshotgun = 1
			end
		end,
		
		OnFire = function (item,being)
			if not being:is_player() then return true end
			if not item then return true end
			if item.group == "shotgun" then return true end
			ui.msg("This is a weapon for wimps, not a true man!")
			return false
		end,

		OnMortem = function ()
			if player.level_index >= 16 then player:add_badge("shotgun1") end
			if player:has_won() then
				player:add_badge("shotgun2")
				if DIFFICULTY >= DIFF_VERYHARD  then player:add_badge("shotgun3") end
				if DIFFICULTY >= DIFF_NIGHTMARE then
					player:add_badge("shotgun4")
					if statistics.unique_kills >= statistics.max_unique_kills * 0.8 then player:add_badge("shotgun5") end
					if SCHALLENGE == "challenge_aooc" and statistics.unique_kills >= statistics.max_unique_kills * 0.75 then
						player:add_badge("shotgun6")
					end
				end
			end
		end,
	}

-- CHALLENGE LIGHT TRAVEL --

	register_badge "lightfoot1"
	{
		name  = "Lightfoot Bronze Badge",
		desc  = "Reach level 9 on Angel of Light Travel",
		level = 1,
	}

	register_badge "lightfoot2"
	{
		name  = "Lightfoot Silver Badge",
		desc  = "Complete Angel of Light Travel (AoLT)",
		level = 2,
	}

	register_badge "lightfoot3"
	{
		name  = "Lightfoot Gold Badge",
		desc  = "Complete AoLT on HMP",
		level = 3,
	}

	register_badge "lightfoot4"
	{
		name  = "Lightfoot Platinum Badge",
		desc  = "Complete AoLT on UV+ w/<20,000 turns",
		level = 4,
	}

	register_badge "lightfoot5"
	{
		name  = "Lightfoot Diamond Badge",
		desc  = "Complete AoLT on N! w/o melee kills",
		level = 5,
	}

	register_badge "lightfoot6"
	{
		name  = "Lightfoot Angelic Badge",
		desc  = "Complete ArchAoLT on N! w/o melee kills",
		level = 6,
	}

	register_challenge "challenge_aolt"
	{
		name        = "Angel of Light Travel",
		description = "Who needs all that junk? Try to complete the game only using 5 inventory slots! To help you out, you get a +20% speed bonus.",

		rating      = "HARD",
		rank        = 2,
		abbr        = "AoLT",
		let         = "L",

		arch_name        = "Archangel of Travel",
		arch_description = "Who needs all that junk? Try to complete the game only using 2 inventory slots! You get a +30% speed bonus this time.",
		arch_rating      = "BLADE",
		arch_rank        = 5,

		OnCreatePlayer = function ()
			if ARCHANGEL then
				player:set_inv_size(2)
				player.inv:clear()
				player.inv:add( "pammo" )
				player.speed = player.speed + 30
				if player.klass == klasses.technician.nid then
					player.inv:add("mod_tech")
				end
			else
				player:set_inv_size(5)
				if CHALLENGE ~= "challenge_aosh" and CHALLENGE ~= "challenge_aob" then
					player.inv:add( "pammo" )
				end
				if CHALLENGE ~= "challenge_aomr" and CHALLENGE ~= "challenge_aob" then
					player.inv:add( "pshell" )
				end
				player.speed = player.speed + 20
			end
		end,

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.rocket = nil
				level.data.final_reward.bazooka = nil
				level.data.final_reward.pammo = 1
				level.data.final_reward.pshell = 1
			end
		end,
		
		OnMortem = function ()
			local melee_tot = kills.get_type("melee")
			for index = 1, items.__counter do
				if items[index].group == "melee" then
					melee_tot = melee_tot + kills.get_type(items[index].id)
				end
			end
			if player.level_index >= 9 then player:add_badge("lightfoot1") end
			if player:has_won() then
				player:add_badge("lightfoot2")
				if DIFFICULTY >= DIFF_HARD                                        then player:add_badge("lightfoot3") end
				if DIFFICULTY >= DIFF_VERYHARD  and statistics.game_time <= 20000 then player:add_badge("lightfoot4") end
				if DIFFICULTY >= DIFF_NIGHTMARE and melee_tot == 0                then
					player:add_badge("lightfoot5")
					if ARCHANGEL then  player:add_badge("lightfoot6") end
				end
			end
		end,

	}

-- CHALLENGE IMPATENCE --

	register_badge "impatient1"
	{
		name  = "Eagerness Bronze Badge",
		desc  = "Reach level 9 on Angel of Impatience",
		level = 1,
	}

	register_badge "impatient2"
	{
		name  = "Eagerness Silver Badge",
		desc  = "Complete Angel of Impatience (AoI)",
		level = 2,
	}

	register_badge "impatient3"
	{
		name  = "Eagerness Gold Badge",
		desc  = "Complete AoI on HMP",
		level = 3,
	}

	register_badge "impatient4"
	{
		name  = "Eagerness Platinum Badge",
		desc  = "Complete AoI on UV as non-Marine",
		level = 4,
	}

	register_badge "impatient5"
	{
		name  = "Eagerness Diamond Badge",
		desc  = "Complete AoI on N! as Technician",
		level = 5,
	}

	register_badge "impatient6"
	{
		name  = "Eagerness Angelic Badge",
		desc  = "Complete AoI+AoRA on N!/90% kills",
		level = 6,
	}

	register_challenge "challenge_aoi"
	{
		name        = "Angel of Impatience",
		description = "You need to kill NOW! No time to carry all those medkits and phase devices, you use them immediately on pickup!",
		rating      = "HARD",
		rank        = 3,
		abbr        = "AoI",
		let         = "I",
		secondary   = { "AoCn", "AoOC", "A100", "AoLT", "AoRA", "AoD" },

		OnCreatePlayer = function ()
			player.inv:clear()
			if CHALLENGE ~= "challenge_aob" then
				if CHALLENGE == "challenge_aosh" then
					player.inv:add( "shell", { amount = 50 } )
				elseif CHALLENGE == "challenge_aopc" then
					player.inv:add( "nuke" )
				else
					player.inv:add( "ammo", { amount = 100 } )
				end
			end
			player.flags[ BF_IMPATIENT ] = true
		end,

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.lmed = nil
				level.data.final_reward.sboots = 1
			end
		end,
		
		OnMortem = function ()
			if player.level_index >= 9 then player:add_badge("impatient1") end
			if player:has_won() then
				player:add_badge("impatient2")
				if DIFFICULTY >= DIFF_HARD                                                   then player:add_badge("impatient3") end
				if DIFFICULTY >= DIFF_VERYHARD  and klasses[player.klass].id ~= "marine"     then player:add_badge("impatient4") end
				if DIFFICULTY >= DIFF_NIGHTMARE and klasses[player.klass].id == "technician" then player:add_badge("impatient5") end
				if DIFFICULTY >= DIFF_NIGHTMARE and SCHALLENGE == "challenge_aora" then
					if statistics.unique_kills >= statistics.max_unique_kills * 0.9 then player:add_badge("impatient6") end
				end
			end
		end,
	}


	register_badge "confident1"
	{
		name  = "Daredevil Bronze Badge",
		desc  = "Reach level 9 on Angel of Confidence",
		level = 1,
	}

	register_badge "confident2"
	{
		name  = "Daredevil Silver Badge",
		desc  = "Complete Angel of Confidence (AoCn)",
		level = 2,
	}

	register_badge "confident4"
	{
		name  = "Daredevil Platinum Badge",
		desc  = "Complete AoCn on UV/100% kills",
		level = 4,
	}

	register_challenge "challenge_aocn"
	{
		name        = "Angel of Confidence",
		description = "Are three episodes too much of a grind? Try beating the game in just two! Having seen the destruction of Phobos beforehand, you asked to be dropped off at the Deimos base to save yourself the trouble. At least they were nice enough to give you some more gear.",
		rating      = "VERY HARD",
		rank        = 4,
		abbr        = "AoCn",
		let         = "N",
		removemedals = { "icarus1", "icarus2", "explorer", "conqueror", "competn1", "competn2", "competn3", "untouchable1", "untouchable2", "untouchable3" },

		OnCreateEpisode = function ()
			local slevcount = 0
			for i=8,24 do
				if player.episode[i].special then
					slevcount = slevcount + 1
				end
			end
			statistics.bonus_levels_count = slevcount
			player.level_index = 8
		end,

		OnCreatePlayer = function ()
			player.inv:clear()
			if CHALLENGE == "challenge_aob" then
				player.inv:add( "chainsaw")
			elseif CHALLENGE == "challenge_aomr" then
				player.inv:add( "ammo", { amount = 100 } )
			elseif CHALLENGE == "challenge_aosh" then
				player.inv:add( "shotgun" )
				player.inv:add( "shell", { amount = 50 } )
			elseif CHALLENGE == "challenge_aolt" then
				player.eq.prepared = "pammo"
				player.inv:add( "shotgun" )
				player.inv:add( "chaingun" )
				player.inv:add( "pshell" )
			elseif CHALLENGE == "challenge_aopc" then
			else
				player.inv:add( "shotgun" )
				player.inv:add( "chaingun" )
				player.inv:add( "knife")
				player.inv:add( "ammo", { amount = 100 } )
				player.inv:add( "shell", { amount = 50 } )
			end
			if CHALLENGE ~= "challenge_aoi" and CHALLENGE ~= "challenge_aoms" then
				player.inv:add( "lmed" )
				player.inv:add( "lmed" )
			end
			if CHALLENGE == "challenge_aohu" then
				player.eq.armor = "rarmor"
				for i=1,2 do
					player.inv:add( "lmed" )
				end
				player.inv:add( "mod_agility" )
				player.inv:add( "mod_tech" )
				player.inv:add( "mod_power" )
				player.inv:add( "mod_bulk" )
			end
			if CHALLENGE ~= "challenge_aoi"  then
				if player.klass == klasses.technician.nid then
					player.inv:add("mod_tech")
				end
			end
		end,

		OnMortem = function ()
			if player.level_index >= 9 then player:add_badge("confident1") end
			if player:has_won() then
				player:add_badge("confident2")
				if statistics.unique_kills == statistics.max_unique_kills and DIFFICULTY >= DIFF_VERYHARD then player:add_badge("confident4") end
			end
		end,

	}

-- CHALLENGE PURITY


	register_badge "purity3"
	{
		name  = "Inquisitor Gold Badge",
		desc  = "Complete Angel of Purity (AoP)",
		level = 3,
	}

	register_badge "purity4"
	{
		name  = "Inquisitor Platinum Badge",
		desc  = "Complete AoP on UV",
		level = 4,
	}

	register_badge "purity5"
	{
		name  = "Inquisitor Diamond Badge",
		desc  = "Complete AoP on N! as Marine",
		level = 5,
	}

	register_badge "purity6"
	{
		name  = "Inquisitor Angelic Badge",
		desc  = "Complete AoP+AoRA on N!",
		level = 6,
	}

	register_challenge "challenge_aop"
	{
		name        = "Angel of Purity",
		description = "Who needs those powerups anyway? Try to finish DRL without them. But remember that health globes are also a powerup!",
		rating      = "BLADE",
		rank        = 4,
		abbr        = "AoP",
		let         = "P",
		secondary   = { "AoCn", "AoOC", "A100", "AoLT", "AoRA", "AoD" },

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.scglobe = nil
				if level.data.final_reward.lmed then
					level.data.final_reward.lmed = level.data.final_reward.lmed + 1
				end
			end
		end,
		
		OnPickupCheck = function(item,being)
			if not being:is_player() then return true end
			if item.itype == ITEMTYPE_POWER then
				ui.msg('Impure.')
				return false
			else
				return true
			end
		end,

		OnMortem = function ()
			if player:has_won() then
				player:add_badge("purity3")
				if DIFFICULTY >= DIFF_VERYHARD  then player:add_badge("purity4") end
				if DIFFICULTY >= DIFF_NIGHTMARE and klasses[player.klass].id == "marine"   then player:add_badge("purity5") end
				if DIFFICULTY >= DIFF_NIGHTMARE and SCHALLENGE == "challenge_aora"         then player:add_badge("purity6") end
			end
		end,
	}

-- CHALLENGE RED ALERT


	register_badge "redalert1"
	{
		name  = "Quartermaster Bronze Badge",
		desc  = "Reach level 16 on Angel of Red Alert",
		level = 1,
	}

	register_badge "redalert2"
	{
		name  = "Quartermaster Silver Badge",
		desc  = "Complete Angel of Red Alert (AoRA)",
		level = 2,
	}

	register_badge "redalert3"
	{
		name  = "Quartermaster Gold Badge",
		desc  = "Complete AoRA with 100% kills",
		level = 3,
	}

	register_badge "redalert4"
	{
		name  = "Quartermaster Platinum Badge",
		desc  = "Complete AoRA on N!",
		level = 4,
	}

	register_badge "redalert5"
	{
		name  = "Quartermaster Diamond Badge",
		desc  = "Complete AoRA on UV/100% kills",
		level = 5,
	}

	register_badge "redalert6"
	{
		name  = "Quartermaster Angelic Badge",
		desc  = "Complete ArchAoRA on UV/80% kills",
		level = 6,
	}

	register_challenge "challenge_aora"
	{
		name        = "Angel of Red Alert",
		description = "You've been ordered to clear out Hell, no matter what. Every time you enter a level, a nuke is dropped and armed, with countdown of 5 minutes (around 240 moves). Warning, the areas can't be scouted!",
		rating      = "MEDIUM",
		rank        = 4,
		abbr        = "AoRA",
		let         = "A",
		removemedals = { "fallout1", "fallout2", "fallout3" },

		arch_name        = "Archangel of Red Alert",
		arch_description = "You've been ordered to clear out Hell, no matter what. Every time you enter a level, a nuke is dropped and armed, with countdown of 2.5 minutes (around 120 moves). Warning, the areas can't be scouted!",
		arch_rating      = "BLADE",
		arch_rank        = 6,

		OnEnterLevel = function (l, lid)
			player.flags[ BF_STAIRSENSE ] = false
			if ARCHANGEL then
				player:nuke(2.5*60*10)
				ui.msg_feel("\"Thermonuclear bomb deployed. 2 minutes 30 seconds till explosion.\"")
			else
				player:nuke(5*60*10)
				ui.msg_feel("\"Thermonuclear bomb deployed. 5 minutes till explosion.\"")
			end
			if lid == "hells_arena" then
				level.data.drop_zone = area(3,8,7,12)
			end
		end,

		OnMortem = function ()
			if player.level_index >= 16 then player:add_badge("redalert1") end
			if player:has_won() then
				player:add_badge("redalert2")
				if DIFFICULTY >= DIFF_NIGHTMARE then player:add_badge("redalert4") end
				if statistics.unique_kills == statistics.max_unique_kills then
					player:add_badge("redalert3")
					if DIFFICULTY >= DIFF_VERYHARD then player:add_badge("redalert5") end
				end
				if ARCHANGEL and DIFFICULTY >= DIFF_VERYHARD and statistics.unique_kills >= statistics.max_unique_kills * 0.8 then
					player:add_badge("redalert6")
				end
			end
		end,
	}

-- CHALLENGE DARKNESS --


	register_badge "darkness1"
	{
		name  = "Hunter Bronze Badge",
		desc  = "Reach level 9 on Angel of Darkness",
		level = 1,
	}

	register_badge "darkness2"
	{
		name  = "Hunter Silver Badge",
		desc  = "Complete Angel of Darkness (AoD)",
		level = 2,
	}

	register_badge "darkness3"
	{
		name  = "Hunter Gold Badge",
		desc  = "Complete AoD on HMP/80% kills",
		level = 3,
	}

	register_badge "darkness4"
	{
		name  = "Hunter Platinum Badge",
		desc  = "Complete AoD on N!",
		level = 4,
	}

	register_badge "darkness5"
	{
		name  = "Hunter Diamond Badge",
		desc  = "Complete AoD on N! w/Explorer Pin",
		level = 5,
	}

	register_challenge "challenge_aod"
	{
		name        = "Angel of Darkness",
		description = "You think the DRL levels are dark? Try this challenge, and feel a bit of painful claustrophobia! As a bonus to all that is unjust in this challenge, you level up twice as fast.",
		rating      = "VERY HARD",
		rank        = 5,
		abbr        = "AoD",
		let         = "D",
		secondary   = { "AoCn", "AoOC", "A100", "AoLT", "AoI", "AoP", "AoRA", "AoMs" },

		OnEnterLevel = function ()
			level.flags[ LF_RESPAWN ] = true
		end,

		OnCreatePlayer = function ()
			player.flags[ BF_STAIRSENSE ] = true
			player.flags[ BF_DARKNESS ]   = true
			player.vision = player.vision - 2
		end,

		OnCreate = function ( this )
			if this:is_being() then
				this.expvalue = this.expvalue * 2
			end
		end,

		OnMortem = function ()
			if player.level_index >= 9 then player:add_badge("darkness1") end
			if player:has_won() then
				player:add_badge("darkness2")
				if DIFFICULTY >= DIFF_HARD and statistics.unique_kills >= statistics.max_unique_kills * 0.8 then player:add_badge("darkness3") end
				if DIFFICULTY >= DIFF_NIGHTMARE then
					player:add_badge("darkness4")
					if statistics.bonus_levels_visited == statistics.bonus_levels_count then
						player:add_badge("darkness5")
					end
				end
			end
		end,
	}

-- CHALLENGE CARNAGE


	register_badge "carnage1"
	{
		name  = "Destroyer Bronze Badge",
		desc  = "Reach level 16 in Angel of Max Carnage",
		level = 1,
	}

	register_badge "carnage2"
	{
		name  = "Destroyer Silver Badge",
		desc  = "Complete Angel of Max Carnage (AoMC)",
		level = 2,
	}

	register_badge "carnage3"
	{
		name  = "Destroyer Gold Badge",
		desc  = "Complete AoMC on HMP w/Untouchable Pin",
		level = 3,
	}

	register_badge "carnage4"
	{
		name  = "Destroyer Platinum Badge",
		desc  = "Complete AoMC on UV w/Untouchable Medal",
		level = 4,
	}

	register_badge "carnage5"
	{
		name  = "Destroyer Diamond Badge",
		desc  = "Complete AoMC on N! w/Untouchable Cross",
		level = 5,
	}

	register_challenge "challenge_aomc"
	{
		name        = "Angel of Max Carnage",
		description = "You hate chance, you hate games of chance, you hate dice so much that you crush them when you see them. As a result, your guns do max damage and you are almost guaranteed to hit. However this also applies to your enemies...",
		rating      = "EASY",
		rank        = 5,
		abbr        = "AoMC",
		let         = "C",
		secondary   = { "AoCn", "AoOC", "A100", "AoLT", "AoI", "AoP", "AoRA", "AoD", "AoMs" },

		OnCreate = function ( this )
			if this:is_being() then
				this.accuracy = this.accuracy + 12
				this.flags[ BF_MAXDAMAGE ] = true
			end
		end,

		OnMortem = function ()
			if player.level_index >= 16 then player:add_badge("carnage1") end
			if player:has_won() then
				player:add_badge("carnage2")
				if DIFFICULTY >= DIFF_HARD and statistics.damage_taken < 500 then player:add_badge("carnage3") end
				if DIFFICULTY >= DIFF_VERYHARD and statistics.damage_taken < 200 then player:add_badge("carnage4") end
				if DIFFICULTY >= DIFF_NIGHTMARE and statistics.damage_taken < 50 then player:add_badge("carnage5") end
			end
		end,
	}

-- CHALLENGE MASOCHISM


	register_badge "masochism3"
	{
		name  = "Masochist Gold Badge",
		desc  = "Complete Angel of Masochism (AoMs)",
		level = 3,
	}

	register_badge "masochism4"
	{
		name  = "Masochist Platinum Badge",
		desc  = "Complete AoMs on HMP w/o Bad",
		level = 4,
	}

	register_badge "masochism5"
	{
		name  = "Masochist Diamond Badge",
		desc  = "Complete AoMs on N! w/o Iro/Bad",
		level = 5,
	}

	register_badge "masochism6"
	{
		name  = "Masochist Angelic Badge",
		desc  = "Complete ArchAoMs on N!",
		level = 6,
	}

	register_challenge "challenge_aoms"
	{
		name        = "Angel of Masochism",
		description = "Okay, this one is for masochists -- healing globes, supercharge, and medkits will *not* work on you! As a small compensation you heal up to 200% at level up. Now beat this!",
		rating      = "BLADE",
		rank        = 5,
		abbr        = "AoMs",
		let         = "M",

		arch_name        = "Archangel of Masochism",
		arch_description = "Okay, this one is for TRUE masochists -- healing globes, supercharge, and medkits will *not* work on you! And yeah, no compensation. Now beat THIS!",
		arch_rating      = "BLADE",
		arch_rank        = 6,

		OnCreatePlayer = function ()
			player.inv:clear()
			if CHALLENGE ~= "challenge_aob" then
				if CHALLENGE == "challenge_aosh" then
					player.inv:add( "shell", { amount = 50 } )
				elseif CHALLENGE == "challenge_aopc" then
					player.inv:add( "nuke" )
				else
					player.inv:add( "ammo", { amount = 100 } )
				end
			end
			if player.klass == klasses.technician.nid then
				player.inv:add("mod_tech")
			end
			player.flags[ BF_NOHEAL ] = true
		end,

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.barmor = nil
				level.data.final_reward.rarmor = 1
				level.data.final_reward.lmed = nil
				level.data.final_reward.psboots = 1
			end
		end,
		
		OnLevelUp = function (l)
			if not ARCHANGEL then
				ui.msg("SuperCharge!")
				ui.blink(LIGHTBLUE,100)
				player.hp = 2 * player.hpmax
				player:remove_affect( "tired" )
			end
		end,

		OnPickupCheck = function(item,being)
			if not being:is_player() then return true end
			if item.flags[IF_GLOBE] then
				ui.msg("Nothing happens.")
				return false
			end
			return true
		end,

		OnMortem = function ()
			if player:has_won() then
				player:add_badge("masochism3")
				if DIFFICULTY >= DIFF_HARD and player:get_trait( traits["badass"].nid ) == 0 then player:add_badge("masochism4") end
				if DIFFICULTY >= DIFF_NIGHTMARE and player:get_trait( traits["badass"].nid ) + player:get_trait( traits["ironman"].nid ) == 0 then player:add_badge("masochism5") end
				if ARCHANGEL and DIFFICULTY >= DIFF_NIGHTMARE then player:add_badge("masochism6") end
			end
		end,
	}

-- CHALLENGE 100

	register_medal "dervis"
	{
		name  = "Dervis' Medallion",
		desc  = "Win Angel of 100 on Nightmare!",
		hidden  = true,
	}

	register_badge "century1"
	{
		name  = "Centurial Bronze Badge",
		desc  = "Reach level 16 on Angel of 100",
		level = 1,
	}

	register_badge "century2"
	{
		name  = "Centurial Silver Badge",
		desc  = "Reach level 51 on Angel of 100",
		level = 2,
	}

	register_badge "century3"
	{
		name  = "Centurial Gold Badge",
		desc  = "Complete Angel of 100 (Ao100)",
		level = 3,
	}

	register_badge "century4"
	{
		name  = "Centurial Platinum Badge",
		desc  = "Complete Ao100 on UV",
		level = 4,
	}

	register_badge "century5"
	{
		name  = "Centurial Diamond Badge",
		desc  = "Complete Ao100 on N!",
		level = 5,
	}

	register_badge "century6"
	{
		name  = "Centurial Angelic Badge",
		desc  = "Complete ArchAo666 on N!",
		level = 6,
	}

	register_challenge "challenge_a100"
	{
		name        = "Angel of 100",
		description = "100 levels, and you win. No Cybie, no Spidey, no JC, no special levels, just 100 normal levels. And yes, there are more and more enemies after level 25...",
		rating      = "HARD",
		rank        = 5,
		abbr        = "A100",
		let         = "O",
		removemedals = { "gambler", "aurora", "explorer", "conqueror", "fallout1", "fallout2", "fallout3", "ironskull1" },
		win_mortem    = "completed 100 levels of torture",
		win_highscore = "completed 100 levels",

		arch_name        = "Archangel of 666",
		arch_description = "This one is *not* supposed to be fun. This is just a GRIND. You've been warned.",
		arch_rating      = "BLADE",
		arch_rank        = 7,
		arch_win_mortem    = "completed 666 levels of torture",
		arch_win_highscore = "completed 666 levels",

		OnCreateEpisode = function ()
			local LevCount = 100
			local LevD = 9
			local LevH = 17
			player.episode = {}
			if ARCHANGEL then LevCount = 666 end

			for i=1,LevD - 1 do
				player.episode[i] = { style = table.random_pick{1,5,8}, name = "Phobos L"..tostring(i), danger = i, deathname = "level "..tostring(i).." of the Phobos base" }
			end
			for i=LevD, LevH - 1 do
				player.episode[i] = { style = table.random_pick{2,6}, name = "Deimos L"..tostring(i), danger = i, deathname = "level "..tostring(i).." of the Deimos base" }
			end
			for i=LevH,LevCount-1 do
				if i < 25 then
					player.episode[i] = { style = table.random_pick{3,7}, name = "Hell L"..tostring(i), danger = i, deathname = "level "..tostring(i).." of Hell" }
				else
					local mod_value = {
						{1,5,8},
						{2,6},
						{3,7},
					}
					local list = mod_value[math.floor(i / 5) % 3 + 1]
					player.episode[i] = { style = table.random_pick(list), name = "Beyond L"..tostring(i), danger = i, deathname = "level "..tostring(i).." of Beyond" }
				end
			end

			-- Here is where we can add some Ao100 specific special levels like #88
			player.episode[LevCount] = { style = 3, name = "Hell L"..tostring(LevCount), danger = LevCount*2, deathname = "level "..tostring(LevCount).." of Hell" }
			statistics.bonus_levels_count = 0
		end,

		OnUnLoad = function ()
			drl.OnCreateEpisode()
		end,

		OnEnterLevel = function (l)
			local LevCount = 100
			if ARCHANGEL then LevCount = 666 end

			if l == LevCount and player.eq.armor and player.eq.armor.id == "uberarmor" then
				level.flags[ LF_NOBEINGREVEAL ] = true
				ui.msg_enter("Something is wrong... Something is really wrong here!")
				for b in level:beings() do
					if not b:is_player() then
						b:kill()
					end
				end
				local apostle = level:summon("apostle")
				level:transmute("stairs", "floor")
			end
		end,

		OnExit = function (l)
			    if l == 25 then ui.msg_enter("Well, that was easy. Now starts the really hard part...")
			elseif l == 50 then ui.msg_enter("Halfway there, and it's getting less and less funny!")
			elseif l == 75 then ui.msg_enter("Just 25 more, you can make it!")
			elseif l == 90 then ui.msg_enter("Ten more! Can you really take the heat?")
			elseif l == 99 then ui.msg_enter("Just one more! Just one more! Will you die here?")
			elseif l == 100 then
				ui.msg_enter("You did it! You completed 100 levels of DRL! You're the champion!")
				if ARCHANGEL then
					ui.msg_enter("Or wait... false alarm. Still 566 to go.")
				else
					if DIFFICULTY == DIFF_NIGHTMARE then
						player:add_medal("dervis")
					end
					player:win()
				end
			-- Adding flavour text
			elseif l == 299 then ui.msg_enter("Sparta coming right up.")
			elseif l == 313 then ui.msg_enter("Half-way round a circle.")
			elseif l == 402 then ui.msg_enter("Next floor is forbidden.")
			elseif l == 403 then ui.msg_enter("Next floor is not found.")
			elseif l == 627 then ui.msg_enter("Feel like you have travelled in a circle?")
			elseif l == 666 then
				ui.msg_enter("You're crazy, you know that, right? Hell, congratulations anyway!")
				-- Should we add a medal here?
				player:win()
			end
		end,

		OnWinGame = function ()
			if player.eq.armor and player.eq.armor.id == "uberarmor" then
				drl.plot_outro_special()
				return false
			end
			ui.blood_slide()
			local level_count = 100
			if ARCHANGEL then
			  level_count = 666
			end
			ui.plot_screen(string.gsub([[
You've completed @1 levels of DRL!

You can rest easy knowing that you're Boss. Yet at the last level you sensed something missing... was there something you've not accomplished? The secret of the Dragonslayer and the Berserk Armor is left unsolved...]],
				"@1", tostring(level_count)),RED)
			return false
		end,

		OnMortem = function ()
			if player.level_index >= 16 then player:add_badge("century1") end
			if player.level_index >= 51 then player:add_badge("century2") end
			if player:has_won() then
				player:add_badge("century3")
				if DIFFICULTY >= DIFF_VERYHARD then player:add_badge("century4") end
				if DIFFICULTY >= DIFF_NIGHTMARE then
					if ARCHANGEL then player:add_badge("century6") end
					player:add_badge("century5")
				end
			end
		end,
	}

-- CHALLENGE PACIFISM


	register_badge "pacifism1"
	{
		name  = "Pacifist Bronze Badge",
		desc  = "Reach level 16 on Angel of Pacifism",
		level = 1,
	}

	register_badge "pacifism2"
	{
		name  = "Pacifist Silver Badge",
		desc  = "Complete Angel of Pacifism (AoPc)",
		level = 2,
	}

	register_badge "pacifism3"
	{
		name  = "Pacifist Gold Badge",
		desc  = "Complete AoPc in under 10 minutes",
		level = 3,
	}

	register_badge "pacifism6"
	{
		name  = "Pacifist Angelic Badge",
		desc  = "Complete ArchAoPc game with @<1 kill@>",
		level = 6,
	}

	register_challenge "challenge_aopc"
	{
		name        = "Angel of Pacifism",
		description = "The monsters are beings too! They don't deserve to be killed! It's all the fault of that damn Spider Mastermind, she should be NUKED! You start with a Thermie, and due to your pacifistic beliefs you gain a level every third dungeon level. Of course - *no* weapon usage.",
		rating      = "EASY",
		rank        = 5,
		abbr        = "AoPc",
		let         = "F",
		removemedals = { "zen", "fist", "knives", "experience1", "experience2", "purple", "killfew", "pistols", "shotguns" },
		secondary   = { "AoCn", "AoOC", "A100", "AoI", "AoP", "AoD", "AoMs" },

		arch_name        = "Archangel of Pacifism",
		arch_description = "The monsters are beings too! They don't deserve to be killed! It's all the fault of that damn Spider Mastermind, she should be NUKED! You start with a Thermie, and... that's it -- no freebies for pacifists. Of course - *no* weapon usage.",
		arch_rating      = "BLADE",
		arch_rank        = 7,

		OnCreatePlayer = function ()
			player.inv:clear()
			player.eq:clear()
			player.eq.armor = "barmor"
			player.flags[ BF_STAIRSENSE ] = false
			player.flags[ BF_NOMELEE ] = true
			for i=1,4 do
				player.inv:add( "lmed" )
			end
			player.inv:add( "nuke" )
			if player.klass == klasses.technician.nid then
				player.inv:add("mod_tech")
			end
		end,

		OnEnterLevel = function (l,lid)
			if not ARCHANGEL and l % 3 == 0 and player.explevel < 25 then
				player:level_up()
			end
			if lid == "tower_of_babel" then
				level.map[coord(77,19)] = "stairs"
			end
		end,

		OnFire = function (item,being)
			if not being:is_player() then return true end
			ui.msg("No way! You're a pacifist!")
			return false
		end,

		OnCreateEpisode = function ()
			player.episode[1] = { style = 1, name = "Phobos L1", danger = 2, deathname = "level 1 of the Phobos base" }
		end,

		OnUnLoad = function ()
			drl.OnCreateEpisode()
		end,

		OnMortem = function ()
			if player.level_index >= 16 then player:add_badge("pacifism1") end
			if player:has_won() then
				player:add_badge("pacifism2")
				if statistics.real_time <= 10*60 then
					player:add_badge("pacifism3")
				end
				if ARCHANGEL and statistics.kills == 1 then 
					player:add_badge("pacifism6")
				end
			end
		end,
	}


	register_badge "everyman3"
	{
		name  = "Everyman Gold Badge",
		desc  = "Complete Angel of Humanity (AoHu)",
		level = 3,
	}

	register_badge "everyman4"
	{
		name  = "Everyman Platinum Badge",
		desc  = "Complete AoHu as Conqueror",
		level = 4,
	}

	register_badge "everyman5"
	{
		name  = "Everyman Diamond Badge",
		desc  = "Complete AoHu on UV as Conqueror",
		level = 5,
	}

	register_badge "everyman6"
	{
		name  = "Everyman Angelic Badge",
		desc  = "Complete ArchAoHu on N!",
		level = 6,
	}

	register_medal "thomas"
	{
		name  = "Thomas's Medal",
		desc  = "Win AoHu as Conqueror",
		hidden  = true,
		winonly = true,
	}


	register_challenge "challenge_aohu"
	{
		name        = "Angel of Humanity",
		description = "You're no hero. Try beating the game with a mere 10 HP. Oh, and don't count on Ironman, it will only give you +2 HP per level. To ease your suffering a little, you gain some useful junk at start. Yes, you will get instakilled a lot, go ahead and cry.",
		rating      = "BLADE",
		rank        = 6,
		abbr        = "AoHu",
		let         = "U",
		removemedals = {},
		secondary   = { "AoCn", "AoOC", "A100", "AoI", "AoP", "AoRA", "AoD", "AoMs" },

		arch_name        = "Archangel of Humanity",
		arch_description = "You're no hero. Try beating the game with a mere 10 HP. Oh, and don't count on Ironman, it will only give you +2 HP per level. To ease your suffering a little, you gain some useful junk at start. Actually, traits are so unrealistic, take just one at the start.",
		arch_rating      = "TORMUSE",
		arch_rank        = 9,

		OnCreatePlayer = function ()
			player.hp = player.hp / 5
			player.hpmax = player.hp
			player.hpnom = player.hp
			player.eq.armor = "rarmor"
			for i=1,2 do
				player.inv:add( "lmed" )
			end
			player.inv:add( "mod_agility" )
			player.inv:add( "mod_tech" )
			player.inv:add( "mod_power" )
			player.inv:add( "mod_bulk" )
			if player.klass == klasses.technician.nid then
				player.inv:add("mod_tech")
			end
		end,

		OnEnterLevel = function (l, lid)
			if lid == "hells_arena" then
				level.data.final_reward.barmor = nil
				level.data.final_reward[table.random_pick{"uparmor","uballisticarmor","uacidboots"}] = 1
			end
		end,
		
		OnPreLevelUp = function ()
			return not ARCHANGEL
		end,

		OnMortem = function ()
			if player:has_won() then
				player:add_badge("everyman3")
				if statistics.bonus_levels_completed == statistics.bonus_levels_count then
					player:add_badge("everyman4")
					player:add_medal("thomas")
					if DIFFICULTY >= DIFF_VERYHARD then
						player:add_badge("everyman5")
					end
				end
				if DIFFICULTY >= DIFF_NIGHTMARE and ARCHANGEL then
					player:add_badge("everyman6")
				end
			end
		end,

	}

	register_badge "confident3"
	{
		name  = "Daredevil Gold Badge",
		desc  = "Complete Angel of Overconfidence (AoOC)",
		level = 3,
	}

	register_badge "confident5"
	{
		name  = "Daredevil Diamond Badge",
		desc  = "Complete AoOC on N!/80% kills",
		level = 5,
	}

	register_challenge "challenge_aooc"
	{
		name        = "Angel of Overconfidence",
		description = "Not three episodes, not even two: now we're down to a single count! You were so ready to face the legions of Hell that you were sent directly to their home turf. Good thing you snuck some extra supplies!",
		-- In memory of our best abuser of AoOC
		rating      = "SEREG",
		rank        = 6,
		abbr        = "AoOC",
		let         = "V",
		removemedals = { "icarus1", "icarus2", "explorer", "conqueror", "competn1", "competn2", "competn3", "untouchable1", "untouchable2", "untouchable3" },

		OnCreateEpisode = function ()
			local slevcount = 0
			for i=16,24 do
				if player.episode[i].special then
					slevcount = slevcount + 1
				end
			end
			statistics.bonus_levels_count = slevcount
			player.level_index = 16
		end,

		OnCreatePlayer = function ()
			player.inv:clear()
			player.eq:clear()
			if CHALLENGE == "challenge_aob" then
				player.eq.weapon = "chainsaw"
				player.inv:add( "knife" )
			elseif CHALLENGE == "challenge_aomr" then
				player.eq.weapon = "pistol"
				mod_arrays.speedloader.OnApply(player.eq.weapon)
				player.eq.weapon.color = CYAN
				player.eq.weapon.flags[IF_MODIFIED] = true
				player.inv:add( "pammo" )
			elseif CHALLENGE == "challenge_aosh" then
				player.eq.weapon = "ashotgun"
				player.inv:add( "pshell" )
			elseif CHALLENGE == "challenge_aolt" then
				player.eq.weapon = "pistol"
				mod_arrays.speedloader.OnApply(player.eq.weapon)
				player.eq.weapon.color = CYAN
				player.eq.weapon.flags[IF_MODIFIED] = true
				player.eq.prepared = "pammo"
				player.inv:add( "ashotgun" )
				local cgun = item.new( "chaingun" )
				mod_arrays.high.OnApply( cgun )
				cgun.color = CYAN
				cgun.flags[IF_MODIFIED] = true
				player.inv:add( cgun )
				player.inv:add( "pshell" )
			elseif CHALLENGE == "challenge_aopc" then
			else
				player.eq.weapon = "pistol"
				mod_arrays.speedloader.OnApply(player.eq.weapon)
				player.eq.weapon.color = CYAN
				player.eq.weapon.flags[IF_MODIFIED] = true
				player.inv:add( "ashotgun" )
				local cgun = item.new( "chaingun" )
				mod_arrays.high.OnApply( cgun )
				player.inv:add( cgun )
				cgun.color = CYAN
				cgun.flags[IF_MODIFIED] = true
				player.inv:add( "knife" )
				player.inv:add( "pammo" )
				player.inv:add( "pshell" )
			end
			if CHALLENGE ~= "challenge_aoi" and CHALLENGE ~= "challenge_aoms" then
				player.inv:add( "lmed" )
				player.inv:add( "lmed" )
			end
			if CHALLENGE == "challenge_aohu" then
				player.eq.armor = "rarmor"
				for i=1,2 do
					player.inv:add( "lmed" )
				end
				player.inv:add( "mod_agility" )
				player.inv:add( "mod_tech" )
				player.inv:add( "mod_power" )
				player.inv:add( "mod_bulk" )
			end
			if CHALLENGE ~= "challenge_aoi" then
				if player.klass == klasses.technician.nid then
					player.inv:add("mod_tech")
				end
			end
		end,

		OnMortem = function ()
			if player:has_won() then
				player:add_badge("confident3")
				if statistics.unique_kills >= statistics.max_unique_kills * 0.8 and DIFFICULTY >= DIFF_NIGHTMARE then player:add_badge("confident5") end
			end
		end,

	}

--[[

	register_challenge "challenge_aocq"
	{
		name        = "Angel of Conquest",
		description = "",
		rating      = "BLADE",
		rank        = 5,
		abbr        = "AoCq",
		let         = "Q",
		removemedals = { "gambler", "aurora", "explorer", "conqueror", "fallout1", "fallout2", "fallout3", "ironskull1" },
		win_mortem    = "completed 100 levels of torture",
		win_highscore = "completed 100 levels",

		OnCreateEpisode = function ()
			player.episode = {
				{ script = "intro", style = 1 },
				{ script = "hells_arena", style = 1 },
				{ script = "the_chained_court", style = 1 },
				{ script = table.random_pick{ "military_base","halls_of_carnage" }, style = 1 },
				{ script = "hellgate", style = 1 },
				{ script = "hells_armory", style = 2 },
				{ script = table.random_pick{ "abyssal_plains", "city_of_skulls" }, style = 2 },
				{ script = table.random_pick{ "spiders_lair", "the_wall" }, style = 2 },
				{ script = "tower_of_babel", style = 2 },
				{ script = "unholy_cathedral", style = 3 },
				{ script = table.random_pick{ "house_of_pain", "the_vaults" }, style = 3 },
				{ script = "the_mortuary", style = 3 },
				{ script = table.random_pick{ "the_asmos_den", "the_lava_pits" }, style = 3 },
				{ script = "dis", style = 3 },
			}
		end,

		OnUnLoad = function ()
			drl.OnCreateEpisode()
		end,

		OnMortem = function ()

		end,
	}

	register_badge "haste1"
	{
		name  = "Runner Bronze Badge",
		desc  = "Reach level 8 on Angel of Haste",
		level = 1,
	}

	register_badge "haste2"
	{
		name  = "Runner Silver Badge",
		desc  = "Complete Angel of Haste",
		level = 2,
	}

	register_badge "haste3"
	{
		name  = "Runner Gold Badge",
		desc  = "Complete Angel of Haste on UV/100%",
		level = 3,
	}
	
	register_challenge "challenge_aoh"
	{
		name        = "Angel of Haste",
		description = "DRL is too long, you want to fight your way through, as fast as possible. Half as many levels, twice the danger increase.",
		rating      = "HARD",
		rank        = 4,
		abbr        = "AoH",
		let         = "H",
		removemedals = { "icarus1", "icarus2", "explorer", "conqueror", "competn1", "competn2", "competn3", "untouchable1", "untouchable2", "untouchable3" },

		OnCreateEpisode = function ()
			local LevCount = 15
			local LevH = math.ceil(3*(LevCount-1) / 5)
			player.episode = {}

			for i=1,LevH - 1 do
				player.episode[i] = { style = 1, name = "Phobos L"..tostring(i), danger = i*2, deathname = "level "..tostring(i).." of the Phobos base" }
			end
			for i=LevH,LevCount - 2 do
				player.episode[i] = { style = 2, name = "Phobos Hell L"..tostring(i), danger = i*2, deathname = "level "..tostring(i).." of Phobos Hell" }
			end
			player.episode[LevCount-1] = { script = "tower_of_babel" }
			player.episode[LevCount]   = { script = "hell_fortress" }

			for _,level_proto in pairs(levels) do
				if level_proto.level then
					if not (level_proto.chance and (math.random(100) > level_proto.chance)) then
						local lev = core.resolve_range(level_proto.level)
						if lev % 2 == 0 then
 							local from = player.episode[lev / 2]
							table.insert( player.episode, { 
								script = level_proto.id,
								style  = from.style,
								danger = from.danger,
								name   = level_proto.name,
								exit   = (lev / 2) + 1,
							} )
							from.special = #player.episode
						end
					end
				end
			end
			local SpecLevCount = 0
			for i=2,LevCount-1 do
				if player.episode[i].special then
					SpecLevCount = SpecLevCount + 1
				end
			end
			statistics.bonus_levels_count = SpecLevCount
		end,

		OnMortem = function ()
			if player.level_index >= 8 then player:add_badge("haste1") end
			if player:has_won() then
				player:add_badge("haste2")
				if statistics.unique_kills == statistics.max_unique_kills and DIFFICULTY >= DIFF_VERYHARD then player:add_badge("haste3") end
			end
		end,

	}
--]]

--[[
	register_challenge "challenge_aodd"
	{
		name        = "Angel of D&D",
		description = "You played too many roleplaying games when you were young. Because of that you gain +5 HP each level and +1 toHit every 2 levels. However, you gain a trait only at character creation, and every 4 levels.",
		rating      = "HARD",
		rank        = 4,
		abbr        = "AoDD",
		let         = "N",
		OnPreLevelUp = function (l)
			if l % 4 == 0 then
				ui.blood_slide()
				Player.chooseTrait()
			end
			Player.incStat(STAT_HPMAX,5)
			ui.msg("You gain +5HP!")
			if l % 2 == 0 then
				Player.incStat(STAT_TOHIT,1)
				ui.msg("You gain +1 toHit!")
			end
			ui.msg("You now have "..Player.getStat(STAT_HPMAX).." HP and +"..(Player.getStat(STAT_TOHIT)-10).." toHit!")
			return false
		end,
	}
--]]

--[[
	register_challenge "challenge_aopw"
	{
		name        = "Angel of Power",
		description = "Power Overwhelming! You level up three times as fast! However, the monsters have twice the health...",
		rating      = "HARD",
		rank        = 2,
		abbr        = "AoPw",
		let         = "W",

		OnCreate = function ()
			if not Being.isPlayer() then
				Being.setStat( STAT_EXPVALUE, Being.getStat( STAT_EXPVALUE ) * 3 )
				Being.setStat( STAT_HPMAX,    Being.getStat( STAT_HPMAX )    * 2 )
				Being.setStat( STAT_HP,       Being.getStat( STAT_HP )       * 2 )
			end
		end,
	}
--]]

end
