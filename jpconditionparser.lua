--[[[
@module Static Spell Tables
@description
Static Tables hava a significant advantage over old-style rotations - memory usage and to some extend execution time. Instead of
creating a new Table every Update Interval the table is only created once and used over and over again. This needs some major modifications
to your rotation - you can find all relevant information on Transforming your Rotations in the PG forums.
]]--

local UnitIsUnit = UnitIsUnit
local GetSpellInfo = GetSpellInfo
local ipairs = ipairs

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

local function fnMacroEval(condition,macro)
    if condition then
    	if not jps.Casting then jps.Macro(macro) -- Avoid interrupt Channeling with Macro
        -- CASTSEQUENCE WORKS ONLY FOR INSTANT CAST SPELL
		-- "#showtooltip\n/cast Frappe du colosse\n/cast Sanguinaire"
		elseif jps.Casting and string.find(macro,"/stopcasting") then
			if jps.Debug then print("macrostopcastig") end
			jps.Macro("/stopcasting")
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
local function alwaysFalse() return false end
local function conditionParser(conditions)
	if conditions == nil then return alwaysTrue()
	elseif type(conditions) == "boolean" then return conditions
	elseif type(conditions) == "function" then return conditions()
	elseif type(conditions) == "string" then
		local tokens = {}
		local i = 0
	
		for t,v in jps.lexer.lua(conditions) do
			i = i+1
			tokens[i] = {t,v}
		end
		local retOK, fn  = pcall(parser.conditions, tokens, 0)
		if not retOK then
			return ERROR(conditions,fn)
		end
		parser.testMode = true
		local retOK, err = pcall(fn)
		parser.testMode = false
		if not retOK then
			return ERROR(conditions,err)
		end
		return fn
    else
        return alwaysFalse
    end
end

---[[[ Internal Parsing function - DON'T USE !!! ]]--
local function compileSpellTable(unparsedTable)
    local spell = nil
    local conditions = nil
    local target = nil
    local message = nil

    for i, spellTable in pairs(unparsedTable) do
        if type(spellTable) == "table" then
            spell = spellTable[1]
            conditions = spellTable[2]
            if conditions ~= nil and type(conditions)=="string" then
                spellTable[2] = conditionParser(conditions)
            end
            if spell == "nested" then
                compileSpellTable(spellTable[3])
            end
        end
    end
    return unparsedTable
end

parser.compiledTables = {}
parseStaticSpellTable = function(hydraTable)

    if not parser.compiledTables[tostring(hydraTable)] then
        compileSpellTable(hydraTable)
        parser.compiledTables[tostring(hydraTable)] = true
    end
    
	local spell = nil
	local conditions = nil
	local target = nil
	local message = ""

    for _,spellTable in ipairs(hydraTable) do

        if type(spellTable) == "function" then spellTable = spellTable() end

		-- MACRO -- BE SURE THAT CONDITION TAKES CARE OF CANCAST -- TRUE or FALSE NOT NIL
		-- {"macro", condition, "MACRO_TEXT" }
		if spellTable[1] == "macro" then
			fnMacroEval(fnConditionEval(spellTable[2]), fnTargetEval(spellTable[3]))
		-- NESTED TABLE { {"nested"}, condition, { nested spell table } }
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
        if spell ~= nil and conditions and jps.canCast(spell,target) then
            return spell,target
        end
    end
end


