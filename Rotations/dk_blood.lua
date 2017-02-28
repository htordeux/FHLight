local spells = jps.spells.deathknight

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("DEATHKNIGHT","BLOOD",function()

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

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "Blood DK")

