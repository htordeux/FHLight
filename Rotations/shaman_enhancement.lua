local spells = jps.spells.shaman

------------------------------------------------------------------------------------------------------
---------------------------------------------- ROTATION ----------------------------------------------
------------------------------------------------------------------------------------------------------

jps.registerRotation("SHAMAN","ENHANCEMENT",function()


local spellTable = {

    {spells.boulderfist},
    {spells.frostbrand},
    {spells.boulderfist},
    {spells.flametongue},
    {spells.feralSpirit},
    {spells.crashLightning},
    {spells.stormstrike},
    {spells.crashLightning},
    {spells.lavaLash},
    {spells.boulderfist},
    {spells.flametongue},
    {spells.lightningBolt},


}

	local spell,target = ParseSpellTable(spellTable)
	return spell,target

end,"shaman enhancement")

