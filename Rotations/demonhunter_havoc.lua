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


    {spells.felRush , CheckInteractDistance(rangedTarget,3) == false },
	-- "Planer"
	{ 131347, jps.fallingFor() > 1.5 , "player" },
	-- "Torrent arcanique" 202719
	{ 202719, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Manavore" 183752
	{ 183752, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Lancer de glaive" 185123
	{ 185123 },
	-- Rayon accablant "198013"
	{spells.eyeBeam , jps.powerFury() > 50 },
	-- "Frappe du chaos" 162794 
    {spells.chaosStrike , jps.powerFury() > 40 },
    -- "Morsure du demon" 162243 
    {spells.demonsBite},

    {spells.throwGlaive},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Havoc")