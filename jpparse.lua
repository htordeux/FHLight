--------------------------
-- LOCALIZATION
--------------------------

local LOG = jps.Logger(jps.LogLevel.ERROR)
local IsSpellInRange = IsSpellInRange
local SpellHasRange = SpellHasRange
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetUnitName = GetUnitName
local UnitIsUnit = UnitIsUnit
local UnitExists = UnitExists
local UnitIsVisible = UnitIsVisible
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitCanAssist = UnitCanAssist
local UnitIsFriend = UnitIsFriend
local UnitInVehicle = UnitInVehicle
local UnitCanAttack = UnitCanAttack
local UnitInRange = UnitInRange
local CastSpellByName = CastSpellByName
local UnitGUID = UnitGUID
local strfind = string.find
local tinsert = table.insert
local tremove = table.remove
local tinsert = table.insert
local toSpellName = jps.toSpellName

----------------------------
-- Blacklistplayer Functions 
-- These functions will blacklist a target for a set time.
----------------------------

local CHECK_INTERVAL = 1

jps.UpdateHealerBlacklist = function(self)
	if #jps.HealerBlacklist > 0 then
		for i = #jps.HealerBlacklist, 1, -1 do
			if GetTime() - jps.HealerBlacklist[i][2] > CHECK_INTERVAL then
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
-- CAST FUNCTIONS
--------------------------

-- returns spell cooldown
-- start, duration, enable = GetSpellCooldown("name") or GetSpellCooldown(id)
function jps.cooldown(spell)
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
	local start,duration,_ = GetSpellCooldown(spellname)
	-- if spell is unknown start is nil and cd is 0 => set it to 99 if the spell is unknown
	if start == nil then return 99 end
	local cd = start+duration-GetTime()
	if cd < 0 then return 0 end
	return cd
end

local rc = LibStub("LibRangeCheck-2.0")

--[[[
@function `<UNIT>.distanceMin` - returns the min. approximated distance to the given unit.
]]--
function jps.distanceMin(unit)
    local minRange, maxRange = rc:GetRange(unit)
    if minRange == nil then return 99 end
    return minRange
end

--[[[
@function `<UNIT>.distanceMax` - returns the max. approximated distance to the given unit.
]]--
function jps.distanceMax(unit)
    local minRange, maxRange = rc:GetRange(unit)
    if maxRange == nil then return 99 end
    return maxRange
end

-- IsHarmfulSpell(spellname) -- IsHelpfulSpell(spellname)) returns 1 or nil -- USELESS SOMES SPELLS RETURNS NIL AS OUBLI, SPIRIT SHELL
-- IsSpellInRange(spellID, spellType, unit) -- spellType String, "spell" or "pet"
-- IsSpellInRange(spellName, unit) -- returns 0 if out of range, 1 if in range, or nil if the unit is invalid.
local UnitIsSpellInRange = function(spell,unit)
	if unit == nil then unit = "target" end
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	
	local inRange = IsSpellInRange(spellname, unit) -- returns 1,0,nil
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
		if numPetSpells then
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
	end
	return inRange
end


jps.IsSpellInRange = function(spell,unit)
	local inrange = UnitIsSpellInRange(spell,unit)
	if inrange == 0 then return false end
	return true
end

-- Collecting the Spell GLOBAL SpellID, not to be confused with the SpellID
-- Matching the Spell Name and the GLOBAL SpellID will give us the Spellbook index of the Spell
-- With the Spellbook index, we can then proceed to do a proper IsSpellInRange with the index.
jps.SpellHasRange = function(spell)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end

	local hasRange = SpellHasRange(spellname) -- True/False
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
	end
	return hasRange
end

local buffImmune = {
	45438, 	-- ice block mage
	642, 	-- divine shield paladin
	23920, 	-- Spell Reflection 23920 -- Spell Reflection Reflects a spell cast on you -- Dispel type n/a
	110617, -- Deterrence 110617 -- reduces the chance ranged attacks will hit you by 100% and grants a 100% chance to deflect spells -- Dispel type	n/a
	48707, 	-- Anti-Magic Shell 48707 -- Absorbing up to 75 magic damage. Immune to magic debuffs -- Dispel type	n/a
}

local UnitHasImmuneBuff = function(unit)
	for i=1,#buffImmune do
		local buff = buffImmune[i]
		if jps.buff(buff,unit) then return true end
	end
	return false
end

-- UnitIsDeadOrGhost(unit) Returns false for priests who are currently in [Spirit of Redemption] form, having died once and are about to die again
function jps.UnitExists(unit)
	if unit == nil then return false end
	if not UnitExists(unit) then return false end
	if not UnitIsVisible(unit) then return false end
	if UnitIsDeadOrGhost(unit) then return false end
	return true
end

-- UnitInRange(unit) -- returns FALSE if out of range or if the unit is invalid. TRUE if in range
-- information is ONLY AVAILABLE FOR MEMBERS OF THE PLAYER'S GROUP
-- when not in a party/raid, the new version of UnitInRange returns FALSE for "player" and "pet". The old function returned true.
-- UnitInRange return FALSE when not in a party/raid

local SpiritOfRedemption = jps.toSpellName(20711)
local UnitHasBuff = function(spell,unit)
    local spellname = tostring(spell)
    if spellname == nil then return false end
    if select(1,UnitBuff(unit,spellname)) ~= nil then return true end
    return false
end
function jps.canHeal(unit)
	if unit == "player" and UnitHasBuff(SpiritOfRedemption,"player") then return false end -- UnitIsDeadOrGhost(unit) Returns false for priests who are currently in [Spirit of Redemption] form
	if unit == "player" and not UnitIsDeadOrGhost("player") then return true end
	if unit == "target" and UnitCanAssist("player","target") and UnitIsFriend("player","target") then return true end
	if unit == "focus" and UnitCanAssist("player","focus") and UnitIsFriend("player","focus") then return true end
    if not jps.UnitExists(unit) then return false end
	if UnitInVehicle(unit) then return false end
	if jps.PlayerIsBlacklisted(unit) then return false end
	if not UnitCanAssist("player",unit) then return false end
	if not UnitIsFriend("player",unit) then return false end
	local inRange,_ = UnitInRange(unit)
	if not inRange then return false end
	return true
end

-- WORKING ONLY FOR PARTYn..TARGET AND RAIDn..TARGET NOT FOR UNITNAME..TARGET
-- CHECK IF WE CAN DAMAGE A UNIT
-- WARNING a unit is hostile to you or not Returns either 1 ot nil -- Raider's Training returns nil with UnitIsEnemy
function jps.canDPS(unit)
	if not jps.UnitExists(unit) then return false end
	if UnitHasImmuneBuff(unit) then return false end
	if not UnitCanAttack("player", unit) then return false end
	if UnitIsFriend("player", unit) then return false end
	if jps.PlayerIsBlacklisted(unit) then return false end
	if not jps.IsSpellInRange(jps.HarmSpell,unit) then return false end
	return true
end

jps.canAttack = function(unit)
	if not jps.canDPS(unit) then return false end
	if not UnitAffectingCombat(unit) then return false end
	return true
end

local battleRezSpells = {
	20484, -- Druid: Rebirth
	61999, -- DK: Raise Ally
	20707, -- Warlock: Soulstone
	126393 -- Hunter: Eternal Guardian
}
local isBattleRez = function (spell)
	for i=1,#battleRezSpells do
		local buff = battleRezSpells[i]
		local unitbuff = GetSpellInfo(buff)
		if unitbuff ~= nil and unitbuff == spell then return true end
	end
    return false
end

-------------------------
-- CANCAST SPELL
-------------------------

-- check if a spell is castable @ unit 
function jps.canCast(spell,unit)
	if unit == nil then unit = "target" end
	local spellname = toSpellName(spell)
	if spellname == nil then return false end

	if jps.PlayerIsBlacklisted(unit) then return false end
	if not jps.UnitExists(unit) and not isBattleRez(spellname) then return false end -- isBattleRez need spellname
	
	local usable, nomana = IsUsableSpell(spell) -- usable, nomana = IsUsableSpell("spellName" or spellID)
	if not usable then return false end
	if nomana then return false end
	if jps.cooldown(spell) > 0 then return false end -- unknown spell returns zero
	if not jps.IsSpellInRange(spell,unit) then return false end
	return true
end

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
-- "Lightwell" 126135 - Priest

local spellNeedSelectTable = {34861,126135,121536,108921,30283,88685,724,32375,43265,62618,2120,104233,118022,114158,73921,
88747,13813,13809,34600,1499,115313,115460,114192,6544,33395,116011,5740}

function jps.spellNeedSelect(spell)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end

	for i=1,#spellNeedSelectTable do
		local spellNeed = spellNeedSelectTable[i]
		local spellSelect = GetSpellInfo(spellNeed)
		if spellSelect ~= nil and spellSelect == spellname then return true end 
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

function jps.shouldSpellBeIgnored(spell)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end

	for i=1,#UserInitiatedSpellsToIgnore do
		local SpellToIgnore = UserInitiatedSpellsToIgnore[i]
		local InitiatedSpell = GetSpellInfo(SpellToIgnore)
		if InitiatedSpell ~= nil and spellname == InitiatedSpell then return true end
	end
	return false
end

------------------------------
-- PLUA PROTECTED
------------------------------

function jps.groundClick(spellname)
	SetCVar("deselectOnClick", "0") --	jps.Macro("/console deselectOnClick 0")
	CameraOrSelectOrMoveStart(1)
	CastSpellByName(spellname)
	CameraOrSelectOrMoveStop(1)
	SetCVar("deselectOnClick", "1") --	jps.Macro("/console deselectOnClick 1")
end

function jps.Macro(text)
	RunMacroText(text)
end

----------------------
-- CAST
----------------------

function jps.Cast(spell) -- "number" "string"
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if jps.Target == nil then jps.Target = "target" end
	
	if jps.spellNeedSelect(spellname) then
		jps.groundClick(spellname)
	else 
		CastSpellByName(spellname,jps.Target)
	end

	if jps.Debug then write(spellname,"|cff1eff00","|",GetUnitName(jps.Target),"|cffffffff","|",jps.Message) end

	jps.TimedCasting[spellname] = math.ceil(GetTime())
	jps.LastCast = spellname
	jps.LastTarget = jps.Target
	jps.LastTargetGUID = UnitGUID(jps.LastTarget)

	if (jps.IconSpell ~= spellname) then
		jps.set_jps_icon(spellname)
	end

	jps.Target = nil
	jps.ThisCast = nil
	jps.Message = ""
end

function jps.LastSpell(spell)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if jps.CurrentCast == "Interrupt" then return false end
	if jps.CurrentCast == spellname then return true end
	if jps.LastCast == spellname then return true end
	return false
end

function jps.isRecast(spell,unit)
	local spellname = toSpellName(spell)
	if unit == nil then unit = "target" end
	if jps.LastSpell(spell) and (UnitGUID(unit) == jps.LastTargetGUID) then return true end
	return false
end

--------------------------------------------------------------------------------------------------------------
-------------------------------------------- PARSE -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

local function fnSpellEval(spell)
    if type(spell) == "function" then return spell()
    else return spell
    end
end

local function fnConditionEval(condition)
    if condition == nil then return true
    elseif type(condition) == "boolean" then return condition
    elseif type(condition) == "number" then return condition ~= 0
    elseif type(condition) == "function" then return condition()
    else return false
    end
end

local function fnTargetEval(target)
    if target == nil then return "target"
    elseif type(target) == "function" then return target()
    else return target
    end
end

local function fnMessageEval(message)
    if type(message) == "string" then return message
    else return ""
    end
end

local function fnMacroEval(macroText,condition)
    if condition then
    	if not jps.Casting then jps.Macro(macroText) -- Avoid interrupt Channeling with Macro
        -- CASTSEQUENCE WORKS ONLY FOR INSTANT CAST SPELL
		-- "#showtooltip\n/cast Frappe du colosse\n/cast Sanguinaire"
		elseif jps.Casting and string.find(macroText,"/stopcasting") ~= nil then
			jps.Macro("/stopcasting")
			if jps.Debug then print("|cffa335eestopcasting") end
		end
	end
end

local function fnCastSequenceEval(condition,spellList)
    local parsedSpellList = {} -- {spell, condition, target}
    if condition then
        for _, spell in pairs(spellList) do
        	table.insert(parsedSpellList, fnSpellEval(spell))
    	end
    end
    return parsedSpellList
end

-------------------------
-- PARSE DYNAMIC
-------------------------

--local readOnly = function(t)
--        local mt = {
--                __index=t,
--                __newindex=function(t, k, v) error("Attempt to modify read-only table", 2) end,
--                __pairs=function() return pairs(t) end,
--                __ipairs=function() return ipairs(t) end,
--                __len=function() return #t end,
--                __metatable=false
--        }
--        return setmetatable({}, mt)
--end

--local readOnly = function(t)
--        local proxy = {}
--        local mt = {
--                __index=t,
--                __newindex=function(t, k, v) error("Attempt to modify read-only table", 2) end,
--        }
--        setmetatable(proxy, mt)
--        return proxy
--end

--local readOnly = function(t)
--    local mt = setmetatable(t, {
--    	__index = function(t, index) return index end,
--    	__newindex=function(t, k, v) print("Attempt to modify read-only table") end,
--    })
--    return mt
--end

--local readOnly = function(t)
--    local mt = {
--    	__index = function(t, index) return index end, -- return rawset(t,index)
--    	__newindex=function(t, k, v) print("Attempt to modify read-only table") end,
--    }
--    return setmetatable(t, mt)
--end

--	proxy = setmetatable(hydraTable, {__index = function(t, index) return index end})
--	proxy = setmetatable(hydraTable, proxy) -- sets proxy to be spellTable's metatable

--	myListOfObjects = {}  
--	setmetatable(myListOfObjects, { __mode = 'v' }) -- myListOfObjects is now weak  
--	myListOfObjects = setmetatable({}, {__mode = 'v' }) -- creation of a weak table

ParseSpellTable = function(hydraTable)

	local spell = nil
	local condition = nil
	local target = nil

	for i=1,#hydraTable do -- for i, spellTable in ipairs(hydraTable) do
		local spellTable = hydraTable[i]
        if type(spellTable) == "function" then spellTable = spellTable() end

		spell = fnSpellEval(spellTable[1])
		condition = fnConditionEval(spellTable[2])
		target = fnTargetEval(spellTable[3])
        jps.Message = fnMessageEval(spellTable[4])

		-- MACRO -- BE SURE THAT CONDITION TAKES CARE OF CANCAST -- TRUE or FALSE NOT NIL
		-- {"macro", condition, "MACRO_TEXT" }
		if spell == "macro" and type(target) == "string"then
			fnMacroEval(target,condition)
		-- NESTED TABLE { "nested" , condition , { nested spell table } }
		elseif spell == "nested" and type(target) == "table" then
			if condition then
				spell,target = ParseSpellTable(target)
			end
		-- CAST SEQUENCE { "castsequence" , condition , {spell_1, spell_2, ...} }
		elseif spell == "castsequence" and type(target) == "table" then
			if condition then jps.castSequence = target end
		end
		-- DEFAULT {spell[[, condition[, target]]}
		-- Return spell if condition are true and spell is castable.
		if spell ~= nil and condition and jps.canCast(spell,target) then
			return spell,target
		end
	end
end

--------------------------------------------------------------------------------------------------------------
-------------------------------------------- PARSE -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

jps.parser = {}

local function fnParseSpell(spell)
    if type(spell) == "function" then return spell()
    else return function () return spell end
    end
end

local function alwaysTrue() return true end
local function alwaysFalse() return false end
local function fnParseCondition(conditions)
    if conditions == nil then return alwaysTrue()
    elseif type(conditions) == "function" then return function() return conditions() end
    elseif type(conditions) == "boolean" then return function() return conditions end
    elseif type(conditions) == "number" then return function() return conditions ~= 0 end
    else return alwaysFalse()
    end
end

local function fnParseTarget(target)
	if target == nil then return function() return "target" end
    elseif type(target) == "function" then return target()
    else return function() return target end
    end
end

local function fnParseDefault(spell, condition, target)
    local spellFn = fnParseSpell(spell)
    local conditionFn = fnParseCondition(condition)
    local targetFn = fnParseTarget(target)
    return function ()
        local spell = spellFn()
        local condition = conditionFn()
        local target = targetFn()
        if spell ~= nil and condition then
            if jps.canCast(spell,target) then
                return spell, target
            end
        end
        return nil, nil
    end
end

function compileSpellTable(hydraTable)
	local compiledTable = {}
	for i=1,#hydraTable do -- for i, spellTable in ipairs(hydraTable) do
		local spellTable = hydraTable[i]
        if type(spellTable) == "function" then spellTable = spellTable() end

		if type(spellTable) == "function" then
            table.insert(compiledTable, spellTable)
		else
			-- DEFAULT {spell[[, condition[, target]]}
			-- Return spell if condition are true and spell is castable.
			table.insert(compiledTable, fnParseDefault(spellTable[1], spellTable[2], spellTable[3]))
		end
	end
	return compiledTable
end

function jps.parser.ParseSpellTable(hydraTable)
    local compiledTable = compileSpellTable(hydraTable)
    return function ()
        for _, spellFn in pairs(compiledTable) do
            local spell, target = spellFn()
            if spell ~= nil and target ~= nil then
                return spell, target
            end
        end
        return nil, nil
    end
end