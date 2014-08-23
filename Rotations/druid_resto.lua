--TO DO : tranquility detection

--[[[
@rotation Legacy Rotation
@class DRUID
@spec RESTORATION
@description 
Makes you Top Healer...until you run out of mana. You have to use Innervate and Tranquility manually![br]
]]--

jps.registerStaticTable("DRUID","RESTORATION",{
    -- rebirth Ctrl-key + mouseover
    { druid.spells.rebirth, 'IsControlKeyDown() ~= nil and UnitIsDeadOrGhost("mouseover") ~= nil and IsSpellInRange("rebirth", "mouseover")', "mouseover" },
    
    -- Buffs
    { druid.spells.markOfTheWild, 'not jps.buff(druid.spells.markOfTheWild)', player },
    
    -- CDs
    { druid.spells.barkskin, 'jps.hp() < 0.50' },
    { druid.spells.incarnation, 'IsShiftKeyDown() ~= nil and GetCurrentKeyBoardFocus() == nil' },
    
    druid.dispel,
    { druid.spells.lifebloom, 'jps.buffDuration(druid.spells.lifebloom,jps.findMeATank()) < 3 or jps.buffStacks(druid.spells.lifebloom,jps.findMeATank()) < 3', jps.findMeATank },
    { druid.spells.swiftmend, 'druid.legacyDefaultHP() < 0.85 and (jps.buff(druid.spells.rejuvination,druid.legacyDefaultTarget()) or jps.buff(druid.spells.regrowth,druid.legacyDefaultTarget()))', druid.legacyDefaultTarget },
    { druid.spells.wildGrowth, 'druid.legacyDefaultHP() < 0.95 and jps.MultiTarget', druid.legacyDefaultTarget },
    { druid.spells.rejuvination, 'druid.legacyDefaultHP() < 0.95 and not jps.buff(druid.spells.rejuvination,druid.legacyDefaultTarget())', druid.legacyDefaultTarget },
    { druid.spells.rejuvination, 'jps.buffDuration(druid.spells.rejuvination,jps.findMeATank()) < 3', jps.findMeATank },
    { druid.spells.regrowth, 'druid.legacyDefaultHP() < 0.55 or jps.buff(druid.spells.clearcasting)', druid.legacyDefaultTarget },
    { druid.spells.naturesSwiftness, 'druid.legacyDefaultHP() < 0.40' },
    { druid.spells.healingTouch, '(jps.buff(druid.spells.naturesSwiftness) or not jps.Moving) and druid.legacyDefaultHP() < 0.55', druid.legacyDefaultTarget },    
    { druid.spells.nourish, 'druid.legacyDefaultHP() < 0.85', druid.legacyDefaultTarget },
}, "Legacy Rotation")


--[[[
@rotation Advanced Rotation
@class DRUID
@spec RESTORATION
@talents UY!002010!gUTSPF
@author Kirk24788
@description 
This is a Raid-Rotation, don't use it for PvP!. It's focus is mana conserve and minimum overheal. You might not end up as top healer but you shouldn't
run out of mana. Don't worry, if there is something to heal, it will heal! Use Tranquility manually.
[br]
Modifiers:[br]
[*] [code]SHIFT[/code]: Place Wild Mushroom[br]
[*] [code]CTRL-SHIFT[/code]: Cast Wild Mushroom: Bloom[br]
]]--

jps.registerStaticTable("DRUID","RESTORATION",{
    -- rebirth Ctrl-key + mouseover
    { druid.spells.rebirth, 'IsControlKeyDown() ~= nil and UnitIsDeadOrGhost("target") ~= nil and IsSpellInRange("rebirth", "target")', "target" },
    { druid.spells.rebirth, 'IsControlKeyDown() ~= nil and UnitIsDeadOrGhost("mouseover") ~= nil and IsSpellInRange("rebirth", "mouseover")', "mouseover" },
    
    -- Buffs
    { druid.spells.markOfTheWild, 'not jps.buff(druid.spells.markOfTheWild)', player },
    
    -- CDs
    { druid.spells.barkskin, 'jps.hp() < 0.50' },

    -- Dispel
    druid.dispel,

    -- Wild Mushrooms
    {druid.spells.wildMushroomBloom, 'IsShiftKeyDown() and IsControlKeyDown() and not GetCurrentKeyBoardFocus()' },
    {druid.spells.wildMushroom, 'IsShiftKeyDown() and druid.activeMushrooms() < 3 and not GetCurrentKeyBoardFocus()'  },
    
    -- Innervate
    {druid.spells.innervate, 'jps.mana("player") < 0.75', "player"},
    
    -- Group Heal
    {"nested", 'not jps.Defensive', {
        -- Lifebloom on tank
        { druid.spells.lifebloom, 'jps.buffDuration(druid.spells.lifebloom,jps.findMeATank()) < 3 or jps.buffStacks(druid.spells.lifebloom,jps.findMeATank()) < 3', jps.findMeATank },
        -- Harmony!
        { druid.spells.nourish, 'jps.buffDuration(druid.spells.harmony) < 3', jps.findMeATank },
        -- Group Heal
        { druid.spells.rejuvination, 'jps.hpInc(druid.groupHealTarget()) < 0.80 and not jps.buff(druid.spells.rejuvination,druid.groupHealTarget())', druid.groupHealTarget },
        { druid.spells.swiftmend, 'jps.buff(druid.spells.rejuvination,druid.groupHealTarget()) or jps.buff(druid.spells.regrowth,druid.groupHealTarget())', druid.groupHealTarget },
        { druid.spells.wildGrowth, 'druid.hastSotF() and jps.buff(druid.spells.soulOfTheForrest) or not druid.hastSotF()', druid.groupHealTarget },
    }},

    -- Focus Heal
    {"nested", 'jps.Defensive and druid.focusHealTarget() ~= nil', {
        { druid.spells.regrowth, 'jps.buffDuration(druid.spells.harmony) < 2 and not jps.buff(druid.spells.regrowth, druid.focusHealTarget())', druid.focusHealTarget },
        { druid.spells.nourish, 'jps.buffDuration(druid.spells.harmony) < 3 and jps.buff(druid.spells.regrowth, druid.focusHealTarget())', druid.focusHealTarget },
        { druid.spells.ironbark, 'jps.hp(jps.findMeATank())', jps.findMeATank },
        { druid.spells.lifebloom, 'jps.buffDuration(druid.spells.lifebloom,jps.findMeATank()) < 3 or jps.buffStacks(druid.spells.lifebloom,jps.findMeATank()) < 3', jps.findMeATank },
        { druid.spells.rejuvination, 'jps.buffDuration(druid.spells.rejuvination,druid.focusHealTarget()) < 2', druid.focusHealTarget },
        { druid.spells.swiftmend, 'jps.buff(druid.spells.rejuvination,druid.focusHealTarget()) or jps.buff(druid.spells.regrowth,druid.focusHealTarget())', druid.focusHealTarget },
        { druid.spells.naturesSwiftness, 'jps.hpInc(druid.focusHealTarget()) < 0.40' },
        { druid.spells.healingTouch, 'jps.buff(druid.spells.naturesSwiftness) and jps.hpInc(druid.focusHealTarget()) < 0.55', druid.focusHealTarget },
        { druid.spells.regrowth, 'jps.hpInc(druid.focusHealTarget()) < 0.75 and jps.buff(druid.spells.clearcasting)', druid.focusHealTarget },
        { druid.spells.regrowth, 'jps.hpInc(druid.focusHealTarget()) < 0.55 and not jps.buff(druid.spells.regrowth, druid.focusHealTarget())', druid.focusHealTarget },
        { druid.spells.nourish, 'jps.hpInc(druid.focusHealTarget()) < 0.85', druid.focusHealTarget },
    }},
},"Advanced Rotation")
