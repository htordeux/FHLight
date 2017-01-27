--[[[
@module Demonhunter Vengeance Rotation
@author kirk24788
@untested
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

jps.registerRotation("DEMONHUNTER","VENGEANCE",function()

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

	-- "Frappe infernale" 189110
	{ spells.infernalStrike , jps.spellCharges(189110) == 2 , "target" , "infernalStrike" },
	{ 204596 },

	-- "Planer"
	{ 131347, jps.fallingFor() > 1.5 , "player" },
	-- "Métamorphose" 187827
	{ spells.metamorphosis , jps.hp("player") < 0.70 , "target" , "Métamorphose" },
	-- "Pointes démoniaques" 203720 -- Physical dmg
	{ spells.demonSpikes , jps.IncomingDamage("player") > 0 , "target" , "demonSpikes" },
	-- "Marques protectrices" 218256 -- Magic dmg
	{ spells.empowerWards , jps.IncomingDamage("player") > 0 , "target" , "empowerWards" },
	-- "Marque enflammée" 204021
	{ spells.fieryBrand , jps.IncomingDamage("player") > 0 and jps.hp("player") < 0.70 , "target" , "fieryBrand" },
	
	-- "Tourment" 185245
	{ spells.torment, not jps.playerIsTargeted() },
	
	-- "Manavore" 183752 -- 15 sec cd
	{ spells.consumeMagic, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) , rangedTarget , "Manavore" },
	-- "Torrent arcanique" 202719 -- 90 sec cd
	{ 202719, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and jps.cooldown(183752) > 0 , rangedTarget },

	-- "Déchirement d'âme" 207407
	{ spells.soulCarver , true , "target" , "soulCarver" },
	-- "Aura d'immolation" 178740
	{ spells.immolationAura , true , "target" , "immolationAura" },
	-- "Division de l'âme" 228477
	{ spells.soulCleave , jps.powerPain() > 50 , "target" , "soulCleave" },
	-- "Lancer de glaive" 204157
	{ spells.throwGlaive , true , "target" , "throwGlaive" },
	-- "Entaille" 203782
	{ spells.shear , true , "target" , "Entaille" },


}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Vengeance")