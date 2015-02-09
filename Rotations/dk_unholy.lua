
jps.registerRotation("DEATHKNIGHT","UNHOLY",function()

	-- Shift-key to cast Death and Decay
	-- Set "focus" for dark simulacrum (duplicate spell) (this is optional, default is current target)
	-- Automatically raise ghoul if dead

	local rp = UnitPower("player") 

	local ffDuration = jps.myDebuffDuration("Frost Fever")
	local bpDuration = jps.myDebuffDuration("Blood Plague")
	local siStacks = jps.buffStacks("shadow infusion","pet")
	local superPet = jps.buff("dark transformation","pet")

	local Dr,Fr,Ur = dk.updateRune()
	local DepletedRunes = (Dr == 0) or (Ur == 0) or (Fr == 0)
	local AllDepletedRunes = (Dr == 0) and (Ur == 0) and (Fr == 0)
	local timeToDie = jps.TimeToDie("target")
	
	local spellTable =
	{
	   -- Kick
		{ "mind freeze",		jps.ShouldKick() },
		{ "mind freeze",		jps.ShouldKick("focus"), "focus" },
		{ "Strangulate",		jps.ShouldKick() and jps.UseCDs and IsSpellInRange("mind freeze","target")==0 and jps.LastCast ~= "mind freeze" },
		{ "Strangulate",		jps.ShouldKick("focus") and jps.UseCDs and IsSpellInRange("mind freeze","focus")==0 and jps.LastCast ~= "mind freeze" , "focus" },
		{ "Asphyxiate",			jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate" },
		{ "Asphyxiate",			jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate", "focus" },
		{ "Horn of Winter", 	not jps.buff("Horn of Winter")},
		
		-- Self heals
		{ "Death Siphon",	jps.hp() < .8 and jps.Defensive },
		{ "Death Strike",	jps.hp() < .7 and jps.Defensive },
		{ "Death Pact",		jps.UseCDs and jps.hp() < .6 and UnitExists("pet") == true },
		
		-- Battle Rezz
    	{ "Raise Ally", UnitIsDeadOrGhost("focus") == 1 and jps.UseCds, "focus" },
    	{ "Raise Ally", UnitIsDeadOrGhost("target") == 1 and jps.UseCds, "target"},

		-- AOE
		{ "Death and Decay", IsShiftKeyDown() == true and GetCurrentKeyBoardFocus() == nil},
		
		-- spell steal
		
		{"Dark Simulacrum ", dk.shouldDarkSimTarget() , "target"},
		{"Dark Simulacrum ", dk.shouldDarkSimFocus() , "focus"},
		
		-- CDs
		{ jps.getDPSRacial(),	jps.UseCDs },
		{ jps.useTrinket(0),	jps.UseCDs },
		{ jps.useTrinket(1),	jps.UseCDs },

		-- rezz pet
		{ "Raise Dead", jps.UseCDs and UnitExists("pet") == nil },
		
		
		-- Execute
		{ "soul reaper", jps.hp("target") <= 0.35 },
		
		
		-- DOT CDs

		{ "outbreak",				not jps.myDebuff("Frost Fever") or not jps.myDebuff("Blood Plague") },
		{ "unholy blight",			not jps.myDebuff("Frost Fever") or not jps.myDebuff("Blood Plague") },
		
		
		-- renew Dots
		{ "plague strike",			bpDuration <= 0 or ffDuration <= 0 },
		
		-- get Runes
		{ "summon gargoyle" ,		jps.UseCDs},
		
		{ "dark transformation",	siStacks >= 5 and superPet == false },
		{ "death coil",				siStacks < 5 },
		-- 
		{ "scourge strike",			Ur == 2 and rp < 90 },
		{ "festering strike",		Dr == 2 and Fr == 2 and rp < 90 },
		{ "Blood Tap", 				jps.buffStacks("Blood Charge") >= 5 },
		{ "death coil",				rp > 90 },
		{ "death coil",				jps.buff("sudden doom") },
		{ "blood tap",            	jps.buffStacks("blood charge") >= 5 and AllDepletedRunes },
		{ "scourge strike" },
		{ "festering strike" },
		{ "death coil"},
		{ "empower rune weapon" , 	jps.UseCDs},
	}

	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable) 
	return spell,target
end, "Default")
