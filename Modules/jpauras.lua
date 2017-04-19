--------------------------
-- LOCALIZATION
--------------------------

local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetSpellInfo = GetSpellInfo
local toSpellName = jps.toSpellName 

--------------------------
-- BUFF DEBUFF
--------------------------
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, nameplateShowAll, timeMod, value1, value2, value3 = UnitDebuff("unit", index or ["name", "rank"][, "filter"])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, nameplateShowAll, timeMod, value1, value2, value3 = UnitBuff("unit", index or "name"[, "rank"[, "filter"]])
-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod,value1, value2, value3 = UnitAura("unit", index or "name"[, "rank"[, "filter"]])


function jps.BossDebuff(unit)
	if unit == nil then unit = "player" end
	local auraName, debuffType, expTime, unitCaster, spellID, isBossDebuff
	local i = 1
	auraName, _, _, _, debuffType, _, expTime, unitCaster, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, i)
	while auraName do
		local classCaster = UnitClassification(unitCaster)
		if string.find(classCaster,"boss") ~= nil then return true end
		if string.find(classCaster,"elite") ~= nil then return true end
		i = i + 1
		auraName, _, _, _, debuffType, _, expirationTime, unitCaster, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, i)
	end
	return false
end

function jps.buff(spell,unit)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if unit == nil then unit = "player" end
	if select(1,UnitBuff(unit,spellname)) then return true end
	return false
end

function jps.debuff(spell,unit)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if unit == nil then unit = "target" end
	if select(1,UnitDebuff(unit,spellname)) then return true end
	return false
end

function jps.myDebuff(spell,unit)
	local spellname = toSpellName(spell)
	if spellname == nil then return false end
	if unit == nil then unit = "target" end
	if select(1,UnitDebuff(unit,spellname)) and select(8,UnitDebuff(unit,spellname))=="player" then return true end
	return false
end

function jps.myBuffDuration(spell,unit)
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
	if unit == nil then unit = "player" end
	local auraName, _, _, count, _, duration, expirationTime, caster, _, _, _ = UnitDebuff(unit,spellname)
	if caster ~= "player" then return 0 end
	if expirationTime == nil then return 0 end
	local timeLeft = expirationTime - GetTime() 
	if timeLeft < 0 then return 0 end
	return timeLeft
end

function jps.myDebuffDuration(spell,unit) 
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
	if unit == nil then unit = "target" end
	local auraName, _, _, count, _, duration, expirationTime, caster, _, _, _ = UnitDebuff(unit,spellname)
	if caster ~= "player" then return 0 end
	if expirationTime == nil then return 0 end
	local timeLeft = expirationTime - GetTime() 
	if timeLeft < 0 then return 0 end
	return timeLeft
end

function jps.buffDuration(spell,unit)
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
	if unit == nil then unit = "player" end
	local auraName, _, _, count, _, duration, expirationTime, caster, _, _, _ = UnitBuff(unit,spellname)
	if expirationTime == nil then return 0 end
	local timeLeft = expirationTime - GetTime() 
	if timeLeft < 0 then return 0 end
	return timeLeft
end

function jps.debuffDuration(spell,unit) 
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
	if unit == nil then unit = "target" end
	local auraName, _, _, count, _, duration, expirationTime, caster, _, _, _ = UnitDebuff(unit,spellname)
	if expirationTime == nil then return 0 end
	local timeLeft = expirationTime - GetTime() 
	if timeLeft < 0 then return 0 end
	return timeLeft
end

function jps.debuffStacks(spell,unit)
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
	if unit == nil then unit = "target" end
	local _,_,_,count, _,_,_,_,_,_ = UnitDebuff(unit,spellname)
	if count == nil then count = 0 end
	return count
end

function jps.buffStacks(spell,unit)
	local spellname = toSpellName(spell)
	if spellname == nil then return 0 end
	if unit == nil then unit = "player" end
	local _, _, _, count, _, _, _, _, _ = UnitBuff(unit,spellname)
	if count == nil then count = 0 end
	return count
end

function jps.buffValue(spell,unit)
	if unit == nil then unit = "player" end
	local value = 0
	if jps.buffDuration(spell) > 0 then
		local buffname = jps.toSpellName(spell)
		value = select(17,UnitBuff(unit,buffname))
	end
	return value
end

---------------------------------------------
-- BOSS DEBUFF
---------------------------------------------

-- check if a unit has at least one buff from a buff table (first param)
function jps.buffLooper(tableName, unit)
	for _, buffName in pairs(tableName) do
		if jps.buff(buffName, unit) then
			return true
		end
	end
	return false
end

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