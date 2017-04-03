local spells = jps.spells.demonhunter

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("DEMONHUNTER","HAVOC",function()

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

	-- 195072
    {spells.felRush , CheckInteractDistance(rangedTarget,2) == false },
	-- "Planer"
	{ 131347, jps.IsFallingFor(1) , "player" },
	-- "Torrent arcanique" 202719
	{ 202719, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Manavore" 183752
	{ 183752, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Lancer de glaive" 185123
	{ spells.throwGlaive },
	-- Rayon accablant "198013"
	{spells.eyeBeam , jps.powerFury() > 50 },
	-- "Frappe du chaos" 162794 
    {spells.chaosStrike , jps.powerFury() > 40 },
    -- "Morsure du demon" 162243 
    {spells.demonsBite},
    {spells.throwGlaive},

}

	local spell,target = ParseSpellTable(spellTable)
	return spell,target

end,"Havoc")