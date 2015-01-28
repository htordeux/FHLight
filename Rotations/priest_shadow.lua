-- jps.MultiTarget for "MindSear" 48045
-- jps.Interrupts for "Semblance spectrale" 112833 -- because lose the orbs in Kotmogu Temple

local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local tinsert = table.insert

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
	local Cyclone = false
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i)) -- UnitAura(unit,i,"HARMFUL")
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			Cyclone = true
		elseif strfind(auraName,L["Cyclone"]) then
			Cyclone = true
		elseif strfind(auraName,L["Hex"]) then
			Cyclone = true
		end
		if Cyclone then break end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i)) -- UnitAura(unit,i,"HARMFUL") 
	end
	return Cyclone
end

----------------------------
-- ROTATION
----------------------------

jps.registerRotation("PRIEST","SHADOW",function()

local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
local playerhealth =  jps.hp("player","abs")
local playerhealthpct = jps.hp("player")
local playermana = jps.roundValue(UnitPower("player",0)/UnitPowerMax("player",0),2)
local Orbs = UnitPower("player",13) -- SPELL_POWER_SHADOW_ORBS 	13

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) --- return true/false ONLY FOR PLAYER > 2 sec
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()
local isArena, _ = IsActiveBattlefieldArena()

-- Config FOCUS
if not jps.UnitExists("focus") and canDPS("mouseover") then
	-- set focus an enemy targeting you
	if jps.UnitIsUnit("mouseovertarget","player") and not jps.UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy healer
	elseif jps.EnemyHealer("mouseover") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy HEALER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end

-- CONFIG jps.getConfigVal("keep focus") if you want to keep focus
if jps.UnitExists("focus") and jps.UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	if jps.getConfigVal("keep focus") == false then jps.Macro("/clearfocus") end
end

if canDPS("target") and not DebuffUnitCyclone("target") then rangedTarget =  "target"
elseif canDPS("targettarget") and not DebuffUnitCyclone("targettarget") then rangedTarget = "targettarget"
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

-- take care if "focus" not Polymorph and not Cyclone
-- table.insert(t, 1, "element") insert an element at the start
if canDPS("focus") and not DebuffUnitCyclone("focus") then tinsert(EnemyUnit,1,"focus") end

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
for _,unit in ipairs(EnemyUnit) do
	if jps.canCast(15487,unit) then
		if jps.ShouldKick(unit) then
			SilenceEnemyTarget = unit
		break end
	end
end

local DeathEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if priest.canShadowWordDeath(unit) then 
		DeathEnemyTarget = unit
	break end
end

local PainEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if fnPainEnemyTarget(unit) and not jps.UnitIsUnit("target",unit) then
		PainEnemyTarget = unit
	break end
end

local VampEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if fnVampEnemyTarget(unit) and not jps.UnitIsUnit("target",unit) then
		VampEnemyTarget = unit
	break end
end

local DispelOffensiveTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if jps.DispelOffensive(unit) then
		DispelOffensiveTarget = unit
	break end
end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

-- priest.unitForLeap includes jps.FriendAggro and jps.LoseControl
local LeapFriendFlag = nil 
for _,unit in ipairs(FriendUnit) do
	if priest.unitForLeap(unit) and jps.hp(unit) < 0.50 then
		if jps.RoleInRaid(unit) == "HEALER" then
			LeapFriendFlag = unit
		break end
	end
end

-- if jps.debuffDuration(114404,"target") > 18 and jps.UnitExists("target") then MoveBackwardStart() end
-- if jps.debuffDuration(114404,"target") < 18 and jps.debuff(114404,"target") and jps.UnitExists("target") then MoveBackwardStop() end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- SPELLSTOPCASTING
----------------------------------------------------------

if jps.buff(47585,"player") then return end -- "Dispersion" 47585
	
--	SpellStopCasting()
-- "Mind Flay" 15407 -- "Mind Blast" 8092 -- buff 81292 "Glyph of Mind Spike"
-- "Insanity" 129197
local canCastMindBlast = false
local canCastDeath = false
local MindFlay = GetSpellInfo(15407) or GetSpellInfo(129197)
local Channeling = UnitChannelInfo("player") -- "Mind Flay" is a channeling spell
-- "Shadow Word: Insanity" 132573 not jps.buff(132573)
if Channeling == MindFlay then
	-- "Mind Blast" 8092 -- buff 81292 "Glyph of Mind Spike"
	if (jps.cooldown(8092) == 0) and (jps.buffStacks(81292) == 2) then 
		canCastMindBlast = true
	-- "Shadowy Insight" proc "Mind Blast" 8092 -- "Shadowy Insight" 162452 gives BUFF 124430
	elseif jps.buff(124430) then
		canCastMindBlast = true
	-- "Mind Blast" 8092
	elseif jps.cooldown(8092) == 0 and not jps.Moving then 
		canCastMindBlast = true
	-- "Shadow Word: Death" 32379
	elseif jps.hp(rangedTarget) < 0.20 then
		canCastDeath = true
	end
end

if canCastMindBlast then
	SpellStopCasting()
	spell = 8092;
	target = rangedTarget;
	write("MIND_BLAST")
return end

if canCastDeath then
	SpellStopCasting()
	spell = 32379;
	target = rangedTarget;
	write("DEATH_MultiUnit")
return end

-- Avoid interrupt Channeling
if jps.ChannelTimeLeft() > 0 then return nil end

-------------------------------------------------------------
------------------------ TABLES
-------------------------------------------------------------

local fnOrbs = function(unit)
	if jps.LoseControl(unit) then return false end
	if Orbs == 0 then return false end
	if Orbs < 3 and jps.ShouldKick(unit) then return true end
	if Orbs < 3 and jps.EnemyHealer(unit) then return true end
	if Orbs < 3 and jps.UnitIsUnit(unit.."target","player") then return true end
	return false
end

local parseControl = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear(rangedTarget) , rangedTarget },
	-- "Silence" 15487
	{ 15487, EnemyCaster(rangedTarget) == "caster" , rangedTarget },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.canCast(64044,rangedTarget) and fnOrbs(rangedTarget) , rangedTarget },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
}

local parseControlFocus = {
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear("focus") , "focus" , "Fear_".."focus" },
	-- "Silence" 15487
	{ 15487, EnemyCaster("focus") == "caster" , "focus" , "Silence_".."focus" },
	-- "Psychic Horror" 64044 "Horreur psychique" -- 30 yd range
	{ 64044, jps.canCast(64044,"focus") and fnOrbs("focus") , "focus" , "Horror_".."focus" },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, playerAggro and priest.canFear("focus") , "focus" },
}

local parseHeal = {
	-- "Don des naaru" 59544
	{ 59544, jps.IsSpellKnown(59544) , "player" , "Naaru_Player" },
	-- "Prière du désespoir" 19236
	{ 19236, jps.IsSpellKnown(19236) , "player" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
	-- "Power Word: Shield" 17	
	{ 17, not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" },
	-- "Prayer of Mending" "Prière de guérison" 33076 
	--{ 33076, not jps.buff(33076,"player") , "player" },
}

local parseAggro = {
	-- "Semblance spectrale" 112833
	{ 112833, jps.Interrupts and jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },
	-- "Dispersion" 47585
	{ 47585,  playerhealthpct < 0.40 , "player" , "Aggro_Dispersion" },
	-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
	{ 586, jps.IsSpellKnown(108942) and playerhealthpct < 0.70 , "player" , "Aggro_Oubli" },
	-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
	{ 586, jps.glyphInfo(55684) and playerhealthpct < 0.70 , "player" , "Aggro_Oubli" },
}

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

	-- "Semblance spectrale" 112833 "Spectral Guise" gives buff 119032
	{"nested", not jps.Combat and not jps.buff(119032,"player") , 
		{
			-- "Gardien de peur" 6346
			{ 6346, not jps.buff(6346,"player") , "player" },
			-- "Fortitude" 21562 Keep Inner Fortitude up 
			{ 21562, jps.buffMissing(21562) , "player" },
		},
	},
	
	-- "Shadowform" 15473 -- UnitAffectingCombat("player") == true
	{ 15473, not jps.buff(15473) , "player" },
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.combatStart > 0 and jps.hp(rangedTarget) < 0.9 , "player" },
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun , "player" },
	-- PLAYER AGGRO
	{ "nested", playerAggro , parseAggro },
	
	-- FOCUS CONTROL
	-- "Silence" 15487
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit_Target" },
	{ "nested", canDPS(rangedTarget) and not jps.LoseControl(rangedTarget) , parseControl },
	{ "nested", canDPS("focus") and not jps.LoseControl("focus") , parseControlFocus },
	
	-- "Mind Spike" 73510 -- "Surge of Darkness" 162452 gives buff -- "Surge of Darkness" 87160
	{ 73510, jps.buffStacks(87160,"player") == 3 , rangedTarget , "Spike_SurgeofDarkness_Stacks" },
	{ 73510, jps.buff(87160) and jps.hp(rangedTarget) < 0.20 , rangedTarget , "Spike_SurgeofDarkness_LowHealth" },
	{ 73510, jps.buff(87160) and jps.buffDuration(87160) < 4 , rangedTarget , "Spike_SurgeofDarkness_GCD" },
	
	-- "Clarity of Power" 155246 "Clarté de pouvoir"
	{ "nested", jps.IsSpellKnown(155246) and Orbs > 3 ,{
		-- "Shadow Word: Pain" 589 with CoP
		{ 589, not jps.myDebuff(589,rangedTarget) and not jps.isRecast(589,rangedTarget) , rangedTarget , "VT_On_ORBS_5" },
		-- "Vampiric Touch" 34914 with CoP
		{ 34914, not jps.Moving and not jps.myDebuff(34914,rangedTarget) and not jps.isRecast(34914,rangedTarget) , rangedTarget , "Pain_On_ORBS_5" },

	}},
	
	-- "Devouring Plague" 2944 now consumes 3 Shadow Orbs, you don't have the ability to use with less Orbs
	{ 2944, Orbs == 5 , rangedTarget , "ORBS_5" },
	-- "Devouring Plague" 2944 now consumes 3 Shadow Orbs, you don't have the ability to use with less Orbs
	{ 2944, Orbs > 2 and jps.hp(rangedTarget) < 0.20 , rangedTarget , "ORBS_LowHealth" },
	-- "Devouring Plague" spell 2944 -- "Insanity" 139139 -- transforms your Mind Flay into Insanity for 2 sec per Shadow Orb consumed
	{ 2944, jps.IsSpellKnown(139139) and Orbs > 2 and jps.cooldown(8092) > 6 , rangedTarget , "ORBS_Insanity" },
	-- "Mind Flay" 15407 -- "Shadow Word: Insanity" buff 132573
	{ 15407, jps.buff(132573) , rangedTarget , "MINDFLAYORBS_" },
	
	-- "Shadow Word: Death" 32379 "Mot de l'ombre : Mort"
	{ 32379, jps.hp(rangedTarget) < 0.20 , rangedTarget, "castDeath_"..rangedTarget },
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "Death_MultiUnit" },
	
	-- "Mind Blast" 8092 -- "Shadowy Insight" 162452 gives buff 124430
	{ 8092, jps.buff(124430) , rangedTarget , "Blast_ShadowyInsight" },
	-- "Mind Blast" 8092 -- "Glyph of Mind Spike" 33371 gives buff 81292 
	{ 8092, jps.buffStacks(81292) == 2 , rangedTarget },
	-- "Mind Blast" 8092
	{ 8092, not jps.Moving , rangedTarget , "Blast_CD" },
	
	-- "Vampiric Embrace" 15286
	{ 15286, AvgHealthLoss < 0.85 , "player" },
	-- SELF HEAL
	{ "nested", playerhealthpct < 0.70 , parseHeal },

	-- "Shadow Word: Pain" 589 -- "Shadow Word: Insanity" buff 132573
	{ 589, type(PainEnemyTarget) == "string" , PainEnemyTarget , "Pain_MultiUnit_" },
	{ 589, not jps.buff(132573) and fnPainEnemyTarget("mouseover") and not jps.UnitIsUnit("target","mouseover") , "mouseover" , "Pain_MOUSEOVER_ORBS" },
	-- "Vampiric Touch" 34914 -- "Shadow Word: Insanity" buff 132573
	{ 34914, type(VampEnemyTarget) == "string" , VampEnemyTarget , "Vamp_MultiUnit_" },
	{ 34914, not jps.buff(132573) and fnVampEnemyTarget("mouseover") and not jps.UnitIsUnit("target","mouseover") , "mouseover" , "Vamp_MOUSEOVER_ORBS" },

	-- MULTITARGET
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 122121, jps.IsSpellKnown(122121) and playerIsInterrupt and jps.IsSpellInRange(122121,rangedTarget) , rangedTarget , "Interrupt_DivineStar_" },
	{ 122121, jps.IsSpellKnown(122121) and EnemyCount > 2 and jps.IsSpellInRange(122121,rangedTarget) , rangedTarget , "Divine_Star"  },
	-- "Cascade" Holy 121135 Shadow 127632
	{ 127632, jps.IsSpellKnown(127632) and EnemyCount > 2 , rangedTarget , "Cascade_"  },
	-- "MindSear" 48045
	{ 48045, not jps.Moving and jps.MultiTarget and EnemyCount > 3 , rangedTarget  },

	-- "Mind Spike" 73510 -- "Clarity of Power" 155246 "Clarté de pouvoir" -- "Devouring Plague" debuff 158831
	-- Orbs < 5 permet d'executer les conditions suivantes à partir de 4 Orbs
	{ 73510, not jps.Moving and jps.IsSpellKnown(155246) and Orbs < 5 and not jps.myDebuff(158831,rangedTarget) and not jps.myDebuff(34914,rangedTarget) and not jps.myDebuff(589,rangedTarget) , rangedTarget , "Spike_CoP" },

	-- "Mindbender" "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	
	-- "Shadow Word: Pain" 589 Keep up
	{ 589, jps.myDebuff(589,rangedTarget) and jps.myDebuffDuration(589,rangedTarget) < jps.GCD and not jps.isRecast(589,rangedTarget) , rangedTarget , "Pain_Target_" },
	-- "Vampiric Touch" 34914 Keep up
	{ 34914, not jps.Moving and jps.myDebuff(34914,rangedTarget) and jps.myDebuffDuration(34914,rangedTarget) < jps.GCD and not jps.isRecast(34914,rangedTarget) , rangedTarget , "VT_Target_" },

	-- "Leap of Faith" 73325 -- "Saut de foi"
	{ 73325 , type(LeapFriendFlag) == "string" , LeapFriendFlag , "|cff1eff00Leap_MultiUnit_" },
	
	-- Offensive Dispel -- "Dissipation de la magie" 528 -- includes canDPS
	{ 528, jps.castEverySeconds(528,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00Dispel_Offensive_"..rangedTarget },
	{ 528, jps.castEverySeconds(528,10) and type(DispelOffensiveTarget) == "string"  , DispelOffensiveTarget , "|cff1eff00Dispel_Offensive_MultiUnit_" },
	
	-- "Power Infusion" "Infusion de puissance" 10060
	{ 10060, jps.combatStart > 0 , "player" },
	-- "Gardien de peur" 634
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Mind Flay" 15407
	{ 15407, true , rangedTarget , "Fouet_Mental" },
}

	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Shadow Priest Default" )

-- Surge of Darkness
-- Your Vampiric Touch and Devouring Plague damage has a 10% chance to cause your next Mind Spike not to consume your damage over time effects
-- be instant, and deal 50% additional damage. Can accumulate up to 3 charges.

-- Shadowy Insight
-- Your Shadow Word: Pain damage over time and Mind Spike damage has a 5% chance to reset the cooldown on Mind Blast and make your next Mind Blast instant.

-- Shadow Word: Pain
-- causes (47.5% of Spell power) Shadow damage and an additional (285% of Spell power) Shadow damage over 18 sec.

-- Vampiric Touch
-- Causes (292.5% of Spell power) Shadow damage over 15 sec. If Vampiric Touch is dispelled, the dispeller flees in Horror for 3 sec.