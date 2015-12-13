--[[[
@rotation PvP
@class Warrior
@spec Arms
@talents Juggernaut or Double Time, Enraged Regeneration, Taste for Blood[br]
Storm Bolt, Mass Spell Reflection, Bladestorm, Anger Management
@author SwollNMember
@description
This is a pvp rotation.[br]
Not optimal for pve.[br]
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
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			return true
		elseif strfind(auraName,L["Cyclone"]) then
			return true
		elseif strfind(auraName,L["Hex"]) then
			return true
		elseif strfind(auraName,L["Deterrence"]) then
			return true
		elseif strfind(auraName,L["Ice Block"]) then
			return true
		end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i))
	end
	return false
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
-------------------------------------------------- PvP ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("WARRIOR","ARMS",function()

local spell = nil
local target = nil
local myHealer,HealerUnit = jps.findHealerInRaid() -- default "focus"
local playerhealth_pct = jps.hp("player")
local playerVirtualHP = jps.hpInc("player")
local playerTTD = jps.TimeToDie("player")
local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local hasControl = HasFullControl() -- returns true /false if the player character can be controlled (i.e. isn't feared, charmed...)
local Enrage = jps.buff(12880) -- "Enrage" 12880 "Enrager"
--local inMelee = IsItemInRange("Heavy Silk Bandage","target") -- FAIL!
local inMelee = jps.IsSpellInRange(163201,"target") -- "Execute" 163201
--FAIL! local inMeleeRange = select(6, GetSpellInfo(163201)) -- "Execute" 163201
     --if inMeleeRange <= 6 then inMelee = true end
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"
local inAoE = CheckInteractDistance("target", 3)
local inCombat = UnitAffectingCombat("player") -- not necessarily inMelee, inRanged, inAoE
local mounted = IsMounted()
local creatureType = UnitCreatureType("target")

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

local ClassCounters = {
   { 1499, jps.debuff("psychic scream","player") }, -- Fear
   { 1499, jps.debuff("fear","player") }, -- Fear
   { 1499, jps.debuff("intimidating shout","player") }, -- Fear
   { 1499, jps.debuff("howl of terror","player") }, -- Fear
   { 1499, jps.debuff("mind control","player") }, -- Charm
   { 1499, jps.debuff("seduction","player") }, -- Charm
   { 1499, jps.debuff("wyvern sting","player") }, -- Sleep
}

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

   -- "Heroic Leap" 6544 "Bond héroïque"
   { 6544, IsControlKeyDown() , "player" },
   
   -- "Bladestorm" 46924 "Tempête de lames" -- Storm Bolt debuff is 132169
   { 46924, jps.combatStart > 0 and jps.debuff(132169) and inAoE , rangedTarget , "_BoltBladestorm" },
   
   -- CLASS COUNTERS -- share 30s cd with trinket
   --{ "nested", jps.UseCDs , ClassCounters },
   { 1499, not hasControl and jps.combatStart > 0 , "player" , "enrage_hasControl" },
   { 1499, playerIsStun and jps.combatStart > 0 , "player" , "enrage_stun" },
   
   -- BUFFS --
   -- "Battle Stance" 2457
   { 2457, playerVirtualHP > 0.30 and not jps.buff(2457) and not jps.buff(46924) and not mounted and inCombat , "player" },
   -- "Defensive Stance" 71 -- stay in def stance when not in combat for stealthies
   { 71 , not inCombat , "player" },
   -- "Battle Shout" 6673 "Cri de guerre"
   { 6673, not jps.hasAttackPowerBuff("player") and not jps.buff(469) , "player" },
   -- "Commanding Shout" 469 "Cri de commandement"
   { 469, not jps.hasStaminaBuff("player") and jps.hasAttackPowerBuff("player") , rangedTarget , "_CommandingShout" },

   -- INTERRUPTS --
   { "nested", jps.Interrupts,{
      -- "Choc martial" 74606 "War Stomp" -- Racial
      { 74606, jps.ShouldKick() and jps.cooldown(6552) > 0 , rangedTarget },
      -- "Pummel" 6552 "Volée de coups"
      { 6552 , jps.ShouldKick(rangedTarget) , rangedTarget , "_Pummel" },
      { 6552 , jps.ShouldKick("focus") , "focus" , "_Pummel" },
      -- "Intimidating Shout" 5246
      { 5246, jps.ShouldKick(rangedTarget) and inMelee , rangedTarget , "_KickShout"},
      -- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
      { 114028 , ClassEnemy = "caster" and UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "_MassSpell" },
      -- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
      { 114028 , jps.debuff("Frost Nova") , rangedTarget , "_MassSpell" },
      -- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
      { 114028 , jps.debuff("Frost Nova") or jps.debuff("Freeze") , rangedTarget , "_MassSpell" },   
   }},
   
   -- DAMAGE MITIGATION --
   -- "Charge" 100 -- charge to pushback
   { 100, jps.fallingFor() > 0.2 and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_ChargeFalling"},
   -- "Intervene" 3411
   { 3411, jps.hp(myHealer) < 0.30 and jps.FriendAggro(myHealer) , myHealer , "_InterveneHealer" },
   -- "Taunt" 355 -- Taunt enemy pet off friend -- Will force into defensive stance
   { 355, UnitIsPlayer("target") == false and not UnitIsUnit("targettarget","player") and UnitIsUnit("targettarget",myHealer) , rangedTarget , "_Taunt" },
   -- "Intimidating Shout" 5246 -- To peel off healer
   { 5246, inAoE and UnitIsUnit("targettarget",myHealer) , rangedTarget , "_IntShoutPeel"},
   
   { "nested", jps.Defensive and playerAggro,{
      -- "Stoneform" 20594 "Forme de pierre"
      { 20594 , playerhealth_pct < 0.85 , rangedTarget , "_Stoneform" },
      { 20594 , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },
      -- "Defensive Stance" -- While bladestorm to minimize damage to player
      { 71 , jps.buff(46924) },
     
      -- LOW HEALTH CASCADE -- Commanding Shout > Rallying Cry > Enraged Regeneration
      -- "Defensive Stance"
      { 71 , not jps.buff(71) and playerhealth_pct < 0.30 },           
      -- "Commanding Shout" 469
      { 469, not jps.hasStaminaBuff("player") and playerhealth_pct < 0.30 , "player" , "_ComShoutLowHP" },
      -- "Rallying Cry" 97462 -- 15% increase to maximum health for 10 sec.
      { 97462, playerVirtualHP < 0.30 , "player" , "_RallyCry" },
      -- "Enraged Regeneration" 55694 "Régénération enragée"
      { 55694, jps.buff(97463) , "player" , "_EnragedRegen_RallyCry" },
      { 55694, playerhealth_pct < 0.30 and playerIsStun and playerAggro , "player" , "_EnragedRegen_Stun" },
      { 55694, playerVirtualHP < 0.30 , "player" , "_EnragedRegen" },
     
      -- "Victory Rush" 34428 "Ivresse de la victoire" -- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
      { 34428, playerhealth_pct < 0.85 , rangedTarget , "_VictoryRush" },
      { 34428, jps.buffDuration(32216) < 4 , rangedTarget , "_VictoryRush" },
      -- "Pierre de soins" 5512 "Healthstone"
      { {"macro","/use item:5512"} , jps.combatStart > 0 and jps.itemCooldown(5512)==0 and playerhealth_pct < 0.50 , rangedTarget , "_UseItem"},
      -- "Die by the Sword" 118038
      { 118038 , ClassEnemy == "cac" and playerVirtualHP < 0.30 , rangedTarget , "_DieSword" },
      -- "Shield Barrier" 174926 "Barrière protectrice" -- "Defensive Stance" 71
      { 174926, ClassEnemy == "cac" and jps.buff(71) and not jps.buff(174926) and playerVirtualHP < 0.30 },
   }},

   -- "Heroic Throw" 57755 "Lancer héroïque"
   { 57755, inRanged and not inMelee , rangedTarget , "_HeroicThrow" },
   -- "Charge" 100
   { 100, UnitIsPlayer("target") and jps.UseCDs and jps.IsSpellInRange(100,rangedTarget) , rangedTarget , "_Charge"},
   { 100, jps.UseCDs and TargetMoving , rangedTarget , "_MoveCharge"},   
   -- "Hamstring" 1715
   { 1715, not jps.debuff(1715) and not UnitClass("druid") and not isBoss , rangedTarget , "_Hamstring"},
   -- "Intimidating Shout" 5246
   { 5246, jps.cooldown(107570) > 0 and jps.LastCast ~= "Storm Bolt" and not jps.debuff(5246,rangedTarget) and not isBoss and not jps.LoseControl(rangedTarget) , rangedTarget , "_IntimidatingShout"},
   
   -- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId 13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
   -- DPS trinket in top slot(13) and CC break in bottom slot(14)
   --{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.UseCDs and inMelee and jps.combatStart > 0 , rangedTarget , "Trinket0"},
   { jps.useTrinket(1), jps.PvP and jps.useTrinketBool(1) and not hasControl and jps.combatStart > 0 , "player" , "useTrinket1_hasControl" },
   { jps.useTrinket(1), jps.PvP and jps.useTrinketBool(1) and playerIsStun and jps.combatStart > 0 , "player" , "useTrinket1" },
   
   -- "Berserker Rage" 1499 -- Sap id is 6770
   { 1499, jps.debuff(6770) , "player" , "_BRSapBreak" },
   
   -- DPS BOOST --
   -- Racial --
   { jps.getDPSRacial(), jps.combatStart > 0 and jps.UseCDs and inMelee , rangedTarget , "_Racial" },
   -- "Recklessness" 1719 "Témérité" -- "Defensive Stance" 71 -- Avoid forcing back into battle stance
   { 1719, jps.combatStart > 0 and jps.rage() > 60 and inMelee and jps.debuff(167105,rangedTarget) , rangedTarget , "_Recklessness" },
   -- "Bloodbath" 12292 "Bain de sang"  -- jps.buff(12292)
   { 12292, jps.combatStart > 0 and inMelee and jps.debuff(167105,rangedTarget), rangedTarget , "_Bloodbath" },
   
   -- TALENTS --
   -- "Storm Bolt" 107570 "Eclair de tempete"
   { 107570, jps.LastCast ~= "Intimidating Shout" and UnitIsPlayer("target") and jps.IsSpellKnown(107570) and not jps.LoseControl(rangedTarget) , rangedTarget , "_StormBolt_Health" },
   -- "Dragon Roar" 118000 "Rugissement de dragon"
   { 118000, jps.IsSpellKnown(118000) and inMelee , rangedTarget , "_DragonRoar" },
   -- "Ravager" 152277 -- "Colossus Smash" 167105
   { 152277, jps.IsSpellKnown(152277) and jps.debuff(167105,rangedTarget) , rangedTarget , "_Ravager"},
   -- "Siegebreaker" 176289 "Briseur de siège"
   { 176289 , jps.IsSpellKnown(176289) , rangedTarget ,"_Siegebreaker" },
   -- "Execute" 163201 "Exécution" -- "Mort soudaine" 29725
   { 163201, jps.buff(29725) , rangedTarget , "Execute_SuddenDeath" },

   -- MULTI-TARGET --
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
   -- "Bladestorm" 46924 "Tempête de lames"
   -- Sap debuff is 6770
   { 46924, jps.combatStart > 0 and jps.debuff(6770) , rangedTarget , "_SapBladestorm" },
   -- Storm Bolt debuff is 132169
   { 46924, jps.combatStart > 0 and jps.debuff(132169) and inAoE , rangedTarget , "_BoltBladestorm" },
   -- Intimidating Shout debuff is 5246
   { 46924, jps.combatStart > 0 and jps.debuff(5246) and inAoE , rangedTarget , "_FearBladestorm" },
   
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
   { 1680, jps.combatStart > 0 and jps.hp(rangedTarget) > 0.20 and inAoE , rangedTarget , "_Whirlwind" }
}

spell,target = parseSpellTable(spellTable)
return spell,target
end, "Warrior Arms PvP")

--------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- TO DO FOR PVP --
-- C=conceptual, T=to do, W=working, U=unsure if working, N=not working
--T Dont blow major burst when target is above 50% virtual health.
   -- Healer above 30% or defensives on cd
--U Dont cast ccs when target is already ccd.
--T Create peel rotation for healer.
--N Fix blowing rage on whirlwind when not in range of target. inAoE
--T Smart trinket use. Conditional for DPS, defensive, etc.
--T Auto-choose enemy healer as target.
--T Save Storm Bolt and Int Shout when target=caster.
--U No Storm Bolt or Int Shout if target is stunned.
--T On mouseover of target, Heroic Leap if Charge is out of range or on cd.
--T Pop burst damage when opponent has low defense. BuffEnemyDefense
--T Use playerTTD to fine tune defensives.
--C PoachKill: Auto-target lowest health enemy in range if efc or enemy healer is not current target.
--C TargetPetOwner: Target the owner of a pet attacking player.
   -- Read tooltip text?
--U Taunt pet off healer.
--T Totem stomp.
--W Ensure character is in Defensive Stance if OOC.
--T Switch target to unit targeting healer if Intervene.
--T Reacquire target if target blinks or feign death.
--U Berserk rage out of sap. Other stuns to be included later.