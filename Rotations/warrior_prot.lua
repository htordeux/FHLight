
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
if not jps.UnitExists("focus") and canDPS("mouseover") and UnitAffectingCombat("mouseover") then
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

local DamageIncoming = jps.IncomingDamage() - jps.IncomingHeal()

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

-- interrupts --
{spells.pummel, jps.Interrupts and jps.ShouldKick("target") },
-- Heroic Leap resets the cooldown of Taunt.
{spells.taunt, jps.Defensive and not jps.playerIsTargeted() },
-- "Berserker Rage" cd 60 sec
{spells.berserkerRage, playerIsStun },
-- "Ivresse de la victoire" 34428
{spells.victoryRush, jps.hp() < 1 },
-- "Mur protecteur" 871 buff same id
{spells.shieldWall, jps.hp() < 0.40 and not jps.buff(12975) , "target" , "shieldWall" }, -- cd 4 min
-- "Dernier rempart" 12975 buff same id
{spells.lastStand , jps.hp() < 0.40 and not jps.buff(871) , "target" , "lastStand" }, -- cd 3 min

-- "Demoralizing Shout" 1160
{spells.demoralizingShout,  },
-- "Neltharion's Fury" cd 45 sec
{spells.neltharionsFury, jps.cooldown(spells.shieldBlock) > 0 and not jps.buff(132404) , "target" , "neltharionsFury" },

-- "Focused Rage"  204488 "Rage concentrée"
-- Increasing Shield Slam damage by 50%, stacking up to 3 times.
-- Vengeance talent buff  202573 reduces the Rage cost of your next Focused Rage by 35%
{spells.focusedRage, jps.buff(202573), "target" , "focusedRage_Vengeance" },
-- "Ultimatum" buff 122510 Your next Focused Rage costs no Rage
{spells.focusedRage, jps.buff(122510) , "target" , "focusedRage_Ultimatum" },
-- "Shield Block" 2565 -- cd 13 sec, duration 6 sec, Increases Shield Slam damage by 30% while active 
{spells.shieldBlock },
-- "Battle Cry" 1719 -- cd 60 sec, duration 5 sec, 100% increased critical strike chance for 5 sec.
-- "Shield Block" buff 132404
{spells.battleCry, jps.buff(132404) , "target" , "battleCry" },
-- "Shield Slam" 23922
{spells.shieldSlam },

-- "Dur au mal" 190456 -- "Vengeance: Ignore Pain" 202574 "Vengeance : Dur au mal"
-- Vengeance talent buff 202574 reduces the Rage cost of your next Ignore Pain by 35%
{spells.ignorePain, jps.buff(202574) and jps.buffDuration(190456) < 3 , "target" , "ignorePain_Vengeance" },
{spells.ignorePain, jps.Defensive and jps.buffDuration(190456) < 3 , "target" , "ignorePain_Duration" },

--MultiTarget -- including Renewed, Into the Fray, and Ravager, 
{ "nested" , jps.MultiTarget, {
	{spells.neltharionsFury }, -- cd 45 sec
	{spells.ravager }, -- "Ravager" 152277
	{spells.thunderClap }, -- "Thunderclap" 6343
	{spells.shockwave }, -- "Onde de choc" 46968
}},

-- Single -- including Ultimatum, Vengeance, and Heavy Repercussions
-- "Revenge" 6572 -- cd 9 sec -- cooldown can be reset up to once every 3 seconds from dodging or parrying attacks
{spells.revenge },
-- "Devastate" 20243 -- you have a 30% chance to reset the remaining cooldown of Shield Slam Icon Shield Slam.
{spells.devastate },


}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Warrior Protection")


--    Shield Slam Icon Shield Slam generates 10 Rage.
--    Revenge Icon Revenge generates 5 Rage (and an additional 2 Rage per target hit if you have the Best Served Cold Icon Best Served Cold talent
--    Intercept Icon Intercept generates 10 Rage.
--    Demoralizing Shout Icon Demoralizing Shout generates 50 Rage if you have the Booming Voice Icon Booming Voice talent



