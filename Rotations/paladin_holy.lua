
local spells = jps.spells.paladin


jps.registerRotation("PALADIN","HOLY",function()


	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Paladin Holy")
