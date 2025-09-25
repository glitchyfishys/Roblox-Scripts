--[[ made by
	 ¦¦¦¦¦¦+ ¦¦+     ¦¦+¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦+¦¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+
	¦¦+----+ ¦¦¦     ¦¦¦+--¦¦+--+¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+¦¦¦¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+
	¦¦¦  ¦¦¦+¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦+  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦¦¦+
	¦¦¦   ¦¦¦¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦+--¦¦¦  +¦¦++  ¦¦+--+  ¦¦¦+----¦¦¦¦¦+--¦¦¦  +¦¦++  +----¦¦¦
	+¦¦¦¦¦¦++¦¦¦¦¦¦¦+¦¦¦   ¦¦¦   +¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦¦
	 +-----+ +------++-+   +-+    +-----++-+  +-+   +-+   +-+     +-++------++-+  +-+   +-+   +------+
]]

local Pathfind = {};

local players = {};

local rayLength = 1000;
local Rand = Random.new();

local function Check(Result)
	if Result then
		--print(Result, Result.Instance)
		local H = Result.Instance.Parent:FindFirstChild("Humanoid");
		if H then
			if H.Health > 0 then
				return true;
			else
				return false;
			end
		end
	end
	return false;
end

local function Strafe(MP, LP)
	return (CFrame.lookAt(MP, LP) * CFrame.Angles(0, -math.pi/2, 0)).LookVector * Rand:NextInteger(-1,1) * 8;
end

local function FindClosestPlayer(Info, range : number)
	debug.profilebegin('FindClosestPlayer');
	local closest : player = nil;
	local closestPos : number = range; -- closet player within x studs
	for _, plr : Player in players do
		if plr == nil or plr.Character == nil then continue end
		local HRP = plr.Character:FindFirstChild('HumanoidRootPart');
		local MYHRP = Info.Me:FindFirstChild('HumanoidRootPart');
		if plr.Character.Humanoid.Health <= 0 then continue end
		if HRP and MYHRP then -- joining a game the player has no character
			local Dis : Vector3 = HRP.Position - MYHRP.Position;
			if Dis.Magnitude < closestPos then -- cloest player
				closestPos = Dis.Magnitude;
				closest = plr;
			end
		end
	end
	Info.PlayerTarget = closest;
	debug.profileend();
	return closest;
end

local function CheckTarget(self, plr)
	if plr == nil and self.PlayerTarget then plr = self.PlayerTarget end; -- set default if used outside of the Module
	if plr == nil or plr.Character == nil or plr.Character.PrimaryPart == nil then return nil end;
	local rayOrigin = self.Me.PrimaryPart.Position;
	local rayDirection = (plr.Character.PrimaryPart.Position - rayOrigin).Unit * math.min(self.RaycastRange, rayLength);
	local param = RaycastParams.new();
	param.RespectCanCollide = true;
	param.FilterDescendantsInstances = {self.Me};

	local Result = workspace:Raycast(rayOrigin, rayDirection, param);

	if Check(Result) then
		self.PlayerTarget = plr;
		self.CanSeeTargetPlayer = true;
		self.TargetDistance = Result.Distance;
		if Result.Distance < self.VisualRange then
			self.IsTargetInRange = true;
		else
			self.IsTargetInRange = false;
		end
	else
		self.PlayerTarget = nil;
		self.TargetDistance = math.huge;
		self.CanSeeTargetPlayer = false;
		self.IsTargetInRange = false;
	end

	return Result;
end

local function FindPlayer(self, plr)
	local Player = nil;
	local R = plr or self.PlayerTarget or players[Rand:NextInteger(1, #players)];
	if R then
		CheckTarget(self,R);
	end
	return R;
end

local data ={  -- add more config later
	
	-- go to this part if no players can be found
	Target = nil,
	Me = nil,
	PathFinder = nil, -- pathfinder object
	PlayerTarget = nil,
	CanSeeTargetPlayer = false,
	IsTargetInRange = false,
	-- max distance the pathfinder can go
	PathfindRange = math.huge,
	-- max raycast range for finding players
	RaycastRange = 250,
	-- Distance when the player can be seen
	VisualRange = 100,
	-- Distance from the target player
	TargetDistance = 0,
	
	NodeList = nil,
	
	-- set manually or nil for a new one
	V3Point = nil,
	
	Move = function(self, Target, strafe)
		local Path = self.PathFinder;
		
		if typeof(Target) == 'Vector3' then
			Path:ComputeAsync(self.Me.HumanoidRootPart.Position, Target);
		else
			if Target then -- target player
				Path:ComputeAsync(self.Me.HumanoidRootPart.Position, Target.Character.HumanoidRootPart.Position);
			else
				Path:ComputeAsync(self.Me.HumanoidRootPart.Position, self.Target.Position);
			end
		end
		
		local WayPoints = Path:GetWaypoints();
		
		if #WayPoints == 0 then -- has no target or cant get to them
			Path:ComputeAsync(self.Me.HumanoidRootPart.Position, typeof(Target) == 'Vector3' and Target or self.Target.Position);
			WayPoints = Path:GetWaypoints();
		end

		self.NodeList = WayPoints; -- this can be used to make pathfinding more efficient
		
		if WayPoints[2] == nil then
			return false;
		end;
		
		if WayPoints[3] and WayPoints[3].Action == Enum.PathWaypointAction.Jump then -- jumping
			local Str = strafe and Strafe(self.Me.PrimaryPart.Position, WayPoints[3].Position) or Vector3.zero;
			self.Me.Humanoid.Jump = true;
			self.Me.Humanoid:MoveTo(WayPoints[3].Position + Str);
		else
			local Str = strafe and Strafe(self.Me.PrimaryPart.Position, WayPoints[2].Position)  or Vector3.zero;
			self.Me.Humanoid:MoveTo(WayPoints[2].Position + Str);
		end
		
		return true;
	end,
	
	CheckTarget = function(self) -- go to target if there is no player in range
		CheckTarget(self, FindPlayer(self));
	end,
	
	TargetOrInRange = function(self) -- go to target if there is no player in range
		local closest = FindClosestPlayer(self, self.PathfindRange);
		self:Move(closest);
	end,
	
	Sniper = function(self)
		FindPlayer(self);
		
		local closest = FindClosestPlayer(self, math.huge);
		task.spawn(self.Move, self, closest);
		return closest, true, false; -- player, can find, can target
	end,
	
	General = function(self)
		FindPlayer(self);
		
		local closest = FindClosestPlayer(self, math.huge);
		task.spawn(self.Move, self, closest);
		return closest, true, false; -- player, can find, can target
	end,
	
	Strafe = function(self) -- you will hate this enemy
		FindPlayer(self);
		
		local closest = FindClosestPlayer(self, math.huge);
		task.spawn(self.Move, self, closest, self.PlayerTarget ~= nil);
	end,
	
	-- move away from the target player
	MoveAwayFrom = function(self)
		FindClosestPlayer(self, self.VisualRange);
		if self.PlayerTarget then
			local c = CFrame.lookAt(self.Me.HumanoidRootPart.Position, self.PlayerTarget.Character.PrimaryPart.Position).LookVector;
			self.Me.Humanoid:MoveTo(self.Me.HumanoidRootPart.Position + (c * -50));
		end
	end,
	
	GoToRandomPoint = function(self)
		local rand = self.V3Point or Vector3.new(Rand:NextNumber(-230, 220), 5, Rand:NextNumber(-400, 280));
		self.V3Point = rand;
		if not self:Move(rand, false) then
			self.Me.Humanoid:MoveTo(rand);
		end
	end,
	
	GoToRandomNode = function(self, Nodes) -- untested
		local rand = Nodes[Rand:NextInteger(1, #Nodes)];
		if typeof(rand) == "Part" then
			return self:Move(rand.Position, false);
		end
		return self:Move(rand, false);
	end,
	
	PointToPlayer = function(self, predictive : boolean, plr : Player?)
		local Player = nil;
		self.Me.Humanoid.AutoRotate = true;
		local T = plr or self.PlayerTarget or players[Rand:NextInteger(1, #players)];
		if T then
			local Result = CheckTarget(self, T);
		end
		
		game["Run Service"].Heartbeat:Once(function() -- using Once to keep memory free
			if self.PlayerTarget and self.PlayerTarget.Character then
				self.Me.Humanoid.AutoRotate = false;
				local HRP : Part = self.Me.HumanoidRootPart;
				if HRP:FindFirstChild("AlignOrientation") then
					local P = self.PlayerTarget.Character.PrimaryPart.Position;
					local M = HRP.Position;
					HRP.AlignOrientation.LookAtPosition = Vector3.new(P.X, M.Y, P.Z);
				end
			end
		end)
		
	end,
	
	FindPlayerToTarget = function(self, plr)
		FindPlayer(self, plr);
	end,
	
	RandomPlayerToTarget = function(self, plr)
		self.PlayerTarget = players[Rand:NextInteger(1, #players)];
	end,
}

-- players to find
for _, plr in game.Players:GetPlayers() do
	table.insert(players, plr);
end

game.Players.PlayerAdded:Connect(function(player)
	table.insert(players, player);
end)

game.Players.PlayerRemoving:Connect(function(player)
	table.remove(players, table.find(players, player));
end)



Pathfind.new = function(Me)
	local Class = setmetatable(table.clone(data), Pathfind); -- there is some quantum entanglement going on here
	
	Class.Me = Me;
	
	return Class;
end

return Pathfind;

-- Visualize pathfinding

--for _, point in pairs(WayPoints) do
--	local p = Instance.new('Part');
--	p.Shape =  "Ball";
--	p.Color = Color3.fromRGB(0, 255, 0);
--	p.Size = Vector3.new(0.5,0.5,0.5);
--	p.Position = point.Position;
--	p.Parent = workspace;
--	p.Anchored = true;
--	p.CanCollide = false;
--end

--[[ Side Notes
	If the pathfinding breaks use the "Visualize pathfinding" code up there.
	Any function with 'self' must be called using ":" like this Path:Move().
	
--]]
