--[[[
@module Rotation Registry
@description
Rotations are stored in a central registry - each class/spec combination can have multiple Rotations.
Most of the rotations are registered on load, but you can also (un)register Rotations during runtime.
You could even outsource your rotations to a separate addon if you want to.
]]--

local tinsert = table.insert
local ipairs = ipairs
local combatRotations = {}
local oocRotations = {}
local activeRotation = 1
local rotations = {}

local classNames = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER" }

local specNames = {}
specNames[1] = {"ARMS","FURY","PROTECTION"}
specNames[2] = {"HOLY","PROTECTION","RETRIBUTION"}
specNames[3] = {"BEASTMASTERY","MARKSMANSHIP","SURVIVAL"}
specNames[4] = {"ASSASSINATION","OUTLAW","SUBTLETY"}
specNames[5] = {"DISCIPLINE","HOLY","SHADOW"}
specNames[6] = {"BLOOD","FROST","UNHOLY"}
specNames[7] = {"ELEMENTAL","ENHANCEMENT","RESTORATION"}
specNames[8] = {"ARCANE","FIRE","FROST"}
specNames[9] = {"AFFLICTION","DEMONOLOGY","DESTRUCTION"}
specNames[10] = {"BREWMASTER","MISTWEAVER","WINDWALKER"}
specNames[11] = {"BALANCE","FERAL","GUARDIAN","RESTORATION"}
specNames[12] = {"HAVOC","VENGEANCE"}

local specHEAL = {"HOLY", "DISCIPLINE" , "RESTORATION" , "MISTWEAVER" }

local function classToNumber(class)
    if type(class) == "string" then
        className = string.upper(class)
        for k, v in ipairs(classNames) do
            if v == className then return k end
        end
    elseif type(class) == "number" then
        if classNames[class] then return class end
    end
    return nil
end

local function specToNumber(classId, spec)
    if not specNames[classId] then return nil end
    if type(spec) == "string" then
        specName = string.upper(spec)
        for k, v in ipairs(specNames[classId]) do
            if v == specName then return k end
        end
    elseif type(spec) == "number" then
        if specNames[classId][spec] then return class end
    end
    return nil
end

local function toKey(class,spec)
    local classId = classToNumber(class)
    if not classId then return 0 end
    local specId = specToNumber(classId, spec)
    if not specId then return 0 end
    if classId < 1 or classId > 12 then return 0 end
    if classId < 11 and specId > 3 then return 0 end
    if classId == 11 and specId > 4 then return 0 end
    if classId == 12 and specId > 2 then return 0 end
    return classId * 10 + specId
end

local function getCurrentKey()
    _,_,classId = UnitClass("player")
    specId = GetSpecialization() or 0
    return classId * 10 + specId
end

function jps.className()
    local _,_,classId = UnitClass("player")
    return classNames[classId]
end

function jps.specName()
    local _,_,classId = UnitClass("player")
    local specId = GetSpecialization()
    if specId then
        return specNames[classId][specId]
    else
        return "NONE"
    end
end

function jps.isPlayerClass(class)
    local _,_,classId = UnitClass("player")
    return classToNumber(class) == classId
end


local function addRotationToTable(rotations,rotation)
    for k,v in pairs(rotations) do
        if v.tooltip == rotation.tooltip then
            rotations[k] = rotation
            return
        end
    end
    tinsert(rotations, rotation)
end

local function tableCount(rotationTable, key)
    if not rotationTable[key] then return 0 end
    return #(rotationTable[key])
end

--[[[ Internal function: Allows the DropDown to change the active rotation ]]--
function jps.setActiveRotation(idx)
	local maxCount = 0
	local oocCount = tableCount(oocRotations, getCurrentKey())
	local combatCount = tableCount(combatRotations, getCurrentKey())
	if not jps.Combat and oocCount > 0 then maxCount = oocCount
	else maxCount = combatCount end

    if idx < 1 or idx > maxCount then idx = 1 end
    activeRotation = idx
end

--[[[ Internal function: Allows the DropDown to change the active rotation ]]--
function jps.getRotations()
    local key = getCurrentKey()
    if not rotations[key] then rotations[key] = {} end
    return rotations[key]
end

function jps.getRotationCount()
    return tableCount(rotations, getCurrentKey())
end

--function jps.getActiveRotation()
--    if not rotations[getCurrentKey()] or not rotations[getCurrentKey()][activeRotation] then return nil end
--    return rotations[getCurrentKey()][activeRotation]
--end

function jps.registerRotation(class,spec,fn,tooltip,combat,ooc)
    local key = toKey(class, spec)
    if combat == nil then combat = true end
    if ooc == nil then ooc = false end
    if combat and not combatRotations[key] then combatRotations[key] = {} end
    if ooc and not oocRotations[key] then oocRotations[key] = {} end
    local rotation = {tooltip = tooltip, getSpell = fn}
    if combat then addRotationToTable(combatRotations[key], rotation) end
    if ooc then addRotationToTable(oocRotations[key], rotation) end
    jps.resetRotation()
end

function jps.registerParseRotation(class,spec,table,tooltip,combat,ooc)
    local key = toKey(class, spec)
    if combat == nil then combat = true end
    if ooc == nil then ooc = false end
    if combat and not combatRotations[key] then combatRotations[key] = {} end
    if ooc and not oocRotations[key] then oocRotations[key] = {} end
    local rotation = {tooltip = tooltip }
    rotation["getSpell"] = function ()
        rotation.getSpell = jps.parser.ParseSpellTable(table)
        return rotation.getSpell()
    end
    if combat then addRotationToTable(combatRotations[key], rotation) end
    if ooc then addRotationToTable(oocRotations[key], rotation) end
    jps.resetRotation()
end

--[[[ Internal function: Resets the active Rotation, e.g. if the drop down was changed ]]--
function jps.resetRotation()
	jps.initializedRotation = false
    jps.setActiveRotation(activeRotation)
    jps.getActiveRotation(rotationTable)
end

--[[[ Debug Function - prints all Rotations sorted by class and spec ]]--
function jps.printRotations()
    for ci,class in ipairs(classNames) do
        local msg = class .. ": "
        for si,spec in ipairs(specNames[ci]) do
            local key = toKey(class, spec)
            local combatCount = tableCount(combatRotations,key)
            local oocCount = tableCount(oocRotations,key)
            msg = msg .. spec .. "(COMBAT " .. combatCount .. " / OOC " ..oocCount..") "
        end
        print(msg)
    end
end

--[[[
@function jps.registerStaticTable
@description
Short-hand function for registering static spell tables which usually only have a function with [code]return parseStaticSpellTable(spellTable)[/code].
For mor info look at #see:jps.registerRotation.
@param class Uppercase english classname or <a href="http://www.wowpedia.org/ClassId">Class ID</a>
@param spec Uppercase english spec name (no abbreviations!) or spec id
@param spellTabel static spell table
@param tooltip Unique Name for this Rotation
@param pve [i]Optional:[/i] [code]True[/code] if this should be registered as PvE rotation else [code]False[/code] - defaults to  [code]True[/code]
@param ooc [i]Optional:[/i] [code]True[/code] if this should be registered as a out of combat rotation else [code]False[/code] - defaults to  [code]false[/code]
]]--

function jps.hasOOCRotation()
	return tableCount(oocRotations, getCurrentKey())
end

function jps.hasCombatRotation()
	return tableCount(pveRotations, getCurrentKey())
end


--[[[ Internal function: Returns the active Rotation for use in the Combat Loop ]]--
local ToggleRotationName = {}
function jps.getActiveRotation(rotationTable)
    if rotationTable == nil then
	    if not jps.Combat and jps.hasOOCRotation() > 0 then return jps.getActiveRotation(oocRotations)
        else return jps.getActiveRotation(combatRotations) end
    end
    if not rotationTable[getCurrentKey()] then return nil end
    
    table.wipe(ToggleRotationName)
    for k,v in pairs(rotationTable[getCurrentKey()]) do
        ToggleRotationName[k] = v.tooltip
    end
    if jps.initializedRotation == false then
		UIDropDownMenu_SetText(DropDownRotationGUI, ToggleRotationName[activeRotation])
        rotationDropdownHolder:Show()
    end
    jps.initializedRotation = true

    if not rotationTable[getCurrentKey()][activeRotation] then return nil end
    jps.Tooltip = rotationTable[getCurrentKey()][activeRotation].tooltip
    return rotationTable[getCurrentKey()][activeRotation]
end

---------------------------------
-- DROPDOWN ROTATIONS
---------------------------------

local rotationDropdownHolder = CreateFrame("frame","rotationDropdownHolder")
rotationDropdownHolder:SetWidth(150)
rotationDropdownHolder:SetHeight(60)
rotationDropdownHolder:SetPoint("CENTER",UIParent)
rotationDropdownHolder:EnableMouse(true)
rotationDropdownHolder:SetMovable(true)
rotationDropdownHolder:RegisterForDrag("LeftButton")
rotationDropdownHolder:SetScript("OnDragStart", function(self) self:StartMoving() end)
rotationDropdownHolder:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

DropDownRotationGUI = CreateFrame("FRAME", "JPS Rotation GUI", rotationDropdownHolder, "UIDropDownMenuTemplate")
DropDownRotationGUI:ClearAllPoints()
DropDownRotationGUI:SetPoint("CENTER",10,10)
local title = DropDownRotationGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", 20, 10) 
title:SetText("JPS ROTATIONS")	

local function GUIRotation_OnClick(self)
   UIDropDownMenu_SetSelectedID(DropDownRotationGUI, self:GetID())
   local activerotation = self:GetID() -- HERE we get the activerotation in the DropDownRotation
   jps.setActiveRotation(self:GetID())
   write("Changed your active Rotation to: "..ToggleRotationName[activerotation])
end

local function GUIDropDown_Initialize(self, level)
	local infoGUI = UIDropDownMenu_CreateInfo()
	for _,rotation in pairs(ToggleRotationName) do
		infoGUI = UIDropDownMenu_CreateInfo()
		infoGUI.text = rotation
		infoGUI.value = rotation
		infoGUI.func = GUIRotation_OnClick
		UIDropDownMenu_AddButton(infoGUI, level)
	end
end

function updateDropdownMenu()
		
	UIDropDownMenu_Initialize(DropDownRotationGUI, GUIDropDown_Initialize)
	UIDropDownMenu_SetSelectedID(DropDownRotationGUI, 1)
	UIDropDownMenu_SetWidth(DropDownRotationGUI, 100);
	UIDropDownMenu_SetButtonWidth(DropDownRotationGUI, 100)
	UIDropDownMenu_JustifyText(DropDownRotationGUI, "LEFT")
	
	if jps.FaceTarget then rotationDropdownHolder:Hide() else rotationDropdownHolder:Show() end

end

updateDropdownMenu()