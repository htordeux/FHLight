-- SwollNMember
-- use macro /jps.Multi for multiple targets
-- when > 6 enemies, hold shift to remove eviscerate
-- from the rotation and build cp for crimson tempest

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

jps.registerRotation("ROGUE","COMBAT",function()

--local "player" = player
local comboPoints = GetComboPoints("player")
local energy = UnitPower("player",3)
local ruptureDuration = jps.debuffDuration("rupture")
local sndDuration = jps.buffDuration("Slice and Dice")
local arDuration = jps.buffDuration("adrenaline rush") -- simcraft
local arMultiplier = arDuration * 2 -- simcraft
local ksDuration = jps.buffDuration("killing spree") -- simcraft
local ksMultiplier = ksDuration * 5 -- simcraft
local rsDuration = jps.debuffDuration("revealing strike") -- simcraft
local rsAddition = rsDuration + 7 -- simcraft
local vanishMacroText = "/cancelaura Vanish"
local vanishMacro = { "macro", vanishMacroText }
local tricksText = "/cast [@targettarget]Tricks of the Trade"
local tricksMacro = { "macro", tricksText }
local targetClass = UnitClass("target")
local enemyIsMelee = targetClass == "warrior" or targetClass == "rogue" or targetClass == "death knight"
-- Shiv Conditions --
-- berserker rage(warrior) 18499, enrage(warrior) 13046, bloodbath(warrior) 12292 -- add more later
local enemyEnrage = 18499 or 13046 or 12292
local isBehind = jps.isBehind == true
local isNotBehind = jps.isNotBehind == true
local spell = nil
local target = nil
local myTank,TankUnit = jps.findTankInRaid()
local myHealer,HealerUnit = jps.findHealerInRaid()
local playerhealth_pct = jps.hp("player")
local playerVirtualHP = jps.hpInc("player")
local playerTTD = jps.TimeToDie("player")
local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR "player" -- "ROOT" was removed of Stuntype
--    {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR "player"
local playerWasControl = jps.ControlEvents() -- return true/false "player" was interrupt or stun 2 sec ago ONLY FOR "player"
local hasControl = HasFullControl() -- returns true /false if the "player" character can be controlled (i.e. isn't feared, charmed...)
local inMelee = jps.IsSpellInRange(8676,"target") -- "Ambush"
local inCloseRange = jps.IsSpellInRange(6770,"target") -- "Sap" 10yd
local inShortRange = jps.IsSpellInRange(2094,"target") -- "Blind" 15yd
local inMedRange = jps.IsSpellInRange (36554,"target") -- "Shadowstep" 25yd
local inLongRange = jps.IsSpellInRange(26679,"target") -- "Deadly Throw" 30yd
local inAoERange = CheckInteractDistance("target", 3) -- 9.9yd
local inCombat = UnitAffectingCombat("player")
local mounted = IsMounted()
local creatureType = UnitCreatureType("target")

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()
local isBoss = (UnitLevel("target") == -1) or (UnitClassification("target") == "elite")
local targetTTD = jps.TimeToDie(rangedTarget)
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

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

-- Rupture -- Assasination/Subtlety only
--[[ local function shouldRupture
if not jps.debuff("Rupture") and not jps.buff("blade flurry") and jps.debuff("revealing strike") then return false end
if jps.debuff("Trauma") then return true end
if jps.debuff("hemorrhage") then return true end
if jps.debuff("mangle") then return true end
end ]]

local spellTable =
{
   -- SetView -- reset camera for all the jumping around lol
   { SetView(5), nil , "player" },
   
   -- BUFFS/DEBUFFS--
   { {"macro","/cancelaura Blade Flurry"}, jps.buff("Blade Flurry") and not jps.MultiTarget , rangedTarget },
   -- "Marked for Death" +5cp
   { "Marked for Death", not jps.debuff("marked for death") , rangedTarget },
   -- "Killing Spree" 2m cd
   { "Killing Spree", inMelee and jps.UseCDs and not jps.MultiTarget and energy < 20 and not jps.buff("adrenaline rush") },
   -- "Adrenaline Rush" 3m cd
   { "Adrenaline Rush", inMelee and jps.UseCDs and not jps.buff("killing spree"), "player" },
   -- "Slice and Dice" -25e
   { "Slice and Dice", not jps.buff("slice and dice") , "player" },
   { "Slice and Dice", jps.buffDuration("slice and dice") < 10 , "player" },

   -- UTILITY and RESETS--
   -- "Arcane Torrent" +15e
   { "Arcane Torrent", energy < 60 , "player" }, -- bloodelf only
   -- "Preparation"
   { "Preparation", playerAggro and jps.UseCDs and jps.cooldown("Evasion") > playerTTD , "player" },
   -- "Stealth"
   { "Stealth", not inCombat and isBoss , "player" },
   -- "Vanish"
   { "Vanish", playerAggro and isBoss and IsInGroup() , "player" },
   -- "Shadowstep"
   { "Shadowstep", isNotBehind and inCombat and inMedRange , rangedTarget },
   -- "Sprint"
   { "Sprint", inCombat and inLongRange and not inShortRange , "player" }, -- Don't blow if target is close enough

   -- TRINKETS -- PvP: DPS trinket in top slot(13), CC break in bottom slot(14) PvE: DPS in top and bottom
      { jps.useTrinket(0), not jps.PvP and jps.useTrinketBool(0) and jps.UseCDs and inMelee and jps.combatStart > 0 , "player" },
      { jps.useTrinket(1), jps.useTrinketBool(1) and not hasControl and jps.combatStart > 0 , "player" },
      { jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun and jps.combatStart > 0 , "player" },

   -- INTERRUPTS --
   { "Arcane Torrent", inAoERange and jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget },
   -- "Kick"
   { "Kick", jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget },
   -- "Kidney Shot" -25e
   { "Kidney Shot", jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget },
   -- "Cheap Shot" +2cp -40e
   { "Cheap Shot", jps.Interrupts and jps.buff("stealth") and jps.ShouldKick(rangedTarget) , rangedTarget },
   { "Cheap Shot", comboPoints < 3 , rangedTarget }, -- use as cp builder
   -- "Garrot" +1cp -45e
   { "Garrot", jps.Interrupts and jps.buff("stealth") and jps.ShouldKick(rangedTarget) , rangedTarget },
   -- "Gouge" -45e target must be facing
   { "Gouge", jps.Interrupts and isNotBehind and jps.ShouldKick(rangedTarget) , rangedTarget }, -- Any subsequent damage removes
   -- "Throw"
   { "Throw", inLongRange and jps.IsCasting(rangedTarget) and not isBoss , rangedTarget }, -- try to push back casting
   -- "Shiv" -20e
   { "Shiv", enemyEnrage , rangedTarget },

   -- DAMAGE MITIGATION --
   -- "Tricks of the Trade"
   { "Tricks of the Trade", playerAggro and IsInGroup() , myTank },
   -- "Healthstone"
   { {"macro","/use item:5512"}, playerVirtualHP < 0.75 , "player" },
   -- "Evasion" -20e
   { "Evasion", playerVirtualHP < 0.6 and not jps.buff("evasion") and playerAggro , "player" },
   -- "Recuperate" -30e
   { "Recuperate", playerVirtualHP < 0.8 and not jps.buff("Recuperate") , "player" },
   -- "Faint"
   { "Faint", jps.debuffAoE() , "player" }, -- currently only for PvP
   { "Faint", playerAggro and playerVirtualHP < 0.6 and jps.IsSpellKnown("elusiveness") , "player" },
   -- "Cloak of Shadows"
   { "Cloak of Shadows", jps.IsCasting(rangedTarget) and UnitIsUnit("targettarget", "player") , "player" },
   -- "Combat Readiness"
   { "Combat Readiness", enemyIsMelee and playerAggro , "player" },

   -- MULTI-TARGET --
   { "nested", inAoERange and jps.MultiTarget ,
      {
         -- "Blade Flurry" -- 2 to 4 enemies
         { "Blade Flurry", energy < 20 , "player" },
         -- "Killing Spree"
         { "Killing Spree", jps.buff("blade flurry") , "player" },
         -- "Crimson Tempest" -- hold shift if > 6 enemies
         { "Crimson Tempest", IsShiftKeyDown() == false and not jps.debuff("crimson tempest") , "player" },
         { "Crimson Tempest", IsShiftKeyDown() and not jps.debuff("crimson tempest") and comboPoints == 5 , "player" },
      }
   },
   
   -- SINGLE TARGET --
   -- "Marked for Death" +5cp
   { "Marked for Death", not jps.debuff("marked for death") , rangedTarget },
   -- "Deadly Throw" -35e
   { "Deadly Throw", inLongRange and not inAoERange , rangedTarget },
   -- "Ambush" +2cp
   { "Ambush", jps.IsSpellKnown("shadow focus") , rangedTarget },
   { "Ambush", jps.buff("stealth") , rangedTarget },
   { "Ambush", jps.buff("vanish") , rangedTarget },
   -- "Eviscerate" -5cp
   { "Eviscerate", IsShiftKeyDown() == false and jps.cooldown("slice and dice") < 36 and comboPoints == 5 , rangedTarget },
   -- "Revealing Strike" +1cp -40e
   { "Revealing Strike", not jps.debuff("revealing strike") , rangedTarget },
   -- "Sinister Strike" +1cp
   { "Sinister Strike", jps.IsSpellKnown(114015) and jps.buffStacks("anticipation") > 3 and jps.debuff("revealing strike") , rangedTarget }, -- only works if have anticipation talent
   { "Sinister Strike", comboPoints < 5 , rangedTarget },
}

spell,target = parseSpellTable(spellTable)
return spell,target
end, "Rogue Combat PvE", false, true)

-- TO DO --
-- CC enemies attacking myHealer