
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
-- UPDATE RUNES ---------
------------------------

local oneDr,twoDr,oneFr,twoFr,oneUr,twoUr = dk.updateRunes()
local DepletedRunes = (not oneDr and not twoDr) or (not oneUr and not twoUr) or (not oneFr and not twoFr) 
------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "FrostPresence" 48266 "Présence de givre"
	{ dk.spells["FrostPresence"] , jps.hp() > 0.55 and not jps.buff(dk.spells["FrostPresence"]) },
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells["HornOfWinter"]) },

	-- Battle Rezz
	--{ dk.spells["RaiseAlly"] , UnitIsDeadOrGhost("focus") == 1 and UnitPlayerControlled("focus") and jps.UseCds, "focus" },
	--{ dk.spells["RaiseAlly"] , UnitIsDeadOrGhost("target") == 1 and UnitPlayerControlled("target") and jps.UseCds, "target" },

	-- HEAL
	-- "Stoneform" 20594 "Forme de pierre"
	{ 20594 , playerAggro and jps.hp() < 0.90 , "player" , "_Stoneform" },
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.IsSpellKnown(108196) and jps.hp() < 0.55 },
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.IsSpellKnown(48743) and jps.hp() < 0.55 },
	
	-- "Blood Presence" 48263 --  increasing Stamina by 20%, base armor by 30%, and reducing damage taken by 10%. Threat generation is significantly increased.
	{ 48263 , jps.hp() < 0.50 and not jps.buff(48263) },
	
	-- "Icebound Fortitude" 61999 "Robustesse glaciale"
	{ dk.spells["Icebound"] , jps.hp() < 0.85 },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Dark Succor" 101568 "Sombre secours" Buff -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	-- "Dark Succor" 178819 "Sombre secours" Spell -- En Présence de givre ou impie, lorsque vous tuez un ennemi qui rapporte de l’expérience ou de l’honneur, votre prochaine Frappe de mort dans les 15 s ne coûte rien et rend 100% de points de vie supplémentaires.
	{ dk.spells["DeathStrike"] , jps.buff(101568) and jps.hp() < 0.85 , rangedTarget, "DeathStrike_buff" },
	{ dk.spells["DeathStrike"] , twoDr and jps.hp() < 0.85 , rangedTarget, "DeathStrike_buff" },
	{ dk.spells["DeathStrike"] , oneDr and oneUr and jps.hp() < 0.85 , rangedTarget, "DeathStrike_buff" },
	{ dk.spells["DeathStrike"] , oneDr and oneFr and jps.hp() < 0.85 , rangedTarget, "DeathStrike_buff" },

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

	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(9) and DepletedRunes , rangedTarget , "Parasite_Peste" },
	-- "Outbreak" 77575 "Poussée de fièvre" -- 30 yd range -- Poussée de fièvre gives both debuff Frost Fever 55095 Blood Plague 55078 1 min cd
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55078,rangedTarget) < 9 , rangedTarget , "_OutBreak" },
	-- "Faucheur d'âme" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },

	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095 -- 1 Frost
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	{ dk.spells["HowlingBlast"] , jps.buff(59052) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,rangedTarget) , rangedTarget , "HowlingBlast_Debuff_1" },
	{ dk.spells["HowlingBlast"] , jps.myDebuff(55095,rangedTarget) and jps.myDebuffDuration(55095,rangedTarget) < 6 and not jps.isRecast(49184,rangedTarget) , rangedTarget , "HowlingBlast_Debuff_2" },
	-- "Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,rangedTarget) , rangedTarget , "PlagueStrike_Debuff_1" },
	{ dk.spells["PlagueStrike"] , jps.myDebuff(55078,rangedTarget) and jps.myDebuffDuration(55078,rangedTarget) < 9 and not jps.isRecast(45462,rangedTarget) , rangedTarget , "PlagueStrike_Debuff_2" },


	-- "BloodTap" 45529 -- "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes , rangedTarget , "DrainSanglant_10" },
	

	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power -- Killing Machine next Obliterate or Frost Strike automatically critically strike.
	-- "Frost Strike" With "KillingMachine" for Dual-Wield DPS
	{ dk.spells["FrostStrike"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "FrostStrike_KillingMachine" },
	{ dk.spells["FrostStrike"] , jps.runicPower() > 75 , rangedTarget , "FrostStrike_RunicPower" },
	
	-- "Obliterate" 49020 "Anéantissement" -- 45% chance to cause your next Howling Blast or Icy Touch to consume no runes
	-- "Obliterate" With "KillingMachine" for Two-Hand DPS -- 1 Unholy, 1 Frost
	{ dk.spells["Obliterate"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "KillingMachine_Obliterate" }, 
	{ dk.spells["Obliterate"] , twoDr , rangedTarget , "Obliterate_twoDr" },
	{ dk.spells["Obliterate"] , twoFr , rangedTarget , "Obliterate_twoFr" },
	{ dk.spells["Obliterate"] , twoUr , rangedTarget , "Obliterate_twoUr" },
	{ dk.spells["Obliterate"] , oneUr and oneDr , rangedTarget , "Obliterate_oneUr" },

	-- 47568 -- Renforcer l'arme runique
	{ dk.spells["EmpowerRuneWeapon"] , jps.runicPower() < 25 and not twoDr and not twoFr and not twoUr },

	-- MULTITARGET	
	{"nested", jps.MultiTarget ,{
		
		-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost
		{ dk.spells["HowlingBlast"] , twoFr , rangedTarget , "HowlingBlast_Fr" }, -- Frost runes
		{ dk.spells["HowlingBlast"] , twoDr , rangedTarget , "HowlingBlast_Dr" }, -- Death runes
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		{ dk.spells["DeathAndDecay"] , oneUr },
		{ dk.spells["DeathAndDecay"] , oneDr },
		-- "Plague Leech" 123693 "Parasite de peste"
		{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(4) , rangedTarget , "Parasite_Peste" },

	}},

}
	
	
	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "PVE Frost Default")

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