-- THE MORTUARY ---------------------------------------------------------

register_level "the_mortuary"
{
	name  = "The Mortuary",
	entry = "On @1 he was foolish enough to enter the Mortuary!",
	level = 20,
	welcome = "You enter the Mortuary.",

	canGenerate = function ()
	return DIFFICULTY > 1
	end,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "rwall" )
		level:fill( "floor", area.FULL_SHRINKED )
		generator.set_blood( area.FULL_SHRINKED, true )

		local translation = {
			['.'] = { "floor", flags = { LFBLOOD } },
			['>'] = "stairs",
			['X'] = "rwall",
			['1'] = { "floor", flags = { LFBLOOD }, item = "lmed" },
			['2'] = { "floor", flags = { LFBLOOD }, item = "scglobe" },
			['3'] = { "floor", flags = { LFBLOOD }, item = "rarmor" },
			['4'] = { "floor", flags = { LFBLOOD }, item = "ashard" },
		}

		local tile = [[
X.X.X
..1..
X2>3X
..4..
X.X.X
]]
		local center = [[
XX.XX
X3.2X
.....
X2.3X
XX.XX
]]

		generator.place_tile( translation, tile, 2, 2 )
		generator.place_tile( translation, tile, 2, 15 )
		generator.place_tile( translation, tile, 73, 2 )
		generator.place_tile( translation, tile, 73, 15 )

		level:drop_item( "mod_power", coord(3, 3) )
		level:drop_item( "mod_bulk",  coord(76, 18) )
		level:drop_item( "unbfg9000", coord(76, 3) )
		level:drop_item( "uashotgun", coord(3, 18) )

		generator.place_tile( translation, center, 36,8 )

		local corpses = {
			"former",  "sergeant", "captain", "imp",      "demon",    "cacodemon",
			"baron",   "knight",   "arachno", "commando", "mancubus", "revenant"
		}

		for cnt = 1,DIFFICULTY+25 do
			local corpse = corpses[math.random(7+DIFFICULTY)].."corpse";
			generator.scatter(area.FULL_SHRINKED,"floor",corpse,math.random(10)+4)
		end

		level:player(38,10)
	end,

	OnEnterLevel = function ()
		ui.msg_feel("The smell of blood! Can this be real?? The floor is")
		ui.msg_feel("covered in blood, and there are corpses everywhere!")

		level.status = 0
		ui.msg_feel("Suddenly with a wail, arch-viles appear!")
		level:summon("arch",3+DIFFICULTY)
		player:add_badge("reaper1")
	end,

	OnKillAll = function ()
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
			ui.msg("As you descend the stairs you hear a wail. They're back...")
			ui.msg("There's only one way to end this...")
			core.special_complete()
			player:add_history("He managed to clear the Mortuary from evil!")
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
			player:add_history("He managed to escape from the Mortuary!")
			player:add_badge("reaper2")
		end
	end,

}
