-- Settings --
local ccFrame = 20 -- Check every X frames
local ccSplit = 4 -- Split the objects by X
local ccDelay = 1000 -- Seconds before looting the next corpse
--------------
local al = CreateFrame("Frame");
local ctFrame = 0;
local ccLastLoot = 0;

function fhAutoLoot_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage(":: AutoLoot - Loaded.", 0, 0.5, 0.8);
	al:SetScript("OnUpdate", OnUpdate);
end
 
function OnUpdate(self, elapsed)
	ctFrame = ctFrame + 1
	if ctFrame >= ccFrame then
		if FireHack then
			LootArea();
			ctFrame = 0;
        end
    end
end
 
function LootArea()
	if GetUnitSpeed("player") > 0 or UnitAffectingCombat("player") == true or IsMounted() == true then return; end

	local Total = GetTotalObjects()
	
	if not CurrentPosition then
		CurrentPosition = 1;
	end
	
	if not PreviousTotal or Total ~= PreviousTotal then
		PreviousTotal = Total;
		CurrentPosition = 1;
	end
		
	if (Total / ccSplit) > (Total - CurrentPosition) then
		MaxLimit = (Total - CurrentPosition)
	else
		MaxLimit = (Total / ccSplit)
	end
	
	local i = 1;
	while i < MaxLimit do
		local ThisObject = GetObjectListEntry(i + CurrentPosition);
		if ThisObject:GetType() == 3 and ThisObject:IsLootable() and ThisObject:GetDistance() <= 8 then
			if ccLastLoot == nil or ((GetTime()*1000) - ccLastLoot) > ccDelay then
				print(" Last Loot: " .. ((GetTime()*1000) - ccLastLoot));
				ThisObject:Interact();
				ccLastLoot = (GetTime()*1000)
				return
			end
		end
		i = i + 1;
	end
		
	CurrentPosition = i + CurrentPosition;
	-- print ("CP: " .. CurrentPosition .. " - Total: " .. Total);
	
	if CurrentPosition >= Total then
		CurrentPosition = 1;
	end
		
    return;
end
 
fhAutoLoot_OnLoad();