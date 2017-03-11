local spells = jps.spells.paladin

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PALADIN","HOLY",function()

----------------------------
-- LOWEST UNIT
----------------------------

	local CountInRange, AvgHealthRaid, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80) -- CountInRange return raid count unit below healpct -- FriendUnit return table with all raid unit in range
	local LowestUnit, lowestUnitInc = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}
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

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local DispelFriend = jps.DispelMagicTarget() -- "Magic", "Poison", "Disease", "Curse"
	local DispelFriendRole = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(TankUnit) do
		local unit = TankUnit[i]
		if jps.canDispel(unit,"Magic") then -- jps.canDispel includes jps.WarningDebuffs
			DispelFriendRole = unit
		break end
	end
	
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
	
	-- "Cleanse"
	local parseDispel = {
		{ spells.cleanse, jps.canDispel("player","Poison") , "player" , "Dispel" },
		{ spells.cleanse, jps.canDispel("player","Disease") , "player" , "Dispel" },
		{ spells.cleanse, jps.canDispel("player","Magic") , "player" , "Dispel" },
		{ spells.cleanse, DispelFriendRole ~= nil , DispelFriendRole , "|cff1eff00DispelFriend_Role" },
		{ spells.cleanse, DispelFriendPvP ~= nil , DispelFriendPvP , "|cff1eff00DispelFriend_PvP" },
		{ spells.cleanse, DispelFriend ~= nil , DispelFriend , "|cff1eff00DispelFriend_PvE" },
	}
	
------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------


------------------------
-- SPELL TABLE ---------
------------------------
-- "Imprégnation de lumière" 54149
-- Les coups critiques que vous infligez avec Horion sacré réduisent le temps d’incantation de votre prochain sort Lumière sacrée de 1.5 s
-- ou augmentent les soins prodigués par le prochain Éclair lumineux de 50%.


local spellTable = {

	-- "Adaptation" 214027
	{ 214027, playerIsStun , "player" , "playerCC" },
	-- "Use bottom trinket"
	{"macro", isPVP and jps.hp("player") < 0.80 and jps.IncomingDamage("player") > jps.IncomingHeal("player") and not jps.buff(642) and not jps.buff(1022) , "/use 14" },
    -- "Healthstone"
    { "macro", jps.hp("player") < 0.60 and jps.useItem(5512) ,"/use item:5512" },
    
    -- "Light of the Martyr" 183998 -- when blessing of protection
    { spells.lightOfTheMartyr, jps.buff(1022) , LowestUnit },
    -- "Bouclier divin" 642 -- cd 5 min
    { spells.divineShield, jps.hp("player") < 0.30 and jps.IncomingDamage("player") > jps.IncomingHeal("player") , "player" },
    -- "Bénédiction de protection" 1022
    { spells.blessingOfProtection, jps.hp("player") < 0.60 and not jps.buff(642) , "player" },
    { spells.blessingOfProtection, jps.hp("mouseover") < 0.60 and canHeal("mouseover") , "mouseover" },
    { spells.blessingOfProtection, isPVP and jps.hp(LowestUnit) < 0.20 and lowestAggro , LowestUnit },
    -- "Vengeur sacré" 498
    { spells.divineProtection, jps.hp(Tank) < 0.80 and jps.IncomingDamage(Tank) > jps.IncomingHeal(Tank) , Tank },
	{ spells.divineProtection, jps.hp("player") < 0.80 and jps.IncomingDamage("player") > jps.IncomingHeal("player") , "player" },
     -- "Imposition des mains" 633 -- cd 10 min
    { spells.layOnHands, jps.hp("player") < 0.20 , "player" },
    -- "Guide de lumière" 53563
    { spells.beaconOfLight, not jps.buff(53563,Tank) , Tank },
    
    -- interrupts
	-- "Marteau de la justice" 853
	{ spells.hammerOfJustice, jps.Interrupts and jps.IsCasting(rangedTarget) , rangedTarget },
	{ spells.hammerOfJustice, jps.Interrupts and jps.IsCasting("focus") , "focus" },
	-- "Lumière aveuglante" 115750 --
	{ spells.blindingLight, jps.Interrupts and jps.hasTalent(3,3) and jps.IsCasting("focus") and CheckInteractDistance("focus",3) == true , "focus" },
    { spells.blindingLight, jps.Interrupts and jps.hasTalent(3,3) and jps.IsCasting(rangedTarget) and CheckInteractDistance(rangedTarget,3) == true , rangedTarget },
    -- "Arcane Torrent" 155145
    { 155145, jps.Interrupts and jps.IsCasting(rangedTarget) and CheckInteractDistance(rangedTarget,3) == true , rangedTarget },
    
    -- "Don de foi" 223306 -- Imprègne de foi une cible alliée pendant 5 sec et lui rend (600% of Spell power) points de vie à la fin de l’effet.
    { spells.bestowFaith, jps.hp("player") < 0.80 and not jps.buff(223306) , "player" },
    { spells.bestowFaith, jps.hp(LowestUnit) < 0.80 and not jps.buff(223306,LowestUnit) , LowestUnit },
    { spells.bestowFaith, jps.hp(Tank) < 0.80 and not jps.buff(223306,Tank) , Tank },
    -- "Horion sacré" 20473
	{ spells.holyShock, jps.hp(LowestUnit) < 0.80 , LowestUnit },
	{ spells.holyShock, true , rangedTarget },
   	-- "Eclair lumineux" 19750
	{ spells.flashOfLight, not jps.Moving and jps.hp(LowestUnit) < 0.60 and jps.buff(54149) , LowestUnit },
	{ spells,flashOfLight, isPVP and not jps.Moving and jps.hp("player") < 0.80 , "player" },
	-- "Lumière sacrée" 82326
	{ spells.holyLight, not jps.Moving and jps.hp(LowestUnit) < 0.80 and jps.buff(54149) , LowestUnit },

	{ "nested", jps.UseCDs , parseDispel },
	
	{ "nested", jps.Defensive , {
		-- "Jugement" 20271 -- duration 8 sec
		{ spells.judgment, jps.hp(LowestUnit) > 0.60 , rangedTarget },
		-- "Frappe du croisé" 35395
		{ spells.crusaderStrike, jps.hp(LowestUnit) > 0.60 , rangedTarget },
		-- "Horion sacré" 20473
		{ spells.holyShock, jps.hp(LowestUnit) > 0.80 , rangedTarget },
		-- 26573
		{ spells.consecration, CheckInteractDistance(rangedTarget,2) == true , rangedTarget },
		--"Aura Mastery" 31821
		{ spells.auraMastery, isPVP and AvgHealthRaid < 0.50 },
	}},

    -- "Courroux vengeur" 31842 -- gives buff 31842
    { spells.avengingWrath, CountInRange > 3 and AvgHealthRaid < 0.80 , LowestUnit },
    { spells.avengingWrath, not isPVP and jps.hp(Tank) < 0.60 and jps.hp(LowestUnit) < 0.60 and not UnitIsUnit(Tank,LowestUnit), LowestUnit },
    { spells.avengingWrath, jps.hp("player") < 0.80 and jps.IncomingDamage("player") > jps.IncomingHeal("player") , "player" },
    { spells.avengingWrath, jps.hp(rangedTarget) < 0.30 and CheckInteractDistance(rangedTarget,3) == true , "player" },
    -- "Vengeur sacré" 105809 -- Augmente votre hâte de 30% et les soins de votre Horion sacré de 30% pendant 20 sec.
	{ spells.holyAvenger, jps.hp(Tank) < 0.40 , Tank },
	{ spells,holyAvenger, isPVP and jps.hp("player") < 0.50 , "player" },
	
	
	-- "Délivrance de Tyr" 200652 -- buff 200654 -- Soins reçus de Lumière sacrée et Éclair lumineux augmentés de 20%. 
    { spells.tyrsDeliverance, jps.hp(LowestUnit) < 0.60 , LowestUnit },
	
	-- "Lumière du martyr" 183998 -- Vous sacrifiez une partie de vos points de vie pour en rendre instantanément à un allié
	-- Vous subissez des dégâts équivalant à 50% des soins effectués.
	--{ spells.lightOfTheMartyr, jps.hp(Tank) < 0.40 and not UnitIsUnit("player",Tank) and jps.hp("player") > 0.80 , Tank }
	
	-- "Lumière de l’aube" 85222
    -- rend de la vie à un maximum de 5 alliés blessés se trouvant dans un cône frontal de 15 mètres
    { spells.lightOfDawn, CountInRange > 3 and AvgHealthRaid < 0.80 and jps.distanceMax(FriendLowest) < 20 , FriendLowest },

	-- "Eclair lumineux" 19750 -- 
	{ spells.flashOfLight, not jps.Moving and jps.hp(LowestUnit) < 0.60 , LowestUnit },
	-- "Lumière sacrée" 82326 -- jps.buff(54149)
	{ spells.holyLight, not jps.Moving and jps.hp(LowestUnit) < 0.80 , LowestUnit },


}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Paladin Holy")

--------------------------------------------------------------------------------------------------------------
------------------------------------------------ ROTATION OOC ------------------------------------------------
--------------------------------------------------------------------------------------------------------------

jps.registerRotation("PALADIN","HOLY",function()

	local LowestUnit = jps.LowestImportantUnit()
	local areaType = IsInInstance()
	local isOutdoors = IsOutdoors()
	local isPVP = UnitIsPVP("player")

	if IsMounted() then return end
	
	local spellTable = {
	
	-- "Holy Light" 82326
	{ spells.holyLight, jps.hp(LowestUnit) < 0.60 , LowestUnit },
	-- "Flash of Light" 19750
	{ spells.flashOfLight, jps.hp(LowestUnit) < 0.80 , LowestUnit },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Paladin Holy",false,true)