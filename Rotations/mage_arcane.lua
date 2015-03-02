--[[[
@rotation Arcane PVE Simcraft lvl 90 6.0.2
@class mage
@spec arcane
@author pcmd
@description
SimCraft 6.0.2
]]--

-- IsAltKeyDown		--> mage.runeOfPower
-- IsShiftKeyDown	--> mage.prismaticCrystal
-- jps.Defensive	--> mage.iceblock
-- jps.UseCDs		--> mage.iceFloes -- Iceberg
-- jps.MultiTarget	--> mage.netherTempest

-- TO DO
-- Cast frost ward and slow on aggro'd going after nontanks
-- Fix casting frost ward when target is boss

local L = MyLocalizationTable
local spellTable = {}
local canDPS = jps.canDPS
local canHeal = jps.canHeal

if not mage then mage = {} end

mage.alterTime = 108978;
mage.arcaneBarrage = 44425;
mage.arcaneBlast = 30451;
mage.arcaneBrilliance = 1459;
mage.arcaneDalaran = 61316;
mage.arcaneCharge = 114664;
mage.arcaneExplosion = 1449;
mage.arcaneInstability = 166872; -- ??
mage.arcaneMissiles = 5143;
mage.arcaneMissilesBuff = 79683;
mage.arcaneOrb = 153626;
mage.arcanePower = 12042;
mage.arcaneTorrent = 28730; -- Racial blood Elfe
mage.blazingSpeed = 108843;
mage.bloodFury = 20572; -- Orc Racial
mage.berserking = "Berserker";
mage.blink = 1953;
mage.coldSnap = 11958;
mage.coneOfCold = 120;
mage.counterspell = 2139;
mage.evocation = 12051;
mage.frostNova = 122;
mage.iceFloes = 108839; -- Iceberg
mage.iceWard = 111264;
mage.invisibility = 66;
mage.mirrorImage = 55342;
mage.netherTempest = 114923;
mage.overpowered = 155147;
mage.presenceOfMind = 12043; --
mage.prismaticCrystal = 152087; -- Cristal prismatique
mage.runeOfPower = 116011;
mage.supernova = 157980;
mage.slow = 31589;
mage.slowFall = 130;
mage.aspecOfTheFox = 172106; -- Buff Hunt
mage.iceblock = 45438

mage.hasRune = function()
	local hasOne,_ = GetTotemInfo(1)
	local hasSecond,_ = GetTotemInfo(2)
	if hasOne ~= false or hasSecond ~= false then 
		return true
	end
	return false
end

mage.hasCrystal = function()
	return UnitName("target") == L["Prismatic Crystal"]
end

mage.crystalTimeLeft = function()
	if mage.hasCrystal() then
		return jps.mana("target") * 12 
	end
	return 0
end

mage.shouldBurn = function()
	if jps.TimeToDie("target") < jps.mana()*0.35*UnitSpellHaste("player") then return true end
	if jps.cooldown(mage.evocation) <= (jps.mana()-30)*0.3*UnitSpellHaste("player") then return true end
	if (jps.buff(mage.arcanePower) and jps.cooldown(mage.evocation) <= (jps.mana()-30)*0.4*UnitSpellHaste("player")) then return true end
	return false
end

mage.supernovaCharges = function() 
	local cur, max = GetSpellCharges(mage.supernova)
	return cur
end

mage.targetIsCrystal = function()
	if not UnitExists("target") then return false end
	local targetid,_ = jps.UnitGUID("target")
	if targetid == mage.prismaticCrystal then
		return true
	end
	return false
end

mage.shouldUseCDs = function() 
	if jps.TimeToDie("target") < 30 then return false end 
	if jps.debuffStacks(mage.arcaneCharge,"player")==4 and not jps.IsSpellKnown(mage.prismaticCrystal) then return false end 
	if jps.cooldown(mage.prismaticCrystal) > 15 then return false end 
	return false
end

mage.spellhasteCalc = function(no)
	return UnitSpellHaste("player") * no
end

mage.canCastWhileMove = function()
	local cur, max = GetSpellCharges(mage.iceFloes)
	if not cur then return false end
	if cur > 0 or jps.buff(mage.aspecOfTheFox) then
		return true
	end
	return false
end

jps.registerRotation("MAGE","ARCANE", function()

	local spell = nil
	local target = nil

----------------------------
-- LOWESTIMPORTANTUNIT
----------------------------

	local playerAggro = jps.FriendAggro("player")
	local playerhealth = jps.hp("player","abs")
	local playerhealthpct = jps.hp("player")
	local myTank,TankUnit = jps.findAggroInRaid() -- return Table with UnitThreatSituation == 3 (tanking) or == 1 (Overnuking)
	local TankTarget = "target"
	if canHeal(myTank) then TankTarget = myTank.."target" end

---------------------
-- ENEMY TARGET
---------------------

	local isBoss = UnitLevel("target") == -1 or UnitClassification("target") == "elite"
	-- rangedTarget returns "target" by default, sometimes could be friend
	local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

	if canDPS("target") then rangedTarget =  "target"
	elseif canDPS(TankTarget) then rangedTarget = TankTarget 
	elseif canDPS("targettarget") then rangedTarget = "targettarget"
	elseif canDPS("focustarget") then rangedTarget = "focustarget"
	elseif canDPS("mouseover") and UnitAffectingCombat("mouseover") then rangedTarget = "mouseover"
	end
	if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

	--? stop casting if invisible -- buff is 32612
	if jps.Defensive and jps.buff(32612) then SpellStopCasting() end

-----------------------------
--- ROTATION
-----------------------------

spellTable = {

	--? invisibility
	{mage.invisibility, jps.Defensive and playerAggro and isBoss },
	--? arcane barrage if invisibility buff and no aggro
	{mage.arcaneBarrage, jps.buff(32612) and not playerAggro },
	--? slow
	{mage.slow, jps.Defensive and playerAggro and not jps.debuff(mage.slow) and not isBoss },
	--? alter time, first cast
	{mage.alterTime, jps.Defensive and playerhealthpct < 0.75 and playerAggro and not jps.buff(110909) },
	--? alter time, second cast -- buff is 110909
	{mage.alterTime, jps.Defensive and jps.buff(110909) and jps.castEverySeconds(mage.alterTime,5) and jps.Moving },
	--? iceblock
	{mage.iceblock, jps.Defensive and playerhealthpct < 0.20 and not jps.buff(110909) and playerAggro },
	--? frost ward
	{mage.iceWard, canHeal(myTank) and not jps.buff(mage.iceWard,myTank) , myTank },   
	--? iceblock cancel -- buff is 45438
	{mage.iceblock, jps.Defensive and jps.buff(45438) and playerhealthpct > 0.20 and not playerAggro },
	-- iceblock
	{mage.iceblock, jps.Defensive and playerhealthpct < 0.20 and playerAggro },
	
	--interrupts
	{mage.counterspell, jps.ShouldKick("target") },

	--cds defensive
	{mage.slowFall, jps.fallingFor() > 1.5 and not jps.buff(mage.slowFall) ,"player"},
	
	--cds offensive IsAltKeyDown
	{mage.runeOfPower, IsAltKeyDown() == true and GetCurrentKeyBoardFocus() == nil and jps.IsSpellKnown(mage.runeOfPower)},
	{mage.arcaneBrilliance, not jps.buff(mage.arcaneBrilliance),"player" }, 

	{"nested",mage.shouldUseCDs() and jps.canDPS("target") and not jps.Moving,{
		{mage.coldSnap, not jps.buff(mage.presenceOfMind) and jps.cooldown(mage.presenceOfMind) > 75 },
		{mage.mirrorImage},
		{mage.arcanePower},
		{mage.bloodFury},
		{mage.berserking}
		
	}},
	
	--prepare crsytal IsShiftKeyDown
	{"nested", jps.cooldown(mage.prismaticCrystal) == 0 and IsShiftKeyDown(), {
		{mage.prismaticCrystal, jps.debuffStacks(mage.arcaneCharge,"player") >= 4 and jps.cooldown(mage.arcanePower) < 0.5},
		{mage.prismaticCrystal, jps.debuffStacks(mage.arcaneCharge,"player") >= 4 and jps.cooldown(mage.arcanePower) > 45 and jps.glyphInfo(62210)},
	}},
	
	--crystal rotation
	{"nested", jps.MultiTarget and mage.hasCrystal(),{
		{mage.netherTempest,jps.debuffStacks(mage.arcaneCharge,"player") >= 4 and mage.crystalTimeLeft() > 8 and not jps.myDebuff(mage.netherTempest)}
	}},

	--aoe > 5 enemies
	{"nested", jps.MultiTarget, {
		{mage.netherTempest,jps.debuffStacks(mage.arcaneCharge,"player") >= 4 and jps.myDebuffDuration(mage.netherTempest) < 3.5},
		{mage.supernova},
		{mage.arcaneBarrage, jps.debuffStacks(mage.arcaneCharge,"player") >= 4},
		{mage.arcaneOrb,jps.debuffStacks(mage.arcaneCharge,"player") >= 4},
		{mage.coneOfCold,jps.glyphInfo(115705)},
		{mage.arcaneBarrage, jps.debuffStacks(mage.arcaneCharge,"player")==4 },
		{mage.arcaneExplosion}
	}},
	
	-- Moving
	{mage.iceFloes, jps.UseCDs and jps.Moving and not jps.buff(mage.iceFloes) , rangedTarget , "_Iceberg" },
	{mage.iceFloes, jps.UseCDs and mage.shouldBurn() and jps.Moving and not jps.buff(mage.iceFloes) },
	
	--burn
	{"nested",mage.shouldBurn(),{
		{mage.arcaneMissiles, jps.buffStacks(mage.arcaneMissiles)==3 and jps.ChannelTimeLeft("player") == 0 },
		{mage.arcaneMissiles, jps.buff(mage.arcaneInstability) and jps.buffDuration(mage.arcaneInstability) < jps.SpellCastTime(mage.arcaneBlast) and jps.ChannelTimeLeft("player") == 0 },
		{mage.arcaneMissiles, jps.buffStacks(mage.arcaneMissilesBuff) > 0 and mage.targetIsCrystal() },

		{mage.supernova, jps.TimeToDie("target") < 8 or mage.supernovaCharges()==2  },
		{mage.supernova, jps.cooldown(mage.prismaticCrystal) > 24 and jps.IsSpellKnown(mage.prismaticCrystal) },

		{mage.netherTempest, jps.MultiTarget and jps.debuffStacks(mage.arcaneCharge,"player") >= 4 and jps.myDebuffDuration(mage.netherTempest) < 3.5},
		{mage.arcaneOrb, jps.buffStacks(mage.arcaneCharge) < 4 },
		{mage.supernova, mage.targetIsCrystal() },
		{mage.presenceOfMind, jps.mana() > 0.96 and not jps.Moving },
		{mage.arcaneBlast, jps.buffStacks(mage.arcaneCharge)>=4 and jps.mana() > 0.93 , "target" , "Blast_Burn1" },
		{mage.arcaneMissiles, jps.buffStacks(mage.arcaneCharge)>=4 and jps.ChannelTimeLeft("player") == 0 },
		{mage.supernova, jps.mana() < 0.96 },
		
		--{callactionlist,mage.name==mage.conserve, jps.cooldown(mage.evocation)-jps.cooldown(mage.evocation) < 5  },
		{mage.evocation,jps.TimeToDie("target") > 10 and jps.mana() < 0.50  },
		{mage.presenceOfMind, not jps.Moving },
		{mage.arcaneBlast, not jps.Moving or mage.canCastWhileMove() , "target" , "Blast_Burn2" },
	}},

	--low mana
	{mage.arcaneMissiles, jps.buffStacks(mage.arcaneMissilesBuff)==3 or (jps.IsSpellKnown(mage.overpowered) and jps.buff(mage.arcanePower) and jps.buffDuration(mage.arcanePower) < jps.SpellCastTime(mage.arcaneBlast)) and jps.ChannelTimeLeft("player") == 0 },
	{mage.arcaneMissiles, jps.buff(mage.arcaneInstability) and jps.buffDuration(mage.arcaneInstability) < jps.SpellCastTime(mage.arcaneBlast) and jps.ChannelTimeLeft("player") == 0 },
	{mage.arcaneMissiles, jps.buffStacks(mage.arcaneMissilesBuff) > 0 and mage.targetIsCrystal() },

	{mage.netherTempest, jps.MultiTarget and jps.debuffStacks(mage.arcaneCharge,"player") >= 4 and jps.myDebuffDuration(mage.netherTempest) < 3.5},
	{mage.supernova, jps.TimeToDie("target") < 8 },
	{mage.supernova, jps.buff(mage.arcanePower) },
	{mage.supernova, jps.cooldown(mage.prismaticCrystal) > 24 and jps.IsSpellKnown(mage.prismaticCrystal) },

	{mage.arcaneOrb, jps.debuffStacks(mage.arcaneCharge,"player") < 2 },
	{mage.presenceOfMind, jps.mana() > 0.96  and not jps.Moving },
	{mage.arcaneBlast, jps.debuffStacks(mage.arcaneCharge,"player")==4 and jps.mana() > 0.93 , "target" , "Blast_1" },
	{mage.arcaneMissiles, jps.debuffStacks(mage.arcaneCharge,"player")==4 and not jps.IsSpellKnown(mage.overpowered) and jps.ChannelTimeLeft("player") == 0},
	{mage.arcaneMissiles, jps.debuffStacks(mage.arcaneCharge,"player")==4 and jps.cooldown(mage.arcanePower) > mage.spellhasteCalc(10) and jps.ChannelTimeLeft("player") == 0 },
	{mage.supernova, jps.mana() < 0.96 and jps.buffStacks(mage.arcaneMissilesBuff) < 2 and jps.buff(mage.arcanePower)  },
	{mage.supernova, jps.mana() < 0.96 and jps.debuffStacks(mage.arcaneCharge,"player")==4 and jps.buff(mage.arcanePower)  },
	{mage.arcaneBarrage, jps.debuffStacks(mage.arcaneCharge,"player")==4 },
	{mage.presenceOfMind, jps.debuffStacks(mage.arcaneCharge,"player") < 2  and not jps.Moving },
	{mage.arcaneBlast, not jps.Moving or mage.canCastWhileMove() , "target" , "Blast_2" },
	{mage.arcaneBarrage,jps.Moving and jps.buffStacks(mage.arcaneMissilesBuff) == 0},
}
	
	spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "Arcane Mage Default")


-----------------------------
--- ROTATION AOE
-----------------------------


jps.registerRotation("MAGE","ARCANE", function()

spellTable = {

	{mage.netherTempest,jps.debuffStacks(mage.arcaneCharge,"player") >= 4 and jps.myDebuffDuration(mage.netherTempest) < 3.5},
	{mage.supernova},
	{mage.arcaneBarrage, jps.debuffStacks(mage.arcaneCharge,"player") >= 4},
	{mage.arcaneOrb,jps.debuffStacks(mage.arcaneCharge,"player") >= 4},
	{mage.coneOfCold,jps.glyphInfo(115705)},
	{mage.arcaneBarrage, jps.debuffStacks(mage.arcaneCharge,"player")==4 },
	{mage.arcaneExplosion}

}
	
	spell,target = parseSpellTable(spellTable)
	return spell,target
	
end, "Arcane Mage AoE")

