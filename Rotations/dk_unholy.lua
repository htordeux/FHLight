local spells = jps.spells.deathknight

jps.registerRotation("DEATHKNIGHT","UNHOLY",function()

	local spell = nil
	local target = nil
	
	local spellTable =
	{

	}


	spell,target = parseSpellTable(spellTable) 
	return spell,target
end, "Unholy DK")
