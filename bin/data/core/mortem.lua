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

function mortem.get_death_description( killedby, killedmelee, highscore, reasons )
	if reasons and reasons[killedby] then
		return reasons[killedby]
	end

	local killer = beings[killedby]
	if not killer then return nil end
	if not highscore then
		local description
		if killedmelee then
			description = killer.kill_desc_melee
		else
			description = killer.kill_desc
		end
		if description then return description end
	end
	return "killed by "..killer.name
end


function mortem.append_time_and_kills( lines )
    table.insert( lines, " "..mortem.Pronoun.." survived {!"..statistics.game_time.."} turns and scored {!"..player.score.."} points. " )
	table.insert( lines, " "..mortem.Pronoun.." played for {!"..core.seconds_to_string(math.floor(statistics.real_time)).."}. " )
	table.insert( lines, " "..diff[DIFFICULTY].description )
	table.insert( lines, " Game seed was {!"..GAME_SEED.."}." )
	table.insert( lines, "" )


	local k   = statistics.kills
	local mk  = statistics.max_kills
	local uk  = statistics.unique_kills
	local muk = statistics.max_unique_kills
	local ratio = uk / muk

	table.insert( lines, " "..mortem.Pronoun.." killed {!"..uk.."} out of {!"..muk.."} encountered hellspawn. ({!"..math.floor(ratio*100).."%})" )
	if uk ~= k or muk ~= mk then
		table.insert( lines, " "..mortem.Pronoun.." killed {!"..k.."} out of {!"..mk.."} enemy spawns total." )
	end
end

function mortem.append_challenge( lines )
	if CHALLENGE ~= "" then
		if ARCHANGEL then
			table.insert( lines, " "..mortem.Pronoun.." was an {!"..chal[CHALLENGE].arch_name.."}!" )
		else
			table.insert( lines, " "..mortem.Pronoun.." was an {!"..chal[CHALLENGE].name.."}!" )
		end
		if SCHALLENGE ~= "" then
			table.insert( lines, " "..mortem.Pronoun.." was also an {!"..chal[SCHALLENGE].name.."}!" )
		end
	end
end

function mortem.append_crash_save( lines )
    local function times( n )
		if n <= 1 then return "once" else return n.." times" end
	end

	if statistics.save_count > 0 or statistics.crash_count > 0 then
		table.insert( lines, "" )
		if statistics.crash_count > 0 then
			table.insert( lines, " The world crashed {!"..times( statistics.crash_count ).."}." )
		end
		if statistics.save_count > 0 then
			table.insert( lines, " "..mortem.Pronoun.." saved {!"..times( statistics.save_count ).."}." )
		end
	end
end

function mortem.append_special_levels( lines )
    table.insert( lines, "  Levels generated : {!"..statistics.bonus_levels_count.."}" )
    table.insert( lines, "  Levels visited   : {!"..statistics.bonus_levels_visited.."}" )
    table.insert( lines, "  Levels completed : {!"..statistics.bonus_levels_completed.."}" )
end

function mortem.append_awards( lines, awards_only )
	local awarded = false

	if not awards_only then
		for k,v in ipairs( medals ) do
			if player:has_medal( v.id ) then
				table.insert( lines, "  {!"..mortem.padded( v.name, 26 ).."} "..v.desc )
				awarded = true
			end
		end

		for k,v in ipairs( badges ) do
			if player:has_badge( v.id ) then
				table.insert( lines, "  {!"..mortem.padded( v.name, 26 ).."} "..v.desc )
				awarded = true
			end
		end
	end

	for k,v in ipairs( awards ) do
		if player:has_award( v.id ) then
			table.insert( lines, "  {!"..v.name.."} ({!"..v.levels[ player:get_award( v.id ) ].name.."})" )
			awarded = true
		end
	end

	if not awarded then
		table.insert( lines, "  None" )
	end
end

function mortem.append_graveyard( lines )
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
		table.insert( lines, line )
	end
end

function mortem.append_statistics( lines )
	local function bonus( val ) if val < 0 then return "{!"..val.."}" else return "{!+"..val.."}" end end

	table.insert( lines, "  Health {!"..player.hp.."}/{!"..player.hpmax.."}   Experience {!"..player.exp.."}/{!"..player.explevel.."}" )
	table.insert( lines, "  ToHit Ranged "..bonus( player:get_tohit() )..
						"  ToHit Melee "..bonus( player:get_tohit(true) )..
						"  ToDmg Ranged "..bonus( player:get_todam() )..
						"  ToDmg Melee "..bonus( player:get_todam(true) ) )
end

function mortem.append_damage_and_spree( lines )
	table.insert( lines, "" )
	table.insert( lines, "  Damage taken       : {!"..statistics.damage_taken.."}" )
	table.insert( lines, "  Longest kill spree : {!"..statistics.kills_non_damage.."}" )
end

function mortem.append_traits( lines )
    if klasses.__counter > 1 then
        table.insert( lines, "  Class : {!"..klasses[player.klass].name.."}" )
	    table.insert( lines, "" )
    end

	for i = 1,traits.__counter do
		local value = player:get_trait(i)
		if value > 0 and traits[i].name ~= "" then
			table.insert( lines, "    "..mortem.padded(traits[i].name,16).." (Level {!"..value.."})" )
		end
	end

	if player.explevel > 1 then
		table.insert( lines, "" )
		table.insert( lines, "  "..player:get_trait_hist() )
	end
end

function mortem.item_desc( item )
	return item.inv_name
end

function mortem.append_equipment( lines, item_desc )
	item_desc = item_desc or mortem.item_desc
	local slot_name = { "[ Armor      ]", "[ Weapon     ]", "[ Boots      ]", "[ Prepared   ]", "[ Relic      ]" }
	local eq_size = core.options.relic_slot and MAX_EQ_SIZE or (MAX_EQ_SIZE - 1)

	for i = 0,eq_size-1 do
		local it = player.eq[i]
		if it then
			table.insert( lines, "    "..slot_name[i+1].."   {!"..item_desc( it ).."}" )
		else
			table.insert( lines, "    "..slot_name[i+1].."   nothing" )
		end
	end
end

function mortem.append_inventory( lines, item_desc )
	item_desc = item_desc or mortem.item_desc
    local items = {}

	for it in player.inv:items() do
		table.insert( items, { itype = it.itype, nid = it.__proto.nid, desc = item_desc( it ) } )
	end

	table.sort( items, function(a,b) if (a.itype ~= b.itype) then return a.itype < b.itype else return a.nid < b.nid end end )

	for k,v in ipairs(items) do
		table.insert( lines, "    "..v.desc )
	end
end

function mortem.append_resistance( lines, name )
    local internal = player.resist[name] or 0
    local torso    = player:get_total_resistance(name, TARGET_TORSO)
    local feet     = player:get_total_resistance(name, TARGET_FEET)

    if internal == 0 and torso == 0 and feet == 0 then return end

    table.insert( lines, "    "..mortem.padded( name, 10 ).." - "..
    "internal {!"..mortem.padded( internal.."%", 5 ).."} "..
    "torso {!"..mortem.padded( torso.."%", 5 ).."} "..
    "feet {!"..mortem.padded( feet.."%", 5 ).."}" )

end

function mortem.append_resistances( lines )
	local first = #lines
	mortem.append_resistance( lines, "bullet" )
	mortem.append_resistance( lines, "melee" )
	mortem.append_resistance( lines, "shrapnel" )
	mortem.append_resistance( lines, "acid" )
	mortem.append_resistance( lines, "fire" )
	mortem.append_resistance( lines, "cold" )
	mortem.append_resistance( lines, "poison" )
	mortem.append_resistance( lines, "plasma" )
	if #lines == first then
		table.insert( lines, "    None" )
	end
end

function mortem.append_kills( lines )
	for _,b in ipairs( beings ) do
		local kills = kills.get(b.id)
		if kills > 0 then
			if kills == 1 then
				table.insert( lines, "    {!1} "..b.name )
			else
				table.insert( lines, "    {!"..kills.."} "..b.name_plural )
			end
		end
	end
end

function mortem.append_weapon_kills( lines, groups, names )
	for index,group in ipairs( groups ) do
		local count = core.kills_count_group( group )
		if count > 0 then
			table.insert( lines, "    "..names[index].."{!"..count.."}" )
		end
	end

	local unarmed = kills.get_type( "melee" )
	local other = kills.get_type( "other" )
	if unarmed > 0 or other > 0 then
		table.insert( lines, "" )
	end

	if unarmed > 0 then
		table.insert( lines, "    Unarmed kills  : {!"..unarmed.."}" )
	end

	if other > 0 then
		table.insert( lines, "    Other kills    : {!"..other.."}" )
	end
end

function mortem.append_history( lines )
	for _,v in pairs( player.__props.history ) do
		table.insert( lines, "  "..v )
	end
end

function mortem.append_messages( lines )
	for i = 15,0,-1 do
		local msg = ui.msg_history(i)
		if msg then table.insert( lines, " ".. msg ) end
	end
end
