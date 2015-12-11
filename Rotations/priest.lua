
if not priest then priest = {} end

---------------------------
-- SPELLS TABLE
---------------------------

-- average amount of healing  = (1+MP)*(1+CP)*(B+c*SP) -- MP is the mastery percentage, CP is the crit percentage, SP is our spellpower 
-- Flash Heal: Heals a friendly target for 12619 to 14664 (+ 131.4% of Spell power).
-- Greater Heal : heals a single target for 21022 to 24430 (+ 219% of Spell power).
-- Heal : heals your target for 9848 to 11443 (+ 102.4% of Spell power).

-- GetMastery() the value returns by GetMastery is not your final Mastery value
-- To find your true Mastery, and the multiplier factor used to calculate it, see GetMasteryEffect.

local L = MyLocalizationTable
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit
local mastery = GetMasteryEffect()
local masteryValue = math.ceil(GetMastery())/100
local bonusHealing = math.ceil(GetSpellBonusHealing())
local minCrit = math.ceil(GetSpellCritChance(2))/100 -- 2 - Holy
priest.AvgAmountFlashHeal = (1+masteryValue)*(1+minCrit)*(14664+(1.314*bonusHealing))
priest.AvgAmountGreatHeal = (1+masteryValue)*(1+minCrit)*(24430+(2.219*bonusHealing))


priest.Disc = {}
priest.Spell = {}

priest.Spell.Archangel = 81700;
priest.Spell.Smite = 585;
priest.Spell.ClarityOfWill = 152118
priest.Spell.Cascade = 121135;
priest.Spell.Halo = 120517;
priest.Spell.PowerWordShield = 17;
priest.Spell.PowerWordSolace = 129250;
priest.Spell.Heal = 2060;
priest.Spell.FlashHeal = 2061;
priest.Spell.BindingHeal = 32546;
priest.Spell.Penance = 47540;

priest.Spell.PowerInfusion = 10060;
priest.Spell.Evangelism = 81662;
priest.Spell.Mindbender = 123040;
priest.Spell.DesperatePrayer = 19236;
priest.Spell.Grace = 77613;
priest.Spell.Rapture = 47536;
priest.Spell.Renew = 139; 
priest.Spell.SurgeOfLight = 114255;
priest.Spell.TwistOfFate = 109142; 
priest.Spell.Purify = 527;
priest.Spell.SpiritShell = 114908;
priest.Spell.SpiritShellBuild = 109964;
priest.Spell.PrayerOfHealing = 596;
priest.Spell.PrayerOfMending = 33076;
priest.Spell.DivineAegis = 47753;
priest.Spell.NaaruGift = 59544;

priest.Spell.Shadowfiend = 34433;
priest.Spell.PainSuppression = 33206;
priest.Spell.HolyFire = 14914;
priest.Spell.WeakenedSoul = 6788;
priest.Spell.HolyCascade = 121135 -- "Cascade" Holy 121135 Shadow 127632

--local InterruptTable = {
--	{priest.Spell.FlashHeal, 0.75, jps.buffId(priest.Spell.SpiritShellBuild) },
--	{priest.Spell.Heal, 0.95, jps.buffId(priest.Spell.SpiritShellBuild) },
--	{priest.Spell.PrayerOfHealing, 0.95, jps.buffId(priest.Spell.SpiritShellBuild) or jps.MultiTarget}
--}

priest.ShouldInterruptCasting = function ( InterruptTable, AvgHealthLoss, CountInRaid )
	if jps.LastTarget == nil then return end
	local spellCasting, _, _, _, _, endTime, _ = UnitCastingInfo("player")
	if spellCasting == nil then return false end
	local timeLeft = endTime/1000 - GetTime()
	local TargetHpct = jps.hp(jps.LastTarget)
	
	for key, healSpellTable  in pairs(InterruptTable) do
		local breakpoint = healSpellTable[2]
		local spellName = GetSpellInfo(healSpellTable[1])
		if spellName == spellCasting and healSpellTable[3] == false then
			if healSpellTable[1] == priest.Spell.HolyCascade and CountInRaid < breakpoint then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING avgHP "..spellName.." , raid has enough hp!",0, 0.5, 0.8)
			elseif healSpellTable[1] == priest.Spell.PrayerOfHealing and AvgHealthLoss > breakpoint then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING avgHP "..spellName.." , raid has enough hp!",0, 0.5, 0.8)
			elseif TargetHpct > breakpoint then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING OverHeal "..spellName.." , unit "..jps.LastTarget.. " has enough hp!",0, 0.5, 0.8)
			end
		end
	end
end

------------------------------------
-- FUNCTIONS ENEMY UNIT
------------------------------------

priest.canFear = function(rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	local canFear = false
	local BerserkerRage = GetSpellInfo(18499)
	if jps.buff(BerserkerRage,rangedTarget) then return false end
	if jps.canDPS(rangedTarget) then
		if (CheckInteractDistance(rangedTarget,3) == true) then canFear = true end
		local rangedTargetGuid = UnitGUID(rangedTarget)
		if FireHack and rangedTargetGuid ~= nil then
			local rangedTargetObject = GetObjectFromGUID(rangedTargetGuid)
			if (rangedTargetObject:GetDistance() > 8) then canFear = false end
			rangedTargetObject:Target()
		end
	end
	return canFear
end

priest.canShadowfiend = function(rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	if UnitGetTotalAbsorbs(rangedTarget) > 0 then return false end
	if jps.TimeToDie(rangedTarget) > 12 then return true end
	return false
end

priest.canShadowWordDeath = function(rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	if jps.cooldown(32379) == 0 and jps.hp(rangedTarget) < 0.20 then return true end
	return false
end

------------------------------------
-- FUNCTIONS FRIEND UNIT
------------------------------------

priest.unitForClarity = function(unit)
	if not jps.UnitExists(unit) then return false end
	if jps.buff(152118,unit) then return false end
	if not jps.FriendAggro(unit) then return false end
	if jps.isRecast(152118,unit) then return false end
	return true
end

priest.unitForShield = function(unit)
	if not jps.UnitExists(unit) then return false end
	if not jps.FriendAggro(unit) then return false end
	if jps.buff(17,unit) then return false end
	if jps.debuff(6788,unit) and not jps.buffId(123266,"player") then return false end
	return true
end

priest.unitForMending = function(unit)
	if not jps.UnitExists(unit) then return false end
	if not jps.FriendAggro(unit) then return false end
	if jps.cooldown(33076) > 0 then return false end
	if jps.buff(41635,unit) then return false end
	return true
end

priest.unitForBinding = function(unit)
	if not jps.UnitExists(unit) then return false end
	if UnitIsUnit(unit,"player") then return false end
	if jps.hp("player") > 0.75 then return false end
	if jps.hp(unit) > 0.75  then return false end
	return true
end

priest.unitForLeap = function(unit)
	if not jps.UnitExists(unit) then return false end
	if UnitIsUnit(unit,"player") then return false end
	if not jps.FriendAggro(unit) then return false end
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
		if spellID == 123258 or spellID == 17 then
			if jps.checkTimer("ShieldTimer") == 0 then jps.createTimer("ShieldTimer", 12 ) end
		end
		if spellID == 88625 then jps.createTimer("Chastise",30) end
	end
end)

-- UNIT_SPELLCAST_SUCCEEDED for Holy Word: Chastise 88625 Cooldown
jps.listener.registerEvent("UNIT_SPELLCAST_SUCCEEDED", function(unitID,spellname,_,_,spellID)
	if (unitID == "player") and spellID == 88625 then
		jps.createTimer("Chastise",30)
	end
end)