
local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass

local ClassEnemy = {
	["WARRIOR"] = "cac",
	["PALADIN"] = "caster",
	["HUNTER"] = "cac",
	["ROGUE"] = "cac",
	["PRIEST"] = "caster",
	["DEATHKNIGHT"] = "cac",
	["SHAMAN"] = "caster",
	["MAGE"] = "caster",
	["WARLOCK"] = "caster",
	["MONK"] = "caster",
	["DRUID"] = "caster"
}

local EnemyCaster = function(unit)
	if not jps.UnitExists(unit) then return false end
	local _, classTarget, classIDTarget = UnitClass(unit)
	return ClassEnemy[classTarget]
end


jps.registerRotation("DEATHKNIGHT","FROST", function()

local spell = nil
local target = nil

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) --- return true/false ONLY FOR PLAYER > 2 sec
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER

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
	{ dk.spells["FrostPresence"] , jps.hp() > 0.50 and not jps.buff(dk.spells["FrostPresence"]) , "player" },
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells["HornOfWinter"]) , "player" },
	-- "Icebound Fortitude" 61999 "Robustesse glaciale"
	{ dk.spells["Icebound"] , playerAggro and jps.hp() < 0.55 , "player" , "_Icebound" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ 20594 , playerAggro and jps.hp() < 0.90 , "player" , "_Stoneform" },
	-- "Remorseless Winter" 108200 "Hiver impitoyable"
	{ dk.spells["RemorselessWinter"] , playerAggro and jps.hp() < 0.90 , "player" , "_Icebound" },
	-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
	{ dk.spells["AntiMagicZone"] , EnemyCaster(rangedTarget) == "caster" and jps.IsCasting(rangedTarget) and jps.UnitIsUnit(rangedTarget.."target","player") , rangedTarget },
	-- "Blood Presence" 48263 
	--{ 48263 , playerAggro and jps.hp() < 0.50 and not jps.buff(48263) , "player" },

	-- Battle Rezz
	--{ dk.spells["RaiseAlly"] , UnitIsDeadOrGhost("focus") == 1 and jps.UseCds, "focus" },
	--{ dk.spells["RaiseAlly"] , UnitIsDeadOrGhost("target") == 1 and jps.UseCds, "target" },

	-- HEAL
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.IsSpellKnown(108196) and jps.hp() < 0.55 , rangedTarget, "_DeathSiphon" },
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.IsSpellKnown(48743) and jps.hp() < 0.55 , "player" , "_DeathPact" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Dark Succor" 101568 "Sombre secours" Buff -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	-- "Dark Succor" 178819 "Sombre secours" Spell Passif -- En Présence de givre ou impie, lorsque vous tuez un ennemi qui rapporte de l’expérience ou de l’honneur, votre prochaine Frappe de mort dans les 15 s ne coûte rien et rend 100% de points de vie supplémentaires.
	{ dk.spells["DeathStrike"] , jps.hp() < 0.85 and jps.buff(101568) , rangedTarget, "DeathStrike_buff" },
	{ dk.spells["DeathStrike"] , twoDr and jps.hp() < 0.85 , rangedTarget, "DeathStrike_twoDr" },
	{ dk.spells["DeathStrike"] , jps.hp() < 0.55 , rangedTarget, "DeathStrike_Health" },

	-- Interrupts
	-- "Mind Freeze" 47528 "Gel de l'esprit"
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "MIND_FREEZE" },
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick("focus"), "focus" },
	-- "Strangulate" 47476 "Strangulation"
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick(rangedTarget) and jps.IsSpellInRange(47476, rangedTarget) , "_STRANGULATE" },
	
	-- Spell Steal
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , rangedTarget , "_DarkSimulacrum" },
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},
	
	-- 51271 -- Pilier de givre -- increases the Death Knight's Strength by 15%
	{ dk.spells["PillarOfFrost"] , jps.combatStart > 0 },
	-- On-use Trinkets.
	--{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.UseCDs},
	--{ jps.useTrinket(1), jps.useTrinketBool(1) and jps.UseCDs},
	
	-- "BloodTap" 45529 -- "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes , rangedTarget , "DrainSanglant_10" },

	-- "Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	-- Poussée de fièvre gives both debuff Frost Fever 55095 Blood Plague 55078 1 min cd
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55078,rangedTarget) < 9 , rangedTarget , "_OutBreak" },


	-- "Faucheur d'âme" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },	
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power -- Killing Machine next Obliterate or Frost Strike automatically critically strike.
	-- "Frost Strike" With "KillingMachine" for Dual-Wield DPS
	{ dk.spells["FrostStrike"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "FrostStrike_KillingMachine" },
	{ dk.spells["FrostStrike"] , jps.runicPower() > 75 , rangedTarget , "FrostStrike_RunicPower" },
	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
	-- 45% chance to cause your next Howling Blast or Icy Touch to consume no runes
	{ dk.spells["Obliterate"] , jps.myDebuffDuration(55095,rangedTarget) > 10 and jps.myDebuffDuration(55078,rangedTarget) > 10 , rangedTarget , "Obliterate_Debuff" },


	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095 -- 1 Frost
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	{ dk.spells["HowlingBlast"] , jps.buff(59052) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,rangedTarget) and not jps.isRecast(49184,rangedTarget) , rangedTarget , "HowlingBlast_Debuff" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,"focus") and not jps.isRecast(49184,"focus") , "focus" , "HowlingBlast_Debuff_focus" },
	-- "Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078 -- 1 Unholy
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,rangedTarget) and not jps.isRecast(45462,rangedTarget) , rangedTarget , "PlagueStrike_Debuff" },
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,"focus") and not jps.isRecast(45462,"focus") , "focus" , "PlagueStrike_Debuff_focus" },
	
	-- "Obliterate" 49020 "Anéantissement" -- 45% chance to cause your next Howling Blast or Icy Touch to consume no runes 
	{ dk.spells["Obliterate"] , twoDr , rangedTarget , "Obliterate_twoDr" },
	{ dk.spells["Obliterate"] , twoFr , rangedTarget , "Obliterate_twoFr" },
	{ dk.spells["Obliterate"] , twoUr , rangedTarget , "Obliterate_twoUr" },

	-- 47568 -- Renforcer l'arme runique
	{ dk.spells["EmpowerRuneWeapon"] , jps.runicPower() < 30 and not twoDr and not twoFr and not twoUr },

	-- MULTITARGET	
	{"nested", jps.MultiTarget and EnemyCount > 2 ,{
		
		-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost
		{ dk.spells["HowlingBlast"] , twoFr , rangedTarget , "HowlingBlast_Fr" }, -- Frost runes
		{ dk.spells["HowlingBlast"] , twoDr , rangedTarget , "HowlingBlast_Dr" }, -- Death runes
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		{ dk.spells["DeathAndDecay"] , oneUr },
		{ dk.spells["DeathAndDecay"] , oneDr },
		-- "Plague Leech" 123693 "Parasite de peste"
		{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(9) and DepletedRunes , rangedTarget , "Parasite_Peste" },

	}},

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "Frost Dual-Wield")

--[[

Killing Machine is now uses critical strikes on Frost Strike and Obliterates depending on Deathknight's weapons.
When using 2H Weapons, Killing Machine no longer gains critical strike from FROST STRIKES.
When using Dual Wield, Killing Machine no longer gains critical strike from OBLITERATES.

DW Frost doesn't rely on Oblit for most of its damage. Oblit is only used to keep unholy runes on CD. Howling blast and Frost Strike are your main abilites as DW

don't prioritize Obliterate like you do with 2h. You only want to use your unholy runes on Obliterate and everything else you're just a Howling Blast spam machine. You should see a dps increase.

The difference between dual wield and 2H comes down to Killing Machine procs. In 2H you prioritize Obliterate, so if you have a KM proc, but your runes aren't up yet, you can sit on that KM proc for a bit, or use Plague Leech or Empowered Runes to get those runes and get a big crit.

In dual wield, if you get a KM proc and don't have Runic power for Frost Strike, you basically have to always waste that proc on an Obliterate, or try to spend runes on less than ideal strikes to generate RP, which is going to be a net loss. For me, it just doesn't play out as well as 2H does

There is no rotation, make sure you are using as many runes on obliterate as possible and dont frost strike unless you are going to cap on runic power or all your runes are on cooldown and you cant obliterate. If you get a kill machine proc try not to frost strike unless your obliterate isnt going to be availble for around 3 seconds. Use rime procs on howling blast for damage or icy touch for dispelling

http://www.skill-capped.com/forums/showthread.php?29889-Frost-Death-Knight-PvP-Guide-Warlords-of-Draenor

Pillar of Frost increases our total strength by 20% and has a very short 1 minute cooldown. To get the most out of this ability you want to stack it with as many procs as you possibly can for maximum burst potential

Frost Strike - This ability is used as your runic power dump. You will use this to get rid of excess runic power or when all your runes are on cooldown and you have nothing left to use.

Your disease's are always a high priority as any death knight spec although they aren't as important for frost as they once were because of the change's that were made to obliterate and frost strike no longer gaining extra damage bonuses from having disease's up on your target. Because of this you won't be worrying so much about blood plague being active on the target all the time so you will want to maintain it via outbreak

http://forums.elitistjerks.com/page/articles.html/_/world-of-warcraft/death-knight/60-dps-death-knight-603-%25E2%2580%2593-turtles-all-the-r112%2BKilling+Machine+no+longer+gains+critical+strike&rlz=1I7AURU_frFR503&safe=active&gws_rd=cr,ssl&safe=active&&ct=clnk

Plague Leech Explained to be useable you are required to have both your blood plague/frost fever active on the target.
For this ability to work you must have any 2 types of runes on cooldown at the same time as they must be depleted
You can use plague leech when your getting low on HP and need the extra runes to death strike for a quick self heal

]]--

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

}, "PvP Frost Two-Hand", false, true)

