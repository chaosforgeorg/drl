core.declare( "mortem", {} )

mortem.Pronoun = "He"

function mortem.version_string( v )
	local result = v[1].."."..v[2].."."..v[3]
	if v[4] then result = result.."."..v[4] end
	return result
end

function mortem.padded( str, size )
    return str..string.rep(" ",math.max(0,size - string.len(str)) )
end


function mortem.print_time_and_kills()
    player:mortem_print( " "..mortem.Pronoun.." survived {!"..statistics.game_time.."} turns and scored {!"..player.score.."} points. ")
	player:mortem_print( " "..mortem.Pronoun.." played for {!"..core.seconds_to_string(math.floor(statistics.real_time)).."}. ")
	player:mortem_print( " "..diff[DIFFICULTY].description)
	player:mortem_print()


	local k   = statistics.kills
	local mk  = statistics.max_kills
	local uk  = statistics.unique_kills
	local muk = statistics.max_unique_kills
	local ratio = uk / muk

	player:mortem_print( " "..mortem.Pronoun.." killed {!"..uk.."} out of {!"..muk.."} encountered hellspawn. ({!"..math.floor(ratio*100).."%})" )
	if uk ~= k or muk ~= mk then
		player:mortem_print( " "..mortem.Pronoun.." killed {!"..k.."} out of {!"..mk.."} enemy spawns total." )
	end
end

function mortem.print_challenge()
	if CHALLENGE ~= "" then
		if ARCHANGEL then
			player:mortem_print( " "..mortem.Pronoun.." was an {!"..chal[CHALLENGE].arch_name.."}!")
		else
			player:mortem_print( " "..mortem.Pronoun.." was an {!"..chal[CHALLENGE].name.."}!")
		end
		if SCHALLENGE ~= "" then
			player:mortem_print( " "..mortem.Pronoun.." was also an {!"..chal[SCHALLENGE].name.."}!")
		end
	end
end

function mortem.print_crash_save()
    local function times( n )
		if n <= 1 then return "once" else return n.." times" end
	end

	if statistics.save_count > 0 or statistics.crash_count > 0 then
		player:mortem_print()
		if statistics.crash_count > 0 then
			player:mortem_print(" The world crashed {!"..times( statistics.crash_count ).."}." )
		end
		if statistics.save_count > 0 then
			player:mortem_print(" "..mortem.Pronoun.." saved {!"..times( statistics.save_count ).."}.")
		end
	end
end

function mortem.print_special_levels()
    player:mortem_print("  Levels generated : {!"..statistics.bonus_levels_count.."}")
    player:mortem_print("  Levels visited   : {!"..statistics.bonus_levels_visited.."}") 
    player:mortem_print("  Levels completed : {!"..statistics.bonus_levels_completed.."}")
end

function mortem.print_awards( awards_only )
	local awarded = false

	if not awards_only then
		for k,v in ipairs( medals ) do
			if player:has_medal( v.id ) then
				player:mortem_print( "  {!"..mortem.padded( v.name, 26 ).."} "..v.desc )
				awarded = true
			end
		end

		for k,v in ipairs( badges ) do
			if player:has_badge( v.id ) then
				player:mortem_print( "  {!"..mortem.padded( v.name, 26 ).."} "..v.desc )
				awarded = true
			end
		end
	end

	for k,v in ipairs( awards ) do
		if player:has_award( v.id ) then
			player:mortem_print( "  {!"..v.name.."} ({!"..v.levels[ player:get_award( v.id ) ].name.."})" )
			awarded = true
		end
	end

	if not awarded then
		player:mortem_print("  None")
	end
end

function mortem.print_graveyard()
	-- TODO This would be a good place to use utf-8 expansions for the high-ascii text.
	local function get_pic( c )
		local being = level:get_being( c )
		if being then
			if string.char(being.picture) == '@' then return 'X' end
			return string.char(being.picture)
		end
		local item = level:get_item( c )
		if item then
			return string.char(item.picture)
		end
		local cell = level:get_cell( c )
		return cells[ cell ].asciilow
	end

	for vy = 1,MAXY do
		local line = "  "
		for vx = math.min( 20, math.max( 1,player.x - 30 ) ), math.min( 20, math.max(1,player.x - 30 ) ) + MAXX - 20 do
			line = line..get_pic( coord( vx, vy ) )
		end
		player:mortem_print( line )
	end
end

function mortem.print_statistics()
	local function bonus( val ) if val < 0 then return "{!"..val.."}" else return "{!+"..val.."}" end end

	player:mortem_print( "  Health {!"..player.hp.."}/{!"..player.hpmax.."}   Experience {!"..player.exp.."}/{!"..player.explevel.."}" )
	player:mortem_print("  ToHit Ranged "..bonus( player:get_tohit() )..
						"  ToHit Melee "..bonus( player:get_tohit(true) )..
						"  ToDmg Ranged "..bonus( player:get_todam() )..
						"  ToDmg Melee "..bonus( player:get_todam(true) ) )
end

function mortem.print_traits()
    if klasses.__counter > 1 then
        player:mortem_print( "  Class : {!"..klasses[player.klass].name.."}" )
	    player:mortem_print()
    end

	for i = 1,traits.__counter do
		local value = player:get_trait(i)
		if value > 0 and traits[i].name ~= "" then
			player:mortem_print( "    "..mortem.padded(traits[i].name,16).." (Level {!"..value.."})" )
		end
	end

	if player.explevel > 1 then
		player:mortem_print()
		player:mortem_print("  "..player:get_trait_hist() )
	end
end

function mortem.print_equipment()
	local slot_name = { "[ Armor      ]", "[ Weapon     ]", "[ Boots      ]", "[ Prepared   ]", "[ Relic      ]" }
	local eq_size = core.options.relic_slot and MAX_EQ_SIZE or (MAX_EQ_SIZE - 1)

	for i = 0,eq_size-1 do
		local it = player.eq[i]
		if it then
			player:mortem_print( "    "..slot_name[i+1].."   {!"..it.desc.."}" )
		else
			player:mortem_print( "    "..slot_name[i+1].."   nothing" )
		end
	end
end

function mortem.print_inventory()
    local items = {}

	for it in player.inv:items() do
		table.insert( items, { itype = it.itype, nid = it.__proto.nid, desc = it.desc } )
	end

	table.sort( items, function(a,b) if (a.itype ~= b.itype) then return a.itype < b.itype else return a.nid < b.nid end end )

	for k,v in ipairs(items) do
		player:mortem_print( "    "..v.desc )
	end
end

mortem.resistance_count = 0

function mortem.print_resistance( name )
    local internal = player.resist[name] or 0
    local torso    = player:get_total_resistance(name, TARGET_TORSO)
    local feet     = player:get_total_resistance(name, TARGET_FEET)

    if internal == 0 and torso == 0 and feet == 0 then return end

    player:mortem_print( "    "..mortem.padded( name, 10 ).." - "..
    "internal {!"..mortem.padded( internal.."%", 5 ).."} "..
    "torso {!"..mortem.padded( torso.."%", 5 ).."} "..
    "feet {!"..mortem.padded( feet.."%", 5 ).."}"
    )

    mortem.resistance_count = mortem.resistance_count + 1
end

function mortem.print_resistances()
    mortem.resistance_count = 0
	mortem.print_resistance( "bullet" )
	mortem.print_resistance( "melee" )
	mortem.print_resistance( "shrapnel" )
	mortem.print_resistance( "acid" )
	mortem.print_resistance( "fire" )
	mortem.print_resistance( "cold" )
	mortem.print_resistance( "poison" )
	mortem.print_resistance( "plasma" )
	if mortem.resistance_count == 0 then
		player:mortem_print("    None")
	end
end

function mortem.print_kills()
	for _,b in ipairs( beings ) do
		local kills = kills.get(b.id)
		if kills > 0 then
			if kills == 1 then
				player:mortem_print( "    {!1} "..b.name )
			else
				player:mortem_print( "    {!"..kills.."} "..b.name_plural )
			end
		end
	end
end

function mortem.print_history()
	for _,v in pairs( player.__props.history ) do
		player:mortem_print( "  "..v )
	end
end

function mortem.print_messages()
	for i = 15,0,-1 do
		local msg = ui.msg_history(i)
		if msg then player:mortem_print( " ".. msg ) end
	end
end