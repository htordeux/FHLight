-- jps.Interrupts for Dispel
-- jps.Defensive changes the LowestImportantUnit to table = { "player","focus","target","mouseover" } with table.insert TankUnit  = jps.findTankInRaid()
-- jps.MultiTarget to DPSing

local L = MyLocalizationTable
local spellTable = {}
local parseDamage = {}
local parseControl = {}
local parseDispel = {}

local canDPS = jps.canDPS
local canHeal = jps.canHeal
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit

local POH = tostring(select(1,GetSpellInfo(596)))
local Hymn = tostring(select(1,GetSpellInfo(64843))) -- "Divine Hymn" 64843
local Serenity = tostring(select(1,GetSpellInfo(88684))) -- "Holy Word: Serenity" 88684
local Chastise = tostring(select(1,GetSpellInfo(88625))) -- Holy Word: Chastise 88625
local Santuary = tostring(select(1,GetSpellInfo(88685))) -- Holy Word: Sanctuary 88685

local ChakraSanctuary = tostring(select(1,GetSpellInfo(81206))) -- Chakra: Sanctuary 81206
local ChakraChastise = tostring(select(1,GetSpellInfo(81209))) -- Chakra: Chastise 81209
local ChakraSerenity = tostring(select(1,GetSpellInfo(81208))) -- Chakra: Serenity 81208

local sanctuaryPOH = "/cast "..ChakraSanctuary.."\n".."/cast "..POH
local sanctuaryHymn = "/cast "..ChakraSanctuary.."\n".."/cast "..Hymn
local macroSerenity = "/cast "..Serenity
local macroChastise = "/cast "..Chastise
local macroCancelaura = "/cancelaura "..ChakraSerenity.."\n".."/cancelaura "..ChakraSanctuary -- takes 1 GCD
local macroCancelauraChastise = macroCancelaura.."\n"..macroChastise -- takes 2 GCD

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

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION PVE ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

local priestHoly = function()

	local spell = nil
	local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus()
	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local countFriendNearby = jps.FriendNearby(12)
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	--local POHTarget, groupToHeal = jps.FindSubGroupTarget(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local CountFriendLowest = jps.CountInRaidLowest(0.80)
	local CountFriendEmergency = jps.CountInRaidLowest(0.50)

	local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
	local TankTarget = "target"
	if canHeal(Tank) then TankTarget = Tank.."target" end

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local playerTTD = jps.TimeToDie("player")
	local PlayerIsFacingLowest = jps.PlayerIsFacing(LowestImportantUnit,30)	-- angle value between 10-180

---------------------
-- ENEMY TARGET
---------------------

	local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS(TankTarget) then rangedTarget = TankTarget 
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	local playerIsTargeted = false
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if TargetCount > 0 then
			if UnitIsUnit(unit.."target","player") then
				playerIsTargeted = true
			break end
		end
	end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local MendingFriend = nil
	local MendingFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if priest.unitForMending(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingFriendHealth then
				MendingFriend = unit
				MendingFriendHealth = unitHP
			end
		end
	end
	
	-- priest.unitForLeap includes jps.FriendAggro and jps.LoseControl
	local LeapFriend = nil
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if priest.unitForLeap(unit) and jps.hp(unit) < 0.25 then 
			LeapFriend = unit -- if jps.RoleInRaid(unit) == "HEALER" then
		break end
	end
	
	local BindingHealFriend = nil
	local BindingHealFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if priest.unitForBinding(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < BindingHealFriendHealth then
				BindingHealFriend = unit
				BindingHealFriendHealth = unitHP
			end
		end
	end

	-- DISPEL --
	local DispelFriend = jps.FindMeDispelTarget( {"Magic"} ) -- {"Magic", "Poison", "Disease", "Curse"}

	local DispelFriendRole = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(TankUnit) do
		local unit = TankUnit[i]
		if jps.canDispel(unit,{"Magic"}) then
			DispelFriendRole = unit -- if jps.RoleInRaid(unit) == "HEALER" then
		break end
	end
	
	local RenewFriend = nil
	local RenewFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		local unitHP = jps.hp(unit)
		if not jps.buff(139,unit) and jps.FriendAggro(unit) then
			if unitHP < RenewFriendHealth then
				RenewFriend = unit
				RenewFriendHealth = unitHP
			end
		end
	end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local SilenceEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if jps.IsSpellInRange(15487,unit) then
			if jps.ShouldKick(unit) then
				SilenceEnemyTarget = unit
			break end
		end
	end

	local FearEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if priest.canFear(unit) and not jps.LoseControl(unit) then
			FearEnemyTarget = unit
		break end
	end

	local DispelOffensiveEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if jps.DispelOffensive(unit) and LowestImportantUnitHpct > 0.85 then
			DispelOffensiveEnemyTarget = unit
		break end
	end

------------------------
-- LOCAL TABLES
------------------------

	parseControl = {
		-- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
		{ 88625, not jps.buffId(81208) and not jps.buffId(81206) , rangedTarget  , "|cFFFF0000Chastise_NO_Chakra_" },
		{ 88625, jps.buffId(81209) , rangedTarget , "|cFFFF0000Chastise_Chakra_" },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelFriendRole) == "string" , DispelFriendRole , "|cff1eff00DispelFriendRole_MultiUnit_" },
		{ 527, type(DispelFriend) == "string" , DispelFriend , "|cff1eff00DispelFriend_MultiUnit_" },
	}
	
	parseDamage = {
		-- Chakra: Chastise 81209 -- Chakra: Sanctuary 81206 -- Chakra: Serenity 81208 -- Holy Word: Chastise 88625
		{ {"macro",macroCancelaura}, jps.checkTimer("Chastise") == 0 and canDPS(rangedTarget) and jps.buffId(81208) and jps.cooldown(81208) == 0 , "player"  , "Cancelaura_Chakra_" },
		-- Chakra: Chastise 81209
		{ 81209, not jps.buffId(81209) , "player" , "|cffa335eeChakra_Chastise" },
		-- "Chastise" 88625 -- Chakra: Chastise 81209
		{ 88625, jps.buffId(81209) , rangedTarget , "|cFFFF0000Chastise_" },
		-- "Flammes sacrées" 14914
		{ 14914, jps.buffId(81209) , rangedTarget },
		-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
		{ 129250, jps.buffId(81209) , rangedTarget },
		-- "Mot de l'ombre: Douleur" 589 -- FARMING OR PVP -- NOT PVE -- Only if 1 targeted enemy 
		{ 589, TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 and not IsInGroup() , rangedTarget  },
		-- "Châtiment" 585
		{ 585, jps.buffId(81209) and not jps.Moving , rangedTarget  },
	}
	
------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

	local InterruptTable = {
		{priest.Spell.FlashHeal, 0.75 , jps.buff(27827) }, -- "Esprit de rédemption" 27827
		{priest.Spell.Heal, 0.90 , jps.buff(27827) },
		{priest.Spell.PrayerOfHealing, 0.80, jps.buffId(81206) or jps.buff(27827) }, -- Chakra: Sanctuary 81206
	}

	-- AVOID OVERHEALING
	priest.ShouldInterruptCasting(InterruptTable , groupHealth , CountFriendLowest)

------------------------
-- SPELL TABLE ---------
------------------------
	
local spellTable = {

	-- "Esprit de rédemption" 27827
	{ "nested", jps.buff(27827) , 
		{
			-- "Divine Hymn" 64843
			{ 64843, AvgHealthLoss < 0.75  , "player" },
			-- "Prière de guérison" 33076 -- Buff POM 41635
			{ 33076, not jps.buffTracker(41635) , LowestImportantUnit },
			-- "Prayer of Healing" 596
			{ 596, (type(POHTarget) == "string") , POHTarget },
			-- "Circle of Healing" 34861
			{ 34861, AvgHealthLoss < 0.75 , LowestImportantUnit },
			-- "Soins rapides" 2061
			{ 2061, LowestImportantUnitHpct < 0.75 , LowestImportantUnit },
			-- "Renew" 139
			{ 139, type(RenewFriend) == "string" , RenewFriend },
		},
	},

	-- SNM "Chacun pour soi" 59752 "Every Man for Himself" -- Human
	{ 59752, playerIsStun , "player" , "Every_Man_for_Himself" },
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , "player" , "Trinket0"},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , "player" , "Trinket1"},

	-- "Guardian Spirit"
	{ 47788, playerIsStun and LowestImportantUnitHpct < 0.30 , LowestImportantUnit , "Guardian_" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.itemCooldown(5512) == 0 and jps.hp() < 0.75 , "player" , "Item5512" },
	-- "Prière du désespoir" 19236
	{ 19236, jps.IsSpellKnown(19236) and jps.hp() < 0.75 , "player" , "Aggro_DESESPERATE" },
	-- "Don des naaru" 59544
	{ 59544, jps.hp() < 0.75 , "player" , "Aggro_Naaru" },

	-- PLAYER AGGRO
	{ "nested", playerAggro or playerWasControl or playerIsTargeted ,{
		-- "Power Word: Shield" 17
		{ 17, jps.IsSpellKnown(64129) and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield" },
		-- "Spectral Guise" 112833 "Semblance spectrale"
		{ 112833, jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },
		-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même
		{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
		-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
		{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
		-- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
		{ 527, jps.canDispel("player",{"Magic"}) , "player" , "Aggro_Dispel" },
	}},

	-- "Leap of Faith" 73325 -- "Saut de foi"
	--{ 73325, type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
	-- "Soins rapides" 2061 -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and LowestImportantUnitHpct < 0.75 , LowestImportantUnit , "FlashHeal_Light_" },
	{ 2061, jps.buff(114255) and jps.buffDuration(114255) < 4 , LowestImportantUnit , "FlashHeal_Light_" },

	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace_" },
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes_" },

	-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
	{ 139, not jps.buff(139,Tank) , Tank , "Timer_Renew_Tank" },
	-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
	{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) and jps.myBuffDuration(139,Tank) < 2 , Tank , "Renew_Serenity_Tank" },
	{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) and jps.hp(Tank) < 0.80 , Tank , "Health_Serenity_Tank" },
	
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ "nested", not jps.Moving and not jps.buffTracker(41635) ,{
		{ 33076, canHeal(Tank) , Tank , "Tracker_Mending_Tank" },
		{ 33076, type(MendingFriend) == "string" , MendingFriend , "Tracker_Mending_Friend" },
		{ 33076, true , LowestImportantUnit , "Tracker_Mending_" },
	}},

	-- CHAKRA
	-- Chakra: Serenity 81208 -- "Holy Word: Serenity" 88684
	{ 81208, not jps.buffId(81208) , "player" , "|cffa335eeChakra_Serenity" },
	{ 81208, not jps.buffId(81208) and LowestImportantUnitHpct < 0.85 and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },
	{ 81208, not jps.buffId(81208) and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },

	-- "Infusion de puissance" 10060
	{ 10060, jps.combatStart > 0 and LowestImportantUnitHpct < 0.50 , "player" , "Emergency_POWERINFUSION" },
	
	-- GROUP HEAL
	-- "Circle of Healing" 34861
	{ 34861, CountInRange > 2 and AvgHealthLoss < 0.80 , LowestImportantUnit , "COH_" },
	-- "Cascade" Holy 121135 Shadow 127632
	{ 121135, not jps.Moving and CountInRange > 2 and AvgHealthLoss < 0.80 , LowestImportantUnit ,  "Cascade_" },
	{ "nested", not jps.Moving and (type(POHTarget) == "string") ,{
		-- "Prayer of Healing" 596 -- Chakra: Sanctuary 81206 -- increase 25 % Prayer of Mending, Circle of Healing, Divine Star, Cascade, Halo, Divine Hymn
		{ {"macro",sanctuaryPOH}, not jps.buffId(81206) and jps.cooldown(81206) == 0 and jps.cooldown(596) == 0 , POHTarget , "|cffa335eeSanctuary_POH"},
		{ 596, canHeal(POHTarget) , POHTarget },
	}},

	-- EMERGENCY HEAL -- "Serendipity" 63735
	{ "nested", LowestImportantUnitHpct < 0.50 ,{
		-- "Guardian Spirit" 47788
		{ 47788, LowestImportantUnitHpct < 0.30 , LowestImportantUnit , "Emergency_Guardian_" },
		-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
		{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , LowestImportantUnit , "Emergency_Serenity_" },
		-- "Power Word: Shield" 17 
		{ 17, LowestImportantUnitHpct < 0.30 and not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_" },
		-- "Soins supérieurs" 2060
		{ 2060,  jps.buffStacks(63735,"player") == 2 , LowestImportantUnit , "Emergency_Soins_"  },
		-- "Soins de lien"
		{ 32546 , priest.unitForBinding(LowestImportantUnit) , LowestImportantUnit , "Emergency_Lien_" },
		-- "Soins rapides" 2061
		{ 2061, true , LowestImportantUnit , "Emergency_FlashHeal_" },

	}},
	
	-- DISPEL -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
	{ "nested", jps.Interrupts , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,10) and jps.DispelOffensive(rangedTarget) and LowestImportantUnitHpct > 0.85 , rangedTarget , "|cff1eff00DispelOffensive_" },
	{ 528, jps.castEverySeconds(528,10) and type(DispelOffensiveEnemyTarget) == "string"  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },

	-- CONTROL --
	--{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit" },
	--{ "nested", not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },

	{ "nested", LowestImportantUnitHpct < 0.85 ,{
		-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
		{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , LowestImportantUnit , "Serenity_" },
		-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
		{ 139, not jps.buff(139,LowestImportantUnit) , LowestImportantUnit , "Renew_" },
		-- "Don des naaru" 59544
		{ 59544, true , LowestImportantUnit , "Naaru_" },
		-- "Soins supérieurs" 2060
		{ 2060,  jps.buffStacks(63735,"player") == 2 , LowestImportantUnit , "Buff_Soins_"  },
		-- "Soins de lien"
		{ 32546 , not jps.Moving and type(BindingHealFriend) == "string" , BindingHealFriend , "Lien_" },
		-- "Soins supérieurs" 2060
		{ 2060,  not jps.Moving , LowestImportantUnit , "Soins_"  },
	}},
	
	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- DAMAGE -- Chakra: Chastise 81209
	{ "nested", jps.MultiTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.85 , parseDamage },

	-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
	{ 139, type(RenewFriend) == "string" , RenewFriend , "Tracker_Renew_Friend" },
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	--{ 6346, not jps.buff(6346,"player") , "player" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","HOLY", priestHoly, "Holy Priest Default" )