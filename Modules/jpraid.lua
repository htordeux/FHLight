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
local LowestTarget = jps.LowestTarget -- include canDPS
-- local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

------------------------------
-- HEALTH Functions
------------------------------

function jps.UnitIsUnit(unit1,unit2)
	if unit2 == nil then unit2 = "player" end
	if unit1 == nil then return false end
	if UnitGUID(unit1) == UnitGUID(unit2) then return true end
	return false
end

function jps.hp(unit,message)
	if unit == nil then unit = "player" end
	if message == "abs" then
		return UnitHealthMax(unit) - UnitHealth(unit)
	else
		return UnitHealth(unit) / UnitHealthMax(unit)
	end
end

function jps.hpInc(unit,message)
	if unit == nil then unit = "player" end
	local hpInc = UnitGetIncomingHeals(unit)
	if not hpInc then hpInc = 0 end
	if message == "abs" then
		return UnitHealthMax(unit) - (UnitHealth(unit) + hpInc)
	else
		return (UnitHealth(unit) + hpInc)/UnitHealthMax(unit)
	end
end

function jps.hpAbs(unit,message)
	if unit == nil then unit = "player" end
	local hpInc = UnitGetIncomingHeals(unit)
	if not hpInc then hpInc = 0 end
	local hpAbs = UnitGetTotalAbsorbs(unit)
	if not hpAbs then hpAbs = 0 end
	if message == "abs" then
		return UnitHealthMax(unit) - (UnitHealth(unit) + hpInc + hpAbs)
	else
		return (UnitHealth(unit) + hpInc + hpAbs)/UnitHealthMax(unit)
	end
end

function jps.rage()
	return UnitPower("player",1)
end

function jps.energy()
	return UnitPower("player",3)
end

function jps.focus()
	return UnitPower("player",2)
end

function jps.runicPower()
	return UnitPower("player",6)
end

function jps.soulShards()
	return UnitPower("player",7)
end

function jps.eclipsePower()
	return UnitPower("player",8)
end

function jps.chi()
	return UnitPower("player", 12)
end

function jps.holyPower()
	return UnitPower("player",9)
end

function jps.shadowOrbs()
	return UnitPower("player",13)
end

function jps.burningEmbers()
	return UnitPower("player",14)
end

function jps.emberShards()
	return UnitPower("player",14, true)
end

function jps.demonicFury()
	return UnitPower("player",15)
end

-- Mana = UnitPower("player",0)
function jps.mana(unit,message)
	if unit == nil then unit = "player" end
	if message == "abs" or message == "absolute" then
		return UnitMana(unit)
	else
		return UnitMana(unit)/UnitManaMax(unit)
	end
end

function jps.fallingFor()
	local falling = IsFalling()
	if not falling then return 0 end
	return GetTime() - jps.startedFalling
end

----------------------
-- Find ENEMY TARGET
----------------------

function jps.targetIsRaidBoss(target)
	if target == nil then target = "target" end
	if not jps.UnitExists(target) then return false end
	if UnitLevel(target) == -1 and UnitPlayerControlled(target) == false then
		return true
	end
	return false
end

jps.findMeRangedTarget = function()
	local rangedTarget = "target"
	if canDPS("target") then
		rangedTarget = "target"
	elseif canDPS("focustarget") then
		rangedTarget = "focustarget"
	elseif canDPS("targettarget") then
		rangedTarget = "targettarget"
	elseif canDPS("mouseover") then
		rangedTarget = "mouseover"
	elseif canDPS("boss1") then
		rangedTarget = "boss1"
	elseif canDPS("boss2") then
		rangedTarget = "boss2"
	elseif canDPS("boss3") then
		rangedTarget = "boss3"
	elseif canDPS("boss4") then
		rangedTarget = "boss3"
	else
		local LowestEnemy,_,_ = LowestTarget()
		rangedTarget = LowestEnemy
	end
	return rangedTarget
end

-------------------------
-- DONGEONS
-------------------------

diffTable = {}
diffTable[0] = "none"
diffTable[1] = "normal5"
diffTable[2] = "heroic5"
diffTable[3] = "normal10"
diffTable[4] = "normal25"
diffTable[5] = "heroic10"
diffTable[6] = "heroic25"
diffTable[7] = "lfr25"
diffTable[8] = "challenge"
diffTable[9] = "normal40"
diffTable[10] = "none"
diffTable[11] = "normal3"
diffTable[12] = "heroic3"

-- load instance info , we should read instance name & check if we fight an encounter
jps.instance = {}
function jps.getInstanceInfo()
	local name, instanceType , difficultyID = GetInstanceInfo()
	local targetName = UnitName("target")

	jps.instance["instance"] = name
	jps.instance["enemy"] = targetName
	jps.instance["difficulty"] = diffTable[difficultyID]

	return jps.instance
end