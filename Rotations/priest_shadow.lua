-- jps.UseCDs for RACIAL COUNTERS
-- jps.UseCDs for "Cascade" 127632
-- jps.Interrupts for "Semblance spectrale" 112833 "Spectral Guise" -- PvP it loses the orb in Kotmogu Temple
-- jps.Defensive to keep Shield up
-- jps.MultiTarget for "MindSear" 48045
-- IsControlKeyDown() for "Angelic Feather" 121536 "Plume angélique"

local L = MyLocalizationTable
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

-- Channeling
local MindFlay = GetSpellInfo(15407)
local Insanity = GetSpellInfo(129197)
local MindSear = GetSpellInfo(48045)
local Searing = GetSpellInfo(179338)

local ClassEnemy = {
	["WARRIOR"] = "cac",
	["PALADIN"] = "caster",
	["HUNTER"] = "cac",
	["ROGUE"] = "cac",
	["PRIEST"] = "caster",
	["DEATHKNIGHT"] = "cac",
	["SHAMAN"] = "caster",
	["MAGE"] = "caster",
	["WARLOCK"] = "caster",
	["MONK"] = "caster",
	["DRUID"] = "caster"
}

local EnemyCaster = function(unit)
	if not jps.UnitExists(unit) then return false end
	local _, classTarget, classIDTarget = UnitClass(unit)
	return ClassEnemy[classTarget]
end

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

----------------------------
-- ROTATION
----------------------------

jps.registerRotation("PRIEST","SHADOW",function()

local spell = nil
local target = nil
local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus()
local playermana = jps.roundValue(UnitPower("player",0)/UnitPowerMax("player",0),2)
local Orbs = UnitPower("player",13) -- SPELL_POWER_SHADOW_ORBS 	13
-- "Body and Soul" 64129
local BodyAndSoul = jps.IsSpellKnown(64129)
-- "Clarity of Power" 155246 "Clarté de pouvoir"
local COP = jps.IsSpellKnown(155246)

local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if canHeal(Tank) then TankTarget = Tank.."target" end

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
local name = GetUnitName("focus") or ""
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

if canDPS("target") and not DebuffUnitCyclone(rangedTarget) then rangedTarget =  "target"
elseif canDPS(enemyHealer) and not DebuffUnitCyclone(enemyHealer) then rangedTarget =  enemyHealer
elseif canDPS(TankTarget) and not DebuffUnitCyclone(rangedTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") and not DebuffUnitCyclone(rangedTarget) then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
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
	if canDPS(unit) and not jps.myDebuff(589,unit) and not jps.isRecast(589,unit) then
		return true end
	return false
end

local fnVampEnemyTarget = function(unit)
	if jps.Moving then return false end
	if canDPS(unit) and not jps.myDebuff(34914,unit) and not jps.isRecast(34914,unit) then
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
	if priest.canShadowWordDeath(unit) then 
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

-- priest.unitForLeap includes jps.FriendAggro and jps.LoseControl
local LeapFriend = nil
for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
	local unit = FriendUnit[i]
	if priest.unitForLeap(unit) and jps.hp(unit) < 0.25 then 
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

local canCastMindBlast = false
local Channeling = UnitChannelInfo("player") -- "Mind Flay" is a channeling spell
if Channeling and Channeling == MindFlay and jps.cooldown(8092) == 0 then
	-- "Glyph of Mind Spike" 33371 gives buff 81292
	if jps.buffStacks(81292) == 2 then 
		canCastMindBlast = true
	-- "Shadowy Insight" 162452 gives BUFF 124430
	elseif jps.buff(124430) then
		canCastMindBlast = true
	-- "Mind Blast" 8092 -- Instant with COP 155246
	elseif COP then 
		canCastMindBlast = true
	-- "OnCD"
	elseif not jps.Moving then
		canCastMindBlast = true
	end
elseif Channeling and Channeling == MindSear and jps.cooldown(8092) == 0 then
	canCastMindBlast = true
end

if canCastMindBlast then
	SpellStopCasting()
	spell = 8092;
	target = rangedTarget;
	if jps.combatStart > 0 then write("MIND_BLAST") end
return spell,target end

if Channeling and Channeling == Searing and jps.buff(132573) and jps.buffDuration(132573) < 1.25 and jps.ChannelTimeLeft() < 1.75 then
	SpellStopCasting()
	spell = 179338;
	target = rangedTarget;
	if jps.combatStart > 0 then write("MIND_SEAR") end
return spell,target end

-- Avoid interrupt Channeling
if jps.ChannelTimeLeft() > 0 then return nil end

-------------------------------------------------------------
------------------------ TABLES
-------------------------------------------------------------

-- "Psychic Horror" 64044 Consumes up to 3 Shadow Orbs to terrify the target
-- incapacitating the target for 1 sec plus 1 sec per Shadow Orb consumed.
local fnOrbs = function(unit)
	if Orbs == 0 then return false end
	if jps.LoseControl(unit) then return false end
	if DebuffUnitCyclone(unit) then return false end
	if jps.ShouldKick(unit) then return true end
	if jps.EnemyHealer(unit) then return true end
	return false
end

local parseControl = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear(rangedTarget) , rangedTarget },
	-- "Silence" 15487
	{ 15487, jps.IsSpellInRange(15487,rangedTarget) and EnemyCaster(rangedTarget) == "caster" , rangedTarget },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.IsSpellInRange(64044,rangedTarget) and fnOrbs(rangedTarget) , rangedTarget },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, priest.canFear(rangedTarget) , rangedTarget },
}

local parseControlFocus = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear("focus") , "focus" , "Fear_focus" },
	-- "Silence" 15487
	{ 15487, jps.IsSpellInRange(15487,"focus") and EnemyCaster("focus") == "caster" , "focus" , "Silence_focus" },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.IsSpellInRange(64044,"focus") and fnOrbs("focus") , "focus" , "Horror_focus" },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, priest.canFear("focus") , "focus" },
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
	
	-- "Shadowform" 15473
	{ 15473, not jps.buff(15473) , "player" },
	
	-- SNM "Levitate" 1706 -- "Dark Simulacrum" debuff 77606
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.PvP and jps.debuff(77606,"player") , "player" , "DarkSim_Levitate" },
	-- "Angelic Feather" 121536 "Plume angélique"
	{ 121536, IsControlKeyDown() },
	
	-- SNM RACIAL COUNTERS -- share 30s cd with trinket
	{"nested", jps.PvP and jps.UseCDs , RacialCounters },
	-- SNM "Chacun pour soi" 59752 "Every Man for Himself" -- Human
	{ 59752, playerIsStun , "player" , "Every_Man_for_Himself" },
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , "player" , "useTrinket0" },
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun and jps.combatStart > 0 , "player" , "useTrinket1" },

	-- "Spectral Guise" 112833 "Semblance spectrale" gives buff 119032
	{ 112833, jps.Interrupts and jps.EnemyCastingSpellControl() and jps.IsSpellKnown(112833) and not jps.buff(159630) , "player" , "Control_Spectral" },
	-- "Fade" 586 "Oubli" -- "Glyph of Shadow Magic" 159628 -- gives buff "Shadow Magic" 159630 "Magie des Ténèbres"
	{ 586, jps.EnemyCastingSpellControl() and jps.glyphInfo(159628) and not jps.buff(119032), "player" , "Control_Oubli" },
	
	-- FOCUS CONTROL
	-- "Silence" 15487
	{ 15487, SilenceEnemyTarget ~= nil , SilenceEnemyTarget , "Silence_MultiUnit_Target" },
	{ "nested", jps.PvP and canDPS(rangedTarget) and not jps.LoseControl(rangedTarget) , parseControl },
	{ "nested", jps.PvP and canDPS("focus") and not jps.LoseControl("focus") , parseControlFocus },
	-- OFFENSIVE DISPEL -- "Dissipation de la magie" 528 (jps.DispelOffensive includes canDPS)
	{ 528, jps.castEverySeconds(528,8) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00Dispel_Offensive" },
	{ 528, jps.castEverySeconds(528,8) and DispelOffensiveTarget ~= nil  , DispelOffensiveTarget , "|cff1eff00Dispel_Offensive_MultiUnit" },

	-- PLAYER AGGRO PVP
	{ "nested", playerAggro or playerIsTargeted ,{
		-- "Spectral Guise" 112833 "Semblance spectrale" gives buff 119032
		{ 112833, jps.Interrupts and jps.IsSpellKnown(112833) and not jps.buff(159630) , "player" , "Aggro_Spectral" },
		-- "Fade" 586 "Oubli" -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
		{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
		-- "Fade" 586 "Oubli" -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même
		{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
		-- "Power Word: Shield" 17	
		{ 17, not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" , "Aggro_Shield" },
		-- "Dispersion" 47585
		{ 47585, jps.PvP and jps.hp("player") < 0.40 , "player" , "Aggro_Dispersion" },
		{ 47585, jps.cooldown(112833) > 0 and jps.debuff(6788,"player") and jps.hp("player") < 0.40 , "player" , "Aggro_Dispersion" },
	}},

	-- "Power Word: Shield" 17 -- Glyph of Reflective Shield 33202
	{ 17, jps.Defensive and not jps.buff(132573) and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Defensive_Shield" },
	{ 17, jps.glyphInfo(33202) and not jps.buff(132573) and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Defensive_Shield" },
	-- "Leap of Faith" 73325 -- "Saut de foi"
	{ 73325 , jps.PvP and LeapFriend ~= nil , LeapFriend , "|cff1eff00Leap_MultiUnit" },
	-- "Gardien de peur" 634
	{ 6346, jps.PvP and not jps.buff(6346,"player") , "player" },

	-- HEAL --
	-- "Vampiric Embrace" 15286
	{ 15286, CountInRange > 5 , rangedTarget , "VampiricEmbrace"  },
	{ 15286, jps.hp("player") < 0.75 and not IsInGroup() , rangedTarget , "VampiricEmbrace"  },
	{ "nested", jps.hp("player") < 0.75 , parseHeal },

	-- "Power Infusion" "Infusion de puissance" 10060
	{ 10060, jps.FinderLastMessage("PLAGUE") and jps.hp("player") > jps.hp(rangedTarget) , rangedTarget , "PowerInfusion" },

	-- "Devouring Plague" 2944 consumes 3 Shadow Orbs, you don't have the ability to use with less Orbs
	{ 2944, Orbs == 5 , rangedTarget , "PLAGUE_5_Orbs" },
	{ 2944, Orbs > 2 and jps.MultiTarget , rangedTarget , "PLAGUE_MultiTarget" },
	-- "Devouring Plague" 2944 consumes 3 Shadow Orbs, you don't have the ability to use with less Orbs
	{ "nested", not jps.buff(132573) and Orbs > 2 , {
		{ 2944, jps.hp("player") < 0.75 , rangedTarget , "PLAGUE_LowHealth_Player" },
		{ 2944, jps.hp(rangedTarget) < 0.20 , rangedTarget , "PLAGUE_LowHealth_Target" },
		{ 2944, jps.myDebuffDuration(34914,rangedTarget) > 5 and jps.myDebuffDuration(589,rangedTarget) > 5 , rangedTarget , "PLAGUE_Debuff_Duration" },
	}},
		
	-- "MindSear" 48045 -- "Insanité incendiaire" 179338 "Searing Insanity"
	{ 48045, not jps.Moving and jps.MultiTarget and jps.buff(132573) , rangedTarget , "MINDSEARORBS_Target" },
	-- "Mind Flay" 15407 -- "Shadow Word: Insanity" buff 132573 -- "Insanity" 129197
	{ 15407, not jps.Moving and jps.buff(132573) , rangedTarget , "MINDFLAYORBS" },

	-- "Mind Blast" 8092 -- "Shadowy Insight" 162452 gives buff 124430
	{ 8092, jps.buff(124430) , rangedTarget , "Blast_Insight" },
	-- "Mind Blast" 8092 -- "Glyph of Mind Spike" 33371 gives buff 81292 
	{ 8092, jps.buffStacks(81292) == 2 , rangedTarget , "Blast_Stacks" },
	-- "Mind Blast" 8092 -- Instant with COP 155246
	{ 8092, COP , rangedTarget , "Blast_CD" },
	{ 8092, not jps.Moving , "Blast_CD" },
	
	-- "Shadow Word: Death" 32379 "Mot de l'ombre : Mort"
	{ 32379, DeathEnemyTarget ~= nil and not jps.buff(132573) and Orbs < 5 , DeathEnemyTarget , "Death_MultiUnit" },
	{ 32379, jps.hp(rangedTarget) < 0.20 and Orbs < 5 , rangedTarget, "Death_Target" },
	{ 32379, jps.hp("focus") < 0.20 and Orbs < 5 , "focus", "Death_Focus" },
	{ 32379, jps.hp("mouseover") < 0.20 and Orbs < 5 , "mouseover", "Death_Mouseover" },
	
	-- "Mind Spike" 73510 -- "Surge of Darkness" gives buff -- "Surge of Darkness" 87160
	{ 73510, jps.buffStacks(87160,"player") > 1 , rangedTarget , "Spike_SurgeofDarkness_Stacks" },
	{ 73510, jps.buff(87160) and jps.hp(rangedTarget) < 0.20 , rangedTarget , "Spike_SurgeofDarkness_LowHealth" },
	{ 73510, jps.buff(87160) and jps.buffDuration(87160) < 4 , rangedTarget , "Spike_SurgeofDarkness_CD" },
	
	-- MULTITARGET
	-- "Mindbender" "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- "Cascade" Holy 121135 Shadow 127632
	{ 127632, jps.UseCDs and not jps.Moving , rangedTarget , "Cascade"  },
	-- "Divine Star" Holy 110744 Shadow 122121 -- "Dissipation de la magie" 528 to check in range 30 y
	{ 122121, jps.IsSpellInRange(528,rangedTarget) and jps.myLastCast(15407) , rangedTarget , "DivineStar"  },
	
	-- "Shadow Word: Pain" 589 -- "Shadow Word: Insanity" buff 132573
	--{ 589, Orbs > 3 and fnPainEnemyTarget(rangedTarget) and not jps.isRecast(589,rangedTarget) , rangedTarget , "Pain_Orbs" },
	{ 589, fnPainEnemyTarget(rangedTarget) and not jps.isRecast(589,rangedTarget) , rangedTarget , "Pain_Target" },
	-- "Vampiric Touch" 34914 -- "Shadow Word: Insanity" buff 132573
	--{ 34914, Orbs > 3 and not jps.Moving and fnVampEnemyTarget(rangedTarget) and not jps.isRecast(34914,rangedTarget) , rangedTarget , "VT_Orbs" },
	{ 34914, not jps.Moving and fnVampEnemyTarget(rangedTarget) and not jps.isRecast(34914,rangedTarget) , rangedTarget , "VT_Target" },

	-- "Shadow Word: Pain" 589 -- "Shadow Word: Insanity" buff 132573	
	{ 589, not jps.buff(132573) and PainEnemyTarget ~= nil and not UnitIsUnit(PainEnemyTarget,"target") , PainEnemyTarget , "Pain_MultiUnit" },
	{ 589, not jps.buff(132573) and fnPainEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "Pain_focus" },
	{ 589, not jps.buff(132573) and fnPainEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "Pain_Mouseover" },

	{ "nested", not jps.Moving , {
		-- "Vampiric Touch" 34914 -- "Shadow Word: Insanity" buff 132573
		{ 34914, not jps.buff(132573) and VampEnemyTarget ~= nil and not UnitIsUnit(VampEnemyTarget,"target") , VampEnemyTarget , "VT_MultiUnit" },
		{ 34914, not jps.buff(132573) and fnVampEnemyTarget("focus") and not UnitIsUnit("target","focus") , "focus" , "VT_focus" },
		{ 34914, not jps.buff(132573) and fnVampEnemyTarget("mouseover") and not UnitIsUnit("target","mouseover") , "mouseover" , "VT_Mouseover" },
		
		-- "MindSear" 48045 -- "Insanité incendiaire" 179338 "Searing Insanity"
		{ 48045, jps.MultiTarget and EnemyCount > 3 , rangedTarget , "MINDSEAR_Target" },

		-- "Mind Spike" 73510 -- "Devouring Plague" debuff 158831
		{ 73510, COP and not jps.myDebuff(158831,rangedTarget) and fnMindSpike(rangedTarget) , rangedTarget , "Spike_CoP_target" },
		{ 34914, MindSpikeTarget ~= nil , MindSpikeTarget , "Spike_MultiUnit" },
	}},

	-- "Mind Flay" 15407
	{ 15407, true , rangedTarget , "FouetMental" },
}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Shadow Priest Default" )

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
	
	local ShadowForm = tostring(select(1,GetSpellInfo(15473)))
	local macroCancelaura = "/cancelaura "..ShadowForm
	
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
	-- "Soins rapides" 2061
	{ {"macro",macroCancelaura}, jps.buff(15473) and jps.hp("player") < 0.50 , "player"  , "Cancelaura_" },
	{ 2061, not jps.buff(15473) and not jps.Moving and jps.hp("player") < 0.75 , "player" , "FlashHeal_" },
	-- "Shadowform" 15473
	{ 15473, not jps.buff(15473) , "player" },

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