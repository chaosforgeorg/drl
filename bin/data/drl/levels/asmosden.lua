-- The Asmos Den --------------------------------------------------------
--[[
local hell

register_level "the_asmos_den"
{
	name  = "The Asmos Den",
	entry = "On @1 he braved the Asmos Den.",
	welcome = "This place reeks of evil, even more so than everywhere else...",
	level = 22,
	welcome = "You enter Asmos Den.",

	OnRegister = function()

		register_being "hellmaster"
		{
			name         = "Hell Incarnate",
			ascii        = "H",
			color        = LIGHTRED,
			sprite       = SPRITE_MASTER,
			sframes      = 2,
			sflags       = { SF_LARGE },
			hp           = 1,
			armor        = 0,
			attackchance = 50,
			strength     = 1,
			accuracy     = 12,
			speed        = 50,
			min_lev      = 200,
			corpse       = "corpse",
			danger       = 0,
			weight       = 0,
			sound_id     = "baron",
			flags        = { BF_KNOCKIMMUNE, BF_INV, BF_ENVIROSAFE },
			desc         = "It's from your worst nightmares. You don't like to think about it.",

			ai_type         = "melee_ranged_ai",
			kill_desc       = "damned by Hell Incarnate",

			weapon = {
				damage     = "3d2",
				damagetype = DAMAGE_IGNOREARMOR,
				radius     = 1,
				flags      = { IF_AUTOHIT },
				missile = {
					sound_id   = "arch",
					color      = LIGHTRED,
					sprite     = 0,
					delay      = 1,
					miss_base  = 0,
					miss_dist  = 0,
					hitdesc    = "You feel an intense pain!",
					flags      = { MF_EXACT },
					explosion = {
						delay = 100,
						color = LIGHTBLUE,
					},
				},
				hitsprite  = SPRITE_BLAST,
			},

			OnCreate = function (self)
				self:add_property( "master", true )
			end,
			
			OnAction = function (self)
				if self:distance_to(player) > self.vision-1 then
					local target = level:drop_coord( self.position, {EF_NOBEINGS,EF_NOBLOCK} )
					self:play_sound("phasing")
					level:explosion( player, { range = 2, delay = 50, color = YELLOW } )
					player:relocate( target )
					level:explosion( player, { range = 1, delay = 50, color = YELLOW } )
				end

			end,
		}

		-- TODO: Isn't this perma-inv that only gets destroyed if level is NOT nuked?
		register_item "uhellwrap"
		{
			name     = "hellish wrapping",
			color    = LIGHTRED,
			sprite   = SPRITE_ARMOR,
			coscolor = { 1.0,0.0,0.0,1.0 },
			pcoscolor= { 1.0,0.0,0.0,1.0 },
			level    = 200,
			weight   = 0,
			desc     = "The material glows a vibrant red. What's the worst that could happen?",
			flags    = { IF_UNIQUE, IF_CURSED, IF_NODURABILITY },

			type       = ITEMTYPE_ARMOR,
			armor      = 0,

			OnEquip = function(self, being)
				if not being.flags[ BF_INV ] then
					being.flags[ BF_INV ] = true
				end
			end,

			OnEquipTick = function(self, being)
				if not level.flags[ LF_NUKED ] then
					ui.msg("Looks like even the armor of Hell couldn't handle an explosion ")
					ui.msg("THAT big. At least it kept you alive.")
					self:destroy()
					return
				end
				if not being.flags[ BF_INV ] then
					being.flags[ BF_INV ] = true
				end
				if being.hp - 5 < 1 then
					being.hp = 1
					if not player:is_affect("inv") then
						being.flags[ BF_INV ] = false
					end
				else
					being.hp = being.hp - 5
				end
			end,
		}
	end,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		level:fill( "rwall" )
		local asmosden_armor = {
			level = 25,
			type = {ITEMTYPE_ARMOR,ITEMTYPE_BOOTS},
			unique_mod = 5,
		}

		local translation = {
			['.'] = "floor",
			[','] = { "floor", flags = { LFBLOOD } },
			['#'] = { "rwall", flags = { LFPERMANENT } },
			['%'] = { "rwall", flags = { LFPERMANENT, LFBLOOD } },
			['>'] = { "stairs" },
			['='] = "lava",
			['~'] = "bridge",
			['s'] = { "lava", being = "lostsoul"},
			['O'] = { "lava", being = core.bydiff{ "lostsoul", "lostsoul", "pain", "pain" } },
			['M'] = { "floor", being = core.bydiff{ "knight", "baron", "baron", "mancubus" } },
			['R'] = { "floor", being = core.bydiff{ "imp", "cacodemon", "revenant", "revenant" } },
			['B'] = { "floor", being = core.ifdiff( 2, "baron", "knight" ) },

			['-'] = { "floor", item = "shell" },
			['('] = { "floor", item = "rocket" },
			[')'] = { "floor", item = "cell" },

			['1'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['2'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['3'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['4'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['5'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['6'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['7'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['8'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['9'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['0'] = { "floor", item = level:roll_item( asmosden_armor ) },
			['$'] = { "floor", item = "uhellwrap" },
		}

		local map = [=[
>..#####670....===###########.......##############....##-(........########==
#....####8..M.==s...#####.............R...#######.....-##).###.....######===
##.....###9..===..............##..............###..##21(#....##..R..###===s=
#####....###====..........#####....%%%%%%%%%....#...##)##...###)....###====.
#####M......==O=...B..##..###....###%.....%%%%..##...###....####...(##=O==..
#######.....=====.....##..##....##%%........-%%..###......####....-##===....
#####.....##=s====.....#...#.R.##%....%%%...)%...####...###....######=s=....
###.......#=======.....##..#...#%...%%%%....(%.B.##...###........###===.....
###......##===s===.....##..##..#%....%%%...%%%...##...#....##...###s==......
##M.....##========.....##...#..##..R..%%$%%%....##...##...##...####===.....#
##......#==O====.......##.R.#...###....%%%.....###..##...##.......~~=......#
#......=======##.......##...##....##....B....###...##...##...###=~~~.......#
#....~~=s==####.......####...##....####....###....##..###...##===~........##
==s===~~=###.B.......#####...-##......######....###...R...###==s=.......####
====..............#########..(###.......##.....#####....###====..........###
#####.......###R....#####...)######.........R...##....####==O=.......##....#
#################...........###########..............####=s==......#####....
###################..534..##################......######====.....########...

]=]
		generator.place_tile( translation, map, 2, 2 )

		generator.set_permanence( area.FULL )

		level:player(77,19)
	end,

	OnEnterLevel = function ()
		level.status = 0
	end,

	OnPickup = function (item)
		if level.status == 0 and item.id == "uhellwrap" then
			ui.msg("A deafening voice speaks: \"So you think you can steal Hell's riches? ")
			ui.msg("Then try to best that which guards it!\"")
			hell = level:drop_being( "hellmaster", coord(43,9) )
			level.flags[ LF_NOHOMING ] = true
			statistics.kills = statistics.kills - 1
			level.status = 1
		end
	end,

	OnExit = function ()
		local result = level.status
		if result == 0 then
			ui.msg("Let's just get the hell out of here!")
			player:add_history("He kept his hands to himself.")
		else
			hell:kill()
			ui.msg("I hope this damn armor was worth the trouble!")
			player:add_history("He pilfered the treasure there.")
			core.special_complete()
		end
	end,
}
--]]