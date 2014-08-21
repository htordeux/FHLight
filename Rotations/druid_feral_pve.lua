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
	{druidferal.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druidferal.rake)) > 3 and jps.dotPower(1822) >= 100'},
	{druidferal.shred, 'jps.buff(druidferal.omenOfClarity) and not jps.buff(druidferal.kingOfTheJungle)'},
	{druidferal.shred, 'jps.buff(druidferal.berserk) and not jps.buff(druidferal.kingOfTheJungle)'},
	{druidferal.shred, 'druidferal.energyRegen() > 15 and not jps.buff(druidferal.kingOfTheJungle)'},
	{druidferal.mangle, 'not jps.buff(druidferal.kingOfTheJungle)'}
}

local spellTable = {
      
-- buffs
	{nil, 'IsControlKeyDown() and not GetCurrentKeyBoardFocus()'},
	{druidferal.barksin, 'jps.hp("player") < 0.5'},
	{druidferal.markOfTheWild, 'not jps.hasStatsBuff("player") and not jps.buff("Cat Form")'},
	{jps.useBagItem(5512), 'jps.hp("player") < 0.65' }, -- Healthstone
	{jps.useBagItem(5512), 'jps.hp("player") < 0.90 and jps.debuff("weak ancient barrier")' }, --malk barrier
	{jps.useBagItem(5512), 'jps.hp("player") < 0.99 and jps.debuff("ancient barrier")' }, --malk barrier
	{jps.useBagItem(86569), 'not jps.buff("Flask of the spring blossom") and not jps.buff("Crystal of Insanity")'},

	{ "Cat Form", 'not jps.buff("Cat Form")'},


-- cooldowns

	{druidferal.skullBashCat, 'jps.Interrupts and jps.ShouldKick("target")' },
	{druidferal.arcaneTorrent, 'jps.Interrupts and jps.ShouldKick("target") and IsSpellInRange("Shred", "target") == 1' },
	{druidferal.forceOfNature, 'select(1,GetSpellCharges(druidferal.forceOfNature))==3'},
	{druidferal.forceOfNature, 'jps.buff(druidferal.runeOfReorigination) and jps.buffDuration(druidferal.runeOfReorigination) < 2'},
	{druidferal.forceOfNature, 'jps.buff(druidferal.vicious) and jps.buffDuration(druidferal.vicious) < 2'},
	{druidferal.forceOfNature, 'jps.TimeToDie("target") < 20'},


	{'nested' , 'not jps.MultiTarget', 
		{
			{druidferal.ravage, 'jps.buff(druidferal.stealthed)' },
			{druidferal.ferociousBite, 'jps.myDebuff(druidferal.rip) and jps.myDebuffDuration(druidferal.rip) <= 3 and jps.hp("target") <= 0.25' },
			{druidferal.faerieFire, 'jps.debuffStacks(druidferal.weakenedArmor) < 3' },
			{druidferal.healingTouch, 'jps.talentInfo(druidferal.dreamOfCenarius) and jps.buff(druidferal.predatorySwiftness) and not jps.buff(druidferal.dreamOfCenarius) and jps.buffDuration(druidferal.predatorySwiftness) < 1.5' },
			{druidferal.healingTouch, 'jps.talentInfo(druidferal.dreamOfCenarius) and jps.buff(druidferal.predatorySwiftness) and not jps.buff(druidferal.dreamOfCenarius) and druidferal.cp() >= 4' },
			{druidferal.savageRoar, 'not jps.buff(druidferal.savageRoar)' },
		}
	},


	{ "nested",'IsSpellInRange("Shred", "target") == 1 and jps.UseCDs',
		{	
			{jps.getDPSRacial(), 'jps.UseCDs' },
			{druidferal.tigersFury, 'druidferal.energy() <= 35 and not jps.buff(druidferal.omenOfClarity)' },
			{druidferal.berserk, 'jps.buff(druidferal.tigersFury)' },
			{druidferal.berserk, 'jps.TimeToDie("target") < 18 and jps.cooldown(druidferal.tigersFury) > 6' },
			{"Lifeblood", 'jps.UseCDs' },
			{jps.useTrinket(0), 'jps.UseCDs' },
			{jps.useTrinket(1), 'jps.UseCDs' },	
		} 
	},
	

-- multitarget target 
	
	{'nested' , 'jps.MultiTarget',
		{
			{druidferal.faerieFire, 'jps.debuffStacks(druidferal.weakenedArmor) < 3' },
			{druidferal.savageRoar, 'not jps.buff(druidferal.savageRoar)' },
			{druidferal.savageRoar, 'jps.buffDuration(druidferal.savageRoar) < 3 and druidferal.cp() > 0' },
		
			{ {"macro","/use 10"}, 'jps.useSynapseSprings() ~= "" and jps.UseCDs' },
			{druidferal.bloodFury, 'jps.buff(druidferal.tigersFury)' },
			{druidferal.berserking, 'jps.buff(druidferal.tigersFury)' },
			{druidferal.arcaneTorrent, 'jps.buff(druidferal.tigersFury)' },
			{druidferal.tigersFury, 'druidferal.energy() <= 35 and  not jps.buff(druidferal.omenOfClarity)' },
			{druidferal.berserk, 'jps.buff(druidferal.tigersFury)' },
			--{druidferal.poolResource,druidferal.forNext==1, 'onCD' },
			{druidferal.thrashCat, 'jps.buff(druidferal.runeOfReorigination)' },
			--[[ need edit: {druidferal.poolResource,druidferal.wait==0.1,druidferal.forNext==1 ]--, 'onCD' }, ]]--
			{druidferal.thrashCat, 'jps.myDebuffDuration(druidferal.thrashCat) < 3' },
			{druidferal.thrashCat, 'jps.buff(druidferal.tigersFury) and jps.myDebuffDuration(druidferal.thrashCat) < 9' },
			{druidferal.savageRoar, 'jps.buffDuration(druidferal.savageRoar) < 9 and druidferal.cp() >= 5' },
			{druidferal.rip, 'druidferal.cp() >= 5' },
			{druidferal.rake, 'jps.buff(druidferal.runeOfReorigination) and jps.myDebuffDuration(druidferal.rake) < 3 and jps.TimeToDie("target") >= 15' },
			{druidferal.swipeCat, 'jps.buffDuration(druidferal.savageRoar) <= 5' },
			{druidferal.swipeCat, 'jps.buff(druidferal.tigersFury)' },
			{druidferal.swipeCat, 'jps.buff(druidferal.berserk)'},
			{druidferal.swipeCat, 'jps.cooldown(druidferal.tigersFury) < 3' },
			{druidferal.swipeCat, 'jps.buff(druidferal.omenOfClarity)' },
			{druidferal.swipeCat, 'onCD' },
		}
	},
	
-- single target
	{'nested' , 'not jps.MultiTarget', 	
		{
			{ {"macro","/use 10"}, 'jps.useSynapseSprings() ~= "" and jps.UseCDs' },
			{druidferal.thrashCat, 'jps.buff(druidferal.omenOfClarity) and jps.myDebuffDuration(druidferal.thrashCat) < 3 and jps.TimeToDie("target") >= 6' },
			{druidferal.ferociousBite, 'jps.TimeToDie("target") <= 1 and druidferal.cp() >= 3' },
			{druidferal.savageRoar, 'jps.buffDuration(druidferal.savageRoar) <= 3 and druidferal.cp() > 0 and jps.hp("target") < 0.25' },
			{druidferal.rip, 'druidferal.cp() >= 5 and jps.dotPower(1079) >= 115 and jps.TimeToDie("target") > 30' }, 
			{druidferal.rip, 'druidferal.cp() >= 4 and jps.dotPower(1079) >= 95 and jps.TimeToDie("target") > 30 and jps.buff(druidferal.runeOfReorigination) and jps.buffDuration(druidferal.runeOfReorigination) <= 1.5'},
		--	{druidferal.poolResource, 'druidferal.cp() >= 5 and jps.hp("target") <= 0.25 and jps.myDebuff(druidferal.rip) and  not (druidferal.energy() >= 50 or (jps.buff(druidferal.berserk) and druidferal.energy() >= 25))' },
			{druidferal.ferociousBite, 'druidferal.cp() >= 5 and jps.myDebuff(druidferal.rip) and jps.hp("target") <= 0.25' },
			{druidferal.rip, 'druidferal.cp() >= 5 and jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druidferal.rip) < 2 and jps.buff(druidferal.berserk)' },
			
			{druidferal.rip, 'druidferal.cp() >= 5 and jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druidferal.rip) < 2 and jps.add(jps.myDebuffDuration(druidferal.rip),1.9) <= jps.cooldown(druidferal.tigersFury)' },
			{druidferal.rip, 'druidferal.cp() >= 5 and jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druidferal.rip) == 0' },
			{druidferal.savageRoar, 'jps.buffDuration(druidferal.savageRoar) <= 3 and druidferal.cp() > 0 and jps.add(jps.buffDuration(druidferal.savageRoar),2) > jps.myDebuffDuration(druidferal.rip)' },
			{druidferal.savageRoar, 'jps.buffDuration(druidferal.savageRoar) <= 6 and druidferal.cp() >= 5 and jps.add(jps.buffDuration(druidferal.savageRoar),2) <= jps.myDebuffDuration(druidferal.rip) and jps.myDebuff(druidferal.rip)' },
			{druidferal.savageRoar, 'jps.buffDuration(druidferal.savageRoar) <= 12 and druidferal.cp() >= 5 and druidferal.timeToMax() <= 1 and jps.buffDuration(druidferal.savageRoar) <= jps.add(jps.myDebuffDuration(druidferal.rip),6) and jps.myDebuff(druidferal.rip)' },
			{druidferal.rake, 'jps.buff(druidferal.runeOfReorigination) and jps.myDebuffDuration(druidferal.rake) < 9 and jps.buffDuration(druidferal.runeOfReorigination) <= 1.5' },
			{druidferal.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druidferal.rake)) > 3 and jps.dotPower(1822) > 100' },
			{druidferal.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druidferal.rake)) > 3 and jps.myDebuffDuration(druidferal.rake) < 3 and jps.dotPower(1822) >= 75' },
			{druidferal.rake, 'jps.sub(jps.TimeToDie("target"),jps.myDebuffDuration(druidferal.rake)) > 3 and jps.myDebuffDuration(druidferal.rake) < 3 and jps.dotPower(1822) == 0' },
			
			--{druidferal.poolResource,druidferal.forNext==1, 'onCD' },
			{druidferal.thrashCat, 'jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druidferal.thrashCat) < 3 and jps.myDebuffDuration(druidferal.rip) >= 8 and jps.buffDuration(druidferal.savageRoar) >= 12' },
			{druidferal.thrashCat, 'jps.buff(druidferal.berserk)' },
			{druidferal.thrashCat, 'druidferal.cp() >= 5 and jps.myDebuff(druidferal.rip)' },
		
			{druidferal.thrashCat, 'jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druidferal.thrashCat) < 3 and jps.myDebuffDuration(druidferal.rip) >= 8 and jps.buffDuration(druidferal.savageRoar) >= 12 and jps.myDebuff(druidferal.rip)' },
		
			--{druidferal.poolResource,druidferal.forNext==1, 'onCD' },
			{druidferal.thrashCat, 'jps.TimeToDie("target") >= 6 and jps.myDebuffDuration(druidferal.thrashCat) < 9 and jps.buff(druidferal.runeOfReorigination) and jps.buffDuration(druidferal.runeOfReorigination) <= 1.5 and jps.myDebuff(druidferal.rip)' },
		--	{druidferal.poolResource, 'druidferal.cp() >= 5 and  not (druidferal.timeToMax() <= 1 or (jps.buff(druidferal.berserk) and druidferal.energy() >= 25) or (jps.buff(druidferal.feralRage) and jps.buffDuration(druidferal.feralRage) <= 1)) and jps.myDebuff(druidferal.rip)' },
			{druidferal.ferociousBite, 'druidferal.cp() >= 5 and jps.myDebuff(druidferal.rip)' },
			{druidferal.ravage, "onCD"},
		}
	},

	{'nested' , 'not jps.MultiTarget and jps.buff(druidferal.omenOfClarity)', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.buff(druidferal.feralFury)', fillerTable },
	{'nested' , 'not jps.MultiTarget and druidferal.cp() < 5 and jps.myDebuffDuration(druidferal.rip) < 3', fillerTable },
	{'nested' , 'not jps.MultiTarget and druidferal.cp() < 3 and jps.buffDuration(druidferal.savageRoar) < 2', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.TimeToDie("target") < 8.5', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.buff(druidferal.tigersFury)', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.buff(druidferal.berserk)', fillerTable },
	{'nested' , 'not jps.MultiTarget and jps.cooldown(druidferal.tigersFury) <= 3', fillerTable },
	{'nested' , 'not jps.MultiTarget and druidferal.timeToMax() <= 1', fillerTable },
	{druidferal.mangle, 'onCD'},

}

jps.registerRotation("DRUID","FERAL",function()
	local spell = nil
	local target = nil
	spell,target = parseStaticSpellTable(spellTable)
	return spell,target
end, "Simcraft druid-FERAL")

