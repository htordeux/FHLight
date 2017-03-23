local spells = jps.spells.priest
local UnitIsUnit = UnitIsUnit
local Enemy = { "target", "focus" ,"mouseover" }

local CountInRange = function(pct)
	local Count, _, _ = jps.CountInRaidStatus(pct)
	return Count
end
local AvgHealthRaid = function()
	local _, AvgHealth, _ = jps.CountInRaidStatus()
	return AvgHealth
end

local PlayerHealth = function()
	return jps.hp("player")
end

local PlayerIsRecast = function(spell,unit)
	return jps.isRecast(spell,unit)
end

local PlayerDistance = function(unit)
	return jps.distanceMax(unit)
end

local PlayerInsanity = function()
	return jps.insanity()
end

local PlayerMoving = function()
	if select(1,GetUnitSpeed("player")) > 0 then return true end
	return false
end

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

local PlayerCanHeal = function(unit)
	return jps.canHeal(unit)
end

local PlayerHasBuff = function(spell)
	return jps.buff(spell,"player")
end

local PlayerBuffStacks = function(spell)
	return jps.buffStacks(spell)
end

local PlayerHasTalent = function(row,talent)
	return jps.hasTalent(row,talent)
end

local PlayerCanDispel = function(unit,dispel)
	return jps.canDispel(unit,dispel)
end

local PlayerOffensiveDispel = function(unit)
	return jps.DispelOffensive(unit)
end

local DispelDiseaseTarget = function()
	return jps.DispelDiseaseTarget()
end

local DispelMagicTarget = function()
	return jps.DispelMagicTarget()
end

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

-- jps.MultiTarget for DPS
-- jps.UseCDs for Dispel
-- jps.Defensive for Heal on mouseover
-- jps.Interrupts for Guardian Spirit

jps.registerRotation("PRIEST","HOLY", function()

----------------------------
-- LOWEST UNIT
----------------------------

	local CountInRange, AvgHealthRaid, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80) -- CountInRange return raid count unit below healpct -- FriendUnit return table with all raid unit in range
	local LowestUnit, lowestUnitInc = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}
	local Tank,TankUnit = jps.findRaidTank() -- default "focus" "player"
	local TankTarget = Tank.."target"
	local TankThreat,_  = jps.findRaidTankThreat()

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local playerIsTarget = jps.PlayerIsTarget()
	local isPVP= UnitIsPVP("player")
	local raidCount = #FriendUnit
	local isInRaid = IsInRaid()

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

	local rangedTarget  = "target"
	if PlayerCanDPS("target") then rangedTarget =  "target"
	elseif PlayerCanAttack(TankTarget) then rangedTarget = TankTarget
	elseif PlayerCanAttack("targettarget") then rangedTarget = "targettarget"
	elseif PlayerCanAttack("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not PlayerCanHeal("target") and PlayerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

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
	local MendingFriendHealth = 100
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
	local RenewFriendHealth = 0.90
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		local unitHP = jps.hpInc(unit)
		if not jps.buff(spells.renew,unit) then
			if unitHP < RenewFriendHealth then
				RenewFriend = unit
				RenewFriendHealth = unitHP
			end
		end
	end
	
	local RenewTank = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(FriendUnit) do
		if jps.buffDuration(spells.renew,unit) < 3 then
			RenewFriend = unit
		end
	end

------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------


------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------
	local breakpoint = 3
	if isInRaid then breakpoint = 5 end
	local SerenityOnCD = true
	if jps.cooldown(spells.holyWordSerenity) == 0 then SerenityOnCD = false end 
	local InterruptTable = {
		{jps.spells.priest.flashHeal, 0.85 , PlayerHasBuff(27827) or SerenityOnCD}, -- "Esprit de rédemption" 27827
		{jps.spells.priest.heal, 0.95 , PlayerHasBuff(27827) or SerenityOnCD },
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
	{ "nested", PlayerHasBuff(27827) and not UnitIsUnit("player",LowestUnit) , {
		-- "Holy Word: Serenity" 2050
		{ spells.holyWordSerenity , jps.hp(LowestUnit) < 0.65 , LowestUnit  },
		-- "Prière de guérison" 33076
		{ spells.prayerOfMending, not jps.buffTracker(41635) , LowestUnit },
		{ spells.divineHymn ,  AvgHealthRaid < 0.80 , LowestUnit },
		-- "Prayer of Healing" 596
		{ spells.prayerOfHealing, AvgHealthRaid < 0.80 , FriendLowest },
		-- "Soins rapides" 2061
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.80 , LowestUnit },
		-- "Renew" 139
		{ spells.renew, not jps.buff(spells.renew,LowestUnit) , LowestUnit },
	}},
	
	-- "Levitate" 1706
	{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not PlayerHasBuff(spells.levitate) , "player" },
	--{ spells.levitate, jps.Defensive and IsSwimming() and not PlayerHasBuff(spells.levitate) , "player" },

	-- PLAYER AGGRO --
	-- "Médaillon de gladiateur" 208683
	{ 208683, isPVP and playerIsStun , "player" , "playerCC" },
	{ 214027, isPVP and playerIsStun , "player" , "playerCC" },
	-- "Prière du désespoir" 19236 "Desperate Prayer" -- Vous rend 30% de vos points de vie maximum et augmente vos points de vie maximum de 30%, avant de diminuer de 2% chaque seconde.
	{ spells.desperatePrayer, jps.hp("player") < 0.65 , "player" },
	-- "Corps et esprit" 214121
	{ spells.bodyAndMind, jps.Moving , "player" },
	-- "Fade" 586 "Disparition"
	{ spells.fade, not isPVP and playerAggro },
	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.70 , "player" , "Naaru" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.65 and jps.useItem(5512) ,"/use item:5512" },
	-- "Mot sacré : Châtier" 88625
	{ spells.holyWordChastise , isPVP and PlayerCanDPS(rangedTarget) , rangedTarget },

	-- "Guardian Spirit" 47788
	-- "Gardiens de la Lumière" -- Esprit gardien invoque un esprit supplémentaire pour veiller sur vous.
	{ spells.guardianSpirit, jps.hp("player") < 0.30 , LowestUnit },
	{ "nested", jps.Interrupts ,{
		{ spells.guardianSpirit, jps.hp(Tank) < 0.50 and not UnitIsUnit("player",Tank) and jps.FriendDamage(Tank) > UnitHealth(Tank) , Tank },
		{ spells.guardianSpirit, jps.hp(Tank) < 0.30 and not UnitIsUnit("player",Tank) , Tank },
		{ spells.guardianSpirit, jps.hp(TankThreat) < 0.50 and not UnitIsUnit("player",TankThreat) and jps.FriendDamage(TankThreat) > UnitHealth(TankThreat) , TankThreat },
		{ spells.guardianSpirit, jps.hp(TankThreat) < 0.30 and not UnitIsUnit("player",TankThreat) , TankThreat },
		{ spells.guardianSpirit, jps.hp(LowestUnit) < 0.30 , LowestUnit },
	}},

	-- TRINKETS
	-- { "macro", jps.useTrinket(0) , "/use 13"}, -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13
	{ "macro", jps.useTrinket(1) and CountInRange > 2 , "/use 14"}, -- jps.useTrinket(1) est "Trinket1Slot" est slotId  14

	-- "Apotheosis" 200183 increasing the effects of Serendipity by 200% and reducing the cost of your Holy Words by 100%.
	{ spells.apotheosis, jps.hasTalent(7,1) and jps.hp(LowestUnit) < 0.60 and SerenityOnCD },
	{ spells.apotheosis, jps.hasTalent(7,1) and jps.hp(LowestUnit) < 0.60 and AvgHealthRaid < 0.80 },
	
	-- "Soins rapides" 2061 -- "Vague de Lumière" 109186 "Surge of Light" -- gives buff 114255
	{ "nested", PlayerHasBuff(114255) ,{
		{ spells.flashHeal, jps.hp("player") < 0.80 , "player" },
		{ spells.flashHeal, jps.hp(Tank) < 0.80 and not UnitIsUnit("player",Tank) , Tank },
		{ spells.flashHeal, jps.hp(TankThreat) < 0.80 and not UnitIsUnit("player",TankThreat) , TankThreat },
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.80 , LowestUnit },
		{ spells.flashHeal, jps.buffDuration(114255) < 4 , LowestUnit },
	}},
	-- "Holy Word: Serenity" 2050
	{ spells.holyWordSerenity, jps.hp(Tank) < 0.50 and not UnitIsUnit("player",Tank) , Tank },
	{ spells.holyWordSerenity, jps.hp(TankThreat) < 0.50 and not UnitIsUnit("player",TankThreat) , TankThreat },
	{ spells.holyWordSerenity, jps.hp("player") < 0.50 , "player" },
	{ spells.holyWordSerenity, jps.hp(LowestUnit) < 0.40 , LowestUnit },

	-- "Dispel" "Purifier" 527
	{ spells.purify, jps.canDispel("mouseover","Magic") , "mouseover" },
	{ "nested", jps.UseCDs and DispelFriend ~= nil , {
		{ spells.purify, jps.canDispel("player","Magic") , "player" },
		{ spells.purify, DispelFriendRole ~= nil , DispelFriendRole },
		{ spells.purify, DispelFriend ~= nil , DispelFriend },
	}},
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", isPVP, {
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and jps.DispelOffensive(rangedTarget) , rangedTarget },
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and jps.DispelOffensive("mouseover") , "mouseover" },
	}},

	-- "Prière de guérison" 33076 -- Buff POM 41635 -- Change de cible un maximum de 5 fois et dure 30 sec après chaque changement.
	-- "Guérison sacrée" -- Prière de guérison se propage à une cible affectée par votre Rénovation, elle lui rend instantanément (150% of Spell power) points de vie.
	{ "nested", not jps.Moving and jps.hp(LowestUnit) > 0.60 and jps.buffTrackerCharge(41635) < 5 and jps.buffTrackerDuration(41635) < 15 , {
		{ spells.prayerOfMending, not jps.Moving and not UnitIsUnit("player",Tank) and not jps.buff(41635,Tank) , Tank , "M1" },
		{ spells.prayerOfMending, not jps.Moving and not UnitIsUnit("player",TankThreat) and not jps.buff(41635,TankThreat) , TankThreat , "M2" },
		{ spells.prayerOfMending, not jps.Moving and MendingFriend ~= nil , MendingFriend , "M3" },
	}},

	-- "Divine Hymn" 64843 should be used during periods of very intense raid damage.
	{ spells.divineHymn , not jps.Moving and jps.buffTracker(41635) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.60 , LowestUnit },
	{ spells.divineHymn , not jps.Moving and PlayerHasBuff(197030) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.60 , LowestUnit },
	{ spells.divineHymn , not jps.Moving and jps.buffTracker(41635) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.70 and isInRaid , LowestUnit },
	{ spells.divineHymn , not jps.Moving and PlayerHasBuff(197030) and CountInRange * 2 > raidCount and AvgHealthRaid < 0.70 and isInRaid , LowestUnit },

	-- MOUSEOVER --
	{ "nested", jps.Defensive and jps.hp("mouseover") < 0.90 and PlayerCanHeal("mouseover") , {
		{ spells.holyWordSerenity, jps.hp("mouseover") < 0.40 , "mouseover" },
		{ spells.guardianSpirit, jps.hp("mouseover") < 0.30 , "mouseover" },
		{ spells.flashHeal, not jps.Moving and jps.hp("mouseover") < 0.70 , "mouseover" },
		{ spells.renew, not jps.buff(spells.renew,"mouseover") and jps.hpInc("mouseover") < 0.90 , "mouseover" },
		{ spells.heal, not jps.Moving and jps.hp("mouseover") < 0.90 , "mouseover" },
	}},
	
	-- DPS --
	{ "nested", jps.MultiTarget and PlayerCanDPS(rangedTarget) and jps.hp(LowestUnit) > 0.70 , {
		{ spells.holyWordChastise , PlayerCanDPS(rangedTarget) , rangedTarget },
		{ spells.holyFire , PlayerCanDPS(rangedTarget) , rangedTarget  },
		{ spells.smite , not jps.Moving and PlayerCanDPS(rangedTarget) , rangedTarget },
		{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true and PlayerCanDPS("target") , "target" },
	}},
	
	-- "Light of T'uure" 208065 it buffs the target to increase your healing done to them by 25% for 10 seconds
	{ spells.lightOfTuure, jps.BossDebuff(Tank) and not jps.buff(208065,Tank) , Tank },
	{ spells.lightOfTuure, jps.hpRange("player",0.60,0.85) and not PlayerHasBuff(208065) , "player" },
	{ spells.lightOfTuure, jps.hpRange(Tank,0.60,0.85) and not jps.buff(208065,Tank) , Tank },
	{ spells.lightOfTuure, jps.hpRange(LowestUnit,0.60,0.85) and not jps.buff(208065,LowestUnit) , LowestUnit },
	
	-- EMERGENCY HEAL -- "Serendipity" 63733 -- "Benediction" for raid and "Apotheosis" for party
	-- "Soins de lien" 32546
	{ spells.bindingHeal, jps.hp(Tank) < 0.70 and not jps.Moving and jps.unitForBinding(Tank) , Tank },
	{ spells.bindingHeal, jps.hp(TankThreat) < 0.70 and not jps.Moving and jps.unitForBinding(TankThreat) , TankThreat },
	{ spells.bindingHeal, jps.hp(LowestUnit) < 0.70 and not jps.Moving and jps.unitForBinding(LowestUnit) , LowestUnit },
	
	-- "Soins rapides" 2061 -- "Traînée de lumière" 200128 "Trail of Light" -- When you cast Flash Heal, 40% of the healing is replicated to the previous target you healed with Flash Heal.
	{ "nested", not jps.Moving and jps.hasTalent(1,1) and jps.hp(LowestUnit) < 0.80 and jps.LastCastUnit(spells.flashHeal) ~= LowestUnit ,{
		{ spells.flashHeal, jps.LastCastUnit(spells.flashHeal) == Tank and jps.hp(Tank) > jps.hp(LowestUnit) , LowestUnit , "F1" },
		{ spells.flashHeal, CountInRange < 4 , LowestUnit , "F2" },
		{ spells.flashHeal, isInRaid and CountInRange < 6 , LowestUnit , "F2" },
	}},
	{ "nested", not jps.Moving and jps.hp(Tank) < 0.80 ,{
		{ spells.flashHeal,	jps.FriendDamage(Tank)*1.6 > UnitHealth(Tank) , Tank , "FHTankDamage" },
		{ spells.flashHeal, SerenityOnCD , Tank , "FHTank" },
		{ spells.flashHeal, jps.hp(Tank) < 0.70 , Tank , "FHTank" },
	}},
	{ "nested", not jps.Moving and jps.hp(LowestUnit) < 0.70 ,{
		{ spells.flashHeal,	jps.FriendDamage(LowestUnit) > UnitHealth(LowestUnit) , LowestUnit , "FHLowestDamage" },
		{ spells.flashHeal, not isInRaid and CountInRange < 4 , LowestUnit , "FHLowest" },
		{ spells.flashHeal, isInRaid and CountInRange < 6 , LowestUnit , "FHLowest" },
	}},

	-- "Renew" 139
	{ "nested", jps.hp(LowestUnit) > 0.70 ,{
		{ spells.renew, jps.buffDuration(spells.renew,"player") < 3 and jps.hpInc("player") < 0.90 , "player" },
		{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and not UnitIsUnit("player",Tank) , Tank },
		{ spells.renew, RenewTank ~= nil and not UnitIsUnit("player",RenewTank) , RenewTank },
		{ spells.renew, not isInRaid and CountInRange < 4 and not jps.buff(spells.renew,LowestUnit) and jps.hpInc(LowestUnit) < 0.90 , LowestUnit , "RenewParty" },
		{ spells.renew, isInRaid and CountInRange < 6 and not jps.buff(spells.renew,LowestUnit) and jps.hpInc(LowestUnit) < 0.90 , LowestUnit , "RenewRaid" },
	}},

	{ "nested", not jps.Moving and jps.cooldown(spells.holyWordSanctify) == 0 and AvgHealthRaid < 0.80 and jps.distanceMax(TankThreat) < 20 and not UnitIsUnit("player",TankThreat) ,{
		{ "castsequence", not isInRaid and CountInRange > 3 , { spells.holyWordSanctify , spells.prayerOfHealing } },
		{ "castsequence", isInRaid and CountInRange > 5 , { spells.holyWordSanctify , spells.prayerOfHealing } },
	}},

	-- "Prayer of Healing" 596 -- A powerful prayer that heals the target and the 4 nearest allies within 40 yards for (250% of Spell power)
	-- "Holy Word: Sanctify" gives buff  "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec.	
	{ "nested", not jps.Moving and CountInRange > 3 and not isInRaid ,{
		{ spells.prayerOfHealing, PlayerHasBuff(197030) , "player" },
		{ spells.holyWordSanctify, jps.distanceMax(TankThreat) < 20 and not UnitIsUnit("player",TankThreat) , TankThreat },
		{ spells.prayerOfHealing, true , "player" },

	}},
	{ "nested", not jps.Moving and CountInRange > 5 and isInRaid ,{
		{ spells.prayerOfHealing, PlayerHasBuff(197030) , "player" },
		{ spells.holyWordSanctify, jps.distanceMax(TankThreat) < 20 and not UnitIsUnit("player",TankThreat) , TankThreat },
		{ spells.prayerOfHealing, true , "player" },
	}},

	-- "Circle of Healing" 204883
	{ spells.circleOfHealing, jps.Moving and AvgHealthRaid < 0.80 , FriendLowest },
	
	-- "Renew" 139 -- spells.masteryEchoOfLight -- Your direct healing spells heal for an additional 10% over 6 sec.
	{ spells.renew, RenewFriend ~= nil , RenewFriend , "Renew" },

	-- "Soins rapides" 2061	
	-- "Soins" 2060 -- "Renouveau constant" 200153 -- Vos sorts de soins à cible unique réinitialisent la durée de votre Rénovation sur la cible
	-- Serendipity is a passive ability that causes Heal and Flash Heal to reduce the remaining cooldown of Holy Word: Serenity by 6 seconds
	-- Serendipity causes Prayer of Healing Icon Prayer of Healing to reduce the remaining cooldown of Holy Word: Sanctify Icon Holy Word: Sanctify by 6 seconds.
	{ "nested", not jps.Moving and jps.hp(LowestUnit) < 0.95 ,{
		{ spells.heal, jps.hp(Tank) < 0.90 , Tank },
		{ spells.heal, jps.hp(LowestUnit) < 0.85 , LowestUnit },
		{ spells.heal, SerenityOnCD , LowestUnit },
	}},

	-- "Nova sacrée" 132157
	{ spells.holyNova, jps.Moving and CheckInteractDistance("target",2) == true and PlayerCanDPS("target") , "target" },
	-- Your healing spells and Smite have a 8% chance to make your next Flash Heal instant and cost no mana
	{ spells.smite, not jps.Moving and not PlayerHasBuff(114255) and PlayerCanDPS("target") , "target" },

}
	local spell,target = parseSpellTable(spellTable)
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
-- jps.buff(197030) -- "Holy Word: Sanctify" gives buff "Divinity" 197030 -- vos soins sont augmentés de 15% pendant 6 sec.
-- jps.buff(196490) -- "Holy Word: Sanctify" gives buff "Puissance des naaru" 196490

--------------------------------------------------------------------------------------------------------------
------------------------------------------------ ROTATION OOC ------------------------------------------------
--------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","HOLY",function()

	local CountInRange, AvgHealthRaid, FriendUnit, FriendLowest = jps.CountInRaidStatus(0.80) -- CountInRange return raid count unit below healpct -- FriendUnit return table with all raid unit in range
	local LowestUnit, lowestUnitInc = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}
	local Tank,TankUnit = jps.findRaidTank() -- default "focus" "player"

	if IsMounted() then return end
	
	local spellTable = {
	
		-- "Esprit de rédemption" buff 27827 "Spirit of Redemption"
	{ "nested", PlayerHasBuff(27827) and not UnitIsUnit("player",LowestUnit) , {
		-- "Holy Word: Serenity" 2050
		{ spells.holyWordSerenity , jps.hp(LowestUnit) < 0.65 , LowestUnit  },
		-- "Prière de guérison" 33076
		{ spells.prayerOfMending, not jps.buffTracker(41635) , LowestUnit },
		{ spells.divineHymn , AvgHealthRaid < 0.80 , LowestUnit },
		-- "Prayer of Healing" 596
		{ spells.prayerOfHealing, AvgHealthRaid < 0.80 , FriendLowest },
		-- "Soins rapides" 2061
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.80 , LowestUnit },
		-- "Renew" 139
		{ spells.renew, not jps.buff(spells.renew,LowestUnit) , LowestUnit },
	}},

	-- "Esprit de rédemption" buff 27827 "Spirit of Redemption"
	--{ "macro", PlayerHasBuff(27827) , "/cancelaura Esprit de rédemption"  },
	{ "macro", PlayerHasBuff(spells.levitate) and not IsFalling() , "/cancelaura Lévitation"  },
	
	{ spells.prayerOfMending, not jps.Moving and not jps.buffTracker(41635) and not UnitIsUnit("player",Tank) , Tank , "Tracker_Mending_Tank" },

	-- "Levitate" 1706
	{ spells.levitate, jps.IsFallingFor(1) and not PlayerHasBuff(spells.levitate) , "player" },
	{ spells.levitate, IsSwimming() and not PlayerHasBuff(spells.levitate) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" },
	{ spells.bodyAndMind, jps.Moving , "player" },
	{ spells.flashHeal, not jps.Moving and jps.hp("player") < 0.80 , "player" , "Emergency_Player" },
	
	-- "Renew" 139 -- heals because group never want's to stop
	{ spells.renew, not jps.buff(spells.renew,LowestUnit) and jps.hp(LowestUnit) < 0.80 , LowestUnit , "Renew_Topoff" },
	-- "Soins" 2060
	{ spells.heal, jps.hp(LowestUnit) < 0.60 and jps.buff(spells.renew,LowestUnit) , LowestUnit , "Soins_Topoff" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", not PlayerHasBuff(156079) and not PlayerHasBuff(188031) and jps.useItem(118922) , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Holy Priest",false,true)