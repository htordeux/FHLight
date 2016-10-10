
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

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

   {spells.enragedRegeneration, jps.hp() < 0.70 , "target", "Regeneration" },
   -- when enragedRegeneration is active, Bloodthirst heals for an additional 20% of your total health when cast.
   {spells.bloodthirst, jps.buff(spells.enragedRegeneration) and jps.hp() < 1 , "target", "bloodthirst_Regeneration" },
   {spells.commandingShout, jps.hp() < 0.40 and not jps.buff(spells.commandingShout) },
      
   	-- interrupts --
	{spells.pummel, jps.Interrupts and jps.ShouldKick("target") },

--Dragon Roar just before Battle Cry due to its guaranteed Critical chance
--Dragon Roar before casting Rampage
{spells.charge , jps.IsSpellInRange(spells.charge,"target") },
{spells.bloodthirst, jps.buff(spells.battleCry) and not jps.buff(spells.enrage) , "target", "bloodthirst_NotEnragebattleCry"  },
{spells.bloodthirst, jps.rage() == 0 and not jps.buff(spells.enrage) , "target", "bloodthirst_NotEnrageZeroRage"  },
{spells.bloodthirst, jps.buff(206333) and not jps.buff(spells.enrage) , "target", "bloodthirst_Blood"  },
{spells.dragonRoar }, -- jps.hasTalent(7,3)
{spells.avatar }, -- jps.hasTalent(3,3)
{spells.bloodbath  }, -- jps.hasTalent(6,1)
{spells.battleCry, jps.buff(spells.dragonRoar) },
{spells.odynsFury , jps.buff(spells.battleCry) or jps.buff(spells.dragonRoar) , "target", "odynsFury"  },
{spells.rampage, jps.rage() == 100 and jps.buff(spells.enrage) ,"target", "rampage_Enrage100"  },
-- "Fenzy" 202539 "Entaille furieuse" increases your Haste by 5% for 10 sec, stacking up to 3 times.
-- "Taste for Blood" "Goût du sang" 206333 buff augmente de 15% les chances de coup critique de Sanguinaire.
{spells.furiousSlash, jps.hasTalent(6,2) and jps.buffDuration(202539) < 3 },  
{spells.berserkerRage, jps.hasTalent(3,2) and not jps.buff(spells.enrage) }, -- talent Outburst 206320

--MultiTarget
-- "Meat Cleaver" 85739 your Bloodthirst or Rampage to strike up to 4 additional targets for 50% damage.
-- Dealing damage with Whirlwind increases the number of targets that your Bloodthirst or Rampage hits by 4.
{ "nested" , jps.MultiTarget, {
	{spells.whirlwind, jps.canFear(rangedTarget) and not jps.buff(spells.meatCleaver) ,"target", "whirlwind_NotMeatCleaver"  },
	{spells.bladestorm , jps.hasTalent(7,1) },
	{spells.rampage, not jps.buff(spells.enrage) ,"target", "rampage_NotEnrage"  },
	{spells.rampage, jps.rage() > 90 and jps.buff(spells.meatCleaver) ,"target", "rampage_MeatCleaver"  },
	{spells.bloodthirst, not jps.buff(spells.enrage) and jps.buff(spells.meatCleaver) ,"target", "bloodthirst_MeatCleaver"  },
	{spells.whirlwind, jps.buff(spells.wreckingBall) }, -- jps.hasTalent(3,1)
	{spells.ragingBlow }, -- jps.hasTalent(6,3)
  	{spells.whirlwind, jps.canFear(rangedTarget) },
}},

-- Single

{spells.execute, jps.buff(spells.enrage) },
{spells.rampage, not jps.buff(spells.enrage) ,"target", "rampage_NotEnrage"  },
{spells.bloodthirst, not jps.buff(spells.enrage) ,"target", "bloodthirst_NotEnrage"  },
{spells.ragingBlow },
{spells.whirlwind, jps.buff(spells.wreckingBall) }, -- jps.hasTalent(3,1)
{spells.bloodthirst },
 -- "Furious Slash" Increases your Bloodthirst critical strike chance by 15% until it next deals a critical strike, stacking up to 6 times.
{spells.furiousSlash},
{spells.whirlwind, jps.UnitExists("focus") and jps.UnitExists("target") and not jps.buff(spells.meatCleaver) , "target", "whirlwind_NotMeatCleaver"  },


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