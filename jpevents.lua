--[[[
@module Events
@description 
JPS Event Handling. If you need to react to specific events or want to execute a function this module might help you.
Instead of creating your own frame and event-handler you can just hook into the JPS main frame and register functions
here.[br]
[br]
This module also contains profiling support for the events. If enabled you will get the memory consumption from all events summarized 
- [i]Attention:[/i] This has a serious impact on FPS!
]]--

-- Localization
local L = MyLocalizationTable
-- Logger
local LOG = jps.Logger(jps.LogLevel.ERROR)
-- Update Table
local updateTable = {}
-- Event Table for all events
local eventTable = {}
-- Event Table for COMBAT_LOG_EVENT_UNFILTERED Sub-Types
local combatLogEventTable = {}
-- JPS Frame
local jpsFrame = CreateFrame("Frame", "JPSFrame")

jps.listener = {}
local listener = jps.listener
local UnitGUID = UnitGUID

-- TABLE ENEMIES IN COMBAT
local EnemyDamager = {}
setmetatable(EnemyDamager, { __mode = 'k' }) -- creation of a weak table
local EnemyHealer = {}
setmetatable(EnemyHealer, { __mode = 'k' }) -- creation of a weak table
local EnemyCooldowns = {}
setmetatable(EnemyCooldowns, { __mode = 'k' }) -- creation of a weak table
-- HEALTABLE
local Healtable = {}
setmetatable(Healtable, { __mode = 'k' }) -- creation of a weak table
-- RaidStatus
local GetTime = GetTime
local canHeal = jps.canHeal
local canDPS = jps.canDPS
local GetUnitName = GetUnitName
local pairs = pairs
local tinsert = table.insert
local tremove = table.remove
-- Table for failed spells
local SpellFailedTable = {}

-- local function
local GetSpellInfo = GetSpellInfo
local function toSpellName(spell)
	local spellname = GetSpellInfo(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	return spellname
end

--------------------------
-- (UN)REGISTER FUNCTIONS 
--------------------------

--[[[
@function jps.registerOnUpdate
@description 
Register OnUpdate Function[br]
Adds the given function to the update table if it wasn't already registered.[br]
[br][i]Usage:[/i][br]
[code]
jps.registerOnUpdate(function()[br]
print("Update")[br]
end)[br]
[/code]
@param fn function to be executed on update
]]--
function jps.registerOnUpdate(fn)
	if not updateTable[fn] then
		updateTable[fn] = fn
		return true
	end
end

--[[[
@function jps.unregisterOnUpdate
@description 
Unregister OnUpdate Function[br]
Removes the given event function from the update table if it was registered earlier. Has no effect if the function wasn't registered.[br]
[br][i]Usage:[/i][br]
[code]
function myOnUpdate() ... end[br]
...[br]
jps.registerOnUpdate(myOnUpdate)[br]
...[br]
jps.unregisterOnUpdate(myOnUpdate)[br]
[/code]
@param fn function to unregister
]]--
function jps.unregisterOnUpdate(fn)
	if updateTable[fn] then
		updateTable[fn] = nil
		return true
	end
end

--[[[
@function jps.listener.registerEvent
@description 
Adds the given event function to the event table if it wasn't already registered.[br]
[br][i]Usage:[/i][br]
[code]
jps.listener.registerEvent("LOOT_OPENED", function()[br]
print("You opened Loot!")[br]
end)[br]
[/code]
@param event event name
@param fn function to be executed on update
]]--
function listener.registerEvent(event, fn)
	if not eventTable[event] then
		eventTable[event] = {}
		jpsFrame:RegisterEvent(event)
	end
	if not eventTable[event][fn] then
		eventTable[event][fn] = fn
		return true
	end
end

--[[[
@function jps.unregisterEvent
@description 
Removes the given event function from the event table if it was registered earlier. Has no effect if the function wasn't registered.[br]
[br][i]Usage:[/i][br]
[code]
function myLootOpened() ... end[br]
...[br]
jps.listener.registerEvent("LOOT_OPENED", myLootOpened)[br]
...[br]
jps.unregisterEvent("LOOT_OPENED", myLootOpened)[br]
[/code]
@param event event name
@param fn function to unregister
]]--
function listener.unregisterEvent(event, fn)
	if eventTable[event] and eventTable[event][fn] then
		eventTable[event][fn] = nil
		local count = 0
		for k in pairs(eventTable[event]) do count = count + 1 end
		if count == 0 then
			jpsFrame:UnregisterEvent(event)
		end
		return true
	end
end

--[[[
@function jps.registerCombatLogEventUnfiltered
@description 
Register event subtype for COMBAT_LOG_EVENT_UNFILTERED - Adds the given event function to the COMBAT_LOG_EVENT_UNFILTERED table if it wasn't already registered.[br]
[br][i]Usage:[/i][br]
[code]
jps.registerCombatLogEventUnfiltered("SWING_DAMAGE", function()[br]
print("Swing Damage - yay!")[br]
end)[br]
[/code]
@param event name of the combat sub-event
@param fn function which should be executed on event
]]--
function listener.registerCombatLogEventUnfiltered(event, fn)
	if not combatLogEventTable[event] then
		combatLogEventTable[event] = {}
		jpsFrame:RegisterEvent(event)
	end
	if not combatLogEventTable[event][fn] then
		combatLogEventTable[event][fn] = fn
		return true
	end
end


--[[[
@function jps.unregisterCombatLogEventUnfiltered
@description 
Removes the given event function from the COMBAT_LOG_EVENT_UNFILTERED table if it was registered earlier. Has no effect if the function wasn't registered.[br]
[br][i]Usage:[/i][br]
[code]
function mySwingDamage() ... end[br]
...[br]
jps.registerCombatLogEventUnfiltered("SWING_DAMAGE", mySwingDamage)[br]
...[br]
jps.unregisterCombatLogEventUnfiltered("SWING_DAMAGE", mySwingDamage)[br]
[/code]
@param event event name
@param fn function to unregister
]]--
function listener.unregisterCombatLogEventUnfiltered(event, fn)
	 if combatLogEventTable[event] and combatLogEventTable[event][fn] then
		combatLogEventTable[event][fn] = nil
		local count = 0
		for k in pairs(combatLogEventTable[event]) do count = count + 1 end
		if count == 0 then
			jpsFrame:UnregisterEvent(event)
		end
		return true
	 end
end

--------------------------
-- PROFILING FUNCTIONS 
--------------------------

local enableProfiling = false
local enableUnfilteredProfiling = false
local memoryUsageTable = {}
local memoryStartTable = {}
local memoryUsageInterval = 0
local function startProfileMemory(key)
	if not memoryStartTable[key] then UpdateAddOnMemoryUsage(); memoryStartTable[key] = GetAddOnMemoryUsage("JPS") end 
end

local function endProfileMemory(key)
	if not memoryStartTable[key] then return end
	if not memoryUsageTable[key] then memoryUsageTable[key] = 0 end
	UpdateAddOnMemoryUsage()
	memoryUsageTable[key] = GetAddOnMemoryUsage("JPS") - memoryStartTable[key]
end

local reportInterval = 15
local maxProfileDuration = 60
local lastReportUpdate = 0
local totalProfileDuration = 0
--[[[ Internal - Memory Usage Report ]]--
function jps.reportMemoryUsage(elapsed)
	lastReportUpdate = lastReportUpdate + elapsed
	totalProfileDuration = totalProfileDuration + elapsed
	if lastReportUpdate > reportInterval then
		lastReportUpdate = 0
		print("Memory Usage Report:")
		for key,usage in pairs(memoryUsageTable) do
			print(" * " .. key .. ": " .. usage .. " KB in " .. reportInterval .. " seconds" )
		end
	    UpdateAddOnMemoryUsage()
		print(" *** TOTAL: " .. (GetAddOnMemoryUsage("JPS")-memoryUsageInterval) .. " KB in " .. reportInterval .. " seconds" )
		memoryUsageInterval = GetAddOnMemoryUsage("JPS")
		memoryStartTable = {}
		memoryUsageTable = {}
	end
	if totalProfileDuration >= maxProfileDuration then
		enableProfiling = false
		enableUnfilteredProfiling = false
	end
end

--[[[
@function jps.enableProfiling
@description 
Enables profiling for one minute. Every 15 seconds you will get the memory consumption from all events summarized 
- [i]Attention:[/i] This has a serious impact on FPS!
@param unfiltered [code]True[/code] if COMBAT_LOG_UNFILTERED events should be split up ([i]BIG PERFORMANCE DECREASE[/i]) - defaults to [code]False[/code]
]]--
function jps.enableProfiling(unfiltered)
	totalProfileDuration = 0
	lastReportUpdate = 0
	enableProfiling = true
	enableUnfilteredProfiling = unfiltered
	UpdateAddOnMemoryUsage()
	memoryUsageInterval = GetAddOnMemoryUsage("JPS")
end

--------------------------
-- ON UPDATE
--------------------------

--[[[
@function jps.cachedValue
@description
This function generates a function which will store a value which might be too expensive to generate everytime. You must provide
a function which generates the value which will be called every [code]updateInterval[/code] seconds to refresh the cached value.
@param fn function which generates the value
@param updateInterval [i]Optional:[/i] max age in seconds before the value is fetched again from the function - defaults to [code]jps.UpdateInterval[/code]
@returns A function which will return the cached value
]]--

jps.cachedValue = function(fn,updateInterval)
    if not updateInterval then updateInterval = jps.UpdateInterval end
    local value = fn()
    local maxAge = GetTime() + updateInterval
    return function()
        if maxAge < GetTime() then
            value = fn()
            maxAge = GetTime() + updateInterval
        end
        return value
    end
end

-- UPDATE HANDLER
jpsFrame:SetScript("OnUpdate", function(self, elapsed)
	if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
	if (self.TimeSinceLastUpdate > jps.UpdateInterval) then
		for _,fn in pairs(updateTable) do
			local status, error = pcall(fn)
			if not status then
				 LOG.error("Error %s on OnUpdate function %s", error, fn)
			end
		end
		self.TimeSinceLastUpdate = 0
	end
	if enableProfiling then jps.reportMemoryUsage(elapsed) end
end)

--- EVENT HANDLER
local debugFaceTarget = function ()
	if jps.checkTimer("FacingBug") > 0 and jps.checkTimer("Facing") == 0 then
		TurnLeftStop()
	end
end

jpsFrame:SetScript("OnEvent", function(self, event, ...)
	if eventTable[event] then
		if enableProfiling then startProfileMemory(event) end
		for _,fn in pairs(eventTable[event]) do
			local status, error = pcall(fn, ...)
			if not status then
				LOG.error("Error on event %s, function %s", error, fn)
			end
		end
		if enableProfiling then endProfileMemory(event) end
	end
	-- Execute this code everytime
	debugFaceTarget()
end)

--- COMBAT_LOG_EVENT_UNFILTERED Handler
jps.listener.registerEvent("COMBAT_LOG_EVENT_UNFILTERED", function(timeStamp, event, ...)
	if jps.Enabled and UnitAffectingCombat("player") and combatLogEventTable[event] then
		--LOG.debug("CombatLogEventUntfiltered: %s", event)
		if enableUnfilteredProfiling and enableProfiling then startProfileMemory("COMBAT_LOG_EVENT_UNFILTERED::"..event) end
		for _,fn in pairs(combatLogEventTable[event]) do
			local status, error = pcall(fn, timeStamp, event, ...)
			if not status then
				LOG.error("Error on COMBAT_LOG_EVENT_UNFILTERED sub-event %s, function %s", error, fn)
			end
		end
		if enableUnfilteredProfiling and enableProfiling then endProfileMemory("COMBAT_LOG_EVENT_UNFILTERED::"..event) end
	end
end)

--------------------------
-- UPDATE FUNCTIONS
--------------------------

-- Garbage Collection is automatic in lua every 30 sec
local collectGarbage = function()
	UpdateAddOnMemoryUsage()
	write("Memory: ",GetAddOnMemoryUsage("JPS"))
	if GetAddOnMemoryUsage("JPS") > 5120 then collectgarbage("collect") end
end

-- TimeToDie Update
jps.registerOnUpdate(updateTimeToDie)

-- Combat
jps.registerOnUpdate(function()
	if jps.Enabled then
    	if jps.Combat then jps.Cycle()
    	elseif jps.hasOOCRotation() > 0 then jps.Cycle()
    	end
	end
end)

--------------------------
-- EVENT FUNCTIONS
--------------------------

-- PLAYER_LOGIN
jps.listener.registerEvent("PLAYER_LOGIN", function()
	NotifyInspect("player")
end)

-- PLAYER_ENTERING_WORLD
-- Fired when the player enters the world, reloads the UI, enters/leaves an instance or battleground, or respawns at a graveyard.
-- Also fires any other time the player sees a loading screen
jps.listener.registerEvent("PLAYER_ENTERING_WORLD", function()
	jps.detectSpec()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
	EnemyHealer = {} -- keep healer enemy table during all RBG time?
	jps.Timers = {} -- keep Holy Word: Chastise 88625 Cooldown
end)

-- INSPECT_READY
jps.listener.registerEvent("INSPECT_READY", function()
	if not jps.Spec then jps.detectSpec() end
	if jps_variablesLoaded and not jps.Configged then 
		jps.createConfigFrame()
		jps.createMinimap()
	end
end)

-- VARIABLES_LOADED
jps.listener.registerEvent("VARIABLES_LOADED", jps_VARIABLES_LOADED)

-- Dual Spec Respec -- only fire when spec change no other event before
jps.listener.registerEvent("ACTIVE_TALENT_GROUP_CHANGED", function()
	jps.resetRotationTable()
	jps.detectSpec()
end)
jps.listener.registerEvent("SPELLS_CHANGED", function()
	GetHarmfulSpell()
end)


-- Save on Logout
jps.listener.registerEvent("PLAYER_LEAVING_WORLD", jps_SAVE_PROFILE)

-- Hide Static Popup - thx here to Phelps & ProbablyEngine
local hideStaticPopup = function(addon, eventBlocked)
	jps.PLuaFlag = true
	if string.upper(addon) == "JPS" then
		StaticPopup1:Hide()
		LOG.debug("Addon Action Blocked: %s", eventBlocked)
	end
end
jps.listener.registerEvent("ADDON_ACTION_FORBIDDEN", hideStaticPopup)
jps.listener.registerEvent("ADDON_ACTION_BLOCKED", hideStaticPopup)

-- Enter Combat
jps.listener.registerEvent("PLAYER_REGEN_DISABLED", function()
	jps.Combat = true
	jps.gui_toggleCombat(true)
	jps.combatStart = GetTime()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
end)

-- LOOT_OPENED
jps.listener.registerEvent("LOOT_OPENED", function()
	if (IsFishingLoot()) then
		jps.Fishing = true
	end
end)

-- Leave Combat
local leaveCombat = function()
	if jps.checkTimer("FacingBug") > 0 then TurnLeftStop() end
	jps.Opening = true
	jps.Combat = false
	jps.gui_toggleCombat(false)
	jps.combatStart = 0
	jps.NextSpell = nil

	-- nil all tables
	SpellFailedTable = {}
	EnemyCooldowns = {}
	EnemyDamager = {}
	Healtable = {}
	jps.LastMessage = {}
	jps.TimeToDieData = {}
	jps.TimedCasting = {}
	jps.HealerBlacklist = {} 
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
	-- Garbage
	collectGarbage()
end

jps.listener.registerEvent("PLAYER_REGEN_ENABLED", leaveCombat)
jps.listener.registerEvent("PLAYER_UNGHOST", leaveCombat)

-- "UNIT_AURA"
-- Fired when a buff, debuff, status, or item bonus was gained by or faded from an entity (player, pet, NPC, or mob.)
-- This event fires before the associated effects take place
local updateAverageHeal = function()
	local masteryValue = math.ceil(GetMastery())/100
	local bonusHealing = math.ceil(GetSpellBonusHealing())
	local minCrit = math.ceil(GetSpellCritChance(2))/100 -- 2 - Holy
	priest.AvgAmountFlashHeal = (1+masteryValue)*(1+minCrit)*(14664+(1.314*bonusHealing))
	priest.AvgAmountGreatHeal = (1+masteryValue)*(1+minCrit)*(24430+(2.219*bonusHealing))
end

jps.listener.registerEvent("UNIT_AURA", function(unitID)
	if unitID == "player" then
		updateAverageHeal()
	end
end)

--------------------------
-- GLOBAL COOLDOWN
--------------------------

local GlobalCooldown = function()
	local cdStart,duration,_ = GetSpellCooldown(61304)
	if cdStart == 0 then return 0 end
	local timeLeft = duration - (GetTime() - cdStart )
	if timeLeft < 0 then timeLeft = 0 end
	return duration
end

--------------------------
-- EVENT FUNCTIONS SPELL
--------------------------

-- UI_ERROR_MESSAGE
jps.listener.registerEvent("UI_ERROR_MESSAGE", function(event_error)
	-- "UI_ERROR_MESSAGE" returns ONLY one arg1
	-- http://www.wowwiki.com/WoW_Constants/Errors
	-- http://www.wowwiki.com/WoW_Constants/Spells
		if (event_error == SPELL_FAILED_NOT_BEHIND) then -- "You must be behind your target."
			LOG.debug("SPELL_FAILED_NOT_BEHIND - %s", event_error)
			jps.isNotBehind = true
			jps.isBehind = false
		elseif jps.FaceTarget and not jps.Moving and ((event_error == SPELL_FAILED_UNIT_NOT_INFRONT) or (event_error == ERR_BADATTACKFACING)) then
			--LOG.debug("ERR_BADATTACKFACING - %s", event_error)			

			local TargetGuid = UnitGUID("target")
			if FireHack and (TargetGuid ~= nil) then
				local TargetObject = GetObjectFromGUID(TargetGuid)
				TargetObject:Face ()
			else
				jps.createTimer("Facing",0.6)
				jps.createTimer("FacingBug",1.2)
				TurnLeftStart()
			end
		elseif (event_error == SPELL_FAILED_LINE_OF_SIGHT) or (event_error == SPELL_FAILED_VISION_OBSCURED) then
			--LOG.debug("SPELL_FAILED - %s", event_error)
			jps.BlacklistPlayer(jps.LastTarget)
		end
end)

--casting failed = FAILED ( bad target, out of range)
--casting success = SENT - START - SUCCEEDED - SPELLCAST_STOP
--casting interrupt = SENT - START - INTERRUPT - SPELLCAST_STOP
--channel success = SENT - CHANNEL_START - SUCCEEDED - CHANNEL_STOP
--channel interrupt = SENT - CHANNEL_START - SUCCEEDED - CHANNEL_STOP

local sendTime = 0
local GetTime = GetTime
local Shield = toSpellName(17)
jps.listener.registerEvent("UNIT_SPELLCAST_SENT", function(unitID,spellname,_,spelltarget,_)
	if unitID == "player" then
		jps.SentCast = spellname
		sendTime = GetTime()
		jps.CurrentCastInterrupt = nil
		if spellname == Shield then jps.createTimer("ShieldTimer", 12 ) end
	end
end)

local descriptorTable = { L["Strikes"] , L["Roots"] , L["Transforms"] , L["Forces"] , L["Seduces"] }
jps.listener.registerEvent("UNIT_SPELLCAST_START", function(unitID,spellname,_,_,spellID)
		if unitID == "player" then
			jps.CurrentCast = spellname
			jps.Latency = GetTime() - sendTime
			jps.GCD = GlobalCooldown()
			--print("SPELLCAST_START: ",unitID,"spellname: ",spellname,"spellID: ",spellID)
		end
end)

jps.listener.registerEvent("UNIT_SPELLCAST_CHANNEL_START", function(unitID,spellname,_,_,spellID)
		if unitID == "player" and type(spellname) == "string" then
			jps.CurrentCast = spellname
			jps.Latency = GetTime() - sendTime
			jps.GCD = GlobalCooldown()
		end
end)

jps.listener.registerEvent("UNIT_SPELLCAST_INTERRUPTED", function(unitID,spellname,_,_,spellID)
	if unitID == "player" and type(spellname) == "string" then
		jps.CurrentCastInterrupt = spellname
		jps.CurrentCastInterruptID = spellID
		--print("INTERRUPTED: ",unitID,"spellname:",spellname,": ",spellID)
	end
end)

--jps.listener.registerEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(unitID,spellname,_,_,spellID)
--	if unitID == "player" and spellID ~= nil then
--		jps.Casting = false
--		print("CHANNEL_STOP: ",unitID,"spellname:",spellname,"spellID: ",spellID)
--	end
--end)

--jps.listener.registerEvent("UNIT_SPELLCAST_STOP", function(unitID,spellname,_,_,spellID)
--	if unitID == "player" and spellID ~= nil then
--		jps.Casting = false
--		print("SPELLCAST_STOP: ",unitID,"spellname:",spellname,"spellID: ",spellID)
--	end
--end)

-- UNIT_SPELLCAST_SUCCEEDED
jps.listener.registerEvent("UNIT_SPELLCAST_SUCCEEDED", function(unitID,spellname,_,_,spellID)
	if (unitID == "player") and spellID then
		jps.CurrentCastInterrupt = nil
		if jps.FaceTarget then
			if jps.checkTimer("FacingBug") > 0 then
				TurnLeftStop()
			end
		end
		if ((jps.Class == "Druid" and jps.Spec == "Feral") or jps.Class == "Rogue") then
			-- "Druid" -- 5221 -- "Shred" -- "Ambush" 8676
			if (unitID == "player") and spellID == 5221 then 
				jps.isNotBehind = false
				jps.isBehind = true
			elseif (unitID == "player") and spellID == 8676 then
				jps.isNotBehind = false
				jps.isBehind = true
			end
		end
	end
end)

----------------------
-- LOSS_OF_CONTROL
----------------------

-- LossOfControlType, _, LossOfControlText, _, LossOfControlStartTime, LossOfControlTimeRemaining, duration, _, _, _ = C_LossOfControl.GetEventInfo(eventIndex)
-- eventIndex Number - index of the loss-of-control effect currently affecting your character to return information about, ascending from 1. 
-- LossOfControlType : --STUN_MECHANIC --STUN --PACIFYSILENCE --SILENCE --FEAR --CHARM --PACIFY --CONFUSE --POSSESS --SCHOOL_INTERRUPT --DISARM --ROOT

local stunTypeTable = {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
jps.listener.registerEvent("LOSS_OF_CONTROL_ADDED", function ()
	local i = C_LossOfControl.GetNumEvents()
    local locType, _, text, _, _, _, duration = C_LossOfControl.GetEventInfo(i)
    --print("CONTROL:", locType,"/",text,"/",duration)
    if text and duration then
    	if locType == "SCHOOL_INTERRUPT" then
    		jps.createTimer("PlayerInterrupt",duration)
    		jps.createTimer("PlayerWasControl",duration + 2)
    	return end
		for i=1,#stunTypeTable do -- for _,stuntype in ipairs(stunTypeTable) do
			local stuntype = stunTypeTable[i]
			if locType == stuntype then 
				jps.createTimer("PlayerStun",duration)
				jps.createTimer("PlayerWasControl",duration + 2)
			break end
		end
    end
end)

--jps.listener.registerEvent("LOSS_OF_CONTROL_UPDATE", function()
--	local i = C_LossOfControl.GetNumEvents()
--	local _, _, text, _, _, _, duration = C_LossOfControl.GetEventInfo(i)
--	print("CONTROL_UPDATE: ",text, duration)
--end)

----------------------
-- UPDATE RAID STATUS
----------------------
-- UNIT_HEALTH events are sent for raid and party members regardless of their distance from the character of the host. 
-- This makes UNIT_HEALTH extremely valuable to monitor PARTY AND RAID MEMBERS.
-- arg1 the UnitID of the unit whose health is affected player, pet, target, mouseover, party1..4, partypet1..4, raid1..40
-- "UNIT_HEALTH_FREQUENT" Same event as UNIT_HEALTH, but not throttled as aggressively by the client
-- "UNIT_HEALTH_PREDICTION" arg1 unitId receiving the incoming heal

-- In Arena ??? Opposing arena member with index N (1,2,3,4 or 5).
jps.listener.registerEvent("UNIT_HEALTH_FREQUENT", function(unitID)
	if jps.PvP and not jps.Combat and jps.RaidEnemyCount() > 0 then jps.Cycle() end
	if jps.isHealer then jps.UpdateRaidUnit(unitID) end
end)

-- Group/Raid Update
-- RAID_ROSTER_UPDATE's pre-MoP functionality was moved to the new event GROUP_ROSTER_UPDATE
-- PARTY_MEMBER_DISABLE -- Fired when a specific party member is offline or dead 
jps.listener.registerEvent("GROUP_ROSTER_UPDATE", function()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
end)
jps.listener.registerEvent("PARTY_MEMBER_DISABLE", function()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
end)

-----------------------
-- UPDATE ENEMY TABLE
-----------------------
-- "UNIT_TARGET" Fired when the target of yourself, raid, and party members change: 'target', 'party1target', 'raid1target', etc.. 
-- Should also work for 'pet' and 'focus'. This event only fires when the triggering unit is within the player's visual range
jps.listener.registerEvent("UNIT_TARGET", jps.LowestTarget)

local updateEnemyDamager = function()
	for unit,index in pairs(EnemyDamager) do
		local dataset = index.friendaggro
		if dataset then 
			local timeDelta = GetTime() - dataset[1]
			if timeDelta > 4 then EnemyDamager[unit] = nil end
		end
	end
end

--------------------------
-- TRACKING ENEMY COOLDOWNS
--------------------------

-- EnemyCooldowns[sourceGUID][spellId]
-- jps.registerOnUpdate(SpellTimer) on jpevents.lua ?
local SpellTimer = function(unitGuid)
	local dataset = EnemyCooldowns[unitGuid]
	for spell,index in pairs(dataset) do
		local endSpell = index[1] --local start, duration, _ = GetSpellCooldown(spell)
		local timeLeft = math.ceil(endSpell - GetTime()) --local timeLeft = start + duration - GetTime()
		EnemyCooldowns[unitGuid][spell][2] = timeLeft
		if timeLeft < 1 then -- GCD 1 sec
			EnemyCooldowns[unitGuid][spell][2] = 0
		end 
	end
end

function jps.enemyCooldownWatch(unit)
	if not jps.UnitExists(unit) then return end
	local unitGuid = UnitGUID(unit)
	local dataset = EnemyCooldowns[unitGuid]
	if not dataset then return 0 end
	-- Update Table
	SpellTimer(unitGuid)
	local cooldown = 999
	for spell,index in pairs(dataset) do
		if index[2] < cooldown then cooldown = index[2] end 
		write(index[3],"-",spell,": ",index[2])
	end
	return cooldown
end

-----------------------
-- UPDATE HEALERBLACKLIST
-----------------------

--local GetNumGroupMembers = GetNumGroupMembers
--local isArena, _ = IsActiveBattlefieldArena()
--local UpdateScoreFrequency = function()
--	if isArena == true then scoreFrequency  = 0.2
--	elseif GetNumGroupMembers() <= 10 then scoreFrequency  = 0.4
--	else scoreFrequency  = 0.8 end
--end

local scoreLastUpdate = GetTime()
local scoreFrequency  = 2 -- sec
local UpdateIntervalRaidStatus = function()
	local curTime = GetTime()
	local diff = curTime - scoreLastUpdate
	if diff < scoreFrequency then return end
	scoreLastUpdate = curTime
	jps.UpdateHealerBlacklist()
	updateEnemyDamager()
	if #jps.LastMessage > 2 then
		for i=3,#jps.LastMessage do jps.LastMessage[i] = nil end
	end
end

-- HealerBlacklist Update
jps.registerOnUpdate(UpdateIntervalRaidStatus)

--------------------------
-- COMBAT_LOG_EVENT_UNFILTERED FUNCTIONS
--------------------------
-- eventtable[4] == sourceGUID
-- eventtable[5] == sourceName
-- eventtable[6] == sourceFlags
-- eventtable[8] == destGUID
-- eventtable[9] == destName
-- eventtable[10] == destFlags
-- eventtable[15] -- amount if suffix is SPELL_DAMAGE or SPELL_HEAL
-- eventtable[12] -- amount if suffix is SWING_DAMAGE

local damageEvents = {
        ["SWING_DAMAGE"] = true,
        ["SPELL_DAMAGE"] = true,
        ["SPELL_PERIODIC_DAMAGE"] = true,
        ["RANGE_DAMAGE"] = true,
}

local healEvents = {
        ["SPELL_HEAL"] = true,
        ["SPELL_PERIODIC_HEAL"] = true,
}

local spellEvents = {
		["SPELL_CAST_SUCCESS"]= true,
		["SPELL_AURA_APPLIED"] = true,
		["SPELL_MISSED"] = true,
		["SPELL_SUMMON"] = true,
}

-- UNIT_DIED destGUID and destName refer to the unit that died.
jps.listener.registerCombatLogEventUnfiltered("UNIT_DIED", function(...)
	local destGUID = select(8,...)
	if EnemyDamager[destGUID] then EnemyDamager[destGUID] = nil end
	if EnemyHealer[destGUID] then EnemyHealer[destGUID] = nil end
end)

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY
local COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID
local COMBATLOG_OBJECT_REACTION_HOSTILE	= COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local RAID_AFFILIATION = bit.bor(COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_AFFILIATION_MINE)
local bitband = bit.band

-- TABLE ENEMIES IN COMBAT
jps.listener.registerEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...)
	local event = select(2,...)
	local sourceGUID = select(4,...)
	local sourceName = select(5,...)
	local sourceFlags = select(6,...)
	local destGUID = select(8,...)
	local destName = select(9,...)
	local destFlags = select(10,...)
	
-- The numeric values of the global variables starts with 1 for MINE and increases toward OUTSIDER with 8
	local isDestEnemy = bitband(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
	local isDestRaid = bitband(destFlags, RAID_AFFILIATION) > 0
	local isSourceRaid = bitband(sourceFlags, RAID_AFFILIATION) > 0
	local isSourceEnemy = bitband(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
	
--	if jps.Debug then
--		print("COMBATLOG_OBJECT_TYPE_PLAYER =", COMBATLOG_OBJECT_TYPE_PLAYER,bitband(sourceFlags,COMBATLOG_OBJECT_TYPE_PLAYER),
--		"COMBATLOG_OBJECT_AFFILIATION_MINE =", COMBATLOG_OBJECT_AFFILIATION_MINE,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_MINE),
--		"COMBATLOG_OBJECT_AFFILIATION_PARTY =", COMBATLOG_OBJECT_AFFILIATION_PARTY,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_PARTY),
--		"COMBATLOG_OBJECT_AFFILIATION_RAID =", COMBATLOG_OBJECT_AFFILIATION_RAID,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_RAID),
--		"COMBATLOG_OBJECT_REACTION_HOSTILE	=", COMBATLOG_OBJECT_REACTION_HOSTILE,bitband(sourceFlags,COMBATLOG_OBJECT_REACTION_HOSTILE),
--		"COMBATLOG_OBJECT_REACTION_FRIENDLY =", COMBATLOG_OBJECT_REACTION_FRIENDLY,bitband(sourceFlags,COMBATLOG_OBJECT_REACTION_FRIENDLY),
--		"COMBATLOG_OBJECT_AFFILIATION_OUTSIDER =", COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_OUTSIDER),
--		"RAID_AFFILIATION =", RAID_AFFILIATION,bitband(sourceFlags,RAID_AFFILIATION))
--	end

-- HEAL TABLE -- contains the average value of healing spells
	if sourceGUID and destGUID and healEvents[event] then
--		if sourceGUID == UnitGUID("player") then
--			local healname = select(13, ...)
--			local healVal = select(15, ...)
--			
--			if Healtable[healname] == nil then
--				Healtable[healname] = { 	
--					["healname"]= healname,
--					["healtotal"]= healVal,
--					["healcount"]= 1,
--					["averageheal"]=healVal
--				}
--			else
--				Healtable[healname]["healtotal"] = Healtable[healname]["healtotal"] + healVal
--				Healtable[healname]["healcount"] = Healtable[healname]["healcount"] + 1
--				Healtable[healname]["averageheal"] = Healtable[healname]["healtotal"] / Healtable[healname]["healcount"]
--			end
--		end

-- HEAL ENEMY TABLE -- contains the UnitGUID of Enemy Healers
		if isSourceEnemy then
			local healId = select(12, ...)
			local addEnemyHealer = false
			if jps.HealerSpellID[healId] then
				if EnemyHealer[sourceGUID] == nil then
					addEnemyHealer = true
				end
				if addEnemyHealer then EnemyHealer[sourceGUID] = {jps.HealerSpellID[healId],sourceName} end
			end
		end
	end

-- Table ENEMYCOOLDOWNS to track some CD Spells depends of spellID in table jps.EnemyCds
	if sourceGUID and destGUID and spellEvents[event] then
			local spellId = select(12, ...)
			local spellname = select(13, ...)
			local start, _, _ = GetSpellCooldown(spellId)
			if start > 0 and jps.EnemyCds[spellId] then
				local duration = jps.EnemyCds[spellId]
				if not EnemyCooldowns[sourceGUID] then EnemyCooldowns[sourceGUID] = {} end
				if not EnemyCooldowns[sourceGUID][spellId] then
					EnemyCooldowns[sourceGUID][spellId] = {start + duration, duration, spellname}
				elseif EnemyCooldowns[sourceGUID][spellId][2] == 0 then
					EnemyCooldowns[sourceGUID][spellId] = {start + duration, duration, spellname}
				end
			end

	end

-- DAMAGE TABLE Note that for the SWING prefix, _DAMAGE starts at the 12th parameter
	if sourceGUID and destGUID and damageEvents[event] then

		if isSourceEnemy and isDestRaid then
			local dmgTTD = 0
			if event == "SWING_DAMAGE" then
				local swing = select(12, ...)
				if swing == nil then swing = 0 end
				if swing > 0 then dmgTTD = swing end
			else
				local damage = select(15, ...)
				if damage == nil then damage = 0 end
				if damage > 0 then dmgTTD = damage end
			end
			
			if UnitCanAssist("player",destName) and UnitIsFriend("player",destName) then
				if EnemyDamager[sourceGUID] == nil then EnemyDamager[sourceGUID] = {} end
				EnemyDamager[sourceGUID]["friend"] = destGUID -- TABLE OF ENEMY GUID TARGETING FRIEND GUID
				EnemyDamager[sourceGUID]["friendname"] = destName
				EnemyDamager[sourceGUID]["friendaggro"] = {GetTime(), dmgTTD}
			end

		end
	end
end)

------------------------------
-- ENEMY TABLE
------------------------------
-- table.insert(table, [ position, ] valeur) -- table.insert(t, 1, "element") insert an element at the start
-- table.insert called without a position, it inserts the element in the last position of the array (and, therefore, moves no elements)
-- table.remove called without a position, it removes the last element of the array.

-- TABLE OF ENEMY GUID TARGETING FRIEND GUID
-- EnemyDamager[enemyGuid] = { ["friend"] = enemyFriend , [""friendname""] = destName , ["friendaggro"] = {GetTime(), dmgTTD} }
function jps.RaidEnemyCount()
	local enemycount = 0
	for unit,index in pairs(EnemyDamager) do
		enemycount = enemycount + 1
	end
	return enemycount
end

jps.EnemyHealer = function(unit)
	local unitguid = UnitGUID(unit)
	if EnemyHealer[unitguid] ~= nil then return true end
	return false
end

jps.EnemyDamager = function(unit)
	local unitguid = UnitGUID(unit)
	if EnemyDamager[unitguid] ~= nil then return true end
	return false
end

-- TABLE OF ENEMY GUID TARGETING FRIEND GUID
-- EnemyDamager[enemyGuid] = { ["friend"] = enemyFriend , [""friendname""] = destName , ["friendaggro"] = {GetTime(), dmgTTD} }
jps.FriendAggro = function (friend)
	local friendGuid = UnitGUID(friend)
	for _,index in pairs(EnemyDamager) do
		if index.friend == friendGuid then return true end
	end
	return false
end

-- Table of Targeted Friend -- Return SPELLNAME
local FriendTable = {}
jps.FriendAggroTable = function()
	table.wipe(FriendTable)
	for unit,index in pairs (EnemyDamager) do
		FriendTable[#FriendTable+1] = index.friendname
		-- table.insert(FriendTable, index.friendname) -- { "Bob" , "Fred" , "Bob" }
	end

	-- make unique keys
	local hash = {}
	for i=1,#FriendTable do -- for _,v in ipairs(FriendTable) do
		local v = FriendTable[i]
		local count = hash[v]
		if count == nil then count = 1 else count = count + 1 end
		hash[v] = count --  hash = { ["Bob] = 2 , ["Fred"] = 1}
	end

	-- transform keys back into values
	local dupe = {}
	for k,_ in pairs(hash) do
		dupe[#dupe+1] = k
	end
	table.sort(dupe, function(a,b) return jps.hp(a) < jps.hp(b) end)
	return dupe[1] or nil, dupe, #dupe
end

-- EnemyDamager[enemyGuid] = { ["friend"] = enemyFriend , [""friendname""] = destName , ["friendaggro"] = {GetTime(), dmgTTD} }
-- className, classId, raceName, raceId, gender, name, realm = GetPlayerInfoByGUID("guid")
jps.LookupEnemyDamager = function()
	if jps.tableLength(EnemyDamager) == 0 then print("EnemyDamager is Empty") end
	for unit,index in pairs(EnemyDamager) do
		print("EnemyGuid_|cFFFF0000: ",unit," |cffffffffFriendGuid_|cff1eff00: ",index.friend," |cffffffffName_|cff1eff00: ",index.friendname,"|cffffffffDmg|cFFFF0000: ",index.friendaggro[2])
	end
end

-- EnemyHealer[enemyGuid] = {Class,sourceName}
jps.LookupEnemyHealer = function()
	if jps.tableLength(EnemyHealer) == 0 then print("EnemyHealer is Empty") end
	for _,index in pairs(EnemyHealer) do
		print("Class:|cFFFF0000: ",index[1]," |cffffffffName:|cFFFF0000: ",index[2])
	end
end

------------------------------
-- SPELLTABLE -- contains the average value of healing spells
------------------------------

-- Resets the count of each healing spell to 1 makes sure that the average takes continuously into account changes in stats due to buffs etc
reset_healtable = function(self)
	for k,v in pairs(Healtable) do
		Healtable[k]["healtotal"] = Healtable[k]["averageheal"]
		Healtable[k]["healcount"] = 1
	end
end

-- Displays the different health values - mainly for tweaking/debugging
print_healtable = function(self)
	for k,v in pairs(Healtable) do
		print(k,"|cffff8000", Healtable[k]["healtotal"]," ", Healtable[k]["healcount"]," ", Healtable[k]["averageheal"])
	end
end

-- Returns the average heal value of given spell.
getaverage_heal = function(spell)
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
 	if Healtable[spellname] == nil then
		return 0
 	else
		return (Healtable[spellname]["averageheal"])
 	end
end


------------------------------
-- TIMETODIE Based on incoming DMG
------------------------------

-- 	RaidTimeToDie = {}
--	if RaidTimeToDie[destGUID] == nil then RaidTimeToDie[destGUID] = {} end
--	local dataset = RaidTimeToDie[destGUID]
--	local data = table.getn(dataset)
--	if data >= maxTDDLifetime then table.remove(dataset, maxTDDLifetime) end
--	table.insert(dataset, 1, {GetTime(), dmgTTD})
--	RaidTimeToDie[destGUID] = dataset
--	[[ RaidTimeToDie[destGuid] = { [1] = {GetTime(), thisEvent[15] },[2] = {GetTime(), thisEvent[15] },[3] = {GetTime(), thisEvent[15] } } ]]

-- jps.RaidTimeToDie[unitGuid] = { [1] = {GetTime(), eventtable[15] },[2] = {GetTime(), eventtable[15] },[3] = {GetTime(), eventtable[15] } }
-- table.getn Returns the size of a table, If the table has an n field with a numeric value, this value is the size of the table.
-- Otherwise, the size is the largest numerical index with a non-nil value in the table

--jps.DmgTimeToDie = function(unit)
--	if unit == nil then return 60 end
--	local guid = UnitGUID(unit)
--	local health_unit = UnitHealth(unit)
--	local timetodie = 60 -- e.g. 60 seconds
--	local totalDmg = 1 -- to avoid 0/0
--	local incomingDps = 1
--	if jps.RaidTimeToDie[guid] ~= nil then
--		local dataset = jps.RaidTimeToDie[guid]
--		local data = table.getn(dataset)
--		if #dataset > 1 then
--			local timeDelta = dataset[1][1] - dataset[data][1] -- (lasttime - firsttime)
--			local totalTime = math.max(timeDelta, 1)
--			for i,j in ipairs(dataset) do
--				totalDmg = totalDmg + j[2]
--			end
--			incomingDps = math.ceil(totalDmg / totalTime)
--		end
--		timetodie = math.ceil(health_unit / incomingDps)
--	end
--	return timetodie
--end

-- jps.RaidTimeToDie[unitGuid] = { [1] = {GetTime(), eventtable[15] },[2] = {GetTime(), eventtable[15] },[3] = {GetTime(), eventtable[15] } }
--	for unit,index in pairs(jps.RaidTimeToDie) do 
--		local dataset = jps.RaidTimeToDie[unit]
--		for i,j in ipairs(dataset) do
--			print("|cffa335ee","Guid_",unit,"/",i,"|cff1eff00","Time_",j[1],"|cff1eff00","Dmg_",j[2] )
--		end
--	end

--------------------------
-- COMBAT_LOG_EVENT_UNFILTERED FUNCTIONS
-- SPELL_FAILED
--------------------------

-- table.insert(table, [ position, ] valeur) -- table.insert(t, 1, "element") insert an element at the start
-- table.insert called without a position, it inserts the element in the last position of the array (and, therefore, moves no elements)
-- table.remove called without a position, it removes the last element of the array.

--jps.listener.registerCombatLogEventUnfiltered("SPELL_CAST_FAILED", function(...)
--	local sourceGUID = select(4,...)
--	local spellID =  select(12,...)
--	local failedType = select(15,...)
--	local spellname = select(13, ...)
--	if sourceGUID == UnitGUID("player") and type(failedType) == "string" then
--		--print("SPELL_CAST_FAILED "..spellID.."_"..spellname.."_"..failedType)
--		tinsert(SpellFailedTable,1,{spellname,failedType})
--	end
--end)
--
--jps.IsSpellFailed = function(spellname)
--	if jps.tableLength(SpellFailedTable) == 0 then return false end
--	for i,j in ipairs(SpellFailedTable) do
--		if j[1] == spellname and j[2] == "Insensible" then return true end
--	end
--	return false
--end
--
--jps.printIsSpellFailed = function()
--	for i,j in ipairs(SpellFailedTable) do
--		print(i,"-",j[1],"-",j[2])
--	end
--end
