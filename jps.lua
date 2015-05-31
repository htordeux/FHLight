--[[
	 JPS - WoW Protected Lua DPS AddOn
	Copyright (C) 2011 Jp Ganis

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
	
	Huge thanks to everyone who's helped out on this.
]]--


local L = MyLocalizationTable
local IsHarmfulSpell = IsHarmfulSpell
local IsHelpfulSpell = IsHelpfulSpell
		
jps = {}

jps.Version = "1.5"
jps.Rotation = nil
jps.UpdateInterval = 0.075
jps.Enabled = false
jps.Combat = false
jps.Debug = false
jps.DebugMsg = false
jps.DebugLevel = 1
jps.PLuaFlag = false
jps.MoveToTarget = false
jps.FaceTarget = true

jps.Fishing = false
jps.MultiTarget = false
jps.Interrupts = false
jps.UseCDs = false
jps.PvP = false
jps.Defensive = false

-- Combat
jps.combatStart = 0
jps.IconSpell = nil
jps.Target = nil
jps.Casting = false
jps.ThisCast = nil
jps.Moving = false
jps.HarmSpell = ""
jps.HelpSpell = ""
jps.CurrentCast = nil
jps.CurrentCastInterrupt = nil
jps.CurrentCastInterruptID = nil
jps.SentCast = nil
jps.LastCast = nil
jps.LastTarget = nil
jps.Message = ""
jps.LastMessage = {}
jps.LastTargetGUID = nil
jps.Latency = 0
jps.NextSpell = nil
jps.GCD = 1
jps.startedFalling = 0

-- Class
jps.Class = nil
jps.Spec = nil
jps.Race = nil
jps.Level = 1
jps.isNotBehind = false
jps.isBehind = true
jps.isHealer = false
jps.DPSRacial = nil
jps.isTank = false

-- Tables
jps.Timers = {}
jps.TimedCasting = {}
jps.HealerBlacklist = {} 
jps.settings = {}
jps.settingsQueue = {}
jps.functionQueues = {}
jps.Minimap = {}

-- Config.
jps.initializedRotation = false
jps.Configged = false
jps_variablesLoaded = false
jpsName = select(1,UnitName("player"))
jpsRealm = GetRealmName()
jps.ExtraButtons = true
jps.ResetDB = false

-- Rotation
jps.Opening = true
jps.Count = 1
jps.Tooltip = ""
jps.ToggleRotationName = {"No Rotations"}
rotationDropdownHolder = nil

-- Local
local tinsert = table.insert
local GetSpellInfo = GetSpellInfo

-- Slash Cmd
SLASH_jps1 = '/jps'

function write(...)
   DEFAULT_CHAT_FRAME:AddMessage("|cffff8000JPS: " .. strjoin(" ", tostringall(...))); -- color orange
end
function macrowrite(...)
   DEFAULT_CHAT_FRAME:AddMessage("|cffff8000MACRO: " .. strjoin(" ", tostringall(...))); -- color orange
end

------------------------
-- DETECT CLASS SPEC
------------------------

function GetHarmfulSpell()
	local _, _, offset, numSpells, _ = GetSpellTabInfo(2)
	local booktype = "spell"
	local harm = 0
	local help = 0
	for index = offset+1, numSpells+offset do
		-- Get the Global Spell ID from the Player's spellbook
		local spell = select(1,GetSpellBookItemName(index, booktype))
		local spellID = select(2,GetSpellBookItemInfo(index, booktype))
		local minRange = select(5,GetSpellInfo(spellID))
		if minRange == nil then minRange = 8 end
		local maxRange = select(6,GetSpellInfo(spellID))
		if maxRange == nil then maxRange = 0 end
		local harmful = IsHarmfulSpell(index, booktype)
		local helpful = IsHelpfulSpell(index, booktype)
		if harmful and maxRange > 0 and minRange == 0 and jps.IsSpellKnown(spellID) then
			if maxRange > harm then
				harm = maxRange
				jps.HarmSpell = spell
			end
		elseif helpful and maxRange > 0 and minRange == 0 and jps.IsSpellKnown(spellID) then
			if maxRange > help then
				help = maxRange
				jps.HelpSpell = spell
			end
		end
	end
end

local getDPSRacial = function()
	-- Trolls n' Orcs
	if jps.DPSRacial ~= nil then return jps.DPSRacial end -- no more checks needed
	if jps.Race == nil then jps.Race = UnitRace("player") end
	if jps.Race == "Troll" then
		return "Berserking"
	elseif jps.Race == "Orc" then
		return "Blood Fury"
	end
	return nil
end

local setClassCooldowns = function()
	local options = {}
	jps.DPSRacial = getDPSRacial()
	if jps.DPSRacial then tinsert(options,"DPS Racial") end

	-- Add spells
	for i,spell in pairs(options) do
		if jpsDB[jpsRealm][jpsName][spell] == nil then
			jpsDB[jpsRealm][jpsName][spell] = true
			jps[spell] = true
		end
	end
end

function jps.detectSpec()

	jps.Count = 1
	jps.Tooltip = ""
	jps.ToggleRotationName = {"No Rotations"}
	rotationDropdownHolder:Hide()
	jps.initializedRotation = false
	jps.Race = UnitRace("player")
	jps.Class = UnitClass("player")
	jps.Level = Ternary(jps.Level > 1, jps.Level, UnitLevel("player"))

	if jps.Class then
		local id = GetSpecialization() -- remplace GetPrimaryTalentTree() patch 5.0.4
		if not id then
			if jps.Level < 10 then
				write("You need to be at least at level 10 and have a specialization to use JPS")
				jps.Enabled = false
			else
				write("jps couldn't find your talent tree... One second please.")
			end
		else
			-- local id, name, description, icon, background, role = GetSpecializationInfo(specIndex [, isInspect [, isPet]])
			local _,name,_,_,_,_ = GetSpecializationInfo(id)
			if name then
				jps.Spec = name
				if jps.Spec then
					write("Online for your",jps.Class,"-",jps.Spec)
				end
			end
		end
	end
	if jps.Spec == L["Discipline"] or jps.Spec == L["Holy"] or jps.Spec == L["Restoration"] or jps.Spec == L["Mistweaver"] then jps.isHealer = true end
	if jps.Spec == L["Blood"] or jps.Spec == L["Protection"] or jps.Spec == L["Brewmaster"] or jps.Spec == L["Guardian"] then jps.isTank = true end
	setClassCooldowns()
	jps_VARIABLES_LOADED()
	if jps.initializedRotation == false then
		jps.Cycle()
	end
end

------------------------
-- SLASHCMDLIST
------------------------

function SlashCmdList.jps(cmd, editbox)
	local msg, rest = cmd:match("^(%S*)%s*(.-)$");
	if msg == "toggle" or msg == "t" then
		if jps.Enabled == false then msg = "e"
		else msg = "d" end
	end
	if msg == "config" then
		InterfaceOptionsFrame_OpenToCategory(jpsConfigFrame)
	elseif msg == "show" then
		jpsIcon:Show()
		write("Icon set to show")
	elseif msg == "hide" then
		jpsIcon:Hide()
		write("Icon set to hide")
	elseif msg== "disable" or msg == "d" then
		jps.Enabled = false
		jps.gui_toggleEnabled(false)
		write("jps Disabled.")
	elseif msg== "enable" or msg == "e" then
		jps.Enabled = true
		jps.gui_toggleEnabled(true)
		write("jps Enabled.")
	elseif msg == "respec" then
		jps.detectSpec()
	elseif msg == "multi" or msg == "aoe" then
		jps.gui_toggleMulti()
	elseif msg == "cds" then
		jps.gui_toggleCDs()
	elseif msg == "int" then
		jps.gui_toggleInt()
	elseif msg == "pvp" then
		jps.togglePvP()
		write("PvP mode is now set to",tostring(jps.PvP))
	elseif msg == "def" then
		jps.gui_toggleDef()
		write("Defensive set to",tostring(jps.Defensive))
	elseif msg == "heal" then
		jps.isHealer = not jps.isHealer
		write("Healing set to", tostring(jps.isHealer))
	elseif msg == "opening" then
		jps.Opening = not jps.Opening
		write("Opening flag set to",tostring(jps.Opening))
	elseif msg == "fishing" or msg == "fish" then
		jps.Fishing = not jps.Fishing
		write("Murglesnout & Grey Deletion now", tostring(jps.Fishing))
	elseif msg == "debug" and rest ~="" then
		if tonumber(rest) then
			jps.DebugLevel = rest
			write("Debug level set to",tostring(rest))
		else
			jps.DebugLevel = 1
			write("Debug level set to 1")
		end
	elseif msg == "debug" then
		jps.Debug = not jps.Debug
		write("Debug mode set to",tostring(jps.Debug))
	elseif msg == "msg" then
		jps.DebugMsg = not jps.DebugMsg
		write("DebugMsg mode set to",tostring(jps.DebugMsg))
	elseif msg == "face" then
		jps.gui_toggleRot()
		write("jps.FaceTarget set to",tostring(jps.FaceTarget))
	elseif msg == "db" then
		jps.ResetDB = not jps.ResetDB
		jps_VARIABLES_LOADED()
		write("jps.ResetDB set to",tostring(jps.ResetDB))
		jps.Macro("/reload")
	elseif msg == "ver" or msg == "v" then
		write("You have JPS version: "..jps.Version)
	elseif msg == "size" then
		jps.resize( rest )
	elseif msg == "reset" then
		jps.resetView()
	elseif msg == "help" then
		write("Slash Commands:")
		write("/jps - Show enabled status.")
		write("/jps enable/disable - Enable/Disable the addon.")
		write("/jps spam - Toggle spamming of a given macro.")
		write("/jps cds - Toggle use of cooldowns.")
		write("/jps pew - Spammable macro to do your best moves, if for some reason you don't want it fully automated")
		write("/jps interrupts - Toggle interrupting")
		write("/jps reset - reset position of jps icons and UI")
		write("/jps db - cleares your local jps DB")
		write("/jps help - Show this help text.")
	elseif msg == "pew" then
	  	jps.Cycle()
	elseif msg == "harm" then
	  	write("|cFFFF0000HarmfulSpell "..jps.HarmSpell)
	  	write("|cff1eff00HelpfulSpell "..jps.HelpSpell)
	else
		if jps.Enabled then
			print("jps Enabled - Ready and Waiting.")
		else
			print "jps Disabled - Waiting on Standby."
		end
	end
end

----------------------
-- USE ACTION
----------------------

-- cache for WoW API functions that return always the same results for the given params
local spellcache = setmetatable({}, {__index=function(t,v) local a = {GetSpellInfo(v)} if GetSpellInfo(v) then t[v] = a end return a end})
local function GetSpellInfo(a)
	return unpack(spellcache[a])
end

-- set's jps.NextSpell if user manually uses a spell/item
-- name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellId or spellName)
hooksecurefunc("UseAction", function(...)
	if jps.Enabled and (select(3, ...) ~= nil) and InCombatLockdown() == true then
		local stype,id,_ = GetActionInfo(select(1, ...))
		if stype == "spell" then
			local name, _, icon, _, _, _, _ = GetSpellInfo(id)
			if string.find(string.lower(icon),"spell") ~= nil then
				if jps.NextSpell ~= name and not jps.shouldSpellBeIgnored(name) then
					jps.NextSpell = name
					write("Set",name,"for next cast.")
				end
			end
		end
	end
end)

----------------------
-- COMBAT
----------------------
local GetTime = GetTime
local GetUnitSpeed = GetUnitSpeed
local GetSpellCooldown = GetSpellCooldown

function jps.Cycle()
	-- Check for the Rotation
	if not jps.Class then return end
	if not jps.activeRotation() then
		write("JPS does not have a rotation for your",jps.Spec,jps.Class)
		jps.Enabled = false
		return
	end
	
	-- CASTING
	if jps.ChannelTimeLeft("player") > 0 then jps.Casting = true
	elseif jps.CastTimeLeft("player") - jps.Latency > 0 then jps.Casting = true
	else jps.Casting = false end

	-- STOP Combat
	if (IsMounted() == true and jps.getConfigVal("dismount in combat") == false) or UnitIsDeadOrGhost("player") == true or jps.buff(L["Drink"],"player") then return end
	
	-- GCD -- if too small value we can't get spellstopcasting
	local cdStart,duration,_ = GetSpellCooldown(61304)
	local timeLeft = 0
	if cdStart > 0 then timeLeft = duration - (GetTime() - cdStart ) end
	if jps.getConfigVal("gcd activation") and timeLeft > 0.5 then return end
	
	-- Movement
	jps.Moving = select(1,GetUnitSpeed("player")) > 0
	if IsFalling() and jps.startedFalling == 0 then jps.startedFalling = GetTime() end
	if not IsFalling() and jps.startedFalling > 0 then jps.startedFalling = 0 end

	-- Check spell usability -- ALLOW SPELLSTOPCASTING() IN JPS.ROTATION() TABLE
	jps.ThisCast,jps.Target = jps.activeRotation().getSpell()

	if not jps.Casting and jps.ThisCast ~= nil then
		if jps.NextSpell ~= nil then
			if jps.NextSpell ~= jps.SentCast then
				jps.Cast(jps.NextSpell,jps.Target)
			else
				write("|cFFFF0000Next Spell "..jps.NextSpell.. " was casted")
				jps.NextSpell = nil
				jps.Cast(jps.ThisCast)
			end
			if jps.cooldown(jps.NextSpell) > 1 then jps.NextSpell = nil end
		else
			jps.Cast(jps.ThisCast)
		end
	end

	-- Return spellcast.
	return jps.ThisCast,jps.Target
end

-----------------------
-- FUNCTIONQUEUE
-----------------------

function jps.addTofunctionQueue(fn,queueName) 
	if not jps.functionQueues[queueName] then
		jps.functionQueues[queueName] = {}
	end
	if not jps.functionQueues[queueName][fn] then
		jps.functionQueues[queueName][fn] = fn
	end
end

function jps.deleteFunctionFromQueue(fn, queueName)
	if jps.functionQueues[queueName] ~= nil then
		if jps.functionQueues[queueName][fn] ~= nil then
			jps.functionQueues[queueName][fn] = nil
		end
	end
end

function jps.runFunctionQueue(queueName)
	local noErrors = true
	if jps.functionQueues[queueName] then
		for _,fn in pairs(jps.functionQueues[queueName]) do
			local status, error = pcall(fn)
			if not status then
				noError = false

			end
			jps.functionQueues[queueName][fn] = nil
		end
		if noErrors then
			jps.functionQueues[queueName] = nil
			return true
		end
	end	
	return false
end