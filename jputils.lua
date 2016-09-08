
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

	-- Higher up = higher display prio
    
    -- Immune
    [33786] = "immune", 			-- Cyclone
	[19263] = "immune",   		-- Deterrence
	[186265] = "immune", 			-- Aspect of the Turtle
    [45438] = "immune", 	    	-- Ice Block
    [642] = "immune", 		    -- Divine Shield    
    [115018] = "immune", 	    	-- Desecrated Ground
    [31821] = "immune", 			-- Aura Mastery
	[1022] = "immune", 			-- Hand of Protection
    [47585] = "immune", 	    	-- Dispersion
    [31224] = "immune", 	        -- Cloak of Shadows
	[45182] = "immune", 			-- Cheating Death
    [8178] = "immune", 	        -- Grounding Totem Effect (Grounding Totem)
    [76577] = "immune", 			-- Smoke Bomb
	[88611] = "immune", 			-- Smoke Bomb
    [46924] = "immune", 		    -- Bladestorm
    [51690] = "immune",            -- Killing Spree
	[221703] = "immune", 			-- Casting Circle
    
    -- CCs    
	[108194] = "cc", 		    -- Asphyxiate
	[115001] = "cc", 			-- Remorseless Winter
    [115000] = "cc", 			-- Remorseless Winter
    [91800] = "cc", 			-- Gnaw
    [91797] = "cc", 			-- Monstrous Blow (Dark Transformation)
    [99] = "cc", 			-- Incapacitating Roar
	[217832] = "cc", 			-- Imprison (Demon Hunter)
	[163505] = "cc",       	-- Rake
	[179057] = "cc", 			-- Chaos Nova
	[22570] = "cc", 			-- Maim
	[5211] = "cc", 			-- Mighty Bash
    [3355] = "cc", 			-- Freezing Trap
    [117526] = "cc", 			-- Binding Shot
    [19386] = "cc", 			-- Wyvern Sting
    [24394] = "cc", 		    -- Intimidation
    [44572] = "cc", 			-- Deep Freeze
	[31661] = "cc", 			-- Dragon's Breath
	[118] = "cc", 			-- Polymorph
	[61305] = "cc", 			-- Polymorph: Black Cat
	[28272] = "cc", 			-- Polymorph: Pig
	[61721] = "cc", 			-- Polymorph: Rabbit
	[61780] = "cc", 			-- Polymorph: Turkey
	[28271] = "cc", 			-- Polymorph: Turtle
	[82691] = "cc", 			-- Ring of Frost
	[140376] = "cc", 			-- Ring of Frost	
    [119392] = "cc", 			-- Charging Ox Wave
	[120086] = "cc", 			-- Fists of Fury
	[119381] = "cc", 			-- Leg Sweep
	[115078] = "cc", 			-- Paralysis
    [105421] = "cc", 			-- Blinding Light
	[105593] = "cc", 			-- Fist of Justice
	[853] = "cc", 			-- Hammer of Justice
	[20066] = "cc", 			-- Repentance
    [605] = "cc", 			-- Dominate Mind
	[88625] = "cc", 			-- Holy Word: Chastise
	[64044] = "cc", 			-- Psychic Horror
	[8122] = "cc", 			-- Psychic Scream
	[9484] = "cc", 			-- Shackle Undead
	[87204] = "cc", 			-- Sin and Punishment
    [2094] = "cc", 			-- Blind
	[1833] = "cc", 			-- Cheap Shot
	[1776] = "cc", 			-- Gouge
	[408] = "cc", 			-- Kidney Shot
	[199804] = "cc", 			-- Between the Eyes
	[185763] = "cc", 			-- Pistol Shot
	[6770] = "cc", 			-- Sap
    [51514] = "cc", 			-- Hex
	[118905] = "cc", 			-- Static Charge (Capacitor Totem)
    [5782] = "cc", 			-- Fear
	[118699] = "cc", 			-- Fear
	[130616] = "cc", 			-- Fear (Glyph of Fear)
	[5484] = "cc", 			-- Howl of Terror
    [6789] = "cc", 			-- Mortal Coil
	[30283] = "cc", 			-- Shadowfury
    [89766] = "cc", 		    -- Axe Toss (Felguard/Wrathguard)
	[115268] = "cc", 		    -- Mesmerize (Shivarra)
    [6358] = "cc", 		    -- Seduction (Succubus)
    [118895] = "cc", 			-- Dragon Roar
	[5246] = "cc", 			-- Intimidating Shout (aoe)
	[132168] = "cc", 			-- Shockwave
	[107570] = "cc", 			-- Storm Bolt
	[132169] = "cc", 			-- Storm Bolt
    [20549] = "cc", 		    -- War Stomp
    
    -- Anti CC
    [48792] = "anticc", 			-- Icebound Fortitude
    [48707] = "anticc", 	        -- Anti-Magic Shell
    [23920] = "anticc", 	        -- Spell Reflection
	[114028] = "anticc", 	        -- Mass Spell Reflection
	[205604] = "anticc", 			-- Reverse Magic
    
    -- Silence
    [47476] = "silence", 		    -- Strangulate
    [114238] = "silence", 	    	-- Fae silence (Glyph of Fae silence)
	[81261] = "silence", 		    -- Solar Beam
    [137460] = "silence",  		-- silenced (Ring of Peace)
    [15487] = "silence", 		    -- silence
    [1330] = "silence", 		    -- Garrote - silence
    [31117] = "silence", 		    -- Unstable Affliction
	
	-- Buffs	
	[122470] = "buff",          -- Touch of Karma
	[203720] = "buff", 			-- Demon Spikes
	[203819] = "buff", 			-- Demon Spikes
	[202748] = "buff", 			-- Survival Tactics
--	[208796] = "buff", 			-- Jagged Spikes
	[49039] = "buff", 			-- Lichborne
    [61394] = "buff", 			-- Frozen Wake (Glyph of Freezing Trap)
    [54216] = "buff", 		    -- Master's Call (root and snare immune only)
    [137798] = "buff", 		    -- Reflective Armor Plating
    [5277] = "buff", 			    -- Evasion
	[199754] = "buff", 			-- Riposte (Outlaw)
	[198589] = "buff", 			-- Blur (Demon Hunter)
	[196555] = "buff", 			-- Netherwalk (Demon Hunter)
	[196718] = "buff", 			-- Darkness (Demon Hunter)
    [110913] = "buff", 			-- Dark Bargain
	[104773] = "buff", 			-- Unending Resolve
	[207319] = "buff", 			-- Corpse Shield
    [147531] = "buff", 			-- Bloodbath
    [18499] = "buff", 			-- Berserker Rage
    [51713] = "buff",            -- Shadow Dance
    [61336] = "buff",            -- Survival Instincts
    [22812] = "buff",            -- Barkskin
    [50334] = "buff",            -- Bersek
    [112071] = "buff",           -- Celestial Alignment
    [102342] = "buff",           -- Iron Bark
    [6940] = "buff",             -- Sac
    [53480] = "buff",            -- Roar of Sacrifice
    [31884] = "buff",            -- Avenging Wrath
    [1719] = "buff",             -- Recklessness
    [110909] = "buff",           -- Alter Time
    [113858] = "buff",           -- Dark Soul
    [113861] = "buff",           -- Dark Soul
    [113860] = "buff",           -- Dark Soul
    [102543] = "buff",           -- Incarnation: King of the Jungle
    [102560] = "buff",           -- Incarnation: Chosen of Elune
    --[137573] = "buff",           -- Burst of Speed
    --[2983] = "buff",             -- Sprint
    
    -- Root & Snare    
	[96294] = "root", 			-- Chains of Ice (Chilblains)
	[222029] = "root",			-- Strike of the Windlord (Monk Artifact)
	[209782] = "root",		-- Goremaw's Bite (Rogue Artifact)
	[195452] = "root", 			-- Nightblade
    [91807] = "root",			-- Shambling Rush (Dark Transformation)
    [339] = "root",			-- Entangling roots
	[113770] = "root", 			-- Entangling roots (Force of Nature - Balance Treants)
	[45334] = "root", 			-- Immobilized (Wild Charge - Bear)
	[102359] = "root", 			-- Mass Entanglement
	[127797] = "root", 			-- Ursol's Vortex
    [128405] = "root", 			-- Narrow Escape
	[5116] = "root", 			-- Concussive Shot
    [13809] = "root", 			-- Ice Trap 1	
	[13810] = "root", 			-- Ice Trap 2
    [122] = "root", 			-- Frost Nova
	[111340] = "root", 			-- Ice Ward
	[115760] = "root", 	        -- Glyph of Ice Block
	[157997] = "root", 			-- Ice Nova
	[66309] = "root", 			-- Ice Nova
	[110959] = "root", 			-- Greater Invisibility
	[33395] = "root", 		    -- Freeze
    [116706] = "root", 			-- Disable
	[116095] = "root", 			-- Disable
	[118585] = "root", 			-- Leer of the Ox
	[123586] = "root", 			-- Flying Serpent Kick
    [31935] = "root", 		    -- Avenger's Shield
	[110300] = "root", 			-- Burden of Guilt
	[87194] = "root", 			-- Glyph of Mind Blast
	[114404] = "root", 			-- Void Tendril's Grasp
	[114239] = "root", 	        -- Phantasm
	[159630] = "root", 		    -- Fade
    [102051] = "root", 	    	-- Frostjaw (also a root)
	[26679] = "root", 			-- Deadly Throw
	[119696] = "root", 			-- Debilitation	
	[77505] = "root", 			-- Earthquake	
	[64695] = "root", 			-- Earthgrab (Earthgrab Totem)
	[63685] = "root", 			-- Freeze (Frozen Power)
	[77478] = "root", 			-- Earthquake (Glyph of Unstable Earth)
	[118345] = "root", 		    -- Pulverize
	[710] = "root", 			-- Banish
	[137143] = "root", 			-- Blood Horror
	[22703] = "root", 			-- Infernal Awakening
	[18498] = "root", 		    -- Silenced - Gag Order (PvE only)
	[107566] = "root", 			-- Staggering Shout
	[105771] = "root", 			-- Warbringer	
	[12323] = "root", 			-- Piercing Howl
	
	-- Other
	[30217] = "other", 		-- Adamantite Grenade
	[67769] = "other", 		-- Cobalt Frag Bomb
	[30216] = "other", 		-- Fel Iron Bomb
	[107079] = "other", 		-- Quaking Palm
	[13327] = "other", 		-- Reckless Charge	
	[25046] = "other", 		-- Arcane Torrent (Energy)
	[28730] = "other", 		-- Arcane Torrent (Mana)
	[50613] = "other", 		-- Arcane Torrent (Runic Power)
	[69179] = "other", 		-- Arcane Torrent (Rage)
	[80483] = "other", 		-- Arcane Torrent (Focus)
	[129597] = "other", 		-- Arcane Torrent (Chi)
	[39965] = "other", 		-- Frost Grenade
	[55536] = "other", 		-- Frostweave Net
	[13099] = "other", 		-- Net-o-Matic
	[1604] = "other", 		-- Dazed

}

--------------------------
-- DEBUFF RBG -- Credits - BigDebuffs Addon
--------------------------

-- Show one of these when a big debuff is displayed
jps.WarningDebuffs = {
	88611, -- Smoke Bomb
	81261, -- Solar Beam
	30108, -- Unstable Affliction
	34914, -- Vampiric Touch
}


jps.BigDebuff = {

-- Immunities
	[46924]  =  "immune" , -- Bladestorm
	[642]    =  "immune" , -- Divine Shield
	[19263]  =  "immune" , -- Deterrence
		[148467] =  "immune" , -- Deterrence (Glyph of Mirrored Blades)
	[51690]  =  "immune" , -- Killing Spree
	[115018] =  "immune" , -- Desecrated Ground
	[45438]  =  "immune" , -- Ice Block
	[157913] =  "immune" , -- Evanesce

	-- Spell Immunities
	[23920]  =  "immune_spell" , -- Spell Reflection
		[114028] =  "immune_spell" , -- Mass Spell Reflection
	[31821]  =  "immune_spell" , -- Devotion Aura
	[31224]  =  "immune_spell" , -- Cloak of Shadows
	[48707]  =  "immune_spell" , -- Anti-Magic Shell
	[104773] =  "immune_spell" , -- Unending Resolve

	-- CC
	[33786]  =  "cc" , -- Cyclone
	[605]    =  "cc" , -- Mind Control
	[20549]  =  "cc" , -- War Stomp
	[107079] =  "cc" , -- Quaking Palm
	[129597] =  "cc" , -- Arcane Torrent
		[28730]  =  "cc" , -- Arcane Torrent
		[25046]  =  "cc" , -- Arcane Torrent
		[50613]  =  "cc" , -- Arcane Torrent
		[69179]  =  "cc" , -- Arcane Torrent
		[155145] =  "cc" , -- Arcane Torrent
		[80483]  =  "cc" , -- Arcane Torrent
	[155335] =  "cc" , -- Touched by Ice
	[5246]   =  "cc" , -- Intimidating Shout
	[24394]  =  "cc" , -- Intimidation
	[132168] =  "cc" , -- Shockwave
	[132169] =  "cc" , -- Storm Bolt
	[853]    =  "cc" , -- Hammer of Justice
	[20066]  =  "cc" , -- Repentance
	[31935]  =  "cc" , -- Avengers Shield
	[105421] =  "cc" , -- Blinding Light
	[3355]   =  "cc" , -- Freezing Trap
	[19386]  =  "cc" , -- Wyvern Sting
	[117526] =  "cc" , -- Binding Shot
	[408]    =  "cc" , -- Kidney Shot
	[1330]   =  "cc" , -- Garrote - Silence
	[1776]   =  "cc" , -- Gouge
	[1833]   =  "cc" , -- Cheap Shot
	[2094]   =  "cc" , -- Blind
	[6770]   =  "cc" , -- Sap
	[88611]  =  "cc" , -- Smoke Bomb
	[8122]   =  "cc" , -- Psychic Scream
	[9484]   =  "cc" , -- Shackle Undead
	[15487]  =  "cc" , -- Silence
	[64044]  =  "cc" , -- Psychic Horror
	[87204]  =  "cc" , -- Sin and Punishment
	[88625]  =  "cc" , -- Holy Word: Chastise
	[47476]  =  "cc" , -- Strangulate
	[91797]  =  "cc" , -- Monstrous Blow
	[91800]  =  "cc" , -- Gnaw
	[108194] =  "cc" , -- Asphyxiate
	[51514]  =  "cc" , -- Hex
	[77505]  =  "cc" , -- Earthquake
	[118345] =  "cc" , -- Pulverize
	[118905] =  "cc" , -- Static Charge (Capacitor Totem)
	[118]    =  "cc" , -- Polymorph
		[61305]  =  "cc" , -- Polymorph Black Cat
		[28272]  =  "cc" , -- Polymorph Pig
		[61721]  =  "cc" , -- Polymorph Rabbit
		[61780]  =  "cc" , -- Polymorph Turkey
		[28271]  =  "cc", -- Polymorph Turtle
	[31661]  =  "cc" , -- Dragon's Breath
	[82691]  =  "cc" , -- Ring of Frost
	[710]    =  "cc" , -- Banish
	[5484]   =  "cc" , -- Howl of Terror
	[6358]   =  "cc" , -- Seduction
	[6789]   =  "cc" , -- Mortal Coil
	[22703]  =  "cc" , -- Infernal Awakening
	[30283]  =  "cc" , -- Shadowfury
	[31117]  =  "cc" , -- Unstable Affliction (Silence)
	[89766]  =  "cc" , -- Axe Toss
	[115268] =  "cc" , -- Mesmerize
	[118699] =  "cc" , -- Fear
		[130616] =  "cc" , -- Fear (Glyph of Fear)
	[115078] =  "cc" , -- Paralysis
	[119381] =  "cc" , -- Leg Sweep
	[120086] =  "cc" , -- Fists of Fury
	[99]     =  "cc" , -- Incapacitating Roar
	[5211]   =  "cc" , -- Mighty Bash
	[22570]  =  "cc" , -- Maim
	[81261]  =  "cc" , -- Solar Beam
	[163505] =  "cc" , -- Rake
	[205369] =  "cc" , -- Mind Bomb
		[226943] =  "cc" , -- Mind Bomb (Stun)

	-- Defensive Buffs
	[871]    =  "buff_defensive" , -- Shield Wall
	[108271] =  "buff_defensive" , -- Astral Shift
	[33206]  =  "buff_defensive" , -- Pain Suppression
	[116849] =  "buff_defensive" , -- Life Cocoon
	[47788]  =  "buff_defensive" , -- Guardian Spirit
	[47585]  =  "buff_defensive" , -- Dispersion
	[122783] =  "buff_defensive" , -- Diffuse Magic
	[178858] =  "buff_defensive" , -- Contender
	[61336]  =  "buff_defensive" , -- Survival Instincts
	[98007]  =  "buff_defensive" , -- Spirit Link
	[118038] =  "buff_defensive" , -- Die by the Sword
	[74001]  =  "buff_defensive" , -- Combat Readiness
	[5277]   =  "buff_defensive" , -- Evasion
	[49039]  =  "buff_defensive" , -- Lichborne
	[117679] =  "buff_defensive" , -- Incarnation: Tree of Life
	[102342] =  "buff_defensive" , -- Ironbark
	[22812]  =  "buff_defensive" , -- Barkskin
	[122278] =  "buff_defensive" , -- Dampen Harm
	[53480]  =  "buff_defensive" , -- Roar of Sacrifice
	[12975]  =  "buff_defensive" , -- Last Stand
	[1966]   =  "buff_defensive" , -- Feint
	[6940]   =  "buff_defensive" , -- Hand of Sacrifice
	[97463]  =  "buff_defensive" , -- Rallying Cry
	[115176] =  "buff_defensive" , -- Zen Meditation
	[120954] =  "buff_defensive" , -- Fortifying Brew
	[81782]  =  "buff_defensive" , -- Power Word: Barrier
	[155835] =  "buff_defensive" , -- Bristling Fur
	[1022]   =  "buff_defensive" , -- Hand of Protection
	[48743]  =  "buff_defensive" , -- Death Pact
	[31850]  =  "buff_defensive" , -- Ardent Defender
	[114030] =  "buff_defensive" , -- Vigilance
	[498]    =  "buff_defensive" , -- Divine Protection
	[122470] =  "buff_defensive" , -- Touch of Karma
	[48792]  =  "buff_defensive" , -- Icebound Fortitude
	[55233]  =  "buff_defensive" , -- Vampiric Blood
	[86659]  =  "buff_defensive" , -- Guardian of Ancient Kings
	[108416] =  "buff_defensive" , -- Sacrificial Pact

	-- Offensive Buffs
	[19574]  =  "buff_offensive" , -- Bestial Wrath
	[131894] =  "buff_offensive" , -- A Murder of Crows
	[152151] =  "buff_offensive" , -- Shadow Reflection
	[31842]  =  "buff_offensive" , -- Avenging Wrath
	[51690]  =  "buff_offensive" , -- Killing Spree
	[79140]  =  "buff_offensive" , -- Vendetta
	[102560] =  "buff_offensive" , -- Incarnation: Chosen of Elune
	[102543] =  "buff_offensive" , -- Incarnation: King of the Jungle
	[124974] =  "buff_offensive" , -- Nature's Vigil
	[12472]  =  "buff_offensive" , -- Icy Veins
	[16166]  =  "buff_offensive" , -- Elemental Mastery
	[114049] =  "buff_offensive" , -- Ascendance
		[114052] =  "buff_offensive" , -- Ascendance (Restoration)
		[114050] =  "buff_offensive" , -- Ascendance (Elemental)
		[114051] =  "buff_offensive" , -- Ascendance (Enhancement)
	[107574] =  "buff_offensive" , -- Avatar
	[13750]  =  "buff_offensive" , -- Adrenaline Rush
	[1719]   =  "buff_offensive" , -- Recklessness
	[106951] =  "buff_offensive" , -- Berserk
	[12042]  =  "buff_offensive" , -- Arcane Power
	[51271]  =  "buff_offensive" , -- Pillar of Frost
	[152279] =  "buff_offensive" , -- Breath of Sindragosa

	[41425]  =  "buff_other" , -- Hypothermia
	[130736] =  "buff_other" , -- Soul Reaper
	[77606]  =  "buff_other" , -- Dark Simulacrum
	[172786] =  "buff_other" , -- Drink
		[167152] =  "buff_other" , -- Refreshment
	[114239] =  "buff_other" , -- Phantasm
	[119032] =  "buff_other" , -- Spectral Guise
	[1044]   =  "buff_other" , -- Hand of Freedom
	[10060]  =  "buff_other" , -- Power Infusion
	[5384]   =  "buff_other" , -- Feign Death
	[108978] =  "buff_other" , -- Alter Time
	[170856] =  "buff_other" , -- Nature's Grasp
	[110959] =  "buff_other" , -- Greater Invisibility
	[18499]  =  "buff_other" , -- Berserker Rage	
	[114896] =  "buff_other" , -- Windwalk Totem

	-- Roots
	[122]    =  "root" , -- Frost Nova
		[33395] =  "root" , -- Freeze
	[339]    =  "root" , -- Entangling root
		[170855] =  "root" , -- Entangling root (Nature's Grasp)
	[53148]  =  "root" , -- Charge (Hunter)
	[105771] =  "root" , -- Charge (Warrior)
	[64695]  =  "root" , -- Earthgrab Totem
	[96294]  =  "root" , -- Chains of Ice
	[102359] =  "root" , -- Mass Entanglement
	[114404] =  "root" , -- Void Tendrils
	[116706] =  "root" , -- Disable
	[135373] =  "root" , -- Entrapment
	[136634] =  "root" , -- Narrow Escape
	[55536]  =  "root" , -- Frostweave Net
	[157997] =  "root" , -- Ice Nova
	[45334]  =  "root" , -- Wild Charge

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
-- DEBUFF AOE            -- Credits - GTFO Addon
---------------------------


local PvPEnemyAoE = {
-- Generic
46264,    	--"Void Zone Effect (Unknown)"
49699,    	--"Consumption"
39004,    	--"Consumption"
30538,    	--"Consumption"
30498,    	--"Consumption"
35951,    	--"Consumption"
-- Paladin
81297,    	--"Consecration"
-- Mage
2120,    	--"Flamestrike"
10,    		--"Blizzard"
42208,    	--"Blizzard"
82739,    	--"Flame Orb"
84721,    	--"Frostfire Orb"
-- Warlock
5740,    	--"Rain of Fire"
42223,    	--"Rain of Fire"
5857,    	--"Hellfire Effect"
-- Druid
50288,    	--"Starfall"
16914,    	--"Hurricane"
42231,    	--"Hurricane"
-- Death Knight
43265,    	--"Death and Decay"
52212,    	--"Death and Decay"
68766,    	--"Desecration"
-- Shaman
8187,    	--"Magma Totem"
8349,    	--"Fire Nova"
77478,    	--"Earthquake"
20754,    	--"Rain of Fire"
36808,    	--"Rain of Fire"
76055,    	--"Flame Patch"
13812,    	--"Explosive Trap"
033239, 	--"Whirlwind"
15578,    	--"Whirlwind"
114919, 	--"Arcing Light"
}

function jps.debuffAoE(unit)
	if unit == nil then unit = "player" end
	for i=1,#PvPEnemyAoE do
		local spellname = PvPEnemyAoE[i]
		if jps.debuff(spellname,unit) then return true end
	end
   return false
end