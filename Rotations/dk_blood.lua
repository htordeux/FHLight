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
local combatTime = jps.combatTime() 

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

local DeathRuneCount = dk.updateRuneType()
local Dr,Fr,Ur = dk.updateRune()
local DepletedRunes = (Dr == 0) or (Fr == 0) or (Ur == 0)
local AllDepletedRunes = (Dr + Fr + Ur) == 0
local DeathStrikeRunes = (Fr + Ur > 1)
local BloodBoilRunes = (Dr > 0)

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
		-- "Blood Boil" 50842 "Furoncle sanglant" -- 1 Blood
		{ dk.spells["BloodBoil"] , BloodBoilRunes and EnemyCount < 2 },
	}},
	
	-- "Army of the Dead" 42650 "Armée des morts"
	{dk.spells["ArmyoftheDead"] , IsLeftControlKeyDown() == true and GetCurrentKeyBoardFocus() == nil},

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
	
	-- "Death Grip" 49576 "Poigne de la mort" -- "Death Strike" 49998 "Frappe de Mort"
	{ dk.spells["DeathGrip"] , combatTime > 5 and not jps.IsSpellInRange(49998,"target") },
	
	-- TRINKETS
	{ jps.useTrinket(0), playerAggro and jps.useTrinketBool(0) and jps.UseCDs},
	{ jps.useTrinket(1), playerAggro and jps.useTrinketBool(1) and jps.UseCDs},

	-- AGGRO
	{"nested", playerAggro ,{
		-- "Stoneform" 20594 "Forme de pierre"
		{ 20594 , jps.hp() < 0.90 , "player" , "_Stoneform" },
		-- "Icebound Fortitude" 48792 "Robustesse glaciale"
		{ dk.spells["Icebound"] , jps.hp() < 0.80 , "player" , "_Icebound" },
		-- "Remorseless Winter" 108200 "Hiver impitoyable"
		{ dk.spells["RemorselessWinter"] , jps.IsSpellInRange(49998) , "player" , "_Remorseless" },
		-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") , "target" , "_AntiMagic" },
		{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") , "focus" , "_AntiMagic" },

		-- "Vampiric Blood" 55233 "Sang vampirique" -- Augmente le maximum de points de vie de 15% et les soins reçus de 15% pendant 10 s.
		{dk.spells["VampiricBlood"] , jps.hp() < 0.40 , "target" , "_VampiricBlood" },
		-- "Pierre de soins" 5512
		{ {"macro","/use item:5512"}, jps.hp("player") < 0.70 and jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
		-- "Rune Tap" 48982 "Connexion runique" -- "Rune Tap" Buff 171049 -- Consomme 1 rune de sang pour réduire tous les dégâts subis de 40% pendant 3 s.
		{dk.spells["RuneTap"] , jps.hp() < 0.50 and not jps.buff(171049) },
		-- "Death Pact" 48743 "Pacte mortel" -- - Heals the Death Knight for 50% of max health, and absorbs incoming healing equal to 25% of max health for 15 sec.
		{dk.spells["DeathPact"] , jps.hp() < 0.50 , "target" , "_Death Pact" },
		-- "Death Siphon" 108196 "Siphon mortel" -- moved here, because we heal often more with Death Strike than Death Siphon
		{dk.spells["DeathSiphon"] , jps.hp() < 0.50 },
	}},
	
	-- RUNE MANAGEMENT
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech() and DepletedRunes },
	--"BloodTap" 45529 -- "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 5 and AllDepletedRunes },
	-- "Empower Rune Weapon" 47568 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.IsSpellInRange(49998,"target") and jps.runicPower() < 75 and AllDepletedRunes },
	
	-- "Death Coil" 47541 "Voile mortel"
	{dk.spells["DeathCoil"] , jps.runicPower() > 69 , "target" , "_DeathCoil_RunicPower" },
	-- "Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	{ dk.spells["OutBreak"] , not jps.myDebuff(55078) , "target" , "_OutBreak_Opening" },
	{ dk.spells["OutBreak"] , not jps.myDebuff(55095) , "target" , "_OutBreak_Opening" },
	-- "Soul Reaper" 130735 "Faucheur d’âme"
	{dk.spells["SoulReaper"] , jps.hp("target") < 0.35 , "target" , "_SoulReaper " },
	-- "Blood Boil" 50842 "Furoncle sanglant" -- 1 Blood
	{ dk.spells["BloodBoil"] , BloodBoilRunes , "target" , "_BloodBoil_Opening" },
	
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Scent of Blood" 50421 "Odeur du sang"
	{dk.spells["DeathStrike"] , DeathStrikeRunes and jps.buffStacks(50421) > 0 , "target" , "_DeathStrike_Opening" },
	-- "Blood Shield" 77535 "Bouclier de sang" 
	{dk.spells["DeathStrike"] , DeathStrikeRunes and not jps.buff(77535) , "target" , "_DeathStrike_BloodShield" },

	-- DISEASES -- debuff Frost Fever 55095 -- debuff Blood Plague 55078
	-- "Plague Strike" 45462 "Frappe de peste" -- 1 Unholy Rune
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078) },
	-- "Icy Touch" 45477 "Toucher de glace" -- 1 Frost Rune
	{ dk.spells["IcyTouch"] , not jps.myDebuff(55095) },

	-- MULTITARGET
	{"nested", jps.MultiTarget and EnemyCount > 2 ,{
		-- "Defile" 152280 "Profanation" -- 1 Unholy -- 30 s cd
		{ dk.spells["Defile"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		--{dk.spells["DeathAndDecay"] , true },
		-- "Blood Boil" 50842 "Furoncle sanglant" -- 1 Blood
		{ dk.spells["BloodBoil"] , BloodBoilRunes , "target" , "_BloodBoil_MultiTarget" },
		-- "Dancing Rune Weapon" 49028 "Arme runique dansante" -- Summons a second rune weapon for 8 sec granting an additional 20% parry chance.
		{ dk.spells["DancingRune"] , EnemyCount > 3 },

	}},

	-- ROTATION
	-- "Death Coil" 47541 "Voile mortel"
	{dk.spells["DeathCoil"] , AllDepletedRunes , "target" , "_DeathCoil_DepletedRunes" },
	-- "Death Strike" 49998 "Frappe de Mort" -- "Blood Shield" 77535 "Bouclier de sang" -- 1 Unholy, 1 Frost
	{dk.spells["DeathStrike"] , DeathStrikeRunes , "target" , "_DeathStrike_Runes" },
	-- "Blood Boil" 50842 "Furoncle sanglant"
	{ dk.spells["BloodBoil"] , BloodBoilRunes , "target" , "_BloodBoil_END" },

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


