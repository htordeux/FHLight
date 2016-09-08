--[[[
@module Demonhunter Vengeance Rotation
@author kirk24788
@untested
@version 7.0.3
]]--

local spells = jps.spells.demonhunter


jps.registerRotation("DEMONHUNTER","VENGEANCE",function()

local spell = nil
local target = nil

local spellTable = {

    {spells.felRush},
    {spells.demonsBite},
    {spells.chaosStrike},
    {spells.throwGlaive},
}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Vengeance")