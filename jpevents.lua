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


jps.events = {}
local eventLoop = {}

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



-- TABLE ENEMIES IN COMBAT
local EnemyDamager = {}
setmetatable(EnemyDamager, { __mode = 'k' }) -- creation of a weak table
local EnemyHealer = {}
setmetatable(EnemyHealer, { __mode = 'k' }) -- creation of a weak table
-- HEALTABLE
local Healtable = {}
setmetatable(Healtable, { __mode = 'k' }) -- creation of a weak table
-- IncomingDamage
local IncomingDamage = {}
setmetatable(IncomingDamage, { __mode = 'k' }) -- creation of a weak table
-- Incoming Heal
local IncomingHeal = {}
setmetatable(IncomingHeal, { __mode = 'k' }) -- creation of a weak table

-- RaidStatus
local UnitGUID = UnitGUID
local GetTime = GetTime
local canHeal = jps.canHeal
local canDPS = jps.canDPS
local GetUnitName = GetUnitName
local pairs = pairs
local tinsert = table.insert
local tremove = table.remove
local toSpellName = jps.toSpellName
local GetUnitName = GetUnitName

--------------------------
-- (UN)REGISTER FUNCTIONS 
--------------------------

function jps.registerOnUpdate(fn)
	if not updateTable[fn] then
		updateTable[fn] = fn
		return true
	end
end

function jps.unregisterOnUpdate(fn)
	if updateTable[fn] then
		updateTable[fn] = nil
		return true
	end
end

function jps.events.registerEvent(event, fn)
	if not eventTable[event] then
		eventTable[event] = {}
		jpsFrame:RegisterEvent(event)
	end
	if not eventTable[event][fn] then
		eventTable[event][fn] = fn
		return true
	end
end


function jps.events.unregisterEvent(event, fn)
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

function jps.events.registerCombatLog(event, fn)
	if not combatLogEventTable[event] then
		combatLogEventTable[event] = {}
		jpsFrame:RegisterEvent(event)
	end
	if not combatLogEventTable[event][fn] then
		combatLogEventTable[event][fn] = fn
		return true
	end
end


function jps.events.unregisterCombatLog(event, fn)
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
end)

--- COMBAT_LOG_EVENT_UNFILTERED Handler
jps.events.registerEvent("COMBAT_LOG_EVENT_UNFILTERED", function(timeStamp, event, ...)
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

--[[[
@function jps.cachedValue
@description
This function generates a function which will store a value which might be too expensive to generate everytime. You must provide
a function which generates the value which will be called every [code]updateInterval[/code] seconds to refresh the cached value.
@param fn function which generates the value
@param updateInterval [i]Optional:[/i] max age in seconds before the value is fetched again from the function - defaults to [code]jps.UpdateInterval[/code]
@returns A function which will return the cached value
]]--

local LastUpdateFrequency = GetTime()
jps.cachedValue = function(fn,updateInterval)
	if not updateInterval then updateInterval = 1 end
	local curTime = GetTime()
	local diff = curTime - LastUpdateFrequency
	if diff < updateInterval then return end
	LastUpdateFrequency = curTime
	local value = fn()
	return value
end

-- Garbage Collection is automatic in lua every 30 sec
local collectGarbage = function()
	UpdateAddOnMemoryUsage()
	local Memory = GetAddOnMemoryUsage("JPS")
	if Memory > 8192 and not jps.Casting then
		write("Memory: ", Memory)
		collectgarbage("collect")
	end
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

jps.registerOnUpdate(function()
	jps.cachedValue(collectGarbage,30)
end)

----------------------
-- NAMEPLATES
----------------------

--[[

SetCVar("nameplateMaxDistance", 40)
The nameplates show up at 45 yards (the old default was 40 I believe, the new one is 60).

SetCVar("nameplateLargeTopInset", -1)
SetCVar("nameplateOtherTopInset", -1)
SetCVar("nameplateLargeBottomInset", -1)
SetCVar("nameplateOtherBottomInset", -1)
These stop the nameplates from showing up and jumping around when the character isn't in your field of vision anymore.

SetCVar("nameplateSelectedScale", 0.9)
Makes the nameplate of your target not as ridiculously big.

SetCVar("nameplateMinAlpha", 0.8)
Makes the nameplates that you aren't targeting easier to see (less transparent).

SetCVar("NoBuffDebuffFilterOnTarget", 1)
Doesn't have anything to do with the nameplates, but it once again makes it show all debuffs on the enemy, not just yours.

Mind you, you need to do this for every single character. You can make it into an addon to make it automatic though, here's the code I use:

local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_LOGIN")

Frame:SetScript("OnEvent", function(...)
SetCVar("nameplateMaxDistance", 45)
SetCVar("nameplateLargeTopInset", -1)
SetCVar("nameplateOtherTopInset", -1)
SetCVar("nameplateLargeBottomInset", -1)
SetCVar("nameplateOtherBottomInset", -1)
SetCVar("nameplateHorizontalScale", 1)
SetCVar("nameplateLargerScale", 1)
SetCVar("nameplateSelectedScale", 0.9)
SetCVar("nameplateMinAlpha", 0.8)
SetCVar("ShowDispelDebuffs", 0)
SetCVar("NoBuffDebuffFilterOnTarget", 1)
SetCVar("nameplateMotion", 1) -- 1 doesn't allow nameplates to overlap
end)

Overlapping vertically
/script SetCVar("nameplateOverlapV", 0.35)
Default to this one is 1.1
Overlapping Horizontally
/script SetCVar("nameplateOverlapH", 0.35)
Default is 0.8. Change value with a number.

SetCVar("NameplateOtherAtBase",2)
nameplates at the target's feet

SET spreadnameplates value
1 Nameplates may not overlap, and will be constantly shuffled around to fit on the screen while remaining as close as possible to their units.
0 Nameplates may overlap, and will stay more or less directly above the units they represent.


]]

-- Nameplates
local SetNamePlate = function ()
	SetCVar("nameplateMaxDistance", 40)
	--SetCVar("nameplateOtherTopInset", -1)
	--SetCVar("nameplateOtherBottomInset", -1)
	SetCVar("nameplateOtherTopInset", GetCVarDefault("nameplateOtherTopInset"))
	SetCVar("nameplateOtherBottomInset", GetCVarDefault("nameplateOtherBottomInset"))
	
	SetCVar("nameplateLargeTopInset", -1)
	SetCVar("nameplateLargeBottomInset", -1)

	--SetCVar("nameplateHorizontalScale", 1.0)
	--SetCVar("namePlateVerticalScale", 1.0)
	SetCVar("NamePlateHorizontalScale", GetCVarDefault("NamePlateHorizontalScale"))
	SetCVar("NamePlateVerticalScale", GetCVarDefault("NamePlateVerticalScale"))
	--SetCVar("nameplateMinScale", GetCVarDefault("nameplateMinScale"))
	--SetCVar("namePlateMaxScale", GetCVarDefault("namePlateMaxScale"))
	SetCVar("nameplateLargerScale", 1)
	SetCVar("nameplateSelectedScale", 1) -- Makes the nameplate of your target not as ridiculously big.
	SetCVar("nameplateMinAlpha", 1)
	-- SetCVar("nameplateMaxAlpha", GetCVarDefault("nameplateMaxAlpha"))

	SetCVar("ShowDispelDebuffs", 0)
	SetCVar("nameplateShowSelf", 0) -- remove the hp/mana bar that is under your character
	SetCVar("NoBuffDebuffFilterOnTarget", 1)
	SetCVar("nameplateMotion", 1)
end

local activeUnitPlates = {}

local function AddNameplate(unitID)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
	if UnitCanAttack("player",unitID) then
		activeUnitPlates[unitID] = nameplate:GetName()
	end
end

local function RemoveNameplate(unitID)
	activeUnitPlates[unitID] = nil
end

jps.events.registerEvent("NAME_PLATE_UNIT_ADDED", function(unitID)
	AddNameplate(unitID)
end)

jps.events.registerEvent("NAME_PLATE_UNIT_REMOVED", function(unitID)
	RemoveNameplate(unitID)
end)

function jps.NamePlate()
	return activeUnitPlates
end

function jps.NamePlateCount()
	local plateCount = 0
	for unit,_ in pairs(activeUnitPlates) do
		if UnitAffectingCombat(unit) then plateCount = plateCount + 1 end
	end
	return plateCount
end

function jps.NamePlateDebuffCount(debuff)
	local plateCount = 0
	for unit,_ in pairs(activeUnitPlates) do
		if UnitAffectingCombat(unit) and not jps.myDebuff(debuff,unit) then plateCount = plateCount + 1 end
	end
	return plateCount
end

jps.PlayerIsTarget = function()
	for unit,_ in pairs(activeUnitPlates) do
		if jps.UnitExists(unit.."target") then
			local target = unit.."target"
			if UnitIsUnit(target,"player") then return true end
		end
	end
	return false
end

jps.UnitIsTarget = function(unit)
	for unit,_ in pairs(activeUnitPlates) do
		if jps.UnitExists(unit.."target") then
			local target = unit.."target"
			if UnitIsUnit(target,unit) then return true end
		end
	end
	return false
end


--------------------------
-- EVENT FUNCTIONS
--------------------------

-- PLAYER_LOGIN
jps.events.registerEvent("PLAYER_LOGIN", function()
	NotifyInspect("player")
end)

-- PLAYER_ENTERING_WORLD
-- Fired when the player enters the world, reloads the UI, enters/leaves an instance or battleground, or respawns at a graveyard.
-- Also fires any other time the player sees a loading screen
jps.events.registerEvent("PLAYER_ENTERING_WORLD", function()
	jps.detectSpec()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
	updateDropdownMenu()
	SetNamePlate()
end)

-- INSPECT_READY
jps.events.registerEvent("INSPECT_READY", function()
	if not jps.Spec then jps.detectSpec() end
end)

-- VARIABLES_LOADED
jps.events.registerEvent("VARIABLES_LOADED", jps_VARIABLES_LOADED)

-- Dual Spec Respec -- only fire when spec change no other event before
jps.events.registerEvent("ACTIVE_TALENT_GROUP_CHANGED", function()
	jps.detectSpec()
	jps.resetRotation()
	updateDropdownMenu()
end)

jps.events.registerEvent("SPELLS_CHANGED", function()
	jps.GetHarmfulSpell()
end)

-- Save on Logout
jps.events.registerEvent("PLAYER_LEAVING_WORLD", jps_SAVE_PROFILE)

-- Hide Static Popup - thx here to Phelps & ProbablyEngine
local hideStaticPopup = function(addon, eventBlocked) 
	if string.upper(addon) == "JPS" then
		StaticPopup1:Hide()
		LOG.debug("Addon Action Blocked: %s", eventBlocked)
	end
end
jps.events.registerEvent("ADDON_ACTION_FORBIDDEN", hideStaticPopup)
jps.events.registerEvent("ADDON_ACTION_BLOCKED", hideStaticPopup)

-- Enter Combat
jps.events.registerEvent("PLAYER_REGEN_DISABLED", function()
	jps.Combat = true
	jps.gui_toggleCombat(true)
	jps.combatStart = GetTime()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
	jps.Timers = {}
end)

-- Leave Combat
local leaveCombat = function()
	jps.Combat = false
	jps.gui_toggleCombat(false)
	jps.combatStart = 0
	jps.NextSpell = nil

	-- nil all tables
	EnemyDamager = {}
	IncomingDamage = {}
	IncomingHeal = {}
	Healtable = {}
	jps.TimeToDieData = {}
	jps.TimedCasting = {}
	jps.HealerBlacklist = {} 
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
	jps.castSequence = {}
	jps.LastCastUnitWipe()

	-- Garbage
	collectGarbage()
end

jps.events.registerEvent("PLAYER_REGEN_ENABLED", leaveCombat)
jps.events.registerEvent("PLAYER_UNGHOST", leaveCombat)

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

local classNames = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID" }
local _,classPlayer,_ = UnitClass("player")

-- UI_ERROR_MESSAGE
--arg1 message_string Legion This section concerns content exclusive to Legion.
--arg1 message_type, see GetGameMessageInfo
--arg2 message_string
--252 Another action is in progress
--50 Can't do that while moving
--50 Interrupted
--51 Item is not ready yet.
--220 You have no target.

jps.events.registerEvent("UI_ERROR_MESSAGE", function(number_error,event_error)
	--if jps.FaceTarget then print("event_error:",number_error,"-",event_error) end
	if (event_error == SPELL_FAILED_NOT_BEHIND) then
		jps.isNotBehind = true
		jps.isBehind = false
	--elseif jps.FaceTarget and not jps.Moving and event_error == ERR_BADATTACKFACING then
	elseif jps.FaceTarget and not jps.Moving and event_error == SPELL_FAILED_UNIT_NOT_INFRONT then
		if jps.checkTimer("Facing") == 0 then
			jps.createTimer("Facing",1)
			TurnLeftStart()
			C_Timer.After(1,function() TurnLeftStop() end)
		end
	elseif (event_error == SPELL_FAILED_LINE_OF_SIGHT) or (event_error == SPELL_FAILED_VISION_OBSCURED) then
		jps.BlacklistPlayer(jps.LastTarget)
	elseif jps.FaceTarget and not jps.Moving and event_error == ERR_BADATTACKPOS then
		if classPlayer == "WARRIOR" and jps.canDPS("target") then
			MoveForwardStart()
			C_Timer.After(0.6,function() MoveForwardStop() end)
		end
	end
end)

-- UNIT_SPELLCAST_SUCCEEDED
jps.events.registerEvent("UNIT_SPELLCAST_SUCCEEDED", function(unitID,spellname,_,_,spellID)
	if (unitID == "player") and spellID then
		jps.CurrentCastInterrupt = nil
		if jps.FaceTarget and jps.checkTimer("Facing") > 0 then
			TurnLeftStop()
			CameraOrSelectOrMoveStop()
		end
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
jps.events.registerEvent("UNIT_SPELLCAST_SENT", function(unitID,spellname,_,spelltarget,_)
	if unitID == "player" then
		sendTime = GetTime()
		jps.CurrentCastInterrupt = nil
		--print("SPELLCAST_SENT: ",unitID,"spellname: ",spellname,"spellID: ",spellID)
	end
end)

jps.events.registerEvent("UNIT_SPELLCAST_START", function(unitID,spellname,_,_,spellID)
		if unitID == "player" then
			jps.CurrentCast = spellname
			jps.Latency = GetTime() - sendTime
			jps.GCD = GlobalCooldown()
			--print("SPELLCAST_START: ",unitID,"spellname: ",spellname,"spellID: ",spellID)
		end
end)

jps.events.registerEvent("UNIT_SPELLCAST_CHANNEL_START", function(unitID,spellname,_,_,spellID)
		if unitID == "player" and type(spellname) == "string" then
			jps.CurrentCast = spellname
			jps.Latency = GetTime() - sendTime
			jps.GCD = GlobalCooldown()
			--print("SPELLCHANNEL_START: ",unitID,"spellname: ",spellname,"spellID: ",spellID)
		end
end)

jps.events.registerEvent("UNIT_SPELLCAST_INTERRUPTED", function(unitID,spellname,_,_,spellID)
	if unitID == "player" and type(spellname) == "string" then
		jps.CurrentCastInterrupt = spellname
		--print("INTERRUPTED: ",unitID,"spellname:",spellname,": ",spellID)
	end
end)

--jps.events.registerEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(unitID,spellname,_,_,spellID)
--	if unitID == "player" and spellID ~= nil then
--		print("CHANNEL_STOP: ",unitID,"spellname:",spellname,"spellID: ",spellID)
--	end
--end)

jps.events.registerEvent("UNIT_SPELLCAST_STOP", function(unitID,spellname,_,_,spellID)
	if unitID == "player" and spellID ~= nil then
		if not jps.Casting then collectGarbage() end
		--print("SPELLCAST_STOP: ",unitID,"spellname:",spellname,"spellID: ",spellID)
	end
end)

----------------------
-- LOSS_OF_CONTROL
----------------------

-- LossOfControlType, _, LossOfControlText, _, LossOfControlStartTime, LossOfControlTimeRemaining, duration, _, _, _ = C_LossOfControl.GetEventInfo(eventIndex)
-- eventIndex Number - index of the loss-of-control effect currently affecting your character to return information about, ascending from 1. 
-- LossOfControlType : --STUN_MECHANIC --STUN --PACIFYSILENCE --SILENCE --FEAR --CHARM --PACIFY --CONFUSE --POSSESS --SCHOOL_INTERRUPT --DISARM --ROOT
-- name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellId or spellName)

-- start, duration, enabled = GetSpellCooldown("spellName" or spellID or slotID, "bookType")
-- if spell has no cd then start, duration, enabled = 0,0,1
-- if spell has cd then duration is the global cooldown

local stunTypeTable = {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
jps.events.registerEvent("LOSS_OF_CONTROL_ADDED", function ()
	local i = C_LossOfControl.GetNumEvents()
    local locType, spellID, text, _, _, _, duration = C_LossOfControl.GetEventInfo(i)
    --print("CONTROL:", locType,"/",text,"/",duration)
    if spellID and duration then
		if jps.SpellControl[spellID] == nil then jps.SpellControl[spellID] = locType end
    	if locType == "SCHOOL_INTERRUPT" then
    		if jps.checkTimer("PlayerInterrupt") == 0 then jps.createTimer("PlayerInterrupt",duration) end
    	else
			for i=1,#stunTypeTable do -- for _,stuntype in ipairs(stunTypeTable) do
				local stunType = stunTypeTable[i]
				if locType == stunType then 
					if jps.checkTimer("PlayerStun") == 0 then jps.createTimer("PlayerStun",duration) end
				break end
			end
		end
    end
end)

-- locType, spellID, text, iconTexture, startTime, timeRemaining, duration, lockoutSchool, priority, displayType = C_LossOfControl.GetEventInfo(eventIndex)
-- locType: String - Effect type, e.g. "SCHOOL_INTERRUPT"
-- spellID: Number - Spell ID causing the effect, e.g. 33786 for Cyclone.
-- text: String - Name of the effect, e.g. "Interrupted".
-- startTime: Number - Time at which this effect began, as per GetTime()

jps.events.registerEvent("LOSS_OF_CONTROL_UPDATE", function()
	local i = C_LossOfControl.GetNumEvents()
	local locType, spellID, text, _, startTime, _, duration = C_LossOfControl.GetEventInfo(i)
	if spellID and duration then
    	if locType == "SCHOOL_INTERRUPT" then
    		jps.createTimer("PlayerInterrupt",duration)
    	else
			for i=1,#stunTypeTable do -- for _,stuntype in ipairs(stunTypeTable) do
				local stunType = stunTypeTable[i]
				if locType == stunType then 
					jps.createTimer("PlayerStun",duration)
				break end
			end
		end
	end
end)

----------------------
-- UPDATE RAID STATUS
----------------------
-- UNIT_HEALTH events are sent for raid and party members regardless of their distance from the character of the host. 
-- This makes UNIT_HEALTH extremely valuable to monitor PARTY AND RAID MEMBERS.
-- arg1 the UnitID of the unit whose health is affected player, pet, target, mouseover, party1..4, partypet1..4, raid1..40
-- "UNIT_HEALTH_FREQUENT" Same event as UNIT_HEALTH, but not throttled as aggressively by the client
-- "UNIT_HEALTH_PREDICTION" arg1 unitId receiving the incoming heal

jps.events.registerEvent("UNIT_HEALTH_FREQUENT", function(unitID)
	if jps.isHealer then
		jps.UpdateRaidStatus()
		if UnitAffectingCombat(unitID) and canHeal(unitID) then jps.Combat = true end
	else
		jps.UpdateRaidUnit(unitID)
	end
end)

-- Group/Raid Update
-- RAID_ROSTER_UPDATE's pre-MoP functionality was moved to the new event GROUP_ROSTER_UPDATE
-- PARTY_MEMBER_DISABLE -- Fired when a specific party member is offline or dead 
jps.events.registerEvent("GROUP_ROSTER_UPDATE", function()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
end)

jps.events.registerEvent("PARTY_MEMBER_DISABLE", function()
	jps.UpdateRaidStatus()
	jps.UpdateRaidRole()
end)


-- "UNIT_AURA" Fired when a buff, debuff, status, or item bonus was gained by or faded from an entity (player, pet, NPC, or mob.)
jps.events.registerEvent("UNIT_AURA", function(unitID)
	jps.RaidStatusDebuff()
end)

-----------------------
-- UPDATE ENEMY TABLE
-----------------------
-- "UNIT_TARGET" Fired when the target of yourself, raid, and party members change: 'target', 'party1target', 'raid1target', etc.. 
-- Should also work for 'pet' and 'focus'. This event only fires when the triggering unit is within the player's visual range

-- EnemyDamager[sourceGuid] = { ["friendguid"] = friendGuid , ["friendaggro"] = GetTime() }
local updateEnemyDamager = function()
	for unit,index in pairs(EnemyDamager) do
		local dataset = index.friendaggro
		if dataset then 
			local timeDelta = GetTime() - dataset
			if timeDelta > 6 then EnemyDamager[unit] = nil end
		end
	end
end

-- IncomingDamage[destGUID] = { {GetTime(),damage,destName}, ... }
local updateIncomingDamage = function()
	for unit,index in pairs(IncomingDamage) do
		local data = #index
		local delta = GetTime() - index[1][1]
		if delta > 6 then IncomingDamage[unit] = nil end
	end
end

-- IncomingHeal[destGUID] = ( {GetTime(),heal,destName}, ... )
local updateIncomingHeal = function()
	for unit,index in pairs(IncomingHeal) do
		local data = #index
		local delta = GetTime() - index[1][1]
		if delta > 6 then IncomingHeal[unit] = nil end
	end
end

-----------------------
-- UPDATE HEALERBLACKLIST
-----------------------

local UpdateIntervalRaidStatus = function()
	jps.UpdateHealerBlacklist()
	updateEnemyDamager()
	updateIncomingDamage()
	updateIncomingHeal()
end


jps.registerOnUpdate(function()
	jps.cachedValue(UpdateIntervalRaidStatus,1)
end)


--------------------------
-- COMBAT_LOG_EVENT_UNFILTERED FUNCTIONS
--------------------------
-- eventtable[1] == timestamp
-- eventtable[2] == combatEvent
-- eventtable[3] == hideCaster
-- eventtable[4] == sourceGUID
-- eventtable[5] == sourceName
-- eventtable[6] == sourceFlags
-- eventtable[7] == sourceFlags2
-- eventtable[8] == destGUID
-- eventtable[9] == destName
-- eventtable[10] == destFlags
-- eventtable[11] == destFlags2
-- eventtable[12] == spellID -- amount if prefix is SWING_DAMAGE
-- eventtable[13] == spellName -- amount if prefix is ENVIRONMENTAL_DAMAGE
-- eventtable[14] == spellSchool -- 1 Physical, 2 Holy, 4 Fire, 8 Nature, 16 Frost, 32 Shadow, 64 Arcane
-- eventtable[15] == amount if suffix is SPELL_DAMAGE or SPELL_HEAL -- spellHealed
-- eventtable[16] == spellCount if suffix is _AURA

-- for the SWING prefix, _DAMAGE starts at the 12th parameter. 
-- for ENVIRONMENTAL prefix, _DAMAGE starts at the 13th.


local damageEvents = {
        ["SWING_DAMAGE"] = true,
        ["SPELL_DAMAGE"] = true,
        ["SPELL_PERIODIC_DAMAGE"] = true,
        ["RANGE_DAMAGE"] = true,
        ["ENVIRONMENTAL_DAMAGE"] = true,
}
local healEvents = {
        ["SPELL_HEAL"] = true,
        ["SPELL_PERIODIC_HEAL"] = true,
}

-- UNIT_DIED destGUID and destName refer to the unit that died.
jps.events.registerCombatLog("UNIT_DIED", function(...)
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
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local bitband = bit.band

-- TABLE ENEMIES IN COMBAT
-- http://wow.gamepedia.com/COMBAT_LOG_EVENT

jps.events.registerEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...)
	local event = select(2,...)
	local sourceGUID = select(4,...)
	local sourceFlags = select(6,...)
	local destGUID = select(8,...)
	local destFlags = select(10,...)

-- The numeric values of the global variables starts with 1 for MINE and increases toward OUTSIDER with 8
	local isSourceEnemy = bitband(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
	local isDestEnemy = bitband(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
	local isSourceFriend = bitband(sourceFlags,COMBATLOG_OBJECT_REACTION_FRIENDLY) == COMBATLOG_OBJECT_REACTION_FRIENDLY
	local isDestFriend = bitband(destFlags,COMBATLOG_OBJECT_REACTION_FRIENDLY) == COMBATLOG_OBJECT_REACTION_FRIENDLY
	
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

	if sourceGUID and destGUID then
		local sourceName = select(5,...) 
		local destName = select(9,...)

		-- Enemy Casting SpellControl according to table jps.SpellControl[spellID]
		if isSourceEnemy and destName == GetUnitName("player") then
			local suffix = event:match(".+(_.-)$")
			local spellID = select(12, ...)
			if jps.SpellControl[spellID] ~= nil then
				if jps.SpellControl[spellID] == "cc" and jps.checkTimer("SpellControl") < 2 then jps.createTimer("SpellControl",2)
				elseif jps.SpellControl[spellID] == "silence" and jps.checkTimer("SpellControl") < 2 then jps.createTimer("SpellControl",2) end
			end
		end

-- HEAL TABLE -- Average value of player healing spells
--		if sourceName == GetUnitName("player") then
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

-- HEAL TABLE -- Incoming Heal on Enemy from Enemy Healers UnitGUID
		if healEvents[event] then
--		print(  "cff1eff00Event: ",event)
--		print(  "|cff1eff00destName: |cffffffff",destName,"F:",isDestFriend,"E:",isDestEnemy,
--				"|cff1eff00sourceName: |cffffffff",sourceName,"F:",isSourceFriend,"E:",isSourceEnemy)
		
			if isDestEnemy and isSourceEnemy then
				local spellID = select(12, ...)
				local addEnemyHealer = false
				local classHealer = jps.HealerSpellID[spellID]
				if classHealer and UnitCanAttack("player",destName) then
					if EnemyHealer[sourceGUID] == nil then addEnemyHealer = true end
					if addEnemyHealer then EnemyHealer[sourceGUID] = {classHealer,sourceName} end
				end
			end

-- HEAL TABLE -- Incoming Heal on Friend
			if isDestFriend and UnitCanAssist("player",destName) then
				local heal = select(15,...)
				if IncomingHeal[destGUID] == nil then IncomingHeal[destGUID] = {} end
				tinsert(IncomingHeal[destGUID],1,{GetTime(),heal,destName})
			end
		end

-- DAMAGE TABLE Note that for the SWING prefix, _DAMAGE starts at the 12th parameter
		if damageEvents[event] then
--		print("|cFFFF0000Event: ",event)
--		print("|cFFFF0000destName: |cffffffff",destName,"F:",isDestFriend,"E:",isDestEnemy,
--				"|cFFFF0000sourceName: |cffffffff",sourceName,"F:",isSourceFriend,"E:",isSourceEnemy)
			if isDestFriend and UnitCanAssist("player",destName) then
				-- for the SWING prefix, _DAMAGE starts at the 12th parameter. 
				-- for ENVIRONMENTAL prefix, _DAMAGE starts at the 13th.
				local damage = 0
				local swingdmg = 0
				local spelldmg = 0
				local envdmg = 0
				if event == "SWING_DAMAGE" then
					local dmg = select(12, ...)
					if dmg == nil then dmg = 0 end
					swingdmg = dmg
				else
					local dmg = select(15, ...)
					if dmg == nil then dmg = 0 end
					spelldmg = dmg
				end
				if event == "ENVIRONMENTAL_DAMAGE" then
					local env = select(13, ...)
					if env == nil then env = 0 end
					envdmg = env
				end
				damage = swingdmg + spelldmg + envdmg

				-- Table of Incoming Damage on Friend
				if IncomingDamage[destGUID] == nil then IncomingDamage[destGUID] = {} end
				tinsert(IncomingDamage[destGUID],1,{GetTime(),damage,destName})
				-- Table of EnemyGuid doing damage on targeted FriendGuid
				if EnemyDamager[sourceGUID] == nil then EnemyDamager[sourceGUID] = {} end
				EnemyDamager[sourceGUID]["friendguid"] = destGUID 
				EnemyDamager[sourceGUID]["friendaggro"] = GetTime()
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

function jps.IncomingDamage(unit)
	if unit == nil then unit = "player" end
	local time = 4
	local unitguid = UnitGUID(unit)
	local totalDamage = 0
	if IncomingDamage[unitguid] ~= nil then
		local dataset = IncomingDamage[unitguid]
		if #dataset > 1 then
			local timeDelta = dataset[1][1] - dataset[#dataset][1] -- (lasttime - firsttime)
			local totalTime = math.max(timeDelta, 1)
			if time > totalTime then time = totalTime end
			for i=1,#dataset do
				if dataset[1][1] - dataset[i][1] <= time then
					totalDamage = totalDamage + dataset[i][2]
				end
			end
		end
	end
	return totalDamage
end

function jps.IncomingHeal(unit)
	if unit == nil then unit = "player" end
	local time = 4
	local unitguid = UnitGUID(unit)
	local totalHeal = 0
	if IncomingHeal[unitguid] ~= nil then
		local dataset = IncomingHeal[unitguid]
		if #dataset > 1 then
			local timeDelta = dataset[1][1] - dataset[#dataset][1] -- (lasttime - firsttime)
			local totalTime = math.max(timeDelta, 1)
			if time > totalTime then time = totalTime end
				for i=1,#dataset do
					if dataset[1][1] - dataset[i][1] <= time then
					totalHeal = totalHeal + dataset[i][2]
				end
			end
		end
	end
	return totalHeal
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
-- EnemyDamager[enemyGuid] = { ["friendguid"] = friendGuid , ["friendaggro"] = GetTime() }
jps.FriendAggro = function (unit)
	if unit == nil then unit = "player" end
	local unitGuid = UnitGUID(unit)
	for _,index in pairs(EnemyDamager) do
		if index.friendguid == unitGuid then return true end
	end
	return false
end

-- EnemyDamager[enemyGuid] = { ["friendguid"] = friendGuid , ["friendaggro"] = GetTime() }
jps.LookupEnemyDamager = function()
	if EnemyDamager == nil then print("EnemyDamager is Empty") end
	for unit,index in pairs(EnemyDamager) do
		print("|cffffffffEnemyGuid_|cFFFF0000: ",unit," |cffffffffFriendGuid_|cff1eff00: ",index.friendguid)
	end
end

-- EnemyHealer[enemyGuid] = {Class,sourceName}
jps.LookupEnemyHealer = function()
	if EnemyHealer == nil then print("EnemyHealer is Empty") end
	for _,index in pairs(EnemyHealer) do
		print("|cffffffffHealerClass:|cFFFF0000: ",index[1]," |cffffffffName:|cFFFF0000: ",index[2])
	end
end

jps.LookupIncomingDamage = function()
-- IncomingHeal[destGUID] = {GetTime(),heal,destName}
	for unit,index in pairs (IncomingHeal) do
		print(#index,"|cff1eff00unit:",unit,"destname:",index[1][3],"heal:",index[1][2])
	end
-- IncomingDamage[destGUID] = {GetTime(),damage,destName}
	for unit,index in pairs (IncomingDamage) do
		print(#index,"|cFFFF0000unit:",unit,"destname:",index[1][3],"damage:",index[1][2])
	end
end


------------------------------
-- SPELLTABLE -- contains the average value of healing spells
------------------------------

-- Resets the count of each healing spell to 1 makes sure that the average takes continuously into account changes in stats due to buffs etc
jps.ResetHealtable = function(self)
	for k,v in pairs(Healtable) do
		Healtable[k]["healtotal"] = Healtable[k]["averageheal"]
		Healtable[k]["healcount"] = 1
	end
end

-- Displays the different health values - mainly for tweaking/debugging
jps.PrintHealtable = function(self)
	for k,v in pairs(Healtable) do
		print(k,"|cffff8000", Healtable[k]["healtotal"]," ", Healtable[k]["healcount"]," ", Healtable[k]["averageheal"])
	end
end

-- Returns the average heal value of given spell.
jps.AverageHeal = function(spell)
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
 	if Healtable[spellname] == nil then
		return 0
 	else
		return (Healtable[spellname]["averageheal"])
 	end
end

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ANTI AFK ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

function deleteItem()
	local str = "Maquereau"
	for bag = 0,4,1 do
		for slot = 1, 32, 1 do
			local name = GetContainerItemLink(bag,slot)
			if name and string.find(name,str) ~= nil then
				PickupContainerItem(bag,slot)
				DeleteCursorItem()
			end
		end
	end
end

--local function antiAFK()
--	if not jps.Combat then
--		TurnLeftStart()
--		C_Timer.After(1,function() TurnLeftStop() end)
--	end
--end

--jps.registerOnUpdate(function()
--	local value = math.random(10,30)
--	jps.cachedValue(deleteItem,value)
--end)
