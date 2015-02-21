
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
	local playerIsStun = jps.StunEvents() -- return true/false
	local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
	local Enrage = jps.buff(12880) -- "Enrage" 12880 "Enrager"
	
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
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	--{ jps.useTrinket(0), jps.UseCds },
	--{ jps.useTrinket(1), jps.UseCds },
	-- "Pummel" 6552 "Volée de coups"
	{ warrior.spells["Pummel"], jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "_Pummel" },
	-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
	{ warrior.spells["MassSpellReflection"], jps.Interrupts and jps.ShouldKick(rangedTarget) and jps.UnitIsUnit("targettarget","player") , rangedTarget , "_MassSpellReflection" },

	-- "Commanding Shout" 469 "Cri de commandement"
	{ warrior.spells["CommandingShout"] , not jps.buff(469) and playerhealth_pct < 0.75 , "player" , "_CommandingShout" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"] , not jps.buff(6673) and playerhealth_pct > 0.75 , "player" , "_BattleShout" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and playerhealth_pct < 0.85 , "player" , "_Stoneform" },
	-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
	{ warrior.spells["ImpendingVictory"] , playerhealth_pct < 0.85 , rangedTarget , "_ImpendingVictory" },
	-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
	{ warrior.spells["ImpendingVictory"] , jps.buffDuration(32216) < 4 , rangedTarget , "_ImpendingVictory" },
	--{ warrior.spells["VictoryRush"] , playerhealth_pct <  0.85 , rangedTarget , "_VictoryRush" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"} , UnitAffectingCombat("player") == true and jps.itemCooldown(5512)==0 and (jps.hp("player") < 0.50) , "player" , "_UseItem"},
	-- "Die by the Sword" 118038
	{ warrior.spells["DieSword"] , playerAggro and playerhealth_pct < 0.7 , rangedTarget , "_DieSword" },

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ warrior.spells["HeroicThrow"] , jps.IsSpellInRange(57755,rangedTarget) , rangedTarget , "_Heroic Throw" },
	-- "Charge" 100
	{ warrior.spells["Charge"], jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
	-- "Piercing Howl" 12323 "Hurlement percant"
	{ warrior.spells["PiercingHowl"] , jps.PvP and not jps.debuff(12323,rangedTarget) , rangedTarget , "_PiercingHowl"},
	-- "Intimidating Shout" 5246
	{ warrior.spells["IntimidatingShout"] , not jps.debuff(5246,rangedTarget) and jps.hp(rangedTarget,"abs") > 500000 , rangedTarget , "_IntimidatingShout"},

	-- "Bloodthirst" 23881 "Sanguinaire"
	{ warrior.spells["Bloodthirst"], jps.rage() < 30 , rangedTarget , "_Bloodthirst" },
	{ warrior.spells["Bloodthirst"], jps.rage() < 80 and not Enrage and jps.cooldown(18499) > 0 , rangedTarget , "_Bloodthirst" },
	-- "Berserker Rage" 18499 "Rage de berserker"
	{ warrior.spells["BerserkerRage"] , not Enrage , "player" , "_BerserkerRage" },
	
	-- "Recklessness" 1719 "Témérité" -- buff Raging Blow! 131116 -- "Bloodsurge" 46916 "Afflux sanguin"
	{ warrior.spells["Recklessness"], jps.buff(131116) and jps.rage() > 80 and jps.hp(rangedTarget,"abs") > 500000 , "player" , "_Recklessness" },
	{ warrior.spells["Recklessness"], jps.buff(46916) and jps.rage() > 80 and jps.hp(rangedTarget,"abs") > 500000 , "player" , "_Recklessness" },
	-- "Bloodbath" 12292 "Bain de sang"  -- jps.buff(12292)
	{ warrior.spells["Bloodbath"], jps.rage() > 60 and jps.hp(rangedTarget,"abs") > 500000 , rangedTarget , "_Bloodbath" },
	-- "Avatar" 107574
	{ warrior.spells["Avatar"], jps.rage() > 60 and jps.hp(rangedTarget,"abs") > 500000 , rangedTarget , "_Avatar" },

	-- "Execute" 5308 "Exécution" -- "Mort soudaine" 29725
	{ warrior.spells["Execute"], jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },
	-- "Ravager" 152277 -- 40 yd range
	{ warrior.spells["Ravager"] , jps.IsSpellKnown(152277) , rangedTarget , "_Ravager" },
	-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range
	{ warrior.spells["StormBolt"] , jps.IsSpellKnown(107570) , rangedTarget ,"_StormBolt" },
	-- "Dragon Roar " 118000 -- 8 yards
	{ warrior.spells["DragonRoar"] , jps.IsSpellKnown(118000) and jps.IsSpellInRange(118000,rangedTarget) , rangedTarget , "_DragonRoar" },
	-- "Siegebreaker" 176289 "Briseur de siège"
	{ warrior.spells["Siegebreaker"] , jps.IsSpellKnown(176289) , rangedTarget ,"_Siegebreaker" },

	{"nested", jps.hp(rangedTarget) < 0.20 ,{
		-- "Execute" 5308 "Exécution" -- cost 30 rage
		{ warrior.spells["Execute"], jps.rage() > 60 , rangedTarget , "Execute" },
		-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
		{ warrior.spells["WildStrike"] , jps.buff(46916) , rangedTarget ,"_WildStrike_Bloodsurge" },
		-- "Execute" 5308 "Exécution" -- cost 30 rage
		{ warrior.spells["Execute"], Enrage , rangedTarget , "Execute" },

	}},

	{"nested", jps.MultiTarget or EnemyCount >= 3 ,{
	
		-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
		{ warrior.spells["WildStrike"] , jps.buff(46916) , rangedTarget ,"_WildStrike_Bloodsurge" },
		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- cost 10 rage -- "Meat Cleaver" 85739 "Fendoir à viande"
		{ warrior.spells["RagingBlow"] , jps.buff(131116) and (jps.buffStacks(85739) >= 2) , rangedTarget , "_RagingBlow_MeatCleaver" },
		-- "Bladestorm" 46924 "Tempête de lames" -- "Enrage" 12880 "Enrager" -- While Bladestorm is active, you cannot perform any actions except for using your Taunt
		{ warrior.spells["Bladestorm"], jps.buffDuration(12880) > 6 , rangedTarget , "_Bladestorm" },
		-- "Shockwave" 46968 "Onde de choc"
		{ warrior.spells["Shockwave"] , jps.IsSpellInRange(46968,rangedTarget) , rangedTarget , "_Shockwave" },
		-- "Whirlwind" 1680 -- 8 yd range
		{ warrior.spells["Whirlwind"], jps.rage() > 60 and jps.IsSpellInRange(1680,rangedTarget) , rangedTarget , "_Whirlwind" },

	}},
	
	-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- cost 10 rage
	{ warrior.spells["RagingBlow"] , (jps.buffStacks(131116) == 2) , rangedTarget , "_RagingBlow_Stacks" },
	-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
	{ warrior.spells["WildStrike"] , jps.buff(46916) , rangedTarget ,"_WildStrike_Bloodsurge" },
	-- "Wild Strike" 100130 "Frappe sauvage" -- Alone cost 45 rage -- "Bloodsurge" 46916 "Afflux sanguin"
	{ warrior.spells["WildStrike"] , jps.rage() > 80 , rangedTarget ,"_WildStrike_Rage" },
	-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116
	{ warrior.spells["RagingBlow"] , jps.buffDuration(131116) < 4 , rangedTarget , "_RagingBlow_Buff" },
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
		{ warrior.spells["BattleShout"],'not jps.buff(6673)' , "player"},

		-- Normal Rotation
		{ warrior.spells["RagingBlow"] ,'jps.buffStacks(131116) == 2', warrior.rangedTarget },
		{ warrior.spells["WildStrike"] ,'jps.buff(46916)', warrior.rangedTarget },
		{ warrior.spells["Bloodthirst"] ,'true', warrior.rangedTarget},

	}
,"Warrior Static Fury", true, false)