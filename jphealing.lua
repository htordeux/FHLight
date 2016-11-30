local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local GetRaidRosterInfo = GetRaidRosterInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPower = UnitPower
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local MAX_RAID_MEMBERS = MAX_RAID_MEMBERS
local UnitGUID = UnitGUID
local GetTime = GetTime
local UnitInRaid = UnitInRaid
local UnitAffectingCombat = UnitAffectingCombat
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitClass = UnitClass
local GetUnitName = GetUnitName
local canHeal = jps.canHeal
local canDPS = jps.canDPS
local twipe = table.wipe
local tsort = table.sort
local tinsert = table.insert
local pairs = pairs
local toSpellName = jps.toSpellName

local function HealthPct(unit)
	if not jps.UnitExists(unit) then return 999 end
	return UnitHealth(unit) / UnitHealthMax(unit)
end

----------------------
-- UPDATE RAIDROSTER
----------------------
-- GetNumSubgroupMembers() -- Number of players in the player's sub-group, excluding the player. remplace GetNumPartyMembers patch 5.0.4
-- GetNumGroupMembers() -- returns Number of players in the group (either party or raid), 0 if not in a group. remplace GetNumRaidMembers patch 5.0.4
-- IsInRaid() Boolean - returns true if the player is currently in a raid group, false otherwise
-- IsInGroup() Boolean - returns true if the player is in a some kind of group, otherwise false

local RaidStatusRole = {}
local RaidStatus = {}
local RaidRoster = {}

jps.UpdateRaidStatus = function ()
	local unit = nil
	local grouptype = nil
	local nps = 0
	local npe = 0

	if IsInRaid() then
		grouptype = "raid"
		nps = 1
		npe = GetNumGroupMembers()
	else
		grouptype = "party"
		nps = 0
		npe = GetNumSubgroupMembers()
	end

	twipe(RaidStatus)
	for i=nps,npe do
		if i==0 then
			unit = "player"
		else
			unit = grouptype..i
		end
		
		if RaidStatus[unit] == nil then RaidStatus[unit] = {} end
		RaidStatus[unit]["hpct"] = HealthPct(unit)
		RaidStatus[unit]["inrange"] = canHeal(unit)
	end
end

jps.UpdateRaidUnit = function (unit)
	if RaidStatus[unit] == nil then return end
	RaidStatus[unit]["hpct"] = HealthPct(unit)
	RaidStatus[unit]["inrange"] = canHeal(unit)
end

--------------------------
-- CLASS SPEC RAID ROSTER
--------------------------

-- IsInRaid() Boolean - returns true if the player is currently in a raid group, false otherwise
-- IsInGroup() Boolean - returns true if the player is in a some kind of group, otherwise false
-- name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex);
-- combatRole Returns the combat role of the player if one is selected "DAMAGER", "TANK" or "HEALER". Returns "NONE" otherwise.
-- role = UnitGroupRolesAssigned(unit) -- works only for friendly unit in raid TANK, HEALER, DAMAGER, NONE -- return "NONE" if not in raid

jps.UpdateRaidRole = function ()
	twipe(RaidStatusRole)
	twipe(RaidRoster)
	for unit,_ in pairs(RaidStatus) do
		RaidRoster[#RaidRoster+1] = unit
		local role = UnitGroupRolesAssigned(unit)
		local class = select(2,UnitClass(unit))
		if RaidStatusRole[unit] == nil then RaidStatusRole[unit] = {} end
		RaidStatusRole[unit]["role"] = role
		RaidStatusRole[unit]["class"] = class
	end
end

-- "DAMAGER" , "HEALER" , "TANK" , "NONE -- works only for RaidStatus units
jps.RoleInRaid = function (unit)
	if RaidStatusRole[unit] then return RaidStatusRole[unit]["role"] end
	return "NONE"
end

----------------------
-- UPDATE RAIDTARGET
----------------------

jps.LowestTarget = function()
	local RaidTarget = {}
	for unit,_ in pairs(RaidStatus) do
		if canDPS(unit.."target") then
			local unittarget = unit.."target"
			RaidTarget[#RaidTarget+1] = unittarget -- tinsert(RaidTarget, unittarget)
		end
	end
	
	local hash = {}
	for i=1,#RaidTarget do -- for _,v in ipairs(RaidTarget) do -- { "playertarget" , "raid5target" , "raid4target" }
		local v = RaidTarget[i]
		local targuid = UnitGUID(v)
		hash[targuid] = v -- hash = { [targuid1] = "playertarget" , [targuid2] = "raid5target"}
	end

	local dupe = {}
	for _,j in pairs(hash) do
		dupe[#dupe+1] = j -- dupe = { "playertarget" , "raid5target" }
	end
	tsort(dupe, function(a,b) return HealthPct(a) < HealthPct(b) end)
	return dupe[1] or "target", dupe, #dupe
end

--local locClass, enClass, classID = UnitClass(unit)
jps.LowestTargetRole = function()
	local spec = "HEALER"
	local _,EnemyUnit,_ = jps.LowestTarget()
	local EnemyRole = {}
	for i=1,#EnemyUnit do
		local unit = EnemyUnit[i]
		local _, _, classID = UnitClass(unit)
		local numTabs = GetNumSpecializationsForClassID(classID)
		for i = 1, numTabs do
			local id, name, _, icon, _, role = GetSpecializationInfoForClassID(classID, i)
			if id and role == spec then
				if EnemyRole[unit] == nil then EnemyRole[unit] = role end
			end
		end
	end
	return EnemyRole -- table with choosen role "DAMAGER" "TANK" "HEALER"
end

jps.LowestTargetHealer = function()
	local enemyTable = jps.LowestTargetRole()
	for unit,index in pairs(enemyTable) do
		if jps.EnemyHealer(unit) then return unit end
	end
end

jps.playerIsTargeted = function()
	local isArena, _ = IsActiveBattlefieldArena()
	if isArena then
		--  "arenaN" Opposing arena member with index N (1,2,3,4 or 5)
		local arenaEnemy = {}
		local arenaTarget = {}
		for n=1,5 do
			local unit = "arena"..n
			if jps.UnitExists(unit) then arenaEnemy[#arenaEnemy + 1] = unit end
		end
		for i=1,#arenaEnemy do
			local target = arenaEnemy[i].."target"
			if jps.UnitExists(target) then
				if UnitIsUnit(target,"player") then return true end
			end
		end
	else
		local RaidTarget = {}
		for unit,_ in pairs(RaidStatus) do
			if jps.UnitExists(unit.."target") then
				local unittarget = unit.."target"
				RaidTarget[#RaidTarget+1] = unittarget -- tinsert(RaidTarget, unittarget)
			end
		end
		for i=1,#RaidTarget do
			local target = RaidTarget[i].."target"
			if jps.UnitExists(target) then
				if UnitIsUnit(target,"player") then return true end
			end
		end
	end
	return false
end

--------------------------
-- TANK
--------------------------

function jps.findHealerInRaid()
	local HealerUnit = {}
	for unit,_ in pairs(RaidStatus) do
		if jps.RoleInRaid(unit) == "HEALER" and canHeal(unit) then
			HealerUnit[#HealerUnit+1] = unit
		end
	end
	tsort(HealerUnit, function(a,b) return HealthPct(a) < HealthPct(b) end)
	return HealerUnit[1] or "focus" , HealerUnit
end

function jps.findTankInRaid()
	local TankUnit = {}
	for unit,_ in pairs(RaidStatus) do
		local unitThreat = UnitThreatSituation(unit)
		if jps.RoleInRaid(unit) == "TANK" and canHeal(unit) then
			TankUnit[#TankUnit+1] = unit
		elseif unitThreat and canHeal(unit) then
			if unitThreat == 1 then TankUnit[#TankUnit+1] = unit
			elseif unitThreat == 3 then TankUnit[#TankUnit+1] = unit 
			end
		end
	end
	tsort(TankUnit, function(a,b) return HealthPct(a) < HealthPct(b) end)
	local defaultTank = "focus"
	if canHeal("focus") then defaultTank = "focus" else defaultTank = "player" end
	return TankUnit[1] or defaultTank, TankUnit
end

--status = UnitThreatSituation("unit"[, "otherunit"])
--Without otherunit specified
--nil = unit is not on any other unit's threat table.
--0 = not tanking anything.
--1 = not tanking anything, but have higher threat than tank on at least one unit.(Overnuking)
--Overnuking is where a player deals so much damage (therefore generating excess threat) that it pulls aggro away from the tank.
--2 = insecurely tanking at least one unit, but not securely tanking anything.
--3 = securely tanking at least one unit.

--isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("unit", "mob")
--http://wow.gamepedia.com/API_UnitDetailedThreatSituation
--Returns 100 if the unit is tanking and nil if the unit is not on the mob's threat list.

function jps.findThreatInRaid()
	local defaultTank,TankUnit = jps.findTankInRaid()
	local maxThreat = 0
	for i=1,#TankUnit do
		local unit = TankUnit[i]
		local _,_,threatpct,_,_ = UnitDetailedThreatSituation(unit,"target")
		if threatpct and canHeal(unit) then
			if threatpct > maxThreat then
				maxThreat = threatpct
				defaultTank = unit
			end
		end
	end
	return defaultTank
end

---------------------------
-- HEALTH UNIT RAID
---------------------------

-- COUNTS THE NUMBER OF PARTY MEMBERS INRANGE HAVING A SIGNIFICANT HEALTH PCT LOSS
jps.CountInRaidStatus = function (heathpct)
	if heathpct == nil then heathpct = 1 end
	local countInRange = 0
	local FriendUnit = {}
	local raidHP = 0
	local avgHP = 1

	for unit,_ in pairs(RaidStatus) do
		local unitHP = HealthPct(unit)
		if canHeal(unit) and unitHP < heathpct then
			FriendUnit[#FriendUnit+1] = unit -- tinsert(FriendUnit, unit)
			raidHP = raidHP + unitHP
			countInRange = countInRange + 1
        end
	end
	tsort(FriendUnit, function(a,b) return HealthPct(a) < HealthPct(b) end)
	if countInRange > 0 then avgHP = raidHP / countInRange end
	return countInRange, avgHP, FriendUnit
end

-- COUNTS THE NUMBER OF PARTY MEMBERS INRANGE HAVING A SIGNIFICANT HEALTH PCT LOSS
-- WITH A RANGE WITH LibRangeCheck
jps.CountInRangeStatus = function (heathpct,range)
	if range == nil then range = 20 end
	if heathpct == nil then heathpct = 0.80 end
	local countInRange = 0
	local FriendUnit = {}
	local raidHP = 0
	local avgHP = 1

	for unit,_ in pairs(RaidStatus) do
		local unitHP = HealthPct(unit)
		local maxRange = jps.distanceMax(unit) 
		if maxRange <= range and unitHP < heathpct then
			FriendUnit[#FriendUnit+1] = unit -- tinsert(FriendUnit, unit)
			raidHP = raidHP + unitHP
			countInRange = countInRange + 1
        end
	end
	tsort(FriendUnit, function(a,b) return HealthPct(a) < HealthPct(b) end)
	if countInRange > 0 then avgHP = raidHP / countInRange end
	return countInRange, avgHP, FriendUnit
end

-- LOWEST PERCENTAGE in RaidStatus
jps.LowestInRaidStatus = function()
	local lowestUnit = "player"
	local lowestHP = 1
	for unit,_ in pairs(RaidStatus) do
		if canHeal(unit) then
			local unitHP = HealthPct(unit)
			if unitHP < lowestHP then
				lowestHP = unitHP
				lowestUnit = unit
			end
		end
	end
	return lowestUnit
end

-- LOWEST HP in RaidStatus
jps.LowestFriend = function()
	local lowestUnit = "player"
	local lowestHP = 0
	for unit,_ in pairs(RaidStatus) do
		local unitHP = UnitHealthMax(unit) - UnitHealth(unit) 
		if canHeal(unit) and unitHP > lowestHP then
			lowestHP = unitHP
			lowestUnit = unit
		end
	end
	return lowestUnit
end


-- WARNING FOCUS RETURN FALSE IF NOT IN GROUP OR RAID BECAUSE OF UNITINRANGE(UNIT)
-- CANHEAL returns TRUE for "target" and "focus" FRIENDS NOT IN RAID
jps.LowestImportantUnit = function()
	local LowestUnit = "player"
	if jps.Defensive then
		local myTanks = {"player","mouseover","target","focus","targettarget","focustarget"}
		local _,Tanks = jps.findTankInRaid()
		for i=1,#Tanks do
			local unit = Tanks[i]
			myTanks[#myTanks+1] = unit
		end
		local lowestHP = 1 -- in case with Inc & Abs > 1
		for i=1,#myTanks do -- for _,unit in ipairs(myTanks) do
			local unit = myTanks[i]
			local unitHP = HealthPct(unit)
			if canHeal(unit) and unitHP < lowestHP then 
				lowestHP = unitHP
				LowestUnit = unit
			end
		end
	else
		LowestUnit = jps.LowestInRaidStatus()
	end
	return LowestUnit
end

-- LOWEST TIME TO DIE
jps.LowestFriendTimeToDie = function(timetodie)
	if timetodie == nil then timetodie = 5 end
	local lowestFriendTTD = nil
	local lowestTTD = 60 -- Second
	for unit,_ in pairs(RaidStatus) do
		if canHeal(unit) then
			local TTD = jps.TimeToDie(unit)
			if TTD < timetodie then
				lowestFriendTTD = unit
				lowestTTD = TTD
			end
		end
	end
	return lowestFriendTTD
end

------------------------------------
-- GROUP FUNCTION IN RAID
------------------------------------
-- Patch 7.1.0 : RETURNS NIL WHILE INSIDE A RESTRICTED AREA (INSTANCE/BATTLEGROUND/ARENA).
-- jps.Distance(unit) Works with "player", "partyN" or "raidN" as unit type.
jps.FriendNearby = function(distance)
	if distance == nil then distance = 8 end
	local count = 0
	for unit,_ in pairs(RaidStatus) do
		if jps.Distance(unit) < distance and HealthPct(unit) < 0.95 then
			count = count + 1
		end
	end
	return count
end

-- FIND the Unit Layout of an UNITNAME in RAID -- Bob raid7
-- UnitInRaid Layout position for raid members: integer ascending from 0 (which is the first member of the first group)
-- UnitInRaid Returns a number if the unit is in your raid group, nil otherwise
-- local raidname = string.sub(unit,1,4) -- return raid
-- local raidIndex = tonumber(string.sub(unit,5)) -- raid1..40 return returns 1 for raid1, 13 for raid13
-- FIND THE SUBGROUP OF AN UNIT
-- partypet1 to partypet4 -- party1 to party4 -- raid1 to raid40 -- raidpet1 to raidpet40 -- arena1 to arena5 - A member of the opposing team in an Arena match
-- Pet return nil with UnitInRaid -- UnitInRaid("unit") returns 0 for raid1, 12 for raid13

local FindSubGroupUnit = function(unit) -- UnitNAME or raidn
	local subgroup = 1 
	if not IsInRaid() and IsInGroup() then return subgroup end
	if IsInRaid() then
		if UnitInRaid(unit) ~= nil then
			subgroup = math.ceil(UnitInRaid(unit)/5)
			-- math.floor(0.5) > 0 math.ceil(0.5) > 1 Renvoie le nombre entier au-dessus et au-dessous d'une valeur donnée.
		end
	end
	return subgroup
end

-- FIND THE RAID SUBGROUP TO HEAL WITH AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
-- name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex)
-- raidIndex of raid member between 1 and MAX_RAID_MEMBERS (40). If you specify an index that is out of bounds, the function returns nil
jps.FindSubGroupTarget = function(lowHealth)
	if lowHealth == nil then lowHealth = 1 end
	local groupTable = {}
	for i=1,MAX_RAID_MEMBERS do
		if GetRaidRosterInfo(i) == nil then break end
		local group = select(3,GetRaidRosterInfo(i)) -- if index is out of bounds, the function returns nil
		local name = select(1,GetRaidRosterInfo(i))
		if canHeal(name) and HealthPct(name) < lowHealth then
			local groupcount = groupTable[group]
			if groupcount == nil then groupcount = 1 else groupcount = groupcount + 1 end
			groupTable[group] = groupcount
		end
	end

	local groupCount = 2
	local groupToHeal = 0
	for i=1,#groupTable do
		if groupTable[i] == nil then break end
		if groupTable[i] > groupCount then -- HEAL >= 3 JOUEURS
			groupCount = groupTable[i]
			groupToHeal = i
		end
	end

	local tt = nil
	local lowestHP = lowHealth
	if groupToHeal > 0 then
		for unit,_ in pairs(RaidStatus) do
			local unitHP = HealthPct(unit)
			if FindSubGroupUnit(unit) == groupToHeal and unitHP < lowestHP then
				tt = unit
				lowestHP = unitHP
			end
		end
	end
	return tt, groupToHeal -- RETURN Group with at least 3 unit in range
end

-- FIND THE RAID SUBGROUP TO HEAL WITH AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
jps.FindSubGroupHeal = function(lowHealth)
	if lowHealth == nil then lowHealth = 1 end
	local HealthGroup = {}
	for unit,_ in pairs(RaidStatus) do
		local group = FindSubGroupUnit(unit)
		local unitHealth = HealthPct(unit)
		if not HealthGroup[group] then HealthGroup[group] = {} end

		local healthGroup = HealthGroup[group][1]
		if healthGroup == nil then healthGroup = 0 end
		local countGroup = HealthGroup[group][2]
		if countGroup == nil then countGroup = 0 end
		HealthGroup[group][1] = healthGroup + unitHealth 
		HealthGroup[group][2] = countGroup + 1

		local countUnitGroup = HealthGroup[group][3]
		if countUnitGroup == nil then
			countUnitGroup = 0
			HealthGroup[group][3] = countUnitGroup
		end
		if canHeal(unit) and unitHealth < lowHealth then
			HealthGroup[group][3] = countUnitGroup + 1
		end
	end
	
	local groupCount = 2
	local groupToHeal = 0
	local groupToHealHealthAvg = 1
	for group,index in pairs(HealthGroup) do
		local indexAvg = index[1] / index[2]
		local indexCount = index[3]
		if indexAvg < lowHealth and indexCount > groupCount then
			groupCount = indexCount
			groupToHealHealthAvg = indexAvg
			groupToHeal = tonumber(group)
		end
	end

	local tt = nil
	local lowestHP = lowHealth
	if groupToHealHealthAvg > lowHealth then return tt, groupToHeal, groupToHealHealthAvg end

	for unit,_ in pairs(RaidStatus) do
		local unitHealth = HealthPct(unit)
		if FindSubGroupUnit(unit) == groupToHeal and unitHealth < lowestHP then
			tt = unit
			lowestHP = unitHealth
		end
	end
	return tt, groupToHeal, groupToHealHealthAvg  -- RETURN Group unit with avg health group lower than lowHealth
end

-- FIND THE RAID SUBGROUP TO HEAL WITH AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
local FindSubGroup = function(lowHealth)
	if lowHealth == nil then lowHealth = 1 end
	local groupTable = {}
	for i=1,MAX_RAID_MEMBERS do
		if GetRaidRosterInfo(i) == nil then break end
		local group = select(3,GetRaidRosterInfo(i)) -- if index is out of bounds, the function returns nil
		local name = select(1,GetRaidRosterInfo(i))
		if canHeal(name) and HealthPct(name) < lowHealth then
			local groupcount = groupTable[group]
			if groupcount == nil then groupcount = 1 else groupcount = groupcount + 1 end
			groupTable[group] = groupcount
		end
	end

	local groupCount = 2
	local groupToHeal = 0
	for i=1,#groupTable do
		if groupTable[i] == nil then break end
		if groupTable[i] > groupCount then -- HEAL >= 3 JOUEURS
			groupCount = groupTable[i]
			groupToHeal = i
		end
	end
	return groupToHeal -- RETURN Group with at least 3 unit in range
end

-- FIND THE TARGET IN SUBGROUP TO HEAL WITH BUFF SPIRIT SHELL IN RAID
jps.FindSubGroupAura = function(aura) -- auraID to get correct spellID
	local tt = nil
	local tt_count = 0
	local groupToHeal = FindSubGroup()

	for unit,_ in pairs(RaidStatus) do
		local mybuff = jps.buffId(aura,unit) -- spellID
		if not mybuff and FindSubGroupUnit(unit) == groupToHeal then
			tt = unit
			tt_count = tt_count + 1
		end
	end
	if tt_count > 2 then return tt end
	return nil
end

-- CHECKS THE WHOLE RAID FOR A BUFF (E.G. PRAYER OF MENDING)
jps.buffTracker = function(buff)
	for unit,_ in pairs(RaidStatus) do
		if canHeal(unit) and jps.myBuffDuration(buff,unit) > 20 then
		return true end
	end
	return false
end

jps.buffTrackerCount = function(buff)
	local count = 0
	for unit,_ in pairs(RaidStatus) do
		if canHeal(unit) and jps.myBuffDuration(buff,unit) > 0 then
			count = count + 1
		end
	end
	return count
end

-- CHECKS THE WHOLE RAID FOR A MISSING BUFF (E.G. FORTITUDE)
jps.buffMissing = function(buff)
	for unit,_ in pairs(RaidStatus) do
		if canHeal(unit) and not jps.buff(buff,unit) then
		return true end
	end
	return false
end

---------------------------------
-- DISPEL FUNCTIONS RAID STATUS
---------------------------------
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitDebuff("unit", index or ["name", "rank"][, "filter"])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitBuff("unit", index or "name"[, "rank"[, "filter"]])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, ... = UnitAura("unit", index or "name"[, "rank"[, "filter"]])
-- spellId of the spell or effect that applied the aura

-- Don't Dispel if unit is affected by some debuffs
local WarningDebuffs = {
	toSpellName(31117), 	-- "Unstable Affliction"
	toSpellName(34914), 	-- "Vampiric Touch"
	}

-- Don't dispel if friend is affected by "Unstable Affliction" or "Vampiric Touch" or "Lifebloom"
jps.WarningDebuffs = function(unit)
	for i=1,#WarningDebuffs do
		local debuff = WarningDebuffs[i]
		if jps.debuff(debuff,unit) then return true end
	end
	return false
end

jps.RaidStatusDebuff = function() -- returns table 
	local RaidStatusDebuff = {}
	for unit,_ in pairs(RaidStatus) do
		local auraName, debuffType, expirationTime, castBy, spellId
		local i = 1
		auraName, _, _, _, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i) 
		while auraName do
			if debuffType ~= nil and expirationTime - GetTime() > 1 then
			RaidStatusDebuff[unit] = debuffType
			end
			i = i + 1
			auraName, _, _, _, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i)
		end
	end
	return RaidStatusDebuff
end

jps.canDispel = function(unit,dispelType) -- "Magic", "Poison", "Disease", "Curse"
	if not canHeal(unit) then return false end
	if jps.WarningDebuffs(unit) then return false end
	if dispelType == nil then dispelType = "Magic" end
	local auraName, debuffType, expirationTime, castBy, spellId
	local i = 1
	auraName, _, _, _, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i) 
	while auraName do
		if debuffType ~= nil and debuffType == dispeltype and expirationTime - GetTime() > 1 then
		if jps.Debug then write("debuffType:",debuffType) end
		return true end
		i = i + 1
		auraName, _, _, _, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i)
	end
	return false
end

jps.canDispelUnit = function(dispelType) -- "Magic", "Poison", "Disease", "Curse"
	if dispelType == nil then dispelType = "Magic" end
	local dispelUnit = nil
	local dispelUnitHP = 1
	local RaidStatusDebuff = jps.RaidStatusDebuff()
	for unit,_ in pairs(RaidStatus) do
		if RaidStatusDebuff[unit] == dispelType then -- jps.canDispel(unit,dispelType)
			local unitHP = HealthPct(unit)
			if unitHP < dispelUnitHP then
				dispelUnitHP = unitHP
				dispelUnit = unit
			end
		end
	end
	return dispelUnit
end

function jps.DispelMagicTarget()
	for unit,_ in pairs(RaidStatus) do
		if jps.canDispel(unit,"Magic") then return unit end
	end
end 

function jps.DispelDiseaseTarget()
	for unit,_ in pairs(RaidStatus) do
		if jps.canDispel(unit,"Disease") then return unit end
	end
end 

function jps.DispelPoisonTarget()
	for unit,_ in pairs(RaidStatus) do
		if jps.canDispel(unit,"Poison") then return unit end
	end
end 

function jps.DispelCurseTarget()
	for unit,_ in pairs(RaidStatus) do
		if jps.canDispel(unit,"Curse") then return unit end
	end
end

---------------------------------------
-- BOSS DEBUFF
---------------------------------------

function jps.BossDebuff(unit)
	if jps.WarningDebuffs(unit) then return false end
	local i = 1
	local auraName,debuffType,expirationTime,unitCaster,spellId,isBossDebuff
	auraName, _, _, _, debuffType, _, expirationTime, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(unit, i)
	while auraName do
		if UnitClassification(unitCaster) == "elite" and debuffType == "Magic" then return true end
		i = i + 1
		auraName, _, _, _, debuffType, _, expirationTime, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(unit, i)
	end
	return false
end

function jps.FindMeBossDebuff()
	for unit,_ in pairs(RaidStatus) do
		if canHeal(unit) and jps.BossDebuff(unit) then return unit end
	end
	return nil
end

-----------------------
-- FUNCTION LOOKUP RAID 
-----------------------

function jps.LookupRaid ()

-- RaidClass
	for unit,index in pairs(RaidStatusRole) do
		print("|cffe5cc80",unit,"Role: ",index.role,"Class: ",index.class) -- color beige(artifact)
	end
	
-- RaidStatus
	for unit,index in pairs(RaidStatus) do 
		print("|cffa335ee",unit,"Hpct: ",index.hpct,"/",HealthPct(unit),"Range: ",index.inrange,"/",canHeal(unit)) -- color violet 
	end

end






