
local spells = jps.spells.priest
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
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
-- LOWEST UNIT
----------------------------

	local CountInRange, AvgHealthRaid, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80) -- CountInRange return count raid unit below healpct -- FriendUnit return table with all raid unit in range
	local POHTarget, POHGroup, HealthGroup = jps.FindSubGroupHeal(0.80) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local LowestUnit, LowestUnitPrev = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}

	local Tank,TankUnit = jps.findRaidTank() -- default "player"
	local TankTarget = Tank.."target"
	local TankThreat = jps.findRaidTankThreat()

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local ispvp = UnitIsPVP("player")
	local raidCount = #FriendUnit

	-- "Prayer of Healing" 596 -- A powerful prayer that heals the target and the 4 nearest allies within 40 yards for (250% of Spell power)
--	local POHInRange = 0
--	for i=1,#FriendUnit do
--		local unit = FriendUnit[i]
--		local maxRange = jps.distanceMax(unit)
--		if maxRange <= 40 and jps.hp(unit) < 0.80 then
--			POHInRange = POHInRange + 1
--		end
--	end

----------------------
-- TARGET ENEMY
----------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canAttack(TankTarget) then rangedTarget = TankTarget
	elseif canAttack("targettarget") then rangedTarget = "targettarget"
	elseif canAttack("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end

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

	local DispelFriend = jps.DispelMagicTarget() -- "Magic", "Poison", "Disease", "Curse"
	local DispelFriendRole = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(TankUnit) do
		local unit = TankUnit[i]
		if jps.canDispel(unit,"Magic") then -- jps.canDispel includes jps.WarningDebuffs
			DispelFriendRole = unit
		break end
	end

	-- "Holy Mending" 196779 causes Prayer of Mending to heal the target instantly for an additional amount whenever it jumps to a player on which Renew is active
	-- Renew on players without "Prayer of Mending" 33076 -- Buff POM 41635 you will increase the likelihood of this trait to proc	
	local MendingFriend = nil
	local MendingFriendHealth = 1
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.FriendAggro(unit) and not jps.buff(41635,unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingFriendHealth then
				MendingFriend = unit
				MendingFriendHealth = unitHP
			end
		elseif jps.buff(139,unit) and jps.hp(unit) < 0.90 then
			MendingFriend = unit
		end
	end

	-- "Holy Mending" 196779 causes Prayer of Mending to heal the target instantly for an additional amount whenever it jumps to a player on which Renew is active
	-- Renew on players without "Prayer of Mending" 33076 -- Buff POM 41635 you will increase the likelihood of this trait to proc
	local RenewFriend = nil
	local RenewFriendHealth = 1
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		local unitHP = jps.hp(unit)
		if jps.FriendAggro(unit) and not jps.buff(139,unit) then
			if unitHP < RenewFriendHealth then
				RenewFriend = unit
				RenewFriendHealth = unitHP
			end
		elseif not jps.buff(139,unit) and not jps.buff(41635) and jps.hp(unit) < 0.90 then
			RenewFriend = unit
		end
	end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local DispelOffensiveEnemyTarget = nil
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if jps.DispelOffensive(unit) and jps.hp(LowestUnit) > 0.80 then
			DispelOffensiveEnemyTarget = unit
		break end
	end

------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

	local InterruptTable = {
		{jps.spells.priest.flashHeal, 0.80 , jps.buff(27827) or ispvp }, -- "Esprit de rédemption" 27827
		{jps.spells.priest.heal, 0.95 , jps.buff(27827) },
		{jps.spells.priest.prayerOfHealing , 3 , jps.buff(64901) or jps.buff(27827) }, -- "Symbol of Hope" 64901
	}

	-- AVOID OVERHEALING
	jps.ShouldInterruptCasting(InterruptTable , CountInRange , AvgHealthRaid )

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
	{ "macro", jps.buff(27827) and raidCount == 1 , "/cancelaura Esprit de rédemption"  },
	{ "nested", jps.buff(27827) and not UnitIsUnit("player",LowestUnit) , {
		-- "Holy Word: Serenity" 2050
		{ spells.holyWordSerenity , jps.hp(LowestUnit) < 0.60 , LowestUnit  },
		-- "Prière de guérison" 33076
		{ spells.prayerOfMending, true , LowestUnit },
		-- "Prayer of Healing" 596
		{ spells.prayerOfHealing, AvgHealthRaid < 0.80 and CountInRange > 4 and IsInRaid() , FriendLowest },
		{ spells.prayerOfHealing, HealthGroup < 0.80 and POHTarget ~= nil and not IsInRaid()  , POHTarget },
		-- "Soins rapides" 2061
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.80 , LowestUnit },
		-- "Renew" 139
		{ spells.renew, jps.buffDuration(spells.renew,LowestUnit) < 3 , LowestUnit },
	}},
	
	-- SNM "Levitate" 1706	
	{ 1706, jps.Defensive and jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.Defensive and IsSwimming() and not jps.buff(111759) , "player" },

	-- PLAYER AGGRO --
	-- "Médaillon de gladiateur" 208683
	{ 208683, ispvp and playerIsStun , "player" , "playerCC" },
	{ 214027, ispvp and playerIsStun , "player" , "playerCC" },
	-- "Prière du désespoir" 19236 "Desperate Prayer" -- Vous rend 30% de vos points de vie maximum et augmente vos points de vie maximum de 30%, avant de diminuer de 2% chaque seconde.
	{ spells.desperatePrayer, jps.hp("player") < 0.60 , "player" },
	-- "Corps et esprit" 214121
	{ spells.bodyAndMind, jps.Moving , "player" },
	-- "Fade" 586 "Disparition"
	{ spells.fade, not ispvp and jps.FriendAggro("player") },
	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" , "Naaru" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.60 and jps.itemCooldown(5512) == 0 ,"/use item:5512" },
	-- "Renew" 139 PvP
	{ spells.renew, ispvp and jps.buffDuration(spells.renew,"player") < 3 and jps.hp(LowestUnit) > 0.60 , "player" , "Timer_Renew_Player" },
	-- "Mot sacré : Châtier" 88625
	{ spells.holyWordChastise , ispvp and canDPS(rangedTarget) , rangedTarget },
	{ "nested", jps.Defensive and canDPS(rangedTarget) and jps.hp(LowestUnit) > 0.60  , {
		{ spells.holyWordChastise , canDPS(rangedTarget) , rangedTarget },
		{ spells.holyFire , canDPS(rangedTarget) , rangedTarget  },
		{ spells.smite , not jps.Moving and canDPS(rangedTarget) , rangedTarget },
		{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true },
	}},

	-- "Guardian Spirit" 47788
	-- "Gardiens de la Lumière" -- Esprit gardien invoque un esprit supplémentaire pour veiller sur vous.
	{ spells.guardianSpirit, jps.hp(TankThreat) < 0.50 and jps.FriendDamage(TankThreat) * 2 > UnitHealth(TankThreat) , TankThreat , "Damage_Guardian_Tank" },
	{ spells.guardianSpirit, jps.hp(TankThreat) < 0.30 and not UnitIsUnit("player",TankThreat) , TankThreat , "Emergency_Guardian_Tank" },
	{ spells.guardianSpirit, jps.hp(Tank) < 0.30 and not UnitIsUnit("player",Tank) , Tank , "Emergency_Guardian_Tank" },
	{ spells.guardianSpirit, jps.hp(LowestUnit) < 0.30 , LowestUnit , "Emergency_Guardian_Lowest" },
	{ spells.guardianSpirit, jps.hp("player") < 0.30 , "player" , "Emergency_Guardian_Player" },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ "macro", jps.useTrinket(1) and CountInRange > 2 , "/use 14"},
	-- "Apotheosis" 200183 increasing the effects of Serendipity by 200% and reducing the cost of your Holy Words by 100%.
	{ spells.apotheosis, jps.hasTalent(7,1) and jps.hp(Tank) < 0.60 },
	{ spells.apotheosis, jps.hasTalent(7,1) and jps.hp(LowestUnit) < 0.60 },
	
	-- "Soins rapides" 2061 -- "Vague de Lumière" 109186 "Surge of Light" -- gives buff 114255
	{ "nested", jps.buff(114255) ,{
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.60 , LowestUnit , "FlashHeal_Surge" },
		{ spells.flashHeal, jps.hp("player") < 0.80 , "player" , "FlashHeal_Surge" },
		{ spells.flashHeal, jps.hp(TankThreat) < 0.80 and not UnitIsUnit("player",TankThreat) , TankThreat, "FlashHeal_Surge" },
		{ spells.flashHeal, jps.hp(Tank) < 0.80 and not UnitIsUnit("player",Tank) , Tank , "FlashHeal_Surge" },
		{ spells.flashHeal, jps.buffDuration(114255) < 4 , LowestUnit , "FlashHeal_Surge" },
	}},
	-- "Light of T'uure" 208065 it buffs the target to increase your healing done to them by 25% for 10 seconds 
	{ spells.lightOfTuure, jps.hp(TankThreat) < 0.80 and not jps.buff(208065,TankThreat) , TankThreat , "Tuure_Tank" },
	{ spells.lightOfTuure, jps.hp(Tank) < 0.80 and not jps.buff(208065,Tank) , Tank , "Tuure_Tank" },
	{ spells.lightOfTuure, jps.hp(LowestUnit) < 0.60 and not jps.buff(208065,LowestUnit) , LowestUnit, "Tuure_Lowest" },
	-- "Holy Word: Serenity" 2050
	{ spells.holyWordSerenity, jps.hp("player") < 0.60 , "player" , "Emergency_player" },
	{ spells.holyWordSerenity, jps.hp(TankThreat) < 0.60 and not UnitIsUnit("player",TankThreat) , TankThreat , "Emergency_Tank" },
	{ spells.holyWordSerenity, jps.hp(Tank) < 0.60 and not UnitIsUnit("player",Tank) , Tank , "Emergency_Tank" },
	{ spells.holyWordSerenity, jps.hp(LowestUnit) < 0.40 , LowestUnit  , "Emergency_Lowest" },

	-- "Dispel" "Purifier" 527
	{ "nested", jps.UseCDs and DispelFriend ~= nil , {
		{ spells.purify, jps.canDispel("mouseover","Magic") , "mouseover" , "|cff1eff00Dispel" },
		{ spells.purify, jps.canDispel("player","Magic") , "player" , "|cff1eff00Dispel" },
		{ spells.purify, DispelFriendRole ~= nil , DispelFriendRole , "|cff1eff00DispelFriendRole" },
		{ spells.purify, true , DispelFriend , "|cff1eff00DispelFriend" },
	}},
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", ispvp and jps.hp(LowestUnit) > 0.60 , {
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and DispelOffensiveEnemyTarget ~= nil  , DispelOffensiveEnemyTarget , "|cff1eff00DispelOffensive_MULTITARGET_" },
	}},

	-- MOUSEOVER
	{ "nested", jps.Interrupts and jps.hp("mouseover") < 0.95 and canHeal("mouseover") , {
		{ spells.flashHeal, not jps.Moving and jps.hp("mouseover") < 0.60 , "mouseover" },
		{ spells.renew, not jps.buff(spells.renew,"mouseover") and jps.hp("mouseover") < 0.95 , "mouseover" },
		{ spells.holyWordSerenity, jps.hp("mouseover") < 0.40 , "mouseover" },
		{ spells.heal, not jps.Moving and jps.hp("mouseover") < 0.95 , "mouseover" },
	}},

	-- "Prière de guérison" 33076 -- Buff POM 41635
	{ "nested", not jps.Moving and not jps.buffTracker(41635) and jps.hp(LowestUnit) > 0.40 ,{
		{ spells.prayerOfMending, not UnitIsUnit("player",TankThreat) , TankThreat , "Tracker_Mending_Tank" },
		{ spells.prayerOfMending, not UnitIsUnit("player",Tank) , Tank , "Tracker_Mending_Tank" },
		{ spells.prayerOfMending, MendingFriend ~= nil , MendingFriend , "Tracker_Mending_Friend" },
	}},
	{ spells.prayerOfMending, not jps.buff(41635,TankThreat) and not jps.Moving and CountInRange > 4 and IsInRaid() , TankThreat , "POM_CountInRange" },
	{ spells.prayerOfMending, not jps.buff(41635,Tank) and not jps.Moving and CountInRange > 4 and IsInRaid() , Tank , "POM_CountInRange" },
	{ spells.prayerOfMending, MendingFriend ~= nil and not jps.Moving and CountInRange > 2 and not IsInRaid() , MendingFriend , "POM_CountInRange" },

	-- "Divine Hymn" 64843 should be used during periods of very intense raid damage.
	{ spells.divineHymn , not jps.Moving and jps.buffTracker(41635) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.60 and not IsInRaid() , LowestUnit },
	{ spells.divineHymn , not jps.Moving and jps.buff(197030) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.70 and IsInRaid() , LowestUnit },

	-- EMERGENCY HEAL -- "Serendipity" 63733 -- "Benediction" for raid and "Apotheosis" for party
	-- "Soins de lien" 32546
	{ spells.bindingHeal, jps.hp(TankThreat) < 0.60 and not UnitIsUnit("player",TankThreat) and not jps.Moving and jps.unitForBinding(TankThreat) , TankThreat , "Emergency_Lien" },
	{ spells.bindingHeal, jps.hp(Tank) < 0.60 and not UnitIsUnit("player",Tank) and not jps.Moving and jps.unitForBinding(Tank) , Tank , "Emergency_Lien" },
	{ spells.bindingHeal, jps.hp(LowestUnit) < 0.60 and not UnitIsUnit("player",LowestUnit) and not jps.Moving and jps.unitForBinding(LowestUnit) , LowestUnit , "Emergency_Lien" },
	-- "Soins rapides" 2061
	{ spells.flashHeal, ispvp and not jps.Moving and jps.hp("player") < 0.80 , "player" , "Emergency_player" },
	{ spells.flashHeal, ispvp and not jps.Moving and jps.hp(LowestUnit) < 0.80 , LowestUnit , "Emergency_Lowest" },

	-- "Renew" 139
	{ spells.renew, jps.buffDuration(spells.renew,TankThreat) < 3 and jps.hp(LowestUnit) > 0.60 and not UnitIsUnit("player",TankThreat) , TankThreat , "Timer_Renew_Tank" },
	{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and jps.hp(LowestUnit) > 0.60 and not UnitIsUnit("player",Tank) , Tank , "Timer_Renew_Tank" },
	{ spells.renew, jps.buffDuration(spells.renew,"player") < 3 and jps.hp(LowestUnit) > 0.60 and jps.hp("player") < 0.95 , "player" , "Timer_Renew_Player" },
	{ spells.renew, jps.hp(Tank) > jps.hp(LowestUnit) and jps.hp(LowestUnit) < 0.90 and not jps.buff(spells.renew,LowestUnit) and CountInRange < 3 and not IsInRaid() , LowestUnit , "Renew_Lowest" },
	{ spells.renew, jps.hp(Tank) > jps.hp(LowestUnit) and jps.hp(LowestUnit) < 0.90 and not jps.buff(spells.renew,LowestUnit) and CountInRange < 5 and IsInRaid() , LowestUnit , "Renew_Lowest" },
	
	-- "Soins rapides" 2061
	{ spells.flashHeal, not jps.Moving and jps.hp(TankThreat) < 0.60 , TankThreat , "Emergency_Tank"  },
	{ spells.flashHeal, not jps.Moving and jps.hp(Tank) < 0.60 , Tank , "Emergency_Tank"  },
	{ spells.flashHeal, not jps.Moving and jps.hp(TankThreat) > jps.hp(LowestUnit) and jps.hp(LowestUnit) < 0.40 , LowestUnit , "Emergency_Lowest_40" },
	{ spells.flashHeal, not jps.Moving and jps.hp(LowestUnit) < 0.60 and CountInRange < 5 and IsInRaid() , LowestUnit , "Emergency_Lowest_60" },
	{ spells.flashHeal, not jps.Moving and jps.hp(LowestUnit) < 0.60 and CountInRange < 3 and not IsInRaid()  , LowestUnit , "Emergency_Lowest_60" },

	-- jps.buff(64901) -- "Symbol of Hope" 64901
	-- jps.buff(200183) -- "Apotheosis" 200183
	-- jps.buff(197030) -- "Holy Word: Sanctify" gives buff "Divinity" 197030
	-- jps.buff(196490) -- "Holy Word: Sanctify" gives buff "Puissance des naaru" 196490 -- range 10 y
	{ "nested", not IsInRaid() and CountInRange > 2 ,{
		-- "Prayer of Healing" 596 -- A powerful prayer that heals the target and the 4 nearest allies within 40 yards for (250% of Spell power)
		{ spells.prayerOfHealing, not jps.Moving  and jps.buff(197030) , "player" , "POH_CountInRange" },
		--  not moving for holyWordSanctify to be sure to do not cast anywhere
		{ spells.holyWordSanctify, not jps.Moving and jps.distanceMax(Tank) < 21 , "player", "Sanctify_CountInRange" },
	}},
	{ "nested", IsInRaid() and CountInRange > 4 ,{
		-- "Prayer of Healing" 596 -- A powerful prayer that heals the target and the 4 nearest allies within 40 yards for (250% of Spell power)
		{ spells.prayerOfHealing, not jps.Moving  and jps.buff(197030) , "player" , "POH_CountInRange" },
		--  not moving for holyWordSanctify to be sure to do not cast anywhere
		{ spells.holyWordSanctify, not jps.Moving and jps.distanceMax(Tank) < 21 , "player", "Sanctify_CountInRange" },
	}},

	-- PARTY MultiTarget
	{ "nested", not IsInRaid() and POHTarget ~= nil and HealthGroup < 0.80 ,{
		-- "Holy Word: Sanctify" gives buff  "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec.
		{ spells.holyWordSanctify, not jps.Moving and jps.distanceMax(Tank) < 21  , POHTarget , "Sanctify_POHTarget" },
		-- "Prayer of Healing" 596
		--{ "castsequence", jps.cooldown(spells.holyWordSanctify) == 0 and POHTarget ~= nil and HealthGroup < 0.80 , { spells.holyWordSanctify , spells.prayerOfHealing , spells.prayerOfHealing  } },
		{ spells.prayerOfHealing, not jps.Moving , POHTarget , "POHTarget" },
		-- "Circle of Healing" 204883
		{ spells.circleOfHealing, true , POHTarget },
	}},
	-- RAID MultiTarget
	{ "nested", IsInRaid() and CountInRange > 4 and AvgHealthRaid < 0.80 ,{
		-- "Holy Word: Sanctify" gives buff  "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec.
		{ spells.holyWordSanctify, not jps.Moving and jps.distanceMax(Tank) < 21 , FriendLowest, "Sanctify_POHFriend" },
		-- "Prayer of Healing" 596
		{ spells.prayerOfHealing, not jps.Moving , FriendLowest , "POHFriend" },
		-- "Circle of Healing" 204883
		{ spells.circleOfHealing, true , FriendLowest },	
	}},

	-- "Soins" 2060 -- "Renouveau constant" 200153 -- Vos sorts de soins à cible unique réinitialisent la durée de votre Rénovation sur la cible
	-- Serendipity is a passive ability that causes Heal and Flash Heal to reduce the remaining cooldown of Holy Word: Serenity by 6 seconds
	-- Serendipity causes Prayer of Healing Icon Prayer of Healing to reduce the remaining cooldown of Holy Word: Sanctify Icon Holy Word: Sanctify by 6 seconds.
	{ "nested", not jps.Moving ,{
		{ spells.flashHeal, not jps.Moving and jps.hp(TankThreat) < 0.70 , TankThreat , "Emergency_Tank_70"  },
		{ spells.flashHeal, not jps.Moving and jps.hp(TankThreat) < 0.80 and jps.FriendDamage(TankThreat) * 2 > UnitHealth(TankThreat) , TankThreat , "Emergency_Tank_80"  },
		{ spells.heal, jps.hp(TankThreat) < 0.95 , TankThreat , "Soins_Tank"  },
		{ spells.heal, jps.hp(Tank) < 0.95 , Tank , "Soins_Tank"  },
		{ spells.heal, jps.hp(LowestUnit) < 0.95 and jps.cooldown(spells.holyWordSerenity) > 0 , LowestUnit , "Heal_CD_Serenity" },
	}},

	-- "Renew" 139
	{ spells.renew, RenewFriend ~= nil , RenewFriend , "Renew_Friend" },

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

--------------------------------------------------------------------------------------------------------------
------------------------------------------------ ROTATION OOC ------------------------------------------------
--------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","HOLY",function()

	local LowestUnit,_ = jps.LowestImportantUnit()

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
	{ "macro", not jps.buff(156079) and not jps.buff(188031) and jps.itemCooldown(118922) == 0 , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Holy Priest",false,true)