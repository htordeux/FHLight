
local spells = jps.spells.priest
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
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

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.80)
	local POHInRange, _, _ = jps.CountInRangeStatus(0.80,20)
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.80) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local LowestImportantUnit = jps.LowestImportantUnit()

	local Tank,TankUnit = jps.findTankInRaid() -- default "focus" "player"
	local TankTarget = Tank.."target"
	local TankThreat = jps.findThreatInRaid() -- default "focus" "player"

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local isArena, _ = IsActiveBattlefieldArena()

	-- LOWEST TTD
	local LowestFriendTTD = jps.LowestFriendTimeToDie(5)

----------------------
-- TARGET ENEMY
----------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS(TankTarget) then rangedTarget = TankTarget
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canAttack("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

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
		elseif not jps.buff(139,unit) and jps.buff(27827) then
		-- "Esprit de rédemption" buff 27827 "Spirit of Redemption"
			RenewFriend = unit
		elseif not jps.buff(41635) and jps.hp(unit) < 0.80 then
		-- "Holy Mending" 196779 causes Prayer of Mending to heal the target instantly for an additional amount
		-- whenever it jumps to a player on which Renew is active
		-- placing Renew on players without Prayer of Mending, you will increase the likelihood of this trait to proc
			RenewFriend = unit
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
		{ spells.purify, jps.canDispel("player","Magic") , "player" , "Dispel" },
		{ spells.purify, DispelFriendRole ~= nil , DispelFriendRole , "|cff1eff00DispelFriend_Role" },
		{ spells.purify, DispelFriendPvP ~= nil , DispelFriendPvP , "|cff1eff00DispelFriend_PvP" },
		{ spells.purify, DispelFriendPvE ~= nil , DispelFriendPvE , "|cff1eff00DispelFriend_PvE" },
	}

------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

	local InterruptTable = {
		{jps.spells.priest.flashHeal, 0.80 , jps.buff(27827) or jps.PvP }, -- "Esprit de rédemption" 27827
		{jps.spells.priest.heal, 0.50 , jps.buff(27827) },
		{jps.spells.priest.prayerOfHealing , 4 , jps.buff(64901) or jps.buff(27827) }, -- "Symbol of Hope" 64901
	}

	-- AVOID OVERHEALING
	jps.ShouldInterruptCasting(InterruptTable , CountInRange , jps.hp(LowestImportantUnit) )

------------------------
-- SPELL TABLE ---------
------------------------

-- casting "Holy Word: Serenity" gives buff "Divinity" 197031 your healing is increased by 15% for 6 sec.

-- "Invoke the Naaru" 196684 When you use a Holy Word spell, you have a chance to summon an image of T'uure for 15 sec
-- whenever you cast a spell, T'uure will cast a similar spell. Your Heal Flash Heal and Holy Word: Serenity cause T'uure to cast Healing Light
-- Healing Light heals for 250% of spellpower, while your own Heal and Flash Heal heal for 475%.

-- "Blessing of T'uure" 196578 "Bénédiction de T’uure" buff will also greatly increase your healing.
-- If you can proc your Blessing of T'uure (by getting a critical heal with Flash Heal or Heal)
-- you should then use Holy Word: Serenity to proc Divinity
-- then use Holy Word: Sanctify for large AoE heal and buff to Prayer of Healing


if jps.ChannelTimeLeft("player") > 0 then return end

local spellTable = {

	-- "Esprit de rédemption" buff 27827 "Spirit of Redemption"
	{ "macro", jps.buff(27827) and CountInRange == 0 , "/cancelaura Esprit de rédemption"  },
	{ "nested", jps.buff(27827) and not UnitIsUnit("player",LowestImportantUnit) , {
		-- "Holy Word: Serenity" 2050
		{ spells.holyWordSerenity , jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit  },
		-- "Divine Hymn" 64843
		{ spells.divineHymn, jps.buffDuration(27827) > 8 and CountInRange > 4 and AvgHealthLoss < 0.80 },
		-- "Prayer of Healing" 596
		{ spells.prayerOfHealing, POHInRange > 4 , LowestImportantUnit },
		-- "Soins rapides" 2061
		{ spells.flashHeal, jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit },
		-- "Prière de guérison" 33076
		{ spells.prayerOfMending, true , LowestImportantUnit },
		-- "Renew" 139
		{ spells.renew, jps.buffDuration(spells.renew,LowestImportantUnit) < 3 , LowestImportantUnit },
		-- "Soins rapides" 2061
		{ spells.flashHeal, true , LowestImportantUnit },
	}},
	
	-- SNM "Levitate" 1706	
	{ 1706, jps.Defensive and jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.Defensive and IsSwimming() and not jps.buff(111759) , "player" },

	-- PLAYER AGGRO --
	-- "Médaillon de gladiateur" 208683
	{ 208683, jps.PvP and playerIsStun , "player" , "playerCC" },
	{ 214027, jps.PvP and playerIsStun , "player" , "playerCC" },
	-- "Corps et esprit" 214121
	{ spells.bodyAndMind, jps.Moving , "player" },
	-- "Fade" 586 "Disparition"
	{ spells.fade, not jps.PvP and jps.FriendAggro("player") },
	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp() < 0.80 , "player" , "Naaru" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp() < 0.60 and jps.itemCooldown(5512) == 0 ,"/use item:5512" , "Aggro_Item5512" },
	-- "Mot sacré : Châtier" 88625
	{ spells.holyWordChastise , jps.PvP and canDPS(rangedTarget) , rangedTarget },

	-- "Guardian Spirit" 47788
	{ spells.guardianSpirit, jps.hp() < 0.30 , "player" , "Emergency_Guardian_Player" },
	{ spells.guardianSpirit, jps.hp(TankThreat) < 0.30 and not UnitIsUnit("player",TankThreat) , TankThreat , "Emergency_Guardian_Tank" },
	{ spells.guardianSpirit, jps.hp(Tank) < 0.30 and not UnitIsUnit("player",Tank) , Tank , "Emergency_Guardian_Tank" },
	{ spells.guardianSpirit, jps.hp(LowestImportantUnit) < 0.30 , LowestImportantUnit , "Emergency_Guardian_Lowest" },
	-- "Soins rapides" 2061 -- "Vague de Lumière" 109186 "Surge of Light" -- gives buff 114255
	{ spells.flashHeal, jps.hp(TankThreat) < 0.80 and jps.buff(114255) and not UnitIsUnit("player",TankThreat) , TankThreat , "FlashHeal_114255" },
	{ spells.flashHeal, jps.hp(Tank) < 0.80 and jps.buff(114255) and not UnitIsUnit("player",Tank) , Tank , "FlashHeal_114255" },
	{ spells.flashHeal, jps.hp() < 0.80 and jps.buff(114255) , "player" , "FlashHeal_114255" },
	{ spells.flashHeal, jps.hp(LowestImportantUnit) < 0.60 and jps.buff(114255) , LowestImportantUnit , "FlashHeal_114255" },
	{ spells.flashHeal, jps.buff(114255) and jps.buffDuration(114255) < 3 , LowestImportantUnit , "FlashHeal_114255" },
	-- "Holy Word: Serenity" 2050
	{ spells.holyWordSerenity, jps.hp(TankThreat) < 0.60 and not UnitIsUnit("player",TankThreat) , TankThreat , "Emergency_TankThreat" },
	{ spells.holyWordSerenity, jps.hp(Tank) < 0.60 and not UnitIsUnit("player",Tank) , Tank , "Emergency_Tank" },
	{ spells.holyWordSerenity, jps.hp() < 0.60 , "player" , "Emergency_player" },
	{ spells.holyWordSerenity , jps.hp(LowestImportantUnit) < 0.40 , LowestImportantUnit  , "Emergency_Serenity" },
	-- "Light of T'uure" 208065 it buffs the target to increase your healing done to them by 25% for 10 seconds
	{ spells.lightOfTuure, jps.hp(TankThreat) < 0.60 and not UnitIsUnit("player",TankThreat) , TankThreat },
	{ spells.lightOfTuure, jps.hp(Tank) < 0.60 and not UnitIsUnit("player",Tank) , Tank },
	{ spells.lightOfTuure, jps.hp(LowestImportantUnit) < 0.40 , LowestImportantUnit  },
	-- "Apotheosis" 200183 increasing the effects of Serendipity by 200% and reducing the cost of your Holy Words by 100%.
	{ spells.apotheosis, jps.hasTalent(7,1) and jps.hp(TankThreat) < 0.60 },
	{ spells.apotheosis, jps.hasTalent(7,1) and jps.hp(LowestImportantUnit) < 0.60 },

	-- "Renew" 139
	{ spells.renew, jps.buffDuration(spells.renew,TankThreat) < 3 and jps.LastMessage == "Soins_TankThreat" , TankThreat , "Timer_Renew_TankThreat" },
	{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and jps.LastMessage == "Soins_Tank" , Tank , "Timer_Renew_Tank" },
	{ spells.renew, jps.buffDuration(spells.renew,TankThreat) < 3 and jps.LastMessage == "Emergency_TankThreat" , TankThreat , "Emergency_Renew_Tank" },
	{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and jps.LastMessage == "Emergency_Tank" , Tank , "Emergency_Renew_Tank" },
	{ spells.renew, jps.buffDuration(spells.renew,LowestImportantUnit) < 3 and jps.LastMessage == "Emergency_FlashHeal" , LowestImportantUnit  , "Emergency_Renew_Lowest" },
	{ spells.renew, jps.buffDuration(spells.renew,LowestImportantUnit) < 3 and jps.LastMessage == "Emergency_Serenity" , LowestImportantUnit , "Emergency_Renew_Lowest" },
	
	-- "Renew" 139
	{ spells.renew, RenewFriend ~= nil and jps.buffTrackerCount(139) < 3 and jps.hp(LowestImportantUnit) > 0.60 , RenewFriend , "RenewFriend" },
	-- "Prière de guérison" 33076 -- Buff POM 41635 -- "Guerison sacrée"
	{ spells.prayerOfMending, not jps.Moving and jps.buffTrackerCount(139) > 3 and jps.hp(LowestImportantUnit) > 0.60 , LowestImportantUnit , "POM_LowestImportantUnit" },

	-- EMERGENCY HEAL -- "Serendipity" 63733
	-- "Soins rapides" 2061
	{ spells.flashHeal, jps.hp(Tank) < 0.60 and not UnitIsUnit("player",Tank) and not jps.Moving , Tank , "Emergency_Tank" },
	{ spells.flashHeal, jps.hp(TankThreat) < 0.60 and not UnitIsUnit("player",TankThreat) and not jps.Moving , TankThreat , "Emergency_TankThreat" },
	-- "Soins de lien" 32546
	{ spells.bindingHeal, jps.hp(Tank) < 0.60 and not UnitIsUnit("player",Tank) and not jps.Moving and jps.unitForBinding(Tank) , Tank , "Emergency_Lien_Tank" },
	{ spells.bindingHeal, jps.hp(TankThreat) < 0.60 and not UnitIsUnit("player",TankThreat) and not jps.Moving and jps.unitForBinding(TankThreat) , TankThreat , "Emergency_Lien_TankThreat" },

	-- EMERGENCY HEAL -- "Serendipity" 6373
	-- "Soins rapides" 2061
	{ spells.flashHeal, jps.hp(LowestImportantUnit) < 0.50 and jps.LastMessage == "Heal_StopCasting" , LowestImportantUnit , "Emergency_FlashHeal" },
	{ spells.flashHeal, jps.hp(LowestImportantUnit) < 0.50 and groupHealth > 0.80 , LowestImportantUnit , "Emergency_FlashHeal" },
	{ spells.flashHeal, jps.hp(LowestImportantUnit) < 0.50 and AvgHealthLoss > 0.80 , LowestImportantUnit , "Emergency_FlashHeal" },

	-- "Dispel" "Purifier" 527
	{ "nested", jps.UseCDs , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", jps.PvP and jps.hp(LowestImportantUnit) > 0.60 , {
		{ spells.dispelMagic, jps.castEverySeconds(528,8) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
		{ spells.dispelMagic, jps.castEverySeconds(528,8) and DispelOffensiveEnemyTarget ~= nil  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },
	}},

	-- "Prière de guérison" 33076 -- Buff POM 41635
	{ spells.prayerOfMending, not jps.Moving and POHTarget ~= nil and groupHealth < 0.80 , POHTarget , "POM_POHTarget" },
	{ "nested", not jps.Moving and not jps.buffTracker(41635) and jps.hp(LowestImportantUnit) > 0.60 ,{
		{ spells.prayerOfMending, not UnitIsUnit("player",TankThreat) , TankThreat , "Tracker_Mending_Tank" },
		{ spells.prayerOfMending, not UnitIsUnit("player",Tank) , Tank , "Tracker_Mending_Tank" },
		{ spells.prayerOfMending, MendingFriend ~= nil , MendingFriend , "Tracker_Mending_Friend" },
		{ spells.prayerOfMending, true , LowestImportantUnit , "Tracker_Mending_Lowest" },
	}},

	-- "Soins rapides" 2061
	{ spells.flashHeal, groupHealth > 0.80 and not jps.Moving and canHeal(TankThreat) and jps.hpInc(TankThreat) < 0.90 and jps.hp(TankThreat) < 0.60 , TankThreat , "FlashHeal_TankThreat"  },
	{ spells.flashHeal, groupHealth > 0.80 and not jps.Moving and canHeal(Tank) and jps.hpInc(Tank) < 0.90 and jps.hp(Tank) < 0.60 , Tank , "FlashHeal_Tank"  },	
	-- "Soins" 2060
	{ spells.heal , groupHealth > 0.80 and not jps.Moving and canHeal(TankThreat) and jps.hpInc(TankThreat) < 0.90 and jps.hp(TankThreat) > 0.60 , TankThreat , "Soins_TankThreat"  },
	{ spells.heal , groupHealth > 0.80 and not jps.Moving and canHeal(Tank) and jps.hpInc(Tank) < 0.90 and jps.hp(Tank) > 0.60 , Tank , "Soins_Tank"  },
	
	{ "nested", jps.Defensive and canDPS(rangedTarget) and jps.hp(LowestImportantUnit) > 0.60  , {
		{ spells.holyWordChastise , canDPS(rangedTarget) , rangedTarget },
		{ spells.holyFire , canDPS(rangedTarget) , rangedTarget  },
		{ spells.smite , not jps.Moving and canDPS(rangedTarget) , rangedTarget },
		{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true },
	}},

	-- "Symbol of Hope" you should you use expensive spells such as Prayer of Healing and Holy Word: Sanctify
	{ spells.symbolOfHope , CountInRange > 4 and AvgHealthLoss < 0.60 },
	-- "Divine Hymn" 64843 should be used during periods of very intense raid damage.
	{ spells.divineHymn , not jps.Moving and jps.buffTracker(41635) and CountInRange > 4 and AvgHealthLoss < 0.60 , LowestImportantUnit },

--	{ "castsequence", jps.cooldown(spells.holyWordSanctify) == 0 and POHTarget ~= nil and groupHealth < 0.80 ,
--		{ spells.holyWordSanctify , spells.prayerOfHealing , spells.prayerOfHealing  }
--	},
	{ "nested", not jps.Moving and POHTarget ~= nil and groupHealth < 0.80 ,{
		{ spells.prayerOfHealing, jps.buff(64901) , POHTarget , "POH_Buff" }, -- "Symbol of Hope" 64901
		{ spells.prayerOfHealing, jps.buff(200183) , POHTarget , "POH_Buff" }, -- "Apotheosis" 200183
		{ spells.prayerOfHealing, jps.buff(197030) , POHTarget , "POH_Buff" }, -- "Holy Word: Sanctify" gives buff  "Divinity" 197030
		{ spells.prayerOfHealing, jps.buff(196490) , POHTarget , "POH_Buff" }, -- "Holy Word: Sanctify" gives buff  "Puissance des naaru" 196490
	}},
	-- "Holy Word: Sanctify" gives buff  "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec.
	{ spells.holyWordSanctify, POHTarget ~= nil and groupHealth < 0.80 , POHTarget , "Sanctify_POH" },
	{ spells.holyWordSanctify, POHInRange > 4 and jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit, "Sanctify_CountInRange" },
	-- "Prayer of Healing" 596 is no longer restricted to healing players who are in your group.	
	{ spells.prayerOfHealing, not jps.Moving and jps.hp(TankThreat) > 0.40 and jps.hp(LowestImportantUnit) < 0.60 and POHInRange > 4 , LowestImportantUnit , "POH_LowestImportantUnit" },
	{ spells.prayerOfHealing, not jps.Moving and POHTarget ~= nil and groupHealth < 0.80 , POHTarget },

	-- "Renew" 139
	{ spells.renew, jps.buffDuration(spells.renew,"player") < 3 and jps.hp(LowestImportantUnit) > 0.60 , "player" , "Timer_Renew_Player" },
	{ spells.renew, jps.buffDuration(spells.renew,TankThreat) < 3 and jps.hp(LowestImportantUnit) > 0.60 and not UnitIsUnit("player",TankThreat) , TankThreat , "Timer_Renew_Tank" },
	{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and jps.hp(LowestImportantUnit) > 0.60 and not UnitIsUnit("player",Tank) , Tank , "Timer_Renew_Tank" },

	-- "Benediction" for raids and "Apotheosis" for 5 man groups.
	-- EMERGENCY HEAL -- "Serendipity" 63733
	{ "nested", jps.hp(LowestImportantUnit) < 0.60 and not jps.Moving ,{
		-- "Soins de lien" 32546
		{ spells.bindingHeal , jps.unitForBinding(LowestImportantUnit) , LowestImportantUnit , "Emergency_Lien" },
		-- "Soins rapides" 2061
		{ spells.flashHeal, not jps.Moving , LowestImportantUnit , "Emergency_FlashHeal" },
	}},

	-- "Circle of Healing" 204883
	{ spells.circleOfHealing, CountInRange > 4 and AvgHealthLoss < 0.80 , LowestImportantUnit },
	{ spells.circleOfHealing, POHTarget ~= nil and groupHealth < 0.80 , POHTarget },

	-- "Renew" 139
	{ spells.renew, RenewFriend ~= nil , RenewFriend , "RenewFriend" },
	
	-- Serendipity is a passive ability that causes Heal and Flash Heal to reduce the remaining cooldown of Holy Word: Serenity by 6 seconds
	-- Serendipity causes Prayer of Healing Icon Prayer of Healing to reduce the remaining cooldown of Holy Word: Sanctify Icon Holy Word: Sanctify by 6 seconds.
	{ spells.heal, not jps.Moving and jps.hp(LowestImportantUnit) < 0.90 and jps.IncomingDamage(LowestImportantUnit) > jps.IncomingHeal(LowestImportantUnit) , LowestImportantUnit , "Heal_Lowest" },
	{ spells.heal, not jps.Moving and jps.cooldown(spells.holyWordSerenity) > 6 , LowestImportantUnit , "Heal_CD" },
	-- "Renouveau constant" 200153 -- Vos sorts de soins à cible unique réinitialisent la durée de votre Rénovation sur la cible
	{ spells.heal, not jps.Moving and jps.hasTalent(1,2) and jps.cooldown(spells.renew) < 3 , LowestImportantUnit , "Heal_CD" },

	-- "Nova sacrée" 132157
	{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true },
	{ spells.smite, not jps.Moving and canDPS(rangedTarget) , rangedTarget },

}
	spell,target = parseSpellTable(spellTable)
	return spell,target
end , "Holy Priest Default" )

--To maximise your single target HPS:
--Cast Holy Word: Sanctify Icon Holy Word: Sanctify.
--Cast Holy Word: Serenity Icon Holy Word: Serenity.
--Cast Flash Heal Icon Flash Heal until Holy Word: Serenity comes off cooldown.
--Cast Holy Word: Serenity Icon Holy Word: Serenity and repeat step 3.
--
--To maximise your AoE HPS:
--Cast Holy Word: Serenity Icon Holy Word: Serenity.
--Cast Holy Word: Sanctify Icon Holy Word: Sanctify.
--Cast Prayer of Healing Icon Prayer of Healing 3 times.
--Cast Holy Word: Sanctify Icon Holy Word: Sanctify and repeat steps 2 and onward.


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

--------------------------------------------------------------------------------------------------------------
------------------------------------------------ ROTATION OOC ------------------------------------------------
--------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","HOLY",function()

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.80)
	local LowestImportantUnit = jps.LowestImportantUnit()
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.80) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE

	if IsMounted() then return end
	
	local spellTable = {
	
	-- "Esprit de rédemption" buff 27827 "Spirit of Redemption"
	{ "macro", jps.buff(27827) , "/cancelaura Esprit de rédemption"  },

	-- SNM "Levitate" 1706	
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, IsSwimming() and not jps.buff(111759) , "player" },
	
	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" },
	{ spells.bodyAndMind, jps.Moving , "player" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	--{ "macro", jps.itemCooldown(118922) == 0 , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Holy Priest",false,true)