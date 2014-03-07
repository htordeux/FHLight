--[[
	 JPS - WoW Protected Lua DPS AddOn
	Copyright (C) 2011 Jp Ganis

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
]]--

--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local UnitAura = UnitAura
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local UnitIsUnit = UnitIsUnit
local function toSpellName(id) return tostring(select(1,GetSpellInfo(id))) end
local GetTime = GetTime

--------------------------------------
-- LOSS OF CONTROL CHECK
--------------------------------------
-- name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitDebuff("unit", index [, "filter"]) or UnitDebuff("unit", "name" [, "rank" [, "filter"]])
-- name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura("unit", index [, "filter"]) or UnitAura("unit", "name" [, "rank" [, "filter"]])

function jps.StunEvents(duration) -- ONLY FOR PLAYER
	if duration == nil then duration = 0 end
	if jps.checkTimer("Player_Stun") > duration then return true end
	return false
end

-- Check if unit loosed control
-- unit = http://www.wowwiki.com/UnitId
-- { "CC" , "Snare" , "Root" , "Silence" , "Immune", "ImmuneSpell", "Disarm" }
function jps.LoseControl(unit, controlTable)
	local targetControlled = false
	local timeControlled = 0
	if controlTable == nil then controlTable = {"CC" , "Snare" , "Root" , "Silence" } end
	-- Check debuffs
	local auraname, duration, expTime, spellId
	local i = 1
	auraname, _, _, _, debufftype, duration, expTime, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
	while auraname do
		local Priority = jps.SpellControl[spellId]
		if Priority then
			for _,control in ipairs(controlTable) do
				if Priority == control then
					targetControlled = true
					if expTime ~= nil then timeControlled = expTime - GetTime() end
				break end
			end
		end
		if targetControlled == true and timeControlled > 0 then return targetControlled end
		i = i + 1
		auraname, _, _, _, debufftype, duration, expTime, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
	end
	return targetControlled
end

--------------------------
-- DISPEL FUNCTIONS TABLE
--------------------------

-- Table of controls Spellnames by index
local DebuffToDispel = {}
for spellID,control in pairs(jps.SpellControl) do
	if control == "CC" then 
		DebuffToDispel[toSpellName(spellID)] = spellID
	end
end

local polySpellIds = {
	[51514] = "Hex" ,
	[118]	= "Polymorph" ,
	[61305] = "Polymorph: Black Cat" ,
	[28272] = "Polymorph: Pig" ,
	[61721] = "Polymorph: Rabbit" ,
	[61780] = "Polymorph: Turkey" ,
	[28271] = "Polymorph: Turtle" ,
	}

-- Enemy Casting Polymorph Target is Player
local latencyWorld = select(4,GetNetStats())/1000
function jps.IsCastingPoly(unit)
	if not canDPS(unit) then return false end
	local delay, spellname = jps.CastTimeLeft(unit)

	for spellID,spell in pairs(polySpellIds) do
		if UnitIsUnit(unit.."target", "player") == 1 and spellname == toSpellName(spellID) and delay > 0 then
			if delay - (latencyWorld * 2) < 0 then return true end
		end
	end 
	return false
end

-- Enemy casting CrowdControl Spell
function jps.IsCastingControl(unit)
	if not canDPS(unit) then return false end
	local delay, spellname = jps.CastTimeLeft(unit)
	if DebuffToDispel[spellname] and delay > 0 then
		return true 
	end 
	return false
end

-- Don't Dispel if unit is affected by some debuffs
local DebuffNotDispel = {
	toSpellName(31117), 	-- "Unstable Affliction"
	toSpellName(34914), 	-- "Vampiric Touch"
	}
-- Don't dispel if friend is affected by "Unstable Affliction" or "Vampiric Touch" or "Lifebloom"
local NotDispelFriendly = function(unit)
	for _,debuff in ipairs(DebuffNotDispel) do
		if jps.debuff(debuff,unit) then return true end
	end
	return false
end

-- Dispel all debuff in the debuff table EXCEPT if unit is affected by some debuffs
jps.DispelFriendly = function (unit)
	if not canHeal(unit) then return false end
	if NotDispelFriendly(unit) then return false end
	local timeControlled = 0
	local auraname, debufftype, duration, expTime, spellId
	local i = 1
	auraname, _, _, _, debufftype, duration, expTime, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
	while auraname do
		if debufftype == "Magic" and DebuffToDispel[auraname] then
			if expTime ~= nil then timeControlled = expTime - GetTime() end
			if timeControlled > 0 then
			return true end
		end
		i = i + 1
		auraname, _, _, _, debufftype, duration, expTime, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
	end
	return false
end

printDebuffToDispel = function()
	for i, j in pairs(DebuffToDispel) do
		print(i,"/",j)
	end
end

------------------------------------
-- OFFENSIVE DISPEL
------------------------------------
-- Avenging Wrath 31884 Dispel type	n/a
-- Sacrifice 7812 Type de dissipation	Magie
-- Archangel 109147 Type de dissipation	Magie
-- Frost Armor 110694 Type de dissipation	Magie
-- Power Word: Shield 17 Type de dissipation	Magie
-- Fear Ward 6346 Type de dissipation	Magie
-- Hand of Protection 1022  Dispel type	Magic
-- Incanter's Ward 1463 Dispel type	Magic
-- Predatory Swiftness 69369 Dispel type	Magic
-- Ice Barrier 11426 Dispel type	Magic

local BuffToDispel = 
{	
	toSpellName(7812),
	toSpellName(109147) ,
	toSpellName(110694),
	toSpellName(17),
	toSpellName(6346),
	toSpellName(1022),
	toSpellName(1463),
	toSpellName(69369),
	toSpellName(11426)
}

-- "Lifebloom" When Lifebloom expires or is dispelled, the target is instantly healed
local NotOffensiveDispel = toSpellName(94447) -- "Lifebloom"
function jps.DispelOffensive(unit)
	if unit == nil then return false end
	if not canDPS(unit) then return false end
	if jps.buff(NotOffensiveDispel,unit) then return false end 
	for _, buff in ipairs(BuffToDispel) do
		if jps.buff(buff,unit) then
		return true end
	end
	return false
end

function jps.shouldKick(unit)
	if not jps.Interrupts then return false end
	if not canDPS(unit) then return false end
	if unit == nil then unit = "target" end
	local target_spell, _, _, _, _, _, _, _, unInterruptable = UnitCastingInfo(unit)
	local channelling, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
	if target_spell == L["Release Aberrations"] then return false end

	if target_spell and (unInterruptable == false) then
		return true
	elseif channelling and (notInterruptible == false) then
		return true
	end
	return false
end

function jps.shouldKickLag(unit)
	if not jps.Interrupts then return false end
	if not canDPS(unit) then return false end
	if unit == nil then unit = "target" end
	local target_spell, _, _, _, _, cast_endTime, _, _, unInterruptable = UnitCastingInfo(unit)
	local channelling, _, _, _, _, chanel_endTime, _, notInterruptible = UnitChannelInfo(unit)
	if target_spell == L["Release Aberrations"] then return false end

	if cast_endTime == nil then cast_endTime = 0 end
	if chanel_endTime == nil then chanel_endTime = 0 end

	if target_spell and unInterruptable == false then
		if jps.CastTimeLeft(unit) < 1 then
		return true end
	elseif channelling and notInterruptible == false then
		if jps.ChannelTimeLeft(unit) < 1 then
		return true end
	end
	return false
end

local interruptDelay = 0
local interruptDelaySpellUnit = ""
local interruptDelayTimestamp = GetTime()

function jps.kickDelay(unit)
	if not jps.Interrupts then return false end
	if not canDPS(unit) then return false end
	if jps.IsCasting(unit) then
		local castLeft, spellName = jps.CastTimeLeft(unit) or jps.ChannelTimeLeft(unit)
		if castLeft < 2 then return true end

		if (GetTime() - interruptDelayTimestamp) > 5 or  interruptDelaySpellUnit ~= (spellName..unit) then -- recalc delay value
			maxDelay = castLeft-2
			if(castLeft <= 2.5) then maxDelay = castLeft - 0.5 end
			minDelay = 0.5
			interruptDelay = Math.random(minDelay,maxDelay)
			interruptDelaySpellUnit = spellName..unit
			interruptDelayTimestamp = GetTime()
		end

		if interruptDelay <= castLeft and  interruptDelaySpellUnit == spellName..unit then
			interruptDelaySpellUnit = ""
			interruptDelay = 0
			return true
		end
		return false
	end
	if interruptDelaySpellUnit ~= "" then
		interruptDelaySpellUnit = ""
		interruptDelay = 0
	end
	return true
end