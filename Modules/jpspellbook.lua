--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local GetSpellInfo = GetSpellInfo
local GetTalentInfo = GetTalentInfo
local GetGlyphSocketInfo = GetGlyphSocketInfo
local GetGlyphLink = GetGlyphLink

------------------------------
-- GLYPHS
------------------------------

-- numTalents = GetNumTalents(inspect)
-- numTalents If true, returns information for the inspected unit. otherwise, returns information for the player character.
-- name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq, previewRank, meetsPreviewPrereq = GetTalentInfo(tabIndex, talentIndex, inspect, pet, talentGroup)

-- isKnown = IsSpellKnown(spellID [, isPet])
-- isKnown - True if the player (or pet) knows the given spell. false otherwise

function jps.talentInfo(talent)
	local talentname = nil
	if type(talent) == "string" then talentname = talent end
	if type(talent) == "number" then talentname = tostring(select(1,GetSpellInfo(talent))) end
	local numTalents = GetNumTalents();
	for t = 1, numTalents do
		local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq, previewRank, meetsPreviewPrereq = GetTalentInfo(t);
		if name == talentname and rank then return true end
	end
	return false
end

-- numGlyphs = GetNumGlyphs() numGlyphs the number of glyphs THAT THE CHARACTER CAN LEARN
-- name, glyphType, isKnown, icon, glyphId, glyphLink, spec = GetGlyphInfo(index)
-- enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(socketID[[, talentGroup], isInspect, inspectUnit])

function jps.glyphInfo(glyphID)
	for i = 1, NUM_GLYPH_SLOTS do
		local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(i)
		if enabled then
			local link = GetGlyphLink(i) -- Retrieves the Glyph's link ("" if no glyph in Socket)
			if ( link ~= "") and glyphSpellID == glyphID then return true end
		end
	end
	return false
end

------------------------------
-- SPELLS
------------------------------

local GetSpellInfo = GetSpellInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellTabInfo = GetSpellTabInfo
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName

local jps_IsSpellKnown = function(spell)
	local name, texture, offset, numSpells, isGuild = GetSpellTabInfo(2)
	local booktype = "spell"
	local mySpell = nil
		local spellname = nil
		if type(spell) == "string" then spellname = spell end
		if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
			for index = offset+1, numSpells+offset do
				-- Get the Global Spell ID from the Player's spellbook
				local spellID = select(2,GetSpellBookItemInfo(index, booktype))
				local slotType = select(1,GetSpellBookItemInfo(index, booktype))
				local name = select(1,GetSpellBookItemName(index, booktype))
				if ((spellname:lower() == name:lower()) or (spellname == name)) and slotType ~= "FUTURESPELL" then
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