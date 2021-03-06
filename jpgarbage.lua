--[[
|cffe5cc80 = beige (artifact)
|cffff8000 = orange (legendary)
|cffa335ee = purple (epic)
|cff0070dd = blue (rare)
|cff1eff00 = green (uncommon)
|cffffffff = white (normal)
|cff9d9d9d = gray (crappy)
|cFFFFff00 = yellow
|cFFFF0000 = red
]]

--[[
ShiftKeyIsDown = IsShiftKeyDown();
AltKeyIsDown = IsAltKeyDown();
CtrlKeyIsDown = IsControlKeyDown();
]]

-----------------------
-- FUNCTION TEST 
-----------------------

local function Test()

write("***************************")
--  print("Haste",UnitSpellHaste("player"),"-",GetCombatRating(20))
--	print("Stun:|cff0070dd ", jps.checkTimer("PlayerStun"))
--	print("Interrupt:|cff0070dd ", jps.checkTimer("PlayerInterrupt"))
--	print("|cFFFF0000Aggro:|cff0070dd ", jps.FriendAggro("player"))
--	print("ControlEvents: ",jps.ControlEvents())
--	local TargetGroup, HealthGroup = jps.FindSubGroupHeal()
--	print("|cff1eff00Target: |cffffffff",TargetGroup,"|cff1eff00HealthGroup: |cffffffff",HealthGroup)
--  print("|cff1eff00TTDTarget: |cffffffff",jps.TimeToDie("target"))
print("|cFFFF0000IncDamage: ", jps.IncomingDamage("target"))
print("|cff1eff00IncHeal: ", jps.IncomingHeal("target"))
local CountInRange, AvgHealth, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80)
print("|cff1eff00CountInRange: |cffffffff",CountInRange,"|cff1eff00FriendUnit: |cffffffff",#FriendUnit,"|cff1eff00AvgHealth: |cffffffff",AvgHealth,"|cff1eff00FriendLowest: |cffffffff",GetUnitName(FriendLowest))
local LowestUnit = jps.LowestImportantUnit()
print("|cff1eff00LowestUnit: |cffffffff",GetUnitName(LowestUnit))
local LowestTarget = jps.findLowestTargetInRaid()
print("|cff1eff00LowestTarget: |cffffffff",GetUnitName(LowestTarget))
write("***************************")
local Tank,Tanks = jps.findRaidTank()
local Threat,Threats = jps.findRaidTankThreat()
print("|cff0070ddTank: |cffffffff",GetUnitName(Tank), "|cFFFF0000Theat: |cffffffff",GetUnitName(Threat))
for i=1,#Tanks do
	print("|cff0070ddTank: |cffffffff",GetUnitName(Tanks[i]))
end
for i=1,#Threats do
	print("|cFFFF0000TankThreat: |cffffffff",GetUnitName(Threats[i]))
end
write("***************************")


end

local function DkTest()

	local Dr, Fr, Ur = jps.updateRune()
	local DeathRuneCount = dk.updateDeathRune()
	print("Dr:", Dr ,"Fr:", Fr ,"Ur:", Ur )
	print("DeathRune:",DeathRuneCount)
	
	local RunesCD = 0
	for i=1,6 do
		local cd = dk.runeCooldown(i)
		RunesCD = RunesCD + cd
	end
	print("RunesCD:",RunesCD)

end

function jps.RaidTest()
	jps.LookupRaid()
end

function ChatRandom()
	-- SendChatMessage("text" [, "chatType" [, languageIndex [, "channel"]]])
	local table = { "bonsoir" , "Seul est vraiment libre l'homme qui ne possède rien", "La liberté commence où l'ignorance finit",
	"La liberté n'existe que si l'on s'en sert", "L'ambition est le dernier refuge de l’échec" }
	
	local str = ""
	local val = 0
	val = math.random(1,#table)
	str = table[val]
	SendChatMessage("bonsoir"..str , "GUILD" )
end
 
function jpsTest()

Test()

--local value = select(17,UnitBuff("player",jps.spells.priest.echoOfLight))
--local duration = select(6,UnitBuff("player",jps.spells.priest.echoOfLight))
--print(name,spellId,"|cFFFF0000value1: |cffffffff", value , duration)
--print("|cFFFF0000Test:", jps.buffValue(77489) )

--print("|cff1eff00prayerOfMendingBuff: |cffffffff", jps.buffTrackerCharge(41635),":", jps.buffTrackerDuration(41635))

--local RaidStatusDebuff = jps.RaidStatusDebuff()
--write("RaidStatusDebuff: ",jps.tableCount(RaidStatusDebuff))
--for unit,debuff in pairs(RaidStatusDebuff) do
--	print("unit:",unit,"debuff:",unpack(debuff))
--end

--local rc = LibStub("LibRangeCheck-2.0")
--local minRange, maxRange = rc:GetRange('target')
--if not minRange then
--print("cannot get range estimate for target")
--elseif not maxRange then
--print("target is over " .. minRange .. " yards")
--else
--print("target is between " .. minRange .. " and " .. maxRange .. " yards")
--end

--print(jps.isUsableSpell(jps.spells.priest.shadowWordDeath))
--print(jps.spellCharges(jps.spells.priest.shadowWordDeath))
--print(jps.cooldown(jps.spells.priest.shadowWordDeath))

--local target = GetUnitName("target")
--print("find",string.find(target,"Mannequin") ~= nil )
--print("match",string.match(target,"Mannequin") ~= nil )

--local _,_,classId = UnitClass("player")
--local specId = GetSpecialization()
--local id, name, description, icon, background, role, primaryStat = GetSpecializationInfo(specId)
--print("classId:",classId,"specId",specId)
--print("specName:",jps.specName(),"Spec",jps.Spec)
--print("isHealer: ", jps.isHealer)

--	jps.LookupIncomingDamage()
--	jps.LookupEnemyDamager()
--	jps.LookupEnemyHealer()

--	local rangedTarget, EnemyUnit, EnemyCount = jps.LowestEnemy()
--	if jps.canDPS("focus") then EnemyUnit[#EnemyUnit+1] = "focus" end
--	print("|cffffffffRangedTarget:|cff1eff00",rangedTarget,"|cffffffffEnemyCount:|cff1eff00",TargetCount)
--	print("|cffffffffEnemyUnit:|cff1eff00",unpack(EnemyUnit))

--	local enemyTable = jps.LowestEnemyRole()
--	for unit,role in pairs(enemyTable) do
--		print("|cffffffffRole:|cff1eff00",role,"|cffffffffUnit:|cff1eff00",GetUnitName(unit))
--	end

--	TurnLeftStart()
--	C_Timer.After(1,function() print("test") TurnLeftStop() end)
--	MoveForwardStart()
--	C_Timer.After(0.25,function() MoveForwardStop() end)

--	local lowestTTD = jps.LowestFriendTimeToDie(5)
--	print("|cffffffffDamage: |cffff8000",lowestUnit,"|cffffffffTTD: |cffff8000",lowestTTD)


--	local table_1 = { {"target","HEALER"}, {"playertarget","DEFENSIVE"}, {"raid4target","DAMAGE"} }
--	local table_2 = { ["target"] = "HEALER", ["playertarget"] = "DEFENSIVE", ["raid4target"] = "DAMAGE" }
--	local table_3 = { ["target"] = {"HEALER","A"}, ["playertarget"] = {"DEFENSIVE","B"}, ["raid4target"] = {"DAMAGE","C"} }
--	
--	table.insert(table_1,{"player","TEST"})
--	table_2["player"] = "TEST"
--	table_3["player"] = {"TEST","D"}
--	
--	for i,j in pairs(table_1) do
--		print(i,"unit: ",j[1],"role: ",j[2])
--	end
--	for i,j in pairs(table_2) do
--		print("unit: ",i,"role: ",j)
--	end
--	for i,j in pairs(table_3) do
--		print("unit: ",i,"role: ",j[1],"-",j[2])
--	end


--for distIndex =1,6 do
--	local inRange = CheckInteractDistance("target", distIndex)
--	print("distIndex:",distIndex,"inRange:",inRange)
--end
--
--1 et 4 false to true à 28 yards
--2 false to true à 8 yards
--3 et 5 false to true à 7 yards


end

--[[
local hostile = {
  ["_DAMAGE"] = true, 
  ["_LEECH"] = true,
  ["_DRAIN"] = true,
  ["_STOLEN"] = true,
  ["_INSTAKILL"] = true,
  ["_INTERRUPT"] = true,
  ["_MISSED"] = true
}

local function GetEnemy(time, event, sguid, sname, sflags, dguid, dname, dflags)
	local suffix = event:match(".+(_.-)$")
	if hostile[suffix] then
		if bit.band(sflags, COMBATLOG_OBJECT_AFFILIATION_MASK) < 8 then
			return dguid, dname, dflags
		elseif bit.band(dflags, COMBATLOG_OBJECT_AFFILIATION_MASK) < 8 then
			return sguid, sname, sflags
		end
	end
end
]]

--[[
local tsort = table.sort
local table = {9,5,12,1,2,4}
for i=1,#table do
	print("|cffe5cc80",table[i])
end
tsort(table, function(a,b) return a >= b end)
for i=1,#table do
	print("sort>",table[i]) -- 12,9,5,4,1,2
end
tsort(table, function(a,b) return a <= b end)
for i=1,#table do
	write("sort<",table[i]) -- 1,2,4,5,9,12
end


local myTanks = { "player","focus","target" }
myTanks[1] = "prout";
write("1",unpack(myTanks)) -- "prout,focus,target"

local myTanks = { "player","focus","target" }
myTanks[#myTanks] = "prout";  
write("2",unpack(myTanks)) -- player,focus,prout"

local myTanks = { "player","focus","target" }
myTanks[#myTanks+1] = "prout";  
write("3",unpack(myTanks)) -- "player,focus,target,prout"
]]

-----------------------
-- FUNCTION MEMORY
-----------------------

