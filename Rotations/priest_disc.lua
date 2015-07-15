-- jps.UseCDs for RACIAL COUNTERS & "Spectral Guise"
-- jps.UseCDs for WoM when OOC
-- jps.MultiTarget not in use
-- jps.Interrupts for Dispel
-- jps.Defensive changes the LowestImportantUnit to table = { "player","focus","target","mouseover" } with table.insert TankUnit  = jps.findTankInRaid()
-- jps.FaceTarget to DPSing

local L = MyLocalizationTable
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat

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

-- Debuff EnemyTarget NOT DPS
local DebuffUnitCyclone = function (unit)
	if not UnitAffectingCombat(unit) then return false end
	local Cyclone = false
	local i = 1
	local auraName = select(1,UnitDebuff(unit, i))
	while auraName do
		if strfind(auraName,L["Polymorph"]) then
			Cyclone = true
		elseif strfind(auraName,L["Cyclone"]) then
			Cyclone = true
		elseif strfind(auraName,L["Hex"]) then
			Cyclone = true
		end
		if Cyclone then break end
		i = i + 1
		auraName = select(1,UnitDebuff(unit, i))
	end
	return Cyclone
end

----------------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION PVP & PVP ----------------------------------------------
----------------------------------------------------------------------------------------------------------------

local priestDisc = function()

	local spell = nil
	local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHealth = jps.hp(LowestImportantUnit,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local countFriendNearby = jps.FriendNearby(12)
	local POHTarget, groupToHeal, groupHealth = jps.FindSubGroupHeal(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	--local POHTarget, groupToHeal = jps.FindSubGroupTarget(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE

	local myTank,TankUnit = jps.findTankInRaid() -- default "focus"
	local TankTarget = "target"
	if canHeal(myTank) then TankTarget = myTank.."target" end
	local TankThreat = jps.findThreatInRaid()

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
	local playerTTD = jps.TimeToDie("player")
	local buffTrackerMending = jps.buffTracker(41635)
	local ShellTarget = jps.FindSubGroupAura(114908) -- buff target Spirit Shell 114908 need SPELLID
	-- "Body and Soul" 64129
	local BodyAndSoul = jps.IsSpellKnown(64129)
	local isArena, _ = IsActiveBattlefieldArena()

---------------------
-- ENEMY TARGET
---------------------

	local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") and not DebuffUnitCyclone("target") then rangedTarget =  "target"
	elseif canDPS(TankTarget) and not DebuffUnitCyclone(TankTarget) then rangedTarget = TankTarget 
	elseif canDPS("targettarget") and not DebuffUnitCyclone("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("mouseover") and not DebuffUnitCyclone("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	local playerIsTargeted = false
	for i=1,#EnemyUnit do -- for _,unit in ipairs(EnemyUnit) do
		local unit = EnemyUnit[i]
		if TargetCount > 0 then
			if jps.UnitIsUnit(unit.."target","player") then
				playerIsTargeted = true
			break end
		end
	end

----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	-- LOWEST TTD
	local LowestFriendTTD = nil
	local LowestTTD = 6 -- Second
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		local TTD = jps.TimeToDie(unit)
		if TTD < LowestTTD then
			LowestFriendTTD = unit
			LowestTTD = TTD
		end
	end

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
		if priest.unitForLeap(unit) and jps.hpAbs(unit) < 0.30 then 
			LeapFriend = unit -- if jps.RoleInRaid(unit) == "HEALER" then
		break end
	end
	
	-- priest.unitForShield includes jps.FriendAggro
	local ShieldFriend = nil
	local ShieldFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if priest.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldFriendHealth then
				ShieldFriend = unit
				ShieldFriendHealth = unitHP
			end
		end
	end

	-- DISPEL --
	local BossDebuffFriend = jps.FindMeBossDebuff() -- to cast Shield on Unit affected by Boss Debuff
	local DispelFriendPvE = jps.FindMeDispelTarget( {"Magic"} ) -- {"Magic", "Poison", "Disease", "Curse"}
	local DispelFriendPvP = nil
	local DispelFriendHealth = 100
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.DispelFriendly(unit,2) then -- jps.DispelFriendly includes UnstableAffliction
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
		if jps.canDispel(unit,{"Magic"}) then -- jps.canDispel includes UnstableAffliction
			DispelFriendRole = unit -- if jps.RoleInRaid(unit) == "HEALER" then
		break end
	end

	-- PAIN SUPPRESSION
	local PainFriend = nil
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.cooldown(33206) == 0 then break end 
		if jps.buff(33206,unit) then
			PainFriend = unit
		break end
	end
	
	-- CASCADE
	local CountFriendLowest = 0
	for i=1,#FriendUnit do -- for _,unit in ipairs(FriendUnit) do
		local unit = FriendUnit[i]
		if jps.hp(unit) < 0.75 and canHeal(unit) then
			CountFriendLowest = CountFriendLowest + 1
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

	local parseShell = {
	--TANK not Buff Spirit Shell 114908
		{ 2061, jps.buff(114255) , LowestImportantUnit , "Carapace_FlashHeal_Light_" },
		{ 596, canHeal(ShellTarget) , ShellTarget , "Carapace_Shell_Target_" },
		{ 2061, not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_NoBuff_FlashHeal_" },
	--TANK Buff Spirit Shell 114908
		{ 2060, jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_Buff_Soins_" },
	}
	
	local parseControl = {
		-- "Silence" 15487
		{ 15487, jps.IsSpellInRange(15487,rangedTarget) and EnemyCaster(rangedTarget) == "caster" , rangedTarget },
		-- "Psychic Scream" "Cri psychique" 8122 -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	local parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelFriendRole) == "string" , DispelFriendRole , "|cff1eff00DispelFriend_Role" },
		{ 527, type(DispelFriendPvP) == "string" , DispelFriendPvP , "|cff1eff00DispelFriend_PvP" },
		{ 527, type(DispelFriendPvE) == "string" , DispelFriendPvE , "|cff1eff00DispelFriend_PvE" },
	}

	local RacialCounters = {
		-- Undead "Will of the Forsaken" 7744 -- SNM priest is undead ;)
		{ 7744, jps.debuff("psychic scream","player") }, -- Fear
		{ 7744, jps.debuff("fear","player") }, -- Fear
		{ 7744, jps.debuff("intimidating shout","player") }, -- Fear
		{ 7744, jps.debuff("howl of terror","player") }, -- Fear
		{ 7744, jps.debuff("mind control","player") }, -- Charm
		{ 7744, jps.debuff("seduction","player") }, -- Charm
		{ 7744, jps.debuff("wyvern sting","player") }, -- Sleep
	}

------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

	-- "Archange surpuissant" 172359  100 % critique POH or FH
	-- "Power Infusion" 10060 "Infusion de puissance"
	local InterruptTable = {
		{priest.Spell.FlashHeal, 0.75, jps.buffId(priest.Spell.SpiritShellBuild) or jps.buff(172359) },
		{priest.Spell.Heal, 0.90, jps.buffId(priest.Spell.SpiritShellBuild) },
		{priest.Spell.PrayerOfHealing, 0.80, jps.buff(10060) or jps.buff(172359) or jps.buffId(priest.Spell.SpiritShellBuild) },
		{priest.Spell.HolyCascade, 4 , false}
	}
	  
	-- AVOID OVERHEALING
	priest.ShouldInterruptCasting(InterruptTable , groupHealth , CountFriendLowest)

	-- FAKE CAST -- 6948 -- "Hearthstone"
	local FakeCast = UnitCastingInfo("player")
	if FakeCast == GetItemInfo(6948) then
		if jps.CastTimeLeft() < 4 then
			SpellStopCasting()
		elseif LowestImportantUnitHpct < 0.85 then
			SpellStopCasting()
		elseif not playerAggro then
			SpellStopCasting()
		end
	end

-- SNM Trinket 1 use function to avoid blowing trinket when not needed
-- False if rooted, not moving, and lowest friendly unit in range
-- False if stunned/incapacitated but lowest friendly unit is good health
-- False if stunned/incapacitated and playerAggro but player health is good

------------------------
-- SPELL TABLE ---------
------------------------

spellTable = {

	-- SNM "Levitate" 1706 -- "Dark Simulacrum" debuff 77606
	{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) , "player" },
	{ 1706, jps.debuff(77606,"player") , "player" , "DarkSim_Levitate" },

	-- SNM RACIAL COUNTERS -- share 30s cd with trinket
	{"nested", jps.PvP and jps.UseCDs , RacialCounters },
	-- SNM "Chacun pour soi" 59752 "Every Man for Himself" -- Human
	{ 59752, playerIsStun , "player" , "Every_Man_for_Himself" },
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , "player" , "useTrinket0" },
	{ jps.useTrinket(1), not jps.PvP and jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , "player" , "useTrinket1" },
	{ jps.useTrinket(1), jps.PvP and jps.useTrinketBool(1) and playerIsStun and jps.combatStart > 0 and LowestImportantUnitHpct < 0.75 , "player" , "useTrinket1" },

	-- "Suppression de la douleur" 33206 "Pain Suppression" -- Buff "Pain Suppression" 33206
	{ 33206, jps.hp(myTank) < 0.30 , myTank , "StunPain_" },
	{ 33206, jps.hp("player") < 0.30 , "player" , "StunPain_" },
	{ 33206, jps.hpAbs(LowestImportantUnit) < 0.30 , LowestImportantUnit , "StunPain_" },
	
	-- CONTROL --
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit" },
	{ "nested", jps.PvP and not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },
	-- "Leap of Faith" 73325 -- "Saut de foi" -- jps.TimeToDie is now a condition in LeapFriend
	{ 73325, jps.PvP and type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
	
	-- DISPEL -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
	{ "nested", jps.Interrupts , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_" },

	-- FAKE CAST -- 6948 -- "Hearthstone"
	{ {"macro","/use item:6948"}, jps.PvP and LowestImportantUnitHpct > 0.80 and not jps.Moving and playerAggro and jps.itemCooldown(6948) == 0 , "player" , "Aggro_FAKECAST" },

	-- "Power Word: Shield" 17
	{ 17, jps.Defensive and jps.Moving and BodyAndSoul and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Shield_Moving" },
	-- PLAYER AGGRO
	{ "nested", jps.hp() < 0.75 ,{
		-- "Power Word: Shield" 17
		{ 17, not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield" },
		-- "Don des naaru" 59544
		{ 59544, true , "player" , "Aggro_Naaru" },
		-- "Pierre de soins" 5512
		{ {"macro","/use item:5512"}, jps.itemCooldown(5512) == 0 , "player" , "Item5512" },
		-- "Prière du désespoir" 19236
		{ 19236, jps.IsSpellKnown(19236) , "player" , "Aggro_DESESPERATE" },
	}},

	-- PLAYER HEALS --
	-- SNM "Fade" 586 "Oubli" + "Glyph of Shadow Magic" 159628 -- Use if will die soon and have aggro
	{ 586, jps.glyphInfo(159628) and jps.PvP and playerAggro and playerTTD < 6 , "player" , "Aggro_Oubli" },
	{ 586, jps.glyphInfo(159628) and jps.PvP and playerWasControl and playerTTD < 6 , "player" , "Control_Oubli" },
	{ 586, jps.glyphInfo(159628) and jps.PvP and playerWasControl and type(LowestFriendTTD) == "string" , "player" , "Control_Oubli" },
	
	{ "nested", playerAggro or playerWasControl or playerIsTargeted ,{
		-- "Power Word: Shield" 17
		{ 17, not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield" },
		-- "Spectral Guise" 112833 "Semblance spectrale"
		{ 112833, jps.useCDs and jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },
		-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même
		{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
		-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
		{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
		-- "Oubli" 586
		{ 586, not jps.PvP , "player" , "Aggro_Oubli" },
		-- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
		{ 527, jps.canDispel("player",{"Magic"}) , "player" , "Aggro_Dispel" },
		-- "Pénitence" 47540
		{ 47540, jps.hp() < 0.75 , "player" , "Aggro_Penance" },
		-- "Soins rapides" 2061 -- Buff "Borrowed" 59889 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 2061, not jps.Moving and jps.hp() < 0.40 , "player" , "Aggro_FlashHeal" },
		-- "Prière de guérison" 33076 -- Buff POM 41635
		{ 33076, not jps.Moving and not jps.buff(41635,"player") , "player" , "Aggro_Mending" },
		-- "Clarity of Will" 152118 shields with protective ward for 20 sec
		{ 152118, not jps.Moving and priest.unitForClarity("player") and jps.debuff(6788,"player") , "player" , "Aggro_Clarity" },
		-- "Nova" 132157 -- "Words of Mending" 155362 "Mot de guérison"
		{ 132157, jps.hp() < 0.40 , "player" , "Aggro_Nova" },
	}},

	-- "Soins rapides" 2061 -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and LowestImportantUnitHpct < 0.75 , LowestImportantUnit , "FlashHeal_Light_" },
	{ 2061, jps.buff(114255) and jps.buffDuration(114255) < 4 , LowestImportantUnit , "FlashHeal_Light_" },

	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace_" },
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes_" },
	
	-- SHIELD BOSS TARGET
	{ "nested", canDPS("target") and canHeal(TankThreat) ,{
		{ 17, not jps.buff(17,TankThreat) and not jps.debuff(6788,TankThreat) , TankThreat , "Shield_TankThreat" },
		{ 152118, jps.debuff(6788,TankThreat) and not jps.buff(152118,TankThreat) and not jps.isRecast(152118,TankThreat) , TankThreat , "Clarity_TankThreat" },
	}},
	-- BOSS DEBUFF
	{ "nested", type(BossDebuffFriend) == "string" ,{
		{ 17, not jps.buff(17,BossDebuffFriend) and not jps.debuff(6788,BossDebuffFriend) , BossDebuffFriend , "Shield_BossDebuff" },
		{ 152118, jps.debuff(6788,BossDebuffFriend) and not jps.buff(152118,BossDebuffFriend) and not jps.isRecast(152118,BossDebuffFriend) , BossDebuffFriend , "Clarity_BossDebuff" },
	}},

	-- "Pénitence" 47540
	{ 47540, canHeal(myTank) and jps.hp(myTank) < 0.80 , myTank , "Penance_myTank_" },
	-- SHIELD TANK
	{ 17, canHeal(myTank) and not jps.buff(17,myTank) and not jps.debuff(6788,myTank) , myTank , "Timer_Shield_Tank" },
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ 33076, not jps.Moving and canHeal(myTank) and not jps.buff(41635,myTank) , myTank , "Timer_Mending_Tank" },
	{ "nested", not jps.Moving and not buffTrackerMending ,{
		{ 33076, type(MendingFriend) == "string" , MendingFriend , "Tracker_Mending_Friend" },
		{ 33076, not jps.buff(41635,LowestImportantUnit) , LowestImportantUnit , "Tracker_Mending_" },
	}},
	-- ClarityTank -- "Clarity of Will" 152118 shields with protective ward for 20 sec
	{ 152118, not jps.Moving and canHeal(myTank) and priest.unitForClarity(myTank) and LowestImportantUnitHpct > 0.50 and jps.hp(myTank) > 0.80  , myTank , "Timer_ClarityTank" },
	-- "Soins" 2060
	{ 2060, groupHealth > 0.80 and not jps.Moving and canHeal(myTank) and jps.debuff(6788,myTank) and LowestImportantUnitHpct > 0.50 and jps.hpAbs(myTank) < 0.90 , myTank , "Soins_myTank_"  },

	{ "nested", type(POHTarget) == "string" ,{
		-- "Archange" 81700 -- Buff 81700 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 81700, jps.buffStacks(81661) == 5 , "player", "Emergency_ARCHANGE_POH" },
		-- "Power Infusion" 10060 "Infusion de puissance"
		{ 10060, LowestImportantUnitHpct < 0.50 , "player" , "Emergency_POWERINFUSION_POH" },
		-- SNM Troll "Berserker" 26297 -- haste buff
		{ 26297, true , "player" },
	}},

	{ "nested", not jps.Moving and type(POHTarget) == "string" and canHeal(POHTarget) ,{
		-- "Cascade" Holy 121135 Shadow 127632
		{ 121135, true , POHTarget ,  "Cascade_POH_" },
		-- "POH" 596 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 596, jps.buff(172359) , POHTarget , "Archange_POH_" },
		-- "POH" 596 -- "Power Infusion" 10060 "Infusion de puissance"
		{ 596, jps.buff(10060) , POHTarget , "PowerInfusion_POH_" },
		-- "POH" 596 -- Buff "Borrowed" 59889
		{ 596, jps.buff(59889) and jps.hp(myTank) > 0.50 , POHTarget , "Borrowed_POH_" },
	}},
	
	-- "Power Infusion" 10060 "Infusion de puissance"
	{ 10060, jps.hp(myTank) < 0.50 , "player" , "Emergency_POWERINFUSION" },
	{ 10060, LowestImportantUnitHpct < 0.50 and CountFriendLowest > 3 , "player" , "Count_POWERINFUSION" },

	-- LOWEST TTD -- LowestFriendTTD friend unit in raid with TTD < 6 sec 
	-- SNM "Power Word: Shield 
	{ 17, type(LowestFriendTTD) == "string" and not jps.buff(17,LowestFriendTTD) and not jps.debuff(6788,LowestFriendTTD) , LowestFriendTTD , "Bubble_Lowest_TTD" },

	-- EMERGENCY HEAL --
	{ "nested", LowestImportantUnitHpct < 0.50 ,{
		-- "Power Word: Shield" 17 -- Keep Buff "Borrowed" 59889 always
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_" },
		{ 17, type(ShieldFriend) == "string" and not jps.buff(59889) , ShieldFriend , "Emergency_Timer_ShieldFriend" },
		-- "Archange" 81700 -- Buff 81700 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 81700, jps.buffStacks(81661) == 5 , "player", "Emergency_ARCHANGE" },
		-- "Suppression de la douleur" 33206 "Pain Suppression" -- Buff "Pain Suppression" 33206
		{"nested", type(PainFriend) == "string" and jps.hp(PainFriend) < 0.50 , {
			{ 10060, true , "player" , "Emergency_POWERINFUSION" },
			{ 17, not jps.buff(17,PainFriend) and not jps.debuff(6788,PainFriend) , PainFriend , "_Pain_Shield" },
			{ 2061, not jps.Moving and jps.buff(172359) , PainFriend , "_Pain_Archange_FH" },
			{ 152118, not jps.Moving and jps.buff(59889) and jps.buff(10060) and jps.debuff(6788,PainFriend)
			and not jps.buff(152118,PainFriend) and not jps.isRecast(152118,PainFriend) , PainFriend , "_Pain_Clarity" },
		}},
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance_" },
		-- "Soins rapides" 2061 -- Buff "Borrowed" 59889 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 2061, not jps.Moving and type(LowestFriendTTD) == "string" , LowestFriendTTD , "Flash_Heal_Lowest_TTD" },
		{ 2061, not jps.Moving and jps.buff(172359) , LowestImportantUnit , "Emergency_FlashHeal_Archange_" },
		{ 2061, not jps.Moving and jps.buff(10060) , LowestImportantUnit , "Emergency_FlashHeal_Infusion_" },
		{ 2061, not jps.Moving and LowestImportantUnitHpct < 0.25 , LowestImportantUnit , "Emergency_FlashHeal_25_" },
		-- "Cascade" Holy 121135 Shadow 127632
		{ 121135, not jps.Moving and CountFriendLowest > 3 , LowestImportantUnit , "Emergency_Cascade_" },
		-- "Clarity of Will" 152118 shields with protective ward for 20 sec -- 2.5 sec cast
		{ 152118, not jps.Moving and priest.unitForClarity(LowestImportantUnit) and jps.debuff(6788,LowestImportantUnit) and jps.buff(59889) , LowestImportantUnit  , "Emergency_Clarity_"  },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving , LowestImportantUnit , "Emergency_FlashHeal_50_" },
	}},

	-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
	{ "nested", jps.buffId(109964) and not jps.Moving , parseShell },

	-- GROUP HEAL --
	-- "Cascade" Holy 121135 Shadow 127632
	{ 121135, not jps.Moving and CountFriendLowest > 3 , LowestImportantUnit ,  "Cascade_" },
	{ "nested", type(POHTarget) == "string" and canHeal(POHTarget) ,{
		-- "Prière de guérison" 33076 -- Buff POM 41635
		{ 33076, not jps.buff(41635,POHTarget) , "Mending_POH_" },
		-- "Power Word: Shield" 17 -- Keep Buff "Borrowed" 59889 always
		{ 17, type(ShieldFriend) == "string" and not jps.buff(59889) , ShieldFriend , "Timer_ShieldFriend" },
		-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
		{ 109964, jps.IsSpellKnown(109964) , POHTarget , "Carapace_POH_" },
		-- "Prière de soins" 596 "Prayer of Healing"
		{ 596, not jps.Moving , POHTarget , "POH_" },
	}},

	-- HEAL --
	{ "nested", LowestImportantUnitHpct < 0.80 ,{
		-- "Shield" 17
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Shield_" },
		-- SNM Flash Heal top off -- Less important to be conservative with mana in PvP
		{ 2061, not jps.Moving and isArena and LowestImportantUnitHpct < 0.75 and jps.mana() > 0.50 , LowestImportantUnit , "Flash_Heal_Topoff" },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Penance_" },
		-- "Don des naaru" 59544
		{ 59544, true , LowestImportantUnit , "Naaru_" },
		-- "Châtiment" 585
		{ 585, jps.castEverySeconds(585,2) and jps.buffStacks(81661) < 5 , rangedTarget , "|cFFFF0000Chatiment_Stacks" },
		-- "Soins" 2060 -- Buff "Borrowed" 59889 -- Buff "Clarity of Will" 152118
		{ 2060, not jps.Moving and jps.buff(152118,LowestImportantUnit) , LowestImportantUnit , "Soins_Clarity_"  },
		{ 2060, not jps.Moving and jps.buff(17,LowestImportantUnit) , LowestImportantUnit , "Soins_Shield_"  },
		{ 2060, not jps.Moving and jps.buff(59889) , LowestImportantUnit , "Soins_Borrowed_"  },
		{ 2060, not jps.Moving and jps.buff(10060) , LowestImportantUnit , "Soins_Infusion_"  },
		-- "Clarity of Will" 152118 shields with protective ward for 20 sec -- 2.5 sec cast
		{ 152118, not jps.Moving and priest.unitForClarity(LowestImportantUnit) and jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit  , "Clarity_"  },
		-- "Soins" 2060
		{ 2060, not jps.Moving , LowestImportantUnit , "Soins_"  },
	}},

	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend("target") , "target" },
	{ 123040, priest.canShadowfiend("target") , "target" },

	-- DAMAGE --
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.80 ,{
		-- "Mot de l'ombre: Douleur" 589
		{ 589, jps.myDebuffDuration(589,rangedTarget) == 0 and not IsInGroup() , rangedTarget , "|cFFFF0000Douleur_" },
		-- "Châtiment" 585
		{ 585, jps.castEverySeconds(585,2) and jps.PvP , rangedTarget , "|cFFFF0000Chatiment_" },
		{ 585, jps.castEverySeconds(585,2) and not IsInGroup() , rangedTarget , "|cFFFF0000Chatiment_" },
		{ 585, jps.castEverySeconds(585,2) and jps.buffStacks(81661) < 5 , rangedTarget , "|cFFFF0000Chatiment_Stacks" },
		{ 585, jps.castEverySeconds(585,2) and jps.hp(myTank) < 1 , rangedTarget , "|cFFFF0000Chatiment_Tank" },
		{ 585, jps.castEverySeconds(585,2) and LowestImportantUnitHpct < 1 and jps.mana("player") > 0.50 , rangedTarget , "|cFFFF0000Chatiment_Mana" },
		-- "Pénitence" 47540 -- jps.glyphInfo(119866) -- allows Penance to be cast while moving.
		{ 47540, not IsInGroup() , rangedTarget ,"|cFFFF0000Penance_" },
		{ 47540, jps.PvP , rangedTarget ,"|cFFFF0000Penance_" },
	}},
	
	-- "Nova" 132157 -- "Words of Mending" 155362 "Mot de guérison"
	{ 132157, jps.Moving and countFriendNearby > 3 , "player" , "_Nova" },
	-- "Soins" 2060
	{ 2060, not jps.Moving and LowestImportantUnitHealth > priest.AvgAmountGreatHeal , LowestImportantUnit },
	-- "Gardien de peur" 6346
	{ 6346, jps.PvP and not jps.buff(6346,"player") , "player" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","DISCIPLINE", priestDisc , "Disc Priest")

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION OOC ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PRIEST","DISCIPLINE",function()

	local playerIsSwimming = IsSwimming()
	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local POHTarget, _, _ = jps.FindSubGroupHeal(0.50)
	local myTank,TankUnit = jps.findTankInRaid() -- default "focus"
	local rangedTarget, _, _ = jps.LowestTarget() -- default "target"
	-- "Body and Soul" 64129
	local BodyAndSoul = jps.IsSpellKnown(64129)

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
	{ 1706, playerIsSwimming and not jps.buff(111759) , "player" },

	-- "Fortitude" 21562 -- "Commanding Shout" 469 -- "Blood Pact" 166928
	{ 21562, jps.buffMissing(21562) , "player" },
	-- SNM "Nova" 132157 -- keep buff "Words of Mending" 155362 "Mot de guérison"
	{ 132157, jps.UseCDs and jps.buffStacks(155362) < 5 , "player" , "Nova_WoM" },

	{"nested", jps.PvP , {
		-- "Gardien de peur" 6346
		{ 6346, not jps.buff(6346,"player") , "player" },
		-- SNM "Fortitude" 21562 -- "Commanding Shout" 469 -- "Blood Pact" 166928
		{ 21562, jps.buffMissing(21562) and jps.buffMissing(469) and jps.buffMissing(166928) , "player" },
	}},

	-- "Shield" 17 "Body and Soul" 64129 -- figure out how to speed buff everyone as they move
	{ 17, jps.Moving and BodyAndSoul and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Shield_BodySoul" },
	-- "Pénitence" 47540
	{ 47540, LowestImportantUnitHpct < 0.25  , LowestImportantUnit , "Penance_" },
	-- "Prière de soins" 596 "Prayer of Healing"
	{ 596, not jps.Moving and canHeal(POHTarget) , POHTarget , "POH_" },
	-- "Soins" 2060
	{ 2060, not jps.Moving and LowestImportantUnitHpct < 0.50 , LowestImportantUnit , "Soins_"  },
	
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ 33076, not jps.Moving and not jps.buff(41635,myTank) and canHeal(myTank) , myTank , "Mending_Tank" },
	-- ClarityTank -- "Clarity of Will" 152118 shields with protective ward for 20 sec
	{ 152118, not jps.Moving and canHeal(myTank) and not jps.buff(152118,myTank) and not jps.isRecast(152118,myTank) , myTank , "Clarity_Tank" },
	
	-- "Oralius' Whispering Crystal" 118922 "Cristal murmurant d’Oralius"
	{ {"macro","/use item:118922"}, not jps.buff(105691) and not jps.buff(156070) and not jps.buff(156079) and jps.itemCooldown(118922) == 0 and not jps.buff(176151) , "player" , "Item_Oralius"},

}

	local spell,target = parseSpellTable(spellTableOOC)
	return spell,target

end,"OOC Disc Priest",nil,nil,nil,true)

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
-- First must put OOC casting from PCMD into htordeux version.
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