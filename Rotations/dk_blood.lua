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

local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass

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

jps.registerRotation("DEATHKNIGHT","BLOOD",function()

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
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- UPDATE RUNES ---------
------------------------

local DepletedRunes = (dk.rune("Dr") == 0) or (dk.rune("Fr") == 0) or (dk.rune("Ur") == 0)
local AllDepletedRunes = (dk.rune("Dr") == 0) and (dk.rune("Fr") == 0) and (dk.rune("Ur") == 0)
local DeathStrikeRunes = (dk.rune("Dr") > 0 and dk.rune("Fr") > 0)

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {
	-- "BloodPresence" 48263 "Présence de sang"
	{dk.spells["BloodPresence"] , not jps.buff(48263) },
	-- "Horn of Winter" 57330 "Cor de l’hiver"
	{dk.spells["HornOfWinter"] , not jps.buff(57330) },
	-- "Bone Shield" 49222 "Bouclier dos" -- 1 min cd
	{49222 , not jps.buff(49822)},
	
	-- "Crimson Scourge" buff 81141 "Fléau cramoisi" -- Furoncle sanglant ou Mort et décomposition de ne pas consommer de runes.
	{"nested", jps.buff(81141) ,{
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		{ dk.spells["DeathAndDecay"] , EnemyCount > 2 },
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , EnemyCount < 2 },
	}},
	
	{"nested", jps.combatStart < 9 ,{
		{ dk.spells["OutBreak"] , not jps.myDebuff(55078) or not jps.myDebuff(55095) },
		{ dk.spells["DeathStrike"] , jps.myLastCast(50842) },
		{ dk.spells["BloodBoil"] , dk.rune("Dr") > 0 }, -- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["DeathStrike"] , not DepletedRunes },
	}},

	-- AGGRO
	{"nested", playerAggro and jps.hp() < 0.90 ,{
		-- "Icebound Fortitude" 48792 "Robustesse glaciale"
		{ dk.spells["Icebound"] , jps.hp() < 0.75 , "player" , "_Icebound" },
		-- "Stoneform" 20594 "Forme de pierre"
		{ 20594 , true , "player" , "_Stoneform" },
		-- "Remorseless Winter" 108200 "Hiver impitoyable"
		{ dk.spells["RemorselessWinter"] , jps.IsSpellInRange(49998) , "player" , "_Remorseless" },
		-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") , "target" , "_AntiMagic" },
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") , "focus" , "_AntiMagic" },
	}},

	-- "Army of the Dead" 42650 "Armée des morts"
	{dk.spells["ArmyoftheDead"] , IsLeftControlKeyDown() == true and GetCurrentKeyBoardFocus() == nil},
	-- INTERRUPTS
	{dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick() },
	{dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick("focus"), "focus" },
	{dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick() },
	{dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick("mouseover"), "mouseover" },
	{dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick("focus"), "focus" },
	{dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick()},
	{dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick("mouseover"), "mouseover"},
	{dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick("focus"), "focus"},
	-- Spell Steal
	{dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , "target"},
	{dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},

	-- DEFENSIVE COOLDOWNS
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.70 and jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
	-- "Death Pact" 48743 "Pacte mortel" -- - Heals the Death Knight for 50% of max health, and absorbs incoming healing equal to 25% of max health for 15 sec.
	{48743 , jps.hp() < 0.55 },
	-- "Lichborne" 49039 "Changeliche" -- vous rend insensible aux effets de charme, de peur et de sommeil pendant 10 s.
	{49039 , jps.hp() < 0.55 and jps.runicPower() > 40 },
	-- "Death Coil" 47541 "Voile mortel"
	{47541 , jps.hp() < 0.90 and jps.runicPower() > 40  },
	-- "Rune Tap" 48982 "Connexion runique" -- "Rune Tap" Buff 171049 -- Consomme 1 rune de sang pour réduire tous les dégâts subis de 40% pendant 3 s.
	{48982 , jps.hp() < 0.90 and not jps.buff(171049) },
	-- "Vampiric Blood" 55233 "Sang vampirique" -- Augmente le maximum de points de vie de 15% et les soins reçus de 15% pendant 10 s.
	{55233 , jps.hp() < 0.55 },
	--"Death Siphon" 108196 "Siphon mortel" -- moved here, because we heal often more with Death Strike than Death Siphon
	{dk.spells["DeathSiphon"] , jps.hp() < 0.60},

	-- RUNE MANAGEMENT
	--"BloodTap" 45529 -- "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 5 and AllDepletedRunes },
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and DepletedRunes },
	-- "Empower Rune Weapon" 47568 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.IsSpellInRange(49998,"target") and jps.runicPower() < 30 and AllDepletedRunes },

	-- DISEASES -- debuff Frost Fever 55095 -- debuff Blood Plague 55078
	--"Outbreak" 77575 "Poussée de fièvre" -- 30 yd range
	{dk.spells["OutBreak"] , jps.myDebuffDuration(55095) < 3 },
	{dk.spells["OutBreak"] , jps.myDebuffDuration(55078) < 3 },
	-- "Plague Strike" 45462 "Frappe de peste"
	{dk.spells["PlagueStrike"] , not jps.myDebuff(55078) },
	-- "Icy Touch" 45477
	{45477 , not jps.myDebuff(55095) },
	
	--MULTITARGET -- "Crimson Scourge" buff 81141 "Fléau cramoisi" -- Furoncle sanglant ou Mort et décomposition de ne pas consommer de runes.
	{"nested", jps.MultiTarget and EnemyCount > 2 ,{
		-- "Defile" 152280 "Profanation" -- 1 Unholy
		{ dk.spells["Defile"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		--{ dk.spells["DeathAndDecay"] , true },
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , dk.rune("Dr") > 0 },
		-- "Dancing Rune Weapon" 49028 "Arme runique dansante" -- Summons a second rune weapon for 8 sec granting an additional 20% parry chance.
		{49028 , true},

	}},

	-- ROTATION
	--"Soul Reaper" 130735 "Faucheur d’âme"
	{dk.spells["SoulReaper"] , jps.hp("target") < 0.35 },
	-- "Blood Boil" 50842 "Furoncle sanglant"
	{ dk.spells["BloodBoil"] , dk.rune("Dr") > 0 },
	-- "Death Strike" 49998 "Frappe de Mort" -- "Blood Shield" 77535 "Bouclier de sang"
	{dk.spells["DeathStrike"] , not jps.buff(77535) , "target" , "_DeathStrike_BloodShield" },
	{dk.spells["DeathStrike"] , not DepletedRunes , "target" , "_DeathStrike_Runes" },
	-- "Death Coil" 47541 "Voile mortel"
	{47541 , jps.runicPower() > 80 },
	{47541 , DepletedRunes },

}

	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "DK Blood Main")

-- [Rune Strike] has been removed. Blood death knights should now use [Death Coil] in its place.
-- [Heart Strike] has been removed. Blood death knights should use [Pestilence] in its place.
-- "Runic Strikes" 165394 "Frappes runiques" -- Passif -- Vous gagnez 5% de score de frappe multiple supplémentaire de toutes les sources
-- et les frappes multiples de vos attaques automatiques avec les armes à deux mains génèrent 15 points de puissance runique.


