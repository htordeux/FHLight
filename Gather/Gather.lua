if not FireHack then
	return;
end

local WaitForMount = false;
local CurrentObject = nil;
local CurrentWaypoint = 0;
local MiningSkill = 0;
local HerbalismSkill = 0;
local StopAscending = false;
local AttemptedMountTime = 0;
local LastNodeCheck = 0;

function GetNearestWaypoint ()
	local BestWaypoint = nil;
	for Key, Value in pairs(Profile.Waypoints) do
		local X, Y, Z = Value[1], Value[2], Value[3];
		if not BestWaypoint or GetDistanceBetweenPoints(X, Y, Z, Player:GetLocation()) < GetDistanceBetweenPoints(Profile.Waypoints[BestWaypoint][1], Profile.Waypoints[BestWaypoint][2], Profile.Waypoints[BestWaypoint][3], Player:GetLocation()) then
			BestWaypoint = Key;
		end
	end
	
	return BestWaypoint;
end

function GatherStart ()
	CurrentWaypoint = GetNearestWaypoint();
	
	local Profession1, Profession2 = GetProfessions();
	local Profession1Name, _, Profession1Skill = GetProfessionInfo(Profession1);
	local Profession2Name, _, Profession2Skill = GetProfessionInfo(Profession2);
	
	if Profession1Name == "Mining" then
		MiningSkill = Profession1Skill;
	elseif Profession1Name == "Herbalism" then
		HerbalismSkill = Profession1Skill;
	end
	
	if Profession2Name == "Mining" then
		MiningSkill = Profession2Skill;
	elseif Profession2Name == "Herbalism" then
		HerbalismSkill = Profession2Skill;
	end
end

function GatherStop ()
	SetM2Collision(true);
	SetWMOCollision(true);
	SetTerrainCollision(true);
	SetLiquidCollision(true);
end

function IsValidNode (ThisObject)
	if select(2, ThisObject:GetType()) ~= 3 then
		return false;
	end

	for Key, Value in pairs(Veins) do
		if Value[1] == ThisObject:GetName() and Value[2] <= MiningSkill then
			return true;
		end
	end
	
	for Key, Value in pairs(Herbs) do
		if Value[1] == ThisObject:GetName() and Value[2] <= HerbalismSkill then
			return true;
		end
	end
	
	return false;
end

function AreLootableNodesNearby ()
	return not EnumerateObjects(function (ThisObject)
		return not IsValidNode(ThisObject);
	end, TYPE_GAMEOBJECT);
end

function IsNodeSafe (Obj)
	return #Obj:GetNearbyEnemies(25) <= 1 and #Obj:GetNearbyPlayers(40) == 0;
end

function IsObjectInLOS (ThisObject)
	local X, Y, Z = ThisObject:GetLocation();
	local PlayerX, PlayerY, PlayerZ = Player:GetLocation();
	return not TraceLine(X, Y, Z + 3, PlayerX, PlayerY, PlayerZ + 3, bit.bor(0x1, 0x10, 0x100, 0x10000, 0x100000));
end

function SelectNewNode ()
	local BestObject = nil;
	EnumerateObjects(function (ThisObject)
		if (not BestObject or ThisObject:GetDistance() < BestObject:GetDistance()) and --[[not ThisObject:IsSubmerged() and]] IsValidNode(ThisObject) and ThisObject:InLineOfSight() and IsNodeSafe(ThisObject) then
			BestObject = ThisObject;
		end
		
		return true;
	end, TYPE_GAMEOBJECT);
	
	return BestObject;
end

function Gather ()
	if UnitIsDeadOrGhost("Player") then
		if UnitIsDead("Player") then
			RepopMe();
		else
			if Player:IsMoving() then
				return;
			end
		
			local X, Y, Z = GetCorpseLocation();
			if GetDistanceBetweenPoints(X, Y, Z, Player:GetLocation()) > 30 then
				if not GetFlyHack() then
					SetFlyHack(true);
					return;
				end
				
				X = X + math.random(-0.5, 0.5);
				Y = Y + math.random(-0.5, 0.5);
				
				MoveTo(X, Y, Z);
			else
				if GetFlyHack() then
					SetFlyHack(false);
					return;
				end
				
				RetrieveCorpse();
			end
		end
	end
	
	if IsFalling() and GetDistanceFallen() > 11 then
		StopFalling();
		SetFlyHack(true);
		return;
	end
	
	if GetFlyHack() then
		SetFlyHack(false);
	end

	local Flying = (IsFlying() == 1 or IsSwimming() == 1);
	if Flying and GetTerrainCollision() then
		SetM2Collision(false);
		SetWMOCollision(false);
		SetTerrainCollision(false);
		
		if not IsSwimming() then
			SetLiquidCollision(false);
		end
	elseif not Flying and not GetTerrainCollision() then
		SetM2Collision(true);
		SetWMOCollision(true);
		SetTerrainCollision(true);
		if not IsSwimming() then
			SetLiquidCollision(true);
		end
	end
	
	local X, Y, Z = Player:GetLocation();
	if IsFalling() and not TraceLine(X, Y, Z, X, Y, Z - 30, bit.bor(0x1, 0x10, 0x100)) then
		SetFlyHack(true);
		StopMoving();
	end
	
	if Player:IsInCombat() and not IsMounted() then
		if not Target or not Target:IsAttackable() or Target:GetTarget():GetGUID() ~= Player:GetGUID() then
			TargetNearestEnemy();
		end
		
		if Target then
			Target:Face();
			Behavior.Combat(Target);
		end
		
		return;
	end
	
	if CurrentObject and not CurrentObject:Exists() then
		CurrentObject = nil;
	end
	
	if WaitForMount and not IsMounted() and IsOutdoors() then
		if GetTime() - AttemptedMountTime <= 5 then
			return;
		else
			DEFAULT_CHAT_FRAME:AddMessage("Failed to mount. Retrying.", 0, 0.5, 0.8);
			
			if UseMount and not IsMounted() and IsOutdoors() then
				CastSpellByName(FireBot["Mount"]);
				CurrentWaypoint = GetNearestWaypoint();
				AttemptedMountTime = GetTime();
				WaitForMount = true;
				return;
			end
		end
	end
	
	WaitForMount = false;
	AttemptedMountTime = 0;
	AttemptedMounts = 0;
	
	WaitForMount = false;
	if (not CurrentObject or CurrentObject:GetDistance() > 3) and IsOutdoors() and not IsMounted() then
		CastSpellByName(FireBot["Mount"]);
		AttemptedMountTime = GetTime();
		WaitForMount = true;
		return;
	end
	
	if StopAscending then
		AscendStop();
		StopAscending = false;
	end
	
	if IsMounted() and not IsFlying() and not IsSwimming() then
		JumpOrAscendStart();
		StopAscending = true;
		return;
	end
	
	if CurrentObject then
		if Player:IsMoving() then
			return;
		end
		
		if CurrentObject:GetDistance() > 3 then
			local X, Y, Z = CurrentObject:GetLocation();
			X = X ;
			Y = Y + math.random(-0.5, 0.5);
			
			MoveTo(X + math.random(-0.5, 0.5), Y + math.random(-0.5, 0.5), Z + math.random(0, 2));
		else
			if IsMounted() then
				if IsSafeToDismount() then
					Dismount();
				else
					local X, Y, Z = Player:GetLocation();
					MoveTo(X, Y, Z + 1);
				end
				
				return;
			end
			
			if LootFrame:IsVisible() then
				if LootButton1:IsVisible() then
					LootButton1:Click();
				end
				
				if LootButton2:IsVisible() then
					LootButton2:Click();
				end
				
				if LootButton3:IsVisible() then
					LootButton3:Click();
				end
				
				if LootButton4:IsVisible() then
					LootButton4:Click();
				end
			else
				CurrentObject:Interact();
			end
		end
	else
		if LastNodeCheck <= GetTime() - 0.5 then
			CurrentObject = SelectNewNode();
			LastNodeCheck = GetTime();
			StopMoving();
		end
		
		if not CurrentObject then
			if GetDistanceBetweenPoints(Profile.Waypoints[CurrentWaypoint][1], Profile.Waypoints[CurrentWaypoint][2], Profile.Waypoints[CurrentWaypoint][3], Player:GetLocation()) > 5 then
				if not Player:IsMoving() then
					MoveTo(Profile.Waypoints[CurrentWaypoint][1], Profile.Waypoints[CurrentWaypoint][2], Profile.Waypoints[CurrentWaypoint][3]);
				end
				
				return;
			end
			
			CurrentWaypoint = CurrentWaypoint + 1;
			
			if not Profile.Waypoints[CurrentWaypoint] then
				CurrentWaypoint = 1;
			end
			
			MoveTo(Profile.Waypoints[CurrentWaypoint][1], Profile.Waypoints[CurrentWaypoint][2], Profile.Waypoints[CurrentWaypoint][3]);
		end
	end
end