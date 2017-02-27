local spells = jps.spells.priest

local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit

local Enemy = { "target", "focus" ,"mouseover" }

local fnNamePlateCount = function()
	return jps.NamePlateCount()
end
local fnCountInRange = function(pct)
	local Count, _, _ = jps.CountInRaidStatus(pct)
	return Count
end
local fnAvgHealthRaid = function()
	local _, AvgHealth, _ = jps.CountInRaidStatus()
	return AvgHealth
end

local playerHealth = function()
	return jps.hp("player")
end

local playerIsRecast = function(spell,unit)
	return jps.isRecast(spell,unit)
end

local playerDistance = function(unit)
	return jps.distanceMax(unit)
end

local playerInsanity = function()
	return jps.insanity()
end

local playerMoving = function()
	if select(1,GetUnitSpeed("player")) > 0 then return true end
	return false
end

local playerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local playerCanDPS = function(unit)
	return jps.canDPS(unit)
end

local playerHasBuff = function(spell)
	return jps.buff(spell,"player")
end

local playerBuffStacks = function(spell)
	return jps.buffStacks(spell)
end

local playerHasTalent = function(row,talent)
	return jps.hasTalent(row,talent)
end

local playerCanDispel = function(unit,dispel)
	return jps.canDispel(unit,dispel)
end

local playerOffensiveDispel = function(unit)
	return jps.DispelOffensive(unit)
end

local DispelDiseaseTarget = function()
	return jps.DispelDiseaseTarget()
end

------------------------------------------------

local targetDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"target")
end
local targetDebuff = function(spell)
	return jps.myDebuff(spell,"target")
end

------------------------------------------------

local focusDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"focus")
end
local focusDebuff = function(spell)
	return jps.myDebuff(spell,"focus")
end

------------------------------------------------

local mouseoverDebuffDuration = function(spell)
	return jps.myDebuffDuration(spell,"mouseover")
end
local mouseoverDebuff = function(spell)
	return jps.myDebuff(spell,"mouseover")
end

------------------------------------------------

local fnPainEnemyTarget = function(unit)
	if playerCanDPS(unit) and not jps.myDebuff(spells.shadowWordPain,unit) and not playerIsRecast(spells.shadowWordPain,unit) then
		return true end
	return false
end

local fnVampEnemyTarget = function(unit)
	if jps.Moving then return false end
	if playerCanDPS(unit) and not jps.myDebuff(spells.vampiricTouch,unit) and not playerIsRecast(spells.vampiricTouch,unit) then
		return true end
	return false
end

local PainEnemyTarget = function()
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if fnPainEnemyTarget(unit) then
			PainEnemyTarget = unit
		break end
	end
end

local VampEnemyTarget = function()
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if fnVampEnemyTarget(unit) then
			VampEnemyTarget = unit
		break end
	end
end

------------------------------------------------

local TargetMouseover = function()
	-- Config FOCUS with MOUSEOVER
	if not jps.UnitExists("focus") and (playerCanAttack("mouseover") or (playerCanDPS("mouseover") and jps.Defensive)) then
		if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
			jps.Macro("/focus mouseover") --print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
		elseif not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.shadowWordPain,"mouseover") then 
			jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
		elseif not UnitIsUnit("target","mouseover") and not jps.myDebuff(spells.vampiricTouch,"mouseover") then
			jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS not DEBUFF")
		elseif not UnitIsUnit("target","mouseover") then
			jps.Macro("/focus mouseover")
		end
	end
	if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
		jps.Macro("/clearfocus")
	elseif jps.UnitExists("focus") and not playerCanDPS("focus") then
		jps.Macro("/clearfocus")
	end
end

local FocusNamePlate = function()
	local NamePlateTable = jps.NamePlate()
	local NamePlateTarget = nil
	for unit,_ in pairs(NamePlateTable) do
		if playerCanAttack(unit) and not jps.myDebuff(spells.shadowWordPain,unit) and not jps.myDebuff(spells.vampiricTouch,unit) then
			NamePlateTarget = unit
		elseif playerCanDPS("mouseover") and jps.Defensive and not jps.myDebuff(spells.shadowWordPain,unit) and not jps.myDebuff(spells.vampiricTouch,unit) then
			NamePlateTarget = unit
		break end
	end
	if NamePlateTarget ~= nil and UnitIsUnit("mouseover",NamePlateTarget) then
		if jps.UnitExists("focus") and jps.myDebuffDuration(spells.vampiricTouch,"focus") > 12 and jps.myDebuffDuration(spells.shadowWordPain,"focus") > 9 then
			jps.Macro("/focus mouseover")
		elseif not jps.UnitExists("focus") then
			jps.Macro("/focus mouseover")
		end
	end
end

local VoidBoltTarget = function()
	local VoidBoltTarget = nil
	local VoidBoltTargetDuration = 24
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if jps.myDebuff(spells.shadowWordPain,unit) and jps.myDebuff(spells.vampiricTouch,unit) then
			local shadowWordPainDuration = jps.myDebuffDuration(spells.shadowWordPain,unit)
			local vampiricTouchDuration = jps.myDebuffDuration(spells.vampiricTouch,unit)
			local duration = math.min(shadowWordPainDuration,vampiricTouchDuration)
			if duration < VoidBoltTargetDuration then
				VoidBoltTargetDuration = shadowWordPainDuration
				VoidBoltTarget = unit
			end
		end
	end
	return VoidBoltTarget
end

local DeathEnemyTarget = function()
	local DeathEnemyTarget = nil
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if jps.hasTalent(4,2) and  jps.hp(unit) < 0.35 then
			DeathEnemyTarget = unit
		elseif jps.hp(unit) < 0.20 then
			DeathEnemyTarget = unit
		break end
	end
end

local TargetElite = function()
	if jps.targetIsBoss("target") then return true
	elseif jps.hp("target") > 0.50 then return true
	elseif string.find(GetUnitName("target"),"Mannequin") ~= nil then return true
	elseif fnNamePlateCount() > 3 then return true
	end
	return false
end

local DispelOffensiveTarget = function()
	local DispelOffensiveTarget = nil
	for i=1,#Enemy do -- for _,unit in ipairs(EnemyUnit) do
		local unit = Enemy[i]
		if playerOffensiveDispel(unit) then
			DispelOffensiveTarget = unit
		break end
	end
	return DispelOffensiveTarget
end


------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------
--jps.Defensive for "Levitate"
--jps.Defensive for DPS any mouseover
--jps.Interrupts for "Silence" et "Mind Bomb" et "Psychic Scream"
--jps.UseCDs for "Purify Disease"
--jps.MultiTarget for not stopcasting


jps.registerRotation("PRIEST","SHADOW",function()

TargetMouseover()
--FocusNamePlate()

local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local rangedTarget  = "target"
if playerCanDPS("target") then rangedTarget = "target"
elseif playerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif playerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif playerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if playerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end

if playerHasBuff(47585) then return end
if not playerCanDPS(rangedTarget) then return end

local spellTable = {

	-- "Dispersion" 47585
	{spells.dispersion, playerHealth() < 0.40 },
	{spells.fade, jps.PlayerIsTarget() },
	-- "Power Word: Shield" 17
	{spells.powerWordShield, playerMoving() and playerHasTalent(2,2) and not playerHasBuff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, playerHealth() < 0.80 and not playerHasBuff(194249) and not playerHasBuff(spells.powerWordShield) , "player" },
	-- "Pierre de soins" 5512
	{ "macro", playerHealth() < 0.70 and jps.useItem(5512) , "/use item:5512" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, playerHealth() < 0.60 , "player" },
	-- "Etreinte vampirique" buff 15286 -- pendant 15 sec, vous permet de rendre à un allié proche, un montant de points de vie égal à 40% des dégâts d’Ombre que vous infligez avec des sorts à cible unique
	{spells.vampiricEmbrace, playerHasBuff(194249) and playerHealth() < 0.50 },
	{spells.vampiricEmbrace, playerHasBuff(194249) and fnAvgHealthRaid() < 0.80 },

   	{spells.voidEruption, playerCanDPS("target") and not playerHasBuff(194249) and playerInsanity() > 65 and playerHasTalent(7,1) and TargetElite() },
	{spells.voidEruption, playerCanDPS("target") and not playerHasBuff(194249) and playerInsanity() == 100 and TargetElite() },

	{spells.powerInfusion, playerBuffStacks(194249) > 9 and playerInsanity() > 65 and TargetElite() },
	{spells.shadowfiend, playerBuffStacks(194249) > 9 , "target" },
	{spells.mindbender, playerBuffStacks(194249) > 9 , "target" },
	
	{"nested", playerHasBuff(194249) , {
		--{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, VoidBoltTarget() ~= nil , VoidBoltTarget },
		{spells.voidTorrent , not playerMoving() },
		{spells.shadowWordDeath, playerInsanity() < 85 , "target" },
		{spells.shadowWordDeath, playerInsanity() < 85 and DeathEnemyTarget() ~= nil , DeathEnemyTarget },
	}},

	{spells.shadowWordDeath, not playerHasBuff(194249) , "target" },
	{spells.shadowWordDeath, not playerHasBuff(194249) and DeathEnemyTarget() ~= nil , DeathEnemyTarget },

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not playerMoving() , "target"  },

	{spells.vampiricTouch, not playerMoving() and targetDebuffDuration(spells.vampiricTouch) < 4  and not playerIsRecast(spells.vampiricTouch,"target") , "target"  },
	{spells.shadowWordPain, targetDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"target") , "target" },
	
	{spells.shadowWordPain, playerCanAttack("mouseover") and mouseoverDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },
	{spells.shadowWordPain, jps.Defensive and mouseoverDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },
		
	{spells.vampiricTouch, not playerMoving() and focusDebuffDuration(spells.vampiricTouch) < 4 and not playerIsRecast(spells.vampiricTouch,"focus") , "focus"  },
	{spells.shadowWordPain, focusDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"focus") , "focus" },

	{spells.vampiricTouch, playerCanAttack("mouseover") and not playerMoving() and mouseoverDebuffDuration(spells.vampiricTouch) < 4 and not playerIsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.vampiricTouch, jps.Defensive and not playerMoving() and mouseoverDebuffDuration(spells.vampiricTouch) < 4 and not playerIsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },

	-- Mind Flay If the target is afflicted with Shadow Word: Pain you will also deal splash damage to nearby targets.
    {spells.mindFlay , not playerMoving() , "target"  },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end,"Simple Shadow Priest")

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

TargetMouseover()
--FocusNamePlate()

local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local rangedTarget  = "target"
if playerCanDPS("target") then rangedTarget = "target"
elseif playerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif playerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif playerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if playerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end

if playerHasBuff(47585) then return end
if not playerCanDPS(rangedTarget) then return end

local spellTable = {

	-- "Dispersion" 47585
	{spells.dispersion, playerHealth() < 0.40 },
	{spells.fade, jps.PlayerIsTarget() },
	-- "Power Word: Shield" 17
	{spells.powerWordShield, playerMoving() and playerHasTalent(2,2) and not playerHasBuff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, playerHealth() < 0.80 and not playerHasBuff(194249) and not playerHasBuff(spells.powerWordShield) , "player" },
	{spells.powerWordShield, jps.hp("mouseover") < 0.50 and not jps.buff(spells.powerWordShield,"mouseover") , "mouseover" },
	-- "Pierre de soins" 5512
	{ "macro", playerHealth() < 0.60 and jps.useItem(5512) , "/use item:5512" },
	-- "Don des naaru" 59544
	{spells.giftNaaru, playerHealth() < 0.70 , "player" },
	-- "Etreinte vampirique" buff 15286 -- pendant 15 sec, vous permet de rendre à un allié proche, un montant de points de vie égal à 40% des dégâts d’Ombre que vous infligez avec des sorts à cible unique
	{spells.vampiricEmbrace, playerHasBuff(194249) and playerHealth() < 0.50 },
	{spells.vampiricEmbrace, playerHasBuff(194249) and fnAvgHealthRaid() < 0.80 },

	-- "Purify Disease" 213634
	{"nested", jps.UseCDs , {
		{spells.purifyDisease, playerCanDispel("mouseover","Disease") , "mouseover" },
		{spells.purifyDisease, playerCanDispel("player","Disease") , "player" },
		{spells.purifyDisease, playerCanDispel(Tank,"Disease") , Tank },
		{spells.purifyDisease, DispelDiseaseTarget() ~= nil , DispelDiseaseTarget },
	}},

	{"nested", jps.Interrupts , {
		-- "Silence" 15487 -- debuff same ID
		{spells.silence,  not targetDebuff(226943) and jps.IsCasting("target") and playerDistance("target") < 30 , "target" },
		{spells.silence, not focusDebuff(226943) and jps.IsCasting("focus") and playerDistance("focus") < 30 , "focus" },
		-- "Mind Bomb" 205369 -- 30 yd range -- debuff "Explosion mentale" 226943
		{spells.mindBomb, jps.IsCasting("target") and playerDistance("target") < 30 , "target" },
		{spells.mindBomb, jps.IsCasting("focus") and playerDistance("focus") < 30 , "focus" },
		{spells.mindBomb, jps.MultiTarget , "target" },
		-- "Levitate" 1706
		{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not playerHasBuff(111759) , "player" },
		{ spells.levitate, jps.Defensive and IsSwimming() and not playerHasBuff(111759) , "player" },
	}},
	
	-- "Guérison de l’ombre" 186263 -- debuff "Shadow Mend" 187464 10 sec
	{spells.shadowMend, not playerMoving() and not playerHasBuff(194249) and playerHealth() < 0.60 and not playerHasBuff(15286) and jps.castEverySeconds(186263,4) , "player" },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ spells.dispelMagic, UnitIsPVP("player") and DispelOffensiveTarget() ~= nil and jps.castEverySeconds(528,4) , DispelOffensiveTarget , "|cff1eff00DispelOffensive" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	-- { "macro", jps.useTrinket(1) , "/use 14"},

    -- "Déferlante d’ombre" 205385
    {spells.shadowCrash, playerHasTalent(7,2) },

   	{spells.voidEruption, not playerMoving() and playerCanDPS("target") and not playerHasBuff(194249) and playerInsanity() > 65 and playerHasTalent(7,1) },
	{spells.voidEruption, not playerMoving() and playerCanDPS("target") and not playerHasBuff(194249) and playerInsanity() == 100 },

	{spells.powerInfusion, playerBuffStacks(194249) > 9 and playerInsanity() > 65 },
	{spells.shadowfiend, playerBuffStacks(194249) > 9 , "target" },
	{spells.mindbender, playerBuffStacks(194249) > 9 , "target" },
	
	{"nested", playerHasBuff(194249) , {
		--{"macro", jps.canCastvoidBolt , "/stopcasting" },
		{spells.voidEruption, VoidBoltTarget() ~= nil , VoidBoltTarget },
		{spells.voidTorrent , not playerMoving() },
		{spells.shadowWordDeath, playerInsanity() < 85 , "target" },
		{spells.shadowWordDeath, playerInsanity() < 85 and DeathEnemyTarget() ~= nil , DeathEnemyTarget },
	}},

	{spells.shadowWordDeath, not playerHasBuff(194249) , "target" },
	{spells.shadowWordDeath, not playerHasBuff(194249) and DeathEnemyTarget() ~= nil , DeathEnemyTarget },

	{"macro", jps.canCastMindBlast , "/stopcasting" },
	{spells.mindBlast, not playerMoving() , "target"  },

	{spells.vampiricTouch, not playerMoving() and targetDebuffDuration(spells.vampiricTouch) < 4  and not playerIsRecast(spells.vampiricTouch,"target") , "target"  },
	{spells.shadowWordPain, targetDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"target") , "target" },
	{spells.vampiricTouch, not playerMoving() and focusDebuffDuration(spells.vampiricTouch) < 4 and not playerIsRecast(spells.vampiricTouch,"focus") , "focus"  },
	{spells.shadowWordPain, focusDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"focus") , "focus" },

	{spells.vampiricTouch, playerCanAttack("mouseover") and not playerMoving() and mouseoverDebuffDuration(spells.vampiricTouch) < 4 and not playerIsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, playerCanAttack("mouseover") and mouseoverDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },
	{spells.vampiricTouch, jps.Defensive and not playerMoving() and mouseoverDebuffDuration(spells.vampiricTouch) < 4 and not playerIsRecast(spells.vampiricTouch,"mouseover") , "mouseover"  },
	{spells.shadowWordPain, jps.Defensive and mouseoverDebuffDuration(spells.shadowWordPain) < 4 and not playerIsRecast(spells.shadowWordPain,"mouseover") , "mouseover" },

	-- Mind Flay If the target is afflicted with Shadow Word: Pain you will also deal splash damage to nearby targets.
    {spells.mindFlay , not playerMoving() , "target"  },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end,"Shadow Priest")

--[[

#showtooltip Mot de l’ombre : Douleur
/cast [@mouseover,exists,nodead,harm][@target] Mot de l’ombre : Douleur

]]

--	"Dernier souffle d’Anund" buff 215210 (Brassards Legendaire) -- 15 secondes restantes
--	Chaque fois que Mot de l’ombre : Douleur et Toucher vampirique infligent des dégâts
--	Les dégâts de votre prochain Éclair de Vide sont augmentés de 2%, ce effet se cumulant jusqu’à 50 fois

--	Low Insanity coming up (Shadow Word: Death , Void Bolt , Mind Blast , AND Void Torrent are all on cooldown and you are in danger of reaching 0 Insanity).
--	{spells.dispersion, jps.hasTalent(6,3) and playerInsanity() > 21 and playerInsanity() < 71 and jps.cooldown(spells.mindbender) > 51 , "player" },

--	{spells.voidEruption, targetDebuffDuration(spells.shadowWordPain) > 0 and targetDebuffDuration(spells.shadowWordPain) < focusDebuffDuration(spells.shadowWordPain) and targetDebuffDuration(spells.shadowWordPain) < mouseoverDebuffDuration(spells.shadowWordPain) , "target" },
--	{spells.voidEruption, targetDebuffDuration(spells.vampiricTouch) > 0 and targetDebuffDuration(spells.vampiricTouch) < focusDebuffDuration(spells.vampiricTouch) and targetDebuffDuration(spells.vampiricTouch) < mouseoverDebuffDuration(spells.vampiricTouch) , "target" },
--	{spells.voidEruption, focusDebuffDuration(spells.shadowWordPain) >  0 and focusDebuffDuration(spells.shadowWordPain) < mouseoverDebuffDuration(spells.shadowWordPain) , "focus" },
--	{spells.voidEruption, focusDebuffDuration(spells.vampiricTouch) >  0 and focusDebuffDuration(spells.vampiricTouch) < mouseoverDebuffDuration(spells.vampiricTouch) , "focus" },
--	{spells.voidEruption, mouseoverDebuffDuration(spells.shadowWordPain) > 0 , "mouseover" },
--	{spells.voidEruption, mouseoverDebuffDuration(spells.vampiricTouch) > 0 , "mouseover" },

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

	local spell = nil
	local target = nil
	local Shield = jps.spells.priest.powerWordShield
	
	if IsMounted() then return end
	
	local spellTable = {
	
	-- "Shield" 17 "Body and Soul" 64129 "Corps et âme" -- Vitesse de déplacement augmentée de 40% -- buff 65081
	{ spells.powerWordShield, jps.Moving and not jps.buff(17,"player") and jps.hasTalent(2,2) , "player" , "Shield_BodySoul" },
	{ "macro", not jps.buff(65081) and jps.Moving and jps.buff(17) and jps.hasTalent(2,2) , "/cancelaura "..Shield },

	-- "Levitate" 1706
	{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not playerHasBuff(111759) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not playerHasBuff(111759) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, playerHealth() < 0.80 , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", not jps.buff(156079) and not jps.buff(188031) and jps.useItem(118922) , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Shadow Priest",false,true)
