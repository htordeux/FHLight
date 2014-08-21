druidferal = {}

druidferal.arcaneTorrent = "Arcane Torrent";        
druidferal.berserk = "Berserk";      
druidferal.berserking = "Berserking"; 
druidferal.bloodFury = "Blood Fury";        
        
druidferal.dreamOfCenarius = "Dream of Cenarius";        
druidferal.faerieFire = "Faerie Fire";        
druidferal.feralRage = "Feral Rage";        
druidferal.ferociousBite = "Ferocious Bite";        
druidferal.forNext = "for next";        
druidferal.forceOfNature = "Force of Nature";        
druidferal.healingTouch = "healing touch";        
druidferal.name = "name";        
druidferal.omenOfClarity = "Omen of Clarity";        
druidferal.poolResource = "pool resource";        
druidferal.predatorySwiftness = "predatory swiftness";        
druidferal.rake = "rake";        
druidferal.rip = "rip";        
druidferal.runeOfReorigination = "Rune of Re-Origination";        
druidferal.savageRoar = "savage roar";        
druidferal.skullBashCat = "skull bash";        
druidferal.slot = "slot";        
druidferal.stealthed = "prowl";   
druidferal.shred = "shred";
druidferal.kingOfTheJungle = "Incarnation: King of the Jungle";   
druidferal.swipeCat = "swipe";        
druidferal.thrashCat = "thrash";        
druidferal.tigersFury = "Tiger's Fury";        
druidferal.vicious = "Vicious";        
druidferal.virmensBitePotion = "Virmen's Bite";        
druidferal.weakenedArmor = "Weakened Armor";      
druidferal.markOfTheWild = "Mark of the Wild";
druidferal.mangle = "Mangle";
druidferal.feralFury ="Feral Fury";
druidferal.ravage = "ravage"

druidferal.energyRegen = function() 
	return select(1,GetPowerRegen())
end

druidferal.cp = function()
	return GetComboPoints("player")
end

druidferal.timeToMax = function() 
	return (100- UnitMana("player")) / druidferal.energyRegen()
end

druidferal.energy = function()
	return UnitMana("player")
end

if jps.TimetoDie == nil then
	jps.TimetoDie = function(unit) 
		if DeathClock_TimeTillDeath ~= nil then
			return jps.cachedValue(function()
				return  DeathClock_TimeTillDeath(unit) 
			end , 1)
		end
	end
end

if AffDots == nil then 
	print("install Affdots druidferal! ");
end

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