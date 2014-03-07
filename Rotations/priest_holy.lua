jps.registerRotation("PRIEST","HOLY",function()

	local Priest_Target = jps.LowestInRaidStatus() 
	local health_deficiency = jps.hp(Priest_Target,"abs") -- UnitHealthMax(Priest_Target) - UnitHealth(Priest_Target)
	local health_pct = jps.hp(Priest_Target)
	
	local stackSerendip = jps.buffStacks("Serendipity","player")
	local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.90)
	local POHTarget, groupToHeal, groupTableToHeal = jps.FindSubGroupTarget(0.70) -- Target to heal with POH in RAID with AT LEAST 3 RAID UNIT of the SAME GROUP IN RANGE
	

	------------------------
	-- SPELL TABLE ---------
	------------------------
	
	local function parse_Chakra() -- return table
		local table=
		{
			{
				{ 2050, health_deficiency < priest.AvgAmountFlashHeal, Priest_Target },
				{ 2061, health_deficiency > priest.AvgAmountFlashHeal, Priest_Target },
			}
		}
		return table
	end
	
	local spellTable =
	{
		-- "Feu intérieur" 588 -- "Volonté intérieure" 73413
		{ 588, not jps.buff(588,"player") and not jps.buff(73413,"player") }, -- "target" by default must must be a valid target
		-- Chakra
		{ "Chakra", not jps.buff("Chakra") and not jps.buff("Chakra: Serenity"), "player" },
		{ "nested", jps.buff("Chakra") and not jps.buff("Chakra: Serenity") , parse_Chakra() },
		
		-- "Guardian Spirit"
		{ "Guardian Spirit", health_pct < 0.35 , Priest_Target },
		-- "Prière du désespoir" 19236
		{ 19236, jps.hp("player") < 0.55  and select(2,GetSpellBookItemInfo(priest.Spell["Desesperate"]))~=nil , "player" },
		-- "Pierre de soins" 5512
		{ {"macro","/use item:5512"}, jps.hp("player") < 0.55  and select(1,IsUsableItem(5512))==1 and jps.itemCooldown(5512)==0 , "player" },
		
		-- "Oubli" 586
		{ 586, UnitThreatSituation("player")==3, "player" },
		
		-- "Renew" 139
		{ 139, not jps.buff(139,Priest_Target) and health_deficiency > priest.AvgAmountHeal, Priest_Target },
		-- "Prayer of Mending" "Prière de guérison" 33076
		{ 33076, not jps.buff("Prayer of Mending",Priest_Target), Priest_Target },
		-- "Soins rapides" 2061 "From Darkness, Comes Light" 109186 gives buff -- "Vague de Lumière" 114255 "Surge of Light"
		{ 2061, jps.buff(114255) and health_deficiency > priest.AvgAmountFlashHeal, Priest_Target },
		-- "Holy Word: Serenity"
		{ "Holy Word: Serenity", health_deficiency > priest.AvgAmountHeal, Priest_Target },
		-- "Soins rapides" 2061
		{ 2061, health_pct < 0.55 and stackSerendip < 2, Priest_Target },
		-- "Soins supérieurs" 2060
		{ 2060, health_pct < 0.75 and health_deficiency > priest.AvgAmountGreatHeal, Priest_Target },
		-- "Soins de lien" 32546
		{ 32546, UnitIsUnit(Priest_Target, "player")~=1 and health_deficiency > priest.AvgAmountFlashHeal and jps.hp("player","abs") > priest.AvgAmountFlashHeal, Priest_Target },
		

		-- "Circle of Healing"
		{ "Circle of Healing", countInRange  > 3, Priest_Target },
		-- "Cascade" 121135
		{ 121135, countInRange  > 3 , Priest_Target },
		-- "Prayer of Healing" 596
		{ 596, (type(POHTarget) == "string") , POHTarget },
		
		-- "Soins" 2050
		{ 2050, health_deficiency > priest.AvgAmountHeal, Priest_Target }
	}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default")

-- Serendipity When you heal with Binding Heal or Flash Heal, the cast time of your next Greater Heal or Prayer of Healing spell is reduced by 20% 
-- Serendipity mana cost reduced by 20%. Stacks up to 2 times. Lasts 20 sec.
-- Chakra: Serenity Increases the healing done by your single-target healing spells by 25%
-- Chakra: refresh the duration of your Renew on the target, and transforms your Holy Word: Chastise spell into Holy Word: Serenity.
-- Cascade will also refresh Renew on cooldown.
-- Holy Word: Serenity heals the target and increases the critical effect chance of your healing spells on the target by 25% for 6 sec. 15 sec cooldown.