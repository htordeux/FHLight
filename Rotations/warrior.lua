
warrior = {}

-- Enemy Tracking
function warrior.rangedTarget()
	local rangedTarget = "target"
	local myTarget = jps.LowestTarget()
	if jps.canDPS("target") then
		rangedTarget =  "target"
	elseif jps.canDPS("focustarget") then
		rangedTarget = "focustarget"
	elseif jps.canDPS("targettarget") then
		rangedTarget = "targettarget"
	elseif jps.canDPS(myTarget) then
		rangedTarget = myTarget
	end
	return rangedTarget
end

function warrior.relativeRage(percentage)
	local maxRage = 100
	if jps.glyphInfo(43399) then maxRage = 120 end
	return maxRage * percentage
end

function warrior.minColossusSmash()
	return jps.debuffDuration("Colossus Smash") >= 5
end

local function toSpellName(id) name = GetSpellInfo(id); return name end
warrior.spells = {}
warrior.spells["Pummel"] = toSpellName(6552) -- "Pummel" 6552 "Volée de coups"
warrior.spells["DisruptingShout"] = toSpellName(102060) -- "Disrupting Shout" 102060 "Cri perturbant"
warrior.spells["ImpendingVictory"] = toSpellName(103840) -- "Impending Victory" 103840 "Victoire imminente"
warrior.spells["VictoryRush"] = toSpellName(34428) -- "Victory Rush" 34428 "Ivresse de la victoire" -- buff "Victorious" 32216 "Victorieux"
warrior.spells["Victorious"] = toSpellName(32216) -- "Victory Rush" 34428 "Ivresse de la victoire" -- buff "Victorious" 32216 "Victorieux"
warrior.spells["Recklessness"] = toSpellName(1719) -- "Recklessness" 1719 "Témérité"
warrior.spells["SkullBanner"] = toSpellName(114207) -- "Skull Banner" 114207 "Bannière du crâne"
warrior.spells["BerserkerRage"] = toSpellName(18499) -- "Berserker Rage" 18499 "Rage de berserker"
warrior.spells["Whirlwind"] = toSpellName(1680) -- "Whirlwind" 1680 "Tourbillon"
warrior.spells["ColossusSmash"] = toSpellName(86346) -- "Colossus Smash" 86346 "Frappe du colosse" -- "Colossus Smash" 86346 same ID spell & debuff
warrior.spells["Bloodthirst"] = toSpellName(23881) -- "Bloodthirst" 23881 "Sanguinaire"
warrior.spells["Cleave"] = toSpellName(845) -- "Cleave" 845 "Enchaînement"
warrior.spells["RagingBlow"] = toSpellName(85288) -- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116
warrior.spells["RagingBlow!"] = toSpellName(131116) -- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116
warrior.spells["Bladestorm"] = toSpellName(6552) -- "Bladestorm" 46924 "Tempête de lames"
warrior.spells["Execute"] = toSpellName(5308) -- "Execute" 5308 "Exécution"
warrior.spells["Lifeblood"] = toSpellName(74497) -- "Lifeblood" 74497 same ID spell & buff
warrior.spells["WildStrike"] = toSpellName(100130) -- "Wild Strike" 100130 "Frappe sauvage" -- donne DEBUFF "Mortal Wounds" 115804 "Blessures mortelles" -- Healing effects received reduced by 25%
warrior.spells["HeroicStrike"] = toSpellName(78) -- "Heroic Strike" 78 "Frappe héroïque"
warrior.spells["DragonRoar"] = toSpellName(118000) -- "Dragon Roar" 118000 "Rugissement de dragon"
warrior.spells["BattleShout"] = toSpellName(6673) -- "Battle Shout" 6673 "Cri de guerre"
warrior.spells["Bloodbath"] = toSpellName(12292) -- "Bloodbath" 12292 "Bain de sang"
warrior.spells["Shockwave"] = toSpellName(46968) -- "Shockwave" 46968 "Onde de choc"
warrior.spells["HeroicLeap"] = toSpellName(6544) -- "Heroic Leap" 6544 "Bond héroïque"
warrior.spells["Charge"] = toSpellName(100) -- "Charge" 100 -- IsFalling() returns 1 if the character is currently falling, nil otherwise
warrior.spells["HeroicThrow"] = toSpellName(57755) -- "Heroic Throw" 57755 "Lancer héroïque"
warrior.spells["DragonRoar"] = toSpellName(118000) -- "Dragon Roar" 118000 "Rugissement de dragon"
warrior.spells["DisruptingShout"] = toSpellName(102060) -- "Disrupting Shout" 102060 "Cri perturbant"
warrior.spells["MassSpellReflection"] = toSpellName(114028) -- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
warrior.spells["Stoneform"] = toSpellName(20594) -- "Stoneform" 20594 "Forme de pierre"
warrior.spells["Disarm"] = toSpellName(676) -- "Disarm" 676 "Désarmement"
warrior.spells["ThunderClap"] = toSpellName(6343) -- "Thunder Clap" 6343 "Coup de tonnerre"
warrior.spells["ShatteringThrow"] = toSpellName(64382) -- "Shattering Throw" 64382 "Lancer fracassant"
warrior.spells["CommandingShout"] = toSpellName(469) -- "Commanding Shout" 469 "Cri de commandement"
warrior.spells["Hamstring"] = toSpellName(1715) -- "Brise-genou" 1715 "Hamstring"
warrior.spells["Bloodsurge"] = toSpellName(46916) -- "Bloodsurge" 46916 "Afflux sanguin"
warrior.spells["MeatCleaver"] = toSpellName(12950) -- "Meat Cleaver" 12950 "Fendoir à viande"
warrior.spells["HeroicLeap"] = toSpellName(6544) -- "Heroic Leap" 6544 "Bond héroïque"