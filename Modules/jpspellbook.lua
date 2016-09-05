--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local GetTalentInfo = GetTalentInfo
local GetGlyphSocketInfo = GetGlyphSocketInfo
local GetGlyphLink = GetGlyphLink
local GetSpellCooldown = GetSpellCooldown
local GetSpellTabInfo = GetSpellTabInfo
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellInfo = GetSpellInfo
local toSpellName = jps.toSpellName

------------------------------
-- GLYPHS
------------------------------

-- Patch 6.0.2  GetNumTalents REMOVED
-- talentID, name, iconTexture, selected, available = GetTalentInfo(tier, column, talentGroup [, isInspect, inspectedUnit])
-- talentID, name, texture, selected, available = GetTalentInfoByID(talentID, talentGroup[, isInspect, inspectedUnit])

-- numGlyphs = GetNumGlyphs() numGlyphs the number of glyphs THAT THE CHARACTER CAN LEARN
-- name, glyphType, isKnown, icon, glyphId, glyphLink, spec = GetGlyphInfo(index)
-- enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(socketID[[, talentGroup], isInspect, inspectUnit])

function jps.glyphInfo(glyphID)
	for i = 1, NUM_GLYPH_SLOTS do
		local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(i)
		if enabled then
			local link = GetGlyphLink(i) -- Retrieves the Glyph's link ("" if no glyph in Socket)
			if (link ~= "") and glyphSpellID == glyphID then return true end
		end
	end
	return false
end

------------------------------
-- SPELLS
------------------------------

function jps.IsSpellKnown(spell)
	local name, texture, offset, numSpells, isGuild = GetSpellTabInfo(2)
	local mySpell = nil
	local spellname = toSpellName(spell)
	for index = offset+1, numSpells+offset do
		-- Get the Global Spell ID from the Player's spellbook
		local spellID = select(2,GetSpellBookItemInfo(index, "spell"))
		local slotType = select(1,GetSpellBookItemInfo(index, "spell"))
		local name = select(1,GetSpellBookItemName(index, "spell"))
		if spellname == name and slotType ~= "FUTURESPELL" then
			mySpell = spellname
			break -- Breaking out of the for/do loop, because we have a match
		end
	end
	if mySpell == nil then return false end
	return true
end

-- usable, nomana = IsUsableSpell("spellName" or spellID or spellIndex[, "bookType"]);
function jps.isUsableSpell(spell)
	if not jps.IsSpellKnown(spell) then return false end
	local usable = IsUsableSpell(spell)
	if usable then return true end
	return false
end

-- returns true if the player has the selected talent (row: 1-7, talent: 1-3).
function jps.hasTalent(row,talent)
--for row=1,MAX_TALENT_TIERS do
	local _, talentRowSelected =  GetTalentTierInfo(row,1)
	if talent == talentRowSelected then return true end
	return false
end

