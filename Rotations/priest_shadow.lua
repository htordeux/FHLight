
local spells = jps.spells.priest
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------
--jps.PvP for mouseover which are not UnitAffectingCombat
--jps.Defensive for "Psychic Scream"
--jps.Interrupts for "Silence"
--jps.UseCDs for "Purify Disease"

jps.registerRotation("PRIEST","SHADOW",function()

local spell = nil
local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------
	
local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus()
local LowestImportantUnit = jps.LowestImportantUnit()

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER

local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if canHeal(Tank) then TankTarget = Tank.."target" end
local TankThreat = jps.findThreatInRaid()

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

-- Config FOCUS with MOUSEOVER
if not jps.UnitExists("focus") and canDPS("mouseover") and UnitAffectingCombat("mouseover") then
	-- set focus an enemy targeting you
	if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy in combat
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.vampiricTouch,"mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.shadowWordPain,"mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
	end
end

if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	jps.Macro("/clearfocus")
end

if canDPS("target") then rangedTarget =  "target"
elseif canDPS(TankTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0
local isTargetElite = false
if jps.targetIsBoss("target") then isTargetElite = true
elseif jps.hp("target") > 0.20 then isTargetElite = true
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
		if jps.myDebuffDuration(spells.shadowWordPain,unit) < 3  then
			VoidBoltTarget = unit
		end
	elseif jps.myDebuff(spells.vampiricTouch,unit) then
		if jps.myDebuffDuration(spells.vampiricTouch) < 3 then
			VoidBoltTarget = unit
		end
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
	{ 17, not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" },
	-- "Don des naaru" 59544
	{ 59544, true , "player" },
	-- "Pierre de soins" 5512
	{ "macro", jps.itemCooldown(5512)==0 , "/use item:5512" , "player" },
}

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

	{spells.dispersion, jps.hp("player") < 0.30 },
	{spells.vampiricEmbrace, jps.hp("player") < 0.60 },
	{spells.giftNaaru, jps.hp("player") < 0.80 , "player" },

	-- Opening
	{spells.mindbender, jps.insanity() == 0 and not jps.buff(spells.lingeringInsanity) , rangedTarget , "opening_mindbender" },

	{"macro", jps.canCastvoidEruption , "/stopcasting" },
	-- "Lingering Insanity" 197937 "Délire persistant"
	{"nested", not jps.Moving and isTargetElite and jps.insanity() > 85 and not jps.buff(spells.voidform) , {
		{spells.voidEruption, jps.insanity() == 100 and jps.myDebuffDuration(spells.vampiricTouch) > 4 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.insanity() == 100 and jps.myDebuffDuration(spells.shadowWordPain) > 4 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.insanity() == 100 and jps.buff(spells.lingeringInsanity) and jps.buffDuration(197937) < 6 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.hasTalent(7,1) and jps.myDebuffDuration(spells.shadowWordPain) > 4 and jps.myDebuffDuration(spells.vampiricTouch) > 4 , rangedTarget , "voidEruption" },
		{spells.voidEruption, jps.hasTalent(7,1) and jps.buff(spells.lingeringInsanity) and jps.buffDuration(197937) < 6 , rangedTarget , "voidEruption" },
	}},
	
	{"nested", jps.buff(spells.voidform) , {
		{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, jps.myDebuff(spells.shadowWordPain,rangedTarget) and jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) < 3 , rangedTarget , "voidBold_Target"},
		{spells.voidEruption, jps.myDebuff(spells.vampiricTouch,rangedTarget) and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) < 3 , rangedTarget , "voidBold_Target"},
		{spells.voidEruption, VoidBoltTarget ~= nil , VoidBoltTarget , "voidBold_MultiUnit"},
    	{spells.voidEruption, jps.myDebuff(spells.shadowWordPain,"mouseover") and jps.myDebuffDuration(spells.shadowWordPain,"mouseover") < 3 , "mouseover" , "voidBold_mouseover"},
    	{spells.voidEruption, jps.myDebuff(spells.vampiricTouch,"mouseover") and jps.myDebuffDuration(spells.vampiricTouch,"mouseover") < 3 , "mouseover" , "voidBold_mouseover"},
    	{spells.voidEruption, true , rangedTarget , "voidBold_Buff"},
    	-- spells.voidTorrent
    	{spells.voidTorrent , not jps.Moving and jps.insanity() < 70 and jps.cooldown(spells.mindBlast) > 0 and not jps.isUsableSpell(spells.shadowWordDeath) , rangedTarget , "voidTorrent_Buff"},
   		-- spells.mindbender
		{spells.mindbender,  jps.buffStacks(spells.voidform) > 10 , rangedTarget , "high_mindbender_Buff" },
		{spells.mindbender, jps.insanity() < 50 , rangedTarget , "low_mindbender_Buff" },
		-- Low Insanity coming up (Shadow Word: Death , Void Bolt , Mind Blast , AND Void Torrent are all on cooldown and you are in danger of reaching 0 Insanity).
		{spells.dispersion, jps.insanity() < 50 and jps.cooldown(spells.mindbender) > 50 and jps.cooldown(spells.voidTorrent) > 0 and jps.cooldown(spells.mindBlast) > 0 and not jps.isUsableSpell(spells.shadowWordDeath) , "player" , "DISPERSION_insanity" },
	}},

    -- spells.shadowWordDeath
	{"macro", jps.canCastshadowWordDeath , "/stopcasting" },
	{"nested", jps.spellCharges(spells.shadowWordDeath) == 2 , {
		{spells.shadowWordDeath, jps.hp("target") < 0.35 , "target" , "Death2_Buff" },
		{spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death2_Buff" },
		{spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover" , "Death2_Buff" },
	}},
	{"nested", jps.spellCharges(spells.shadowWordDeath) < 2 and not jps.buff(spells.voidform) , {
		{spells.shadowWordDeath, jps.hp("target") < 0.35 , "target" , "Death" },
		{spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death" },
		{spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover" , "Death" },
	}},
	{"nested", jps.spellCharges(spells.shadowWordDeath) < 2 and jps.buff(spells.voidform) and jps.insanity() < 70  , {
		{spells.shadowWordDeath, jps.hp("target") < 0.35 , "target" , "Death1_Buff" },
		{spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death1_Buff" },
		{spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover" , "Death1_Buff" },
	}},

	-- interrupts --
	{spells.fade, jps.hp("player") < 0.60 and jps.playerIsTargeted() },
	{spells.silence, jps.Interrupts and SilenceEnemyTarget ~= nil , SilenceEnemyTarget , "Silence_MultiUnit_Target" },
	-- "Psychic Scream" 8122 "Cri psychique"  -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{spells.psychicScream, jps.Defensive and jps.IsCasting(rangedTarget) and jps.canFear(rangedTarget) and jps.cooldown(spells.silence) > 0 , rangedTarget },

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast , not jps.Moving , rangedTarget , "mindBlast"},
	{spells.mindSear, jps.MultiTarget and not jps.Moving and jps.myDebuffDuration(spells.shadowWordPain) > 4 and jps.myDebuffDuration(spells.vampiricTouch) > 4 },
	
	{spells.powerWordShield, jps.IncomingDamage("player") > 0 and jps.hp("player") < 0.60 and not jps.buff(spells.powerWordShield) , "player" },
	-- "Purify Disease" 213634
	{spells.purifyDisease, jps.UseCDs and jps.canDispel("player","Disease") , "player" , "Disease" },
	{spells.purifyDisease, jps.UseCDs and jps.canDispel("player",Tank) , Tank },
	
	{spells.shadowWordPain, canAttack("mouseover") and fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },
	{spells.shadowWordPain, jps.PvP and fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },
	
	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) < 3 and not jps.isRecast(spells.vampiricTouch,rangedTarget) , rangedTarget , "Refresh_VT_Target" },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) < 3 and not jps.isRecast(spells.shadowWordPain,rangedTarget) , rangedTarget , "Refresh_Pain_Target" },
	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,"focus") < 3 and not jps.isRecast(spells.vampiricTouch,"focus") , "focus" , "Refresh_VT_Focus" },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,"focus") < 3 and not jps.isRecast(spells.shadowWordPain,"focus") , "focus" , "Refresh_Pain_Focus" },
	{spells.vampiricTouch, not jps.Moving and VampEnemyTarget ~= nil and not UnitIsUnit("target",VampEnemyTarget) , VampEnemyTarget , "VT_MultiUnit" },
	{spells.shadowWordPain, PainEnemyTarget ~= nil and not UnitIsUnit("target",PainEnemyTarget) , PainEnemyTarget , "Pain_MultiUnit" },
	
	{spells.shadowMend, not jps.Moving and jps.hp("player") < 0.80 and jps.cooldown(spells.vampiricEmbrace) > 0 and jps.castEverySeconds(spells.shadowMend, 4), "player" , "shadowMendPlayer" },
	
	{spells.vampiricTouch, canAttack("mouseover") and not jps.Moving and fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "VT_Mouseover" },
	{spells.vampiricTouch, jps.PvP and not jps.Moving and fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "VT_Mouseover" },

	{spells.powerWordShield, jps.IncomingDamage(Tank) > 0 and jps.hp(Tank) < 0.80 and not jps.buff(spells.powerWordShield,Tank) , Tank },
	{spells.shadowMend, not jps.Moving and jps.hp(Tank) < 0.40 and jps.cooldown(spells.vampiricEmbrace) > 0 and jps.castEverySeconds(spells.shadowMend, 4), Tank , "shadowMendTank" },

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

local spell = nil
local target = nil

if canDPS("target") then rangedTarget =  "target"
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canDPS("focustarget") then rangedTarget = "focustarget"
end

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

--if canDPS("target") then rangedTarget =  "target"
--elseif canDPS("targettarget") then rangedTarget = "targettarget"
--elseif canDPS("focustarget") then rangedTarget = "focustarget"
--end

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

	-- rangedTarget returns "target" by default
	local rangedTarget, _, _ = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	if jps.ChannelTimeLeft() > 0 then return nil end
	if jps.CastTimeLeft() > 0 then return nil end
	
	local spellTable = {

	-- SNM "Levitate" 1706	
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, IsSwimming() and not jps.buff(111759) , "player" },
	
	-- "Don des naaru" 59544
	{ 59544, jps.hp("player") < 0.75 , "player" },
	-- "Shield" 17 "Body and Soul" 64129 -- figure out how to speed buff everyone as they move
	{ 17, jps.Moving and jps.hasTalent(2,2) and not jps.buff(17,"player") , "player" , "Shield_BodySoul" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	--{ "macro", jps.itemCooldown(118922) == 0 , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)