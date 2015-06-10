-- jps.Defensive for "Shield Wall" & "Last Stand" 
-- jps.UseCDs for "Charge"
-- jps.Interrupts for "Pummel"

local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat

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
local Enrage = jps.buff(12880) -- "Enrage" 12880 "Enrager" -- 30 sec cd
local inMelee = jps.IsSpellInRange(20243,"target") -- "Dévaster" 20243 "Devastate"
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"
local ShieldCharge  = GetSpellCharges(156321)
local myTank,TankUnit = jps.findTankInRaid() -- return Table with UnitThreatSituation == 3 (tanking) or == 1 (Overnuking) or default "focus"
	
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
elseif canDPS("targettarget") and not DebuffUnitCyclone("targettarget") then rangedTarget = "targettarget"
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
	-- "Proteger" 114029
	{ 114029, jps.hp(myTank) < 0.25 and jps.hp() > 0.85, myTank , "PROTEGER_myTank" },
	
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
	{ 355, jps.buff(71) , rangedTarget , "Provocation" },
	-- "Demoralizing Shout" 1160 "Cri démoralisant"
	{ 1160, jps.buff(71) and not jps.debuff(1160,rangedTarget) , rangedTarget , "Demoralizing" },
	-- "Shield Block" 2565 "Maîtrise du blocage" -- works against physical attacks, but it does nothing against magic
	{ warrior.spells["ShieldBlock"] , EnemyCaster(rangedTarget) == "cac" and jps.hp() < 0.80 , rangedTarget , "|cff1eff00ShieldBlock" },
	-- "Shield Barrier" 112048 "Barrière protectrice" -- Shield Barrier works against all types of damage (excluding fall damage).
	{ warrior.spells["ShieldBarrier"] , EnemyCaster(rangedTarget) == "caster" and jps.hp() < 0.80 , rangedTarget , "|cff1eff00ShieldBarrier" },
	{ warrior.spells["ShieldBarrier"] , jps.hp() < 0.60 , rangedTarget , "|cff1eff00ShieldBarrier" },
		
	-- DEFENSIVE
	-- "Shield Wall"
	{ warrior.spells["ShieldWall"] , jps.Defensive and jps.hp() < 0.40 , rangedTarget , "|cff1eff00ShieldWall" },
	-- "Last Stand" 
	{ warrior.spells["LastStand"] , jps.Defensive and  jps.hp() < 0.40 , rangedTarget , "|cff1eff00LastStand" },
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
	-- "Bloodbath" 12292 "Bain de sang" -- Buff 12292
	{ warrior.spells["Bloodbath"], jps.combatStart > 0 and Enrage and inMelee , rangedTarget , "|cFFFF0000Bloodbath" },
	-- "Berserker Rage" 18499 "Rage de berserker"
	{ warrior.spells["BerserkerRage"] , not Enrage and jps.cooldown(23922) > 0 , rangedTarget , "|cFFFF0000BerserkerRage" },

	-- TALENTS --
	-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range
	{ warrior.spells["StormBolt"] , jps.IsSpellKnown(107570) , rangedTarget ,"StormBolt" },
	-- "Dragon Roar " 118000 -- 8 yards
	{ warrior.spells["DragonRoar"] , jps.IsSpellKnown(118000) and jps.IsSpellInRange(118000,rangedTarget) , rangedTarget , "DragonRoar" },
	-- "Revenge" 6572 "Revanche"
	{ warrior.spells["Revenge"] , true , rangedTarget , "Revenge" },
	-- "Shield Slam" 23922 "Heurt de bouclier" -- Buff "Sword and Board" 50227 "Epée et bouclier"
	{ warrior.spells["ShieldSlam"] , jps.buff(50227) , rangedTarget , "ShieldSlam_SwordBoard" },

	-- MULTITARGET --
	{"nested", jps.MultiTarget and inMelee ,{
		-- "Ravager" 152277 -- 40 yd range
		{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "Ravager" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.IsSpellKnown(46968) , rangedTarget , "Shockwave" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ warrior.spells["ThunderClap"] , true , rangedTarget , "ThunderClap" },
	}},

	-- SINGLETARGET -- "Gladiator Stance" 156291
	-- "Execute" 5308 "Exécution" -- Buff "Mort soudaine" 29725
	{ 5308, jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },
	{ 5308, jps.rage() > 59 and jps.hp(rangedTarget) < 0.20 , rangedTarget , "Execute" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Ultimatum" 122509
	{ warrior.spells["HeroicStrike"] , jps.buff(122509) , rangedTarget , "HeroicStrike_Ultimatum" },
	-- "Shield Charge" 156321 "Charge de bouclier" -- Buff "Shield Charge" 169667 -- Increasing the damage of Shield Slam, Revenge, and Heroic Strike by 25% for 7 sec.
	{ 156321, jps.buff(156291) and jps.buffDuration(169667) < 2 , rangedTarget , "ShieldCharge_Buff"},
	{ 156321, jps.buff(156291) and ShieldCharge == 2 , rangedTarget , "ShieldCharge_2"},
	-- "Shield Slam" 23922 "Heurt de bouclier"
	{ warrior.spells["ShieldSlam"] , true , rangedTarget , "ShieldSlam" },
	-- "Dévaster" 20243 "Devastate" -- Buff "Unyielding Strikes" 169686 "Frappes inflexibles" 169686 -- Cumulable jusqu’à 6 fois
	{ warrior.spells["Devastate"] , jps.buffDuration(169686) < 2 , rangedTarget , "Devastate_BuffDuration" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- Buff "Shield Charge" 169667
	{ warrior.spells["HeroicStrike"] , jps.buffStacks(169686) > 3 , rangedTarget , "HeroicStrike_BuffStrikes" },
	{ warrior.spells["HeroicStrike"] , jps.buff(169667) , rangedTarget , "HeroicStrike_ShieldCharge" },
	{ warrior.spells["HeroicStrike"] , jps.rage() > 89 , rangedTarget , "HeroicStrike_DumpRage_90" },
	-- "Dévaster" 20243 "Devastate" -- Dévaster réduit le coût en rage de Frappe héroïque de 5 pendant 5 s.
	{ warrior.spells["Devastate"] , true , rangedTarget , "Devastate_End" },
	-- "Heroic Strike" 78 "Frappe héroïque" -- "Ultimatum" 122509
	{ warrior.spells["HeroicStrike"] , jps.rage() > 59 , rangedTarget , "HeroicStrike_DumpRage_60" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default")