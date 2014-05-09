local L = MyLocalizationTable
local canDPS = jps.canDPS

jps.registerRotation("PRIEST","SHADOW",function()

local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.90)
local playerhealth =  jps.hp("player","abs") -- UnitHealthMax("player") - UnitHealth("player")
local playerhealthpct = jps.hp("player")
	
----------------------
-- HELPER
----------------------
	
local NaaruGift = tostring(select(1,GetSpellInfo(59544))) -- NaaruGift 59544
local Desesperate = tostring(select(1,GetSpellInfo(19236))) -- "Prière du désespoir" 19236
local MindBlast = tostring(select(1,GetSpellInfo(8092))) -- "Mind Blast" 8092
local painDuration = jps.myDebuffDuration(589)
local plagueDuration = jps.myDebuffDuration(2944)
local vtDuration = jps.myDebuffDuration(34914)
local Orbs = UnitPower("player",13)
local VampTouch = tostring(select(1,GetSpellInfo(34914)))
local ShadowPain = tostring(select(1,GetSpellInfo(589)))
	
---------------------
-- TIMER
---------------------

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents() --- return true/false ONLY FOR PLAYER
local playerControlled = jps.LoseControl("player",{"CC"})

----------------------
-- TARGET ENEMY
----------------------

local rangedTarget,EnemyUnit = jps.LowestTarget()
if canDPS("target") then rangedTarget = "target" end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

------------------------
-- LOCAL FUNCTIONS
------------------------

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

local SilenceEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if jps.IsCasting(unit) and not jps.LoseControl(rangedTarget,{"Silence" }) then 
		SilenceEnemyTarget = unit
	break end
end

local PainEnemyTarget = nil
for _,unit in ipairs(EnemyUnit) do 
	if not jps.myDebuff(589,unit) then 
		PainEnemyTarget = unit
	break end
end

local swapFriend = nil
for _,unit in ipairs(FriendUnit) do 
	if jps.hp(unit) > 0.90 and not jps.FriendAggro(unit) and UnitIsUnit(unit,"player")~=1 then 
		swapFriend = unit
	break end
end

-- if jps.debuffDuration(114404,"target") > 18 and jps.UnitExists("target") then MoveBackwardStart() end
-- if jps.debuffDuration(114404,"target") < 18 and jps.debuff(114404,"target") and jps.UnitExists("target") then MoveBackwardStop() end

----------------------------------------------------------
-- TRINKETS -- OPENING -- CANCELAURA -- SPELLSTOPCASTING
----------------------------------------------------------

if jps.buff(47585,"player") then return end -- "Dispersion" 47585
	
--	SpellStopCasting() -- "Mind Flay" 15407 -- "Mind Blast" 8092 -- buff 81292 "Glyph of Mind Spike"
local canCastMindBlast = false
local spellstop = select(1,UnitChannelInfo("player")) -- it's a channeling spell so jps.CastTimeLeft("player") can't work (work only for UnitCastingInfo -- insead use 
if spellstop == tostring(select(1,GetSpellInfo(15407))) then
	-- "Mind Blast" 8092 Stack shadow orbs -- buff 81292 "Glyph of Mind Spike"
	if (jps.cooldown(8092) == 0) and jps.buff(81292,"player") then 
		canCastMindBlast = true
	-- "Divine Insight" proc "Mind Blast" 8092 -- "Divine Insight" Clairvoyance divine 109175
	elseif (jps.cooldown(8092) == 0) and jps.buff(109175) then
		canCastMindBlast = true
	-- "Mind Blast" 8092
	elseif (jps.cooldown(8092) == 0) and (Orbs < 3) then 
		canCastMindBlast = true
	end
end

if canCastMindBlast then
	SpellStopCasting()
	spell = 8092;
	target = rangedTarget;
return end

-------------------------------------------------------------
------------------------ TABLES------------------------
-------------------------------------------------------------

local LowHealthEnemy = {
	-- "Shadow Word: Death " 32379
	{ 32379, jps.hp(rangedTarget) < 0.20 , rangedTarget , "Death" },
	-- "Devouring Plague" 2944	
	{ 2944, (Orbs > 0) , rangedTarget },
	-- "Mind Blast" 8092
	{ 8092, (jps.buffStacks(81292) == 2) , rangedTarget , "Blast" },
	-- "Mind Spike" 73510
	{ 73510, (jps.buffStacks(81292) < 2) , rangedTarget , "Spike" },
	-- "Mind Blast" 8092
	{ 8092, true , rangedTarget , "Blast" },
}

local parseMultitarget = {
	-- "Cascade" Holy 121135 Shadow 127632
	{ 127632, true , rangedTarget , "Cascade_"  },
	-- "Oubli" 586 PVE 
	{ 586, not jps.PvP and UnitThreatSituation("player")==3 , "player" },
	-- "Shadow Word: Pain" 589
	{ 589, type(PainEnemyTarget) == "string" , PainEnemyTarget , "Pain_MultiUnit_" },
	-- "Mind Sear" 48045
	{ 48045, true , rangedTarget  },
}

local parseControl = {
	-- "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, not jps.buff(6346,"player") , "player" },
	-- "Psychic Scream" "Cri psychique" 8122 -- FARMING OR PVP -- NOT PVE -- debuff same ID 8122
	{ 8122, priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	{ 8122, type(FearEnemyTarget) == "string" , FearEnemyTarget , "Fear_MultiUnit_" },
	-- "Psyfiend" 108921 Démon psychique
	{ 108921, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Void Tendrils" 108920 -- debuff "Void Tendril's Grasp" 114404
	{ 108920, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) , rangedTarget },
	-- "Psychic Horror" 64044 "Horreur psychique"
	{ 64044, playerAggro and priest.canFear(rangedTarget) and not jps.LoseControl(rangedTarget) and (Orbs < 3) , rangedTarget , "Psychic Horror_"..rangedTarget },
	-- "Silence" 15487
	{ 15487, jps.IsCasting(rangedTarget) and not jps.LoseControl(rangedTarget,{"Silence" }) , rangedTarget , "Silence_"..rangedTarget },
	{ 15487, type(SilenceEnemyTarget) == "string" , SilenceEnemyTarget , "Silence_MultiUnit" },
}

local parseDispel = {
	-- OFFENSIVE Dispel -- "Dissipation de la magie" 528
	{ 528, (jps.LastCast ~= priest.Spell["DispelMagic"]) and jps.DispelOffensive(rangedTarget) , rangedTarget , "|cff1eff00dispelOffensive_"..rangedTarget },
	-- "Leap of Faith" 73325 -- "Saut de foi"
	-- "Dispel" "Purifier" 527 -- UNAVAILABLE IN SHADOW FORM 15473
}

local parseAggro = {
	-- "Pierre de soins" 5512
	{ {"macro","/use item:5512"}, select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" },
	-- "Prière du désespoir" 19236
	{ 19236, select(2,GetSpellBookItemInfo(Desesperate))~=nil , "player" },
	-- "Oubli" 586 -- PVE 
	{ 586, not jps.PvP and UnitThreatSituation("player") == 3 , "player" },
	-- "Oubli" 586 -- Fantasme 108942 -- vous dissipez tous les effets affectant le déplacement sur vous-même et votre vitesse de déplacement ne peut être réduite pendant 5 s
	{ 586, playerAggro and jps.IsSpellKnown(108942) , "player" , "Aggro_Oubli" },
	-- "Dispersion" 47585
	{ 47585, playerAggro and (playerhealthpct < 0.35) , "player" , "Aggro_Dispersion_" },
	-- "Void Shift" 108968
	--{ 108968,  type(swapFriend) == "string" and jps.hp("player") < 0.35 and jps.UseCDs , swapFriend , "Emergency_VoidShift_" },
}
		
local parseMoving = 
{
	-- "Mind Blast" 8092 Stack shadow orbs -- buff 81292 "Glyph of Mind Spike"
	{ 8092, (jps.buffStacks(81292) == 2) , rangedTarget , "Blast" },
	-- "Shadow Word: Pain" 589 Keep SW:P up with duration
	{ 589, jps.myDebuff(589,rangedTarget) and painDuration < 2.5 and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget },
	-- "Shadow Word: Pain" 589 Keep up
	{ 589, (not jps.myDebuff(589,rangedTarget)) and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget },
	-- "Shadow Word: Pain" 589
	{ 589, type(PainEnemyTarget) == "string" , PainEnemyTarget , "Pain_MultiUnit_" },
}

local spellTable = {

	-- "Shadowform" 15473
	{ 15473, not jps.buff(15473) , "player" },
	-- TRINKETS -- jps.useTrinket(0) est "Trinket0Slot" est slotId  13 -- "jps.useTrinket(1) est "Trinket1Slot" est slotId  14
	{ jps.useTrinket(1), jps.UseCDs and jps.useTrinketBool(1) and playerIsStun , "player" },
	-- "Dispersion" 47585
	{ 47585, (UnitPower ("player",0)/UnitPowerMax ("player",0) < 0.50) and jps.myDebuff(589,rangedTarget) and jps.myDebuff(34914,rangedTarget) , "player" , "Dispersion_Mana" },
	{ "nested", jps.hp("player") < 0.55 , parseAggro },
	{ "nested", jps.PvP , parseControl },
	{ "nested", jps.Interrupts , parseDispel },
	
	-- "Divine Insight" proc "Mind Blast" 8092 
	{ 8092, jps.buff(109175) , rangedTarget }, -- "Divine Insight" Clairvoyance divine 109175
	-- "Mind Spike" 73510 proc -- "From Darkness, Comes Light" 109186 gives buff -- "Surge of Darkness" 87160
	{ 73510, jps.buff(87160) , rangedTarget }, -- buff 87160 "Surge of Darkness"
	-- "Devouring Plague" 2944 plague when we have 3 orbs 	
	{ 2944, Orbs == 3  , rangedTarget },
	-- "Shadow Word: Death " "Mot de l'ombre : Mort" 32379
	{ 32379, (UnitHealth(rangedTarget)/UnitHealthMax(rangedTarget) < 0.20) , rangedTarget, "castDeath_"..rangedTarget },
	{ 32379, type(DeathEnemyTarget) == "string" , DeathEnemyTarget , "Death_MultiUnit_" },
	
	-- MOVING
	{ 15473, jps.Moving , parseMoving },
	
	-- "Mindbender" "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	
	-- MULTITARGET
	{ "nested", jps.MultiTarget , parseMultitarget },
	
	-- HEAL
	-- "Vampiric Embrace" 15286
	{ 15286, playerhealthpct < 0.75 , "player" },
	-- "Power Word: Shield" 17	
	{ 17, (playerhealthpct < 0.75) and not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" }, -- Shield
	-- "Renew" 139 Self heal when critical 
	{ 139, (playerhealthpct < 0.75) and not jps.buff(139,"player"), "player" },
	-- "Prayer of Mending" "Prière de guérison" 33076 
	{ 33076, (playerhealthpct < 0.75) and not jps.buff(33076,"player") , "player" },

	-- "Mind Blast" 8092 Stack shadow orbs -- buff 81292 "Glyph of Mind Spike"
	{ 8092, true , rangedTarget },
	-- "Mind Flay" 15407
	{ 15407, jps.debuff(2944,rangedTarget) , rangedTarget , "MINDFLAYORBS" },
	-- "Vampiric Touch" 34914 Keep VT up with duration
	{ 34914, jps.myDebuff(34914,rangedTarget) and vtDuration < 2.5 and (jps.CurrentCast ~= VampTouch or jps.LastCast ~= VampTouch) , rangedTarget },
	-- "Shadow Word: Pain" 589 Keep SW:P up with duration
	{ 589, jps.myDebuff(589,rangedTarget) and painDuration < 2.5 and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget },

	-- "Power Infusion" "Infusion de puissance" 10060
	{ 10060, UnitAffectingCombat("player")==1 and (UnitPower ("player",0)/UnitPowerMax ("player",0) > 0.20) , "player" },

	-- "Shadow Word: Pain" 589
	{ 589, not jps.myDebuff(589,rangedTarget) and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget },
	-- "Vampiric Touch" 34914 
	{ 34914, not jps.myDebuff(34914,rangedTarget) and (jps.CurrentCast ~= VampTouch or jps.LastCast ~= VampTouch) , rangedTarget },
	-- "Shadow Word: Pain" 589
	{ 589, type(PainEnemyTarget) == "string" , PainEnemyTarget , "Pain_MultiUnit_" },

	-- "Divine Star" Holy 110744 Shadow 122121
	{ 122121, true , rangedTarget , "DivineStar_" },
	-- "Cascade" Holy 121135 Shadow 127632
	{ 127632, true , rangedTarget , "Cascade_"  },

	-- "Inner Fire" 588 Keep Inner Fire up 
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
	-- "Mind Flay" 15407
	{ 15407, true , rangedTarget },
}

	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Shadow Priest PvE", true, false)

-------------------------------
-- ROTATION 2
-------------------------------

jps.registerRotation("PRIEST","SHADOW",function()

	local playerhealth =  jps.hp("player","abs") -- UnitHealthMax("player") - UnitHealth("player")
	local playerhealthpct = jps.hp("player")

	local myTarget = jps.LowestTarget()
	local rangedTarget = "target"
	if jps.canDPS("target") then
	rangedTarget = "target"
	elseif jps.canDPS("focustarget") then
	rangedTarget = "focustarget"
	elseif jps.canDPS("targettarget") then
	rangedTarget = "targettarget"
	elseif jps.canDPS(myTarget) then
	rangedTarget = myTarget
	end
	
	local isBoss = (UnitLevel(rangedTarget) == -1) or (UnitClassification(rangedTarget) == "elite")
	local isEnemy = jps.canDPS(rangedTarget) and (jps.TimeToDie(rangedTarget) > 12)
	local canCastShadowfiend = isEnemy  or isBoss
	
	local NaaruGift = tostring(select(1,GetSpellInfo(59544))) -- NaaruGift 59544
	local Desesperate = tostring(select(1,GetSpellInfo(19236))) -- "Prière du désespoir" 19236
	local MindBlast = tostring(select(1,GetSpellInfo(8092))) -- "Mind Blast" 8092
	local painDuration = jps.myDebuffDuration(589)
	local plagueDuration = jps.myDebuffDuration(2944)
	local vtDuration = jps.myDebuffDuration(34914)
	local Orbs = UnitPower("player",13)
	local VampTouch = tostring(select(1,GetSpellInfo(34914)))
	local ShadowPain = tostring(select(1,GetSpellInfo(589)))
	
	local playerAggro =  jps.FriendAggro("player")
	local playerIsStun = jps.StunEvents() --- return true/false ONLY FOR PLAYER
	local playerControlled = jps.LoseControl("player",{"CC"})

	if jps.buff(47585,"player") then return end -- "Dispersion" 47585
		
	--	SpellStopCasting() -- "Mind Flay" 15407 -- "Mind Blast" 8092 -- buff 81292 "Glyph of Mind Spike"
	local canCastMindBlast = false
	local spellstop = select(1,UnitChannelInfo("player"))
	if spellstop == tostring(select(1,GetSpellInfo(15407))) then
		-- "Mind Blast" 8092 Stack shadow orbs -- buff 81292 "Glyph of Mind Spike"
		if (jps.cooldown(8092) == 0) and jps.buff(81292,"player") then 
			canCastMindBlast = true
		-- "Divine Insight" proc "Mind Blast" 8092 -- "Divine Insight" Clairvoyance divine 109175
		elseif (jps.cooldown(8092) == 0) and jps.buff(109175) then
			canCastMindBlast = true
		-- "Mind Blast" 8092
		elseif (jps.cooldown(8092) == 0) and (Orbs < 3) then 
			canCastMindBlast = true
		end
	end


	if canCastMindBlast then
		SpellStopCasting()
		spell = 8092;
		target = rangedTarget;
	return end	
	
local spellTable = {

	-- "Shadowform" 15473
	{ 15473, not jps.buff(15473) , "player" },
	-- "Divine Insight" proc "Mind Blast" 8092
	{ 8092, jps.buff(109175) , rangedTarget }, -- "Divine Insight" Clairvoyance divine 109175
	-- "Mind Spike" 73510 proc -- "From Darkness, Comes Light" 109186 gives buff -- "Surge of Darkness" 87160
	{ 73510, jps.buff(87160) , rangedTarget }, -- buff 87160 "Surge of Darkness"
	-- "Devouring Plague" 2944 plague when we have 3 orbs 	
	{ 2944, Orbs == 3 and vtDuration > 5 and painDuration > 5 , rangedTarget },
	-- "Shadow Word: Death" "Mot de l'ombre : Mort" 32379
	{ 32379, jps.canDPS(rangedTarget) and (UnitHealth(rangedTarget)/UnitHealthMax(rangedTarget) < 0.20) , rangedTarget, "|cFFFF0000castDeath_"..rangedTarget },
	-- "Vampiric Touch" 34914 Keep VT up with duration
	{ 34914, jps.myDebuff(34914,rangedTarget) and vtDuration < 2.5 and (jps.CurrentCast ~= VampTouch or jps.LastCast ~= VampTouch) , rangedTarget },
	-- "Shadow Word: Pain" 589 Keep SW:P up with duration
	{ 589, jps.myDebuff(589,rangedTarget) and painDuration < 2.5 and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget },
	-- "Mind Flay" 15407
	{ 15407, jps.debuff(2944,rangedTarget) , rangedTarget , "MINDFLAYORBS" },
	-- "Power Infusion" "Infusion de puissance" 10060
	{ 10060, UnitAffectingCombat("player")==1 and (UnitPower ("player",0)/UnitPowerMax ("player",0) > 0.20) , "player" },
	-- "Mind Blast" 8092 Stack shadow orbs -- buff 81292 "Glyph of Mind Spike"
	{ 8092, true , rangedTarget },
	-- "Shadow Word: Pain" 589
	{ 589, not jps.myDebuff(589,rangedTarget) and (jps.CurrentCast ~= ShadowPain or jps.LastCast ~= ShadowPain) , rangedTarget },
	-- "Vampiric Touch" 34914 
	{ 34914, not jps.myDebuff(34914,rangedTarget) and (jps.CurrentCast ~= VampTouch or jps.LastCast ~= VampTouch) , rangedTarget },
	-- "Mindbender" "Torve-esprit" 123040 -- "Ombrefiel" 34433 "Shadowfiend"
	{ 34433, priest.canShadowfiend(rangedTarget) , rangedTarget },
	{ 123040, priest.canShadowfiend(rangedTarget) , rangedTarget },
	-- "Divine Star" Holy 110744 Shadow 122121
	{ 122121, true , rangedTarget , "DivineStar_" },

-- HEAL	
	-- "Power Word: Shield" 17	
	{ 17, (playerhealthpct < 0.75) and not jps.debuff(6788,"player") and not jps.buff(17,"player") , "player" }, -- Shield
	-- "Vampiric Embrace" 15286
	{ 15286, playerhealthpct < 0.75 , "player" },
	-- "Prière du désespoir" 19236
	{ 19236, UnitAffectingCombat("player")==1 and select(2,GetSpellBookItemInfo(Desesperate))~=nil and (playerhealthpct < 0.50) , "player" },
	-- "Inner Fire" 588 Keep Inner Fire up 
	{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player"), "player" }, -- "Volonté intérieure" 73413
	-- "Fear Ward" "Gardien de peur" 6346 -- FARMING OR PVP -- NOT PVE
	{ 6346, jps.PvP and not jps.buff(6346,"player") , "player" },
	-- "Prayer of Mending" "Prière de guérison" 33076 
	{ 33076, (playerhealthpct < 0.75) and not jps.buff(33076,"player") , "player" },
	-- "Renew" 139 Self heal when critical 
	{ 139, (playerhealthpct < 0.75) and not jps.buff(139,"player"), "player" },
	-- "Don des naaru" 59544 -- YOU CAN'T DO IT YOU ARE IN SHAPESHIFT FORM
	-- "Mind Flay" 15407
	{ 15407, true , rangedTarget },

}

	local spell = nil
	local target = nil
	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Shadow Priest PvE OnlyDMG", true, false)

-- Vampiric Embrace -- 3-minute cooldown with a 15-second duration. It causes all the single-target damage you deal to heal nearby allies for 50% of the damage
-- Void Shift  -- allows you to swap health percentages with your target raid or party member. It can be used to save raid members, by trading your life with theirs, or to save yourself in the same way
-- Dispersion  -- use Dispersion immediately after using Mind Blast and while none of your DoTs need to be refreshed. In this way, Dispersion will essentially take the place of  Mind Flay in your rotation, which is your weakest spell
-- Divine Insight 109175 -- reset the cooldown on Mind Blast and cause your next Mind Blast within 12 sec to be instant cast and cost no mana.