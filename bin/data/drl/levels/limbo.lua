-- LIMBO ----------------------------------------------------------------

register_level "limbo"
{
	name  = "Limbo",
	entry = "On @1 he was foolish enough to enter Limbo!",
	level = 20,
	welcome = "You arrive at Limbo.",

	canGenerate = function ()
		return DIFFICULTY > 1
	end,

	OnRegister = function ()
		register_item "lever_limbow"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY, IF_FEATURENAME },

			good = "neutral",
			desc = "raises the bridges",

			color_id = false,
			sound_id = "lever",

			OnUse = function(self,being)
				level:transmute_by_flag( "blood", "bridge", LFMARKER1, area.FULL)
				ui.msg("The west bridges rise!")
				level:recalc_fluids()
				return true
			end,

			OnDescribe = item.get_lever_description,
		}

		register_item "lever_limboe"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY, IF_FEATURENAME },

			good = "neutral",
			desc = "raises the bridges",

			color_id = false,
			sound_id = "lever",

			OnUse = function(self,being)
				level:transmute_by_flag( "blood", "bridge", LFMARKER2, area.FULL)
				ui.msg("The east bridges rise!")
				level:recalc_fluids()
				return true
			end,

			OnDescribe = item.get_lever_description,
		}
	end,


	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "blood" )

		local translation = {
			['.'] = "floor",
			['='] = "blood",
			['>'] = "stairs",
			[','] = "bridge",
			['>'] = "stairs",
			['X'] = "gwall",
			['#'] = "rwall",
			['w'] = { "blood", flags = { LFMARKER1 } },
			['e'] = { "blood", flags = { LFMARKER2 } },
			['W'] = { "floor", item = "lever_limbow" },
			['E'] = { "floor", item = "lever_limboe" },
			['1'] = { "floor", flags = { LFBLOOD }, item = "lmed" },
			['2'] = { "floor", flags = { LFBLOOD }, item = "scglobe" },
			['3'] = { "floor", flags = { LFBLOOD }, item = "rarmor" },
			['4'] = { "floor", flags = { LFBLOOD }, item = "ashard" },
		}

		local map = [=[
============================================================================
=.24..=====================....==============....=====================..12.=
=1>XX.=======....==========.W..,,,,,,,,,,,,,,..E.==========....=======.XX>3=
=3XXX.======......=========....,,,,,,,,,,,,,,....=========......======.XXX4=
=.XXX.======......=========....======,,======....=========......======.XXX.=
=.....======......==========,,=======,,=======,,==========......======.....=
==www========....===========,,====XX=,,=XX====,,===========....========eee==
==www=========ww============,,====XX3..2XX====,,============ee=========eee==
==wwwwwwwwwwwwwwwwwwwwwwwwww,,,,,,,......,,,,,,,eeeeeeeeeeeeeeeeeeeeeeeeee==
==wwwwwwwwwwwwwwwwwwwwwwwwww,,,,,,,......,,,,,,,eeeeeeeeeeeeeeeeeeeeeeeeee==
==www=========ww============,,====XX2..3XX====,,============ee=========eee==
==www========....===========,,====XX=,,=XX====,,===========....========eee==
=.....======......==========,,=======,,=======,,==========......======.....=
=.XXX.======......=========....======,,======....=========......======.XXX.=
=1XXX.======......=========....,,,,,,,,,,,,,,....=========......======.XXX4=
=2>XX.=======....==========.W..,,,,,,,,,,,,,,..E.==========....=======.XX>3=
=.34..=====================....==============....=====================..12.=
============================================================================
]=]
		generator.place_tile( translation, map, 2, 2 )

		level:drop_item( "mod_power", coord(3, 3) )
		level:drop_item( "mod_bulk",  coord(76, 18) )
		level:drop_item( "unbfg9000", coord(76, 3) )
		level:drop_item( "uashotgun", coord(3, 18) )

		local corpses = {
			"imp", "cacodemon", "baron", "knight", "arachno", "mancubus",
			"revenant", "ndemon", "ncacodemon", "nimp", "narachno", "bruiser", "bruiser",
		}

		for cnt = 1,5*DIFFICULTY+60 do
			local corpse = corpses[math.random(6+DIFFICULTY)].."corpse";
			generator.scatter(area.FULL_SHRINKED,"floor",corpse,math.random(10)+4)
		end

		level:player(38,10)
	end,

	OnEnterLevel = function ()
		ui.msg_feel("The smell of blood! You can barely believe this living hell...")
		level.status = 0
		ui.msg_feel("Suddenly with a wail, arch-viles appear!")
		level:summon("arch",3 + 2 * DIFFICULTY )
		player:add_badge("reaper1")
	end,

	OnKillAll = function ()
		--Unlike Erebus, if you nuke this level you still need to pull the levers to raise the bridges
		if level.status == 0 then
			ui.msg("Suddenly everything is peaceful. Rest in peace, damned souls...")

			level.status = 1

			if player:has_medal("hellchampion3") then
				ui.msg_enter( "A presence! Of something cursed. How could that be?")
				level:drop( "uberarmor" )
			else
				ui.msg_enter( "A presence! Of something holy! Here in this hell?")
				level:drop( "aarmor" )
			end

			ui.msg("Find it under the corpses!")
		end
	end,

	OnExit = function ()
		if level.status == 1 then
			core.special_complete()
			ui.msg("As you descend the stairs you hear a wail. They're back...")
			ui.msg("There's only one way to end this...")
			player:add_history("He managed to clear Limbo from evil!")
			player:add_medal("mortuary")
			player:add_badge("reaper2")
			if not level.flags[ LF_NUKED ] then
				if statistics.damage_on_level == 0 then
					player:add_medal("mortuary2")
					if player_data.count('player/medals/medal[@id="mortuary"]') > 0 then
						player:remove_medal("mortuary")
					end
				end
				player:add_badge("reaper3")
				if DIFFICULTY == DIFF_NIGHTMARE then
					player:add_badge("reaper4")
					if core.is_challenge("challenge_aocn") then player:add_badge("reaper5") end
				end
			end
		else
			ui.msg("You flee! You flee like hell from this cursed place!")
			player:add_history("He managed to escape from Limbo!")
			player:add_badge("reaper2")
		end
	end,

}
