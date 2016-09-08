--[[[
@module Demonhunter Havoc Rotation
@author kirk24788
@version 7.0.3
]]--

local spells = jps.spells.demonhunter


--[[
Suggested Talents:
Level 99: Fel Mastery
Level 100: Demon Blades
]]--


jps.registerRotation("DEMONHUNTER","HAVOC",function()

local spell = nil
local target = nil
local rangedTarget = "target"

local spellTable = {

	{ 131347, jps.fallingFor() > 1.5 , "player" },
	{ 202719, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },


    {spells.felRush , CheckInteractDistance(rangedTarget,3) == false },
    {spells.demonsBite},

    {spells.chaosStrike},
    {spells.throwGlaive},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Havoc")