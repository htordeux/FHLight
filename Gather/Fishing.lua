-----------------------
-- FUNCTION FISHING
-----------------------
-- TYPE_OBJECT
-- TYPE_ITEM
-- TYPE_CONTAINER
-- TYPE_UNIT
-- TYPE_PLAYER
-- TYPE_GAMEOBJECT
-- TYPE_DYNAMICOBJECT
-- TYPE_CORPSE

if not FireHack then
	return;
end

local fh = {}
fh.FishingCast = {}
fh.Fishing = false
fh.SlotBag = nil
local PlayerGuid = UnitGUID("player")
local PlayerObject = GetObjectFromGUID(PlayerGuid)
local FishUntil = 0
SLASH_fh1 = '/fh'

function SlashCmdList.fh(cmd, editBox)
	local msg, rest = cmd:match("^(%S*)%s*(.-)$");
    if msg == "fish" then
	  fh.Fishing = not fh.Fishing
		print("Fishing set to", tostring(fh.Fishing))
	end
end

local BobberFrame = CreateFrame("FRAME", "FishingFrame")
-- BobberFrame:SetScript("OnUpdate", function(self, elapsed)
    -- if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
    -- self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
    -- if (self.TimeSinceLastUpdate > 0.2) and fh.Fishing then
		-- LookupFishing ()
        -- self.TimeSinceLastUpdate = 0
   	-- end
-- end)

local function ExploreBag()
	local freeSlot = {}
	local count = 0
	for bag = 0,4,1 do
		GetContainerFreeSlots(bag,freeSlot)
	end
	if freeSlot == nil then return 0 end
    for k,v in ipairs(freeSlot) do 
        count = count+1
    end
return count
end

local FISHINGLURES = {
	{ ["id"] = 33820 , ["name"] = "Weather-Beaten Fishing Hat"}, -- 75 for 10 minutes
	{ ["id"] = 88710 , ["name"] = "Nat's Hat"}, -- 150 for 10 minutes
}

local function HatLure ()
	local slotId, texture, checkRelic = GetInventorySlotInfo("HeadSlot") -- MainHandSlot
	local itemId = GetInventoryItemID("player", slotId)
	local start, duration, enabled = GetInventoryItemCooldown("player", slotId)
	for _,lure in ipairs(FISHINGLURES) do
		if itemId == lure.id then
			return itemId
		end
	end
	return nil
end

function fh.itemCooldown(item) -- start, duration, enable = GetItemCooldown(itemID) or GetItemCooldown("itemName")
	if item == nil then return 999 end
	local start,duration,_ = GetItemCooldown(item) -- GetItemCooldown(ItemID)
	local cd = start+duration-GetTime()
	if cd < 0 then return 0 end
	return cd
end

local function GetLatency()
	return select(4, GetNetStats())
end

local function Sleep(Interval)
	FishUntil = GetTime() + (Interval / 1000)
end

local function spelltoName(spellID)
	local name = GetSpellInfo(spellID)
	return name
end

-- 0x7 is the index of the created-by descriptor, not the offset.
-- You need to multiply it by 4 to get the offset, so the offset would be 0x1C. Since created-by is a GUID
-- you need to use Object:GetInt64Descriptor(0x1C) to read it. 
local function GetBobber()
	local BobberName = "Bobber"
	if (GetLocale() == "frFR") then BobberName = "Flotteur" 
	elseif (GetLocale() == "deDE") then BobberName = "Schwimmer"
	end
	local Total = GetTotalObjects(TYPE_GAMEOBJECT)
	
	local BobberID = nil
	local BobberDescriptor = nil
	
	for i = 1, Total,1 do
		local Object = GetObjectListEntry(i)
		local ObjectName = Object:GetName ()

		if (Object:GetDistance() <= 20) and ObjectName == BobberName then
			BobberDescriptor = Object:GetInt64Descriptor(0x20)
			BobberID = Object:GetDisplayID ()
			--print(BobberID,"|cffff8000",PlayerGuid,BobberDescriptor)
			if BobberDescriptor == PlayerGuid then
				return Object
			end
		end
	end
end

function LookupFishing ()
	if (FishUntil > GetTime()) or (InCombatLockdown == true) then return end
	if (not fh.Fishing) or (fh.SlotBag == 0) then RemoveTimerCallback(LookupFishing) return end
	local MyHatLure = HatLure()
	local CdMyHatLure = fh.itemCooldown(MyHatLure)

	local BobberLoot = false
	local BobberPointer = 0
	local BobberObject = GetBobber()
	
	if BobberObject then
		BobberPointer = bit.band(ReadInt(BobberObject:GetPointer() + 0xC4), 0x1) --BobberStateOffs = 0x00C4 // animation
			--print(BobberObject,"|cffff8000",BobberPointer)
			if BobberPointer == 1 then BobberObject:Interact () end
	else
		if CdMyHatLure == 0 then 
			UseInventoryItem(1) -- slot - An inventory slot number
		else 
			RemoveTimerCallback(LookupFishing)
			--PlayerObject:CastSpellByID(131474)
			PlayerObject:CastSpellByName(spelltoName(131474)) 
		end
	end
	Sleep(GetLatency() + 500)
end

local function SpellCastEventHandler(self, event, ...)

	if event == "UNIT_SPELLCAST_CHANNEL_START" then
		fh.FishingCast = {...}
	
    -- unitID - The unit that's casting. (string) -- player
    -- spell - The name of the spell that's being casted. (string) -- Pêche
    -- rank - The rank of the spell that's being casted. (string) -- Apprenti
    -- lineID - Spell lineID counter. This number is always 0 for channels. (number) -- 0
    -- spellID - The id of the spell that's being casted. (number, spellID) -- 131490

		if fh.FishingCast[1] == "player" and fh.FishingCast[2] == spelltoName(131490) then --  fh.FishingCast[5] == 131490 -- BUFF  
			local timer = math.random(200,500)
			SetTimerCallback(LookupFishing, timer)
		end
	elseif event == "BAG_UPDATE" then
		for bag = 0,4,1 do
			for slot = 1, GetContainerNumSlots(bag), 1 do
				local name = GetContainerItemLink(bag,slot)
				if name and string.find(name,"ff9d9d9d") then 
					PickupContainerItem(bag,slot)
					DeleteCursorItem()
				end
		 	end 
		end
		fh.SlotBag = ExploreBag()
	else
		Sleep(500)
	end
end

BobberFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
BobberFrame:RegisterEvent("BAG_UPDATE")
BobberFrame:SetScript("OnEvent", SpellCastEventHandler)

function fhFishing_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage(":: AutoFishing - Loaded. Cmd /fh fish",0, 0.5, 0.8)
	BobberFrame:SetScript("OnUpdate", nil);
end

fhFishing_OnLoad()
