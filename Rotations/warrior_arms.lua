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

jps.registerRotation("WARRIOR","ARMS",function()

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
local inMelee = jps.IsSpellInRange(163201,"target") -- "Execute" 163201
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
	{ 6544, IsShiftKeyDown() , "player" },
	
	-- BUFFS 
	-- "Battle Stance"" 2457 -- "Defensive Stance" 71
	{ warrior.spells["BattleStance"], not jps.buff(71) and not jps.buff(2457) , "player" },
	-- "Battle Shout" 6673 "Cri de guerre"
	{ warrior.spells["BattleShout"], not jps.hasAttackPowerBuff("player") and not jps.buff(469) , "player" },
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
		{ 114028 , jps.UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "_MassSpell" },
	}},
	
	-- DAMAGE MITIGATION --
	{ "nested", jps.Defensive ,{
		-- "Stoneform" 20594 "Forme de pierre"
		{ 20594 , playerAggro and playerhealth_pct < 0.85 , rangedTarget , "_Stoneform" },
		{ 20594 , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },
		-- "Impending Victory" 103840 "Victoire imminente" -- Talent Replaces Victory Rush.
		{ 103840 , playerhealth_pct < 0.85 , rangedTarget , "_ImpendingVictory" },
		-- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
		{ 103840 , jps.buffDuration(32216) < 4 , rangedTarget , "_ImpendingVictory" },
		-- Master Healing Potion
		{ jps.useBagItem(76097), playerhealth_pct < 0.50 }, 
		-- "Pierre de soins" 5512 "Healthstone"
		{ {"macro","/use item:5512"} , jps.combatStart > 0 and jps.itemCooldown(5512)==0 and playerhealth_pct < 0.50 , rangedTarget , "_UseItem"},
		-- "Die by the Sword" 118038
		{ 118038 , playerAggro and playerhealth_pct < 0.70 , rangedTarget , "_DieSword" },
		-- "Defensive Stance" 71
		{ warrior.spells["DefensiveStance"] , not jps.buff(71) and playerhealth_pct < 0.30 },
		-- "Shield Barrier" 112048 "Barrière protectrice" -- "Defensive Stance" 71
		{ 112048, jps.buff(71) and playerhealth_pct < 0.30 },
	}},

	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ 57755, inRanged , rangedTarget , "_Heroic Throw" },
	-- "Taunt" 355 "Provocation"
	-- "Charge" 100
	{ 100, jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
	
	 -- COOLDOWNS --
	{ "nested", inMelee and jps.UseCDs,{
		{ jps.useTrinket(0), jps.useTrinketBool(0) },
		{ jps.useTrinket(1), jps.useTrinketBool(1) },
		-- "Bloodbath" 12292 "Bain de sang"
		{ 12292, true , rangedTarget },
		-- "Recklessness" 1719 "Témérité" -- "Defensive Stance" 71 -- Avoid forcing back into battle stance
		{ 1719, not jps.buff(71) , rangedTarget },
	}},
	
	-- MULTI-TARGET 
	{ "nested", inMelee and jps.MultiTarget,{
		-- "Sweeping Strikes" 12328 "Attaques circulaires" 
		{ 12328, not jps.myDebuff(12328) , rangedTarget , "_SweepingStrikes" },
		-- "Bladestorm" 46924 "Tempête de lames"
		{ 46924, true , rangedTarget , "_Bladestorm" },
		-- "Rend" 772 "Pourfendre" -- Apply if tab-target has no debuff
		{ 772 , not jps.debuff(772,rangedTarget) , rangedTarget , "_Rend_Debuff" },
		{ 772 , jps.myDebuffDuration(772,rangedTarget) < 4 , rangedTarget , "_Rend_Duration" },
		-- "Ravager" 152277 -- "Bloodbath" 12292 "Bain de sang"
		{ 152277, jps.buff(12292) , rangedTarget , "_Ravager" },
		-- "Dragon Roar" 118000 "Rugissement de dragon"
		{ 118000, true , rangedTarget , "_DragonRoar" },
		-- "Whirlwind" 1680 "Tourbillon"
		{ 1680, true , rangedTarget , "_Whirlwind" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ 6343, true , rangedTarget , "_ThunderClap" },
	}},
	
	-- SINGLE TARGET --
	-- "Heroic Throw" 57755 "Lancer héroïque"
	{ 57755, inRanged , rangedTarget , "_Heroic Throw" },
	-- "Taunt" 355 "Provocation"
	-- "Charge" 100
	{ 100, jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
	-- "MortalStrike" 12294 "Frappe mortelle" -- Remplace "Frappe Heroique" -- Rage dump
	{ 12294, jps.rage() > 80 and jps.hp(rangedTarget) > 0.20 , rangedTarget , "_MortalStrike_Rage" },
	-- "Ravager" 152277 -- "Colossus Smash" 167105
	{ 152277, jps.cooldown(167105) < 3 , rangedTarget , "_Ravager"},
	-- 163201 "Execute" -- "Sudden Death" 52437 -- "Death Sentence" 144442
	{ 163201, jps.buff(144442) , rangedTarget , "_Execute_SuddenDeath" }, -- T16 4p
	{ 163201, jps.buff(52437) , rangedTarget , "_Execute_DeathSentence" },
	-- "Rend" 772 "Pourfendre"
	{ 772, not jps.debuff(772,rangedTarget) , rangedTarget , "_Rend_Debuff" },
	{ 772, jps.myDebuffDuration(772,rangedTarget) < 4 , rangedTarget , "_Rend_Duration" },
	-- "Storm Bolt" 107570 "Eclair de tempete"
	{ 107570, true , rangedTarget , "_StormBolt_Health" },
	
	-- PRE-EXECUTE PHASE -- target > 20% Health
	{ "nested", inMelee and jps.hp("target") > 0.20 and not jps.debuff(167105,"target"),{
		-- "MortalStrike" 12294 "Frappe mortelle" -- Remplace "Frappe Heroique"
		{ 12294 , true , rangedTarget , "_MortalStrike" },
		-- "Colossus Smash" 167105
		{ 167105, jps.rage() > 60 , rangedTarget , "_ColossusSmash" },
		-- "Dragon Roar" 118000 "Rugissement de dragon"
		{ 118000, true , rangedTarget , "_DragonRoar" },
		-- "Whirlwind" 1680 "Tourbillon"
		{ 1680, jps.rage() > 40 , rangedTarget , "_Whirlwind" },
		-- "Thunder Clap" 6343 "Coup de tonnerre"
		{ 6343, true , rangedTarget , "_ThunderClap" },
	}},

	{ "nested", inMelee and jps.hp(rangedTarget) > 0.20 and jps.debuff(167105,rangedTarget) ,{
		-- "MortalStrike" 12294 "Frappe mortelle" -- Remplace "Frappe Heroique"
		{ 12294, true , rangedTarget , "_MortalStrike" },
		-- "Impending Victory" 103840 "Victoire imminente"
		{ 103840, jps.rage() < 30 , rangedTarget , "_ImpendingVictory" },
		-- "Whirlwind" 1680 "Tourbillon"
		{ 1680, true , rangedTarget , "_Whirlwind" },
		-- "Shockwave" 46968 "Onde de choc"
		{ 46968, true , rangedTarget , "_Shockwave" },
	}},
	
	-- EXECUTE PHASE -- target < 20% Health -- "Colossus Smash" 167105
	{ "nested", inMelee and jps.hp(rangedTarget) < 0.20 ,{
		-- 163201 "Execute"
		{ 163201, true , rangedTarget , "_Execute_Health" },
		-- "Colossus Smash" 167105
		{ 167105, jps.rage() > 60 , rangedTarget , "_ColossusSmash_Health" },
		-- "Dragon Roar" 118000 "Rugissement de dragon"
		{ 118000, true , rangedTarget , "_DragonRoar_Health" },
	}},

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Warrior Arms SNM")
