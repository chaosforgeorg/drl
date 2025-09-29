core.declare( "drl", {} )
core.declare( "core_module", "drl" )
core.declare( "DEMO", false )
core.declare( "VERSION_MODULE",      "0.10.4" )
core.declare( "VERSION_MODULE_SAVE", "0.10.4" )

require( "drl:generator" )
require( "drl:generators" )
require( "drl:rooms" )
require( "drl:events" )
require( "drl:sprites" )
require( "drl:difficulty" )
require( "drl:affects" )
require( "drl:awards" )
require( "drl:cells" )
require( "drl:traits" )
require( "drl:ai" )
require( "drl:beings" )
require( "drl:ranks" )
require( "drl:plot" )
require( "drl:challenge" )
require( "drl:assemblies" )
require( "drl:klass" )

require( "drl:items/items" )
require( "drl:items/eitems" )
require( "drl:items/uitems" )

require( "drl:levels/boss" )
require( "drl:levels/arena" )
require( "drl:levels/phoboslab" )
require( "drl:levels/fortress" )
require( "drl:levels/intro" )
require( "drl:levels/chained" )
require( "drl:levels/centralprocessing")
require( "drl:levels/toxinrefinery" )
require( "drl:levels/carnage" )
require( "drl:levels/milibase" )
require( "drl:levels/deimoslab" )
require( "drl:levels/armory" )
require( "drl:levels/skulls" )
require( "drl:levels/abyssal" )
require( "drl:levels/wall" )
require( "drl:levels/spider" )
require( "drl:levels/vaults" )
require( "drl:levels/house" )
require( "drl:levels/limbo" )
require( "drl:levels/mortuary" )
require( "drl:levels/mterebus" )
require( "drl:levels/lavapits" )
require( "drl:levels/asmosden" )
require( "drl:levels/containment" )
require( "drl:levels/house" )

-- main DRL lua script file --

function drl.OnLoaded()
	ui.msg('Welcome to {RDRL}...')
end

function drl.OnLoad()
	drl.register_sprites()
	drl.register_difficulties()
	drl.register_base_data()
	drl.register_affects()
	drl.register_cells()
	drl.register_regular_items()
	drl.register_exotic_items()
	drl.register_unique_items()
	drl.register_beings()
	drl.register_ranks()
	drl.register_traits()
	drl.register_awards()
	drl.register_assemblies()
	drl.register_challenges()
	drl.register_klasses()

	drl.register_generators()
	drl.register_events()
	drl.register_rooms()

	generator.styles = {
		{ floor = "floor", wall = "wall",  door="door",  odoor = "odoor",  style = 0,  },
		{ floor = "floor", wall = "wall",  door="door",  odoor = "odoor",  style = 1,  },
		{ floor = "floor", wall = "rwall", door="door",  odoor = "odoor",  style = 2, },
		-- boss levels (4)
		{ floor = "floor", wall = "rwall", door="door",  odoor = "odoor",  style = 0,  },
		-- alt-style for phobos
		{ floor = "floor", wall = "wall",  door="door",  odoor = "odoor",  style = 3,  },
		-- alt-style for deimos
		{ floor = "floor", wall = "wall",  door="door",  odoor = "odoor",  style = 4,  },
		-- alt-style for hell
		{ floor = "floor", wall = "rwall", door="door",  odoor = "odoor",  style = 5,  },
		-- alt-style for phobos 2
		{ floor = "floor", wall = "wall",  door="door",  odoor = "odoor",  style = 6,  },
		-- babel
		{ floor = "floor", wall = "rwall", door="door",  odoor = "odoor",  style = 7,  },
		-- caves (10-12)
		{ floor = "cfloor",  wall = "cwall", door="door",  odoor = "odoor", style = 0,  },
		{ floor = "cfloor",  wall = "cwall", door="door",  odoor = "odoor", style = 1,  },
		{ floor = "cfloor",  wall = "cwall", door="door",  odoor = "odoor", style = 2,  },
	}

	for _,level_proto in ipairs(levels) do
		if level_proto.OnRegister then level_proto.OnRegister() end
	end

	ui.set_style_frame( VTIG_BORDER_FRAME, "\196\196  \196\196\196\196" )
	ui.set_style_color( VTIG_TITLE_COLOR, YELLOW )
	ui.set_style_color( VTIG_FRAME_COLOR, RED )
	ui.set_style_color( VTIG_FOOTER_COLOR, LIGHTRED )
	ui.set_style_color( VTIG_SELECTED_TEXT_COLOR, YELLOW )
	ui.set_style_color( VTIG_SCROLL_COLOR, YELLOW )

	if GRAPHICSVERSION then
		ui.set_style_color( VTIG_BACKGROUND_COLOR, { 16, 0, 0, 0 } )
		ui.set_style_color( VTIG_WINDOW_BACKGROUND_COLOR, { 1, 1, 1, 200 } )
		ui.set_style_color( VTIG_SELECTED_BACKGROUND_COLOR, { 68, 34, 34, 255 } )
		ui.set_style_color( VTIG_INPUT_TEXT_COLOR, LIGHTGRAY )
		ui.set_style_color( VTIG_INPUT_BACKGROUND_COLOR, {68, 34, 34, 255} )
	else
		ui.set_style_color( VTIG_SELECTED_BACKGROUND_COLOR, DARKGRAY )
		ui.set_style_color( VTIG_SELECTED_DISABLED_COLOR, BLACK )
	end
	ui.update_styles()
end

function drl.register_base_data()

	register_cell "bloodpool"
	{
		name = "pool of blood";
		ascii = "";
		asciilow = '.';
		color = RED;
		set = CELLSET_FLOORS;
		sprite = SPRITE_BLOODPOOL;
		flags = {CF_OVERLAY, CF_VBLOODY};
	}

	register_cell "corpse"
	{
		name = "bloody corpse";
		ascii = "%";
		color = RED;
		set = CELLSET_FLOORS;
		flags = { CF_CORPSE, CF_OVERLAY, CF_NOCHANGE, CF_VBLOODY};
		destroyto = "bloodpool",
		sprite = SPRITE_CORPSE,
	}

	register_item "stubitem"
	{
		name     = "stubitem",
		color    = RED,
		sprite   = SPRITE_TELEPORT,
		weight   = 0,

		type = ITEMTYPE_TELE,

		OnEnter = function() end,
	}

	register_item "teleport"
	{
		name     = "teleport",
		color    = LIGHTCYAN,
		sprite   = SPRITE_TELEPORT,
		sframes  = 2,
		weight   = 0,
		flags    = { IF_NODESTROY, IF_NUKERESIST },

		type = ITEMTYPE_TELE,

		OnCreate = function( self )
			self:add_property( "target", false )
		end,

		OnEnter = function( self, being )
			if not self.target then
				self.target = level:random_empty_coord{ EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }
			end
			-- Explosions can have sounds, but by the time the sound plays, the player has already moved
			level:play_sound( "teleport.use", being.position )
			level:explosion( being.position, { range = 4, delay = 50, color = GREEN } )
			being:msg( "You feel yanked away!", being:get_name(true,true).." suddenly disappears!" )
			local target = self.target
			local empty = { EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }
			if cells[ level.map[ target ] ].flags[ CF_BLOCKMOVE ] then
				being:msg("You feel out of place!")
				being:apply_damage(15, TARGET_INTERNAL, DAMAGE_FIRE )
				target = level:random_empty_coord( empty )
			end
			if level:get_being( target ) then
				local tgt = level:get_being( target )
				being:msg("Suddenly you feel weird!")
				tgt:msg("Argh! You feel like someone is trying to implode you!")
				tgt:apply_damage(15, TARGET_INTERNAL, DAMAGE_FIRE )
				target = level:random_empty_coord( empty )
			end
			if being.__ptr then
				being:relocate( target )
				being:msg(nil,"Suddenly "..being:get_name(false,false).." appears out of nowhere!")
				being.scount = being.scount - 1000
			end
		end,
	}

	register_being "soldier"
	{
		name         = "soldier",
		ascii        = "@" ,
		color        = LIGHTGRAY,
		sprite       = SPRITE_PLAYER,
		sframes      = 2,
		sftime       = 500,
		min_lev      = 200,
		corpse       = "corpse",
		danger       = 0,
		weight       = 0,
		xp           = 0,
		flags        = { BF_OPENDOORS, BF_UNIQUENAME },
		desc         = "You're a soldier. One of the best that the world could set against the demonic invasion.",
		ai_type      = "",

		OnCreate = function(self)
			self:add_property( "medals", {} )
			self:add_property( "badges", {} )
			self:add_property( "awards", {} )
			self:add_property( "assemblies", {} )
			self:add_property( "items_found", {} )
			self:add_property( "history", {} )
			self:add_property( "episode", {} )
			self:add_property( "level_data", {} )

			if rawget(_G,"DIFFICULTY") then
				self.hp    = 50
				self.hpmax = self.hp
				self.hpnom = self.hp
				self.scount = 4000 --Removes player's start delay on level 1
				self.expfactor = diff[DIFFICULTY].expfactor
			end

			self:add_property( "runningtime", 30 )
			self:add_property( "techbonus", 0 )
			self:set_coscolor{ 0.8, 0.7, 0.7, 1.0 }
		end,

		--These stubs exist so that modders can hijack them properly
		OnAction   = function(self) return end,
		OnAttacked = function(self) return end,
		OnDie      = function(self, overkill) return end,
		OnDieCheck = function(self, overkill) return true end,

		OnPickupItem = function(self,i)
			if not self:has_found_item( i.id ) then
				if i.flags[ IF_UNIQUE ] then
					statistics.uniques_found = statistics.uniques_found + 1
					self:add_history( 'On @1 he found the '..i.name..'!' )
					ui.blink( LIGHTGREEN, 50 )
				end
				if items[ i.id ].OnFirstPickup then
					items[ i.id ].OnFirstPickup( i, self )
				end
				self:add_found_item( i.id )
			end
		end,

		OnUseActive = function( self )
			if klasses[player.klass].OnUseActive then
				return klasses[player.klass].OnUseActive( self )
			end
			if self:is_affect( "berserk" ) then return false end
			if self:is_affect( "tired" ) then
				ui.msg( "Too tired to do that right now.")
				return false
			end
			if self:is_affect( "running" ) then
				self:remove_affect( "running", false )
				return false
			else
				self:set_affect( "running", self.runningtime )
				self.scount = self.scount - 100
				return true
			end
		end,
	}

end

function drl.OnEnterLevel()
	player:remove_affect( "running", true )
	player:remove_affect( "tired", true )
end

function drl.GetDisassembleId( it )
	local modlist = {"mod_agility","mod_bulk","mod_tech","mod_power"}
	if it.__proto.scavenge then
		modlist = it.__proto.scavenge
	elseif it.flags[IF_EXOTIC] then
		modlist = {"mod_agility","mod_bulk","mod_tech","mod_power","umod_firestorm","umod_sniper"}
	elseif it.flags[IF_UNIQUE] then
		modlist = {"umod_firestorm","umod_firestorm","umod_sniper","umod_sniper","umod_onyx","umod_nano"}
	else
		local mods = it:get_mod_ids()
		if #mods > 0 then
			modlist = mods 
		end
	end
	return table.random_pick( modlist )
end

function drl.GetResultId()
	local result    = "unknown"
	local dead      = player.hp <= 0
	local won       = player:has_won()
	local nuked     = level.flags[ LF_NUKED ]
	local boss1dead = won
	local boss2dead = kills.get("jc") > 0 or kills.get("apostle") > 0

	if won then 
		result = "win"
		if boss2dead and not dead then
			result = "final"
		elseif boss1dead and dead then
			result = "sacrifice"
		end
	elseif not dead then 
		result = "win"
	elseif nuked then
		result = "nuke"
	elseif player.killedby == player.id then
		result = "suicide"
	elseif beings[ player.killedby ] then
		result = "killed"
	end
	return result
end

function drl.GetShortResultId( result, level_index )
	if result == "win" or result == "final" or result == "sacrifice" then return result end
	return "level:"..level_index
end

function drl.GetResultDescription( result, highscore )
	local killed_by = "was killed by something"

	    if result == "win"   then killed_by = "defeated the Mastermind"
	elseif result == "final" then killed_by = "nuked the Mastermind"
	elseif result == "nuke"  then killed_by = "nuked himself"
	elseif result == "sacrifice" then
		if highscore then killed_by = "won by sacrifice" else killed_by = "sacrificed himself to kill the Mastermind" end
	elseif result == "suicide" then
		if highscore then killed_by = "committed suicide" else killed_by = "committed a stupid suicide" end
	elseif result == "killed" then
		local killer = beings[ player.killedby ]
		if killer then
			if not highscore then
				if player.killedmelee then
					killed_by = killer.kill_desc_melee 
				else
					killed_by = killer.kill_desc
				end
			end
			if highscore or not killed_by then
				killed_by = 'killed by '..killer.name
			end
		end
	end

	if player:has_won() then
		local chal_idx
		if highscore then
			if ARCHANGEL then
				chal_idx = "arch_win_highscore"
			else
				chal_idx = "win_highscore"
			end
		else
			if ARCHANGEL then
				chal_idx = "arch_win_mortem"
			else
				chal_idx = "win_mortem"
			end
		end
		if SCHALLENGE ~= '' and chal[ SCHALLENGE ][ chal_idx ] then
			killed_by = chal[ SCHALLENGE ][ chal_idx ]
		elseif CHALLENGE ~= '' and chal[ CHALLENGE ][ chal_idx ] then
			killed_by = chal[ CHALLENGE ][ chal_idx ]
		end
	end

	return killed_by
end

function drl.RunPrintMortem()
	local result_id    = drl.GetResultId()
	local death_reason = drl.GetResultDescription( result_id, false )
	local game_module    = nil

	player:mortem_print( "{r--------------------------------------------------------------}" )
	player:mortem_print( " {RDRL} ({!"..VERSION_STRING.."}) roguelike post-mortem character dump")
--	if game_type ~= GAMESTANDARD then
--		player:mortem_print( " Module : "..module.name.." ("..mortem.version_string(module.version)..")")
--		game_module = _G[module.id]
--	end
	player:mortem_print( "{r--------------------------------------------------------------}" )
	player:mortem_print()

	if game_module and game_module.RunPrintMortem then
		game_module.RunPrintMortem()
		return
	end

	if not game_module then
		local player_description = "level {!"..player.explevel.." "
			..ranks.exp[ ui.get_rank("exp") + 1].name.." "..ranks.skill[ui.get_rank("skill") + 1].name
			.." "..klasses[player.klass].name.."},"
		if string.len(player.name) <= 12 then
			player:mortem_print(" {!"..player.name.."}, "..player_description)
		else
			player:mortem_print(" {!"..player.name.."},")
			player:mortem_print(" "..player_description)
		end
		local epi_name = player.episode[player.level_index].deathname or player.episode[player.level_index].name or "an Unknown Location"
		player:mortem_print( " "..death_reason.." at {!"..epi_name.."}." )
	else
		if game_module.OnMortemPrint then
			game_module.OnMortemPrint(death_reason)
		else
			player:mortem_print( " {!"..player.name.."}, level {!"..player.explevel.." "
		.." "..klasses[player.klass].name.."}, "..death_reason )
			player:mortem_print(" in a custom location...")
		end
	end

	mortem.print_time_and_kills()
	local ratio = statistics.kills / statistics.max_kills

		if statistics.kills == statistics.max_kills then
			player:mortem_print( " This ass-kicking marine killed all of them!" )
	elseif statistics.kills + 1 == statistics.max_kills then
			player:mortem_print (" He missed one kill to totally be ass-kicking." )
	elseif statistics.kills == 0 then
			player:mortem_print( " Poor pacifist, didn't even get a single kill..." )
	elseif statistics.kills == 1 then
			player:mortem_print( " Somehow, he managed only *one* kill." )
	elseif ratio < 0.1    then
			player:mortem_print( " My, wasn't he a wimpy chump." )
	elseif ratio < 0.3    then
			player:mortem_print( " Who gave him the ticket to Hell, anyway?" )
	elseif ratio > 0.999  then
			player:mortem_print( " A natural born killer!" )
	elseif ratio > 0.99   then
			player:mortem_print( " He was a real killing machine..." )
	elseif ratio > 0.9    then
			player:mortem_print( " He held his right to remain violent." )
	end

	mortem.print_challenge()
	mortem.print_crash_save()
	player:mortem_print()
	player:mortem_print("{r-- {ySpecial levels} --------------------------------------------}")
	player:mortem_print()
	mortem.print_special_levels()
	player:mortem_print()
	player:mortem_print("{r-- {yAwards} ----------------------------------------------------}")
	player:mortem_print()
	mortem.print_awards()
	player:mortem_print()

	player:mortem_print( "{r-- {yGraveyard} -------------------------------------------------}")
	player:mortem_print()
	mortem.print_graveyard()
	player:mortem_print()
	player:mortem_print( "{r-- {yStatistics} ------------------------------------------------}" )
	player:mortem_print()
	mortem.print_statistics()
	player:mortem_print()
	player:mortem_print( "{r-- {yTraits} ----------------------------------------------------}" )
	player:mortem_print()
	mortem.print_traits()
	player:mortem_print()
	player:mortem_print( "{r-- {yEquipment} -------------------------------------------------}" )
	player:mortem_print()
	mortem.print_equipment()
	player:mortem_print()
	player:mortem_print( "{r-- {yInventory} -------------------------------------------------}" )
	player:mortem_print()
	mortem.print_inventory()
	player:mortem_print()
	player:mortem_print( "{r-- {yResistances} -----------------------------------------------}" )
	player:mortem_print()
	mortem.print_resistances()
	player:mortem_print()
	player:mortem_print( "{r-- {yKills} -----------------------------------------------------}" )
	player:mortem_print()
	mortem.print_kills()
	player:mortem_print()
	local groups = { "melee", "pistol", "shotgun", "chain", "rocket", "plasma", "bfg" }
	local names  = { "Melee kills   : ", "Pistol kills  : ", "Shotgun kills : ", "Chaingun kills: ", "Rocket kills  : ", "Plasma kills  : ", "BFG kills     : " }
	for idx,group in ipairs(groups) do
		local count = core.kills_count_group( group )
		if count > 0 then
			player:mortem_print( "    "..names[ idx ].."{!"..count.."}" )
		end
	end
	player:mortem_print( "    Unarmed kills : {!"..kills.get_type( "melee" ).."}" )
	player:mortem_print( "    Other kills   : {!"..kills.get_type( "other" ).."}" )
	player:mortem_print()
	player:mortem_print( "{r-- {yHistory} ---------------------------------------------------}" )
	player:mortem_print()
	mortem.print_history()
	if not game_module then
		if kills.get("jc") > 0 then
			player:mortem_print( "  Then finally in Hell itself, he killed the final EVIL." )
		else
			player:mortem_print( "  On level {!"..player.level_index.."} he finally "..death_reason..".")
		end
	end
	player:mortem_print()
	player:mortem_print( "{r-- {yMessages} --------------------------------------------------} " )
	player:mortem_print()
	mortem.print_messages()
	player:mortem_print()

	if not game_module then
		player:mortem_print( "{r-- {yGeneral} ---------------------------------------------------} " )
		player:mortem_print()

		local deaths = player_data.count('player/deaths')
		if deaths > 1 then
			local function reason( id, desc )
				local count = player_data.count('player/deaths/death[@id="'..id..'"]')
				if count == 0 then return end
				if count > 1 then
					desc = desc:gsub( "@was", "were" )
				else
					desc = desc:gsub( "@was", "was" )
				end
				player:mortem_print( desc:gsub( "@1", count.."" ) )
			end
			player:mortem_print( " "..deaths.." brave souls have ventured into Phobos:" )
			reason( "killed" ," {!@1} of those @was killed.")
			reason( "unknown"," {!@1} of those @was killed by something unknown." )
			reason( "nuke"   ," {!@1} didn't read the thermonuclear bomb manual." )
			reason( "suicide"," And {!@1} couldn't handle the stress and committed a stupid suicide." )

			local sacrifice = player_data.count('player/games/win[@id="sacrifice"]')
			local win       = player_data.count('player/games/win[@id="win"]')
			local fullwin   = player_data.count('player/games/win[@id="final"]')
			local wins      = sacrifice + win + fullwin

			if wins > 0 then
				player:mortem_print()
				player:mortem_print(" {!"..wins.."} souls destroyed the Mastermind...")
				if sacrifice > 0 then player:mortem_print(" {!"..sacrifice.."} sacrificed itself for the good of mankind." ) end
				if win       > 0 then player:mortem_print(" {!"..win.."} killed the bitch and survived." ) end
				if fullwin   > 0 then player:mortem_print(" {!"..fullwin.."} showed that it can outsmart Hell itself." ) end
			end
		else
			player:mortem_print("  He's the {!first} brave soul to have ventured into Hell...")
		end
		player:mortem_print()
	end
	player:mortem_print( "{r--------------------------------------------------------------} " )
end

function drl.OnCreateEpisode()
	player.episode = {}
	local paired = {
		{"hells_arena"}, -- 2                                    26
		{"central_processing","toxin_refinery"}, -- 4            27
		{"the_chained_court"}, -- 5                              28
		{"military_base","phobos_lab"}, -- 7                     29
		{"hells_armory", "deimos_lab"}, -- 9/1                   30
		{"the_wall","containment_area"}, -- 11/3                 31
		{"city_of_skulls","abyssal_plains"}, -- 12/4             32
		{"halls_of_carnage","spiders_lair"}, -- 14/6             33
		{"the_vaults","house_of_pain"}, -- 17/1                  34
		{"unholy_cathedral"}, -- 19/3                            35
		{"the_mortuary","limbo"},-- 20/4                         36
		{"the_lava_pits","mt_erebus"},-- 22/6                    37
	}

	player.episode[1] = { script = "intro", style = 1, deathname = "level 1 of the Phobos base" }
	player.episode[2] = { style = 1, name = "Phobos L2", danger = 2, deathname = "level 2 of the Phobos base" }
	for i=3,8 do
		player.episode[i] = { style = table.random_pick{1,5,8}, name = "Phobos L"..tostring(i), danger = i, deathname = "level "..tostring(i).." of the Phobos base" }
	end
	for i=9,16 do
		player.episode[i] = { style = table.random_pick{2,6}, name = "Deimos L"..tostring(i-8), danger = i, deathname = "level "..tostring(i-8).." of the Deimos base" }
	end
	for i=17,23 do
		player.episode[i] = { style = table.random_pick{3,7}, name = "Hell L"..tostring(i-16), danger = i, deathname = "level "..tostring(i-16).." of Hell" }
	end
	player.episode[8]            = { script = "hellgate", style = 4, deathname = "the Hellgate" }
	player.episode[16]           = { script = "tower_of_babel", style = 9, deathname = "the Tower of Babel" }
	player.episode[24]           = { script = "dis", style = 4, deathname = "the City of Dis" }
	player.episode[25]           = { script = "hell_fortress", style = 4, deathname = "the Hell Fortress" }

	for _,pairing in ipairs(paired) do
		local level_proto = levels[table.random_pick(pairing)]
		if (not level_proto.canGenerate) or level_proto.canGenerate() then
			local index = core.resolve_range(level_proto.level)
			local from  = player.episode[index]
			table.insert( player.episode, { 
				script = level_proto.id,
				style  = from.style,
				danger = from.danger,
				depth  = from.depth,
				name   = level_proto.name,
				exit   = index + 1,
			} )
			from.special = #player.episode
		end
	end
	local slcount = 0
	for i=2,23 do
		if player.episode[i].special then
			slcount = slcount + 1
		end
	end
	statistics.bonus_levels_count = slcount
end

function drl.GetMOTD()
	return "{BSupport the game by buying the {LDRL expansion} at {Ljupiterhellclassic.com}!}"
end

function drl.GetLogoTexture()
	return "logo"
end

function drl.GetLogoBox()
	return
[[{rDRL version {R]]..VERSION_STRING..[[}
by {RKornel Kisielewicz}
graphics by {RDerek Yu}
and {RLukasz Sliwinski}}]]
end

function drl.GetLogoText()
	return
[[{rAdd. coding : {ytehtmi}, {yGame Hunter}, {yshark20061}, {yadd} and {ybrisbang}
Music tracks: {ySonic Clang} (remixes), {ySimon Volpert} (special levels)
HQ SFX      : {yPer Kristian Risvik}

Major changes since last version (see {yversion.txt} for full list)
{R  * tons of UI and UX changes, a lot new visual effects!
  * new L4 special levels by brisbang, two new environment fluids!
  * enrage mechanic, infighting, more nightmare variants, tons little stuff!
  
{B facebook.com/ChaosForge  x.com/chaosforge_org  discord.gg/jupiterhell}
                                       Press <{y{$input_ok}}> to continue...}
]]
end

function drl.OnWinGame()
	if kills.get("jc") > 0 then
		drl.plot_outro_final()
	elseif player.level_index >= 24 then
		if player.hp > 0 or player.level_index > 24 then
			drl.plot_outro_3()
		else
			drl.plot_outro_partial()
		end
	else
		return false
	end
	ui.plot_screen([[




             D**m, the Roguelike ]]..VERSION_STRING..[[

                   Congratulations!
           Look further for the next release
            on https://drl.chaosforge.org/]])
	ui.blood_slide()
	return true
end

function drl.GetFirstText()
	return
[[{yWelcome to {RD**m the Roguelike}!

You are running DRL for the first time. I hope you will find this roguelike game as enjoyable as it was for me to write it.

This game is in active development (again?), and as such please be always sure that you have the most recent version, for bugs are fixed, new features appear, and the game becomes better at every iteration. You can find the lastest version on DRL website:

{Bhttps://drl.chaosforge.org/}

Also, if you enjoy this game, join the Discord and/or the forums:

{Bhttp://discord.gg/jupiterhell}
{Bhttp://forum.chaosforge.org/}

You can also follow me on X ({B@chaosforge_org}/{B@epyoncf}).

Press <{L{$input_ok}}> to continue...}
]]
end

function drl.GetRandomName()
	-- TODO Add more names
	local names =
	{
		"Adam Ring",
		"Adrian Carmack",
		"Ashannar",
		"Bobby Prince",
		"Charchian",
		"Derek Yu",
		"Derrick Sund",
		"Eol Armok",
		"Grey",
		"Ian McTaggart",
		"Igor Savin",
		"Ilya Bely",
		"Jacob Orine",
		"John Romero",
		"Joseph Hewitt",
		"Material Defender",
		"Moog",
		"Nils Bloodaxe",
		"Phwop",
		"Rahul Chandra",
		"Sandy Peterson",
		"Stephen Ward",
		"Thomas Parasiuk",
		"Timo Viitanen",
		"Zalminen",
	}

	return names[math.random(#(names))]
end

function drl.get_special_item( pname )
	if DIFFICULTY > 3 then return nil end
	local name = string.gsub( string.lower( pname or "" ), " ", "_" )
	local matches = 
	{
		malek             = "umarmor",
		malek_deneith     = "umarmor",
		thelaptop         = "unboots",
		ian_mctaggart     = "unboots",
		sam_charchian     = "unullpointer",
		charchian         = "unullpointer",
		nullpointer       = "unullpointer",
		deathdealer       = "usubtle",
		phwop             = "usubtle",
		rchandra          = "umega",
		rahul_chandra     = "umega",
		material_defender = "umjoll",
		flame_us3r        = "umjoll",
		derrick_sund      = "ufshotgun",
		dtsund            = "ufshotgun",
	}
	if matches[ name ] or DIFFICULTY > 2 then
		return matches[ name ]
	end
	matches = 
	{
		alan_shaefer      = "uminigun",
		diablo            = "ubutcher",
		butcher           = "ubutcher",
		vash              = "utrigun",
		vash_stampede     = "utrigun",
		vash_the_stampede = "utrigun",
		alucard           = "ujackal",
		hellsing          = "ujackal",
		preston           = "uberetta",
		john_preston      = "uberetta",
		revenant          = "urbazooka",
		-- XXX What about "Gutts"?
	}
	return matches[ name ]
end

function drl.GetQuitMessage()
	-- TODO O/S specific messages (i.e. OSX, Linux etc)
	local messages = {
		"Don't leave -- there's a demon behind that corner!",
		"Your system will get overrun by imps!",
		"If I were your boss I'd deathmatch you in a minute!",
		"Let's beat it -- it's turning into a bloodbath!",
		"You're trying to say you like the internet better then me, eh?",
		"Please don't leave -- there're more demons to roast!",
		"I wouldn't leave if I were you. The internet is much worse!",
		"Get outta here and go back to your boring programs...!",
		"Go ahead and leave. See if I care.",
		"Ya know. Next time ya gonna come here, I'm gonna toast ya."
	}
	return messages[math.random(#(messages))]
end

function drl.GetItemMax( id )
	local result   = items[ id ].max
	if items[ id ].type == ITEMTYPE_AMMO then
		local backpack = player:get_property( "BACKPACK", 0 )
		if backpack > 0 then
			result = math.ceil( result * ( 1 + backpack * 0.1 ) )
		end
	end
	return result
end

function drl.OnGenerate()
	core.log("drl.OnGenerate()")

	local dlevel = level.danger_level
	local choice = weight_table.new()
	for _,g in ipairs(generators) do
		if dlevel >= g.min_dlevel and DIFFICULTY >= g.min_diff then
			local weight = core.ranged_table( g.weight, dlevel ) 
			choice:add( g, weight )
		end
	end
	if choice:size() == 0 then error("NO GENERATOR AVAILABLE!") end
	local gen = choice:roll()
	generator.run( gen )
end

function drl.OnTick( time )
	if level.empty    then return end
	if time % 10 ~= 0 then return end
	time = time / 10 -- convert to seconds
	local enrage = 15*60 -- 15 minutes
	local stage1 = enrage - 2*60
	local stage2 = enrage - 1*60
	local stage3 = enrage -   10
	if time >= stage1 then
		if time == stage1 then
			ui.msg( "Demonic forces grow restless..." )
		elseif time == stage2 then
			ui.msg( "Demonic forces grow more restless..." )
		elseif time == stage3 then
			ui.msg( "The air grows thick with malice..." )
		end
		if time == enrage then
			ui.msg( "You hear angry growls!" )
			level.flags[ LF_ENRAGE ] = true
			for b in level:beings() do
				if not b:is_player() then
					b.flags[ BF_HUNTING ] = true
					b.expvalue = math.ceil( b.expvalue * 0.5 )
					b.speed    = math.min( math.ceil( b.speed * 1.5 ), 250 )
					b.accuracy = b.accuracy + 4
				end
			end
		end
		if time == enrage * 2 then
			for b in level:beings() do
				if not b:is_player() then
					b.expvalue = 0
					b.speed    = math.min( math.ceil( b.speed * 1.5 ), 250 )
					b.accuracy = b.accuracy + 4
				end
			end
		end
	end
end

function drl.OnCreate( this )
	if rawget( level, "__ptr" ) and level.flags[ LF_ENRAGE ] then
		if this:is_being() then
			if not this:is_player() then
				if not this.flags[ BF_HUNTING ] then
					this.flags[ BF_HUNTING ] = true
					this.expvalue = math.ceil( this.expvalue * 0.5 )
					this.speed    = math.ceil( this.speed * 1.5 )
					this.accuracy = this.accuracy + 4
				end
			end
		end
	end
end

drl.help = {
	{ "intro", "Introduction" },
	{ "start", "Getting started" },
	{ "gamepad", "Gamepad controls" },
	{ "keys", "Keyboard controls" },
	{ "mouse", "Mouse controls" },
	{ "feedback", "Feedback" },
	{ "disclaim", "Disclaimer" },
	{ "credits", "Credits" },
}

