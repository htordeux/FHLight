
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

--jps.Defensive for "Psychic Scream" and "Levitate"
--jps.Interrupts for "Silence" et "Mind Bomb"
--jps.UseCDs for "Purify Disease"

jps.registerRotation("PRIEST","SHADOW",function()

local spell = nil
local target = nil

----------------------------
-- LOWEST UNIT
----------------------------
	
local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.80)
local LowestUnit = jps.LowestImportantUnit()

local Tank,TankUnit = jps.findTankInRaid() -- default "focus" "player"
local TankThreat = jps.findThreatInRaid() -- default "focus" "player"
local TankTarget = TankThreat.."target"

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local ispvp = UnitIsPVP("player")

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
	elseif canAttack("mouseover") and not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.vampiricTouch,"mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
	elseif canAttack("mouseover") and not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.shadowWordPain,"mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
	elseif canAttack("mouseover") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
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
if canAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end

local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0
local playerIsTargeted = jps.playerIsTargeted()

local isTargetElite = false
if jps.targetIsBoss("target") then isTargetElite = true
elseif jps.TimeToDie("target") > 5 then isTargetElite = true
elseif jps.hp("target") > 0.50 then isTargetElite = true
elseif string.find(GetUnitName("target"),"Mannequin") ~= nil then isTargetElite = true
end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

if canDPS("focus") then EnemyUnit[#EnemyUnit+1] = "focus" end

local fnPainEnemyTarget = function(unit)
	if canDPS(unit) and not jps.myDebuff(spells.shadowWordPain,unit) and not jps.isRecast(spells.shadowWordPain,unit) then
		return true end
	return false
end

local fnVampEnemyTarget = function(unit)
	if jps.Moving then return false end
	if canDPS(unit) and not jps.myDebuff(spells.vampiricTouch,unit) and not jps.isRecast(spells.vampiricTouch,unit) then
		return true end
	return false
end

local DeathEnemyTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.hp(unit) < 0.35 then 
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

local VoidBoltTarget = nil
local VoidBoltTargetDuration = 20
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.myDebuff(spells.shadowWordPain,unit) then
		local shadowWordPainDuration = jps.myDebuffDuration(spells.shadowWordPain,unit)
		if shadowWordPainDuration < VoidBoltTargetDuration then
			VoidBoltTargetDuration = shadowWordPainDuration
			VoidBoltTarget = unit
		end
	elseif jps.myDebuff(spells.vampiricTouch,unit) then
		local vampiricTouchDuration = jps.myDebuffDuration(spells.vampiricTouch,unit)
		if vampiricTouchDuration < VoidBoltTargetDuration then
			VoidBoltTargetDuration = vampiricTouchDuration
			VoidBoltTarget = unit
		end
	end
end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

-- jps.unitForLeap includes jps.FriendAggro and jps.LoseControl
local LeapFriend = nil
for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
	local unit = FriendUnit[i]
	if jps.unitForLeap(unit) and jps.hp(unit) < 0.30 then 
		LeapFriend = unit
	break end
end

-- if jps.debuffDuration(114404,"target") > 18 and jps.UnitExists("target") then MoveBackwardStart() end
-- if jps.debuffDuration(114404,"target") < 18 and jps.debuff(114404,"target") and jps.UnitExists("target") then MoveBackwardStop() end

-------------------------------------------------------------
------------------------ TABLES
-------------------------------------------------------------


local parseHeal = {
	-- "Power Word: Shield" 17	
	{spells.powerWordShield, not jps.buff(spells.powerWordShield) , "player" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, true , "player" },
	-- "Guérison de l’ombre" 186263
	{spells.shadowMend, not jps.Moving and not jps.buff(194249) and jps.castEverySeconds(186263, 4) , "player" , "shadowMendPlayer" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.60 and jps.itemCooldown(5512) == 0 , "/use item:5512" },
}

-----------------------------
-- SPELLTABLE
-----------------------------

-- "Dernier souffle d’Anund" buff 215210 (Brassards Legendaire) -- 15 secondes restantes
-- Chaque fois que Mot de l’ombre : Douleur et Toucher vampirique infligent des dégâts
-- les dégâts de votre prochain Éclair de Vide sont augmentés de 2%, ce effet se cumulant jusqu’à 50 fois.

if jps.buff(47585,"player") then return end -- "Dispersion" 47585
if not UnitCanAttack("player", "target") then return end
if jps.IsChannelingSpell(spells.voidEruption) and not jps.UnitExists("target") then SpellStopCasting() end

local spellTable = {

	{spells.dispersion, jps.hp("player") < 0.40 },
	 -- "Etreinte vampirique" buff 15286
	{spells.vampiricEmbrace, jps.hp("player") < 0.60 },
	{spells.vampiricEmbrace, CountInRange > 2 and AvgHealthLoss < 0.80 },
	{"nested", jps.hp("player") < 0.80 and not jps.buff(spells.vampiricEmbrace) , parseHeal },
	
	{spells.powerWordShield, jps.hp(TankThreat) < 0.50 and not jps.buff(spells.powerWordShield,TankThreat) , TankThreat , "shield_TankThreat" },
	{spells.powerWordShield, canHeal("mouseover") and jps.hp("mouseover") < 0.50 , "mouseover" , "shield_Mouseover" },
	{spells.powerWordShield, jps.Moving and not jps.buff(17,"player") and jps.hasTalent(2,2) , "player" , "Shield_BodySoul" },
	-- "Guérison de l’ombre" 186263
	{spells.shadowMend, not jps.Moving and not jps.buff(194249) and jps.hp(TankThreat) < 0.50 and jps.castEverySeconds(186263, 4) , TankThreat , "shadowMend_TankThreat" },
	{spells.shadowMend, not jps.Moving and not jps.buff(194249) and canHeal("mouseover") and jps.hp("mouseover") < 0.50 , "mouseover" , "shadowMend_Mouseover" },
	
	-- interrupts --
	{spells.fade, not ispvp and jps.FriendAggro("player") },
	{spells.silence, jps.Interrupts and jps.IsCasting(rangedTarget) and jps.distanceMax(rangedTarget) < 30 , rangedTarget , "Silence_Target" },
	{spells.silence, jps.Interrupts and jps.IsCasting("focus") and jps.distanceMax("focus") < 30 , "focus" , "Silence_Focus" },
	-- "Psychic Scream" 8122 "Cri psychique"  -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{spells.psychicScream, jps.Interrupts and jps.Defensive and jps.IsCasting(rangedTarget) and jps.canFear(rangedTarget) , rangedTarget },
	{spells.psychicScream, jps.Interrupts and jps.Defensive and jps.IsCasting("focus") and jps.canFear("focus") , "focus" },
	-- "Mind Bomb" 205369 -- 30 yd range
	{spells.mindBomb, jps.Interrupts and jps.IsCasting(rangedTarget) , rangedTarget },
	{spells.mindBomb, jps.Interrupts and jps.IsCasting("focus") , "focus" },
	{spells.mindBomb, jps.Interrupts and jps.MultiTarget , rangedTarget },
	-- "Purify Disease" 213634
	{spells.purifyDisease, jps.UseCDs and jps.canDispel("player","Disease") , "player" },
	{spells.purifyDisease, jps.UseCDs and jps.canDispel(TankThreat,"Disease") , TankThreat },
	{spells.purifyDisease, jps.UseCDs and jps.canDispel("mouseover","Disease") , "mouseover" },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", ispvp and jps.hp(LowestUnit) > 0.60 , {
		{ spells.dispelMagic, jps.castEverySeconds(528,8) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
		{ spells.dispelMagic, jps.castEverySeconds(528,8) and DispelOffensiveEnemyTarget ~= nil  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },
	}},
	-- SNM "Levitate" 1706	
	{ 1706, jps.Defensive and jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.Defensive and IsSwimming() and not jps.buff(111759) , "player" },

	-- Opening -- "Voidform" buff 194249 -- "Lingering Insanity" buff 197937
	{spells.mindBlast, not jps.Moving and not jps.buff(197937) and not jps.buff(194249) , rangedTarget , "mindBlast_Opening"},
	{spells.mindbender, not jps.buff(197937) and not jps.buff(194249) },
	-- "Power Infusion" 10060
	--{spells.powerInfusion, jps.buffStacks(194249) > 9 },
	{ "nested", jps.buffStacks(194249) > 9 , {
		{spells.powerInfusion, UnitLevel("target") == -1 },
		{spells.powerInfusion, jps.targetIsBoss("target") and jps.hp("target") > 0.50 },
		{spells.powerInfusion, jps.MultiTarget },
		{spells.powerInfusion, UnitLevel("focus") == -1 },
		{spells.powerInfusion, jps.targetIsBoss("focus") and jps.hp("focus") > 0.50 },
	}},

	{spells.shadowWordDeath, jps.spellCharges(spells.shadowWordDeath) == 2 and jps.insanity() < 100 , "target" , "Death_Buff_2" },

	{"nested", jps.buff(194249) , {

		{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, jps.myDebuff(spells.shadowWordPain,rangedTarget) and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) < 4 , rangedTarget , "voidBold_Target" },
		{spells.voidEruption, jps.myDebuff(spells.vampiricTouch,rangedTarget) and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) < 4 , rangedTarget , "voidBold_Target" },
		{spells.voidEruption, VoidBoltTarget ~= nil , VoidBoltTarget , "voidBold_MultiUnit"},
		{spells.voidEruption, jps.myDebuff(spells.shadowWordPain,"mouseover") , "mouseover" , "voidBold_Mouseover"},
    	{spells.voidEruption, jps.myDebuff(spells.vampiricTouch,"mouseover") , "mouseover" , "voidBold_Mouseover"},
    	{spells.voidEruption, true , rangedTarget , "voidBold"},
    	
       	{spells.voidTorrent , not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) > 6 and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) > 6 , rangedTarget , "voidTorrent"},

		{"macro", jps.canCastshadowWordDeath , "/stopcasting" },
    	{spells.shadowWordDeath, jps.insanity() < 71 and jps.hp("target") < 0.35 , "target" , "Death_Buff" },
		{spells.shadowWordDeath, jps.insanity() < 71 and  DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death_Buff" },
		{spells.shadowWordDeath, jps.insanity() < 71 and jps.hp("mouseover") < 0.35 , "mouseover" , "Death_Buff" },
		
	    {"macro", jps.canCastMindBlast , "/stopcasting" },
		{spells.mindBlast, not jps.Moving , rangedTarget , "mindBlast" },

		{spells.mindSear, jps.MultiTarget and not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) > 6 and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) > 6 },

   		-- spells.mindbender -- 15 seconds cd 1 min
   		{spells.shadowfiend, jps.buffStacks(194249) > 9 , rangedTarget , "high_shadowfiend_Buff" },
		{spells.mindbender,  jps.buffStacks(194249) > 9 , rangedTarget , "high_mindbender_Buff" },
		{spells.mindbender, jps.insanity() < 55 , rangedTarget , "low_mindbender_Buff" },
		
		-- Low Insanity coming up (Shadow Word: Death , Void Bolt , Mind Blast , AND Void Torrent are all on cooldown and you are in danger of reaching 0 Insanity).
		{spells.dispersion, jps.hasTalent(6,3) and jps.insanity() > 21 and jps.insanity() < 100 and jps.cooldown(spells.mindbender) > 51 , "player" , "DISPERSION_Insanity_Mindbender" },
		{spells.dispersion, jps.hasTalent(6,1) and jps.insanity() > 49 and jps.insanity() < 100 and jps.cooldown(spells.powerInfusion) < 6 and jps.buffStacks(194249) > 9 , "player" , "DISPERSION_Insanity_Infusion" },
		--{spells.dispersion, jps.insanity() > 21 and jps.insanity() < 100 and jps.cooldown(spells.voidTorrent) < 6 , "player" , "DISPERSION_Insanity_VoidEruption" },

	}},

	{spells.vampiricTouch, not jps.buff(194249) and not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) < 4 and not jps.isRecast(spells.vampiricTouch,rangedTarget) , rangedTarget , "Refresh_VT_Target" },
	{spells.shadowWordPain, not jps.buff(194249) and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) < 4 and not jps.isRecast(spells.shadowWordPain,rangedTarget) , rangedTarget , "Refresh_Pain_Target" },	

	{spells.voidEruption, not jps.buff(194249) and jps.hasTalent(7,1) and jps.insanity() > 85 and not jps.Moving and isTargetElite  , rangedTarget , "voidEruption" },
	{spells.voidEruption, not jps.buff(194249) and jps.insanity() == 100 and not jps.Moving and isTargetElite , rangedTarget , "voidEruption" },
	
	-- "Déferlante d’ombre" 205385
	--{spells.shadowCrash, jps.hasTalent(6,2) , rangedTarget , "shadowCrash" },

	-- spells.shadowWordDeath
	{"macro", jps.canCastshadowWordDeath , "/stopcasting" },
	{"nested", not jps.buff(194249) , {
		{spells.shadowWordDeath, jps.hp("target") < 0.35 , "target" , "Death" },
		{spells.shadowWordDeath, jps.hp("focus") < 0.35 , "focus" , "Death" },
		{spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death" },
		{spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover" , "Death" },
	}},
	
	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not jps.Moving , rangedTarget , "mindBlast"},

	-- "Shadow Word: Pain"
	{spells.vampiricTouch, not jps.Moving and fnVampEnemyTarget("focus") , "focus" , "VT_Focus" },
	{spells.shadowWordPain, fnPainEnemyTarget("focus") , "focus" , "Pain_Focus" },
	{spells.shadowWordPain, PainEnemyTarget ~= nil and not UnitIsUnit("target",PainEnemyTarget) , PainEnemyTarget , "Pain_MultiUnit" },
	{spells.shadowWordPain, canAttack("mouseover") and fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },

	{spells.mindSear, jps.EnemyCount() > 4 and not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) > 6 and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) > 6 , rangedTarget , "EnemyCount_MindSear" },
	{spells.mindSear, jps.MultiTarget and not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) > 6 and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) > 6 , rangedTarget , "MultiTarget_MindSear" },

	-- "Vampiric Touch" heals the Priest for 50% of damage
	{spells.vampiricTouch, not jps.Moving and VampEnemyTarget ~= nil and not UnitIsUnit("target",VampEnemyTarget) , VampEnemyTarget , "VT_MultiUnit" },
	{spells.vampiricTouch, not jps.Moving and canAttack("mouseover") and fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") and jps.hp("mouseover") > 0.20 , "mouseover" , "VT_Mouseover" },

	{spells.mindSpike, not jps.Moving },
	{spells.mindFlay, not jps.Moving },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default Shadow Priest" )

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

local spellTable = {

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not jps.Moving },
	{spells.mindSear, not jps.Moving and jps.MultiTarget },
	{spells.mindFlay},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Test Shadow Priest")

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

	-- SNM "Levitate" 1706	
	{ 1706, jps.Defensive and jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.Defensive and IsSwimming() and not jps.buff(111759) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", jps.itemCooldown(118922) == 0 , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)