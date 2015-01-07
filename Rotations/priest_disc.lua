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
	
	local timerShield = jps.checkTimer("ShieldTimer")
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
	
	local LeapFriend = nil
	for _,unit in ipairs(FriendUnit) do
		if priest.unitForLeap(unit) and jps.FriendAggro(unit) and jps.LoseControl(unit) then 
			LeapFriend = unit
		break end
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

	local FearEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canFear(unit) and not jps.LoseControl(unit) then
			FearEnemyTarget = unit
		break end
	end

	local DeathEnemyTarget = nil
	for _,unit in ipairs(EnemyUnit) do 
		if priest.canShadowWordDeath(unit) then 
			DeathEnemyTarget = unit
		break end
	end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- STOPCASTING
----------------------------------------------------------

local InterruptTable = {
	{priest.Spell.flashHeal, 0.75, jps.buffId(priest.Spell.spiritShellBuild) or jps.buffId(priest.Spell.innerFocus) },
	{priest.Spell.greaterHeal, 0.90, jps.buffId(priest.Spell.spiritShellBuild) },
	{priest.Spell.prayerOfHealing, 0.85, jps.buffId(priest.Spell.spiritShellBuild) or jps.buffId(priest.Spell.innerFocus) or jps.MultiTarget}
}

-- Avoid interrupt Channeling
	if jps.ChannelTimeLeft() > 0 then return nil end
-- Avoid Overhealing
	priest.ShouldInterruptCasting( InterruptTable , AvgHealthLoss ,  CountInRange )

------------------------
-- LOCAL TABLES
------------------------

	parseMoving = {
		-- "Shield" 17 Player
		{ 17, playerAggro and not jps.buff(17,"player") and not jps.debuff(6788,"player") , "player" , "Move_Shield_Player" },
		{ 17, playerAggro and not jps.buff(17,"player") and jps.buffId(123266,"player") , "player" , "Move_DivineShield_Player" },
		-- "Pénitence" 47540 -- jps.glyphInfo(119866)
		{ 47540, LowestImportantUnitHealth > priest.AvgAmountGreatHeal , LowestImportantUnit, "Move_Penance_"..LowestImportantUnit },
		-- "Prière de guérison" 33076 -- buff 4P pvp aug. 50% soins -- "Holy Spark" 131567 "Etincelle sacrée"
		{ 33076, (type(MendingTarget) == "string") , MendingTarget , "Move_MendingTarget" },
		-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
		{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
		{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
		-- "Don des naaru" 59544
		{ 59544, jps.IsSpellKnown(59544) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "Move_Naaru_"..LowestImportantUnit },
	}

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
		-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
		{ 8122, priest.canFear(rangedTarget) , rangedTarget },
		-- "Psyfiend" 108921 Démon psychique
		{ 108921, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
		-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
		{ 108920, playerAggro and priest.canFear(rangedTarget) , rangedTarget },
	}
	
	parseDispel = {
		-- "Leap of Faith" 73325 -- "Saut de foi"
		{ 73325 , type(LeapFriend) == "string" , LeapFriend , "|cff1eff00Leap_MultiUnit_" },
		-- "Dispel" "Purifier" 527
		{ 527, type(DispelTargetRole) == "string" , DispelTargetRole , "|cff1eff00DispelTargetRole_MultiUnit_" },
		{ 527, type(DispelFriendlyTarget) == "string" , DispelFriendlyTarget , "|cff1eff00DispelFriendlyTarget_MultiUnit_" },
		{ 527, jps.Interrupts and type(DispelTarget) == "string" , DispelTarget , "|cff1eff00DispelTarget_MultiUnit_" },
	}

------------------------
-- SPELL TABLE ---------
------------------------

	spellTable = {
		
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.useTrinketBool(1) and playerIsStun , "player" },
	-- "Soins rapides" 2061 -- "Vague de Lumière" 114255 "Surge of Light"
	{ 2061, jps.buff(114255) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	{ 2061, jps.buff(114255) and (jps.buffDuration(114255) < 4) , LowestImportantUnit , "SoinsRapides_Light_"..LowestImportantUnit },
	-- "Suppression de la douleur" 33206 "Pain Suppression"
	{ 33206, LowestImportantUnitHpct < 0.40 , LowestImportantUnit , "Emergency_Pain_"..LowestImportantUnit },

	{ "nested", jps.hp("player") < 0.75 ,
		{
			-- "Pierre de soins" 5512
			{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512)) == true and jps.itemCooldown(5512)==0 , "player" , "PIERRESOINS"},
			-- "Prière du désespoir" 19236
			{ 19236, jps.IsSpellKnown(19236) , "player" , "DESESPERATE" },
			-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
			-- "Oubli" 586 -- Glyphe d'oubli 55684 -- Votre technique Oubli réduit à présent tous les dégâts subis de 10%.
			{ 586, playerAggro and jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli_" },
			{ 586, playerAggro and jps.glyphInfo(55684) , "player" , "Aggro_Oubli_" },
			-- "Divine Star" Holy 110744 Shadow 122121
			{ 110744, playerIsInterrupt , "player" , "Interrupt_DivineStar_" },
			-- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
			{ 527, playerAggro and jps.canDispel("player",{"Magic"}) and jps.glyphInfo(55677) , "player" , "Aggro_Dispell_Player" },
		},
	},

	-- CONTROL -- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ "nested", not jps.LoseControl(rangedTarget) and canDPS(rangedTarget) , parseControl },

	-- "Pénitence" 47540
	{ 47540, LowestImportantUnitHealth > priest.AvgAmountGreatHeal , "Penance_"..LowestImportantUnit },	
	-- "Power Word: Shield" 17 -- TIMER SHIELD
	{ 17, (type(ShieldTarget) == "string") , ShieldTarget , "Timer_ShieldTarget" },
	-- "Prière de guérison" 33076 -- TIMER POM
	{ 33076, UnitAffectingCombat("player") == true and not jps.buffTracker(33076) , LowestImportantUnit , "Tracker_Mending_"..LowestImportantUnit },
	
	-- "Inner Focus" 89485 "Focalisation intérieure" --  96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
	{ 89485, playerAggro and not jps.buffId(89485,"player") and (LowestImportantUnitHpct > 0.40) , "player" , "Focus_Aggro" },
	{ 89485, jps.Defensive and not jps.buffId(89485,"player") and (LowestImportantUnitHpct > 0.40) , "player" , "Focus_Defensive" },
	
	-- "Inner Focus" 89485 "Focalisation intérieure"
	{ "nested", not jps.Moving and jps.buffId(89485,"player") ,
		{
			-- "Soins rapides" 2061 "Focalisation intérieure" 96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
			{ 2061, playerHasImmune and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "SoinsRapides_Immune "..LowestImportantUnit },
			-- "Soins rapides" 2061
			{ 2061, jps.roundValue(jps.cooldown(89485)) == 0 and jps.FriendAggro(LowestImportantUnit) , LowestImportantUnit , "SoinsRapides_Focus_"..LowestImportantUnit },
			{ 2061, jps.roundValue(jps.cooldown(89485)) == 0 and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "SoinsRapides_Focus_"..LowestImportantUnit },
		},
	},

	-- GROUP HEAL
	{ "nested", (type(POHTarget) == "string") and jps.MultiTarget ,
		{
			-- "Cascade" Holy 121135 Shadow 127632
			{ 121135, CountInRange > 2 and AvgHealthLoss < 0.95 , LowestImportantUnit ,  "Cascade_POH_"..LowestImportantUnit },
			-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
			{ 109964, true , POHTarget , "Carapace_POH_" },
			{ 596, jps.canHeal(POHTarget) , POHTarget , "POH_" },
		},
	},

	-- "Carapace" 109964 Player -- WARNING if jps.Defensive LowestImportantUnit = { "player","focus","target","targettarget","mouseover" }
	{ 109964, jps.Defensive , "player" },
	-- "Carapace spirituelle" spell & buff "player" 109964 buff target 114908
	{ "nested", jps.buffId(109964) , parseShell },

	-- EMERGENCY HEAL
	{ "nested", LowestImportantUnitHpct < 0.75 ,
		{
			-- "Shield" 17 "Clairvoyance divine" 109175 gives buff "Divine Insight" 123266 gives buff "Shield" 123258
			{ 17, not jps.buff(17,LowestImportantUnit) and not jps.debuff(6788,LowestImportantUnit) , LowestImportantUnit , "Emergency_Shield_"..LowestImportantUnit },
			{ 17, not jps.buff(17,LowestImportantUnit) and jps.buffId(123266,"player") , LowestImportantUnit , "Emergency_DivineShield_"..LowestImportantUnit  },
			-- "Pénitence" 47540
			{ 47540, true , LowestImportantUnit , "Emergency_Penance_"..LowestImportantUnit },
			-- "Prière de guérison" 33076 -- buff 4P pvp aug. 50% soins -- "Holy Spark" 131567 "Etincelle sacrée"
			{ 33076, (type(MendingTarget) == "string") , MendingTarget , "Emergency_MendingTarget" },
			-- "Soins rapides" 2061
			{ 2061, not jps.Moving and (LowestImportantUnitHpct < 0.40) , LowestImportantUnit , "Emergency_SoinsRapides_40%_"..LowestImportantUnit },
			-- Dispell -- "Glyph of Purify" 55677 Your Purify spell also heals your target for 5% of maximum health
			{ 527, jps.canDispel(LowestImportantUnit,{"Magic"}) and jps.glyphInfo(55677) , LowestImportantUnit , "Emergency_Dispell"..LowestImportantUnit },
			-- "Don des naaru" 59544
			{ 59544, jps.IsSpellKnown(59544) , LowestImportantUnit , "Emergency_Naaru_"..LowestImportantUnit },
		},
	},

	-- DISPEL	
	{ "nested", true , parseDispel },
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, jps.castEverySeconds(528,10) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00DispelOffensive_"..rangedTarget },

	-- DAMAGE
	-- "Flammes sacrées" 14914  -- "Evangélisme" 81661
	{ 14914, canDPS(rangedTarget) and (LowestImportantUnitHpct > 0.40) , rangedTarget , "|cFFFF0000Flammes_"..rangedTarget },
	-- "Mot de pouvoir : Réconfort" -- "Power Word: Solace" 129250 -- REGEN MANA
	{ 129250, canDPS(rangedTarget) and (LowestImportantUnitHpct > 0.40) , rangedTarget, "|cFFFF0000Solace_"..rangedTarget },

	-- MOVING
	{ "nested", jps.Moving , parseMoving },

	-- DAMAGE
	-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
	{ 32379, priest.canShadowWordDeath(rangedTarget) , rangedTarget , "|cFFFF0000Death_Health_"..rangedTarget },
	{ "nested", jps.FaceTarget and canDPS(rangedTarget) and LowestImportantUnitHpct > 0.85 ,
		{
			-- "Mot de l'ombre : Mort" 32379 -- FARMING OR PVP -- NOT PVE
			{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "|cFFFF0000Death_MultiUnit_" },
			-- "Pénitence" 47540 
			{ 47540, true , rangedTarget,"|cFFFF0000Penance_"..rangedTarget }, -- jps.glyphInfo(119866) and (Glyphe de Penance)
			-- "Mot de l'ombre: Douleur" 589 -- FARMING OR PVP -- NOT PVE -- Only if 1 targeted enemy 
			{ 589, TargetCount == 1 and jps.myDebuffDuration(589,rangedTarget) == 0 , rangedTarget , "|cFFFF0000Douleur_"..rangedTarget },
			-- "Châtiment" 585
			{ 585, CountInRange > 0 and jps.castEverySeconds(585,2.5) , rangedTarget , "|cFFFF0000Chatiment_"..rangedTarget },
		},
	},
	
	-- "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, jps.mana("player") < 0.75 and priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- "Infusion de puissance" 10060 
	{ 10060, not jps.buffId(10060,"player") and UnitAffectingCombat("player") == true , "player" , "POWERINFUSION_" },
	-- "Archange" 81700 -- "Evangélisme" 81661 buffStacks == 5
	{ 81700, (LowestImportantUnitHpct < 0.85) and (jps.buffStacks(81661) == 5) , "player", "ARCHANGE_" },
	-- "Don des naaru" 59544
	{ 59544, jps.IsSpellKnown(59544) and (LowestImportantUnitHealth > priest.AvgAmountFlashHeal) , LowestImportantUnit , "Naaru_"..LowestImportantUnit },
	-- "Soins supérieurs" 2060
	{ 2060, not playerAggro and (LowestImportantUnitHealth > priest.AvgAmountGreatHeal) , LowestImportantUnit , "SoinsSup_"..LowestImportantUnit  },
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },

}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end

jps.registerRotation("PRIEST","DISCIPLINE", priestDisc , "Disc Priest Default" )
