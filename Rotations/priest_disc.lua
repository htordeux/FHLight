
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

jps.registerRotation("PRIEST","DISCIPLINE", function()

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
	
	local DispelFriendPvE = jps.canDispelUnit( "Magic" ) -- {"Magic", "Poison", "Disease", "Curse"}
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

	-- FACING ANGLE -- jps.PlayerIsFacing(LowestImportantUnit,45) -- angle value between 10-180
	local CountFriendIsFacing = 0
	local FriendIsFacingLowest = nil
	local FriendIsFacingHeath = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.hp(unit) < 0.90 and canHeal(unit) then
			if jps.Distance(unit) < 30 and jps.PlayerIsFacing(unit,90) then
				CountFriendIsFacing = CountFriendIsFacing + 1
				local unitHP = jps.hp(unit)
				if unitHP < FriendIsFacingHeath then
					FriendIsFacingLowest = unit
					FriendIsFacingHeath = unitHP
				end
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
		{ 527, DispelFriendPvE ~= nil , DispelFriendPvE , "|cff1eff00DispelFriend_PvE" },
	}

------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

	local InterruptTable = {
		{jps.spells.priest.flashHeal, 0.80, jps.buff(172359) },
		{jps.spells.priest.heal, 0.90, jps.PvP },
		{jps.spells.priest.prayerOfHealing, 0.80, jps.buff(10060) or jps.buff(172359) or jps.PvP },
	}

	-- AVOID OVERHEALING
	jps.ShouldInterruptCasting(InterruptTable , groupHealth , CountFriendLowest)

------------------------
-- SPELL TABLE ---------
------------------------

local spellTable = {

	-- SNM "Levitate" 1706
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	-- "Angelic Feather" 121536 "Plume angélique"
	{ 121536, IsControlKeyDown() },

	-- SNM "Chacun pour soi" 59752 "Every Man for Himself" -- Human
	{ 59752, playerIsStun , "player" , "Every_Man_for_Himself" },
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 },
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun and jps.combatStart > 0 },

	-- "Suppression de la douleur" 33206 "Pain Suppression" -- Buff "Pain Suppression" 33206
	{ 33206, jps.hp(TankThreat) < 0.30 and UnitAffectingCombat(TankThreat) , TankThreat , "Pain_TankThreat" },
	{ 33206, jps.hp(Tank) < 0.30 and UnitAffectingCombat(Tank) , Tank , "Pain_Tank" },
	{ 33206, jps.hp("player") < 0.40 and UnitAffectingCombat("player") , "player" , "Pain_player" },
	{ 33206, jps.hp(LowestImportantUnit) < 0.40 and UnitAffectingCombat(LowestImportantUnit) , LowestImportantUnit , "Pain_Lowest" },

	-- "Soins rapides" 2061 -- "Vague de Lumière" 109186 "Surge of Light" -- gives buff 114255
	{ 2061, jps.buff(114255) and jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit , "FlashHeal_Light" },
	{ 2061, jps.buff(114255) and jps.buffDuration(114255) < 4 , LowestImportantUnit , "FlashHeal_Light" },
	-- "Saving Grace" 152116 "Grâce salvatrice"
	{ 152116, jps.hp("player") < 0.40 and jps.debuffStacks(155274,"player") < 2 , "player" , "Emergency_SavingGrace" },
	{ 152116, jps.hp(LowestImportantUnit) < 0.40 and jps.debuffStacks(155274,"player") < 2 , LowestImportantUnit , "Emergency_SavingGrace" },
	-- "Pénitence" 47540
	{ 47540, jps.hpInc(LowestImportantUnit) < 0.50 , LowestImportantUnit , "Emergency_Penance" },
	-- "Soins rapides" 2061 -- Buff Borrowed 59889 -- Buff infusion 10060
	{ 2061, not jps.Moving and jps.hpInc("player") < 0.50 and jps.buff(59889) and jps.buff(10060) ,"player" , "FlashHeal_Borrowed"  },
	{ 2061, not jps.Moving and jps.hpInc(LowestImportantUnit) < 0.50 and jps.buff(59889) and jps.buff(10060) , LowestImportantUnit , "FlashHeal_Borrowed"  },

	-- DISPEL --
	-- "Dispel" 527 "Purifier" -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
	{ 527, jps.canDispel("player","Magic") , "player" , "Aggro_Dispel" },
	{ 527, jps.canDispel("mouseover") , "mouseover" , "Dispel_Mouseover"},
	{ "nested", jps.UseCDs , parseDispel },

	-- PLAYER AGGRO --
	{ "nested", playerAggro or playerIsTargeted ,{
		-- "Spectral Guise" 112833 "Semblance spectrale" Buff 119032 -- "Glyph of Shadow Magic" 159628 -- Buff "Shadow Magic" 159630 "Magie des Ténèbres"
		{ 112833, jps.Interrupts and jps.IsSpellKnown(112833) and not jps.buff(159630) , "player" , "Aggro_Spectral" },
		-- "Fade" 586 "Oubli" -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
		{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
		-- "Fade" 586 "Oubli" -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même
		{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
		-- "Power Word: Shield" 17
		{ 17, not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield" },
		-- "Prière du désespoir" 19236
		{ 19236, jps.hp() < 0.60 and jps.IsSpellKnown(19236) , "player" , "Aggro_DESESPERATE" },
		-- "Pierre de soins" 5512
		{ {"macro","/use item:5512"}, jps.hp() < 0.60 and jps.itemCooldown(5512) == 0 , "player" , "Aggro_Item5512" },
		-- "Pénitence" 47540
		{ 47540, jps.hp() < 0.80 , "player" , "Aggro_Penance" },
		-- "Don des naaru" 59544
		{ 59544, jps.hp() < 0.80 , "player" , "Aggro_Naaru" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving and jps.hp() < 0.60 , "player" , "Aggro_FlashHeal" },
	}},
	
	-- DAMAGE --
	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, jps.IsSpellInRange(129250,rangedTarget) and canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace" },
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, jps.IsSpellInRange(14914,rangedTarget) and canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes" },

	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,8) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive" },
	-- CONTROL --
	{ 15487, SilenceEnemyTarget ~= nil , SilenceEnemyTarget , "Silence_MultiUnit" },
	{ "nested", jps.PvP and not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },
	-- "Leap of Faith" 73325 -- "Saut de foi"
	{ 73325, jps.PvP and LeapFriend ~= nil , LeapFriend , "|cff1eff00Leap_MultiUnit" },
	-- "Gardien de peur" 6346
	{ 6346, jps.PvP and not jps.buff(6346,"player") and jps.hp() > 0.80 , "player" },
	-- SNM "Levitate" 1706 -- "Dark Simulacrum" debuff 77606
	{ 1706, jps.PvP and jps.debuff(77606,"player") , "player" , "DarkSim_Levitate" },
	
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ "nested", not jps.Moving and CountFriendLowest > 2 and jps.hpSum(LowestImportantUnit) > 0.60 ,{
		{ 33076, canHeal(TankThreat) , TankThreat , "Tracker_Mending_TankThreat" },
		{ 33076, canHeal(Tank) , Tank , "Tracker_Mending_Tank" },
		{ 33076, MendingFriend ~= nil , MendingFriend , "Mending_CountFriendLowest" },
		{ 33076, not jps.buff(41635,LowestImportantUnit) , LowestImportantUnit , "Mending_CountFriendLowest" },
	}},
	
	-- EMERGENCY HEAL --
	{ 596, jps.MultiTarget and not jps.Moving and POHTarget ~= nil and canHeal(POHTarget) and jps.buff(59889) and jps.hpSum(LowestImportantUnit) > 0.40 , POHTarget , "Borrowed_POH" },
	{ "nested", groupHealth > 0.80 and jps.hp(TankThreat) > 0.80 and jps.hp(Tank) > 0.80 and jps.hp(LowestImportantUnit) < 0.60 ,{
		-- "Power Word: Shield" 17 -- Keep Buff "Borrowed" 59889 always
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield" },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance" },
		-- "Soins rapides" 2061 -- Buff "Borrowed" 59889 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 2061, not jps.Moving and jps.buff(172359) , LowestImportantUnit , "Emergency_FlashHeal_Archange" },
		{ 2061, not jps.Moving and jps.buff(10060) , LowestImportantUnit , "Emergency_FlashHeal_Infusion" },
	}},

	-- TANK THREAT --
	-- "Power Word: Shield" -- Keep Buff "Borrowed" 59889 always
	{ 17, canHeal(TankThreat) and not jps.buff(17,TankThreat) and not jps.debuff(6788,TankThreat) , TankThreat , "Shield_TankThreat" },
	{ 17, canHeal(Tank) and not jps.buff(17,Tank) and not jps.debuff(6788,Tank) , Tank , "Shield_Tank" },
	{ 17, ShieldFriend ~= nil and not jps.buff(59889) , ShieldFriend , "ShieldFriend" },
	{ 17, UnitIsPlayer("targettarget") and canHeal("targettarget") and not jps.buff(17,"targettarget") and not jps.debuff(6788,"targettarget") , "targettarget" , "Shield_targettarget" },
	-- "Power Word: Shield" 17 -- "Body and Soul" 65081 buff -- Glyph of Reflective Shield 33202
	{ 17, jps.glyphInfo(33202) and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Defensive_Shield" },
	{ 17, not jps.buff(65081,"player") and jps.Moving and BodyAndSoul and not jps.debuff(6788,"player") , "player" , "Shield_Moving" },
	-- "Archange" 81700 -- Buff 81700 -- Buff "Archange surpuissant" 172359  100 % critique POH or FH
	{ 81700, jps.buffStacks(81661) == 5 and  jps.hp(TankThreat) < 0.70 , "player" , "ARCHANGE_TankThreat" },
	{ 81700, jps.buffStacks(81661) == 5 and  jps.hp(Tank) < 0.70 , "player" , "ARCHANGE_Tank" },
	-- "Pénitence" 47540
	{ 47540, canHeal(TankThreat) and jps.hp(TankThreat) < 0.80 , TankThreat , "Penance_TankThreat" },
	-- "Soins rapides" 2061 -- Buff "Archange surpuissant" 172359  100 % critique POH or FH
	{ 2061, canHeal(TankThreat) and jps.hp(TankThreat) < 0.60 and jps.buff(172359) , TankThreat , "FlashHeal_TankThreat" },
	-- "Soins" 2060
	{ 2060, groupHealth > 0.80 and not jps.Moving and canHeal(TankThreat) and jps.hpInc(TankThreat) < 0.90 and jps.hpSum(TankThreat) > 0.60 , TankThreat , "Soins_TankThreat"  },
	{ 2060, groupHealth > 0.80 and not jps.Moving and canHeal(Tank) and jps.hpInc(Tank) < 0.90 and jps.hpSum(Tank) > 0.60 , Tank , "Soins_Tank"  },
	-- "Soins rapides" 2061
	{ 2061, groupHealth > 0.80 and not jps.Moving and canHeal(TankThreat) and jps.hpInc(TankThreat) < 0.90 and jps.hpSum(TankThreat) < 0.60 , TankThreat , "FlashHeal_TankThreat"  },
	{ 2061, groupHealth > 0.80 and not jps.Moving and canHeal(Tank) and jps.hpInc(Tank) < 0.90 and jps.hpSum(Tank) < 0.60 , Tank , "FlashHeal_Tank"  },

	-- "Power Infusion" 10060 "Infusion de puissance"
	{ 10060, jps.hp(LowestImportantUnit) < 0.50 , "player" , "POWERINFUSION_Lowest" },
	{ 10060, groupHealth < 0.80 , "player" , "POWERINFUSION_POH" },
	{ 10060, CountFriendLowest > 3 , "player" , "POWERINFUSION_Count" },
	-- SNM Troll "Berserker" 26297 -- Haste Buff
	{ 26297, CountFriendEmergency > 1 , "player" },

	-- "Divine Star" Holy 110744 Shadow 122121
	{ 110744, FriendIsFacingLowest ~= nil and CountFriendIsFacing > 3 , FriendIsFacingLowest ,  "DivineStar_Count" },
	{ 110744, FriendIsFacingLowest ~= nil and jps.hp(FriendIsFacingLowest) < 0.80 , FriendIsFacingLowest ,  "DivineStar_Lowest" },
	-- "Cascade" Holy 121135 Shadow 127632
	{ 121135, not jps.Moving and CountFriendEmergency > 2 , LowestImportantUnit ,  "Cascade_Emergency" },
	{ 121135, not jps.Moving and CountFriendLowest > 3 , LowestImportantUnit ,  "Cascade_Count" },
	{ 121135, not jps.Moving and POHTarget ~= nil and canHeal(POHTarget) , POHTarget ,  "Cascade_POH" },

	-- "Archange" 81700 -- Buff 81700 -- Buff "Archange surpuissant" 172359  100 % critique POH or FH
	{ 81700, jps.buffStacks(81661) == 5 and  groupHealth < 0.80 , "player", "ARCHANGE_POH" },
	{ 81700, jps.buffStacks(81661) == 5 and  jps.hp(LowestImportantUnit) < 0.60 , "player", "ARCHANGE_Lowest" },

	-- GROUP HEAL --
	{ "nested", not jps.Moving and POHTarget ~= nil and canHeal(POHTarget) ,{
		-- "POH" 596 -- Buff "Archange surpuissant" 172359  100 % critique POH or FH
		{ 596, jps.buff(172359) , POHTarget , "Archange_POH" },
		-- "POH" 596 -- "Power Infusion" 10060 "Infusion de puissance"
		{ 596, jps.buff(10060) , POHTarget , "PowerInfusion_POH" },
		-- "POH" 596 -- Buff "Borrowed" 59889
		{ 596, jps.buff(59889) and jps.hpSum(LowestImportantUnit) > 0.40 , POHTarget , "Borrowed_POH" },
	}},
	
	-- EMERGENCY HEAL --
	{ "nested", jps.hp(LowestImportantUnit) < 0.50 ,{
		-- "Power Word: Shield" 17 -- Keep Buff "Borrowed" 59889 always
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield" },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving , LowestImportantUnit , "Emergency_FlashHeal" },
	}},

	-- LOWEST TTD -- LowestFriendTTD friend unit in raid with TTD < 6 sec 
	{ "nested", LowestFriendTTD ~= nil and jps.hpInc(LowestFriendTTD) < 0.80 ,{
		-- "Power Word: Shield" -- "Egide divine" 47515 "Divine Aegis"
		{ 17, jps.hpSum(LowestFriendTTD) < 0.80 and not jps.buff(17,LowestFriendTTD) and not jps.debuff(6788,LowestFriendTTD) , LowestFriendTTD , "Bubble_Lowest_TTD" },
		-- "Pénitence" 47540
		{ 47540, jps.hp(LowestFriendTTD) < 0.60 , LowestFriendTTD , "Penance_Lowest_TTD" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving and groupHealth > 0.80 and jps.hp(LowestFriendTTD) < 0.50 , LowestFriendTTD , "FlashHeal_Lowest_TTD" },
	}},
	
	-- HIGHEST DAMAGE -- Highest Damage Friend with Lowest Health
	{ "nested", IncomingDamageFriend ~= nil and jps.hpInc(IncomingDamageFriend) < 0.80 ,{
		-- "Power Word: Shield" -- "Egide divine" 47515 "Divine Aegis"
		{ 17, jps.hpSum(IncomingDamageFriend) < 0.80 and not jps.buff(17,IncomingDamageFriend) and not jps.debuff(6788,IncomingDamageFriend) , IncomingDamageFriend , "Bubble_Lowest_DAMAGE" },
		-- "Pénitence" 47540
		{ 47540, jps.hp(IncomingDamageFriend) < 0.60 , IncomingDamageFriend , "Penance_Lowest_DAMAGE" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving and groupHealth > 0.80 and jps.hp(IncomingDamageFriend) < 0.50 , IncomingDamageFriend , "FlashHeal_Lowest_DAMAGE" },
	}},

	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ "nested", not jps.Moving and not jps.buffTracker(41635) ,{
		{ 33076, canHeal(TankThreat) , TankThreat , "Tracker_Mending_TankThreat" },
		{ 33076, canHeal(Tank) , Tank , "Tracker_Mending_Tank" },
		{ 33076, MendingFriend ~= nil , MendingFriend , "Tracker_Mending_Friend" },
		{ 33076, not jps.buff(41635,LowestImportantUnit) , LowestImportantUnit , "Tracker_Mending_Lowest" },
	}},
	
	-- DAMAGE --
	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, jps.IsSpellInRange(129250,rangedTarget) and canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace" },
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, jps.IsSpellInRange(14914,rangedTarget) and canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes" },
	{ "nested", jps.MultiTarget and jps.hp(LowestImportantUnit) > 0.80 and canDPS(rangedTarget) ,{
		-- "Mot de l'ombre: Douleur" 589
		{ 589, jps.myDebuffDuration(589,rangedTarget) == 0 and jps.PvP , rangedTarget , "|cFFFF0000Douleur" },
		{ 589, jps.myDebuffDuration(589,rangedTarget) == 0 and not IsInGroup() , rangedTarget , "|cFFFF0000Douleur" },
		-- "Châtiment" 585
		{ 585, not jps.Moving and jps.buffStacks(81661) < 5 , rangedTarget , "|cFFFF0000Chatiment_Stacks" },
		{ 585, not jps.Moving and jps.buffDuration(81661) < 9 , rangedTarget , "|cFFFF0000Chatiment_Stacks" },
		{ 585, not jps.Moving and jps.hp(LowestImportantUnit) < 1 and jps.mana() > 0.60 , rangedTarget , "|cFFFF0000Chatiment_Health" },
		{ 585, not jps.Moving and jps.PvP , rangedTarget , "|cFFFF0000Chatiment_PvP" },
		{ 585, not jps.Moving and not IsInGroup() , rangedTarget , "|cFFFF0000Chatiment_Solo" },
		-- "Pénitence" 47540 -- jps.glyphInfo(119866) -- allows Penance to be cast while moving.
		{ 47540, jps.PvP , rangedTarget ,"|cFFFF0000Penance_PvP" },
		{ 47540, not IsInGroup() , rangedTarget ,"|cFFFF0000Penance_Solo" },
	}},

	-- GROUP HEAL --
	-- "Prière de soins" 596 "Prayer of Healing"
	{ 596, not jps.Moving and POHTarget ~= nil and canHeal(POHTarget) , POHTarget , "POH" },

	-- HEAL --
	-- "Pénitence" 47540
	{ 47540, jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit , "Top_Penance" },
	-- "Don des naaru" 59544
	{ 59544, jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit , "Top_Naaru" },
	-- "Soins" 2060
	{ 2060, not jps.Moving and jps.hp(LowestImportantUnit) < 0.80 , LowestImportantUnit , "Top_Soins"  },

	-- "Nova" 132157 -- "Words of Mending" 155362 "Mot de guérison"
	{ 132157, jps.Moving and countFriendNearby > 2 , "player" , "Nova_Count" },
	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend("target") , "target" },
	{ 123040, priest.canShadowfiend("target") , "target" },
	-- "Châtiment" 585
	{ 585, not jps.Moving and jps.buffStacks(81661) < 5 and canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Chatiment_Stacks" },
	{ 585, not jps.Moving and jps.buffDuration(81661) < 9 and canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Chatiment_Stacks" }

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end , "Disc Priest PvE", true, false)

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","DISCIPLINE",function()

	local LowestImportantUnit = jps.LowestImportantUnit()
	local POHTarget, _, _ = jps.FindSubGroupHeal(0.50)
	local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
	local rangedTarget, _, _ = jps.LowestTarget() -- default "target"
	local BodyAndSoul = jps.IsSpellKnown(64129) -- "Body and Soul" 64129

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	if jps.ChannelTimeLeft() > 0 then return nil end
	if jps.CastTimeLeft() > 0 then return nil end
	
	local spellTableOOC = {

	-- SNM "Levitate" 1706
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, IsSwimming() and not jps.buff(111759) , "player" },

	-- "Fortitude" 21562 -- "Commanding Shout" 469 -- "Blood Pact" 166928
	{ 21562, jps.buffMissing(21562) and jps.buffMissing(469) and jps.buffMissing(166928) , "player" },
	-- "Gardien de peur" 6346
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Don des naaru" 59544
	{ 59544, jps.hp("player") < 0.75 , "player" },
	-- "Shield" 17 "Body and Soul" 64129 -- figure out how to speed buff everyone as they move
	{ 17, jps.Moving and BodyAndSoul and not jps.debuff(6788,"player") , "player" , "Shield_BodySoul" },
	-- "Pénitence" 47540
	{ 47540, jps.hp(LowestImportantUnit) < 0.50  , LowestImportantUnit , "Penance" },
	-- "Prière de soins" 596 "Prayer of Healing"
	{ 596, not jps.Moving and canHeal(POHTarget) , POHTarget , "POH" },
	-- "Soins" 2060
	{ 2060, not jps.Moving and jps.hp(LowestImportantUnit) < 0.60 , LowestImportantUnit , "Soins"  },
	
	-- "Nova" 132157 -- buff "Words of Mending" 155362 "Mot de guérison"
	{ 132157, jps.IsSpellKnown(152117) and jps.Defensive and jps.buffDuration(155362) < 9 , "player" , "Nova_WoM" },
	
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ 33076, jps.Defensive and UnitIsPlayer(Tank) and not jps.Moving and not jps.buff(41635,Tank) and canHeal(Tank) , Tank , "Mending_Tank" },
	-- ClarityTank -- "Clarity of Will" 152118 shields with protective ward for 20 sec
	{ 152118, not jps.Moving and canHeal(Tank) and not jps.buff(152118,Tank) and not jps.isRecast(152118,Tank) , Tank , "Clarity_Tank" },
	
	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius"
	{ {"macro","/use item:118922"}, not jps.buff(105691) and not jps.buff(156070) and not jps.buff(156079) and jps.itemCooldown(118922) == 0 and not jps.buff(176151) , "player" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTableOOC)
	return spell,target

end,"OOC Disc Priest PvE",false,false,true)

-- REMOVED -- http://fr.wowhead.com/guide=2298/warlords-of-draenor-priest-changes#specializations-removed
-- Borrowed Time has been redesigned. It now increases the Priest's stat gains to Haste from all sources by 40% for 6 seconds.
-- Void Shift
-- Inner Focus has been removed.
-- Inner Will has been removed.
-- Rapture has been removed.( Removes the cooldown on Power Word: Shield)
-- Hymn of Hope has been removed.
-- Heal has been removed.

-- CHANGED --
-- Greater has been renamed to Heal.
-- Renew Holy -- HOLY
-- Binding Heal -- HOLY
-- Mot de l'ombre : Mort 32379 -- SHADOW
-- Divine Insight -- HOLY

-------------------
-- TO DO --
-------------------
-- jpevents.lua: jps.whoIsCapping.
   -- Look for flag capture event and honorable defender buff 68652 on player?
      -- Buff 68652 only for AB, EotS and IoC
      -- Maybe use subzone location for others?
   -- if both == true target flag capper and attack
   -- if both == true and attack cast on cd cast HN
     
-- jpevents.lua: look for long lasting and channeled ccs being cast(cyclone).
   -- if caster targeting player, target caster
      -- silence 3/4 of way through cast
     
-- OOC ACTIONS ON ENTERING INSTANCE, TALENT/GLYPH SWAP ACCORDING TO ENEMY COMP --
-- http://www.wowinterface.com/downloads/info22148-GlyphKeeper-TalentGlyphMgmt.html#info
-- http://www.wowinterface.com/downloads/info23452-AutoConfirmTalents.html
-- Should be universal function to use with all classes.
-- Announce
   -- "Swapping talent to TalentName."
   -- "Swapping glyph to GlyphName."

-- Enemy Team Comps: 1 or 2 of same in 2s, 2 or 3 in 3s, 3 or > in 5s.
   -- MeleeTeam = melee classes: Warrior, FDK, BDK, enshaman, rpally.
   -- DOTTeam = dot classes: Lock, spriest, boomkin, UDK. Maybe arcane and fire mage?
   -- StealthTeam = stealth classes: Rogue, fdruid.
   -- RangeTeam = ranged classes: Hunter, boomkin, mage, spriest, lock, elshaman.
   -- RootTeam = root/slow/snare classes: Hunter, frmage. May not need.

-- Talents --
-- http://wow.gamepedia.com/World_of_Warcraft_API#Talent_Functions
-- http://wow.gamepedia.com/API_LearnTalent -- Is now LearnTalents
-- http://wowprogramming.com/docs/api/LearnTalent -- Is now LearnTalents
-- LearnTalents( tabIndex, talentIndex )
-- Tab top = 1(primary spec), bottom = 2(secondary spec).
-- TalentIndex counts from top left, left to right, top to bottom, 1-21.
-- If tab top, Desperate Prayer = LearnTalents(1, 2), Saving Grace = LearnTalents(1, 21).
-- Only do if have Tome of the Clear Mind in bags. Give count on use.
   -- "You have TomeCount of Tome of the Clear Mind remaining."
-- Alert if <= 1 Tome of the Clear Mind when accept queue or leave instance.

-- PvP Arena/BG Talent Swaps --
-- T1 --
-- Desperate Prayer, default.
-- Spectral Guise vs RangeTeam. Mage + hunter + boomkin, etc.
-- Angelic Bulwark vs teams likely to focus player. MeleeTeam or warrior + dk + hunter, etc.

-- T2 --
-- Body and Soul, default.
-- Phantasm vs root/slow teams or in capture the flag maps.
   -- WSG, TP.

-- T3 --
-- Surge of Light vs StealthTeam.
   -- Spam Holy Nova and/or PW:S to get proc.
      -- Random spam timer for HN when OOC to keep enemy off rhythm?
         -- Do not spam if stealthed
-- Power Word: Solace, default.

-- T4 --
-- Void Tendrils vs MeleeTeam & on capture the flag maps (WSG, SotA).
-- Psychic Scream, default & resource defense maps.
   -- AB, AV, EotS, BfG, DG, SM, ToK, IoC, Ashran

-- T5 --
-- Power Infusion, default.
-- Spirit Shell vs MeleeTeam.
   -- Pop @ beginning of arena. Stack 2x with quick or insta heals.
   -- Teammate(s) in trouble/dying & enemy pops offensive cds.
   -- When teammate(s) @ full health and on offensive.

-- T6 --
-- Cascade if > 5 in raid or if in bg.
-- Divine Star if < 6 in raid or if in arena.

-- T7 --
-- Clarity of Will vs dps teams likely to focus player.
   -- PW:S to get borrowed time then stack CoW x 2 + PoM if getting trained.
   -- Watch enemy offensive cds. Reapply CoW when timer(s) is/are about to be up.
      -- New jpevents.lua function, jps.enemyCooldownWatch.
         -- Need table of major offensive cds and cd durations.
            -- Celestial Alignment 112071, 360s
            -- Druid Berserk
-- Words of Mending vs DOTTeams.
-- Saving Grace, default.
   -- When enemy pops offensive cds.
   
-- Glyphs --
-- http://wow.gamepedia.com/MACRO_castglyph
   -- /castglyph glyph slot
      -- /castglyph Glyph of the Inquisitor major3 or maybe /castglyph Inquisitor major3
-- Glyph of the Inquisitor if enemy arena team has mage and/or shaman.
   -- Wait just before poly cast is finished, attack with PW:Sol(LowestTarget).
-- Glyph of Purify vs DOT cleave teams? Lock + spriest, boomkin + DK, etc.
-- Glyph of Reflective Shield vs MeleeTeam and 2s.? -- Caution, will break poly/cc.
-- Glyph of Shadow Magic vs interrupt teams.
   -- Bait interrupt with fake cast, stop 1/2 way, fade, cast spell.
   
-- Double melee that will more than likely sit on you: penance, shadow magic, weakened soul
-- Double caster with Mage: shadow magic, inquisitor, penance
-- Mage + pally of any kind: shadow magic, inquisitor, mass dispell
-- Any sort of other pally team: shadow magic, mass dispell, penance
-- 1 range 1 melee: shadow magic, penance, weakened soul.
-- Mending with WoM.

-- TRICKS & STRATEGIES --
-- Fear ward right before player is feared. Don't fear ward on cd. Easily dispelled.
   -- Look for fear cast event of EnemyCaster, wait for 3/4 cast time, cast Fear Ward.
-- Levitate when ooc for extra debuff to dispel.
-- Levitate when dark sim debuff is on player.

-- Best Comps for Disc
-- Feral + Hunter + Disc, Pala + Hunter + Disc, Feral + Mage + Disc