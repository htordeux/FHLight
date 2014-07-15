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
local GetSpellInfo = GetSpellInfo
local GetSpellCooldown = GetSpellCooldown

--------------------------
-- CASTING SPELL
--------------------------

--name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
--name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")

function jps.CastTimeLeft(unit)
	if unit == nil then unit = "player" end
	local spellName,_,_,_,_,endTime,_,_,_ = UnitCastingInfo(unit)
	if endTime == nil then return 0 end
	return ((endTime - (GetTime() * 1000 ) )/1000), spellName
end

function jps.ChannelTimeLeft(unit)
	if unit == nil then unit = "player" end
	local spellName,_,_,_,_,endTime,_,_,_ = UnitChannelInfo(unit)
	if endTime == nil then return 0 end
	return ((endTime - (GetTime() * 1000 ) )/1000), spellName
end

function jps.IsCasting(unit)
	if unit == nil then unit = "player" end
	if jps.CastTimeLeft(unit) > 0 or jps.ChannelTimeLeft(unit) > 0 then
		return true end
	return false
end

function jps.IsCastingSpell(spell,unit) -- WORKS FOR CASTING SPELL NOT CHANNELING SPELL
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	if unit == nil then unit = "player" end
	local name, _, _, _, startTime, endTime, _, _, interrupt = UnitCastingInfo(unit)
	if not name then return false end
	if spellname:lower() == name:lower() and jps.CastTimeLeft(unit) > 0 then return true end
	return false
end

function jps.IsChannelingSpell(spell,unit) -- WORKS FOR CHANNELING SPELL NOT CASTING SPELL
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	if unit == nil then unit = "player" end
	local name, _, _, _, startTime, endTime, _, interrupt = UnitChannelInfo(unit)
	if not name then return false end
	if spellname:lower() == name:lower() and jps.ChannelTimeLeft(unit) > 0 then return true end
	return false
end

function jps.spellCastTime(spell)
	return select(7, GetSpellInfo(spell)) /1000
end

-- returns cooldown off a spell
function jps.cooldown(spell) -- start, duration, enable = GetSpellCooldown("name") or GetSpellCooldown(id)
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	local start,duration,_ = GetSpellCooldown(spellname)
	-- if spell is unknown start is nil and cd is 0 => set it to 999 if the spell is unknown
	if start == nil then return 999 end
	local cd = start+duration-GetTime()
	if cd < 0 then return 0 end
	return cd
end

------------------
-- TIMED CASTING
------------------

function jps.castEverySeconds(spell, seconds)
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	
	if not jps.TimedCasting[string.lower(spellname)] then
		return true
	end
	if jps.TimedCasting[string.lower(spellname)] + seconds <= GetTime() then
		return true
	end
	return false
end
