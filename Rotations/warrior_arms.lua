--[[[
@rotation Solo/Farming
@class Warrior
@spec Arms
@talents Zaa!120021
@author SwollNMember
@description
This is an aggressive rotation that will tag anything you target.[br]
Be careful with it or you may pull more than even JPS can handle!br]
Its meant for use in a competitive area where you're farming mobs[br]
or solo grinding.[br]
Enable/disable jps.MultiTarget or use a macro (/jps multi) to include/exclude multi-target rotation.[br]
]]--
   
local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit

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

-- Debuff EnemyTarget DO NOT DPS
local DebuffUnitCyclone = function (unit)
	if not UnitAffectingCombat(unit) then return false end
	local Cyclone = false
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			Cyclone = true
		elseif strfind(auraName,L["Cyclone"]) then
			Cyclone = true
		elseif strfind(auraName,L["Hex"]) then
			Cyclone = true
		elseif strfind(auraName,L["Deterrence"]) then
		 Cyclone = true
		elseif strfind(auraName,L["Ice Block"]) then
		 Cyclone = true
		end
		if Cyclone then break end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i))
	end
	return Cyclone
end

-- Buff EnemyTarget DO NOT BURST
local BuffEnemyDefense = function (unit)
	if not UnitAffectingCombat(unit) then return false end
	local Defense = false
	local i = 1
	local auraName = select(1,UnitBuff(unit, i))
		while auraName do
		if strfind(auraName,L["Die by the Sword"]) then
			Defense = true
		elseif strfind(auraName,L["Evasion"]) then
			Defense = true
		elseif strfind(auraName,L["Icebound Fortitude"]) then
			Defense = true
		elseif strfind(auraName,L["Ironbark"]) then
			Defense = true
		elseif strfind(auraName,L["Last Stand"]) then
			Defense = true
		end
		if Defense then break end
		i = i + 1
		auraName = select(1,UnitBuff(unit, i))
	end
	return Defense
end

-- Buff EnemyTarget POP DEFENSE
local BuffEnemyBurst = function (unit)
	if not UnitAffectingCombat(unit) then return false end
	local Burst = false
	local i = 1
	local auraName = select(1,UnitBuff(unit, i))
		while auraName do
		if strfind(auraName,L["Avatar"]) then
			Burst = true
		elseif strfind(auraName,L["Avenging Wrath"]) then
			Burst = true
		elseif strfind(auraName,L["Icy Veins"]) then
			Burst = true
		elseif strfind(auraName,L["Pillar of Frost"]) then
			Burst = true
		elseif strfind(auraName,L["Tiger's Fury"]) then
			Burst = true
		elseif strfind(auraName,L["Rapid Fire"]) then
			Burst = true
		elseif strfind(auraName,L["Bladestorm"]) then
			Burst = true         
		end
	if Burst then break end
	i = i + 1
	auraName = select(1,UnitBuff(unit, i))
	end
	return Burst
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("WARRIOR","ARMS",function()

local spell = nil
local target = nil
local playerhealth_pct = jps.hp("player") 
local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local Enrage = jps.buff(12880) -- "Enrage" 12880 "Enrager"
local inMelee = jps.IsSpellInRange(163201,"target") -- "Execute" 163201
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"
	
----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()
local isBoss = (UnitLevel("target") == -1) or (UnitClassification("target") == "elite")

-- Config FOCUS with MOUSEOVER
local name = GetUnitName("focus") or ""
if not jps.UnitExists("focus") and canDPS("mouseover") and UnitAffectingCombat("mouseover") then
	-- set focus an enemy targeting you
	if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy healer
	elseif jps.EnemyHealer("mouseover") then
		jps.Macro("/focus mouseover")
		print("Enemy HEALER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy in combat
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end

-- CONFIG jps.getConfigVal("keep focus") if you want to keep focus
if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	if jps.getConfigVal("keep focus") == false then jps.Macro("/clearfocus") end
end

if canDPS("target") and not DebuffUnitCyclone("target") then rangedTarget =  "target"
elseif canDPS("targettarget") and not DebuffUnitCyclone("targettarget") then rangedTarget = "targettarget"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "Heroic Leap" 6544 "Bond héroïque"
	{ 6544, IsControlKeyDown() , "player" },
	
	-- BUFFS 
	-- "Battle Stance"" 2457 -- "Defensive Stance" 71
	{ warrior.spells["BattleStance"] , not jps.buff(71) and not jps.buff(2457) , "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , not jps.hasAttackPowerBuff("player") and not jps.buff(469) , "player" },
	-- "Commanding Shout" 469 "Cri de commandement"
	{ warrior.spells["CommandingShout"] , not jps.buff(469) and jps.hasAttackPowerBuff("player") and not jps.buff(6673) , rangedTarget , "_CommandingShout" },

	-- INTERRUPTS --
	{ "nested", jps.Interrupts ,{
		-- "Choc martial" 74606 "War Stomp" -- Racial
		{ 74606, jps.ShouldKick() and jps.cooldown(6552) > 0 , rangedTarget },
		-- "Pummel" 6552 "Volée de coups"
		{ 6552 , jps.ShouldKick(rangedTarget) , rangedTarget , "_Pummel" },
		{ 6552 , jps.ShouldKick("focus") , "focus" , "_Pummel" },
		-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
		{ 114028 , UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "_MassSpell" },
	}},
	
	-- DAMAGE MITIGATION --
	{ "nested", jps.Defensive ,{
		-- "Stoneform" 20594 "Forme de pierre"
		{ 20594 , playerAggro and playerhealth_pct < 0.85 , rangedTarget , "_Stoneform" },
		{ 20594 , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },
		-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
		{ warrior.spells["ImpendingVictory"] , playerhealth_pct < 0.85 , rangedTarget , "_ImpendingVictory" },
		{ warrior.spells["VictoryRush"] , playerhealth_pct <  0.85 , rangedTarget , "_VictoryRush" },
		-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
		{ warrior.spells["ImpendingVictory"] , jps.buffDuration(32216) < 4 , rangedTarget , "_ImpendingVictory" },
		{ warrior.spells["VictoryRush"] , jps.buffDuration(32216) < 4 , rangedTarget , "_VictoryRush" }, 
		-- "Pierre de soins" 5512 "Healthstone"
		{ {"macro","/use item:5512"} , jps.combatStart > 0 and jps.itemCooldown(5512)==0 and playerhealth_pct < 0.50 , rangedTarget , "_UseItem"},
		-- "Die by the Sword" 118038
		{ 118038 , playerAggro and playerhealth_pct < 0.70 , rangedTarget , "_DieSword" },
		-- "Defensive Stance" 71
		{ 71 , not jps.buff(71) and playerhealth_pct < 0.30 },
		-- "Shield Barrier" 112048 "Barrière protectrice" -- "Defensive Stance" 71
		{ 112048, jps.buff(71) and playerhealth_pct < 0.30 },
	}},

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ 57755, inRanged and not inMelee , rangedTarget , "_Heroic Throw" },
	-- "Charge" 100
	{ 100, jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
	-- "Intimidating Shout" 5246
	{ 5246, not jps.debuff(5246,rangedTarget) and isBoss , rangedTarget , "_IntimidatingShout"},
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket0"},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket1"},
	
	-- "Recklessness" 1719 "Témérité" -- "Defensive Stance" 71 -- Avoid forcing back into battle stance
	{ 1719, not jps.buff(71) and jps.rage() > 60 and inMelee and jps.debuff(167105,rangedTarget) , rangedTarget , "_Recklessness" },
	-- "Bloodbath" 12292 "Bain de sang"  -- jps.buff(12292)
	{ 12292, jps.combatStart > 0 and inMelee and jps.debuff(167105,rangedTarget), rangedTarget , "_Bloodbath" },
	
	-- TALENTS --
	-- "Storm Bolt" 107570 "Eclair de tempete"
	{ 107570, jps.IsSpellKnown(107570) , rangedTarget , "_StormBolt_Health" },
	-- "Dragon Roar" 118000 "Rugissement de dragon"
	{ 118000, jps.IsSpellKnown(118000) and inMelee , rangedTarget , "_DragonRoar" },
	-- "Ravager" 152277 -- "Colossus Smash" 167105
	{ 152277, jps.IsSpellKnown(152277) and jps.debuff(167105,rangedTarget) , rangedTarget , "_Ravager"},
	-- "Siegebreaker" 176289 "Briseur de siège"
	{ 176289 , jps.IsSpellKnown(176289) , rangedTarget ,"_Siegebreaker" },
	-- "Execute" 163201 "Exécution" -- "Mort soudaine" 29725
	{ 163201, jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },

	-- MULTI-TARGET 
	{ "nested", jps.MultiTarget and inMelee ,{
		-- "Sweeping Strikes" 12328 "Attaques circulaires" 
		{ 12328, not jps.myDebuff(12328) , rangedTarget , "_SweepingStrikes" },
		-- "Rend" 772 "Pourfendre" -- Apply if tab-target has no debuff
		{ 772 , not jps.debuff(772,rangedTarget) , rangedTarget , "_Rend_Debuff" },
		{ 772 , jps.myDebuffDuration(772,rangedTarget) < 4 , rangedTarget , "_Rend_Duration" },
		-- "Whirlwind" 1680 "Tourbillon"
		{ 1680, true , rangedTarget , "_Whirlwind" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ 6343, true , rangedTarget , "_ThunderClap" },
		-- "Bladestorm" 46924 "Tempête de lames" -- "Enrage" 12880 "Enrager" -- While Bladestorm is active, you cannot perform any actions except for using your Taunt
		{ 46924, true , rangedTarget , "_Bladestorm" },
		-- "Shockwave" 46968 "Onde de choc"
		{ 46968 , true , rangedTarget , "_Shockwave" },
	}},
	
	-- SINGLE TARGET --
	-- "Rend" 772 "Pourfendre"
	{ 772, not jps.debuff(772,rangedTarget) , rangedTarget , "_Rend_Debuff" },
	{ 772, jps.myDebuffDuration(772,rangedTarget) < 5 , rangedTarget , "_Rend_Duration" },
	-- "Colossus Smash" 167105
	{ 167105, true , rangedTarget , "_ColossusSmash_Health" },
	-- "Execute" 163201
	{ 163201, not jps.debuff(167105,rangedTarget) and jps.hp(rangedTarget) < 0.20 and jps.rage() > 40 , rangedTarget , "_Execute_Health" },
	{ 163201, jps.debuff(167105,rangedTarget) and jps.hp(rangedTarget) < 0.20 , rangedTarget , "_Execute_Health" },
	-- "MortalStrike" 12294 "Frappe mortelle" -- Remplace "Frappe Heroique"
	{ 12294 , jps.hp(rangedTarget) > 0.20 , rangedTarget , "_MortalStrike" },
	-- "Whirlwind" 1680 "Tourbillon"
	{ 1680, jps.hp(rangedTarget) > 0.20 , rangedTarget , "_Whirlwind" }

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Warrior Arms SNM")
