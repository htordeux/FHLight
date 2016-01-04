--[[
	 JPS - WoW Protected Lua DPS AddOn
	Copyright (C) 2011 Jp Ganis

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
]]--

--------------------------
-- LOCALIZATION
--------------------------
--Pre-6.0:
-- name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellID or spellName)
--6.0:
-- name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spellID or spellName)

local L = MyLocalizationTable
local UnitDebuff = UnitDebuff
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local UnitIsUnit = UnitIsUnit
local GetTime = GetTime
local toSpellName = jps.toSpellName

--------------------------
-- DISPEL TABLE
--------------------------
-- Create table with jps.SpellControl[spellID] in a local table DebuffControl[SpellName]

local DebuffControl = {}
for spellID,control in pairs(jps.SpellControl) do
	DebuffControl[toSpellName(spellID)] = control
end

-- Don't Dispel if unit is affected by some debuffs
local DebuffNotDispel = {
	toSpellName(31117), 	-- "Unstable Affliction"
	toSpellName(34914), 	-- "Vampiric Touch"
	}

-- Don't dispel if friend is affected by "Unstable Affliction" or "Vampiric Touch" or "Lifebloom"
local UnstableAffliction = function(unit)
	for i=1,#DebuffNotDispel do -- for _,debuff in ipairs(DebuffNotDispel) do
		local debuff = DebuffNotDispel[i]
		if jps.debuff(debuff,unit) then return true end
	end
	return false
end

--------------------------------------
-- LOSS OF CONTROL CHECK
--------------------------------------
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitDebuff("unit", index or ["name", "rank"][, "filter"])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitBuff("unit", index or "name"[, "rank"[, "filter"]])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff, isCastByPlayer, ... = UnitAura("unit", index or "name"[, "rank"[, "filter"]])
-- SPELLID OF THE SPELL OR EFFECT THAT APPLIED THE AURA

function jps.StunEvents(duration) -- ONLY FOR PLAYER
	if duration == nil then duration = 0 end
	if jps.checkTimer("PlayerStun") > duration then return true end
	return false
end

function jps.InterruptEvents() -- ONLY FOR PLAYER
	if jps.checkTimer("PlayerInterrupt") > 0 then return true end
	return false
end

function jps.ControlEvents() -- ONLY FOR PLAYER
	if jps.checkTimer("PlayerInterrupt") > 0 then return true end
	if jps.checkTimer("PlayerStun") > 0 then return true end
	return false
end

-- Check if unit loosed control
-- { "CC" , "Snare" , "Root" , "Silence" , "Immune", "ImmuneSpell", "Disarm" }
-- LoseControl could be FRIEND or ENEMY
jps.LoseControl = function(unit,controlTable)
	local timeControlled = 0
	if controlTable == nil then controlTable = {"CC" , "Snare" , "Root" , "Silence" } end
	-- Check debuffs
	local auraName, debuffType, duration, expTime, spellID
	local i = 1
	auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	while auraName do
		local Priority = DebuffControl[auraName] -- jps.SpellControl[spellID]
		if Priority then
			for i=1,#controlTable do
				if Priority == controlTable[i] then
					if expTime ~= nil then timeControlled = expTime - GetTime() end
					if timeControlled > 1 then return true end
				end
			end
		end
		i = i + 1
		auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	end
	return false
end

-- LoseControl could be FRIEND or ENEMY
jps.DispelLoseControl = function(unit,controlTable)
	if not canHeal(unit) then return false end
	if UnstableAffliction(unit) then return false end
	local timeControlled = 0
	if controlTable == nil then controlTable = {"CC" , "Snare" , "Root" , "Silence" } end
	-- Check debuffs
	local auraName, debuffType, duration, expTime, spellID
	local i = 1
	auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	while auraName do
		local Priority = DebuffControl[auraName] -- jps.SpellControl[spellID]
		if Priority and debuffType == "Magic" then -- {"Magic", "Poison", "Disease", "Curse"}
			for i=1,#controlTable do
				if Priority == controlTable[i] then
					if expTime ~= nil then timeControlled = expTime - GetTime() end
					if timeControlled > 1 then return true end
				end
			end
		end
		i = i + 1
		auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID, _ = UnitDebuff(unit,i)
	end
	return false
end

--------------------------
-- DEBUFF RBG -- Credits - BigDebuffs Addon
--------------------------

local BigDebuff = {
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
		[130616] = "cc", parent = 118699 , -- Fear (Glyph of Fear)
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

-- Enemy Casting SpellControl according to table jps.SpellControl[spellID]
local latencyWorld = select(4,GetNetStats())/1000

function jps.IsCastingSpellControl(unit) -- WORKS FOR CASTING SPELL NOT CHANNELING SPELL
	if unit == nil then unit = "player" end
	-- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitCastingInfo("unit")
	local spellName, _, _, _, startTime, endTime, _, _, interrupt = UnitCastingInfo(unit)
	if not spellName then return false end
	if DebuffControl[spellName] == "CC" then return true
	elseif DebuffControl[spellName] == "Silence" then return true
	elseif DebuffControl[spellName] == "Root" then return true
	end
	return false
end

-- Dispel all MAGIC debuff in the debuff TABLE DebuffToDispel EXCEPT if unit is affected by UnstableAffliction
jps.DispelFriendly = function(unit,time)
	if not canHeal(unit) then return false end
	if UnstableAffliction(unit) then return false end
	if time == nil then time = 0 end
	local timeControlled = 0
	-- Check debuffs
	local auraName, debuffType, duration, expTime, spellID
	local i = 1
	auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID = UnitDebuff(unit, i)
	while auraName do
		if debuffType == "Magic" then -- {"Magic", "Poison", "Disease", "Curse"}
			if BigDebuff[spellID]  == "cc" then
				if expTime ~= nil then timeControlled = expTime - GetTime() end
				if timeControlled > time then return true end
			end
		end
		i = i + 1
		auraName, _, _, _, debuffType, duration, expTime, _, _, _, spellID = UnitDebuff(unit, i)
	end
	return false
end

------------------------------------
-- OFFENSIVE DISPEL
------------------------------------

-- Avenging Wrath 31884 Dispel type	n/a
-- Divine Shield and Ice Block need Mass Dispel
local BuffToDispel = 
{	
	toSpellName(7812), -- Sacrifice 7812 Type de dissipation	Magie
	toSpellName(109147), -- Archangel 109147 Type de dissipation	Magie
	toSpellName(110694), -- Frost Armor 110694 Type de dissipation	Magie
	toSpellName(17), -- Power Word: Shield 17 Type de dissipation	Magie
	toSpellName(6346), -- Fear Ward 6346 Type de dissipation	Magie
	toSpellName(1022), -- Hand of Protection 1022  Dispel type	Magic
	toSpellName(1463), -- Incanter's Ward 1463 Dispel type	Magic
	toSpellName(69369), -- Predatory Swiftness 69369 Dispel type	Magic
	toSpellName(11426), -- Ice Barrier 11426 Dispel type	Magic
	toSpellName(6940), -- Hand of Sacrifice Dispel type	Magic
	toSpellName(110909), -- Alter Time Dispel type	Magic
	toSpellName(132158), -- Nature's Swiftness Dispel type	Magic
	toSpellName(12043) -- Presence of Mind Dispel type	Magic
} 

-- "Lifebloom" When Lifebloom expires or is dispelled, the target is instantly healed
local NotOffensiveDispel = toSpellName(94447) -- "Lifebloom"
function jps.DispelOffensive(unit)
	if not canDPS(unit) then return false end
	if jps.buff(NotOffensiveDispel,unit) then return false end 
	for i=1,#BuffToDispel do -- for _,buff in ipairs(BuffToDispel) do
		local buff = BuffToDispel[i]
		if jps.buff(buff,unit) then
		return true end
	end
	return false
end

-- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")
-- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitCastingInfo("unit")

function jps.ShouldKick(unit)
	if not canDPS(unit) then return false end
	local casting = select(1,UnitCastingInfo(unit))
	local notinterruptible = select(9,UnitCastingInfo(unit)) --  if true, indicates that this cast cannot be interrupted 
	local channelling = select(1,UnitChannelInfo(unit))
	local not_interruptible = select(8,UnitChannelInfo(unit)) -- if true, indicates that this cast cannot be interrupted
	if casting == L["Release Aberrations"] then return false end
	if casting == nil and channelling == nil then return false end
	if casting and not notinterruptible then
		return true
	elseif channelling and not not_interruptible then
		return true
	end
	return false
end

function jps.ShouldKickDelay(unit)
	if not canDPS(unit) then return false end
	if unit == nil then unit = "target" end
	local casting = UnitCastingInfo(unit)
	local channelling = UnitChannelInfo(unit)
	if casting == L["Release Aberrations"] then return false end

	if casting and jps.CastTimeLeft(unit) < 2 then
		return true
	elseif channelling and jps.ChannelTimeLeft(unit) < 2 then
		return true
	end
	return false
end