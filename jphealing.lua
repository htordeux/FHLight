
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
local function toSpellName(id) return tostring(select(1,GetSpellInfo(id))) end

----------------------
-- UPDATE RAIDROSTER
----------------------
-- GetNumSubgroupMembers() -- Number of players in the player's sub-group, excluding the player. remplace GetNumPartyMembers patch 5.0.4
-- GetNumGroupMembers() -- returns Number of players in the group (either party or raid), 0 if not in a group. remplace GetNumRaidMembers patch 5.0.4
-- IsInRaid() Boolean - returns true if the player is currently in a raid group, false otherwise
-- IsInGroup() Boolean - returns true if the player is in a some kind of group, otherwise false

local RaidStatusRole = {}
local RaidStatus = {}
local unitHpct = function(unit,inrange) if inrange then return jps.hp(unit) end end
local unitHealth = function(unit,inrange) if inrange then return jps.hp(unit,"abs") end end

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
		local inrange = canHeal(unit)
		RaidStatus[unit]["hpct"] = unitHpct(unit,inrange)
		RaidStatus[unit]["health"] = unitHealth(unit,inrange)
		RaidStatus[unit]["inrange"] = inrange
	end

-- Role in Raid -- with UnitGUID
-- local role = UnitGroupRolesAssigned(unit) -- works only for friendly unit in raid -- return "NONE" if not in raid	
	table.wipe(RaidStatusRole)
	for unit,_ in pairs(RaidStatus) do
		local unitguid = UnitGUID(unit)
		if RaidStatusRole[unitguid] == nil then RaidStatusRole[unitguid] = {} end
		local role = UnitGroupRolesAssigned(unit)
		local class = select(2,UnitClass(unit))
		RaidStatusRole[unitguid]["role"] = role
		RaidStatusRole[unitguid]["class"] = class
	end

end

-- Unit is INRANGE
jps.UpdateRaidUnit = function (unit,inrange)
	if RaidStatus[unit] == nil then RaidStatus[unit] = {} end
	RaidStatus[unit]["hpct"] = unitHpct(unit,inrange)
	RaidStatus[unit]["health"] = unitHealth(unit,inrange)
	RaidStatus[unit]["inrange"] = inrange
end

jps.UnitInRaid = function(unit)
	if RaidStatus[unit] ~= nil then return true end
	return false
end

-- IsInRaid() Boolean - returns true if the player is currently in a raid group, false otherwise
-- IsInGroup() Boolean - returns true if the player is in a some kind of group, otherwise false
-- leader = UnitIsRaidOfficer("unit") -- 1 if the unit is a raid assistant; otherwise nil or false if not in raid
-- leader = UnitIsGroupLeader("unit") -- true if the unit is a raid assistant; otherwise false (bool)

local IsRaidLeader = function()
	for i=1,MAX_RAID_MEMBERS do
		-- if index is out of bounds, the function returns nil
		if GetRaidRosterInfo(i) == nil then return 0 end
		local rank = select(2,GetRaidRosterInfo(i))
		local name = select(1,GetRaidRosterInfo(i))
		if name == GetUnitName("player") then return rank end
	end
end

function jps.PlayerIsLeader()
	local RaidLeader = IsRaidLeader()
	if IsInRaid() and RaidLeader > 0 then return true end
	if not IsInRaid() and not IsInGroup() then return true end
	return false
end

--------------------------
-- CLASS SPEC RAIDROSTER
--------------------------

-- "DAMAGER" , "HEALER" , "TANK" , "NONE"
jps.RoleInRaid = function (unit)
	local unitguid = UnitGUID(unit)
	if RaidStatusRole[unitguid] then return RaidStatusRole[unitguid]["role"] end
	return "NONE"
end

-- "DAMAGER" , "HEALER" , "TANK" , "NONE"
local findTanksInRaid = function(unit)
	local foundTank = false
	if UnitGroupRolesAssigned(unit) == "TANK" then
		foundTank = true
	end
	if foundTank == false and jps.buff(L["Bear Form"],unit) then
		foundTank = true
	end
	if foundTank == false and jps.buff(L["Blood Presence"],unit) then
		foundTank = true
	end
	if foundTank == false and jps.buff(L["Righteous Fury"],unit) then
		foundTank = true
	end
	return foundTank
end

function jps.findTanksInRaid()
	local myTanks = {}
	for unit,index in pairs(RaidStatus) do
		if findTanksInRaid(unit) then tinsert(myTanks, unit) end
	end
	return myTanks
end

function jps.FriendHealerInRange()
	for unit,index in pairs(RaidStatus) do
		if jps.RoleInRaid(unit) == "HEALER" and index.inrange then return true end
	end
	return false
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
	if countInRange >= 1 then avgHP = raidHP / countInRange end
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

-- AVG RAID PERCENTAGE in RaidStatus without aberrations
jps.avgRaidHP = function()
	local raidHP = 0
	local unitCount = 0
	local avgHP = 1
	for unit, unitTable in pairs(RaidStatus) do
		if unitTable["inrange"] then
			local unitHP = unitTable["hpct"]
			if unitHP then
				raidHP = raidHP + unitHP
				unitCount = unitCount + 1
			end
		end
	end
	if unitCount >= 1 then avgHP = raidHP / unitCount end
	return avgHP
end

local myTanks = { "player","focus","target","targettarget","mouseover" }
-- WARNING FOCUS RETURN FALSE IF NOT IN GROUP OR RAID BECAUSE OF UNITINRANGE(UNIT)
jps.LowestImportantUnit = function()
	local LowestImportantUnit = "player"
	if jps.Defensive then 
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

jps.FindSubGroupUnit = function(unit) -- UnitNAME or raidn
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
	local group = 0
	local name = nil
	local groupTable = {}
	for i=1,MAX_RAID_MEMBERS do
		if GetRaidRosterInfo(i) == nil then break end
		group = select(3,GetRaidRosterInfo(i)) -- if index is out of bounds, the function returns nil
		name = select(1,GetRaidRosterInfo(i))
		if canHeal(name) and jps.hp(name) < lowHealthDef then
			local groupcount = groupTable[group]
			if groupcount == nil then groupcount = 1 else groupcount = groupcount + 1 end
			groupTable[group] = groupcount
		end
	end
	
	local groupToHeal = 0
	local groupVal = 2
	local groupTableToHeal = {}
	for i=1,#groupTable do
		if groupTable[i] == nil then break end
		if groupTable[i] > groupVal then -- HEAL >= 3 JOUEURS
			groupVal = groupTable[i]
			groupToHeal = i
			tinsert(groupTableToHeal,i)
		end
	end

	local tt = nil
	local lowestHP = lowHealthDef
	if groupToHeal > 0 then
		for unit,index in pairs(RaidStatus) do
			if (index["inrange"] == true) and (jps.FindSubGroupUnit(unit) == groupToHeal) and (index["hpct"] < lowestHP) then
				tt = unit
				lowestHP = index["hpct"]
			end
		end
	end
	return tt, groupToHeal, groupTableToHeal -- RETURN Group with at least 3 unit in range
end

-- FIND THE RAID SUBGROUP TO HEAL WITH AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
jps.FindSubGroup = function()
		local group = 0
		local name = nil
		local groupTable = {}
		for i=1,MAX_RAID_MEMBERS do
			if GetRaidRosterInfo(i) == nil then break end
			group = select(3,GetRaidRosterInfo(i)) -- if index is out of bounds, the function returns nil
			name = select(1,GetRaidRosterInfo(i))
			if canHeal(name) and jps.hp(name) < lowHealthDef then
				local groupcount = groupTable[group]
				if groupcount == nil then groupcount = 1 else groupcount = groupcount + 1 end
				groupTable[group] = groupcount
			end
		end
		
		local groupToHeal = 0
		local groupVal = 2
		local groupTableToHeal = {}
		for i=1,#groupTable do
			if groupTable[i] == nil then break end
			if groupTable[i] > groupVal then -- HEAL >= 3 JOUEURS
				groupVal = groupTable[i]
				groupToHeal = i
				tinsert(groupTableToHeal,i)
			end
		end
	return groupToHeal, groupTableToHeal -- RETURN Group with at least 3 unit in range
end

-- FIND THE TARGET IN SUBGROUP TO HEAL WITH BUFF SPIRIT SHELL IN RAID
jps.FindSubGroupAura = function(aura,tank) -- auraID to get correct spellID
	local tt = nil
	local tt_count = 0
	local groupToHeal = 1
	if tank == nil then groupToHeal = jps.FindSubGroup()
	else groupToHeal = jps.FindSubGroupUnit(tank) end 

	for unit,index in pairs(RaidStatus) do
		local mybuff = jps.buffId(aura,unit) -- spellID
		if (not mybuff) and (index["inrange"] == true) and (jps.FindSubGroupUnit(unit) == groupToHeal) then
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
	local auraName, icon, count, debuffType, expirationTime, castBy
	local i = 1
	auraName, _, icon, count, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i) -- UnitAura(unit,i,"HARMFUL") 
	while auraName do
		for _,dispeltype in ipairs(dispelTable) do
			if debuffType == dispeltype then
			return true end
		end
		i = i + 1
		auraName, _, icon, count, debuffType, _, expirationTime, castBy, _, _, spellId = UnitDebuff(unit, i) -- UnitAura(unit,i,"HARMFUL") 
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
		print("|cffa335ee",unit,"Hpct: ",index.hpct,"Health: ",index.health,"Range: ",index.inrange) -- color violet 
	end
end






