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
        -- [000017] = "PRIEST", -- Power word: Shield -- exists also for shadow priests
        [047540] = "PRIEST", -- Penance
        [062618] = "PRIEST", -- Power word: Barrier
        [109964] = "PRIEST", -- Spirit shell
        [047515] = "PRIEST", -- Divine Aegis
        [081700] = "PRIEST", -- Archangel
        [002060] = "PRIEST", -- Greater Heal
        [002061] = "PRIEST", -- Flash Heal
        [002050] = "PRIEST", -- Heal
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
    };

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
	[13809] = "Snare",			-- Ice Trap 1
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

jps.EnemyCds = {

	--------------------------------------------------------------------------
	--Misc
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
	[69070] = 120,				-- Goblin: Rocket Jump

	--------------------------------------------------------------------------
	--Pets(Death Knight)
	[91797] = 60,				--"Monstrous Blow",
	[91837] = 45,				--"Putrid Bulwark",
	[91802] = 30,				--"Shambling Rush",
	[47482] = 30,				--"Leap",
	[91809] = 30,				--"Leap",
	[91800] = 60,				--"Gnaw",
	[47481] = 60,				--"Gnaw",

	--------------------------------------------------------------------------
	--Pets(Hunter)
	[90339] = 60,				--"Harden Carapace",
	[61685] = 25,				--"Charge",
	[50519] = 60,				--"Sonic Blast",
	[35290] = 10,				--"Gore",
	[50245] = 40,				--"Pin",
	[50433] = 10,				--"Ankle Crack",
	[26090] = 30,				--"Pummel",
	[93434] = 90,				--"Horn Toss",
	[57386] = 15,				--"Stampede",
	[50541] = 60, 				--"Clench",
	[26064] = 60, 				--"Shell Shield",
	[35346] = 15, 				--"Time Warp",
	[93433] = 30,				--"Burrow Attack",
	[91644] = 60,				--"Snatch",
	[54644] = 10,				--"Frost Breath",
	[34889] = 30,				--"Fire Breath",
	[50479] = 40,				--"Nether Shock",
	[50518] = 15,				--"Ravage",
	[35387] = 6, 				--"Corrosive Spit",
	[54706] = 40,				--"Vemom Web Spray",
	[4167] = 40,				--"Web",
	[50274] = 12,				--"Spore Cloud",
	[24844] = 30, 				--"Lightning Breath",
	[90355] = 360,				--"Ancient Hysteria",
	[54680] = 8,				--"Monstrous Bite",
	[90314] = 25,				--"Tailspin",
	[50271] = 10, 				--"Tendon Rip",
	[50318] = 60,				--"Serenity Dust",
	[50498] = 6, 				--"Tear Armor",
	[90361] = 40,				--"Spirit Mend",
	[50285] = 40, 				--"Dust Cloud",
	[56626] = 45,				--"Sting",
	[24604] = 45,				--"Furious Howl",
	[90309] = 45,				--"Terrifying Roar",
	[24423] = 10,				--"Demoralizing Screech",
	[93435] = 45,				--"Roar of Courage",
	[58604] = 8,				--"Lava Breath",
	[90327] = 40,				--"Lock Jaw",
	[90337] = 60,				--"Bad Manner",
	[53490] = 180,				--"Bullheaded",
	[23145] = 32,				--"Dive",
	[55709] = 480,				--"Heart of the Phoenix",
	[53426] = 180,				--"Lick Your Wounds",
	[53401] = 45, 				--"Rabid",
	[53476] = 30,				--"Intervene",
	[53480] = 60,				--"Roar of Sacrifice",
	[53478] = 360,				--"Last Stand",
	[53517] = 180,				--"Roar of Recovery",

	--------------------------------------------------------------------------
	--Pets(Warlock)
	[19647] = 24,				--"Spell Lock",
	[7812] = 60,				--"Sacrifice",
	[89766] = 30,				--"Axe Toss"
	[89751] = 45,				--"Felstorm",

	--------------------------------------------------------------------------
	--Pets(Mage)
	[33395] = 25,				--"Freeze", --No way to tell which WE cast this still usefull to some degree.

	--------------------------------------------------------------------------
	--Death Knight
	-- abilities
	[49576] = 25,				--"Death Grip",	
	[46584] = 120,				--"Raise Dead",
	[47528] = 15,				--"Mind Freeze",
	[47476] = 60,				--"Strangulate",
	[43265] = 30,				--"Death and Decay",
	[48792] = 180,				--"Icebound Fortitude",
	[48707] = 45,				--"Anti-Magic Shell",
	[47568] = 300,				--"Empower Rune Weapon",
	[77606] = 60,				--"Dark Simulakrum",

	-- talents
	[51052] = 120,				--"Anti-Magic Zone",
	[49039] = 120,				--"Lichborne",
	[114556] = 180,				--"Purgatory",
	[108194] = 60,				--"Asphyxiate",
	[96268] = 30,				--"Death's Advance",
	[48743] = 120,				--"Death Packt",
	[108201] = 120,				--"Desecrated Ground",
	[108199] = 60,				--"Gorefiend's Grasp",
	[108200] = 60,				--"Remorseless Winter",

	-- specialization
	[49222] = 60,				--"Bone Shield",
	[49028] = 90,				--"Dancing Rune Weapon",
	[51271] = 60,				--"Pillar of Frost",
	[49206] = 180,				--"Summon Gargoyle",
	[49016] = 180,				--"Unholy Frenzy",
	[55233] = 60,				--"Vampiric Blood",

	--------------------------------------------------------------------------
	--Druid
	-- abilities
	[102543] = 180,				-- Incarnation: King of the Jungle
	[102558] = 180,				-- Incarnation: Son of Ursoc
	[339] = 30,					-- Entangling Roots
	[102560] = 180,				-- Incarnation: Chosen of Elune
	[1850] = 180,				-- Dash
	[22812] = 60,				-- Barkskin
	[16689] = 60,				-- Nature's Grasp
	[29116] = 180,				-- Innervate
	[22842] = 90,				-- Frenzied Regeneration
	[106922] = 180,				-- Might of Ursoc
	[740] = 480,				-- Tranquility
	[77761] = 120,				-- Stampeding Roar

	-- talents
	[102280] = 30,				-- Displacer Beast
	[102401] = 15,				-- Wild Charge
	[102351] = 30,				-- Cenarion Ward
	[132158] = 60,				-- Nature's Swiftness
	[108238] = 120,				-- Renewal
	[102359] = 120,				-- Mass Entanglement
	[132469] = 20,				-- Typhoon
	[106737] = 60,				-- Force of Nature
	[106731] = 180,				-- Incarnation
	[99] = 30,					-- Disorienting Roar
	[5211] = 50,				-- Mighty Bash
	[102793] = 60,				-- Ursol's Vortex
	[108288] = 360,				-- Heart of the Wild
	[124974] = 300,				-- Nature's Vigil

	-- specialization
	[102795] = 60,				-- Bear Hug
	[106952] = 180,				-- Berserk
	[112071] = 180,				-- Celestial Alignment
	[102342] = 120,				-- Ironbark
	[88432] = 8,				-- Nature's Cure
	[2782] = 8,					-- Remove Corruption
	[106839] = 15,				-- Skull Bash
	[78675] = 60,				-- Solar Beam
	[48505] = 90,				-- Starfall
	[78674] = 15,				-- Starsurge
	[61336] = 180,				-- Survival Instincts

	--------------------------------------------------------------------------
	--Hunter
	-- abilities
	[781] = 25,					-- Disengage
	[19503] = 30,				-- Scatter Shot
	[1499] = 30,				-- Freezing Trap
	[5384] = 30,				-- Feign Death
	[1543] = 20,				-- Flare
	[13809] = 30,				-- Ice Trap
	[3045] = 180,				-- Rapid Fire
	[23989] = 300,				-- Readiness
	[34600] = 30,				-- Snake Trap
	[53271] = 45,				-- Master's Call
	[19263] = 120,				-- Deterrence
	[51753] = 60,				-- Camouflage
	[121818] = 300,				-- Stampede

	-- talents
	[109248] = 45,				-- Binding Shot
	[34490] = 20,				-- Silencing Shot
	[19386] = 60,				-- Wyvern Sting
	[109304] = 120,				-- Exhilaration
	[120679] = 30,				-- Dire Beast
	[131894] = 120,				-- A Murder of Crows
	[130392] = 20,				-- Blink Strike
	[120679] = 90,				-- Lynx Rush
	[120360] = 30,				-- Barrage
	[109259] = 60,				-- Powershot

	-- specialization
	[19574] = 60,				-- Bestial Wrath
	[19577] = 60,				-- Intimidation

	--------------------------------------------------------------------------
	--Mage
	-- abilities
	[1953] = 15,				-- Blink
	[122] = 25,					-- Frost Nova
	[2139] = 24,				-- Counterspell
	[45438] = 300,				-- Ice Block
	[475] = 8,					-- Remove Curse
	[12051] = 120,				-- Evocation
	[55342] = 180,				-- Mirror Image
	[66] = 300,					-- Invisibility
	[44572] = 30,				-- Deep Freeze
	[120] = 8,                  -- Cone of Cold

	-- talents
	[108839] = 60,				-- Ice Floes
	[12043] = 90,				-- Presence of Mind
	[108843] = 25,				-- Blazing Speed
	[11426] = 25,				-- Ice Barrier
	[115610] = 25,				-- Temporal Shield
	[102051] = 20,				-- Frostjaw
	[113724] = 30,				-- Ring of Frost
	[86949] = 120,				-- Cautarize
	[11958] = 180,				-- Cold Snap
	[110959] = 150,				-- Greater Invisibility
	[112948] = 10,				-- Frost Bomb
	[116011] = 6,				-- Rune of Power

	-- specialization
	[12042] = 90,				-- Arcane Power
	[11129] = 45,				-- Combustion
	[84714] = 60,				-- Frozen Orb
	[12472] = 180,				-- Icy Veins
	[31687] = 60,				-- Summon Water Elemental
	[31661] = 20,				-- Dragon's Breath

	--------------------------------------------------------------------------
	--Paladin
	-- abilities
	[853] = 60,					-- Hammer of Justice
	[642] = 300,				-- Divine Shield
	[4987] = 8,					-- Cleanse
	[498] = 60,					-- Divine Protection
	[96231] = 15,				-- Rebuke
	[1022] = 300,				-- Hand of Protection
	[1044] = 25,				-- Hand of Freedom
	[31821] = 180,				-- Devotion Aura
	[31884] = 180,				-- Avenging Wrath
	[6940] = 120,				-- Hand of Sacrifice
	[115750] = 120,				-- Blinding Light

	-- talents
	[85499] = 45,				-- Speed of Light
	[105593] = 30,				-- First of Justice
	[20066] = 15,				-- Repentance
	[114039] = 30,				-- Hand of Purity
	[105809] = 120,				-- Holy Avenger

	-- specialization
	[31850] = 180, 				-- Ardent Defender
	[31935] = 15,				-- Avenger's Shield
	[54428] = 120,				-- Devine Plea

	--------------------------------------------------------------------------
	--Priest
	-- abilities
	[8122] = 30,				-- Psychic Scream
	[528] = 8,					-- Dispel Magic
	[586] = 30,					-- Fade
	[34433] = 180,				-- Shadowfiend
	[6346] = 180,				-- Fear Ward
	[64901] = 360,				-- Hymn of Hope
	[32375] = 15,				-- Mass Dispell
	[73325] = 90,				-- Leap of Faith
	[108968] = 360,				-- Void Shift

	-- talents
	[605] = 30,					-- Dominate Mind
	[108921] = 45,				-- Psyfiend
	[108920] = 30,				-- Void Tendrils
	[123040] = 60,				-- Mindbender
	[19236] = 120,				-- Desperate Prayer
	[112883] = 30,				-- Spectral Guise
	[10060] = 120,				-- Power Infusion

	-- specialization
	[47585] = 120,				-- Dispersion
	[64843] = 180,				-- Devine Hymn
	[47788] = 180,				-- Guardian Spirit
	[88625] = 30,				-- Holy Word: Chastise
	[89485] = 45,				-- Inner Focus
	[724] = 180,				-- Light Well
	[33206] = 180,				-- Pain Suppression
	[62618] = 180,				-- Power Word: Barrier
	[64044] = 45,				-- Psychic Horror
	[527] = 8,					-- Purify
	[15487] = 45,				-- Silence
	[109964] = 60,				-- Spirit Shell

	--------------------------------------------------------------------------
	--Monk
	-- abilities
	[116705] = 15,		-- Spear Hand Strike
	[115203] = 180,		-- Fortifying Brew
	[101643] = 45,		-- Transcendence
	[119996] = 25,		-- Transcendence: Transfer
	[117368] = 60,		-- Grapple Weapon
	[115078] = 15,		-- Paralysis
	[137562] = 120,		-- Nimble Brew
	-- talents
	[116841] = 30,		-- Tiger's Lust
	[115399] = 90,		-- Chi Brew
	[116844] = 45,		-- Ring of Peace
	[119392] = 30,		-- Charging Ox Wave
	[119381] = 45,		-- Leg Sweep
	[122278] = 90,		-- Dampen Harm
	[122783] = 90,		-- Diffuse Magic
	[116847] = 30,		-- Rushing Jade Wind
	[123904] = 180,		-- Invoke Xuen, the White Tiger
	-- specialization
	[115288] = 60,		-- Energizing Brew
	[122470] = 90,		-- Touch of Karma
	[115176] = 180,		-- Zen Meditation
	[113656] = 25,		-- Fists of Fury

	--------------------------------------------------------------------------
	--Rogue
	-- abilities
	[2094] = 180,				--"Blind",
	[1766] = 15,				--"Kick",
	[1776] = 10,				--"Gauge",
	[2983] = 60,				--"Sprint",
	[31224] = 120,				--"Cloak of Shadows",
	[5938] = 10,				--"Shiv",
	[1856] = 180,				--"Vanish",
	[5277] = 180,				--"Evasion",
	[408] = 20,					--"Kidney Shot",
	[51722] = 60,				--"Dismantle",
	[114842] = 60,				--"Shadow Walk",
	[114018] = 300,				--"Shroud of Concealment",
	[73981] = 60,				--"Redirect" (talented: w/o cooldown)
	[76577] = 180,				--"Smoke Bomb",
	[121471] = 180,				--"Shadow Blades",

	-- talents
	[14185] = 300,				--"Preparation", (sprint, vanish, cloak, evasion, dismantle)
	[36554] = 24,				--"Shadowstep",
	[74001] = 120,				--"Combat Readiness",
	[31230] = 90,				--"Cheat Death",

	-- specialization
	[79140] = 120,				--"Vendetta",
	[51690] = 120,				--"Killing Spree",
	[51713] = 60, 				--"Shadow Dance",
	[13750] = 180,				--"Adrenaline Rush",
	[14183] = 20,				--"Premeditation",

	--------------------------------------------------------------------------
	--Shaman
	-- abilities
	[57994] = 12,				-- Wind Shear
	[51886] = 8,				-- Cleanse Spirit
	[8056] = 6,					-- Frost Shock
	[8711] = 25,				-- Grounding Totem
	[8143] = 60,				-- Tremor Totem
	[51514] = 45,				-- Hex
	[79206] = 120,				-- Spiritwalker's Grace
	[114049] = 180,				-- Ascendance

	-- talents
	[108271] = 120,				-- Astral Shift
	[51485] = 30,				-- Earthgrab Totem
	[108273] = 60,				-- Windwalk Totem
	[108285] = 180,				-- Call of the Elements
	[16188] = 60,				-- Ancestral Swiftness
	[16166] = 120,				-- Elemental Mastery
	[108281] = 120,				-- Ancestral Guidance

	-- specialization
	[16190] = 180,				-- Mana Tide Totem
	[77130] = 8,				-- Purify Spirit
	[30823] = 60,				-- Shamanistic Rage
	[98008] = 180,				-- Spirit Link Totem
	[58875] = 120,				-- Spirit Walk
	[51490] = 45,				-- Thunderstorm

	--------------------------------------------------------------------------
	--Warlock
	-- talents
	[103135] = 24,				-- Felhunter: Spell Lock
	[48020] = 30,				-- Demonic Circle: Teleport
	[48018] = 360,				-- Demonic Circle: Summon (this is not a cooldown, but the time the portal is alive)
	[77801] = 120,				-- Dark Soul

	-- abilities
	[108359] = 120,				-- Dark Regeneration
	[5484] = 40,				-- Howl of Terror
	[6789] = 45,				-- Mortal Coil
	[30283] = 30,				-- Shadowfury
	[110913] = 180,				-- Dark Bargain
	[108416] = 60,				-- Sacrificial Pact
	[111397] = 10,				-- Blood Fear
	[108482] = 60,				-- Unbound Will
	[108503] = 120,				-- Grimoire of Sacrifice
	[108501] = 120,				-- Grimoire of Service
	[108505] = 120,				-- Archimonde's Vengeance
	[119049] = 60,				-- Kil'jaeden's Cunning

	-- specialization
	[109151] = 10,				-- Demonic Leap

	--------------------------------------------------------------------------
	--Warrior
	-- abilities
	[100] = 13,					-- Charge
	[57755] = 30,				-- Heroic Throw
	[6552] = 15,				-- Pummel
	[676] = 60,					-- Disarm
	[871] = 300,				-- Shield Wall
	[5246] = 60,				-- Intimidating Shout
	[18499] = 30,				-- Berserker Rage
	[1719] = 300,				-- Recklesness
	[23920] = 25,				-- Spell Reflection
	[3411] = 30,				-- Intervene
	[64382] = 300,				-- Shattering Throw
	[6544] = 45,				-- Heroic Leap

	-- talents
	[55694] = 60,				-- Enraged Regeneration
	[102060] = 40,				-- Disrupting Shout
	[107566] = 40,				-- Staggering Shout
	[46924] = 90,				-- Bladestorm
	[46968] = 20,				-- Shockwave
	[114028] = 60,				-- Mass Spell Reflection
	[114029] = 30,				-- Safeguard
	[114030] = 120,				-- Vigilance
	[107574] = 180,				-- Avatar
	[107570] = 30,				-- Storm Bolt

	-- specialization
	[12975] = 180,				-- Last Stand
}