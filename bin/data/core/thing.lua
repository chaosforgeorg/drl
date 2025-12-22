
function thing:find_perk( ... )
	local required_tags = {...}
	for _, perk in ipairs(perks) do
		if perk.tags and self:is_perk(perk.id) then
			local matches = true
			for _, tag in ipairs(required_tags) do
				if not perk.tags[tag] then
					matches = false
					break
				end
			end
			if matches then
				return perk
			end
		end
	end
	return nil
end

function thing:remove_perks_by_tag( tag )
	for _, perk in ipairs(perks) do
		if perk.tags and perk.tags[tag] and self:is_perk(perk.id) then
			self:remove_perk(perk.id)
		end
	end
end

table.merge( thing, game_object )
setmetatable( thing, getmetatable(game_object) )
