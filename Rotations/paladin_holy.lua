
local spells = jps.spells.paladin
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

jps.registerRotation("PALADIN","HOLY",function()

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
	
	-- Config FOCUS with MOUSEOVER
	if not jps.UnitExists("focus") and canAttack("mouseover") then
		-- set focus an enemy targeting you
		if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
			jps.Macro("/focus mouseover") --print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
		-- set focus an enemy in combat
		elseif canAttack("mouseover") and not UnitIsUnit("target","mouseover") then
			jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS")
		end
	end
	
	if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
		jps.Macro("/clearfocus")
	elseif jps.UnitExists("focus") and not canDPS("focus") then
		jps.Macro("/clearfocus")
	end

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

	-- "Chacun pour soi" 59752
	{ 59752, playerIsStun , "player" , "playerCC" },
    
    -- "Bouclier divin" 642 -- cd 5 min
    { spells.divineShield, jps.hp(Tank) < 0.40 , Tank },
    { spells.divineShield, jps.hp(LowestUnit) < 0.40 , LowestUnit },
    -- "Bénédiction de protection" 1022
    { spells.blessingOfProtection, jps.hp("player") < 0.60 and not jps.buff(642) , "player" },
    { spells.blessingOfProtection, jps.hp("mouseover") < 0.60 and canHeal("mouseover") , "mouseover" },
    -- "Vengeur sacré" 498
    { spells.divineProtection, jps.hp(Tank) < 0.80 and jps.IncomingDamage(Tank) > jps.IncomingHeal(Tank) , Tank },
	{ spells.divineProtection, jps.hp("player") < 0.80 and jps.IncomingDamage("player") > jps.IncomingHeal("player") , "player" },
     -- "Imposition des mains" 633 -- cd 10 min
    { spells.layOnHands, jps.hp() < 0.20 , "player" },
    -- "Guide de lumière" 53563
    { spells.beaconOfLight, not jps.buff(53563,Tank) , Tank },
    
    -- interrupts
	-- "Marteau de la justice" 853
	{ spells.hammerOfJustice, jps.Interrupts and jps.IsCasting(rangedTarget) , rangedTarget },
	{ spells.hammerOfJustice, jps.Interrupts and jps.IsCasting("focus") , "focus" },
	-- "Lumière aveuglante" 115750 --
	{ spells.blindingLight, jps.Interrupts and jps.hasTalent(3,3) and jps.IsCasting("focus") , "focus" },
    { spells.blindingLight, jps.Interrupts and jps.hasTalent(3,3) and jps.IsCasting(rangedTarget) , rangedTarget },
    
    -- "Don de foi" 223306 -- Imprègne de foi une cible alliée pendant 5 sec et lui rend (600% of Spell power) points de vie à la fin de l’effet.
    { spells.bestowFaith, jps.hp("player") < 0.80 and not jps.buff(223306) , "player" },
    { spells.bestowFaith, jps.hp(LowestUnit) < 0.80 and not jps.buff(223306,LowestUnit) , LowestUnit },
    { spells.bestowFaith, jps.hp(Tank) < 0.80 and not jps.buff(223306,Tank) , Tank },
    -- "Horion sacré" 20473
	{ spells.holyShock, jps.hp(LowestUnit) < 0.80 , LowestUnit },
   	-- "Eclair lumineux" 19750
	{ spells.flashOfLight, not jps.Moving and jps.hp(LowestUnit) < 0.60 and jps.buff(54149) , LowestUnit },
	-- "Lumière sacrée" 82326
	{ spells.holyLight, not jps.Moving and jps.hp(LowestUnit) < 0.80 and jps.buff(54149) , LowestUnit },

	{ "nested", jps.Defensive , {
		-- "Jugement" 20271 -- duration 8 sec
		{ spells.judgment, jps.hp(LowestUnit) > 0.60 , rangedTarget },
		-- "Frappe du croisé" 35395
		{ spells.crusaderStrike, jps.hp(LowestUnit) > 0.60 , rangedTarget },
		-- "Horion sacré" 20473
		{ spells.holyShock, jps.hp(LowestUnit) > 0.80 , rangedTarget },
		-- 26573
		{ spells.consecration, CheckInteractDistance(rangedTarget,2) == true , rangedTarget },
	}},

    -- "Courroux vengeur" 31842 -- gives buff 31842
    { spells.avengingWrath, CountInRange > 3 and AvgHealthRaid < 0.80 , LowestUnit },
    { spells.avengingWrath, jps.hp(Tank) < 0.60 and jps.hp(LowestUnit) < 0.60 and not UnitIsUnit(Tank,LowestUnit), LowestUnit },
    -- "Vengeur sacré" 105809 -- Augmente votre hâte de 30% et les soins de votre Horion sacré de 30% pendant 20 sec.
	{ spells.holyAvenger, jps.hp(Tank) < 0.40 , Tank }, 
	
	
	-- "Délivrance de Tyr" 200652 -- buff 200654 -- Soins reçus de Lumière sacrée et Éclair lumineux augmentés de 20%. 
    { spells.tyrsDeliverance, jps.hp(LowestUnit) < 0.60 , LowestUnit },
	
	-- "Lumière du martyr" 183998 -- Vous sacrifiez une partie de vos points de vie pour en rendre instantanément à un allié
	-- Vous subissez des dégâts équivalant à 50% des soins effectués.
	--{ spells.lightOfTheMartyr, jps.hp(Tank) < 0.40 and not UnitIsUnit("player",Tank) and jps.hp("player") > 0.80 , Tank }
	
	-- "Lumière de l’aube" 85222
    -- rend de la vie à un maximum de 5 alliés blessés se trouvant dans un cône frontal de 15 mètres
    { spells.lightOfDawn, POHCountInRange > 3 , LowestUnit },

	-- "Eclair lumineux" 19750 -- 
	{ spells.flashOfLight, not jps.Moving and jps.hp(LowestUnit) < 0.60 , LowestUnit },
	-- "Lumière sacrée" 82326 -- jps.buff(54149)
	{ spells.holyLight, not jps.Moving and jps.hp(LowestUnit) < 0.80 , LowestUnit },


}


	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Paladin Holy")
