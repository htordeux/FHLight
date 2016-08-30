
local L = MyLocalizationTable
local spells = jps.spells.priest
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.CanAttack
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit

-- Debuff EnemyTarget NOT DPS
local DebuffUnitCyclone = function (unit)
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			return true
		elseif strfind(auraName,L["Cyclone"]) then
			return true
		elseif strfind(auraName,L["Hex"]) then
			return true
		end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i))
	end
	return false
end


------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

local spell = nil
local target = nil
	
local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus()
local playermana = jps.roundValue(UnitPower("player",0)/UnitPowerMax("player",0),2)
local Orbs = UnitPower("player",13) -- SPELL_POWER_SHADOW_ORBS 	13
local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if canHeal(Tank) then TankTarget = Tank.."target" end
local TankThreat = jps.findThreatInRaid()
	
---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()
local isBoss = (UnitLevel("target") == -1) or (UnitClassification("target") == "elite")
local enemyHealer = jps.LowestTargetHealer()

-- Config FOCUS with MOUSEOVER
if not jps.UnitExists("focus") and canDPS("mouseover") and UnitAffectingCombat("mouseover") then
	-- set focus an enemy targeting you
	if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		--print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy healer
	elseif jps.EnemyHealer("mouseover") then
		jps.Macro("/focus mouseover")
		--print("Enemy HEALER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy in combat
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") and not jps.myDebuff(589,"mouseover") then
		jps.Macro("/focus mouseover")
		--print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		--print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end

-- CONFIG jps.getConfigVal("keep focus") if you want to keep focus
if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	if jps.getConfigVal("keep focus") == false then jps.Macro("/clearfocus") end
end

if canDPS("target") and jps.CanAttack("target") then rangedTarget =  "target"
elseif canDPS(TankTarget) and jps.CanAttack(TankTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") and jps.CanAttack("targettarget") then rangedTarget = "targettarget"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

local playerIsTargeted = jps.playerIsTargeted()

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

-- take care if "focus" not Polymorph and not Cyclone
if canDPS("focus") and not DebuffUnitCyclone("focus") then EnemyUnit[#EnemyUnit+1] = "focus" end

local fnMindSpike = function(unit)
	if jps.Moving then return false end
	if jps.buff(132573) then return false end
	if jps.myDebuff(34914,unit) then return false end
	if jps.myDebuff(589,unit) then return false end
	return true
end

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

local SilenceEnemyTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.IsSpellInRange(15487,unit) then
		if jps.ShouldKick(unit) then
			SilenceEnemyTarget = unit
		break end
	end
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

local MindSpikeTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if fnMindSpike(unit) then
		MindSpikeTarget = unit
	break end
end

local DispelOffensiveTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.DispelOffensive(unit) then
		DispelOffensiveTarget = unit
	break end
end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

-- jps.unitForLeap includes jps.FriendAggro and jps.LoseControl
local LeapFriend = nil
for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
	local unit = FriendUnit[i]
	if jps.unitForLeap(unit) and jps.hp(unit) < 0.25 then 
		LeapFriend = unit
	break end
end

-- if jps.debuffDuration(114404,"target") > 18 and jps.UnitExists("target") then MoveBackwardStart() end
-- if jps.debuffDuration(114404,"target") < 18 and jps.debuff(114404,"target") and jps.UnitExists("target") then MoveBackwardStop() end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- SPELLSTOPCASTING
----------------------------------------------------------

if jps.buff(47585,"player") then return end -- "Dispersion" 47585

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
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, jps.canFear(rangedTarget) , rangedTarget },
}

local parseControlFocus = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, jps.canFear("focus") , "focus" , "Fear_focus" },
	-- "Silence" 15487
	{ 15487, jps.IsSpellInRange(15487,"focus") , "focus" , "Silence_focus" },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.IsSpellInRange(64044,"focus") , "focus" , "Horror_focus" },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, jps.canFear("focus") , "focus" },
}

local parseHeal = {
	-- "Power Word: Shield" 17	
	{ 17, not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" },
	-- "Don des naaru" 59544
	{ 59544, true , "player" },
	-- "Prière du désespoir" 19236
	{ 19236, jps.IsSpellKnown(19236) , "player" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.itemCooldown(5512)==0 , "player" },
	-- "Prière de guérison" 33076 -- Buff POM 41635
	--{ 33076, not jps.Moving and not jps.buff(41635,"player") , "player" },
	-- "Soins rapides" 2061
	--{ 2061, not jps.Moving and jps.hp("player") < 0.50 , "player" , "FlashHeal" },
}

local RacialCounters = {
	-- Undead "Will of the Forsaken" 7744 -- SNM priest is undead ;)
	{ 7744, jps.debuff("psychic scream","player") }, -- Fear
	{ 7744, jps.debuff("fear","player") }, -- Fear
	{ 7744, jps.debuff("intimidating shout","player") }, -- Fear
	{ 7744, jps.debuff("howl of terror","player") }, -- Fear
	{ 7744, jps.debuff("mind control","player") }, -- Charm
	{ 7744, jps.debuff("seduction","player") }, -- Charm
	{ 7744, jps.debuff("wyvern sting","player") }, -- Sleep
}

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

	{spells.powerWordShield, jps.hp("player") < 0.75 , "player"},
	{spells.shadowMend, jps.hp("player") < 0.75 and not jps.buff(spells.masochism) }, -- Guerison de l'ombre
	{spells.fade, jps.hp("player") < 0.50 , "player"},
	{spells.vampiricEmbrace, jps.hp("player") < 0.50 },

	-- interrupts
	{spells.silence, SilenceEnemyTarget ~= nil , SilenceEnemyTarget , "Silence_MultiUnit_Target" },

	{"macro", jps.canCastshadowWordDeath , "/stopcasting" }, --not fully tested
	{ spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death_MultiUnit" },
	{ spells.shadowWordDeath, jps.hp(rangedTarget) < 0.35 , rangedTarget, "Death_Target" },
	{ spells.shadowWordDeath, jps.hp("focus") < 0.35 , "focus", "Death_Focus" },
	{ spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover", "Death_Mouseover" },
	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{ spells.mindBlast}, 
	{ spells.mindSear, not jps.Moving and jps.MultiTarget and not jps.buff(spells.voidform) },

	{"nested", jps.buff(spells.voidform), {
    {"macro", jps.canCastvoidEruption , "/stopcasting" }, --not fully tested
    {spells.voidTorrent , jps.shadowOrbs() < 85 , "target" , "voidTorrent_Buff"},
	{spells.voidEruption, jps.shadowOrbs() < 85 , "target" , "voidBold_Buff"},
	{spells.mindbender, jps.buffStacks(spells.voidform) <= 5 , "target" , "mindbender5" },
	{spells.mindbender, jps.buffStacks(spells.voidform) >= 15 , "target", "mindbender15" },
	{spells.shadowWordDeath, jps.hp("target") < 0.35 and jps.spellCharges(spells.shadowWordDeath) == 2 and jps.shadowOrbs() < 70 , "target"},
	{spells.shadowWordDeath, jps.hp("target") < 0.35 and jps.spellCharges(spells.shadowWordDeath) >0  and jps.shadowOrbs() < 30 , "target"},
	{spells.shadowWordPain, fnPainEnemyTarget(rangedTarget) , rangedTarget , "Pain_Target" },
	{spells.shadowWordPain, fnPainEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "Pain_focus" },
	{spells.shadowWordPain, fnPainEnemyTarget(rangedTarget) , rangedTarget , "Pain_Target" },
	{spells.shadowWordPain, fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },
	{spells.vampiricTouch, fnVampEnemyTarget(rangedTarget) , rangedTarget , "VT_Target" },
	{spells.mindSear, not jps.Moving and jps.MultiTarget },
	{spells.mindFlay, true , "target" , "mindFlay_Buff"},
}},

--DPS
	{spells.voidEruption, jps.shadowOrbs() >= 70 and (jps.myDebuffDuration(spells.shadowWordPain) >= 5 and jps.myDebuffDuration(spells.vampiricTouch) >= 5) , "target" , "spells.voidEruption_UnBuff" },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain) <= 4.2 and not jps.isRecast(spells.shadowWordPain,"target")},
	{spells.vampiricTouch, jps.myDebuffDuration(spells.vampiricTouch) <= 5.4 and not jps.isRecast(spells.vampiricTouch,"target")},
	
	-- "Shadow Word: Pain" 589
	{spells.shadowWordPain, fnPainEnemyTarget(rangedTarget) , rangedTarget , "Pain_Target" },
	{spells.shadowWordPain, fnPainEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "Pain_focus" },
	{spells.shadowWordPain, PainEnemyTarget ~= nil and not UnitIsUnit("target",PainEnemyTarget) , PainEnemyTarget , "Pain_MultiUnit" },
	{spells.shadowWordPain, fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },

	-- "Vampiric Touch" 34914
	{ "nested", not jps.Moving , {
		{spells.vampiricTouch, fnVampEnemyTarget(rangedTarget) , rangedTarget , "VT_Target" },
		{spells.vampiricTouch, fnVampEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "VT_focus" },
		{spells.vampiricTouch, VampEnemyTarget ~= nil and not UnitIsUnit("target",VampEnemyTarget) , VampEnemyTarget , "VT_MultiUnit" },
		{spells.vampiricTouch, fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "VT_Mouseover" },
	}},

	{spells.mindFlay},

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Shadow Priest Default" )

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

local spell = nil
local target = nil

if canDPS("target") then rangedTarget =  "target"
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canDPS("focustarget") then rangedTarget = "focustarget"
end

--if jps.canCastMindBlast() then
--	SpellStopCasting()
--	write("SpellStopCasting")
--end

local spellTable = {
	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, true },
	{spells.mindSear, not jps.Moving and jps.MultiTarget },
	--{spells.mindFlay},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Test Shadow Priest")

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

	-- rangedTarget returns "target" by default
	local rangedTarget, _, _ = jps.LowestTarget()
	local Orbs = UnitPower("player",13) -- SPELL_POWER_SHADOW_ORBS 	13

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	if jps.ChannelTimeLeft() > 0 then return nil end
	if jps.CastTimeLeft() > 0 then return nil end
	
	local spellTableOOC = {

	-- SNM "Levitate" 1706	
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, IsSwimming() and not jps.buff(111759) , "player" },

	-- "Semblance spectrale" 112833 "Spectral Guise" gives buff 119032
	{"nested", jps.buff(119032) , {
		-- "Mind Blast" 8092
		{ 8092, true , rangedTarget , "Blast_CD" },
		-- "Mind Flay" 15407
		{ 15407, true , rangedTarget , "Fouet_Mental" },
	}},
	
	-- "Fortitude" 21562 -- "Commanding Shout" 469 -- "Blood Pact" 166928
	{ 21562, jps.buffMissing(21562) and jps.buffMissing(469) and jps.buffMissing(166928) , "player" },
	-- "Gardien de peur" 6346
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Don des naaru" 59544
	{ 59544, jps.hp("player") < 0.75 , "player" },
	-- "Shield" 17 "Body and Soul" 64129 -- figure out how to speed buff everyone as they move
	{ 17, jps.Moving and jps.IsSpellKnown(64129) and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Shield_BodySoul" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ {"macro","/use item:118922"},  not jps.buff(176151) and jps.itemCooldown(118922) == 0 and not jps.buff(156070) and not jps.buff(156079) , "player" , "Item_Oralius"},
	-- "Flacon d’Intelligence draenique" jps.buff(156070)
	-- "Flacon d’Intelligence supérieure draenique" jps.buff(156079)

}

	local spell,target = parseSpellTable(spellTableOOC)
	return spell,target

end,"OOC Shadow Priest",false,false,true)

-- Surge of Darkness
-- Your Vampiric Touch and Devouring Plague damage has a 10% chance to cause your next Mind Spike not to consume your damage over time effects
-- be instant, and deal 50% additional damage. Can accumulate up to 3 charges.

-- Shadowy Insight
-- Your Shadow Word: Pain damage over time and Mind Spike damage has a 5% chance to reset the cooldown on Mind Blast and make your next Mind Blast instant.

-- Shadow Word: Pain
-- causes (47.5% of Spell power) Shadow damage and an additional (285% of Spell power) Shadow damage over 18 sec.

-- Vampiric Touch
-- Causes (292.5% of Spell power) Shadow damage over 15 sec. If Vampiric Touch is dispelled, the dispeller flees in Horror for 3 sec.