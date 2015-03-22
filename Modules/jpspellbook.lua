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

local function toSpellName(spell)
	local spellname = GetSpellInfo(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	return spellname
end

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

local jps_IsSpellKnown = function(spell)
	local name, texture, offset, numSpells, isGuild = GetSpellTabInfo(2)
	local booktype = "spell"
	local mySpell = nil
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end

	for index = offset+1, numSpells+offset do
		-- Get the Global Spell ID from the Player's spellbook
		local spellID = select(2,GetSpellBookItemInfo(index, booktype))
		local slotType = select(1,GetSpellBookItemInfo(index, booktype))
		local name = select(1,GetSpellBookItemName(index, booktype))
		if spellname == name and slotType ~= "FUTURESPELL" then
			mySpell = spellname
			break -- Breaking out of the for/do loop, because we have a match
		end
	end
	return mySpell
end

function jps.IsSpellKnown(spell)
	if jps_IsSpellKnown(spell) == nil then return false end
	return true
end