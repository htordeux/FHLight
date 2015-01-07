
local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass

jps.registerRotation("DEATHKNIGHT","FROST", function()

----------------------
-- TARGET ENEMY
----------------------

-- Debuff EnemyTarget NOT DPS
local DebuffUnitCyclone = function (unit)
	local Cyclone = false
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i)) -- UnitAura(unit,i,"HARMFUL")
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			Cyclone = true
		elseif strfind(auraName,L["Cyclone"]) then
			Cyclone = true
		elseif strfind(auraName,L["Hex"]) then
			Cyclone = true
		end
		if Cyclone then break end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i)) -- UnitAura(unit,i,"HARMFUL") 
	end
	return Cyclone
end

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()
local isArena, _ = IsActiveBattlefieldArena()

-- Config FOCUS
if not jps.UnitExists("focus") and canDPS("mouseover") then
	-- set focus an enemy targeting you
	if jps.UnitIsUnit("mouseovertarget","player") and not jps.UnitIsUnit("target","mouseover") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	-- set focus an enemy healer
	elseif jps.EnemyHealer("mouseover") then
		jps.Macro("/focus mouseover")
		local name = GetUnitName("focus")
		print("Enemy HEALER|cff1eff00 "..name.." |cffffffffset as FOCUS")
	end
end

-- CONFIG jps.getConfigVal("keep focus") if you want to keep focus
if jps.UnitExists("focus") and jps.UnitIsUnit("target","focus") then
	jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
	if jps.getConfigVal("keep focus") == false then jps.Macro("/clearfocus") end
end

if canDPS("target") and not DebuffUnitCyclone("target") then rangedTarget =  "target"
elseif canDPS("targettarget") and not DebuffUnitCyclone("targettarget") then rangedTarget = "targettarget"
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {
	-- Buffs
	{ dk.spells["FrostPresence"] , not jps.buff(dk.spells["FrostPresence"]) },
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells["HornOfWinter"]) },

	-- Battle Rezz
	--{ dk.spells["RaiseAlly"] , UnitIsDeadOrGhost("focus") == 1 and UnitPlayerControlled("focus") and jps.UseCds, "focus" },
	--{ dk.spells["RaiseAlly"] , UnitIsDeadOrGhost("target") == 1 and UnitPlayerControlled("target") and jps.UseCds, "target" },

	-- HEAL
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.IsSpellKnown(48743) and jps.hp() < 0.5 },
	-- "Icebound Fortitude" 61999 "Robustesse glaciale"
	{ dk.spells["Icebound"] , jps.hp() < 0.75 },
	-- "Death Strike" 49998 "Frappe de Mort"
	{ dk.spells["DeathStrike"] , jps.buff(101568) and jps.hp() < 0.9 , rangedTarget, "DeathStrike_buff" },
	-- "Dark Succor" 101568 "Sombre secours" -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	-- "Stoneform" 20594 "Forme de pierre"
	{ 20594 , playerAggro and jps.hp() < 0.9 , "player" , "_Stoneform" },
	-- 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.IsSpellKnown(108196) and jps.hp() < 0.8 },


	-- Interrupts
	-- "Mind Freeze" 47528 "Gel de l'esprit"
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick() , rangedTarget , "Mind_Freeze" },
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick("focus"), "focus" },
	-- "Strangulate" 47476 "Strangulation"
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick() and jps.IsSpellInRange(47476, rangedTarget) },
	
	-- Spell Steal
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , rangedTarget},
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},
	
	-- 51271 -- Pilier de givre -- increases the Death Knight's Strength by 15%
	{ dk.spells["PillarOfFrost"] , jps.UseCDs},
	-- On-use Trinkets.
	--{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.UseCDs},
	--{ jps.useTrinket(1), jps.useTrinketBool(1) and jps.UseCDs},


	-- "Faucheur d'âme" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) <= 0.35 , rangedTarget , "_SoulReaper" },
	-- "Outbreak" 77575 "Poussée de fièvre" -- 30 yd range -- Poussée de fièvre gives both debuff Frost Fever 55095 Blood Plague 55078 1 min cd
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55078,rangedTarget) < 9 , rangedTarget , "_OutBreak" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095
	{ dk.spells["HowlingBlast"] , jps.buff(dk.spells["FreezingFog"]) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , jps.myDebuffDuration(55095,rangedTarget) < 6 , rangedTarget , "HowlingBlast_Debuff" },
	-- "Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078
	{ dk.spells["PlagueStrike"] , jps.myDebuffDuration(55078,rangedTarget) < 9 and dk.rune("dk.oneUr "), rangedTarget , "PlagueStrike_Debuff" },
	-- "Frost Strike" 49143 "Frappe de givre"
	{ dk.spells["FrostStrike"] , jps.runicPower() > 75 , rangedTarget , "FrostStrike_RunicPower" },
	{ dk.spells["FrostStrike"] , jps.runicPower() > 25 and jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "FrostStrike_KillingMachine" },

	-- "BloodTap" 45529 -- "Drain sanglant"
	{ dk.spells["BloodTap"] , jps.buffStacks(dk.spells["BloodCharge"]) > 9 , rangedTarget , "_DrainSanglant_10" },
	
	-- "Obliterate" 49020 "Anéantissement" -- With "KillingMachine" for Two-Hand DPS
	{ dk.spells["Obliterate"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "KillingMachine_Obliterate" },
	{ dk.spells["Obliterate"] , dk.rune("twoDr") , rangedTarget , "_Obliterate_twoDr" },
	{ dk.spells["Obliterate"] , dk.rune("twoFr") , rangedTarget , "_Obliterate_twoFr" },
	{ dk.spells["Obliterate"] , dk.rune("twoUr") , rangedTarget , "_Obliterate_twoUr" },


	{"nested", jps.MultiTarget or EnemyCount >= 3 ,{
		
		-- "Howling Blast" 49184 "Rafale hurlante"
		{ dk.spells["HowlingBlast"] , dk.rune("twoFr") , rangedTarget , "HowlingBlast_twoFr" }, -- Frost runes
		{ dk.spells["HowlingBlast"] , dk.rune("twoDr") , rangedTarget , "HowlingBlast_twoDr" }, -- Death runes
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition"
		{ dk.spells["DeathAndDecay"] , dk.rune("twoUr") }, -- Unholy runes
		-- "Plague Leech" 123693 "Parasite de peste"
		{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(3) , rangedTarget , "_Parasite de peste" },

	}},
	
	-- MULTITARGET


	-- 47568 -- Renforcer l'arme runique
	{ dk.spells["EmpowerRuneWeapon"] , jps.runicPower() <= 25 and not dk.rune("twoDr") and not dk.rune("twoFr") and not dk.rune("twoUr") },
	
}
	
	
	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "PVE 2H Simcraft")


--[[

jps.registerStaticTable("DEATHKNIGHT","FROST",{

	{ "Horn of Winter",not jps.buff("Horn of Winter")},
	{ "Death and Decay",IsShiftKeyDown() == true and GetCurrentKeyBoardFocus() == nil and jps.MultiTarget},

	-- Self heal
	{ "Death Pact",jps.UseCDs and jps.hp() < 0.6 and UnitExists("pet") == true},

	-- Rune Management
	{ "Plague Leech",dk.canCastPlagueLeech(3)},


	{"nested", IsSpellInRange("Obliterate","target") == 1,{
		--CDs + Buffs
		{ "Pillar of Frost",jps.UseCDs},
	
		{ jps.getDPSRacial(),jps.UseCDs},
	
	}},

	-- If our diseases are about to fall off.
 	{ "outbreak",jps.myDebuffDuration("Blood Plague") <3},
 	{ "outbreak",jps.myDebuffDuration("Frost Fever") <3},
	{ "Soul Reaper",jps.hp("target") < 0.35},

	-- Kick
	{ "mind freeze",jps.ShouldKick()},
	{ "mind freeze",jps.ShouldKick("focus"), "focus"},
	{ "Strangulate",jps.ShouldKick() and jps.UseCDs and IsSpellInRange("mind freeze","target")==0 and jps.LastCast ~= "mind freeze"},
	{ "Strangulate",jps.ShouldKick("focus") and jps.UseCDs and IsSpellInRange("mind freeze","focus")==0 and jps.LastCast ~= "mind freeze", "focus"},
	{ "Asphyxiate",jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate"},
	{ "Asphyxiate",jps.ShouldKick() and jps.LastCast ~= "Mind Freeze" and jps.LastCast ~= "Strangulate", "focus"},

	-- Spell Steal
	{"Dark Simulacrum ", dk.shouldDarkSimTarget() , "target"},
	{"Dark Simulacrum ", dk.shouldDarkSimFocus() , "focus"},

	-- Unholy Blight when our diseases are about to fall off. (talent based)
 	{ "unholy blight",jps.myDebuffDuration("Frost Fever") < 3},
 	{ "unholy blight",jps.myDebuffDuration("Blood Plague") < 3},

	-- Diseases
	{ "Howling Blast",jps.myDebuffDuration("Frost Fever") <= 1},
	{ "Howling Blast",jps.buff("Freezing Fog") and jps.runicPower() < 88},
	{ "Plague Strike",jps.myDebuffDuration("Blood Plague") <= 1},

	-- Self heals
	{ "Death Siphon",jps.hp() < 0.8 and jps.Defensive},
	{ "Death Strike",jps.hp() < 0.7 and jps.Defensive},

	{ "Obliterate",jps.runicPower() <= 76},
	{ "Obliterate",jps.buff("Killing Machine")},
	{ "Obliterate",jps.bloodlusting()},
	
	-- Filler
	{ "Frost Strike",jps.runicPower() >= 76},
	{ "Frost Strike",jps.bloodlusting()},
	{ "Frost Strike",not dk.rune("oneFr")},

	{ "Frost Strike",not jps.buff("Killing Machine") and jps.cooldown("Obliterate") > 1},
	{ "Frost Strike",jps.buff("Killing Machine") and jps.cooldown("Obliterate") > 1},
	{ "Obliterate"},
	{ "Frost Strike"},
	{ "Plague Leech",dk.canCastPlagueLeech(2)},
	{ "Empower Rune Weapon",IsSpellInRange("Obliterate","target") == 1 and jps.UseCDs and jps.runicPower() <= 25 and not dk.rune("twoDr") and not dk.rune("twoFr") and not dk.rune("twoUr")},
	{ "Empower Rune Weapon",IsSpellInRange("Obliterate","target") == 1 and jps.UseCDs and jps.TimeToDie("target") < 60 and jps.buff("Potion of Mogu Power")},
	{ "Empower Rune Weapon",IsSpellInRange("Obliterate","target") == 1 and jps.UseCDs and jps.bloodlusting()},
}, "PVP 2H", false, true)

]]--