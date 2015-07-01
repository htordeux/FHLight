local L = MyLocalizationTable
local canDPS = jps.canDPS
local canHeal = jps.canHeal
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
-------------------------------------------------- ROTATION PvE ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("DEATHKNIGHT","BLOOD",function()

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

local myTank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if canHeal(myTank) then TankTarget = myTank.."target" end

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
elseif canDPS(TankTarget) and not DebuffUnitCyclone(TankTarget) then rangedTarget = TankTarget 
elseif canDPS("targettarget") and not DebuffUnitCyclone("targettarget") then rangedTarget = "targettarget"
elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

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

local parseControl = {
	-- "Lichborne" 49039 "Changeliche" -- vous rend insensible aux effets de charme, de peur et de sommeil pendant 10 s.
	{ dk.spells["Lichborne"] , playerIsStun , "target" , "LICHBORNE" },
	--"Strangulate" 47476 "Strangulation" -- 30 yd range
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick("target") , "target" , "STRANGULATE" },
	{ dk.spells["Strangulate"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" , "STRANGULATE" },
	-- "Asphyxiate" 108194 "Asphyxier" -- 30 yd range
	{ dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick("target") , "target" , "ASPHYXIATE" },
	{ dk.spells["Asphyxiate"] , jps.Interrupts and jps.ShouldKick("focus") , "focus" , "ASPHYXIATE" },
	--"Mind Freeze" 47528 "Gel de l'esprit"
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick("target") , "target" , "MINDFREEZE" },
	{ dk.spells["MindFreeze"] , jps.Interrupts and jps.ShouldKick("focus"), "focus" , "MINDFREEZE" },
	-- "Dark Simulacrum" 77606 "Sombre simulacre"
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimTarget() , "target" , "DARKSIMULACRUM" },
	{ dk.spells["DarkSimulacrum"], dk.shouldDarkSimFocus() , "focus" , "DARKSIMULACRUM" },
	-- "Remorseless Winter" 108200 "Hiver impitoyable"
	{ dk.spells["RemorselessWinter"] , jps.combatStart > 0 and jps.IsSpellInRange(49998) , "target" , "Remorseless" },
	-- "Anti-Magic Shell" 48707 "Carapace anti-magie"
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("target") and jps.UnitIsUnit("targettarget","player") , "target" , "AntiMagic" },
	{ dk.spells["AntiMagicShell"] , jps.IsCasting("focus") and jps.UnitIsUnit("focustarget","player") , "focus" , "AntiMagic" },
}

local spellTable = {
	-- "BloodPresence" 48263 "Présence de sang"
	{ dk.spells["BloodPresence"] , not jps.buff(48263) },
	-- "Horn of Winter" 57330 "Cor de l’hiver"
	{ dk.spells["HornOfWinter"] , not jps.buff(57330) },
	-- "Bone Shield" 49222 "Bouclier dos" -- 1 min cd
	{ dk.spells["BoneShield"] , not jps.buff(49822) },

	-- "Army of the Dead" 42650 "Armée des morts"
	{ dk.spells["ArmyoftheDead"] , IsLeftControlKeyDown() },
	-- "Death Grip" 49576 "Poigne de la mort" -- "Death Strike" 49998 "Frappe de Mort"
	{ dk.spells["DeathGrip"] , jps.PvP and not jps.UnitIsUnit("targettarget","player") and not jps.IsSpellInRange(49998,"target") },
	-- "Chains of Ice" 45524 "Chaînes de glace"
	{ dk.spells["ChainsofIce"] , jps.PvP and TargetMoving and not jps.IsSpellInRange(49998,"target") },
	-- "Dark Command" 56222
	{ 56222 , IsInGroup() and not jps.UnitIsUnit("targettarget","player") , "target", "DarkCommand" },

	-- DISEASES -- debuff Frost Fever 55095 -- debuff Blood Plague 55078
	-- "Outbreak" 77575 "Poussée de fièvre" -- 30 yd range 
	{ dk.spells["OutBreak"] , jps.myBuffDuration(55078,"target") < 0 and not jps.isRecast(77575,"target") , "target" , "OutBreak" },
	{ dk.spells["OutBreak"] , jps.myBuffDuration(55095,"target") < 0 and not jps.isRecast(77575,"target") , "target" , "OutBreak" },
	-- "Plague Strike" 45462 "Frappe de peste" -- 1 Unholy Rune
	{ dk.spells["PlagueStrike"] , not jps.myDebuff(55078,"target") , "target" , "PlagueStrike" },
	-- "Icy Touch" 45477 "Toucher de glace" -- 1 Frost Rune
	{ dk.spells["IcyTouch"] , not jps.myDebuff(55095,"target") , "target" , "IcyTouch" },
	
	-- "Crimson Scourge" buff 81141 "Fléau cramoisi"--  your next Blood Boil or Death and Decay cost no runes.
	{ dk.spells["BloodBoil"] , jps.buff(81141) ,"target" , "BloodBoil_Buff" },
	-- "Soul Reaper" 130735 "Faucheur d’âme"
	{ dk.spells["SoulReaper"] , jps.hp("target") < 0.35 , "target" , "SoulReaper " },
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.UseCDs and jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 },
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 },
	-- CONTROL --
	{"nested", jps.combatStart > 0 , parseControl },
	
	-- RUNE MANAGEMENT --
	-- "Plague Leech" 123693 "Parasite de peste"
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech(9) and DepletedRunes , "target", "PlagueLeech" },
	{ dk.spells["PlagueLeech"] , dk.canCastPlagueLeech() and RuneCount == 0 , "target" , "|cff1eff00PlagueLeech_DepletedRunes" },
	--"BloodTap" 45529 -- "Drain sanglant" 114851
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 9 and DepletedRunes , "target", "BloodTap_9" },
	{ dk.spells["BloodTap"] , jps.buffStacks(114851) > 5 and RuneCount == 0 , "target", "BloodTap_5" },
	-- "Empower Rune Weapon" 47568 "Renforcer l'arme runique"
	{ dk.spells["EmpowerRuneWeapon"] , jps.IsSpellInRange(49998,"target") and RuneCount == 0 , "target", "EmpowerRuneWeapon" },

	-- HEALS --
	-- "Death Coil" 47541 "Voile mortel"
	{ dk.spells["DeathCoil"] , jps.runicPower() > 59 , "target" , "DeathCoil_RunicPower" },
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Unholy, 1 Frost -- "Blood Shield" 77535 "Bouclier de sang" -- jps.buffDuration(77535) max 9 sec
	{ dk.spells["DeathStrike"] , jps.hp() < 0.85 , "target" , "|cff1eff00DeathStrike_Health" },
	{ dk.spells["DeathStrike"] , jps.buffDuration(77735) < 2 , "target" , "|cff1eff00DeathStrike_Buff" },
	-- "Blood Boil" 50842 "Furoncle sanglant" -- 1 Blood -- refresh diseases to full duration
	-- "Scent of Blood" 50421 "Odeur du sang" -- jps.buffStacks(50421) max 5 -- increases the healing from your next Death Strike by 20% 
	{ dk.spells["BloodBoil"] , jps.buffStacks(50421) < 5 , "target" , "BloodBoil_Stacks" },
	-- "Rune Tap" 48982 "Connexion runique" -- "Rune Tap" Buff 171049 -- 1 Blood pour réduire tous les dégâts subis de 40% pendant 3 s.
	{ dk.spells["RuneTap"] , jps.combatStart > 0 and jps.hp() < 0.40 and not jps.buff(171049) , "target" , "RuneTap" },
	-- "Vampiric Blood" 55233 "Sang vampirique" -- Augmente le maximum de points de vie de 15% et les soins reçus de 15% pendant 10 s. from other healers and from Death Strike and Death Siphon.
	{ dk.spells["VampiricBlood"] , jps.hp() < 0.75 , "target" , "VampiricBlood" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.hp("player") < 0.75 and jps.itemCooldown(5512)==0 , "target" , "Item5512" },
	-- "Death Pact" 48743 "Pacte mortel" -- - Heals the Death Knight for 50% of max health, and absorbs incoming healing equal to 25% of max health for 15 sec.
	{ dk.spells["DeathPact"] , jps.hp() < 0.40 , "target" , "Death Pact" },
	-- "Death Siphon" 108196 "Siphon mortel"
	{ dk.spells["DeathSiphon"] , jps.hp() < 0.40 , "target" , "DeathSiphon" },
	-- "Stoneform" 20594 "Forme de pierre"
	{ warrior.spells["Stoneform"] , playerAggro and jps.hp() < 0.85 , "target" , "Stoneform" },
	{ warrior.spells["Stoneform"] , jps.canDispel("player",{"Magic","Poison","Disease","Curse"}) , "target" , "Stoneform" },
	-- "Icebound Fortitude" 48792 "Robustesse glaciale"
	{ dk.spells["Icebound"] , jps.combatStart > 0 and jps.hp("player") < 0.75 , "target" , "Icebound" },

	-- MULTITARGET
	-- "Defile" 152280 "Profanation" -- 1 Unholy
	{ dk.spells["Defile"] , IsControlKeyDown() },
	-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
	{ dk.spells["DeathAndDecay"], IsControlKeyDown() },

	{"nested", jps.MultiTarget and inMelee ,{
		-- "Crimson Scourge" buff 81141 "Fléau cramoisi"
		--  your next Blood Boil or Death and Decay cost no runes.
		-- "Death and Decay" 43265 "Mort et decomposition" -- 1 Unholy
		{ dk.spells["DeathAndDecay"] , jps.buff(81141) , "target" , "DeathAndDecay_MultiTarget" },
		-- "Defile" 152280 "Profanation" -- 1 Unholy -- 30 s cd
		{ dk.spells["Defile"] , true , "target" , "Defile_MultiTarget" },
		-- "Blood Boil" 50842 "Furoncle sanglant" -- 1 Blood
		{ dk.spells["BloodBoil"] , true , "target" , "BloodBoil_MultiTarget" },
		-- "Dancing Rune Weapon" 49028 "Arme runique dansante" -- Summons a second rune weapon for 8 sec granting an additional 20% parry chance.
		{ dk.spells["DancingRune"] , EnemyCount > 4 },

	}},
	
	-- "Death Coil" 47541 "Voile mortel"
	{ dk.spells["DeathCoil"] , jps.runicPower() > 29 , "target" , "DeathCoil" },

}
	spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "DK Blood Main")

