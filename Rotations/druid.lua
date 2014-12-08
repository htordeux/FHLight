druid = {}

local function toSpellName(id)
	local name = GetSpellInfo(id)
	return name
end

druid.spells = {}
druid.spells.aquaticForm = toSpellName(1066)
druid.spells.arcaneTorrent = "Arcane Torrent";
druid.spells.astralCommunion = toSpellName(127663)
druid.spells.astralStorm = toSpellName(106996)
druid.spells.balanceOfPower = toSpellName(33596)
druid.spells.barkskin = toSpellName(22812)
druid.spells.bearForm = toSpellName(5487)
druid.spells.bearHug = toSpellName(102795)
druid.spells.berserk = toSpellName(106951) -- spell and buff -- "Berserk";      
druid.spells.berserking = "Berserking";
druid.spells.bloodFury = "Blood Fury";
druid.spells.catForm = toSpellName(768)
druid.spells.celestialAlignment = toSpellName(112071)
druid.spells.cenarionWard = toSpellName(102351)
druid.spells.clearcasting = toSpellName(16870)
druid.spells.cyclone = toSpellName(33786)
druid.spells.dash = toSpellName(1850)
druid.spells.disorientingRoar = toSpellName(99)
druid.spells.displacerBeast = toSpellName(102280)
druid.spells.dreamOfCenarius = toSpellName(108373) -- "Dream of Cenarius";
druid.spells.enrage = toSpellName(5229)
druid.spells.entanglingRoots = toSpellName(339)
druid.spells.euphoria = toSpellName(81062)
druid.spells.faerieFire = toSpellName(770) -- "Faerie Fire"; 
druid.spells.faerieSwarm = toSpellName(106707)
druid.spells.felineGrace = toSpellName(125972)
druid.spells.felineSwiftness = toSpellName(131768)
druid.spells.feralFury ="Feral Fury"; -- toSpellName(144865)
druid.spells.feralRage = "Feral Rage";  -- toSpellName(146874)    
druid.spells.ferociousBite = toSpellName(22568)       
druid.spells.flightForm = toSpellName(33943)
druid.spells.forceOfNature = toSpellName(106737)        
druid.spells.forNext = "for next";
druid.spells.frenziedRegeneration = toSpellName(22842)
druid.spells.genesis = toSpellName(145518)
druid.spells.growl = toSpellName(6795)
druid.spells.harmony = toSpellName(100977)      
druid.spells.healingTouch = toSpellName(5185)
druid.spells.heartOfTheWild = toSpellName(108288)
druid.spells.hibernate = toSpellName(2637)
druid.spells.hurricane = toSpellName(16914)

druid.spells.incarnation = toSpellName(106731)
druid.spells.ChosenOfElune = toSpellName(102560) -- Aura(buff) in moonkin form
druid.spells.kingOfTheJungle = toSpellName(102543) -- Aura(buff) in cat form
druid.spells.sonOfUrsoc = toSpellName(102558) -- Aura(buff) in bear form

druid.spells.infectedWounds = toSpellName(48484)
druid.spells.innervate = toSpellName(29166)
druid.spells.ironbark = toSpellName(102342)
druid.spells.killerInstinct = toSpellName(108299)
druid.spells.lacerate = toSpellName(33745)
druid.spells.leaderOfThePack = toSpellName(17007)
druid.spells.lifeblood = toSpellName(121279)
druid.spells.lifebloom = toSpellName(33763)
druid.spells.livingSeed = toSpellName(48500)
druid.spells.lunarShower = toSpellName(33605)
druid.spells.maim = toSpellName(22570)
druid.spells.malfurionGift = toSpellName(92364)
druid.spells.mangle = toSpellName(33917) -- Cat and bear form spell id
druid.spells.markOfTheWild = toSpellName(1126) -- "Mark of the Wild";
druid.spells.massEntanglement = toSpellName(102359)
druid.spells.maul = toSpellName(6807)
druid.spells.meditation = toSpellName(85101)
druid.spells.mightOfUrsoc = toSpellName(106922)
druid.spells.mightyBash = toSpellName(5211)
druid.spells.moonfire = toSpellName(8921)
druid.spells.moonkinForm = toSpellName(24858)
druid.spells.name = "name";        
druid.spells.naturalInsight = toSpellName(112857)
druid.spells.naturalist = toSpellName(17073)
druid.spells.natureFocus = toSpellName(84736)
druid.spells.natureGrasp = toSpellName(16689)
druid.spells.naturesCure = toSpellName(88423)
druid.spells.naturesSwiftness = toSpellName(132158)
druid.spells.natureVigil = toSpellName(124974)
druid.spells.nourish = toSpellName(50464)
druid.spells.nurturingInstinct = toSpellName(33873)
druid.spells.omenOfClarity = "Omen of Clarity";
druid.spells.omenOfClarityFeral = toSpellName(16864) -- feral
druid.spells.omenOfClarityResto = toSpellName(113043) -- resto
druid.spells.owlkinFrenzy = toSpellName(48393)
druid.spells.poolResource = "Pool Resource";
druid.spells.pounce = toSpellName(9005)
druid.spells.predatorySwiftness = "predatory swiftness";
druid.spells.predatorySwiftnessBuff = toSpellName(69369) -- the buff
druid.spells.predatorySwiftnessSpell = toSpellName(16974) -- the spell
druid.spells.primalFury = toSpellName(16961)
druid.spells.prowl = toSpellName(5215)
druid.spells.rake = toSpellName(1822)
druid.spells.ravage = toSpellName(6785) -- "Ravage"
druid.spells.rebirth = toSpellName(20484)
druid.spells.regrowth = toSpellName(8936)
druid.spells.rejuvination = toSpellName(774)
druid.spells.removeCorruption = toSpellName(2782)
druid.spells.renewal = toSpellName(108238)
druid.spells.revive = toSpellName(50769)      
druid.spells.rip = toSpellName(1079)       
druid.spells.runeOfReorigination = "Rune of Re-Origination";
druid.spells.savageDefense = toSpellName(62606)
druid.spells.savageRoar = toSpellName(52610) -- spell and buff share id      
druid.spells.shootingStars = toSpellName(93399)
druid.spells.shred = toSpellName(5221)
druid.spells.skullBash = toSpellName(106839)
druid.spells.skullBashCat = "skull bash";        
druid.spells.slot = "slot";        
druid.spells.solarBeam = toSpellName(78675)
druid.spells.soothe = toSpellName(2908) 
druid.spells.soulOfTheForrest = toSpellName(114107) -- toSpellName(48504)
druid.spells.stampedingRoar = toSpellName(106898)
druid.spells.starfall = toSpellName(48505)
druid.spells.starfire = toSpellName(2912)
druid.spells.starsurge = toSpellName(78674)
druid.spells.stealthed = "prowl";   
druid.spells.sunfire = toSpellName(93402)
druid.spells.survivalInstincts = toSpellName(61336)
druid.spells.swiftFlightForm = toSpellName(40120)
druid.spells.swiftRejuvenation = toSpellName(33886)
druid.spells.swiftmend = toSpellName(81269) -- toSpellName(18562)
druid.spells.swipe = toSpellName(106785) -- Bear and Cat form version
druid.spells.swipeCat = "swipe";
druid.spells.symbiosis = toSpellName(110309)
druid.spells.thrash = toSpellName(106830) -- debuff
druid.spells.thrashCat = toSpellName(106832) -- Bear and Cat form version
druid.spells.tigersFury = toSpellName(5217) -- spell and buff share id -- "Tiger's Fury";
druid.spells.toothAndClaw = toSpellName(135288)
druid.spells.trackHumanoids = toSpellName(5225)
druid.spells.tranquility = toSpellName(740)
druid.spells.travelForm = toSpellName(783)
druid.spells.typhoon = toSpellName(132469)     
druid.spells.ursolVortex = toSpellName(102793)
druid.spells.vengeance = toSpellName(84840)
druid.spells.vicious = "Vicious";        
druid.spells.virmensBitePotion = "Virmen's Bite";
druid.spells.warStomp = toSpellName(20549)
druid.spells.weakenedArmor = "Weakened Armor";
druid.spells.wildCharge = toSpellName(102401)
druid.spells.wildGrowth = toSpellName(48438)
druid.spells.wildMushroom = toSpellName(88747)
druid.spells.wildMushroomBloom = toSpellName(102791)
druid.spells.wildMushroomDetonate = toSpellName(88751)
druid.spells.wrath = toSpellName(5176)

--------------------------
-- DRUID RESTO
--------------------------

druid.groupHealTable = {"NoSpell", false, "player"}
function druid.groupHealTarget()
    local tank = jps.findMeATank()
    local healTarget = jps.LowestInRaidStatus()
    if jps.canHeal(tank) and jps.hp(tank) <= 0.5 then healTarget = tank end
    if jps.hpInc("player") < 0.2 then healTarget = "player" end
    return healTarget
end

function druid.hastSotF()
    local selected, talentIndex = GetTalentRowSelectionInfo(4)
    return talentIndex == 10
end

function groupHeal()
    local healTarget = druid.groupHealTarget()
    local healSpell = nil
    if jps.canCast(druid.spells.wildGrowth, healTarget) then
        healSpell = druid.spells.wildGrowth
    elseif jps.canCast(druid.spells.swiftmend, healTarget) and jps.buff(druid.spells.rejuvination,healTarget) or jps.buff(druid.spells.regrowth,healTarget) then
        healSpell = druid.spells.swiftmend
    elseif not jps.buff(druid.spells.rejuvination,healTarget) then
        healSpell = druid.spells.rejuvination
    end
    druid.groupHealTable[1] = healSpell
    druid.groupHealTable[2] = healSpell ~= nil
    druid.groupHealTable[3] = healTarget
    return druid.groupHealTable
end

druid.focusHealTable = {"NoSpell", false, "player"}
druid.focusHealTargets = {"target", "targettarget", "focus", "focustarget"}
function druid.focusHealTarget()
    if jps.hpInc("player") < 0.2 then return "player" end
    -- First Check for low targets
    for _,healTarget in pairs(druid.focusHealTargets) do
        if jps.hpInc(healTarget) < .5 and jps.canHeal(healTarget) then return healTarget end
    end
    -- All above 50% -> take first possible target
    for _,healTarget in pairs(druid.focusHealTargets) do
        if jps.canHeal(healTarget) then return healTarget end
    end
    return nil
end

local dispelTable = {druid.spells.naturesCure}
function druid.dispel()
    local cleanseTarget = nil
    if jps.DispelMagicTarget() then
    	cleanseTarget = jps.DispelMagicTarget()
    elseif jps.DispelCurseTarget() then
    	cleanseTarget = jps.DispelCurseTarget()
    elseif jps.DispelPoisonTarget() then
    	cleanseTarget = jps.DispelPoisonTarget()
    end
    dispelTable[2] = cleanseTarget ~= nil
    dispelTable[3] = cleanseTarget
    return dispelTable
end

function druid.activeMushrooms()
    local first = GetTotemInfo(1) and 1 or 0
    local second = GetTotemInfo(2) and 1 or 0
    local third = GetTotemInfo(3) and 1 or 0
    return first + second + third
end

function druid.legacyDefaultTarget()
    --healer
    local tank = nil
    local me = "player"
    
    -- Tank is focus.
    tank = jps.findMeATank()
    
    --Default to healing lowest partymember
    local defaultTarget = jps.LowestInRaidStatus()
    
    --Check that the tank isn't going critical, and that I'm not about to die
    if jps.canHeal(tank) and jps.hp(tank) <= 0.5 then defaultTarget = tank end
    if jps.hpInc(me) < 0.2 then defaultTarget = me end
    
    return defaultTarget
end

function druid.legacyDefaultHP()
    return jps.hpInc(druid.legacyDefaultTarget())
end

--------------------------
-- DRUID FERAL
--------------------------

druid.energyRegen = function() 
	return select(1,GetPowerRegen())
end

druid.cp = function()
	return GetComboPoints("player")
end

druid.timeToMax = function() 
	return (100- UnitMana("player")) / druid.energyRegen()
end

druid.energy = function()
	return UnitMana("player")
end

--if AffDots == nil then 
--	print("install Affdots druid");
--end

jps.dotPower = function(dotID)
	if AffDots == nil then 
		return 0 
	end
	return AffDots.Hook(dotID) or 0
end

jps.sub = function(p1,p2)
   return p1 - p2
end

jps.add = function(p1,p2)
   return p1+p2
end