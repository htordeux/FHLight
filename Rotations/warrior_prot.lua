
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit
local spells = jps.spells.warrior

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
local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if UnitCanAssist("player",Tank) then TankTarget = Tank.."target" end
local TankThreat = jps.findThreatInRaid()
local playerIsTanking = false
if UnitIsUnit("player",TankThreat) then playerIsTanking = true end

local inMelee = jps.IsSpellInRange(spells.devastate,"target")
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

-- Config FOCUS with MOUSEOVER
if not jps.UnitExists("focus") and canAttack("mouseover") then
	-- set focus an enemy targeting you
	if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy in combat
	elseif canDPS("mouseover") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end

if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	jps.Macro("/clearfocus")
end

if canDPS("target") then rangedTarget =  "target"
elseif canDPS(TankTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

local PlayerBossDebuff = jps.BossDebuff("player")
if jps.hp("player") < 0.25 then CreateMessage("LOW HEALTH!")
elseif PlayerBossDebuff then CreateMessage("BOSS DEBUFF!") end

local damageIncoming = jps.IncomingDamage() - jps.IncomingHeal()
local playerIsTargeted = jps.playerIsTargeted()

------------------------
-- SPELL TABLE ---------
------------------------

if not UnitCanAttack("player", "target") then return end

local spellTable = {

-- "Interception" 198304
{spells.intercept, CheckInteractDistance("target",2) == false and CheckInteractDistance("target", 1) == true , "target" , "interceptTarget" },
{spells.intercept, not playerIsTanking and CheckInteractDistance(TankThreat,2) == false and CheckInteractDistance(TankThreat, 1) == true , TankThreat , "interceptTank" },

-- "Bond héroïque" 6544 "Heroic Leap"
--{spells.heroicLeap, jps.cooldown(spells.intercept) == 0 and jps.rage() < 10 },

-- interrupts --
{spells.pummel, jps.Interrupts and jps.ShouldKick("target") },
{spells.spellReflection, jps.IsCasting(rangedTarget) and jps.cooldown(spells.pummel) > 0 , rangedTarget },
{spells.shockwave, jps.PvP and not jps.LoseControl("target"), "target", "PvP_shockwave"  },

-- Heroic Leap resets the cooldown of Taunt.
{spells.taunt, jps.Defensive and not playerIsTargeted },
-- "Berserker Rage" cd 60 sec
{spells.berserkerRage, playerIsStun },
{spells.berserkerRage, jps.buff(spells.battleCry) },
-- "Ivresse de la victoire" 34428
{spells.victoryRush, jps.hp() < 1 },
-- "Mur protecteur" 871 buff same id
{spells.shieldWall, jps.hp() < 0.40 and not jps.buff(12975) , "target" , "shieldWall" }, -- cd 4 min
-- "Dernier rempart" 12975 buff same id
{spells.lastStand , jps.hp() < 0.40 and not jps.buff(871) , "target" , "lastStand" }, -- cd 3 min
-- "Demoralizing Shout" 1160
{spells.demoralizingShout, damageIncoming > 9000 and not jps.buff(190456) },

-- "Focused Rage" 204488 "Rage concentrée" -- Increasing Shield Slam damage by 50%, stacking up to 3 times -- gives buff 204488
-- "Ultimatum" buff 122510 Your next Focused Rage costs no Rage -- Ultimatum lasts 10 sec
{spells.focusedRage, jps.buff(122510) and not jps.buff(204488) , "target" , "focusedRage_Ultimatum" },
-- Vengeance talent buff 202573 reduces the Rage cost of your next Focused Rage by 35%
{spells.focusedRage, jps.buff(202573) and not jps.buff(204488) , "target" , "focusedRage_Vengeance" },
{spells.focusedRage, jps.rage() > 32 and jps.buff(204488) and jps.buffStacks(204488) < 3 , "target" , "focusedRage_Stacks" },
{spells.focusedRage, jps.rage() > 62 and not jps.buff(204488) , "target" , "focusedRage_unBuff" },

-- "Neltharion's Fury" cd 45 sec -- "Shield Block" buff 132404
{spells.neltharionsFury, not jps.Moving and not jps.buff(202574) and jps.cooldown(23922) > 2 , "target" , "neltharionsFury" },
{spells.neltharionsFury, not jps.Moving and not jps.buff(132404) and jps.cooldown(23922) > 2 , "target" , "neltharionsFury" },
-- "Shield Block" 2565 -- cd 13 sec, duration 6 sec, Increases Shield Slam damage by 30% while active - buff 
{spells.shieldBlock, not jps.buff(132404) }, -- "Shield Block" buff 132404
-- "Battle Cry" 1719 -- cd 60 sec, duration 5 sec, 100% increased critical strike chance for 5 sec -- "Shield Block" buff 132404
{spells.battleCry, jps.buff(132404) and jps.cooldown(spells.shieldSlam) == 0 , "target" , "battleCry" },
{spells.battleCry, jps.buff(spells.avatar) and jps.cooldown(spells.shieldSlam) == 0 , "target" , "battleCry" },
-- "Shield Slam" 23922
{spells.shieldSlam, inMelee },

-- "Dur au mal" 190456 -- gives buff 190456
-- "Vengeance: Ignore Pain" 202574 "Vengeance : Dur au mal"
-- Vengeance talent buff 202574 reduces the Rage cost of your next Ignore Pain by 35%
{ "nested" , playerIsTargeted or damageIncoming > 9000 , {
	{spells.ignorePain, jps.buff(202574) and not jps.buff(190456) , "target" , "ignorePain_Vengeance" },
	{spells.ignorePain, jps.buff(202574) and jps.buff(190456) and jps.buffDuration(190456) < 2 , "target" , "ignorePain_Duration" },
	{spells.ignorePain, jps.rage() > 32 and not jps.buff(190456) , "target" , "ignorePain__unBuff" },
}},

--MultiTarget -- including Renewed, Into the Fray, and Ravager
{ "nested" , jps.MultiTarget , {
    {spells.neltharionsFury }, -- cd 45 sec
    {spells.ravager }, -- "Ravager" 152277
    {spells.thunderClap }, -- "Thunderclap" 6343
    {spells.shockwave }, -- "Onde de choc" 46968
    {spells.revenge },
}},

-- Single -- including Ultimatum, Vengeance, and Heavy Repercussions
{spells.shockwave, jps.UnitExists("focus") and jps.UnitExists("target") , "target", "shockwave"  },
-- "Revenge" 6572 -- cd 9 sec -- cooldown can be reset up to once every 3 seconds from dodging or parrying attacks
{spells.revenge, inMelee },
-- "Devastate" 20243 -- you have a 30% chance to reset the remaining cooldown of Shield Slam Icon Shield Slam.
{spells.devastate },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Warrior Protection")


-- Shield Slam Icon Shield Slam generates 10 Rage.
-- Revenge Icon Revenge generates 5 Rage (and an additional 2 Rage per target hit if you have the Best Served Cold Icon Best Served Cold talent
-- Intercept Icon Intercept generates 10 Rage.
-- Demoralizing Shout Icon Demoralizing Shout generates 50 Rage if you have the Booming Voice Icon Booming Voice talent

--  you want to be able to fit in 4 global cooldowns during each Battle Cry; this requires 27-28% Haste, depending on your input lag and your latency.

-- With the Might of the Vrykul artifact trait, Shield Slam and Revenge generate 50% more Rage while Demoralizing Shout is active.

