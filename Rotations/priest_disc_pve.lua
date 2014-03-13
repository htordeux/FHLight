-- jps.Interrupts for Dispel

local L = MyLocalizationTable

local spellTable = {}
local parseDispel = {}
local parseControl = {}
local parseShell = {}
local parseEmergency = {}
local parsePOH = {}
local parseMoving = {}
local parseMana = {}
local parseDamage = {}
local parsePlayerShell = {}

local UnitIsUnit = UnitIsUnit
local canDPS = jps.canDPS

local priestDiscPvE = function()

	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.95)

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local timerShield = jps.checkTimer("Shield")
	local playerAggro = jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER
	local playerIsInterrupt = jps.checkTimer("Player_Interrupt")

	local LowestImportantUnit = jps.LowestImportantUnit()
	local LowestImportantUnitHealth = jps.hpInc(LowestImportantUnit,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local LowestImportantUnitHpct = jps.hpInc(LowestImportantUnit) -- UnitHealth(unit) / UnitHealthMax(unit)
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(0.70) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	local ShellTarget = jps.FindSubGroupAura(114908,LowestImportantUnit) -- buff target Spirit Shell 114908 need SPELLID
	local DispelTarget = jps.FindMeDispelTarget( {"Magic"} ) -- {"Magic", "Poison", "Disease", "Curse"}
	
----------------------------
-- FUNCTIONS FRIEND UNIT
----------------------------

	local ShieldTarget = nil
	local ShieldTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForShield(unit) then
			local unitHP = jps.hpInc(unit)
			if unitHP < ShieldTargetHealth then
				ShieldTarget = unit
				ShieldTargetHealth = unitHP
			end
		end
	end

	local MendingTarget = nil
	local MendingTargetHealth = 100
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForMending(unit) then
			local unitHP = jps.hpInc(unit)
			if unitHP < MendingTargetHealth then
				MendingTarget = unit
				MendingTargetHealth = unitHP
			end
		end
	end
	
	local BindingHealTarget = nil
	local BindingHealTargetHealth = 100
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
	for _,unit in ipairs(FriendUnit) do 
		if jps.DispelFriendly(unit) then 
			DispelFriendlyTarget = unit
		break end
	end

---------------------
-- ENEMY TARGET
---------------------

	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()
	if canDPS("target") then rangedTarget = "target" end
	if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
	
	local DeathEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canShadowWordDeath(unit) then 
			DeathEnemyTarget = unit
		break end
	end
	
	local FearEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if jps.IsCastingControl(unit) and priest.canFear(unit) then
			FearEnemyTarget = unit
		break end
	end

-------------------
-- DEBUG
-------------------

	if IsControlKeyDown() then
		write("|cff1eff00Name: ",GetUnitName(LowestImportantUnit),"|cffe5cc80hp: ",LowestImportantUnitHpct,"hpAbs: ",LowestImportantUnitHealth)
		write("Name: ",GetUnitName(jps.LowestInRaidStatus()),"|cffe5cc80hp: ",jps.hpInc(jps.LowestInRaidStatus()),"hpAbs: ",jps.hpInc(jps.LowestInRaidStatus(),"abs"))
		print("POHTarget: ", POHTarget, "groupToHeal: ", groupToHeal, "groupTableToHeal: ", unpack(groupTableToHeal))
	end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- STOPCASTING
----------------------------------------------------------

local InterruptTable = {
	{priest.Spell.flashHeal, 0.75, jps.buffId(priest.Spell.spiritShellBuild) or jps.buffId(priest.Spell.innerFocus) },
	{priest.Spell.greaterHeal, 0.95, jps.buffId(priest.Spell.spiritShellBuild) },
	{priest.Spell.heal, 1 , jps.buffId(priest.Spell.spiritShellBuild) },
	{priest.Spell.prayerOfHealing, 0.95, jps.buffId(priest.Spell.spiritShellBuild) or jps.MultiTarget}
}

-- Avoid interrupt Channeling
	if jps.ChannelTimeLeft() > 0 then return nil end
-- Avoid Overhealing
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss ,  CountInRange )

------------------------
-- LOCAL TABLES
------------------------

	parseDispel = {
		-- "Mass Dispel" 32375 "Dissipation de masse"
		-- "Leap of Faith" 73325 -- "Saut de foi"
		{ 73325 , priest.unitForLeap , FriendUnit , "|cff1eff00LeapLoseControl_MultiUnit_" },
		-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
		{ 528, (jps.LastCast ~= priest.Spell["DispelMagic"]) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00dispelOffensive_"..rangedTarget },
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelFriendlyTarget) == "string" , DispelFriendlyTarget , "|cff1eff00dispelFriendly_MultiUnit_" },
		{ 527, type(DispelTarget) == "string" , DispelTarget , "|cff1eff00dispelMagic_MultiUnit_" },
	}
	
	parseDamage = {
		-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
		{ 14914, canDPS(rangedTarget) , rangedTarget , "|cFFFF0000Flammes_"..rangedTarget },
		-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
		{ 129250, canDPS(rangedTarget) , rangedTarget, "|cFFFF0000Solace_"..rangedTarget },
		-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
		{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
		-- "Pénitence" 47540 
		{ 47540, jps.FaceTarget and canDPS(rangedTarget) , rangedTarget,"|cFFFF0000Penance_"..rangedTarget }, -- jps.glyphInfo(119866) and (Glyphe de Penance)
		-- "Mot de l'ombre: Douleur" 589 -- FARMING OR PVP -- NOT PVE -- Only if 1 enemy 
		{ 589, jps.FaceTarget and TargetCount == 1 and canDPS(rangedTarget) and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget , "|cFFFF0000Douleur_"..rangedTarget },
	}
		
	parseControl = {
		-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
		{ 6346, not jps.buff(6346,"player") , "player" },
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
		-- "Psyfiend" 108921 Démon psychique
		{ 108921, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	}

	parseEmergency = {
		-- "Shield" 17
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
		-- "Pénitence" 47540
		{ 47540, true , LowestImportantUnit , "Emergency_Penance_"..LowestImportantUnit },
		-- "Shield" 17 "Clairvoyance divine" 109175 gives buff "Divine Insight" 123266
		{ 17, not jps.buff(17,LowestImportantUnit) and jps.buffId(123266,LowestImportantUnit) , LowestImportantUnit , "Emergency_DivineShield_"..LowestImportantUnit  },
		-- "Soins rapides" 2061 -- "Sursis" 59889 "Borrowed"
		{ 2061, (LowestImportantUnitHpct < 0.35) and jps.buff(59889,"player") , LowestImportantUnit , "Emergency_SoinsRapides_Borrowed_"..LowestImportantUnit },
		-- "Soins supérieurs" 2060 "Focalisation intérieure" 96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
		{ 2060, jps.buffId(96267) and (jps.buffDuration(96267,"player") > 2.5) and (LowestImportantUnitHpct > 0.35), LowestImportantUnit , "Emergency_SoinsSup_Immune "..LowestImportantUnit },
		-- "Prière de guérison" 33076 -- buff 4P pvp aug. 50% soins -- "Holy Spark" 131567 "Etincelle sacrée"
		{ 33076, priest.unitForMending(LowestImportantUnit) and not jps.buff(131567,LowestImportantUnit) , LowestImportantUnit , "Emergency_Mending_"..LowestImportantUnit },
		-- "Soins de lien"
		{ 32546 , type(BindingHealTarget) == "string" , BindingHealTarget , "Emergency_Lien_" },
		-- "Soins rapides" 2061
		{ 2061, (LowestImportantUnitHpct < 0.35) , LowestImportantUnit , "Emergency_SoinsRapides_35%_"..LowestImportantUnit },
		-- "Don des naaru"
		{ 59544, select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil , LowestImportantUnit , "Emergency_Naaru_"..LowestImportantUnit },
		-- "Renew"
		{ 139, not jps.buff(139,LowestImportantUnit) , LowestImportantUnit , "Emergency_Renew_"..LowestImportantUnit },
		-- "Soins supérieurs" 2060 
		{ 2060, not playerAggro and (LowestImportantUnitHpct > 0.35) , LowestImportantUnit , "Emergency_SoinsSup_"..LowestImportantUnit },
		-- "Soins" in case low mana
		{ 2050, jps.mana("player") < 0.20 , LowestImportantUnit, "Emergency_Soins_"..LowestImportantUnit },
	}

	parsePOH = {
		-- "Divine Star" Holy 110744 Shadow 122121
		{ 110744, true , LowestImportantUnit , "POH_DivineStar_"..LowestImportantUnit },
		-- "Cascade" Holy 121135 Shadow 127632
		{ 121135, true , LowestImportantUnit , "POH_Cascade_"..LowestImportantUnit },
		{ 109964, jps.MultiTarget , POHTarget },
		{'nested' , jps.LastCast == priest.Spell["PrayerOfHealing"] , 
			{
				{ 33076, not jps.buffTracker(33076) , LowestImportantUnit , "POH_Tracker_Mending_"..LowestImportantUnit },
				{ 17, (type(ShieldTarget) == "string") , ShieldTarget , "POH_ShieldTarget" },
				{ 32546 , type(BindingHealTarget) == "string" , BindingHealTarget , "POH_Lien_MultiUnit_" },
			},
		},
		{ 596, jps.canHeal(POHTarget) , POHTarget , "POH_" },
	}

	parseMoving = {
		-- "Shield" 17
		{ 17, playerAggro and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Move_Shield_Player" },
		{ 17, playerAggro and not jps.buff(17,"player") and jps.buffId(123266,"player") , "player" , "Move_DivineShield_Player" },
		-- "Pénitence" 47540 
		{ 47540, jps.glyphInfo(119866) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit, "Move_Penance_"..LowestImportantUnit },
		-- "Clairvoyance divine" 109175 gives buff "Divine Insight" 123266
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) and LowestImportantUnitHpct < 0.55 , LowestImportantUnit , "Move_Shield_"..LowestImportantUnit },
		{ 17, not jps.buff(17,LowestImportantUnit) and jps.buffId(123266,LowestImportantUnit) and LowestImportantUnitHpct < 0.55 , LowestImportantUnit , "Move_DivineShield_"..LowestImportantUnit },
		-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
		{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
		{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
		-- "Don des naaru" 59544
		{ 59544, (select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "Move_Naaru_"..LowestImportantUnit },
		-- "Rénovation" 139 -- debuff "Ame affaiblie" 6788 -- "Prière de guérison" 33076  on CD
		{ 139, not jps.buff(139,LowestImportantUnit) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) and jps.debuff(6788,LowestImportantUnit) and (jps.cooldown(33076) > 0) , LowestImportantUnit , "Move_Renew_"..LowestImportantUnit },
		-- "Feu intérieur" 588 -- "Volonté intérieure" 73413
		{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player") , "player", "Move_InnerFire" },
		-- Damage
		{ "nested", jps.Interrupts , parseDispel },
		{ "nested", jps.PvP , parseDamage },
	}
	
	parseMana = {
		-- "Don des naaru" 59544
		{ 59544, (select(2,GetSpellBookItemInfo(priest.Spell["NaaruGift"]))~=nil) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "Mana_Naaru_"..LowestImportantUnit },
		-- "Rénovation" 139 -- debuff "Ame affaiblie" 6788 -- "Prière de guérison" 33076  on CD
		{ 139, not jps.buff(139,LowestImportantUnit) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) and jps.debuff(6788,LowestImportantUnit) and (jps.cooldown(33076) > 0) , LowestImportantUnit , "Mana_Renew_"..LowestImportantUnit },
		-- "Soins de lien" 32546 -- Glyph of Binding Heal 
		{ 32546 , playerAggro and type(BindingHealTarget) == "string" , BindingHealTarget , "Mana_Lien_MultiUnit_" },
		-- "Soins supérieurs" 2060
		{'nested' , not playerAggro and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal), -- priest.AvgAmountGreatHeal
			{
				{ 2060, jps.buff(59889,"player") , LowestImportantUnit, "Mana_SoinsSup_Borrowed_"..LowestImportantUnit  }, -- "Sursis" 59889 "Borrowed"
				{ 2060, jps.buffId(89485,"player") , LowestImportantUnit, "Mana_SoinsSup_Foca_"..LowestImportantUnit  }, -- "Focalisation intérieure" 89485
				{ 2060, true , LowestImportantUnit, "Mana_SoinsSup_"..LowestImportantUnit  },
			},
		},
		-- "Soins" 2050
		--{ 2050, LowestImportantUnitHealth > 0 , LowestImportantUnit , "Mana_Soins_"..LowestImportantUnit },
		-- Damage
		{ "nested", jps.Interrupts , parseDispel },
		{ "nested", jps.PvP , parseDamage },
		-- "Châtiment" 585
		{ 585, jps.FaceTarget and canDPS(rangedTarget) and jps.castEverySeconds(585,2) , rangedTarget , "|cFFFF0000Mana_Chatiment_"..rangedTarget },
	}

	parseShell = {
	--TANK not Buff Spirit Shell 114908
		{ 2061, jps.buff(114255) , LowestImportantUnit , "Carapace_SoinsRapides_Waves_"..LowestImportantUnit },
		{ 596, jps.MultiTarget and jps.canHeal(ShellTarget) , ShellTarget , "Carapace_Shell_Target_" },
		{ 596, (jps.LastCast~=priest.Spell["PrayerOfHealing"]) and jps.canHeal(ShellTarget) , ShellTarget , "Carapace_Shell_Target_" },
		{ 2061, jps.PvP and not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_NoBuff_SoinsRapides_"..LowestImportantUnit },
		{ 2060, not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit , "Carapace_NoBuff_SoinsSup_"..LowestImportantUnit },		
	--TANK Buff Spirit Shell 114908
		{ 2061, jps.PvP and jps.buffId(114908,LowestImportantUnit) and (UnitGetTotalAbsorbs(LowestImportantUnit) <= priest.AvgAmountFlashHeal) , LowestImportantUnit , "Carapace_Buff_SoinsRapides_"..LowestImportantUnit },
		{ 2060, jps.buffId(114908,LowestImportantUnit) and (UnitGetTotalAbsorbs(LowestImportantUnit) <= priest.AvgAmountFlashHeal) , LowestImportantUnit , "Carapace_Buff_SoinsSup_"..LowestImportantUnit },
		--{ 2050, jps.buffId(114908,LowestImportantUnit) and (UnitGetTotalAbsorbs(LowestImportantUnit) > priest.AvgAmountFlashHeal) , LowestImportantUnit , "Carapace_Buff_Soins_"..LowestImportantUnit },
	}
	
	parsePlayerShell = {
		-- "Soins rapides" 2061 "Borrowed" 59889 -- After casting Power Word: Shield reducing the cast time or channel time of your next Priest spell within 6 sec by 15%.
		{ 2061, jps.buff(59889,"player") , LowestImportantUnit ,"Def_Flash_"..LowestImportantUnit },
		-- "Pénitence" 47540 Weakened Soul 6788
		{ 47540, jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Def_Penance_"..LowestImportantUnit },
		-- "Clairvoyance divine" 109175 gives buff "Divine Insight" 123266 10 sec
		{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Def_Shield_"..LowestImportantUnit },
		{ 17, not jps.buff(17,LowestImportantUnit) and jps.buffId(123266,LowestImportantUnit) , LowestImportantUnit , "Def_DivineShield_" },
		-- "Soins rapides" 2061
		{ 2061, not jps.buffId(114908,LowestImportantUnit) , LowestImportantUnit ,"Def_Flash_"..LowestImportantUnit },
	}

------------------------
-- SPELL TABLE ---------
------------------------

-- CancelUnitBuff("player",priest.Spell["SpiritShell"])
		--{ {"macro","/cancelaura "..priest.Spell["SpiritShell"],"player"}, (LowestImportantUnitHpct < 0.55) and jps.buffId(109964) , "player" , "Macro_CancelAura_Carapace" }, 
-- SpellStopCasting()
		--{ {"macro","/stopcasting"},  spellstop == tostring(select(1,GetSpellInfo(2050))) and jps.CastTimeLeft("player") > 0.5 and (LowestImportantUnitHpct < 0.75) , "player" , "Macro_StopCasting" },

	spellTable = {
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and playerIsStun , "player" },
	-- playerAggro
	{ "nested", jps.hp("player") < 0.55 and playerAggro ,
		{
			-- "Suppression de la douleur" 33206 "Pain Suppression"
			{ 33206, playerIsStun , "player" , "Stun_Pain_Player" },
			-- "Pierre de soins" 5512
			{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" },
			-- "Prière du désespoir" 19236
			{ 19236, select(2,GetSpellBookItemInfo(priest.Spell["Desesperate"]))~=nil , "player" },
			-- "Oubli" 586 -- PVE 
			{ 586, not jps.PvP and UnitThreatSituation("player") == 3 , "player" },
			-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
			{ 586, IsSpellKnown(108942) , "player" , "Aggro_Oubli_" },
		},
	},

	-- "Divine Star" Holy 110744 Shadow 122121
	{ 110744, playerIsInterrupt > 0 , "player" , "Interrupt_DivineStar_" },
	-- "Void Shift" 108968
	{ 108968, UnitIsUnit(LowestImportantUnit,"player")~=1 and LowestImportantUnitHpct < 0.35 and jps.hp("player") > 0.85 and jps.UseCDs , LowestImportantUnit , "Emergency_VoidShift_"..LowestImportantUnit },	
	-- "Suppression de la douleur" 33206 "Pain Suppression"
	{ 33206, LowestImportantUnitHpct < 0.35 , LowestImportantUnit , "Emergency_Pain_"..LowestImportantUnit },
	-- "Power Word: Shield" 17 -- Ame affaiblie 6788 -- TIMER SHIELD
	{ 17, (type(ShieldTarget) == "string") , ShieldTarget , "Timer_ShieldTarget" },

	-- DAMAGE
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.75 ,
		{
			-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
			{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
			{ 32379, priest.canShadowWordDeath(rangedTarget) , rangedTarget , "|cFFFF0000Death_Health_"..rangedTarget },
			-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
			{ 14914, true , rangedTarget , "|cFFFF0000Flammes_"..rangedTarget },
			-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
			{ 129250, true , rangedTarget, "|cFFFF0000Solace_"..rangedTarget },
		},
	},

	-- "Inner Focus" 89485 "Focalisation intérieure" --  96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
	{ 89485, jps.Defensive and not jps.buffId(89485,"player") , "player" , "Def_Focus" },
	
	-- "Carapace" 109964 Player "Penance" 47540 cd == 0 to remove weakened soul with Divine Insight
	{ 109964, jps.Defensive and jps.buffId(89485,"player") , "player" },
	-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
	{ "nested", jps.Defensive and jps.buffId(109964) , parsePlayerShell },
	{ "nested", jps.buffId(109964) , parseShell },

	-- CONTROL -- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, type(FearEnemyTarget) == "string" , FearEnemyTarget , "Fear_MultiUnit_" },
	{ "nested", jps.PvP , parseControl },
	-- "Inner Focus" 89485 "Focalisation intérieure" --  96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
	{ 89485, playerAggro and not jps.buffId(89485,"player") , "player" , "Focus_Aggro" },
	
	-- "Soins rapides" 2061 "From Darkness, Comes Light" 109186 gives buff -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	{ 2061, jps.buff(114255) and (jps.buffDuration(priest.Spell.surgeOfLight) < 4) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	-- "Pénitence" 47540
	{ 47540, (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit },
	-- "Prière de guérison" 33076 -- "Priere de guerison" buff 4P pvp aug. 50% soins
	{ 33076, (type(MendingTarget) == "string") , MendingTarget , "MendingTarget" },
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 110744, CountInRange > 2 and jps.hp("player") < 0.55, LowestImportantUnit , "Health_DivineStar_"..LowestImportantUnit },
	-- "Cascade" 121135
	{ 121135, CountInRange > 2 and AvgHealthLoss < 0.95 , LowestImportantUnit ,  "Cascade_"..LowestImportantUnit },

	-- MOVING
	{ "nested", jps.Moving , parseMoving },

	-- "Soins rapides" 2061 -- "Focalisation intérieure" 89485 -- "Focalisation intérieure" 96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
	-- "Soins rapides" 2061 "Borrowed" 59889 -- After casting Power Word: Shield reducing the cast time or channel time of your next Priest spell within 6 sec by 15%.
	priest.tableForFlash(LowestImportantUnit),
	{ 2061, jps.roundValue(jps.cooldown(89485)) == 0 and jps.buffId(89485,"player") , LowestImportantUnit , "SoinsRapides_Focus_"..LowestImportantUnit },

	-- GROUP HEAL
	{ "nested", (type(POHTarget) == "string") , parsePOH },
	-- EMERGENCY HEAL
	{ "nested", LowestImportantUnitHpct < 0.55 , parseEmergency },

	-- "Prière de guérison" 33076 buff 4P pvp aug. 50% soins
	{ 33076, UnitAffectingCombat("player")==1 and not jps.buffTracker(33076) , LowestImportantUnit , "Tracker_Mending_"..LowestImportantUnit },
	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- "Inner Focus" 89485 "Focalisation intérieure" --  96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
	{ 89485, UnitAffectingCombat("player")==1 and not jps.buffId(89485,"player") , "player" , "Focus_Combat" },
	-- "Infusion de puissance" 10060 
	{ 10060, not jps.buffId(10060,"player") and UnitAffectingCombat("player") == 1, "player" , "Puissance_" },
	-- "Archange" 81700 -- "Evangélisme" 81661 buffStacks == 5
	{ 81700, (LowestImportantUnitHpct < 0.75) and (jps.buffStacks(81661) == 5) , "player", "ARCHANGE_" },
	-- PARSEMANA
	{ "nested", LowestImportantUnitHpct > 0.55 , parseMana },
	-- "Feu intérieur" 588 -- "Volonté intérieure" 73413
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player") }, -- "target" by default must must be a valid target
	}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","DISCIPLINE", priestDiscPvE, "Disc Priest PVE 5.4", true , false)

-- "Divine Insight" 109175 Penance, gives 100% chance your next Power Word: Shield will both ignore and not cause the Weakened Soul effect. Gives buff "Divine Insight" 123266
-- Divine Star belong to schools that are not used by any of the class's other spells. 
-- When these spells are instant cast, this means that it is not possible for that spell to be locked down.

-- Spirit Shell(SS) se cumule avec Divine Aegis(DA) Bouclier protecteur si soins critiques
-- sous SS Les soins critiques de Focalisation ne donnent plus DA pour Soins Rapides, Sup, POH. Seul Penance sous SS peut donner DA
-- SS Max Absorb = 60% UnitHealthMax("player")
-- SS is affected by Archangel
-- SS Scales with Grace

-- "Leap of Faith" -- "Saut de foi" 
-- "Mass Dispel"  -- Dissipation de masse 32375
-- "Psyfiend" -- "Démon psychique" 108921
-- "Archange" 81700
-- "Borrowed" "Sursis" 59889 
-- "Divine Aegis" "Egide divine" 47753 "
-- "Spirit Shell" -- Carapace spirituelle -- Pendant les prochaines 15 s, vos Soins, Soins rapides, Soins supérieurs, et Prière de soins ne soignent plus mais créent des boucliers d’absorption qui durent 15 s
-- "Holy Fire" -- Flammes sacrées
-- "Archangel" -- Archange -- Consomme votre Evangelisme, ce qui augmente les soins que vous prodiguez de 5% par charge d'Evangelisme consommée pendant 18 s.
-- "Evangelism" -- Evangélisme -- dégâts directs avec Flammes sacrées ou Fouet mental, vous bénéficiez d'Evangélisme. Cumulable jusqu'à 5 fois. Dure 20 s
-- "Atonement" -- Expiation -- dmg avec Châtiment, Flammes sacrées ou Pénitence, vous rendez instantanément à un membre du groupe ou du raid proche qui a peu de points de vie et qui se trouve à moins de 15 mètres de la cible ennemie un montant de points de vie égal à 100% des dégâts infligés.
-- "Borrowed Time" -- Sursis -- Votre prochain sort bénéficie d'un bonus de 15% à la hâte des sorts quand vous lancez Mot de pouvoir : Bouclier. Dure 6 s.
-- "Divine Hymn" -- Hymne divin
-- "Dispel Magic" -- Purifier
-- "Inner Fire" -- Feu intérieur
-- "Serendipity" -- Heureux hasard -- vous soignez avec Soins de lien ou Soins rapides, le temps d'incantation de votre prochain sort Soins supérieurs ou Prière de soins est réduit de 20% et son coût en mana de 10%.
-- "Power Word: Fortitude" -- Mot de pouvoir : Robustesse
-- "Fear Ward" -- Gardien de peur
-- "Chakra: Serenity" -- Chakra : Sérénité
-- "Chakra" -- Chakra
-- "Heal" -- Soins
-- "Flash Heal" -- Soins rapides
-- "Binding Heal" -- Soins de lien
-- "Greater Heal" -- Soins supérieurs
-- "Renew" -- Rénovation
-- "Circle of Healing" -- Cercle de soins
-- "Prayer of Healing" -- Prière de soins
-- "Prayer of Mending" -- Prière de guérison
-- "Guardian Spirit" -- Esprit gardien
-- "Cure Disease" -- Purifier
-- "Desperate Prayer" -- Prière du désespoir
-- "Surge of light" -- Vague de Lumière
-- "Holy Word: Serenity" -- Mot sacré : Sérénité SpellID 88684
-- "Power Word: Shield" -- Mot de pouvoir : Bouclier 
-- "Weakened Soul" -- "Ame affaiblie"

-------------------------
-- ROTATION STATIC
-------------------------