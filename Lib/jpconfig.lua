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
]]--
---------------------------
-- Parent FRAME
---------------------------

function jps.redColor(str)
	return "|cFFFF0000"..str.."|r"
end

local rotationButtonPositionY = -90; 
local rotationButtonPositionX = 20; 
local jpsRotationFrame = nil; 
local rotationCount = 0

local rotationCountSetting = 0
local settingsButtonPositionY = -90;
local settingsButtonPositionX = 20;

function jps.createConfigFrame()

	jpsConfigFrame = CreateFrame("Frame", "jpsConfigFrame", UIParent)
	jpsConfigFrame.name = "JPS Options Panel"
	local title = jpsConfigFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 20, -10) 
	title:SetText("JPS")
	local subtitle = jpsConfigFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", jpsConfigFrame, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText("Configuration options for JPS")

	-- <3 to Juked
	-- Create checkboxes
	local buttonPositionY = -60;
	local buttonPositionX = 40;

	local t = {1,2,3,4,5,6,7,8,9}
	for var,value in pairs(jpsDB[jpsRealm][jpsName]) do
		if type(jpsDB[jpsRealm][jpsName][var]) == "boolean" then
			if var == "Enabled" then t[1] = var
			elseif var == "FaceTarget" then t[2] = var
			elseif var == "MoveToTarget" then t[3] = var
			elseif var == "UseCDs" then t[4] = var
			elseif var == "MultiTarget" then t[5] = var
			elseif var == "Interrupts" then t[6] = var
			elseif var == "Defensive" then t[7] = var
			elseif var == "PvP" then t[8] = var
			elseif var == "ExtraButtons" then t[9] = var
			else table.insert(t,var)
			end
		end
	end

	for i,v in ipairs (t) do
		local JPS_IconOptions_CheckButton = CreateFrame("CheckButton", "JPS_Button_"..v, jpsConfigFrame, "OptionsCheckButtonTemplate");
		JPS_IconOptions_CheckButton:SetPoint("TOPLEFT",buttonPositionX,buttonPositionY);
		getglobal(JPS_IconOptions_CheckButton:GetName().."Text"):SetText(v);

		local function JPS_IconOptions_CheckButton_OnClick()
			if v == "PvP" then jps.togglePvP()
			else jps[v] = not jps[v] end
			jps_SAVE_PROFILE()
			jps_LOAD_PROFILE()
		end

		local function JPS_IconOptions_CheckButton_OnShow()
			jps_SAVE_PROFILE()
			JPS_IconOptions_CheckButton:SetChecked(jpsDB[jpsRealm][jpsName][v]);
		end

		JPS_IconOptions_CheckButton:RegisterForClicks("AnyUp");
		JPS_IconOptions_CheckButton:SetScript("OnClick", JPS_IconOptions_CheckButton_OnClick);
		JPS_IconOptions_CheckButton:SetScript("OnShow", JPS_IconOptions_CheckButton_OnShow);
		if i == 9 then buttonPositionY = buttonPositionY - 30 end
		buttonPositionY = buttonPositionY - 30;
	end

	-- HIDE AT LOAD
	InterfaceOptions_AddCategory(jpsConfigFrame)
	jps.Configged = true
	jpsConfigFrame:Hide()
	
	-- DROPDOWN ROTATION
	--jps.addRotationDropdownFrame()
	jps.addSettingsFrame()
	jps.addUIFrame()
	
end

---------------------------------
-- DROPDOWN ROTATIONS
---------------------------------

rotationDropdownHolder = CreateFrame("frame","rotationDropdownHolder")
rotationDropdownHolder:SetWidth(150)
rotationDropdownHolder:SetHeight(60)
rotationDropdownHolder:SetPoint("CENTER",UIParent)
rotationDropdownHolder:EnableMouse(true)
rotationDropdownHolder:SetMovable(true)
rotationDropdownHolder:RegisterForDrag("LeftButton")
rotationDropdownHolder:SetScript("OnDragStart", function(self) self:StartMoving() end)
rotationDropdownHolder:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

DropDownRotationGUI = CreateFrame("FRAME", "JPS Rotation GUI", rotationDropdownHolder, "UIDropDownMenuTemplate")
DropDownRotationGUI:ClearAllPoints()
DropDownRotationGUI:SetPoint("CENTER",10,10)
local title = DropDownRotationGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", 20, 10) 
title:SetText("JPS ROTATIONS")	

function GUIRotation_OnClick(self)
   UIDropDownMenu_SetSelectedID(DropDownRotationGUI, self:GetID())
   jps.Count = self:GetID() -- HERE we get the jps.Count in the DropDownRotation
   jps.setActiveRotation(self:GetID())
   write("Changed your active Rotation to: "..jps.ToggleRotationName[jps.Count])
end

local menuListGUI = {}
function GUIDropDown_Initialize(self, level)
	table.wipe(menuListGUI)
	for _,rotname in pairs(jps.ToggleRotationName) do table.insert(menuListGUI,rotname) end
	
	local infoGUI = UIDropDownMenu_CreateInfo()
	for k,v in pairs(menuListGUI) do
	  infoGUI = UIDropDownMenu_CreateInfo()
	  infoGUI.text = v
	  infoGUI.value = v
	  infoGUI.func = GUIRotation_OnClick
	  UIDropDownMenu_AddButton(infoGUI, level)
	end
end

UIDropDownMenu_Initialize(DropDownRotationGUI, GUIDropDown_Initialize)
UIDropDownMenu_SetSelectedID(DropDownRotationGUI, 1)
UIDropDownMenu_SetWidth(DropDownRotationGUI, 100);
UIDropDownMenu_SetButtonWidth(DropDownRotationGUI, 100)
UIDropDownMenu_JustifyText(DropDownRotationGUI, "LEFT")

---------------------------
-- TIME TO DIE FRAME
---------------------------

local JPSTextInfoFrame = CreateFrame("frame","JPSTextInfoFrame",UIParent)

JPSTextInfoFrame:SetBackdrop({
	bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = 1, tileSize = 32, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
JPSTextInfoFrame:SetBackdropColor(0,0,0,0)

JPSTextInfoFrame:SetSize(200,100) 
--JPSTextInfoFrame:SetWidth(200)
--JPSTextInfoFrame:SetHeight(50)

JPSTextInfoFrame:SetPoint("CENTER",UIParent)
--JPSTextInfoFrame:SetPoint("CENTER", 0, 200)
JPSTextInfoFrame:SetFrameStrata("FULLSCREEN_DIALOG")

JPSTextInfoFrame:EnableMouse(true)
JPSTextInfoFrame:SetMovable(true)
JPSTextInfoFrame:RegisterForDrag("LeftButton")
JPSTextInfoFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
JPSTextInfoFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

JPSTextInfoFrame.text = JPSTextInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
--JPSTextInfoFrame.text:SetAllPoints()
JPSTextInfoFrame.text:SetFont("Fonts\\FRIZQT__.TTF",14) -- ('Fonts\\ARIALN.ttf', 12, 'THINOUTLINE')
JPSTextInfoFrame.text:SetPoint("TOPLEFT", 5, -5)
JPSTextInfoFrame.text:SetJustifyH("LEFT")
JPSTextInfoFrame.text:SetJustifyV("TOP")
JPSTextInfoFrame:Hide()

local GetUnitName = GetUnitName
local UpdateTextInfo = function()
	local infoTexts = ""
	if jps.getConfigVal("show ttd") == 1 then
		local infoTTD = jps.TimeToDie("target")
		local minutesDie = math.floor(infoTTD / 60)
		local secondsDie = infoTTD - (minutesDie*60)
		infoTexts = "TTD: "..minutesDie.. "min "..secondsDie.. "sec\n"
	end
	if jps.getConfigVal("show latency") == 1 then
		local Lag = jps.roundValue(jps.Latency,2)
		infoTexts = infoTexts.."|cffffffffLatency: ".."|cFFFF0000"..Lag.."\n"
	end
	if jps.getConfigVal("show current cast") == 1 then
		local currentCast = jps.LastCast
		local currentTarget = jps.LastTarget
		infoTexts = infoTexts.."|cff1eff00"..currentCast.."|cffffffff@".."|cffa335ee"..currentTarget.."\n"
	end

	JPSTextInfoFrame.text:SetText(infoTexts)
end

------------------------------------
-- ON UPDATE FRAMES
------------------------------------

local JPSTextInfoFrame_OnUpdate = CreateFrame("Frame")
JPSTextInfoFrame_OnUpdate:SetScript("OnUpdate", function(self, elapsed)
	if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
	if (self.TimeSinceLastUpdate > jps.UpdateInterval) then
		if jps.Combat then
			self.TimeSinceLastUpdate = 0
			if jps.getConfigVal("timetodie frame visible") == 1 then
				UpdateTextInfo()
			end
		end
	end
end)

---------------------------
-- SLIDER UPDATE INTERVAL
---------------------------

local slider = CreateFrame("Slider","UpdateInterval",JPSTextInfoFrame,"OptionsSliderTemplate")

slider:ClearAllPoints()
slider:SetPoint("TOP",0,25)
slider:SetWidth(100)
slider:SetHeight(15)
slider:SetScale(1)
slider:SetMinMaxValues(0.05, 0.5)
slider.minValue, slider.maxValue = slider:GetMinMaxValues()
slider:SetValue(0.2)
slider:SetValueStep(0.05)
slider:EnableMouse(true)
getglobal(slider:GetName() .. 'Low'):SetText('0.05')
getglobal(slider:GetName() .. 'High'):SetText('0.5')
getglobal(slider:GetName() .. 'Text'):SetText("Update Interval")

local function slider_OnClick(self)
	jps.UpdateInterval = jps.roundValue(slider:GetValue(),2)
	write("jps.UpdateInterval set to: "..jps.UpdateInterval)
end

slider:SetScript("OnValueChanged", function(self,event)
	if jps.UpdateInterval ~= jps.roundValue(slider:GetValue(),2) then
		slider_OnClick(self)
	end
end)

---------------------------
-- SLIDERS
---------------------------

function jps.addSlider(sliderName, parentObj, xPos, yPos, defaultVal, stepSize, minVal, maxVal, lowText,HighText,title, onChangeFunc)
	local sliderObj = CreateFrame("Slider",sliderName,parentObj,"OptionsSliderTemplate") --frameType, frameName, frameParent, frameTemplate 

	sliderObj:SetScale(1)
	sliderObj:SetMinMaxValues(minVal,maxVal)
	sliderObj.minValue, sliderObj.maxValue = sliderObj:GetMinMaxValues()
	sliderObj:SetValue(defaultVal)
	sliderObj:SetValueStep(stepSize)
	sliderObj:EnableMouse(true)
	sliderObj:SetPoint("TOPLEFT", parentObj, xPos, yPos)
	getglobal(sliderObj:GetName() .. 'Low'):SetText(lowText)
	getglobal(sliderObj:GetName() .. 'High'):SetText(HighText)
	getglobal(sliderObj:GetName() .. 'Text'):SetText(title)
	sliderObj:SetScript("OnValueChanged", onChangeFunc)
	sliderObj:Show()
	return sliderObj
end

---------------------------
-- UI Settings Frame
---------------------------

function jps.addUIFrame()
	jpsUIFrame = CreateFrame("Frame", "jpsUIFrame", jpsConfigFrame)
	jpsUIFrame.parent = jpsConfigFrame.name
	jpsUIFrame.name = "JPS UI Panel"
	local title = jpsUIFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 20, -10) 
	title:SetText("JPS CUSTOM ROTATION PANEL")
	jpsUIFrameInfo = jpsUIFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	jpsUIFrameInfo:SetHeight(46)
	jpsUIFrameInfo:SetWidth(570)
	jpsUIFrameInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	jpsUIFrameInfo:SetPoint("RIGHT", jpsUIFrame, -32, 0)
	jpsUIFrameInfo:SetNonSpaceWrap(true)
	jpsUIFrameInfo:SetJustifyH("LEFT")
	jpsUIFrameInfo:SetJustifyV("TOP")
	jpsUIFrameInfo:SetText('Adjust the look of the JPS UI')
	
	
	iconSizeSlider = jps.addSlider("iconSizeSlider",jpsUIFrame,30,-90 , 1 , 0.1, 0.5,1.5,"0.5","1.5","Main UI Scale", function(self, value)
		jpsIcon:SetScale(value)
		jps.setConfigVal("jpsIconSize",value)
	end)
	
	rotationDropdownSizeSlider = jps.addSlider("rotationDropdownSizeSlider",jpsUIFrame,30,-155 , 1 , 0.1, 0.5,1.5,"0.5","1.5","Rotation Dropdown Scale", function(self, value)
		rotationDropdownHolder:SetScale(value)
		jps.setConfigVal("rotationDropdownSizeSlider",value)
	end)
	
	timetodieSizeSlider = jps.addSlider("timetodieSizeSlider",jpsUIFrame,30,-215 , 1 , 0.1, 0.5,1.5,"0.5","1.5","TimeToDie UI Scale", function(self, value)
		JPSTextInfoFrame:SetScale(value)
		jps.setConfigVal("timetodieSizeSlider",value)
	end)
	
	InterfaceOptions_AddCategory(jpsUIFrame)
end

---------------------------
-- HIDE/SHOW DROPDOWN SPELLS
---------------------------

function jps.TimeToDieToggle(key, status)
	if status == 1 then -- and InCombatLockdown() == 1
		JPSTextInfoFrame:Show()
	else
		JPSTextInfoFrame:Hide()
	end
end

function jps.DropdownRotationTogle(key, status)
	if status == 1 then
		rotationDropdownHolder:Show()
	else
		rotationDropdownHolder:Hide()
	end
end

function jps.mainIconToggle(key, status) 
	if status == 1 then
		jpsIcon:Show()
	else
		jpsIcon:Hide()
	end
end

function jps.sliderUpdateToggle(key, status) 
	if status == 1 then
		slider:Show()
	else
		slider:Hide()
	end
end

function jps.jpHistoryToggle(key, status) 
	return jps.historyToggle(status)
end

---------------------------
-- Settings Frame
---------------------------
-- Custom Event Handlers which are called after a Setting checkbox is clicked
-- key = name of checkbox, value = function to call

function jps.addSettingsFrame()

	jps.onClickSettingEvents = {
		["timetodie frame visible"] = jps.TimeToDieToggle,
		["rotation dropdown visible"] = jps.DropdownRotationTogle,
		["show jps window"] = jps.mainIconToggle,
		["show slider update"] = jps.sliderUpdateToggle,
		["jphistory visible"] = jps.jpHistoryToggle,
	}
	
	jpsSettingsFrame = CreateFrame("Frame", "jpsSettingsFrame", jpsConfigFrame)
	jpsSettingsFrame.parent  = jpsConfigFrame.name
	jpsSettingsFrame.name = "JPS Settings Panel"
	local title = jpsSettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 20, -10) 
	title:SetText("JPS SETTINGS PANEL")
	local settingsInfo = jpsSettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	settingsInfo:SetHeight(32)
	settingsInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	settingsInfo:SetPoint("RIGHT", jpsSettingsFrame, -32, 0)
	settingsInfo:SetNonSpaceWrap(true)
	settingsInfo:SetJustifyH("LEFT")
	settingsInfo:SetJustifyV("TOP")
	settingsInfo:SetText("Work in Progress!")

	for settingsKey,settingsVal in pairs (jps.settings) do
		jps.notifySettingChanged(settingsKey, jps.getConfigVal(settingsKey))

		rotationCountSetting = rotationCountSetting + 1
		if rotationCountSetting == 16 then 
			settingsButtonPositionX = 220
			settingsButtonPositionY = - 90
		elseif rotationCountSetting == 31 then
			settingsButtonPositionX = 420
			settingsButtonPositionY = - 90
		end

		local settingsJPS_IconOptions_CheckButton = CreateFrame("CheckButton", "JPS_Button_Settings_"..settingsKey, jpsSettingsFrame, "OptionsCheckButtonTemplate");
		settingsJPS_IconOptions_CheckButton:SetPoint("TOPLEFT",settingsButtonPositionX,settingsButtonPositionY);
		getglobal(settingsJPS_IconOptions_CheckButton:GetName().."Text"):SetText(settingsKey);

		local function settingsJPS_IconOptions_CheckButton_OnClick()
            local settingsStatus = nil
            if(settingsJPS_IconOptions_CheckButton:GetChecked() == nil) then 
                settingsStatus = 0 
            else 
                settingsStatus = 1 
            end
            jps.notifySettingChanged(settingsKey, settingsStatus)
            jps.setConfigVal(settingsKey, settingsStatus)
		end  
		
		local function settingsJPS_IconOptions_CheckButton_OnShow()
			settingsJPS_IconOptions_CheckButton:SetChecked(jps.getConfigVal(settingsKey));
		end

		settingsJPS_IconOptions_CheckButton:RegisterForClicks("AnyUp");
		settingsJPS_IconOptions_CheckButton:SetScript("OnClick", settingsJPS_IconOptions_CheckButton_OnClick);
		settingsJPS_IconOptions_CheckButton:SetScript("OnShow", settingsJPS_IconOptions_CheckButton_OnShow);
		
		settingsButtonPositionY = settingsButtonPositionY - 30;
	end

	InterfaceOptions_AddCategory(jpsSettingsFrame)
	
	for key, settingOptions in pairs(jps.settingsQueue) do
		if settingOptions["settingType"] == checkbox then
			jps.addSettingsCheckbox(key)
			jps.settingsQueue[key] = nil
		end
	end
	
	jpsSettingsFrame:Hide()
	
end

function jps.getConfigVal(key)
	local setting = jps.settings[string.lower(key)]
	if setting == nil then
		jps.setConfigVal(key, 1)
		if not jps.Configged then
			if jps.settingsQueue[key] == nil then
				jps.settingsQueue[key] = {settingType="checkbox" }
			end
		else
			jps.addSettingsCheckbox(key)
		end
		return 1
	else 
		return setting
	end
end

function jps.setConfigVal(key,status)
	jps.settings[string.lower(key)] = status
end

function jps.notifySettingChanged(key, status) 
	if jps.onClickSettingEvents[string.lower(key)] ~= nil then
		jps.onClickSettingEvents[string.lower(key)](key, status)
	end
end

function jps.addSettingsCheckbox(settingName)
	rotationCountSetting = rotationCountSetting + 1
	if rotationCountSetting == 16 then 
		settingsButtonPositionX = 220
		settingsButtonPositionY = - 90
	elseif rotationCountSetting == 31 then
		settingsButtonPositionX = 420
		settingsButtonPositionY = - 90
	end

    local settingsJPS_IconOptions_CheckButton = CreateFrame("CheckButton", "JPS_Button_Settings_"..settingName, jpsSettingsFrame, "OptionsCheckButtonTemplate");
    settingsJPS_IconOptions_CheckButton:SetPoint("TOPLEFT",settingsButtonPositionX,settingsButtonPositionY);
    getglobal(settingsJPS_IconOptions_CheckButton:GetName().."Text"):SetText(settingName);
    
    local function settingsJPS_IconOptions_CheckButton_OnClick()
        local settingStatus = nil
        if(settingsJPS_IconOptions_CheckButton:GetChecked() == nil) then 
            settingStatus = 0 
        else 
            settingStatus = 1 
        end
        jps.notifySettingChanged(settingName, settingsStatus)
        jps.setConfigVal(settingName, settingsStatus)
    end  
    
    local function settingsJPS_IconOptions_CheckButton_OnShow()
        settingsJPS_IconOptions_CheckButton:SetChecked(jps.getConfigVal(settingName));
    end  
    
    settingsJPS_IconOptions_CheckButton:RegisterForClicks("AnyUp");
    settingsJPS_IconOptions_CheckButton:SetScript("OnClick", settingsJPS_IconOptions_CheckButton_OnClick);
    settingsJPS_IconOptions_CheckButton:SetScript("OnShow", settingsJPS_IconOptions_CheckButton_OnShow);

	settingsButtonPositionY = settingsButtonPositionY - 30;
end

---------------------------
-- LOAD_PROFILE
---------------------------

function jps.loadDefaultSettings()

	local settingsTable = {}
	settingsTable["rotation dropdown visible"] = 1
	settingsTable["timetodie frame visible"] = 0
	settingsTable["show jps window"] = 1
	settingsTable["jphistory visible"] = 1
	settingsTable["show slider update"] = 0
	settingsTable["show latency"] = 0
	settingsTable["show current cast"] = 0
	settingsTable["dismount in combat"] = 0
	settingsTable["show ttd"] = 0
	settingsTable["set healer as focus"] = 1

	for key,val in pairs(settingsTable) do 
		if jps.settings[string.lower(key)] == nil then
			jps.settings[string.lower(key)] = val
		end
	end
end

function jps_VARIABLES_LOADED()
	if jps.ResetDB then 
		jpsDB = {}
		collectgarbage("collect")
	end
	if not jpsDB then
		jpsDB = {}
	end
	if not jpsDB[jpsRealm] then
		jpsDB[jpsRealm] = {}
	end
	if not jpsDB[jpsRealm][jpsName] then
		write("Initializing new character names")
		jpsDB[jpsRealm][jpsName] = {}
		jpsDB[jpsRealm][jpsName].Enabled = true
		jpsDB[jpsRealm][jpsName].FaceTarget = false
		jpsDB[jpsRealm][jpsName].MoveToTarget = false
		jpsDB[jpsRealm][jpsName].UseCDs = false
		jpsDB[jpsRealm][jpsName].MultiTarget = false
		jpsDB[jpsRealm][jpsName].Interrupts = false
		jpsDB[jpsRealm][jpsName].Defensive = false
		jpsDB[jpsRealm][jpsName].PvP = false
		jpsDB[jpsRealm][jpsName].ExtraButtons = false

--		jpsDB[jpsRealm][jpsName].spellConfig = {} 
--		if jps.Spec then
--			jpsDB[jpsRealm][jpsName].spellConfig[jps.Spec] = {} 
--		end
--		jpsDB[jpsRealm][jpsName].settings = {} 
--	else
--		if not jpsDB[jpsRealm][jpsName].spellConfig then 
--			jpsDB[jpsRealm][jpsName].spellConfig = {} 
--		end
--		if not jpsDB[jpsRealm][jpsName].settings then 
--			jpsDB[jpsRealm][jpsName].settings = {} 
--		end		
--		
--		if jps.Spec then
--			if not jpsDB[jpsRealm][jpsName].spellConfig[jps.Spec] then 
--				jpsDB[jpsRealm][jpsName].spellConfig[jps.Spec] = {} 
--			end	
--		end
	end

	jps_LOAD_PROFILE()
	jps_SAVE_PROFILE()
	jps.loadDefaultSettings()
	jps.runFunctionQueue("settingsLoaded")
	jps_variablesLoaded = true
end

---------------------------
-- LOAD_PROFILE
---------------------------
function jps_LOAD_PROFILE() 
	for saveVar,value in pairs( jpsDB[jpsRealm][jpsName] ) do
		jps[saveVar] = value
	end

	jps.gui_toggleEnabled( jps.Enabled )
	jps.gui_toggleCDs( jps.UseCDs )
	jps.gui_toggleMulti( jps.MultiTarget )
	jps.gui_toggleInt(jps.Interrupts)
	jps.gui_toggleDef(jps.Defensive)
	jps.gui_toggleRot(jps.FaceTarget)
	jps.gui_toggleToggles( jps.ExtraButtons )
	jps.gui_setToggleDir( "right" )
	jps.togglePvP( jps.PvP )
	jps.resize( 36 )
end

---------------------------
-- SAVE_PROFILE
---------------------------

function jps_SAVE_PROFILE()
	for varName, _ in pairs( jpsDB[jpsRealm][jpsName] ) do
		jpsDB[jpsRealm][jpsName][varName] = jps[varName]
	end
end