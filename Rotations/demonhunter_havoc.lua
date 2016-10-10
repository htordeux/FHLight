--[[[
@module Demonhunter Havoc Rotation
@author kirk24788
@version 7.0.3
]]--

local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit
local spells = jps.spells.demonhunter

jps.registerRotation("DEMONHUNTER","HAVOC",function()

local spell = nil
local target = nil

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

-- Config FOCUS with MOUSEOVER
if not jps.UnitExists("focus") and canDPS("mouseover") and UnitAffectingCombat("mouseover") then
	-- set focus an enemy targeting you
	if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy in combat
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.vampiricTouch,"mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.shadowWordPain,"mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
	end
end

if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	jps.Macro("/clearfocus")
end

if canDPS("target") then rangedTarget =  "target"
elseif canDPS(TankTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

	-- 195072
    {spells.felRush , CheckInteractDistance(rangedTarget,3) == false },
	-- "Planer"
	{ 131347, jps.fallingFor() > 1.5 , "player" },
	-- "Torrent arcanique" 202719
	{ 202719, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Manavore" 183752
	{ 183752, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Lancer de glaive" 185123
	{ spells.throwGlaive },
	-- Rayon accablant "198013"
	{spells.eyeBeam , jps.powerFury() > 50 },
	-- "Frappe du chaos" 162794 
    {spells.chaosStrike , jps.powerFury() > 40 },
    -- "Morsure du demon" 162243 
    {spells.demonsBite},

    {spells.throwGlaive},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Havoc")