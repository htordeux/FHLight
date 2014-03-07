if not FireHack then
	return;
end

if not FireBot then
	FireBot = {};
	FireBot["Type"] = "Gather";
end

local RecordedWaypoints = {};
local LastWaypoint = {0, 0, 0};
local IsRecording = false;
local State = false;

function IsSafeToDismount ()
	local X, Y, Z = Player:GetLocation();
	return TraceLine(X, Y, Z, X, Y, Z - 10, bit.bor(0x1, 0x10, 0x100));
end

function RecordWaypoint ()
	local X, Y, Z = Player:GetLocation();
	if GetDistanceBetweenPoints(LastWaypoint[1], LastWaypoint[2], LastWaypoint[3], X, Y, Z) > 5 then
		tinsert(RecordedWaypoints, {X, Y, Z});
		LastWaypoint[1] = X;
		LastWaypoint[2] = Y;
		LastWaypoint[3] = Z;
	end
end

function CommandHandler (Command)
	if Command:sub(1, 3) ~= ".fb" then
		return false;
	end
	
	local FBCommand = Command:sub(5):lower();
	
	if FBCommand == "on" then
		if State then
			DEFAULT_CHAT_FRAME:AddMessage("FireBot is already enabled.", 0, 0.5, 0.8);
			return true;
		end
	
		local ProfileName = FireBot["Profile"];
		if not ProfileName or ProfileName == "" then
			DEFAULT_CHAT_FRAME:AddMessage("You must load a profile before starting FireBot.", 0, 0.5, 0.8);
			return true;
		end
		
		local ProfileContents = ReadFile(GetLoaderFolder() .. "\\Profiles\\" .. ProfileName);
		if not ProfileContents then
			DEFAULT_CHAT_FRAME:AddMessage("Profile not found.", 0, 0.5, 0.8);
			return true;
		end
		
		Profile = nil;
		if not pcall(loadstring(ProfileContents)) or not Profile then
			DEFAULT_CHAT_FRAME:AddMessage("The profile is not valid.", 0, 0.5, 0.8);
			return true;
		end
		
		local BehaviorName = FireBot["Behavior"];
		if not BehaviorName or BehaviorName == "" then
			DEFAULT_CHAT_FRAME:AddMessage("You must load a behavior before starting FireBot.", 0, 0.5, 0.8);
			return true;
		end
		
		local BehaviorContents = ReadFile(GetLoaderFolder() .. "\\Behaviors\\" .. BehaviorName);
		if not BehaviorContents then
			DEFAULT_CHAT_FRAME:AddMessage("Behavior not found.", 0, 0.5, 0.8);
			return true;
		end
		
		Behavior = nil;
		if not pcall(loadstring(BehaviorContents)) or not Behavior then
			DEFAULT_CHAT_FRAME:AddMessage("The behavior is not valid.", 0, 0.5, 0.8);
			return true;
		end
		
		if not FireBot["Mount"] then
			DEFAULT_CHAT_FRAME:AddMessage("You must set a mount before starting FireBot.", 0, 0.5, 0.8);
			return true;
		end
		
		if GetCVar("AutoLootDefault") ~= "1" then
			SetCVar("AutoLootDefault", "1")
			DEFAULT_CHAT_FRAME:AddMessage("Enabled AutoLoot.", 0, 0.5, 0.8);
		end
		
		if FireBot["Type"] == "Gather" then
			GatherStart();
		elseif FireBot["Type"] == "Grind" then
			GrindStart();
		else
			DEFAULT_CHAT_FRAME:AddMessage("Gathering or grinding must be selected.", 0, 0.5, 0.8);
			return true;
		end
		
		State = true;
		
		if not HasSetCallback then
			HasSetCallback = true;
			SetTimerCallback(TimerCallback, 50);
		end
		
		DEFAULT_CHAT_FRAME:AddMessage("FireBot enabled.", 0, 0.5, 0.8);
		
	elseif FBCommand == "off" then
		if not State then
			DEFAULT_CHAT_FRAME:AddMessage("FireBot is already disabled.", 0, 0.5, 0.8);
			return true;
		end
	
		State = false;
		
		if FireBot["Type"] == "Gather" then
			GatherStop();
		elseif FireBot["Type"] == "Grind" then
			GrindStop();
		end
		
		DEFAULT_CHAT_FRAME:AddMessage("FireBot disabled.", 0, 0.5, 0.8);
		
	elseif FBCommand:sub(1, 5) == "mount" then
		local MountName = Command:sub(11);
		local i = 1;
		while i <= GetNumCompanions("Mount") do
			if select(2, GetCompanionInfo("Mount", i)):lower() == MountName:lower() then
				FireBot["Mount"] = MountName;
				print("|c000080B0FireBot mount set to:|r |cFFFFFFFF" .. MountName .. "|r");
				
				return true;
			end
			
			i = i + 1;
		end
		
		print("|c000080B0Unknown mount:|r |cFFFFFFFF" .. MountName .. "|r");
	elseif FBCommand:sub(1, 7) == "profile" then
		local ProfileContents = ReadFile(GetLoaderFolder() .. "\\Profiles\\" .. FBCommand:sub(9));
		if not ProfileContents then
			DEFAULT_CHAT_FRAME:AddMessage("Profile not found.", 0, 0.5, 0.8);
			return true;
		end
		
		Profile = nil;
		if not pcall(loadstring(ProfileContents)) or not Profile then
			DEFAULT_CHAT_FRAME:AddMessage("The profile is not valid.", 0, 0.5, 0.8);
			return true;
		end
		
		FireBot["Profile"] = FBCommand:sub(9);
		DEFAULT_CHAT_FRAME:AddMessage("Profile loaded.", 0, 0.5, 0.8);
		
	elseif FBCommand:sub(1, 8) == "behavior" then
		local BehaviorContents = ReadFile(GetLoaderFolder() .. "\\Behaviors\\" .. FBCommand:sub(10));
		if not BehaviorContents then
			DEFAULT_CHAT_FRAME:AddMessage("Behavior not found.", 0, 0.5, 0.8);
			return true;
		end
		
		Behavior = nil;
		if not pcall(loadstring(BehaviorContents)) or not Behavior then
			DEFAULT_CHAT_FRAME:AddMessage("The behavior is not valid.", 0, 0.5, 0.8);
			return true;
		end
		
		FireBot["Behavior"] = FBCommand:sub(10);
		DEFAULT_CHAT_FRAME:AddMessage("Behavior loaded.", 0, 0.5, 0.8);
	
	elseif FBCommand == "avoid" then
		if FireBot["Avoid"] then
			FireBot["Avoid"] = false;
			DEFAULT_CHAT_FRAME:AddMessage("Avoid mobs disabled.", 0, 0.5, 0.8);
		else
			FireBot["Avoid"] = true;
			DEFAULT_CHAT_FRAME:AddMessage("Avoid mobs enabled.", 0, 0.5, 0.8);
		end
	
	elseif FBCommand == "stoponplayers" then
		if FireBot["StopOnPlayers"] then
			FireBot["StopOnPlayers"] = false;
			DEFAULT_CHAT_FRAME:AddMessage("Stop while players are nearby disabled.", 0, 0.5, 0.8);
		else
			FireBot["StopOnPlayers"] = true;
			DEFAULT_CHAT_FRAME:AddMessage("Stop while players are nearby enabled.", 0, 0.5, 0.8);
		end
		
	elseif FBCommand == "clear" then
		RecordedWaypoints = {};
		DEFAULT_CHAT_FRAME:AddMessage("Recorded profile cleared.", 0, 0.5, 0.8);
		
	elseif FBCommand == "record" then
		if IsRecording then
			RemoveTimerCallback(RecordWaypoint);
			IsRecording = false;
			DEFAULT_CHAT_FRAME:AddMessage("Paused profile recording.", 0, 0.5, 0.8);
		else
			SetTimerCallback(RecordWaypoint, 50);
			IsRecording = true;
			DEFAULT_CHAT_FRAME:AddMessage("Started profile recording.", 0, 0.5, 0.8);
		end
		
	elseif FBCommand:sub(1, 4) == "save" then
		local FileContents = "Profile = {};\nProfile.Waypoints = {\n\t";
		for Key, Value in pairs(RecordedWaypoints) do
			FileContents = FileContents .. "{" .. tostring(Value[1]) .. ", " .. tostring(Value[2]) .. ", " .. tostring(Value[3]) .. "},\n\t";
		end
		
		FileContents = FileContents .. "};";
		WriteFile(GetLoaderFolder() .. "\\Profiles\\" .. FBCommand:sub(6), FileContents);
		DEFAULT_CHAT_FRAME:AddMessage("Profile saved.", 0, 0.5, 0.8);
		
	elseif FBCommand == "help" then
		print("|c000080B0FireBot commands:|r");
		print("|cFFFFFFFF.FB On|r |c000080B0to start FireBot.|r");
		print("|cFFFFFFFF.FB Off|r |c000080B0to stop FireBot.|r");
		print("|cFFFFFFFF.FB Mount <Name>|r |c000080B0to set the mount for FireBot to use.|r");
		print("|cFFFFFFFF.FB Profile <File>|r |c000080B0to load a profile from the Profiles folder.|r");
		print("|cFFFFFFFF.FB Behavior <File>|r |c000080B0to load a behavior from the Behaviors folder.|r");
		print("|cFFFFFFFF.FB Avoid|r |c000080B0to toggle avoiding mobs that are close to nodes.|r");
		print("|cFFFFFFFF.FB StopOnPlayers|r |c000080B0to pause while players are nearby.|r");
		print("|cFFFFFFFF.FB Clear|r |c000080B0to clear the recorded profile.|r");
		print("|cFFFFFFFF.FB Record|r |c000080B0to toggle profile recording.|r");
		print("|cFFFFFFFF.FB Save <File>|r |c000080B0to save the recorded profile.|r");
		print("|cFFFFFFFF.FB Help|r |c000080B0to display this help message.|r");
	else
		print("|c000080B0Unknown FireBot command. Use|r |cFFFFFFFF.FB Help|r |c000080B0to get a list of FireBot commands.|r");
	end
	
	return true;
end

local OSendChatMessage = nil;
CreateFrame("Frame"):SetScript("OnUpdate", function()
	if not OSendChatMessage then
		local OSendChatMessage = SendChatMessage;
		SendChatMessage = function (Message, Type, Language, Channel)
			if not CommandHandler(Message) then
				return OSendChatMessage(Message, Type, Language, Channel);
			end
		end
	end
end);

function ArePlayersNearby () 
	return GetTotalObjects(TYPE_PLAYER) > 1;
end

function TimerCallback ()
	if not State or (FireBot["StopOnPlayers"] and ArePlayersNearby()) then
		return;
	end

	if FireBot["Type"] == "Gather" then
		Gather();
	end
end