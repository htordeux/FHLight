--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local GetTime = GetTime

-----------------------------------------------------------------------------------------------------------------------
-- memoize.lua - v1.2 (2012-01)
-- Enrique García Cota - enrique.garcia.cota [AT] gmail [DOT] com
-- memoize lua functions easily
-- Inspired by http://stackoverflow.com/questions/129877/how-do-i-write-a-generic-memoize-function
-----------------------------------------------------------------------------------------------------------------------

-- Copyright (c) 2011 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--[[ usage:

local memoize = require 'memoize' -- or memoize.lua, depending on your env.

function slowFunc(param1, param2)
-- do something expensive, like calculating a value or reading a file
return somethingSlow
end

local memoizedSlowFunc = memoize(slowFunc)

-- First execution takes some time, but the system caches the result
x = memoizedSlowFunc('a','b') -- first time is slow

-- Second execution is fast, since the system uses the cache
x = memoizedSlowFunc('a','b') -- second time is fast
x = memoizedSlowFunc('a','b') -- from now on, it is fast

-- This happens with every new combination of params
y = memoizedSlowFunc('c','d') -- slow
z = memoizedSlowFunc('e','f') -- slow
y = memoizedSlowFunc('c','d') -- fast
]]

local globalCache = {}

local function getCallMetamethod(f)
  if type(f) ~= 'table' then return nil end
  local mt = getmetatable(f)
  return type(mt)=='table' and mt.__call
end

local function resetCache(f, call)
  globalCache[f] = { results = {}, children = {}, call = call or getCallMetamethod(f) }
end

local function getCacheNode(cache, args)
  local node = cache
  for i=1, #args do
    node = node.children[args[i]]
    if not node then return nil end
  end
  return node
end

local function getOrBuildCacheNode(cache, args)
  local arg
  local node = cache
  for i=1, #args do
    arg = args[i]
    node.children[arg] = node.children[arg] or { children = {} }
    node = node.children[arg]
  end
  return node
end

local function getFromCache(cache, args)
  local node = getCacheNode(cache, args)
  return node and node.results or {}
end

local function insertInCache(cache, args, results)
  local node = getOrBuildCacheNode(cache, args)
  node.results = results
end

local function resetCacheIfMetamethodChanged(t)
  local call = getCallMetamethod(t)
  assert(type(call) == "function", "The __call metamethod must be a function")
  if globalCache[t].call ~= call then
    resetCache(t, call)
  end
end

local function buildMemoizedFunction(f)
  local tf = type(f)
  return function (...)
    if tf == "table" then resetCacheIfMetamethodChanged(f) end

    local results = getFromCache( globalCache[f], {...} )

    if #results == 0 then
      results = { f(...) }
      insertInCache(globalCache[f], {...}, results)
    end
    
    return unpack(results)
  end
end

local function isCallable(f)
  local tf = type(f)
  if tf == 'function' then return true end
  if tf == 'table' then
    return type(getCallMetamethod(f))=="function"
  end
  return false
end

local function assertCallable(f)
  assert(isCallable(f), "Only functions and callable tables are admitted on memoize. Received " .. tostring(f))
end

-- public function

function memoize(f)
  assertCallable(f)
  resetCache(f)
  return buildMemoizedFunction(f)
end

--------------------------
-- TABLE FUNCTIONS
--------------------------

jps.removeDuplicate = function(table)
	-- make unique keys
	local hash = {}
	for _,v in ipairs(table) do
		hash[v] = true
	end
	
	-- transform keys back into values
	local dupe = {}
	for k,_ in pairs(hash) do
		dupe[#dupe+1] = k
	end
	return dupe
end

function jps.removeTable(table)
	for k,v in pairs(table) do
		table[k] = nil
	end
end

function jps.removeTableKey(table, key)
	if key == nil then return end
    local element = table[key]
    table[key] = nil
    return element
end

function jps.tableLength(table)
	if table == nil then return 0 end
    local count = 0
    for k,_ in pairs(table) do 
        count = count+1
    end
    return count
end

function jps.deepTableCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--------------------------
-- STRING FUNCTION -- change a string "Bob" or "Bob-Garona" to "Bob"
--------------------------

function jps.stringSplit(unit,case)
	if unit == nil then return "UnKnown" end -- ERROR if threatUnit is nil
	local threatUnit = tostring(unit)
	local playerName = threatUnit
	local playerServer = "UnKnown"
	
	local stringLength = string.len(threatUnit)
	local startPos, endPos = string.find(threatUnit,case)  -- "-" "%s" space
	if ( startPos ) then
		playerName = string.sub(threatUnit, 1, (startPos-1))
		playerServer = string.sub(threatUnit, (startPos+1), stringLength)
		--print("playerName_",playerName,"playerServer_",playerServer) 
	else
		playerName = threatUnit
		playerServer = "UnKnown"
		--print("playerName_",playerName,"playerServer_",playerServer)
	end
return playerName
end

------------------------------
-- BenPhelps' Timer Functions
------------------------------

function jps.resetTimer( name )
	jps.Timers[name] = nil
end

function jps.createTimer( name, duration )
	if duration == nil then duration = 60 end -- 1 min
	jps.Timers[name] = duration + GetTime()
end

function jps.checkTimer( name )
	if jps.Timers[name] ~= nil then
		local now = GetTime()
		if jps.Timers[name] < now then
			jps.Timers[name] = nil
			return 0
		else
			return jps.Timers[name] - now
		end
	end
	return 0
end

-- returns seconds in combat or if out of combat 0
function jps.combatTime()
	return GetTime() - jps.combatStart
end

------------------------------
-- function like C / PHP ternary operator val = (condition) ? true : false
------------------------------

function Ternary(condition, doIt, notDo)
	if condition then return doIt else return notDo end
end

function inArray(needle, haystack)
	if type(haystack) ~= "table" then return false end
	for key, value in pairs(haystack) do 
		local valType = type(value)
		if valType == "string" or valType == "number" or valType == "boolean" then
			if value == needle then 
				return true
			end
		end
	end
	return false
end

function jps.roundValue(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

------------------------------
-- GUID
------------------------------
-- GUID is a string containing the hexadecimal representation of the unit's GUID, 
-- e.g. "0xF130C3030000037F2", or nil if the unit does not exist
-- className, classId, raceName, raceId, gender, name, realm = GetPlayerInfoByGUID("guid")

function ParseGUID(unit)
local guid = UnitGUID(unit)
if guid then
	local first3 = tonumber("0x"..strsub(guid, 5,5))
	local known = tonumber(strsub(guid, 5,5))
	
	local unitType = bit.band(first3,0x7)
	local knownType = tonumber(guid:sub(5,5), 16) % 8
	
   if (unitType == 0x000) then
		local playerID = (strsub(guid,6))
		print("Player, ID #", playerID)
   elseif (unitType == 0x003) then
      local creatureID = tonumber("0x"..strsub(guid,7,10))
      local spawnCounter = tonumber("0x"..strsub(guid,11))
      print("NPC, ID #",creatureID,"spawn #",spawnCounter)
   elseif (unitType == 0x004) then
      local petID = tonumber("0x"..strsub(guid,7,10))
      local spawnCounter = tonumber("0x"..strsub(guid,11))
      print("Pet, ID #",petID,"spawn #",spawnCounter)
   elseif (unitType == 0x005) then
      local creatureID = tonumber("0x"..strsub(guid,7,10))
      local spawnCounter = tonumber("0x"..strsub(guid,11))
      print("Vehicle, ID #",creatureID,"spawn #",spawnCounter)
   end
end
   return guid
end

------------------------------
-- KEYS
------------------------------

keyDownMapper = {}
keyDownMapper["shift"] = IsShiftKeyDown
keyDownMapper["left-shift"] = IsLeftShiftKeyDown
keyDownMapper["right-shift"] = IsRightShiftKeyDown
keyDownMapper["alt"]= IsAltKeyDown
keyDownMapper["left-alt"] = IsLeftAltKeyDown
keyDownMapper["right-alt"] = IsRightAltKeyDown
keyDownMapper["ctrl"] = IsControlKeyDown
keyDownMapper["left-ctrl"] = IsLeftControlKeyDown
keyDownMapper["right-ctrl"] = IsRightControlKeyDown

function keyPressed(...)	
	local paramType = type(arrayOrString)
	matchesNeed = select("#", ...)
	matchesFound = 0
	i = 1
	while select(i , ...) ~= nil  do
		needle = select(i, ...)
		i = i+1
		local apiFunction = keyDownMapper[needle:lower()]
		if type(apiFunction) == "function" then
			if apiFunction() ~= nil  then
				matchesFound  =matchesFound+1
				if matchesFound == matchesNeed then
					return true
				end
			end
		end
	end
	return false
end

function dump(o)
	if type(o) == 'table' then
		local s = '{ \n'
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '	['..k..'] = ' .. dump(v) .. ',\n'
		end
		print(s .. '\n} ')
	else
		return tostring(o)
	end
end
