
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
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.80) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local CountFriendLowest = jps.CountInRaidLowest(0.60)


	local Tank,TankUnit = jps.findTankInRaid() -- ddefault "focus" "player"
	local TankTarget = "target"
	if canHeal(Tank) then TankTarget = Tank.."target" end
	local TankThreat = jps.findThreatInRaid() -- default "focus" "player"

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local isArena, _ = IsActiveBattlefieldArena()

----------------------
-- TARGET ENEMY
----------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
	local isBoss = (UnitLevel("target") == -1) or (UnitClassification("target") == "elite")

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS(TankTarget) then rangedTarget = TankTarget
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0
	local playerIsTargeted = jps.playerIsTargeted()

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

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

	-- DISPEL --
	
	local DispelFriendPvE = jps.DispelMagicTarget() -- {"Magic", "Poison", "Disease", "Curse"}
	local DispelFriendPvP = nil
	local DispelFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.DispelLoseControl(unit) then -- jps.DispelLoseControl includes jps.WarningDebuffs
			local unitHP = jps.hp(unit)
			if unitHP < DispelFriendHealth then
				DispelFriendPvP = unit
				DispelFriendHealth = unitHP
			end
		end
	end

	local DispelFriendRole = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(TankUnit) do
		local unit = TankUnit[i]
		if jps.canDispel(unit,"Magic") then -- jps.canDispel includes jps.WarningDebuffs
			DispelFriendRole = unit
		break end
	end
	
	local MendingFriend = nil
	local MendingFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.FriendAggro(unit) and not jps.buff(41635,unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingFriendHealth then
				MendingFriend = unit
				MendingFriendHealth = unitHP
			end
		end
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
	}
	
	local parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, DispelFriendRole ~= nil , DispelFriendRole , "|cff1eff00DispelFriend_Role" },
		{ 527, DispelFriendPvP ~= nil , DispelFriendPvP , "|cff1eff00DispelFriend_PvP" },
		{ 527, DispelFriendPvE ~= nil , DispelFriendPvE , "|cff1eff00DispelFriend_PvE" },
	}

------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

	local InterruptTable = {
		{jps.spells.priest.flashHeal, 0.80 , jps.buff(27827) }, -- "Esprit de rédemption" 27827
		{jps.spells.priest.heal, 0.90 , jps.buff(27827) },
		{jps.spells.priest.prayerOfHealing , 0.80 , jps.buff(spells.symbolOfHope) or jps.buff(27827) or jps.PvP }, -- Chakra: Sanctuary 81206
	}

	-- AVOID OVERHEALING
	jps.ShouldInterruptCasting(InterruptTable , groupHealth , CountFriendLowest)

------------------------
-- SPELL TABLE ---------
------------------------
local spellTable = {

	-- "Esprit de rédemption" 20711
	{ "nested", jps.buff(spells.spiritOfRedemption) , 
		{
			{ spells.holyWordSerenity , jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit  },
			-- "Guardian Spirit" 47788
			{ spells.guardianSpirit , jps.hp(LowestImportantUnit) < 0.30 , LowestImportantUnit , "Emergency_Guardian" },
			-- "Divine Hymn" 64843
			{ spells.divineHymn, AvgHealthLoss < 0.80 },
			-- "Prayer of Healing" 596
			{ spells.prayerOfHealing, POHTarget ~= nil , POHTarget },
			-- "Soins rapides" 2061
			{ spells.flashHeal, jps.hp(LowestImportantUnit) < 0.90 , LowestImportantUnit },
			-- "Renew" 139
			{ spells.renew, true , LowestImportantUnit },
		},
	},
	
--	{ "castsequence", jps.UseCDs , 
--		{
--
--			--spells.guardianSpirit  ,
--			spells.prayerOfMending ,
--			spells.smite,
--			spells.prayerOfHealing ,
--			spells.flashHeal ,
--			spells.renew ,
--		},
--	},

	-- PLAYER AGGRO --
	{ 208683, playerIsStun , "player" , "playerCC" },
	{ spells.fade, jps.FriendAggro("player") and jps.hp("player") < 0.80, "player" },
	{ spells.bodyAndMind, jps.Moving , "player" },

	-- "Guardian Spirit" 47788
	{ spells.guardianSpirit , jps.hp(TankThreat) < 0.30 , TankThreat , "Emergency_Guardian_Tank" },
	{ spells.guardianSpirit , jps.hp(LowestImportantUnit) < 0.30 , LowestImportantUnit , "Emergency_Guardian" },

	-- Dispell
	{ spells.dispelMagic, jps.UseCDs and jps.canDispel("player","Magic") , "player" , "Dispel" },
	{ "nested", jps.UseCDs , parseDispel },

	{ spells.renew, jps.buffDuration(spells.renew,TankThreat) < 3 and jps.hp(LowestImportantUnit) > 0.80 , TankThreat , "Timer_Renew_Tank" },
	{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and jps.hp(LowestImportantUnit) > 0.80 , Tank , "Timer_Renew_Tank" },
	{ spells.renew , jps.buffDuration(spells.renew,LowestImportantUnit) < 3 and jps.hp(LowestImportantUnit) > 0.80 , LowestImportantUnit  },
	{ spells.renew , jps.buffDuration(spells.renew,"player") < 3 and jps.hp(LowestImportantUnit) > 0.80 , "player"  },

	{ "nested", jps.Defensive , {
		{ spells.holyWordChastise , true , rangedTarget },
		{ spells.holyFire , true , rangedTarget  },
		{ spells.smite , not jps.Moving , rangedTarget },
	}},
	
	-- spells.divineHymn should be used during periods of very intense raid damage.
	-- spells.holyNova
	-- "Holy Word: Serenity" 2050
	{ spells.holyWordSerenity , jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit  },

	-- Symbol of Hope you should you use expensive spells such as Prayer of Healing and Holy Word: Sanctify
	{ spells.symbolOfHope , POHTarget ~= nil and groupHealth < 0.50 }, -- buff 64901
	{ spells.apotheosis , POHTarget ~= nil and groupHealth < 0.70 }, -- buff 200183
	{ spells.prayerOfHealing, not jps.Moving and jps.buff(64901) and POHTarget ~= nil and canHeal(POHTarget) , POHTarget },
	{ spells.prayerOfHealing, not jps.Moving and jps.buff(200183) and POHTarget ~= nil and canHeal(POHTarget) , POHTarget },
	{ spells.prayerOfHealing, not jps.Moving and jps.buff(197030) and POHTarget ~= nil and canHeal(POHTarget) , POHTarget },

	-- Holy Word: Sanctify using before casting Prayer of Healing
	-- gives buff "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec.
	{ spells.holyWordSanctify , POHTarget ~= nil },
	{ spells.holyWordSanctify , CountInRange > 3 and AvgHealthLoss < 0.80 },
	{ spells.holyWordSanctify , CountInRange > 3 and jps.hp(LowestImportantUnit) < 0.60 },

	-- "Light of T'uure" 208065 it buffs the target to increase your healing done to them by 25% for 10 seconds
	{ spells.lightOfTuure , jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit  },
	-- "Apotheosis" 200183 increasing the effects of Serendipity by 200% and reducing the cost of your Holy Words by 100%.
	{ spells.apotheosis , jps.hp(LowestImportantUnit) < 0.60 },

	-- EMERGENCY HEAL -- "Serendipity" 63733
	-- "Soins rapides" 2061 -- "Vague de Lumière" 109186 "Surge of Light" -- gives buff 114255
	{ spells.flashHeal , jps.hp(LowestImportantUnit) < 0.80 and jps.buff(spells.surgeOfLight) , LowestImportantUnit ,  "FlashHeal_surgeOfLight" },
	{ spells.flashHeal , jps.hp(LowestImportantUnit) < 0.80 and jps.buff(114255) , LowestImportantUnit , "FlashHeal_114255" },
	{ spells.flashHeal , jps.buff(114255) and jps.buffDuration(114255) < 4 , LowestImportantUnit , "FlashHeal_114255" },

	{ "nested", jps.hp(LowestImportantUnit) < 0.60 and not jps.Moving ,{
		-- "Soins de lien" 32546
		{ spells.bindingHeal , jps.unitForBinding(LowestImportantUnit) , LowestImportantUnit , "Emergency_Lien" },
		{ spells.bindingHeal , BindingHealFriend ~= nil , BindingHealFriend , "Lien" },
		-- "Soins rapides" 2061
		{ spells.flashHeal, not jps.Moving , LowestImportantUnit , "Emergency_FlashHeal" },
	}},

	-- "Soins rapides" 2061
	{ spells.flashHeal, groupHealth > 0.80 and not jps.Moving and canHeal(TankThreat) and jps.hpInc(TankThreat) < 0.90 and jps.hpSum(TankThreat) < 0.60 , TankThreat , "FlashHeal_TankThreat"  },
	{ spells.flashHeal, groupHealth > 0.80 and not jps.Moving and canHeal(Tank) and jps.hpInc(Tank) < 0.90 and jps.hpSum(Tank) < 0.60 , Tank , "FlashHeal_Tank"  },
	-- "Soins" 2060
	{ spells.heal , groupHealth > 0.80 and not jps.Moving and canHeal(TankThreat) and jps.hpInc(TankThreat) < 0.90 and jps.hpSum(TankThreat) > 0.60 , TankThreat , "Soins_TankThreat"  },
	{ spells.heal , groupHealth > 0.80 and not jps.Moving and canHeal(Tank) and jps.hpInc(Tank) < 0.90 and jps.hpSum(Tank) > 0.60 , Tank , "Soins_Tank"  },

	-- GROUP HEAL
	-- jps.buff(spells.blessingOfTuure)

	-- "Circle of Healing" 204883
	{ spells.circleOfHealing , CountInRange > 3 and AvgHealthLoss < 0.80 , LowestImportantUnit },
	{ spells.circleOfHealing , POHTarget ~= nil and canHeal(POHTarget) , POHTarget },
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ spells.prayerOfMending, not jps.Moving and not jps.buffTracker(41635) and CountInRange > 3 and AvgHealthLoss < 0.80 , LowestImportantUnit },
	{ spells.prayerOfMending, not jps.Moving and not jps.buffTracker(41635) and  POHTarget ~= nil and canHeal(POHTarget) , POHTarget },
	-- Power of the Naaru, an artifact trait, buffs Prayer of Healing for 15 seconds after using
	{ spells.prayerOfHealing, not jps.Moving and POHTarget ~= nil and canHeal(POHTarget) , POHTarget },

	-- LOWEST TTD -- LowestFriendTTD friend unit in raid with TTD < 5 sec 
	{ "nested", LowestFriendTTD ~= nil and jps.hpInc(LowestFriendTTD) < 0.80 ,{
		-- "Pénitence" 47540
		{ spells.holyWordSerenity , jps.hp(LowestFriendTTD) < 0.60 , LowestFriendTTD , "Penance_Lowest_TTD" },
		-- "Soins rapides" 2061
		{ spells.flashHeal, not jps.Moving and groupHealth > 0.80 and jps.hp(LowestFriendTTD) < 0.50 , LowestFriendTTD , "FlashHeal_Lowest_TTD" },
	}},
	
	-- HIGHEST DAMAGE -- Highest Damage Friend with Lowest Health
	{ "nested", IncomingDamageFriend ~= nil and jps.hpInc(IncomingDamageFriend) < 0.80 ,{
		-- "Holy Word: Serenity" 2050
		{ spells.holyWordSerenity, jps.hp(IncomingDamageFriend) < 0.60 , IncomingDamageFriend , "Penance_Lowest_DAMAGE" },
		-- "Soins rapides" 2061
		{ spells.flashHeal, not jps.Moving and groupHealth > 0.80 and jps.hp(IncomingDamageFriend) < 0.50 , IncomingDamageFriend , "FlashHeal_Lowest_DAMAGE" },
	}},
	
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ "nested", not jps.Moving and not jps.buffTracker(41635) ,{
		{ spells.prayerOfMending, canHeal(Tank) , Tank , "Tracker_Mending_Tank" },
		{ spells.prayerOfMending, MendingFriend ~= nil , MendingFriend , "Tracker_Mending_Friend" },
		{ spells.prayerOfMending, jps.buff(41635,LowestImportantUnit) , LowestImportantUnit , "Tracker_Mending_Lowest" },
	}},


	{ spells.heal , not jps.Moving and jps.hp(LowestImportantUnit) < 0.80 and jps.buff(spells.renew,LowestImportantUnit), LowestImportantUnit  },
	{ "nested", jps.hp(LowestImportantUnit) < 1 ,{
		-- "Renew" 139
		{ spells.renew, not jps.buff(spells.renew,LowestImportantUnit) , LowestImportantUnit , "Renew" },
		-- "Don des naaru" 59544
		{ spells.giftNaaru, jps.hp(LowestImportantUnit) < 0.90 , LowestImportantUnit , "Naaru" },
		-- "Soins supérieurs" 2060
		{ spells.heal,  not jps.Moving and jps.hp(LowestImportantUnit) < 0.90 , LowestImportantUnit , "Heal"  },
	}},

	{ spells.renew, RenewFriend ~= nil , RenewFriend },
	
	{ spells.holyWordChastise , true, rangedTarget },
	{ spells.holyFire , true, rangedTarget  },
	{ spells.smite , true, rangedTarget },

}
	spell,target = parseSpellTable(spellTable)
	return spell,target
end , "Holy Priest Default" )

-- Blessing of T'uure buff will also greatly increase your healing.
-- If you can proc your Blessing of T'uure (by getting a critical heal with Flash Heal or Heal)
-- you should then use Holy Word: Serenity to proc Divinity
-- then use Holy Word: Sanctify for large AoE heal and buff to Prayer of Healing

--[[
Below, we use the Heal Icon Heal spell to provide you with an example of a mouse-over macro:

    #showtooltip Heal
    /cast [@mouseover,exists,nodead,help,][exists,nodead,help][@player] Heal

    If you are mousing over a target which exists, is not dead and is friendly, it will cast Heal on them.
    Otherwise, if your currently selected target exists, is not dead and is friendly, Heal will be cast on them instead.
    Lastly, if neither of the above two conditions are met, it will cast Heal on yourself.

--]]


	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
--	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , "player" , "Trinket0"},
--	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , "player" , "Trinket1"},

	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
--	{ 528, jps.castEverySeconds(528,8) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
--	{ 528, jps.castEverySeconds(528,8) and type(DispelOffensiveEnemyTarget) == "string"  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },

	-- CONTROL --
--{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget  },
--{ "nested", not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },

--------------------------------------------------------------------------------------------------------------
------------------------------------------------ ROTATION OOC ------------------------------------------------
--------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","HOLY",function()

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus()
	local LowestImportantUnit = jps.LowestImportantUnit()
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.80) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local CountFriendLowest = jps.CountInRaidLowest(0.60)

	-- rangedTarget returns "target" by default
	local rangedTarget, _, _ = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	if jps.ChannelTimeLeft() > 0 then return nil end
	if jps.CastTimeLeft() > 0 then return nil end
	
	local spellTable = {
	
	-- "Esprit de rédemption" 20711
	{ "nested", jps.buff(spells.spiritOfRedemption) , 
		{
			{ spells.holyWordSerenity , jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit  },
			-- "Guardian Spirit" 47788
			{ spells.guardianSpirit , jps.hp(LowestImportantUnit) < 0.30 , LowestImportantUnit , "Emergency_Guardian" },
			-- "Divine Hymn" 64843
			{ spells.divineHymn, AvgHealthLoss < 0.80 },
			-- "Prayer of Healing" 596
			{ spells.prayerOfHealing, POHTarget ~= nil , POHTarget },
			-- "Soins rapides" 2061
			{ spells.flashHeal, jps.hp(LowestImportantUnit) < 0.90 , LowestImportantUnit },
			-- "Renew" 139
			{ spells.renew, true , LowestImportantUnit },
		},
	},
	

	-- SNM "Levitate" 1706	
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, IsSwimming() and not jps.buff(111759) , "player" },
	
	-- "Don des naaru" 59544
	{ 59544, jps.hp("player") < 0.80 , "player" },
	{ spells.bodyAndMind, jps.Moving , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ {"macro","/use item:118922"}, jps.itemCooldown(118922) == 0 , "player" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Holy Priest",false,true)