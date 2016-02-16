local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit

local EnemyCaster = function(unit)
   if not jps.UnitExists(unit) then return false end
   local _, classTarget, classIDTarget = UnitClass(unit)
   return ClassEnemy[classTarget]
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- PvP ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PALADIN","RETRIBUTION",function()

local spell = nil
local target = nil
local myHealer,HealerUnit = jps.findHealerInRaid() -- default "focus"
local myTank,TankUnit = jps.findTankInRaid() -- default "focus"
local playerhealth_pct = jps.hp("player")
local playerVirtualHP = jps.hpInc("player")
local holyPower = UnitPower("player")
local playerTTD = jps.TimeToDie("player")
local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local hasControl = HasFullControl() -- returns true /false if the player character can be controlled (i.e. isn't feared, charmed...)
local inMelee = jps.IsSpellInRange(6603,"target") -- "Auto Attack 6603"
--FAIL! local inMeleeRange = select(6, GetSpellInfo(163201)) -- "Execute" 163201
     --if inMeleeRange <= 6 then inMelee = true end
local inRanged = jps.IsSpellInRange(85673,"target") -- "Word of Glory" 85673
local inAoE = CheckInteractDistance("target", 3)
local inCombat = UnitAffectingCombat("player") -- not necessarily inMelee, inRanged, inAoE
local inRaid = IsInRaid()
local inGroup = IsInGroup()
local mounted = IsMounted()
local creatureType = UnitCreatureType("target")

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()
local targetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0
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

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {
   
   -- BUFFS --
   -- Blessings --
   -- "Blessing of Kings" 20217
   { 20217, not jps.hasAttackPowerBuff("player") , "player" },
   -- "Blessing of Might" 31801
   { 31801, not jps.jps.hasMasteryBuff("player") , "player" },
   -- "Blessing of Might" 31801
   { 31801, not jps.jps.hasMasteryBuff("player") and not inRaid and not inGroup , "player" },
   
   -- Seals --
   -- "Seal of Truth" 31801
   { 31801, not jps.buff(31801) and not jps.MultiTarget , "player" },
   -- "Seal of Righteousness" 20154
   { 20154, not jps.buff(20154) and jps.MultiTarget , "player" },
   
   -- Tier 7 --
   -- "Seraphim" 152262 -- Haste, Critical Strike, Mastery, Multistrike, Versatility, and Bonus Armor increased by 1,000.
   { 152262, true, "player" , "Seraphim" },
   -- "Avenging Wrath" 31884 -- Stack with Seraphim
   { 31884, jps.buff(152262) , "AvengingWrath" },

   -- INTERRUPTS --
   { "nested", jps.Interrupts, {
      -- "Arcane Torrent" 155145 -- Blood Elf Racial -- Use for emergency holy power
      { 155145, jps.ShouldKick() and inMelee , rangedTarget },
      -- "Rebuke" 96231
      { 96231, jps.ShouldKick() , rangedTarget },
      -- "Fist of Justice" 105593
      { 105593, jps.ShouldKick() , rangedTarget },
      { 105593, targetMoving , rangedTarget },
   }},
   
   -- DAMAGE MITIGATION --
   -- "Cleanse" 4987 -- Remove disease and poison from target
   { 4987, jps.canDispel(myHealer,{"Poison","Disease"}) , myHealer , "CleanseHealer" },
   { 4987, jps.canDispel(myTank,{"Poison","Disease"}) , myTank , "CleanseTank" },
   { 4987, jps.canDispel("player",{"Poison","Disease"}) , "player" , "CleansePlayer" },
   -- "Emancipate" 121783 -- Free from one movement impairing effect
   { 121783, select(1,GetUnitSpeed(myHealer)) < 7 and select(1,GetUnitSpeed(myHealer)) > 0 , myHealer , "EmancipateHealer" },
   { 121783, select(1,GetUnitSpeed(myTank)) < 7 and select(1,GetUnitSpeed(myTank)) > 0 , myTank , "EmancipateTank" },
   { 121783, select(1,GetUnitSpeed("player")) < 7 and jps.Moving , "player" },
   
   -- Divine Spells --
   -- "Divine Protection" 498 -- Reduce magical damage
   { 498, jps.hp(myHealer) < 0.30 and jps.FriendAggro(myHealer) , myHealer , "_DivineProtHealer" },
   { 498, jps.hp(myTank) < 0.30 and jps.FriendAggro(myTank) , myTank , "_DivineProtTank" },
   { 498, ClassEnemy = "caster" and UnitIsUnit("targettarget","player") and jps.IsCasting(rangedTarget) , rangedTarget , "_DivineProtPlayer" },
   -- "Divine Shield" 642 -- Protect from all damage -- Causes Forbearance 25771
   { 642, jps.TimeToDie(myHealer) < 3 and jps.FriendAggro(myHealer) , myHealer , "_DivineShieldHealer" },
   { 642, jps.TimeToDie(myTank) < 3 and jps.FriendAggro(myTank) , myTank , "_DivineShieldTank" },
   
   -- Heals --
   -- "Flash of Light" 19750 -- Heal
   { 19750, jps.hpInc(myHealer) < 0.30 , myHealer , "FoLHealer" },
   { 19750, jps.hpInc(myTank) < 0.30 , myTank , "FoLTank" },
   { 19750, playerVirtualHP < 0.30 , "player" , "FoLPlayer" },
   -- "Lay on Hands" 633 -- Insta heal -- Causes Forbearance 25771
   { 633, playerVirtualHP < 0.25 and playerTTD < 4 and not jps.buff(642) and playerAggro , "LoHPlayer" },
   -- "Stay of Execution" 114157 -- 9 sec HoT
   { 114157, jps.hpInc(myHealer) < 0.30 and jps.FriendAggro(myHealer) , myHealer , "SoEHealer" },
   { 114157, jps.hpInc(myTank) < 0.30 and jps.FriendAggro(myTank) , myTank , "SoETank" },
   { 114157, playerVirtualHP < 0.30 and playerAggro , "player" , "SoEPlayer" },
   
   -- "Arcane Torrent" 155145 -- Emergency: generates 1 holy power
   { 155145, holyPower < 3 and jps.hpInc(myHealer) < 0.30 , "player" },
   { 155145, holyPower < 3 and jps.hpInc(myTank) < 0.30 , "player" },
   { 155145, holyPower < 3 and playerVirtualHP < 0.30 , "player" },
   -- "Word of Glory" 85673 -- Consumes 1-3 Holy Power
   { 85673, holyPower > 1 and jps.hpInc(myHealer) < 0.30 , myHealer , "WoGHealer" },
   { 85673, holyPower > 1 and jps.hpInc(myTank) < 0.30 , myTank , "WoGTank" },
   { 85673, holyPower > 1 and playerVirtualHP < 0.30 , "player" , "WoGPlayer" },
   
   -- Hand Spells -- Only one hand can be on target
   -- "Hand of Freedom" 1044 -- Removes movement impairment
   { 1044, select(1,GetUnitSpeed(myHealer)) < 7 and select(1,GetUnitSpeed(myHealer)) > 0 , myHealer , "FreedomHealer" },
   { 1044, select(1,GetUnitSpeed("player")) < 7 and jps.Moving , "player" , "FreedomPlayer" },
      --jps.Moving and jps.LoseControl("player",{"Root"}) },
      --jps.Moving and jps.LoseControl("player",{"Snare"}) },
   -- "Hand of Protection" 1022 -- Protects from all physical attacks -- Causes Forbearance 25771
   { 1022, not jps.debuff(25771,myHealer) and jps.TimeToDie(myHealer) < 3 , myHealer , "HoPHealer" }, -- Use vs heavy melee damage
   -- "Hand of Sacrifice" 6940 -- Remove all harmful magic and transfer health to target
   { 6940, not jps.debuff(25771,myHealer) and jps.TimeToDie(myHealer) < 3 , myHealer , "HoSHealer" }, -- Use vs heavy caster damage
   
   --{ "nested", jps.Defensive and playerAggro,{
      --
      --{
   --}},
   
   -- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId 13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId 14
   -- DPS trinket in top slot(13) and CC break in bottom slot(14)
   --{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.UseCDs and inMelee and jps.combatStart > 0 , rangedTarget , "Trinket0"},
   { jps.useTrinket(1), jps.useTrinketBool(1) and not hasControl and jps.combatStart > 0 , "player" , "useTrinket1_hasControl" },
   { jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun and jps.combatStart > 0 , "player" , "useTrinket1" },
   
   -- DPS BOOST --
   
   -- TALENTS --

   -- MULTI-TARGET --
   { "nested", jps.MultiTarget and inMelee , {
      -- "Divine Storm" 53385 -- Empowered Divine Storm buff
      { 53385, true , rangedTarget , "DivineStorm" },
      -- "Hammer of the Righteous" 53595 -- On CD
      { 53595, true , rangedTarget , "HammerRight" },
   }},
   
   -- SINGLE TARGET --
   -- "Execution Sentence" 114157 -- On CD
   { 114157, true, rangedTarget , "ExecutionSentence" },
   -- "Hammer of Wrath" 24275 -- Below 20% health
   { 24275, jps.hp(rangedTarget) < 0.35 , "HammerWrath" },
   { 24275, jps.buff(31884) , rangedTarget , "HammerWrath_Avenge"},
   -- "Crusader Strike" 35395
   { 35395, true , rangedTarget , "CrusaderStrike" },
   -- "Judgement" 20271
   { 20271, true , rangedTarget , "Judgement" },
   -- "Exorcism" 879
   { 879, true , rangedTarget , "Exorcism" }
   -- "Final Verdict" -- 5 holy power or 3-4 holy power and no holy power generator available
   
}

spell,target = parseSpellTable(spellTable)
return spell,target
end, "Paladin Ret PvP")