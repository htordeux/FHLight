
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local GetSpellInfo = GetSpellInfo
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

-- Localization
local L = MyLocalizationTable
local canHeal = jps.canHeal
local canDPS = jps.canDPS
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitClass = UnitClass
local GetUnitName = GetUnitName
local tinsert = table.insert
local pairs = pairs

-- local function
local function toSpellName(id)
	local name = GetSpellInfo(id)
	return name
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

	table.wipe(RaidStatus)
	for i=nps,npe do
		if i==0 then
			unit = "player"
		else
			unit = grouptype..i
		end
		
		if RaidStatus[unit] == nil then RaidStatus[unit] = {} end
		RaidStatus[unit]["hpct"] = jps.hp(unit)
		RaidStatus[unit]["inrange"] = canHeal(unit)
	end
end

-- Unit is INRANGE
jps.UpdateRaidUnit = function (unit)
	if RaidStatus[unit] == nil then RaidStatus[unit] = {} end
	RaidStatus[unit]["hpct"] = jps.hp(unit)
	RaidStatus[unit]["inrange"] = canHeal(unit)
end

jps.UnitInRaid = function(unit)
	if RaidStatus[unit] ~= nil then return true end
	return false
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
	table.wipe(RaidStatusRole)
	for unit,_ in pairs(RaidStatus) do
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

function jps.FriendHealerInRange()
	for unit,index in pairs(RaidStatus) do
		if jps.RoleInRaid(unit) == "HEALER" and index.inrange then return true end
	end
	return false
end

--------------------------
-- TANK
--------------------------

--status = UnitThreatSituation("unit"[, "otherunit"])
--Without otherunit specified
--nil = unit is not on any other unit's threat table.
--0 = not tanking anything.
--1 = not tanking anything, but have higher threat than tank on at least one unit.(Overnuking)
--Overnuking is where a player deals so much damage (therefore generating excess threat) that it pulls aggro away from the tank.
--2 = insecurely tanking at least one unit, but not securely tanking anything.
--3 = securely tanking at least one unit.

function jps.findTankInRaid()
	local myTanks = {}
	for unit,index in pairs(RaidStatus) do
		if jps.RoleInRaid(unit) == "TANK" then tinsert(myTanks,unit) end
	end
	local highestThreat = 0
	local aggroTank = myTanks[1] or "focus"
	for _, tank in ipairs(myTanks) do
		local unitThreat = UnitThreatSituation(tank)
		if unitThreat and unitThreat > highestThreat then
			highestThreat = unitThreat
			aggroTank = tank
		end
	end
	return aggroTank, myTanks
end

function jps.findAggroInRaid()
	local TankUnit = {}
	for unit,_ in pairs(RaidStatus) do
		local Threat = UnitThreatSituation(unit)
		if Threat then
			if Threat == 1 then tinsert(TankUnit, unit)
			elseif Threat == 3 then tinsert(TankUnit, unit) end
		end
	end
	table.sort(TankUnit, function(a,b) return jps.hp(a) < jps.hp(b) end)
	return TankUnit[1] or "focus", TankUnit
end

----------------------
-- UPDATE RAIDTARGET
----------------------

local RaidTarget = {}
jps.LowestTarget = function()
	table.wipe(RaidTarget)
	for unit,index in pairs (RaidStatus) do
		if canDPS(unit.."target") then
			local unittarget = unit.."target"
			tinsert(RaidTarget, unittarget)
		end
	end
	
	local hash = {}
	for _,v in ipairs(RaidTarget) do -- { "playertarget" , "raid5target" , "raid4target" }
		local targuid = UnitGUID(v)
		hash[targuid] = v -- hash = { [targuid1] = "playertarget" , [targuid2] = "raid5target"}
	end

	local dupe = {}
	for _,j in pairs(hash) do
		dupe[#dupe+1] = j -- dupe = { "playertarget" , "raid5target" }
	end
	table.sort(dupe, function(a,b) return jps.hp(a) < jps.hp(b) end)
	return dupe[1] or "target", dupe, #dupe
end

---------------------------
-- HEALTH UNIT RAID
---------------------------

-- COUNTS THE NUMBER OF PARTY MEMBERS INRANGE HAVING A SIGNIFICANT HEALTH PCT LOSS
jps.CountInRaidStatus = function (lowHealthDef)
	if lowHealthDef == nil then lowHealthDef = 1 end
	local countInRange = 0
	local myFriends = {}
	local raidHP = 0
	local avgHP = 1

	for unit,index in pairs(RaidStatus) do
		if (index["inrange"] == true) then
			tinsert(myFriends, unit)
			raidHP = raidHP + index["hpct"]
			if index["hpct"] <= lowHealthDef then
				countInRange = countInRange + 1
			end
        end
	end
	table.sort(myFriends, function(a,b) return jps.hp(a) < jps.hp(b) end)
	if countInRange > 0 then avgHP = raidHP / countInRange end
	return countInRange, avgHP, myFriends
end

-- LOWEST PERCENTAGE in RaidStatus
jps.LowestInRaidStatus = function()
	local lowestUnit = "player"
	local lowestHP = 100
	for unit,unitTable in pairs(RaidStatus) do
		if (unitTable["inrange"] == true) and unitTable["hpct"] < lowestHP then
			lowestHP = Ternary(jps.isHealer, unitTable["hpct"], jps.hp(unit)) -- if isHealer is disabled get health value from jps.hp() (some "non-healer" rotations uses LowestInRaidStatus)
			lowestUnit = unit
		end
	end
	return lowestUnit
end

-- LOWEST HP in RaidStatus
jps.LowestFriendly = function()
	local lowestUnit = "player"
	local lowestHP = 0
	for unit,unitTable in pairs(RaidStatus) do
	local thisHP = UnitHealthMax(unit) - UnitHealth(unit) 
		if (unitTable["inrange"] == true) and thisHP > lowestHP then
			lowestHP = thisHP
			lowestUnit = unit
		end
	end
	return lowestUnit
end


-- WARNING FOCUS RETURN FALSE IF NOT IN GROUP OR RAID BECAUSE OF UNITINRANGE(UNIT)
-- CANHEAL returns TRUE for "target" and "focus" FRIENDS NOT IN RAID
jps.LowestImportantUnit = function()
	local myTanks = { "player","focus","target","targettarget","mouseover" }
	local LowestImportantUnit = "player"
	if jps.Defensive then
		local _,aggroTanks = jps.findAggroInRaid()
		for i,j in ipairs(aggroTanks) do
			table.insert(myTanks, j)
		end
		local lowestHP = 100 -- in case with Inc & Abs > 1
		for _, unit in pairs(myTanks) do
			local thisHP = jps.hp(unit)
			if canHeal(unit) and thisHP <= lowestHP then 
				lowestHP = thisHP
				LowestImportantUnit = unit
			end
		end
	else
		LowestImportantUnit = jps.LowestInRaidStatus()
	end
	return LowestImportantUnit
end

------------------------------------
-- GROUP FUNCTION IN RAID
------------------------------------

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
jps.FindSubGroupTarget = function(lowHealthDef)
	if lowHealthDef == nil then lowHealthDef = 1 end
	local groupTable = {}
	for i=1,MAX_RAID_MEMBERS do
		if GetRaidRosterInfo(i) == nil then break end
		local group = select(3,GetRaidRosterInfo(i)) -- if index is out of bounds, the function returns nil
		local name = select(1,GetRaidRosterInfo(i))
		if canHeal(name) and jps.hp(name) <= lowHealthDef then
			local groupcount = groupTable[group]
			if groupcount == nil then groupcount = 1 else groupcount = groupcount + 1 end
			groupTable[group] = groupcount
		end
	end

	local groupCount = 2
	local groupToHeal = 0
	local groupTableToHeal = {}
	for i=1,#groupTable do
		if groupTable[i] == nil then break end
		if groupTable[i] > groupCount then -- HEAL >= 3 JOUEURS
			groupCount = groupTable[i]
			groupToHeal = i
			tinsert(groupTableToHeal,i)
		end
	end

	local tt = nil
	local lowestHP = lowHealthDef
	if groupToHeal > 0 then
		for unit,index in pairs(RaidStatus) do
			if index["inrange"] == true and FindSubGroupUnit(unit) == groupToHeal and index["hpct"] <= lowestHP then
				tt = unit
				lowestHP = index["hpct"]
			end
		end
	end
	return tt, groupToHeal -- RETURN Group with at least 3 unit in range
end

-- FIND THE RAID SUBGROUP TO HEAL WITH AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
jps.FindSubGroupHeal = function(lowHealthDef)
	if lowHealthDef == nil then lowHealthDef = 1 end
	local HealthGroup = {}
	for unit,index in pairs(RaidStatus) do
		local group = FindSubGroupUnit(unit)
		local unitHealth = jps.hp(unit)
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
		if unitHealth <= lowHealthDef and canHeal(unit) then
			HealthGroup[group][3] = countUnitGroup + 1
		end
	end
	
	local groupCount = 2
	local groupToHeal = 0
	local groupToHealHealthAvg = 100
	for group,index in pairs(HealthGroup) do
		local indexAvg = index[1] / index[2]
		local indexCount = index[3]
		if indexAvg <= lowHealthDef and indexCount > groupCount then
			groupCount = indexCount
			groupToHealHealthAvg = indexAvg
			groupToHeal = tonumber(group)
		end
	end
	
	if groupToHealHealthAvg > lowHealthDef then return nil end
	local tt = nil
	local lowestHP = lowHealthDef
	for unit,index in pairs(RaidStatus) do
		local unitHealth = jps.hp(unit)
		if FindSubGroupUnit(unit) == groupToHeal and unitHealth <= lowestHP then
			tt = unit
			lowestHP = unitHealth
		end
	end
	return tt, groupToHeal, groupToHealHealthAvg  -- RETURN Group unit with avg health group lower than lowHealthDef
end

-- FIND THE RAID SUBGROUP TO HEAL WITH AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
local FindSubGroup = function(lowHealthDef)
	if lowHealthDef == nil then lowHealthDef = 1 end
	local groupTable = {}
	for i=1,MAX_RAID_MEMBERS do
		if GetRaidRosterInfo(i) == nil then break end
		local group = select(3,GetRaidRosterInfo(i)) -- if index is out of bounds, the function returns nil
		local name = select(1,GetRaidRosterInfo(i))
		if canHeal(name) and jps.hp(name) <= lowHealthDef then
			local groupcount = groupTable[group]
			if groupcount == nil then groupcount = 1 else groupcount = groupcount + 1 end
			groupTable[group] = groupcount
		end
	end

	local groupCount = 2
	local groupToHeal = 0
	local groupTableToHeal = {}
	for i=1,#groupTable do
		if groupTable[i] == nil then break end
		if groupTable[i] > groupCount then -- HEAL >= 3 JOUEURS
			groupCount = groupTable[i]
			groupToHeal = i
			tinsert(groupTableToHeal,i)
		end
	end
	return groupToHeal -- RETURN Group with at least 3 unit in range
end

-- FIND THE TARGET IN SUBGROUP TO HEAL WITH BUFF SPIRIT SHELL IN RAID
jps.FindSubGroupAura = function(aura) -- auraID to get correct spellID
	local tt = nil
	local tt_count = 0
	local groupToHeal, _ = FindSubGroup()

	for unit,index in pairs(RaidStatus) do
		local mybuff = jps.buffId(aura,unit) -- spellID
		if not mybuff and index["inrange"] == true and FindSubGroupUnit(unit) == groupToHeal then
			tt = unit
			tt_count = tt_count + 1
		end
	end
	if tt_count > 2 then return tt end
	return nil
end

-- CHECKS THE WHOLE RAID FOR A BUFF (E.G. PRAYER OF MENDING)
jps.buffTracker = function(buff)
	for unit,index in pairs(RaidStatus) do
		if (index["inrange"] == true) and jps.myBuffDuration(buff,unit) > 0 then
		return true end
	end
	return false
end

-- CHECKS THE WHOLE RAID FOR A MISSING BUFF (E.G. FORTITUDE)
jps.buffMissing = function(buff)
	for unit,index in pairs(RaidStatus) do
		if (index["inrange"] == true) and not jps.buff(buff,unit) then
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
local DebuffNotDispel = {
	toSpellName(31117), 	-- "Unstable Affliction"
	toSpellName(34914), 	-- "Vampiric Touch"
	}
-- Don't dispel if friend is affected by "Unstable Affliction" or "Vampiric Touch" or "Lifebloom"
local NotDispelFriendly = function(unit)
	for _,debuff in ipairs(DebuffNotDispel) do
		if jps.debuff(debuff,unit) then return true end
	end
	return false
end

jps.canDispel = function (unit,dispelTable) -- {"Magic", "Poison", "Disease", "Curse"}
	if not canHeal(unit) then return false end
	if NotDispelFriendly(unit) then return false end
	if dispelTable == nil then dispelTable = {"Magic"} end
	local auraName, debuffType, expirationTime, castBy, spellId
	local i = 1
	auraName, _, _, _, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i) 
	while auraName do
		for _,dispeltype in ipairs(dispelTable) do
			if debuffType == dispeltype and expirationTime-GetTime() > 1 then
			return true end
		end
		i = i + 1
		auraName, _, _, _, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i)
	end
	return false
end

jps.FindMeDispelTarget = function (dispelTable) -- {"Magic", "Poison", "Disease", "Curse"}
	local dispelUnit = nil
	local dispelUnitHP = 100
	for unit,index in pairs(RaidStatus) do	 
		if (index["inrange"] == true) then
			if jps.canDispel(unit,dispelTable) then
				local unitHP = jps.hp(unit)
				if unitHP < dispelUnitHP then
					dispelUnitHP = unitHP
					dispelUnit = unit
				end
			end
		end
	end
	return dispelUnit
end

function jps.DispelMagicTarget()
	for unit,index in pairs(RaidStatus) do	 
		if (index["inrange"] == true) and jps.canDispel(unit,{"Magic"}) then return unit end
	end
end 

function jps.DispelDiseaseTarget()
	for unit,index in pairs(RaidStatus) do	 
		if (index["inrange"] == true) and jps.canDispel(unit,{"Disease"}) then return unit end
	end
end 

function jps.DispelPoisonTarget()
	for unit,index in pairs(RaidStatus) do	 
		if (index["inrange"] == true) and jps.canDispel(unit,{"Poison"}) then return unit end
	end
end 

function jps.DispelCurseTarget()
	for unit,index in pairs(RaidStatus) do	 
		if (index["inrange"] == true) and jps.canDispel(unit,{"Curse"}) then return unit end
	end
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
		print("|cffa335ee",unit,"Hpct: ",index.hpct,"Range: ",index.inrange) -- color violet 
	end
end






