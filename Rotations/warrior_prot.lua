-- jps.UseCDs for "Charge"
-- jps.Interrupts for "Pummel"
-- jps.Defensive for "Provocation"

local L = MyLocalizationTable
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local PhysicalDamage = false
local MagicDamage = false
local canAttack = jps.CanAttack

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

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("WARRIOR","PROTECTION",function()

local spell = nil
local target = nil

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER

local inMelee = jps.IsSpellInRange(20243,"target") -- "Dévaster" 20243 "Devastate"
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"
-- currentCharges, maxCharges, cooldownStart, cooldownDuration = GetSpellCharges(spellId or "spellName")
local ShieldCharge  = GetSpellCharges(156321)

local myTank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if UnitCanAssist("player",myTank) then TankTarget = myTank.."target" end
	
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
	if jps.UnitIsUnit("mouseovertarget","player") and not jps.UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy healer
	elseif jps.EnemyHealer("mouseover") then
		jps.Macro("/focus mouseover")
		print("Enemy HEALER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy in combat
	elseif canDPS("mouseover") and not jps.UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end

-- CONFIG jps.getConfigVal("keep focus") if you want to keep focus
if jps.UnitExists("focus") and jps.UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	if jps.getConfigVal("keep focus") == false then jps.Macro("/clearfocus") end
end

if canAttack("target") then rangedTarget =  "target"
elseif jps.buff(156291) and canAttack(TankTarget) then rangedTarget = TankTarget -- "Gladiator Stance" 156291
elseif canAttack("targettarget") then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

--if jps.buff(156291) and jps.UnitIsUnit("targettarget","player") then
--	SpellStopCasting()
--	spell = 20243;
--	target = "target";
--	if jps.combatStart > 0 then write("AGGRO_STOPCASTING") end
--return spell,target end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "Heroic Leap" 6544 "Bond héroïque"
	{ warrior.spells["HeroicLeap"] , IsControlKeyDown() , "player" },
	
	-- BUFFS
	-- "Gladiator Stance" 156291 -- Talent "Gladiator's Resolve" 152276
	{ 156291, jps.IsSpellKnown(152276) and not jps.buff(156291) and not jps.buff(71) , "player" },
	-- "Defensive Stance" 71
	{ warrior.spells["DefensiveStance"] , not jps.buff(71) and not jps.buff(156291), "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , not jps.hasAttackPowerBuff("player") , "player" },
	-- "Commanding Shout" 469 "Cri de commandement"
	{ 469 , jps.hasAttackPowerBuff("player") and jps.myBuffDuration(6673,"player") == 0 and not jps.buff(469) , "player" },

	-- INTERRUPTS --
	-- "Spell Reflection" 23920 "Renvoi de sort" --renvoyez le prochain sort lancé sur vous. Dure 5 s. Buff same spellId
	{ warrior.spells["SpellReflection"] , jps.ShouldKick(rangedTarget) and jps.UnitIsUnit("targettarget","player") , rangedTarget , "SpellReflection" },
	{ warrior.spells["SpellReflection"] , jps.ShouldKick("focus") and jps.UnitIsUnit("focustarget","player") , "focus" , "SpellReflection" },
	-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
	{ warrior.spells["MassSpellReflection"] , jps.UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "MassSpell" },
	{ warrior.spells["MassSpellReflection"] , jps.UnitIsUnit("focustarget","player") and jps.IsCasting("focus") , "focus" , "MassSpell" },
	-- "Pummel" 6552 "Volée de coups"
	{ warrior.spells["Pummel"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "Pummel" },
	{ warrior.spells["Pummel"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" , "Pummel" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 },
	{ jps.useTrinket(1), jps.PvP and jps.useTrinketBool(1) and playerIsStun },
	{ jps.useTrinket(1), not jps.PvP and jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 },
	
	-- "Revenge" 6572 "Revanche"
	{ warrior.spells["Revenge"] , inMelee , rangedTarget , "Revenge" },
	-- "Shield Slam" 23922 "Heurt de bouclier" -- Buff "Sword and Board" 50227 "Epée et bouclier"
	{ warrior.spells["ShieldSlam"] , jps.buff(50227) , rangedTarget , "ShieldSlam_SwordBoard" },
	{ warrior.spells["ShieldSlam"] , true , rangedTarget , "ShieldSlam" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Ultimatum" 122509 -- HS cost no rage & crtique
	{ warrior.spells["HeroicStrike"] , jps.buffStacks(169686) == 6 , rangedTarget , "HeroicStrike_6_Strikes" },
	{ warrior.spells["HeroicStrike"] , jps.buff(122509) , rangedTarget , "HeroicStrike_Ultimatum" },
	-- "Execute" 5308 "Exécution" -- Buff "Mort soudaine" 29725
	{ 5308, jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },

	-- DEFENSIVE
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and jps.hp() < 0.80 , rangedTarget , "|cff1eff00Stoneform_Health" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "|cff1eff00Stoneform_Dispel" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.80 and jps.itemCooldown(5512) == 0 , "player" , "Item5512" },
	-- "Proteger" 114029 -- "Intervention" 3411
	{ 3411, not jps.UnitIsUnit(myTank,"player") and jps.hp(myTank) < 0.30 and jps.hp("player") > 0.85 and UnitCanAssist("player",myTank) , myTank , "Intervention_myTank" },
	{ 114029, not jps.UnitIsUnit(myTank,"player") and jps.hp(myTank) < 0.30 and jps.hp("player") > 0.85 and UnitCanAssist("player",myTank) , myTank , "Proteger_myTank" },
	{ 3411, not jps.UnitIsUnit("targettarget","player") and jps.hp("targettarget") < 0.30 and jps.hp("player") > 0.85 , "targettarget" , "Intervention_Aggro" },
	{ 114029, not jps.UnitIsUnit("targettarget","player") and jps.hp("targettarget") < 0.30 and jps.hp("player") > 0.85 , "targettarget" , "Proteger_Aggro" },
	-- "Provocation" 355
	{ 355, jps.Defensive and jps.buff(71) and not jps.UnitIsUnit("targettarget","player") , "target" , "Provocation" },
	-- "Demoralizing Shout" 1160 "Cri démoralisant"
	{ 1160, playerAggro and not jps.debuff(1160,rangedTarget) , rangedTarget , "Demoralizing" },

	-- "Last Stand" 12975 "Dernier rempart" -- 3 min
	{ warrior.spells["LastStand"] , jps.hp("player") < 0.30 , rangedTarget , "|cff1eff00LastStand" },	
	-- "Shield Block" 2565 "Maîtrise du blocage" -- works against physical attacks, it does nothing against magic -- Buff "Shield Block" 132404 -- 60 rage
	{ warrior.spells["ShieldBlock"] , jps.buff(71) and PhysicalDamage and not jps.buff(132404) and jps.hp("player") < 0.80 , rangedTarget , "|cff1eff00ShieldBlock_PhysicalDmg" },
	-- "Shield Barrier" 112048 "Barrière protectrice" -- Shield Barrier works against all types of damage (excluding fall damage) -- 20 + 40 rage
	{ warrior.spells["ShieldBarrier"] , jps.buff(71) and MagicDamage and not jps.buff(112048) and jps.hp("player") < 0.80 , rangedTarget , "|cff1eff00ShieldBarrier_MagicDmg" },
	{ warrior.spells["ShieldBarrier"] , not jps.buff(112048) and playerAggro and jps.hp("player") < 0.50 , rangedTarget , "|cff1eff00ShieldBarrier" },
	-- "Shield Wall" 871 "Mur protecteur" -- cd 2 min
	{ warrior.spells["ShieldWall"] , jps.hp("player") < 0.50 , rangedTarget , "|cff1eff00ShieldWall" },

	-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
	{ warrior.spells["ImpendingVictory"] , jps.hp("player") < 0.80 , rangedTarget , "|cff1eff00ImpendingVictory" },
	{ warrior.spells["VictoryRush"] , jps.hp("player") <  0.80 , rangedTarget , "|cff1eff00VictoryRush" },
	-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
	{ warrior.spells["ImpendingVictory"] , jps.buffDuration(32216) < 4 , rangedTarget , "|cff1eff00ImpendingVictory_Duration" },
	{ warrior.spells["VictoryRush"] , jps.buffDuration(32216) < 4 , rangedTarget , "|cff1eff00VictoryRush_Duration" },
	-- "Enraged Regeneration" 55694 "Régénération enragée"
	{ warrior.spells["EnragedRegeneration"] , playerAggro and jps.hp() < 0.80 , rangedTarget , "|cff1eff00EnragedRegeneration" },

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ warrior.spells["HeroicThrow"] , inRanged and not inMelee , rangedTarget , "Heroic Throw" },
	-- "Charge" 100
	{ warrior.spells["Charge"], jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "Charge"},
	-- "Intimidating Shout" 5246
	{ warrior.spells["IntimidatingShout"] , playerAggro and not jps.debuff(5246,rangedTarget) , rangedTarget , "IntimidatingShout"},
	-- "Berserker Rage" 18499 "Rage de berserker" -- "Enrage" 12880 "Enrager"
	{ warrior.spells["BerserkerRage"] , not jps.buff(12880) , rangedTarget , "|cFFFF0000BerserkerRage" },

	-- TALENTS --
	-- "Bloodbath" 12292 "Bain de sang" -- Buff 12292
	{ warrior.spells["Bloodbath"], inMelee and jps.MultiTarget , rangedTarget , "|cFFFF0000Bloodbath" },
	{ warrior.spells["Bloodbath"], inMelee and jps.rage() > 89 , rangedTarget , "|cFFFF0000Bloodbath_DumpRage" },
	{ warrior.spells["Bloodbath"], inMelee and jps.rage() > 59 and jps.buffStacks(169686) > 3 , rangedTarget , "|cFFFF0000Bloodbath_BuffStrikes" },
	-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range
	{ warrior.spells["StormBolt"] , jps.IsSpellKnown(107570) , rangedTarget ,"StormBolt" },
	-- "Dragon Roar " 118000 -- 8 yards
	{ warrior.spells["DragonRoar"] , jps.IsSpellKnown(118000) and inMelee , rangedTarget , "DragonRoar" },
	-- "Bladestorm" 46924 "Tempête de lames"
	{ warrior.spells["Bladestorm"] , jps.IsSpellKnown(46924) and inMelee , rangedTarget , "Bladestorm" },
	-- "Ravager" 152277 -- 40 yd range
	{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "Ravager" },

	-- MULTITARGET --
	{"nested", jps.MultiTarget and inMelee ,{
		-- "Bladestorm" 46924 "Tempête de lames"
		{ warrior.spells["Bladestorm"] , jps.IsSpellKnown(46924) , rangedTarget , "Bladestorm" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.IsSpellKnown(46968) , rangedTarget , "Shockwave" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ warrior.spells["ThunderClap"] , true , rangedTarget , "ThunderClap" },
	}},

	-- "Shield Charge" 156321 "Charge de bouclier" -- Buff "Shield Charge" 169667 -- "Bloodbath" 12292 "Bain de sang"
	-- Increasing the damage of Shield Slam, Revenge, and Heroic Strike by 25% for 7 sec.
	{"nested", jps.buff(156291) and jps.buffDuration(169667) < 2 and inMelee ,{
		{ 156321, inMelee and ShieldCharge == 2 , rangedTarget , "|cffa335eeShieldCharge" },
		{ 156321, inMelee and jps.rage() > 59 and jps.buffStacks(169686) > 3 , rangedTarget , "|cffa335eeShieldCharge_Strikes" },
		{ 156321, inMelee and jps.rage() > 89 , rangedTarget , "|cffa335eeShieldCharge_Rage" },
		{ 156321, inMelee and jps.buff(12292) , rangedTarget , "|cffa335eeShieldCharge_Bloodbath" },
	}},

	-- SINGLETARGET -- "Gladiator Stance" 156291
	-- "Dévaster" 20243 "Devastate" -- Buff "Unyielding Strikes" 169686 "Frappes inflexibles" 169686 -- Cumulable jusqu’à 6 fois
	{ warrior.spells["Devastate"] , jps.buffDuration(169686) < 2 , rangedTarget , "Devastate_BuffDuration" },
	-- "Execute" 5308 "Exécution" -- Buff "Mort soudaine" 29725
	{ 5308, not jps.buff(169667) and jps.hp(rangedTarget) < 0.20 , rangedTarget , "Execute_UnBuff" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Shield Charge" 169667
	{ warrior.spells["HeroicStrike"] , jps.buff(169667) , rangedTarget , "HeroicStrike_ShieldCharge" },
	{ warrior.spells["HeroicStrike"] , jps.buffStacks(169686) > 3 , rangedTarget , "HeroicStrike_4_BuffStrikes" },
	{ warrior.spells["HeroicStrike"] , jps.rage() > 89 and jps.hp(rangedTarget) > 0.20 , rangedTarget , "HeroicStrike_DumpRage" },
	-- "Dévaster" 20243 "Devastate" -- Dévaster réduit le coût en rage de Frappe héroïque de 5 pendant 5 s.
	{ warrior.spells["Devastate"] , true , rangedTarget , "Devastate" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default")

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- spellSchool == 1 Physical, 2 Holy, 4 Fire, 8 Nature, 16 Frost, 32 Shadow, 64 Arcane
jps.listener.registerCombatLogEventUnfiltered("SPELL_DAMAGE", function(...)
	local sourceGUID = select(4,...)
	local destGUID = select(8,...)
	local spellID =  select(12,...)
	local spellSchool =  select(17,...)
	if destGUID == UnitGUID("player") and spellSchool then
		if spellSchool == 1 then
			PhysicalDamage = true
			MagicDamage = false
		else
			PhysicalDamage = false
			MagicDamage = true
		end
	end
end)