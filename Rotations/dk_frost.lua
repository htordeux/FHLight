local L = MyLocalizationTable
local canDPS = jps.canDPS
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat

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
	if not UnitAffectingCombat(unit) then return false end
	local Cyclone = false
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
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
		auraName = select(1,UnitDebuff(unit, i))
	end
	return Cyclone
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION 1H PvE ---------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("DEATHKNIGHT","FROST", function()

local spell = nil
local target = nil

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local inMelee = jps.IsSpellInRange(49998,"target") -- "Death Strike" 49998 "Frappe de Mort"

----------------------
-- TARGET ENEMY
----------------------

local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
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
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

-- Chains of Ice
local shouldChain = function()
	local _, classTarget, _ = UnitClass(rangedTarget)
	if classTarget == "DRUID" then return false end
	if classTarget == "PALADIN" then return false end
	if jps.buff(19263,rangedTarget) then return false end -- deterrence
	if jps.buff(1044,rangedTarget) then return false end -- hand of freedom
	if jps.debuff(45524) then return false end -- chains of ice
	--if chainCount(rangedTarget) > 1 then return false end -- track diminishing returns
return true
end

------------------------
-- UPDATE RUNES ---------
------------------------

local Dr,Fr,Ur = dk.updateRune()
local DepletedRunes = (Dr == 0) or (Fr == 0) or (Ur == 0)
local RuneCount = Dr + Fr + Ur
local DeathRuneCount = dk.updateDeathRune()
local CompletedRunes = (Dr > 0) and (Fr > 0) and (Ur > 0)
local RunesCD = 0
for i=1,6 do
	local cd = dk.runeCooldown(i)
	RunesCD = RunesCD + cd
end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "FrostPresence" 48266 "Présence de givre"
	{ dk.spells["FrostPresence"] , not jps.buff(dk.spells.FrostPresence) and jps.hp() > 0.50 , "player" },
	-- "Blood Presence" 48263 "Présence de sang" -- stamina + 20%, armor + 30%, damage - 10%
	{ dk.spells["BloodPresence"] , not jps.buff(dk.spells.BloodPresence) and jps.hpInc() < 0.50 and playerAggro , "player" },
	-- "Horn of Winter" 57330 "Cor de l’hiver" -- + 10% attack power
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells.HornOfWinter) , "player" },

	-- AGGRO --
	{ dk.spells["Icebound"] , playerAggro and jps.hp() < 0.75 , "player" , "_Icebound" },
	-- "Remorseless Winter" 108200 "Hiver impitoyable"
	{ dk.spells["RemorselessWinter"] , playerAggro , "player" , "_Remorseless" },
	-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") },
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") },	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and jps.hp() < 0.85 , rangedTarget , "_Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },

	-- CONTROL --
	-- "Lichborne" 49039 "Changeliche" -- vous rend insensible aux effets de charme, de peur et de sommeil pendant 10 s.
	{ dk.spells["Lichborne"] , playerIsStun , rangedTarget , "_Lichborne" },
	-- "Death Grip" 49576 "Poigne de la mort"
	{ dk.spells["DeathGrip"] , jps.PvP and not inMelee , rangedTarget },
	-- "Chains of Ice" 45524 "Chaînes de glace"
	{ dk.spells["ChainsOfIce"] , jps.PvP and TargetMoving and not inMelee and jps.cooldown(49576) > 0 , rangedTarget },
	-- "Icy Touch" 45477 "Toucher de glace" -- for use with Glyph of Icy Touch 43546
	{ dk.spells["IcyTouch"] , jps.glyphInfo(43546) and jps.castEverySeconds(45477,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
	-- "Icebound Fortitude" 48792 "Robustesse glaciale" -- The Death Knight freezes his blood to become immune to Stun effects and reduce all damage taken by 20% for 8 sec.
	{ dk.spells["Icebound"] , playerWasControl , "player" , "Stun_Icebound" },

	-- RUNE MANAGEMENT --
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and dk.Runes("DepletedRunes") and jps.cooldown(dk.spells.OutBreak) == 0 , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and dk.Runes("DepletedRunes") and jps.buff(59057) , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and dk.Runes("DepletedRunes") and jps.buff(59052) , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech() and dk.Runes("RuneCount") == 0 , rangedTarget , "|cff1eff00PlagueLeech_AllDepletedRunes" },

	-- "BloodTap" 45529 -- Buff "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and dk.Runes("DepletedRunes") , rangedTarget , "DrainSanglant_10" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 4 and dk.Runes("DepletedRunes") and jps.buff(152279) , rangedTarget , "|cff1eff00DrainSanglant_5_Sindragosa" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 4 and dk.Runes("DepletedRunes") and jps.buff(51124) , rangedTarget , "|cff1eff00DrainSanglant_5_Killing" },

	-- "Empower Rune Weapon" 47568 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.runicPower() < 76 and dk.Runes("RuneCount") == 0 , rangedTarget , "|cff1eff00EmpowerRuneWeapon" },
	{ dk.spells["EmpowerRuneWeapon"] , jps.buff(152279) and dk.Runes("RunesCD") > 50 , rangedTarget , "|cff1eff00EmpowerRuneWeapon_Sindragosa" },
	{ dk.spells["EmpowerRuneWeapon"] , jps.cooldown(152279) == 0 and dk.Runes("RunesCD") > 50 , rangedTarget , "|cff1eff00EmpowerRuneWeapon_Sindragosa" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.UseCDs and jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 },
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 },

	-- HEALS --	
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.75 and jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_DeathPact" },
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_DeathSiphon" },
	-- "Conversion" 119975
	{ dk.spells["Conversion"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_Conversion" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Dark Succor" 101568 "Sombre secours" -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	{ dk.spells["DeathStrike"] , jps.buff(101568) , rangedTarget, "|cff1eff00DeathStrike_Buff" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	{ dk.spells["DeathStrike"] , jps.hp() < 0.65 , rangedTarget, "|cff1eff00DeathStrike_Health" },

	-- KICK --
	-- "Dark Simulacrum" 77606 "Sombre simulacre"
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , "target" , "_DARKSIMULACRUM" },
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},
	{"nested", jps.Interrupts ,{
		-- Blood Elf "Arcane Torrent" 28730
		{ 28730, CheckInteractDistance(rangedTarget,3) == true and jps.ShouldKick(rangedTarget) , rangedTarget },
		-- Pandaren "Quaking Palm" 107079
		{ 107079, IsSpellInRange(107079,rangedTarget) and jps.ShouldKick(rangedTarget) , rangedTarget },
		-- Tauren "War Stomp" 20549 "Choc martial"
		{ 20549 , CheckInteractDistance(rangedTarget,3) == true and jps.ShouldKick(rangedTarget) , rangedTarget },
		--"Strangulate" 47476 "Strangulation" -- 30 yd range
		{ dk.spells["Strangulate"] , jps.ShouldKick(rangedTarget) , "_STRANGULATE" },
		{ dk.spells["Strangulate"] , jps.ShouldKick("focus") , "focus" },
		-- "Asphyxiate" 108194 "Asphyxier" -- 30 yd range
		{ dk.spells["Asphyxiate"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_ASPHYXIATE" },
		{ dk.spells["Asphyxiate"] , jps.ShouldKick("focus") , "focus" },
		--"Mind Freeze" 47528 "Gel de l'esprit"
		{ dk.spells["MindFreeze"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_MINDFREEZE" },
		{ dk.spells["MindFreeze"] , jps.ShouldKick("focus"), "focus" },
	}},

	-- "Pillar of Frost" 51271 "Pilier de givre" -- increases the Death Knight's Strength by 15%
	{ dk.spells["PillarOfFrost"] , jps.buff(51124) and not DepletedRunes , rangedTarget , "Pillar_Of_Frost" },
	{ dk.spells["PillarOfFrost"] , jps.runicPower() > 75 , rangedTarget , "Pillar_Of_Frost" },
	-- "Soul Reaper" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },

	-- DISEASES --
	--"Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55078,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) , rangedTarget },
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55095,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) , rangedTarget },
	-- "Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078 -- 1 Unholy
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,rangedTarget) and not jps.isRecast(45462,rangedTarget) , rangedTarget , "PlagueStrike_Debuff" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095 -- 1 Frost
	-- "Rime" 59057 "Frimas" -- Obliterate gives 45% chance to cause your next Howling Blast or Icy Touch to consume no runes.
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	{ dk.spells["HowlingBlast"] , jps.buff(59057) , rangedTarget , "HowlingBlast_Rime" },
	{ dk.spells["HowlingBlast"] , jps.buff(59052) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,rangedTarget) and not jps.isRecast(49184,rangedTarget) , rangedTarget , "HowlingBlast_Debuff" },

	-- "Breath of Sindragosa" 152279 "Souffle de Sindragosa"
	{ dk.spells["Sindragosa"] , jps.runicPower() > 75 and CompletedRunes and jps.cooldown(dk.spells.PlagueLeech) == 0, rangedTarget , "SINDRAGOSA" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	-- "Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["FrostStrike"] , jps.buff(51124) and not jps.buff(152279) , rangedTarget , "FrostStrike_KillingMachine" },
	{ dk.spells["FrostStrike"] , jps.runicPower() > 75 and not jps.buff(152279) , rangedTarget , "FrostStrike_RunicPower" },
	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost 
	-- "Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["Obliterate"] , dk.Runes("Ur") > 0 and jps.runicPower() < 76 , rangedTarget , "Obliterate_Ur" },
	{ dk.spells["Obliterate"] , jps.buff(51124) , rangedTarget , "Obliterate_KillingMachine" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , dk.Runes("Fr") > 0 , rangedTarget , "HowlingBlast_Fr" },
	
	-- MULTITARGET -- and EnemyCount > 2
	-- "Defile" 152280 "Profanation" -- 1 Unholy
	{ dk.spells["Defile"] , IsShiftKeyDown() },
	-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
	{ dk.spells["DeathAndDecay"], IsShiftKeyDown() },
	{"nested", jps.MultiTarget ,{
		-- "Defile" 152280 "Profanation" -- 1 Unholy
		{ dk.spells["Defile"] , true },
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		{ dk.spells["DeathAndDecay"] , true },
	}},

	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
	{ dk.spells["Obliterate"] ,  dk.Runes("DeathRuneCount") > 1 , rangedTarget , "Obliterate_Dr" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , dk.Runes("DeathRuneCount") > 0 , rangedTarget , "HowlingBlast_Dr" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	{ dk.spells["FrostStrike"] , jps.cooldown(152279) > 8 and jps.runicPower() > 25 , rangedTarget , "FrostStrike_RP" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target

end, "Frost 1H PvE", true, false)

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

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION 2H PvE ---------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("DEATHKNIGHT","FROST", function()

local spell = nil
local target = nil

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local inMelee = jps.IsSpellInRange(49998,"target") -- "Death Strike" 49998 "Frappe de Mort"

----------------------
-- TARGET ENEMY
----------------------

local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
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
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

-- Chains of Ice
local shouldChain = function()
	local _, classTarget, _ = UnitClass(rangedTarget)
	if classTarget == "DRUID" then return false end
	if classTarget == "PALADIN" then return false end
	if jps.buff(19263,rangedTarget) then return false end -- deterrence
	if jps.buff(1044,rangedTarget) then return false end -- hand of freedom
	if jps.debuff(45524) then return false end -- chains of ice
	--if chainCount(rangedTarget) > 1 then return false end -- track diminishing returns
return true
end

------------------------
-- UPDATE RUNES ---------
------------------------

local Dr,Fr,Ur = dk.updateRune()
local DepletedRunes = (Dr == 0) or (Fr == 0) or (Ur == 0)
local RuneCount = Dr + Fr + Ur
local DeathRuneCount = dk.updateDeathRune()
local CompletedRunes = (Dr > 0) and (Fr > 0) and (Ur > 0)
local RunesCD = 0
for i=1,6 do
	local cd = dk.runeCooldown(i)
	RunesCD = RunesCD + cd
end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "FrostPresence" 48266 "Présence de givre"
	{ dk.spells["FrostPresence"] , not jps.buff(dk.spells.FrostPresence) and jps.hp() > 0.50 , "player" },
	-- "Blood Presence" 48263 "Présence de sang" -- stamina + 20%, armor + 30%, damage - 10%
	{ dk.spells["BloodPresence"] , not jps.buff(dk.spells.BloodPresence) and jps.hpInc() < 0.50 and playerAggro , "player" },
	-- "Horn of Winter" 57330 "Cor de l’hiver" -- + 10% attack power
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells.HornOfWinter) , "player" },

	-- AGGRO --
	{ dk.spells["Icebound"] , playerAggro and jps.hp() < 0.75 , "player" , "_Icebound" },
	-- "Remorseless Winter" 108200 "Hiver impitoyable"
	{ dk.spells["RemorselessWinter"] , playerAggro , "player" , "_Remorseless" },
	-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") },
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") },	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and jps.hp() < 0.85 , rangedTarget , "_Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },

	-- CONTROL --
	-- "Lichborne" 49039 "Changeliche" -- vous rend insensible aux effets de charme, de peur et de sommeil pendant 10 s.
	{ dk.spells["Lichborne"] , playerIsStun , rangedTarget , "_Lichborne" },
	-- "Death Grip" 49576 "Poigne de la mort"
	{ dk.spells["DeathGrip"] , jps.PvP and not inMelee },
	-- "Chains of Ice" 45524 "Chaînes de glace"
	{ dk.spells["ChainsOfIce"] , jps.PvP and TargetMoving and not inMelee },
	-- "Icy Touch" 45477 "Toucher de glace" -- for use with Glyph of Icy Touch 43546
	{ dk.spells["IcyTouch"] , jps.glyphInfo(43546) and jps.castEverySeconds(45477,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
	-- "Icebound Fortitude" 48792 "Robustesse glaciale" -- The Death Knight freezes his blood to become immune to Stun effects and reduce all damage taken by 20% for 8 sec.
	{ dk.spells["Icebound"] , playerWasControl , "player" , "Stun_Icebound" },

	-- RUNE MANAGEMENT --
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and DepletedRunes and jps.cooldown(dk.spells.OutBreak) == 0 , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and DepletedRunes and jps.buff(59057) , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and DepletedRunes and jps.buff(59052) , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech() and RuneCount == 0 , rangedTarget , "|cff1eff00PlagueLeech_AllDepletedRunes" },

	-- "BloodTap" 45529 -- Buff "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes , rangedTarget , "DrainSanglant_10" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 4 and DepletedRunes and jps.buff(152279) , rangedTarget , "|cff1eff00DrainSanglant_5_Sindragosa" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 4 and DepletedRunes and jps.buff(51124) , rangedTarget , "|cff1eff00DrainSanglant_5_Killing" },

	-- "Empower Rune Weapon" 47568 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.runicPower() < 76 and RuneCount == 0 , rangedTarget , "|cff1eff00EmpowerRuneWeapon" },
	{ dk.spells["EmpowerRuneWeapon"] , jps.buff(152279) and RunesCD > 50 , rangedTarget , "|cff1eff00EmpowerRuneWeapon_Sindragosa" },
	{ dk.spells["EmpowerRuneWeapon"] , jps.cooldown(152279) == 0 and RunesCD > 50 , rangedTarget , "|cff1eff00EmpowerRuneWeapon_Sindragosa" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.UseCDs and jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 },
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 },

	-- HEALS --	
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.75 and jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_DeathPact" },
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_DeathSiphon" },
	-- "Conversion" 119975
	{ dk.spells["Conversion"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_Conversion" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Dark Succor" 101568 "Sombre secours" -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	{ dk.spells["DeathStrike"] , jps.buff(101568) , rangedTarget, "|cff1eff00DeathStrike_Buff" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	{ dk.spells["DeathStrike"] , jps.hp() < 0.65 , rangedTarget, "|cff1eff00DeathStrike_Health" },

	-- KICK --
	-- "Dark Simulacrum" 77606 "Sombre simulacre"
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , "target" , "_DARKSIMULACRUM" },
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},
	{"nested", jps.Interrupts ,{
		-- Blood Elf "Arcane Torrent" 28730
		{ 28730, CheckInteractDistance(rangedTarget,3) == true and jps.ShouldKick(rangedTarget) , rangedTarget },
		-- Pandaren "Quaking Palm" 107079
		{ 107079, IsSpellInRange(107079,rangedTarget) and jps.ShouldKick(rangedTarget) , rangedTarget },
		-- Tauren "War Stomp" 20549 "Choc martial"
		{ 20549 , CheckInteractDistance(rangedTarget,3) == true and jps.ShouldKick(rangedTarget) , rangedTarget },
		--"Strangulate" 47476 "Strangulation" -- 30 yd range
		{ dk.spells["Strangulate"] , jps.ShouldKick(rangedTarget) , "_STRANGULATE" },
		{ dk.spells["Strangulate"] , jps.ShouldKick("focus") , "focus" },
		-- "Asphyxiate" 108194 "Asphyxier" -- 30 yd range
		{ dk.spells["Asphyxiate"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_ASPHYXIATE" },
		{ dk.spells["Asphyxiate"] , jps.ShouldKick("focus") , "focus" },
		--"Mind Freeze" 47528 "Gel de l'esprit"
		{ dk.spells["MindFreeze"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_MINDFREEZE" },
		{ dk.spells["MindFreeze"] , jps.ShouldKick("focus"), "focus" },
	}},

	-- "Pillar of Frost" 51271 "Pilier de givre" -- increases the Death Knight's Strength by 15%
	{ dk.spells["PillarOfFrost"] , jps.buff(51124) and not DepletedRunes , rangedTarget , "Pillar_Of_Frost" },
	{ dk.spells["PillarOfFrost"] , jps.runicPower() > 75 , rangedTarget , "Pillar_Of_Frost" },
	-- "Soul Reaper" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },

	-- DISEASES --
	--"Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55078,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) , rangedTarget },
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55095,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) , rangedTarget },
	-- "Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078 -- 1 Unholy
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,rangedTarget) and not jps.isRecast(45462,rangedTarget) , rangedTarget , "PlagueStrike_Debuff" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095 -- 1 Frost
	-- "Rime" 59057 "Frimas" -- Obliterate gives 45% chance to cause your next Howling Blast or Icy Touch to consume no runes.
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	{ dk.spells["HowlingBlast"] , jps.buff(59057) , rangedTarget , "HowlingBlast_Rime" },
	{ dk.spells["HowlingBlast"] , jps.buff(59052) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,rangedTarget) and not jps.isRecast(49184,rangedTarget) , rangedTarget , "HowlingBlast_Debuff" },

	-- "Breath of Sindragosa" 152279 "Souffle de Sindragosa"
	{ dk.spells["Sindragosa"] , jps.runicPower() > 75 and CompletedRunes and jps.cooldown(dk.spells.PlagueLeech) == 0, rangedTarget , "SINDRAGOSA" },
	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost 
	-- "Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["Obliterate"] , jps.buff(51124) , rangedTarget , "Obliterate_KillingMachine" },
	{ dk.spells["Obliterate"] , Ur > 0 and jps.runicPower() < 76 , rangedTarget , "Obliterate_Ur" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	-- "Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["FrostStrike"] , jps.runicPower() > 75 and not jps.buff(152279) , rangedTarget , "FrostStrike_RunicPower" },
	{ dk.spells["FrostStrike"] , jps.buff(51124) and not jps.buff(152279) , rangedTarget , "FrostStrike_KillingMachine" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , Fr > 0 , rangedTarget , "HowlingBlast_Fr" },
	
	-- MULTITARGET -- and EnemyCount > 2
	-- "Defile" 152280 "Profanation" -- 1 Unholy
	{ dk.spells["Defile"] , IsShiftKeyDown() },
	-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
	{ dk.spells["DeathAndDecay"], IsShiftKeyDown() },
	{"nested", jps.MultiTarget ,{
		-- "Defile" 152280 "Profanation" -- 1 Unholy
		{ dk.spells["Defile"] , true },
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		{ dk.spells["DeathAndDecay"] , true },
	}},

	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
	{ dk.spells["Obliterate"] ,  DeathRuneCount > 1 , rangedTarget , "Obliterate_Dr" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , DeathRuneCount > 0 , rangedTarget , "HowlingBlast_Dr" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	{ dk.spells["FrostStrike"] , jps.cooldown(152279) > 8 and jps.runicPower() > 25 , rangedTarget , "FrostStrike_RP" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target

end, "Frost 2H PvE", true, false)

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION 2H PvP ---------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("DEATHKNIGHT","FROST", function()

local spell = nil
local target = nil

---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local inMelee = jps.IsSpellInRange(49998,"target") -- "Death Strike" 49998 "Frappe de Mort"

----------------------
-- TARGET ENEMY
----------------------

local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
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
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

-- Chains of Ice
local shouldChain = function()
	local _, classTarget, _ = UnitClass(rangedTarget)
	if classTarget == "DRUID" then return false end
	if classTarget == "PALADIN" then return false end
	if jps.buff(19263,rangedTarget) then return false end -- deterrence
	if jps.buff(1044,rangedTarget) then return false end -- hand of freedom
	if jps.debuff(45524) then return false end -- chains of ice
	--if chainCount(rangedTarget) > 1 then return false end -- track diminishing returns
return true
end

------------------------
-- UPDATE RUNES ---------
------------------------

local Dr,Fr,Ur = dk.updateRune()
local DepletedRunes = (Dr == 0) or (Fr == 0) or (Ur == 0)
local RuneCount = Dr + Fr + Ur
local DeathRuneCount = dk.updateDeathRune()
local CompletedRunes = (Dr > 0) and (Fr > 0) and (Ur > 0)
local RunesCD = 0
for i=1,6 do
	local cd = dk.runeCooldown(i)
	RunesCD = RunesCD + cd
end

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- "FrostPresence" 48266 "Présence de givre"
	{ dk.spells["FrostPresence"] , not jps.buff(dk.spells.FrostPresence) and jps.hp() > 0.50 , "player" },
	-- "Blood Presence" 48263 "Présence de sang" -- stamina + 20%, armor + 30%, damage - 10%
	{ dk.spells["BloodPresence"] , not jps.buff(dk.spells.BloodPresence) and jps.hpInc() < 0.50 and playerAggro , "player" },
	-- "Horn of Winter" 57330 "Cor de l’hiver" -- + 10% attack power
	{ dk.spells["HornOfWinter"] , not jps.buff(dk.spells.HornOfWinter) , "player" },

	-- AGGRO --
	{ dk.spells["Icebound"] , playerAggro and jps.hp() < 0.75 , "player" , "_Icebound" },
	-- "Remorseless Winter" 108200 "Hiver impitoyable"
	{ dk.spells["RemorselessWinter"] , playerAggro , "player" , "_Remorseless" },
	-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") },
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") },	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and jps.hp() < 0.85 , rangedTarget , "_Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , rangedTarget , "_Stoneform" },

	-- CONTROL --
	-- "Lichborne" 49039 "Changeliche" -- vous rend insensible aux effets de charme, de peur et de sommeil pendant 10 s.
	{ dk.spells["Lichborne"] , playerIsStun , rangedTarget , "_Lichborne" },
	-- "Death Grip" 49576 "Poigne de la mort"
	{ dk.spells["DeathGrip"] , jps.PvP and not inMelee },
	-- "Chains of Ice" 45524 "Chaînes de glace"
	{ dk.spells["ChainsOfIce"] , jps.PvP and TargetMoving and not inMelee },
	-- "Icy Touch" 45477 "Toucher de glace" -- for use with Glyph of Icy Touch 43546
	{ dk.spells["IcyTouch"] , jps.glyphInfo(43546) and jps.castEverySeconds(45477,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
	-- "Icebound Fortitude" 48792 "Robustesse glaciale" -- The Death Knight freezes his blood to become immune to Stun effects and reduce all damage taken by 20% for 8 sec.
	{ dk.spells["Icebound"] , playerWasControl , "player" , "Stun_Icebound" },

	-- RUNE MANAGEMENT --
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and DepletedRunes and jps.cooldown(dk.spells.OutBreak) == 0 , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and DepletedRunes and jps.buff(59057) , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(5) and DepletedRunes and jps.buff(59052) , rangedTarget , "|cff1eff00PlagueLeech_DepletedRunes" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech() and RuneCount == 0 , rangedTarget , "|cff1eff00PlagueLeech_AllDepletedRunes" },

	-- "BloodTap" 45529 -- Buff "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes , rangedTarget , "DrainSanglant_10" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 4 and DepletedRunes and jps.buff(152279) , rangedTarget , "|cff1eff00DrainSanglant_5_Sindragosa" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 4 and DepletedRunes and jps.buff(51124) , rangedTarget , "|cff1eff00DrainSanglant_5_Killing" },

	-- "Empower Rune Weapon" 47568 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.runicPower() < 76 and RuneCount == 0 , rangedTarget , "|cff1eff00EmpowerRuneWeapon" },
	{ dk.spells["EmpowerRuneWeapon"] , jps.buff(152279) and RunesCD > 50 , rangedTarget , "|cff1eff00EmpowerRuneWeapon_Sindragosa" },
	{ dk.spells["EmpowerRuneWeapon"] , jps.cooldown(152279) == 0 and RunesCD > 50 , rangedTarget , "|cff1eff00EmpowerRuneWeapon_Sindragosa" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.UseCDs and jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 },
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and playerIsStun },

	-- HEALS --	
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.75 and jps.itemCooldown(5512)==0 , "player" , "_Item5512" },
	-- "Death Pact" 48743 "Pacte mortel"
	{ dk.spells["DeathPact"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_DeathPact" },
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_DeathSiphon" },
	-- "Conversion" 119975
	{ dk.spells["Conversion"] , jps.UseCDs and jps.hp() < 0.55 , rangedTarget, "_Conversion" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	-- "Dark Succor" 101568 "Sombre secours" -- Your next Death Strike in Frost or Unholy Presence is free and its healing is increased by 100%.
	{ dk.spells["DeathStrike"] , jps.buff(101568) , rangedTarget, "|cff1eff00DeathStrike_Buff" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost
	{ dk.spells["DeathStrike"] , jps.hp() < 0.65 , rangedTarget, "|cff1eff00DeathStrike_Health" },

	-- KICK --
	-- "Dark Simulacrum" 77606 "Sombre simulacre"
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , "target" , "_DARKSIMULACRUM" },
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus"},
	{"nested", jps.Interrupts ,{
		-- Blood Elf "Arcane Torrent" 28730
		{ 28730, CheckInteractDistance(rangedTarget,3) == true and jps.ShouldKick(rangedTarget) , rangedTarget },
		-- Pandaren "Quaking Palm" 107079
		{ 107079, IsSpellInRange(107079,rangedTarget) and jps.ShouldKick(rangedTarget) , rangedTarget },
		-- Tauren "War Stomp" 20549 "Choc martial"
		{ 20549 , CheckInteractDistance(rangedTarget,3) == true and jps.ShouldKick(rangedTarget) , rangedTarget },
		--"Strangulate" 47476 "Strangulation" -- 30 yd range
		{ dk.spells["Strangulate"] , jps.ShouldKick(rangedTarget) , "_STRANGULATE" },
		{ dk.spells["Strangulate"] , jps.ShouldKick("focus") , "focus" },
		-- "Asphyxiate" 108194 "Asphyxier" -- 30 yd range
		{ dk.spells["Asphyxiate"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_ASPHYXIATE" },
		{ dk.spells["Asphyxiate"] , jps.ShouldKick("focus") , "focus" },
		--"Mind Freeze" 47528 "Gel de l'esprit"
		{ dk.spells["MindFreeze"] , jps.ShouldKick(rangedTarget) , rangedTarget , "_MINDFREEZE" },
		{ dk.spells["MindFreeze"] , jps.ShouldKick("focus"), "focus" },
	}},

	-- "Pillar of Frost" 51271 "Pilier de givre" -- increases the Death Knight's Strength by 15%
	{ dk.spells["PillarOfFrost"] , jps.buff(51124) and not DepletedRunes , rangedTarget , "Pillar_Of_Frost" },
	{ dk.spells["PillarOfFrost"] , jps.runicPower() > 75 , rangedTarget , "Pillar_Of_Frost" },
	-- "Soul Reaper" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },

	-- DISEASES --
	--"Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55078,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) , rangedTarget },
	{ dk.spells["OutBreak"] , jps.myDebuffDuration(55095,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) , rangedTarget },
	-- "Plague Strike" 45462 "Frappe de peste" -- gives debuff Blood Plague 55078 -- 1 Unholy
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,rangedTarget) and not jps.isRecast(45462,rangedTarget) , rangedTarget , "PlagueStrike_Debuff" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- gives debuff Frost Fever 55095 -- 1 Frost
	-- "Rime" 59057 "Frimas" -- Obliterate gives 45% chance to cause your next Howling Blast or Icy Touch to consume no runes.
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	{ dk.spells["HowlingBlast"] , jps.buff(59057) , rangedTarget , "HowlingBlast_Rime" },
	{ dk.spells["HowlingBlast"] , jps.buff(59052) , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , not jps.myDebuff(55095,rangedTarget) and not jps.isRecast(49184,rangedTarget) , rangedTarget , "HowlingBlast_Debuff" },

	-- "Breath of Sindragosa" 152279 "Souffle de Sindragosa"
	{ dk.spells["Sindragosa"] , jps.runicPower() > 75 and CompletedRunes and jps.cooldown(dk.spells.PlagueLeech) == 0, rangedTarget , "SINDRAGOSA" },
	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost 
	-- "Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["Obliterate"] , jps.buff(51124) , rangedTarget , "Obliterate_KillingMachine" },
	{ dk.spells["Obliterate"] , Ur > 0 and jps.runicPower() < 76 , rangedTarget , "Obliterate_Ur" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	-- "Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	{ dk.spells["FrostStrike"] , jps.runicPower() > 75 and not jps.buff(152279) , rangedTarget , "FrostStrike_RunicPower" },
	{ dk.spells["FrostStrike"] , jps.buff(51124) and not jps.buff(152279) , rangedTarget , "FrostStrike_KillingMachine" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , Fr > 0 , rangedTarget , "HowlingBlast_Fr" },
	
	-- MULTITARGET -- and EnemyCount > 2
	-- "Defile" 152280 "Profanation" -- 1 Unholy
	{ dk.spells["Defile"] , IsShiftKeyDown() },
	-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
	{ dk.spells["DeathAndDecay"], IsShiftKeyDown() },
	{"nested", jps.MultiTarget ,{
		-- "Defile" 152280 "Profanation" -- 1 Unholy
		{ dk.spells["Defile"] , true },
		-- "Blood Boil" 50842 "Furoncle sanglant"
		{ dk.spells["BloodBoil"] , true },
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		{ dk.spells["DeathAndDecay"] , true },
	}},
	
	-- COUNTERS, TALENTED -- { "CC" , "Snare" , "Root" , "Silence" , "Immune", "ImmuneSpell", "Disarm" }
	-- "Desecrated Ground" 108201 "Terre profanée" -- immune to/removes roots, snares, and loss of control
	{ dk.spells["DesecratedGround"] , jps.Moving and jps.LoseControl("player",{"Root"}) },
	{ dk.spells["DesecratedGround"] , jps.Moving and jps.LoseControl("player",{"Snare"}) },
	{ dk.spells["DesecratedGround"] , playerIsStun and not jps.LoseControl("player",{"Silence"}) },
	-- "Lichborne" 49039 "Changeliche"
	{ dk.spells["Lichborne"] , jps.debuff("psychic scream","player") }, -- Fear
	{ dk.spells["Lichborne"] , jps.debuff("fear","player") }, -- Fear
	{ dk.spells["Lichborne"] , jps.debuff("intimidating shout","player") }, -- Fear
	{ dk.spells["Lichborne"] , jps.debuff("howl of terror","player") }, -- Fear
	{ dk.spells["Lichborne"] , jps.debuff("mind control","player") }, -- Charm
	{ dk.spells["Lichborne"] , jps.debuff("seduction","player") }, -- Charm
	{ dk.spells["Lichborne"] , jps.debuff("wyvern sting","player") }, -- Sleep

	-- COUNTERS, RACIAL -- transfers 30s cd to trinket
	{"nested", jps.UseCDs ,{
		-- Dwarf "Stoneform" 20594 Removes all poison, disease, curse, magic, and bleed effects and reduces all physical damage taken by 10% for 8 sec.
		-->{ 20594, jps.hp() < 0.50 and playerAggro },
		-- Gnome "Escape Artist" 20589
		-->{ 20589, jps.LoseControl("player",{"Snare"}) and jps.UseCDs },
		-->{ 20589, jps.LoseControl("player",{"Root"}) and jps.UseCDs },
		-- Undead "Will of the Forsaken" 7744
		{ 7744, jps.debuff("psychic scream","player") }, -- Fear
		{ 7744, jps.debuff("fear","player") }, -- Fear
		{ 7744, jps.debuff("intimidating shout","player") }, -- Fear
		{ 7744, jps.debuff("howl of terror","player") }, -- Fear
		{ 7744, jps.debuff("mind control","player") }, -- Charm
		{ 7744, jps.debuff("seduction","player") }, -- Charm
		{ 7744, jps.debuff("wyvern sting","player") }, -- Sleep
	}},

	-- COUNTERS, ABILITIES -- icebound as last resort on Stun
	-- "Icebound Fortitude" 48792 "Robustesse glaciale"
	{ dk.spells["Icebound"] , playerWasControl , "player" , "Stun_Icebound" },

	--"Soul Reaper" 130735 "Faucheur d’âme"
	--{ dk.spells["SoulReaper"] , dk.timeToReap() , rangedTarget , "_SoulReaper" },
		-- Use pre-emptively @ 5 sec before proc @ <= 35% health
		-- Need dk.lua dk.timeToReap function with formula
	{ dk.spells["SoulReaper"] , jps.hp(rangedTarget) < 0.35 , rangedTarget , "_SoulReaper" },

	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
	{ dk.spells["Obliterate"] ,  DeathRuneCount > 1 , rangedTarget , "Obliterate_Dr" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , DeathRuneCount > 0 , rangedTarget , "HowlingBlast_Dr" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	{ dk.spells["FrostStrike"] , jps.cooldown(152279) > 8 and jps.runicPower() > 25 , rangedTarget , "FrostStrike_RP" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target

end, "Frost 2H PvP", false, true)

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION STATIC TABLE ---------------------------------------
----------------------------------------------------------------------------------------------------------------

dk.player = {}
dk.player.aggro = jps.FriendAggro("player")

jps.registerStaticTable("DEATHKNIGHT","FROST",
{

	-- "FrostPresence" 48266 "Présence de givre"
	{ dk.spells["FrostPresence"] , ' not jps.buff(dk.spells.FrostPresence) and jps.hp() > 0.50 ' , "player" },
	-- "Blood Presence" 48263 "Présence de sang" -- stamina + 20%, armor + 30%, damage - 10%
	{ dk.spells["BloodPresence"] , ' dk.player.aggro and not jps.buff(dk.spells.BloodPresence) and jps.hpInc() < 0.50 ' , "player" },
	-- "Horn of Winter" 57330 "Cor de l’hiver" -- + 10% attack power
	{ dk.spells["HornOfWinter"] , ' not jps.buff(dk.spells.HornOfWinter) ' , "player" },

	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , ' dk.Runes("DepletedRunes") ' , rangedTarget , "|cff1eff00PlagueLeech_AllDepletedRunes" },
	-- "BloodTap" 45529 -- Buff "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , ' jps.buffStacks(114851) > 9 and dk.Runes("DepletedRunes") ' , rangedTarget , "DrainSanglant_10" },
	
	--"Outbreak" 77575 "Poussée de fièvre"
	{ dk.spells["OutBreak"] , ' jps.myDebuffDuration(55078,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) ' , rangedTarget },
	{ dk.spells["OutBreak"] , ' jps.myDebuffDuration(55095,rangedTarget) < 5 and not jps.isRecast(77575,rangedTarget) ' , rangedTarget },
	-- "Howling Blast" 49184 "Rafale hurlante" 
	{ dk.spells["HowlingBlast"] , ' jps.buff(59057) ' , rangedTarget , "HowlingBlast_Rime" },
	{ dk.spells["HowlingBlast"] , ' jps.buff(59052) ' , rangedTarget , "HowlingBlast_FreezingFog" },
	{ dk.spells["HowlingBlast"] , ' not jps.myDebuff(55095,rangedTarget) and not jps.isRecast(49184,rangedTarget) ' , rangedTarget , "HowlingBlast_Debuff" },
	-- "Plague Strike" 45462 "Frappe de peste"
	{ dk.spells["PlagueStrike"] , ' not jps.myDebuff(55078,rangedTarget) and not jps.isRecast(45462,rangedTarget) ' , rangedTarget , "PlagueStrike_Debuff" },

	-- "Pillar of Frost" 51271 "Pilier de givre"
	{ dk.spells["PillarOfFrost"] , ' true ' , rangedTarget , "Pillar_Of_Frost" },
	-- "Killing Machine" 51124 "Machine à tuer" -- next Obliterate or Frost Strike automatically critically strike.
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	{ dk.spells["Obliterate"] , ' jps.buff(dk.spells.KillingMachine) ' , rangedTarget , "Obliterate_KillingMachine" },
	{ dk.spells["FrostStrike"] , ' jps.buff(dk.spells.KillingMachine) ' , rangedTarget , "FrostStrike_KillingMachine" },
	
	-- "Breath of Sindragosa" 152279 "Souffle de Sindragosa"
	{ dk.spells["Sindragosa"] , ' jps.runicPower() > 74 ' , rangedTarget , "Breath_Sindragosa" },
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	{ dk.spells["FrostStrike"] , ' jps.runicPower() > 74 and jps.cooldown(152279) > 0 ' , rangedTarget , "FrostStrike_RunicPower" },
	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost
	{ dk.spells["Obliterate"] , ' dk.Runes("Ur") > 0 and jps.runicPower() < 76 ' , rangedTarget , "Obliterate_Ur" },
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 Frost -- 30 yd range
	{ dk.spells["HowlingBlast"] , ' dk.Runes("Fr") > 0 ' , rangedTarget , "HowlingBlast_Fr" },
	
}
, "Frost Static")
