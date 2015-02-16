-- jps.Interrupts for Dispel
-- jps.Defensive changes the LowestImportantUnit to table = { "player","focus","target","targettarget","mouseover" } with insert TankUnit  = jps.findAggroInRaid()
-- jps.FaceTarget to DPSing


local L = MyLocalizationTable
local spellTable = {}
local parseMoving = {}
local parseShell = {}
local parsePlayerShell = {}
local parseControl = {}
local parseDispel = {}
local UnitIsUnit = UnitIsUnit
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local ipairs = ipairs
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local tinsert = table.insert

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

local ClarityFriendTarget = function(unit)
	if not jps.UnitExists(unit) then return false end
	if not jps.FriendAggro(unit) then return false end
	--if UnitGetTotalAbsorbs(unit) > 0 then return false end
	if jps.buff(152118,unit) then return false end
	return true
end

local ShieldFriendTarget = function(unit)
	if not jps.UnitExists(unit) then return false end
	if not priest.unitForShield(unit) then return false end
	if UnitGetTotalAbsorbs(unit) > 0 then return false end
	return true
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION PVE ------------------------------------------------
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
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local ShellTarget = jps.FindSubGroupAura(114908,LowestImportantUnit) -- buff target Spirit Shell 114908 need SPELLID
	local TankUnit, myTank  = jps.findAggroInRaid() -- return Table with UnitThreatSituation == 3 (tanking) or == 1 (Overnuking)
	local TankTarget = "target"
	if canHeal(myTank) then TankTarget = myTank.."target" end

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER

	local playerWasControl = false
	if playerIsStun then jps.createTimer("playerWasControl",2) end
	if jps.checkTimer("playerWasControl") > 0 then playerWasControl = true end

---------------------
-- ENEMY TARGET
---------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS(TankTarget) then rangedTarget = TankTarget
	elseif canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local MendingFriend = nil
	local MendingFriendHealth = 1
	for _,unit in ipairs(FriendUnit) do
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
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForLeap(unit) and jps.hp(unit) < 0.25 then 
			LeapFriend = unit
		break end
	end
	
	-- priest.unitForShield includes jps.FriendAggro
	local ShieldFriend = nil
	local ShieldFriendHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if ShieldFriendTarget(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldFriendHealth then
				ShieldFriend = unit
				ShieldFriendHealth = unitHP
			end
		end
	end

	-- TANK -- 
	-- priest.unitForShield includes jps.FriendAggro
	local ShieldTank = nil
	local ShieldTankHealth = 100
	for _,unit in ipairs(TankUnit) do
		if priest.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldTankHealth then
				ShieldTank = unit
				ShieldTankHealth = unitHP
			end
		end
	end
	
	local ClarityTank = nil
	local ClarityTankHealth = 100
	for _,unit in ipairs(TankUnit) do
		if ClarityFriendTarget(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ClarityTankHealth then
				ClarityTank = unit
				ClarityTankHealth = unitHP
			end
		end
	end

	-- DISPEL --
	local DispelFriend = jps.FindMeDispelTarget( {"Magic"} ) -- {"Magic", "Poison", "Disease", "Curse"}

	local DispelFriendRole = nil
	for _,unit in ipairs(TankUnit) do 
		if jps.canDispel(unit,{"Magic"}) then
			DispelFriendRole = unit
		break end
	end
	
------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local SilenceEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do
		if jps.IsSpellInRange(15487,unit) then
			if jps.ShouldKick(unit) then
				SilenceEnemyTarget = unit
			break end
		end
	end

	local FearEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canFear(unit) and not jps.LoseControl(unit) then
			FearEnemyTarget = unit
		break end
	end

------------------------
-- LOCAL TABLES
------------------------

	parseShell = {
	--TANK not Buff Spirit Shell 114908
		{ 2061, jps.buff(114255) , LowestImportantUnit , "Carapace_FlashHeal_Light_"..LowestImportantUnit },
		{ 596, canHeal(ShellTarget) , ShellTarget , "Carapace_Shell_Target_" },
		{ 2061, not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_NoBuff_FlashHeal_"..LowestImportantUnit },	
	--TANK Buff Spirit Shell 114908
		{ 2060, jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_Buff_Soins_"..LowestImportantUnit },
	}
	
	parseControl = {
		-- "Silence" 15487
		{ 15487, jps.IsCastingControl(rangedTarget) , rangedTarget , "Silence_"..rangedTarget },
		-- "Psychic Scream" "Cri psychique" 8122 -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelFriendRole) == "string" , DispelFriendRole , "|cff1eff00DispelFriendRole_MultiUnit_" },
		{ 527, type(DispelFriend) == "string" , DispelFriend , "|cff1eff00DispelFriend_MultiUnit_" },
	}
	
------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

local InterruptTable = {
	{priest.Spell.FlashHeal, 0.75, jps.buffId(priest.Spell.SpiritShellBuild) },
	{priest.Spell.Heal, 0.90, jps.buffId(priest.Spell.SpiritShellBuild) },
	{priest.Spell.PrayerOfHealing, 0.85, jps.buffId(priest.Spell.SpiritShellBuild)},
  }
  
	-- AVOID OVERHEALING
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss , CountInRange )

------------------------
-- SPELL TABLE ---------
------------------------

spellTable = {

	{"nested", not jps.Combat , {
		-- "Gardien de peur" 6346
		--{ 6346, not jps.buff(6346,"player") , "player" },
		-- "Fortitude" 21562 Keep Fortitude up 
		{ 21562, jps.buffMissing(21562) , "player" },
		-- SNM "Levitate" 1706 -- try to keep buff for enemy dispel -- Buff "Lévitation" 111759
		{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) },
		{ 1706, IsSwimming() and not jps.buff(111759) and not playerAggro },
		-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
		{ 33076, not jps.Moving and not jps.buffTracker(41635) and canHeal("focus") , "focus" , "Focus_Mending_" },
	},},
	
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ 33076, not jps.Moving and not jps.buffTracker(41635) and canHeal(myTank) and jps.hp(myTank) > 0.80 , myTank , "myTank_Mending_" },
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , "player" , "Trinket0"},
	{ jps.useTrinket(1), jps.useTrinketBool(1) and not playerWasControl and jps.combatStart > 0 , "player" , "Trinket1"},

	-- "Suppression de la douleur" 33206 "Pain Suppression"
	{ 33206, playerIsStun and jps.hp() < 0.35 , "player", "Stun_Pain" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.itemCooldown(5512) == 0 and jps.hp() < 0.75 , "player" , "Item5512" },
	-- "Prière du désespoir" 19236
	{ 19236, jps.IsSpellKnown(19236) and jps.hp() < 0.75 , "player" , "Aggro_DESESPERATE" },

	{ "nested", playerAggro ,{
		-- "Shield" 17
		{ 17, not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield" },
		-- "Semblance spectrale" 112833
		{ 112833, jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },
		-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même
		{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
		-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
		{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
		-- "Don des naaru" 59544
		{ 59544, jps.hp() < 0.75 , "player" , "Aggro_Naaru" },
		-- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
		{ 527, jps.canDispel("player",{"Magic"}) , "player" , "Aggro_Dispel" },
	},},

	-- EMERGENCY HEAL --
	{ "nested", LowestImportantUnitHpct < 0.50 ,{
		-- "Suppression de la douleur" 33206 "Pain Suppression" -- Buff "Pain Suppression" 33206
		{ 33206, LowestImportantUnitHpct < 0.35 , LowestImportantUnit , "Emergency_Pain_"..LowestImportantUnit },
		-- "Soins rapides" 2061 -- "Vague de Lumière" 114255 "Surge of Light"
		--{ 2061, jps.buff(114255) and LowestImportantUnitHealth > priest.AvgAmountGreatHeal , LowestImportantUnit , "FlashHeal_Light_"..LowestImportantUnit },
		--{ 2061, jps.buff(114255) and jps.buffDuration(114255) < 4 , LowestImportantUnit , "FlashHeal_Light_"..LowestImportantUnit },
		-- "Shield" 17
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
		-- SNM Troll "Berserker" 26297 -- haste buff
		{ 26297, true , "player" },
		-- "Soins rapides" 2061 -- Buff "Borrowed" 59889 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 2061, not jps.Moving and jps.buff(59889,"player") , LowestImportantUnit , "Emergency_FlashHeal_Borrowed_"..LowestImportantUnit },
		{ 2061, not jps.Moving and jps.buff(172359,"player") , LowestImportantUnit , "Emergency_FlashHeal_ARCHANGE_"..LowestImportantUnit },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance_"..LowestImportantUnit },
		-- "Archange" 81700 -- Buff 81700 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 81700, jps.buffStacks(81661) == 5 , "player", "Emergency_ARCHANGE" },
		-- "Infusion de puissance" 10060 -- Buff "Pain Suppression" 33206
		{ 10060, jps.buff(33206,LowestImportantUnit) , LowestImportantUnit , "Emergency_POWERINFUSION" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving and LowestImportantUnitHpct < 0.35 , LowestImportantUnit , "Emergency_FlashHeal1_"..LowestImportantUnit },
		-- "Prière de guérison" 33076 -- Buff POM 41635
		{ 33076, not jps.Moving and not jps.buff(41635,LowestImportantUnit) , LowestImportantUnit , "Emergency_Mending_"..LowestImportantUnit },

		-- "Cascade" Holy 121135 Shadow 127632
		{ 121135, not jps.Moving and CountInRange > 2 and AvgHealthLoss < 0.75 , LowestImportantUnit ,  "Emergency_Cascade_"..LowestImportantUnit },
		-- "POH" 596
		{ 596, not jps.Moving and (type(POHTarget) == "string") and canHeal(POHTarget) , POHTarget , "Emergency_POH_" },

		-- "Clarity of Will" 152118 shields with protective ward for 20 sec
		{ 152118, not jps.Moving and ClarityFriendTarget(LowestImportantUnit) and jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Clarity" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving , LowestImportantUnit , "Emergency_FlashHeal2_"..LowestImportantUnit },
	},},

	-- DISPEL -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
	{ "nested", jps.Interrupts , parseDispel },
	
	-- CONTROL --
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit" },

	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ 33076, not jps.Moving and not jps.buffTracker(41635) and type(MendingFriend) == "string" , MendingFriend , "Tracker_Mending_" },

	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace_"..rangedTarget },
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes_"..rangedTarget },

	-- ShieldTank
	{ 17, type(ShieldTank) == "string" , ShieldTank , "Timer_ShieldTank" },
	-- PénitenceTank
	{ 47540, canHeal(myTank) and jps.hp(myTank) < 0.80 , myTank , "Penance_myTank" },
	-- ClarityTank -- "Clarity of Will" 152118 shields with protective ward for 20 sec
	{ 152118, LowestImportantUnitHpct > 0.80 and not jps.Moving and type(ClarityTank) == "string" , ClarityTank , "Timer_ClarityTank" },

	-- "Infusion de puissance" 10060
	{ 10060, AvgHealthLoss < 0.75 and jps.combatStart > 0 , "player" , "HealthLoss_POWERINFUSION" },
	-- "Archange" 81700 -- "Evangélisme" 81661 buffStacks == 5
	{ 81700, AvgHealthLoss < 0.75 and jps.buffStacks(81661) == 5 and jps.combatStart > 0 , "player", "HealthLoss_ARCHANGE" },

	-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
	{ "nested", jps.buffId(109964) and not jps.Moving , parseShell },

	-- GROUP HEAL --
	-- "Cascade" Holy 121135 Shadow 127632
	{ 121135, not jps.Moving and CountInRange > 2 and AvgHealthLoss < 0.80 , LowestImportantUnit ,  "Cascade_"..LowestImportantUnit },
	{ "nested", (type(POHTarget) == "string") ,{
		-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
		{ 109964, jps.IsSpellKnown(109964) , POHTarget , "Carapace_POH_" },
		-- "Prière de soins" 596 "Prayer of Healing"
		{ 596, canHeal(POHTarget) , POHTarget , "POH_" },
	},},

	-- HEAL --
	{ "nested", LowestImportantUnitHpct < 0.80 ,{
		-- "Shield" 17
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Shield_"..LowestImportantUnit },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance_"..LowestImportantUnit },
		-- "Soins" 2060 -- Buff "Borrowed" 59889
		{ 2060, not jps.Moving and jps.buff(59889) , LowestImportantUnit , "Soins_"..LowestImportantUnit  },
		{ 2060, not jps.Moving and jps.buff(152118,LowestImportantUnit) , LowestImportantUnit , "Soins_"..LowestImportantUnit  },
		{ 2060, not jps.Moving and jps.myLastCast(152118) , LowestImportantUnit , "Soins_"..LowestImportantUnit  },
		-- "Don des naaru" 59544
		{ 59544, true , LowestImportantUnit , "Naaru_"..LowestImportantUnit },
		-- "Clarity of Will" 152118 shields with protective ward for 20 sec
		{ 152118, not jps.Moving and ClarityFriendTarget(LowestImportantUnit) and jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit  , "Clarity_"..LowestImportantUnit  },
		-- "Soins" 2060 -- Buff "Borrowed" 59889
		{ 2060, not jps.Moving , LowestImportantUnit , "Soins_"..LowestImportantUnit  },
	},},

	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	
	-- PROACTIVE BUBBLES --
	-- "Power Word: Shield" 17 -- try to keep Buff "Borrowed" 59889 always
	{ 17, type(ShieldFriend) == "string" , ShieldFriend , "Timer_ShieldFriend" },

	-- DAMAGE --
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.80 ,{
		-- "Pénitence" 47540
		{ 47540, jps.glyphInfo(119866) , rangedTarget,"|cFFFF0000Penance_"..rangedTarget },
		-- "Mot de l'ombre: Douleur" 589 -- Only if 1 targeted enemy 
		{ 589, TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget , "|cFFFF0000Douleur_"..rangedTarget },
		-- "Châtiment" 585
		{ 585, CountInRange > 0 and jps.castEverySeconds(585,2) , rangedTarget , "|cFFFF0000Chatiment_"..rangedTarget },
	},},

	-- "Pénitence" 47540
	{ 47540, LowestImportantUnitHealth > priest.AvgAmountGreatHeal , LowestImportantUnit },
	-- "Soins" 2060
	{ 2060, not jps.Moving and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit },
	-- "Gardien de peur" 6346
	--{ 6346, not jps.buff(6346,"player") , "player" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","DISCIPLINE", priestDisc , "Disc Priest PVE" , true, false)

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

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION PVP ------------------------------------------------
----------------------------------------------------------------------------------------------------------------

local priestDiscPvP = function()

	local spell = nil
	local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHealth = jps.hp(LowestImportantUnit,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(0.75) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local ShellTarget = jps.FindSubGroupAura(114908,LowestImportantUnit) -- buff target Spirit Shell 114908 need SPELLID
	local TankUnit, myTank  = jps.findAggroInRaid() -- return Table with UnitThreatSituation == 3 (tanking) or == 1 (Overnuking)

	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER
	-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER

	local playerWasControl = false
	if playerIsStun then jps.createTimer("playerWasControl",2) end
	if jps.checkTimer("playerWasControl") > 0 then playerWasControl = true end

   -- SNM
   local playerTTD = jps.TimeToDie("player")
   local isArena, _ = IsActiveBattlefieldArena()
   
---------------------
-- ENEMY TARGET
---------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	local PlayerIsTargeted = false
	for _,enemy in ipairs(EnemyUnit) do
		if TargetCount > 0 then
			if jps.UnitIsUnit(enemy.."target","player") then
				PlayerIsTargeted = true
			break end
		end
	end
	
----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local MendingFriend = nil
	local MendingFriendHealth = 1
	for _,unit in ipairs(FriendUnit) do
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
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForLeap(unit) and jps.hp(unit) < 0.25 then 
			LeapFriend = unit
		break end
	end
	
	-- priest.unitForShield includes jps.FriendAggro
	local ShieldFriend = nil
	local ShieldFriendHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if ShieldFriendTarget(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldFriendHealth then
				ShieldFriend = unit
				ShieldFriendHealth = unitHP
			end
		end
	end

	-- TANK -- 
	-- priest.unitForShield includes jps.FriendAggro
	local ShieldTank = nil
	local ShieldTankHealth = 100
	for _,unit in ipairs(TankUnit) do
		if priest.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldTankHealth then
				ShieldTank = unit
				ShieldTankHealth = unitHP
			end
		end
	end
	
	local ClarityTank = nil
	local ClarityTankHealth = 100
	for _,unit in ipairs(TankUnit) do
		if ClarityFriendTarget(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ClarityTankHealth then
				ClarityTank = unit
				ClarityTankHealth = unitHP
			end
		end
	end

	-- DISPEL --
	local DispelFriend = nil
	local DispelFriendHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if jps.DispelFriendly(unit,2) then
			local unitHP = jps.hp(unit)
			if unitHP < DispelFriendHealth then
				DispelFriend = unit
				DispelFriendHealth = unitHP
			end
		end
	end

	local DispelFriendRole = nil
	for _,unit in ipairs(TankUnit) do 
		if jps.canDispel(unit,{"Magic"}) then
			DispelFriendRole = unit
		break end
	end
	
------------------------
-- LOCAL FUNCTIONS ENEMY
------------------------

	local SilenceEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do
		if jps.IsSpellInRange(15487,unit) then
			if jps.ShouldKick(unit) then
				SilenceEnemyTarget = unit
			break end
		end
	end

	local FearEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canFear(unit) and not jps.LoseControl(unit) then
			FearEnemyTarget = unit
		break end
	end

------------------------
-- LOCAL TABLES
------------------------

	parseShell = {
	--TANK not Buff Spirit Shell 114908
		{ 2061, jps.buff(114255) , LowestImportantUnit , "Carapace_FlashHeal_Light_"..LowestImportantUnit },
		{ 596, canHeal(ShellTarget) , ShellTarget , "Carapace_Shell_Target_" },
		{ 2061, not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_NoBuff_FlashHeal_"..LowestImportantUnit },	
	--TANK Buff Spirit Shell 114908
		{ 2060, jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_Buff_Soins_"..LowestImportantUnit },
	}
	
	parseControl = {
		-- "Silence" 15487
		{ 15487, jps.IsCastingControl(rangedTarget) , rangedTarget , "Silence_"..rangedTarget },
		-- "Psychic Scream" "Cri psychique" 8122 -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelFriendRole) == "string" , DispelFriendRole , "|cff1eff00DispelFriendRole_MultiUnit_" },
		{ 527, type(DispelFriend) == "string" , DispelFriend , "|cff1eff00DispelFriend_MultiUnit_" },
	}
	
------------------------------------------------------
-- OVERHEAL -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

local InterruptTable = {
	{priest.Spell.FlashHeal, 0.75, jps.buffId(priest.Spell.SpiritShellBuild) },
	{priest.Spell.Heal, 0.90, jps.buffId(priest.Spell.SpiritShellBuild) },
	{priest.Spell.PrayerOfHealing, 0.85, jps.buffId(priest.Spell.SpiritShellBuild)},
  }
  
	-- AVOID OVERHEALING
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss , CountInRange )

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
	
	--[[ SNM JUKE -- "Soins" 2060 -- alternate fake cast
	local Juke = UnitCastingInfo("player")
      if Juke == GetSpellInfo(2060) then
         if jps.CastTimeLeft() > 1 then
            SpellStopCasting()
      elseif LowestImportantUnitHpct < 0.60 then
            SpellStopCasting()
      elseif not playerAggro then
            SpellStopCasting()
      end
   end]]--
   
   -- SNM Trinket 1 use function to avoid blowing trinket when not needed
      -- False if rooted, not moving, and lowest friendly unit in range
      -- False if stunned/incapacitated but lowest friendly unit is good health
      -- False if stunned/incapacitated and playerAggro but player health is good

------------------------
-- SPELL TABLE ---------
------------------------

spellTable = {

	{"nested", not jps.Combat , {
		-- "Gardien de peur" 6346
		{ 6346, not jps.buff(6346,"player") , "player" },
		-- SNM "Fortitude" 21562 Keep Fortitude up -- "Commanding Shout" 469 -- "Blood Pact" 166928
		{ 21562, jps.buffMissing(21562) and jps.buffMissing(469) and jps.buffMissing(166928) , "player" },
		-- SNM "Levitate" 1706 -- try to keep buff for enemy dispel -- Buff "Lévitation" 111759
		{ 1706, not jps.buff(111759) and isArena == true , "player" },
		{ 1706, jps.fallingFor() > 1.5 and not jps.buff(111759) },
		{ 1706, IsSwimming() and not jps.buff(111759) and not playerAggro },
		-- SNM "Nova" 132157 -- keep buff "Words of Mending" 155362 "Mot de guérison" 
		{ 132157, jps.IsSpellKnown(155362) and jps.buffStacks(155362) < 10 , "player" , "WoM_Nova_Player" },
		-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
		{ 33076, not jps.Moving and not jps.buffTracker(41635) and canHeal("focus") , "focus" , "Focus_Mending_" },
	},},

	-- SNM "Levitate" 1706 -- "Dark Simulacrum" debuff 77606
	{ 1706, jps.debuff(77606,"player") , "player" , "DarkSim_Levitate" },
	
	-- SNM RACIAL COUNTERS -- share 30s cd with trinket
	{"nested", jps.UseCDs , {
		 -- Blood Elf "Arcane Torrent" 28730
		 -->{ 28730, jps.IsSpellInRange(8122,rangedTarget) and EnemyCaster(rangedTarget) == "caster" , rangedTarget },
		 -- Dwarf "Stoneform" 20594 Removes all poison, disease, curse, magic, and bleed effects and reduces all physical damage taken by 10% for 8 sec.
		 -->{ 20594, jps.hp() < 0.50 and playerAggro },
		 -- Gnome "Escape Artist" 20589
		 -->{ 20589, (jps.LoseControl("player","Root") or jps.LoseControl("player","Snare")) and jps.UseCDs },
		 -- Pandaren "Quaking Palm" 107079
		 -->{ 107079, EnemyCaster(rangedTarget) == "caster" , rangedTarget },
		 -- Tauren "War Stomp" 20549
		 -->{ 20549, jps.IsSpellInRange(8122,rangedTarget) and EnemyCaster(rangedTarget) == "caster" , rangedTarget },
		 -- Undead "Will of the Forsaken" 7744
		 { 7744, jps.debuff("psychic scream","player") }, -- Fear
		 { 7744, jps.debuff("fear","player") }, -- Fear
		 { 7744, jps.debuff("intimidating shout","player") }, -- Fear
		 { 7744, jps.debuff("howl of terror","player") }, -- Fear
		 { 7744, jps.debuff("mind control","player") }, -- Charm
		 { 7744, jps.debuff("seduction","player") }, -- Charm
		 { 7744, jps.debuff("wyvern sting","player") }, -- Sleep
	},},
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	-- SNM "Chacun pour soi" 59752 "Every Man for Himself" -- Human
	{ 59752, playerIsStun , "player" , "Every_Man_for_Himself" },
	{ jps.useTrinket(0), jps.useTrinketBool(0) and not playerWasControl and jps.combatStart > 0 , "player" , "Trinket0"},
	-- SNM dont blow trinket if not moving and rooted -- "ROOT" was removed of Stuntype
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun and LowestImportantUnitHpct < 0.75 , "player" , "Trinket1"},

	-- "Suppression de la douleur" 33206 "Pain Suppression"
	{ 33206, playerIsStun and jps.hp() < 0.35 , "player", "Stun_Pain" },
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, jps.itemCooldown(5512) == 0 and jps.hp() < 0.75 , "player" , "Item5512" },
	-- "Prière du désespoir" 19236
	{ 19236, jps.IsSpellKnown(19236) and jps.hp() < 0.75 , "player" , "Aggro_DESESPERATE" },

	{ "nested", playerAggro or playerWasControl ,{
		-- SNM -- Uncomment Coz Spam Chat ^_^
		--{ {"macro","/y Help! I'm a banana! PEEL ME!"}, jps.hp() < 0.50 and (playerIsStun or playerTTD < 6) and GetLocale() == "enUS" },
		--{ {"macro","/y Help! Je suis une banane! PEEL MOI!"}, jps.hp() < 0.50 and (playerIsStun or playerTTD < 6) and GetLocale() == "frFR" },
		-- "Shield" 17
		{ 17, not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Aggro_Shield" },
		-- "Semblance spectrale" 112833
		{ 112833, jps.IsSpellKnown(112833) , "player" , "Aggro_Spectral" },
		-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même
		{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
		-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
		{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Oubli" },
		-- "Pénitence" 47540
		{ 47540, jps.hp() < 0.75 , "player" , "Aggro_Penance" },
		-- "Don des naaru" 59544
		{ 59544, jps.hp() < 0.75 , "player" , "Aggro_Naaru" },
		-- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
		{ 527, jps.canDispel("player",{"Magic"}) , "player" , "Aggro_Dispel" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving and jps.hp() < 0.40 , "player" , "Aggro_FlashHeal" },
		-- SNM "Nova" 132157 -- "Words of Mending" 155362 "Mot de guérison"
		{ 132157, jps.hp() < 0.40 , "player" , "Aggro_Nova" },
		{ 132157, jps.IsSpellKnown(155362) and jps.buffStacks(155362) < 10 , "player" , "Aggro_Nova" },
		-- "Prière de guérison" 33076 -- Buff POM 41635
		{ 33076, not jps.Moving and not jps.buff(41635,"player") , "player" , "Aggro_Mending_" },
		-- "Clarity of Will" 152118 shields with protective ward for 20 sec
		{ 152118, not jps.Moving and ClarityFriendTarget("player") and jps.debuff(6788,"player") , "player" , "Aggro_Clarity" },
	},},

	-- "Leap of Faith" 73325 -- "Saut de foi"
	{ 73325, type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },

	-- SNM EMERGENCY FRIEND HEAL -- "Words of Mending" 155362 "Mot de guérison" -- buff same id
	{ "nested", LowestImportantUnitHpct < 0.50 ,{
		-- "Suppression de la douleur" 33206 "Pain Suppression" -- Buff "Pain Suppression" 33206
		{ 33206, LowestImportantUnitHpct < 0.35 , LowestImportantUnit , "Emergency_Pain_"..LowestImportantUnit },
		-- "Soins rapides" 2061 -- "Vague de Lumière" 114255 "Surge of Light"
		{ 2061, jps.buff(114255) and LowestImportantUnitHealth > priest.AvgAmountGreatHeal , LowestImportantUnit , "FlashHeal_Light_"..LowestImportantUnit },
		{ 2061, jps.buff(114255) and jps.buffDuration(114255) < 4 , LowestImportantUnit , "FlashHeal_Light_"..LowestImportantUnit },
		-- "Shield" 17
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
		-- SNM Troll "Berserker" 26297 -- haste buff
		{ 26297, true , "player" },
		-- "Soins rapides" 2061 -- Buff "Borrowed" 59889 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 2061, not jps.Moving and jps.buff(59889,"player") , LowestImportantUnit , "Emergency_FlashHeal_Borrowed_"..LowestImportantUnit },
		{ 2061, not jps.Moving and jps.buff(172359,"player") , LowestImportantUnit , "Emergency_FlashHeal_ARCHANGE_"..LowestImportantUnit },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance_"..LowestImportantUnit },
		-- "Archange" 81700 -- Buff 81700 -- "Archange surpuissant" 172359  100 % critique POH or FH
		{ 81700, jps.buffStacks(81661) == 5 , "player", "Emergency_ARCHANGE" },
		-- "Infusion de puissance" 10060 -- Buff "Pain Suppression" 33206
		{ 10060, jps.buff(33206,LowestImportantUnit) , LowestImportantUnit , "Emergency_POWERINFUSION" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving and LowestImportantUnitHpct < 0.35 , LowestImportantUnit , "Emergency_FlashHeal1_"..LowestImportantUnit },
		-- "Prière de guérison" 33076 -- Buff POM 41635
		{ 33076, not jps.Moving and not jps.buff(41635,LowestImportantUnit) , LowestImportantUnit , "Emergency_Mending_"..LowestImportantUnit },

		-- "Cascade" Holy 121135 Shadow 127632
		{ 121135, not jps.Moving and CountInRange > 2 and AvgHealthLoss < 0.75 , LowestImportantUnit ,  "Emergency_Cascade_"..LowestImportantUnit },
		-- "POH" 596
		{ 596, not jps.Moving and (type(POHTarget) == "string") and canHeal(POHTarget) , POHTarget , "Emergency_POH_" },

		-- "Clarity of Will" 152118 shields with protective ward for 20 sec
		{ 152118, not jps.Moving and ClarityFriendTarget(LowestImportantUnit) and jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Clarity" },
		-- "Soins rapides" 2061
		{ 2061, not jps.Moving , LowestImportantUnit , "Emergency_FlashHeal2_"..LowestImportantUnit },
	},},

	-- DISPEL -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
	{ "nested", jps.Interrupts , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },

	-- CONTROL --
	{ "nested", not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },
	
	-- TIMER POM -- "Prière de guérison" 33076 -- Buff POM 41635
	{ 33076, not jps.Moving and not jps.buffTracker(41635) and type(MendingFriend) == "string" , MendingFriend , "Tracker_Mending_" },

	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace_"..rangedTarget },
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes_"..rangedTarget },

	-- ShieldTank
	{ 17, type(ShieldTank) == "string" , ShieldTank , "Timer_ShieldTank" },
	-- ClarityTank -- "Clarity of Will" 152118 shields with protective ward for 20 sec
	{ 152118, LowestImportantUnitHpct > 0.80 and not jps.Moving and type(ClarityTank) == "string" , ClarityTank , "Timer_ClarityTank" },
	-- PénitenceTank
	{ 47540, canHeal(myTank) and jps.hp(myTank) < 0.80 , myTank , "Penance_myTank" },

	-- FAKE CAST -- 6948 -- "Hearthstone"
	{ {"macro","/use item:6948"}, not jps.Moving and playerAggro and jps.itemCooldown(6948) == 0 and LowestImportantUnitHpct > 0.85  , "player" , "Aggro_FAKECAST" },

	-- "Infusion de puissance" 10060
	{ 10060, AvgHealthLoss < 0.75 and jps.combatStart > 0 , "player" , "HealthLoss_POWERINFUSION" },
	-- "Archange" 81700 -- "Evangélisme" 81661 buffStacks == 5
	{ 81700, AvgHealthLoss < 0.75 and jps.buffStacks(81661) == 5 and jps.combatStart > 0 , "player", "HealthLoss_ARCHANGE" },

	-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
	{ "nested", jps.buffId(109964) and not jps.Moving , parseShell },

	-- GROUP HEAL --
	-- "Cascade" Holy 121135 Shadow 127632
	{ 121135, not jps.Moving and CountInRange > 2 and AvgHealthLoss < 0.80 , LowestImportantUnit ,  "Cascade_"..LowestImportantUnit },
	{ "nested", (type(POHTarget) == "string") ,{
		-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
		{ 109964, jps.IsSpellKnown(109964) , POHTarget , "Carapace_POH_" },
		-- "Prière de soins" 596 "Prayer of Healing"
		{ 596, canHeal(POHTarget) , POHTarget , "POH_" },
	},},

	-- HEAL --
	{ "nested", LowestImportantUnitHpct < 0.80 ,{
		-- "Shield" 17
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Shield_"..LowestImportantUnit },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance_"..LowestImportantUnit },
		-- "Soins" 2060 -- Buff "Borrowed" 59889
		{ 2060, not jps.Moving and jps.buff(59889) , LowestImportantUnit , "Soins_"..LowestImportantUnit  },
		{ 2060, not jps.Moving and jps.buff(152118,LowestImportantUnit) , LowestImportantUnit , "Soins_"..LowestImportantUnit  },
		-- "Don des naaru" 59544
		{ 59544, true , LowestImportantUnit , "Naaru_"..LowestImportantUnit },
		-- "Clarity of Will" 152118 shields with protective ward for 20 sec
		{ 152118, not jps.Moving and ClarityFriendTarget(LowestImportantUnit) and jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit  , "Clarity_"..LowestImportantUnit  },
		-- "Soins" 2060 -- Buff "Borrowed" 59889
		{ 2060, not jps.Moving , LowestImportantUnit , "Soins_"..LowestImportantUnit  },
	},},

	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	
	-- PROACTIVE BUBBLES --
	-- "Power Word: Shield" 17 -- try to keep Buff "Borrowed" 59889 always
	{ 17, type(ShieldFriend) == "string" , ShieldFriend , "Timer_ShieldFriend" },
	-- if "Shadowfiend" 34433 exists, cast PW:S
	{ 17, canHeal("pet") and not jps.buff(17,"pet") and not jps.debuff(6788,"pet"), "pet","Shadowfiend_Shield" },

	-- DAMAGE --
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.80 ,{
		-- "Pénitence" 47540
		{ 47540, jps.glyphInfo(119866) , rangedTarget,"|cFFFF0000Penance_"..rangedTarget },
		-- "Mot de l'ombre: Douleur" 589 -- Only if 1 targeted enemy 
		{ 589, TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget , "|cFFFF0000Douleur_"..rangedTarget },
		-- "Châtiment" 585
		{ 585, CountInRange > 0 and jps.castEverySeconds(585,2) , rangedTarget , "|cFFFF0000Chatiment_"..rangedTarget },
	},},

	-- "Pénitence" 47540
	{ 47540, LowestImportantUnitHealth > priest.AvgAmountGreatHeal , LowestImportantUnit },
	-- "Soins" 2060
	{ 2060, not jps.Moving and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit },
	-- "Gardien de peur" 6346
	{ 6346, not jps.buff(6346,"player") , "player" },

}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","DISCIPLINE", priestDiscPvP , "Disc Priest PVP" , false, true)

-------------------
-- SNM, MY TO DO --
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