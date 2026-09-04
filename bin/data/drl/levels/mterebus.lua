-- MT. EREBUS -----------------------------------------------------------

register_level "mt_erebus"
{
	name    = "Mt. Erebus",
	entry   = "On @1 he arrived at Mt. Erebus.",
	welcome = "You arrive at Mt. Erebus. You shiver before the mountain of eternal fire!",
	level   = 22,

	runtime = {
		OnTick = function ( self )
			local newStatus = 0
			local msg
	--		ui.msg( level.status )
	--		if level.data.zoneReset:contains( player.position ) then level:transmute("floor", "cwall", level.data.zoneOfEffect)
	--		    level.status = 0
	--			return
	--		end
			if self.status > 2 then return end
			if self.status < 3 and self.data.zone3:contains( player.position ) then
				if newStatus == 0 then
					msg = "The molten cliffs give way leaving you tremendously exposed."
					newStatus = 3
				end
				self:transmute_by_flag( "cwall", "floor", LFMARKER3, self.data.mountain)
			end
			if self.status < 2 and self.data.zone2:contains( player.position ) then
				if newStatus == 0 then
					msg = "A violent earthquake shakes your being."
					newStatus = 2
				end
				self:transmute_by_flag( "cwall", "floor", LFMARKER2, self.data.mountain)
				newStatus = 2
			end
			if self.status < 1 and (self.data.zone1a:contains( player.position ) or self.data.zone1b:contains( player.position )) then
				if newStatus == 0 then
					msg = "The safety of the earth dissolves in front of you."
					newStatus = 1
				end
				self:transmute_by_flag( "cwall", "floor", LFMARKER1, self.data.mountain)
			end
			if newStatus == 0 then return false end
			ui.msg( msg )
			self.status = newStatus
			return true
		end,

		OnKillAll = function ( self )
			local result = self.status
			if result < 4 then
				ui.msg("That seems to be all of them... wait! Something is moving there, or is it just lava glow?")
				--In the event of a nuke disable the need to open up the walls (unlike Limbo).
				--This inconsistency is partly due to historical reasons but also because the spawning of the elemental shouldn'can't be behind a wall.
				--However the elemental is killed immediately in practice because it appears at the end of the monster list.
				self:transmute( "cwall", "floor", self.data.mountain )
				self.status = 4
				local element = self:summon("lava_elemental")
				element.inv:add( item.new("lava_element") )
			elseif result == 4 then
				ui.msg("Tough son of a bitch... now to get that shiny object he left behind...")
				self.status = 5
			end
		end,

		OnExitLevel = function ( self )
			local result = self.status
			if result < 4 then
				ui.msg("Better leave, before this thing blows!")
				player:add_history("He decided it was too dangerous.")
			elseif result == 4 then
				ui.msg("There goes my beard... at least I'm still alive.")
				player:add_history("He fled there from the monstrous lava elemental.")
			elseif result == 5 then
				core.special_complete()
				ui.msg("Lava elementals my ass. I don't care.")
				player:add_badge("lava1")
				if core.is_challenge("challenge_aoi") then player:add_badge("lava2") end
				player:add_history("He managed to raise Mt. Erebus completely!")
			end
		end,
	},

	OnRegister = function ()
		register_item "lever_erebus"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY, IF_FEATURENAME },

			good = "dangerous",
			desc = "raises the mountain",

			color_id = false,

			OnUse = function(self,being)
				statistics.levers_pulled = statistics.levers_pulled + 1
				--Levers will always trigger the next status.
				--So if someone relocates to a mountain phase 2 square, the next lever will open phase 3.
				--The player does not need to activate all levers, repaying them for the risk they took.
				if level.status > 2 then return true end
				player:play_sound("lever.use")
				local raise = LFMARKER1
				if level.status == 1 then
					raise = LFMARKER2
				elseif level.status == 2 then
					raise = LFMARKER3
				end
				level:transmute_by_flag( "cwall", "floor", raise, level.data.mountain)
				level.status = level.status + 1
				return true
			end,

			OnDescribe = item.get_lever_description,
		}
	end,

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
			[','] = "bridge",
			['X'] = { "cwall", flags = { LFPERMANENT, LFMARKER1 }, style = 1, },
			['%'] = { "cwall", flags = { LFPERMANENT, LFMARKER2 }, style = 2, },
			['#'] = { "cwall", flags = { LFPERMANENT, LFMARKER3 }, style = 3, },
			['&'] = { "floor", item = "lever_erebus" },

			['/'] = { "floor", item = "shell" },
			['|'] = { "floor", item = "cell" },
			['-'] = { "floor", item = "rocket" },
			['!'] = { "floor", item = "epack" },
			['?'] = { "floor", item = core.ifdiff( 3, nil, "epack" ) },
			['*'] = { "floor", item = core.ifdiff( 4, nil, "epack" ) },

			['A'] = { "floor", being = core.bydiff{ "sergeant", "knight", "mancubus", "revenant" } },
			['B'] = { "floor", being = core.bydiff{ "knight", "mancubus", "revenant", "mancubus" } },

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
====================================================XXXXXXX===========.|/.==
=================================================XXXX.....XXXX========.&?A==
================================================XXA.........AXX=======.-..==
================================================X..%%%%%%%%%..X========,,===
===============================================XX.%%B..|..B%%.XX=======,,===
==...==========================================X..%/.#####./%..X=======,,===
=.....============================...==========X..%.##154##.%..X=======,,===
=.....===========================..&..,,,,,,,,,X..%.#7-=-9#.%..X,,,,,,,,,===
=..>..===========================..A..,,,,,,,,,X..%.#8B=*0#.%..X,,,,,,,,,===
=.....============================...==========X..%.##362##.%..X=======,,===
==...==========================================X..%/.#####./%..X=======,,===
===============================================XX.%%B..|..B%%.XX=======,,===
================================================X..%%%%%%%%%..X========,,===
================================================XXA.........AXX=======.-..==
=================================================XXXX.....XXXX========.&!A==
====================================================XXXXXXX===========.|/.==
============================================================================
]=]

		generator.place_tile( translation, map, 2, 2 )

		local second = core.bydiff{ "lostsoul", "cacodemon", "cacodemon", "pain" }		

		level.data.zone1a = area(50,  5, 64, 16)
		level.data.zone1b = area(55,  4, 59, 17)
		level.data.zone2  = area(53,  7, 61, 14)
		level.data.zone3  = area(55,  9, 59, 12)
		level.data.mountain = area(49, 3, 65, 18)

		level:set_light_flag( level.data.mountain, LFNOTELE, true )

		level:drop_being( player, coord( 4,11 ) )
		level.status = 0
	end,

}
