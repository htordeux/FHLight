local spells = jps.spells.mage

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("MAGE","ARCANE",function()

----------------------
-- TARGET ENEMY
----------------------

local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local rangedTarget  = "target"
if PlayerCanDPS("target") then rangedTarget = "target"
elseif PlayerCanAttack(TankTarget) then rangedTarget = TankTarget
elseif PlayerCanAttack("targettarget") then rangedTarget = "targettarget"
elseif PlayerCanAttack("mouseover") then rangedTarget = "mouseover"
end
if PlayerCanAttack(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local targetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

-----------------------------
-- SPELLTABLE
-----------------------------

local spellTable = {

    --BURN PHASE Ensure you have 4 Arcane Charges.
--Activate Arcane Power
    {spells.arcanePower , jps.cooldown(spells.arcanePower) == 0 and not jps.Moving and jps.arcaneCharges() == 4 },
    
    {"nested", jps.buff(spells.arcanePower) , {
--Rune of Power (if talented).
    {spells.runeOfPower },
--Cast Arcane Missiles
    {spells.arcaneMissiles },
--Cast Arcane Blast
    {spells.arcaneBlast },
--Activate Presence of Mind (if talented) for the end of Arcane Power
    {spells.presenceOfMind },
	}},
	
	
	{spells.timeWarp, jps.hp("target") < 0.25 or jps.timeInCombat() > 5 }, -- time_warp,if=target.health.pct<25|time>5
    {spells.mirrorImage , jps.Defensive }, -- mirror_image

	--CONSERVE PHASE
--Rune of Power if it has 2 charges.
    {spells.runeOfPower ,  jps.spellCharges(spells.runeOfPower) == 2 },
    {spells.runeOfPower, jps.buffDuration(spells.runeOfPower) < 2 }, -- rune_of_power,if=buff.rune_of_power.remains<2*spell_haste
--Cast Icon Mark of Aluneth on cooldown.
    {spells.markOfAluneth  },
--Cast Arcane Orb Icon Arcane Orb (if talented) and you currently have no Arcane Charge
    {spells.arcaneOrb , jps.arcaneCharges() == 0 },
--Apply Nether Tempest Icon Nether Tempest (if talented) with 4 stacks of Arcane Charge
    {spells.netherTempest ,  jps.arcaneCharges() == 4 and not jps.myDebuff(spells.netherTempest,"target") },
--Refresh Nether Tempest (if talented) with 4 stacks of Arcane Charge if it has less than 4 seconds remaining
    {spells.netherTempest ,  jps.arcaneCharges() == 4 and jps.myDebuffDuration(spells.netherTempest,"target") < 4},
--Cast Arcane Missiles if you have 3 charges of Arcane Missiles
    {spells.arcaneMissiles , jps.spellCharges(spells.arcaneMissiles) == 3 },
--Cast Arcane Missiles if you are not at 100% Mana and you have 2 or more Arcane Charge
    {spells.arcaneMissiles , jps.arcaneCharges() > 1 },
--Cast Supernova (if talented)
    {spells.supernova },
--Cast Arcane Barrage if you need to regenerate Mana
    {spells.arcaneBarrage , jps.mana() < 0.90 },
--Cast Arcane Explosion if you will hit 3 or more targets
    {spells.arcaneExplosion , jps.MultiTarget },
--Cast Arcane Blast
    {spells.arcaneBlast },

}

	local spell,target = ParseSpellTable(spellTable)
	return spell,target
end, "mage_arcane" )


