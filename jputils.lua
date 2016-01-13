--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable

---------------------------
-- FUNCTION HARMSPELL For Checking Inrange Enemy
---------------------------

-- isHarmful = IsHarmfulSpell(index, "bookType") or IsHarmfulSpell("name")
-- name, texture, offset, numEntries, isGuild, offspecID = GetSpellTabInfo(tabIndex)
-- tabIndex Number - The index of the tab, ascending from 1.
-- numTabs = GetNumSpellTabs() -- numTabs Number - number of ability tabs in the player's spellbook (e.g. 4 -- "General", "Arcane", "Fire", "Frost") 
-- Name, Subtext = GetSpellBookItemName(index, "bookType") or GetSpellBookItemName("spellName")
-- Name - Name of the spell. (string)
-- skillType, spellId = GetSpellBookItemInfo(index, "bookType") or GetSpellBookItemInfo("spellName") -- spellId - The global spell id (number) 

---------------------------
-- GET CLASS COOLDOWNS
---------------------------

function jps.getDPSRacial()
	-- Trolls n' Orcs
	if jps.DPSRacial ~= nil then return jps.DPSRacial end -- no more checks needed
	if jps.Race == nil then jps.Race = UnitRace("player") end
	if jps.Race == "Troll" then
		return "Berserking"
	elseif jps.Race == "Orc" then
		return "Blood Fury"
	end
	return nil
end

------------------------
-- HEALER ENEMY Table
------------------------

jps.HealerSpellID = {

	-- Priests
	-- [000017] = "PRIEST", -- Power word: Shield (also true for shadow priests)
	[047540] = "PRIEST", -- Penance
	[062618] = "PRIEST", -- Power word: Barrier
	[109964] = "PRIEST", -- Spirit shell
	[047515] = "PRIEST", -- Divine Aegis
	[081700] = "PRIEST", -- Archangel
	[002060] = "PRIEST", -- Greater Heal
	[002061] = "PRIEST", -- Flash Heal
	[014914] = "PRIEST", -- Holy Fire
	[089485] = "PRIEST", -- Inner Focus
	[033206] = "PRIEST", -- Pain Suppression
	[000596] = "PRIEST", -- Prayer of Healing
	[000527] = "PRIEST", -- Purify
	
	-- Holy
	[034861] = "PRIEST", -- Circle of Healing
	[064843] = "PRIEST", -- Divine Hymn
	[047788] = "PRIEST", -- Guardian Spirit
	[000724] = "PRIEST", -- Lightwell
	[088684] = "PRIEST", -- Holy Word: Serenity
	[088685] = "PRIEST", -- Holy Word: Sanctuary

	-- Druids
	[018562] = "DRUID", -- Swiftmend
	[102342] = "DRUID", -- Ironbark
	[033763] = "DRUID", -- Lifebloom
	[088423] = "DRUID", -- Nature's Cure
	[050464] = "DRUID", -- Nourish
	[008936] = "DRUID", -- Regrowth
	[033891] = "DRUID", -- Incarnation: Tree of Life
	[048438] = "DRUID", -- Wild Growth
	[102791] = "DRUID", -- Wild Mushroom Bloom

	-- Shamans
	[00974] = "SHAMAN", -- Earth Shield
	[61295] = "SHAMAN", -- Riptide
	[77472] = "SHAMAN", -- Greater Healing Wave
	[98008] = "SHAMAN", -- Spirit link totem
	[77130] = "SHAMAN", -- Purify Spirit

	-- Paladins
	[20473] = "PALADIN", -- Holy Shock
	-- [85673] = "PALADIN", -- Word of Glory (also true for prot paladins)
	[82327] = "PALADIN", -- Holy radiance
	[53563] = "PALADIN", -- Beacon of Light
	[02812] = "PALADIN", -- Denounce
	[31842] = "PALADIN", -- Divine Favor
	[82326] = "PALADIN", -- Divine Light
	[54428] = "PALADIN", -- Divine Plea
	-- [86669] = "PALADIN", -- Guardian of Ancient Kings (also true for ret paladins)
	[00635] = "PALADIN", -- Holy Light
	[82327] = "PALADIN", -- Holy Radiance
	[85222] = "PALADIN", -- Light of Dawn

	-- Monks
	[115175] = "MONK", -- Soothing Mist
	[115294] = "MONK", -- Mana Tea
	[115310] = "MONK", -- Revival
	[116670] = "MONK", -- Uplift
	[116680] = "MONK", -- Thunder Focus Tea
	[116849] = "MONK", -- Life Cocoon
	[116995] = "MONK", -- Surging mist
	[119611] = "MONK", -- Renewing mist
	[132120] = "MONK", -- Envelopping Mist
}

---------------------------
-- LOSE CONTROL TABLES -- Credits - to LoseControl Addon
---------------------------

jps.SpellControl = {
----------------
-- Death Knight
----------------
[108194] = "CC",			-- Asphyxiate
[115001] = "CC",			-- Remorseless Winter
[47476]  = "Silence",		-- Strangulate
[96294]  = "Root",			-- Chains of Ice (Chilblains)
[45524]  = "Snare",			-- Chains of Ice
[50435]  = "Snare",			-- Chilblains
[115000] = "Snare",			-- Remorseless Winter
[115018] = "Immune",		-- Desecrated Ground
[48707]  = "ImmuneSpell",	-- Anti-Magic Shell
[48792]  = "Other",			-- Icebound Fortitude
[49039]  = "Other",			-- Lichborne

----------------
-- Death Knight Ghoul
----------------

[91800]  = "CC",			-- Gnaw
[91797]  = "CC",			-- Monstrous Blow (Dark Transformation)
[91807]  = "Root",			-- Shambling Rush (Dark Transformation)

----------------
-- Druid
----------------

[33786]  = "CC",			-- Cyclone
[99]     = "CC",			-- Incapacitating Roar
[163505] = "CC",       	 	-- Rake
[22570]  = "CC",			-- Maim
[5211]   = "CC",			-- Mighty Bash
[114238] = "Silence",		-- Fae Silence (Glyph of Fae Silence)
[81261]  = "Silence",		-- Solar Beam
[97547]  = "Silence",		-- Solar Beam
[339]    = "Root",			-- Entangling Roots
[113770] = "Root",			-- Entangling Roots (Force of Nature - Balance Treants)
[45334]  = "Root",			-- Immobilized (Wild Charge - Bear)
[102359] = "Root",			-- Mass Entanglement
[50259]  = "Snare",			-- Dazed (Wild Charge - Cat)
[58180]  = "Snare",			-- Infected Wounds
[61391]  = "Snare",			-- Typhoon
[127797] = "Snare",			-- Ursol's Vortex

----------------
-- Hunter
----------------

[117526] = "CC",			-- Binding Shot
[3355]   = "CC",			-- Freezing Trap
[13809]  = "Snare",			-- Ice Trap 1
[19386]  = "CC",			-- Wyvern Sting
[128405] = "Root",			-- Narrow Escape
[5116]   = "Snare",			-- Concussive Shot
[61394]  = "Snare",			-- Frozen Wake (Glyph of Freezing Trap)
[13810]  = "Snare",			-- Ice Trap 2
[19263]  = "Immune",		-- Deterrence

----------------
-- Hunter Pets
----------------
[24394]  = "CC",		-- Intimidation
[50433]  = "Snare",		-- Ankle Crack (Crocolisk)
[54644]  = "Snare",		-- Frost Breath (Chimaera)
[54216]  = "Other",		-- Master's Call (root and snare immune only)
[137798] = "Other",		-- Reflective Armor Plating

----------------
-- Mage
----------------

[44572]  = "CC",			-- Deep Freeze
[31661]  = "CC",			-- Dragon's Breath
[118]    = "CC",			-- Polymorph
[61305]  = "CC",			-- Polymorph: Black Cat
[28272]  = "CC",			-- Polymorph: Pig
[61721]  = "CC",			-- Polymorph: Rabbit
[61780]  = "CC",			-- Polymorph: Turkey
[28271]  = "CC",			-- Polymorph: Turtle
[82691]  = "CC",			-- Ring of Frost
[140376] = "CC",			-- Ring of Frost
[102051] = "Silence",		-- Frostjaw (also a root)
[122]    = "Root",			-- Frost Nova
[111340] = "Root",			-- Ice Ward
[120]    = "Snare",			-- Cone of Cold
[116]    = "Snare",			-- Frostbolt
[44614]  = "Snare",			-- Frostfire Bolt
[31589]  = "Snare",			-- Slow
[10]	 = "Snare",			-- Blizzard
[45438]  = "Immune",		-- Ice Block
[115760] = "ImmuneSpell",	-- Glyph of Ice Block
[157997] = "CC",			-- Ice Nova
[66309]  = "CC",			-- Ice Nova
[110959] = "Other",			-- Greater Invisibility

----------------
-- Mage Water Elemental
----------------
[33395]  = "Root",		-- Freeze


----------------
-- Monk
----------------

[123393] = "CC",			-- Breath of Fire (Glyph of Breath of Fire)
[119392] = "CC",			-- Charging Ox Wave
[120086] = "CC",			-- Fists of Fury
[119381] = "CC",			-- Leg Sweep
[115078] = "CC",			-- Paralysis
[140023] = "Disarm",		-- Ring of Peace
[137460] = "Silence",		-- Silenced (Ring of Peace)
[116706] = "Root",			-- Disable
[116095] = "Snare",			-- Disable
[118585] = "Snare",			-- Leer of the Ox
[123586] = "Snare",			-- Flying Serpent Kick


----------------
-- Paladin
----------------

[105421] = "CC",			-- Blinding Light
[105593] = "CC",			-- Fist of Justice
[853]    = "CC",			-- Hammer of Justice
[20066]  = "CC",			-- Repentance
[31935]  = "Silence",		-- Avenger's Shield
[110300] = "Snare",			-- Burden of Guilt
[63529]  = "Snare",			-- Dazed - Avenger's Shield
[20170]  = "Snare",			-- Seal of Justice
[642]    = "Immune",		-- Divine Shield
[31821]  = "Other",			-- Aura Mastery
[1022]   = "Other",			-- Hand of Protection

----------------
-- Priest
----------------

[605]    = "CC",			-- Dominate Mind
[88625]  = "CC",			-- Holy Word: Chastise
[64044]  = "CC",			-- Psychic Horror
[8122]   = "CC",			-- Psychic Scream
[9484]   = "CC",			-- Shackle Undead
[87204]  = "CC",			-- Sin and Punishment
[15487]  = "Silence",		-- Silence
[64044]  = "Disarm",		-- Psychic Horror
[87194]  = "Root",			-- Glyph of Mind Blast
[114404] = "Root",			-- Void Tendril's Grasp
[15407]  = "Snare",			-- Mind Flay
[47585]  = "Immune",		-- Dispersion
[114239] = "ImmuneSpell",	-- Phantasm
[586] 	 = "Other",			-- Fade (Aura mastery when glyphed, dunno which id is right)
[159628] = "Other",			-- Fade

----------------
-- Rogue
----------------

[2094]   = "CC",			-- Blind
[1833]   = "CC",			-- Cheap Shot
[1776]   = "CC",			-- Gouge
[408]    = "CC",			-- Kidney Shot
[6770]   = "CC",			-- Sap
[1330]   = "Silence",		-- Garrote - Silence
[3409]   = "Snare",			-- Crippling Poison
[26679]  = "Snare",			-- Deadly Throw
[119696] = "Snare",			-- Debilitation
[31224]  = "ImmuneSpell",	-- Cloak of Shadows
[45182]  = "Other",			-- Cheating Death
[5277]   = "Other",			-- Evasion
[76577]  = "Other",			-- Smoke Bomb
[88611]  = "Other",			-- Smoke Bomb

----------------
-- Shaman
----------------

[77505]  = "CC",			-- Earthquake
[51514]  = "CC",			-- Hex
[118905] = "CC",			-- Static Charge (Capacitor Totem)
[64695]  = "Root",			-- Earthgrab (Earthgrab Totem)
[63685]  = "Root",			-- Freeze (Frozen Power)
[3600]   = "Snare",			-- Earthbind (Earthbind Totem)
[116947] = "Snare",			-- Earthbind (Earthgrab Totem)
[77478]  = "Snare",			-- Earthquake (Glyph of Unstable Earth)
[8056]   = "Snare",			-- Frost Shock
[51490]  = "Snare",			-- Thunderstorm
[8178]   = "ImmuneSpell",	-- Grounding Totem Effect (Grounding Totem)

----------------
-- Shaman Primal Earth Elemental
----------------
[118345] = "CC",		-- Pulverize

----------------
-- Warlock
----------------

[710]    = "CC",			-- Banish
[137143] = "CC",			-- Blood Horror
[5782]   = "CC",			-- Fear
[118699] = "CC",			-- Fear
[130616] = "CC",			-- Fear (Glyph of Fear)
[5484]   = "CC",			-- Howl of Terror
[22703]  = "CC",			-- Infernal Awakening
[6789]   = "CC",			-- Mortal Coil
[30283]  = "CC",			-- Shadowfury
[31117]  = "Silence",		-- Unstable Affliction
[110913] = "Other",			-- Dark Bargain
[104773] = "Other",			-- Unending Resolve

----------------
-- Warlock Pets
----------------
[89766]  = "CC",		-- Axe Toss (Felguard/Wrathguard)
[115268] = "CC",		-- Mesmerize (Shivarra)
[6358]   = "CC",		-- Seduction (Succubus)


----------------
-- Warrior
----------------
[118895] = "CC",			-- Dragon Roar
[5246]   = "CC",			-- Intimidating Shout (aoe)
[132168] = "CC",			-- Shockwave
[107570] = "CC",			-- Storm Bolt
[132169] = "CC",			-- Storm Bolt
[18498]  = "Silence",		-- Silenced - Gag Order (PvE only)
[107566] = "Root",			-- Staggering Shout
[105771] = "Root",			-- Warbringer
[147531] = "Snare",			-- Bloodbath
[1715]   = "Snare",			-- Hamstring
[12323]  = "Snare",			-- Piercing Howl
[129923] = "Snare",			-- Sluggish (Glyph of Hindering Strikes)
[46924]  = "Immune",		-- Bladestorm
[23920]  = "ImmuneSpell",	-- Spell Reflection
[114028] = "ImmuneSpell",	-- Mass Spell Reflection
[18499]  = "Other",			-- Berserker Rage

----------------
-- Other
----------------

[30217]  = "CC",		-- Adamantite Grenade
[67769]  = "CC",		-- Cobalt Frag Bomb
[30216]  = "CC",		-- Fel Iron Bomb
[107079] = "CC",		-- Quaking Palm
[13327]  = "CC",		-- Reckless Charge
[20549]  = "CC",		-- War Stomp
[25046]  = "Silence",		-- Arcane Torrent (Energy)
[28730]  = "Silence",		-- Arcane Torrent (Mana)
[50613]  = "Silence",		-- Arcane Torrent (Runic Power)
[69179]  = "Silence",		-- Arcane Torrent (Rage)
[80483]  = "Silence",		-- Arcane Torrent (Focus)
[129597] = "Silence",		-- Arcane Torrent (Chi)
[39965]  = "Root",		-- Frost Grenade
[55536]  = "Root",		-- Frostweave Net
[13099]  = "Root",		-- Net-o-Matic
[1604]   = "Snare",		-- Dazed

}

--------------------------
-- DEBUFF RBG -- Credits - BigDebuffs Addon
--------------------------

jps.BigDebuff = {
	-- Immunities
	[46924]  = "immunities" , -- Bladestorm
	[642]    = "immunities" , -- Divine Shield
	[19263]  = "immunities" , -- Deterrence
		[148467] = "immunities" , -- Deterrence (Glyph of Mirrored Blades)
	[51690]  = "immunities" , -- Killing Spree
	[115018] = "immunities" , -- Desecrated Ground
	[45438]  = "immunities" , -- Ice Block
	[115760] = "immunities" , -- Glyph of Ice Block
	[157913] = "immunities" , -- Evanesce

	-- Spell Immunities
	[23920]  = "immunities_spells" , -- Spell Reflection
		[114028] = "immunities_spells" , -- Mass Spell Reflection
	[31821]  = "immunities_spells" , -- Devotion Aura
	[31224]  = "immunities_spells" , -- Cloak of Shadows
	[159630] = "immunities_spells" , -- Shadow Magic
	[8178]   = "immunities_spells" , -- Grounding Totem
		[89523]  = "immunities_spells" , -- Grounding Totem (Glyph of Grounding Totem)
	[159652] = "immunities_spells" , -- Glyph of Spiritwalker's Aegis
	[48707]  = "immunities_spells" , -- Anti-Magic Shell
	[104773] = "immunities_spells" , -- Unending Resolve
	[159546] = "immunities_spells" , -- Glyph of Zen Focus
	[159438] = "immunities_spells" , -- Glyph of Enchanted Bark

	-- CC
	[33786]  = "cc" , -- Cyclone
	[605]    = "cc" , -- Dominate Mind (Mind Control)
	[20549]  = "cc" , -- War Stomp
	[107079] = "cc" , -- Quaking Palm
	[129597] = "cc" , -- Arcane Torrent
		[28730]  = "cc" , -- Arcane Torrent
		[25046]  = "cc" , -- Arcane Torrent
		[50613]  = "cc" , -- Arcane Torrent
		[69179]  = "cc" , -- Arcane Torrent
		[155145] = "cc" , -- Arcane Torrent
		[80483]  = "cc" , -- Arcane Torrent
	[155335] = "cc" , -- Touched by Ice
	[5246]   = "cc" , -- Intimidating Shout
	[24394]  = "cc" , -- Intimidation
	[132168] = "cc" , -- Shockwave
	[132169] = "cc" , -- Storm Bolt
	[853]    = "cc" , -- Hammer of Justice
	[10326]  = "cc" , -- Turn Evil
	[20066]  = "cc" , -- Repentance
	[31935]  = "cc" , -- Avengers Shield
	[105421] = "cc" , -- Blinding Light
	[105593] = "cc" , -- Fist of Justice
	[119072] = "cc" , -- Holy Wrath
	[3355]   = "cc" , -- Freezing Trap
	[19386]  = "cc" , -- Wyvern Sting
	[117526] = "cc" , -- Binding Shot
	[408]    = "cc" , -- Kidney Shot
	[1330]   = "cc" , -- Garrote - Silence
	[1776]   = "cc" , -- Gouge
	[1833]   = "cc" , -- Cheap Shot
	[2094]   = "cc" , -- Blind
	[6770]   = "cc" , -- Sap
	[88611]  = "cc" , -- Smoke Bomb
	[8122]   = "cc" , -- Psychic Scream
	[9484]   = "cc" , -- Shackle Undead
	[15487]  = "cc" , -- Silence
	[64044]  = "cc" , -- Psychic Horror
	[87204]  = "cc" , -- Sin and Punishment
	[88625]  = "cc" , -- Holy Word: Chastise
	[47476] = "cc" , -- Strangulate
		[115502] = "cc" , -- Strangulate (Asphyxiate)
	[91797]  = "cc" , -- Monstrous Blow
	[91800]  = "cc" , -- Gnaw
	[108194] = "cc" , -- Asphyxiate
	[115001] = "cc" , -- Remorseless Winter
	[51514]  = "cc" , -- Hex
	[77505]  = "cc" , -- Earthquake
	[118345] = "cc" , -- Pulverize
	[118905] = "cc" , -- Static Charge (Capacitor Totem)
	[118]    = "cc" , -- Polymorph
		[61305]  = "cc" , -- Polymorph Black Cat
		[28272]  = "cc" , -- Polymorph Pig
		[61721]  = "cc" , -- Polymorph Rabbit
		[61780]  = "cc" , -- Polymorph Turkey
		[28271]  = "cc" , -- Polymorph Turtle
	[31661]  = "cc" , -- Dragon's Breath
	[44572]  = "cc" , -- Deep Freeze
	[82691]  = "cc" , -- Ring of Frost
	[102051] = "cc" , -- Frostjaw
	[710]    = "cc" , -- Banish
	[5484]   = "cc" , -- Howl of Terror
	[6358]   = "cc" , -- Seduction
	[6789]   = "cc" , -- Mortal Coil
	[22703]  = "cc" , -- Infernal Awakening
	[30283]  = "cc" , -- Shadowfury
	[31117]  = "cc" , -- Unstable Affliction (Silence)
	[89766]  = "cc" , -- Axe Toss
	[115268] = "cc" , -- Mesmerize
	[118699] = "cc" , -- Fear
	[130616] = "cc" , -- Fear (Glyph of Fear)
	[137143] = "cc" , -- Blood Horror
	[115078] = "cc" , -- Paralysis
	[119381] = "cc" , -- Leg Sweep
	[119392] = "cc" , -- Charging Ox Wave
	[120086] = "cc" , -- Fists of Fury
	[123393] = "cc" , -- Breath of Fire
	[137460] = "cc" , -- Incapacitated
	[99]     = "cc" , -- Incapacitating Roar
	[5211]   = "cc" , -- Mighty Bash
	[22570]  = "cc" , -- Maim
	[81261]  = "cc" , -- Solar Beam
	[114238] = "cc" , -- Fae Silence
	[163505] = "cc" , -- Rake

	-- Defensive Buffs
	[871]    = "buffs_defensive" , -- Shield Wall
	[108271] = "buffs_defensive" , -- Astral Shift
	[157128] = "buffs_defensive" , -- Saved by the Light
	[33206]  = "buffs_defensive" , -- Pain Suppression
	[116849] = "buffs_defensive" , -- Life Cocoon
	[47788]  = "buffs_defensive" , -- Guardian Spirit
	[47585]  = "buffs_defensive" , -- Dispersion
	[122783] = "buffs_defensive" , -- Diffuse Magic
	[178858] = "buffs_defensive" , -- Contender
	[61336]  = "buffs_defensive" , -- Survival Instincts
	[98007]  = "buffs_defensive" , -- Spirit Link
	[118038] = "buffs_defensive" , -- Die by the Sword
	[74001]  = "buffs_defensive" , -- Combat Readiness
	[30823]  = "buffs_defensive" , -- Shamanistic Rage
	[114917] = "buffs_defensive" , -- Stay of Execution
	[114029] = "buffs_defensive" , -- Safeguard
	[5277]   = "buffs_defensive" , -- Evasion
	[49039]  = "buffs_defensive" , -- Lichborne
	[117679] = "buffs_defensive" , -- Incarnation: Tree of Life
	[137562] = "buffs_defensive" , -- Nimble Brew
	[102342] = "buffs_defensive" , -- Ironbark
	[22812]  = "buffs_defensive" , -- Barkskin
	[110913] = "buffs_defensive" , -- Dark Bargain
	[122278] = "buffs_defensive" , -- Dampen Harm
	[53480]  = "buffs_defensive" , -- Roar of Sacrifice
	[55694]  = "buffs_defensive" , -- Enraged Regeneration
	[12975]  = "buffs_defensive" , -- Last Stand
	[1966]   = "buffs_defensive" , -- Feint
	[6940]   = "buffs_defensive" , -- Hand of Sacrifice
	[97463]  = "buffs_defensive" , -- Rallying Cry
	[115176] = "buffs_defensive" , -- Zen Meditation
	[120954] = "buffs_defensive" , -- Fortifying Brew
	[118347] = "buffs_defensive" , -- Reinforce
	[81782]  = "buffs_defensive" , -- Power Word: Barrier
	[30884]  = "buffs_defensive" , -- Nature's Guardian
	[155835] = "buffs_defensive" , -- Bristling Fur
	[62606]  = "buffs_defensive" , -- Savage Defense
	[1022]   = "buffs_defensive" , -- Hand of Protection
	[48743]  = "buffs_defensive" , -- Death Pact
	[31850]  = "buffs_defensive" , -- Ardent Defender
	[114030] = "buffs_defensive" , -- Vigilance
	[498]    = "buffs_defensive" , -- Divine Protection
	[122470] = "buffs_defensive" , -- Touch of Karma
	[48792]  = "buffs_defensive" , -- Icebound Fortitude
	[55233]  = "buffs_defensive" , -- Vampiric Blood
	[114039] = "buffs_defensive" , -- Hand of Purity
	[86659]  = "buffs_defensive" , -- Guardian of Ancient Kings
	[108416] = "buffs_defensive" , -- Sacrificial Pact

	-- Offensive Buffs
	[19574]  = "buffs_offensive" , -- Bestial Wrath
	[84747]  = "buffs_offensive" , -- Deep Insight
	[131894] = "buffs_offensive" , -- A Murder of Crows
	[152151] = "buffs_offensive" , -- Shadow Reflection
	[31842]  = "buffs_offensive" , -- Avenging Wrath
	[114916] = "buffs_offensive" , -- Execution Sentence
	[83853]  = "buffs_offensive" , -- Combustion
	[51690]  = "buffs_offensive" , -- Killing Spree
	[79140]  = "buffs_offensive" , -- Vendetta
	[102560] = "buffs_offensive" , -- Incarnation: Chosen of Elune
	[102543] = "buffs_offensive" , -- Incarnation: King of the Jungle
	[123737] = "buffs_offensive" , -- Heart of the Wild
		[108291] = "buffs_offensive" , -- Heart of the Wild (Balance)
		[108292] = "buffs_offensive" , -- Heart of the Wild (Feral)
		[108293] = "buffs_offensive" , -- Heart of the Wild (Guardian)
		[108294] = "buffs_offensive" , -- Heart of the Wild (Restoration)
	[124974] = "buffs_offensive" , -- Nature's Vigil
	[12472]  = "buffs_offensive" , -- Icy Veins
	[77801]  = "buffs_offensive" , -- Dark Soul
		[113860] = "buffs_offensive" , -- Dark Soul (Misery)
		[113861] = "buffs_offensive" , -- Dark Soul (Knowledge)
		[113858] = "buffs_offensive" , -- Dark Soul (Instability)
	[16166]  = "buffs_offensive" , -- Elemental Mastery
	[114049] = "buffs_offensive" , -- Ascendance
		[114052] = "buffs_offensive" , -- Ascendance (Restoration)
		[114050] = "buffs_offensive" , -- Ascendance (Elemental)
		[114051] = "buffs_offensive" , -- Ascendance (Enhancement)
	[107574] = "buffs_offensive" , -- Avatar
	[51713]  = "buffs_offensive" , -- Shadow Dance
	[13750]  = "buffs_offensive" , -- Adrenaline Rush
	[1719]   = "buffs_offensive" , -- Recklessness
	[84746]  = "buffs_offensive" , -- Moderate Insight
	[112071] = "buffs_offensive" , -- Celestial Alignment
	[106951] = "buffs_offensive" , -- Berserk
	[12042]  = "buffs_offensive" , -- Arcane Power
	[51271]  = "buffs_offensive" , -- Pillar of Frost
	[152279] = "buffs_offensive" , -- Breath of Sindragosa

	[41425]  = "buffs_other" , -- Hypothermia
	[130736] = "buffs_other" , -- Soul Reaper (Blood)
		[114866] = "buffs_other" , -- Soul Reaper (Unholy)
		[130735] = "buffs_other" , -- Soul Reaper (Frost)
	[12043]  = "buffs_other" , -- Presence of Mind
	[16188]  = "buffs_other" , -- Ancestral Swiftness
	[132158] = "buffs_other" , -- Nature's Swiftness
	[6346]   = "buffs_other" , -- Fear Ward
	[77606]  = "buffs_other" , -- Dark Simulacrum
	[172786] = "buffs_other" , -- Drink
		[167152] = "buffs_other" , -- Refreshment
	[114239] = "buffs_other" , -- Phantasm
	[119032] = "buffs_other" , -- Spectral Guise
	[1044]   = "buffs_other" , -- Hand of Freedom
	[10060]  = "buffs_other" , -- Power Infusion
	[5384]   = "buffs_other" , -- Feign Death
	[108978] = "buffs_other" , -- Alter Time
	[170856] = "buffs_other" , -- Nature's Grasp
	[110959] = "buffs_other" , -- Greater Invisibility
	[18499]  = "buffs_other" , -- Berserker Rage	
	[111397] = "buffs_other" , -- Blood Horror (Buff)
	[114896] = "buffs_other" , -- Windwalk Totem

	-- Roots
	[122]    = "roots" , -- Frost Nova
		[33395] = "roots" , -- Freeze
	[339]    = "roots" , -- Entangling Roots
		[113770] = "roots" , -- Entangling Roots
		[170855] = "roots" , -- Entangling Roots (Nature's Grasp)
	[53148]  = "roots" , -- Charge (Hunter)
	[105771] = "roots" , -- Charge (Warrior)
	[63685]  = "roots" , -- Frozen Power
	[64695]  = "roots" , -- Earthgrab Totem
	[87194]  = "roots" , -- Glyph of Mind Blast
	[96294]  = "roots" , -- Chains of Ice
	[102359] = "roots" , -- Mass Entanglement
	[111340] = "roots" , -- Ice Ward
	[114404] = "roots" , -- Void Tendrils
	[116706] = "roots" , -- Disable
	[135373] = "roots" , -- Entrapment
	[136634] = "roots" , -- Narrow Escape
	[55536]  = "roots" , -- Frostweave Net
	[157997] = "roots" , -- Ice Nova
	[45334]  = "roots" , -- Wild Charge
}

--------------------------------------------------------------------
-- FUNCTION RETURNS SPELL ID -- on mouseover item/spell/glyph/aura/buff/Debuff
--------------------------------------------------------------------

local select, UnitBuff, UnitDebuff, UnitAura, tonumber, strfind, hooksecurefunc =
	select, UnitBuff, UnitDebuff, UnitAura, tonumber, strfind, hooksecurefunc
local GetGlyphSocketInfo = GetGlyphSocketInfo

local function addLine(self,id,isItem)
	if isItem then
		self:AddDoubleLine("ItemID:","|cffffffff"..id)
	else
		self:AddDoubleLine("SpellID:","|cffffffff"..id)
	end
	self:Show()
end

hooksecurefunc(GameTooltip, "SetUnitBuff", function(self,...)
	local id = select(11,UnitBuff(...))
	if id then addLine(self,id) end
end)

hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self,...)
	local id = select(11,UnitDebuff(...))
	if id then addLine(self,id) end
end)

hooksecurefunc(GameTooltip, "SetUnitAura", function(self,...)
	local id = select(11,UnitAura(...))
	if id then addLine(self,id) end
end)

-- local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(i) 
hooksecurefunc(GameTooltip, "SetGlyph", function(self,...)
	local id = select(4,GetGlyphSocketInfo(...))
	if id then addLine(self,id) end
end)

GameTooltip:HookScript("OnTooltipSetSpell", function(self)
	local id = select(3,self:GetSpell())
	if id then addLine(self,id) end
end)

hooksecurefunc("SetItemRef", function(link, ...)
	local id = tonumber(link:match("spell:(%d+)"))
	if id then addLine(ItemRefTooltip,id) end
end)

local function attachItemTooltip(self)
	local link = select(2,self:GetItem())
	if not link then return end
	local id = select(3,strfind(link, "^|%x+|Hitem:(%-?%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%-?%d+)"))
	if id then addLine(self,id,true) end
end

GameTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)

--------------------------------------------------------------------
-- FUNCTION RETURNS SPEC OF UNITFRAME WHEN MOUSEOVER THE FRAME
--------------------------------------------------------------------

--[[
local _G = _G 

local function InspectTalents(inspect)
	local numLines, linesNeeded = GameTooltip:NumLines()
	local unit = select(2, GameTooltip:GetUnit())
	if not unit then return end
	local guild, guildRankName, guildRankIndex = GetGuildInfo(unit)
	local isInRange = CheckInteractDistance(unit, 1)
	local UnitIsPlayerControlled = UnitPlayerControlled(unit)

	if UnitIsPlayerControlled == false then return end

	for i=1, GetNumSpecGroups(unit) do -- check for Dualspec
		local group = GetActiveSpecGroup(unit) --check which Spec is active
		if group == 1 then
			activegroup = "|cffddff55<|r"
		elseif group == 2 then
			activegroup = "|cFFdddd55<<|r"
		end
	end

	local specID = GetInspectSpecialization(unit)
	local id, name, description, icon, background, role, class = GetSpecializationInfoByID(specID)

	local customRole
	if role == "HEALER" then
		customRole = "Heal"
	elseif role == "DAMAGER" then
		customRole = "Damage"
	elseif role == "TANK" then
		customRole = "Tank"
	end

	if not icon then return end
	local linetext = ((string.format("|T%s:%d:%d:0:-1|t", icon, 16, 16)).." "..name.." ("..customRole..")")

	if isInRange then
		if guild then
			_G["GameTooltipTextLeft4"]:SetText(linetext)
			_G["GameTooltipTextLeft4"]:Show()
		elseif not guild then
			_G["GameTooltipTextLeft3"]:SetText(linetext)
			_G["GameTooltipTextLeft3"]:Show()
		else
			GameTooltip:AddLine(linetext)
		end
	end
	GameTooltip:AppendText("")
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent",function(self, event, guid)
	self:UnregisterEvent("INSPECT_READY")
	InspectTalents(1)
end)

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
	local unit = select(2, GameTooltip:GetUnit())
	if not unit then return end

	if UnitIsPlayer(unit) and (UnitLevel(unit) > 9 or UnitLevel(unit) == -1) then
		if not InspectFrame or not InspectFrame:IsShown() then
			if CheckInteractDistance(unit,1) and CanInspect(unit) then

				f:RegisterEvent("INSPECT_READY")
				NotifyInspect(unit)
			end
		end
	end
end)
]]


---------------------------
-- SPELLS COOLDOWNS -- Credits - NameplateCooldowns Addon
---------------------------
-- If you wish to disable an ability tracker, put '--' infront of the ID.

jps.SpellCD = {

-- ["MISC"]
	[28730] = 120,				--"Arcane Torrent",
	[50613] = 120,				--"Arcane Torrent",
	[80483] = 120,				--"Arcane Torrent",
	[25046] = 120,				--"Arcane Torrent",
	[69179] = 120,				--"Arcane Torrent",
	[20572] = 120,				--"Blood Fury",
	[33702] = 120,				--"Blood Fury",
	[33697] = 120,				--"Blood Fury",
	[59543] = 180,				--"Gift of the Naaru",
	[69070] = 120,				--"Rocket Jump",
	[26297] = 180,				--"Berserking",
	[20594] = 120,				--"Stoneform",
	[58984] = 120,				--"Shadowmeld",
	[20589] = 90,				--"Escape Artist",
	[59752] = 120,				--"Every Man for Himself",
	[7744] = 120,				--"Will of the Forsaken",
	[68992] = 120,				--"Darkflight",
	[50613] = 120,				--"Arcane Torrent",
	[11876] = 120,				--"War Stomp",
	[69041] = 120,				--"Rocket Barrage",
	[42292] = 120,				--"PvP Trinket",
-- ["HUNTER"]
	[19386] = 45,				--"Wyvern Sting",
	[19263] = 180,				--"Deterrence",
	[147362] = 24,				--"Counter Shot"
	[120697] = 90,				--"Lynx Rush",
	[120679] = 30,				--"Dire Beast",
	[109248] = 45,				--"Binding Shot",
	[1499] = 15,				--"Freezing Trap",
	[60192] = 12,				--"Freezing Trap (launcher)",
	[82726] = 30,				--"Fervor",
	[3045] = 180,				--"Rapid Fire",
	[53351] = 10,				--"Kill Shot",
	[53271] = 45, 				--"Master's Call",
	[51753] = 60,				--"Camouflage",
	[19574] = 60,				--"Bestial Wrath",
	[61685] = 25,				--"Charge",
	[50519] = 60,				--"Sonic Blast",
	[50433] = 10,				--"Ankle Crack",
	[90355] = 360,				--"Ancient Hysteria",
	[90361] = 40,				--"Spirit Mend",
	[55709] = 480,				--"Heart of the Phoenix",
	[53480] = 60,				--"Roar of Sacrifice",
	[53478] = 360,				--"Last Stand",

-- ["WARLOCK"]
	[6789] = 45,				--"Death Coil",
	[5484] = 40,				--"Howl of Terror",
	[111397] = 30,				--"Blood Horror",
	[110913] = 180,				--"Dark Bargain",
	[108482] = 60,				--"Unbound Will",
	[108359] = 120,				--"Dark Regeneration",
	[108416] = 60,				--"Sacrificial Pact",
	[30283] = 30,				--"Shadowfury",
	[48020] = 30,				--"Demonic Circle: Teleport",
	[104773] = 120,				-- Unending Resolve
	[19647] = 24,				--"Spell Lock",
	[7812] = 60,				--"Sacrifice",
	[89766] = 30,				--"Axe Toss"
	[89751] = 45,				--"Felstorm",
	[115781] = 24,				-- Optical Blast

-- ["MAGE"]
	[2139] = 22,				--"Counterspell",
	[45438] = 300,				--"Ice Block",
	[110959] = 90,				--"Greater Invisibility",
	[102051] = 20,				--"Frostjaw",
	[44572] = 30,				--"Deep Freeze",
	[11958] = 180,				--"Cold Snap",	
	[12042] = 90,				--"Arcane Power",		
	[12051] = 120,				--"Evocation", 
	[122] = 25,					--"Frost Nova",	
	[11426] = 25,				--"Ice Barrier", 
	[12472] = 180,				--"Icy Veins",
	[55342] = 180,				--"Mirror Image", 
	[66] = 300,					--"Invisibility",
	[113724] = 45,				--"Ring of Frost",
	[80353] = 300, 				--"Time Warp",
	[12043] = 90,				--"Presence of Mind",
	[11129] = 45,				--"Combustion",
	[31661] = 20,				--"Dragon's Breath",
	[1953] = 15,				-- Blink
	[33395] = 25,				--"Freeze",

-- ["DEATHKNIGHT"]
	[47476] = 60,				--"Strangulate",
	[108194] = 30,				-- Asphyxiate
	[48707] = 45,				--"Anti-Magic Shell",
	[49576] = 25,				--"Death Grip",	
	[47528] = 13,				--"Mind Freeze",
	[108200] = 60,				--"Remorseless Winter",
	[108201] = 120,				--"Desecrated Ground",
	[108199] = 60,				--"Gorefiend's Grasp",
	[49039] = 120,				--"Lichborne",
	[49222] = 60,				--"Bone Shield",
	[51271] = 60,				--"Pillar of Frost",
	[51052] = 120,				--"Anti-Magic Zone",
	[49206] = 180,				--"Summon Gargoyle",
	[48792] = 180,				--"Icebound Fortitude",
	[48743] = 120,				--"Death Pact",
	[77606] = 60,				-- Dark Simulacrum

-- ["DRUID"]
	[78675] = 60,				--"Solar Beam",
	[5211] = 50,				--"Bash",
	[106839] = 15,				-- Skull Bash
	[132469] = 30,				-- Тайфун
	[124974] = 90,				--"Nature's Vigil",
	[102359] = 30,				--"Mass Entanglement",
	[99] = 30,					--"Disorienting Roar",
	[102280] = 30,				--"Displacer Beast",
	[22812] = 60,				--"Barkskin",
	[132158] = 60,				--"Nature's Swiftness",
	[33891] = 180,				--"Tree of Life",
	[16979] = 15,				--"Wild Charge - Bear",
	[49376] = 15,				--"Wild Charge - Cat",
	[61336] = 180,				--"Survival Instincts",
	[50334] = 180,				--"Berserk",
	[22570] = 10,				--"Maim",
	[18562] = 15,				--"Swiftmend",
	[48505] = 90,				--"Starfall",
	[740] = 480,				--"Tranquility",
	[78674] = 15,				--"Starsurge",
	[102543] = 180,				-- Incarnation: King of the Jungle
	[102560] = 180,				-- Incarnation: Chosen of Elune

-- ["MONK"]
	[116705] = 15, 				--Spear Hand Strike (interrupt)
	[115078] = 15, 				--Paralysis
	[119381] = 45, 				--Leg Sweep (mass stun)
	[123904] = 180,				--"Invoke Xuen, the White Tiger",
	[101643] = 45,				--"Transcendence",
	[119996] = 25,				--"Transcendence: Transfer",
	[115176] = 180,				--"Zen Meditation",
	[115310] = 180,				--"Revival",
	[122278] = 90, 				--"Dampen Harm",
	[122783] = 90,				--"Diffuse Magic",
	[116844] = 45,				--"Ring of Peace",
	[116849] = 120,				--"Life Cocoon",
	[137562] = 120,				--"Nimble Brew",
	[122470] = 90,				--"Touch of Karma",
	[101545] = 25,				--"Flying Serpent Kick",
	[116841] = 30,				--"Tiger's Lust",
	[113656] = 25,				--"Fists of Fury",

-- ["PALADIN"]
	[853] = 60,					--"Hammer of Justice" (stun)
	[115750] = 120,				--Blinding Light (blind (sic!))
	[105593] = 30,				-- Fist of Justice
	[96231] = 15,				--"Rebuke",
	[642] = 300,				--"Divine Shield",
	[85499] = 45,				--"Speed of Light",
	[1044] = 25,				--"Hand of Freedom",
	[31884] = 180,				--"Avenging Wrath",
	[31935] = 15,				--"Avenger's Shield",
	[633] = 600,				--"Lay on Hands",
	[1022] = 300,				--"Hand of Protection",
	[498] = 60,					--"Divine Protection",
	[6940] = 120,				--"Hand of Sacrifice",
	[31842] = 180,				--"Divine Favor",
	[31821] = 180,				--"Devotion Aura",
	[20066] = 15,				--"Repentance",
	[31850] = 180,				--"Ardent Defender",

-- ["PRIEST"]
	[64044] = 45,				--"Psychic Horror",
	[8122] = 30,				--"Psychic Scream",
	[15487] = 45,				--"Silence",
	[47585] = 105,				--"Dispersion",
	[33206] = 180,				--"Pain Suppression",
	[108920] = 30,				-- Void Tendrils
	[112833] = 30,				-- Призрачный облик
	[123040] = 60,				--"Mindbender",
	[10060] = 120,				--"Power Infusion",
	[88625] = 30,				--"Holy Word: Chastise",
	[586] = 30,					--"Fade",
	[112833] = 30,				--"Spectral Guise",
	[6346] = 120,				--"Fear Ward",
	[64843] = 180,				--"Divine Hymn",
	[73325] = 90,				--"Leap of Faith",
	[19236] = 120,				--"Desperate Prayer",
	[724] = 180,				--"Lightwell",
	[62618] = 180,				--"Power Word: Barrier",
	[47788] = 180,				-- Guardian Spirit

-- ["ROGUE"]
	[2094] = 90,				--"Blind",
	[1766] = 13,				--"Kick",
	[31224] = 60,				--"Cloak of Shadows",
	[1856] = 120,				-- Исчезновение
	[1776] = 10,				--"Gouge",
	[2983] = 60,				--"Sprint",
	[14185] = 300,				--"Preparation",
	[36554] = 20,				--"Shadowstep",
	[5277] = 120,				--"Evasion",
	[408] = 20,					--"Kidney Shot",
	[76577] = 180,				--"Smoke Bomb",
	[51690] = 120,				--"Killing Spree",
	[51713] = 60, 				--"Shadow Dance",
	[79140] = 120,				--"Vendetta",

-- ["SHAMAN"]
	[8177] = 25,				--"Grounding Totem",
	[57994] = 12,				--"Wind Shear",
	[51490] = 35,				--"Thunderstorm",
	[51485] = 30,				--"Earthbind Totem",
	[8143] = 60,				--"Tremor Totem",
	[51514] = 35,				--"Hex",
	[108269] = 45,				--"Capacitor Totem",
	[108270] = 60,				--"Stone Bulwark Totem",
	[108280] = 180,				--"Healing Tide Totem",
	[98008] = 180,				--"Spirit Link Totem",
	[32182] = 300,				--"Heroism",
	[2825] = 300,				--"Bloodlust",
	[51533] = 120,				--"Feral Spirit",
	[30823] = 60,				--"Shamanistic Rage",
	[2484] = 30,				--"Earthbind Totem",
	[79206] = 120,				--"Spiritwalker's Grace",
	[16166] = 90,				--"Elemental Mastery",
	[16188] = 90,				--"Ancestral Swiftness",
	[108273] =	60,				-- Windwalk Totem
	[108285] = 	180,			-- Call of the Elements

-- ["WARRIOR"]
	[102060] = 40,				--"Disrupting Shout"
	[100] = 12,					--"Charge",
	[6552] = 15,				--"Pummel",
	[23920] = 20,				--"Spell Reflection",
	[46924] = 60,				--"Bladestorm",
	[46968] = 40,				--"Shockwave",
	[107574] = 180,				--"Avatar",
	[12292] = 60, 				--"Bloodbath",
	[86346] = 20,				--"Colossus Smash",
	[5246] = 90,				--"Intimidating Shout",
	[871] = 180,				--"Shield Wall",	
	[118038] = 120,				--"Die by the Sword",
	[1719] = 180,				--"Recklessness",
	[3411] = 30,				--"Intervene",
	[64382] = 300,				--"Shattering Throw",
	[6544] = 30,				--"Heroic Leap",
	[12975] = 180,				--"Last Stand",
	[114028] = 60,				-- Mass Spell Reflection
	[18499] = 30,				-- Berserker Rage
	[107570] = 30,				-- Storm Bolt
}