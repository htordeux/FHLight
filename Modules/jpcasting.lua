--[[[
@module JPS Casting
@description
Functions which handle casting & channeling stuff.
]]--

--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local toSpellName = jps.toSpellName

--------------------------
-- CASTING SPELL
--------------------------

-- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")
-- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitCastingInfo("unit")

function jps.CastTimeLeft(unit)
	if unit == nil then unit = "player" end
	local spellName,_,_,_,_,endTime,_,_,_ = UnitCastingInfo(unit)
	if endTime == nil then return 0 end
	return ((endTime - (GetTime() * 1000 ) )/1000)
end

function jps.ChannelTimeLeft(unit)
	if unit == nil then unit = "player" end
	local spellName,_,_,_,_,endTime,_,_,_ = UnitChannelInfo(unit)
	if endTime == nil then return 0 end
	return ((endTime - (GetTime() * 1000 ) )/1000)
end

function jps.SpellCastTime(spell)
	local castTime = select(4, GetSpellInfo(spell))
	if castTime == nil then return 0 end
	return (castTime/1000) or 0
end

function jps.IsCasting(unit)
	if unit == nil then unit = "player" end
	if jps.CastTimeLeft(unit) > 0 or jps.ChannelTimeLeft(unit) > 0 then
		return true end
	return false
end

function jps.IsCastingSpell(spell,unit) -- WORKS FOR CASTING SPELL NOT CHANNELING SPELL
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if unit == nil then unit = "player" end
	local name, _, _, _, startTime, endTime, _, _, interrupt = UnitCastingInfo(unit)
	if not name then return false end
	if spellname:lower() == name:lower() and jps.CastTimeLeft(unit) > 0 then return true end
	return false
end

function jps.IsChannelingSpell(spell,unit) -- WORKS FOR CHANNELING SPELL NOT CASTING SPELL
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if unit == nil then unit = "player" end
	local name, _, _, _, startTime, endTime, _, interrupt = UnitChannelInfo(unit)
	if not name then return false end
	if spellname:lower() == name:lower() and jps.ChannelTimeLeft(unit) > 0 then return true end
	return false
end

------------------
-- TIMED CASTING
------------------

function jps.castEverySeconds(spell, seconds)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if not jps.TimedCasting[spellname] then
		return true
	end
	if jps.TimedCasting[spellname] + seconds <= GetTime() then
		return true
	end
	return false
end

----------------------
-- PLAYER FACING FRIEND UNIT
----------------------
-- GetPlayerMapPosition Works with "player", "partyN" or "raidN" as unit type
-- Angle by default is 30° front of Player

function jps.PlayerIsFacing(unit,alpha) -- alpha is angle value between 10-180
	-- Number - Direction the player is facing in radians, in the [0, 2π] range, where 0 is North and values increase counterclockwise
	local pf = GetPlayerFacing()
	local px,py = GetPlayerMapPosition("player")
	local tx,ty = GetPlayerMapPosition(unit)

	if tx == 0 and ty == 0 then return false end
	if jps.UnitIsUnit(unit,"player") then return false end

	if alpha == nil then alpha = 30 end
	local math_360 = math.pi * 2
	local math_radian = math.rad(alpha) -- math.pi / (180/alpha)
	-- math.rad(alpha/2) ou math.pi / (360/alpha)
	local math_alpha = math_radian / 2

	local dir = math_360 - math.atan2 (px-tx,ty-py)
	local radian = dir - pf
	local facing = false

	if radian > math.pi + math_alpha then facing = false
	elseif radian < math.pi - math_alpha then facing = false
	else facing = true
	end
	return facing, radian
end

-- posX, posY, posZ, terrainMapID = UnitPosition("unit");
-- Does not work with all unit types. Works with "player", "partyN" or "raidN" as unit type.
-- It does not work on pets or any unit not in your group.

-- distanceSquared, checkedDistance = UnitDistanceSquared("unit")
-- Returns the squared distance from you to a unit in the player's group -- math.sqrt(100) = 10
-- (x2-x1)^2 + (y2-y1)^2

-- When a given unit has no valid returns:
-- UnitDistanceSquared returns 0
-- UnitPosition returns nil

function jps.Distance(unit)
	local dist,_ = math.sqrt(UnitDistanceSquared(unit))
	if dist == 0 and UnitPosition(unit) == nil then dist = 100 end
	return dist
end