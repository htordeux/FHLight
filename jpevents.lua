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
local EnemyTable = {}
local EnemyHealer = {}
-- HEALTABLE
local Healtable = {}
-- Timetodie based on incoming Damage
local RaidTimeToDie = {}
local GetTime = GetTime
-- RaidStatus
local canHeal = jps.canHeal
local UpdateRaidUnit = jps.UpdateRaidUnit
local UpdateRaidStatus = jps.UpdateRaidStatus
local pairs = pairs
local UnitIsPlayer = UnitIsPlayer

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
	if jps.Enabled and UnitAffectingCombat("player") == 1 and combatLogEventTable[event] then
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
	if GetAddOnMemoryUsage("JPS") > 5120 then collectgarbage("collect") end
end

-- TimeToDie Update
jps.registerOnUpdate(updateTimeToDie)

-- Combat -- and UPDATE 2 sec if not in COMBAT
jps.registerOnUpdate(function()
	if jps.Combat and jps.Enabled then
    	jps.Cycle()
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
	reset_healtable()
	jps.UpdateRaidStatus()
	EnemyHealer = {}
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
jps.listener.registerEvent("ACTIVE_TALENT_GROUP_CHANGED", jps.detectSpec)
jps.listener.registerEvent("ACTIVE_TALENT_GROUP_CHANGED", jps.resetRotationTable)

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
	jps.IsRaidLeader()
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

	-- nil all tables
	--jps.Timers = {} -- because of Holy Word: Chastise 88625 Cooldown
	RaidTimeToDie = {}
	EnemyTable = {}
	Healtable = {}
	jps.LastMessage = {}
	jps.TimeToDieData = {}
	jps.timedCasting = {}
	jps.HealerBlacklist = {} 
	jps.UpdateRaidStatus()

	collectgarbage()
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
	priest.AvgAmountHeal = (1+masteryValue)*(1+minCrit)*(11443+(1.102*bonusHealing))
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
	local cdStart, duration = GetSpellCooldown(61304)
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
		elseif jps.FaceTarget and ((event_error == SPELL_FAILED_UNIT_NOT_INFRONT) or (event_error == ERR_BADATTACKFACING)) then
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

-- "UNIT_SPELLCAST_SENT"
local sendTime = 0
local GetTime = GetTime
jps.listener.registerEvent("UNIT_SPELLCAST_SENT", function(unitID,spellname,_,spelltarget,_)
	if unitID == "player" then
		jps.SentCast = spellname
		sendTime = GetTime()
		jps.CurrentCastInterrupt = nil
		if spellname == tostring(select(1,GetSpellInfo(17))) then jps.createTimer("ShieldTimer", 12 ) end
	end
end)

local descriptorTable = { L["Strikes"] , L["Roots"] , L["Transforms"] , L["Forces"] , L["Seduces"] }
jps.listener.registerEvent("UNIT_SPELLCAST_START", function(unitID,spellname,_,_,spellID)
		if unitID == "player" then
			jps.CurrentCast = spellname
			jps.Latency = GetTime() - sendTime
			jps.GCD = GlobalCooldown()
			--jps.Casting = true
			--print("SPELLCAST_START: ",unitID,"spellname: ",spellname,"",jps.Casting)
		end
end)

jps.listener.registerEvent("UNIT_SPELLCAST_CHANNEL_START", function(unitID,spellname,_,_,spellID)
		if unitID == "player" and spellID ~= nil then
			jps.CurrentCast = spellname
			jps.Latency = GetTime() - sendTime
			jps.GCD = GlobalCooldown()
			--jps.Casting = true
			--print("CHANNEL_START: ",unitID,"spellname:",spellname,"",jps.Casting)
		end
end)

--jps.listener.registerEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(unitID,spellname,_,_,spellID)
--	if unitID == "player" and spellID ~= nil then
--		jps.Casting = false
--		print("CHANNEL_STOP: ",unitID,"spellname:",spellname,"",jps.Casting)
--	end
--end)

jps.listener.registerEvent("UNIT_SPELLCAST_INTERRUPTED", function(unitID,spellname,_,_,spellID)
	if unitID == "player" and spellID ~= nil then
		jps.CurrentCastInterrupt = spellname
		--jps.Casting = false
		--print("INTERRUPTED: ",unitID,"spellname:",spellname,": ",spellID)
	end
end)

--jps.listener.registerEvent("UNIT_SPELLCAST_STOP", function(unitID,spellname,_,_,spellID)
--	if unitID == "player" and spellID ~= nil then
--		jps.Casting = false
--		print("SPELLCAST_STOP: ",unitID,"spellname:",spellname,"",jps.Casting)
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

local stunTypeTable = {"STUN_MECHANIC", "STUN", "FEAR", "CHARM", "CONFUSE", "ROOT", "PACIFYSILENCE"}
jps.listener.registerEvent("LOSS_OF_CONTROL_ADDED", function ()
	local i = C_LossOfControl.GetNumEvents()
    local locType, _, text, _, _, _, duration = C_LossOfControl.GetEventInfo(i)
    --print("CONTROL:", locType,"/",text,"/",duration)
    if text and duration then
    	if locType == "SCHOOL_INTERRUPT" then jps.createTimer("PlayerInterrupt", duration ) end
    	if duration >= 2 then
			for _, stuntype in ipairs(stunTypeTable) do
				if locType == stuntype then 
					jps.createTimer("PlayerStun", duration )
				break end
			end
		end
    end
end)

--jps.listener.registerEvent("LOSS_OF_CONTROL_UPDATE", function()
--	local i = C_LossOfControl.GetNumEvents()
--	local _, _, text, _, _, _, duration = C_LossOfControl.GetEventInfo(i)
--	print("CONTROL_UPDATE: ",text, duration)
--end)

----------------------
-- UPDATE RAID ROSTER
----------------------
-- UNIT_HEALTH events are sent for raid and party members regardless of their distance from the character of the host. 
-- This makes UNIT_HEALTH extremely valuable to monitor PARTY AND RAID MEMBERS.
-- arg1 the UnitID of the unit whose health is affected player, pet, target, mouseover, party1..4, partypet1..4, raid1..40
-- "UNIT_HEALTH_FREQUENT" Same event as UNIT_HEALTH, but not throttled as aggressively by the client
-- "UNIT_HEALTH_PREDICTION" arg1 unitId receiving the incoming heal

-- local RaidStatusCoroutine = coroutine.create ( jps.UpdateRaidStatus )
-- Immediately after a coroutine is created, the code is “suspended” until you instruct Lua to resume it with coroutine.resume. 
-- coroutine.resume(RaidStatusCoroutine)
-- the coroutine is run until it reaches one of two things:
-- An explicit yielding point A yielding point can be created with the function coroutine.yield()
-- The end of the function (at which point it yields implicitly).
-- Because the coroutine has finished all of the code in the function, the status returned by coroutine.status is “dead”
-- We can no longer make use of it.

-- In Arena ??? Opposing arena member with index N (1,2,3,4 or 5).
jps.listener.registerEvent("UNIT_HEALTH_FREQUENT", function(unitID)
	if not jps.isHealer then return end
	if jps.UnitInRaid(unitID) then
		local inrange = canHeal(unitID)
		UpdateRaidUnit(unitID,inrange)
		if jps.PvP and not jps.Combat and jps.tableLength(EnemyTable) > 0 then
    		jps.Cycle()
		end
	end
end)

-- Group/Raid Update
-- RAID_ROSTER_UPDATE's pre-MoP functionality was moved to the new event GROUP_ROSTER_UPDATE
jps.listener.registerEvent("GROUP_ROSTER_UPDATE", jps.UpdateRaidStatus)
jps.listener.registerEvent("ARENA_TEAM_ROSTER_UPDATE", jps.UpdateRaidStatus)

-----------------------
-- UPDATE ENEMY TABLE
-----------------------
-- "UNIT_TARGET" Fired when the target of yourself, raid, and party members change: 'target', 'party1target', 'raid1target', etc.. 
-- Should also work for 'pet' and 'focus'. This event only fires when the triggering unit is within the player's visual range

jps.listener.registerEvent("UNIT_TARGET", jps.LowestTarget)

local updateEnemyTable = function()
	for unit,index in pairs(EnemyTable) do
		local dataset = index.friendaggro
		if dataset then 
			local timeDelta = GetTime() - dataset[1]
			if timeDelta > 2 then EnemyTable[unit] = nil end
		end
	end
end

-----------------------
-- UPDATE HEALERBLACKLIST
-----------------------

--local GetNumGroupMembers = GetNumGroupMembers
--local isArena, _ = IsActiveBattlefieldArena() -- isArena - 1 if player is in an Arena match; otherwise nil
--local UpdateScoreFrequency = function()
--	if isArena == 1 then scoreFrequency  = 0.2
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
	updateEnemyTable()
	-- Update RaidStatus if not jps.isHealer
	if not jps.isHealer then
		UpdateRaidStatus()
	end
	if #jps.LastMessage > 2 then
		for i=3,#jps.LastMessage do jps.LastMessage[i] = nil end
	end
end

-- HealerBlacklist Update
jps.registerOnUpdate(UpdateIntervalRaidStatus)

------------------------
-- Healer ENEMY Table
------------------------

local HealerSpellID = {

        -- Priests
        -- Discipline
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
        [000139] = "PRIEST", -- Renew -- exists also for shadow priests
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

-- isArena, isRegistered = IsActiveBattlefieldArena()
-- isArena - 1 if player is in an Arena match; otherwise nil
-- IsInRaid() Boolean - returns true if the player is currently in a raid group, false otherwise
-- IsInGroup() Boolean - returns true if the player is in a some kind of group, otherwise false

-- leader = UnitIsRaidOfficer("unit") -- 1 if the unit is a raid assistant; otherwise nil or false if not in raid
-- leader = UnitIsGroupLeader("unit") -- true if the unit is a raid assistant; otherwise false (bool)
local IsRaidLeader = jps.IsRaidLeader()
local PlayerIsLeader = function()
	if IsInRaid() and IsRaidLeader > 0 then return true end
	if not IsInRaid() and not IsInGroup() then return true end
	return false
end

--	  0 - Clear any raid target markers
--    1 - Star
--    2 - Circle
--    3 - Diamond
--    4 - Triangle
--    5 - Moon
--    6 - Square
--    7 - Cross
--    8 - Skull

-- {"skull",false,8} keep it for target to kill
local MarkerTable = { {"star",false,1}, {"triangle",false,4}, {"cross",false,7} }
local resetMarkerTable = function()
	MarkerTable = { {"star",false,1}, {"triangle",false,4}, {"cross",false,7} }
end

local hookSetRaidTarget = function(unit, index)
	SetRaidTarget(unit, index)
end
hooksecurefunc("SetRaidTarget",hookSetRaidTarget)

jps.TargetMarker = function(unit,num)
	local playerAssistRaid = PlayerIsLeader()
	if not playerAssistRaid then return end
	if IsAltKeyDown() then SetRaidTarget("target",0) return end
	
	if GetRaidTargetIndex(unit) == nil and type(num) == "number" then SetRaidTarget(unit, num) return end
	if GetRaidTargetIndex(unit) == nil then
		for _,index in ipairs(MarkerTable) do
			if index[2] == false then
				SetRaidTarget(unit, index[3])
				index[2] = true
			break end
		end
	end
	-- if all MarkerTable are true reset the table
	if GetRaidTargetIndex(unit) == nil then
		resetMarkerTable()
		SetRaidTarget(unit, 1)
		MarkerTable[1][2] = true
	end
end

-- EnemyHealer[UnitGUId] = {"MONK"}
-- className, classId, raceName, raceId, gender, name, realm = GetPlayerInfoByGUID("guid")
jps.listener.registerEvent("UPDATE_MOUSEOVER_UNIT", function()
	if jps.getConfigVal("set healer as focus") == 1 then
		local unitGuidMouseover = UnitGUID("mouseover")
		if EnemyHealer[unitGuidMouseover] then
			local class = EnemyHealer[unitGuidMouseover][1]
			local name = EnemyHealer[unitGuidMouseover][2]
			print("Enemy HEALER|cff1eff00 "..name.." |cffffffffClass|cff1eff00 "..class.." |cffffffffset as FOCUS")
			jps.TargetMarker("mouseover")
		end
	end
end)

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

-- UNIT_DIED destGUID and destName refer to the unit that died.
jps.listener.registerCombatLogEventUnfiltered("UNIT_DIED", function(...)
	local destGUID = select(8,...)
	if EnemyTable[destGUID] then EnemyTable[destGUID] = nil end
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
	local sourceFlags = select(6,...)
	local destGUID = select(8,...)
	local destName = select(9,...)
	local destFlags = select(10,...)
	
-- The numeric values of the global variables starts with 1 for MINE and increases toward OUTSIDER with 8
	local isDestEnemy = bitband(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
	local isDestRaid = bitband(destFlags, RAID_AFFILIATION) > 0
	local isSourceRaid = bitband(sourceFlags, RAID_AFFILIATION) > 0
	local isSourceEnemy = bitband(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE

-- HEAL TABLE -- contains the average value of healing spells
	if sourceGUID and destGUID and healEvents[event] then

		if sourceGUID == UnitGUID("player") then
			local healname = select(13, ...)
			local healVal = select(15, ...)
			
			if Healtable[healname] == nil then
				Healtable[healname] = { 	
					["healname"]= healname,
					["healtotal"]= healVal,
					["healcount"]= 1,
					["averageheal"]=healVal
				}
			else
				Healtable[healname]["healtotal"] = Healtable[healname]["healtotal"] + healVal
				Healtable[healname]["healcount"] = Healtable[healname]["healcount"] + 1
				Healtable[healname]["averageheal"] = Healtable[healname]["healtotal"] / Healtable[healname]["healcount"]
			end
		end

-- HEAL ENEMY TABLE -- contains the UnitGUID of Enemy Healers
		if isSourceEnemy then
			local healId = select(12, ...)
			local sourceName = select(5,...)
			local updateEnemyHealer = false
			if HealerSpellID[healId] then
				if EnemyHealer[sourceGUID] == nil then
					updateEnemyHealer = true
				end
				if updateEnemyHealer then EnemyHealer[sourceGUID] = {HealerSpellID[healId],sourceName} end
			end
		end
	
	end

-- DAMAGE TABLE Note that for the SWING prefix, _DAMAGE starts at the 12th parameter
	if sourceGUID and destGUID and damageEvents[event] then
	
--	if jps.Debug then
--		print("COMBATLOG_OBJECT_TYPE_PLAYER =", COMBATLOG_OBJECT_TYPE_PLAYER,bitband(sourceFlags,COMBATLOG_OBJECT_TYPE_PLAYER),
--		"COMBATLOG_OBJECT_AFFILIATION_MINE =", COMBATLOG_OBJECT_AFFILIATION_MINE,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_MINE),
--		"COMBATLOG_OBJECT_AFFILIATION_PARTY =", COMBATLOG_OBJECT_AFFILIATION_PARTY,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_PARTY),
--		"COMBATLOG_OBJECT_AFFILIATION_RAID =", COMBATLOG_OBJECT_AFFILIATION_RAID,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_RAID),
--		"COMBATLOG_OBJECT_REACTION_HOSTILE	=", COMBATLOG_OBJECT_REACTION_HOSTILE,bitband(sourceFlags,COMBATLOG_OBJECT_REACTION_HOSTILE),
--		"COMBATLOG_OBJECT_REACTION_FRIENDLY =", COMBATLOG_OBJECT_REACTION_FRIENDLY,bitband(sourceFlags,COMBATLOG_OBJECT_REACTION_FRIENDLY),
--		"COMBATLOG_OBJECT_AFFILIATION_OUTSIDER =", COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,bitband(sourceFlags,COMBATLOG_OBJECT_AFFILIATION_OUTSIDER),
--		"RAID_AFFILIATION =", RAID_AFFILIATION,bitband(sourceFlags,RAID_AFFILIATION))

--		if isSourceEnemy then
--			print("isSourceEnemy: ", bitband(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE))
--		elseif isDestEnemy then
--			print("isDestEnemy: ", bitband(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE))
--		end
--	end

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
			
			if canHeal(destName) then
				if EnemyTable[sourceGUID] == nil then EnemyTable[sourceGUID] = {} end
				EnemyTable[sourceGUID]["friend"] = destGUID -- TABLE OF ENEMY GUID TARGETING FRIEND GUID
				EnemyTable[sourceGUID]["friendname"] = destName
				EnemyTable[sourceGUID]["friendaggro"] = {GetTime(), dmgTTD}
			end

		end
	end
end)

------------------------------
-- ENEMY TABLE
------------------------------
-- table.insert called without a position, it inserts the element in the last position of the array (and, therefore, moves no elements)
-- table.remove called without a position, it removes the last element of the array.

-- EnemyTable[enemyGuid] = { ["friend"] = enemyFriend } -- TABLE OF ENEMY GUID TARGETING FRIEND NAME
-- COUNT ENEMY ONLY WHEN THEY DO DAMAGE TO INRANGE FRIENDS
function jps.RaidEnemyCount()
	local enemycount = 0
	for unit,index in pairs(EnemyTable) do
		enemycount = enemycount + 1
	end
	return enemycount
end

-- EnemyTable[enemyGuid] = { ["friend"] = enemyFriend } -- TABLE OF ENEMY GUID TARGETING FRIEND GUID
jps.FriendAggro = function (friend)
	local friendGuid = UnitGUID(friend)
	for _,index in pairs(EnemyTable) do
		if index.friend == friendGuid then return true end
	end
	return false
end

-- Table of Targeted Friend -- Return SPELLNAME
local FriendTable = {}
jps.FriendAggroTable = function()
	jps.removeTable(FriendTable)
	for unit,index in pairs (EnemyTable) do
		table.insert(FriendTable, index.friendname) -- { "Bob" , "Fred" , "Bob" }
	end

	-- make unique keys
	local hash = {}
	for _,v in ipairs(FriendTable) do
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

-- EnemyTable[enemyGuid] = { ["friend"] = enemyFriend , [""friendname""] = destName , ["friendaggro"] = dmgTTD }
jps.LookupEnemy = function()
	if jps.tableLength(EnemyTable) == 0 then print("EnemyTable is nil") end
	for unit,index in pairs(EnemyTable) do
		print("|cffa335ee","EnemyGuid_",unit,"|cff1eff00","FriendGuid_",index.friend,"|cffe5cc80Name_",index.friendname,"|cFFFF0000Dmg:",index.friendaggro[1],"/",index.friendaggro[2])
	end
end

-- EnemyHealer[enemyGuid] = {Class,sourceName}
jps.LookupEnemyHealer = function()
	if jps.tableLength(EnemyHealer) == 0 then print("EnemyHealer is nil") end
	for _,index in pairs(EnemyHealer) do
		print("|cffff8000Class: ",index[1],"|cffe5cc80Name: ",index[2])
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
	local spellname = nil
	if type(spell) == "string" then spellname = spell end
	if type(spell) == "number" then spellname = tostring(select(1,GetSpellInfo(spell))) end
	
 	if Healtable[spellname] == nil then
		return 0
 	else
		return (Healtable[spellname]["averageheal"])
 	end
end


------------------------------
-- TIMETODIE Based on incoming DMG
------------------------------

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