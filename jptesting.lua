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
	print("Stun:|cff0070dd ",jps.checkTimer("PlayerStun"))
	print("Interrupt:|cff0070dd ",jps.checkTimer("PlayerInterrupt"))
	print("Shield:|cff0070dd ",jps.checkTimer("ShieldTimer"))
	print("Aggro:|cff0070dd ",jps.FriendAggro("player"))
	print("LoseControl:|cff0070dd ",jps.LoseControl("player"))
	print("Playerttd: ",jps.TimeToDie("target"))
	print("GCD: ",jps.GCD)
	print("Distance12: ",jps.FriendNearby(12))
	print("hasControl: ",HasFullControl()))
	write("***************************")

--	local CDtarget = jps.enemyCooldownWatch("target")
--	write("CDtarget: ",CDtarget)
	
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(1)
	print("POHTarget: ",POHTarget,"groupToHeal: ",groupToHeal,"groupHealth: ",groupHealth)
	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(100)
	print("CountInRange: ",CountInRange,"AvgHealthLoss: ", AvgHealthLoss)

	local myTank,Tanks = jps.findTankInRaid()
	print("|cff0070ddmyTank: ",GetUnitName(myTank))
	for i=1,#Tanks do
		print("|cff0070ddTanks: ",GetUnitName(Tanks[i]))
	end
	local aggroTank = jps.findThreatInRaid()
	print("|cFFFF0000Aggro: ",GetUnitName(aggroTank))
	local lowestUnit = jps.LowestImportantUnit()
	print("|cff1eff00Lowest: ",lowestUnit,":",GetUnitName(lowestUnit))

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

function jps_Test()

	Test()
	--DkTest()

end

function jps_RaidTest()

	jps.LookupRaid ()
	jps.LookupEnemyDamager()
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
	print("rangedTarget: ",rangedTarget,"TargetCount: ",TargetCount)
	print("EnemyUnit: ",unpack(EnemyUnit))

end

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

