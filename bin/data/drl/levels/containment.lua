-- CONTAINMENT AREA -----------------------------------------------------

register_level "containment_area"
{
	name    = "Containment Area",
	entry   = "On @1 he arrived at the Containment Area.",
	welcome = "You enter the Containment Area. You feel something is hidden behind this wall.",
	level   = 11,

	runtime = {
		OnTick = function ( self )
			local res = self.status
			if res > 2 then return end
			if res < 2 and self.data.middle:contains( player.position ) then
				ui.msg( "\"This is too easy...\"" )
				res = 2
			end
			if self.data.right:contains( player.position ) then
				ui.msg( "\"It's a trap!\"" )
				self:transmute("ldoor","door")
				res = 3
				self:play_sound( "phasing", player.position )

				local total   = 8 + DIFFICULTY
				local knights = math.max( 9 - (3*( DIFFICULTY - 1 ) ), 0 )
				self:summon{ "knight", knights,         area = self.data.middle }
				self:summon{ "baron",  total - knights, area = self.data.middle }
				if DIFFICULTY >= 4 then
					self:summon{ "arch",  DIFFICULTY-3,     area = self.data.middle }
				end
				self:play_sound( "phasing", player.position, 50 )
				self:play_sound( "baron.act", player.position, 100 )
			end
			self.status = res
		end,

		OnKill = function ( self )
			if self.status < 1 then
				self.status = 1
			end
		end,
	},

	Create = function ()
		core.special_create()
		level:set_generator_style( 2 )
		level:fill( "wall" )

		local translation = {
			['.'] = "floor",
			['#'] = { "wall", style = 1, },
			['X'] = { "wall", style = 1, flags = { LFMARKER1 }},
			['P'] = { "wall", flags = { LFPERMANENT } },
			['*'] = "gwall",
			[','] = { "floor", flags = { LFBLOOD } },
			['+'] = "door",
			['L'] = "ldoor",
			['>'] = "stairs",
			['$'] = "crate",
			['&'] = "ycrate",
			['%'] = "crate_ammo",
			['@'] = "crate_armor",
			['i'] = { "floor", being = "imp" },
			['c'] = { "floor", being = "demon" },


			['^'] = { "floor", item = "backpack" },
			['!'] = { "floor", item = "umbazooka" },
			['|'] = { "floor", item = "procket" },
			['-'] = { "floor", item = "pammo" },
		}

		local map = [[
...........######..........&&..................#.................PPP......PP
.>.........######..$$......&&...&&........%%...#...**...**...**..PP........P
...........######..$$..%%.......&&..&&....%%...#...**...**...**..P..........
...........######...&&&%%...$$.$$...&&.....&&..#.................P..........
...........######...&&&.....$$.$$..$$..$$..&&..#.................P..........
............XXXXX.......$$.........$$..$$..$$..L........,,..................
............XXXXX..$$...$$....&&..&&$$&&...$$..L......,,,,,............^....
............XXXXX..$$...&&..$$&&..&&$$&&$$.....L.......,,...................
...........######.....$$@@..$$.....&&...$$.....#.................P..........
...........######.....$$@@...&&....&&....&&....#.................P..........
...........######..$$........&&...$$.....&&....#...**...**...**..P..........
...........######..$$..$$&&..$$...$$..@@....$$.#...**...**...**..PP........P
...........######......$$&&..$$.......@@....$$.#.................PPP......PP
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPLPPPPLPPPPLPPPPPPPPPPPPPP
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP..c.c.P...P.i.i..PPPPPPPPPPP
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP...-..P.!.P..|...PPPPPPPPPPP
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP..c.c.P...P.i.i..PPPPPPPPPPP
PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
]]
		generator.place_tile( translation, map, 2, 2 )

		level.data.left   = area( 19, 2, 48, 14 )
		level.data.middle = area( 50, 2, 66, 14 )
		level.data.right  = area( 68, 2, 78, 14 )
		level.data.sound_location = coord(15, 8)

		local total   = 5 + 2*DIFFICULTY
		level:summon{ "imp", total, area = level.data.left }

		level:drop_being( player, coord( 2,2 ) )
		level.status = 0
	end,

	OnKillAll = function ()
		if level.status ~= 3 then return end
		level:transmute_by_flag( "wall", "floor", LFMARKER1, area.FULL)
		level:play_sound( "door.close", level.data.sound_location)
		ui.msg("I guess I prefered the Wall. The air seems less claustrophic now.")
		level.status = 4
	end,

	OnNuked = function ()
		--Just check that everyone is dead
		for b in level:beings() do
			if not b:is_player() then return end
		end
		--Skip the wall trap sequence if required
		level.status = 4
	end,

	OnExit = function ()
		local result = level.status
		if result == 0 then
			ui.msg("I guess this tincan will stay closed...")
			player:add_history("Not knowing what to do, he left.")
		elseif result < 4 then
			ui.msg("It's way too hairy down here!")
			player:add_history("He broke into the Containment Area, but gave up against the overwhelming forces.")
		elseif result == 4 then
			core.special_complete()
			ui.msg("Luckily it's not as bad as tricks and traps...")
			player:add_history("He emerged from the Containment Area victorious!")
			player:add_badge("wall1")
			if CHALLENGE == "challenge_aohu" then
				player:add_medal("everysoldier")
			end
			if core.is_challenge("challenge_aomr") or core.is_challenge("challenge_aob") or core.is_challenge("challenge_aosh") then
				player:add_badge("wall2")
			end
		end
	end,
}
