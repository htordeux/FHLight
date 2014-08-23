--[[[
@rotation Default PvE
@class DRUID
@spec FERAL
@author jpganis
@description 
Ty to MEW Feral Sim
]]--
	
jps.registerRotation("DRUID","FERAL", function()
	local spell = nil
	local target = nil

	local energy = UnitMana("player")
	local cp = GetComboPoints("player")
	local executePhase = jps.hp("target") <= .25
	local energyPerSec = 11.16
	
	local tigersFuryCD = jps.cooldown("Tiger's Fury")
	
	local clearcasting = jps.buff("Clearcasting")
	local berserk = jps.buff("Berserk")
	local tigersFury = jps.buff("Tiger's fury")
	local predatorySwiftness = jps.buff("Predatory Swiftness")
	local cenarionStacks = jps.buffStacks(108373) -- jps.buffStacks("Dream of Cenarius") 
	
	local ripDuration = jps.myDebuffDuration("Rip")
	local rakeDuration = jps.myDebuffDuration("Rake")
	local savageRoarDuration = jps.buffDuration("Savage Roar")
	local thrashDuration = jps.myDebuffDuration("Thrash")
	local predatorySwiftnessDuration = jps.buffDuration("Predatory Swiftness")
	
	
	-- Berserk makes every ability cost 50% less energy, so we can't hardcode these values (more future proof this way, anyways).
	local thrashCost = ({ GetSpellInfo('Thrash') })[4]
	local swipeCost = ({ GetSpellInfo('Swipe') })[4]
	local shredCost = ({ GetSpellInfo('Shred') })[4]
	local ripCost = ({ GetSpellInfo('Rip') })[4]
	local ravageCost = ({ GetSpellInfo('Ravage') })[4]
	local rakeCost = ({ GetSpellInfo('Rake') })[4]
	
	local maxLevel = (UnitLevel("player") == 90)
	
	local spellTable = {
		
	-- Cat Form 
		{ "Cat Form",  not jps.buff("Cat Form") },
		
	-- Bail if not in melee range. 
		{ nil,  IsSpellInRange("Shred", "target") == 0 },
		
	-- Survival Instincts 
		{ "Survival Instincts", jps.hp() < .5 },
		
	-- Healthstone if you get low. 
		{ "Healthstone", jps.hp() < .5 and GetItemCount("Healthstone", 0, 1) > 0 },
		
	-- Barkskin 
		{ "Barkskin", jps.hp() < .6 },
		
	-- Interrupts 
		{ "Skull Bash",  jps.ShouldKick()  and jps.Interrupts },
		
	-- Talent based stun. 
		{ "Mighty Bash",  jps.ShouldKick()  and jps.Interrupts },
		
	-- Savage Roar should be kept up at all times. 
		{ "Savage Roar",  savageRoarDuration == 0 },
		
	-- Healing Touch when we have Predatory Swiftness, less than 2 cenarion stacks, and the combo points to use the damage buff.
		{ "Healing Touch",  predatorySwiftness and cenarionStacks < 2 and cp >= 4 and maxLevel },
		
	-- Healing Touch to use up Predatory Swiftness before it falls off if we have less than 2 cenarion stacks and low combo points and energy. 
		{ "Healing Touch",  predatorySwiftness and predatorySwiftnessDuration <= 1 and not clearcasting  and energy < 45  and cenarionStacks < 2  and cp < 4 and maxLevel },
		
	-- Healing Touch whenever we have Nature's Swiftness. (talent based) 
		{ "Healing Touch",  jps.buff("Nature's Swiftness") and cenarionStacks < 2 },
		
	-- Tiger's Fury when we're low on energy. 
		{ "Tiger's Fury",  jps.UseCDs and energy <= 35  and not clearcasting },
		
	-- Berserk when we have Tiger's Fury 
		{ "Berserk",  jps.UseCDs and jps.buff("Tiger's Fury") },
		
	-- Nature's Vigil if Berserk buff in on. 
		{ "Nature's Vigil",  jps.UseCDs and berserk },
		
	-- Incarnation if Berserk buff in on. (talent specific) 
		{ "Incarnation",  jps.UseCDs and berserk },
		
	-- Engineers may have synapse springs on their gloves (slot 10). 
		{ jps.useSynapseSprings(),  jps.useSynapseSprings() ~= "" and jps.UseCDs and tigersFury },
		
	-- On-Use Trinkets if Berserk buff in on. 
		{ jps.useTrinket(0),  jps.UseCDs },
		{ jps.useTrinket(1),  jps.UseCDs },
		
	-- DPS Racial if Berserk buff in on. 
		{ jps.DPSRacial,  jps.UseCDs },
		
	-- Lifeblood if Berserk buff in on. (requires herbalism) 
		{ "Lifeblood", jps.UseCDs },
		
	-- Treants (talent specific) 
		{ "Force of Nature" },
		
	-- Faerie Fire single-target when we know it's going to be a longer fight. 
		{ "Faerie Fire",  not jps.MultiTarget and energy <= 60 and not jps.debuff("Weakened Armor") and UnitHealth("target") > (UnitHealth("player") * .8) },
		
	-- Ferocious Bite if we're in execute phase and Rip is about the fall off. 
		{ "Ferocious Bite",  not jps.MultiTarget and executePhase  and cp > 0  and ripDuration <= 2  and ripDuration > 0 },
		
	-- Multi-target only: Thrash debuff should be kept up at all times. 
		{ "Thrash",  jps.MultiTarget and energy >= thrashCost and thrashDuration < 2 },
		
	-- Multi-target only: Swipe is the base AoE spell. (Assume there's a good reason to limit at 51+?) 
		{ "Swipe",  jps.MultiTarget and energy >= swipeCost },
		
	-- Thrash if we're clearcasting, it's debuff is about to run out, and we have no cenarion stacks. 
		{ "Thrash",  clearcasting  and thrashDuration < 3  and cenarionStacks == 0 },
		
	-- Savage Roar 
		{ "Savage Roar",  savageRoarDuration <= 1  or (savageRoarDuration <= 3  and cp > 0)  and executePhase },
		
	-- Nature's Swiftness 
		{ "Nature's Swiftness", cenarionStacks == 0  and not predatorySwiftness  and cp >= 5  and executePhase },
		
	-- Rip 
		{ "Rip",  not jps.MultiTarget and (energy >= ripCost or clearcasting) and cp >= 5  and cenarionStacks > 0  and executePhase  and ripDuration < 4 },
		
	-- stronger rip detection	  -- Ferocious Bite 
		{ "Ferocious Bite",  not jps.MultiTarget and executePhase  and cp == 5  and ripDuration > 0 },
		
	-- Rip 
		{ "Rip",  not jps.MultiTarget and (energy >= ripCost or clearcasting) and cp >= 5  and ripDuration < 2  and cenarionStacks > 0 },
		
	-- Savage Roar 
		{ "Savage Roar",  savageRoarDuration <= 1  or (savageRoarDuration <= 3  and cp > 0) },
		
	-- Nature's Swiftness 
		{ "Nature's Swiftness", cenarionStacks == 0  and not predatorySwiftness  and cp >= 5  and ripDuration < 3  and (berserk  or ripDuration <= tigersFuryCD)  and not executePhase and maxLevel },
		
	-- Temporary for leveling 
		{ "Nature's Swiftness", not predatorySwiftness and not maxLevel },
		
	-- Rip 
		{ "Rip",  not jps.MultiTarget and (energy >= ripCost or clearcasting) and cp >= 5  and ripDuration < 2  and (berserk  or ripDuration < tigersFuryCD) },
		
	-- Thrash 
		{ "Thrash",  clearcasting  and thrashDuration < 3 },
		
	-- Savage Roar 
		{ "Savage Roar",  savageRoarDuration <= 6  and cp >= 5  and ripDuration > 4 },
		
	-- Ferocious Bite 
		{ "Ferocious Bite",  not jps.MultiTarget and cp >= 5  and ripDuration > 4 },
		
	-- Rake 
		{ "Rake",  not jps.MultiTarget and (energy >= rakeCost or clearcasting) and cenarionStacks > 0  and rakeDuration < 3 },
		
	-- Rake 
		{ "Rake",  not jps.MultiTarget and (energy >= rakeCost or clearcasting) and rakeDuration < 3  and (berserk  or tigersFuryCD + .8 >= rakeDuration) },
		
	-- Shred 
		{ "Shred",  not jps.MultiTarget and clearcasting and jps.isBehind },
		
	-- Shred 
		{ "Shred",  not jps.MultiTarget and predatorySwiftnessDuration > 1  and not (energy + (energyPerSec * (predatorySwiftnessDuration - 1)) < (4 - cp) * 20) and jps.isBehind },
		
	-- Shred 
		{ "Shred",  not jps.MultiTarget and energy >= shredCost and (  (cp < 5  and ripDuration < 3)  or (cp == 0  and savageRoarDuration < 2 )  ) and jps.isBehind },
		
	-- Thrash 
		{ "Thrash",  cp >= 5  and energy >= thrashCost and thrashDuration < 6  and (tigersFury  or berserk) },
		
	-- Thrash 
		{ "Thrash",  cp >= 5  and energy >= thrashCost and thrashDuration < 6  and tigersFuryCD <= 3 },
		
	-- Thrash 
		{ "Thrash",  cp >= 5  and energy >= thrashCost and thrashDuration < 6  and energy >= 100 - energyPerSec },
		
	-- Shred 
		{ "Shred",  not jps.MultiTarget and energy >= shredCost and (tigersFury  or berserk)  and jps.isBehind },
		
	-- Shred 
		{ "Shred",  not jps.MultiTarget and energy >= shredCost and tigersFuryCD <= 3  and jps.isBehind },
		
	-- Shred 
		{ "Shred",  not jps.MultiTarget and energy >= 100 - (energyPerSec * 2)  and jps.isBehind }, 
	-- Mangle if not behind
		{ "Mangle",  not jps.MultiTarget and jps.isNotBehind }  
	}

	spell,target = parseSpellTable(spellTable)
	return spell,target

end	,"Default PvE",true,false)

-------------------------------
-- Simcraft druid-FERAL PCMD
-------------------------------

local fillerTable = {
	{druid.spells.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druid.spells.rake)) > 3 and jps.dotPower(1822) >= 100'},
	{druid.spells.shred, 'jps.buff(druid.spells.omenOfClarity) and not jps.buff(druid.spells.kingOfTheJungle)'},
	{druid.spells.shred, 'jps.buff(druid.spells.berserk) and not jps.buff(druid.spells.kingOfTheJungle)'},
	{druid.spells.shred, 'druid.energyRegen() > 15 and not jps.buff(druid.spells.kingOfTheJungle)'},
	{druid.spells.mangle, 'not jps.buff(druid.spells.kingOfTheJungle)'}
}

local spellTable = {
      
-- buffs
	{nil, 'IsControlKeyDown() and not GetCurrentKeyBoardFocus()'},
	{druid.spells.barksin, 'jps.hp("player") < 0.5'},
	{druid.spells.markOfTheWild, 'not jps.hasStatsBuff("player") and not jps.buff("Cat Form")'},
	{jps.useBagItem(5512), 'jps.hp("player") < 0.65' }, -- Healthstone
	{jps.useBagItem(5512), 'jps.hp("player") < 0.90 and jps.debuff("weak ancient barrier")' }, --malk barrier
	{jps.useBagItem(5512), 'jps.hp("player") < 0.99 and jps.debuff("ancient barrier")' }, --malk barrier
	{jps.useBagItem(86569), 'not jps.buff("Flask of the spring blossom") and not jps.buff("Crystal of Insanity")'},

	{ "Cat Form", 'not jps.buff("Cat Form")'},


-- cooldowns

	{druid.spells.skullBashCat, 'jps.Interrupts and jps.ShouldKick("target")' },
	{druid.spells.arcaneTorrent, 'jps.Interrupts and jps.ShouldKick("target") and IsSpellInRange("Shred", "target") == 1' },
	{druid.spells.forceOfNature, 'select(1,GetSpellCharges(druid.spells.forceOfNature))==3'},
	{druid.spells.forceOfNature, 'jps.buff(druid.spells.runeOfReorigination) and jps.buffDuration(druid.spells.runeOfReorigination) < 2'},
	{druid.spells.forceOfNature, 'jps.buff(druid.spells.vicious) and jps.buffDuration(druid.spells.vicious) < 2'},
	{druid.spells.forceOfNature, 'jps.TimeToDie("target") < 20'},


	{'nested' , 'not jps.MultiTarget', 
		{
			{druid.spells.ravage, 'jps.buff(druid.spells.stealthed)' },
			{druid.spells.ferociousBite, 'jps.myDebuff(druid.spells.rip) and jps.myDebuffDuration(druid.spells.rip) <= 3 and jps.hp("target") <= 0.25' },
			{druid.spells.faerieFire, 'jps.debuffStacks(druid.spells.weakenedArmor) < 3' },
			{druid.spells.healingTouch, 'jps.talentInfo(druid.spells.dreamOfCenarius) and jps.buff(druid.spells.predatorySwiftness) and not jps.buff(druid.spells.dreamOfCenarius) and jps.buffDuration(druid.spells.predatorySwiftness) < 1.5' },
			{druid.spells.healingTouch, 'jps.talentInfo(druid.spells.dreamOfCenarius) and jps.buff(druid.spells.predatorySwiftness) and not jps.buff(druid.spells.dreamOfCenarius) and druid.cp() >= 4' },
			{druid.spells.savageRoar, 'not jps.buff(druid.spells.savageRoar)' },
		}
	},


	{ "nested",'IsSpellInRange("Shred", "target") == 1 and jps.UseCDs',
		{	
			{jps.getDPSRacial(), 'jps.UseCDs' },
			{druid.spells.tigersFury, 'druid.energy() <= 35 and not jps.buff(druid.spells.omenOfClarity)' },
			{druid.spells.berserk, 'jps.buff(druid.spells.tigersFury)' },
			{druid.spells.berserk, 'jps.TimeToDie("target") < 18 and jps.cooldown(druid.spells.tigersFury) > 6' },
			{"Lifeblood", 'jps.UseCDs' },
			{jps.useTrinket(0), 'jps.UseCDs' },
			{jps.useTrinket(1), 'jps.UseCDs' },	
		} 
	},
	

-- multitarget target 
	
	{'nested' , 'jps.MultiTarget',
		{
			{druid.spells.faerieFire, 'jps.debuffStacks(druid.spells.weakenedArmor) < 3' },
			{druid.spells.savageRoar, 'not jps.buff(druid.spells.savageRoar)' },
			{druid.spells.savageRoar, 'jps.buffDuration(druid.spells.savageRoar) < 3 and druid.cp() > 0' },
		
			{ {"macro","/use 10"}, 'jps.useSynapseSprings() ~= "" and jps.UseCDs' },
			{druid.spells.bloodFury, 'jps.buff(druid.spells.tigersFury)' },
			{druid.spells.berserking, 'jps.buff(druid.spells.tigersFury)' },
			{druid.spells.arcaneTorrent, 'jps.buff(druid.spells.tigersFury)' },
			{druid.spells.tigersFury, 'druid.energy() <= 35 and  not jps.buff(druid.spells.omenOfClarity)' },
			{druid.spells.berserk, 'jps.buff(druid.spells.tigersFury)' },
			--{druid.spells.poolResource,druid.spells.forNext==1, 'onCD' },
			{druid.spells.thrashCat, 'jps.buff(druid.spells.runeOfReorigination)' },
			--[[ need edit: {druid.spells.poolResource,druid.spells.wait==0.1,druid.spells.forNext==1 ]--, 'onCD' }, ]]--
			{druid.spells.thrashCat, 'jps.myDebuffDuration(druid.spells.thrashCat) < 3' },
			{druid.spells.thrashCat, 'jps.buff(druid.spells.tigersFury) and jps.myDebuffDuration(druid.spells.thrashCat) < 9' },
			{druid.spells.savageRoar, 'jps.buffDuration(druid.spells.savageRoar) < 9 and druid.cp() >= 5' },
			{druid.spells.rip, 'druid.cp() >= 5' },
			{druid.spells.rake, 'jps.buff(druid.spells.runeOfReorigination) and jps.myDebuffDuration(druid.spells.rake) < 3 and jps.TimeToDie("target") >= 15' },
			{druid.spells.swipeCat, 'jps.buffDuration(druid.spells.savageRoar) <= 5' },
			{druid.spells.swipeCat, 'jps.buff(druid.spells.tigersFury)' },
			{druid.spells.swipeCat, 'jps.buff(druid.spells.berserk)'},
			{druid.spells.swipeCat, 'jps.cooldown(druid.spells.tigersFury) < 3' },
			{druid.spells.swipeCat, 'jps.buff(druid.spells.omenOfClarity)' },
			{druid.spells.swipeCat, 'onCD' },
		}
	},
	
-- single target
	{'nested' , 'not jps.MultiTarget', 	
		{
			{ {"macro","/use 10"}, 'jps.useSynapseSprings() ~= "" and jps.UseCDs' },
			{druid.spells.thrashCat, 'jps.buff(druid.spells.omenOfClarity) and jps.myDebuffDuration(druid.spells.thrashCat) < 3 and jps.TimeToDie("target") >= 6' },
			{druid.spells.ferociousBite, 'jps.TimeToDie("target") <= 1 and druid.cp() >= 3' },
			{druid.spells.savageRoar, 'jps.buffDuration(druid.spells.savageRoar) <= 3 and druid.cp() > 0 and jps.hp("target") < 0.25' },
			{druid.spells.rip, 'druid.cp() >= 5 and jps.dotPower(1079) >= 115 and jps.TimeToDie("target") > 30' }, 
			{druid.spells.rip, 'druid.cp() >= 4 and jps.dotPower(1079) >= 95 and jps.TimeToDie("target") > 30 and jps.buff(druid.spells.runeOfReorigination) and jps.buffDuration(druid.spells.runeOfReorigination) <= 1.5'},
		--	{druid.spells.poolResource, 'druid.cp() >= 5 and jps.hp("target") <= 0.25 and jps.myDebuff(druid.spells.rip) and  not (druid.energy() >= 50 or (jps.buff(druid.spells.berserk) and druid.energy() >= 25))' },
			{druid.spells.ferociousBite, 'druid.cp() >= 5 and jps.myDebuff(druid.spells.rip) and jps.hp("target") <= 0.25' },
			{druid.spells.rip, 'druid.cp() >= 5 and jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druid.spells.rip) < 2 and jps.buff(druid.spells.berserk)' },
			
			{druid.spells.rip, 'druid.cp() >= 5 and jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druid.spells.rip) < 2 and jps.add(jps.myDebuffDuration(druid.spells.rip),1.9) <= jps.cooldown(druid.spells.tigersFury)' },
			{druid.spells.rip, 'druid.cp() >= 5 and jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druid.spells.rip) == 0' },
			{druid.spells.savageRoar, 'jps.buffDuration(druid.spells.savageRoar) <= 3 and druid.cp() > 0 and jps.add(jps.buffDuration(druid.spells.savageRoar),2) > jps.myDebuffDuration(druid.spells.rip)' },
			{druid.spells.savageRoar, 'jps.buffDuration(druid.spells.savageRoar) <= 6 and druid.cp() >= 5 and jps.add(jps.buffDuration(druid.spells.savageRoar),2) <= jps.myDebuffDuration(druid.spells.rip) and jps.myDebuff(druid.spells.rip)' },
			{druid.spells.savageRoar, 'jps.buffDuration(druid.spells.savageRoar) <= 12 and druid.cp() >= 5 and druid.timeToMax() <= 1 and jps.buffDuration(druid.spells.savageRoar) <= jps.add(jps.myDebuffDuration(druid.spells.rip),6) and jps.myDebuff(druid.spells.rip)' },
			{druid.spells.rake, 'jps.buff(druid.spells.runeOfReorigination) and jps.myDebuffDuration(druid.spells.rake) < 9 and jps.buffDuration(druid.spells.runeOfReorigination) <= 1.5' },
			{druid.spells.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druid.spells.rake)) > 3 and jps.dotPower(1822) > 100' },
			{druid.spells.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druid.spells.rake)) > 3 and jps.myDebuffDuration(druid.spells.rake) < 3 and jps.dotPower(1822) >= 75' },
			{druid.spells.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druid.spells.rake)) > 3 and jps.myDebuffDuration(druid.spells.rake) < 3 and jps.dotPower(1822) == 0' },
			
			--{druid.spells.poolResource,druid.spells.forNext==1, 'onCD' },
			{druid.spells.thrashCat, 'jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druid.spells.thrashCat) < 3 and jps.myDebuffDuration(druid.spells.rip) >= 8 and jps.buffDuration(druid.spells.savageRoar) >= 12' },
			{druid.spells.thrashCat, 'jps.buff(druid.spells.berserk)' },
			{druid.spells.thrashCat, 'druid.cp() >= 5 and jps.myDebuff(druid.spells.rip)' },
		
			{druid.spells.thrashCat, 'jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druid.spells.thrashCat) < 3 and jps.myDebuffDuration(druid.spells.rip) >= 8 and jps.buffDuration(druid.spells.savageRoar) >= 12 and jps.myDebuff(druid.spells.rip)' },
		
			--{druid.spells.poolResource,druid.spells.forNext==1, 'onCD' },
			{druid.spells.thrashCat, 'jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druid.spells.thrashCat) < 9 and jps.buff(druid.spells.runeOfReorigination) and jps.buffDuration(druid.spells.runeOfReorigination) <= 1.5 and jps.myDebuff(druid.spells.rip)' },
			--{druid.spells.poolResource, 'druid.cp() >= 5 and  not (druid.timeToMax() <= 1 or (jps.buff(druid.spells.berserk) and druid.energy() >= 25) or (jps.buff(druid.spells.feralRage) and jps.buffDuration(druid.spells.feralRage) <= 1)) and jps.myDebuff(druid.spells.rip)' },
			{druid.spells.ferociousBite, 'druid.cp() >= 5 and jps.myDebuff(druid.spells.rip)' },
			{druid.spells.ravage, "onCD"},
		}
	},

	{'nested' , 'not jps.MultiTarget and jps.buff(druid.spells.omenOfClarity)', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.buff(druid.spells.feralFury)', fillerTable },
	{'nested' , 'not jps.MultiTarget and druid.cp() < 5 and jps.myDebuffDuration(druid.spells.rip) < 3', fillerTable },
	{'nested' , 'not jps.MultiTarget and druid.cp() < 3 and jps.buffDuration(druid.spells.savageRoar) < 2', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.TimeToDie("target") < 8.5', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.buff(druid.spells.tigersFury)', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.buff(druid.spells.berserk)', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.cooldown(druid.spells.tigersFury) <= 3', fillerTable },
	{'nested' , 'not jps.MultiTarget and druid.timeToMax() <= 1', fillerTable },
	{druid.spells.mangle, 'onCD'},

}

jps.registerRotation("DRUID","FERAL",function()
	local spell = nil
	local target = nil
	spell,target = parseStaticSpellTable(spellTable)
	return spell,target
end, "Simcraft druid-FERAL")

