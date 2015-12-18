-- jps.UseCDs for "Charge"
-- jps.Interrupts for "Pummel"
-- jps.Defensive for "Provocation"

local L = MyLocalizationTable
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.CanAttack
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit
local toSpellName = jps.toSpellName

-- "Shield Charge" 156321 "Charge de bouclier"
warrior.spells["ShieldCharge"] = toSpellName(156321)

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

local currentCharges, _, cooldownStart, cooldownDuration = GetSpellCharges(156321) -- (spellId or "spellName")
local ShieldChargeReady = true
if currentCharges == 1 and jps.rage() < 109 and jps.cooldown(12292) > 0 and jps.cooldown(12292) < 8 then ShieldChargeReady = false end

local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if UnitCanAssist("player",Tank) then TankTarget = Tank.."target" end
local TankThreat = jps.findThreatInRaid()
local playerIsTanking = false
if UnitIsUnit("player",TankThreat) then playerIsTanking = true end
	
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
		--print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy healer
	elseif jps.EnemyHealer("mouseover") then
		jps.Macro("/focus mouseover")
		--print("Enemy HEALER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy in combat
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
elseif canDPS(TankTarget) and not DebuffUnitCyclone(rangedTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") and not DebuffUnitCyclone(rangedTarget) then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

local TankBossDebuff = jps.BossDebuff("player")
if jps.hp("player") < 0.25 then CreateMessage("LOW HEALTH!") -- CreateFlasher()
elseif TankBossDebuff then CreateMessage("BOSS DEBUFF!") end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {
	
	-- BUFFS
	-- "Gladiator Stance" 156291 -- Talent "Gladiator's Resolve" 152276
	{ warrior.spells["GladiatorStance"], jps.IsSpellKnown(152276) and not jps.buff(156291) and not jps.buff(71) , "player" },
	-- "Defensive Stance" 71
	{ warrior.spells["DefensiveStance"] , not jps.buff(71) and not jps.buff(156291), "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , not jps.hasAttackPowerBuff("player") , "player" },
	-- "Commanding Shout" 469 "Cri de commandement"
	{ warrior.spells["CommandingShout"] , jps.hasAttackPowerBuff("player") and jps.myBuffDuration(6673,"player") == 0 and not jps.buff(469) , "player" },
	
	-- "Heroic Leap" 6544 "Bond héroïque"
	{ warrior.spells["HeroicLeap"] , IsControlKeyDown() , "player" },
	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ warrior.spells["HeroicThrow"] , inRanged and not inMelee , rangedTarget , "Heroic Throw" },
	-- "Charge" 100
	{ warrior.spells["Charge"], jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "Charge"},

	-- INTERRUPTS --
	-- "Pummel" 6552 "Volée de coups"
	{ warrior.spells["Pummel"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "Pummel" },
	{ warrior.spells["Pummel"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" , "Pummel" },
	-- "Spell Reflection" 23920 "Renvoi de sort" --renvoyez le prochain sort lancé sur vous. Dure 5 s. Buff same spellId
	{ warrior.spells["SpellReflection"] , jps.IsCasting(rangedTarget) and UnitIsUnit("targettarget","player") , rangedTarget , "SpellReflection" },
	{ warrior.spells["SpellReflection"] , jps.IsCasting("focus") and UnitIsUnit("focustarget","player") , "focus" , "SpellReflection" },
	-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
	{ warrior.spells["MassSpellReflection"] , jps.IsCasting(rangedTarget) and UnitIsUnit("targettarget","player")  , rangedTarget , "MassSpell" },
	{ warrior.spells["MassSpellReflection"] , jps.IsCasting("focus") and UnitIsUnit("focustarget","player") , "focus" , "MassSpell" },
	
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "|cff1eff00Stoneform_Dispel" },

	-- "Proteger" 114029 -- "Intervention" 3411
	{ 3411, IsInGroup() and not UnitIsUnit(Tank,"player") and jps.hp(Tank) < 0.30 and jps.hp("player") > 0.85 and UnitCanAssist("player",Tank) , Tank , "Intervention_myTank" },
	{ 114029, IsInGroup() and not UnitIsUnit(Tank,"player") and jps.hp(Tank) < 0.30 and jps.hp("player") > 0.85 and UnitCanAssist("player",Tank) , Tank , "Proteger_myTank" },
	{ 3411, IsInGroup() and not UnitIsUnit("targettarget","player") and jps.hp("targettarget") < 0.30 and jps.hp("player") > 0.85 and UnitCanAssist("player","targettarget") , "targettarget" , "Intervention_Aggro" },
	{ 114029, IsInGroup() and not UnitIsUnit("targettarget","player") and jps.hp("targettarget") < 0.30 and jps.hp("player") > 0.85 and UnitCanAssist("player","targettarget") , "targettarget" , "Proteger_Aggro" },
	-- "Provocation" 355
	{ 355, jps.Defensive and jps.buff(71) and not UnitIsUnit("targettarget","player") , "target" , "Provocation" },
	-- "Demoralizing Shout" 1160 "Cri démoralisant"
	{ warrior.spells["DemoralizingShout"], playerIsTanking and not jps.debuff(1160,rangedTarget) , rangedTarget , "Demoralizing" },
	
	-- "Revenge" 6572 "Revanche"
	{ warrior.spells["Revenge"] , inMelee , rangedTarget , "Revenge" },
	-- "Shield Slam" 23922 "Heurt de bouclier" -- Buff "Sword and Board" 50227 "Epée et bouclier" -- Buff "Shield Charge" 169667
	{ warrior.spells["ShieldSlam"] , inMelee and jps.buff(71) , rangedTarget , "ShieldSlam_1" },
	{ warrior.spells["ShieldSlam"] , inMelee and jps.buff(71) and jps.buff(50227) , rangedTarget , "ShieldSlam_SwordBoard_1" },
	{ warrior.spells["ShieldSlam"] , inMelee and jps.buff(156291) and jps.buff(169667) , rangedTarget , "ShieldSlam_1" },
	{ warrior.spells["ShieldSlam"] , inMelee and jps.buff(156291) and jps.buff(50227) and jps.buff(169667) , rangedTarget , "ShieldSlam_SwordBoard_1" },
	-- "Ravager" 152277 "Ravageur"
	{ warrior.spells["Ravager"] , jps.buff(71) and jps.IsSpellKnown(152277) , rangedTarget , "Ravager" },

	-- DEFENSIVE HEALTH
	-- "Last Stand" 12975 "Dernier rempart" -- 3 min
	{ warrior.spells["LastStand"] , jps.hpInc("player") < 0.40 and jps.IncomingDamage("player") > 0 , rangedTarget , "|cff1eff00LastStand" },
	-- "Shield Wall" 871 "Mur protecteur" -- cd 2 min
	{ warrior.spells["ShieldWall"] , jps.hpInc("player") < 0.60 and jps.IncomingDamage("player") > 0 , rangedTarget , "|cff1eff00ShieldWall" },
	-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
	{ warrior.spells["ImpendingVictory"] , jps.buff(32216) and jps.hp("player") < 0.80 , rangedTarget , "|cff1eff00ImpendingVictory_Health" },
	{ warrior.spells["VictoryRush"] , jps.buff(32216) and jps.hp("player") <  0.80 , rangedTarget , "|cff1eff00VictoryRush_Health" },
	-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
	{ warrior.spells["ImpendingVictory"] , jps.buff(32216) and jps.buffDuration(32216) < 4 , rangedTarget , "|cff1eff00ImpendingVictory_Duration" },
	{ warrior.spells["VictoryRush"] , jps.buff(32216) and jps.buffDuration(32216) < 4 , rangedTarget , "|cff1eff00VictoryRush_Duration" },
	-- "Enraged Regeneration" 55694 "Régénération enragée"
	{ warrior.spells["EnragedRegeneration"] , playerIsTanking and jps.hp("player") < 0.60 and jps.hpInc("player") < 0.80 , rangedTarget , "|cff1eff00EnragedRegeneration_Threat" },
	{ warrior.spells["EnragedRegeneration"] , playerAggro and jps.hp("player") < 0.60 and jps.hpInc("player") < 0.80 , rangedTarget , "|cff1eff00EnragedRegeneration_Aggro" },

	-- DEFENSIVE DAMAGE
	{"nested", jps.buff(71) and TankBossDebuff and jps.hpSum("player") < 0.80 ,{
		{ warrior.spells["ShieldBlock"] , jps.SchoolDamage("physical") and not jps.buff(132404) , rangedTarget , "|cff1eff00ShieldBlock_PhysicalDmg_TankBossDebuff" },
		{ warrior.spells["ShieldBarrier"] , jps.SchoolDamage("magic") and not jps.buff(112048) , rangedTarget , "|cff1eff00ShieldBarrier_MagicDmg_TankBossDebuff" },
	}},
	
	-- player.hasBuff(spells.shieldWall) or player.hasBuff(spells.lastStand) or player.hasBuff(spells.enragedRegeneration)
	{ warrior.spells["ShieldBarrier"] , jps.buff(71) and not jps.buff(112048) and jps.IncomingDamage("player") > UnitHealthMax("player")*0.10 , rangedTarget , "|cff1eff00ShieldBarrier_IncDmg" },
	
	{"nested", jps.buff(71) and jps.hp("player") < 0.80 and jps.hpSum("player") < 0.80 ,{
		-- "Shield Block" 2565 "Maîtrise du blocage" -- works against physical attacks, it does nothing against magic -- Buff "Shield Block" 132404 -- 60 rage
		{ warrior.spells["ShieldBlock"] , jps.SchoolDamage("physical") and not jps.buff(132404) , rangedTarget , "|cff1eff00ShieldBlock_Physical" },
		-- "Shield Barrier" 112048 "Barrière protectrice" -- Shield Barrier works against all types of damage (excluding fall damage) -- 20 + 40 rage
		{ warrior.spells["ShieldBarrier"] , jps.SchoolDamage("magic") and not jps.buff(112048) , rangedTarget , "|cff1eff00ShieldBarrier_Magic" },
		{ warrior.spells["ShieldBarrier"] , playerIsTanking and not jps.buff(112048) , rangedTarget , "|cff1eff00ShieldBarrier_Threat" },
	}},
	
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, playerAggro and jps.hp("player") < 0.80 and jps.itemCooldown(5512) == 0 , "player" , "Item5512" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and jps.hp("player") < 0.80 , rangedTarget , "|cff1eff00Stoneform_Health" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 },
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.buff(12292) and jps.combatStart > 0 },
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun and jps.combatStart > 0 },
	
	-- "Berserker Rage" 18499 "Rage de berserker" -- "Enrage" 12880 "Enrager" -- Buff "Shield Charge" 169667 -- "Bloodbath" 12292 "Bain de sang"
	{ warrior.spells["BerserkerRage"] , not jps.buff(12880) and jps.buff(169667) , rangedTarget , "|cFFFF0000BerserkerRage" },
	{ warrior.spells["BerserkerRage"] , not jps.buff(12880) and jps.buff(12292) , rangedTarget , "|cFFFF0000BerserkerRage" },
	{ warrior.spells["BerserkerRage"] , not jps.buff(12880) and jps.rage() > 89 , rangedTarget , "|cFFFF0000BerserkerRage" },
	
	-- MULTITARGET
	{"nested", jps.MultiTarget and inMelee ,{
		-- "Bladestorm" 46924 "Tempête de lames"
		{ warrior.spells["Bladestorm"] , jps.IsSpellKnown(46924) , rangedTarget , "Bladestorm" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.IsSpellKnown(46968) , rangedTarget , "Shockwave" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ warrior.spells["ThunderClap"] , inMelee , rangedTarget , "ThunderClap" },
	}},

	-- TALENTS
	{"nested", jps.buff(12880) ,{
		-- "Ravager" 152277 -- 40 yd range
		{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "Ravager_Enrage" },
		-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range
		{ warrior.spells["StormBolt"] , jps.IsSpellKnown(107570) , rangedTarget ,"StormBolt_Enrage" },
		-- "Dragon Roar " 118000 -- 8 yards
		{ warrior.spells["DragonRoar"] , jps.IsSpellKnown(118000) and inMelee , rangedTarget , "DragonRoar_Enrage" },
		-- "Bladestorm" 46924 "Tempête de lames"
		{ warrior.spells["Bladestorm"] , jps.IsSpellKnown(46924) and inMelee , rangedTarget , "Bladestorm_Enrage" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.IsSpellKnown(46968) and inMelee , rangedTarget , "Shockwave_Enrage" },
	}},

	-- "Shield Charge" 156321 "Charge de bouclier" -- Buff "Shield Charge" 169667 -- "Bloodbath" 12292 "Bain de sang"
	-- Increasing the damage of "Shield Slam" 23922 "Heurt de bouclier" , "Revenge" 6572 "Revanche" and "Heroic Strike" 78 "Frappe héroïque" by 25% for 7 sec
	{"nested", jps.buff(156291) and not jps.buff(169667) and inMelee and ShieldChargeReady ,{
		{ warrior.spells["ShieldCharge"], jps.rage() > 29 and ShieldCharge == 2 , rangedTarget , "|cffa335eeShieldCharge_2" },
		-- Buff "Unyielding Strikes" 169686 "Frappes inflexibles" 169686 -- Cumulable jusqu’à 6 fois
		{ warrior.spells["ShieldCharge"], jps.buffStacks(169686) == 6 , rangedTarget , "|cffa335eeShieldCharge_6_Strikes" },
		-- "Shield Slam" 23922 "Heurt de bouclier" -- Buff "Sword and Board" 50227 "Epée et bouclier"
		{ warrior.spells["ShieldCharge"], jps.rage() > 29 and jps.buff(50227) and jps.buffStacks(169686) > 3 , rangedTarget , "|cffa335eeShieldCharge_ShieldSlam_SwordBoard" },
		-- "Enrage" 12880 "Enrager"
		{ warrior.spells["ShieldCharge"], jps.rage() > 29 and jps.buffDuration(12880) > 5 and jps.buffStacks(169686) > 3 , rangedTarget , "|cffa335eeShieldCharge_Enrage" },
		-- "Bloodbath" 12292 "Bain de sang" -- Buff 12292
		{ warrior.spells["ShieldCharge"], jps.buffDuration(12292) > 5 , rangedTarget , "|cffa335eeShieldCharge_Bloodbath" },
		-- Dump Rage
		{ warrior.spells["ShieldCharge"], jps.rage() > 89 , rangedTarget , "|cffa335eeShieldCharge_DumpRage" },
	}},
	
	-- "Bloodbath" 12292 "Bain de sang" -- "Shield Slam" 23922 "Heurt de bouclier" -- "Revenge" 6572 "Revanche"
	{"nested", inMelee and jps.rage() > 29 ,{
		-- Buff "Unyielding Strikes" 169686 "Frappes inflexibles" 169686 -- Cumulable jusqu’à 6 fois
		{ warrior.spells["Bloodbath"], jps.buffStacks(169686) == 6 , rangedTarget , "|cFFFF0000Bloodbath_6_Strikes" },
		-- "Shield Slam" 23922 "Heurt de bouclier"
		{ warrior.spells["Bloodbath"], jps.buff(50227) and jps.buffStacks(169686) > 3 , rangedTarget , "|cFFFF0000Bloodbath_ShieldSlam_SwordBoard" },
		-- "Enrage" 12880 "Enrager"
		{ warrior.spells["Bloodbath"], jps.buffDuration(12880) > 5 and jps.buffStacks(169686) > 3 , rangedTarget , "|cFFFF0000Bloodbath_Enrage" },
		-- "Shield Charge" 156321 "Charge de bouclier" -- Buff "Shield Charge" 169667
		{ warrior.spells["Bloodbath"], jps.buffDuration(169667) > 5 , rangedTarget , "|cFFFF0000Bloodbath_ShieldCharge" },
		-- Dump Rage
		{ warrior.spells["Bloodbath"], jps.rage() > 89 , rangedTarget , "|cFFFF0000Bloodbath_DumpRage" },
	}},
	
	-- DAMAGE
	-- "Dévaster" 20243 "Devastate" -- Buff "Unyielding Strikes" 169686 "Frappes inflexibles" 169686 -- Cumulable jusqu’à 6 fois
	{ warrior.spells["Devastate"] , inMelee and jps.buffDuration(169686) < 1 and jps.buffStacks(169686) < 6 , rangedTarget , "Devastate_BuffDuration" },
	-- "Shield Slam" 23922 "Heurt de bouclier" -- Buff "Sword and Board" 50227 "Epée et bouclier"
	{ warrior.spells["ShieldSlam"] , inMelee and jps.buff(50227) , rangedTarget , "ShieldSlam_SwordBoard_2" },
	{ warrior.spells["ShieldSlam"] , inMelee , rangedTarget , "ShieldSlam_2" },

	-- "Execute" 5308 "Exécution" -- Buff "Mort soudaine" 29725
	{ warrior.spells["Execute"], jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },
	{ warrior.spells["Execute"] , not jps.buff(169667) and jps.hp(rangedTarget) < 0.20 and jps.rage() > 59 , rangedTarget , "Execute_UnBuff_Rage" },

	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Unyielding Strikes" 169686 "Frappes inflexibles" 169686 -- Cumulable jusqu’à 6 fois
	{ warrior.spells["HeroicStrike"] , jps.buffStacks(169686) == 6 , rangedTarget , "HeroicStrike_6_Strikes" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Ultimatum" 122509 -- HS cost no rage & crtique
	{ warrior.spells["HeroicStrike"] , jps.buff(122509) , rangedTarget , "HeroicStrike_Ultimatum" },
	{ warrior.spells["HeroicStrike"] , jps.rage() > 89 and jps.hp(rangedTarget) > 0.20 , rangedTarget , "HeroicStrike_DumpRage" },
	-- "Execute" 5308 "Exécution"
	{ warrior.spells["Execute"], jps.rage() > 89 and jps.hp(rangedTarget) < 0.20 , rangedTarget , "Execute_DumpRage" },
	
	-- "Shield Barrier" 112048 "Barrière protectrice"
	{ warrior.spells["ShieldBarrier"], playerAggro and jps.hpInc("player") < 0.80 and not jps.buff(112048) , rangedTarget , "|cff1eff00ShieldBarrier_Aggro" },
	{ warrior.spells["ShieldBarrier"], TankBossDebuff and jps.hpInc("player") < 0.80 and not jps.buff(112048) , rangedTarget , "|cff1eff00ShieldBarrier_Debuff" },

	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Shield Charge" 169667
	{ warrior.spells["HeroicStrike"] , jps.buff(169667) and jps.buffStacks(169686) > 3 , rangedTarget , "HeroicStrike_ShieldCharge_Strikes" },
	{ warrior.spells["HeroicStrike"] , jps.buff(169667) and jps.rage() > 59 , rangedTarget , "HeroicStrike_ShieldCharge_Rage" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- "Bloodbath" 12292 "Bain de sang"
	{ warrior.spells["HeroicStrike"] , jps.buff(12292) and jps.buffStacks(169686) > 3 , rangedTarget , "HeroicStrike_Bloodbath_Strikes" },
	{ warrior.spells["HeroicStrike"] , jps.buff(12292) and jps.rage() > 59 , rangedTarget , "HeroicStrike_Bloodbath_Rage" },
	-- "Dévaster" 20243 "Devastate" -- Dévaster réduit le coût en rage de Frappe héroïque de 5 pendant 5 s.
	{ warrior.spells["Devastate"] , inMelee , rangedTarget , "Devastate" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Protection")


jps.registerStaticTable("WARRIOR","PROTECTION",{

	-- "Enraged Regeneration" 55694 "Régénération enragée"
	{ warrior.spells["EnragedRegeneration"] , 'jps.hp("player") < 0.70' , "target" },
	-- "Pummel" 6552 "Volée de coups"
	{ warrior.spells["Pummel"] , 'jps.Interrupts and jps.ShouldKick("target")' , "target" },
	-- "Demoralizing Shout" 1160 "Cri démoralisant"
	{ warrior.spells["DemoralizingShout"], 'not jps.debuff(1160,"target")' , "target" },
	-- "Last Stand" 12975 "Dernier rempart" -- 3 min
	{ warrior.spells["LastStand"] , 'jps.hpInc("player") < 0.40 and jps.IncomingDamage("player") > 0' , "target" },
	-- "Shield Wall" 871 "Mur protecteur" -- cd 2 min
	{ warrior.spells["ShieldWall"] , 'jps.hpInc("player") < 0.60 and jps.IncomingDamage("player") > 0' , "target" },
	-- "Enraged Regeneration" 55694 "Régénération enragée"
	{ warrior.spells["EnragedRegeneration"] , 'jps.IncomingDamage("player") > 0 and jps.hp("player") < 0.60 and jps.hpInc("player") < 0.80' , "target" },

	-- "Shield Block" 2565 "Maîtrise du blocage" -- works against physical attacks, it does nothing against magic -- Buff "Shield Block" 132404 -- 60 rage
	{ warrior.spells["ShieldBlock"] , 'jps.SchoolDamage("physical") and not jps.buff(132404)' , "target" },
	-- "Shield Barrier" 112048 "Barrière protectrice" -- Shield Barrier works against all types of damage (excluding fall damage) -- 20 + 40 rage
	{ warrior.spells["ShieldBarrier"] , 'jps.SchoolDamage("magic") and not jps.buff(112048)' , "target" },
	{ warrior.spells["ShieldBarrier"] , 'jps.hp("player") < 0.80 and not jps.buff(112048)' , "target" },
	
	{ warrior.spells["Bloodbath"], 'jps.rage() > 89' , "target" },

	-- "Thunder Clap" 6343 "Coup de tonnerre"
	{ warrior.spells["ThunderClap"] , 'jps.MultiTarget' , "target" },

	-- "Revenge" 6572 "Revanche"
	{ warrior.spells["Revenge"] , 'true' , "target" },
	-- "Shield Slam" 23922 "Heurt de bouclier"
	{ warrior.spells["ShieldSlam"] , 'jps.buff(50227)' , "target" },
	{ warrior.spells["ShieldSlam"] , 'true' , "target" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Ultimatum" 122509 -- HS cost no rage & crtique
	{ warrior.spells["HeroicStrike"] , 'jps.buff(122509)' , "target" },
	{ warrior.spells["HeroicStrike"] , 'jps.buffStacks(169686) == 6' , "target" },
	{ warrior.spells["HeroicStrike"] , 'jps.rage() > 89' , "target" },
	-- "Dévaster" 20243 "Devastate" -- Dévaster réduit le coût en rage de Frappe héroïque de 5 pendant 5 s.
	{ warrior.spells["Devastate"] , 'true' , "target" },

}
, "Warrior Protection StopAggro")

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerStaticTable("WARRIOR","PROTECTION",{

	-- "Heroic Leap" 6544 "Bond héroïque"
	{ warrior.spells["HeroicLeap"] , 'IsControlKeyDown()' , "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , 'not jps.hasAttackPowerBuff("player")' , "player" },
	-- "Commanding Shout" 469 "Cri de commandement"
	{ warrior.spells["CommandingShout"] , 'jps.hasAttackPowerBuff("player") and jps.myBuffDuration(6673,"player") == 0 and not jps.buff(469)' , "player" },
	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ {"macro","/use item:118922"}, 'not jps.buff(176151) and jps.itemCooldown(118922) == 0 and not jps.buff(156080) and not jps.buff(156071)' , "player" , "Item_Oralius"},
	-- "Flacon d’Intelligence draenique" jps.buff(156070)
	-- "Flacon d’Intelligence supérieure draenique" jps.buff(156079)
	-- "Flacon de Force supérieure draenique" jps.buff(156080)
	-- "Flacon de Force draenique" jps.buff(156071)

}
, "OOC Warrior Protection",false,false,true)


--Rage Generation

-- Critical strike with Devastate and Shield Slam
-- Getting a critical block (thanks to your Mastery), due to your Enrage ability;
-- Defensive Stance Icon Defensive Stance (1 Rage every 3 seconds, while in combat).
-- Shield Slam: 20 Rage (+5 Rage if used during Sword and Board proc, and 30 if a Critical Strike), 6 second CD
-- Revenge: 20 Rage, 9 second CD
-- Charge: 20 Rage, 20 Second CD (Shares diminishing returns on the same target, only first Charge grants Rage)
-- Critical Blocks (Cause Enrage): 10 Rage, 3 second CD
-- Berserker Rage (Cause Enrage): 10 Rage, 30 second CD