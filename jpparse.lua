local UnitIsUnit = UnitIsUnit
local canCast = jps.canCast
local tinsert = table.insert
local GetSpellInfo = GetSpellInfo

local function fnMessageEval(message)
    if message == nil then
        return ""
    elseif type(message) == "string" then
        return message
    end
end

local function fnTargetEval(target)
    if target == nil then
        return "target"
    elseif type(target) == "function" then
        return target()
    else
        return target
    end
end

local function fnConditionEval(conditions)
    if conditions == nil then
        return true
    elseif type(conditions) == "boolean" then
        return conditions
    elseif type(conditions) == "number" then
        return conditions ~= 0
    elseif type(conditions) == "function" then
        return conditions()
    else
        return false
    end
end

-- { {"macro","/cast Sanguinaire"} , conditions , "target" }
-- fnParseMacro(spellTable[1][2], fnConditionEval(spellTable[2]), fnTargetEval(spellTable[3]))
local function fnParseMacro(macro, conditions, target)
    if conditions then
    	if target == nil then target = "target" end 
        -- Workaround for TargetUnit is still PROTECTED despite goblin active
        local changeTargets = not UnitIsUnit(target,"target") and jps.UnitExists(target)
        if changeTargets then jps.Macro("/target "..target) end
		local macroSpell = ""
        if type(macro) == "string" then
            if string.find(macro,"%s") == nil then -- {"macro","/startattack"}
                macroSpell = macro
            else
                macroSpell = select(3,string.find(macro,"%s(.*)")) -- {"macro","/cast Sanguinaire"}
            end
            if not jps.Casting then jps.Macro(macro) end -- Avoid interrupt Channeling with Macro
        -- CASTSEQUENCE WORKS ONLY FOR INSTANT CAST SPELL
		-- "#showtooltip\n/cast Frappe du colosse\n/cast Sanguinaire"
		elseif type(macro) == "number" then
			macroSpell = GetSpellInfo(macro)
			jps.Macro("/cast "..tostring(macroSpell))
		end
		if jps.Debug then macrowrite(macroSpell,"|cff1eff00",target) end
        if jps.DebugMsg then macrowrite("|cffffffff",jps.Message) end
		if changeTargets and not jps.Casting then jps.Macro("/targetlasttarget") end
	end
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

parseSpellTable = function(hydraTable)
	
--	proxy = setmetatable(hydraTable, {__index = function(t, index) return index end})
--	proxy = setmetatable(hydraTable, proxy) -- sets proxy to be spellTable's metatable

--	myListOfObjects = {}  
--	setmetatable(myListOfObjects, { __mode = 'v' }) -- myListOfObjects is now weak  
--	myListOfObjects = setmetatable({}, {__mode = 'v' }) -- creation of a weak table

	local spell = nil
	local conditions = nil
	local target = nil
	local message = ""

	for i=1,#hydraTable do -- for i, spellTable in ipairs(hydraTable) do
		local spellTable = hydraTable[i]
        if type(spellTable) == "function" then spellTable = spellTable() end
		spell = spellTable[1] 
		conditions = fnConditionEval(spellTable[2])
		target = fnTargetEval(spellTable[3])
        message = fnMessageEval(spellTable[4])
        if jps.Message ~= message then jps.Message = message end

		-- MACRO -- BE SURE THAT CONDITION TAKES CARE OF CANCAST -- TRUE or FALSE NOT NIL
		if type(spell) == "table" and spell[1] == "macro" then
			fnParseMacro(spellTable[1][2], fnConditionEval(spellTable[2]), fnTargetEval(spellTable[3]))
			
		-- NESTED TABLE
		elseif spell == "nested" and type(target) == "table" then
			if fnConditionEval(spellTable[2]) then
				spell,target = parseSpellTable(target)
			end
		end

		-- DEFAULT {spell[[, condition[, target]]}
		-- Return spell if conditions are true and spell is castable.
		if spell ~= nil and conditions and canCast(spell,target) then
			return spell,target
		end
	end
end