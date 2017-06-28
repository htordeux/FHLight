local spells = jps.spells.priest
local UnitIsUnit = UnitIsUnit
local Enemy = { "target", "focus" ,"mouseover" }
local canDPS = jps.canDPS
local HolyWordSanctify = tostring(spells.holyWordSanctify)
local SpiritOfRedemption = tostring(spells.spiritOfRedemption)

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
	return canDPS(unit)
end

local PlayerCanHeal = function(unit)
	return jps.canHeal(unit)
end

local PlayerHasBuff = function(spell)
	return jps.buff(spell,"player")
end

local PlayerBuffDuration = function(spell)
	return jps.buffDuration(spell,"player")
end

local PlayerBuffStacks = function(spell)
	return jps.buffStacks(spell)
end

local PlayerHasTalent = function(row,talent)
	return jps.hasTalent(row,talent)
end

local PlayerCanDispel = function(unit,dispel)
	return jps.CanDispel(unit,dispel)
end

local PlayerCanDispelWith = function(unit,spellID) 
	return jps.CanDispelWith(unit,spellID) 
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
	local LowestUnit = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}
	local Tank,TankUnit = jps.findRaidTank() -- default "focus" "player"
	local TankTarget = Tank.."target"
	local TankThreat,_  = jps.findRaidTankThreat()

	local playerIsTarget = jps.PlayerIsTarget()
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local playerIsTarget = jps.PlayerIsTarget()
	local isPVP= UnitIsPVP("player")
	local raidCount = #FriendUnit
	local playerIsInRaid = IsInRaid()
	local LowestTarget = jps.findLowestTargetInRaid()

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

	local DispelTankRole = nil
	for i=1,#TankUnit do -- for _,unit in ipairs(TankUnit) do
		local unit = TankUnit[i]
		if jps.CanDispel(unit,"Magic") then -- jps.CanDispel includes jps.WarningDebuffs
			DispelTankRole = unit
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

	local threasold = 0.70
	if not playerIsInRaid then threasold = 0.80 end
	local breakpoint = 3
	if playerIsInRaid then breakpoint = 5 end
	
	-- OVERHEALING
	jps.ShouldInterruptCasting()
	jps.ScreenMessage()

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
	{ "nested", PlayerHasBuff(27827) , {
		{ spells.guardianSpirit, jps.hp(LowestUnit) < 0.30 , LowestUnit },
		{ spells.holyWordSerenity , jps.hp(LowestUnit) < 0.60 , LowestUnit  },
		{ spells.prayerOfMending, not jps.buffTracker(41635) , LowestUnit },
		{ spells.prayerOfHealing, AvgHealthRaid < 0.80 , FriendLowest },
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.80 , LowestUnit },
		{ spells.renew, not jps.buff(spells.renew,LowestUnit) , LowestUnit },
	}},
	
	-- "Dispel" "Purifier" 527
	{ "nested", jps.UseCDs , {
		{ spells.purify, PlayerCanDispelWith("mouseover",527) , "mouseover" },
		{ spells.purify, PlayerCanDispelWith("player",527) , "player" },
		{ spells.purify, DispelTankRole ~= nil , DispelTankRole },
		{ spells.purify, DispelMagicTarget() ~= nil , DispelMagicTarget },
	}},
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ "nested", isPVP, {
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and jps.DispelOffensive(rangedTarget) , rangedTarget },
		{ spells.dispelMagic, jps.castEverySeconds(528,4) and jps.DispelOffensive("mouseover") , "mouseover" },
	}},

	-- "Fade" 586 "Disparition"
	{ spells.fade, not isPVP and playerIsTarget },
	-- "Prière du désespoir" 19236 "Desperate Prayer" -- Vous rend 30% de vos points de vie maximum et augmente vos points de vie maximum de 30%, avant de diminuer de 2% chaque seconde.
	{ spells.desperatePrayer, jps.hp("player") < 0.60 , "player" },
	-- "Corps et esprit" 214121
	{ spells.bodyAndMind, jps.Moving and not jps.buff(spells.bodyAndMind,"player") , "player" },
	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.70 , "player" , "Naaru" },
	-- "Pierre de soins" 5512
	{ "macro", jps.hp("player") < 0.60 and jps.useItem(5512) ,"/use item:5512" },
	-- "Renew" 139
	{ spells.renew, jps.buffDuration(spells.renew,"player") < 3 and jps.hpInc("player") < 0.90 , "player" },
	-- "Light of T'uure" 208065
	{ spells.lightOfTuure, jps.hp("player") < 0.70 and not PlayerHasBuff(208065) , "player" },
	-- "Soins de lien" 32546
	{ spells.bindingHeal, not jps.Moving and jps.hp(LowestUnit) < threasold and not jps.Moving and jps.unitForBinding(LowestUnit) , LowestUnit },
	-- "Levitate" 1706 -- buff Levitate 111759
	{ spells.levitate, jps.IsFallingFor(2) and not PlayerHasBuff(spells.levitate) , "player" },
	{ spells.levitate, IsSwimming() and not PlayerHasBuff(spells.levitate) , "player" },
	-- "Médaillon de gladiateur" 208683
	{ 208683, isPVP and playerIsStun , "player" , "playerCC" },
	{ 214027, isPVP and playerIsStun , "player" , "playerCC" },
	
    -- "Holy Word: Sanctify" and "Holy Word: Serenity" gives buff  "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec.
    {"macro", IsShiftKeyDown() , "/cast [@cursor] "..HolyWordSanctify },

	-- "Guardian Spirit" 47788
	-- "Gardiens de la Lumière" -- Esprit gardien invoque un esprit supplémentaire pour veiller sur vous.
	{ spells.guardianSpirit, jps.hp("player") < 0.30 and not UnitIsUnit("player",LowestUnit) , LowestUnit },
	{ spells.guardianSpirit, jps.hp("player") < 0.30 and not UnitIsUnit("player",Tank) , Tank },
	{ "nested", jps.Interrupts ,{
		{ spells.guardianSpirit, jps.hp(Tank) < 0.30 and not UnitIsUnit("player",Tank) and jps.FriendDamage(Tank)*2 > UnitHealth(Tank) , Tank },
		{ spells.guardianSpirit, jps.hp(TankThreat) < 0.30 and not UnitIsUnit("player",TankThreat) and jps.FriendDamage(TankThreat)*2 > UnitHealth(TankThreat) , TankThreat },
		{ spells.guardianSpirit, jps.hp(Tank) < 0.30 and not UnitIsUnit("player",Tank) , Tank },
		{ spells.guardianSpirit, jps.hp(TankThreat) < 0.30 and not UnitIsUnit("player",TankThreat) , TankThreat },
		{ spells.guardianSpirit, jps.hp(LowestUnit) < 0.30 , LowestUnit },
	}},
	
	-- "Prière de guérison" 33076 -- Buff POM 41635 -- Change de cible un maximum de 5 fois et dure 30 sec après chaque changement.
	-- "Guérison sacrée" -- Prière de guérison se propage à une cible affectée par votre Rénovation, elle lui rend instantanément (150% of Spell power) points de vie.
	{ "nested", not jps.Moving and jps.hp(Tank) > 0.60 and jps.buffTrackerCharge(41635) < 5 and jps.buffTrackerDuration(41635) < 15 , {
		{ spells.prayerOfMending, not jps.Moving and not UnitIsUnit("player",Tank) and not jps.buff(41635,Tank) , Tank , "M1" },
		{ spells.prayerOfMending, not jps.Moving and not UnitIsUnit("player",TankThreat) and not jps.buff(41635,TankThreat) , TankThreat , "M2" },
		{ spells.prayerOfMending, not jps.Moving and MendingFriend ~= nil , MendingFriend , "M3" },
	}},
	-- TRINKETS
	-- { "macro", jps.useTrinket(0) , "/use 13"},
	{ "macro", jps.useTrinket(1) and CountInRange > breakpoint , "/use 14"},
	-- "Apotheosis" 200183 increasing the effects of Serendipity by 200% and reducing the cost of your Holy Words by 100% -- "Benediction" for raid and "Apotheosis" for party
	{ spells.apotheosis, PlayerHasTalent(7,1) and jps.hp(LowestUnit) < 0.60 and CountInRange > breakpoint },
	
	-- "Soins rapides" 2061 -- "Vague de Lumière" 109186 "Surge of Light" -- gives buff 114255
	{ "nested", PlayerHasBuff(114255) ,{
		{ spells.flashHeal, jps.hp("player") < 0.80 , "player" },
		{ spells.flashHeal, jps.hp(Tank) < 0.80 and not UnitIsUnit("player",Tank) , Tank },
		{ spells.flashHeal, jps.hp(TankThreat) < 0.80 and not UnitIsUnit("player",TankThreat) , TankThreat },
		{ spells.flashHeal, jps.hp(LowestUnit) < 0.80 , LowestUnit },
		{ spells.flashHeal, jps.buffDuration(114255) < 3 , LowestUnit },
	}},
	-- "Holy Word: Serenity" 2050
	{ spells.holyWordSerenity, jps.hp(Tank) < 0.50 and not UnitIsUnit("player",Tank) , Tank },
	{ spells.holyWordSerenity, jps.hp(TankThreat) < 0.50 and not UnitIsUnit("player",TankThreat) , TankThreat },
	{ spells.holyWordSerenity, jps.hp("player") < 0.40 , "player" },
	{ spells.holyWordSerenity, jps.hp(LowestUnit) < 0.40 , LowestUnit },
	{ spells.holyWordSerenity, CountInRange > breakpoint and not PlayerHasBuff(197030) , LowestUnit },

	-- MOUSEOVER --
	{ "nested", jps.Defensive and PlayerCanHeal("mouseover") , {
		{ spells.guardianSpirit, jps.hp("mouseover") < 0.30 , "mouseover" },
		{ spells.holyWordSerenity, jps.hp("mouseover") < 0.40 , "mouseover" },
		{ spells.prayerOfHealing, not jps.Moving and CountInRange > breakpoint, "mouseover" },
		{ spells.lightOfTuure, jps.hp("mouseover") < 0.70 , "mouseover" },
		{ spells.flashHeal, not jps.Moving and jps.hp("mouseover") < 0.70 , "mouseover" },
		{ spells.renew, not jps.buff(spells.renew,"mouseover") and jps.hpInc("mouseover") < 0.90 , "mouseover" },
		{ spells.heal, not jps.Moving and jps.hp("mouseover") < 0.90 , "mouseover" },
	}},
	
	-- DPS -- "Mot sacré : Châtier" 88625
	{ "nested", jps.MultiTarget and PlayerCanDPS(rangedTarget) and jps.hp(LowestUnit) > jps.hp("target") and jps.hp(LowestUnit) > 0.60 , {
		{ spells.holyWordChastise , true , rangedTarget },
		{ spells.holyFire , true , rangedTarget  },
		{ spells.smite , not jps.Moving , rangedTarget },
		{ spells.holyNova, jps.Moving and CheckInteractDistance(rangedTarget,2) == true , rangedTarget },
	}},

	-- "Light of T'uure" 208065 it buffs the target to increase your healing done to them by 25% for 10 seconds
	{ spells.lightOfTuure, jps.hpRange(Tank,0.60,0.85) and not jps.buff(208065,Tank) , Tank },
	{ spells.lightOfTuure, jps.hpRange(LowestTarget,0.60,0.85) and not jps.buff(208065,LowestTarget) , LowestTarget },
	{ spells.lightOfTuure, jps.hpRange(LowestUnit,0.60,0.85) and not jps.buff(208065,LowestUnit) , LowestUnit },

   	-- "Prayer of Healing" 596 -- A powerful prayer that heals the target and the 4 nearest allies within 40 yards for (250% of Spell power)
	-- "Holy Word: Sanctify" gives buff  "Divinity" 197030 When you heal with a Holy Word spell, your healing is increased by 15% for 8 sec
	-- "Mot sacré : Sanctification" augmente les soins de Prière de soins de 6% pendant 15 sec. Buff "Puissance des naaru" 196490
    {spells.prayerOfHealing, not jps.Moving and PlayerHasBuff(196490) and CountInRange * 2 >= raidCount and CountInRange > breakpoint , "player" },
    {spells.holyWordSanctify, not jps.Moving and CountInRange * 2 >= raidCount and AvgHealthRaid < 0.80 and CountInRange > breakpoint },
	-- "Divine Hymn" 64843 should be used during periods of very intense raid damage.
	{ spells.divineHymn , not jps.Moving and CountInRange * 2 >= raidCount and AvgHealthRaid < 0.70 and raidCount > breakpoint, LowestUnit },
	-- "Prayer of Healing" 596
	{ "nested", not jps.Moving and CountInRange > breakpoint ,{
		{ spells.prayerOfHealing, PlayerHasBuff(197030) , Tank },
		{ spells.prayerOfHealing, PlayerHasBuff(196490) , Tank },
		{ spells.prayerOfHealing, jps.hp("player") < 0.80 , "player" },
	}},

	-- "Renew" 139
	{ spells.renew, jps.buffDuration(spells.renew,Tank) < 3 and not UnitIsUnit("player",Tank) , Tank },
	{ spells.renew, jps.buffDuration(spells.renew,LowestTarget) < 3 and not UnitIsUnit("player",LowestTarget) , LowestTarget },
	{ spells.renew, not playerIsInRaid and jps.buffDuration(spells.renew,LowestUnit) < 3 and jps.hpRange(LowestUnit,0.70,0.95) , LowestUnit , "RenewParty" },
	-- "Circle of Healing" 204883
	{ spells.circleOfHealing, jps.Moving and AvgHealthRaid < 0.80 , FriendLowest },
	
	-- EMERGENCY HEAL -- "Serendipity" 63733
	-- "Soins rapides" 2061 -- "Traînée de lumière" 200128 "Trail of Light" -- When you cast Flash Heal, 40% of the healing is replicated to the previous target you healed with Flash Heal.
	{ spells.flashHeal, not jps.Moving and jps.hp(LowestTarget) < 0.80 and jps.FriendDamage(LowestTarget) > 0 , LowestTarget },
	{ spells.flashHeal, not jps.Moving and jps.hp(Tank) < 0.80 and jps.FriendDamage(Tank) > 0 , Tank },
	{ spells.flashHeal, not jps.Moving and jps.hp(LowestUnit) < threasold , LowestTarget },

	-- "Soins" 2060 -- "Renouveau constant" 200153 -- Vos sorts de soins à cible unique réinitialisent la durée de votre Rénovation sur la cible
	{ spells.heal, not jps.Moving and jps.hpInc(Tank) < 0.90 , Tank },
	{ spells.heal, not jps.Moving and jps.hpInc(LowestUnit) < 0.90 , LowestUnit },
	{ spells.heal, not jps.Moving and holyWordSerenityOnCD() , LowestUnit },
	
	-- "Renew" 139
	{ spells.renew, RenewFriend ~= nil , RenewFriend , "RenewFriend" },

	-- "Nova sacrée" 132157
	{ spells.holyNova, jps.Moving and CheckInteractDistance(rangedTarget,2) == true and PlayerCanDPS(rangedTarget) , rangedTarget },
	-- Your healing spells and Smite have a 8% chance to make your next Flash Heal instant and cost no mana
	{ spells.smite, not jps.Moving and not PlayerHasBuff(114255) and PlayerCanDPS(rangedTarget) , rangedTarget },

}
	local spell,target = ParseSpellTable(spellTable)
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
	local LowestUnit = jps.LowestImportantUnit() -- if jps.Defensive then LowestUnit is {"player","mouseover","target","focus","targettarget","focustarget"}
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
	
	{ spells.prayerOfMending, not jps.Moving and not jps.buffTracker(41635) and not UnitIsUnit("player",Tank) , Tank , "Tracker_Mending_Tank" },

	-- "Levitate" 1706 -- buff Levitate 111759
	--{ "macro", PlayerHasBuff(spells.levitate) and not IsFalling() , "/cancelaura Lévitation"  },
	{ spells.levitate, jps.Defensive and jps.IsFallingFor(2) and not PlayerHasBuff(spells.levitate) , "player" },
	{ spells.levitate, jps.Defensive and IsSwimming() and not PlayerHasBuff(spells.levitate) , "player" },

	-- "Don des naaru" 59544
	{ spells.giftNaaru, jps.hp("player") < 0.80 , "player" },
	{ spells.bodyAndMind, jps.Moving and not jps.buff(spells.bodyAndMind,"player") , "player" },
	{ spells.flashHeal, not jps.Moving and jps.hp("player") < 0.80 , "player" , "Emergency_Player" },
	
	-- "Renew" 139 -- heals because group never want's to stop
	{ spells.renew, not jps.buff(spells.renew,LowestUnit) and jps.hp(LowestUnit) < 0.85 , LowestUnit , "Renew_Topoff" },
	-- "Soins" 2060
	{ spells.heal, jps.hp(LowestUnit) < 0.70 and jps.buff(spells.renew,LowestUnit) , LowestUnit , "Soins_Topoff" },

	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius" -- buff 176151
	{ "macro", not PlayerHasBuff(156079) and not PlayerHasBuff(188031) and jps.useItem(118922) , "/use item:118922" , "Item_Oralius"},

}

	local spell,target = ParseSpellTable(spellTable)
	return spell,target

end,"OOC Holy Priest",false,true)