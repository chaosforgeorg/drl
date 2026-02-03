require( "core:constants" )
require( "core:commands" )
require( "core:functions" )
require( "core:bsp" )
require( "core:generator" )
require( "core:level" )
require( "core:thing" )
require( "core:being" )
require( "core:item" )
require( "core:player" )
require( "core:aitk" )
require( "core:blueprints" )
require( "core:ui" )
require( "core:mortem" )

core.options = {
	auto_glow_items = true,
	klass_achievements = false,
	new_menu = false,
	melee_move_on_kill = false,
	full_being_description = false,
	percent_health = true,
	assembly_apply_last_mod = false,
	relic_slot = false,
}

module = false

register_cell = core.register_storage( "cells", "cell", function( c )
		c.asciilow   = c.asciilow or c.ascii
		c.hp         = c.hp or c.armor
		if c.set then
			core.add_to_cell_set( c.set, c.nid )
			if not generator.cell_sets[ c.set ] then
				generator.cell_sets[ c.set ] = {}
			end
			generator.cell_sets[ c.set ][ c.id ] = true
			generator.cell_sets[ c.set ][ c.nid ] = true
			if not generator.cell_lists[ c.set ] then
				generator.cell_lists[ c.set ] = {}
			end
			table.insert( generator.cell_lists[ c.set ], c.nid )
		end
		core.register_cell( c.nid )
	end	
)

function register_corpse( being_proto, index, no_resurrect )
	local frames = being_proto.sframes or 1
	if frames < 1 then frames = 1 end
	frames = frames + (index or 0)
	local proto = {
		name = being_proto.name.." corpse";
		ascii = "%";
		color = RED;
		armor = math.max(being_proto.armor, 1);
		hp = being_proto.hp;
		flags = {CF_CORPSE, CF_NOCHANGE, CF_OVERLAY, CF_VBLOODY, CF_RAISABLE};
		sprite = being_proto.sprite + frames * DRL_COLS;
		set = CELLSET_FLOORS;
		destroyto = "bloodpool";
		raiseto = being_proto.id;
	}
	if no_resurrect then
		proto.flags = {CF_CORPSE, CF_NOCHANGE, CF_OVERLAY, CF_VBLOODY }
	end
	if being_proto.sflags[ SF_LARGE ] then
		proto.sflags = { SF_LARGE }
		proto.sprite = being_proto.sprite + frames * 2 * DRL_COLS
	end
	return register_cell( being_proto.id.."corpse" ) (proto)
end

register_room       = core.register_storage( "rooms", "room", function( r )
	r.tags = table.toset( r.tags )
end
)
register_difficulty = core.register_storage( "diff", "difficulty" )
register_medal      = core.register_storage( "medals", "medal" )
register_badge      = core.register_storage( "badges", "badge" )
register_perk       = core.register_storage( "perks", "perk", function (a) 
	a.tags = table.toset( a.tags )
	core.register_perk( a.nid ) 
end )
register_trait      = core.register_storage( "traits", "trait" )
register_ai         = core.register_storage( "ais", "ai" )
register_challenge  = core.register_storage( "chal", "challenge" )
register_itemset    = core.register_storage( "itemsets", "itemset" )
register_mod_array = core.register_storage( "mod_arrays", "mod_array", function (m) 
		m.sig   = core.mod_list_signature(m.mods)
		m.request_desc  = core.mod_array_description(m)
	end
)
register_klass      = core.register_storage( "klasses", "klass", function(k)
		k.sname = k.sname or k.name
		k.trait = {}
		for i,t in ipairs(k.traits) do
			assert(t.id, "id undefined!")
			assert(traits[t.id], t.id.." undefined!")
			local tnid = traits[t.id].nid
			k.trait[tnid] = t
			k.trait[t.id] = t
		end

		k.traitlist = {}
		for i,t in ipairs(k.traits) do
			k.traitlist[i] = traits[t.id].nid
			traits[t.id][k.id] = t
			t.id = traits[t.id].nid
			if type( t.requires ) == "table" then
				for k,v in ipairs( t.requires ) do
					assert(traits[v[1]], v[1].." undefined!")
					v[1] = traits[v[1]].nid
				end
			end
			if type( t.blocks ) == "table" then
				for ii,v in ipairs( t.blocks ) do
					t.blocks[ii] = traits[v].nid
				end
			end
		end
	end
)

function register_klass_badge( id )
	return function( b )
		local acid = b.achievement or ""
		if acid ~= "" then 
			acid = acid:gsub("^jhc_", "")
		end
		local function acv_id( sub )
			if acid ~= "" then 
				return "jhc_"..sub.."_"..acid
			end
			return ""
		end
		register_badge( "any_"..id )  {
			name = b.name,
			desc = b.desc.." as any class",
			level = b.level,
			set   = id,
			klass = "any",
			achievement = acv_id( "any" ),
		}
		for _,k in ipairs(klasses) do
			if k.OnPick then
				register_badge( k.id.."_"..id ) {
					name = k.sname.." "..b.name,
					desc = b.desc.." as "..k.sname,
					level = b.level,
					set   = id,
					klass = k.id,
					achievement = acv_id( k.id ),
				}
			end
		end
		register_badge( "all_"..id )  {
			name = "Master "..b.name,
			desc = b.desc.." w/each class",
			level = b.level,
			set   = id,
			klass = "all",
			achievement = acv_id( "all" ),
		}
	end
end

function check_condition( t )
	if t.challenge then
		local id = "challenge_"..t.challenge
		if not ( CHALLENGE == id or SCHALLENGE == id ) then
			return false
		end
	end
	if t.kills then
		if statistics.unique_kills < statistics.max_unique_kills * t.kills then
			return false
		end
	end
	if t.difficulty then
		if DIFFICULTY < t.difficulty then
			return false
		end
	end
	return true
end
 
function register_master_badge( id )
	return function( b )
		assert( b.mid )
		assert( b.klass, "Master badge '"..id.."' has no klass!" )
		assert( traits[b.mid], "Master trait '"..b.mid.."' not found!" )
		assert( traits[b.mid].master, "'"..b.mid.."' not a master trait!" )
		local name = traits[b.mid].name

		register_badge ( id.."_1" )
		{
			name  = name.." Bronze",
			desc  = "Reach {!Io} with {!"..name.."} master trait",
			level = 1,
			set   = id,
			klass = b.klass,
		}
		register_badge ( id.."_2" )
		{
			name = name.." Silver",
			desc = "Win game with {!"..name.."} master trait",
			level = 2,
			set   = id,
			klass = b.klass,
		}
		register_badge ( id.."_3" )
		{
			name = name.." Gold",
			desc = "Win game with {!"..name.."} on Hard+",
			level = 3,
			set   = id,
			klass = b.klass,
		}
		register_badge ( id.."_4" )
		{
			name = name.." Platinum",
			desc = b.platinum.description.. " with {!"..name.."} master",
			level = 4,
			set   = id,
			klass = b.klass,
			condition = function()
				return player:has_trait( b.mid ) and check_condition( b.platinum )
			end
		}
		register_badge ( id.."_5" )
		{
			name = name.." Diamond",
			desc = b.diamond.description.. " with {!"..name.."} master",
			level = 5,
			set   = id,
			klass = b.klass,
			condition = function()
				return player:has_trait( b.mid ) and check_condition( b.diamond )
			end
		}
	end
end

register_level   = core.register_storage( "levels", "level" )
levels.default = {}

register_requirement   = core.register_storage( "requirements", "requirement" )
register_rank_impl     = core.register_array_storage( "rank_storage", "rank" )

ranks = {}
register_rank = function( typ )
	return function( tab )
		tab.type = typ
		if not ranks[ typ ] then
			ranks[ typ ] = {}
			core.log("Registering rank type '"..typ.."'")
			table.insert( ranks, typ )
		end
		table.insert( ranks[ typ ], tab )
		register_rank_impl( tab )
		ranks[ typ ].__counter = #ranks[ typ ]
	end
end

register_being_group   = core.register_array_storage( "being_groups", "being_group", function( bgp )
	bgp.tags = table.toset( bgp.tags )
end
)

register_being         = core.register_storage( "beings", "being", function( bp )
		bp.name_plural = bp.name_plural or bp.name.."s"
		bp.tags        = table.toset( bp.tags )

		bp.xp = bp.xp or (bp.danger*bp.danger*3+20)
		bp.is_group = false

		if bp.ai_type and bp.ai_type ~= "" then
			local ai_proto = ais[ bp.ai_type ]
			assert(ai_proto ~= nil, "LUA: being["..bp.id.."] has unknown ai_type '"..bp.ai_type.."'!" )

			local OnCreate = function( self )
				self:add_property( "ai_type", bp.ai_type )
				if ai_proto.OnCreate then
					ai_proto.OnCreate( self )
				end
			end

			bp.OnCreate   = core.create_seq_function( OnCreate, bp.OnCreate )
			bp.OnAction   = core.create_seq_function( ai_proto.OnAction, bp.OnAction )
			bp.OnAction   = core.create_seq_function( aitk.OnAction, bp.OnAction )
			bp.OnAttacked = core.create_seq_function( bp.OnAttacked, ai_proto.OnAttacked )
		end

		if bp.weapon then
			local wid   = "nat_"..bp.id
			local ip    = bp.weapon
			ip.name     = ip.name or "ranged attack"
			if not ip.sound_id then
				if bp.sound_id and bp.sound_id ~= "" then
					ip.sound_id = bp.sound_id
				else
					ip.sound_id = bp.id
				end
			end
			ip.type     = ITEMTYPE_NRANGED
			ip.weight   = 0
			ip.sprite   = 0
			register_item( wid ) ( ip )
			ip.flags[ IF_NODROP ] = true
			ip.flags[ IF_NOAMMO ] = true

			local OnCreate = function( self )
				self.eq.weapon = item.new( wid )
			end

			bp.OnCreate = core.create_seq_function( OnCreate, bp.OnCreate )
		end

		if bp.corpse then
			if type(bp.corpse) == "number"  then bp.corpse = register_corpse(bp,bp.corpse)  end
			if type(bp.corpse) == "boolean" then bp.corpse = register_corpse(bp) end
			if type(bp.corpse) == "table"   then bp.corpse = register_corpse(bp,bp.corpse[1],bp.corpse[2]) end
			if type(bp.corpse) == "string"  then bp.corpse = cells[bp.corpse].nid end
		else
			bp.corpse = 0
		end

		local OnCreate = function (self)
			self:add_property( "resist", {} )
			if bp.resist then
				for k,v in pairs( bp.resist ) do
					self.resist[ k ] = v
				end
			end
		end
		bp.OnCreate = core.create_seq_function( OnCreate, bp.OnCreate )
	end
)

register_item          = core.register_storage( "items", "item", function( ip )
		local set = ip.set
		if set then
			ip.flags[ IF_SETITEM ] = true

			local OnEquip = function (self,being)
				if being:set_items( set ) == (itemsets[ set ].trigger - 1) then
					itemsets[ set ].OnEquip(self,being)
				end
			end

			local OnUnequip = function (self,being)
				if being:set_items( set ) == itemsets[ set ].trigger then
					itemsets[ set ].OnUnequip(self,being)
				end
			end

			ip.OnUnequip = core.create_seq_function( OnUnequip, ip.OnUnequip )
			ip.OnEquip  = core.create_seq_function( OnEquip, ip.OnEquip )
		end

		ip.tags        = table.toset( ip.tags )
		ip.flags[ ip.type ] = true
		ip.is_unique  = ip.flags[ IF_UNIQUE ] or false
		ip.is_exotic  = ip.flags[ IF_EXOTIC ] or false
		ip.is_special = ip.is_exotic or ip.is_unique

		if type(ip.ammo_id) == "string" then ip.ammo_id = items[ip.ammo_id].nid	end

		if ip.damage then
			local damage_dice, damage_sides, damage_bonus = string.match(ip.damage, "(%d+)d(%d+)([-+]?%d*)")
			ip.damage_dice = tonumber(damage_dice) or 0
			ip.damage_sides = tonumber(damage_sides) or 0
			ip.damage_bonus = tonumber(damage_bonus) or 0
		end

		if ip.explosion and ip.explosion.content then
			ip.explosion.content = cells[ip.explosion.content].nid
		end

		if ip.firstmsg then ip.OnFirstPickup = function () ui.msg("\""..ip.firstmsg.."\"") end end

		if core.options.auto_glow_items then
			if not ip.glow then
				if ip.flags[ IF_EXOTIC ] then 
					ip.glow  = { 1.0, 0.5, 1.0, 0.8 }
					ip.pglow = { 1.0, 0.5, 1.0, 0.8 }
				end
				if ip.flags[ IF_UNIQUE ] then
					ip.glow  = { 0.5, 1.0, 0.5, 0.8 }
					ip.pglow = { 0.5, 1.0, 0.5, 0.8 }
				end		
			end
		end	

		local OnCreate = function (self)
			self:add_property( "resist", {} )
			if ip.resist then
				for k,v in pairs( ip.resist ) do
					self.resist[ k ] = v
				end
			end
			self:add_property( "group", ip.group or "" )
			if ip.group == "shotgun" then
				self.flags[ IF_SHOTGUN ] = true
			end
		end
		ip.OnCreate = core.create_seq_function( OnCreate, ip.OnCreate )
	end
)

register_award = core.register_storage( "awards", "award" )

register_award_plain = function( id, name, t )
	local aid = id.."_module_award"
	if awards[aid] then return aid end
	t.module = id
	t.mname  = name
	register_award( aid )( t )
	return aid
end

function core.kills_count_group( weapon_group )
	local total = 0
	for _,item in ipairs( items ) do
		if item.group == weapon_group then
			total = total + kills.get_type(item.id)
		end
	end
	return total
end

function core.award_medals()
	-- Prefetch win condition
	local win = player:has_won()

	-- Iterate through the medals
	for _,medal_proto in ipairs(medals) do
		if medal_proto.condition and ( ( not medal_proto.winonly ) or win ) then
			if medal_proto.condition() then
				player:add_medal( medal_proto.id )
				--if the player already has lesser medals in their player.wad, remove them from mortem
				if medal_proto.removes then
					for _,zero_medal in ipairs(medal_proto.removes) do
						local medal_count = player_data.get_counted( 'medals', 'medal', zero_medal )
						if medal_count <= 0 then
							player:add_medal( zero_medal )
						else
							player:remove_medal( zero_medal )
						end
					end
				end
			end
		end
	end
	-- Check for challenge medal removals
	if CHALLENGE ~= "" then
		player:remove_medals( chal[CHALLENGE].removemedals )
	end
	if SCHALLENGE ~= "" then
		player:remove_medals( chal[SCHALLENGE].removemedals )
	end
end

function core.update_player_awards()
	for k,v in ipairs( awards ) do
		if player:has_award( v.id ) then
			player_data.add_counted( 'awards', 'award', v.id.."_"..tostring(player:get_award( v.id )))
		end
	end
end

function core.update_player_data()
	for k,v in ipairs( items ) do
		if ( v.is_exotic or v.is_unique ) and player:has_found_item( v.id ) then
			player_data.add_counted( 'uniques', 'unique', v.id )
		end
	end

	for k,v in ipairs( mod_arrays ) do
		if player:has_assembly(v.id) then
			player_data.add_counted( 'assemblies', 'assembly', v.id, player:has_assembly(v.id) )
		end
	end

	for k,v in ipairs( medals ) do
		if player:has_medal( v.id ) then
			player_data.add_counted( 'medals', 'medal', v.id )
		end
	end
end

function core.update_player_badges()
	for k,v in ipairs( badges ) do
		if player:has_badge( v.id ) then
			if player_data.get_counted( 'badges', 'badge', v.id ) > 0 then
				player:remove_badge( v.id )
			end
			player_data.add_counted( 'badges', 'badge', v.id )
		end
	end
end	

function core.mod_list_signature( mod_list )
	local modsig = ""
	for c=string.byte("A"),string.byte("Z") do
		if mod_list[string.char(c)] then
			modsig = modsig..mod_list[string.char(c)]
		else
			modsig = modsig.."0"
		end
	end
	return modsig
end

function core.power_duration( base )
	return math.floor( base * diff[DIFFICULTY].powerfactor * ( 1.0 + player:get_property( "POWER_BONUS", 0 ) / 100 ) )
end

function core.is_challenge( chal_id )
	return CHALLENGE == chal_id or SCHALLENGE == chal_id
end

function core.proto_weight( proto, weights, one_only )
	local weight = proto.weight or 1
	if not weights then return weight end
	for k,w in pairs( weights ) do
		if (proto.flags and proto.flags[ k ]) or (proto.tags and proto.tags[ k ]) or proto[ k ] or proto.id == k then 
			weight = weight * w 
			if one_only then return weight end
		end
	end
	return weight
end

function core.tag_reqs_met( proto, reqs )
	if not reqs then return true end
	if type(reqs) == "string" then
		return proto.tags[ reqs ]
	end
	if reqs.all then 
		local all = reqs.all
		if type(all) ~= "table" then all = { all } end
		for _,r in ipairs( all ) do
			if not proto.tags[ r ] then return false end
		end
	end
	if reqs.any then 
		local any   = reqs.any
		if type(any) ~= "table" then any = { any } end
		local found = false
		for _,r in ipairs( any ) do
			if proto.tags[ r ] then 
				found = true 
				break
			end
		end
		if not found then return false end
	end
	return true
end

function core.proto_reqs_met( proto, reqs )
	if not reqs then return true end
	for k,r in pairs( reqs ) do
		local pv   = proto[k]
		local rist = ( type(r) == "table" )
		local pist = ( type(pv) == "table" )

		if rist and r[1] and type( r[1] ) ~= "boolean" then 
			r = table.toset( r ) 
			reqs[k] = r
		end

		if pist then 
			if rist then
				for req,_ in pairs( r ) do
					if not pv[ req ] then return false end
				end
			else
				if not pv[ r ] then return false end
			end
		else
			if rist then 
				if not r[ pv ] then return false end
			else
				if pv ~= r then return false end
			end
		end
	end
	return true
end


core.type_name = {
	[ITEMTYPE_NONE]    = "none",
	[ITEMTYPE_RANGED]  = "ranged",
	[ITEMTYPE_NRANGED] = "natural ranged",
	[ITEMTYPE_ARMOR]   = "armor",
	[ITEMTYPE_MELEE]   = "melee weapon",
	[ITEMTYPE_URANGED] = "usable weapon",
	[ITEMTYPE_AMMO]    = "ammo",
	[ITEMTYPE_AMMOPACK]= "ammo pack",
	[ITEMTYPE_PACK]    = "pack",
	[ITEMTYPE_POWER]   = "powerup",
	[ITEMTYPE_BOOTS]   = "boots",
	[ITEMTYPE_TELE]    = "teleporter",
	[ITEMTYPE_LEVER]   = "lever",
	[ITEMTYPE_RELIC]   = "relic",
}

function core.being_plural( id, amount )
	if amount and amount == 1 then
		return beings[ id ].name
	else
		return beings[ id ].name_plural or beings[ id ].name
	end
end
function core.mod_array_description( mod_array_proto )
	local first = true
	local desc = ""
	local function append(str)
		if first then desc = str else desc = desc.." + "..str end
		first = false
	end

	if mod_array_proto.request_desc then 
		append(mod_array_proto.request_desc)
	elseif mod_array_proto.request_id then 
		append(items[mod_array_proto.request_id].name)
	elseif mod_array_proto.request_type then 
		append(core.type_name[mod_array_proto.request_type])
	end

	local sig = ""
	for char,val in pairs(mod_array_proto.mods) do
		if val == 1 then
			sig = sig..char
		else
			sig = sig..char..val
		end
	end

	append("("..sig..")")
	return desc
end

function core.get_unknown_assembly( lvl )
	local list = {}
	for _,ma in ipairs(mod_arrays) do
		if ma.level == lvl then
			if player_data.count('player/assemblies/assembly[@id="'..ma.id..'"]') == 0 and not player:has_assembly(ma.id) then
				table.insert( list, ma.id )
			end
		end
	end
	if #list > 0 then
  		return table.random_pick( list )
 	end
	return nil
end	

function core.ifdiff( min, positive, negative )
	if DIFFICULTY >= min then return positive else return negative end
end

function core.bydiff( entries )
	if DIFFICULTY > #entries then return entries[ #entries ] end
	return entries[DIFFICULTY]
end

function core.less_than_table( value, param )
	for _, v in ipairs( value ) do
		if param < v[1] then return v[2] end
	end
	return value[#value][2]
end

function core.ranged_table( value, param )
	if type( value ) ~= "table" then return value end
	local result = value[1]
	for k, v in pairs( value ) do
		if type( k ) == "table" then
			local min, max = k[1], k[2]
			if not max then 
				if param == min then return v end
			else
				if param >= min and param <= max then result = v end
			end
		end
	end
	return result
end

function core.special_create()
	level.flags[ LF_NOBEINGREVEAL ] = true
	level.flags[ LF_NOITEMREVEAL  ] = true
	statistics.bonus_levels_visited = statistics.bonus_levels_visited + 1
end

function core.special_complete()
	statistics.bonus_levels_completed = statistics.bonus_levels_completed + 1
end

setmetatable(_G, {
	__newindex = function (_, n)
		error("attempt to write to undeclared variable "..n, 2)
	end,
	__index = function (_, n)
		error("attempt to read undeclared variable "..n, 2)
	end,
})
