-- XXX Maximum length for desc is 44 characters (maybe 43)
function drl.register_awards()

	register_badge "technician1"
	{
		name  = "Technician Bronze Badge",
		desc  = "Discover an assembly",
		level = 1,
	}

	register_badge "technician2"
	{
		name  = "Technician Silver Badge",
		desc  = "Discover an advanced assembly",
		level = 2,
	}

	register_badge "technician3"
	{
		name  = "Technician Gold Badge",
		desc  = "Discover {!all} basic assemblies",
		level = 3,
	}

	register_badge "technician4"
	{
		name  = "Technician Platinum Badge",
		desc  = "Discover {!all} advanced assemblies",
		level = 4,
	}

	register_badge "technician5"
	{
		name  = "Technician Diamond Badge",
		desc  = "Discover {!all} assemblies",
		level = 5,
	}

	register_badge "armorer1"
	{
		name  = "Armorer Bronze Badge",
		desc  = "Discover 10 exotics/uniques",
		level = 1,
	}

	register_badge "armorer2"
	{
		name  = "Armorer Silver Badge",
		desc  = "Discover 30 exotics/uniques",
		level = 2,
	}

	register_badge "armorer3"
	{
		name  = "Armorer Gold Badge",
		desc  = "Discover {!all} exotics/uniques",
		level = 3,
	}
	
	register_badge "armorer4"
	{
		name  = "Armorer Platinum Badge",
		desc  = "Find {!1,000} exotics/uniques",
		level = 4,
	}

	register_badge "armorer5"
	{
		name  = "Armorer Diamond Badge",
		desc  = "Find 3 of {!each} exotic/unique",
		level = 5,
	}

	register_badge "heroic1"
	{
		name  = "Heroic Bronze Badge",
		desc  = "Receive 8 unique medals",
		level = 1,
	}

	register_badge "heroic2"
	{
		name  = "Heroic Silver Badge",
		desc  = "Receive 16 unique medals",
		level = 2,
	}

	register_badge "heroic3"
	{
		name  = "Heroic Gold Badge",
		desc  = "Receive 24 unique medals",
		level = 3,
	}

	register_badge "heroic4"
	{
		name  = "Heroic Platinum Badge",
		desc  = "Receive 32 unique medals",
		level = 4,
	}

	register_badge "heroic5"
	{
		name  = "Heroic Diamond Badge",
		desc  = "Receive {!all} medals",
		level = 5,
	}

	-- medals

	register_medal "killall"
	{
		name  = "Medal of Prejudice",
		desc  = "Won with 100% kills",
		winonly = true,
		condition = function() return statistics.unique_kills == statistics.max_unique_kills end,
	}

	register_medal "killfew"
	{
		name  = "Medal of Pacifism",
		desc  = "Won with 10% or less kills",
		winonly = true,
		condition = function() return statistics.unique_kills / statistics.max_unique_kills <= 0.1 end,
	}

	register_medal "shotguns"
	{
		name  = "Shotgunnery Cross",
		desc  = "Won & killed only with shotguns/fists",
		hidden  = true,
		winonly = true,
		condition = function() return kills.get_type( "other" ) + kills.get_type( "melee" ) + core.kills_count_group( "shotgun" ) == statistics.kills end,
	}

	register_medal "pistols"
	{
		name  = "Marksmanship Cross",
		desc  = "Won & killed only with pistols/fists",
		hidden  = true,
		winonly = true,
		condition = function() return kills.get_type( "other" ) + kills.get_type( "melee" ) + core.kills_count_group( "pistol" ) == statistics.kills end,
	}

	register_medal "knives"
	{
		name  = "Malicious Knives Cross",
		desc  = "Won & killed only with knives/fists",
		hidden  = true,
		winonly = true,
		condition = function() return kills.get_type( "other" ) + kills.get_type( "melee" ) + kills.get_type( "knife" ) == statistics.kills end,
	}

	register_medal "fist"
	{
		name  = "Sunrise Iron Fist",
		desc  = "Won & killed only with your bare hands",
		hidden  = true,
		winonly = true,
		removes = { "knives" , "shotguns", "pistols" },
		condition = function() return kills.get_type( "other" ) + kills.get_type( "melee" ) == statistics.kills end,
	}

	register_medal "zen"
	{
		name  = "Zen Master's Cross",
		desc  = "Won & killed w/o using fists/weapons",
		hidden  = true,
		winonly = true,
		removes = { "fist" , "knives" , "shotguns", "pistols" },
		condition = function() return kills.get_type( "other" ) == statistics.kills end,
	}

	register_medal "uac1"
	{
		name  = "UAC Star (bronze cluster)",
		desc  = "25+ kills without taking damage",
		condition = function() return statistics.kills_non_damage >= 25 end,
	}

	register_medal "uac2"
	{
		name  = "UAC Star (silver cluster)",
		desc  = "50+ kills without taking damage",
		removes = { "uac1" },
		condition = function() return statistics.kills_non_damage >= 50 end,
	}

	register_medal "uac3"
	{
		name  = "UAC Star (gold cluster)",
		desc  = "100+ kills without taking damage",
		removes = { "uac1", "uac2" },
		condition = function() return statistics.kills_non_damage >= 100 end,
	}

	register_medal "icarus1"
	{
		name  = "Minor Icarus Cross",
		desc  = "Won the game in less than 40,000 turns",
		winonly = true,
		condition = function() return statistics.game_time < 40000 end,
	}

	register_medal "icarus2"
	{
		name  = "Major Icarus Cross",
		desc  = "Won the game in less than 20,000 turns",
		winonly = true,
		removes = { "icarus1" },
		condition = function() return statistics.game_time < 20000 end,
	}

	register_medal "gambler"
	{
		name  = "Gambler's Shield",
		desc  = "Pulled at least 25 levers in one game",
		condition = function() return statistics.levers_pulled > 24 end,
	}

	register_medal "aurora"
	{
		name  = "Aurora Medallion",
		desc  = "Found more than 3 uniques in one game",
		condition = function() return statistics.uniques_found > 3 end,
	}

	register_medal "explorer"
	{
		name  = "Explorer Pin",
		desc  = "Visited all generated levels",
		condition = function() return statistics.bonus_levels_count > 0 and statistics.bonus_levels_visited == statistics.bonus_levels_count end,
	}

	register_medal "conqueror"
	{
		name  = "Conqueror Pin",
		desc  = "Completed all generated levels",
		removes = { "explorer" },
		condition = function() return statistics.bonus_levels_count > 0 and statistics.bonus_levels_completed == statistics.bonus_levels_count end,
	}

	register_medal "competn1"
	{
		name  = "Compet-n Silver Cross",
		desc  = "Won the game in under 30 minutes",
		winonly = true,
		condition = function() return statistics.real_time < 30*60 end,
	}

	register_medal "competn2"
	{
		name  = "Compet-n Gold Cross",
		desc  = "Won the game in under 20 minutes",
		winonly = true,
		removes = { "competn1" },
		condition = function() return statistics.real_time < 20*60 end,
	}

	register_medal "competn3"
	{
		name  = "Compet-n Platinum Cross",
		desc  = "Won the game in under 10 minutes",
		winonly = true,
		removes = { "competn1", "competn2" },
		condition = function() return statistics.real_time < 10*60 end,
	}

	register_medal "fallout1"
	{
		name  = "Fallout Gold Cross",
		desc  = "Nuked at least 3 levels in one game",
		hidden  = true,
		condition = function() return statistics.levels_nuked >= 3 end,
	}

	register_medal "fallout2"
	{
		name  = "Fallout Platinum Cross",
		desc  = "Nuked at least 6 levels in one game",
		hidden  = true,
		removes = { "fallout1" },
		condition = function() return statistics.levels_nuked >= 6 end,
	}

	register_medal "fallout3"
	{
		name  = "Klear Cross",
		desc  = "Nuked at least 12 levels in one game",
		hidden  = true,
		removes = { "fallout1", "fallout2" },
		condition = function() return statistics.levels_nuked >= 12 end,
	}


	register_medal "ironskull1"
	{
		name  = "Iron Skull",
		desc  = "Took 5,000+ damage in one game",
		hidden  = true,
		condition = function() return statistics.damage_taken >= 5000 end,
	}

	register_medal "untouchable1"
	{
		name  = "Untouchable Pin",
		desc  = "Won taking less than 500 damage",
		winonly = true,
		condition = function() return statistics.damage_taken < 500 end,
	}

	register_medal "untouchable2"
	{
		name  = "Untouchable Medal",
		desc  = "Won taking less than 200 damage",
		hidden  = true,
		winonly = true,
		removes = { "untouchable1" },
		condition = function() return statistics.damage_taken < 200 end,
	}

	register_medal "untouchable3"
	{
		name  = "Untouchable Cross",
		desc  = "Won taking less than 50 damage",
		hidden  = true,
		winonly = true,
		removes = { "untouchable1", "untouchable2" },
		condition = function() return statistics.damage_taken < 50 end,
	}

	register_medal "experience1"
	{
		name  = "Experience Medal",
		desc  = "Reach experience level 20+",
		condition = function() return player.explevel >= 20 end,
	}

	register_medal "experience2"
	{
		name  = "Experience Cross",
		desc  = "Reach experience level 25",
		removes = { "experience1" },
		condition = function() return player.explevel >= 25 end,
	}

	-- Because it is ridiculous to die when you are past level 20
	register_medal "purple"
	{
		name  = "Purple Heart",
		desc  = "Reach experience level 20+ and die",
		hidden = true,
		condition = function() return player.explevel >= 20 and player.hp <= 0 end,
	}

  -- Below not implemented! --

--register_medal "survivor"
--{
--	name  = "Twilight Heart",
--	desc  = "Being near death, but making it through.",
--}

-- <action> [on <difficulty>][<special conditions>] (for badges)

	register_badge "buac1"
	{
		name  = "UAC Bronze Badge",
		desc  = "Win {!standard} game on any difficulty",
		level = 1,
		requirements =
		{
			winonly   = true,
			challenge = "",
		},
	}

	register_badge "buac2"
	{
		name  = "UAC Silver Badge",
		desc  = "Win {!standard} game on Hurt Me Plenty",
		level = 2,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_HARD,
		},
	}

	register_badge "buac3"
	{
		name  = "UAC Gold Badge",
		desc  = "Win {!standard} game on Ultra-Violence",
		level = 3,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_VERYHARD,
		},
	}

	register_badge "buac4"
	{
		name  = "UAC Platinum Badge",
		desc  = "Win {!standard} game on N!",
		level = 4,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
		},
	}

	register_badge "buac5"
	{
		name  = "UAC Diamond Badge",
		desc  = "Win {!standard} N! game under 20 min",
		level = 5,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			condition  = function() return statistics.real_time <= 20*60 end,
		},
	}

	register_badge "buac6"
	{
		name  = "UAC Angelic Badge",
		desc  = "Win {!standard} N! damageless",
		level = 6,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			condition  = function() return statistics.damage_taken == 0 end,
		},
	}

-- VETERAN

	register_badge "veteran1"
	{
		name  = "Veteran Bronze Badge",
		desc  = "Win game on any difficulty w/100% kills",
		level = 1,
		requirements =
		{
			winonly = true,
			kills   = 1.0,
		},
	}

	register_badge "veteran2"
	{
		name  = "Veteran Silver Badge",
		desc  = "Win game on Hurt Me Plenty w/100% kills",
		level = 2,
		requirements =
		{
			winonly    = true,
			difficulty = DIFF_HARD,
			kills      = 1.0,
		},
	}

	register_badge "veteran3"
	{
		name  = "Veteran Gold Badge",
		desc  = "Win game on UV/100% kills",
		level = 3,
		requirements =
		{
			winonly    = true,
			difficulty = DIFF_VERYHARD,
			kills      = 1.0,
		},
	}

	register_badge "veteran4"
	{
		name  = "Veteran Platinum Badge",
		desc  = "Fully win the game on UV",
		level = 4,
		requirements =
		{
			winonly    = true,
			difficulty = DIFF_VERYHARD,
			condition  = function() return kills.get("jc") > 0 and player.hp > 0 end,
		},
	}

	register_badge "veteran5"
	{
		name  = "Veteran Diamond Badge",
		desc  = "Fully win the game on N!",
		level = 5,
		requirements =
		{
			winonly    = true,
			difficulty = DIFF_NIGHTMARE,
			condition  = function() return kills.get("jc") > 0 and player.hp > 0 end,
		},
	}

	register_badge "veteran6"
	{
		name  = "Veteran Angelic Badge",
		desc  = "Fully win on N!/100%",
		level = 6,
		requirements =
		{
			winonly    = true,
			difficulty = DIFF_NIGHTMARE,
			kills      = 1.0,
			condition  = function() return kills.get("jc") > 0 and player.hp > 0 end,
		},
	}

-- STRONGMAN

	register_badge "strongman1"
	{
		name  = "Strongman Bronze Badge",
		desc  = "Win {!standard} game using basic melee weapons",
		level = 1,
		requirements =
		{
			winonly   = true,
			challenge = "",
			condition = function()
				return kills.get_type( "other" ) + kills.get_type( "melee" ) +
					kills.get_type( "knife" ) + kills.get_type( "chainsaw" ) == statistics.kills
			end,
		},
	}

	register_badge "strongman2"
	{
		name  = "Strongman Silver Badge",
		desc  = "Win {!standard} game using knives/fists",
		level = 2,
		requirements =
		{
			winonly   = true,
			challenge = "",
			condition = function()
				return kills.get_type( "other" ) + kills.get_type( "melee" ) + kills.get_type( "knife" ) == statistics.kills
			end,
		},
	}

	register_badge "strongman3"
	{
		name  = "Strongman Gold Badge",
		desc  = "Win {!standard} game using knives/fists HMP",
		level = 3,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_HARD,
			condition  = function()
				return kills.get_type( "other" ) + kills.get_type( "melee" ) + kills.get_type( "knife" ) == statistics.kills
			end,
		},
	}

	register_badge "strongman4"
	{
		name  = "Strongman Platinum Badge",
		desc  = "Win {!standard} game using only fists HMP",
		level = 4,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_HARD,
			condition  = function()
				return kills.get_type( "other" ) + kills.get_type( "melee" ) == statistics.kills
			end,
		},
	}

	register_badge "strongman5"
	{
		name  = "Strongman Diamond Badge",
		desc  = "Win {!standard} game fist-only HMP/100% kills",
		level = 5,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_HARD,
			kills      = 1.0,
			condition  = function() return kills.get_type( "other" ) + kills.get_type( "melee" ) == statistics.kills end,
		},
	}

	register_badge "strongman6"
	{
		name  = "Strongman Angelic Badge",
		desc  = "Win {!standard} game fist-only N!/90% kills",
		level = 6,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			kills      = 0.9,
			condition  = function() return kills.get_type( "other" ) + kills.get_type( "melee" ) == statistics.kills end,
		},
	}

-- SPEEDRUNNER

	register_badge "speedrunner1"
	{
		name  = "Speedrunner Bronze Badge",
		desc  = "Win {!standard} game under 30 minutes",
		level = 1,
		requirements =
		{
			winonly   = true,
			challenge = "",
			condition = function() return statistics.real_time <= 30*60 end,
		},
	}

	register_badge "speedrunner2"
	{
		name  = "Speedrunner Silver Badge",
		desc  = "Win {!standard} HNTR game under 25 minutes",
		level = 2,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_MEDIUM,
			condition  = function() return statistics.real_time <= 25*60 end,
		},
	}

	register_badge "speedrunner3"
	{
		name  = "Speedrunner Gold Badge",
		desc  = "Win {!standard} HMP game under 20 minutes",
		level = 3,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_HARD,
			condition  = function() return statistics.real_time <= 20*60 end,
		},
	}
--[[

	register_badge "speedrunner4"
	{
		name  = "Speedrunner Platinum Badge",
		desc  = "Win AoHaste HMP+ game under 10 minutes",
		level = 4,
	}

	register_badge "speedrunner5"
	{
		name  = "Speedrunner Diamond Badge",
		desc  = "Win AoHaste N! game under 10 minutes",
		level = 5,
	}
--]]

	register_badge "speedrunner6"
	{
		name  = "Speedrunner Angelic Badge",
		desc  = "Win {!standard} N! game under 4 minutes",
		level = 6,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			condition  = function() return statistics.real_time <= 4*60 end,
		},
	}

-- ELITE

	register_badge "elite4"
	{
		name  = "Elite Platinum Badge",
		desc  = "Win {!standard} UV game as Conqueror",
		level = 4,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_VERYHARD,
			condition  = function() return statistics.bonus_levels_completed == statistics.bonus_levels_count end,
		},
	}

	register_badge "elite5"
	{
		name  = "Elite Diamond Badge",
		desc  = "Win {!standard} N!/90% kills",
		level = 5,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			kills      = 0.9,
		},
	}

	register_badge "elite6"
	{
		name  = "Elite Angelic Badge",
		desc  = "Win {!standard} N!/100% as Conqueror",
		level = 6,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			kills      = 1.0,
			condition  = function() return statistics.bonus_levels_completed == statistics.bonus_levels_count end,
		},
	}

-- Demonic

	register_badge "demonic4"
	{
		name  = "Demonic Platinum Badge",
		desc  = "Win {!standard} N! as Explorer",
		level = 4,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			condition  = function() return statistics.bonus_levels_visited == statistics.bonus_levels_count end,
		},
	}

	register_badge "demonic5"
	{
		name  = "Demonic Diamond Badge",
		desc  = "Win {!standard} N! with Untouchable Medal",
		level = 5,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			condition  = function() return statistics.damage_taken < 200 end,
		},
	}

	register_badge "demonic6"
	{
		name  = "Demonic Angelic Badge",
		desc  = "Win {!standard} N!/100% damageless",
		level = 6,
		requirements =
		{
			winonly    = true,
			challenge  = "",
			difficulty = DIFF_NIGHTMARE,
			kills      = 1.0,
			condition  = function() return statistics.damage_taken == 0 end,
		},
	}

-- Common special level

	register_badge "lava1"
	{
		name  = "Lava Bronze Badge",
		desc  = "Clear the Lava Pits/Mt. Erebus",
		level = 1,
	}

	register_badge "lava2"
	{
		name  = "Lava Silver Badge",
		desc  = "Clear the Lava Pits/Mt. Erebus on AoI",
		level = 2,
	}

	register_medal "mortuary"
	{
		name = "Grim Reaper's Pin",
		desc = "Clear the Mortuary/Limbo",
		hidden  = true,
	}

	register_medal "mortuary2"
	{
		name = "Angelic Pin",
		desc = "Clear the Mortuary/Limbo w/o taking damage",
		hidden  = true,
		removes = { "mortuary" },
	}

	register_badge "reaper1"
	{
		name  = "Reaper Bronze Badge",
		desc  = "Enter the Mortuary/Limbo",
		level = 1,
	}

	register_badge "reaper2"
	{
		name  = "Reaper Silver Badge",
		desc  = "Enter the Mortuary/Limbo and exit alive",
		level = 2,
	}

	register_badge "reaper3"
	{
		name  = "Reaper Gold Badge",
		desc  = "Complete the Mortuary/Limbo",
		level = 3,
	}

	register_badge "reaper4"
	{
		name  = "Reaper Platinum Badge",
		desc  = "Complete the Mortuary/Limbo on N!",
		level = 4,
	}

	register_badge "reaper5"
	{
		name  = "Reaper Diamond Badge",
		desc  = "Complete the Mortuary/Limbo on N! AoCn",
		level = 5,
	}

	register_medal "armory1"
	{
		name = "Hell Armorer Pin",
		desc = "Clear Hell's Armory/Deimos Lab",
		hidden  = true,
	}

	register_medal "armory2"
	{
		name = "Shambler's Head",
		desc = "Clear Hell's Armory/Deimos Lab w/o taking damage",
		hidden  = true,
		removes = { "armory1" },
	}

	register_badge "wall1"
	{
		name  = "Brick Bronze Badge",
		desc  = "Clear The Wall/Containment Area",
		level = 1,
	}

	register_badge "wall2"
	{
		name  = "Brick Silver Badge",
		desc  = "Clear The Wall/Containment on AoB/AoMr/AoSh",
		level = 2,
	}

	register_medal "everysoldier"
	{
		name = "Every Soldier's Medal",
		desc = "Clear The Wall/Containment Area on AoHu",
		hidden  = true,
	}

	register_badge "skull1"
	{
		name  = "Skull Bronze Badge",
		desc  = "Clear City of Skulls/Abyssal Plains",
		level = 1,
	}

	register_badge "skull2"
	{
		name  = "Skull Silver Badge",
		desc  = "Clear City of Skulls/Abyssal Plains on AoRA",
		level = 2,
	}

end

function drl.award_badges()
	for _,badge in ipairs( badges ) do
		if badge.requirements and ( badge.challenge == "" or core.is_challenge( badge.challenge ) ) and
			core.check_badge_conditions( badge.requirements )
		then
			player:add_badge( badge.id )
		end
	end

	if player:has_won() and CHALLENGE == "" then
		player:set_achievement("drl_legacy_2")
		if DIFFICULTY >= DIFF_HARD then
			player:set_achievement("drl_legacy_3")
		end
	end
end

function drl.award_global_badges()
	local medals_max = medals.__counter
	local medals     = player_data.child_count('player/medals')

	if medals >= 8          then player:add_badge("heroic1") end
	if medals >= 16         then player:add_badge("heroic2") end
	if medals >= 24         then player:add_badge("heroic3") end
	if medals >= 32         then player:add_badge("heroic4") end
	if medals >= medals_max then player:add_badge("heroic5") end

	local uniques_max    = 0
	local uniques_triple = 0
	local uniques        = player_data.child_count('player/uniques')

	for _,v in ipairs(items) do
		if v.is_unique or v.is_exotic then
			uniques_max = uniques_max + 1
			uniques_triple = uniques_triple + math.min( 3, player_data.count('player/uniques/unique[@id="'..v.id..'"]') )
		end
	end

	if uniques >= 10                               then player:add_badge("armorer1") end
	if uniques >= 30                               then player:add_badge("armorer2") end
	if uniques >= uniques_max                      then player:add_badge("armorer3") end
	if player_data.count('player/uniques') >= 1000 then player:add_badge("armorer4") end
	if uniques_triple >= uniques_max * 3           then player:add_badge("armorer5") end

	local amb_found  = { 0, 0, 0 }
 	local amb_max    = { 0, 0, 0 }

	for _,v in ipairs(mod_arrays) do
		amb_max[v.level+1] = amb_max[v.level+1] + 1
		if player_data.count('player/assemblies/assembly[@id="'..v.id..'"]') > 0 then
			amb_found[v.level+1] = amb_found[v.level+1] + 1
		end
	end

	local amb_total     = amb_found[1] + amb_found[2] + amb_found[3]
	local amb_total_max = amb_max[1]   + amb_max[2]   + amb_max[3]

	if amb_total > 0                 then player:add_badge("technician1") end
	if amb_found[2]+amb_found[3] > 0 then player:add_badge("technician2") end
	if amb_found[1] >= amb_max[1]    then player:add_badge("technician3") end
	if amb_found[2] >= amb_max[2]    then player:add_badge("technician4") end
	if amb_total >= amb_total_max    then player:add_badge("technician5") end
end

function drl.RunAwards( no_record )
	core.award_medals()
	drl.award_badges()
	core.update_player_awards()
	if no_record then return end
	core.update_player_data()
	drl.award_global_badges()
	core.update_player_badges()
end
