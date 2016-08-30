
local L = MyLocalizationTable
local spells = jps.spells.priest
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.CanAttack
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit

-- Debuff EnemyTarget NOT DPS
local DebuffUnitCyclone = function (unit)
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			return true
		elseif strfind(auraName,L["Cyclone"]) then
			return true
		elseif strfind(auraName,L["Hex"]) then
			return true
		end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i))
	end
	return false
end

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","HOLY", function()

	local spell = nil
	local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus()
	local LowestImportantUnit = jps.LowestImportantUnit()
	local countFriendNearby = jps.FriendNearby(12)
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	--local POHTarget, groupToHeal = jps.FindSubGroupTarget(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local CountFriendLowest = jps.CountInRaidLowest(0.80)
	local CountFriendEmergency = jps.CountInRaidLowest(0.50)

	local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
	local TankTarget = "target"
	if canHeal(Tank) then TankTarget = Tank.."target" end
	local TankThreat = jps.findThreatInRaid()

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local playerTTD = jps.TimeToDie("player")
	local BodyAndSoul = jps.IsSpellKnown(64129) -- "Body and Soul" 64129
	local isArena, _ = IsActiveBattlefieldArena()

---------------------
-- ENEMY TARGET
---------------------

	local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS(TankTarget) then rangedTarget = TankTarget
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	local playerIsTargeted = jps.playerIsTargeted()

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local MendingFriend = nil
	local MendingFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.unitForMending(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingFriendHealth then
				MendingFriend = unit
				MendingFriendHealth = unitHP
			end
		end
	end
	
	-- jps.unitForLeap includes jps.FriendAggro and jps.LoseControl
	local LeapFriend = nil
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.unitForLeap(unit) and jps.hpInc(unit) < 0.30 then 
			LeapFriend = unit
		break end
	end
	
	-- jps.unitForShield includes jps.FriendAggro
	local ShieldFriend = nil
	local ShieldFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldFriendHealth then
				ShieldFriend = unit
				ShieldFriendHealth = unitHP
			end
		end
	end
	
	local BindingHealFriend = nil
	local BindingHealFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.unitForBinding(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < BindingHealFriendHealth then
				BindingHealFriend = unit
				BindingHealFriendHealth = unitHP
			end
		end
	end

	-- DISPEL --
	
	local DispelFriendPvE = jps.FindMeDispelTarget( {"Magic"} ) -- {"Magic", "Poison", "Disease", "Curse"}
	local DispelFriendPvP = nil
	local DispelFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.DispelFriendly(unit) then -- jps.DispelFriendly includes UnstableAffliction
			local unitHP = jps.hp(unit)
			if unitHP < DispelFriendHealth then
				DispelFriendPvP = unit
				DispelFriendHealth = unitHP
			end
		end
	end

	local DispelFriendLoseControl = nil
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if DispelFriendLoseControl == nil and jps.DispelLoseControl(unit) then DispelFriendLoseControl = unit
		break end
	end

	local DispelFriendRole = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(TankUnit) do
		local unit = TankUnit[i]
		if jps.canDispel(unit,{"Magic"}) then -- jps.canDispel includes UnstableAffliction
			DispelFriendRole = unit
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
	
	-- INCOMING DAMAGE
	local IncomingDamageFriend = jps.HighestIncomingDamage()
	
	-- LOWEST TTD
	local LowestFriendTTD = jps.LowestFriendTimeToDie(5)

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
		if jps.canFear(unit) and not jps.LoseControl(unit) then
			FearEnemyTarget = unit
		break end
	end

	local DispelOffensiveEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if jps.DispelOffensive(unit) and jps.hp(LowestImportantUnit) > 0.85 then
			DispelOffensiveEnemyTarget = unit
		break end
	end

------------------------
-- LOCAL TABLES
------------------------
	
	local parseControl = {
		-- "Silence" 15487
		{ 15487, jps.IsSpellInRange(15487,rangedTarget) , rangedTarget },
		-- "Psychic Scream" "Cri psychique" 8122 -- debuff same ID 8122
		{ 8122, jps.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, jps.canFear(rangedTarget) , rangedTarget },
	}
	
	local parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, DispelFriendRole ~= nil , DispelFriendRole , "|cff1eff00DispelFriend_Role" },
		{ 527, DispelFriendPvP ~= nil , DispelFriendPvP , "|cff1eff00DispelFriend_PvP" },
		{ 527, DispelFriendLoseControl ~= nil , DispelFriendLoseControl , "|cff1eff00DispelFriend_LoseControl" },
		{ 527, DispelFriendPvE ~= nil , DispelFriendPvE , "|cff1eff00DispelFriend_PvE" },
	}

------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

	local InterruptTable = {
		{jps.spells.priest.flashHeal, 0.75 , jps.buff(27827) }, -- "Esprit de rédemption" 27827
		{jps.spells.priest.heal, 0.90 , jps.buff(27827) },
		{jps.spells.priest.prayerOfHealing , 0.80, jps.buffId(81206) or jps.buff(27827) }, -- Chakra: Sanctuary 81206
	}

	-- AVOID OVERHEALING
	jps.ShouldInterruptCasting(InterruptTable , groupHealth , CountFriendLowest)

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
			{ 2061, jps.hp(LowestImportantUnit) < 0.75 , LowestImportantUnit },
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
	{ 47788, playerIsStun and jps.hp(LowestImportantUnit) < 0.30 , LowestImportantUnit , "Guardian_" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.itemCooldown(5512) == 0 and jps.hp() < 0.75 , "player" , "Item5512" },
	-- "Prière du désespoir" 19236
	{ 19236, jps.IsSpellKnown(19236) and jps.hp() < 0.75 , "player" , "Aggro_DESESPERATE" },
	-- "Don des naaru" 59544
	{ 59544, jps.hp() < 0.75 , "player" , "Aggro_Naaru" },

	-- PLAYER AGGRO
	{ "nested", playerAggro or playerIsTargeted ,{
		-- "Power Word: Shield" 17
		{ 17, jps.IsSpellKnown(64129) and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield" },
		-- "Spectral Guise" 112833 "Semblance spectrale"
		{ 112833, jps.Interrupts and jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },
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
	{ 2061, jps.buff(114255) and jps.hp(LowestImportantUnit) < 0.75 , LowestImportantUnit , "FlashHeal_Light_" },
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
	{ 81208, not jps.buffId(81208) and jps.hp(LowestImportantUnit) < 0.85 and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },
	{ 81208, not jps.buffId(81208) and jps.FinderLastMessage("Cancelaura") == false , "player" , "|cffa335eeChakra_Serenity" },

	-- "Infusion de puissance" 10060
	{ 10060, jps.combatStart > 0 and jps.hp(LowestImportantUnit) < 0.50 , "player" , "Emergency_POWERINFUSION" },
	
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
	{ "nested", jps.hp(LowestImportantUnit) < 0.50 ,{
		-- "Guardian Spirit" 47788
		{ 47788, jps.hp(LowestImportantUnit) < 0.30 , LowestImportantUnit , "Emergency_Guardian_" },
		-- "Holy Word: Serenity" 88684 -- Chakra: Serenity 81208
		{ {"macro",macroSerenity}, jps.cooldown(88684) == 0 and jps.buffId(81208) , LowestImportantUnit , "Emergency_Serenity_" },
		-- "Power Word: Shield" 17 
		{ 17, jps.hp(LowestImportantUnit) < 0.30 and not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_" },
		-- "Soins supérieurs" 2060
		{ 2060,  jps.buffStacks(63735,"player") == 2 , LowestImportantUnit , "Emergency_Soins_"  },
		-- "Soins de lien"
		{ 32546 , jps.unitForBinding(LowestImportantUnit) , LowestImportantUnit , "Emergency_Lien_" },
		-- "Soins rapides" 2061
		{ 2061, true , LowestImportantUnit , "Emergency_FlashHeal_" },

	}},
	
	-- DISPEL -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
	{ "nested", jps.UseCDs , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,8) and jps.DispelOffensive(rangedTarget) and jps.hp(LowestImportantUnit) > 0.85 , rangedTarget , "|cff1eff00DispelOffensive_" },
	{ 528, jps.castEverySeconds(528,8) and type(DispelOffensiveEnemyTarget) == "string"  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },

	-- CONTROL --
	--{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit" },
	--{ "nested", not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },

	{ "nested", jps.hp(LowestImportantUnit) < 0.85 ,{
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
	{ 34433, jps.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, jps.canShadowfiend(rangedTarget) , rangedTarget },
	-- DAMAGE -- Chakra: Chastise 81209
	{ "nested", jps.MultiTarget and canDPS(rangedTarget) and jps.hp(LowestImportantUnit) > 0.85 , parseDamage },

	-- "Renew" 139 -- Haste breakpoints are 12.5 and 16.7%(Holy)
	{ 139, type(RenewFriend) == "string" , RenewFriend , "Tracker_Renew_Friend" },
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	--{ 6346, not jps.buff(6346,"player") , "player" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end , "Holy Priest Default" )