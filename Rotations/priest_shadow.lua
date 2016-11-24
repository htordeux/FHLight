
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
--jps.PvP for mouseover which are not UnitAffectingCombat and for Power Infusion
--jps.Defensive for "Psychic Scream"
--jps.Interrupts for "Silence"
--jps.UseCDs for "Purify Disease"

jps.registerRotation("PRIEST","SHADOW",function()

local spell = nil
local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------
	
local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.80)
local LowestImportantUnit = jps.LowestImportantUnit()

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER

local Tank,TankUnit = jps.findTankInRaid() -- default "focus" "player"
local TankTarget = Tank.."target"
local TankThreat = jps.findThreatInRaid() -- default "focus" "player"

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
local isTargetElite = false
if jps.targetIsBoss("target") then isTargetElite = true
elseif jps.hp("target") > 0.20 then isTargetElite = true
elseif string.find(GetUnitName("target"),"Mannequin") then isTargetElite = true
end

local damageIncoming = jps.IncomingDamage() - jps.IncomingHeal()
local playerIsTargeted = jps.playerIsTargeted()

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

local SilenceEnemyTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.IsSpellInRange(15487,unit) then
		if jps.ShouldKick(unit) then
			SilenceEnemyTarget = unit
		break end
	end
end

local VoidBoltTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.myDebuff(spells.shadowWordPain,unit) then 
		VoidBoltTarget = unit
	elseif jps.myDebuff(spells.vampiricTouch,unit) then
		VoidBoltTarget = unit
	break end
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

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- SPELLSTOPCASTING
----------------------------------------------------------

if jps.buff(47585,"player") then return end -- "Dispersion" 47585
local canCastShadowWordDeath = isUsableShadowWordDeath()

-- "Mind Flay" 15407 -- "Mind Blast" 8092 -- buff 81292 "Glyph of Mind Spike"
-- "Insanity" 129197 -- buff "Shadow Word: Insanity" 132573

-------------------------------------------------------------
------------------------ TABLES
-------------------------------------------------------------

local parseControl = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, jps.canFear(rangedTarget) , rangedTarget },
	-- "Silence" 15487
	{ 15487, jps.IsSpellInRange(15487,rangedTarget) , rangedTarget },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.IsSpellInRange(64044,rangedTarget) , rangedTarget },
}

local parseControlFocus = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, jps.canFear("focus") , "focus" , "Fear_focus" },
	-- "Silence" 15487
	{ 15487, jps.IsSpellInRange(15487,"focus") , "focus" , "Silence_focus" },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.IsSpellInRange(64044,"focus") , "focus" , "Horror_focus" },
}

local parseHeal = {
	-- "Power Word: Shield" 17	
	{spells.powerWordShield, not jps.buff(spells.powerWordShield) , "player" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, true , "player" },
	-- "Guérison de l’ombre" 186263
	{spells.shadowMend, not jps.Moving and not jps.buff(spells.voidForm) and jps.castEverySeconds(186263, 4) , "player" , "shadowMendPlayer" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.60 and jps.itemCooldown(5512) == 0 , "/use item:5512" },
}

-----------------------------
-- SPELLTABLE
-----------------------------

if not UnitCanAttack("player", "target") then return end

local spellTable = {

	{spells.dispersion, jps.hp("player") < 0.40 },
	{spells.vampiricEmbrace, jps.hp("player") < 0.60 }, -- buff 15286
	{spells.vampiricEmbrace, CountInRange > 2 and AvgHealthLoss < 0.80 },
	{"nested", jps.hp("player") < 0.80 and not jps.buff(15286) , parseHeal },
	
	{spells.powerWordShield, jps.hp(Tank) < 0.50 and not jps.buff(spells.powerWordShield,Tank) , Tank , "shield_Tank" },
	{spells.powerWordShield, not jps.Moving and canHeal("mouseover") and jps.hp("mouseover") < 0.50 , "mouseover" , "shield_Mouseover" },
	-- "Guérison de l’ombre" 186263
	{spells.shadowMend, not jps.Moving and not jps.buff(spells.voidForm) and jps.hp(Tank) < 0.50 and jps.castEverySeconds(186263, 4) , Tank , "shadowMend_Tank" },
	{spells.shadowMend, not jps.Moving and not jps.buff(spells.voidForm) and canHeal("mouseover") and jps.hp("mouseover") < 0.50 and jps.castEverySeconds(186263, 4) , "mouseover" , "shadowMend_Mouseover" },
	
	-- interrupts --
	{spells.fade, not jps.PvP and jps.FriendAggro("player") },
	{spells.silence, jps.Interrupts and SilenceEnemyTarget ~= nil , SilenceEnemyTarget , "Silence_MultiUnit_Target" },
	-- "Psychic Scream" 8122 "Cri psychique"  -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{spells.psychicScream, jps.Defensive and jps.IsCasting(rangedTarget) and jps.canFear(rangedTarget) , rangedTarget },
	-- "Mind Bomb" 205369 -- 30 yd range
	{spells.mindBomb, jps.IsCasting(rangedTarget) , rangedTarget },
	{spells.mindBomb, jps.MultiTarget , rangedTarget },

	-- Opening
	{spells.mindbender, jps.insanity() < 21 and not jps.buff(spells.lingeringInsanity) and not jps.buff(spells.voidform) },
	-- "Power Infusion" 10060
	{spells.powerInfusion, jps.insanity() < 90 and jps.buffStacks(spells.voidForm) > 11 },

	-- "Purify Disease" 213634
	{spells.purifyDisease, jps.UseCDs and jps.canDispel("player","Disease") , "player" },
	{spells.purifyDisease, jps.UseCDs and jps.canDispel(Tank,"Disease") , Tank },
	{spells.purifyDisease, jps.UseCDs and jps.canDispel("mouseover","Disease") , "mouseover" },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", jps.PvP and jps.hp(LowestImportantUnit) > 0.60 , {
		{ spells.dispelMagic, jps.castEverySeconds(528,8) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
		{ spells.dispelMagic, jps.castEverySeconds(528,8) and DispelOffensiveEnemyTarget ~= nil  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },
	}},
	
	-- SNM "Levitate" 1706	
	{ 1706, jps.Defensive and jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.Defensive and IsSwimming() and not jps.buff(111759) , "player" },

	{"nested", jps.buff(spells.voidForm) , {
		{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, jps.myDebuff(spells.shadowWordPain,rangedTarget) and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) < 3 , rangedTarget , "voidBold_Target"},
		{spells.voidEruption, jps.myDebuff(spells.vampiricTouch,rangedTarget) and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) < 3 , rangedTarget , "voidBold_Target"},
		{spells.voidEruption, jps.myDebuff(spells.shadowWordPain,"focus") and jps.myDebuffDuration(spells.shadowWordPain,"focus") < 3 , "focus" , "voidBold_Focus"},
		{spells.voidEruption, jps.myDebuff(spells.vampiricTouch,"focus") and jps.myDebuffDuration(spells.vampiricTouch,"focus") < 3 , "focus" , "voidBold_Focus"},
    	{spells.voidEruption, jps.myDebuff(spells.shadowWordPain,"mouseover") and jps.myDebuffDuration(spells.shadowWordPain,"mouseover") < 3 , "mouseover" , "voidBold_Mouseover"},
    	{spells.voidEruption, jps.myDebuff(spells.vampiricTouch,"mouseover") and jps.myDebuffDuration(spells.vampiricTouch,"mouseover") < 3 , "mouseover" , "voidBold_Mouseover"},
	}},

	{"nested", jps.buff(spells.voidForm) , {

		{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, VoidBoltTarget ~= nil , VoidBoltTarget , "voidBold_MultiUnit"},

    	{spells.shadowWordDeath, jps.insanity() < 70 and jps.hp("target") < 0.35 , "target" , "Death1_Buff" },
		{spells.shadowWordDeath, jps.insanity() < 70 and  DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death1_Buff" },
		{spells.shadowWordDeath, jps.insanity() < 70 and jps.hp("mouseover") < 0.35 , "mouseover" , "Death1_Buff" },
		
	    {spells.mindSear, jps.MultiTarget and not jps.Moving and jps.cooldown(spells.voidTorrent) > 4 },
		
        {spells.voidTorrent , not jps.Moving and jps.insanity() < 90 and not canCastShadowWordDeath , rangedTarget , "voidTorrent"},
       	{spells.voidTorrent , not jps.Moving and jps.insanity() < 90 and jps.LastMessage == "mindBlast" , rangedTarget , "voidTorrent_mindBlast"},
    	{"macro", jps.canCastMindBlast , "/stopcasting" },
		{spells.mindBlast , not jps.Moving , rangedTarget , "mindBlast" },

   		-- spells.mindbender
   		{spells.shadowfiend, jps.buffStacks(spells.voidForm) > 9 , rangedTarget , "high_shadowfiend_Buff" },
		{spells.mindbender,  jps.buffStacks(spells.voidForm) > 9 , rangedTarget , "high_mindbender_Buff" },
		{spells.mindbender, jps.insanity() < 55 , rangedTarget , "low_mindbender_Buff" },
		
		-- Low Insanity coming up (Shadow Word: Death , Void Bolt , Mind Blast , AND Void Torrent are all on cooldown and you are in danger of reaching 0 Insanity).
		{spells.dispersion, jps.hasTalent(6,3) and jps.insanity() > 21 and jps.insanity() < 55 and jps.cooldown(spells.mindbender) > 51 , "player" , "DISPERSION_insanity" },
		{spells.dispersion, jps.hasTalent(6,1) and jps.insanity() > 21 and jps.insanity() < 55 and jps.cooldown(spells.powerInfusion) < 7 , "player" , "DISPERSION_insanity" },

	}},
	
	{"macro", jps.canCastvoidEruption , "/stopcasting" },
	-- "Lingering Insanity" 197937 "Délire persistant"
	{"nested", not jps.Moving and isTargetElite and jps.insanity() > 85 and not jps.buff(spells.voidform) , {
		{spells.voidEruption, jps.insanity() == 100 and jps.myDebuffDuration(spells.vampiricTouch) > 4 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.insanity() == 100 and jps.myDebuffDuration(spells.shadowWordPain) > 4 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.insanity() == 100 and jps.buff(spells.lingeringInsanity) and jps.buffDuration(197937) < 4 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.hasTalent(7,1) and jps.myDebuffDuration(spells.shadowWordPain) > 4 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.hasTalent(7,1) and jps.myDebuffDuration(spells.vampiricTouch) > 4 , rangedTarget , "voidEruption" },
	}},

	-- spells.shadowWordDeath
	{"macro", jps.canCastshadowWordDeath , "/stopcasting" },
	{"nested", jps.spellCharges(spells.shadowWordDeath) == 2 , {
		{spells.shadowWordDeath, jps.hp("target") < 0.35 , "target" , "Death2_Buff" },
		{spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death2_Buff" },
		{spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover" , "Death2_Buff" },
	}},
	{"nested", jps.spellCharges(spells.shadowWordDeath) < 2 and not jps.buff(spells.voidForm) , {
		{spells.shadowWordDeath, jps.hp("target") < 0.35 , "target" , "Death" },
		{spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death" },
		{spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover" , "Death" },
	}},
	
	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not jps.Moving , rangedTarget , "mindBlast"},
	--{spells.mindSear, jps.MultiTarget and not jps.Moving },

	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) < 3 and not jps.isRecast(spells.vampiricTouch,rangedTarget) , rangedTarget , "Refresh_VT_Target" },
	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,"focus") < 3 and not jps.isRecast(spells.vampiricTouch,"focus") , "focus" , "Refresh_VT_Focus" },	
	{spells.vampiricTouch, not jps.Moving and VampEnemyTarget ~= nil and not UnitIsUnit("target",VampEnemyTarget) , VampEnemyTarget , "VT_MultiUnit" },

	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) < 3 and not jps.isRecast(spells.shadowWordPain,rangedTarget) , rangedTarget , "Refresh_Pain_Target" },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,"focus") < 3 and not jps.isRecast(spells.shadowWordPain,"focus") , "focus" , "Refresh_Pain_Focus" },
	{spells.shadowWordPain, PainEnemyTarget ~= nil and not UnitIsUnit("target",PainEnemyTarget) , PainEnemyTarget , "Pain_MultiUnit" },

	{spells.shadowWordPain, canDPS("mouseover") and fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },
	{spells.vampiricTouch, canDPS("mouseover") and not jps.Moving and fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "VT_Mouseover" },

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
	
	{spells.dispersion, jps.Defensive and jps.insanity() > 55 , "player" , "DISPERSION_insanity_OOC" },
	
	-- "Shield" 17 "Body and Soul" 64129 "Corps et âme" -- Vitesse de déplacement augmentée de 40% -- buff 65081
	{ 17, jps.Moving and not jps.buff(17,"player") and jps.hasTalent(2,2) , "player" , "Shield_BodySoul" },
	{ "macro", not jps.buff(65081) and jps.Moving and jps.buff(17) and jps.hasTalent(2,2) , "/cancelaura "..Shield },

	-- SNM "Levitate" 1706	
	{ 1706, jps.Defensive and jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.Defensive and IsSwimming() and not jps.buff(111759) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	--{ "macro", jps.itemCooldown(118922) == 0 , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)