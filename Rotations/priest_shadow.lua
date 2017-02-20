local spells = jps.spells.priest

local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit

local NamePlateCount = function()
	return jps.NamePlateCount()
end
local fnCountInRange = function(pct)
	local Count, _, _ = jps.CountInRaidStatus(pct)
	return Count
end
local fnAvgHealthRaid = function()
	local _, AvgHealth, _ = jps.CountInRaidStatus()
	return AvgHealth
end
local IsRecast = function(spell,unit)
	return jps.isRecast(spell,unit)
end
local DistanceMax = function(unit)
	return jps.distanceMax(unit)
end

local playerInsanity = function()
	return jps.insanity()
end

local playerMoving = function()
	if select(1,GetUnitSpeed("player")) > 0 then return true end
	return false
end

local playerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local playerCanDPS = function(unit)
	return jps.canDPS(unit)
end

local playerHasBuff = function(spell)
	return jps.buff(spell,"player")
end

local playerBuffStacks = function(spell)
	return jps.buffStacks(spell)
end

local playerHasTalent = function(row,talent)
	return jps.hasTalent(row,talent)
end

local playerCanDispel = function(unit,dispel)
	return jps.canDispel(unit,dispel)
end

local DispelDiseaseTarget = function()
	return jps.DispelDiseaseTarget()
end

------------------------------------------------

local targetDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"target")
end
local targetDebuff = function(spell)
	return jps.myDebuff(spell,"target")
end

------------------------------------------------

local focusDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"focus")
end
local focusDebuff = function(spell)
	return jps.myDebuff(spell,"focus")
end

------------------------------------------------

local mouseoverDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"mouseover")
end
local mouseoverDebuff = function(spell)
	return jps.myDebuff(spell,"mouseover")
end

------------------------------------------------

local TargetMouseover = function()
	-- Config FOCUS with MOUSEOVER
	if not jps.UnitExists("focus") and (playerCanAttack("mouseover") or (playerCanDPS("mouseover") and jps.Defensive)) then
		if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
			jps.Macro("/focus mouseover") --print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
		elseif not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.shadowWordPain,"mouseover") then 
			jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
		elseif not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.vampiricTouch,"mouseover") then
			jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
		elseif not UnitIsUnit("target","mouseover") then
			jps.Macro("/focus mouseover")
		end
	end
	if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
		jps.Macro("/clearfocus")
	elseif jps.UnitExists("focus") and not playerCanDPS("focus") then
		jps.Macro("/clearfocus")
	end
end

local FocusNamePlate = function()
	local NamePlateTable = jps.NamePlate()
	local NamePlateTarget = nil
	for unit,_ in pairs(NamePlateTable) do
		if playerCanAttack(unit) and not jps.myDebuff(spells.shadowWordPain,unit) and not jps.myDebuff(spells.vampiricTouch,unit) then
			NamePlateTarget = unit
		elseif playerCanDPS("mouseover") and jps.Defensive and not jps.myDebuff(spells.shadowWordPain,unit) and not jps.myDebuff(spells.vampiricTouch,unit) then
			NamePlateTarget = unit
		break end
	end
	if NamePlateTarget ~= nil and UnitIsUnit("mouseover",NamePlateTarget) then
		if jps.UnitExists("focus") and jps.myDebuffDuration(spells.vampiricTouch,"focus") > 12 and jps.myDebuffDuration(spells.shadowWordPain,"focus") > 9 then
			jps.Macro("/focus mouseover")
		elseif not jps.UnitExists("focus") then
			jps.Macro("/focus mouseover")
		end
	end
end

local Enemy = { "target", "focus" ,"mouseover" }
local VoidBoltTarget = function()
	local VoidBoltTarget = nil
	local VoidBoltTargetDuration = 24
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if jps.myDebuff(spells.shadowWordPain,unit) and jps.myDebuff(spells.vampiricTouch,unit) then
			local shadowWordPainDuration = jps.myDebuffDuration(spells.shadowWordPain,unit)
			local vampiricTouchDuration = jps.myDebuffDuration(spells.vampiricTouch,unit)
			local duration = math.min(shadowWordPainDuration,vampiricTouchDuration)
			if duration < VoidBoltTargetDuration then
				VoidBoltTargetDuration = shadowWordPainDuration
				VoidBoltTarget = unit
			end
		end
	end
	return VoidBoltTarget
end


------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------
--jps.Defensive for "Levitate"
--jps.Defensive for DPS any mouseover
--jps.Interrupts for "Silence" et "Mind Bomb" et "Psychic Scream"
--jps.UseCDs for "Purify Disease"
--jps.MultiTarget for not stopcasting

jps.registerRotation("PRIEST","SHADOW",function()

TargetMouseover()

local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local rangedTarget  = "target"
if playerCanDPS("target") then rangedTarget = "target"
elseif playerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif playerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif playerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if playerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0
local voidBoltTarget = VoidBoltTarget()

local spellTable = {

	-- "Dispersion" 47585
	{spells.dispersion, jps.hp("player") < 0.40 },
	{spells.fade, not UnitIsPVP("player") and jps.playerIsTargeted() },
	-- "Power Word: Shield" 17
	{spells.powerWordShield, playerMoving() and playerHasTalent(2,2) and not playerHasBuff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, jps.hp("player") < 0.80 and not playerHasBuff(194249) and not playerHasBuff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, jps.hp("mouseover") < 0.50 and not jps.buff(spells.powerWordShield,"mouseover") , "mouseover" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.60 and jps.useItem(5512) , "/use item:5512" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, jps.hp("player") < 0.70 , "player" },
	-- "Etreinte vampirique" buff 15286 -- pendant 15 sec, vous permet de rendre à un allié proche, un montant de points de vie égal à 40% des dégâts d’Ombre que vous infligez avec des sorts à cible unique
	{spells.vampiricEmbrace, playerHasBuff(194249) and not IsInRaid() and jps.hp("player") < 0.60 },
	{spells.vampiricEmbrace, playerHasBuff(194249) and fnCountInRange(0.80) > 2 and fnAvgHealthRaid() < 0.80 },

	-- "Purify Disease" 213634
	{spells.purifyDisease, playerCanDispel("mouseover","Disease") , "mouseover" },
	{spells.purifyDisease, playerCanDispel("player","Disease") , "player" },
	{spells.purifyDisease, playerCanDispel(Tank,"Disease") , Tank },
	{spells.purifyDisease, DispelDiseaseTarget() ~= nil , DispelDiseaseTarget },

	{"nested", jps.Interrupts , {
		-- "Silence" 15487 -- debuff same ID
		{spells.silence,  not jps.debuff(226943,"target") and jps.IsCasting("target") and DistanceMax("target") < 30 , "target" },
		{spells.silence, not jps.debuff(226943,"focus") and jps.IsCasting("focus") and DistanceMax("focus") < 30 , "focus" },
		-- "Mind Bomb" 205369 -- 30 yd range -- debuff "Explosion mentale" 226943
		{spells.mindBomb, jps.IsCasting("target") and DistanceMax("target") < 30 , "target" },
		{spells.mindBomb, jps.IsCasting("focus") and DistanceMax("focus") < 30 , "focus" },
		{spells.mindBomb, jps.MultiTarget , "target" },
		-- "Levitate" 1706
		{ spells.levitate, jps.Defensive and IsFalling() and not playerHasBuff(111759) , "player" },
		{ spells.levitate, jps.Defensive and IsSwimming() and not playerHasBuff(111759) , "player" },
	}},

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	-- { "macro", jps.useTrinket(1) , "/use 14"},

    -- "Déferlante d’ombre" 205385
    {spells.shadowCrash, playerHasTalent(7,2) },

   	{spells.voidEruption, playerCanDPS("target") and not playerHasBuff(194249) and playerInsanity() > 65 and playerHasTalent(7,1) },
	{spells.voidEruption, playerCanDPS("target") and not playerHasBuff(194249) and playerInsanity() == 100 },

	{spells.powerInfusion, playerBuffStacks(194249) > 9 and playerInsanity() > 65 },
	{spells.shadowfiend, playerBuffStacks(194249) > 9 , "target" },
	{spells.mindbender, playerBuffStacks(194249) > 9 , "target" },
	
	{"nested", playerHasBuff(194249) , {
		--{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, voidBoltTarget ~= nil , voidBoltTarget },
--		{spells.voidEruption, targetDebuffDuration(spells.shadowWordPain) > 0 and targetDebuffDuration(spells.shadowWordPain) < focusDebuffDuration(spells.shadowWordPain) and targetDebuffDuration(spells.shadowWordPain) < mouseoverDebuffDuration(spells.shadowWordPain) , "target" },
--		{spells.voidEruption, targetDebuffDuration(spells.vampiricTouch) > 0 and targetDebuffDuration(spells.vampiricTouch) < focusDebuffDuration(spells.vampiricTouch) and targetDebuffDuration(spells.vampiricTouch) < mouseoverDebuffDuration(spells.vampiricTouch) , "target" },
--		{spells.voidEruption, focusDebuffDuration(spells.shadowWordPain) >  0 and focusDebuffDuration(spells.shadowWordPain) < mouseoverDebuffDuration(spells.shadowWordPain) , "focus" },
--		{spells.voidEruption, focusDebuffDuration(spells.vampiricTouch) >  0 and focusDebuffDuration(spells.vampiricTouch) < mouseoverDebuffDuration(spells.vampiricTouch) , "focus" },
--		{spells.voidEruption, mouseoverDebuffDuration(spells.shadowWordPain) > 0 , "mouseover" },
--		{spells.voidEruption, mouseoverDebuffDuration(spells.vampiricTouch) > 0 , "mouseover" },
		{spells.voidTorrent , not playerMoving() },
	}},

	{spells.shadowWordDeath, jps.hp("target") < 0.20 , "target" },
	{spells.shadowWordDeath, playerHasTalent(4,2) and jps.hp("target") < 0.35 , "target" },
	{spells.shadowWordDeath, jps.hp("focus") < 0.20 , "focus" },
	{spells.shadowWordDeath, playerHasTalent(4,2) and jps.hp("focus") < 0.35 , "focus" },
	
	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not playerMoving() , "target"  },

	{spells.vampiricTouch, not playerMoving() and targetDebuffDuration(spells.vampiricTouch) < 4  and not IsRecast(spells.vampiricTouch,"target") , "target"  },
	{spells.shadowWordPain, targetDebuffDuration(spells.shadowWordPain) < 4 and not IsRecast(spells.shadowWordPain,"target") , "target" },
	{spells.vampiricTouch, not playerMoving() and focusDebuffDuration(spells.vampiricTouch) < 4 and not IsRecast(spells.vampiricTouch,"focus") , "focus"  },
	{spells.shadowWordPain, focusDebuffDuration(spells.shadowWordPain) < 4 and not IsRecast(spells.shadowWordPain,"focus") , "focus" },
	{spells.vampiricTouch, playerCanAttack("mouseover") and not playerMoving() and mouseoverDebuffDuration(spells.vampiricTouch) < 4 and not IsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, playerCanAttack("mouseover") and mouseoverDebuffDuration(spells.shadowWordPain) < 4 and not IsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },
	{spells.vampiricTouch, jps.Defensive and not playerMoving() and mouseoverDebuffDuration(spells.vampiricTouch) < 4 and not IsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, jps.Defensive and mouseoverDebuffDuration(spells.shadowWordPain) < 4 and not IsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },

	-- Mind Flay If the target is afflicted with Shadow Word: Pain you will also deal splash damage to nearby targets.
    {spells.mindFlay , not playerMoving() , "target"  },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Test Shadow Priest")

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

----------------------
-- TARGET ENEMY
----------------------

-- Config FOCUS with MOUSEOVER
TargetMouseover()
FocusNamePlate()

local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
if playerCanDPS("target") then rangedTarget = "target"
elseif playerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif playerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif playerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if playerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

local isTargetElite = false
if jps.myDebuffDuration(spells.vampiricTouch,"target") > 4 and jps.myDebuffDuration(spells.shadowWordPain,"target") > 4 then
	if jps.targetIsBoss("target") then isTargetElite = true
	elseif jps.hp("target") > 0.50 then isTargetElite = true
	elseif string.find(GetUnitName("target"),"Mannequin") ~= nil then isTargetElite = true
	elseif NamePlateCount() > 3 then isTargetElite = true
	end
end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

if playerCanDPS("focus") then EnemyUnit[#EnemyUnit+1] = "focus" end
if playerCanAttack("mouseover") then EnemyUnit[#EnemyUnit+1] = "mouseover" end

local fnPainEnemyTarget = function(unit)
	if playerCanDPS(unit) and not jps.myDebuff(spells.shadowWordPain,unit) and not IsRecast(spells.shadowWordPain,unit) then
		return true end
	return false
end

local fnVampEnemyTarget = function(unit)
	if jps.Moving then return false end
	if playerCanDPS(unit) and not jps.myDebuff(spells.vampiricTouch,unit) and not IsRecast(spells.vampiricTouch,unit) then
		return true end
	return false
end

local DeathEnemyTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.hasTalent(4,2) and  jps.hp(unit) < 0.35 then
		DeathEnemyTarget = unit
	elseif jps.hp(unit) < 0.20 then
		DeathEnemyTarget = unit
	break end
end

local PainEnemyTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if fnPainEnemyTarget(unit) then
		PainEnemyTarget = unit
	break end
end

local VampEnemyTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if fnVampEnemyTarget(unit) then
		VampEnemyTarget = unit
	break end
end

local DispelOffensiveTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.DispelOffensive(unit) then
		DispelOffensiveTarget = unit
	break end
end

-----------------------------
-- SPELLTABLE
-----------------------------
-- if jps.debuffDuration(114404,"target") > 18 and jps.UnitExists("target") then MoveBackwardStart() end
-- if jps.debuffDuration(114404,"target") < 18 and jps.debuff(114404,"target") and jps.UnitExists("target") then MoveBackwardStop() end

-- "Dernier souffle d’Anund" buff 215210 (Brassards Legendaire) -- 15 secondes restantes
-- Chaque fois que Mot de l’ombre : Douleur et Toucher vampirique infligent des dégâts
-- les dégâts de votre prochain Éclair de Vide sont augmentés de 2%, ce effet se cumulant jusqu’à 50 fois.

if jps.buff(47585,"player") then return end

local spellTable = {

	-- "Dispersion" 47585
	{spells.dispersion, jps.hp("player") < 0.40 },
	{spells.fade, not UnitIsPVP("player") and jps.playerIsTargeted() },
	-- "Power Word: Shield" 17
	{spells.powerWordShield, jps.Moving and jps.hasTalent(2,2) and not jps.buff(spells.powerWordShield,"player") , "player" },
	{spells.powerWordShield, jps.hp("player") < 0.80 and not jps.buff(194249) and not jps.buff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, jps.hp("mouseover") < 0.50 and not jps.buff(spells.powerWordShield,"mouseover") , "mouseover" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.60 and jps.useItem(5512) , "/use item:5512" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, jps.hp("player") < 0.70 , "player" },
	-- "Etreinte vampirique" buff 15286 -- pendant 15 sec, vous permet de rendre à un allié proche, un montant de points de vie égal à 40% des dégâts d’Ombre que vous infligez avec des sorts à cible unique
	{spells.vampiricEmbrace, jps.buff(194249) and not IsInRaid() and jps.hp("player") < 0.60 },
	{spells.vampiricEmbrace, jps.buff(194249) and fnCountInRange(0.80) > 2 and fnAvgHealthRaid() < 0.80 },

	-- "Purify Disease" 213634
	{spells.purifyDisease, playerCanDispel("mouseover","Disease") , "mouseover" },
	{spells.purifyDisease, playerCanDispel("player","Disease") , "player" },
	{spells.purifyDisease, playerCanDispel(Tank,"Disease") , Tank },
	{spells.purifyDisease, DispelDiseaseTarget() ~= nil , DispelDiseaseTarget },

	{"nested", jps.Interrupts , {
		-- "Silence" 15487 -- debuff same ID
		{spells.silence,  not jps.debuff(226943,"target") and jps.IsCasting("target") and DistanceMax("target") < 30 , "target" },
		{spells.silence, not jps.debuff(226943,"focus") and jps.IsCasting("focus") and DistanceMax("focus") < 30 , "focus" },
		-- "Mind Bomb" 205369 -- 30 yd range -- debuff "Explosion mentale" 226943
		{spells.mindBomb, jps.IsCasting("target") and DistanceMax("target") < 30 , "target" },
		{spells.mindBomb, jps.IsCasting("focus") and DistanceMax("focus") < 30 , "focus" },
		{spells.mindBomb, jps.MultiTarget , "target" },
		-- "Levitate" 1706
		{ spells.levitate, jps.Defensive and IsFalling() and not playerHasBuff(111759) , "player" },
		{ spells.levitate, jps.Defensive and IsSwimming() and not playerHasBuff(111759) , "player" },
	}},

	-- "Guérison de l’ombre" 186263 -- debuff "Shadow Mend" 187464 10 sec
	{spells.shadowMend, not jps.Moving and not jps.buff(194249) and jps.hp("player") < 0.80 and not jps.buff(15286) and jps.castEverySeconds(186263,4) , "player" },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", UnitIsPVP("player") and DispelOffensiveTarget ~= nil , {
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and DispelOffensiveTarget ~= nil  , DispelOffensiveTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },
	}},

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	-- { "macro", jps.useTrinket(1) , "/use 14"},

    -- "Déferlante d’ombre" 205385
    {spells.shadowCrash, jps.hasTalent(7,2) },
    
   	{spells.voidEruption, playerCanDPS("target") and not jps.buff(194249) and jps.insanity() > 65 and jps.hasTalent(7,1) and isTargetElite  , rangedTarget },
	{spells.voidEruption, playerCanDPS("target") and not jps.buff(194249) and jps.insanity() == 100 and isTargetElite , rangedTarget },
    
   	{spells.shadowWordDeath, jps.spellCharges(spells.shadowWordDeath) == 2 and jps.insanity() < 100 , rangedTarget },
	{spells.powerInfusion, jps.buffStacks(194249) > 9 and jps.insanity() > 65 and isTargetElite },
	{spells.shadowfiend, jps.buffStacks(194249) > 9 },
	{spells.mindbender,  jps.buffStacks(194249) > 9 },
	
	{"nested", jps.buff(194249) , {
		--{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, voidBoltTarget ~= nil , voidBoltTarget },
		{spells.voidTorrent , not jps.Moving },

    	{spells.shadowWordDeath, jps.insanity() < 71 , "target" },
		{spells.shadowWordDeath, jps.insanity() < 71 and DeathEnemyTarget ~= nil , DeathEnemyTarget },

		-- Low Insanity coming up (Shadow Word: Death , Void Bolt , Mind Blast , AND Void Torrent are all on cooldown and you are in danger of reaching 0 Insanity).
		--{spells.dispersion, jps.hasTalent(6,3) and jps.insanity() > 21 and jps.insanity() < 71 and jps.cooldown(spells.mindbender) > 51 , "player" },
	}},

	-- "Mot de l’ombre : Mort" 199911
	{spells.shadowWordDeath, not jps.buff(194249) , "target" },
	{spells.shadowWordDeath, not jps.buff(194249) and DeathEnemyTarget ~= nil , DeathEnemyTarget },
	
	-- Mind Flay If the target is afflicted with Shadow Word: Pain you will also deal splash damage to nearby targets.
	{spells.mindFlay, jps.MultiTarget and not jps.Moving and jps.myDebuff(spells.shadowWordPain,"target") , "target" , "mindFlay_MultiTarget" },

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not jps.Moving , "target"  },
	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,"target") < 4  and not IsRecast(spells.vampiricTouch,"target") , "target"  },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,"target") < 4 and not IsRecast(spells.shadowWordPain,"target") , "target" },
	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,"focus") < 4 and not IsRecast(spells.vampiricTouch,"focus") , "focus"  },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,"focus") < 4 and not IsRecast(spells.shadowWordPain,"focus") , "focus" },
	{spells.vampiricTouch, playerCanAttack("mouseover") and not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,"mouseover") < 4 and not IsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, playerCanAttack("mouseover") and jps.myDebuffDuration(spells.shadowWordPain,"mouseover") < 4 and not IsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },
	{spells.vampiricTouch, jps.Defensive and not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,"mouseover") < 4 and not IsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, jps.Defensive and jps.myDebuffDuration(spells.shadowWordPain,"mouseover") < 4 and not IsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },

    {spells.mindFlay , not jps.Moving , "target"  },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default Shadow Priest" )

--[[

#showtooltip Mot de l’ombre : Douleur
/cast [@mouseover,exists,nodead,harm][@target] Mot de l’ombre : Douleur

]]

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerParseRotation("PRIEST","SHADOW", {

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not jps.Moving },
	{spells.mindSear, not jps.Moving and jps.MultiTarget },
	{spells.mindFlay},
}

,"Parse Shadow Priest")

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

	local spell = nil
	local target = nil
	local Shield = jps.spells.priest.powerWordShield
	
	if IsMounted() then return end
	
	local spellTable = {
	
	-- "Shield" 17 "Body and Soul" 64129 "Corps et âme" -- Vitesse de déplacement augmentée de 40% -- buff 65081
	{ spells.powerWordShield, jps.Moving and not jps.buff(17,"player") and jps.hasTalent(2,2) , "player" , "Shield_BodySoul" },
	{ "macro", not jps.buff(65081) and jps.Moving and jps.buff(17) and jps.hasTalent(2,2) , "/cancelaura "..Shield },

	-- "Levitate" 1706
	{ spells.levitate, jps.Defensive and IsFalling() and not playerHasBuff(111759) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not playerHasBuff(111759) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", not jps.buff(156079) and not jps.buff(188031) and jps.useItem(118922) , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)