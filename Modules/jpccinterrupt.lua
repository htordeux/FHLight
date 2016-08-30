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
--Pre-6.0:
-- name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellID or spellName)
--6.0:
-- name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spellID or spellName)

local L = MyLocalizationTable
local UnitDebuff = UnitDebuff
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local UnitIsUnit = UnitIsUnit
local GetTime = GetTime
local toSpellName = jps.toSpellName
local latencyWorld = select(4,GetNetStats())/1000

--------------------------
-- DISPEL TABLE
--------------------------

-- Don't Dispel if unit is affected by some debuffs
local DebuffNotDispel = {
	toSpellName(31117), 	-- "Unstable Affliction"
	toSpellName(34914), 	-- "Vampiric Touch"
	}

-- Don't dispel if friend is affected by "Unstable Affliction" or "Vampiric Touch" or "Lifebloom"
local UnstableAffliction = function(unit)
	for i=1,#DebuffNotDispel do -- for _,debuff in ipairs(DebuffNotDispel) do
		local debuff = DebuffNotDispel[i]
		if jps.debuff(debuff,unit) then return true end
	end
	return false
end

--------------------------------------
-- LOSS OF CONTROL CHECK
--------------------------------------
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitDebuff("unit", index or ["name", "rank"][, "filter"])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitBuff("unit", index or "name"[, "rank"[, "filter"]])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff, isCastByPlayer, ... = UnitAura("unit", index or "name"[, "rank"[, "filter"]])
-- SPELLID OF THE SPELL OR EFFECT THAT APPLIED THE AURA

function jps.StunEvents(duration) -- ONLY FOR PLAYER
	if duration == nil then duration = 0 end
	if jps.checkTimer("PlayerStun") > duration then return true end
	return false
end

function jps.InterruptEvents() -- ONLY FOR PLAYER
	if jps.checkTimer("PlayerInterrupt") > 0 then return true end
	return false
end

function jps.ControlEvents() -- ONLY FOR PLAYER
	if jps.checkTimer("PlayerInterrupt") > 0 then return true end
	if jps.checkTimer("PlayerStun") > 0 then return true end
	return false
end

function jps.EnemyCastingSpellControl()
	if jps.ControlEvents() then return false end
	if jps.checkTimer("SpellControl") > 0 then return true end
	return false
end

-- Check if unit loosed control
-- { "CC" , "Snare" , "Root" , "Silence" , "Immune", "ImmuneSpell", "Disarm" }
-- LoseControl could be FRIEND or ENEMY
jps.LoseControl = function(unit,controlTable)
	local timeControlled = 0
	if controlTable == nil then controlTable = {"CC" , "Snare" , "Root" , "Silence" } end
	-- Check debuffs
	local auraName, debuffType, duration, expTime, spellID
	local i = 1
	auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	while auraName do
		local Priority = jps.SpellControl[spellID]
		if Priority then
			for i=1,#controlTable do
				if Priority == controlTable[i] then
					if expTime ~= nil then timeControlled = expTime - GetTime() end
					if timeControlled > 1 then return true end
				end
			end
		end
		i = i + 1
		auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	end
	return false
end

-- LoseControl could be FRIEND or ENEMY
jps.DispelLoseControl = function(unit,controlTable)
	if not canHeal(unit) then return false end
	if UnstableAffliction(unit) then return false end
	local timeControlled = 0
	if controlTable == nil then controlTable = {"CC" , "Snare" , "Root" , "Silence" } end
	-- Check debuffs
	local auraName, debuffType, duration, expTime, spellID
	local i = 1
	auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	while auraName do
		local Priority = jps.SpellControl[spellID]
		if Priority and debuffType == "Magic" then -- {"Magic", "Poison", "Disease", "Curse"}
			for i=1,#controlTable do
				if Priority == controlTable[i] then
					if expTime ~= nil then timeControlled = expTime - GetTime() end
					if timeControlled > 1 then return true end
				end
			end
		end
		i = i + 1
		auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	end
	return false
end

-- Dispel all MAGIC debuff in the debuff TABLE DebuffToDispel EXCEPT if unit is affected by UnstableAffliction
jps.DispelFriendly = function(unit,time)
	if not canHeal(unit) then return false end
	if UnstableAffliction(unit) then return false end
	if time == nil then time = 0 end
	local timeControlled = 0
	-- Check debuffs
	local auraName, debuffType, duration, expTime, spellID
	local i = 1
	auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID = UnitDebuff(unit, i)
	while auraName do
		if jps.BigDebuff[spellID]  == "cc" and debuffType == "Magic" then -- {"Magic", "Poison", "Disease", "Curse"}
			if expTime ~= nil then timeControlled = expTime - GetTime() end
			if timeControlled > time then return true end
		end
		i = i + 1
		auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID = UnitDebuff(unit, i)
	end
	return false
end

------------------------------------
-- OFFENSIVE DISPEL
------------------------------------

-- Avenging Wrath 31884 Dispel type	n/a
-- Divine Shield and Ice Block need Mass Dispel
local BuffToDispel = 
{	
	toSpellName(7812), -- Sacrifice 7812 Type de dissipation	Magie
	toSpellName(109147), -- Archangel 109147 Type de dissipation	Magie
	toSpellName(110694), -- Frost Armor 110694 Type de dissipation	Magie
	toSpellName(17), -- Power Word: Shield 17 Type de dissipation	Magie
	toSpellName(6346), -- Fear Ward 6346 Type de dissipation	Magie
	toSpellName(1022), -- Hand of Protection 1022  Dispel type	Magic
	toSpellName(1463), -- Incanter's Ward 1463 Dispel type	Magic
	toSpellName(69369), -- Predatory Swiftness 69369 Dispel type	Magic
	toSpellName(11426), -- Ice Barrier 11426 Dispel type	Magic
	toSpellName(6940), -- Hand of Sacrifice Dispel type	Magic
	toSpellName(110909), -- Alter Time Dispel type	Magic
	toSpellName(132158), -- Nature's Swiftness Dispel type	Magic
	toSpellName(12043) -- Presence of Mind Dispel type	Magic
} 

-- "Lifebloom" When Lifebloom expires or is dispelled, the target is instantly healed
local NotOffensiveDispel = toSpellName(94447) -- "Lifebloom"
function jps.DispelOffensive(unit)
	if not canDPS(unit) then return false end
	if jps.buff(NotOffensiveDispel,unit) then return false end 
	for i=1,#BuffToDispel do -- for _,buff in ipairs(BuffToDispel) do
		local buff = BuffToDispel[i]
		if jps.buff(buff,unit) then
		return true end
	end
	return false
end

-- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")
-- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitCastingInfo("unit")

function jps.ShouldKick(unit)
	if not canDPS(unit) then return false end
	local casting = select(1,UnitCastingInfo(unit))
	local notinterruptible = select(9,UnitCastingInfo(unit)) --  if true, indicates that this cast cannot be interrupted 
	local channelling = select(1,UnitChannelInfo(unit))
	local not_interruptible = select(8,UnitChannelInfo(unit)) -- if true, indicates that this cast cannot be interrupted
	if casting == L["Release Aberrations"] then return false end
	if casting == nil and channelling == nil then return false end
	if casting and not notinterruptible then
		return true
	elseif channelling and not not_interruptible then
		return true
	end
	return false
end

function jps.ShouldKickDelay(unit)
	if not canDPS(unit) then return false end
	if unit == nil then unit = "target" end
	local casting = UnitCastingInfo(unit)
	local channelling = UnitChannelInfo(unit)
	if casting == L["Release Aberrations"] then return false end

	if casting and jps.CastTimeLeft(unit) < 2 then
		return true
	elseif channelling and jps.ChannelTimeLeft(unit) < 2 then
		return true
	end
	return false
end