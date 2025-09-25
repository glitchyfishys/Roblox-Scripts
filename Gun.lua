--[[ made by
	 ¦¦¦¦¦¦+ ¦¦+     ¦¦+¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦+¦¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+
	¦¦+----+ ¦¦¦     ¦¦¦+--¦¦+--+¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+¦¦¦¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+
	¦¦¦  ¦¦¦+¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦+  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦¦¦+
	¦¦¦   ¦¦¦¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦+--¦¦¦  +¦¦++  ¦¦+--+  ¦¦¦+----¦¦¦¦¦+--¦¦¦  +¦¦++  +----¦¦¦
	+¦¦¦¦¦¦++¦¦¦¦¦¦¦+¦¦¦   ¦¦¦   +¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦¦
	 +-----+ +------++-+   +-+    +-----++-+  +-+   +-+   +-+     +-++------++-+  +-+   +-+   +------+
]]

local IsClient = game:GetService('RunService'):IsClient();

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

local Gun = {};
Gun.Enum = {
	BulletType = {
		Normal = 1,
		Beam = 2,
		Lightning = 3,
		Other = 4,
	}
}

local UIS = game:GetService('UserInputService');
local plr = game.Players.LocalPlayer;
local cam = workspace.CurrentCamera;
local enum = require(game.ReplicatedStorage.Enum);

local MaxDistance = 750; -- remove the bullet if it's too far away
local DoDamage : RemoteEvent = game.ReplicatedStorage.Events.DoDamage;
local MakeBullet : RemoteEvent = game.ReplicatedStorage.Events.MakeBullet;
local Explosion : RemoteEvent = game.ReplicatedStorage.Events.Explosion;
local Rand = Random.new();
local RayPrams = RaycastParams.new();

RayPrams.RespectCanCollide = true;

local UIS = game.UserInputService;

local function RandomSpread(Spread : number)
	return Vector3.new(math.rad(Rand:NextNumber(-1,1) * Spread),
		math.rad(Rand:NextNumber(-1,1) * Spread),
		math.rad(Rand:NextNumber(-1,1) * Spread));
end

local function IsButtonDown(Button : Enum.KeyCode)
	if Button:IsA("KeyCode") and UIS:IsKeyDown(Button) then
		return true;
	elseif Button:IsA("UserInputType") and UIS:IsMouseButtonPressed(Button) then
		return true;
	end
	return false;
end

local function CheckHit(Info, Results :RaycastResult, Bullet : Part, player : Player, CurrentPierce :number)
	
	local HD : Humanoid = Results.Instance:FindFirstChild('Humanoid');
	if HD == nil then HD = Results.Instance.Parent:FindFirstChild('Humanoid') end;
	
	if IsClient then
		if HD and HD:HasTag('Enemy') and (Info.ArmorPiercing or not HD:HasTag('Armoured')) then -- only hit things with the "Enemy" tag
			DoDamage:FireServer(HD, Info.Damage, Code);
			Info.OnHitEnemy(Bullet, player, HD.Parent);
			if CurrentPierce == 0 then return end; -- damage only once
		elseif HD and HD:HasTag('Team') and (Info.ArmorPiercing or not HD:HasTag('Armoured')) then
			DoDamage:FireServer(HD, Info.Heal * -1, Code); -- just use the same thing
			Info.OnHitTeam(Bullet, player, HD.Parent);
			if CurrentPierce == 0 then return end; -- damage only once
		end
	else
		if HD and HD:HasTag('Team') and (Info.ArmorPiercing or not HD:HasTag('Armoured')) then -- sever side
			HD:TakeDamage(Info.Damage);
			Info.OnHitEnemy(Bullet, player, HD.Parent);
			if CurrentPierce == 0 then return end;
		elseif HD and HD:HasTag('Enemy') and (Info.ArmorPiercing or not HD:HasTag('Armoured')) then
			HD:TakeDamage(Info.Heal * -1);
			Info.OnHitTeam(Bullet, player, HD.Parent);
			if CurrentPierce == 0 then return end;
		end
	end
	
end

local function FadeAndDestroy(Bullet : Part, speed : number?)
	if Bullet == nil then return end;
	while Bullet and Bullet.Transparency and Bullet.Transparency < 1 do
		Bullet.Transparency += task.wait() / speed or 1; -- yes this how it works
		if Bullet == nil then return end
	end
	Bullet:Destroy();
end

local function BulletTick(self, Bullet : BasePart, player : Player)

	local CurrentPierce = self.Pierce;

	local last = os.clock();
	local BS = self.BulletSpeed;
	local BulletDrop = self.BulletDrop;
	local StartMag = Bullet.Position;


	while Bullet do -- basiclly a while true loop but if some how the bullet gets destroyed it will stop
		debug.profilebegin('BulletTick for '..self.Name);
		local tick = os.clock() - last;
		--point in drop direction so that it moves down better
		local BDOT : Vector3 = Bullet.CFrame.LookVector * (BS * tick) - (Vector3.new(0, BulletDrop, 0) * tick);
		if self.BulletDropRotate then Bullet.CFrame = CFrame.lookAt(Bullet.Position, Bullet.Position + BDOT); end;
		local Results = workspace:Raycast(Bullet.Position, BDOT , RayPrams);

		if Results then
			if Results == nil then debug.profileend(); break end;
			CurrentPierce -= 1;
			Bullet.Position = Results.Position;
			self.OnHitObject(Bullet, player, Results.Instance);

			CheckHit(self, Results, Bullet, player, CurrentPierce);
		end

		if Bullet.Position.Magnitude > MaxDistance
			or (StartMag - Bullet.Position).Magnitude > self.Range or CurrentPierce == 0 then
			Bullet:Destroy();
			debug.profileend();
			break; -- despawnend
		end

		Bullet.Position += BDOT - (Results and Results.Position or  Vector3.zero);
		if not self.StaticBulletDrop then BulletDrop += (self.ExponentialBulletDrop and BulletDrop or self.BulletDrop) * tick; end; -- add velocity basicly
		last = os.clock();
		debug.profileend();
		task.wait();
	end

end

local function ArcTick(self, Bullet : BasePart, player : Player)

	debug.profilebegin('ArcTick for '..self.Name);

	local StartMag = Bullet.Position;
	local Results = workspace:Raycast(Bullet.Position, Bullet.CFrame.LookVector * (Bullet.Size.Z / 2), RayPrams);
	if Results then
		self.OnHitObject(Bullet, player, Results.Instance);
		CheckHit(self, Results, Bullet, player, 1);
	end
	debug.profileend();
	task.spawn(FadeAndDestroy, Bullet, self.BulletSpeed);
end

local function Shoot(self, player : Player?, camera : Camera?)
	if self.IsShooting or not self.CanShoot or
		not self.IsEquipped or self.IsReloading then return false end;

	debug.profilebegin('Fired '..self.Name);

	self.CanShoot = false;
	self.IsShooting = true;

	self.OnShootBefore(player);

	if self.BulletType == Gun.Enum.BulletType.Normal then
		debug.profilebegin(self.Name..' bullet | Burst: '..self.Burst.." at "..self.BurstRate);

		for i=1, self.Burst do
			local Bullet = Instance.new('Part');
			Bullet.Transparency = 0;
			Bullet.Size = Vector3.new(0.2,0.2,2);
			Bullet.CanCollide = false; -- don't want to interfere with anything
			Bullet.CanTouch = false;
			Bullet.CanQuery = false;
			Bullet.CastShadow = false;
			Bullet.Anchored = true;
			Bullet.Name = self.Name..' Bullet';
			Bullet.Color = Color3.new(0,1,1);
			Bullet.Material = Enum.Material.Neon;
			Bullet.Parent = workspace;
			Bullet.CFrame = (self.BulletSpawnPart or camera).CFrame; -- this is first because geting just the rotation is hard

			if self.Spread > 0 then
				local R = RandomSpread(self.Spread);
				Bullet.CFrame *= CFrame.Angles(R.X,R.Y,R.Z);
			end

			if not self.BulletSpawnPart then
				local LV = camera.CFrame.LookVector;
				Bullet.Position = player:IsA('Model') and camera.Position or player.Character.Head.Position + (LV / 2); -- this aims better
			end

			if IsClient then
				MakeBullet:FireServer(self, Bullet.CFrame, Code);
			end

			self.OnBulletFired(player, Bullet);
			task.spawn(BulletTick, self, Bullet, player); -- more bullets can be fired
			if self.BurstRate ~= 0 then task.wait(self.BurstRate); end
		end

		debug.profileend();

	elseif self.BulletType == Gun.Enum.BulletType.Beam then

		debug.profilebegin(self.Name..' Beam | Burst: '..self.Burst.." at "..self.BurstRate);

		for i=1, self.Burst do

			local Bullet = Instance.new("Part");
			Bullet.Shape = Enum.PartType.Cylinder;
			Bullet.Name = self.Name..' Beam';
			Bullet.Anchored = true;
			Bullet.CanCollide = false;
			Bullet.CanQuery = false;
			Bullet.CanTouch = false;
			Bullet.CastShadow = false;
			Bullet.Color = Color3.new(0, 1, 1);
			Bullet.Material = Enum.Material.Neon;
			Bullet.Parent = workspace;
			Bullet.CFrame = (self.BulletSpawnPart or camera).CFrame;

			if self.Spread > 0 then
				local R = Vector3.new(Rand:NextNumber(-1,1) * self.Spread,Rand:NextNumber(-1,1) * self.Spread,Rand:NextNumber(-1,1) * self.Spread);
				local G = Bullet.Position + (Bullet.CFrame.LookVector * 100 + R);
				Bullet.CFrame = CFrame.lookAt(player:IsA('Model') and camera.Position or player.Character.Head.Position, G); -- bullet spread took way too long to make
			end

			if not self.BulletSpawnPart then
				local LV = camera.CFrame.LookVector;
				Bullet.Position = player:IsA('Model') and camera.Position or player.Character.Head.Position + (LV / 2); -- this aims better
			end

			local startPosition = Bullet.Position;
			local Info = workspace:Raycast(startPosition, Bullet.CFrame.LookVector * self.Range, RayPrams);

			local laserDistance = Info and (startPosition - (Info.Position)).Magnitude or self.Range;

			Bullet.Size = Vector3.new(laserDistance, 0.2, 0.2);
			Bullet.Position += Bullet.CFrame.LookVector * laserDistance / 2;
			Bullet.CFrame *= CFrame.Angles(0, math.rad(90), 0);

			task.spawn(FadeAndDestroy, Bullet, self.BulletSpeed);

			if Info then  -- just do it here to save raycasting again
				self.OnHitObject(Bullet, player, Info.Instance);
				CheckHit(self, Info, Bullet, player, 1);
			end;

			self.OnBulletFired(player, Bullet);

			if self.BurstRate ~= 0 then task.wait(self.BurstRate); end
		end

		debug.profileend();

	elseif self.BulletType == Gun.Enum.BulletType.Lightning then

		debug.profilebegin(self.Name..' Lightning | Chains: '..self.Burst.." at "..self.BurstRate);

		local Leng = self.Range / self.Pierce;
		for i=1, self.Burst do

			local LastBullet = nil;

			for i=1, self.Pierce do

				local Bullet = LastBullet and LastBullet:Clone() or Instance.new('Part');

				if not LastBullet then -- save some memory and time
					Bullet.Transparency = 0;
					Bullet.Size = Vector3.new(0.2,0.2, Leng);
					Bullet.CanCollide = false;
					Bullet.CanTouch = false;
					Bullet.CanQuery = false;
					Bullet.Anchored = true;
					Bullet.CastShadow = false;
					Bullet.Name = self.Name..' Lightning';
					Bullet.Color = Color3.new(0,1,1);
					Bullet.Material = Enum.Material.Neon;
					Bullet.CFrame = (LastBullet or self.BulletSpawnPart or camera).CFrame; -- this is first because geting just the rotation is hard
				end

				Bullet.Parent = workspace;

				if self.Spread > 0 then
					local R = RandomSpread(self.Spread);
					Bullet.CFrame *= CFrame.Angles(R.X,R.Y,R.Z)
				end

				if LastBullet == nil and not self.BulletSpawnPart then
					local LV = camera.CFrame.LookVector;
					Bullet.Position = player:IsA('Model') and camera.Position or player.Character.Head.Position + LV; -- this aims better
				end

				Bullet.Position += Bullet.CFrame.LookVector * Leng / 2;

				LastBullet = Bullet;

				self.OnBulletFired(player, Bullet);
				task.spawn(ArcTick, self, Bullet, player);

			end

			if self.BurstRate ~= 0 then task.wait(self.BurstRate); end
		end

		debug.profileend();

	else
		-- do your own thing in your script
	end

	if self.OneAmmoPerShot then
		self.CurrentClip -= 1;
	else
		self.CurrentClip -= self.Burst;
	end

	self.OnShootAfter(player);

	debug.profileend();

	local Clock = os.clock();
	local CD = os.clock() + self.FireRate;

	while Clock < CD do -- cooldown
		Clock = os.clock();
		task.wait();
	end

	if self.CurrentClip ~= 0 then self.CanShoot = true; end
	self.IsShooting = false;
	if self.SemiAuto and IsButtonDown(self.ShootButton) then task.spawn(self.Shoot,self, player, camera) end
end

local Data = { -- Gun info
	Name = 'nil',
	Damage  = 10,
	-- use positive numbers not negitive
	Heal  = 0,
	Range = 100,
	-- in degrees / 2
	Spread = 0,
	Burst = 1,
	Pierce = 1,
	-- bullets on reload
	ClipSize = 0,
	-- current bullets
	CurrentClip = 0, 
	BulletSpeed = 100, -- if we dont want this i can just use a single raycast on the server side
	ReloadTime = 3,
	-- total BurstRate time also delays fire rate (BurstRate * Burst)
	FireRate = 0.5,
	BurstRate = 0,
	-- the rate in studs that the bullet falls per second
	BulletDrop = 0,
	ShootButton = Enum.UserInputType.MouseButton1,
	ReloadButton = Enum.KeyCode.R,
	-- holding ShootButton will auto fire
	SemiAuto = false,
	OneAmmoPerShot = false,
	AmmoPerReload = math.huge,
	-- deals damage to armored enemies
	ArmorPiercing = false,
	-- makes Bullet drop rotate bullets downwards
	BulletDropRotate = false,
	-- no veloctity is applied
	StaticBulletDrop = false,
	-- bullets fall faster based on time
	ExponentialBulletDrop = false,
	
	BulletType = Gun.Enum.BulletType.Normal,
	
	BulletSpawnPart = nil;
	
	CanShoot = true,
	IsReloading = false,
	IsShooting = false,
	IsEquipped = false,
	
	Reload = function(self, player : Player)
		if not self.IsEquipped or self.IsReloading or self.CurrentClip == self.ClipSize then return end;
		self.IsReloading = true;
		self.OnReloadBefore(player);
		
		local Clock = os.clock();
		local CD = os.clock() + self.ReloadTime;
		while Clock < CD do -- cooldown
			Clock = os.clock();
			if not self.IsEquipped then
				self.IsReloading = false;
				self.OnReloadAfter(player, false);
				return false;
			end
			task.wait();
		end
		if self.CurrentClip == 0 and not self.IsShooting then self.CanShoot = true; end
		self.CurrentClip += self.AmmoPerReload;
		self.CurrentClip = math.min(self.ClipSize, self.CurrentClip);
		self.OnReloadAfter(player, true);
		self.IsReloading = false;
	end,
	
	Shoot = function(self, player : Player?, camera : Camera?)
		task.spawn(Shoot , self, player, camera);
	end,
	
	Explode = function(self, pos, size, time) -- need to add range and damage
		if IsClient then
			Explosion:FireServer(pos, size, time, Code);
			
			local HitHumanoids = {};
			
			local part = Instance.new('Part');
			part.Size = Vector3.new(4,4,4);
			part.Position += pos;
			part.Anchored = true;
			part.Transparency = 0.6;
			part.Parent = workspace;
			
			local Targets = part:GetTouchingParts();
			
			part:Destroy();
			
			for _, t in Targets do
				local H = nil;
				
				if t.Parent:FindFirstChildWhichIsA('Humanoid') and
					t.Parent:FindFirstChildWhichIsA('Humanoid'):HasTag('Enemy')
					and (self.ArmorPiercing or not t.Parent:FindFirstChildWhichIsA('Humanoid'):HasTag('Armoured')) then -- i should shorten this
					H = t.Parent:FindFirstChildWhichIsA('Humanoid');
				elseif t:FindFirstChildWhichIsA('Humanoid') and t:FindFirstChildWhichIsA('Humanoid'):HasTag('Enemy') then
					H = t:FindFirstChildWhichIsA('Humanoid');
				end
				
				if H == nil or table.find(HitHumanoids, H) then continue end;
				
				table.insert(HitHumanoids, H);
				
				local dis = (t.Position - pos).Magnitude;
				if dis < 2 then
					DoDamage:FireServer(H, 60 / (dis ^ 1.25), Code);
				end
			end
			
		end
	end,
	
	-- Set these as functions after using Gun.New
	-- the warning is only if you forget one
	
	-- passes the player
	OnShootBefore = function(player: Player)
		--warn('Not Implemented OnShootBefore');
	end,
	
	-- passes the player
	OnShootAfter = function(player: Player)
		--warn('Not Implemented OnShootAfter');
	end,
	
	-- passes the player and Bullet
	OnBulletFired = function(player: Player, Bullet : Part)
		--warn('Not Implemented OnBulletFired');
	end,
	
	-- passes the Bullet, Player and the Target
	OnHitEnemy = function(Bullet : Part, Player: Player, Target : Modal?)
		--warn('Not Implemented OnHitEnemy');
	end,
	
	-- passes the Bullet, Player and the Target
	OnHitTeam = function(Bullet : Part, Player: Player, Target : Modal?)
		--warn('Not Implemented OnHitTeam');
	end,
	
	-- passes the Bullet, Player and the Target
	OnHitObject = function(Bullet : Part, Player: Player, Target : Modal?)
		--warn('Not Implemented OnHitObject');
	end,
	
	-- passes the Player
	OnReloadBefore = function(Player: Player)
		--warn('Not Implemented OnReloadBefore');
	end,
	
	-- passes the Player and a Boolean (If it has finished reloading)
	OnReloadAfter = function(Player: Player, HasReloaded : BoolValue)
		--warn('Not Implemented OnReloadAfter');
	end,
	
};

function Gun.New(Name : string, Damage : number?, Range : number?,
	BulletSpeed : number?, ReloadTime : number?, FireRate : number?,
	Spread : number, Burst : number) -- make a new Gun
	
	local Class = setmetatable(table.clone(Data), Gun); -- base data and config
	Class.Name = Name or 'You forgot to name the gun';
	Class.Damage = Damage or 1;
	Class.Range = Range or 100;
	Class.BulletSpeed = BulletSpeed or 10;
	Class.ReloadTime = ReloadTime or 3;
	Class.FireRate = FireRate or 0.2;
	Class.Spread = Spread or 0;
	Class.Burst = Burst or 1;
	Class.CurrentClip = Class.ClipSize;
	
	if plr and cam then
		local function Input(key : InputObject, IsTyping : boolean)
			if IsTyping then return end;
			if key.KeyCode == Class.ReloadButton or key.UserInputType == Class.ReloadButton then
				Class:Reload(plr);
			elseif key.KeyCode == Class.ShootButton or key.UserInputType == Class.ShootButton then
				Class:Shoot(plr, cam);
			end
		end
		UIS.InputBegan:Connect(Input);
	end
	
	return Class;
end

return Gun;
