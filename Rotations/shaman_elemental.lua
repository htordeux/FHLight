local spells = jps.spells.shaman

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("SHAMAN","ELEMENTAL",function()

----------------------
-- TARGET ENEMY
----------------------

local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local rangedTarget  = "target"
if PlayerCanDPS("target") then rangedTarget = "target"
elseif PlayerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif PlayerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif PlayerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if PlayerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local targetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

	-- heals
	{spells.giftNaaru, jps.hp("player") < 0.80 , "player" , "giftNaaru"},
	{spells.healingSurge, jps.hp("player") < 0.50 , "player" , "healingSurge"},
	{spells.astralShift, jps.hp("player") < 0.50 , "player" },

	-- Apply Flame Shock
	{spells.flameShock , not jps.myDebuff(spells.flameShock) },
	-- Cast Fire Elemental if it is off cooldown.
	{spells.fireElemental},
	-- Cast Earth Shock Icon Earth Shock if Maelstrom is 90 or greater.
	{spells.earthShock , jps.isUsableSpell(spells.earthShock) and jps.maelstom() > 90 },
	-- Cast Ascendance (if talented) if it is off cooldown.
	{spells.ascendance  },
	-- Cast Elemental Mastery on cooldown where appropriate.
	{spells.elementalMastery },
	-- Cast Icefury (if talented) and priority damage is necessary, or predictable movement is incoming.
	{spells.icefury , jps.hasTalent(5,3) and jps.Moving },
	-- Cast Lava Burst whenever available and Flame Shock is applied to the target.
	{spells.lavaBurst , jps.myDebuff(spells.flameShock) },
	-- Frost Shock if Icefury buff is active.
	{spells.frostShock, jps.buff(spells.icefury) },
	-- Stormkeeper whenever available if you are not about to use Ascendance
	{spells.stormkeeper },
	-- Maintain Totem Mastery buff.
	{spells.totemMastery, jps.hasTalent(1,3) },
	
	{"nested", jps.MultiTarget , {
		-- Cast Earthquake if there are at least 4 targets present. -- 77478
		{spells.earthquakeTotem }, 
		-- Cast Chain Lightning as a filler on 2 or more targets.
		{spells.chainLightning },
	}},

	-- Cast Lightning Bolt as a filler on a single target.
	{spells.lightningBolt},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"shaman_elemental")
