
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

local fnCountInRange = function(pct)
	local Count, _, _ = jps.CountInRaidStatus(pct)
	return Count
end
local fnAvgHealthRaid = function()
	local _, AvgHealth, _ = jps.CountInRaidStatus()
	return AvgHealth
end
local IsRecast = function(spell,unit)
	return jps.isRecast(spell,unit)
end
local DistanceMax = function(unit)
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

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

-- jps.MultiTarget for DPS
-- jps.UseCDs for Dispel
-- jps.Defensive for Heal on mouseover

jps.registerRotation("PRIEST","HOLY", function()

	local spell = nil
	local target = nil

----------------------------
-- LOWEST UNIT
----------------------------

	local CountInRange, AvgHealthRaid, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80) -- CountInRange return raid count unit below healpct -- FriendUnit return table with all raid unit in range
	local LowestUnit, LowestUnitPrev = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}

	local Tank,TankUnit = jps.findRaidTank() -- default "focus" "player"
	local TankTarget = Tank.."target"
	local TankThreat = jps.findRaidTankThreat()

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local ispvp = UnitIsPVP("player")
	local raidCount = #FriendUnit

--	local friendInRange = 0
--	for i=1,#FriendUnit do
--		local unit = FriendUnit[i]
--		local maxRange = jps.distanceMax(unit)
--		if maxRange < 21 and jps.hp(unit) < 0.80 then
--			friendInRange = friendInRange + 1
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
		if not jps.buff(41635,unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingFriendHealth then
				MendingFriend = unit
				MendingFriendHealth = unitHP
			end
		end
	end

	-- "Holy Mending" 196779 causes Prayer of Mending to heal the target instantly for an additional amount whenever it jumps to a player on which Renew is active
	-- Renew on players without "Prayer of Mending" 33076 -- Buff POM 41635 you will increase the likelihood of this trait to proc
	local RenewFriend = nil
	local RenewFriendHealth = 0.85
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		local unitHP = jps.hp(unit)
		if not jps.buff(139,unit) then
			if unitHP < RenewFriendHealth then
				RenewFriend = unit
				RenewFriendHealth = unitHP
			end
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
	local breakpoint = 3
	if IsInRaid() then breakpoint = 5 end
	local SerenityOnCD = true
	if jps.cooldown(spells.holyWordSerenity) == 0 then SerenityOnCD = false end 
	local InterruptTable = {
		{jps.spells.priest.flashHeal, 0.85 , jps.buff(27827) or ispvp }, -- "Esprit de rédemption" 27827
		{jps.spells.priest.heal, 0.95 , jps.buff(27827) or SerenityOnCD },
		{jps.spells.priest.prayerOfHealing , breakpoint , true },
	}

	-- AVOID OVERHEALING
	jps.ShouldInterruptCasting(InterruptTable, CountInRange, AvgHealthRaid)

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
		{ spells.holyWordSerenity , jps.hp(LowestUnit) < 0.65 , LowestUnit  },
		-- "Prière de guérison" 33076
		{ spells.prayerOfMending, not jps.buffTracker(41635) , LowestUnit },
		{ spells.divineHymn , true , LowestUnit },
		-- "Prayer of Healing" 596
		{ spells.prayerOfHealing, AvgHealthRaid < 0.80 , FriendLowest },
		-- "Soins rapides" 2061
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.80 , LowestUnit },
		-- "Renew" 139
		{ spells.renew, not jps.buff(spells.renew,LowestUnit) , LowestUnit },
		{ spells.renew, not jps.buff(spells.renew,LowestUnitPrev) , LowestUnitPrev },
	}},
	
	-- "Levitate" 1706
	{ spells.levitate, jps.Defensive and IsFalling() and not playerHasBuff(111759) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not playerHasBuff(111759) , "player" },

	-- PLAYER AGGRO --
	-- "Médaillon de gladiateur" 208683
	{ 208683, ispvp and playerIsStun , "player" , "playerCC" },
	{ 214027, ispvp and playerIsStun , "player" , "playerCC" },
	-- "Prière du désespoir" 19236 "Desperate Prayer" -- Vous rend 30% de vos points de vie maximum et augmente vos points de vie maximum de 30%, avant de diminuer de 2% chaque seconde.
	{ spells.desperatePrayer, jps.hp("player") < 0.65 , "player" },
	-- "Corps et esprit" 214121
	{ spells.bodyAndMind, jps.Moving , "player" },
	-- "Fade" 586 "Disparition"
	{ spells.fade, not ispvp and playerAggro },
	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.70 , "player" , "Naaru" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.65 and jps.useItem(5512) ,"/use item:5512" },
	-- "Mot sacré : Châtier" 88625
	{ spells.holyWordChastise , ispvp and canDPS(rangedTarget) , rangedTarget },

	-- "Guardian Spirit" 47788
	{ spells.guardianSpirit, jps.hp(TankThreat) < 0.40 and not UnitIsUnit("player",TankThreat) and jps.FriendDamage(TankThreat) * 2 > UnitHealth(TankThreat) , TankThreat },
	{ spells.guardianSpirit, jps.hp(Tank) < 0.40 and not UnitIsUnit("player",Tank) and jps.FriendDamage(Tank) * 2 > UnitHealth(Tank) , Tank },
	{ spells.guardianSpirit, jps.hp(TankThreat) < 0.30 and not UnitIsUnit("player",TankThreat) , TankThreat },
	{ spells.guardianSpirit, jps.hp(Tank) < 0.30 and not UnitIsUnit("player",Tank) , Tank },
	{ spells.guardianSpirit, jps.hp(LowestUnit) < 0.30 , LowestUnit },
	-- "Gardiens de la Lumière" -- Esprit gardien invoque un esprit supplémentaire pour veiller sur vous.
	{ spells.guardianSpirit, jps.hp("player") < 0.30 , LowestUnit },

	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ "macro", jps.useTrinket(1) and CountInRange > 2 , "/use 14"},
	-- "Apotheosis" 200183 increasing the effects of Serendipity by 200% and reducing the cost of your Holy Words by 100%.
	{ spells.apotheosis, jps.hasTalent(7,1) and jps.hp(LowestUnit) < 0.65 },
	
	-- "Soins rapides" 2061 -- "Vague de Lumière" 109186 "Surge of Light" -- gives buff 114255
	{ "nested", jps.buff(114255) ,{
		{ spells.flashHeal, jps.hp("player") < 0.80 , "player" },
		{ spells.flashHeal, jps.hp(TankThreat) < 0.80 and not UnitIsUnit("player",TankThreat) , TankThreat },
		{ spells.flashHeal, jps.hp(Tank) < 0.80 and not UnitIsUnit("player",Tank) , Tank },
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.70 , LowestUnit },
		{ spells.flashHeal, jps.buffDuration(114255) < 4 , LowestUnit },
	}},
	-- "Holy Word: Serenity" 2050
	{ spells.holyWordSerenity, jps.hp(TankThreat) < 0.55 and not UnitIsUnit("player",TankThreat) , TankThreat },
	{ spells.holyWordSerenity, jps.hp(Tank) < 0.50 and not UnitIsUnit("player",Tank) , Tank },
	{ spells.holyWordSerenity, jps.hp("player") < 0.55 , "player" },
	{ spells.holyWordSerenity, jps.hp(LowestUnit) < 0.50 , LowestUnit },
	-- "Light of T'uure" 208065 it buffs the target to increase your healing done to them by 25% for 10 seconds 
	{ spells.lightOfTuure, jps.hp(TankThreat) < 0.80 and not jps.buff(208065,TankThreat) , TankThreat },
	{ spells.lightOfTuure, jps.hp(Tank) < 0.80 and not jps.buff(208065,Tank) , Tank },
	{ spells.lightOfTuure, jps.hp("player") < 0.80 and not jps.buff(208065,"player") , "player" },
	{ spells.lightOfTuure, jps.hp(LowestUnit) < 0.70 and not jps.buff(208065,LowestUnit) , LowestUnit },

	-- "Dispel" "Purifier" 527
	{ spells.purify, jps.canDispel("mouseover","Magic") , "mouseover" },
	{ spells.purify, jps.canDispel("player","Magic") , "player" },
	{ "nested", jps.UseCDs and DispelFriend ~= nil , {
		{ spells.purify, DispelFriendRole ~= nil , DispelFriendRole },
		{ spells.purify, DispelFriend ~= nil , DispelFriend },
	}},
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", ispvp , {
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and jps.DispelOffensive(rangedTarget) , rangedTarget },
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and DispelOffensiveEnemyTarget ~= nil  , DispelOffensiveEnemyTarget },
	}},

	-- "Prière de guérison" 33076 -- Buff POM 41635
	{ spells.prayerOfMending, not jps.Moving and jps.hp(LowestUnit) > 0.55 and not jps.buffTracker(41635) and not UnitIsUnit("player",TankThreat) , TankThreat },
	{ spells.prayerOfMending, not jps.Moving and jps.hp(LowestUnit) > 0.55 and not jps.buffTracker(41635) and MendingFriend ~= nil and not UnitIsUnit("player",MendingFriend) , MendingFriend },
	-- "Guérison sacrée" -- Prière de guérison se propage à une cible affectée par votre Rénovation, elle lui rend instantanément (150% of Spell power) points de vie.
	--{ spells.prayerOfMending, not jps.Moving and jps.hp(LowestUnit) > 0.55 and jps.buffTrackerCharge(41635) < 3 and not jps.buff(41635,TankThreat) , TankThreat },
	--{ spells.prayerOfMending, not jps.Moving and jps.hp(LowestUnit) > 0.55 and jps.buffTrackerCharge(41635) < 3 and MendingFriend ~= nil , MendingFriend },
	{ spells.prayerOfMending, not jps.Moving and jps.hp(LowestUnit) > 0.55 and jps.buffTrackerCharge(41635) < CountInRange and not jps.buff(41635,TankThreat) , TankThreat },
	{ spells.prayerOfMending, not jps.Moving and jps.hp(LowestUnit) > 0.55 and jps.buffTrackerCharge(41635) < CountInRange and MendingFriend ~= nil , MendingFriend },

	-- "Divine Hymn" 64843 should be used during periods of very intense raid damage.
	{ spells.divineHymn , not jps.Moving and jps.buffTracker(41635) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.60 , LowestUnit },
	{ spells.divineHymn , not jps.Moving and jps.buff(197030) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.60 , LowestUnit },
	{ spells.divineHymn , not jps.Moving and jps.buffTracker(41635) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.70 and IsInRaid() , LowestUnit },
	{ spells.divineHymn , not jps.Moving and jps.buff(197030) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.70 and IsInRaid() , LowestUnit },

	-- MOUSEOVER --
	{ "nested", jps.Defensive and jps.hp("mouseover") < 0.80 and canHeal("mouseover") , {
		{ spells.holyWordSerenity, jps.hp("mouseover") < 0.40 , "mouseover" },
		{ spells.guardianSpirit, jps.hp("mouseover") < 0.30 , "mouseover" },
		{ spells.flashHeal, not jps.Moving and jps.hp("mouseover") < 0.65 , "mouseover" },
		{ spells.renew, not jps.buff(spells.renew,"mouseover") and jps.hp("mouseover") < 0.85 , "mouseover" },
		{ spells.heal, not jps.Moving and jps.hp("mouseover") < 0.80 , "mouseover" },
	}},
	
	-- DPS --
	{ "nested", jps.MultiTarget and canDPS(rangedTarget) and jps.hp(LowestUnit) > 0.70 and jps.buffTracker(41635) , {
		{ spells.holyWordChastise , canDPS(rangedTarget) , rangedTarget },
		{ spells.holyFire , canDPS(rangedTarget) , rangedTarget  },
		{ spells.smite , not jps.Moving and canDPS(rangedTarget) , rangedTarget },
		{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true and canDPS("target") , "target" },
	}},
	
	-- PVP --
	{ "nested", ispvp ,{
		{ spells.flashHeal, not jps.Moving and jps.hp("player") < 0.85 , "player" },
		{ spells.flashHeal, not jps.Moving and jps.hp(LowestUnit) < 0.75 , LowestUnit },
		{ spells.renew, not jps.buff(spells.renew,"player") , "player" },
		{ spells.renew, not jps.buff(spells.renew,LowestUnit) , LowestUnit },
		{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true and canDPS("target") , "target" },
	}},
	
	-- "Renew" 139
	{ spells.renew, jps.buffDuration(spells.renew,"player") < 3 and jps.hp("player") < 0.85 and jps.hp(LowestUnit) > 0.55 , "player" },
	{ spells.renew, jps.buffDuration(spells.renew,TankThreat) < 3 and not UnitIsUnit("player",TankThreat) and jps.hp(TankThreat) > 0.55 , TankThreat },
	{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and not UnitIsUnit("player",Tank) and jps.hp(Tank) > 0.55 , Tank },

	-- EMERGENCY HEAL -- "Serendipity" 63733 -- "Benediction" for raid and "Apotheosis" for party
	-- "Soins de lien" 32546
	{ spells.bindingHeal, jps.hp(TankThreat) < 0.65 and not UnitIsUnit("player",TankThreat) and not jps.Moving and jps.unitForBinding(TankThreat) , TankThreat },
	{ spells.bindingHeal, jps.hp(Tank) < 0.65 and not UnitIsUnit("player",Tank) and not jps.Moving and jps.unitForBinding(Tank) , Tank },
	{ spells.bindingHeal, jps.hp(LowestUnit) < 0.65 and not UnitIsUnit("player",LowestUnit) and not jps.Moving and jps.unitForBinding(LowestUnit) , LowestUnit },

	-- "Soins rapides" 2061 -- "Traînée de lumière" 200128 "Trail of Light" -- When you cast Flash Heal, 40% of the healing is replicated to the previous target you healed with Flash Heal.
	{ "nested", not jps.Moving and jps.hasTalent(1,1) and jps.hp(LowestUnit) < 0.70 and jps.LastCastUnit(spells.flashHeal) ~= "none" ,{
		{ spells.flashHeal, jps.LastCastUnit(spells.flashHeal) ~= LowestUnit and CountInRange < 4 , LowestUnit },
		{ spells.flashHeal, IsInRaid() and jps.LastCastUnit(spells.flashHeal) ~= LowestUnit and CountInRange < 6 , LowestUnit },
	}},
	{ "castsequence", jps.cooldown(spells.holyWordSanctify) == 0 and not jps.Moving and not IsInRaid() and jps.hp(TankThreat) > 0.60 and CountInRange > 3 and AvgHealthRaid < 0.80 , { spells.holyWordSanctify , spells.prayerOfHealing } },
	{ "castsequence", jps.cooldown(spells.holyWordSanctify) == 0 and not jps.Moving and IsInRaid() and jps.hp(TankThreat) > 0.60 and CountInRange > 5 and AvgHealthRaid < 0.80 , { spells.holyWordSanctify , spells.prayerOfHealing } },
	{ spells.flashHeal, jps.hp(TankThreat) < 0.60 , TankThreat },
	{ spells.flashHeal, jps.hp(Tank) < 0.60 , Tank },
	{ "nested", not jps.Moving and jps.hp(LowestUnit) < 0.60 and jps.hp(TankThreat) > jps.hp(LowestUnit) and CountInRange < 6 ,{
		{ spells.flashHeal, not IsInRaid() and CountInRange < 4 , LowestUnit },
		{ spells.flashHeal, IsInRaid() , LowestUnit },
	}},
	
	-- "Renew" 139
	{ spells.renew, CountInRange < 4 and not jps.buff(spells.renew,LowestUnit) and jps.hp(LowestUnit) < 0.85 , LowestUnit },
	{ spells.renew, CountInRange < 4 and RenewFriend ~= nil , RenewFriend },
	{ spells.renew, IsInRaid() and jps.hp(TankThreat) > jps.hp(LowestUnit) and CountInRange < 6 and not jps.buff(spells.renew,LowestUnit) and jps.hp(LowestUnit) < 0.85 , LowestUnit },
	{ spells.renew, IsInRaid() and jps.hp(TankThreat) > jps.hp(LowestUnit) and CountInRange < 6 and RenewFriend ~= nil , RenewFriend },
	
	-- "Prayer of Healing" 596 -- A powerful prayer that heals the target and the 4 nearest allies within 40 yards for (250% of Spell power)
	-- "Holy Word: Sanctify" gives buff  "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec.	
	{ "nested", not jps.Moving and CountInRange > 3 ,{
		{ spells.prayerOfHealing, not IsInRaid() and jps.buff(197030) , "player" },
		{ spells.prayerOfHealing, IsInRaid() and jps.buff(197030) and CountInRange > 5 , "player" },
		{ spells.holyWordSanctify, not IsInRaid() and jps.distanceMax(TankThreat) < 21 , TankThreat },
		{ spells.holyWordSanctify, IsInRaid() and CountInRange > 5 and jps.distanceMax(TankThreat) < 21 , TankThreat },
		{ spells.prayerOfHealing, not IsInRaid() , "player" },
		{ spells.prayerOfHealing, IsInRaid() and CountInRange > 5 , "player" },
	}},

	-- "Circle of Healing" 204883
	{ spells.circleOfHealing, jps.Moving and AvgHealthRaid < 0.80 , FriendLowest },
	
	-- "Soins rapides" 2061	
	-- "Soins" 2060 -- "Renouveau constant" 200153 -- Vos sorts de soins à cible unique réinitialisent la durée de votre Rénovation sur la cible
	-- Serendipity is a passive ability that causes Heal and Flash Heal to reduce the remaining cooldown of Holy Word: Serenity by 6 seconds
	-- Serendipity causes Prayer of Healing Icon Prayer of Healing to reduce the remaining cooldown of Holy Word: Sanctify Icon Holy Word: Sanctify by 6 seconds.
	{ "nested", not jps.Moving and jps.hp(LowestUnit) < 0.95 ,{
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.70 and jps.hp(TankThreat) > jps.hp(LowestUnit) , LowestUnit },
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.70 and jps.hp(Tank) > jps.hp(LowestUnit) , LowestUnit },
		{ spells.flashHeal, jps.hp(TankThreat) < 0.70 , TankThreat },
		{ spells.flashHeal, jps.hp(Tank) < 0.70 , Tank },
		{ spells.flashHeal, jps.hp(TankThreat) < 0.80 and SerenityOnCD , TankThreat },
		{ spells.flashHeal, jps.hp(Tank) < 0.80 and SerenityOnCD , Tank },
		
		{ spells.heal, jps.hp(TankThreat) < 0.85 and not SerenityOnCD , TankThreat },
		{ spells.heal, jps.hp(TankThreat) < 0.85 and jps.buff(208065,TankThreat) , TankThreat },
		{ spells.heal, jps.hp(TankThreat) < 0.85 and jps.buff(197030) , TankThreat },
		{ spells.heal, jps.hp(TankThreat) < 0.90 , TankThreat },
		{ spells.heal, jps.hp(LowestUnit) < 0.85 , LowestUnit },

	}},

	-- "Nova sacrée" 132157
	{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true and canDPS("target") , "target" },
	{ spells.smite, not jps.Moving and jps.hp(LowestUnit) > 0.95 and canDPS("target") , "target" },

}
	spell,target = parseSpellTable(spellTable)
	return spell,target
end , "Holy Priest Default" )

--[[
Below, we use the Heal Icon Heal spell to provide you with an example of a mouse-over macro:

    #showtooltip Heal
    /cast [@mouseover,exists,nodead,help][exists,nodead,help][@player] Heal

    If you are mousing over a target which exists, is not dead and is friendly, it will cast Heal on them.
    Otherwise, if your currently selected target exists, is not dead and is friendly, Heal will be cast on them instead.
    Lastly, if neither of the above two conditions are met, it will cast Heal on yourself.

--]]

-- jps.buff(64901) -- "Symbol of Hope" 64901
-- jps.buff(200183) -- "Apotheosis" 200183
-- jps.buff(197030) -- "Holy Word: Sanctify" gives buff "Divinity" 197030
-- jps.buff(196490) -- "Holy Word: Sanctify" gives buff "Puissance des naaru" 196490

--------------------------------------------------------------------------------------------------------------
------------------------------------------------ ROTATION OOC ------------------------------------------------
--------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","HOLY",function()

	local LowestUnit,_ = jps.LowestImportantUnit()
	local Tank,TankUnit = jps.findRaidTank() -- default "focus" "player"

	if IsMounted() then return end
	
	local spellTable = {
	
	-- "Esprit de rédemption" buff 27827 "Spirit of Redemption"
	{ "macro", jps.buff(27827) , "/cancelaura Esprit de rédemption"  },
	
	{ spells.prayerOfMending, not jps.Moving and not jps.buffTracker(41635) and not UnitIsUnit("player",Tank) , Tank , "Tracker_Mending_Tank" },

	-- "Levitate" 1706
	{ spells.levitate, jps.Defensive and IsFalling() and not playerHasBuff(111759) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not playerHasBuff(111759) , "player" },
	
	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" },
	{ spells.bodyAndMind, jps.Moving , "player" },
	{ spells.flashHeal, not jps.Moving and jps.hp("player") < 0.80 , "player" , "Emergency_Player" },
	
	-- "Renew" 139 -- heals because group never want's to stop
	{ spells.renew, not IsInRaid() and not jps.buff(spells.renew,LowestUnit) and jps.hp(LowestUnit) < 0.85 , LowestUnit , "Renew_Topoff" },
	-- "Soins" 2060
	{ spells.heal, not IsInRaid() and jps.hp(LowestUnit) < 0.65 and jps.buff(spells.renew,LowestUnit) , LowestUnit , "Soins_Topoff" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", not jps.buff(156079) and not jps.buff(188031) and jps.useItem(118922) , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Holy Priest",false,true)