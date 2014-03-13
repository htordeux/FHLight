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
local canDPS = jps.canDPS
function jps_Test()

	jps.LookupEnemy()

--	for i=1,MAX_RAID_MEMBERS do
--		if GetRaidRosterInfo(i) == nil then break end
--		local group = select(3,GetRaidRosterInfo(i)) -- if index is out of bounds, the function returns nil
--		local name = select(1,GetRaidRosterInfo(i))
--		print("name: ",name,"group: ",group)
--	end

	print("Aggro:",jps.checkTimer("Player_Stun"),"Interrupt:",jps.checkTimer("Player_Interrupt"))
	print("Shield:",jps.checkTimer("Shield"),jps.checkTimer("ShieldTimer"))
	print("Aggro:",jps.FriendAggro("player"),"Dmg:",jps.checkTimer("Player_Aggro"))
	print("LoseControl:",jps.LoseControl("player"))
	
--	local masteryValue = math.ceil(GetMastery())/100
--	local bonusHealing = math.ceil(GetSpellBonusHealing())
--	local minCrit = math.ceil(GetSpellCritChance(2))/100 -- 2 - Holy
--	print("priestFlash",priest.AvgAmountFlashHeal,"/",(1+masteryValue)*(1+minCrit)*(14664+(1.314*bonusHealing)))
--	print("priestGreat",priest.AvgAmountGreatHeal,"/",(1+masteryValue)*(1+minCrit)*(24430+(2.219*bonusHealing)))

end

function jps_RaidTest()

	jps.LookupRaid ()

	local target, dupe, dupecount = jps.LowestTarget()
	print("target: ",target,"count", dupecount,"Table: ", unpack(dupe))

end

-----------------------
-- FUNCTION MEMORY
-----------------------