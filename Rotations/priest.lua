
-- average amount of healing  = (1+MP)*(1+CP)*(B+c*SP) -- MP is the mastery percentage, CP is the crit percentage, SP is our spellpower 
-- Flash Heal: Heals a friendly target for 12619 to 14664 (+ 131.4% of Spell power).
-- Greater Heal : heals a single target for 21022 to 24430 (+ 219% of Spell power).
-- Heal : heals your target for 9848 to 11443 (+ 102.4% of Spell power).

-- GetMastery() the value returns by GetMastery is not your final Mastery value
-- To find your true Mastery, and the multiplier factor used to calculate it, see GetMasteryEffect.

local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit

jps.spells.priest = {}
jps.spells.priest.powerWordShield = jps.toSpellName(17)
jps.spells.priest.renew = jps.toSpellName(139)
jps.spells.priest.purify = jps.toSpellName(527)
jps.spells.priest.dispelMagic = jps.toSpellName(528)
jps.spells.priest.smite = jps.toSpellName(585)
jps.spells.priest.fade = jps.toSpellName(586)
jps.spells.priest.shadowWordPain = jps.toSpellName(589)
jps.spells.priest.prayerOfHealing = jps.toSpellName(596)
jps.spells.priest.mindControl = jps.toSpellName(605)
jps.spells.priest.levitate = jps.toSpellName(1706)
jps.spells.priest.resurrection = jps.toSpellName(2006)
jps.spells.priest.holyWordSerenity = jps.toSpellName(2050)
jps.spells.priest.heal = jps.toSpellName(2060)
jps.spells.priest.flashHeal = jps.toSpellName(2061)
jps.spells.priest.mindVision = jps.toSpellName(2096)
jps.spells.priest.mindBlast = jps.toSpellName(8092)
jps.spells.priest.psychicScream = jps.toSpellName(8122)
jps.spells.priest.shackleUndead = jps.toSpellName(9484)
jps.spells.priest.powerInfusion = jps.toSpellName(10060)
jps.spells.priest.holyFire = jps.toSpellName(14914)
jps.spells.priest.vampiricEmbrace = jps.toSpellName(15286)
jps.spells.priest.mindFlay = jps.toSpellName(15407)
jps.spells.priest.silence = jps.toSpellName(15487)
jps.spells.priest.desperatePrayer = jps.toSpellName(19236)
jps.spells.priest.spiritOfRedemption = jps.toSpellName(20711)
jps.spells.priest.massDispel = jps.toSpellName(32375)
jps.spells.priest.shadowWordDeath = jps.toSpellName(32379)
jps.spells.priest.bindingHeal = jps.toSpellName(32546)
jps.spells.priest.prayerOfMending = jps.toSpellName(33076)
jps.spells.priest.painSuppression = jps.toSpellName(33206)
jps.spells.priest.shadowfiend = jps.toSpellName(34433)
jps.spells.priest.holyWordSanctify = jps.toSpellName(34861)
jps.spells.priest.vampiricTouch = jps.toSpellName(34914)
jps.spells.priest.focusedWill = jps.toSpellName(45243)
jps.spells.priest.rapture = jps.toSpellName(47536)
jps.spells.priest.penance = jps.toSpellName(47540)
jps.spells.priest.dispersion = jps.toSpellName(47585)
jps.spells.priest.guardianSpirit = jps.toSpellName(47788)
jps.spells.priest.mindSear = jps.toSpellName(48045)
jps.spells.priest.glyphOfShackleUndead = jps.toSpellName(57986)
jps.spells.priest.powerWordBarrier = jps.toSpellName(62618)
jps.spells.priest.serendipity = jps.toSpellName(63733)
jps.spells.priest.bodyAndSoul = jps.toSpellName(64129)
jps.spells.priest.divineHymn = jps.toSpellName(64843)
jps.spells.priest.symbolOfHope = jps.toSpellName(64901)
jps.spells.priest.leapOfFaith = jps.toSpellName(73325)
jps.spells.priest.mindSpike = jps.toSpellName(73510)
jps.spells.priest.masteryAbsolution = jps.toSpellName(77484)
jps.spells.priest.masteryEchoOfLight = jps.toSpellName(77485)
jps.spells.priest.masteryMadness = jps.toSpellName(77486)
jps.spells.priest.shadowyApparitions = jps.toSpellName(78203)
jps.spells.priest.atonement = jps.toSpellName(81749)
jps.spells.priest.holyWordChastise = jps.toSpellName(88625)
jps.spells.priest.glyphOfShadow = jps.toSpellName(107906)
jps.spells.priest.twistOfFate = jps.toSpellName(109142)
jps.spells.priest.surgeOfLight = jps.toSpellName(109186)
jps.spells.priest.divineStar = jps.toSpellName(110744)
jps.spells.priest.halo = jps.toSpellName(120517)
jps.spells.priest.glyphOfTheHeavens = jps.toSpellName(120581)
jps.spells.priest.angelicFeather = jps.toSpellName(121536)
jps.spells.priest.mindbender = jps.toSpellName(123040)
jps.spells.priest.glyphOfTheValkyr = jps.toSpellName(126094)
jps.spells.priest.glyphOfShadowyFriends = jps.toSpellName(126745)
jps.spells.priest.powerWordSolace = jps.toSpellName(129250)
jps.spells.priest.holyNova = jps.toSpellName(132157)
jps.spells.priest.glyphOfInspiredHymns = jps.toSpellName(147072)
jps.spells.priest.glyphOfTheSha = jps.toSpellName(147776)
jps.spells.priest.clarityOfWill = jps.toSpellName(152118)
jps.spells.priest.auspiciousSpirits = jps.toSpellName(155271)
jps.spells.priest.shadowyInsight = jps.toSpellName(162452)
jps.spells.priest.voidForm = jps.toSpellName(185916)
jps.spells.priest.shadowMend = jps.toSpellName(186263)
jps.spells.priest.masochism = jps.toSpellName(193063)
jps.spells.priest.castigation = jps.toSpellName(193134)
jps.spells.priest.enlightenment = jps.toSpellName(193155)
jps.spells.priest.benediction = jps.toSpellName(193157)
jps.spells.priest.mania = jps.toSpellName(193173)
jps.spells.priest.fortressOfTheMind = jps.toSpellName(193195)
jps.spells.priest.surrenderToMadness = jps.toSpellName(193223)
jps.spells.priest.legacyOfTheVoid = jps.toSpellName(193225)
jps.spells.priest.callToTheVoid = jps.toSpellName(193371)
jps.spells.priest.fromTheShadows = jps.toSpellName(193642)
jps.spells.priest.mindShattering = jps.toSpellName(193643)
jps.spells.priest.toThePain = jps.toSpellName(193644)
jps.spells.priest.deathsEmbrace = jps.toSpellName(193645)
jps.spells.priest.thoughtsOfInsanity = jps.toSpellName(193647)
jps.spells.priest.creepingShadows = jps.toSpellName(194002)
jps.spells.priest.touchOfDarkness = jps.toSpellName(194007)
jps.spells.priest.voidCorruption = jps.toSpellName(194016)
jps.spells.priest.mentalFortitude = jps.toSpellName(194018)
jps.spells.priest.thriveInTheShadows = jps.toSpellName(194024)
jps.spells.priest.sinisterThoughts = jps.toSpellName(194026)
jps.spells.priest.unleashTheShadows = jps.toSpellName(194093)
jps.spells.priest.sphereOfInsanity = jps.toSpellName(194179)
jps.spells.priest.massHysteria = jps.toSpellName(194378)
jps.spells.priest.powerWordRadiance = jps.toSpellName(194509)
jps.spells.priest.trustInTheLight = jps.toSpellName(196355)
jps.spells.priest.sayYourPrayers = jps.toSpellName(196358)
jps.spells.priest.serenityNow = jps.toSpellName(196416)
jps.spells.priest.reverence = jps.toSpellName(196418)
jps.spells.priest.focusInTheLight = jps.toSpellName(196419)
jps.spells.priest.holyHands = jps.toSpellName(196422)
jps.spells.priest.hallowedGround = jps.toSpellName(196429)
jps.spells.priest.wordsOfHealing = jps.toSpellName(196430)
jps.spells.priest.holyGuidance = jps.toSpellName(196434)
jps.spells.priest.guardiansOfTheLight = jps.toSpellName(196437)
jps.spells.priest.powerOfTheNaaru = jps.toSpellName(196489)
jps.spells.priest.renewTheFaith = jps.toSpellName(196492)
jps.spells.priest.blessingOfTuure = jps.toSpellName(196578)
jps.spells.priest.invokeTheNaaru = jps.toSpellName(196684)
jps.spells.priest.psychicVoice = jps.toSpellName(196704)
jps.spells.priest.afterlife = jps.toSpellName(196707)
jps.spells.priest.holyMending = jps.toSpellName(196779)
jps.spells.priest.lightOfTheNaaru = jps.toSpellName(196985)
jps.spells.priest.divinity = jps.toSpellName(197031)
jps.spells.priest.piety = jps.toSpellName(197034)
jps.spells.priest.shieldDiscipline = jps.toSpellName(197045)
jps.spells.priest.contrition = jps.toSpellName(197419)
jps.spells.priest.confession = jps.toSpellName(197708)
jps.spells.priest.vestmentsOfDiscipline = jps.toSpellName(197711)
jps.spells.priest.painIsInYourMind = jps.toSpellName(197713)
jps.spells.priest.theEdgeOfDarkAndLight = jps.toSpellName(197715)
jps.spells.priest.burstOfLight = jps.toSpellName(197716)
jps.spells.priest.doomsayer = jps.toSpellName(197727)
jps.spells.priest.shieldOfFaith = jps.toSpellName(197729)
jps.spells.priest.borrowedTime = jps.toSpellName(197762)
jps.spells.priest.speedOfThePious = jps.toSpellName(197766)
jps.spells.priest.tamingTheShadows = jps.toSpellName(197779)
jps.spells.priest.shareInTheLight = jps.toSpellName(197781)
jps.spells.priest.barrierForTheDevoted = jps.toSpellName(197815)
jps.spells.priest.powerOfTheDarkSide = jps.toSpellName(198068)
jps.spells.priest.sinsOfTheMany = jps.toSpellName(198074)
jps.spells.priest.voidLord = jps.toSpellName(199849)
jps.spells.priest.reaperOfSouls = jps.toSpellName(199853)
jps.spells.priest.sanlayn = jps.toSpellName(199855)
jps.spells.priest.trailOfLight = jps.toSpellName(200128)
jps.spells.priest.enduringRenewal = jps.toSpellName(200153)
jps.spells.priest.apotheosis = jps.toSpellName(200183)
jps.spells.priest.censure = jps.toSpellName(200199)
jps.spells.priest.guardianAngel = jps.toSpellName(200209)
jps.spells.priest.thePenitent = jps.toSpellName(200347)
jps.spells.priest.plea = jps.toSpellName(200829)
jps.spells.priest.shadowCovenant = jps.toSpellName(204065)
jps.spells.priest.purgeTheWicked = jps.toSpellName(204197)
jps.spells.priest.shiningForce = jps.toSpellName(204263)
jps.spells.priest.circleOfHealing = jps.toSpellName(204883)
jps.spells.priest.voidTorrent = jps.toSpellName(205065)
jps.spells.priest.shadowWordVoid = jps.toSpellName(205351)
jps.spells.priest.dominantMind = jps.toSpellName(205367)
jps.spells.priest.mindBomb = jps.toSpellName(205369)
jps.spells.priest.voidRay = jps.toSpellName(205371)
jps.spells.priest.shadowCrash = jps.toSpellName(205385)
jps.spells.priest.lightsWrath = jps.toSpellName(207946)
jps.spells.priest.lightOfTuure = jps.toSpellName(208065)
jps.spells.priest.artificialStamina = jps.toSpellName(211309)
jps.spells.priest.massResurrection = jps.toSpellName(212036)
jps.spells.priest.artificialDamage = jps.toSpellName(213428)
jps.spells.priest.purifyDisease = jps.toSpellName(213634)
jps.spells.priest.bodyAndMind = jps.toSpellName(214121)
jps.spells.priest.schism = jps.toSpellName(214621)
jps.spells.priest.forbiddenFlame = jps.toSpellName(214925)
jps.spells.priest.beaconOfLight = jps.toSpellName(214926)
jps.spells.priest.darkeningWhispers = jps.toSpellName(214927)
jps.spells.priest.voidSiphon = jps.toSpellName(215322)
jps.spells.priest.invokeTheLight = jps.toSpellName(216122)
jps.spells.priest.darkestShadows = jps.toSpellName(216212)
jps.spells.priest.glyphOfGhostlyFade = jps.toSpellName(219669)
jps.spells.priest.followerOfTheLight = jps.toSpellName(222646)
jps.spells.priest.voidEruption = jps.toSpellName(228260)
jps.spells.priest.voidBolt = jps.toSpellName(205448) -- 228266
jps.spells.priest.searingInsanity = jps.toSpellName(179337)
jps.spells.priest.giftNaaru = jps.toSpellName(59544)
jps.spells.priest.lingeringInsanity = jps.toSpellName(197937)

--local InterruptTable = {
--	{jps.spells.priest.flashHeal, 0.80 , jps.buff(27827) or jps.PvP }, -- "Esprit de rédemption" 27827
--	{jps.spells.priest.heal, 0.50 , jps.buff(27827) },
--	{jps.spells.priest.prayerOfHealing , 0.80 , jps.buff(64901) or jps.buff(27827) or jps.PvP }, --"Symbole d’espoir" 64901
--}

jps.ShouldInterruptCasting = function ( InterruptTable, CountInRange, LowestUnitHealth )
	if jps.LastTarget == nil then return end
	local spellCasting, _, _, _, _, endTime, _ = UnitCastingInfo("player")
	if spellCasting == nil then return false end
	local timeLeft = endTime/1000 - GetTime()
	local TargetHpct = jps.hp(jps.LastTarget)
	
	for key, healSpellTable in pairs(InterruptTable) do
		local breakpoint = healSpellTable[2]
		local spellName = GetSpellInfo(healSpellTable[1])
		if spellName == spellCasting and healSpellTable[3] == false then
			if healSpellTable[1] == jps.spells.priest.prayerOfHealing and CountInRange < breakpoint then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING avgHP "..spellName.." , raid has enough hp!",0, 0.5, 0.8)
			elseif healSpellTable[1] == jps.spells.priest.heal and jps.CastTimeLeft() > 0.60 and LowestUnitHealth < breakpoint then
				SpellStopCasting()
				jps.Message = "Heal_StopCasting"
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING LowestHP "..spellName.." , lowest has critical hp!",0, 0.5, 0.8)
			elseif healSpellTable[1] == jps.spells.priest.flashHeal and TargetHpct > breakpoint then
				SpellStopCasting()
				DEFAULT_CHAT_FRAME:AddMessage("STOPCASTING OverHeal "..spellName.." , unit "..jps.LastTarget.. " has enough hp!",0, 0.5, 0.8)
			end
		end
	end
end

------------------------------------
-- FUNCTIONS ENEMY UNIT
------------------------------------

function isUsableShadowWordDeath()
	if jps.isUsableSpell(jps.spells.priest.shadowWordDeath)
	and jps.spellCharges(jps.spells.priest.shadowWordDeath) > 0
	and jps.cooldown(jps.spells.priest.shadowWordDeath) < 1 then return true end
	return false
end

--not fully tested
function jps.canCastshadowWordDeath()
	local canCastShadowWordDeath = isUsableShadowWordDeath()
	if not canCastShadowWordDeath then return false end
	local Channeling = UnitChannelInfo("player") -- "Mind Flay" is a channeling spell
	local MindFlay = tostring(jps.spells.priest.mindFlay)
	local MindSear = tostring(jps.spells.priest.mindSear)
	local charges = jps.spellCharges(jps.spells.priest.shadowWordDeath) -- "Shadow Word: Death"
	local insanity = jps.insanity()
	if Channeling ~= nil then
		if jps.buff(194249) then
			if tostring(Channeling) == MindFlay and jps.insanity() < 71 then return true end
			if tostring(Channeling) == MindSear and jps.insanity() < 71 then return true end
		else
			if tostring(Channeling) == MindFlay then return true end
			if tostring(Channeling) == MindSear then return true end
		end
	end
	return false
end

function jps.canCastMindBlast()
	if jps.cooldown(jps.spells.priest.mindBlast) > 0 then return false end
	local Channeling = UnitChannelInfo("player") -- "Mind Flay" is a channeling spell
	local MindFlay = GetSpellInfo(15407)
	local MindSear = GetSpellInfo(48045)
	if Channeling ~= nil then
		if Channeling == MindFlay then return true end
		--if Channeling == MindSear then return true end
	end
	return false
end

function jps.canCastvoidBolt()
	if not jps.buff(194249) then return false end
	if jps.cooldown(jps.spells.priest.voidEruption) > 0 then return false end
	local Channeling = UnitChannelInfo("player") -- "Mind Flay" is a channeling spell
	local MindFlay = tostring(jps.spells.priest.mindFlay)
	local MindSear = tostring(jps.spells.priest.mindSear)
	if Channeling ~= nil then
	  if tostring(Channeling) == MindFlay then return true end
	  --if tostring(Channeling) == MindSear then return true end
	end
	return false
end

jps.canFear = function(rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	local BerserkerRage = GetSpellInfo(18499)
	if jps.buff(BerserkerRage,rangedTarget) then return false end
	local canFear = false
	if jps.canDPS(rangedTarget) then
		if (CheckInteractDistance(rangedTarget,2) == true) then canFear = true end
	end
	return canFear
end

jps.canShadowfiend = function(rangedTarget)
	if not jps.canDPS(rangedTarget) then return false end
	if UnitGetTotalAbsorbs(rangedTarget) > 0 then return false end
	if jps.TimeToDie(rangedTarget) > 12 then return true end
	return false
end

------------------------------------
-- FUNCTIONS FRIEND UNIT
------------------------------------

jps.unitForClarity = function(unit)
	if not jps.UnitExists(unit) then return false end
	if jps.buff(152118,unit) then return false end
	if not jps.FriendAggro(unit) then return false end
	if jps.isRecast(152118,unit) then return false end
	return true
end

jps.unitForShield = function(unit)
	if not jps.UnitExists(unit) then return false end
	if not jps.FriendAggro(unit) then return false end
	if jps.buff(17,unit) then return false end
	if jps.debuff(6788,unit) then return false end
	return true
end

jps.unitForBinding = function(unit)
	if not jps.UnitExists(unit) then return false end
	if UnitIsUnit(unit,"player") then return false end
	if jps.hp("player") > 0.60 then return false end
	if jps.hp(unit) > 0.60  then return false end
	return true
end

jps.unitForLeap = function(unit)
	if not jps.UnitExists(unit) then return false end
	if UnitIsUnit(unit,"player") then return false end
	if not jps.FriendAggro(unit) then return false end
	if not jps.LoseControl(unit) then return false end
	return true
end