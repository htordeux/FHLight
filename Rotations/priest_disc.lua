-- jps.Interrupts for Dispel
-- jps.MultiTarget for "Carapace spirituelle" when casting POH
-- jps.Defensive changes the LowestImportantUnit to table = { "player","focus","target","targettarget","mouseover" }
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

----------------------------
-- ROTATION
----------------------------

local priestDisc = function()

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local spell = nil
	local target = nil

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(1)
	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER
	local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
	
	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHealth = jps.hp(LowestImportantUnit,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local LowestImportantUnitHpct = jps.hp(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(0.70) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local ShellTarget = jps.FindSubGroupAura(114908,LowestImportantUnit) -- buff target Spirit Shell 114908 need SPELLID
	
----------------------------
-- LOCAL FUNCTIONS FRIENDS
----------------------------

	local ShieldTarget = nil
	local ShieldTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForShield(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ShieldTargetHealth then
				ShieldTarget = unit
				ShieldTargetHealth = unitHP
			end
		end
	end

	local MendingTarget = nil
	local MendingTargetHealth = 1
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForMending(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < MendingTargetHealth then
				MendingTarget = unit
				MendingTargetHealth = unitHP
			end
		end
	end
	
	local BindingHealTarget = nil
	local BindingHealTargetHealth = 1
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForBinding(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < BindingHealTargetHealth then
				BindingHealTarget = unit
				BindingHealTargetHealth = unitHP
			end
		end
	end

	local DispelFriendlyTarget = nil
	local DispelFriendlyTargetHealth = 1
	for _,unit in ipairs(FriendUnit) do 
		if jps.DispelFriendly(unit) then
			local unitHP = jps.hp(unit)
			if unitHP < DispelFriendlyTargetHealth then
				DispelFriendlyTarget = unit
				DispelFriendlyTargetHealth = unitHP
			end
		end
	end

	local DispelTarget = jps.FindMeDispelTarget( {"Magic"} ) -- {"Magic", "Poison", "Disease", "Curse"}
	local DispelTargetRole = nil
	for _,unit in ipairs(FriendUnit) do 
		local role = UnitGroupRolesAssigned(unit)
		if role == "HEALER" and jps.canDispel(unit,{"Magic"}) then
			DispelTargetRole = unit
		end
	end
	
	-- priest.unitForLeap includes jps.FriendAggro and jps.LoseControl
	local LeapFriend = nil
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForLeap(unit) and jps.hp(unit) < 0.50 then 
			LeapFriend = unit
		break end
	end

	local ClarityFriend = nil
	local ClarityFriendHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if jps.FriendAggro(unit) and not jps.buff(152118,unit) then
			local unitHP = jps.hp(unit)
			if unitHP < ClarityFriendHealth then
				ClarityFriend = unit
				ClarityFriendHealth = unitHP
			end
		end
	end

---------------------
-- ENEMY TARGET
---------------------

	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") then rangedTarget = "mouseover"
	end
	-- if your target is friendly keep it as target
	if not jps.canHeal("target") and canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

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

------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- STOPCASTING --
------------------------------------------------------

local InterruptTable = {
	{priest.Spell.FlashHeal, 0.75, jps.buffId(priest.Spell.SpiritShellBuild) },
	{priest.Spell.Heal, 0.90, jps.buffId(priest.Spell.SpiritShellBuild) },
	{priest.Spell.PrayerOfHealing, 0.85, jps.buffId(priest.Spell.SpiritShellBuild) or jps.MultiTarget},
	{priest.Spell.ClarityOfWill, 0.75, jps.IsSpellKnown(152118) }
  }

-- Avoid interrupt Channeling
	if jps.ChannelTimeLeft() > 0 then return nil end
-- Avoid Overhealing
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss ,  CountInRange )

------------------------
-- LOCAL TABLES
------------------------

	parseShell = {
	--TANK not Buff Spirit Shell 114908
		{ 2061, jps.buff(114255) , LowestImportantUnit , "Carapace_SoinsRapides_Waves_"..LowestImportantUnit },
		{ 596, jps.MultiTarget and jps.canHeal(ShellTarget) , ShellTarget , "Carapace_Shell_Target_" },
		{ 2061, not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_NoBuff_SoinsRapides_"..LowestImportantUnit },
		{ 2060, not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_NoBuff_SoinsSup_"..LowestImportantUnit },		
	--TANK Buff Spirit Shell 114908
		{ 2061, jps.buffId(114908,LowestImportantUnit) and (UnitGetTotalAbsorbs(LowestImportantUnit) <= priest.AvgAmountFlashHeal) , LowestImportantUnit , "Carapace_Buff_SoinsRapides_"..LowestImportantUnit },
		{ 2060, jps.buffId(114908,LowestImportantUnit) and (UnitGetTotalAbsorbs(LowestImportantUnit) <= priest.AvgAmountFlashHeal) , LowestImportantUnit , "Carapace_Buff_SoinsSup_"..LowestImportantUnit },
	}
	
	parseControl = {
		-- "Silence" 15487
		{ 15487, jps.IsSpellInRange(15487,rangedTarget) and EnemyCaster(rangedTarget) == "caster" , rangedTarget },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	parseDispel = {
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelTargetRole) == "string" , DispelTargetRole , "|cff1eff00DispelTargetRole_MultiUnit_" },
		{ 527, type(DispelFriendlyTarget) == "string" , DispelFriendlyTarget , "|cff1eff00DispelFriendlyTarget_MultiUnit_" },
		{ 527, type(DispelTarget) == "string" , DispelTarget , "|cff1eff00DispelTarget_MultiUnit_" },
		-- "Leap of Faith" 73325 -- "Saut de foi"
		{ 73325 , type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
	}

------------------------
-- SPELL TABLE ---------
------------------------

	spellTable = {
	
	{"nested", not jps.Combat , 
		{
			-- "Gardien de peur" 6346
			{ 6346, not jps.buff(6346,"player") , "player" },
			-- "Fortitude" 21562 Keep Inner Fortitude up 
			{ 21562, jps.buffMissing(21562) , "player" },
		},
	},
	  
	-- RACIAL COUNTERS --
	-- "Will of the Forsaken" 7744
	-- Fears
	{ 7744, jps.debuff("psychic scream","player") and jps.UseCDs},
	{ 7744, jps.debuff("fear","player") and jps.UseCDs},
	{ 7744, jps.debuff("intimidating shout","player") and jps.UseCDs},
	{ 7744, jps.debuff("howl of terror","player") and jps.UseCDs},
	-- Charms
	{ 7744, jps.debuff("mind control","player") and jps.UseCDs},
	{ 7744, jps.debuff("seduction","player") and jps.UseCDs},
	-- Sleep
	{ 7744, jps.debuff("wyvern sting","player") and jps.UseCDs},
	
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun , "player" },
	{ jps.useTrinket(0), jps.useTrinketBool(0) and jps.hp() < 0.25 , "player" },
	-- "Soins rapides" 2061 -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and LowestImportantUnitHealth > priest.AvgAmountFlashHeal , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	{ 2061, jps.buff(114255) and jps.buffDuration(114255) < 4 , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	-- "Suppression de la douleur" 33206 "Pain Suppression"
	{ 33206, LowestImportantUnitHpct < 0.40 , LowestImportantUnit , "Emergency_Pain_"..LowestImportantUnit },
	-- "Pénitence" 47540
	{ 47540, LowestImportantUnitHpct < 0.40 , "Emergency_Penance_"..LowestImportantUnit },
	-- "Shield" 17
	{ 17, LowestImportantUnitHpct < 0.40 and not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
	-- "Prière de guérison" 33076 -- TIMER POM
	{ 33076, not jps.Moving and jps.combatStart > 0 and not jps.buffTracker(33076) , LowestImportantUnit , "Tracker_Mending_"..LowestImportantUnit },
	
	-- FAKE CAST --
	-- "Hearthstone" 6948
	--{ 6948, jps.castEverySeconds(6948,1.5) and playerAggro and
	-- PvP only
	-- Health is below 50% and enemy is focusing player
	-- Use hearthstone
	-- Time out hearthstone use if not interrupted or cast timer expires
	-- Alternate non-heal fake cast not in holy school?
	
	-- CONTROL -- "Psychic Scream" 8122 "Cri psychique" -- "Silence" 15487
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit" },
	{ "nested", not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },

	-- "Shield" 17 PlayerAggro
	{ 17, playerAggro and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Shield_Player" },
	{ "nested", jps.hp() < 0.85 and playerAggro ,
		{
			-- "Suppression de la douleur" 33206 "Pain Suppression"
			{ 33206, jps.hp() < 0.40 , "player", "Aggro_Player_Pain" },
			-- "Pierre de soins" 5512
			{ {"macro","/use item:5512"}, jps.itemCooldown(5512)==0 and jps.hp() < 0.60 , "player" , "Aggro_Player_Item5512" },
			-- "Prière du désespoir" 19236
			{ 19236, jps.IsSpellKnown(19236) and jps.hp() < 0.50 , "player" , "Aggro_Player_DESESPERATE" },
			-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même
			-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
			{ 586, jps.IsSpellKnown(108942) , "player" , "Aggro_Player_Oubli" },
			{ 586, jps.glyphInfo(55684) , "player" , "Aggro_Player_Oubli" },
			-- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
			{ 527, jps.canDispel("player",{"Magic"}) , "player" , "Aggro_Player_Dispel" },
			-- "Pénitence" 47540
			{ 47540, true , "player" , "Aggro_Player_Penance" },
			-- "Don des naaru" 59544
			{ 59544, true , "player" , "Aggro_Player_Naaru" },
			-- "Nova" 132157
			{ 132157, jps.hp() < 0.40 , "player" , "Aggro_Nova_Player" },
		},
	},

	-- "Infusion de puissance" 10060
	{ 10060, LowestImportantUnitHpct < 0.75 and jps.combatStart > 0 , "player" , "POWERINFUSION_" },
	-- "Archange" 81700 -- "Evangélisme" 81661 buffStacks == 5
	{ 81700, AvgHealthLoss < 0.85 and jps.buffStacks(81661) == 5 , "player", "ARCHANGE_Health" },
	{ 81700, LowestImportantUnitHpct < 0.85 and jps.buffDuration(81661) < 9  , "player", "ARCHANGE_Timeout" },
	-- "Pénitence" 47540
	{ 47540, LowestImportantUnitHealth > priest.AvgAmountGreatHeal , "Penance_"..LowestImportantUnit },
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes_"..rangedTarget },
	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace_"..rangedTarget },
	
	-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
	{ "nested", jps.buffId(109964) and not jps.Moving , parseShell },
	-- "Cascade" Holy 121135 Shadow 127632
	{ 121135, not jps.Moving and CountInRange > 2 and AvgHealthLoss < 0.85 , LowestImportantUnit ,  "Cascade_"..LowestImportantUnit },
	-- GROUP HEAL --
	{ "nested", (type(POHTarget) == "string") and jps.MultiTarget ,
		{
			-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
			{ 109964, jps.IsSpellKnown(109964) , POHTarget , "Carapace_POH_" },
			{ 596, jps.canHeal(POHTarget) , POHTarget , "POH_" },
		},
	},

	-- EMERGENCY HEAL --
	{ "nested", LowestImportantUnitHpct < 0.75 ,
		{
			-- "Shield" 17
			{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
			-- "Shield" 17 -- Divine Insight -- HOLY
			--{ 17, not jps.buff(17,LowestImportantUnit) and jps.buffId(123266,"player") , LowestImportantUnit , "Emergency_DivineShield_"..LowestImportantUnit  },
			-- "Pénitence" 47540
			{ 47540, true , LowestImportantUnit , "Emergency_Penance_"..LowestImportantUnit },
			-- "Soins rapides" 2061 "Borrowed" 59889
			{ 2061, not jps.Moving and jps.buff(59889,"player") and LowestImportantUnitHpct < 0.40 , LowestImportantUnit , "Emergency_SoinsRapides_Borrowed_"..LowestImportantUnit },
			-- "Soins supérieurs" 2060 "Borrowed" 59889
			{ 2060, not jps.Moving and jps.buff(59889,"player") and LowestImportantUnitHpct > 0.40 , LowestImportantUnit , "Emergency_SoinsSup_Borrowed_"..LowestImportantUnit  },
			-- "Clarity of Will" 152118 shields with protective ward for 20 sec
			{ 152118, not jps.Moving and not jps.buff(152118,LowestImportantUnit) , LowestImportantUnit , "Emergency_Clarity_"..LowestImportantUnit },
			-- "Soins rapides" 2061
			{ 2061, not jps.Moving and LowestImportantUnitHpct < 0.40 , LowestImportantUnit , "Emergency_SoinsRapides_"..LowestImportantUnit },
			-- "Purify" 522 -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
			{ 527, jps.canDispel(LowestImportantUnit,{"Magic"}) , LowestImportantUnit , "Emergency_Dispell"..LowestImportantUnit },
			-- "Prière de guérison" 33076
			{ 33076, not jps.Moving and (type(MendingTarget) == "string") , MendingTarget , "Emergency_MendingTarget" },
			-- "Don des naaru" 59544
			{ 59544, jps.IsSpellKnown(59544) , LowestImportantUnit , "Emergency_Naaru_"..LowestImportantUnit },
		},
	},

	-- PROACTIVE BUBBLES --
	-- "Clarity of Will" 152118 shields with protective ward for 20 sec
	{ 152118, not jps.Moving and type(ClarityFriend) == "string" , ClarityFriend , "Timer_ClarityFriend" },
	-- "Clarity of Will" 152118 
	{ 152118, not jps.Moving and not jps.buff(152118) and playerAggro , "player" , "Timer_ClarityPlayer" },
	-- "Power Word: Shield" 17 -- TIMER SHIELD
	{ 17, (type(ShieldTarget) == "string") , ShieldTarget , "Timer_ShieldTarget" },

	-- DISPEL --
	{ "nested", jps.Interrupts , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },

	-- DAMAGE --
	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.85 ,
		{
			-- "Pénitence" 47540
			{ 47540, jps.glyphInfo(119866) , rangedTarget,"|cFFFF0000Penance_"..rangedTarget },
			-- "Mot de l'ombre: Douleur" 589 -- Only if 1 targeted enemy 
			{ 589, TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget , "|cFFFF0000Douleur_"..rangedTarget },
			-- "Châtiment" 585
			{ 585, CountInRange > 0 and jps.castEverySeconds(585,2.5) , rangedTarget , "|cFFFF0000Chatiment_"..rangedTarget },
		},
	},

	-- "Don des naaru" 59544
	{ 59544, (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit  },
	-- "Soins" 2060
	{ 2060, not playerAggro and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit   },
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","DISCIPLINE", priestDisc , "Disc Priest Default" )

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
-- "Mot de l'ombre : Mort" 32379 -- SHADOW
-- Divine Insight -- HOLY

