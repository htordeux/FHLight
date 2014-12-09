
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

local function toSpellName(id)
	local name = GetSpellInfo(id)
	return name
end

warrior.spells = {}

warrior.spells["Bloodthirst"] = toSpellName(23881) -- "Bloodthirst" 23881 "Sanguinaire"
warrior.spells["Ravager"] = toSpellName(152277) -- "Ravager" 152277
warrior.spells["Siegebreaker"] = toSpellName(176289) -- "Siegebreaker" 176289
warrior.spells["StormBolt"] = toSpellName(107570) -- "StormBolt" "107570" 176289 Physical damage and stunning for 4 sec. Deals quadruple damage to targets permanently immune to stuns
warrior.spells["Bloodbath"] = toSpellName(12292) -- "Bloodbath" 12292 "Bain de sang" For the next 12 sec, your melee damage abilities and their multistrikes deal 30% additional damage
warrior.spells["Bladestorm"] = toSpellName(46924) -- "Bladestorm" 46924 "Tempête de lames"  striking all targets within 8 yards
warrior.spells["HeroicThrow"] = toSpellName(57755) -- "Heroic Throw" 57755 "Lancer héroïque"
warrior.spells["WildStrike"] = toSpellName(100130) -- "Wild Strike" 100130 "Frappe sauvage" -- donne DEBUFF "Mortal Wounds" 115804 "Blessures mortelles" -- Healing effects received reduced by 25%
warrior.spells["VictoryRush"] = toSpellName(34428) -- "Victory Rush" 34428 "Ivresse de la victoire" -- buff "Victorious" 32216 "Victorieux"
warrior.spells["Recklessness"] = toSpellName(1719) -- "Recklessness" 1719 "Témérité"
warrior.spells["BerserkerRage"] = toSpellName(18499) -- "Berserker Rage" 18499 "Rage de berserker"
warrior.spells["Avatar"] = toSpellName(107574) -- "Avatar" 107574
warrior.spells["Pummel"] = toSpellName(6552) -- "Pummel" 6552 "Volée de coups"
warrior.spells["RagingBlow"] = toSpellName(85288) -- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116
warrior.spells["Execute"] = toSpellName(5308) -- "Execute" 5308 "Exécution"
warrior.spells["ShatteringThrow"] = toSpellName(64382) -- "Shattering Throw" 64382 "Lancer fracassant"

warrior.spells["Shockwave"] = toSpellName(46968) -- "Shockwave" 46968 "Onde de choc"
warrior.spells["MassSpellReflection"] = toSpellName(114028) -- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
warrior.spells["HeroicLeap"] = toSpellName(6544) -- "Heroic Leap" 6544 "Bond héroïque"
warrior.spells["Hamstring"] = toSpellName(1715) -- "Brise-genou" 1715 "Hamstring"
warrior.spells["Whirlwind"] = toSpellName(1680) -- "Whirlwind" 1680 "Tourbillon"
warrior.spells["HeroicLeap"] = toSpellName(6544) -- "Heroic Leap" 6544 "Bond héroïque"
warrior.spells["Charge"] = toSpellName(100) -- "Charge" 100

warrior.spells["Stoneform"] = toSpellName(20594) -- "Stoneform" 20594 "Forme de pierre"
warrior.spells["Lifeblood"] = toSpellName(74497) -- "Lifeblood" 74497 same ID spell & buff

warrior.spells["BattleShout"] = toSpellName(6673) -- "Battle Shout" 6673 "Cri de guerre"
warrior.spells["CommandingShout"] = toSpellName(469) -- "Commanding Shout" 469 "Cri de commandement"



 
