--[[[
@module Static Spell Tables
@description
Static Tables hava a significant advantage over old-style rotations - memory usage and to some extend execution time. Instead of
creating a new Table every Update Interval the table is only created once and used over and over again. This needs some major modifications
to your rotation - you can find all relevant information on Transforming your Rotations in the PG forums.
]]--

local UnitIsUnit = UnitIsUnit
local canCast = jps.canCast

local parser = {}
parser.testMode = false

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
        local changeTargets = UnitIsUnit(target,"target")~=1 and jps.UnitExists(target)
        if changeTargets then jps.Macro("/target "..target) end

        if type(macro) == "string" then
            local macroSpell = macro
            if string.find(macro,"%s") == nil then -- {"macro","/startattack"}
                macroSpell = macro
            else
                macroSpell = select(3,string.find(macro,"%s(.*)")) -- {"macro","/cast Sanguinaire"}
            end
            if not jps.Casting then jps.Macro(macro) end -- Avoid interrupt Channeling with Macro
            if jps.Debug then macrowrite(macroSpell,"|cff1eff00",target,"|cffffffff",jps.Message) end
            
        -- CASTSEQUENCE WORKS ONLY FOR INSTANT CAST SPELL
		-- "#showtooltip\n/cast Frappe du colosse\n/cast Sanguinaire"
		elseif type(macro) == "number" then
			jps.Macro("/cast "..tostring(GetSpellInfo(macro)))
		end
		if changeTargets and not jps.Casting then jps.Macro("/targetlasttarget") end
	end
end

parser.compiledTables = {}

--[[[
@function parseStaticSpellTable
@description
Parses a static spell table and returns the spell which should be cast or nil if no spell can be cast.
Spell Tables are Tables containing other Tables:[br]
[code]
{[br]
[--]...[br]
[--]{[SPELL], [CONDITION], [TARGET]},[br]
[--]{"nested", [CONDITION], [NESTED SPELL TABLE]},[br]
[--]{[MACRO], [CONDITION], [TARGET]},[br]
[--]...[br]
}[br]
[/code]
e.g:[br]
[code]
{[br]
[--]...[br]
[--]{"Greater Heal", 'jps.hp("target") <= 0.5', "target"},[br]
[--]{{"macro", "/cast Flash Heal"}, 'jps.hp("player") < 0.6', "player"},[br]
[--]{"nested", 'jps.MultiTarget', {...}},[br]
[--]...[br]
}[br]
[/code][br]
[i]SPELL[/i]:[br]
Can either be a spell name or a spell id - id's are preferred since they will work on all client languages! This can also be
the keyword [code]"nested"[/code] - in this case the third paramter is not the target, but a nested spell table which should
be executed if the condition is true.[br]
[br]
[i]MACRO[/i]:[br]
Macro is a table (see example) which replaces the spell and has two elements: they keyword [code]"macro"[/code] and the macro itself.[br]
[br]
[i]CONDITION[/i]:[br]
The condition determines if the spell should be executed - it can either be a boolean value, a function returning a boolean value
or a string. The string must contain a valid boolean expression which will then be re-evaluated every update interval. If there is no
condition the spell will be used on cooldown[br]
[br]
[i]TARGET[/i]:[br]
A WoW unit String or player name - can also be a function which returns this string! If there is no target [code]"target"[/code]
will be used as a default value.[br]
[br]

@param hydraTable static spell table
@returns Tupel [code]spell,target[/code] if a spell should be cast, else [code]nil[/code]
]]--

parseStaticSpellTable = function( hydraTable )

    if not parser.compiledTables[tostring(hydraTable)] then
        jps.compileSpellTable(hydraTable)
        parser.compiledTables[tostring(hydraTable)] = true
    end
    
    local spell = nil
	local conditions = nil
	local target = nil
	local message = ""

    for _, spellTable in pairs(hydraTable) do

        if type(spellTable) == "function" then spellTable = spellTable() end
		spell = spellTable[1] 
		conditions = fnConditionEval(spellTable[2])
		target = fnTargetEval(spellTable[3])
        message = fnMessageEval(spellTable[4])
        if jps.Message ~= message then jps.Message = message end

		-- MACRO -- BE SURE THAT CONDITION TAKES CARE OF CANCAST -- TRUE or FALSE NOT NIL
		if type(spellTable[1]) == "table" and spellTable[1][1] == "macro" then
			fnParseMacro(spellTable[1][2], fnConditionEval(spellTable[2]), fnTargetEval(spellTable[3]))
			
		-- NESTED TABLE
		elseif spellTable[1] == "nested" and type(spellTable[3]) == "table" then
			if fnConditionEval(spellTable[2]) then
				spell,target = parseStaticSpellTable(spellTable[3])
			end

		-- DEFAULT {spell[[, condition[, target]]}
		else 
		    spell = spellTable[1]
            conditions = fnConditionEval(spellTable[2])
            target = fnTargetEval(spellTable[3])
        end

        -- Return spell if conditions are true and spell is castable.
        if spell ~= nil and conditions and canCast(spell,target) then
            return spell,target
        end
    end
end

------------------------
-- PARSE STATIC
------------------------

local function TargetEval(target)
    if target == nil then
        return "target"
    elseif type(target) == "string" then
    	if string.gsub(target, "%s", "") == "LowestImportantUnit" then return jps.LowestImportantUnit()
    	elseif string.gsub(target, "%s", "") == "rangedTarget" then return jps.findMeRangedTarget() end
    end
end

local function ConditionEval(conditions)
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

parseMyStaticSpellTable = function( hydraTable )
	
	local spell = nil
	local conditions = nil
	local target = nil
	local message = ""

--	proxy = setmetatable(hydraTable, {__index = function(t, index) return index end})
--	proxy = setmetatable(hydraTable, proxy) -- sets proxy to be spellTable's metatable

--	myListOfObjects = {}  
--	setmetatable(myListOfObjects, { __mode = 'v' }) --myListOfObjects is now weak  
--	myListOfObjects = setmetatable({}, {__mode = 'v' }) --creation of a weak table

	for i, spellTable in ipairs( hydraTable ) do
        spell = spellTable[1] -- spell
		local cond, targ = strsplit("|", spellTable[2])
		--table.insert(proxy,{spell,conditions,target})
		conditions = ConditionEval(jps.conditionParser(cond))
		target = TargetEval(targ)
		
		-- Return spell if conditions are true and spell is castable.
		if spell ~= nil and conditions and canCast(spell,target) then
			return spell,target
		end
	end
end

------------------------
-- FUNCTIONS USED IN SPELL TABLE
------------------------

local function FN(fn,...)
    local params = {...}
    local params_exec = {}
    return function()
  for i,v in ipairs(params) do
    if type(v) == "function" then
        params_exec[i] = v()
    else
        params_exec[i] = v
    end
  end
        return fn()(unpack(params_exec))
    end
end


local function AND(...)
    local functions = {...}
    return function()
        for _,fn in pairs(functions) do
            if not fn() then if not parser.testMode then return false end end
        end
        return true
    end
end

local function OR(...)
    local functions = {...}
    return function()
        for _,fn in pairs(functions) do
            if fn() then if not parser.testMode then return true end end
        end
        return false
    end
end

local function NOT(fn)
    return function()
        return not fn()
    end
end


local function LT(o1, o2)
    return function()
        return o1() < o2()
    end
end

local function LE(o1, o2)
    return function()
        return o1() <= o2()
    end
end

local function EQ(o1, o2)
    return function()
        return o1() == o2()
    end
end

local function NEQ(o1, o2)
    return function()
        return o1() ~= o2()
    end
end

local function GE(o1, o2)
    return function()
        return o1() >= o2()
    end
end

local function GT(o1, o2)
    return function()
        return o1() > o2()
    end
end

local function VALUE(val)
    return function()
        return val
    end
end

local function GLOBAL_IDENTIFIER(id)
    return function()
        return _G[id]
    end
end

local function ACCESSOR(base, key)
    return function()
        return base()[key]
    end
end

local function ERROR(condition,msg)
    return function()
        print("Your rotation has an error in: \n" .. tostring(condition) .. "\n---" ..tostring(msg))
        return false
    end
end




--[[
    PARSER:
    conditions    = <condition> | <condition> 'and' <conditions> | <condition> 'or' <conditions>
    condition     = 'not' <condition> | '(' <conditions> ')' | <comparison>
    comparison    = <value> <comparator> <value>
    comparator    = '<' | '<=' | '=' | '==' | '~=' | '>=' | '>'
    value         = <identifier> | STRING | NUMBER | BOOLEAN | 'nil'
    identifier    = IDEN | IDEN'.'<accessor> | IDEN '(' ')' | IDEN'('<parameterlist>')
    accessor      = IDEN | IDEN.<accessor>
    parameterlist = <value> | <value> ',' <parameterlist>
]]

---[[[ Internal Parsing function - DON'T USE !!! ]]--
function parser.pop(tokens)
    local t,v = unpack(tokens[1])
    table.remove(tokens, 1)
    return t,v
end

---[[[ Internal Parsing function - DON'T USE !!! ]]--
function parser.lookahead(tokens)
    if tokens[1] then
        local t,v = unpack(tokens[1])
        return t,v
    else
        return nil
    end
end

---[[[ Internal Parsing function - DON'T USE !!! ]]--
function parser.lookaheadType(tokens)
    return parser.lookahead(tokens)
end

---[[[ Internal Parsing function - DON'T USE !!! ]]--
function parser.lookaheadData(tokens)
    return select(2,parser.lookahead(tokens))
end

---[[[ Internal Parsing function - DON'T USE !!! conditions = <condition> | <condition> 'and' <conditions> | <condition> 'or' <conditions> ]]--
function parser.conditions(tokens, bracketLevel)
    local condition1 = parser.condition(tokens, bracketLevel)

    if tokens[1] then
        local t, v = parser.pop(tokens)
        if t == "keyword" then
            if v == 'and' then
                local condition2 = parser.conditions(tokens, bracketLevel)
                return AND(condition1, condition2)
            elseif v == 'or' then
                local condition2 = parser.conditions(tokens, bracketLevel)
                return OR(condition1, condition2)
            else
                error("Unexpected " .. tostring(t) .. ":" .. tostring(v) .. " conditions must be combined using keywords 'and' or 'or'!")
            end
        elseif bracketLevel > 0 then
            if t == ")" then
                return condition1
            else
                error("Unexpected " .. tostring(t) .. ":" .. tostring(v) .. " missing ')'!")
            end
        else
            error("Unexpected " .. tostring(t) .. ":" .. tostring(v) .. " conditions must be combined using keywords 'and' or 'or'!")
        end
    elseif bracketLevel > 0 then
        error("Unexpected " .. tostring(t) .. ":" .. tostring(v) .. " missing ')'!")
    else
        return condition1
    end
end

---[[[ Internal Parsing function - DON'T USE !!! -- condition = 'not' <condition> | '(' <conditions> ')' | <comparison> ]]--
function parser.condition(tokens, bracketLevel)
    local t, v = parser.lookahead(tokens)
    if t == "keyword" and v == "not" then
        parser.pop(tokens)
        return NOT(parser.condition(tokens, bracketLevel))
    elseif t == "(" then
        parser.pop(tokens)
        return parser.conditions(tokens, bracketLevel + 1)
    else
        return parser.comparison(tokens)
    end
end


---[[[ Internal Parsing function - DON'T USE !!! -- comparison = <value> <comparator> <value> -- comparator = '<' | '<=' | '=' | '==' | '~=' | '>=' | '>' ]]--
function parser.comparison(tokens)
    local value1 = parser.value(tokens)
    local t = parser.lookaheadType(tokens)
    if t == "<" then
        local t, v = parser.pop(tokens)
        local value2 = parser.value(tokens)
        return LT(value1, value2)
    elseif t == "<=" then
        local t, v = parser.pop(tokens)
        local value2 = parser.value(tokens)
        return LE(value1, value2)
    elseif t == "=" or t == "==" then
        local t, v = parser.pop(tokens)
        local value2 = parser.value(tokens)
        return EQ(value1, value2)
    elseif t == "~=" then
        local t, v = parser.pop(tokens)
        local value2 = parser.value(tokens)
        return NEQ(value1, value2)
    elseif t == ">=" then
        local t, v = parser.pop(tokens)
        local value2 = parser.value(tokens)
        return GE(value1, value2)
    elseif t == ">" then
        local t, v = parser.pop(tokens)
        local value2 = parser.value(tokens)
        return GT(value1, value2)
    else
        return value1
    end
end

---[[[ Internal Parsing function - DON'T USE !!! -- value      = <identifier> | STRING | NUMBER | BOOLEAN | 'nil']]--
function parser.value(tokens)
    local t, v = parser.lookahead(tokens)
    if t == "number" or t == "string" then
        parser.pop(tokens)
        return VALUE(v)
    elseif t == "keyword" and v == "true" then
        parser.pop(tokens)
        return VALUE(true)
    elseif t == "keyword" and v == "false" then
        parser.pop(tokens)
        return VALUE(false)
    elseif t == "keyword" and v == "nil" then
        parser.pop(tokens)
        return VALUE(nil)
    end
    return parser.identifier(tokens)
end

---[[[ Internal Parsing function - DON'T USE !!! -- identifier = IDEN | IDEN'.'<accessor> | IDEN '(' ')' | IDEN'('<parameterlist>')]]--
function parser.identifier(tokens)
    local t, v = parser.pop(tokens)
    if t ~= "iden" then
        error("Invalid identifier '" .. tostring(v) .. "'!")
    end
    local symbol = GLOBAL_IDENTIFIER(v)
    if parser.lookaheadType(tokens) == "." then
        parser.pop(tokens)
        symbol = parser.accessor(tokens, symbol)
    end
    if parser.lookaheadType(tokens) == "(" then
        parser.pop(tokens)
        if parser.lookaheadType(tokens) == ")" then
            parser.pop(tokens)
            return FN(symbol)
        else
            local parameterList = parser.parameterlist(tokens)
            return FN(symbol, unpack(parameterList))
        end
    else
        return symbol
    end

end

---[[[ Internal Parsing function - DON'T USE !!! -- accessor = IDEN | IDEN.<accessor>]]--
function parser.accessor(tokens, base)
    local t, v = parser.pop(tokens)
    if t ~= "iden" then
        error("Invalid identifier '" .. tostring(v) .. "'!")
    end
    local symbol = ACCESSOR(base, v)
    if parser.lookaheadType(tokens) == "." then
        parser.pop(tokens)
        symbol = parser.accessor(tokens, symbol)
    end
    return symbol
end


---[[[ Internal Parsing function - DON'T USE !!! -- parameterlist = <value> | <value> ',' <parameterlist>]]--
function parser.parameterlist(tokens)
    if parser.lookaheadType(tokens) == ")" then
        parser.pop(tokens)
        return nil
    end
    local value = parser.value(tokens)
    local nextToken = parser.lookaheadType(tokens)
    if nextToken == "," then
        parser.pop(tokens)
        return {value, unpack(parser.parameterlist(tokens))}
    elseif nextToken == ")" then
        parser.pop(tokens)
        return {value}
    else
        error("Invalid Token " .. tostring(nextToken) .. " in parameter list!")
    end
end



---[[[ Internal Parsing function - DON'T USE !!! ]]--
local function alwaysTrue() return true end
function jps.conditionParser(str)
    if type(str) == "function" then return str end
    if str == "onCD" then return alwaysTrue() end
    if str == nil then return alwaysTrue() end
    local tokens = {}
    local i = 0

    for t,v in jps.lexer.lua(str) do
        i = i+1
        tokens[i] = {t,v}
    end
    local retOK, fn  = pcall(parser.conditions, tokens, 0)
    if not retOK then
        return ERROR(str,fn)
    end
    parser.testMode = true
    local retOK, err = pcall(fn)
    parser.testMode = false
    if not retOK then
        return ERROR(str,err)
    end
    return fn
end

---[[[ Internal Parsing function - DON'T USE !!! ]]--
function jps.compileSpellTable(unparsedTable)
    local spell = nil
    local conditions = nil
    local target = nil
    local message = nil

    for i, spellTable in pairs(unparsedTable) do
        if type(spellTable) == "table" then
            spell = spellTable[1]
            conditions = spellTable[2]
            if conditions ~= nil and type(conditions)=="string" then
                spellTable[2] = jps.conditionParser(conditions)
            end
            if spell == "nested" then
                jps.compileSpellTable(spellTable[3])
            end
        end
    end
    return unparsedTable
end

