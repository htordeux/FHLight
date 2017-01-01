
local spells = jps.spells.priest
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","DISCIPLINE", function()

	local spell = nil
	local target = nil

----------------------------
-- LOWEST UNIT
----------------------------

	local CountInRange, AvgHealthRaid, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80) -- CountInRange return count raid unit below healpct -- FriendUnit return table with all raid unit in range
	local POHTarget, POHGroup, HealthGroup = jps.FindSubGroupHeal(0.80) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local LowestUnit, LowestUnitPrev = jps.LowestImportantUnit()

	local Tank,TankUnit = jps.findTankInRaid() -- default "focus" "player"
	local TankThreat = jps.findThreatInRaid() -- default "focus" "player"
	local TankTarget = TankThreat.."target"

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local ispvp = UnitIsPVP("player")
	local raidCount = #FriendUnit

----------------------
-- TARGET ENEMY
----------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canAttack(TankTarget) then rangedTarget = TankTarget
	elseif canAttack("targettarget") then rangedTarget = "targettarget"
	elseif canAttack("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end

	local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0
	local playerIsTargeted = jps.playerIsTargeted()

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	-- jps.unitForLeap includes jps.FriendAggro and jps.LoseControl
	local LeapFriend = nil
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.unitForLeap(unit) and jps.hpInc(unit) < 0.30 then 
			LeapFriend = unit
		break end
	end
	
	-- jps.unitForShield includes jps.FriendAggro
	local ShieldFriend = nil
	local ShieldFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldFriendHealth then
				ShieldFriend = unit
				ShieldFriendHealth = unitHP
			end
		end
	end

	-- DISPEL --
	
	local DispelFriendPvE = jps.DispelMagicTarget() -- {"Magic", "Poison", "Disease", "Curse"}
	local DispelFriendPvP = nil
	local DispelFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.DispelLoseControl(unit) then -- jps.DispelLoseControl includes jps.WarningDebuffs
			local unitHP = jps.hp(unit)
			if unitHP < DispelFriendHealth then
				DispelFriendPvP = unit
				DispelFriendHealth = unitHP
			end
		end
	end

	local DispelFriendRole = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(TankUnit) do
		local unit = TankUnit[i]
		if jps.canDispel(unit,"Magic") then -- jps.canDispel includes jps.WarningDebuffs
			DispelFriendRole = unit
		break end
	end
	
	local MendingFriend = nil
	local MendingFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.FriendAggro(unit) and not jps.buff(41635,unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingFriendHealth then
				MendingFriend = unit
				MendingFriendHealth = unitHP
			end
		end
	end
	
	local RenewFriend = nil
	local RenewFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		local unitHP = jps.hp(unit)
		if not jps.buff(139,unit) and jps.FriendAggro(unit) then
			if unitHP < RenewFriendHealth then
				RenewFriend = unit
				RenewFriendHealth = unitHP
			end
		end
	end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local SilenceEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if jps.IsSpellInRange(15487,unit) then
			if jps.ShouldKick(unit) then
				SilenceEnemyTarget = unit
			break end
		end
	end

	local FearEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if jps.canFear(unit) and not jps.LoseControl(unit) then
			FearEnemyTarget = unit
		break end
	end

	local DispelOffensiveEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if jps.DispelOffensive(unit) and jps.hp(LowestUnit) > 0.85 then
			DispelOffensiveEnemyTarget = unit
		break end
	end

------------------------
-- LOCAL TABLES
------------------------
	
	local parseDispel = {
		-- "Dispel" "Purifier" 527
		{ spells.purify, jps.canDispel("player","Magic") , "player" , "Dispel" },
		{ spells.purify, DispelFriendRole ~= nil , DispelFriendRole , "|cff1eff00DispelFriend_Role" },
		{ spells.purify, DispelFriendPvP ~= nil , DispelFriendPvP , "|cff1eff00DispelFriend_PvP" },
		{ spells.purify, DispelFriendPvE ~= nil , DispelFriendPvE , "|cff1eff00DispelFriend_PvE" },
	}

------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------



------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {
	
	-- DAMAGE --
	{ 123040,  true , rangedTarget , "mindbender" },
	-- "Pénitence"
	{ 47540, true , rangedTarget ,"|cFFFF0000Penance" },
	-- "Courroux de la lumiere"
	{ 207946, true , rangedTarget ,"|cFFFF0000Courroux" },
	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, true , rangedTarget, "|cFFFF0000Solace" },
	-- "Mot de l'ombre: Douleur" 589
	{ 204197, not jps.myDebuff(204213,rangedTarget) , rangedTarget , "|cFFFF0000Purge" },
	-- "Châtiment" 585
	{ 585, not jps.Moving , rangedTarget , "|cFFFF0000Chatiment" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end , "Disc Priest PvE", true,false)

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------
