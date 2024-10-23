local _, LRP = ...

function LRP.GetSpellInfo(spell)
	if C_Spell and C_Spell.GetSpellInfo then
		return C_Spell.GetSpellInfo(spell)
	else
		local name, rank, iconID, castTime, minRange, maxRange, spellID, originalIconID = GetSpellInfo(spell)

		if name then
			return {
				name = name,
				iconID = iconID,
				originalIconID = originalIconID,
				castTime = castTime,
				minRange = minRange,
				maxRange = maxRange,
				spellID = spellID,
				rank = rank
			}
		end
	end
end