function drl.register_events()

	register_event "ice_event"
	{
		min_dlevel = 16,
		weight     = 2,
		history    = "On @1, hell froze over!",
		message    = "Yes... Hell just froze over...",
		
		setup      = function()
			generator.wall_to_ice[ generator.styles[ level.style ].wall ] = "iwall"

			for c in area.FULL:coords() do
				local cell = generator.wall_to_ice[ cells[level:get_cell( c )].id ]
				if cell then
					level:set_cell( c, cell )
				end
			end
		end,
	}

	register_event "perma_event"
	{
		history    = "@1 was a hard nut to crack!",
		message    = "The walls here seem tough!",
		min_dlevel = 8,
		weight     = 4,
		
		setup      = function()
			generator.set_permanence( area.FULL )
		end,
	}

	register_event "alarm_event"
	{
		history    = "He sounded the alarm on @1!",
		message    = "As you enter, some weird alarm starts howling!",
		min_dlevel = 8,
		weight     = 2,

		setup      = function()
			for b in level:beings() do b.flags[ BF_HUNTING ] = true end
		end,
	}

	register_event "deadly_air_event"
	{
		history    = "@1 blasted him with an unholy atmosphere!",
		message    = "The air seems deadly here, you better leave quick!",
		min_dlevel = 16,
		min_diff   = 2,
		weight     = 2,

		setup      = function()
			level.data.event.timer = 0
			level.data.event.step  = 100 - DIFFICULTY * 5
		end,
		on_tick    = function()
			local function chill( b )
				if b.hp > b.hpmax / 4 and not b.flags[BF_INV] then
					if not b:is_player() or not b:is_perk("enviro") then
						b:msg( "You feel a deadly chill!" )
						b.hp = b.hp - 1
					end
				end
			end
			local data = level.data.event
			data.timer = data.timer + 1
			if data.timer == data.step then
				data.timer = 0
				for b in level:beings() do
					chill(b)
				end
				chill(player)
			end
		end
	}

	register_event "nuke_event"
	{
		history    = "On @1 he encountered an armed nuke!",
		min_dlevel = 16,
		min_diff   = 2,
		weight     = 2,

		setup      = function()
			local minutes = 10 - DIFFICULTY
			ui.msg_feel("Descending the staircase you spot a familiar object...")
			ui.msg_feel("\"Thermonuclear bomb deployed. "..minutes.." minutes till explosion.\"")
			player:nuke( minutes*60*10 )
		end,
	}

	register_event "flood_acid_event"
	{
		message    = "You feel the sudden need to run!!!",
		history    = "On @1 he ran for his life from acid!" ,
		min_dlevel = 8,
		weight     = 1,

		setup      = function()
			local data      = level.data.event
			data.timer      = 0
			data.step       = math.max( 200 - level.danger_level - DIFFICULTY * 5, 60 )
			data.direction  = (math.random(2)*2)-3
			data.flood_min  = 0
			data.cell		= "acid"
			if data.direction == -1 then
				data.flood_min = 80
			else
				data.direction = 1
			end
		
			local left  = generator.safe_empty_coord( area(2,2,20,19) )
			local right = generator.safe_empty_coord( area(60,2,78,19) )

			for c in level:each("stairs") do
				level.map[ c ] = generator.styles[ level.style ].floor
			end

			if data.direction == 1 then left, right = right, left end
			player:displace( right )
			level.map[ left ] = "stairs"
		end,
		on_tick = generator.events_flood_tick,
	}

	register_event "flood_lava_event"
	{
		message    = "You feel the sudden need to run!!!",
		history    = "On @1 he ran for his life from lava!" ,
		weight     = 4,
		min_dlevel = 17,
		min_diff   = 3,

		setup      = function()
			local data      = level.data.event
			data.timer      = 0
			data.step       = math.max( 200 - level.danger_level - DIFFICULTY * 5, 40 )
			data.direction  = (math.random(2)*2)-3
			data.flood_min  = 0
			data.cell		= "lava"
			if data.direction == -1 then
				data.flood_min = 80
			else
				data.direction = 1
			end
			
			if level.danger_level > 20 and math.random(5) == 1 then
				data.step = 25
			end

			local left  = generator.safe_empty_coord( area(2,2,20,19) )
			local right = generator.safe_empty_coord( area(60,2,78,19) )

			for c in level:each("stairs") do
				level.map[ c ] = generator.styles[ level.style ].floor
			end

			if data.direction == 1 then left, right = right, left end
			player:displace( right )
			level.map[ left ] = "stairs"
		end,
		on_tick = generator.events_flood_tick,
	}

	register_event "targeted_event"
	{
		message    = "You feel you're being targeted!",
		history    = "On @1 he was targeted for extermination!" ,
		weight     = 2,
		min_dlevel = 17,
		min_diff   = 3,

		setup      = function()
			level.data.event.timer = 0
			level.data.event.step  = math.max( 100 - DIFFICULTY * 10, 50 )
		end,
		on_tick    = function()
			level.data.event.timer = level.data.event.timer + 1
			if level.data.event.timer == level.data.event.step then
				level.data.event.timer = 0
				local list = {}
				local cp = player.position
				for b in level:beings() do
					if not b:is_player() and cp:distance( b.position ) > 9 then
						table.insert( list, b )
					end
				end
				if #list == 0 then return end
				local near_area = area.around( cp, 8 )
				local c 
				local count = 0
				repeat
					if count > 50 then return end
					c = level:random_empty_coord( { EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK, EF_NOHARM, EF_NOSPAWN }, near_area )
					if c == nil then return end -- If the random coordinate selector didn't find a space, just dump.  No need to call it 50 times.
					count = count + 1
				until c:distance( cp ) > 2 and level:eye_contact( c, cp )
				local b = table.random_pick( list )
				-- TODO We need a better way to deal with articles.  Removing this one for now.
				ui.msg( "Suddenly, "..b.name.." appears near you!" )
				b:relocate( c )
				b:play_sound("phasing")
				b.scount = b.scount - math.max( 1000 - DIFFICULTY * 50, 500 )
				level:explosion( b.position, { range = 1, delay = 50, color = LIGHTBLUE } )
			end
		end

	}

	register_event "explosion_event"
	{
		message    = "You hear sounds of hellish mortars!",
		history    = "On @1 he was bombarded!" ,
		weight     = 1,
		min_dlevel = 18,
		min_diff   = 2,

		setup      = function()
			local data   = level.data.event
			data.enext   = math.max( 100 - DIFFICULTY * 10, 50 )
			data.hstep   = math.ceil( data.enext / 2 )
			data.size    = 2
			data.dice    = math.min( math.max( math.ceil( (level.danger_level + 2*DIFFICULTY) / 10 ), 2 ), 5 )
			data.content = nil
		end,
		on_tick    = generator.events_explosion_tick,
	}

	register_event "explosion_lava_event"
	{
		message    = "You hear sounds of hellish mortars! They rolled out the BIG GUNS!",
		history    = "On @1 he was walking in fire!" ,
		weight     = 1,
		min_dlevel = 25,
		min_diff   = 3,

		setup      = function()
			local data   = level.data.event
			data.enext   = math.max( 100 - DIFFICULTY * 10, 50 )
			data.hstep   = math.ceil( data.enext / 2 )
			data.size    = {2,3}
			data.dice    = math.min( math.max( math.ceil( (level.danger_level + 5*DIFFICULTY) / 25 ), 3 ), 6 )
			data.content = "lava"
		end,
		on_tick    = generator.events_explosion_tick,
	}

	register_event "darkness_event"
	{
		message    = "This floor is pitch-black!",
		history    = "On @1 he was stumbling in the dark!",
		weight     = 2,
		min_dlevel = 9,
		min_diff   = 2,

		setup      = function ()
			local data = level.data.event
			data.old_stairsense = player.flags[ BF_STAIRSENSE ]
			data.old_darkness   = player.flags[ BF_DARKNESS ]
			player.vision = player.vision - 2
			player.flags[ BF_DARKNESS ]   = true
			player.flags[ BF_STAIRSENSE ] = false
		end,
		on_leave      = function ()
			local data = level.data.event
			player.flags[ BF_DARKNESS ]   = data.old_darkness
			player.flags[ BF_STAIRSENSE ] = data.old_stairsense
			player.vision = player.vision + 2
		end,
	}
end

function generator.events_explosion_tick()
	local data = level.data.event
	data.enext = data.enext - 1
	if data.enext == 0 then
		data.enext = data.hstep + math.random( data.hstep * 2 )
		local c = level:random_empty_coord( { EF_NOBEINGS, EF_NOITEMS, EF_NOSTAIRS, EF_NOBLOCK } )
		if not c then return end
		local range = data.size
		if type( data.size ) == "table" then
			range = math.random( data.size[1], data.size[2] )
		end
		level:explosion( c, { range = range, delay = 50, damage = data.dice.. "d6", color = LIGHTRED, sound_id = "barrel.explode", flags = { EFRANDOMCONTENT }, content = data.content } )
	end
end


function generator.events_flood_tick()
	local flood_tile = function( pos, cell )
		local cell_data = cells[ level:get_cell( pos ) ]
		if not cell_data.flags[ CF_CRITICAL ] then
			level:set_cell( pos, cell )
		end
		if cell_data.OnDestroy then cell_data.OnDestroy(pos) end
		level:try_destroy_item( pos )
	end
	local data = level.data.event
	data.timer = data.timer + 1
	if data.timer == data.step then
		data.timer = 0
		data.flood_min = data.flood_min + data.direction
		if data.flood_min >= 1 and data.flood_min <= MAXX then
			for y = 1,MAXY do
				flood_tile( coord( data.flood_min, y ), data.cell )
			end
		end
		if data.flood_min + data.direction >= 1 and data.flood_min + data.direction  <= MAXX then
			local switch = false
			for y = 1,MAXY do
				if switch then
					flood_tile( coord( data.flood_min + data.direction, y ), data.cell )
				end
				if math.random(4) == 1 then switch = not switch end
			end
		end
	end
	level:recalc_fluids()
end

