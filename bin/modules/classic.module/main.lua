core.declare( "classic", {} )

require "classic:data/phobos_arena"

function classic.OnMortem()
	if not game.has_won() then return end
	
	local is_maxkills  = (statistics.unique_kills == statistics.max_unique_kills)
	local is_90kills   = (statistics.unique_kills >= statistics.max_unique_kills * 0.9)
	local is_zerodmg   = (statistics.damage_taken == 0)

	if DIFFICULTY >= DIFF_NIGHTMARE then 
		player:set_award( "classic_module_award", 3 )
		if is_90kills then player:set_award( "classic_module_award", 5 ) end
		if is_zerodmg then player:set_award( "classic_module_award", 6 ) end
	elseif DIFFICULTY >= DIFF_VERYHARD then
		player:set_award( "classic_module_award", 3 )
		if is_maxkills then player:set_award( "classic_module_award", 4 ) end
	elseif DIFFICULTY >= DIFF_HARD then
		player:set_award( "classic_module_award", 2 )
	else
		player:set_award( "classic_module_award", 1 )
	end
end

function classic.OnMortemPrint(killedby)
    if killedby == "defeated the Mastermind" then
        killedby = "defeated the Cyberdemon"
    end
    player:mortem_print( " "..player.name..", level "..player.explevel.." "..klasses[player.klass].name..", "..killedby )
end

function classic.OnCreateEpisode()
	local BOSS_LEVEL = 10
	player.episode = {}
  
	player.episode[1]     = { style = 1, script = "intro" }
	for i=2,BOSS_LEVEL-1 do
		player.episode[i] = { style = 1, number = i, name = "Phobos", danger = i}
	end
	player.episode[10]    = { style = 1, script = "phobos_arena" }
	
	statistics.bonus_levels_count = 0
end

function classic.OnGenerate()
	generator.reset()
	generator.run( generators.gen_tiled )
end

function classic.OnWinGame()
	ui.plot_screen([[
Once you beat the Cyberdemon and clean out the moon
base you're supposed to win, aren't you? Aren't you?
Where's your fat reward and ticket back home? What
the hell is this? It's not supposed to end this way!
      
It stinks like rotten meat but it looks like the
lost Deimos base. Looks like you're stuck on
The Shores of Hell. And the only way out is through...
]],RED)
end

