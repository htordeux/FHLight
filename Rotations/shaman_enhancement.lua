--[[[
@module Shaman Enhancement Rotation
@author Silk_sn
@version 7.0.3
]]--
local spells = jps.spells.shaman

jps.registerRotation("SHAMAN","ENHANCEMENT",function()

local spell = nil
local target = nil

local spellTable = {

    {spells.boulderfist},
    {spells.frostbrand},
    {spells.boulderfist},
    {spells.flametongue},
    {spells.feralSpirit},
    {spells.crashLightning},
    {spells.stormstrike},
    {spells.crashLightning},
    {spells.lavaLash},
    {spells.boulderfist},
    {spells.flametongue},
    {spells.lightningBolt},


}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"shaman enhancement")

