local spells = jps.spells.priest
local UnitIsUnit = UnitIsUnit
local Enemy = { "target", "focus" ,"mouseover" }

local CountInRange = function(pct)
	local Count, _, _ = jps.CountInRaidStatus(pct)
	return Count
end
local AvgHealthRaid = function()
	local _, AvgHealth, _ = jps.CountInRaidStatus()
	return AvgHealth
end

local PlayerHealth = function()
	return jps.hp("player")
end

local PlayerIsRecast = function(spell,unit)
	return jps.isRecast(spell,unit)
end

local PlayerDistance = function(unit)
	return jps.distanceMax(unit)
end

local PlayerInsanity = function()
	return jps.insanity()
end

local PlayerMoving = function()
	if select(1,GetUnitSpeed("player")) > 0 then return true end
	return false
end

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

local PlayerCanHeal = function(unit)
	return jps.canHeal(unit)
end

local PlayerHasBuff = function(spell)
	return jps.buff(spell,"player")
end

local PlayerBuffStacks = function(spell)
	return jps.buffStacks(spell)
end

local PlayerHasTalent = function(row,talent)
	return jps.hasTalent(row,talent)
end

local PlayerCanDispel = function(unit,dispel)
	return jps.canDispel(unit,dispel)
end

local PlayerOffensiveDispel = function(unit)
	return jps.DispelOffensive(unit)
end

local DispelDiseaseTarget = function()
	return jps.DispelDiseaseTarget()
end

local DispelMagicTarget = function()
	return jps.DispelMagicTarget()
end

------------------------------------------------

local TargetDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"target")
end
local TargetDebuff = function(spell)
	return jps.myDebuff(spell,"target")
end

------------------------------------------------

local FocusDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"focus")
end
local FocusDebuff = function(spell)
	return jps.myDebuff(spell,"focus")
end

------------------------------------------------

local MouseoverDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"mouseover")
end
local MouseoverDebuff = function(spell)
	return jps.myDebuff(spell,"mouseover")
end

------------------------------------------------

local PainEnemyTarget = function(unit)
	if PlayerCanDPS(unit) and not jps.myDebuff(spells.shadowWordPain,unit) and not PlayerIsRecast(spells.shadowWordPain,unit) then
		return true end
	return false
end

local VampEnemyTarget = function(unit)
	if jps.Moving then return false end
	if PlayerCanDPS(unit) and not jps.myDebuff(spells.vampiricTouch,unit) and not PlayerIsRecast(spells.vampiricTouch,unit) then
		return true end
	return false
end

------------------------------------------------

local FocusNamePlate = function()
	local NamePlateTable = jps.NamePlate()
	local NamePlateTarget = nil
	for unit,_ in pairs(NamePlateTable) do
		if PlayerCanAttack(unit) and not jps.myDebuff(spells.shadowWordPain,unit) and not jps.myDebuff(spells.vampiricTouch,unit) then
			NamePlateTarget = unit
		elseif PlayerCanDPS("mouseover") and jps.Defensive and not jps.myDebuff(spells.shadowWordPain,unit) and not jps.myDebuff(spells.vampiricTouch,unit) then
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

local NamePlateDebuff = function(debuff)
	return jps.NamePlateDebuff(debuff)
end

local NamePlateCount = function()
	return jps.NamePlateCount()
end

------------------------------------------------

local TargetMouseover = function()
	-- Config FOCUS with MOUSEOVER
	if not jps.UnitExists("focus") and (PlayerCanAttack("mouseover") or (PlayerCanDPS("mouseover") and jps.Defensive)) then
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
	elseif jps.UnitExists("focus") and not PlayerCanDPS("focus") then
		jps.Macro("/clearfocus")
	end
end

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

local DeathEnemyTarget = function()
	local DeathEnemyTarget = nil
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if jps.hasTalent(4,2) and  jps.hp(unit) < 0.35 then
			DeathEnemyTarget = unit
		elseif jps.hp(unit) < 0.20 then
			DeathEnemyTarget = unit
		break end
	end
end

local TargetElite = function()
	if jps.targetIsBoss("target") then return true
	elseif jps.hp("target") > 0.50 then return true
	elseif string.find(GetUnitName("target"),"Mannequin") ~= nil then return true
	elseif NamePlateCount() > 3 then return true
	end
	return false
end

local DispelOffensiveTarget = function()
	local DispelOffensiveTarget = nil
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if PlayerOffensiveDispel(unit) then
			DispelOffensiveTarget = unit
		break end
	end
	return DispelOffensiveTarget
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
--FocusNamePlate()

local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local playerIsTarget = jps.PlayerIsTarget()
local isPVP = UnitIsPVP("player")

----------------------
-- TARGET ENEMY
----------------------

local rangedTarget  = "target"
if PlayerCanDPS("target") then rangedTarget = "target"
elseif PlayerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif PlayerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif PlayerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if PlayerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local targetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

------------------------
-- SPELL TABLE ---------
------------------------

if PlayerHasBuff(47585) then return end
if not PlayerCanDPS(rangedTarget) then return end

local spellTable = {

	-- "Dispersion" 47585
	{spells.dispersion, PlayerHealth() < 0.40 },
	{ "macro", PlayerHasBuff(47585) and PlayerHealth > 0.90 , "/cancelaura "..spells.dispersion },
	{spells.fade, playerIsTarget },
	-- "Power Word: Shield" 17
	{spells.powerWordShield, not PlayerHasBuff(65081) and jps.IsMovingFor(1) and PlayerHasTalent(2,2) , "player" },
	{spells.powerWordShield, PlayerHealth() < 0.80 and not PlayerHasBuff(194249) and not PlayerHasBuff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, jps.hp("mouseover") < 0.50 and not jps.buff(spells.powerWordShield,"mouseover") , "mouseover" },
	-- "Pierre de soins" 5512
	{ "macro", PlayerHealth() < 0.60 and jps.useItem(5512) , "/use item:5512" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, PlayerHealth() < 0.70 , "player" },
	-- "Etreinte vampirique" buff 15286 -- pendant 15 sec, vous permet de rendre à un allié proche, un montant de points de vie égal à 40% des dégâts d’Ombre que vous infligez avec des sorts à cible unique
	{spells.vampiricEmbrace, PlayerHasBuff(194249) and PlayerHealth() < 0.50 },
	{spells.vampiricEmbrace, PlayerHasBuff(194249) and AvgHealthRaid() < 0.80 },

	-- "Purify Disease" 213634
	{"nested", jps.UseCDs , {
		{spells.purifyDisease, PlayerCanDispel("mouseover","Disease") , "mouseover" },
		{spells.purifyDisease, PlayerCanDispel("player","Disease") , "player" },
		{spells.purifyDisease, PlayerCanDispel(Tank,"Disease") , Tank },
		{spells.purifyDisease, DispelDiseaseTarget() ~= nil , DispelDiseaseTarget },
	}},

	{"nested", jps.Interrupts , {
		-- "Silence" 15487 -- debuff same ID
		{spells.silence,  not TargetDebuff(226943) and jps.IsCasting("target") and PlayerDistance("target") < 30 , "target" },
		{spells.silence, not FocusDebuff(226943) and jps.IsCasting("focus") and PlayerDistance("focus") < 30 , "focus" },
		-- "Mind Bomb" 205369 -- 30 yd range -- debuff "Explosion mentale" 226943
		{spells.mindBomb, jps.IsCasting("target") and PlayerDistance("target") < 30 , "target" },
		{spells.mindBomb, jps.IsCasting("focus") and PlayerDistance("focus") < 30 , "focus" },
		{spells.mindBomb, jps.MultiTarget , "target" },
		-- "Levitate" 1706
		{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not PlayerHasBuff(111759) , "player" },
		--{ spells.levitate, jps.Defensive and IsSwimming() and not PlayerHasBuff(111759) , "player" },
	}},
	
	-- "Guérison de l’ombre" 186263 -- debuff "Shadow Mend" 187464 10 sec
	{spells.shadowMend, not PlayerMoving() and not PlayerHasBuff(194249) and PlayerHealth() < 0.60 and not PlayerHasBuff(15286) and jps.castEverySeconds(186263,4) , "player" },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ spells.dispelMagic, isPVP and DispelOffensiveTarget() ~= nil and jps.castEverySeconds(528,4) , DispelOffensiveTarget , "|cff1eff00DispelOffensive" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	-- { "macro", jps.useTrinket(1) , "/use 14"},

    -- "Déferlante d’ombre" 205385
    {spells.shadowCrash, PlayerHasTalent(7,2) },

   	{spells.voidEruption, not PlayerMoving() and PlayerCanDPS("target") and not PlayerHasBuff(194249) and PlayerInsanity() > 65 and PlayerHasTalent(7,1) and NamePlateCount() < 5 },
	{spells.voidEruption, not PlayerMoving() and PlayerCanDPS("target") and not PlayerHasBuff(194249) and PlayerInsanity() == 100 },

	{spells.powerInfusion, PlayerBuffStacks(194249) > 9 and PlayerInsanity() > 65 },
	{spells.shadowfiend, PlayerBuffStacks(194249) > 9 , "target" },
	{spells.mindbender, PlayerBuffStacks(194249) > 9 , "target" },
	
	{"nested", PlayerHasBuff(194249) , {
		--{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, VoidBoltTarget() ~= nil , VoidBoltTarget },
		{spells.voidEruption, true , "target"},
		{spells.voidTorrent , not PlayerMoving() },
		{spells.shadowWordDeath, PlayerInsanity() < 85 , "target" },
		{spells.shadowWordDeath, PlayerInsanity() < 85 and DeathEnemyTarget() ~= nil , DeathEnemyTarget },
	}},

	{spells.shadowWordDeath, not PlayerHasBuff(194249) , "target" },
	{spells.shadowWordDeath, not PlayerHasBuff(194249) and DeathEnemyTarget() ~= nil , DeathEnemyTarget },

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not PlayerMoving() , "target"  },

	{spells.vampiricTouch, not PlayerMoving() and TargetDebuffDuration(spells.vampiricTouch) < 4  and not PlayerIsRecast(spells.vampiricTouch,"target") , "target"  },
	{spells.shadowWordPain, TargetDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"target") , "target" },
	
	{spells.shadowWordPain, NamePlateCount() > 4 and NamePlateDebuff(spells.shadowWordPain) < math.min(9,NamePlateCount()) and PlayerCanAttack("mouseover") and not MouseoverDebuff(spells.shadowWordPain) and not PlayerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" , "SwP" },

	{spells.vampiricTouch, not PlayerMoving() and FocusDebuffDuration(spells.vampiricTouch) < 4 and not PlayerIsRecast(spells.vampiricTouch,"focus") , "focus"  },
	{spells.shadowWordPain, FocusDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"focus") , "focus" },
	
    {spells.mindFlay , NamePlateCount() > 4 and not PlayerMoving() and TargetDebuffDuration(spells.shadowWordPain) > 3 , "target" , "MF" },

	{spells.vampiricTouch, PlayerCanAttack("mouseover") and not PlayerMoving() and MouseoverDebuffDuration(spells.vampiricTouch) < 4 and not PlayerIsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, PlayerCanAttack("mouseover") and MouseoverDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },
	{spells.vampiricTouch, jps.Defensive and not PlayerMoving() and MouseoverDebuffDuration(spells.vampiricTouch) < 4 and not PlayerIsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, jps.Defensive and MouseoverDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },

	-- Mind Flay If the target is afflicted with Shadow Word: Pain you will also deal splash damage to nearby targets.
    {spells.mindFlay , not PlayerMoving() , "target"  },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end,"Shadow Priest")

--[[

#showtooltip Mot de l’ombre : Douleur
/cast [@mouseover,exists,nodead,harm][@target] Mot de l’ombre : Douleur

]]

--	"Dernier souffle d’Anund" buff 215210 (Brassards Legendaire) -- 15 secondes restantes
--	Chaque fois que Mot de l’ombre : Douleur et Toucher vampirique infligent des dégâts
--	Les dégâts de votre prochain Éclair de Vide sont augmentés de 2%, ce effet se cumulant jusqu’à 50 fois

--	Low Insanity coming up (Shadow Word: Death , Void Bolt , Mind Blast , AND Void Torrent are all on cooldown and you are in danger of reaching 0 Insanity).
--	{spells.dispersion, jps.hasTalent(6,3) and PlayerInsanity() > 21 and PlayerInsanity() < 71 and jps.cooldown(spells.mindbender) > 51 , "player" },

--	{spells.voidEruption, TargetDebuffDuration(spells.shadowWordPain) > 0 and TargetDebuffDuration(spells.shadowWordPain) < FocusDebuffDuration(spells.shadowWordPain) and TargetDebuffDuration(spells.shadowWordPain) < MouseoverDebuffDuration(spells.shadowWordPain) , "target" },
--	{spells.voidEruption, TargetDebuffDuration(spells.vampiricTouch) > 0 and TargetDebuffDuration(spells.vampiricTouch) < FocusDebuffDuration(spells.vampiricTouch) and TargetDebuffDuration(spells.vampiricTouch) < MouseoverDebuffDuration(spells.vampiricTouch) , "target" },
--	{spells.voidEruption, FocusDebuffDuration(spells.shadowWordPain) >  0 and FocusDebuffDuration(spells.shadowWordPain) < MouseoverDebuffDuration(spells.shadowWordPain) , "focus" },
--	{spells.voidEruption, FocusDebuffDuration(spells.vampiricTouch) >  0 and FocusDebuffDuration(spells.vampiricTouch) < MouseoverDebuffDuration(spells.vampiricTouch) , "focus" },
--	{spells.voidEruption, MouseoverDebuffDuration(spells.shadowWordPain) > 0 , "mouseover" },
--	{spells.voidEruption, MouseoverDebuffDuration(spells.vampiricTouch) > 0 , "mouseover" },

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()
	
	if IsMounted() then return end
	
	local spellTable = {
	
	-- "Shield" 17 "Body and Soul" 64129 "Corps et âme" -- Vitesse de déplacement augmentée de 40% -- buff 65081
	{ spells.powerWordShield, not PlayerHasBuff(65081) and jps.IsMovingFor(1) and PlayerHasTalent(2,2) , "player" , "Shield_BodySoul" },

	-- "Levitate" 1706
	{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not PlayerHasBuff(111759) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not PlayerHasBuff(111759) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, PlayerHealth() < 0.80 , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", not jps.buff(156079) and not jps.buff(188031) and jps.useItem(118922) , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)
