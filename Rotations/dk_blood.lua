-- Talents:
-- Tier 1: Roiling Blood (for trash / add fights) or Plague Leech for Single Target
-- Tier 2: Anti-Magic Zone
-- Tier 3: Death's Advance
-- Tier 4: Death Pact
-- Tier 5: Runic Corruption
-- Tier 6: Remorseless Winter
-- Major Glyphs: Icebound Fortitude, Anti-Magic Shell

-- Usage info:
-- Shift to DnD at mouse
-- left alt for anti magic zone
-- left ctrl for army of death
-- shift + left alt for battle rezz at your focus or (if focus is not death , or no focus or focus target out of range) mouseover
-- Cooldowns: trinkets, raise dead, dancing rune weapon, synapse springs
-- focus on other tank in raids

dkBloodSpellTable = {}
dkBloodSpellTable[1] = {
	-- Blood presence
	{dk.spells["BloodPresence"],'not jps.buff("Blood Presence")'},

	-- Battle Rezz
	--{"Raise Ally",'UnitIsDeadOrGhost("focus") == 1 and jps.UseCds', "focus" },
	--{"Raise Ally",'UnitIsDeadOrGhost("target") == 1 and jps.UseCds', "target"},

	-- Shift is pressed
	{dk.spells["DeathAndDecay"],'IsShiftKeyDown() == true and GetCurrentKeyBoardFocus() == nil'},
	{dk.spells["AntiMagicZone"],'IsLeftAltKeyDown() == true and GetCurrentKeyBoardFocus() == nil '},

	-- Cntrol is pressed
	{dk.spells["ArmyoftheDead"],'IsLeftControlKeyDown() == true and GetCurrentKeyBoardFocus() == nil'},

	-- Defensive cooldowns -- "Lichborne"
	{dk.spells["DeathPact"],'jps.hp() < 0.5 and dk.hasGhoul()'},
	{"Lichborne",'jps.UseCDs and jps.hp() < 0.5 and jps.runicPower() >= 40 and jps.IsSpellKnown("Lichborne")'},
	{"Death Coil",'jps.hp() < 0.9 and jps.runicPower() >= 40 and jps.buff("lichborne")', "player"},
	{"Rune Tap",'jps.hp() < 0.8 and not jps.buff("Rune Tap")'},
	{jps.useBagItem(5512), 'jps.hp("player") < 0.70'},
	{dk.spells["Icebound"],'jps.UseCDs and jps.hp() <= 0.3'},
	{"Vampiric Blood",'jps.UseCDs and jps.hp() < 0.4'},

	-- Interrupts
	{dk.spells["MindFreeze"],'jps.ShouldKick()'},
	{dk.spells["MindFreeze"],'jps.ShouldKick("focus")', "focus"},
	{dk.spells["Strangulate"],'jps.ShouldKick() and jps.UseCDs and IsSpellInRange("mind freeze","target")==0 and jps.LastCast ~= "mind freeze"'},
	{dk.spells["Strangulate"],'jps.ShouldKick("mouseover") and jps.UseCDs and IsSpellInRange("mind freeze","focus")==0 and jps.LastCast ~= "mind freeze"', "mouseover" },
	{dk.spells["Strangulate"],'jps.ShouldKick("focus") and jps.UseCDs and IsSpellInRange("mind freeze","focus")==0 and jps.LastCast ~= "mind freeze"', "focus" },
	{"Asphyxiate",'jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate"'},
	{"Asphyxiate",'jps.ShouldKick("mouseover") and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate"', "mouseover"},
	{"Asphyxiate",'jps.ShouldKick("focus") and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate"', "focus"},
	
	-- Spell Steal
	{dk.spells["DarkSimulacrum"], 'dk.shouldDarkSimTarget() ~= ""' , "target"},
	{dk.spells["DarkSimulacrum"], 'dk.shouldDarkSimFocus() ~= ""' , "focus"},
	
	{"nested", 'IsSpellInRange("Rune Strike","target") == 1',{
		{"Dancing Rune Weapon",'jps.UseCDs'},
		-- Racials
		{ jps.getDPSRacial(),'jps.UseCDs'},
	}},


	-- Buff
	{"Bone Shield",'not jps.buff("Bone Shield")'},

	-- Diseases
	{"Unholy Blight",'jps.myDebuffDuration("Frost Fever") < 2'},
	{"Unholy Blight",'jps.myDebuffDuration("Blood Plague") < 2'},
	{dk.spells["OutBreak"],'jps.myDebuffDuration("Frost Fever") < 2'},
	{dk.spells["OutBreak"],'jps.myDebuffDuration("Blood Plague") < 2'},

	-- Multi target
	{"Blood Boil",'jps.MultiTarget and jps.IsSpellInRange("Blood Boil","target")'},
	{"Death and Decay",'IsShiftKeyDown() == true and GetCurrentKeyBoardFocus() == nil and jps.buff("Crimson Scourge")'},
	{"Blood Boil",'jps.buff("Crimson Scourge") and jps.IsSpellInRange("Blood Boil","target")'},

	-- Rotation
	{dk.spells["DeathStrike"],'jps.hp() < 0.7'},
	{dk.spells["DeathStrike"],'jps.buffDuration("Blood Shield") < 4'},
	{dk.spells["SoulReaper"],'jps.hp("target") <= 0.35'},
	{dk.spells["PlagueStrike"],'not jps.myDebuff("Blood Plague")'},
	{"Icy Touch",'not jps.myDebuff("Frost Fever")'},
	{"Rune Strike",'jps.runicPower() >= 80 and not dk.rune("twoFr") and not dk.rune("twoUr")'},
	{dk.spells["DeathStrike"], "onCD"},

	-- Death Siphon when we need a bit of healing. (talent based)
	{"Death Siphon",'jps.hp() < 0.6'}, -- moved here, because we heal often more with Death Strike than Death Siphon

	{"Heart Strike",'jps.myDebuff("Blood Plague") and jps.myDebuff("Frost Fever") and GetRuneType(1) ~= 4 and GetRuneType(2) ~= 4'},

	{"Death Coil",'jps.runicPower() >= 30 and not jps.buff("lichborne")'}, -- stop casting Rune Strike if Lichborne is up

	{dk.spells["HornOfWinter"], 'not jps.buff("Horn of Winter")'},
	{dk.spells["PlagueLeech"],'dk.canCastPlagueLeech(3)'},
	{"Blood Tap", 'jps.buffStacks("Blood Charge") >= 5'},
	{dk.spells["EmpowerRuneWeapon"],'jps.UseCDs and IsSpellInRange("Rune Strike","target") == 1 and not dk.rune("oneDr") and not dk.rune("oneFr") and not dk.rune("oneUr") and jps.runicPower() < 30'},
}

dkBloodSpellTable[4] = {
	-- Blood presence
	{"Blood Presence",'not jps.buff("Blood Presence")'},

	-- Battle Rezz
	{"Raise Ally",'UnitIsDeadOrGhost("focus") == 1 and jps.UseCds', "focus" },
	{"Raise Ally",'UnitIsDeadOrGhost("target") == 1 and jps.UseCds', "target"},

	{"Anti-Magic Zone",'IsLeftAltKeyDown() == true and GetCurrentKeyBoardFocus() == nil '},

	-- Cntrol is pressed
	{"Army of the Dead",'IsLeftControlKeyDown() == true and GetCurrentKeyBoardFocus() == nil'},

	-- Defensive cooldowns

	{"Death Pact",'jps.hp() < 0.5 and dk.hasGhoul()'},
	{"Lichborne",'jps.UseCDs and jps.hp() < 0.5 and jps.runicPower() >= 40 and jps.IsSpellKnown("Lichborne")'},
	{"Death Coil",'jps.hp() < 0.9 and jps.runicPower() >= 40 and jps.buff("lichborne")', "player"},
	{"Rune Tap",'jps.hp() < 0.8 and not jps.buff("Rune Tap")'},
	{jps.useBagItem(5512), 'jps.hp("player") < 0.70'},
	{"Icebound Fortitude",'jps.UseCDs and jps.hp() <= 0.3'},
	{"Vampiric Blood",'jps.UseCDs and jps.hp() < 0.4'},

	-- Interrupts
	{"mind freeze",'jps.ShouldKick()'},
	{"mind freeze",'jps.ShouldKick("focus")', "focus"},
	{"Strangulate",'jps.ShouldKick() and jps.UseCDs and IsSpellInRange("mind freeze","target")==0 and jps.LastCast ~= "mind freeze"'},
	{"Strangulate",'jps.ShouldKick("focus") and jps.UseCDs and IsSpellInRange("mind freeze","focus")==0 and jps.LastCast ~= "mind freeze"', "mouseover" },
	{"Strangulate",'jps.ShouldKick("focus") and jps.UseCDs and IsSpellInRange("mind freeze","focus")==0 and jps.LastCast ~= "mind freeze"', "focus" },
	{"Asphyxiate",'jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate"'},
	{"Asphyxiate",'jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate"', "mouseover"},
	{"Asphyxiate",'jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate"', "focus"},
	
	{"nested", 'IsSpellInRange("Rune Strike","target") == 1',{
	
		-- Racials
		{ jps.getDPSRacial(),'jps.UseCDs'},
	}},

	-- Buff
	{"Bone Shield",'not jps.buff("Bone Shield")'},

	-- Diseases
	{"Outbreak",'jps.myDebuffDuration("Frost Fever") < 2'},
	{"Outbreak",'jps.myDebuffDuration("Blood Plague") < 2'},

	-- Rotation
	{"Death Strike",'jps.hp() < 0.7'},
	{"Death Strike",'jps.buffDuration("Blood Shield") <= 4'},
	{"Soul Reaper",'jps.hp("target") <= 0.35'},
	{"Plague Strike",'not jps.myDebuff("Blood Plague")'},
	{"Icy Touch",'not jps.myDebuff("Frost Fever")'},
	{"Rune Strike",'jps.runicPower() >= 80 and not dk.rune("twoFr") and not dk.rune("twoUr")'},
	{"Death Strike", "onCD"},

	-- Death Siphon when we need a bit of healing. (talent based)
	{"Death Siphon",'jps.hp() < 0.6'}, -- moved here, because we heal often more with Death Strike than Death Siphon

	{"Death Coil",'jps.runicPower() >= 30 and not jps.buff("lichborne")'}, -- stop casting Rune Strike if Lichborne is up

	{"Horn of Winter", 'not jps.buff("Horn of Winter")'},
	{"Plague Leech",'dk.canCastPlagueLeech(3)'},
	{"Blood Tap", 'jps.buffStacks("Blood Charge") >= 5'},
	{"Empower Rune Weapon",'jps.UseCDs and IsSpellInRange("Rune Strike","target") == 1 and not dk.rune("oneDr") and not dk.rune("oneFr") and not dk.rune("oneUr") and jps.runicPower() < 30'},
}

jps.registerRotation("DEATHKNIGHT","BLOOD",function()
	local spell = nil
	local target = nil
	spell,target = parseStaticSpellTable(dkBloodSpellTable[1])
	return spell,target
end, "DK Blood Main")

jps.registerRotation("DEATHKNIGHT","BLOOD",function()
	local spell = nil
	local target = nil
	spell,target = parseStaticSpellTable(dkBloodSpellTable[4])
	return spell,target
end, "DK Blood No Cleave / AoE")