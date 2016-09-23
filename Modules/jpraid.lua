--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitPower = UnitPower
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitGUID = UnitGUID

local canDPS = jps.canDPS
local UnitThreatSituation = UnitThreatSituation
local UnitPlayerControlled = UnitPlayerControlled
local UnitIsUnit = UnitIsUnit

------------------------------
-- HEALTH Functions
------------------------------

function jps.hp(unit)
	if unit == nil then unit = "player" end
	if not jps.UnitExists(unit) then return 999 end
	return UnitHealth(unit) / UnitHealthMax(unit)
end

function jps.hpInc(unit)
	if unit == nil then unit = "player" end
	if not jps.UnitExists(unit) then return 999 end
	local hpInc = UnitGetIncomingHeals(unit)
	if not hpInc then hpInc = 0 end
	return (UnitHealth(unit) + hpInc)/UnitHealthMax(unit)
end

function jps.hpAbs(unit)
	if unit == nil then unit = "player" end
	if not jps.UnitExists(unit) then return 999 end
	local hpAbs = UnitGetTotalAbsorbs(unit)
	if not hpAbs then hpAbs = 0 end
	return (UnitHealth(unit) + hpAbs)/UnitHealthMax(unit)
end

function jps.hpSum(unit)
	local absorbHeal = jps.hpAbs(unit)
	local incomingHeal = jps.hpInc(unit)
	return (absorbHeal + incomingHeal) / 2
end

-- Mana SPELL_POWER_MANA 	0
function jps.mana(unit)
	if unit == nil then unit = "player" end
	if not jps.UnitExists(unit) then return 999 end
	return UnitMana(unit)/UnitManaMax(unit)
end

-- SPELL_POWER_RAGE 1
function jps.rage()
	return UnitPower("player",1)
end

-- SPELL_POWER_FOCUS 2 -- Hunter
function jps.focus()
	return UnitPower("player",2)
end

-- SPELL_POWER_ENERGY 3 -- Druid
function jps.energy()
	return UnitPower("player",3)
end

-- SPELL_POWER_RUNIC_POWER 6
function jps.runicPower()
	return UnitPower("player",6)
end

-- SPELL_POWER_SOUL_SHARDS 	7
function jps.soulShards()
	return UnitPower("player",7)
end

-- SPELL_POWER_LUNAR_POWER 	8
function jps.eclipsePower()
	return UnitPower("player",8)
end

-- SPELL_POWER_HOLY_POWER 	9
function jps.holyPower()
	return UnitPower("player",9)
end

-- SPELL_POWER_MAELSTROM 11 Legion New Shaman Resource in Legion.
function jps.maelstom()
    return UnitPower("player", 11)
end

-- SPELL_POWER_CHI 	12
function jps.chi()
	return UnitPower("player", 12)
end

-- SPELL_POWER_INSANITY 13 Legion Insanity are used by Shadow Priests.
function jps.insanity()
	return UnitPower("player",13)
end

-- SPELL_POWER_ARCANE_CHARGES 	16 	Legion Arcane Mage resource.
function jps.arcaneCharges()
    return UnitPower("player", 16)
end

-- SPELL_POWER_FURY 17 Legion Vengeance Demon Hunter.
function jps.powerFury()
    return UnitPower("player", 17)
end

-- SPELL_POWER_PAIN 	18 	Legion Havoc Demon Hunter.
function jps.powerPain()
    return UnitPower("player", 18)
end

function jps.fallingFor()
	local falling = IsFalling()
	if not falling then return 0 end
	return GetTime() - jps.startedFalling
end

-- currentCharges, maxCharges, cooldownStart, cooldownDuration = GetSpellCharges(spellId or "spellName")
function jps.spellCharges(spell)
    return GetSpellCharges(spell) or 0
end

----------------------
-- ENEMY TARGET
----------------------

-- Debuff EnemyTarget DO NOT DPS
local DebuffUnitControl = function (unit)
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			return true
		elseif strfind(auraName,L["Cyclone"]) then
			return true
		elseif strfind(auraName,L["Hex"]) then
			return true
		elseif strfind(auraName,L["Deterrence"]) then
		 	return true
		elseif strfind(auraName,L["Ice Block"]) then
		 	return true
		end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i))
	end
	return false
end

jps.CanAttack = function(unit)
	if not canDPS(unit) then return false end
	if not UnitAffectingCombat(unit) then return false end
	if DebuffUnitControl(unit) then return false end
	return true
end

function targetIsBoss(unit)
	if unit == nil then unit = "target" end
	if not jps.UnitExists(unit) then return false end
	if UnitLevel(unit) == -1 then return true end
	local classUnit = UnitClassification(unit)
	if string.find(classUnit,"elite") then return true
	elseif string.find(classUnit,"boss") then return true
	end
	return false
end