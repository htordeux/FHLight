
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

jps.registerRotation("DEATHKNIGHT","FROST", function()

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) --- return true/false ONLY FOR PLAYER > 2 sec
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()

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
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- UPDATE RUNES ---------
------------------------

local Dr,Fr,Ur = dk.updateRune()
local DepletedRunes = (Dr == 0) or (Fr == 0) or (Ur == 0)
local AllDepletedRunes = (Dr + Fr + Ur) == 0

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "FrostPresence" 48266 "Présence de givre"
	{ dk.spells["FrostPresence"] , not jps.buff(dk.spells["FrostPresence"]) , "player" },
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells["HornOfWinter"]) , "player" },

	-- AGGRO
	{"nested", playerAggro and jps.hp() < 0.90 ,{
		-- "Icebound Fortitude" 48792 "Robustesse glaciale"
		{ dk.spells["Icebound"] , jps.hp() < 0.75 , "player" , "_Icebound" },
		-- "Stoneform" 20594 "Forme de pierre"
		{ 20594 , true , "player" , "_Stoneform" },
		-- "Remorseless Winter" 108200 "Hiver impitoyable"
		{ dk.spells["RemorselessWinter"] , jps.IsSpellInRange(49998) , "player" , "_Remorseless" },
		-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") },
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") },
	}},

	-- HEALS --
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.70 and jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.UseCDs and jps.hp() < 0.50 , rangedTarget, "_DeathPact" },
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.UseCDs and jps.hp() < 0.50 , rangedTarget, "_DeathSiphon" },
	
	-- CONTROL --
	-- "Lichborne" 49039 "Changeliche" -- vous rend insensible aux effets de charme, de peur et de sommeil pendant 10 s.
	{dk.spells["Lichborne"] , playerIsStun , rangedTarget , "_Lichborne" },
	--"Strangulate" 47476 "Strangulation" -- 30 yd range
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , "_STRANGULATE" },
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" },
	-- "Asphyxiate" 108194 "Asphyxier" -- 30 yd range
	{ dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "_ASPHYXIATE" },
	{ dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" },
	--"Mind Freeze" 47528 "Gel de l'esprit"
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "_MINDFREEZE" },
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick("focus"), "focus" },
	-- "Dark Simulacrum" 77606 "Sombre simulacre"
	{dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , "target" , "_DARKSIMULACRUM" },
	{dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},
	
	-- KillingMachine --	
	{"nested", jps.buff(dk.spells["KillingMachine"]) ,{	
		-- "Pillar of Frost" 51271 "Pilier de givre" -- increases the Death Knight's Strength by 15%
		{ dk.spells["PillarOfFrost"] , true , rangedTarget , "Pillar_Of_Frost" },
		--"Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power 
		{ dk.spells["FrostStrike"] , true , rangedTarget , "FrostStrike_KillingMachine_1" },
	}},
	
	-- "Death Grip" 49576 "Poigne de la mort"
	{ dk.spells["DeathGrip"] , jps.PvP and not jps.IsSpellInRange(49998,"target") },

	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Dark Succor" 101568 "Sombre secours" Buff -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	{ dk.spells["DeathStrike"] , jps.buff(101568) , rangedTarget, "DeathStrike_Buff" },
	{ dk.spells["DeathStrike"] , jps.hp() < 0.60 , rangedTarget, "DeathStrike_Health" },

	-- RUNE MANAGEMENT --
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech() and DepletedRunes , rangedTarget , "Parasite_Peste" },
	-- "BloodTap" 45529 -- Buff "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes , rangedTarget , "DrainSanglant_10" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 5 and AllDepletedRunes , rangedTarget , "DrainSanglant_5" },
	-- "Empower Rune Weapon" 77606 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.IsSpellInRange(49998,"target") and jps.runicPower() < 75 and AllDepletedRunes },
	
	--"Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	{ dk.spells["OutBreak"] , jps.myDebuffDuration("Blood Plague") < 5 },
	{ dk.spells["OutBreak"] , jps.myDebuffDuration("Frost Fever") < 5 },

	-- TRINKETS
	{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.UseCDs},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and jps.UseCDs},
	
	-- DISEASES --
	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095 -- 1 Frost
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	{ dk.spells["HowlingBlast"] , jps.buff(59052) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,rangedTarget) and not jps.isRecast(49184,rangedTarget) , rangedTarget , "HowlingBlast_Debuff" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,"focus") and not jps.isRecast(49184,"focus") , "focus" , "HowlingBlast_Debuff_focus" },
	--"Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078 -- 1 Unholy
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,rangedTarget) and not jps.isRecast(45462,rangedTarget) , rangedTarget , "PlagueStrike_Debuff" },
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,"focus") and not jps.isRecast(45462,"focus") , "focus" , "PlagueStrike_Debuff_focus" },

	--"Soul Reaper" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },

	-- MULTITARGET --	
	{"nested", jps.MultiTarget and EnemyCount > 2 ,{
		-- "Defile" 152280 "Profanation" -- 1 Unholy
		{ dk.spells["Defile"] , true },
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		--{ dk.spells["DeathAndDecay"] , true },
	}},

	--"Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power 
	--"Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["FrostStrike"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "FrostStrike_KillingMachine_2" },
	{ dk.spells["FrostStrike"] , jps.runicPower() >= 75 , rangedTarget , "FrostStrike_RunicPower" },
	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
	{ dk.spells["Obliterate"] , jps.runicPower() < 75 , rangedTarget , "Obliterate_LowPower" },
	{ dk.spells["Obliterate"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "Obliterate_KillingMachine" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost
	{ dk.spells["HowlingBlast"] , Fr == 2 }, -- Frost runes
	{ dk.spells["HowlingBlast"] , Dr == 2 }, -- Death runes

}
	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target

end, "Frost Dual-Wield")

--[[

Killing Machine is now uses critical strikes on Frost Strike and Obliterates depending on Deathknight's weapons.
When using 2H Weapons, Killing Machine no longer gains critical strike from FROST STRIKES.
When using Dual Wield, Killing Machine no longer gains critical strike from OBLITERATES.

Dual Wield:
DW Frost doesn't rely on Oblit for most of its damage. Oblit is only used to keep unholy runes on CD. Howling blast and Frost Strike are your main abilites as DW
don't prioritize Obliterate like you do with 2h. You only want to use your unholy runes on Obliterate and everything else you're just a Howling Blast spam machine.
In dual wield, if you get a KM proc and don't have Runic power for Frost Strike, you basically have to always waste that proc on an Obliterate.

Two-Hand:
The difference between dual wield and 2H comes down to Killing Machine procs.
In 2H you prioritize Obliterate, so if you have a KM proc, but your runes aren't up yet, you can sit on that KM proc for a bit, or use Plague Leech or Empowered Runes to get those runes and get a big crit.
There is no rotation, make sure you are using as many runes on obliterate as possible and dont frost strike unless you are going to cap on runic power or all your runes are on cooldown and you cant obliterate.
If you get a kill machine proc try not to frost strike unless your obliterate isnt going to be availble for around 3 seconds. Use rime procs on howling blast for damage or icy touch for dispelling
Your disease's are always a high priority as any death knight spec although they aren't as important for frost as they once were because of the change's that were made to obliterate and frost strike no longer gaining extra damage bonuses from having disease's up on your target. Because of this you won't be worrying so much about blood plague being active on the target all the time so you will want to maintain it via outbreak

Plague Leech - Explained to be useable you are required to have both your blood plague/frost fever active on the target.
For this ability to work you must have any 2 types of runes on cooldown at the same time as they must be depleted
You can use plague leech when your getting low on HP and need the extra runes to death strike for a quick self heal
Pillar of Frost - increases our total strength by 20% and has a very short 1 minute cooldown. To get the most out of this ability you want to stack it with as many procs as you possibly can for maximum burst potential
Frost Strike - This ability is used as your runic power dump. You will use this to get rid of excess runic power or when all your runes are on cooldown and you have nothing left to use.

http://www.skill-capped.com/forums/showthread.php?29889-Frost-Death-Knight-PvP-Guide-Warlords-of-Draenor
http://forums.elitistjerks.com/page/articles.html/_/world-of-warcraft/death-knight/60-dps-death-knight-603-%E2%80%93-turtles-all-the-r112

]]--

jps.registerRotation("DEATHKNIGHT","FROST", function()

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) --- return true/false ONLY FOR PLAYER > 2 sec
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
local EnemyCount = jps.RaidEnemyCount()

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
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- UPDATE RUNES ---------
------------------------

local Dr,Fr,Ur = dk.updateRune()
local DepletedRunes = (Dr == 0) or (Fr == 0) or (Ur == 0)
local AllDepletedRunes = (Dr + Fr + Ur) == 0

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "FrostPresence" 48266 "Présence de givre"
	{ dk.spells["FrostPresence"] , not jps.buff(dk.spells["FrostPresence"]) , "player" },
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells["HornOfWinter"]) , "player" },

	-- AGGRO
	{"nested", playerAggro and jps.hp() < 0.90 ,{
		-- "Icebound Fortitude" 48792 "Robustesse glaciale"
		{ dk.spells["Icebound"] , jps.hp() < 0.75 , "player" , "_Icebound" },
		-- "Stoneform" 20594 "Forme de pierre"
		{ 20594 , true , "player" , "_Stoneform" },
		-- "Remorseless Winter" 108200 "Hiver impitoyable"
		{ dk.spells["RemorselessWinter"] , jps.IsSpellInRange(49998) , "player" , "_Remorseless" },
		-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") },
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") },
	}},

	-- HEALS --
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.70 and jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.UseCDs and jps.hp() < 0.50 , rangedTarget, "_DeathPact" },
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.UseCDs and jps.hp() < 0.50 , rangedTarget, "_DeathSiphon" },
	
	-- CONTROL --
	-- "Lichborne" 49039 "Changeliche" -- vous rend insensible aux effets de charme, de peur et de sommeil pendant 10 s.
	{dk.spells["Lichborne"] , playerIsStun , rangedTarget , "_Lichborne" },
	--"Strangulate" 47476 "Strangulation" -- 30 yd range
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , "_STRANGULATE" },
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" },
	-- "Asphyxiate" 108194 "Asphyxier" -- 30 yd range
	{ dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "_ASPHYXIATE" },
	{ dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" },
	--"Mind Freeze" 47528 "Gel de l'esprit"
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget , "_MINDFREEZE" },
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick("focus"), "focus" },
	-- "Dark Simulacrum" 77606 "Sombre simulacre"
	{dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , "target" , "_DARKSIMULACRUM" },
	{dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},

	-- KillingMachine --
	{"nested", jps.buff(dk.spells["KillingMachine"]) ,{
		-- "Pillar of Frost" 51271 "Pilier de givre" -- increases the Death Knight's Strength by 15%
		{ dk.spells["PillarOfFrost"] , true , rangedTarget , "Pillar_Of_Frost" },
		--"Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
		{ dk.spells["Obliterate"] , true , rangedTarget , "Obliterate_KillingMachine_1" },
	}},

	-- "Death Grip" 49576 "Poigne de la mort"
	{ dk.spells["DeathGrip"] , jps.PvP and not jps.IsSpellInRange(49998,"target") },
	
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Dark Succor" 101568 "Sombre secours" Buff -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	{ dk.spells["DeathStrike"] , jps.buff(101568) , rangedTarget, "DeathStrike_Buff" },
	{ dk.spells["DeathStrike"] , jps.hp() < 0.60 , rangedTarget, "DeathStrike_Health" },
	
	-- RUNE MANAGEMENT --
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech() and DepletedRunes , rangedTarget , "Parasite_Peste" },
	-- "BloodTap" 45529 -- Buff "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes , rangedTarget , "DrainSanglant_10" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 5 and AllDepletedRunes , rangedTarget , "DrainSanglant_5" },
	-- "Empower Rune Weapon" 77606 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.IsSpellInRange(49998,"target") and jps.runicPower() < 75 and AllDepletedRunes },
	
	--"Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	{ dk.spells["OutBreak"] , jps.myDebuffDuration("Blood Plague") < 5 },
	{ dk.spells["OutBreak"] , jps.myDebuffDuration("Frost Fever") < 5 },

	-- TRINKETS --
	{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.UseCDs},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and jps.UseCDs},

	-- DISEASES --
	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095 -- 1 Frost
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	{ dk.spells["HowlingBlast"] , jps.buff(59052) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,rangedTarget) and not jps.isRecast(49184,rangedTarget) , rangedTarget , "HowlingBlast_Debuff" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,"focus") and not jps.isRecast(49184,"focus") , "focus" , "HowlingBlast_Debuff_focus" },
	--"Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078 -- 1 Unholy
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,rangedTarget) and not jps.isRecast(45462,rangedTarget) , rangedTarget , "PlagueStrike_Debuff" },
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,"focus") and not jps.isRecast(45462,"focus") , "focus" , "PlagueStrike_Debuff_focus" },

	--"Soul Reaper" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },

	-- MULTITARGET --
	{"nested", jps.MultiTarget and EnemyCount > 2 ,{
		-- "Defile" 152280 "Profanation" -- 1 Unholy
		{ dk.spells["Defile"] , true },
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		--{ dk.spells["DeathAndDecay"] , true },
	}},

	--"Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
	--"Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["Obliterate"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "Obliterate_KillingMachine_2" },
	{ dk.spells["Obliterate"] , jps.runicPower() < 75 , rangedTarget , "Obliterate_LowPower" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power 
	{ dk.spells["FrostStrike"] , jps.runicPower() >= 75 , rangedTarget , "FrostStrike_RunicPower" },
	{ dk.spells["FrostStrike"] , jps.buff(dk.spells["KillingMachine"]) , rangedTarget , "FrostStrike_KillingMachine" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , Fr == 2 }, -- Frost runes
	{ dk.spells["HowlingBlast"] , Dr == 2 }, -- Death runes

}
	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target

end, "Frost Two-Hand")

