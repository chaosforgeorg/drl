-- LAVA PITS ------------------------------------------------------------

register_level "the_lava_pits"
{
	name  = "The Lava Pits",
	entry = "On @1 he entered the Lava Pits.",
	welcome = "You descend into the Lava Pits. Dammit, it's hot in here!",
	level = 22,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "lava" )

		local lavapits_armor = {
			level      = 25,
			type       = {ITEMTYPE_ARMOR,ITEMTYPE_BOOTS},
			weights    = { is_unique = 5, ulavaarmor = 3 }, -- multiplicative!
		}

		local translation = {
			['.'] = "floor",
			['='] = "lava",
			['>'] = "stairs",

			['/'] = { "floor", item = "shell" },
			['|'] = { "floor", item = "cell" },
			['-'] = { "floor", item = "rocket" },
			['!'] = { "floor", item = "epack" },
			['?'] = { "floor", item = core.ifdiff( 3, nil, "epack" ) },
			['*'] = { "floor", item = core.ifdiff( 4, nil, "epack" ) },

			['A'] = { "floor", being = core.bydiff{ "sergeant", "knight", "mancubus", "revenant" } },

			['1'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['2'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['3'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['4'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['5'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['6'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['7'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['8'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['9'] = { "floor", item = level:roll_item( lavapits_armor ) },
			['0'] = { "floor", item = level:roll_item( lavapits_armor ) },
		}

		local map = [=[
============================================================================
============================================================================
==========================A./==============================!8.==============
=========================...-.======================/.=====.A.==============
=========================...|.=====================..-.=====================
==========================...=======================..============...=======
===========================.=====================================...0.======
==...======================A============================...=======...=======
=.....=====================.===========================../|.================
=..>..=====================.=============...============...============.|.==
=.....=====================.============.....==========================./.==
==...======================A============..A..===============================
===========================.=============...========../===========...A======
==========================...======================..A..=========.....?=====
=========================...|.======================..-===========.A7534====
=========================...-.===============..====================*621=====
==========================A./================.9=============================
============================================================================
]=]
		generator.place_tile( translation, map, 2, 2 )

		local second = core.bydiff{ "lostsoul", "cacodemon", "cacodemon", "pain" }		
		level:summon{ "lostsoul", 14 + 2*DIFFICULTY, cell = "lava" }
		level:summon{ second,     5  +   DIFFICULTY, cell = "lava" }

		level:player(4,11)
		level.status = 0
	end,

	OnKillAll = function ()
		local result = level.status
		if result == 0 then
			ui.msg("That seems to be all of them... wait! Something is moving there, or is it just lava glow?")
			level.status = 1
			local element = level:summon("lava_elemental")
			element.inv:add( item.new("lava_element") )
		elseif result == 1 then
			ui.msg("Tough son of a bitch... now to get that shiny object he left behind...")
			level.status = 2
		end
	end,

	OnExit = function ()
		local result = level.status
		if result == 0 then
			ui.msg("Too hot dammit, I'm leaving this party...")
			player:add_history("He decided it was too hot there.")
		elseif result == 1 then
			ui.msg("There goes my beard... at least I'm still alive.")
			player:add_history("He fled there from the monstrous lava elemental.")
		elseif result == 2 then
			core.special_complete()
			ui.msg("Lava elementals my ass. I don't care.")
			player:add_badge("lava1")
			if core.is_challenge("challenge_aoi") then player:add_badge("lava2") end
			player:add_history("He managed to clear the Lava Pits completely!")
		end
	end,
}
