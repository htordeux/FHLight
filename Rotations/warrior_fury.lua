
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

-- Debuff EnemyTarget NOT DPS
local DebuffUnitCyclone = function (unit)
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
local Enrage = jps.buff(12880) -- "Enrage" 12880 "Enrager" -- 30 sec cd
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
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "Heroic Leap" 6544 "Bond héroïque"
	{ warrior.spells["HeroicLeap"] , IsShiftKeyDown() , "player" },
	
	-- BUFFS 
	-- "Battle Stance"" 2457 -- "Defensive Stance" 71
	{ warrior.spells["BattleStance"], not jps.buff(71) and not jps.buff(2457) , "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"], not jps.hasAttackPowerBuff("player") and not jps.buff(469) , "player" },
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
	{ warrior.spells["EnragedRegeneration"] , playerhealth_pct < 0.50 , rangedTarget , "_EnragedRegeneration" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"} , jps.combatStart > 0 and jps.itemCooldown(5512)==0 and jps.hp("player") < 0.50 , rangedTarget , "_UseItem"},
	-- "Die by the Sword" 118038
	{ warrior.spells["DieSword"] , playerAggro and playerhealth_pct < 0.70 , rangedTarget , "_DieSword" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and playerhealth_pct < 0.85 , rangedTarget , "_Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket0"},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , rangedTarget , "Trinket1"},

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ warrior.spells["HeroicThrow"] , inRanged , rangedTarget , "_Heroic Throw" },
	-- "Charge" 100
	{ warrior.spells["Charge"], jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
	-- "Piercing Howl" 12323 "Hurlement percant"
	--{ warrior.spells["PiercingHowl"] , not jps.debuff(12323,rangedTarget) , rangedTarget , "_PiercingHowl"},
	-- "Intimidating Shout" 5246
	{ warrior.spells["IntimidatingShout"] , not jps.debuff(5246,rangedTarget) and isBoss , rangedTarget , "_IntimidatingShout"},

	-- "Bloodthirst" 23881 "Sanguinaire"
	{ warrior.spells["Bloodthirst"], not Enrage , rangedTarget , "_Bloodthirst" },
	
	-- "Recklessness" 1719 "Témérité" -- buff Raging Blow! 131116 -- "Bloodsurge" 46916 "Afflux sanguin"
	{ warrior.spells["Recklessness"], jps.rage() > 80 and jps.buffDuration(12880) > 6 and isBoss , rangedTarget , "_Recklessness" },
	{ warrior.spells["Recklessness"], jps.rage() > 80 and jps.buffDuration(12880) > 6 and isBoss , rangedTarget , "_Recklessness" },
	-- "Bloodbath" 12292 "Bain de sang"  -- jps.buff(12292)
	{ warrior.spells["Bloodbath"], jps.combatStart > 0 , rangedTarget , "_Bloodbath" },
	-- "Execute" 5308 "Exécution" -- cost 30 rage
	{ warrior.spells["Execute"], jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },
	
	{"nested", jps.hp(rangedTarget) < 0.20 and inMelee ,{
		-- "Execute" 5308 "Exécution" -- cost 30 rage
		{ warrior.spells["Execute"], jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },
		{ warrior.spells["Execute"] , Enrage , rangedTarget , "_Execute_Enrage" },
		{ warrior.spells["Execute"] , jps.rage() > 60 , rangedTarget , "_Execute_Rage" },
		-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
		{ warrior.spells["WildStrike"] , jps.buff(46916) , rangedTarget ,"_WildStrike_Bloodsurge" },
		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- cost 10 rage -- "Meat Cleaver" 85739 "Fendoir à viande"
		{ warrior.spells["RagingBlow"] , jps.buff(131116) and jps.buffStacks(131116) == 2 , rangedTarget , "_RagingBlow_Stacks" },
		{ warrior.spells["RagingBlow"] , jps.buff(131116) and jps.buffDuration(131116) < 4 , rangedTarget , "_RagingBlow_Buff" },
		-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
		{ warrior.spells["WildStrike"] , jps.rage() > 80 , rangedTarget ,"_WildStrike_Rage" },
	}},
	
	{"nested", jps.MultiTarget and EnemyCount > 2 and inMelee ,{
		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- cost 10 rage -- "Meat Cleaver" 85739 "Fendoir à viande"
		{ warrior.spells["RagingBlow"] , jps.buff(131116) and jps.buffStacks(85739) > 1 , rangedTarget , "_RagingBlow_MeatCleaver" },
		-- "Whirlwind" 1680 -- 8 yd range -- "Meat Cleaver" 85739 "Fendoir à viande"
		-- Dmg with Whirlwind increases the number of targets that your Raging Blow hits by 1, stacking up to 3 times.
		{ warrior.spells["Whirlwind"], jps.rage() > 60 , rangedTarget , "_Whirlwind" },
		-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
		{ warrior.spells["WildStrike"] , jps.buff(46916) , rangedTarget ,"_WildStrike_Bloodsurge" },
		-- "Bladestorm" 46924 "Tempête de lames" -- "Enrage" 12880 "Enrager" -- While Bladestorm is active, you cannot perform any actions except for using your Taunt
		{ warrior.spells["Bladestorm"], true , rangedTarget , "_Bladestorm" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , true , rangedTarget , "_Shockwave" },
	}},

	-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- cost 10 rage -- "Meat Cleaver" 85739 "Fendoir à viande"
	{ warrior.spells["RagingBlow"] , jps.buff(131116) and jps.buffStacks(131116) == 2 , rangedTarget , "_RagingBlow_Stacks" },
	{ warrior.spells["RagingBlow"] , jps.buff(131116) and jps.buffDuration(131116) < 4 , rangedTarget , "_RagingBlow_Buff" },
	-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
	{ warrior.spells["WildStrike"] , jps.buff(46916) , rangedTarget ,"_WildStrike_Bloodsurge" },
	{ warrior.spells["WildStrike"] , jps.rage() > 80 , rangedTarget ,"_WildStrike_Rage" },

	-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range
	{ warrior.spells["StormBolt"] , jps.IsSpellKnown(107570) , rangedTarget ,"_StormBolt" },
	-- "Dragon Roar " 118000 -- 8 yards
	{ warrior.spells["DragonRoar"] , jps.IsSpellKnown(118000) and jps.IsSpellInRange(118000,rangedTarget) , rangedTarget , "_DragonRoar" },
	-- "Ravager" 152277 -- 40 yd range
	{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "_Ravager" },
	-- "Siegebreaker" 176289 "Briseur de siège"
	{ warrior.spells["Siegebreaker"] , jps.IsSpellKnown(176289) , rangedTarget ,"_Siegebreaker" },

	-- "Bloodthirst" 23881 "Sanguinaire"
	{ warrior.spells["Bloodthirst"], true , rangedTarget , "_Bloodthirst_End" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Warrior Default Fury")


jps.registerStaticTable("WARRIOR","FURY",
	{

		-- "Pummel" 6552 "Volée de coups"
		{ warrior.spells["Pummel"] ,'jps.ShouldKick()', warrior.rangedTarget},

		-- Buffs
		{ warrior.spells["BattleShout"],'not jps.buff(6673)' , warrior.rangedTarget},

		-- Normal Rotation
		{ warrior.spells["RagingBlow"] ,'jps.buffStacks(131116) == 2', warrior.rangedTarget },
		{ warrior.spells["WildStrike"] ,'jps.buff(46916)', warrior.rangedTarget },
		{ warrior.spells["Bloodthirst"] ,'true', warrior.rangedTarget},

	}
,"Warrior Static Fury", true, false)