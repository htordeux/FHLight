local spells = jps.spells.priest
local UnitIsUnit = UnitIsUnit

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","DISCIPLINE", function()

----------------------------
-- LOWEST UNIT
----------------------------

	local CountInRange, AvgHealthRaid, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80) -- CountInRange return raid count unit below healpct -- FriendUnit return table with all raid unit in range
	local LowestUnit, LowestUnitPrev = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}
	local Tank,TankUnit = jps.findRaidTank() -- default "focus" "player"
	local TankTarget = Tank.."target"
	local TankThreat,_  = jps.findRaidTankThreat()

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local playerIsTarget = jps.PlayerIsTarget()
	local isPVP= UnitIsPVP("player")
	local raidCount = #FriendUnit
	local isInRaid = IsInRaid()

--	local friendInRange = 0
--	for i=1,#FriendUnit do
--		local unit = FriendUnit[i]
--		local maxRange = jps.distanceMax(unit)
--		if maxRange < 21 and jps.hp(unit) < 0.80 then
--			friendInRange = friendInRange + 1
--		end
--	end

----------------------
-- TARGET ENEMY
----------------------

	local rangedTarget  = "target"
	if PlayerCanDPS("target") then rangedTarget =  "target"
	elseif PlayerCanAttack(TankTarget) then rangedTarget = TankTarget
	elseif PlayerCanAttack("targettarget") then rangedTarget = "targettarget"
	elseif PlayerCanAttack("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and PlayerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end

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
