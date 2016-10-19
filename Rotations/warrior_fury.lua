
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

jps.registerRotation("WARRIOR","FURY",function()

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

local inMelee = jps.IsSpellInRange(spells.bloodthirst,"target")
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

{spells.commandingShout, jps.hp() < 0.40 and not jps.buff(spells.commandingShout) },
{spells.enragedRegeneration, jps.hp() < 0.70 , "target", "Regeneration" },
-- when enragedRegeneration is active, Bloodthirst heals for an additional 20% of your total health when cast.
{spells.bloodthirst, jps.buff(spells.enragedRegeneration) and jps.hp() < 1 , "target", "bloodthirst_Regeneration" },

-- interrupts --
{spells.pummel, jps.Interrupts and jps.ShouldKick("target") },
-- "Charge" -- distance 8-25 m
{spells.charge , CheckInteractDistance("target",2) == false and CheckInteractDistance("target", 1) == true  },
 -- "Saccager" 184367 -- Enrages you
{spells.rampage, jps.rage() == 100 ,"target", "rampage_Enrage100"  },
{spells.rampage, not jps.buff(spells.enrage) ,"target", "rampage_NotEnrage"  },
-- "Sanguinaire" 23881 
-- "Taste for Blood" 206333 "Goût du sang" -- buff Chances de coup critique de Sanguinaire augmentées de 15%
-- "Battle Cry" 1719 -- Critical strike chance increased by 100%. last 5 sec
{spells.bloodthirst, jps.buff(206333) and not jps.buff(spells.enrage) , "target", "bloodthirst_Blood"  },
{spells.bloodthirst, jps.buff(1719) and not jps.buff(spells.enrage) , "target", "bloodthirst_BattleCry"  },
{spells.bloodthirst, not jps.buff(spells.enrage) ,"target", "bloodthirst_NotEnrage"  },
-- "Fureur d’Odyn" 205545 
{spells.odynsFury , jps.buff(spells.dragonRoar) , "target", "odynsFury"  },
{spells.odynsFury , jps.buff(spells.battleCry) , "target", "odynsFury"  },
-- "Execute"
{spells.execute, jps.buff(spells.enrage) },

{spells.dragonRoar }, -- jps.hasTalent(7,3)
{spells.battleCry, jps.buff(spells.dragonRoar) },
{spells.avatar }, -- jps.hasTalent(3,3)
{spells.bloodbath }, -- jps.hasTalent(6,1)
-- "Fenzy" 202539 "Entaille furieuse" increases your Haste by 5% for 10 sec, stacking up to 3 times.
{spells.furiousSlash, jps.hasTalent(6,2) and jps.buffDuration(202539) < 3 }, -- talent "Fenzy" 202539
{spells.berserkerRage, jps.hasTalent(3,2) and not jps.buff(spells.enrage) }, -- talent "Outburst" 206320

--MultiTarget
-- "Meat Cleaver" 85739 your Bloodthirst or Rampage to strike up to 4 additional targets for 50% damage.
-- Dealing damage with Whirlwind increases the number of targets that your Bloodthirst or Rampage hits by 4.
{ "nested" , jps.MultiTarget, {
	{spells.whirlwind, inMelee and not jps.buff(spells.meatCleaver) ,"target", "whirlwind_NotMeatCleaver"  },
	{spells.bladestorm , jps.hasTalent(7,1) },
	{spells.rampage, not jps.buff(spells.enrage) ,"target", "rampage_NotEnrage"  },
	{spells.rampage, jps.rage() == 100 and jps.buff(spells.meatCleaver) ,"target", "rampage_MeatCleaver"  },
	{spells.bloodthirst, not jps.buff(spells.enrage) and jps.buff(spells.meatCleaver) ,"target", "bloodthirst_MeatCleaver"  },
	{spells.whirlwind, jps.buff(spells.wreckingBall) }, 
	{spells.ragingBlow },
  	{spells.whirlwind, inMelee },
}},

-- "Tourbillon" 190411 "Whirlwind"
-- "Boulet de démolition" 215569 "Wrecking Ball" -- Your attacks have a chance to make your next Whirlwind deal 200% increased damage
{spells.whirlwind, inMelee and jps.buff(spells.wreckingBall) }, -- talent "Boulet de démolition" jps.hasTalent(3,1)
-- "Raging Blow" 85288
{spells.ragingBlow },
-- Single
{spells.bloodthirst },
 -- "Furious Slash" 100130 "Entaille furieuse" 
 -- Increases your Bloodthirst critical strike chance by 15% until it next deals a critical strike, stacking up to 6 times.
{spells.furiousSlash},

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Warrior Fury")

-- Charge > Bloodthirst > Raging Blow > Furious Slash > Blood thirst > Dragon Roar > Avatar+Battlecry > Rampage

-- Rage Management --
-- Bloodthirst generating 10
-- Raging Blow generating 5
-- Rampage to activate Enrage
-- Execute on targets under 20% for extremely high damage.