
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

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

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
local isBoss = (UnitLevel("target") == -1) or (UnitClassification("target") == "elite")
local enemyHealer = jps.LowestTargetHealer()

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

if canDPS("target") and jps.CanAttack("target") then rangedTarget =  "target"
elseif canDPS(TankTarget) and jps.CanAttack(TankTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") and jps.CanAttack("targettarget") then rangedTarget = "targettarget"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

-- take care if "focus" not Polymorph and not Cyclone
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

local DispelOffensiveTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.DispelOffensive(unit) then
		DispelOffensiveTarget = unit
	break end
end

local VoidBoltTarget = nil
for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
	local unit = EnemyUnit[i]
	if jps.myDebuff(spells.shadowWordPain,unit) then 
		if jps.myDebuffDuration(spells.shadowWordPain,unit) < 4  then
			VoidBoltTarget = unit
		end
	elseif jps.myDebuff(spells.vampiricTouch,unit) then
		if jps.myDebuffDuration(spells.vampiricTouch) < 4 then
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
	{ {"macro","/use item:5512"}, jps.itemCooldown(5512)==0 , "player" },
}

-----------------------------
-- SPELLTABLE
-----------------------------
-- jps.UseCDs spells.purifyDisease
-- jps.Interrupts spells.silence spells.psychicScream

local spellTable = {

	-- "Shield" 17 "Body and Soul" 64129 -- figure out how to speed buff everyone as they move
	{spells.dispersion, jps.hp("player") < 0.25 , "player"},
	{spells.fade, jps.hp("player") < 0.50 and jps.FriendAggro("player") , "player"},
	{spells.fade, jps.hp("player") < 0.50 and jps.playerIsTargeted() , "player"},
	{spells.powerWordShield, jps.IncomingDamage("player") > 0 , "player"},
	{spells.giftNaaru, jps.hp("player") < 0.80 , "player" },
	{spells.vampiricEmbrace, jps.hp("player") < 0.60 },
	{spells.shadowMend, jps.hp("player") < 0.60 and jps.cooldown(spells.vampiricEmbrace) > 0 and jps.castEverySeconds(spells.shadowMend, 4), "player" },

	{spells.purifyDisease, jps.UseCDs and jps.canDispel("player","Disease") , "player" , "Disease" },

	-- interrupts -- 
	{"nested", jps.Interrupts , {
		{spells.silence, SilenceEnemyTarget ~= nil , SilenceEnemyTarget , "Silence_MultiUnit_Target" },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{spells.psychicScream, jps.IsCasting(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) and jps.cooldown(spells.silence) > 0 , rangedTarget },
	}},

	{ spells.shadowWordDeath, DeathEnemyTarget ~= nil and not jps.isUsableSpell(jps.spells.priest.voidEruption) , DeathEnemyTarget , "Death_MultiUnit" },
	{ spells.shadowWordDeath, jps.hp(rangedTarget) < 0.35 and not jps.isUsableSpell(jps.spells.priest.voidEruption) , rangedTarget, "Death_Target" },
	{ spells.shadowWordDeath, jps.hp("focus") < 0.35 and not jps.isUsableSpell(jps.spells.priest.voidEruption) , "focus", "Death_Focus" },
	{ spells.shadowWordDeath, jps.hp("mouseover") < 0.35 and not jps.isUsableSpell(jps.spells.priest.voidEruption) , "mouseover", "Death_Mouseover" },

	{ spells.mindSear, not jps.Moving and jps.MultiTarget and not jps.buff(spells.voidform) and jps.insanity() < 70 and jps.hasTalent(7,1) },
	{ spells.mindSear, not jps.Moving and jps.MultiTarget and not jps.buff(spells.voidform) and jps.insanity() < 100 and not jps.hasTalent(7,1) },

	{"nested", jps.buff(spells.voidform), {
	-- Void Bolt
    {"macro", jps.canCastvoidEruption , "/stopcasting" },
    {spells.voidEruption, jps.myDebuff(spells.shadowWordPain,"mouseover") and jps.myDebuffDuration(spells.shadowWordPain,"mouseover") < 4 , "mouseover" , "voidBold_mouseover"},
    {spells.voidEruption, jps.myDebuff(spells.vampiricTouch,"mouseover") and jps.myDebuffDuration(spells.vampiricTouch,"mouseover") < 4 , "mouseover" , "voidBold_mouseover"},
    {spells.voidEruption, VoidBoltTarget ~= nil , VoidBoltTarget , "voidBold_MultiUnit"},
	{spells.voidEruption, true , rangedTarget , "voidBold_Target"},

	{spells.voidTorrent , true , rangedTarget , "voidTorrent_Buff"},
	-- spells.mindbender jps.buffStacks(spells.voidform)
	{spells.mindbender,  jps.buffStacks(spells.voidform) > 10 , rangedTarget , "high_mindbender_Buff" },
	-- spells.shadowWordDeath 
	{"macro", jps.canCastshadowWordDeath , "/stopcasting" },
	{"nested", jps.spellCharges(spells.shadowWordDeath) == 2 , {
		{spells.shadowWordDeath, jps.hp("target") < 0.35 , "target" , "Death_Buff" },
		{spells.shadowWordDeath, jps.hp("focus") < 0.35 , "focus" , "Death_Buff" },
		{spells.shadowWordDeath, DeathEnemyTarget ~= nil , DeathEnemyTarget , "Death_Buff" },
		{spells.shadowWordDeath, jps.hp("mouseover") < 0.35 , "mouseover" , "Death_Buff" },
	}},
	{spells.shadowWordDeath, DeathEnemyTarget ~= nil and jps.spellCharges(spells.shadowWordDeath) == 1 and jps.cooldown(spells.mindBlast) > 0 and jps.insanity() < 70 , DeathEnemyTarget , "Death_MultiUnit_Buff" },

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast , not jps.Moving , rangedTarget , "mindBlast_Buff"},

	{spells.vampiricTouch, not jps.Moving and fnVampEnemyTarget(rangedTarget) , rangedTarget , "VT_Target_Buff" },	
	{spells.shadowWordPain, fnPainEnemyTarget(rangedTarget) , rangedTarget , "Pain_Target_Buff" },

	{spells.vampiricTouch, not jps.Moving and fnVampEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "VT_focus_Buff" },
	{spells.shadowWordPain, fnPainEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "Pain_focus_Buff" },
	
	{spells.mindbender,  jps.buffStacks(spells.voidform) > 0 and jps.insanity() < 50 , rangedTarget , "low_mindbender_Buff" },

	--  low Insanity generation coming up (i.e., Shadow Word: Death , Void Bolt , Mind Blast , AND Void Torrent are all on cooldown and you are in danger of reaching 0 Insanity).
	{spells.dispersion, isBoss and jps.insanity() < 50 and jps.cooldown(spells.mindBlast) > 0 and jps.cooldown(spells.voidEruption) > 0 and not jps.isUsableSpell(jps.spells.priest.shadowWordDeath) , "player" , "DISPERSION_insanity" },
	
	{spells.mindSear, not jps.Moving and jps.MultiTarget },

	{spells.vampiricTouch, not jps.Moving and VampEnemyTarget ~= nil and not UnitIsUnit("target",VampEnemyTarget) , VampEnemyTarget , "VT_MultiUnit_Buff" },
	{spells.shadowWordPain, PainEnemyTarget ~= nil and not UnitIsUnit("target",PainEnemyTarget) , PainEnemyTarget , "Pain_MultiUnit_Buff" },
	
	{spells.shadowWordPain, fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover_Buff" },
	{spells.vampiricTouch, not jps.Moving and fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "VT_Mouseover" },
	
	{spells.mindFlay , not jps.Moving , "target" , "mindFlay_Buff" },
	}},

--DPS
	{spells.voidEruption, jps.hasTalent(7,1) and jps.insanity() > 70 and jps.myDebuffDuration(spells.shadowWordPain) > 4 and jps.myDebuffDuration(spells.vampiricTouch) > 4 , rangedTarget , "voidEruption" },
	{spells.voidEruption, jps.insanity() == 100 and jps.myDebuffDuration(spells.vampiricTouch) > 4 , rangedTarget , "voidEruption" },
	{spells.voidEruption, jps.insanity() == 100 and jps.myDebuffDuration(spells.shadowWordPain) > 4 , rangedTarget , "voidEruption" },
	{spells.mindBlast , not jps.Moving , rangedTarget , "mindBlast" },
	
-- Refresh
	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,rangedTarget) < 4 and not jps.isRecast(spells.vampiricTouch,rangedTarget) , rangedTarget , "Refresh_VT_Target" },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,rangedTarget) < 4 and not jps.isRecast(spells.shadowWordPain,rangedTarget) , rangedTarget , "Refresh_Pain_Target" },
	{spells.vampiricTouch, not jps.Moving and jps.myDebuffDuration(spells.vampiricTouch,"focus") < 4 and not jps.isRecast(spells.vampiricTouch,"focus") ,"focus" , "Refresh_VT_Focus" },
	{spells.shadowWordPain, jps.myDebuffDuration(spells.shadowWordPain,"focus") < 4 and not jps.isRecast(spells.shadowWordPain,"focus") , "focus" , "Refresh_Pain_Focus" },
	
	{spells.vampiricTouch, not jps.Moving and fnVampEnemyTarget(rangedTarget) , rangedTarget , "VT_Target" },
	{spells.vampiricTouch, not jps.Moving and fnVampEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "VT_focus" },
	{spells.vampiricTouch, not jps.Moving and VampEnemyTarget ~= nil and not UnitIsUnit("target",VampEnemyTarget) , VampEnemyTarget , "VT_MultiUnit" },
	
	{spells.shadowWordPain, fnPainEnemyTarget(rangedTarget) , rangedTarget , "Pain_Target" },
	{spells.shadowWordPain, fnPainEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "Pain_focus" },
	{spells.shadowWordPain, PainEnemyTarget ~= nil and not UnitIsUnit("target",PainEnemyTarget) , PainEnemyTarget , "Pain_MultiUnit" },
	
	{spells.shadowWordPain, fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },
	{spells.vampiricTouch, not jps.Moving and fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "VT_Mouseover" },

	{spells.mindFlay, not jps.Moving , "target" , "mindFlay" },

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
	{spells.mindBlast, not jps.Moving },
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
	{ {"macro","/use item:118922"}, jps.itemCooldown(118922) == 0 , "player" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)