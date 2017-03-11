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
	return UnitHealth(unit) / UnitHealthMax(unit)
end

function jps.hpRange(unit,bot,top)
	if top == nil then top = 100 end
	if bot == nil then bot = 0.80 end
	if unit == nil then unit = "player" end
	local unitHP = jps.hp(unit)
	if unitHP >= bot then
		if unitHP <= top then return true end
	end
	return false
end

function jps.hpInc(unit)
	if unit == nil then unit = "player" end
	local hpInc = UnitGetIncomingHeals(unit)
	if not hpInc then hpInc = 0 end
	return (UnitHealth(unit) + hpInc)/UnitHealthMax(unit)
end

function jps.hpAbs(unit)
	if unit == nil then unit = "player" end
	local hpAbs = UnitGetTotalAbsorbs(unit)
	if not hpAbs then hpAbs = 0 end
	return (UnitHealth(unit) + hpAbs)/UnitHealthMax(unit)
end

-- Mana SPELL_POWER_MANA 	0
function jps.mana(unit)
	if unit == nil then unit = "player" end
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

-- SPELL_POWER_FURY 17 Legion Havoc Demon Hunter.
function jps.powerFury()
    return UnitPower("player", 17)
end

-- SPELL_POWER_PAIN 18 	Legion Vengeance Demon Hunter.
function jps.powerPain()
    return UnitPower("player", 18)
end

-- currentCharges, maxCharges, cooldownStart, cooldownDuration = GetSpellCharges(spellId or "spellName")
function jps.spellCharges(spell)
    return GetSpellCharges(spell) or 0
end

----------------------
-- ENEMY TARGET
----------------------

function jps.IsFallingFor(delay)
	if delay == nil then delay = 1 end
	if not IsFalling() then jps.resetTimer("Falling") end
	if IsFalling() then
		if jps.checkTimer("Falling") == 0 then jps.createTimer("Falling", delay * 2 ) end
	end
	if IsFalling() and jps.checkTimer("Falling") > 0 and jps.checkTimer("Falling") < delay then return true end
	return false
end
-- currentSpeed, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("unit");
function jps.IsMovingFor(delay)
	if delay == nil then delay = 1 end
	if not jps.Moving then jps.resetTimer("Moving") end
	if jps.Moving then
		if jps.checkTimer("Moving") == 0 then jps.createTimer("Moving", delay * 2 ) end
	end
	if jps.Moving and jps.checkTimer("Moving") > 0 and jps.checkTimer("Moving") < delay then return true end
	return false
end

function jps.targetIsBoss(unit)
	if unit == nil then unit = "target" end
	if not jps.UnitExists(unit) then return false end
	if UnitLevel(unit) == -1 then return true end
	local classUnit = UnitClassification(unit)
	if string.find(classUnit,"elite") ~= nil then return true
	elseif string.find(classUnit,"boss") ~= nil then return true
	end
	return false
end