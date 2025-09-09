-- CHAINED COURT --------------------------------------------------------

register_level "the_chained_court"
{
	name  = "The Chained Court",
	entry = "On @1 he stormed the Chained Court.",
	welcome = "Welcome to the Chained Court...",
	level = 5,

	OnRegister = function ()

		register_item "uarenastaff"
		{
		  	name   = "Arena Master's Staff",
			color  = YELLOW,
			level  = 200,
			weight = 0,
			sprite = SPRITE_STAFF,

			type  = ITEMTYPE_PACK,
			desc  = "You wonder what this is used for...",
			flags = { IF_UNIQUE },
			ascii = "?",

			OnUse = function(self,being)
				if not being:is_player() then return false end
				if being:is_affect( "tired" ) then
					ui.msg("You're too tired to use the staff now.")
					return false
				end
				being:set_affect( "tired" )
				ui.msg("You raise your arms!")
				if level.id == "the_vaults" and level.status < 2 then
					ui.msg("With a sudden inspiration you yell \"OPEN SESAME!\"!")
					player:play_sound( "lever.use" )
					for c in level:each( "rwall", area.FULL_SHRINKED ) do
						if level.light[ c ][ LFBLOOD ] then
							level.light[ c ][ LFPERMANENT ] = false
							level.map[ c ] = "floor"
						end
					end
					level.status = 3
					ui.msg("You hear a loud rumble!")
					being.scount = being.scount - 1000
					return true
				elseif level.id == "house_of_pain" then
					ui.msg("You brandish the staff. The voice echoes: \"So, it seems that ")
					ui.msg("you have bested one of my offspring. Very well, you are allowed ")
					ui.msg("full access to my domain as you traverse through it.\"")
					level:transmute( "ldoor", "odoor" )
					level:play_sound( "door.open", player.position)
					being.scount = being.scount - 1000
					return true
				else
					for b in level:beings() do
						if not b:is_player() and b:is_visible() then
							level:explosion( b.position, { range = 1, delay = 50, color = YELLOW, sound_id = "arch.fire", damage_type = DAMAGE_FIRE }, self )
							b:apply_damage( 15, TARGET_INTERNAL, DAMAGE_FIRE, self )
						end
					end
					being.scount = being.scount - 1000
					return false
				end
			end,
		}

		register_item "lever_chain1"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY, IF_FEATURENAME },

			good = "dangerous",
			desc = "opens cage",

			color_id = false,

			OnUse = function(self,being)
				level:transmute( "wall", "floor", level.data.cage1 )
				ui.msg("The cage rises!")
				level.status = level.status + 1
				if level.status == 4 then
					level:transmute( "wall", "floor", level.data.prize1 )
					level:transmute( "wall", "floor", level.data.prize2 )
				end
				return true
			end,

			OnDescribe = item.get_lever_description,
		}

		register_item "lever_chain2"
		{
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY, IF_FEATURENAME },

			good = "dangerous",
			desc = "opens cage",

			color_id = false,

			OnUse = function(self,being)
				level:transmute( "wall", "floor", level.data.cage2 )
				ui.msg("The cage rises!")
				level.status = level.status + 1
				if level.status == 4 then
					level:transmute( "wall", "floor", level.data.prize1 )
					level:transmute( "wall", "floor", level.data.prize2 )
				end
				return true
			end,

			OnDescribe = item.get_lever_description,
		}

		register_item "lever_chain3"
		{
			id     = "lever_chain3",
			name   = "lever",
			color  = MAGENTA,
			sprite = SPRITE_LEVER,
			weight = 0,
			type   = ITEMTYPE_LEVER,
			flags  = { IF_NODESTROY, IF_FEATURENAME },

			good = "dangerous",
			desc = "opens cage",

			color_id = false,

			OnUse = function(self,being)
				level:transmute( "wall", "floor", level.data.cage3 )
				ui.msg("The cage rises!")
				level.status = level.status + 1
				if level.status == 4 then
					level:transmute( "wall", "floor", level.data.prize1 )
					level:transmute( "wall", "floor", level.data.prize2 )
				end
				return true
			end,

			OnDescribe = item.get_lever_description,
		}

		register_being "arenamaster"
		{
			name         = "Arena Master",
			ascii        = "V",
			color        = LIGHTGREEN,
			sprite       = SPRITE_MASTER,
			sframes      = 2,
			sflags       = { SF_LARGE },
			hp           = 80,
			armor        = 2,
			attackchance = 50,
			strength     = 3,
			accuracy     = 2,
			speed        = 160,
			min_lev      = 200,
			corpse       = "corpse",
			danger       = 14,
			weight       = 0,
			flags        = { BF_OPENDOORS, BF_SELFIMMUNE },
			desc         = "The meanest, ugliest and strongest Arch-Vile you have ever seen...",

			ai_type         = "archvile_ai",
			kill_desc       = "was charred by the Arena Master",

			weapon = {
				damage     = "15d1",
				damagetype = DAMAGE_FIRE,
				radius     = 2,
				flags      = { IF_AUTOHIT },
				missile = {
					sound_id   = "arch",
					color      = YELLOW,
					delay      = 0,
					miss_base  = 10,
					miss_dist  = 10,
					hitdesc    = "You are engulfed in flames!",
					flags      = { MF_EXACT, MF_IMMIDATE },
				},
				missprite = 0,
				hitsprite = SPRITE_BLAST,
				explosion  = {
					delay = 50,
					color = YELLOW,
					flags = { EFNOKNOCK, EFSELFSAFE },
				},
			},

			OnCreate = function (self)
				self.hpmax = self.hpmax + DIFFICULTY * DIFFICULTY * 5
				self.hp = self.hpmax
				self.inv:add( item.new( "uarenastaff" ) )

				self:add_property( "master", true )
			end,
		}

	end,

	Create = function ()
		core.special_create()
		level:set_generator_style( 1 )
		-- level.status 1 == chained court
		-- level.status 0 == unchained court (w/ Arena Master)
		if player:has_medal("hellchampion") or player:has_medal("hellchampion2") or player:has_medal("hellchampion3") then
			level.status = 0
		else
			level.status = 1
		end

		level:fill( "wall" )
		local mod1,mod2 = generator.roll_pair{"mod_power","mod_agility","mod_bulk","mod_tech"}
		local translation = {
			['.'] = "floor",
			[','] = { "floor", flags = { LFBLOOD } },
			['#'] = "wall",
			['X'] = { "wall", flags = { LFBLOOD } },
			['>'] = "stairs",
			['+'] = "door",
			['='] = "lava",
			['h'] = { "floor", being = "former" },
			['H'] = { "floor", being = core.bydiff{ "former","former","sergeant","captain" } },
			['O'] = { "floor", being = core.bydiff{ "cacodemon","cacodemon","knight","baron" } },
			[';'] = { "floor", item = "shell" },
			['-'] = { "floor", item = "cell" },
			['!'] = { "floor", item = "chainsaw" },
			['^'] = { "floor", item = "bpack" },
			['*'] = { "floor", item = mod1 },
			['?'] = { "floor", item = mod2 },
			['&'] = { "floor", being = "arenamaster" },
			['1'] = { "floor", item = "lever_chain1" },
			['2'] = { "floor", item = "lever_chain2" },
			['3'] = { "floor", item = "lever_chain3" },
		}

		level.data.cage1 = area(16,4,23,9)
		level.data.cage2 = area(16,12,23,17)
		level.data.cage3 = area(59,6,66,15)
		level.data.prize1 = area(35,7,44,8)
		level.data.prize2 = area(35,13,44,14)

		local map = [[

#########............##########==============##########............#########
######.............h....#######==============#######...........H......######
###...........X##X##X#.....####==##;..?.-##==####........h...............###
##...H........########......###==##-h..H;##==###....................H.....##
#.............##...O#X.......##==##;....-##==##..........##X##X##..........#
#######.......X#....##.......##==##########==##..........#######X....#####+#
......#...H...########1..h....#==##########==#....h......X#....##....#......
.>.H..#.......#X##X##X...........+.^....^.+..............##...O##....#H.....
......#..........H............#==#........#==#...........##....#X....#......
......#.......................#==#....!...#==#..........3##....##....#......
.....H#.......##X##X##...........+.^....^.+..............X#...O##....#..H.>.
......#.......X######X2.......#==##########==#...........##....#X....#......
#+#####.......##...O##....h..##==##########==##.......h..########....#######
#........H....##....##.......##==##-....;##==##..........X##X##X#..........#
##............X######X......###==##;H..h-##==###.......................H..##
###...........##X##X##.....####==##-.*..;##==####.....h......H...........###
######.......H..........#######==============#######..................######
#########............##########==============##########............#########
]]

		if level.status == 0 then
			map = [[
###################......................................###################
############.............=======...................................#########
##########............h.....======.....................h...............#####
##...###.......................=====......................................##
#?...##.....H....H...............====......................................#
.....##.................,.H..........h.......====#O;-;-;-O#====.....h.......
.....##.H..........,,,.......................====#XX##XXX##====.............
.....##.......H..,,.,.,..,.......................+....,,^.+.................
.>...##.........,.,...&....,.................====#..,...,,#====..........h..
.....##...H......,..H....,.,,.....h..........====#.,,,!,,.#====.............
.....##.........,..,..,..........................+...,,.^.+.................
.....##H.......H......,,..H..................====##XXX#XX##====.....h.......
.....##...............................h......====.O;-;-;-O#====h............
#*...##..........................====......................................#
##...###.......................=====.....................................###
##########.............h....======....................h...............######
############.............=======.................................#X#########
###################......................................###################

]]
		end


		generator.place_tile( translation, map, 2, 2 )
		generator.set_permanence( area.FULL )
		if level.status == 0 then
			level:player(52,10)
			generator.set_permanence( area(50,7,59,14), false )
		else
			level:player(38,10)
			generator.set_permanence( area(34,4,43,17), false )
		end
	end,
	OnKillAll = function ()
		if level.status == 0 then
			ui.msg("So much for hellish fair-play.")
			level:transmute( "wall", "floor", area(7,5,11,16) )
			player:add_history("He defeated the Hell Arena Master!")
			level.status = 3
		end
	end,

	OnEnterLevel = function ()
		if level.status == 0 then
			ui.msg("A devilish voice booms:")
			ui.msg("\"Come to think of it... I'd rather see you dead, mortal... prepare yourself!\"")
			level:play_sound( "baron.act", player.position )
		end
	end,

	OnExit = function ()
		if level.status == 3 then
			core.special_complete()
		end
	end,

}
