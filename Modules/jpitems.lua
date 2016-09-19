--------------------------
-- LOCALIZATION
--------------------------

local GetItemCooldown = GetItemCooldown
local GetInventoryItemID = GetInventoryItemID
local GetItemSpell = GetItemSpell
local GetInventorySlotInfo = GetInventorySlotInfo

--------------------------
-- TRINKET
--------------------------

-- startTime, duration, enable = GetItemCooldown(itemID)
-- enable : 1 if the item is ready or on cooldown, 0 if the item is used, but the cooldown didn't start yet (e.g. potion in combat).
-- if the item is not equipped return 0,0,1

-- isUsable, notEnoughMana = IsUsableItem(itemID) or IsUsableItem("itemName")
-- isUsable - true if the item is usable; otherwise false (false if the item is not equipped)
-- notEnoughMana - true if the player lacks the resources (e.g. mana, energy, runes) to use the item; otherwise false

function jps.itemCooldown(item)
	if item == nil then return 999 end
	local start,duration,enable = GetItemCooldown(item) -- GetItemCooldown(ItemID) you MUST pass in the itemID.
	local usable = select(1,IsUsableItem(item))
	local itemName,_ = GetItemSpell(item) -- Useful for determining whether an item is usable.
	if not usable then return 999 end
	if not itemName then return 999 end
	if enable == 0 then return 999 end 
	local cd = start+duration-GetTime()
	if cd < 0 then return 0 end
	return cd
end

function jps.glovesCooldown()
	local start, duration, enabled = GetInventoryItemCooldown("player", 10)
	if enabled==0 then return 999 end
	local cd = start+duration-GetTime()
	if cd < 0 then return 0 end
	return cd
end

local useBagItemMacros = {}
function jps.useBagItem(itemName)
	if type(itemName) == "number" then
		itemName, _ = GetItemInfo(itemName) -- get localized name when ID is passed
	end
	local count = GetItemCount(itemName, false, false)
	if count == 0 then return nil end -- we doesn't have this item in our bag
	for bag = 0,4 do
		for slot = 1,GetContainerNumSlots(bag) do
			local item = GetContainerItemLink(bag,slot)
			if item and item:find(itemName) then -- item place found
				itemId = GetContainerItemID(bag, slot) -- get itemID for retrieving item Cooldown
				local start, dur, enable = GetItemCooldown(itemId) -- maybe we should use GetContainerItemCooldown() will test it
				local cdDone = Ternary((start + dur ) > GetTime(), false, true)
				local hasNoCD = Ternary(dur == 0, true, false)
				if (cdDone or hasNoCD) and enable == 1 then -- cd is done and item is not blocked (like potions infight even if CD is finished)
					if not useBagItemMacros[itemName] then useBagItemMacros[itemName] = {"/use "..itemName } end
					return useBagItemMacros[itemName]
				end
			end
		end
	end
	return false
end 

local useSlotMacros = {}
function jps.useSlot(num)
	-- get the Trinket ID
	local trinketId = GetInventoryItemID("player", num)
	if not trinketId then return "" end

	-- Check if it's on cooldown
	local trinketCd = jps.itemCooldown(trinketId)
	if trinketCd > 0 then return "" end

	 -- Check if it's usable
	local trinketUsable = GetItemSpell(trinketId)
	if not trinketUsable then return "" end

	-- Abort Disenchant (or any Spell Targeting) if active
	if SpellIsTargeting() then
		SpellStopTargeting()
	end

	-- Use it
	if not useSlotMacros[num] then useSlotMacros[num] = {"/use "..num} end
	return useSlotMacros[num]
end

-- For trinket's. Pass 0 or 1 for the number.
function jps.useTrinket(trinketNum)
	-- The index actually starts at 0
	local slotName = "Trinket"..(trinketNum).."Slot" -- "Trinket0Slot" "Trinket1Slot"
	-- Get the slot ID
	local slotId = select(1,GetInventorySlotInfo(slotName)) -- "Trinket0Slot" est 13 "Trinket1Slot" est 14

	return jps.useSlot(slotId)
end

-- For trinket's. Pass 0 or 1 for the number.
function jps.useTrinketBool(trinketNum)
	-- The index actually starts at 0
	local slotName = "Trinket"..(trinketNum).."Slot" -- "Trinket0Slot" "Trinket1Slot"
	-- Get the slot ID
	local slotId = select(1,GetInventorySlotInfo(slotName)) -- "Trinket0Slot" est 13 "Trinket1Slot" est 14
	-- get the Trinket ID
	local trinketId = GetInventoryItemID("player", slotId)
	if not trinketId then return false end
	-- Check if it's on cooldown
	local trinketCd = jps.itemCooldown(trinketId)
	if trinketCd > 0 then return false end
	-- Check if it's usable
	local trinketUsable = GetItemSpell(trinketId)
	if not trinketUsable then return false end

	return true
end

-- Engineers will use synapse springs buff on their gloves
function jps.useSynapseSprings()
	-- Get the slot number
	local slotNum = GetInventorySlotInfo("HandsSlot")
	return jps.useSlot(slotNum)
end



CreateFrame("GameTooltip", "ScanningTooltip", nil, "GameTooltipTemplate") -- Tooltip name cannot be nil
ScanningTooltip:SetOwner( WorldFrame, "ANCHOR_NONE" )
ScanningTooltip:ClearLines()

function parseTrinketText(trinket,str)
	local id = 13 + trinket
	if trinket > 1 then return false end
	ScanningTooltip:SetInventoryItem("player", id)

	local found = false
	for i=1,select("#",ScanningTooltip:GetRegions()) do 
		local region=select(i,ScanningTooltip:GetRegions())
		if region and region:GetObjectType()=="FontString" and region:GetText() then
			local text = region:GetText()
			--if text ~=nil then print(text) end
			if type(str) == "table" then 
				local matchesRequired = table.getn(str)
				local matchesFound = 0
				for key, val in pairs(str) do 
					if string.find(text:lower(),val:lower()) then 
						matchesFound = matchesFound +1 
					end
				end
				if matchesFound == matchesRequired then found = true end
			else 
				if string.find(text, str) then 
					found = true 
				end
			end
		end 
	end
	return found
end