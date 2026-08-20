-- utils
function core.seconds_to_string( secs )
	local function plural( name, v )
		if v == 0 then return nil end
		if v > 1 then
			return v.." "..name.."s"
		else
			return v.." "..name
		end
	end

	if secs <= 0 then return "0 seconds" end

	local sec  = plural( "second", secs % 60 )
	local min  = plural( "minute", math.floor( secs / 60 ) % 60 )
	local hour = plural( "hour",   math.floor( secs / (60*60) ) % 24 )
	local day  = plural( "day",    math.floor( secs / (60*60*24) ) )
	local arr  = {}
	if day  then table.insert(arr, day) end
	if hour then table.insert(arr, hour) end
	if min  then table.insert(arr, min) end
	if sec  then table.insert(arr, sec) end

	if #arr > 1 then
		arr[ #arr - 1 ] = arr[ #arr - 1 ].." and "..arr[ #arr ]
		table.remove( arr )
	end
	return table.concat(arr, ", ")
end

function core.resolve_range(range)
	if type(range) == "number" then return range end
	if type(range) ~= "table" then error("bad range designation!") end
	return range[1] + math.random(range[2]-range[1]+1) - 1
end

function core.level_seed( script )
	if not script then
		return math.random( 1000000000 )
	end
	assert( levels[ script ], "unknown level: " .. script )
	return math.mix_seed( GAME_SEED, levels[ script ].nid )
end

function table.random_remove( t )
	assert( type( t ) == "table" )
	return table.remove( t, math.random( #t ) )
end
