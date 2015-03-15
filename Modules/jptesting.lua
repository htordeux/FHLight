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

-----------------------
-- FUNCTION TEST 
-----------------------

-- local function
local GetSpellInfo = GetSpellInfo
local function toSpellName(id)
	local name = GetSpellInfo(id)
	return name
end

local function canCastDebug(spell,unit)
	if spell == "" then return false end
	if unit == nil then unit = "target" end
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	
	if spellname == nil then print("spell is nil") end
	if jps.PlayerIsBlacklisted(unit) then print("blacklisted unit") end
	if not jps.UnitExists(unit) and not isBattleRez(spellname) then print("invalid unit") end -- isBattleRez need spellname
	
	local usable, nomana = IsUsableSpell(spell) -- usable, nomana = IsUsableSpell("spellName" or spellID)
	if not usable then print("spell is not usable") end
	if nomana then return print("failed mana test") end
	if (jps.cooldown(spellname) > 0) then print("cooldown not finished") end
	if not jps.IsSpellInRange(spell,unit) then print("spell is not inrange") end
	if jps[spellname] ~= nil and jps[spellname] == false then print("not spellname") end -- need spellname
	print("passes all tests")
end

function jps_Test()

	write("***************************")
	print("Stun:|cff0070dd ",jps.checkTimer("PlayerStun"))
	print("Interrupt:|cff0070dd ",jps.checkTimer("PlayerInterrupt"))
	print("Shield:|cff0070dd ",jps.checkTimer("ShieldTimer"))
	print("Aggro:|cff0070dd ",jps.FriendAggro("player"))
	print("LoseControl:|cff0070dd ",jps.LoseControl("player"))
	print("ttd: ",jps.TimeToDie("target"))
	print("Facing: ",jps.PlayerIsFacing("target",90))
	print("GCD: ",jps.GCD)
	print("Distance: ",jps.FriendNearby(12))
	write("***************************")

--	local CDtarget = jps.enemyCooldownWatch("target")
--	write("CDtarget: ",CDtarget)
	
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(1)
	print("POHTarget: ",POHTarget,"groupToHeal: ",groupToHeal,"groupHealth: ",groupHealth)
	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(100)
	write("CountInRange: ",CountInRange,"AvgHealthLoss: ", AvgHealthLoss)

--[[	
	local myTanks = { "player","focus","target" }
	myTanks[1] = "prout";
	write("1",unpack(myTanks)) -- "prout,focus,target"
	
	local myTanks = { "player","focus","target" }
	myTanks[#myTanks] = "prout";  
	write("2",unpack(myTanks)) -- player,focus,prout"
	
	local myTanks = { "player","focus","target" }
	myTanks[#myTanks+1] = "prout";  
	write("3",unpack(myTanks)) -- "player,focus,target,prout"
]]--

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

function jps_RaidTest()

	jps.LookupRaid ()
	jps.LookupEnemyDamager()
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
	print("rangedTarget: ",rangedTarget,"TargetCount: ",TargetCount)
	print("EnemyUnit: ",unpack(EnemyUnit))

end

-----------------------
-- FUNCTION MEMORY
-----------------------

