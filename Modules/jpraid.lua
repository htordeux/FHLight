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
function jps.mana(unit)
	if unit == nil then unit = "player" end
	if not jps.UnitExists(unit) then return 999 end
	return UnitMana(unit)/UnitManaMax(unit)
end

function jps.fallingFor()
	local falling = IsFalling()
	if not falling then return 0 end
	return GetTime() - jps.startedFalling
end

----------------------
-- ENEMY TARGET
----------------------

-- Debuff EnemyTarget NOT DPS
local DebuffUnitCyclone = function (unit)
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			return true
		elseif strfind(auraName,L["Cyclone"]) then
			return true
		elseif strfind(auraName,L["Hex"]) then
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
	if DebuffUnitCyclone(unit) then return false end
	return true
end

function jps.targetIsRaidBoss(target)
	if target == nil then target = "target" end
	if not jps.UnitExists(target) then return false end
	if UnitLevel(target) == -1 and not UnitPlayerControlled(target) then
		return true
	end
	return false
end

-- local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
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
		local LowestEnemy,_,_ = jps.LowestTarget()
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