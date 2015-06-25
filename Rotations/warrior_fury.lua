-- jps.MultiTarget for Multitarget
-- jps.UseCDs for "Charge"
-- jps.Interrupts for "Pummel"

local L = MyLocalizationTable
local canDPS = jps.canDPS
local canHeal = jps.canHeal
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

jps.registerRotation("WARRIOR","FURY",function()

local spell = nil
local target = nil
local playerhealth_deficiency =  jps.hp("player","abs") -- UnitHealthMax(player) - UnitHealth(player)
local playerhealth_pct = jps.hp("player") 
local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local inMelee = jps.IsSpellInRange(5308,"target") -- "Execute" 5308
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"

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
elseif canDPS(TankTarget) and not DebuffUnitCyclone(TankTarget) then rangedTarget = TankTarget 
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
	-- "Battle Stance"" 2457 -- "Defensive Stance" 71
	{ warrior.spells["BattleStance"] , not jps.buff(71) and not jps.buff(2457) , "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , not jps.hasAttackPowerBuff("player") and not jps.buff(469) , "player" },
	-- "Commanding Shout" 469 "Cri de commandement"
	{ warrior.spells["CommandingShout"] , not jps.buff(469) and jps.hasAttackPowerBuff("player") and not jps.buff(6673) , rangedTarget , "_CommandingShout" },

	-- INTERRUPTS --
	{ "nested", jps.Interrupts ,{
		-- "Pummel" 6552 "Volée de coups"
		{ warrior.spells["Pummel"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_Pummel" },
		{ warrior.spells["Pummel"] , jps.ShouldKick("focus") , "focus" , "_Pummel" },
		-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
		{ warrior.spells["MassSpellReflection"] , jps.UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "_MassSpell" },
	}},

	-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
	{ warrior.spells["ImpendingVictory"] , playerhealth_pct < 0.85 , rangedTarget , "_ImpendingVictory" },
	{ warrior.spells["VictoryRush"] , playerhealth_pct <  0.85 , rangedTarget , "_VictoryRush" },
	-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
	{ warrior.spells["ImpendingVictory"] , jps.buffDuration(32216) < 4 , rangedTarget , "_ImpendingVictory" },
	{ warrior.spells["VictoryRush"] , jps.buffDuration(32216) < 4 , rangedTarget , "_VictoryRush" },
	-- "Enraged Regeneration" 55694 "Régénération enragée"
	{ warrior.spells["EnragedRegeneration"] , playerhealth_pct < 0.55 , rangedTarget , "_EnragedRegeneration" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"} , jps.itemCooldown(5512)==0 and jps.hp("player") < 0.55 , rangedTarget , "_UseItem"},
	-- "Die by the Sword" 118038
	{ warrior.spells["DieSword"] , playerAggro and playerhealth_pct < 0.65 , rangedTarget , "_DieSword" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and playerhealth_pct < 0.75 , rangedTarget , "_Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ warrior.spells["HeroicThrow"] , inRanged and not inMelee , rangedTarget , "_Heroic Throw" },
	-- "Charge" 100
	{ warrior.spells["Charge"], jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
	-- "Intimidating Shout" 5246
	{ warrior.spells["IntimidatingShout"] , playerAggro and not jps.debuff(5246,rangedTarget) , rangedTarget , "_IntimidatingShout"},
	-- "Piercing Howl" 12323 "Hurlement percant"
	--{ warrior.spells["PiercingHowl"] , jps.PvP and not jps.debuff(12323,rangedTarget) , rangedTarget , "PiercingHowl"},
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket0"},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket1"},

	-- "Bloodthirst" 23881 "Sanguinaire" -- "Enrage" 12880 "Enrager"
	{ warrior.spells["Bloodthirst"], not jps.buff(12880) , rangedTarget , "_Bloodthirst" },
	-- "Berserker Rage" 18499 "Rage de berserker" -- "Enrage" 12880 "Enrager"
	{ warrior.spells["BerserkerRage"], not jps.buff(12880) , rangedTarget , "_BerserkerRage" },

	-- "Recklessness" 1719 "Témérité" -- buff Raging Blow! 131116 -- "Bloodsurge" 46916 "Afflux sanguin" -- "Enrage" 12880 "Enrager"
	{ warrior.spells["Recklessness"], jps.combatStart > 0 and jps.rage() > 29 and jps.buff(12880) and inMelee , rangedTarget , "_Recklessness" },
	-- "Execute" 5308 "Exécution" -- "Mort soudaine" 29725
	{ warrior.spells["Execute"], jps.buff(29725) , rangedTarget , "_Execute_SuddenDeath" },
	-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
	{ warrior.spells["WildStrike"] , jps.buff(46916) , rangedTarget ,"_WildStrike_Bloodsurge" },
	{ warrior.spells["WildStrike"] , jps.rage() > 89 , rangedTarget ,"_WildStrike_Rage89" },
	
	-- TALENTS --
	-- "Bloodbath" 12292 "Bain de sang"  -- jps.buff(12292)
	{ warrior.spells["Bloodbath"], jps.combatStart > 0 and jps.rage() > 29 and inMelee , rangedTarget , "_Bloodbath" },
	-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range
	{ warrior.spells["StormBolt"] , jps.IsSpellKnown(107570) , rangedTarget ,"_StormBolt" },
	-- "Dragon Roar " 118000 -- 8 yards
	{ warrior.spells["DragonRoar"] , jps.IsSpellKnown(118000) and inMelee , rangedTarget , "_DragonRoar" },
	-- "Ravager" 152277 -- 40 yd range
	{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "_Ravager" },
	-- "Siegebreaker" 176289 "Briseur de siège"
	{ warrior.spells["Siegebreaker"] , jps.IsSpellKnown(176289) , rangedTarget ,"_Siegebreaker" },
	
	{"nested", jps.hp(rangedTarget) < 0.20 and inMelee ,{
		-- "Execute" 5308 "Exécution" -- "Enrage" 12880 "Enrager"
		{ warrior.spells["Execute"] , jps.buff(12880) , rangedTarget , "_Execute_Enrage" },
		{ warrior.spells["Execute"] , jps.rage() > 59 , rangedTarget , "_Execute_Rage" },
		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- "Meat Cleaver" 85739 "Fendoir à viande"
		{ warrior.spells["RagingBlow"] , jps.buff(131116) , rangedTarget , "_RagingBlow_Buff" },
	}},

	-- MULTITARGRT -- and EnemyCount > 2
	{"nested", jps.MultiTarget and inMelee ,{
		-- "Whirlwind" 1680 -- "Raging Wind" 115317 -- Raging Blow hits increase the damage of your next Whirlwind by 10%
		{ warrior.spells["Whirlwind"], jps.buff(115317) , rangedTarget , "_Whirlwind_Buff" },
		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- "Meat Cleaver" 85739 "Fendoir à viande"
		-- Whirlwind increases the number of targets that your Raging Blow hits by 1, stacking up to 3 times.
		{ warrior.spells["RagingBlow"] , jps.buff(131116) and jps.buffStacks(85739) > 1 , rangedTarget , "_RagingBlow_MeatCleaver" },
		-- "Whirlwind" 1680 -- 8 yd range -- "Meat Cleaver" 85739 "Fendoir à viande"
		{ warrior.spells["Whirlwind"], jps.rage() > 59 , rangedTarget , "_Whirlwind" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , true , rangedTarget , "_Shockwave" },
		-- "Bladestorm" 46924 "Tempête de lames" -- While Bladestorm is active, you cannot perform any actions except for using your Taunt
		{ warrior.spells["Bladestorm"], true , rangedTarget , "_Bladestorm" },
	}},

	-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- "Meat Cleaver" 85739 "Fendoir à viande"
	{ warrior.spells["RagingBlow"] , jps.buff(131116) , rangedTarget , "_RagingBlow_Buff" },
	-- "Wild Strike" 100130 "Frappe sauvage" -- "Enrage" 12880 "Enrager"
	{ warrior.spells["WildStrike"] , jps.buff(12880) , rangedTarget ,"_WildStrike_Enrage" },
	-- "Bloodthirst" 23881 "Sanguinaire"
	{ warrior.spells["Bloodthirst"], true , rangedTarget , "_Bloodthirst_End" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Warrior Default Fury")

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- STATIC ------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerStaticTable("WARRIOR","FURY",
	{

		-- "Pummel" 6552 "Volée de coups"
		{ warrior.spells["Pummel"] ,'jps.ShouldKick()', warrior.rangedTarget},

		-- Buffs
		{ warrior.spells["BattleShout"],'not jps.buff(6673)' , warrior.rangedTarget},

		-- Normal Rotation
		{ warrior.spells["RagingBlow"] ,'jps.buffStacks(131116)', warrior.rangedTarget },
		{ warrior.spells["WildStrike"] ,'jps.buff(46916)', warrior.rangedTarget },
		{ warrior.spells["Bloodthirst"] },

	}
, "Warrior Static Fury")