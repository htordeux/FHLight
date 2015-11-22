--------------------------
-- LOCALIZATION
--------------------------

local L = MyLocalizationTable
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetSpellInfo = GetSpellInfo
local toSpellName = jps.toSpellName 

--------------------------
-- BUFF DEBUFF
--------------------------
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitDebuff("unit", index or ["name", "rank"][, "filter"])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitBuff("unit", index or "name"[, "rank"[, "filter"]])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, ... = UnitAura("unit", index or "name"[, "rank"[, "filter"]])
-- spellId of the spell or effect that applied the aura

function jps.buffId(spellId,unit)
	local spellname = toSpellName(spellId)
--	if type(spellId) == "number" then spellname = GetSpellInfo(spellId) end
--	if spellname == nil then return false end
	if spellname == nil then return false end
	if unit == nil then unit = "player" end
	local auraName, _, _, count, _, duration, expirationTime, castBy, _, _, buffId
	local i = 1
	auraName, _, _, count, _, duration, expirationTime, castBy, _, _, buffId = UnitBuff(unit, i)
	while auraName do
		if spellId == buffId and auraName == spellname then return true end
		i = i + 1
		auraName, _, _, count, _, duration, expirationTime, castBy, _, _, buffId = UnitBuff(unit, i)
	end
	return false
end

function jps.buff(spell,unit)
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return false end
	if unit == nil then unit = "player" end
	if select(1,UnitBuff(unit,spellname)) then return true end
	return false
end

function jps.debuff(spell,unit)
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return false end
	if unit == nil then unit = "target" end
	if select(1,UnitDebuff(unit,spellname)) then return true end
	return false
end

function jps.myDebuff(spell,unit)
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return false end
	if unit == nil then unit = "target" end
	if select(1,UnitDebuff(unit,spellname)) and select(8,UnitDebuff(unit,spellname))=="player" then return true end
	return false
end

function jps.myBuffDuration(spell,unit)
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return 0 end
	if unit == nil then unit = "player" end
	local _,_,_,_,_,_,duration,caster,_,_,_ = UnitBuff(unit,spellname)
	if caster ~= "player" then return 0 end
	if duration == nil then return 0 end
	duration = duration-GetTime() 
	if duration < 0 then return 0 end
	return duration
end

function jps.myDebuffDuration(spell,unit) 
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return 0 end
	if unit == nil then unit = "target" end
	local _,_,_,_,_,_,duration,caster,_,_ = UnitDebuff(unit,spellname)
	if caster~="player" then return 0 end
	if duration==nil then return 0 end
	duration = duration-GetTime() 
	if duration < 0 then return 0 end
	return duration
end

function jps.buffDuration(spell,unit)
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return 0 end
	if unit == nil then unit = "player" end
	local _,_,_,_,_,_,duration,caster,_,_,_ = UnitBuff(unit,spellname)
	if duration == nil then return 0 end
	duration = duration-GetTime() 
	if duration < 0 then return 0 end
	return duration
end

function jps.debuffDuration(spell,unit) 
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return 0 end
	if unit == nil then unit = "target" end
	local _,_,_,_,_,_,duration,caster,_,_ = UnitDebuff(unit,spellname)
	if duration==nil then return 0 end
	duration = duration-GetTime() 
	if duration < 0 then return 0 end
	return duration
end

function jps.debuffStacks(spell,unit)
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return 0 end
	if unit == nil then unit = "target" end
	local _,_,_,count, _,_,_,_,_,_ = UnitDebuff(unit,spellname)
	if count == nil then count = 0 end
	return count
end

function jps.buffStacks(spell,unit)
	local spellname = toSpellName(spell)
--	if type(spell) == "string" then spellname = spell end
--	if type(spell) == "number" then spellname = GetSpellInfo(spell) end
	if spellname == nil then return 0 end
	if unit == nil then unit = "player" end
	local _, _, _, count, _, _, _, _, _ = UnitBuff(unit,spellname)
	if count == nil then count = 0 end
	return count
end

-- check if a unit has at least one buff from a buff table (first param)
function jps.buffLooper(tableName, unit)
	for _, buffName in pairs(tableName) do
		if jps.buff(buffName, unit) then
			return true
		end
	end
	return false
end

function jps.bloodlusting()
	return jps.buff("bloodlust") or jps.buff("heroism") or jps.buff("time warp") or jps.buff("ancient hysteria") or jps.buff("Drums of Rage") -- drums coming with 5.4
end

-- all raid buffs + types
local raidBuffs = {
	["Power Word: Fortitude"] = "stamina",
	["Commanding Shout"] = "stamina",
	["Qiraji Fortitude"] = "stamina",
	["Dark Intent"] = "stamina",
	["Mark of the Wild"] = "stats",
	["Legacy of the Emperor"] = "stats",
	["Blessing of Kings"] = "stats",
	["Embrace of the Shale Spider"] = "stats",
	["Horn of Winter"] = "attackPower",
	["Trueshot Aura"] = "attackPower",
	["Battle Shout"] = "attackPower",
	["Unholy Aura"] = "haste",
	["Swiftblade's Cunning"] = "haste",
	["Unleashed Rage"] = "haste",
	["Cackling Howl"] = "haste",
	["Serpent's Swiftness"] = "haste",
	["Moonkin Aura"] = "spellHaste",
	["Elemental Oath"] = "spellHaste",
	["Mind Quickening"] = "spellHaste",
	["Energizing Spores"] = "spellHaste",
	["Arcane Brilliance"] = "crit",
	["Dalaran Brilliance"] = "crit",
	["Leader of the Pack"] = "crit",
	["Legacy of the White Tiger"] = "crit",
	["Fearless Roar"] = "crit",
	["Still Water"] = "crit",
	["Terrifying Roar"] = "crit",
	["Furious Howl"] = "crit",
	["Arcane Brilliance"] = "spellPower",
	["Dalaran Brilliance"] = "spellPower",
	["Burning Wrath"] = "spellPower",
	["Dark Intent"] = "spellPower",
	["Still Water"] = "spellPower",
	["Blessing of Might"] = "mastery",
	["Grace of Air"] = "mastery",
	["Roar of Courage"] = "mastery",
	["Spirit Beast Blessing"] = "mastery"
}


-- functions for raid buffs
local staminaBuffs = {"Power Word: Fortitude", "Commanding Shout", "Qiraji Fortitude"}
function jps.hasStaminaBuff(unit)
	return jps.buffLooper(staminaBuffs, unit)
end

local statsBuffs = {"Mark of the Wild", "Legacy of the Emperor", "Blessing of Kings", "Embrace of the Shale Spider"}
function jps.hasStatsBuff(unit)
	return jps.buffLooper(statsBuffs, unit)
end

local attackPowerBuffs = {"Cor de l’hiver","Aura de précision","Cri de guerre","Horn of Winter", "Trueshot Aura", "Battle Shout"}
function jps.hasAttackPowerBuff(unit)
	return jps.buffLooper(attackPowerBuffs, unit)
end

local hasteBuffs = {"Unholy Aura", "Swiftblade's Cunning", "Unleashed Rage","Cackling Howl","Serpent's Swiftness"}
function jps.hasHasteBuff(unit)
	return jps.buffLooper(hasteBuffs, unit)
end

local spellHasteBuffs = {"Moonkin Aura", "Elemental Oath", "Mind Quickening","Energizing Spores"}
function jps.hasSpellHasteBuff(unit)
	return jps.buffLooper(spellHasteBuffs, unit)
end

local critBuffs = {"Arcane Brilliance", "Dalaran Brilliance", "Leader of the Pack","Legacy of the White Tiger","Fearless Roar","Still Water","Terrifying Roar","Furious Howl"}
function jps.hasCritBuff(unit)
	return jps.buffLooper(critBuffs, unit)
end

local spellPowerBuffs = {"Arcane Brilliance", "Dalaran Brilliance", "Burning Wrath", "Dark Intent", "Still Water"}
function jps.hasSpellPowerBuff(unit)
	return jps.buffLooper(spellPowerBuffs, unit)
end

local masteryBuffs = {"Blessing of Might","Grace of Air","Roar of Courage","Spirit Beast Blessing"}
function jps.hasMasteryBuff(unit)
	return jps.buffLooper(masteryBuffs, unit)
end

function jps.hasSpellPowerCritBuff(unit)
	return jps.hasCritBuff(unit) and jps.hasSpellPowerBuff(unit)
end

local multistrikeBuffs = {"Dark Intent"}
function jps.hasMultistrikeBuff(unit)
	return jps.buffLooper(multistrikeBuffs, unit)
end

-- type of raid buffs to functions
jps.raidBuffFunctions = { 
	["stamina"] = jps.hasStaminaBuff,
	["stats"] = jps.hasStatsBuff,
	["attackPower"] = jps.hasAttackPowerBuff,
	["haste"] = jps.hasHasteBuff,
	["spellHaste"] = jps.hasSpellHasteBuff,
	["crit"] = jps.hasCritBuff,
	["spellPower"] = jps.hasSpellPowerBuff,
	["mastery"] = jps.hasMasteryBuff,
	["multistrike"] = jps.hasMultistrikeBuff
}

-- checks wheter a unit have a similarbuff ( e.G. arcane brilliance = still water)
function jps.hasSimilarBuff(buffName, unit)
	local buffType = Ternary(raidBuffs[buffName] ~= nil, raidBuffs[buffname], nil)
	if buffType ~= nil then
		if jps.raidBuffFunctions[buffType] ~= nil then
			return pcall(jps.raidBuffFunctions[buffType], unit)
		end
	end
	return false
end

---------------------------------------------
-- BOSS DEBUFF
---------------------------------------------

function CreateFlasher()

	local flasher = CreateFrame("Frame", "WarningFrame", UIParent)
	flasher:SetToplevel(true)
	flasher:SetFrameStrata("BACKGROUND") -- "FULLSCREEN_DIALOG"
	flasher:SetAllPoints(UIParent)
	flasher.texture = flasher:CreateTexture(nil, "BACKGROUND")
	flasher:SetAlpha(0.1)
	flasher.texture:SetTexture("Interface\\FullScreenTextures\\LowHealth") -- "Interface\\FullScreenTextures\\OutofControl"
	flasher.texture:SetAllPoints(UIParent)
	flasher.texture:SetBlendMode("ADD")
	flasher:Show()

 	flasher:SetScript("OnUpdate", function(self, elapsed)
		if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
		if self.TimeSinceLastUpdate > 1 then
			flasher:Hide()
			self.TimeSinceLastUpdate = 0
		end
	end)
	
 end
 
function CreateMessage(message)

	local msg = CreateFrame("MessageFrame", nil, UIParent)
	msg:SetPoint("LEFT", UIParent)
	msg:SetPoint("RIGHT", UIParent)
	msg:SetPoint("TOP", 0, -700) -- set vertical position here
	msg:SetHeight(25)
	msg:SetInsertMode("TOP")
	msg:SetFrameStrata("HIGH")
	msg:SetTimeVisible(1)
	msg:SetFadeDuration(2)
	msg:SetFont(STANDARD_TEXT_FONT, 25, "OUTLINE")
	msg:AddMessage(message,1,0,0,1)

end