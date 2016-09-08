--[[[
@module Shaman Restoration Rotation
@author kirk24788
@version 7.0.3
@untested
]]--
local spells = jps.spells.shaman




jps.registerRotation("SHAMAN","RESTORATION",function()

local spell = nil
local target = nil

local spellTable = {


}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Empty")
