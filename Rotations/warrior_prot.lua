-- jps.Defensive for "Provocation" 
-- jps.UseCDs for "Charge"
-- jps.Interrupts for "Pummel"

local L = MyLocalizationTable
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local SchoolDamagePlayer = 0

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
		end
		if Cyclone then break end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i))
	end
	return Cyclone
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
local ShieldCharge  = GetSpellCharges(156321)

local PhysicalDmg = SchoolDamagePlayer == 1
local MagicDmg = SchoolDamagePlayer > 1

local myTank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if canHeal(myTank) then TankTarget = myTank.."target" end
	
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

if canDPS("target") and not DebuffUnitCyclone("target") then rangedTarget =  "target"
elseif jps.buff(156291) and canDPS(TankTarget) and not DebuffUnitCyclone(TankTarget) then rangedTarget = TankTarget -- "Gladiator Stance" 156291
elseif canDPS("targettarget") and not DebuffUnitCyclone("targettarget") then rangedTarget = "targettarget"
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "Heroic Leap" 6544 "Bond héroïque"
	{ warrior.spells["HeroicLeap"] , IsShiftKeyDown() , "player" },
	
	-- BUFFS
	-- "Gladiator Stance" 156291 -- Talent "Gladiator's Resolve" 152276
	{ 156291, jps.IsSpellKnown(152276) and not jps.buff(156291) and not jps.buff(71) , "player" },
	-- "Defensive Stance" 71
	{ warrior.spells["DefensiveStance"] , not jps.buff(71) and not jps.buff(156291), "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , not jps.hasAttackPowerBuff("player") , "player" },
	-- "Commanding Shout" 469 "Cri de commandement"
	{ 469 , jps.hasAttackPowerBuff("player") and jps.myBuffDuration(6673,"player") == 0 and not jps.buff(469) , "player" },
	-- "Proteger" 114029 -- "Intervention" 3411
	{ 3411, jps.buff(156291) and jps.hp(myTank) < 0.30 and jps.hp() > 0.85, myTank , "Intervention_myTank" },
	{ 3411, jps.buff(71) and not jps.UnitIsUnit("targettarget","player") and jps.hp("targettarget") < 0.50 , "targettarget" , "Intervention_Aggro" },
	{ 114029, jps.hp(myTank) < 0.30 and jps.hp() > 0.85, myTank , "Proteger_myTank" },
	
	-- INTERRUPTS --
	-- "Spell Reflection" 23920 "Renvoi de sort" --renvoyez le prochain sort lancé sur vous. Dure 5 s. Buff same spellId
	{ warrior.spells["SpellReflection"] , jps.ShouldKick(rangedTarget) and jps.UnitIsUnit("targettarget","player") , rangedTarget , "SpellReflection" },
	{ warrior.spells["SpellReflection"] , jps.ShouldKick("focus") and jps.UnitIsUnit("focustarget","player") , "focus" , "SpellReflection" },
	-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
	{ warrior.spells["MassSpellReflection"] , jps.UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "MassSpell" },
	-- "Pummel" 6552 "Volée de coups"
	{ warrior.spells["Pummel"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "Pummel" },
	{ warrior.spells["Pummel"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" , "Pummel" },

	-- "Provocation" 355
	{ 355, jps.Defensive and jps.buff(71) and not jps.UnitIsUnit("targettarget","player") , rangedTarget , "Provocation" },
	-- "Demoralizing Shout" 1160 "Cri démoralisant"
	{ 1160, jps.buff(71) and not jps.debuff(1160,rangedTarget) , rangedTarget , "Demoralizing" },
	-- "Shield Block" 2565 "Maîtrise du blocage" -- works against physical attacks, it does nothing against magic
	{ warrior.spells["ShieldBlock"] , jps.buff(71) and PhysicalDmg and jps.hp() < 0.80 , rangedTarget , "|cff1eff00ShieldBlock_School" },
	-- "Shield Barrier" 112048 "Barrière protectrice" -- Shield Barrier works against all types of damage (excluding fall damage).
	{ warrior.spells["ShieldBarrier"] , jps.buff(71) and MagicDmg and jps.hp() < 0.80 , rangedTarget , "|cff1eff00ShieldBarrier_School" },
	{ warrior.spells["ShieldBarrier"] , jps.hp() < 0.50 , rangedTarget , "|cff1eff00ShieldBarrier" },
		
	-- DEFENSIVE
	-- "Shield Wall" 871 "Mur protecteur"
	{ warrior.spells["ShieldWall"] , jps.hp() < 0.50 , rangedTarget , "|cff1eff00ShieldWall" },
	-- "Last Stand" 12975 "Dernier rempart" 
	{ warrior.spells["LastStand"] , jps.hp() < 0.30 , rangedTarget , "|cff1eff00LastStand" },
	-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
	{ warrior.spells["ImpendingVictory"] , jps.hp() < 0.80 , rangedTarget , "|cff1eff00ImpendingVictory" },
	{ warrior.spells["VictoryRush"] , jps.hp() <  0.80 , rangedTarget , "|cff1eff00VictoryRush" },
	-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
	{ warrior.spells["ImpendingVictory"] , jps.buffDuration(32216) < 4 , rangedTarget , "|cff1eff00ImpendingVictory" },
	{ warrior.spells["VictoryRush"] , jps.buffDuration(32216) < 4 , rangedTarget , "|cff1eff00VictoryRush" },
	-- "Enraged Regeneration" 55694 "Régénération enragée"
	{ warrior.spells["EnragedRegeneration"] , jps.hp() < 0.70 , rangedTarget , "|cff1eff00EnragedRegeneration" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and jps.hp() < 0.80 , rangedTarget , "|cff1eff00Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "|cff1eff00Stoneform" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp() < 0.80 and jps.itemCooldown(5512) == 0 , "player" , "Item5512" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket0"},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket1"},

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ warrior.spells["HeroicThrow"] , inRanged and not inMelee , rangedTarget , "Heroic Throw" },
	-- "Charge" 100
	{ warrior.spells["Charge"], jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "Charge"},
	-- "Piercing Howl" 12323 "Hurlement percant"
	--{ warrior.spells["PiercingHowl"] , not jps.debuff(12323,rangedTarget) , rangedTarget , "PiercingHowl"},
	-- "Intimidating Shout" 5246
	{ warrior.spells["IntimidatingShout"] , jps.PvP and not jps.debuff(5246,rangedTarget) , rangedTarget , "IntimidatingShout"},
	-- "Berserker Rage" 18499 "Rage de berserker" -- "Enrage" 12880 "Enrager"
	{ warrior.spells["BerserkerRage"] , not jps.buff(12880) and jps.cooldown(23922) > 0 , rangedTarget , "|cFFFF0000BerserkerRage" },

	-- TALENTS --
	-- "Bloodbath" 12292 "Bain de sang" -- Buff 12292
	--{ warrior.spells["Bloodbath"], jps.combatStart > 0 and inMelee and jps.rage() > 29  , rangedTarget , "|cFFFF0000Bloodbath" },
	{ warrior.spells["Bloodbath"], inMelee and jps.MultiTarget , rangedTarget , "|cFFFF0000Bloodbath" },
	{ warrior.spells["Bloodbath"], inMelee and jps.buff(169667) , rangedTarget , "|cFFFF0000Bloodbath_ShieldCharge" },
	-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range
	{ warrior.spells["StormBolt"] , jps.IsSpellKnown(107570) , rangedTarget ,"StormBolt" },
	-- "Dragon Roar " 118000 -- 8 yards
	{ warrior.spells["DragonRoar"] , jps.IsSpellKnown(118000) and inMelee , rangedTarget , "DragonRoar" },

	-- "Shield Charge" 156321 "Charge de bouclier" -- Buff "Shield Charge" 169667 -- Increasing the damage of Shield Slam, Revenge, and Heroic Strike by 25% for 7 sec.
	{"nested", jps.buff(156291) and jps.buffDuration(169667) < 2 and jps.rage() > 29 and inMelee ,{
		{ 156321, jps.buffStacks(169686) > 3 , rangedTarget , "|cffa335eeShieldCharge_Strikes" },
		{ 156321, jps.rage() > 59 , rangedTarget , "|cffa335eeShieldCharge_Rage" },
	}},

	-- "Shield Slam" 23922 "Heurt de bouclier" -- Buff "Sword and Board" 50227 "Epée et bouclier"
	{ warrior.spells["ShieldSlam"] , jps.buff(50227) , rangedTarget , "ShieldSlam_SwordBoard" },
	{ warrior.spells["ShieldSlam"] , true , rangedTarget , "ShieldSlam" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Ultimatum" 122509 -- HS cost no rage & crtique
	{ warrior.spells["HeroicStrike"] , jps.buffStacks(169686) == 6 , rangedTarget , "HeroicStrike_6_Strikes" },
	{ warrior.spells["HeroicStrike"] , jps.buff(122509) , rangedTarget , "HeroicStrike_Ultimatum" },
	-- "Dévaster" 20243 "Devastate" -- Buff "Unyielding Strikes" 169686 "Frappes inflexibles" 169686 -- Cumulable jusqu’à 6 fois
	{ warrior.spells["Devastate"] , jps.buffDuration(169686) < 2 and jps.buffStacks(169686) < 6 , rangedTarget , "Devastate_BuffDuration" },
	-- "Revenge" 6572 "Revanche"
	{ warrior.spells["Revenge"] , inMelee , rangedTarget , "Revenge" },

	-- MULTITARGET --
	{"nested", jps.MultiTarget and inMelee ,{
		-- "Ravager" 152277 -- 40 yd range
		{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "Ravager" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.IsSpellKnown(46968) , rangedTarget , "Shockwave" },
		-- "Bladestorm" 46924 "Tempête de lames"
		{ warrior.spells["Bladestorm"] , jps.IsSpellKnown(46924) , rangedTarget , "Bladestorm" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ warrior.spells["ThunderClap"] , true , rangedTarget , "ThunderClap" },
	}},

	-- SINGLETARGET -- "Gladiator Stance" 156291
	-- "Execute" 5308 "Exécution" -- Buff "Mort soudaine" 29725
	{ 5308, jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },
	{ 5308, jps.rage() > 59 and jps.hp(rangedTarget) < 0.20 , rangedTarget , "Execute_DumpRage" },
	{ 5308, not jps.buff(169667) , rangedTarget , "Execute_UnBuff" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Shield Charge" 169667
	{ warrior.spells["HeroicStrike"] , jps.rage() > 19 and jps.buffStacks(169686) > 3 , rangedTarget , "HeroicStrike_4_BuffStrikes" },
	{ warrior.spells["HeroicStrike"] , jps.buff(169667) , rangedTarget , "HeroicStrike_ShieldCharge" },
	{ warrior.spells["HeroicStrike"] , jps.rage() > 89 and jps.hp(rangedTarget) > 0.20 , rangedTarget , "HeroicStrike_DumpRage" },
	-- "Dévaster" 20243 "Devastate" -- Dévaster réduit le coût en rage de Frappe héroïque de 5 pendant 5 s.
	{ warrior.spells["Devastate"] , true , rangedTarget , "Devastate" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default")


-- spellSchool == 1 Physical, 2 Holy, 4 Fire, 8 Nature, 16 Frost, 32 Shadow, 64 Arcane
jps.listener.registerCombatLogEventUnfiltered("SPELL_DAMAGE", function(...)
	local sourceGUID = select(4,...)
	local destGUID = select(8,...)
	local spellID =  select(12,...)
	local spellSchool =  select(17,...)
	if destGUID == UnitGUID("player") and spellSchool then
		SchoolDamagePlayer = spellSchool
	end
end)