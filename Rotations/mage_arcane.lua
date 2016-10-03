--[[[
@module Mage Arcane Rotation
@generated_from mage_arcane.simc
@version 7.0.3
]]--
local spells = jps.spells.mage

-- rating = GetCombatRating(combatRatingIdentifier) -- CR_HASTE_SPELL = 20 for spellpower( number ) 
-- spellHastePercent = UnitSpellHaste("unit" or "name") -- haste value ( in % )


jps.registerRotation("MAGE","ARCANE",function()

local spell = nil
local target = nil

----------------------
-- TARGET ENEMY
----------------------

if canDPS("target") and jps.canAttack("target") then rangedTarget =  "target"
elseif canDPS(TankTarget) and jps.canAttack(TankTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") and jps.canAttack("targettarget") then rangedTarget = "targettarget"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

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

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "mage_arcane" )


