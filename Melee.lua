--[[ made by
	 ¦¦¦¦¦¦+ ¦¦+     ¦¦+¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦+¦¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+
	¦¦+----+ ¦¦¦     ¦¦¦+--¦¦+--+¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+¦¦¦¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+
	¦¦¦  ¦¦¦+¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦+  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦¦¦+
	¦¦¦   ¦¦¦¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦+--¦¦¦  +¦¦++  ¦¦+--+  ¦¦¦+----¦¦¦¦¦+--¦¦¦  +¦¦++  +----¦¦¦
	+¦¦¦¦¦¦++¦¦¦¦¦¦¦+¦¦¦   ¦¦¦   +¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦¦
	 +-----+ +------++-+   +-+    +-----++-+  +-+   +-+   +-+     +-++------++-+  +-+   +-+   +------+
]]

local Code = "";
local Rand = Random.new(15308);
local StrList = {
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
	"?",
}

for i=1, 50 do
	Code = Code..tostring(StrList[Rand:NextInteger(1, #StrList)]);
end

local Melee = {}
local DoDamage : RemoteEvent = game.ReplicatedStorage.Events.DoDamage;
local plr = game.Players.LocalPlayer;
local cam = workspace.CurrentCamera;
local enum = require(game.ReplicatedStorage.Enum);

local UIS = game.UserInputService;

local function IsButtonDown(Button : Enum.KeyCode)
	if Button:IsA("KeyCode") and UIS:IsKeyDown(Button) then
		return true;
	elseif Button:IsA("UserInputType") and UIS:IsMouseButtonPressed(Button) then
		return true;
	end
	return false;
end

local function Spin(Part : Part)
	local last = os.clock();
	while Part:FindFirstChildWhichIsA('WeldConstraint') == nil do
		Part.CFrame *= CFrame.Angles(math.rad(180 * os.clock() - last),0,0);
		last = os.clock();
		task.wait();
	end
end

-- dont use this for enemies
local function CloestEnemy(CurrentPost)
	debug.profilebegin('Find Closest Enemy');
	local c = workspace.WaveTesting.Enemies:GetChildren();
	local T = {};
	for i, C in ipairs(c) do
		if C:IsA('Model') and C:FindFirstChild('HumanoidRootPart') then
			if C:FindFirstChild('Humanoid') then
				if C.Humanoid.Health > 0 then
					table.insert(T, C);
				end
			end
		end
	end
	
	table.sort(T, function(a : Model , b : Model)
		return (CurrentPost -  a.PrimaryPart.Position).Magnitude < (CurrentPost -  b.PrimaryPart.Position).Magnitude;
	end)
	debug.profileend();
	return T;
end

-- only used for weapon bounce
local function FindHumanoid(Modal : Model, NeedsHealth : boolean)
	local C = Modal:GetDescendants();
	for _, c in ipairs(C) do
		if c:IsA('Humanoid') and c:HasTag('Enemy') then
			if NeedsHealth or c.Health > 0 then
				return c;
			end
		end
	end
end

local function FindModal(Inst)
	if not Inst.Parent:IsA('Model') then
		return FindModal(Inst.Parent);
	end
	return Inst.Parent;
end

local Data = {
	Damage= 5,
	ThrowDamage= 5,
	Size = Vector3.zero, -- range
	Offset = Vector3.zero, -- very useful for different sized enemies
	Stamina = 100,
	StaminaUsage = 5,
	SwingSpeed = 1.2, -- time between each swing
	SwingDelay = 0.2, -- time before the animation
	Combo = 0, -- number of combos
	HitCombo = 0, -- number of combos that hit enemies
	ThrowSpeed = 1.2, -- time between each throw
	ThrowDelay = 0.2, -- time before the animation
	OnlyHitOnce = true,
	AutoSwing = true;
	IsThrowable = true;
	Bounce = 0;
	BounceDamage = 5;
	BounceRange = 20;
	BounceSight = true;
	ThrowPickUp = false;
	IsPlayer = false,
	
	-- deals damage to armored enemies
	ArmorPiercing = false,
	
	Handle = nil,
	IsEquipped = false,
	
	CanSwing = true,
	CanThrow = true,
	
	SwingButton = Enum.UserInputType.MouseButton1;
	ThrowButton = Enum.UserInputType.MouseButton2;
	
	Swing = function(self, Player : Player?)
		if not self.CanSwing or not self.IsEquipped then return end
		
		local C = Player;
		if self.IsPlayer then
			C = Player.Character;
		end
		if C == nil then return end
		
		
		self.CanSwing = false;
		
		self.OnSwingBeforeDelay();
		task.wait(self.SwingDelay);
		debug.profilebegin('Swing '..self.Name);
		self.OnSwingBefore();
		
		local part = Instance.new('Part');
		part.CFrame = C.PrimaryPart.CFrame;
		part.Size = self.Size;
		part.Position += (part.CFrame.LookVector + (part.CFrame.LookVector * part.Size.Z / 2));
		part.CFrame *= CFrame.new(self.Offset);
		part.Anchored = true;
		part.Transparency = 0.6;
		part.Parent = workspace;
		
		local Targets = part:GetTouchingParts();
		
		part.CanCollide = false;
		part.CanQuery = false;
		part.CanTouch = false;
		
		local HitHumanoids = {};
		
		for _, t in Targets do
			local H = nil;
			
			if t.Parent:FindFirstChildWhichIsA('Humanoid') and
				t.Parent:FindFirstChildWhichIsA('Humanoid'):HasTag(self.IsPlayer and 'Enemy' or 'Team')
					and (self.ArmorPiercing or not t.Parent:FindFirstChildWhichIsA('Humanoid'):HasTag('Armoured')) then -- i should shorten this
				H = t.Parent:FindFirstChildWhichIsA('Humanoid');
			elseif t:FindFirstChildWhichIsA('Humanoid') and t:FindFirstChildWhichIsA('Humanoid'):HasTag(self.IsPlayer and 'Enemy' or 'Team') then
				H = t:FindFirstChildWhichIsA('Humanoid');
			end
			
			if H == nil or (self.OnlyHitOnce and table.find(HitHumanoids, H)) then continue end;
			
			if self.IsPlayer then
				DoDamage:FireServer(H, self.Damage, Code);
			else
				H:TakeDamage(self.Damage);
			end
			table.insert(HitHumanoids, H);
			self.OnHitTarget(t.Parent);
		end
		
		if #HitHumanoids > 0 then
			self.HitCombo += 1;
		else
			self.HitCombo = 0;
		end
		
		self.Combo += 1;
		
		self.OnSwingAfter(Targets);
		
		part:Destroy();
		
		debug.profileend();
		task.wait(self.SwingSpeed);
		self.CanSwing = true;
		
		if self.AutoSwing and IsButtonDown(self.SwingButton) then task.spawn(self.Swing, self, Player) end
		
	end,
	
	
	Throw = function(self, Player : Player, Camera : Camera)
		if not self.IsThrowable or not self.CanThrow or not self.IsEquipped then return end
		
		local C = Player.Character;
		if C == nil then return end
		
		self.CanThrow = false;
		
		self.OnThrowBeforeDelay();
		
		task.wait(self.ThrowDelay);
		debug.profilebegin('Throw '..self.Name);
		self.Handle.Transparency = 1;
		self.OnThrowBefore();
		
		local Handle : Part = self.Handle:Clone(); -- test
		local Handle : Part = Handle.Handle;
		Handle.CanCollide = true;
		
		Handle.Parent = workspace;
		Handle.Handle.Transparency = 0;
		Handle.CFrame = Camera.CFrame;
		Handle.Position = Player.Character.Head.Position + Camera.CFrame.LookVector * 2;
		Handle.AssemblyLinearVelocity = Camera.CFrame.LookVector * 250;
		
		if Handle:FindFirstChildWhichIsA('Trail') then
			Handle:FindFirstChildWhichIsA('Trail').Enabled = true;
		end
		
		task.spawn(Spin, Handle);
		
		local E = nil; -- hacky way to do this
		
		E = Handle.Touched:Connect(function(P)
			
			if not Handle:CanCollideWith(P) then return end;
			E:Disconnect();
			
			local Bounce = self.Bounce;
			local HitList = {};
			
			local HD = P.Parent:FindFirstChild('Humanoid') or P:FindFirstChild('Humanoid');
			if HD and HD:HasTag(self.IsPlayer and 'Enemy' or "Team") and (self.ArmorPiercing or not HD:HasTag('Armoured')) then
				DoDamage:FireServer(HD, self.ThrowDamage, Code);
				table.insert(HitList, FindModal(P));
			end
			
			local LB = nil;
			
			self.OnBounceBefore();
			
			while Bounce > 0 do
				local s = 0;
				local T = CloestEnemy(Handle.Position);
				for i, t in T do
					if table.find(HitList, t) == nil then
						if self.BounceSight then
							local Param = RaycastParams.new();
							Param.RespectCanCollide = true;
							Param.FilterDescendantsInstances = {Handle, t, T[1]};
							local Cast = workspace:Raycast(Handle.Position, (t.PrimaryPart.Position - Handle.Position).Unit *
								(Handle.Position - t.PrimaryPart.Position).Magnitude, Param);
							
							if Cast then
								continue;
							end
						end
						s = i;
						break;
					end
				end
				
				if s == 0 then break end;
				
				if T[s] and (T[s].PrimaryPart.Position - Handle.Position).Magnitude < self.BounceRange then
					Handle.Position = T[s].PrimaryPart.Position;
					
					table.insert(HitList, T[s]);
					
					local H = FindHumanoid(T[s]);
					
					DoDamage:FireServer(H, self.BounceDamage, Code);
					self.OnBounceHit(T[s]);
					LB = T[s];
					Bounce -= 1;
				else
					break;
				end
			end
			
			self.OnBounceAfter();
			
			local w = Instance.new('WeldConstraint');
			w.Parent = Handle;
			w.Part0 = Handle;
			w.Part1 = LB and LB.PrimaryPart or P or workspace.Target;
			
			if self.ThrowPickUp then
				Handle.CanTouch = true;
				w.Part1 = nil; -- weld to Anchored part
				Handle.Touched:Connect(function(P)
					Handle.Anchored = true;
					if w.Part1 == nil and P.Anchored then
						w.Part1 = P;
					end
					if plr then
						if Player.Character == P.Parent then
							Handle:Destroy();
							self.Handle.Transparency = 0;
							self.CanThrow = true;
						end
					end
				end)
			else
				game.Debris:AddItem(Handle, 5);
			end
		end);
		
		self.OnThrowAfter();
		debug.profileend();
		task.wait(self.ThrowSpeed);
		if not self.ThrowPickUp then
			self.Handle.Transparency = 0;
			self.CanThrow = true;
		end
	end,
	
	OnSwingBeforeDelay = function()
		--warn("Not Implemented OnSwingBeforeDelay");
	end,
	
	OnSwingBefore = function()
		--warn("Not Implemented OnSwingBefore");
	end,
	
	OnSwingAfter = function(Humanoids : table)
		--warn("Not Implemented OnSwingAfter");
	end,
	
	OnHitTarget = function(Target: modal?)
		--warn("Not Implemented OnHitTarget");
	end,
	
	OnThrowBeforeDelay = function()
		--warn("Not Implemented OnThrowBeforeDelay");
	end,

	OnThrowBefore = function()
		--warn("Not Implemented OnThrowBefore");
	end,

	OnThrowAfter = function()
		--warn("Not Implemented OnThrowAfter");
	end,
	
	OnBounceBefore = function()
		--warn("Not Implemented OnBounceBefore");
	end,
	
	OnBounceHit = function()
		--warn("Not Implemented OnBounceHit");
	end,
	
	OnBounceAfter = function()
		--warn("Not Implemented OnBounceAfter");
	end,
}

-- please use the tools handle not the 
function Melee.new(Handle : Part?, Damage : number, Size : Vector3)
	local Class = setmetatable(table.clone(Data), Melee); -- base data and config
	
	Class.Handle = Handle;
	Class.Damage = Damage;
	Class.Size = Size;
	Class.Name = typeof(Handle) == 'string' and Handle or Handle.Parent.Name;
	
	if plr and cam then
		Class.IsPlayer = true;
		local function Input(key : InputObject, IsTyping : boolean)
			if IsTyping then return end;
			if key.KeyCode == Class.SwingButton or key.UserInputType == Class.SwingButton then
				Class:Swing(plr);
			elseif key.KeyCode == Class.ThrowButton or key.UserInputType == Class.ThrowButton then
				Class:Throw(plr, cam);
			end
		end
		UIS.InputBegan:Connect(Input);
	end
	
	return Class;
end

return Melee
