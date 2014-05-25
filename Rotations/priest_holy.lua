local L = MyLocalizationTable
local spellTable = {}
local parseMoving = {}
local parseControl = {}
local parseDispel = {}

local UnitIsUnit = UnitIsUnit
local canDPS = jps.canDPS
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local ipairs = ipairs

local iceblock = tostring(select(1,GetSpellInfo(45438))) -- ice block mage
local divineshield = tostring(select(1,GetSpellInfo(642))) -- divine shield paladin


	local ChakraSanctuary = tostring(select(1,GetSpellInfo(81206))) -- Chakra: Sanctuary 81206
	local POH = tostring(select(1,GetSpellInfo(596)))
	local Hymn = tostring(select(1,GetSpellInfo(64843))) -- "Divine Hymn" 64843
	
	local Chastise = tostring(select(1,GetSpellInfo(88625))) -- Holy Word: Chastise 88625
	local ChakraChastise = tostring(select(1,GetSpellInfo(81209))) -- Chakra: Chastise 81209
	local sanctuaryPOH = "/cast "..ChakraSanctuary.."\n".."/cast "..POH
	local sanctuaryHymn = "/cast "..ChakraSanctuary.."\n".."/cast "..Hymn
	local macroChastise = "/cast "..ChakraChastise.."\n".."/cast "..Chastise

----------------------------
-- ROTATION
----------------------------

local priestHoly = function()

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------
	local spell = nil
	local target = nil

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
	
	local timerShield = jps.checkTimer("ShieldTimer")
	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER
	local playerIsInterrupt = jps.checkTimer("PlayerInterrupt")

	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHealth = jps.hp(LowestImportantUnit,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local stackSerendip = jps.buffStacks(63735,"player")
	
	----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local ShieldTarget = nil
	local ShieldTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldTargetHealth then
				ShieldTarget = unit
				ShieldTargetHealth = unitHP
			end
		end
	end

	local MendingTarget = nil
	local MendingTargetHealth = 1
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForMending(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingTargetHealth then
				MendingTarget = unit
				MendingTargetHealth = unitHP
			end
		end
	end
	
	local BindingHealTarget = nil
	local BindingHealTargetHealth = 1
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForBinding(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < BindingHealTargetHealth then
				BindingHealTarget = unit
				BindingHealTargetHealth = unitHP
			end
		end
	end
	
	-- {"Magic", "Poison", "Disease", "Curse"}
	--local DispelTarget = jps.FindMeDispelTarget( {"Magic"} )

	local DispelTargetRole = nil
	for _,unit in ipairs(FriendUnit) do 
		local role = UnitGroupRolesAssigned(unit)
		if role == "HEALER" and jps.canDispel(unit,{"Magic"}) then
			DispelTargetRole = unit
		end
	end

	local DispelFriendlyTarget = nil
	local DispelFriendlyTargetHealth = 1
	for _,unit in ipairs(FriendUnit) do 
		if jps.DispelFriendly(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < DispelFriendlyTargetHealth then
				DispelFriendlyTarget = unit
				DispelFriendlyTargetHealth = unitHP
			end
		end
	end

	local LeapFriend = nil
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForLeap(unit) and jps.FriendAggro(unit) then 
			LeapFriend = unit
		break end
	end

---------------------
-- ENEMY TARGET
---------------------

	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget() -- returns "target" by default

	if jps.UnitExists("mouseover") and not jps.UnitExists("focus") then
		if jps.RoleClass("mouseover") == "HEALER" then
			jps.Macro("/focus mouseover")
		elseif jps.UnitIsUnit("mouseovertarget","player") then
			jps.Macro("/focus mouseover")
		end
	end
	if not canDPS("focus") then jps.Macro("/clearfocus") end
	
	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") then rangedTarget = "mouseover"
	end

	if not jps.canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local DeathEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canShadowWordDeath(unit) then 
			DeathEnemyTarget = unit
		break end
	end
	
	local FearEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canFear(unit) and not jps.LoseControl(unit) then 
			FearEnemyTarget = unit
		break end
	end
	
	local MassDispellTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if jps.buff(divineshield,unit) then
			MassDispellTarget = unit
			jps.Macro("/target "..MassDispellTarget)
			table.insert(jps.MessageInfo,1,{true,"PALADIN"})
		break end
	end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- STOPCASTING
----------------------------------------------------------

local InterruptTable = {
	{priest.Spell.flashHeal, 0.75, false },
	{priest.Spell.greaterHeal, 0.95, false },
	{priest.Spell.heal, 1 , false},
	{priest.Spell.prayerOfHealing, 0.85, jps.MultiTarget or jps.buffId(81206)}
}

-- Avoid interrupt Channeling
	if jps.ChannelTimeLeft() > 0 then return nil end
-- Avoid Overhealing
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss ,  CountInRange )
	
---------------------
-- ENEMY TARGET
---------------------

	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget() -- returns "target" by default
	-- set focus a senemy healer or enemy targeting you
	if jps.UnitExists("mouseover") and not jps.UnitExists("focus") then
		if jps.RoleClass("mouseover") == "HEALER" then
			jps.Macro("/focus mouseover")
		elseif jps.UnitIsUnit("mouseovertarget","player") then
			jps.Macro("/focus mouseover")
		end
	end
	if not canDPS("focus") then jps.Macro("/clearfocus") end
	
	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not jps.canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
------------------------
-- LOCAL TABLES
------------------------

	parseMoving = {
		-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208 
		{ 88684, jps.buffId(81208) and LowestImportantUnitHealth > priest.AvgAmountFlashHeal , LowestImportantUnit, "Move_Penance_"..LowestImportantUnit },
		-- "Prière de guérison" 33076 -- buff 4P pvp aug. 50% soins -- "Holy Spark" 131567 "Etincelle sacrée"
		{ 33076, (type(MendingTarget) == "string") , MendingTarget , "Move_MendingTarget" },
		-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
		{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
		{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
		-- "Circle of Healing"
		{ 34861, CountInRange > 2 and AvgHealthLoss < 0.85 , LowestImportantUnit },
		-- "Don des naaru" 59544
		{ 59544, (select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "Move_Naaru_"..LowestImportantUnit },
		-- "Rénovation" 139 -- debuff "Ame affaiblie" 6788 -- "Prière de guérison" 33076  on CD
		{ 139, not jps.buff(139,LowestImportantUnit) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "Move_Renew_"..LowestImportantUnit },
		-- "Feu intérieur" 588 -- "Volonté intérieure" 73413
		{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player") , "player", "Move_InnerFire" },
	}
	
	parseControl = {
		-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
		{ 6346, not jps.buff(6346,"player") , "player" },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
		{ 8122, type(FearEnemyTarget) == "string" , FearEnemyTarget , "Fear_MultiUnit_" },
		-- "Psyfiend" 108921 Démon psychique
		{ 108921, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },

	}
	
	parseDispel = {
		-- "Leap of Faith" 73325 -- "Saut de foi"
		{ 73325 , type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelTargetRole) == "string" , DispelTargetRole , "|cff1eff00DispelTargetRole_MultiUnit_" },
		{ 527, type(DispelFriendlyTarget) == "string" , DispelFriendlyTarget , "|cff1eff00DispelFriendlyTarget_MultiUnit_" },
	}

------------------------
-- SPELL TABLE ---------
------------------------
	
local spellTable = {

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and playerIsStun , "player" },
	-- "Soins rapides" 2061 "From Darkness, Comes Light" 109186 gives buff -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	{ 2061, jps.buff(114255) and (jps.buffDuration(114255) < 4) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	-- "Void Shift" 108968 -- "Prière du désespoir" 19236
	{ 108968, not playerAggro and UnitIsUnit(LowestImportantUnit,"player")~=1 and LowestImportantUnitHpct < 0.40 and jps.hp("player") > 0.85 , LowestImportantUnit , "Emergency_VoidShift_"..LowestImportantUnit },
	{ 108968, jps.cooldown(19236) == 0 and UnitIsUnit(LowestImportantUnit,"player")~=1 and LowestImportantUnitHpct < 0.40 and jps.hp("player") > 0.85 , LowestImportantUnit , "Emergency_VoidShift_"..LowestImportantUnit },
	-- "Guardian Spirit"
	{ 47788, LowestImportantUnitHpct < 0.40 , LowestImportantUnit },
	
	-- "Spectral Guise" -- "Semblance spectrale" 108968 -- fast out of combat drinking
	{ 112833, playerAggro and jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral_" },

	{ "nested", jps.hp("player") < 0.55 ,
		{
			-- "Prière du désespoir" 19236
			{ 19236, select(2,GetSpellBookItemInfo(priest.Spell["Desesperate"]))~=nil , "player" },
			-- "Power Word: Shield" 17 
			{ 17, not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" },
			-- "Pierre de soins" 5512
			{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" },
		},
	},

	-- CONTROL -- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ "nested", true , parseControl },
	-- "Prière de guérison" 33076 -- TIMER POM
	{ 33076, UnitAffectingCombat("player") == 1 and not jps.buffTracker(33076) , LowestImportantUnit , "Tracker_Mending_"..LowestImportantUnit },

	-- GROUP
	{ "nested", CountInRange > 2 and AvgHealthLoss < 0.85 , 
		{
			--- Chakra: Sanctuary 81206
			{ 81206, not jps.buffId(81206) and (type(POHTarget) == "string") , "player" },
			-- "Circle of Healing" 34861
			{ 34861, true , LowestImportantUnit },
			-- "Cascade" 121135
			{ 121135, jps.IsSpellKnown(121135) , LowestImportantUnit },
			-- "Prayer of Healing" 596
			{ 596, (type(POHTarget) == "string") , POHTarget },
		},
	},

	-- Chakra: Serenity 81208
	{ 81208, not jps.buffId(81208) and LowestImportantUnitHpct < 0.85 , "player" , "Chakra: Serenity" },

	-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
	{ 139, not jps.buff(139,LowestImportantUnit) and LowestImportantUnitHealth > priest.AvgAmountFlashHeal , LowestImportantUnit , "Renew_"..LowestImportantUnit },
	-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
	{ 88684, jps.buffId(81208) and LowestImportantUnitHealth > priest.AvgAmountFlashHeal, LowestImportantUnit , "Serenity_"..LowestImportantUnit },
	{ 88684, jps.buffId(81208) and jps.myBuffDuration(139,LowestImportantUnit) < 2 and jps.buff(139,LowestImportantUnit) , LowestImportantUnit , "Serenity_"..LowestImportantUnit},
	
	-- MOVING
	{ "nested", jps.Moving , parseMoving },
	-- DISPEL	
	{ "nested", true , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,2) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },

	-- "Soins rapides" 2061
	{ 2061, (LowestImportantUnitHpct < 0.40) , LowestImportantUnit , "Emergency_SoinsRapides_40%_"..LowestImportantUnit },
	-- "Soins de lien"
	{ 32546 , type(BindingHealTarget) == "string" , BindingHealTarget , "Lien_" },
	-- "Soins rapides" 2061
	{ 2061, (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) and stackSerendip < 2, LowestImportantUnit },
	-- "Soins supérieurs" 2060
	{ 2060, stackSerendip == 2 and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit , "SoinsSup_"..LowestImportantUnit  },
	
	-- DAMAGE
	-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
	{ 32379, priest.canShadowWordDeath(rangedTarget) , rangedTarget , "|cFFFF0000Death_Health_"..rangedTarget },
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.85 ,
		{
			-- Chakra: Chastise 81209
			{ 81209, not jps.buffId(81209) , "player" },
			-- "Chatier" 88625
			{ 88625, true , rangedTarget,"|cFFFF0000Chastise_"..rangedTarget },
			-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
			{ 14914, true , rangedTarget , "|cFFFF0000Flammes_"..rangedTarget },
			-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
			{ 129250, true , rangedTarget, "|cFFFF0000Solace_"..rangedTarget },
			-- "Mot de l'ombre: Douleur" 589 -- FARMING OR PVP -- NOT PVE -- Only if 1 targeted enemy 
			{ 589, priest.get("ShadowPain") and TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget , "|cFFFF0000Douleur_"..rangedTarget },
			-- "Châtiment" 585
			{ 585, priest.get("Chastise") and CountInRange > 0 and jps.castEverySeconds(585,2.5) , rangedTarget , "|cFFFF0000Chatiment_"..rangedTarget },
		},
	},

	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- "Infusion de puissance" 10060 
	{ 10060, not jps.buffId(10060,"player") and UnitAffectingCombat("player") == 1, "player" , "POWERINFUSION_" },
	-- "Feu intérieur" 588 -- "Volonté intérieure" 73413
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player") }, -- "target" by default must must be a valid target
	-- "Soins" 2050
	{ 2050, LowestImportantUnitHealth > priest.AvgAmountHeal , LowestImportantUnit , "Soins_"..LowestImportantUnit },
	
}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","HOLY", priestHoly, "Holy Priest", false , true)


-- Chakra: Serenity 81208
-- Increases the healing done by your single-target healing spells by 25%
-- causes them to refresh the duration of your Renew on the target, and transforms your Holy Word: Chastise spell into Holy Word: Serenity.
-- "Holy Word: Serenity" 88684
-- Instantly heals the target for 12367 to 14517 (+ 130% of Spell power)
-- "Holy Word: Serenity" increases the critical effect chance of your healing spells on the target by 25% for 6 sec. 10 sec cooldown.

-- Chakra: Sanctuary 81206
-- Increases the healing done by your area of effect healing spells by 25% -- Prayer of Mending, Circle of Healing, Divine Star, Cascade, Halo, Divine Hymn
-- reduces the cooldown of your Circle of Healing spell by 2 sec, and transforms your Holy Word: Chastise spell into Holy Word: Sanctuary
-- Holy Word: Sanctuary 88685
-- Blesses the ground with divine light, healing all within it for 461 to 547 (+ 5.83% of Spell power) every 2 sec for 30 sec.
-- Only one Sanctuary can be active at a time  Healing effectiveness diminishes for each player beyond 6 within the area.

-- Chakra: Chastise 81209
-- Increases the damage done by your Shadow and Holy spells by 50%, grants a 10% chance for Smite to reset the cooldown of Holy Word: Chastise
-- reduces the mana cost of Smite and Holy Fire by 90%, and transforms your Holy Word spell back into Holy Word: Chastise
-- Holy Word: Chastise 88625
-- Chastise the target for 627 to 702 (+ 61.4% of Spell power) Holy damage, and disorients them for 3 sec -- 30 sec cooldown.

-- "Serendipity" 63735
-- When you heal with Binding Heal or Flash Heal, the cast time of your next Greater Heal or Prayer of Healing spell is reduced by 20% 
-- and mana cost reduced by 20%. Stacks up to 2 times. Lasts 20 sec.

-- "Guardian Spirit" 47788
-- Calls a guardian spirit to watch over the friendly target. The spirit increases the healing received by the target by 60%
-- and also prevents the target from dying by sacrificing. Lasts 10 sec.  Castable while stunned.

-- "Lightwell" This spell can be used while Tanking, Kiting, Blinded, Stunned, Disoriented, Sapped, Casting another heal or spell

-- "Holy Spark" 131567 (Priest PvP Healing 2P Bonus Holy Spark). When you cast Prayer of Mending, the initial target is blessed with a Holy Spark
-- increasing the healing done by your next Flash Heal, Greater Heal or Holy Word: Serenity by 50% for 10 sec.
-- 1.Serenity -- 2.PoM -- 3.Greater Heal which uses your HOLY SPARK buff proc the greater heal which is also likely to crit due to Serenity buff

-- From Darkness, Comes Light has been buffed this patch increasing it's procs when using Renew, Circle of Healing, Prayer of Mending, and Prayer of Healing

-- Divine Insight, When you cast Greater Heal or Prayer of Healing, there is a 40% chance
-- your next Prayer of Mending will not trigger its cooldown, and will jump to each target instantly.

--[[
/cast Chakra: Chastise
/cast Chastise

/cast Chakra: Holy Word: Serenity
/cast Holy Word: Serenity

/cast Chakra: Sanctuary
/cast Divine Hymn

#showtooltip Prayer of Mending
/cast Chakra: Serenity
/cast [target=mouseover,nomod,exists] Prayer of Mending; Prayer of Mending

]]
