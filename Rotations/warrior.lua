
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

local function toSpellName(id)
	local name = GetSpellInfo(id)
	return name
end

warrior.spells = {}
	
-- BUFFS

-- "Defensive Stance" 71
warrior.spells["DefensiveStance"] = toSpellName(71)
-- "Battle Stance" 2457
warrior.spells["BattleStance"] = toSpellName(2457)
-- "Bloodsurge" 46916 "Coup de sang" -- Your Bloodthirst hits have a 20% chance of making your next 2 Wild Strikes free and reducing their global cooldown to 1 sec.
warrior.spells["Bloodsurge"] = toSpellName(46916)
-- "Stoneform" 20594 "Forme de pierre" -- Dissipe tous les effets d’empoisonnement, maladie, malédiction, magie et saignement et réduit tous les dégâts physiques subis de 10% pendant 8 s.
warrior.spells["Stoneform"] = toSpellName(20594)
-- "Battle Shout" 6673 "Cri de guerre" -- Augmente de 10% la puissance d’attaque de tous les membres du groupe ou raid
warrior.spells["BattleShout"] = toSpellName(6673)
-- "Commanding Shout" 469 "Cri de commandement" -- Augmente de 10% l’Endurance de tous les membres du groupe ou raid 
warrior.spells["CommandingShout"] = toSpellName(469)
-- "Intimidating Shout" 5246 "Cri d’intimidation" -- targeted enemy to cower in fear, and up to 5 additional enemies within 8 yards to flee. Targets are disoriented for 8 sec.
warrior.spells["IntimidatingShout"] = toSpellName(5246)
-- "Rallying Cry" 97462 -- 15% increase to maximum health for 10 sec.  After this effect expires, the health is lost.
warrior.spells["RallyingCry"] = toSpellName(97462)
-- "Meat Cleaver" 85739 "Fendoir à viande" -- Dealing damage with Whirlwind increases the number of targets that your Raging Blow hits by 1, stacking up to 3 times.
warrior.spells["MeatCleaver"] = toSpellName(85739)
-- "Piercing Howl" 12323 "Hurlement percant" -- Snares all enemies within 15 yards, reducing their movement speed by 50% for 15 sec -- Piercing Howl is a better version of Hamstring.
warrior.spells["PiercingHowl"] = toSpellName(12323) -- gives debuff 12323
warrior.spells["Hamstring"] = toSpellName(1715) -- "Brise-genou" 1715 "Hamstring"
-- "Victorious" 32216 "Victorieux" -- Ivresse de la victoire activée.
warrior.spells["Victorious"] = toSpellName(32216)

-- SPELLS

-- "Berserker Rage" 18499 "Rage de berserker" -- removing and granting immunity to Fear, Sap and Incapacitate effects for 6 sec.
warrior.spells["BerserkerRage"] = toSpellName(18499)
-- "Bloodthirst" 23881 "Sanguinaire"
warrior.spells["Bloodthirst"] = toSpellName(23881) -- generating 10 Rage, and restoring 1% of your health. 30% chance to be a critical strike. gives Enrage on a critical hit.
-- "Charge" 100 -- Charge to an enemy, rooting it for 1.50 sec. Generates 20 Rage.
warrior.spells["Charge"] = toSpellName(100)
-- "Pummel" 6552 "Volée de coups" -- Pummel the target, interrupting spellcasting and preventing any spell in that school from being cast for 4 sec.
warrior.spells["Pummel"] = toSpellName(6552)
-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116 -- Becoming Enraged enables one charge of Raging Blow. Limit 2 charges.
warrior.spells["RagingBlow"] = toSpellName(85288)
-- "Wild Strike" 100130 "Frappe sauvage" -- Limit 2 charges -- donne DEBUFF "Mortal Wounds" 115804 "Blessures mortelles" -- Healing effects received reduced by 25%
warrior.spells["WildStrike"] = toSpellName(100130)
-- "Recklessness" 1719 "Témérité" -- vos attaques spéciales 15% de chances supplémentaires de réussir un coup critique, et augmente les dégâts de vos coups critiques de 10%. Dure 10 s.
warrior.spells["Recklessness"] = toSpellName(1719)
 -- "Execute" 5308 "Exécution"
warrior.spells["Execute"] = toSpellName(5308)
 -- "Heroic Leap" 6544 "Bond héroïque"
warrior.spells["HeroicLeap"] = toSpellName(6544)
-- "Heroic Throw" 57755 "Lancer héroïque" -- 8-30 yd range -- Throw your weapon at the enemy, causing 50% Physical damage.  Generates high threat.
warrior.spells["HeroicThrow"] = toSpellName(57755)
-- "Whirlwind" 1680 "Tourbillon" -- attack all enemies within 8 yards -- augmentant le nombre de cibles de Coup déchaîné -- gives buff "Meat Cleaver" 85739 "Fendoir à viande
warrior.spells["Whirlwind"] = toSpellName(1680)
-- "Die by the Sword" 118038 -- Increases your parry chance by 100% and reduces damage taken by 20% for 8 sec.
warrior.spells["DieSword"] = toSpellName(118038)
-- "Rend" 772 "Pourfendre"
warrior.spells["Rend"] = toSpellName(772)

-- SPELLS GLYPHS

-- "Shattering Throw" 64382 "Lancer fracassant" -- 30 yd range -- Throw your weapon at the enemy causing damage or removing any invulnerabilities.
warrior.spells["ShatteringThrow"] = toSpellName(64382)


-- SPELLS TALENTS

-- "Ravager" 152277 -- 40 yd range -- Throw a whirling axe at the target location that inflicts [ 1 + 82.5% of AP ] damage to enemies within 6 yards every 1 sec. Lasts 10 sec.
warrior.spells["Ravager"] = toSpellName(152277)
-- "Siegebreaker" 176289 "Briseur de siège" -- dealing 300% damage, and knocking them back and down for 1 sec. Replaces Intimidating Shout.
warrior.spells["Siegebreaker"] = toSpellName(176289)
-- "Avatar" 107574 -- Transform into a colossus for 24 sec, dealing 20% increased damage and removing all roots and snares.
warrior.spells["Avatar"] = toSpellName(107574)
-- "Bloodbath" 12292 "Bain de sang" -- For the next 12 sec, your melee damage abilities and their multistrikes deal 30% additional  damage
warrior.spells["Bloodbath"] = toSpellName(12292)
-- "Bladestorm" 46924 "Tempête de lames" -- striking all targets within 8 yards You are immune to movement impairing and loss of control effects, but can only use Taunt and other defensive abilities
warrior.spells["Bladestorm"] = toSpellName(46924)
-- "Mass Spell Reflection" 114028 "Renvoi de sort de masse"
warrior.spells["MassSpellReflection"] = toSpellName(114028)
-- "Storm Bolt" 107570 "Eclair de tempete" -- 30 yd range -- Hurls your weapon at an enemy, causing (60% of weapon damage) Physical damage and stunning for 4 se
warrior.spells["StormBolt"] = toSpellName(107570) -- gives debuff 132169
-- "Shockwave" 46968 "Onde de choc" -- damage and stunning all enemies within 10 yards for 4 sec.  Cooldown reduced by 20 sec if it strikes at least 3 targets.
warrior.spells["Shockwave"] = toSpellName(46968)
-- "Dragon Roar" 118000 "Rugissement de dragon" -- damage to all enemies within 8 yards and knocking them back and down for 0.5 sec. STUN
warrior.spells["DragonRoar "] = toSpellName(118000)
-- "Sudden Death" 29725 "Mort soudaine" -- 10% chance to make your next Execute cost no initial Rage and be usable on any target, regardless of health level
warrior.spells["SuddenDeath"] = toSpellName(29725)
-- "Enraged Regeneration" 55694 "Régénération enragée" -- no rage Instantly heals you for 10% of your maximum health, and an additional 20% over 5 sec. Usable while stunned.
warrior.spells["EnragedRegeneration"] = toSpellName(55694)
-- "Impending Victory" 103840 "Victoire imminente" -- damage and healing you for 15% of your maximum health. Killing an enemy that yields experience or honor resets the cooldown of Impending Victory. Replaces Victory Rush.
warrior.spells["ImpendingVictory"] = toSpellName(103840)
-- "Victory Rush" 34428 "Ivresse de la victoire" -- damage and healing you for 15% of your maximum health. Can only be used within 20 sec after you kill an enemy that yields experience or honor.
warrior.spells["VictoryRush"] = toSpellName(34428)