
local spells = jps.spells.paladin
local spells = jps.spells.paladin
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit


jps.registerRotation("PALADIN","HOLY",function()

	local spell = nil
	local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.80)
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.80) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local LowestImportantUnit = jps.LowestImportantUnit()

	local Tank,TankUnit = jps.findTankInRaid() -- default "focus" "player"
	local TankTarget = Tank.."target"
	local TankThreat = jps.findThreatInRaid() -- default "focus" "player"
	
	----------------------
-- TARGET ENEMY
----------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS(TankTarget) then rangedTarget = TankTarget
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canAttack("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0



local spellTable = {

    -- "Marteau de la justice" 853
    { spells.hammerOfJustice, jps.ShouldKick(rangedTarget) },
    { spells.hammerOfJustice, jps.IsCasting(rangedTarget) },
    
    -- "Bouclier divin" 642 -- cd 5 min
    { spells.divineShield, jps.hp(LowestImportantUnit) < 0.40 , LowestImportantUnit },

	-- "Frappe du croisé" 35395 -- Génère 1 charge de puissance sacrée
    { spells.crusaderStrike  },
	-- "Jugement" 20271 -- duration 8 sec
    { spells.judgment  },
   	-- "Horion sacré" 20473
	{ 20473, jps.hp(LowestImportantUnit) > 0.80 , rangedTarget },
	{ 20473, jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit },
	-- 26573
	{ spells.consecration },


    -- "Lumière de l’aube" 85222
    -- rend de la vie à un maximum de 5 alliés blessés se trouvant dans un cône frontal de 15 mètres
    { spells.paladin.lightOfDawn, CountInRange > 3 , LowestImportantUnit },
    -- "Délivrance de Tyr" 200652
    { spells.tyrsDeliverance },
    -- "Guide de lumière" 53563
    { 53563, not jps.buff(Tank,53563) , Tank },
    { 53563, not jps.buff(TankThreat,53563) , TankThreat },
    -- "Courroux vengeur" 31842 -- gives buff 31884
    { 31842, CountInRange > 3 and AvgHealthLoss < 0.80 , LowestImportantUnit },
    -- "Don de foi" 223306
    { 223306, jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit },

	-- "Eclair lumineux" 19750
	{ 19750, jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit },
	-- "Lumière sacrée" 82326
	{ 82326, jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit },
	




}


	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Paladin Holy")
