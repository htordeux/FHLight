--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local LOG = jps.Logger(jps.LogLevel.ERROR)
local GetSpellInfo = GetSpellInfo
local IsSpellInRange = IsSpellInRange
local SpellHasRange = SpellHasRange
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetUnitName = GetUnitName
local UnitExists = UnitExists
local UnitIsVisible = UnitIsVisible
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitCanAssist = UnitCanAssist
local UnitInVehicle = UnitInVehicle
local UnitCanAttack = UnitCanAttack
local SpellIsTargeting = SpellIsTargeting
local CastSpellByName = CastSpellByName

local strfind = string.find
local tinsert = table.insert
local tremove = table.remove

----------------------------
-- Blacklistplayer functions 
-- These functions will blacklist a target for a set time.
----------------------------

jps.BlacklistTimer = 1

jps.UpdateHealerBlacklist = function(self)
	if #jps.HealerBlacklist > 0 then
		for i = #jps.HealerBlacklist, 1, -1 do
			if GetTime() - jps.HealerBlacklist[i][2] > jps.BlacklistTimer then
				if jps.Debug then print("Releasing ", jps.HealerBlacklist[i][1]) end
				tremove(jps.HealerBlacklist,i)
			end
		end
	end
end

jps.PlayerIsBlacklisted = function(unit)
	for i = 1, #jps.HealerBlacklist do
		if jps.HealerBlacklist[i][1] == unit then
			return true
		end
	end
	return false
end

jps.BlacklistPlayer = function(unit)
	if unit ~= nil then
	local playerexclude = {}
	tinsert(playerexclude, unit)
	tinsert(playerexclude, GetTime())
	tinsert(jps.HealerBlacklist,playerexclude)
	if jps.Debug then print("|cffa335eeBlacklisting", unit) end
	end

end

--------------------------
-- Functions CAST
--------------------------
-- GetSpellInfo -- name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId or spellName)
-- IsHarmfulSpell(spellname) -- IsHelpfulSpell(spellname)) returns 1 or nil -- USELESS SOMES SPELLS RETURNS NIL AS OUBLI, SPIRIT SHELL
-- IsSpellInRange(spellID, spellType, unit) -- spellType String, "spell" or "pet"
-- IsSpellInRange(spellName, unit) -- returns 0 if out of range, 1 if in range, or nil if the unit is invalid.
local jps_IsSpellInRange = function(spell,unit)
	if spell == nil then return false end
	if unit == nil then unit = "target" end
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end

	local inRange = IsSpellInRange(spellname, unit)

	if inRange == nil then
		local myIndex = nil
		local name, texture, offset, numSpells, isGuild = GetSpellTabInfo(2)
		local booktype = "spell"
		for index = offset+1, numSpells+offset do
			-- Get the Global Spell ID from the Player's spellbook
			local spellID = select(2, GetSpellBookItemInfo(index, booktype))
			if spellID and spellname == GetSpellBookItemName(index, booktype) then
				myIndex = index
				break -- because we have a match
			end
		end
		-- If a Pet Spellbook is found, do the same as above and try to get an Index on the Spell
		local numPetSpells = HasPetSpells()
		if myIndex == 0 and numPetSpells then
			booktype = "pet"
			for index = 1, numPetSpells do
				-- Get the Global Spell ID from the Pet's spellbook
				local spellID = select(2, GetSpellBookItemInfo(index, booktype))
				if spellID and spellname == GetSpellBookItemName(index, booktype) then
					myIndex = index
					break -- Breaking out of the for/do loop, because we have a match
				end
			end
		end

		if myIndex then
			inRange = IsSpellInRange(myIndex, booktype, unit)
		end
		return inRange
	end
	return inRange
end

function jps.IsSpellInRange(spell,unit)
	if spell == nil then return false end
	if jps_IsSpellInRange(spell,unit)==0 then return false end
	return true
end

-- Collecting the Spell GLOBAL SpellID, not to be confused with the SpellID
-- Matching the Spell Name and the GLOBAL SpellID will give us the Spellbook index of the Spell
-- With the Spellbook index, we can then proceed to do a proper IsSpellInRange with the index.
local jps_SpellHasRange = function(spell)
	if spell == nil then return false end
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end

	local hasRange = SpellHasRange(spellname)

	if hasRange == nil then
		local myIndex = nil
		local name, texture, offset, numSpells, isGuild = GetSpellTabInfo(2)
		local booktype = "spell"
		for index = offset+1, numSpells+offset do
			-- Get the Global Spell ID from the Player's spellbook
			local spellID = select(2, GetSpellBookItemInfo(index, booktype))
			if spellID and spellname == GetSpellBookItemName(index, booktype) then
				myIndex = index
				break -- Breaking out of the for/do loop, because we have a match
			end
		end

		if myIndex then
			hasRange= SpellHasRange(myIndex, booktype)
		end
		return hasRange
	end
	return hasRange
end

function jps.SpellHasRange(spell)
	if spell == nil then return false end
	if jps_SpellHasRange(spell)~=1 then return false end
	return true
end

function jps.UnitExists(unit)
	if unit == nil then return false end
	if UnitExists(unit)~=1 then return false end
	if UnitIsVisible(unit)~=1 then return false end
	if UnitIsDeadOrGhost(unit)==1 then return false end
	return true
end

-- UnitInRange(unit) -- returns FALSE if out of range or if the unit is invalid. TRUE if in range
-- information is ONLY AVAILABLE FOR MEMBERS OF THE PLAYER'S GROUP
-- when not in a party/raid, the new version of UnitInRange returns FALSE for "player" and "pet". The old function returned true.
function jps.canHeal(unit)
	if not jps.UnitExists(unit) then return false end
	if GetUnitName("player") == GetUnitName(unit) then return true end
	if not select(1,UnitInRange(unit)) then return false end 
	-- return FALSE when not in a party/raid reason why to be true for player GetUnitName("player") == GetUnitName(unit)
	if UnitCanAssist("player",unit)~=1 then return false end 
	-- UnitCanAssist(unitToAssist, unitToBeAssisted) return 1 if the unitToAssist can assist the unitToBeAssisted, nil otherwise. PNJ returns 1 or nil (Vendors) with UnitCanAssist
	if UnitIsFriend("player",unit)~=1 then return false end 
	-- UnitIsFriend("unit","otherunit") return 1 if otherunit is friendly to unit, nil otherwise. PNJ returns 1 with UnitIsFriend
	if UnitInVehicle(unit)==1 then return false end -- inVehicle - 1 if the unit is in a vehicle, otherwise nil
	if jps.PlayerIsBlacklisted(unit) then return false end
	return true
end

-- WORKING ONLY FOR PARTYn..TARGET AND RAIDn..TARGET NOT FOR UNITNAME..TARGET
-- CHECK IF WE CAN DAMAGE A UNIT
local iceblock = tostring(select(1,GetSpellInfo(45438))) -- ice block mage
local divineshield = tostring(select(1,GetSpellInfo(642))) -- divine shield paladin
function jps.canDPS(unit)
	if not jps.UnitExists(unit) then return false end
	-- if UnitIsEnemy("player",unit)~=1 then return false end
	-- WARNING a unit is hostile to you or not Returns either 1 ot nil -- Raider's Training returns nil with UnitIsEnemy
	if jps.buff(divineshield,unit) then return false end
	if jps.buff(iceblock,unit) then return false end
	if UnitCanAttack("player", unit)~=1 then return false end-- UnitCanAttack(attacker, attacked) return 1 if the attacker can attack the attacked, nil otherwise.
	if jps.PlayerIsBlacklisted(unit) then return false end
	if not jps.IsSpellInRange(jps.HarmSpell,unit) then return false end
	return true
end

local battleRezSpells = {
tostring(select(1,GetSpellInfo(20484))), -- Druid: Rebirth
tostring(select(1,GetSpellInfo(61999))), -- DK: Raise Ally
tostring(select(1,GetSpellInfo(20707))), -- Warlock: Soulstone
tostring(select(1,GetSpellInfo(126393))) -- Hunter: Eternal Guardian
}
local function isBattleRez(spell)
    for _,v in ipairs(battleRezSpells) do
        if v == spell then return true end
    end
    return false
end

-------------------------
-- CANCAST SPELL
-------------------------

-- check if a spell is castable @ unit 
function jps.canCast(spell,unit)
	if spell == "" then return false end
	if unit == nil then unit = "target" end
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	
	if spellname == nil then return false end
	if jps.PlayerIsBlacklisted(unit) then return false end
	if not jps.UnitExists(unit) and not isBattleRez(spellname) then return false end -- isBattleRez need spellname
	
	local usable, nomana = IsUsableSpell(spell) -- usable, nomana = IsUsableSpell("spellName" or spellID)
	if not usable then return false end
	if nomana then return false end
	if jps.cooldown(spellname) > 0 then return false end
	if jps.SpellHasRange(spell) and not jps.IsSpellInRange(spell,unit) then return false end
	if jps[spellname] ~= nil and jps[spellname] == false then return false end -- need spellname
	return true
end

----------------------
-- CAST
----------------------
-- "Death and Decay" 43265 -- DK
-- "Mass Dispel" 32375 -- Priest
-- "Power Word: Barrier" 62618 -- Priest
-- "Flamestrike" 2120 -- Mage
-- "Rain of Fire" 104233 -- Mage
-- "Dizzying Haze" 118022 -- Brewmaster
-- "Light's Hammer" 114158 -- Paladin
-- "Healing Rain" 73921 -- Shaman
-- "wild mushroom" 88747 -- Druid
-- "Explosive Trap" 13813 - Hunter
-- "Ice Trap" 13809 - Hunter
-- "Snake Trap" 34600 - Hunter
-- "Freezing Trap" 1499 - Hunter
-- "Summon Jade Serpent Statue" - 115313 Monk
-- "Healing Sphere" - 115460 Monk
-- "demoralizing banner" - 114203 warrior
-- "mocking banner" - 114192 warrior 
-- "heroic leap" - 6544 warrior
-- "Freeze" - 33395 Frost Mage
-- "Rune Of Power" 116011- Mage
-- "Rain of Fire" 5740 -- Warlock
-- "Lightwell" 724 - Priest
-- "Holy Word: Sanctuary" 88685 - Priest
-- "Shadowfury" 30283 - Warlock
-- "Psyfiend" 108921 - Priest
-- "Plume angélique" 121536 - Priest

local spellNeedSelectTable = {121536,108921,30283,88685,724,32375,43265,62618,2120,104233,118022,114158,73921,88747, 13813, 13809, 34600, 1499, 115313, 115460, 114203, 114192, 6544, 33395, 116011, 5740}
function jps.spellNeedSelect(spell)
	local spellname = nil
	if type(spell) == "string" then spellname = string.lower(spell) end
	if type(spell) == "number" then spellname = string.lower(tostring(select(1,GetSpellInfo(spell)))) end

	for i,j in ipairs (spellNeedSelectTable) do
		if spellname == string.lower(tostring(select(1,GetSpellInfo(j)))) then return true end 
	end
	return false
end

local UserInitiatedSpellsToIgnore = {
	-- General Skills
	6603, -- Auto Attack (prevents from toggling on/off)
	-- Monk Skills
	109132, -- Roll (Unless you want to roll off cliffs, leave this here)
	137639, -- Storm, Earth, and Fire (prevents you from destroying your copy as soon as you make it)
	115450, -- Detox (when casting Detox without any dispellable debuffs, the cooldown resets)
	119582, -- Purifying Brew (having more than 1 chi, this can prevent using it twice in a row)
	115008, -- Chi Torpedo (same as roll)
	101545, -- Flying Serpent Kick (prevents you from landing as soon as you start "flying")
	115921, -- Legacy of The Emperor
	116781, -- Legacy of the White Tiger
	115072, -- Expel Harm (below 35%, brewmasters ignores cooldown on this spell)
	115181, -- Breath of Fire (if you are chi capped, this can make you burn all your chi)
	115546, -- Provoke (prevents you from wasting your taunt)
	116740, -- Tigereye Brew (prevents you from wasting your stacks and resetting your buff)
	115294, -- Mana Tea (This isn't an instant cast, but since it only has a 0.5 channeled time, it can triggers twice in the rotation)
	111400, -- warlock burning rush
	108978, --alter time
	12051, 	--evocation
	
}

function jps.isRecast(spell,unit)
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	
	if unit==nil then unit = "target" end
	
	return jps.LastCast==spellname and UnitGUID(unit)==jps.LastTargetGUID
end

function jps.shouldSpellBeIgnored(spell)
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	if not spellname then return false end
	spellname = spellname:lower()
	local result = false
	for _, v in pairs(UserInitiatedSpellsToIgnore) do
		if spellname == string.lower(tostring(select(1,GetSpellInfo(v)))) then
			return true
		end
	end
	return false
end

----------------------
-- DEBUG MODE
----------------------`

function jps_canHeal_debug(unit)
	if not jps.UnitExists(unit) then write("not Unit") return false end
	if GetUnitName("player") == GetUnitName(unit) then write("Player") return true end
	if UnitCanAssist("player",unit)~=1 then write("not Friend") return false end
	if UnitInVehicle(unit)==1 then write("in Vehicle") return false end
	if jps.PlayerIsBlacklisted(unit) then write("Blacklist") return false end
	if not select(1,UnitInRange(unit)) then write("not inRange") return false end
	write("Passed all tests canHeal".."|cffa335ee"..unit)
	return true
end

function jps_canCast_debug(spell,unit) -- NEED A SPELLNAME
	LOG.info("Can Cast Debug for %s @ $s ", spell, unit)
	if spell == nil then LOG.info("spell is nil  %s @ $s", spell, unit)return false end
	if not jps.UnitExists(unit) then LOG.info("invalid unit  %s @ $s", spell, unit) return false end

	local usable, nomana = IsUsableSpell(spell) -- IsUsableSpell("spellName" or spellID)
	if not usable then LOG.info("spell is not usable  %s @ $s", spell, unit) return false end
	if nomana then LOG.info("failed mana test  %s @ $s", spell, unit) return false end
	if jps.cooldown(spell) > 0 then LOG.info("cooldown not finished  %s @ $s", spell, unit) return false end
	if jps_SpellHasRange(spell)~=1 then LOG.info("spellhasRange check failed  %s @ $s", spell, unit) return false end

	if jps_IsSpellInRange(spell,unit)~=1 then LOG.info("not in range  %s @ $s", spell, unit) return false end
	LOG.info("Passed all tests  %s @ $s", spell, unit)
	return true
end

------------------------------
-- PLUA PROTECTED
------------------------------

local knownTypes = {[0]="player", [1]="world object", [3]="NPC", [4]="pet", [5]="vehicle"}
jps.UnitType = function (unit)
	if not jps.UnitExists(unit) then return false end
	local UnitGuid = UnitGUID(unit)
	local knownType = tonumber(UnitGuid:sub(5,5), 16) % 8
	return knownTypes[knownType]
end

local fh = {}
function fh.groundClick(spell,unit)
	if unit == nil then unit = "player" end
	local UnitGuid = UnitGUID(unit)
	local knownTypes = {[0]="player", [1]="world object", [3]="NPC", [4]="pet", [5]="vehicle"}

	if FireHack and UnitGuid ~= nil then
		local knownType = tonumber(UnitGuid:sub(5,5), 16) % 8
		if (knownTypes[knownType] ~= nil) then
			local UnitObject = GetObjectFromGUID(UnitGuid)
			UnitObject:CastSpellByName(spell)
		end
	end
end

function jps.groundClick(spellname)
	SetCVar("deselectOnClick", "0") --	jps.Macro("/console deselectOnClick 0")
	if jps.UnitExists("mouseover") then CastSpellByName(spellname) end
	SetCVar("deselectOnClick", "1") --	jps.Macro("/console deselectOnClick 1")
end

function jps.faceTarget()
	InteractUnit("target")
end

function jps.moveToTarget()
	InteractUnit("target")
end

function jps.Macro(text)
	RunMacroText(text)
end

----------------------
-- CAST
----------------------

function jps.Cast(spell) -- "number" "string"
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	
	if jps.Target == nil then jps.Target = "target" end

	if jps.spellNeedSelect(spellname) and SpellIsTargeting() then
		if FireHack then
			fh.groundClick(spellname,jps.target)
		else
			jps.groundClick(spellname)
		end
	else 
		CastSpellByName(spellname,jps.Target)
	end

	jps.TimedCasting[string.lower(spellname)] = math.ceil(GetTime())
	jps.LastCast = spellname
	jps.LastTarget = jps.Target
	jps.LastTargetGUID = UnitGUID(jps.Target)
	tinsert(jps.LastMessage,1,jps.Message)
	
	if (jps.IconSpell ~= spellname) then
		jps.set_jps_icon(spellname)
		if jps.Debug then write(spellname,"|cff1eff00",GetUnitName(jps.Target)) end
		if jps.DebugMsg and strfind(jps.Message,"_") then write("|cffffffff",jps.Message) end
	end
	jps.Target = nil
	jps.ThisCast = nil
	jps.Message = ""
end

function jps.myLastCast(spell)
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	if not spellname then return false end
	if jps.CurrentCastInterrupt == spellname then return false end
	
	if jps.CurrentCast == spellname then return true end
	if jps.LastCast == spellname then return true end
	if jps.SentCast == spellname then return true end
	return false
end

local proxy = setmetatable(jps.LastMessage, {__index = function(t, index) return index end})
function jps.FinderLastMessage(message,iter)
	for i=1,#jps.LastMessage do
		if strfind(jps.LastMessage[i],message) then return true end
	end
return false
end