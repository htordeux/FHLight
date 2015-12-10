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
	print("Stun:|cff0070dd ", jps.checkTimer("PlayerStun"))
	print("Interrupt:|cff0070dd ", jps.checkTimer("PlayerInterrupt"))
	print("Shield:|cff0070dd ", jps.checkTimer("ShieldTimer"))
	print("|cFFFF0000Aggro:|cff0070dd ", jps.FriendAggro("player"))
	print("|cFFFF0000IncDamage:|cff0070dd ", jps.IncomingDamage("player"))
	--print("|cFFFF0000PhysicalDamage:|cff0070dd ", jps.SchoolDamage("physical"))
	print("EventHeal:|cff0070dd ", jps.IncomingHeal("player"))
	print("LoseControl:|cff0070dd ", jps.LoseControl("player"))
	print("PlayerTTD: ", jps.TimeToDie("player"))
	--print("GCD: ", jps.GCD)
	--print("Distance12: ", jps.FriendNearby(12))
	write("***************************")

--	local CDtarget = jps.enemyCooldownWatch("target")
--	write("CDtarget: ",CDtarget)
	
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(1)
	print("|cff1eff00POHTarget: |cffffffff",POHTarget,"|cff1eff00Group: |cffffffff",groupToHeal,"|cff1eff00Health: |cffffffff",groupHealth)
	--print("CountInRaid50: ",jps.CountInRaidLowest(0.50))
	--print("CountInRange80: ",jps.CountInRaidLowest(0.80))

	local myTank,Tanks = jps.findTankInRaid()
	print("|cff0070ddmyTank: ",GetUnitName(myTank))
	for i=1,#Tanks do
		print("|cff0070ddTanks: ",GetUnitName(Tanks[i]))
	end
	local aggroTank = jps.findThreatInRaid()
	print("|cFFFF0000Aggro: ",GetUnitName(aggroTank))
	local lowestUnit = jps.LowestImportantUnit()
	print("|cff1eff00Lowest: ",GetUnitName(lowestUnit))

--	local mastery = GetMasteryEffect()
--	local masteryValue = math.ceil(mastery)/100
--	local bonusHealing = math.ceil(GetSpellBonusHealing())
--	local minCrit = math.ceil(GetSpellCritChance(2))/100 -- 2 - Holy
--	print("priestFlash",priest.AvgAmountFlashHeal,"/",(1+masteryValue)*(1+minCrit)*(14664+(1.314*bonusHealing)))
--	print("priestGreat",priest.AvgAmountGreatHeal,"/",(1+masteryValue)*(1+minCrit)*(24430+(2.219*bonusHealing)))

--	local friendtableaggro = jps.FriendAggroTable()
--	print("friendtableaggro: ",friendtableaggro)

--	local Lowest = jps.LowestImportantUnit() 
--	local face,angle = jps.PlayerIsFacing(Lowest)
--	write("Facing: ",face," Radians: ",angle," Name: ",GetUnitName(Lowest))

end

local function DkTest()

	local Dr, Fr, Ur = dk.updateRune()
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

function jps_RaidTest()

	jps.LookupRaid ()
	jps.LookupEnemyDamager()
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
	print("rangedTarget: ",rangedTarget,"TargetCount: ",TargetCount)
	print("EnemyUnit: ",unpack(EnemyUnit))

end
 
 function jps_Test()

	Test()
	--DkTest()
	--	TurnLeftStart()
	--	C_Timer.After(1,function() print("test") TurnLeftStop() end)
	--	MoveForwardStart()
	--	C_Timer.After(0.25,function() MoveForwardStop() end)
	
--	local myTank,TankUnit = jps.findTankInRaid()
--	if myTank == "focus" then myTank = "player" end
--	local i = 1
--	local auraName,debuffType,expirationTime,unitCaster,spellId,isBossDebuff
--	auraName, _, _, _, debuffType, _, expirationTime, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(myTank, i)
--	while auraName do
--		print(myTank,
--		"|cff1eff00auraName: ","|cffffffff",auraName,
--		"|cff1eff00unitCaster: ","|cffffffff",unitCaster,"|cff1eff00Classification ","|cffffffff",UnitClassification(unitCaster),
--		"|cff1eff00spellId: ","|cffffffff",spellId,
--		"|cff1eff00isBossDebuff: ","|cffffffff",isBossDebuff
--		)
--		i = i + 1
--		auraName, _, _, _, debuffType, _, expirationTime, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(myTank, i)
--	end

	local lowestUnit = jps.HighestIncomingDamage()
	local lowestTTD = jps.LowestFriendTimeToDie(5)
	print("|cffffffffDamage: |cffff8000",lowestUnit,"|cffffffffTTD: |cffff8000",lowestTTD)

	--jps.Lookup()

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

