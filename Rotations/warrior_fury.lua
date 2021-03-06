local spells = jps.spells.warrior
local UnitIsUnit = UnitIsUnit

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("WARRIOR","FURY",function()

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local playerIsTarget = jps.PlayerIsTarget()

local inMelee = jps.IsSpellInRange(spells.bloodthirst,"target")
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"

----------------------
-- TARGET ENEMY
----------------------

-- Config FOCUS with MOUSEOVER
if not jps.UnitExists("focus") and PlayerCanAttack("mouseover") then
	-- set focus an enemy targeting you
	if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
	-- set focus an enemy in combat
	elseif not UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
	end
end

if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not PlayerCanDPS("focus") then
	jps.Macro("/clearfocus")
end

local rangedTarget  = "target"
if PlayerCanDPS("target") then rangedTarget = "target"
elseif PlayerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif PlayerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif PlayerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if PlayerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local targetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

local PlayerBossDebuff = jps.BossDebuff("player")
if jps.hp("player") < 0.25 then CreateMessage("LOW HEALTH!")
elseif PlayerBossDebuff then CreateMessage("BOSS DEBUFF!") end

------------------------
-- SPELL TABLE ---------
------------------------

if not UnitCanAttack("player", "target") then return end

local spellTable = {

{spells.commandingShout, jps.hp("player") < 0.40 and not jps.buff(spells.commandingShout) },
{spells.enragedRegeneration, jps.hp("player") < 0.70 , "target", "Regeneration" },
-- when enragedRegeneration is active, Bloodthirst heals for an additional 20% of your total health when cast.
{spells.bloodthirst, jps.buff(spells.enragedRegeneration) and jps.hp("player") < 1 , "target", "bloodthirst_Regeneration" },

-- interrupts --
{spells.pummel, jps.Interrupts and jps.ShouldKick("target") },
-- "Charge" -- distance 8-25 m
{spells.charge , CheckInteractDistance("target",2) == false and CheckInteractDistance("target", 1) == true  },

-- Battle Cry is only 5 seconds. Wait for full rage before you pop the macro for the CDS.
-- Dragon roar is on the Global Cooldown and will cause downtime
-- Cooldown usage should always be Charge > Dragon roar > Wait for GCD to clear > Battle cry / Avatar / Trinkets. 

{spells.battleCry, jps.buff(spells.dragonRoar) }, -- should be used ideally when Enrage is inactive -- duration 5 s cd 60 s
{spells.avatar, jps.buff(spells.dragonRoar) }, -- jps.hasTalent(3,3) -- duration 20 s -- cd 90 s
{spells.dragonRoar }, -- jps.hasTalent(7,3) -- duration 6 s cd 25 s
{spells.odynsFury, jps.buff(spells.dragonRoar) and jps.buff(spells.enrage) , "target", "odynsFury"  }, -- duration 4 s cd 45 s

 -- "Saccager" 184367 -- Enrages you
{spells.rampage, not jps.buff(1719) and not jps.buff(spells.enrage) ,"target", "rampage_NotEnrage"  },
{spells.rampage, jps.rage() == 100 ,"target", "rampage_Rage100"  },
-- "Sanguinaire" 23881 
-- "Taste for Blood" 206333 "Goût du sang" -- buff Chances de coup critique de Sanguinaire augmentées de 15%
-- "Battle Cry" 1719 -- Critical strike chance increased by 100%. duration 5 sec
{spells.bloodthirst, jps.buff(1719) and not jps.buff(spells.enrage) , "target", "bloodthirst_BattleCry"  },
{spells.bloodthirst, jps.buff(206333) and not jps.buff(spells.enrage) , "target", "bloodthirst_Blood"  },
{spells.bloodthirst, not jps.buff(spells.enrage) ,"target", "bloodthirst_NotEnrage"  },
-- "Raging Blow" 85288
{spells.ragingBlow, jps.buff(spells.enrage) ,"target", "ragingBlow_Enrage"  },
-- "Execute"
{spells.execute, jps.buff(spells.enrage) },

-- "Fenzy" 202539 "Entaille furieuse" increases your Haste by 5% for 10 sec, stacking up to 3 times.
{spells.furiousSlash, jps.hasTalent(6,2) and jps.buffDuration(202539) < 3 }, -- talent "Fenzy" 202539
{spells.berserkerRage, jps.hasTalent(3,2) and not jps.buff(spells.enrage) }, -- talent "Outburst" 206320

-- "Massacre" 

--MultiTarget
-- "Meat Cleaver" 85739 your Bloodthirst or Rampage to strike up to 4 additional targets for 50% damage.
-- Dealing damage with Whirlwind increases the number of targets that your Bloodthirst or Rampage hits by 4.
{ "nested" , jps.MultiTarget, {
	{spells.bladestorm , jps.hasTalent(7,1) },
	{spells.whirlwind, inMelee and not jps.buff(spells.meatCleaver) ,"target", "whirlwind_NotMeatCleaver"  },
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
{spells.whirlwind, inMelee and jps.UnitExists("focus") and jps.UnitExists("target")  },
-- "Raging Blow" 85288
{spells.ragingBlow },
-- "Sanguinaire" 23881
{spells.bloodthirst },
 -- "Furious Slash" 100130 "Entaille furieuse" 
 -- Increases your Bloodthirst critical strike chance by 15% until it next deals a critical strike, stacking up to 6 times.
{spells.furiousSlash},

}

	local spell,target = ParseSpellTable(spellTable)
	return spell,target
end, "Warrior Fury")

-- Charge > Bloodthirst > Raging Blow > Furious Slash > Blood thirst > Dragon Roar > Avatar+Battlecry > Rampage

-- Rage Management --
-- Bloodthirst generating 10
-- Raging Blow generating 5
-- Rampage to activate Enrage
-- Execute on targets under 20% for extremely high damage.