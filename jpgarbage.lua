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

local RaidStatusDebuff = jps.RaidStatusDebuff()
for unit,debuff in pairs(RaidStatusDebuff) do
	print("unit:",unit,"debuff:",debuff)
end

--local _,_,classId = UnitClass("player")
--local specId = GetSpecialization()
--local id, name, description, icon, background, role, primaryStat = GetSpecializationInfo(specId)
--print("classId:",classId,"specId",specId)
--print("specName:",jps.specName(),"Spec",jps.Spec)
--print("jps.buff(jps.spells.priest.voidform):",jps.buff(jps.spells.priest.voidform))
--print("jps.spells.priest.lingeringInsanity):",jps.buff(jps.spells.priest.lingeringInsanity))
--print("jps.isUsableSpell(jps.spells.priest.voidEruption):",jps.isUsableSpell(jps.spells.priest.voidEruption))
print("isHealer: ", jps.isHealer)

	write("***************************")
	
--  print("Haste",UnitSpellHaste("player"),"-",GetCombatRating(20))
--	print("Stun:|cff0070dd ", jps.checkTimer("PlayerStun"))
--	print("Interrupt:|cff0070dd ", jps.checkTimer("PlayerInterrupt"))
--	print("|cFFFF0000Aggro:|cff0070dd ", jps.FriendAggro("player"))
print("|cFFFF0000IncDamage: ", jps.IncomingDamage("player"))
print("|cff1eff00IncHeal: ", jps.IncomingHeal("player"))
--	print("ControlEvents: ",jps.ControlEvents())
--	print("EnemyCastingSpellControl: ",jps.checkTimer("SpellControl") > 0)
--print("GCD: ", jps.GCD)
	write("***************************")
	
--local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(1)
--print("|cff1eff00POHTarget: |cffffffff",POHTarget,"|cff1eff00Group: |cffffffff",groupToHeal,"|cff1eff00Health: |cffffffff",groupHealth)

	local Tank,Tanks = jps.findTankInRaid()
	for i=1,#Tanks do
		print("|cff0070ddTank: ",GetUnitName(Tanks[i]))
	end
	local aggroTank = jps.findThreatInRaid()
	print("|cFFFF0000AggroTank: ",GetUnitName(aggroTank))
	local lowestUnit = jps.LowestImportantUnit()
	print("|cff1eff00Lowest: ",GetUnitName(lowestUnit))

--	local friendtableaggro = jps.FriendAggroTable()
--	print("friendtableaggro: ",friendtableaggro)

--	local Lowest = jps.LowestImportantUnit() 
--	local face,angle = jps.PlayerIsFacing(Lowest)
--	write("Facing: ",face," Radians: ",angle," Name: ",GetUnitName(Lowest))

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

function jps_RaidTest()
	jps.LookupRaid()
end
 
 function jps_Test()

	Test()
	--DkTest()
	--jps.LookupIncomingDamage()
	--jps.LookupEnemyDamager()
--	jps.LookupEnemyHealer()
--	local healerTarget = jps.LowestTargetHealer()
--	if healerTarget ~= nil then print("|cffffffffhealerTarget:|cff1eff00",healerTarget,"|cffffffffUnit:|cff1eff00",GetUnitName(healerTarget)) end
--
--	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
--	print("|cffffffffRangedTarget:|cff1eff00",rangedTarget,"|cffffffffTargetCount:|cff1eff00",TargetCount)

--	local enemyTable = jps.LowestTargetRole()
--	for unit,role in pairs(enemyTable) do
--		print("|cffffffffRole:|cff1eff00",role,"|cffffffffUnit:|cff1eff00",GetUnitName(unit))
--	end

--	TurnLeftStart()
--	C_Timer.After(1,function() print("test") TurnLeftStop() end)
--	MoveForwardStart()
--	C_Timer.After(0.25,function() MoveForwardStop() end)
	
--	local Tank,TankUnit = jps.findTankInRaid()
--	if Tank == "focus" then Tank = "player" end
--	local i = 1
--	local auraName,debuffType,expirationTime,unitCaster,spellId,isBossDebuff
--	auraName, _, _, _, debuffType, _, expirationTime, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(Tank, i)
--	while auraName do
--		print(Tank,
--		"|cff1eff00auraName: ","|cffffffff",auraName,
--		"|cff1eff00unitCaster: ","|cffffffff",unitCaster,"|cff1eff00Classification ","|cffffffff",UnitClassification(unitCaster),
--		"|cff1eff00spellId: ","|cffffffff",spellId,
--		"|cff1eff00isBossDebuff: ","|cffffffff",isBossDebuff
--		)
--		i = i + 1
--		auraName, _, _, _, debuffType, _, expirationTime, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(Tank, i)
--	end

--	local lowestUnit = jps.HighestIncomingDamage()
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
--	


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

