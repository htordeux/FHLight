local spells = jps.spells.priest
local UnitIsUnit = UnitIsUnit
local Enemy = { "target", "focus" ,"mouseover" }
local canDPS = jps.canDPS

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
	return canDPS(unit)
end

local PlayerCanHeal = function(unit)
	return jps.canHeal(unit)
end

local PlayerHasBuff = function(spell)
	return jps.buff(spell,"player")
end

local PlayerBuffDuration = function(spell)
	return jps.buffDuration(spell,"player")
end

local PlayerBuffStacks = function(spell)
	return jps.buffStacks(spell)
end

local PlayerHasTalent = function(row,talent)
	return jps.hasTalent(row,talent)
end

local PlayerCanDispel = function(unit,dispel)
	return jps.CanDispel(unit,dispel)
end

local PlayerCanDispelWith = function(unit,spellID) 
	return jps.CanDispelWith(unit,spellID) 
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

local NamePlateCount = function()
	return jps.NamePlateCount()
end

----------Config FOCUS with MOUSEOVER-------------

local TargetMouseover = function()
	if not jps.UnitExists("focus") and not UnitIsUnit("target","mouseover") and PlayerCanAttack("mouseover") then
		if UnitIsUnit("mouseovertarget","player") then
			jps.Macro("/focus mouseover")
		elseif not MouseoverDebuff(spells.shadowWordPain) and not MouseoverDebuff(spells.vampiricTouch) then 
			jps.Macro("/focus mouseover")
		elseif not MouseoverDebuff(spells.shadowWordPain) then
			jps.Macro("/focus mouseover")
		elseif not MouseoverDebuff(spells.vampiricTouch) then
			jps.Macro("/focus mouseover")
		elseif not UnitIsUnit("target","mouseover") then
			jps.Macro("/focus mouseover")
		end
	end
end

local FocusMouseover = function()
	if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
		jps.Macro("/clearfocus")
	elseif jps.UnitExists("focus") and not PlayerCanDPS("focus") then
		jps.Macro("/clearfocus")
	elseif jps.UnitExists("focus") and PlayerCanAttack("mouseover") and not UnitIsUnit("target","mouseover") and not UnitIsUnit("focus","mouseover") then
		if FocusDebuffDuration(spells.vampiricTouch) > 4 and FocusDebuffDuration(spells.shadowWordPain) > 4 then
			if MouseoverDebuffDuration(spells.vampiricTouch) < 2 and MouseoverDebuffDuration(spells.shadowWordPain) < 2 then
				jps.Macro("/focus mouseover")
			end
		end
	end
end

------------------------------------------------

local VoidBoltTarget = function()
	local voidBoltTarget = "target"
	local voidBoltTargetDuration = 24
	for i=1,#Enemy do -- for _,unit in ipairs(Enemy) do
		local unit = Enemy[i]
		if jps.myDebuff(spells.shadowWordPain,unit) and jps.myDebuff(spells.vampiricTouch,unit) then
			local shadowWordPainDuration = jps.myDebuffDuration(spells.shadowWordPain,unit)
			local vampiricTouchDuration = jps.myDebuffDuration(spells.vampiricTouch,unit)
			local duration = math.min(shadowWordPainDuration,vampiricTouchDuration)
			if duration < voidBoltTargetDuration then
				voidBoltTargetDuration = duration
				voidBoltTarget = unit
			end
		end
	end
	return voidBoltTarget
end

local DeathEnemyTarget = function()
	local deathEnemyTarget = "target"
	local healthEnemyTarget = 1
	for i=1,#Enemy do
		local unit = Enemy[i]
		if UnitExists(unit) then healthEnemyTarget = jps.hp(unit) end
		if PlayerHasTalent(4,2) and healthEnemyTarget < 0.35 and PlayerCanDPS(unit) then
			deathEnemyTarget = unit
		elseif healthEnemyTarget < 0.20 and PlayerCanDPS(unit) then
			deathEnemyTarget = unit
		break end
	end
	return deathEnemyTarget
end

local DispelOffensiveTarget = function()
	local DispelOffensiveTarget = nil
	for i=1,#Enemy do -- for _,unit in ipairs(Enemy) do
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
--jps.Interrupts for "Silence" et "Mind Bomb" et "Psychic Scream"
--jps.UseCDs for "Purify Disease"

jps.registerRotation("PRIEST","SHADOW",function()

TargetMouseover()
FocusMouseover()

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
if not PlayerCanDPS("target") then return end

local spellTable = {

	-- "Dispersion" 47585
	{spells.dispersion, PlayerHealth() < 0.40 },
	{ "macro", PlayerHasBuff(47585) and PlayerHealth > 0.90 and PlayerInsanity() > 90 , "/cancelaura "..spells.dispersion },
	{ "macro", PlayerHasBuff(47585) , "/stopcasting" },
	{spells.fade, playerIsTarget },
	
	-- "Purify Disease" 213634
	{"nested", jps.UseCDs , {
		{spells.purifyDisease, PlayerCanDispel("mouseover","Disease") , "mouseover" },
		{spells.purifyDisease, PlayerCanDispel("player","Disease") , "player" },
		{spells.purifyDisease, PlayerCanDispel(Tank,"Disease") , Tank },
		{spells.purifyDisease, DispelDiseaseTarget() ~= nil , DispelDiseaseTarget },
	}},
	-- "Power Word: Shield" 17
	{spells.powerWordShield, not PlayerHasBuff(65081) and jps.IsMovingFor(1.6) and PlayerHasTalent(2,2) , "player" },
	{spells.powerWordShield, PlayerHealth() < 0.70 and not PlayerHasBuff(194249) and not PlayerHasBuff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, PlayerCanHeal("mouseover") and jps.hp("mouseover") < 0.60 and not jps.buff(spells.powerWordShield,"mouseover") , "mouseover" },
	-- "Pierre de soins" 5512
	{ "macro", PlayerHealth() < 0.60 and jps.useItem(5512) , "/use item:5512" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, PlayerHealth() < 0.70 , "player" },
	-- "Etreinte vampirique" buff 15286 -- pendant 15 sec, vous permet de rendre à un allié proche, un montant de points de vie égal à 40% des dégâts d’Ombre que vous infligez avec des sorts à cible unique
	{spells.vampiricEmbrace, PlayerHasBuff(194249) and PlayerHealth() < 0.50 },
	{spells.vampiricEmbrace, PlayerHasBuff(194249) and AvgHealthRaid() < 0.80 },
	-- "Guérison de l’ombre" 186263 -- debuff "Shadow Mend" 187464 10 sec
	{spells.shadowMend, not PlayerMoving() and not PlayerHasBuff(194249) and PlayerHealth() < 0.60 and not PlayerHasBuff(15286) and jps.castEverySeconds(186263,4) , "player" },

	{"nested", jps.Interrupts , {
		-- "Silence" 15487 -- debuff same ID
		{spells.silence, not TargetDebuff(226943) and jps.IsCasting("target") and PlayerDistance("target") < 30 , "target" },
		{spells.silence, not FocusDebuff(226943) and jps.IsCasting("focus") and PlayerDistance("focus") < 30 , "focus" },
		-- "Mind Bomb" 205369 -- 30 yd range -- debuff "Explosion mentale" 226943
		{spells.mindBomb, jps.IsCasting("target") and PlayerDistance("target") < 30 , "target" },
		{spells.mindBomb, jps.IsCasting("focus") and PlayerDistance("focus") < 30 , "focus" },
		{spells.mindBomb, jps.MultiTarget , "target" },
	}},
	-- "Levitate" 1706 -- buff Levitate 111759
	{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not PlayerHasBuff(spells.levitate) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not PlayerHasBuff(spells.levitate) , "player" },

    -- "Shadow Word: Death" 32379
    {spells.shadowWordDeath, jps.spellCharges(spells.shadowWordDeath) == 2 , "target" },
    {spells.shadowWordDeath, jps.spellCharges(spells.shadowWordDeath) > 0 and PlayerInsanity() < 85 , DeathEnemyTarget , "DeathEnemyTarget" },

    {"macro", jps.CanCastvoidBolt(0.5) , "/stopcasting" },
	{spells.voidEruption, PlayerHasBuff(194249) , VoidBoltTarget },
   	{spells.voidTorrent , PlayerHasBuff(194249) and not PlayerMoving() and TargetDebuffDuration(spells.vampiricTouch) > 4 and TargetDebuffDuration(spells.shadowWordPain) > 4 },
	{spells.voidEruption, not PlayerMoving() and not PlayerHasBuff(194249) and PlayerInsanity() == 100 },
	{spells.voidEruption, not PlayerMoving() and not PlayerHasBuff(194249) and PlayerInsanity() > 65 and PlayerHasTalent(7,1) and TargetDebuffDuration(spells.vampiricTouch) > 4 and TargetDebuffDuration(spells.shadowWordPain) > 4},

   	-- mindblast is highest priority spell out of voidform
	{spells.mindBlast, not PlayerMoving() and not PlayerHasBuff(194249) , "target" },
	{spells.mindBlast, not PlayerMoving() and not PlayerHasBuff(194249) and canDPS("targettarget") , "targettarget" },

     -- MultiTarget -- Mind Flay If the target is afflicted with Shadow Word: Pain you will also deal splash damage to nearby targets.
    {"nested", jps.NamePlateCount() > 4 , {
		{spells.shadowWordPain, PlayerCanDPS("mouseover") and MouseoverDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },
		{spells.mindFlay , not PlayerMoving() and TargetDebuffDuration(spells.shadowWordPain) > 4 , "target"  },
    	{spells.mindFlay , not PlayerMoving() and FocusDebuffDuration(spells.shadowWordPain) > 4 , "focus"  },
   	}},
	
	{spells.vampiricTouch, not PlayerMoving() and TargetDebuffDuration(spells.vampiricTouch) < 4 and not PlayerIsRecast(spells.vampiricTouch,"target") , "target"  },
	{spells.shadowWordPain, TargetDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"target") , "target" },
	{spells.vampiricTouch, not PlayerMoving() and FocusDebuffDuration(spells.vampiricTouch) < 4 and not PlayerIsRecast(spells.vampiricTouch,"focus") , "focus"  },
	{spells.shadowWordPain, FocusDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"focus") , "focus" },
	
	{"macro", jps.CanCastMindBlast(0.5) , "/stopcasting" },
	{spells.mindBlast, not PlayerMoving() , "target"  },
	
   	-- TRINKETS
	-- { "macro", jps.useTrinket(0) , "/use 13"}, -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13
	{ "macro", jps.useTrinket(1) and PlayerHasBuff(194249) , "/use 14"}, -- jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	-- "Infusion de puissance"  -- Confère un regain de puissance pendant 20 sec, ce qui augmente la hâte de 25%
	{spells.powerInfusion, PlayerBuffStacks(194249) > 14 and PlayerBuffStacks(194249) < 22 and PlayerInsanity() > 50 },
	-- "Ombrefiel" cd 3 min duration 12sec -- "Mindbender" cd 1 min duration 12 sec
	{spells.shadowfiend, UnitSpellHaste("player") > 50 , "target" },
	{spells.mindbender, UnitSpellHaste("player") > 50 , "target" },

	{spells.vampiricTouch, PlayerCanAttack("mouseover") and not PlayerMoving() and MouseoverDebuffDuration(spells.vampiricTouch) < 4 and not PlayerIsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, PlayerCanAttack("mouseover") and MouseoverDebuffDuration(spells.shadowWordPain) < 4 and not PlayerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },

	-- Mind Flay If the target is afflicted with Shadow Word: Pain you will also deal splash damage to nearby targets.
    {spells.mindFlay , not PlayerMoving() , "target"  },
    {spells.mindFlay , not PlayerMoving() and canDPS("targettarget") , "targettarget" },

}

	local spell,target = ParseSpellTable(spellTable)
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
--	{spells.dispersion, PlayerHasTalent(6,3) and PlayerInsanity() > 21 and PlayerInsanity() < 71 and jps.cooldown(spells.mindbender) > 51 , "player" },

--	{spells.voidEruption, TargetDebuffDuration(spells.shadowWordPain) > 0 and TargetDebuffDuration(spells.shadowWordPain) < FocusDebuffDuration(spells.shadowWordPain) and TargetDebuffDuration(spells.shadowWordPain) < MouseoverDebuffDuration(spells.shadowWordPain) , "target" },
--	{spells.voidEruption, TargetDebuffDuration(spells.vampiricTouch) > 0 and TargetDebuffDuration(spells.vampiricTouch) < FocusDebuffDuration(spells.vampiricTouch) and TargetDebuffDuration(spells.vampiricTouch) < MouseoverDebuffDuration(spells.vampiricTouch) , "target" },
--	{spells.voidEruption, FocusDebuffDuration(spells.shadowWordPain) >  0 and FocusDebuffDuration(spells.shadowWordPain) < MouseoverDebuffDuration(spells.shadowWordPain) , "focus" },
--	{spells.voidEruption, FocusDebuffDuration(spells.vampiricTouch) >  0 and FocusDebuffDuration(spells.vampiricTouch) < MouseoverDebuffDuration(spells.vampiricTouch) , "focus" },
--	{spells.voidEruption, MouseoverDebuffDuration(spells.shadowWordPain) > 0 , "mouseover" },
--	{spells.voidEruption, MouseoverDebuffDuration(spells.vampiricTouch) > 0 , "mouseover" },


--jps.registerParseRotation("PRIEST","SHADOW",{
--
--	{spells.voidEruption, PlayerHasBuff(194249) , "target"},
--	{spells.voidTorrent , not PlayerMoving() and PlayerHasBuff(194249) },
--	{spells.voidEruption, not PlayerMoving() and PlayerCanDPS("target") and not PlayerHasBuff(194249) and PlayerInsanity() == 100 },
--	{spells.mindBlast, not PlayerMoving() , "target"  },
--	{spells.vampiricTouch, not PlayerMoving() and TargetDebuffDuration(spells.vampiricTouch) < 4  and not PlayerIsRecast(spells.vampiricTouch,"target") , "target"  },
--	{spells.shadowWordPain, TargetDebuffDuration(spells.shadowWordPain) < 4  , "target" },
--    {spells.mindFlay , not PlayerMoving() , "target" ,"MF" },
--}
--,"Parse Priest")




----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

	if IsMounted() then return end
	
	local spellTable = {
	
	-- "Shield" 17 "Body and Soul" 64129 "Corps et âme" -- Vitesse de déplacement augmentée de 40% -- buff 65081
	{ spells.powerWordShield, not PlayerHasBuff(65081) and jps.IsMovingFor() and PlayerHasTalent(2,2) , "player" , "Shield_BodySoul" },

	-- "Levitate" 1706 -- buff Levitate 111759
	--{ "macro", PlayerHasBuff(spells.levitate) and not IsFalling() , "/cancelaura Lévitation"  },
	{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not PlayerHasBuff(spells.levitate) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not PlayerHasBuff(spells.levitate) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, PlayerHealth() < 0.80 , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", not jps.buff(156079) and not jps.buff(188031) and jps.useItem(118922) , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = ParseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)
