local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass

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

jps.registerRotation("WARRIOR","PROTECTION",function()

local spell = nil
local target = nil
local playerhealth_deficiency =  jps.hp("player","abs") -- UnitHealthMax(player) - UnitHealth(player)
local playerhealth_pct = jps.hp("player") 
local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local Enrage = jps.buff(12880) -- "Enrage" 12880 "Enrager"
local inMelee = jps.IsSpellInRange(5308,"target") -- "Execute" 5308
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"
	
----------------------
-- TARGET ENEMY
----------------------

local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()

-- Config FOCUS
if not jps.UnitExists("focus") and canDPS("mouseover") then
	-- set focus an enemy targeting you
	if jps.UnitIsUnit("mouseovertarget","player") and not jps.UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end

-- CONFIG jps.getConfigVal("keep focus") if you want to keep focus
if jps.UnitExists("focus") and jps.UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	if jps.getConfigVal("keep focus") == false then jps.Macro("/clearfocus") end
end

if canDPS("target") then rangedTarget =  "target"
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canDPS("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable ={

	-- "Heroic Leap" 6544 "Bond héroïque"
	{ 6544, IsShiftKeyDown() , "player" },
	
	-- BUFFS
	-- "Defensive Stance"" 71
	{ warrior.spells["DefensiveStance"], not jps.buff(71) , "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , not jps.hasAttackPowerBuff("player") , "player" },
	
	-- INTERRUPTS --
	{ "nested", jps.Interrupts,{
		-- "Pummel" 6552 "Volée de coups"
		{ warrior.spells["Pummel"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_Pummel" },
		{ warrior.spells["Pummel"] , jps.ShouldKick("focus") , "focus" , "_Pummel" },
		-- "Spell Reflection" 23920 "Renvoi de sort" --renvoyez le prochain sort lancé sur vous. Dure 5 s. Buff same spellId
		{ warrior.spells["SpellReflection"] , jps.ShouldKick(rangedTarget) and jps.UnitIsUnit("targettarget","player") , rangedTarget , "_SpellReflection" },
		{ warrior.spells["SpellReflection"] , jps.ShouldKick("focus") and jps.UnitIsUnit("focustarget","player") , "focus" , "_SpellReflection" },
		-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
		{ warrior.spells["MassSpellReflection"] , jps.UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "_MassSpell" },
	}},
		
	-- DEFENSIVE
	-- "Berserker Rage" 18499 "Rage de berserker"
	{ warrior.spells["BerserkerRage"] , not Enrage , rangedTarget , "_BerserkerRage" },
	-- "Shield Wall"
	{ warrior.spells["ShieldWall"] , jps.UseCDs and jps.hp() < 0.30 , rangedTarget , "_ShieldWall" },
	-- "Last Stand" 
	{ warrior.spells["LastStand"] , jps.UseCDs and  jps.hp() < 0.40 , rangedTarget , "_LastStand" },
	-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
	{ warrior.spells["ImpendingVictory"] , playerhealth_pct < 0.85 , rangedTarget , "_ImpendingVictory" },
	{ warrior.spells["VictoryRush"] , playerhealth_pct <  0.85 , rangedTarget , "_VictoryRush" },
	-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
	{ warrior.spells["ImpendingVictory"] , jps.buffDuration(32216) < 4 , rangedTarget , "_ImpendingVictory" },
	{ warrior.spells["VictoryRush"] , jps.buffDuration(32216) < 4 , rangedTarget , "_VictoryRush" },
	-- "Enraged Regeneration" 55694 "Régénération enragée"
	{ warrior.spells["EnragedRegeneration"] , playerhealth_pct < 0.70 , rangedTarget , "_EnragedRegeneration" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and playerhealth_pct < 0.85 , rangedTarget , "_Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },

	-- "Shield Block" 2565 "Maîtrise du blocage" -- works against physical attacks, but it does nothing against magic
	{ warrior.spells["ShieldBlock"] , jps.hp() < 0.80 , rangedTarget , "_ShieldBlock" },
	-- "Shield Barrier" 112048 "Barrière protectrice" -- Shield Barrier works against all types of damage (excluding fall damage).
	{ warrior.spells["ShieldBarrier"] , jps.hp() < 0.80 , rangedTarget , "_ShieldBarrier" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket0"},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket1"},

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ warrior.spells["HeroicThrow"] , jps.IsSpellInRange(57755,rangedTarget) , rangedTarget , "_Heroic Throw" },
	-- "Charge" 100
	{ warrior.spells["Charge"], jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
	-- "Piercing Howl" 12323 "Hurlement percant"
	--{ warrior.spells["PiercingHowl"] , not jps.debuff(12323,rangedTarget) , rangedTarget , "_PiercingHowl"},
	-- "Intimidating Shout" 5246
	{ warrior.spells["IntimidatingShout"] , not jps.debuff(5246,rangedTarget) and isBoss , rangedTarget , "_IntimidatingShout"},
	-- "Bloodbath" 12292 "Bain de sang"  -- jps.buff(12292)
	{ warrior.spells["Bloodbath"], jps.combatStart > 0 , rangedTarget , "_Bloodbath" },
	
	-- MULTITARGET --
	{"nested", (jps.MultiTarget or EnemyCount > 2) ,{

		-- "Ravager" 152277 -- 40 yd range
		{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "_Ravager" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.IsSpellKnown(46968) , rangedTarget , "_Shockwave" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ warrior.spells["ThunderClap"] , jps.IsSpellInRange(6343,rangedTarget) , rangedTarget , "_ThunderClap" },

	}},

	-- SINGLETARGET --
	-- "Shield Slam" 23922 "Heurt de bouclier" -- "Sword and Board" 50227 "Epée et bouclier"
	{ warrior.spells["ShieldSlam"] , jps.buff(50227) , rangedTarget , "_ShieldSlam_SwordBoard" },
	-- "Shield Slam" 23922 "Heurt de bouclier"
	{ warrior.spells["ShieldSlam"] , true , rangedTarget , "_ShieldSlam" },
	-- "Revenge" 6572 "Revanche"
	{ warrior.spells["Revenge"] , true , rangedTarget , "_Revenge" },
	-- "Execute" 5308 "Exécution" -- "Mort soudaine" 29725
	{ warrior.spells["Execute"], jps.buff(29725) , rangedTarget , "_Execute_SuddenDeath" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- "Ultimatum" 122509
	{ warrior.spells["HeroicStrike"] , jps.buff(122509) , rangedTarget , "_HeroicStrike_Ultimatum" },
	-- "Execute" 5308 "Exécution"
	{ warrior.spells["Execute"], jps.rage() > 70 and jps.hp(rangedTarget) < 0.20 , rangedTarget , "_Execute" },
	--- "Heroic Strike" 78 "Frappe héroïque"
	{ warrior.spells["HeroicStrike"] , jps.rage() > 70 and jps.hp(rangedTarget) > 0.20 , rangedTarget , "_HeroicStrike_Rage" },
	-- "Dévaster" 20243 "Devastate"
	{ warrior.spells["Devastate"] , true , rangedTarget , "_Devastate" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default")