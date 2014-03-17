local L = MyLocalizationTable
local GetSpellInfo = GetSpellInfo

if not priest then priest = {} end

---------------------------
-- SPELLS TABLE
---------------------------

-- average amount of healing  = (1+MP)*(1+CP)*(B+c*SP) -- MP is the mastery percentage, CP is the crit percentage, SP is our spellpower 
-- Flash Heal: Heals a friendly target for 12619 to 14664 (+ 131.4% of Spell power).
-- average amount of Flash Heal  = (1+0,25)*(1+0.9)*(14664+(1.314*28000))
-- Greater Heal : heals a single target for 21022 to 24430 (+ 219% of Spell power)
-- Heal : heals your target for 9848 to 11443 (+ 102.4% of Spell power).
local masteryValue = math.ceil(GetMastery())/100
local bonusHealing = math.ceil(GetSpellBonusHealing())
local minCrit = math.ceil(GetSpellCritChance(2))/100 -- 2 - Holy
priest.AvgAmountFlashHeal = (1+masteryValue)*(1+minCrit)*(14664+(1.314*bonusHealing))
priest.AvgAmountGreatHeal = (1+masteryValue)*(1+minCrit)*(24430+(2.219*bonusHealing))
priest.AvgAmountHeal = (1+masteryValue)*(1+minCrit)*(11443+(1.102*bonusHealing))


priest.Disc = {}
priest.Spell = {}
setmetatable(priest.Disc, { __mode = 'k' }) -- priest.Disc is now weak

priest.Spell.arcaneTorrent = 28730;
priest.Spell.bloodFury = 33702;
priest.Spell.bloodlust = 2825;	
priest.Spell.borrowedTime = 59889;
priest.Spell.cascade = 121135;
priest.Spell.divineStar = 110744;
priest.Spell.flashHeal = 2061;
priest.Spell.grace = 77613;
priest.Spell.greaterHeal = 2060;
priest.Spell.halo = 120517;
priest.Spell.archangel = 81700;
priest.Spell.evangelism = 81662;
priest.Spell.hymnOfHope = 64901;
priest.Spell.innerFocus = 89485;
priest.Spell.innerFocusImmune = 96267
priest.Spell.jadeSerpentPotion = 105702;
priest.Spell.manaPotion = 76098;
priest.Spell.mindbender = 123040;
priest.Spell.powerInfusion = 10060;
priest.Spell.powerWordShield = 17;
priest.Spell.powerWordSolace = 129250;
priest.Spell.rapture = 47536;
priest.Spell.renew = 139; 
priest.Spell.shadowWordDeath = 32379;
priest.Spell.smite = 585;
priest.Spell.surgeOfLight = 114255;
priest.Spell.twistOfFate = 109142; 
priest.Spell.purify = 527;
priest.Spell.spiritShell = 114908;
priest.Spell.spiritShellBuild = 109964;
priest.Spell.prayerOfHealing = 596;
priest.Spell.prayerOfMending = 33076;
priest.Spell.divineAegis = 47753;
priest.Spell.bindingHeal = 32546;
priest.Spell.naaruGift = 59544;
priest.Spell.desperatePrayer = 19236;
priest.Spell.innerWill = 73413;
priest.Spell.innerFire = 588;
priest.Spell.penance = 47540;
priest.Spell.shadowfiend = 34433;
priest.Spell.voidShift = 108968;
priest.Spell.painsup = 33206;
priest.Spell.holyFire = 14914;
priest.Spell.heal = 2050;
priest.Spell.weakenedSoul = 6788;
priest.Spell.arcaneTorrent = 28730;


priest.Spell["SpiritShell"] = tostring(select(1,GetSpellInfo(114908))) -- buff target Spirit Shell 114908
priest.Spell["PrayerOfHealing"] = tostring(select(1,GetSpellInfo(596))) -- "Prière de soins" 596
priest.Spell["NaaruGift"] = tostring(select(1,GetSpellInfo(59544))) -- NaaruGift 59544
priest.Spell["Desesperate"] = tostring(select(1,GetSpellInfo(19236))) -- "Prière du désespoir" 19236
priest.Spell["BindingHeal"] = tostring(select(1,GetSpellInfo(32546))) -- "Soins de lien" 32546
priest.Spell["Grace"] = tostring(select(1,GetSpellInfo(77613))) -- Grâce 77613
priest.Spell["DivineAegis"] =  tostring(select(1,GetSpellInfo(47753))) -- Egide Divine 47515
priest.Spell["DispelMagic"] =  tostring(select(1,GetSpellInfo(528))) -- Dispel Magic 528

--local InterruptTable = {
--	{priest.Spell.flashHeal, 0.75, jps.buffId(priest.Spell.spiritShellBuild) or jps.buffId(priest.Spell.innerFocus) },
--	{priest.Spell.greaterHeal, 0.95, jps.buffId(priest.Spell.spiritShellBuild) },
--	{priest.Spell.heal, 1 , jps.buffId(priest.Spell.spiritShellBuild) },
--	{priest.Spell.prayerOfHealing, 0.95, jps.buffId(priest.Spell.spiritShellBuild) or jps.MultiTarget}
--}

priest.ShouldInterruptCasting = function ( InterruptTable, AvgHealthLoss, CountInRaid ) 
	if jps.LastTarget == nil then return end
	local spellCasting, _, _, _, _, endTime, _ = UnitCastingInfo("player")
	if spellCasting == nil then return false end
	local timeLeft = endTime/1000 - GetTime()
	local TargetHealth = jps.hp(jps.LastTarget,"abs")
	local TargetHpct = jps.hp(jps.LastTarget)
	
	for key, healSpellTable  in pairs(InterruptTable) do
		local breakpoint = healSpellTable[2]
		local spellName = tostring(select(1,GetSpellInfo(healSpellTable[1]))) 
		if (spellName:lower() == spellCasting:lower()) and healSpellTable[3] == false then
			if getaverage_heal(spellName) > TargetHealth then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING OverHeal"..spellName.." , unit "..jps.LastTarget.. " has enough hp!",0, 0.5, 0.8)
			elseif healSpellTable[1] == priest.Spell.heal and TargetHpct < 0.55 and jps.CastTimeLeft(player) > 0.5 and jps.mana() > 0.20 then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING "..spellName.." important unit goes critical",0, 0.5, 0.8)
			elseif healSpellTable[1] == priest.Spell.prayerOfHealing and AvgHealthLoss >= breakpoint then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING avgHP"..spellName.." , raid has enough hp!",0, 0.5, 0.8)
			end
		end
	end
end

----------------------
-- FUNCTABLES
----------------------

-- priest.Spell.flashHeal = 2061	
priest.tableForFlash = function ( Lowest )
	local Table = { 2061, false, Lowest, "" }
	if Lowest == nil then return Table end
	local LowestHpct = jps.hp(Lowest) -- UnitHealth(unit) / UnitHealthMax(unit)
	local LowestHealth = jps.hp(Lowest,"abs") -- UnitHealthMax(unit) - UnitHealth(unit)
	local AvgHeal = priest.AvgAmountFlashHeal

	-- "From Darkness, Comes Light" 109186 gives buff -- "Vague de Lumière" 114255 "Surge of Light"
	if jps.buff(114255) and (LowestHealth >= AvgHeal) then
		Table = {2061, true, Lowest, "FlashSurgeOfLight_fn "..Lowest }
	-- "From Darkness, Comes Light" 109186 gives buff -- "Vague de Lumière" 114255 "Surge of Light"
	elseif jps.buff(114255) and (jps.buffDuration(114255) < 4) then
		Table = {2061, true, Lowest, "FlashSurgeOfLight_fn "..Lowest }		
	-- "Focalisation intérieure" 96267 Immune to Silence, Interrupt and Dispel effects 5 seconds remaining
	elseif jps.buffId(96267) and (jps.buffDuration(96267,"player") > 1.5) and (LowestHealth >= AvgHeal) then
		Table = {2061, true, Lowest, "FlashImmune_fn "..Lowest }
	-- "Borrowed" 59889 -- After casting Power Word: Shield reducing the cast time or channel time of your next Priest spell within 6 sec by 15%.
	elseif jps.buff(59889,"player") and (LowestHpct < 0.35) then
		Table = {2061, true, Lowest, "FlashBorrowed_fn "..Lowest }
	end
	return Table
end

--------------------------------
-- FUNCTIONS RAIDSTATUS
--------------------------------

priest.SpiritShell = function (unit) -- Applied to FriendUnit
	if unit == nil then return false end
	if not jps.FriendAggro(unit) then return false end
	if jps.hp(unit) < 0.95 then return false end
	return true
end

------------------------------------
-- FUNCTIONS ENEMY UNIT
------------------------------------
local BerserkerRage = tostring(select(1,GetSpellInfo(18499)))
priest.canFear = function (rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	local canFear = false
	if jps.canDPS(rangedTarget) then
		if jps.buff(BerserkerRage,rangedTarget) then return false
		elseif (CheckInteractDistance(rangedTarget,3) == 1) then canFear = true 
		end
	end
	
	local knownTypes = {[0]="player", [1]="world object", [3]="NPC", [4]="pet", [5]="vehicle"}
	if jps.canDPS(rangedTarget) then
		local rangedTargetGuid = UnitGUID(rangedTarget)
		if FireHack and rangedTargetGuid ~= nil then
			local rangedTargetObject = GetObjectFromGUID(rangedTargetGuid)
			local knownType = tonumber(rangedTargetGuid:sub(5,5), 16) % 8
			if (knownTypes[knownType] ~= nil) then
				if (rangedTargetObject:GetDistance() > 8) then canFear = false end
				if jps.FaceTarget then rangedTargetObject:Target() end
			end
		end
		--if jps.FaceTarget then jps.Macro("/target "..rangedTarget) end
	end
	return canFear
end

priest.canShadowfiend = function (rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	if UnitGetTotalAbsorbs(rangedTarget) > 0 then return false end
	local isBoss = (UnitLevel(rangedTarget) == -1) or (UnitClassification(rangedTarget) == "elite")
	local isEnemy = jps.canDPS(rangedTarget) and jps.TimeToDie(rangedTarget) > 12
	if isEnemy or isBoss then return true end
	return false
end

priest.canShadowWordDeath = function (rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	if jps.cooldown(32379) == 0 and jps.hp(rangedTarget) < 0.20 then return true end
	return false
end


------------------------------------
-- FUNCTIONS FRIEND UNIT
------------------------------------

priest.unitForShield = function (unit)
	if unit == nil then return false end
	if jps.buff(17,unit) then return false end
	if jps.debuff(6788,unit) then return false end
	if jps.checkTimer("ShieldTimer") > 0 then return false end
	return true
end

priest.unitForMending = function (unit)
	if unit == nil then return false end
	if not jps.FriendAggro(unit) then return false end
	if (jps.cooldown(33076) > 0) then return false end
	if jps.buff(33076,unit) then return false end
	return true
end

priest.unitForBinding = function (unit)
	if unit == nil then return false end
	if (UnitIsUnit(unit,"player")==1) then return false end
	if (jps.LastCast == priest.Spell["BindingHeal"]) then return false end
	if (jps.hp("player","abs") < priest.AvgAmountFlashHeal) then return false end
	if (jps.hp(unit,"abs") < priest.AvgAmountFlashHeal) then return false end
	return true
end

priest.unitForLeap = function (unit) -- {"CC", "Snare", "Root", "Silence", "Immune", "ImmuneSpell", "Disarm"}
	if not jps.Interrupts then return false end
	if unit == nil then return false end
	if (UnitIsUnit(unit,"player")==1) then return false end
	if not jps.LoseControl(unit) then return false end
	return true
end

-------------------
-- EVENT FUNCTIONS
-------------------

jps.listener.registerCombatLogEventUnfiltered("SPELL_CAST_SUCCESS", function(...)
	local sourceGUID = select(4,...)
	local spellID =  select(12,...)
	if sourceGUID == UnitGUID("player") then
		if spellID == 123258 then jps.createTimer("ShieldTimer", 12 ) end -- 123258 "Power Word: Shield"
	end
end)

-------------------
-- FIREHACK FUNCTIONS
-------------------

priest.unitForMassDispelFriend = function () -- Mass Dispel on PLAYER
	local parseMassDispell = { 32375, false , "player" , "MassDispel_Friend" }
	if not FireHack then return parseMassDispell end
	if jps.Moving then return parseMassDispell end
	if jps.cooldown(32375) > 0 then return parseMassDispell end
	if not jps.canDispel("player",{"Magic"}) then return parseMassDispell end
	
	local debuffcount = 0
	local PlayerGuid = UnitGUID("player")
	local PlayerObject = GetObjectFromGUID(PlayerGuid)
	local NearbyPlayers = PlayerObject:GetNearbyPlayers (8)
	if jps.tableLength(NearbyPlayers) == 0 then return parseMassDispell end
	
	for _,UnitObject in ipairs(NearbyPlayers) do
		local UnitObject_name = UnitObject:GetName()
		if jps.canDispel(UnitObject_name,{"Magic"}) then
			debuffcount = debuffcount + 1
		end
		if debuffcount > 2 then
			parseMassDispell[2] = true
		break end
	end
	return parseMassDispell
end

priest.unitForMassDispelEnemy = function () -- Mass Dispel on TARGET
	local parseMassDispell = { 32375, false , "target" , "MassDispel_Enemy" }
	if not FireHack then return parseMassDispell end
	if jps.Moving then return parseMassDispell end
	if jps.cooldown(32375) > 0 then return parseMassDispell end
	
	local PlayerGuid = UnitGUID("player")
	local PlayerObject = GetObjectFromGUID(PlayerGuid)
	local NearbyEnemies = PlayerObject:GetNearbyEnemies (30)
	if jps.tableLength(NearbyEnemies) == 0 then return parseMassDispell end
		
	local iceblock = tostring(select(1,GetSpellInfo(45438))) -- ice block mage
	local divineshield = tostring(select(1,GetSpellInfo(642))) -- divine shield paladin
	for _,UnitObject in ipairs(NearbyEnemies) do
		if UnitObject:GetAura (divineshield) then
			UnitObject:Target()
			parseMassDispell[2] = true
		elseif UnitObject:GetAura (iceblock) then
			UnitObject:Target()
			parseMassDispell[2] = true
		break end
	end
	return parseMassDispell
end
