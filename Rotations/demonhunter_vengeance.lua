local spells = jps.spells.demonhunter

local PlayerCanAttack = function(unit)
	return jps.canAttack(unit)
end

local PlayerCanDPS = function(unit)
	return jps.canDPS(unit)
end

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("DEMONHUNTER","VENGEANCE",function()

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

	-- "Frappe infernale" 189110
	{ spells.infernalStrike , jps.spellCharges(189110) == 2 , "target" , "infernalStrike" },
	{ 204596 },

	-- "Planer"
	{ 131347, jps.IsFallingFor(1) , "player" },
	-- "Métamorphose" 187827
	{ spells.metamorphosis , jps.hp("player") < 0.70 , "target" , "Métamorphose" },
	-- "Pointes démoniaques" 203720 -- Physical dmg
	{ spells.demonSpikes , jps.IncomingDamage("player") > 0 , "target" , "demonSpikes" },
	-- "Marques protectrices" 218256 -- Magic dmg
	{ spells.empowerWards , jps.IncomingDamage("player") > 0 , "target" , "empowerWards" },
	-- "Marque enflammée" 204021
	{ spells.fieryBrand , jps.IncomingDamage("player") > 0 and jps.hp("player") < 0.70 , "target" , "fieryBrand" },
	
	-- "Tourment" 185245
	{ spells.torment, not jps.PlayerIsTarget() },
	
	-- "Manavore" 183752 -- 15 sec cd
	{ spells.consumeMagic, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) , rangedTarget , "Manavore" },
	-- "Torrent arcanique" 202719 -- 90 sec cd
	{ 202719, jps.ShouldKick(rangedTarget) and jps.canFear(rangedTarget) and jps.cooldown(183752) > 0 , rangedTarget },

	-- "Déchirement d'âme" 207407
	{ spells.soulCarver , true , "target" , "soulCarver" },
	-- "Aura d'immolation" 178740
	{ spells.immolationAura , true , "target" , "immolationAura" },
	-- "Division de l'âme" 228477
	{ spells.soulCleave , jps.powerPain() > 50 , "target" , "soulCleave" },
	-- "Lancer de glaive" 204157
	{ spells.throwGlaive , true , "target" , "throwGlaive" },
	-- "Entaille" 203782
	{ spells.shear , true , "target" , "Entaille" },


}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"Vengeance")