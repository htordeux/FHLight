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

jps.spells = {}
jps.Version = "1.5"
jps.UpdateInterval = 0.1
jps.Enabled = false
jps.Combat = false
jps.Debug = false
jps.DebugLevel = 1

jps.FaceTarget = true
jps.MultiTarget = false
jps.Interrupts = false
jps.UseCDs = false
jps.PvP = false
jps.Defensive = false
jps.ExtraButtons = true

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
jps.SentCast = nil
jps.LastCast = nil
jps.LastTarget = nil
jps.Message = ""
jps.LastMessage = ""
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
jps.isHealer = false

-- Tables
jps.Timers = {}
jps.TimedCasting = {}
jps.HealerBlacklist = {} 

-- Config.
jps.initializedRotation = false
jps_variablesLoaded = false
jpsName = select(1,UnitName("player"))
jpsRealm = GetRealmName()

jps.ResetDB = false

-- Rotation
jps.Tooltip = ""

-- Local
local tinsert = table.insert
local GetSpellInfo = GetSpellInfo

-- Slash Cmd
SLASH_jps1 = '/jps'

function write(...)
   DEFAULT_CHAT_FRAME:AddMessage("|cffff8000JPS: " .. strjoin(" ", tostringall(...))); -- color orange
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
	if msg == "show" then
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
	elseif msg == "spec" then
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
	elseif msg == "debug" then
		jps.Debug = not jps.Debug
		write("Debug mode set to",tostring(jps.Debug))
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
	elseif msg == "help" then
		write("Slash Commands:")
		write("/jps - Show enabled status.")
		write("/jps enable/disable - Enable/Disable the addon.")
		write("/jps spam - Toggle spamming of a given macro.")
		write("/jps cds - Toggle use of cooldowns.")
		write("/jps pew - Spammable macro to do your best moves, if for some reason you don't want it fully automated")
		write("/jps interrupts - Toggle interrupting")
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

------------------------
-- DETECT CLASS SPEC
------------------------

function jps.detectSpec()
	jps.initializedRotation = false
	jps.Race = UnitRace("player")
	jps.Class = UnitClass("player")
	jps.Level = Ternary(jps.Level > 1, jps.Level, UnitLevel("player"))

	if jps.Class then
		local specIndex = GetSpecialization() -- remplace GetPrimaryTalentTree() patch 5.0.4
		if not specIndex then
			if jps.Level < 10 then
				write("You need to be at least at level 10 and have a specialization to use JPS")
				jps.Enabled = false
			else
				write("JPS couldn't find your talent tree")
			end
		else
			local id, name, _, _, _, role, _ = GetSpecializationInfo(specIndex)
			if name then
				jps.Spec = name
				if jps.Spec then
					write("Online for your",jps.Class,"-",jps.Spec)
				end
				if role == "HEALER" then -- "DAMAGER", "TANK", "HEALER"
					jps.isHealer = true
				else
					jps.isHealer = false
				end
			end
		end
	end
	jps_VARIABLES_LOADED()
end

jps.GetHarmfulSpell = function ()
	local _, _, offset, numSpells, _ = GetSpellTabInfo(2)
	local harmdist = 0
	local helpdist = 0
	for index = offset+1, numSpells+offset do
		-- Get the Global Spell ID from the Player's spellbook
		local spell = select(1,GetSpellBookItemName(index, "spell"))
		local spellID = select(2,GetSpellBookItemInfo(index, "spell"))
		local minRange = select(5,GetSpellInfo(spellID))
		if minRange == nil then minRange = 8 end
		local maxRange = select(6,GetSpellInfo(spellID))
		if maxRange == nil then maxRange = 0 end
		local harmful = IsHarmfulSpell(spell)
		local helpful = IsHelpfulSpell(spell)
		if harmful and maxRange > 0 and minRange == 0 and jps.IsSpellKnown(spellID) then
			if maxRange > harmdist then
				harmdist = maxRange
				jps.HarmSpell = spell
			end
		elseif helpful and maxRange > 0 and minRange == 0 and jps.IsSpellKnown(spellID) then
			if maxRange > helpdist then
				helpdist = maxRange
				jps.HelpSpell = spell
			end
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

-- jps.NextSpell if user manually uses a spell/item
hooksecurefunc("UseAction", function(...)
	if jps.Enabled and (select(3, ...) ~= nil) and InCombatLockdown() == true then
		local stype,id,_ = GetActionInfo(select(1, ...))
		if stype == "spell" then
			local spell = GetSpellInfo(id)
			if jps.NextSpell ~= spell then
				jps.NextSpell = spell
				write("Set",spell,"for next cast.")
			end
		end
--		if stype == "macro" then
--            local macroText = select(3, GetMacroInfo(id))
--            if string.find(macroText,"jps") == nil then
--                jps.NextMacro = macroText
--            end
--        end
	end
end)

----------------------
-- COMBAT
----------------------
--inLockdown = InCombatLockdown()
--Returns true if lockdown restrictions are currently in effect, false otherwise.
--Combat lockdown begins after the PLAYER_REGEN_DISABLED event fires, and ends before the PLAYER_REGEN_ENABLED event fires.
--affectingCombat = UnitAffectingCombat("unit");
--The UnitId of the unit to check ("player", "pet", "party1", hostile "target")
--Returns true if the unit is in combat or has aggro, false otherwise.


local GetTime = GetTime
local GetUnitSpeed = GetUnitSpeed
local GetSpellCooldown = GetSpellCooldown

jps.castSequence = nil
local castSequenceIndex = 1
local castSequenceTarget = nil
local castSequenceStartTime = 0

function jps.Cycle()
	-- Check for the Rotation
	if not jps.Class then return end
	if not jps.getActiveRotation() then
		write("JPS does not have a rotation for your",jps.Spec,jps.Class)
		jps.Enabled = false
		return
	end
	
	-- CASTING
	if jps.ChannelTimeLeft("player") > 0 then jps.Casting = true
	elseif jps.CastTimeLeft("player") - jps.Latency > 0 then jps.Casting = true
	else jps.Casting = false end

	-- STOP Combat
	if IsMounted() then return end
	if jps.buff(L["Drink"],"player") then return end
	if UnitIsDeadOrGhost("player") then return end
	
	-- GCD -- if too small value we can't get spellstopcasting
	-- To check the Global Cooldown, you can use the spell ID 61304. This is a dummy spell specifically for the GCD

	-- Movement
	jps.Moving = select(1,GetUnitSpeed("player")) > 0
	if IsFalling() and jps.startedFalling == 0 then jps.startedFalling = GetTime() end
	if not IsFalling() and jps.startedFalling > 0 then jps.startedFalling = 0 end

    if jps.castSequence ~= nil then
        if jps.castSequence[castSequenceIndex] ~= nil then
        	local spell = jps.castSequence[castSequenceIndex]
            if jps.canCast(spell,castSequenceTarget) and not jps.Casting then
                jps.Cast(spell)
                write("|cFFFF0000Sequence Spell "..spell.. " was casted")
                castSequenceIndex = castSequenceIndex + 1
            end
        else
            jps.castSequence = nil
        end
	else
		local activeRotation = jps.getActiveRotation()
		jps.ThisCast,jps.Target = activeRotation.getSpell()
		if jps.ThisCast ~= nil and not jps.Casting then
			if jps.NextSpell ~= nil then
				if jps.NextSpell ~= jps.SentCast and jps.canCast(jps.NextSpell,jps.Target) then
					jps.Cast(jps.NextSpell)
					write("|cFFFF0000Next Spell "..jps.NextSpell.. " was casted")
					jps.NextSpell = nil
				else
					jps.Cast(jps.ThisCast)
				end
				if jps.cooldown(jps.NextSpell) > 3 then jps.NextSpell = nil end
			else
				jps.Cast(jps.ThisCast)
			end
			castSequenceIndex = 1
			castSequenceStartTime = GetTime()
			castSequenceTarget = jps.LastTarget
		end
	end
end

----------------------------
-- FUNCTION TO SPELLNAME
----------------------------

--Pre-6.0:
-- name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId or spellName)
--6.0:
-- name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellId or spellName)
-- Using spellName or spellLink will only return the info if the spell is in your spellbook. Otherwise it will return nil.

jps.toSpellName = function(spell)
	local spellname = nil
	if type(spell) == "string" then spellname = spell
	elseif type(spell) == "number" then spellname = GetSpellInfo(spell) end
	return spellname
end