function drl.register_rooms()

	register_room "lever_room"
	{
		weight      = 10,
		max_size_x  = 20,
		max_size_y  = 15,

		setup       = function ( room )
			local pos = level:random_empty_coord( { EF_NOBLOCK, EF_NOSTAIRS, EF_NOITEMS, EF_NOHARM, EF_NOSPAWN }, room )
			if not pos then return false end

			local lid = weight_table.new{
				lever_explode     = 2,
				lever_summon      = 2,
				lever_kill        = 3,
				lever_walls       = 3,
				lever_flood_water = 1,
				lever_flood_acid  = 1,
				lever_flood_lava  = 1,
				lever_repair      = 2,
				lever_medical     = 2,
				lever_ammo        = 2,
			}:roll()
		
			local proto = items[lid]
			local lever = item.new( lid )
			if lever:has_property("target_area") then
				lever.target_area = room:clone()
			end
			level:drop_item( lever, pos )

			if proto.fullchance and math.random(100) < proto.fullchance then
				lever.target_area = area.FULL:clone()
				if proto.warning then
					ui.msg_feel( proto.warning )
				end
			end
			return true
		end
	}

	register_room "teleport_room"
	{
		weight      = 5,

		setup       = function ( room )
			local floors = room:shrinked()
			local tries = 5
			local pos
			repeat
				tries = tries - 1
				if tries == 0 then return false end
				pos = floors:random_coord()
			until level:cross_around( pos, generator.styles[ level.style ].floor ) > 2
			level:drop_item( "teleport", pos )
			return true
		end,
	}

	register_room "ammo_room"
	{
		weight      = 5,
		min_size    = 4,

		setup       = function ( room )
			local entries = {
				{ 4, "pammo", 1, 2 },
				{ 3, "pshell", 1, 2 },
				{ 25, "ammo", 3, 5 },
				{ 25, "shell", 3, 5 },
			}
			local roll = math.random(3) + level.danger_level
			if roll > 11 then
				table.insert( entries, { 4, "procket", 1, 2 } )
				table.insert( entries, { 25, "rocket", 3, 5 } )
			end
			if roll > 14 then
				table.insert( entries, { 3, "pcell", 1, 2 } )
				table.insert( entries, { 25, "cell", 3, 5 } )
			end
			local range = 0
			for _, entry in ipairs( entries ) do
				range = range + entry[1]
			end
			local pick = math.random( range )
			for _, entry in ipairs( entries ) do
				pick = pick - entry[1]
				if pick <= 0 then
					local amount = math.random( entry[3], entry[4] )
					level:area_drop( room, entry[2], amount, true )
					return true
				end
			end
			return false
		end,
	}

	register_room "basain_room"
	{
		weight      = 7,
		min_size    = 4,
		max_area    = 140,

		setup       = function ( room )
			local fill
			local roll = math.random(10) + math.floor( level.danger_level / 5 )
			if roll < 8  then fill = "water"
			elseif roll < 13 then fill = "acid"
			else fill = "lava" end
			local roll = math.random(3)
			local big  = room:dim().x >= 6 and room:dim().y >= 6 
			if roll < 3 and big then
				level:fill( "bridge", room:shrinked() )
				level:fill( fill, room:shrinked(2) )
			else
				level:fill( fill, room:shrinked() )
			end
			return true
		end,
	}

	register_room "warehouse_room"
	{
		weight      = 20,
		min_size    = 8,

		setup       = function ( room )
			generator.warehouse_fill( { "crate", "ycrate" }, room:shrinked(), 2, 30, 5, {"crate_armor","crate_ammo"} )
			return true
		end,
	}

	register_room "vault_room"
	{
		weight      = 5,
		min_size    = 8,
		max_size_x  = 26,
		max_size_y  = 14,
		tags        = { "monsters" },

		setup       = function ( room, room_meta, room_list )
			local fill, keypos
			local space = 1
			room_meta.used = true
			local room2 = generator.get_room( room_list, 4,100,100)
			if room_meta.dims.x > 10 and room_meta.dims.y > 10 and math.random(2) == 1 then
				space = 2
			end
			if room2 then
				keypos = level:random_empty_coord( { EF_NOBLOCK, EF_NOSTAIRS, EF_NOITEMS, EF_NOHARM, EF_NOSPAWN }, room2.area )
			end
			local locked = (keypos ~= nil) and (math.random(25) < level.danger_level) and (math.random(4) == 1)
			if locked then
				room2.used = true
				local lever = level:drop_item( "lever_walls", keypos )
				lever.flags[ IF_NODESTROY ] = true
				lever:add_property( "target_area", room:shrinked(1) )
			end

			local vault = room:shrinked(2)

			if locked then
				level:fill( "rwall", vault )
				generator.set_permanence( vault )
			else
				level:fill( "wall", vault )
				level:set_cell( vault:random_inner_edge_coord(), generator.styles[ level.style ].door )
			end
			vault:shrink()
			level:fill( "floor", vault )

			local roll = math.max( math.random( 5 ) + level.danger_level + (DIFFICULTY-2)*3, 1 )
			local diffmod = (DIFFICULTY - 2)*2
			local exotic_mod = 1.5
			local unique_mod = 2
			if diffmod > 0 then diffmod = math.random( diffmod ) end

			if locked then
				roll = roll+5
				exotic_mod = 3
				unique_mod = 4
			end

			local being
			    if roll < 4  then being = 'former'
			elseif roll < 10 then being = 'lostsoul'
			elseif roll < 15 then being = 'demon'
			elseif roll < 30 then being = 'cacodemon'
			else
				being = 'cacodemon'
				if roll % 6 == 4 then being = "ncacodemon" end
				if roll % 6 == 5 then being = "ndemon" end
				if roll % 6 == 3 then being = "nimp" end
			end

			level:summon{ being, math.random(4)+2+diffmod, area = vault }

			local amount = math.random(3)+2
			for i=1,amount do
				local pos = level:random_empty_coord( { EF_NOBLOCK, EF_NOSTAIRS, EF_NOITEMS, EF_NOHARM, EF_NOSPAWN }, vault )
				if not pos then break end
				local item = level:roll_item{
					level = roll+3,
					type = { ITEMTYPE_ARMOR, ITEMTYPE_AMMO, ITEMTYPE_RANGED, ITEMTYPE_PACK },
					unique_mod = unique_mod,
					exotic_mod = exotic_mod,
				}
				level:drop_item( item, pos, true )
			end

			generator.scatter_blood(vault,nil,30)
			level:set_light_flag( vault, LFNOSPAWN, true )

			ui.msg_feel( table.random_pick{
				"You feel excited!",
				"There's the smell of blood in the air!",
				"There's something special here..."
			})

			return true
		end,
	}
end
