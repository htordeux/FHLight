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

jps.registerRotation("WARRIOR","ARMS",function()

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local playerIsTarget = jps.PlayerIsTarget()

local inMelee = jps.IsSpellInRange(163201,"target") -- "Execute" 163201
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
local targetNotSlow = select(1,GetUnitSpeed(rangedTarget)) > 6
local targetClass = UnitClass(rangedTarget)

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "Charge" -- distance 8-25 m
	{ spells.charge, CheckInteractDistance("target",2) == false and CheckInteractDistance("target", 1) == true  },
	{ spells.charge, jps.IsFallingFor(1) , "target" },
	
	-- Shouts/Buffs --
	{ spells.battleCry, not jps.buff(spells.battleCry) and jps.debuff(spells.colossusSmash) }, -- if the Colossus Smash  Colossus Smash debuff is active on your target
	{ spells.commandingShout, jps.hp("player") < 0.30 and not jps.buff(spells.commandingShout) and jps.IncomingDamage("player") > jps.IncomingHeal("player") },
	{ spells.focusedRage, true , "player" },
	{ spells.focusedRage, jps.debuff(209574) and jps.myDebuffDuration(209574,rangedTarget) > 9 , rangedTarget }, -- once with each fresh application of Shattered Defenses
	{ spells.focusedRage, jps.rage() >= 0.75 , rangedTarget }, -- if above 75 rage to avoid rage capping
	{ spells.avatar, true , "player" }, -- use on cooldown for burst damage
	
	-- "Hamstring" 
	{ spells.hamstring, not jps.debuff(1715) and targetNotSlow and targetClass ~= "Druid" , "target" },
	
	-- Defensives/Self Heals --
	-- "Healthstone"
	{ 195710, playerIsStun , "player" , "playerCC" },
    { "macro", jps.hp("player") < 0.60 and jps.useItem(5512) ,"/use item:5512" },
	{ spells.defensiveStance, jps.hp("player") < 0.30 and jps.IncomingDamage("player") > jps.IncomingHeal("player") },
	--{ "macro", jps.hp("player") > 0.30 , "/cast Defensive Stance" , "player" },
	{ spells.defensiveStance, jps.buff(spells.defensiveStance) and jps.hp("player") > 0.30 , "player" },
	{ spells.victoryRush, true , "target", "Victory_Rush" },

	-- Interrupts --
	{ spells.pummel, jps.Interrupts and jps.ShouldKick("target") },
	{ spells.stormBolt, jps.Interrupts and jps.ShouldKick("target") },
	{ spells.shockwave, jps.Interrupts and jps.ShouldKick("target") },
	
	-- AoE --
    -- 2-3 targets with Sweeping Strikes talent
    { "nested" , jps.MultiTarget and ShiftKeyIsDown and jps.hasTalent(1,3), {
    	{ spells.sweepingStrikes, true , rangedTarget },
    	{ spells.whirlwind, true , rangedTarget },
    }},
    
    -- > 2 targets without Sweeping Strikes talent
    { "nested" , jps.MultiTarget and not jps.hasTalent(1,3), {
    	{ spells.warbreaker, true , rangedTarget }, 
    	{ spells.bladestorm, true , rangedTarget },
    	{ spells.cleave, not jps.buff(845) , rangedTarget }, -- to buff Whirlwind
    	{ spells.whirlwind, jps.buff(845) , rangedTarget }, -- when fully buffed by Cleave
	}},

    -- Single Target --
    { spells.colossusSmash, not jps.debuff(209574) , rangedTarget }, --if available and  Shattered Defenses, 209574, is not active.
    { spells.warbreaker, not jps.debuff(171056) and not jps.debuff(209574) , rangedTarget }, -- if Colossus Smash  Colossus Smash is absent from the target and  Shattered Defenses is not active.
    { spells.execute, jps.hp(rangedTarget) <= 0.20 , rangedTarget }, -- if your target is below 20%.
    { spells.mortalStrike, jps.hp(rangedTarget) >= 0.20 , rangedTarget },
    { spells.overpower, true , rangedTarget },
    { spells.whirlwind, jps.rage() >= 35 and jps.hasTalent(3,1) , rangedTarget }, -- at or above 35 Rage
    { spells.slam, jps.hp(rangedTarget) >= 0.20 and jps.rage() >= 32 and jps.cooldown(spells.colossusSmash) > 0 and jps.cooldown(spells.mortalStrike) > 0 and not jps.hasTalent(3,1) , rangedTarget }, -- if above 32 rage and Colossus Smash and Mortal Strike are on cooldown
}

	local spell,target = ParseSpellTable(spellTable)
	return spell,target
end, "Warrior Arms")

-- TO DO --
-- Colossus Smash as often as possible.
-- Execute when available and with >= 40 Rage.