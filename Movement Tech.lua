local Player : Player = game.Players.LocalPlayer;
local Camera : Camera = workspace.CurrentCamera;
local Character : Character = Player.Character;
local Humanoid : Humanoid = Character:WaitForChild('Humanoid');
local HumanoidRootPart : Part = Character:WaitForChild('HumanoidRootPart');
local Input : Input = game.UserInputService;

local OnWall = false;
local WallJumpForce = Vector3.zero;
local CanDoubleJump = false;
local CanTripleJump = false;
local CanDash = true;
local CanSuperDash = true;
local CanJumpDash = true;
local CanSuperJump = true;


-- setup hitbox
local WallJumpBox = Instance.new('Part');
WallJumpBox.Transparency = 0.9;
WallJumpBox.Size = Vector3.new(3,3.5,2.5);
WallJumpBox.CanCollide = false;
WallJumpBox.Position = HumanoidRootPart.Position;
WallJumpBox.Parent = Character;
WallJumpBox.CollisionGroup = 'WallJumpBox';

local Weld = Instance.new('WeldConstraint');
Weld.Part0 = WallJumpBox
Weld.Part1 = HumanoidRootPart;
Weld.Parent = WallJumpBox;


function getClosestFace(pos, part)
	local faces = {
		--Top = part.CFrame * CFrame.new(0, part.Size.Y, 0), -- not needed but just incase
		--Bottom = part.CFrame * CFrame.new(0, -part.Size.Y, 0),
		Front = part.CFrame * CFrame.new(0, 0, -part.Size.Z),
		Back = part.CFrame * CFrame.new(0, 0, part.Size.Z),
		Right = part.CFrame * CFrame.new(part.Size.X, 0, 0),
		Left = part.CFrame * CFrame.new(-part.Size.X, 0, 0),
	}
	local closest = nil;
	local minDist = math.huge;
	
	for face, cframe in pairs(faces) do
		local dist = (cframe.Position - pos).Magnitude;
		if dist < minDist then
			minDist = dist;
			closest = face;
		end
	end
	return closest;
end

function Wall(p : Part)
	if p.Parent:FindFirstChild('WallJumpBox') == WallJumpBox then return end
	local side = getClosestFace(HumanoidRootPart.Position, p);
	
	if side == 'Left' then
		WallJumpForce = Vector3.new(-50,0,0);
	elseif side == 'Right' then
		WallJumpForce = Vector3.new(50,0,0);
	elseif side == 'Front' then
		WallJumpForce = Vector3.new(0,0,-50);
	elseif side == 'Back' then
		WallJumpForce = Vector3.new(0,0,50);
	end
	OnWall = true;
end

function WallEnd(p : Part)
	if p == nil then return end
	if p.Parent:FindFirstChild('WallJumpBox') == WallJumpBox then return end
	WallJumpForce = Vector3.zero;
	OnWall = false;
end

function WallJump()
	if not (CanDoubleJump or CanTripleJump) or not OnWall then return end;
	if Humanoid.FloorMaterial ~= Enum.Material.Air then return end
	
	HumanoidRootPart.AssemblyLinearVelocity =
		Vector3.new(HumanoidRootPart.AssemblyLinearVelocity.X, 50, HumanoidRootPart.AssemblyLinearVelocity.Z) + WallJumpForce;
	if not CanDoubleJump  and CanTripleJump then CanTripleJump = false; end;
	if CanDoubleJump then CanDoubleJump = false end;
	WallJumpForce = Vector3.zero;
	OnWall = false;
end

function Jump()
	if Character.Humanoid.FloorMaterial == Enum.Material.Air then
		if HumanoidRootPart.AssemblyLinearVelocity.Y < 30 then WallJump(); end
	end
end

Input.JumpRequest:Connect(Jump);

WallJumpBox.Touched:Connect(Wall);
WallJumpBox.TouchEnded:Connect(WallEnd);

function loop()
	while task.wait() do -- better then while true
		if Humanoid.FloorMaterial == Enum.Material.Air and OnWall and HumanoidRootPart.AssemblyLinearVelocity.Y < -5 then
			HumanoidRootPart.AssemblyLinearVelocity = 
				Vector3.new(HumanoidRootPart.AssemblyLinearVelocity.X, -5, HumanoidRootPart.AssemblyLinearVelocity.Z);
		end
		
		if Humanoid.FloorMaterial ~= Enum.Material.Air then
			CanDoubleJump = true;
			CanTripleJump = true;
		end
	end
end
task.spawn(loop)

function InputSystem(Key : InputObject)
	if Key.KeyCode == Enum.KeyCode.Q then
		Dash();
	elseif Key.KeyCode == Enum.KeyCode.Z then
		JumpDash();
	elseif Key.KeyCode == Enum.KeyCode.M then
		SuperJump();
	elseif Key.KeyCode == Enum.KeyCode.C then
		superDash();
	end
end

function Dash()
	if not CanDash then return end;
	CanDash = false;
	HumanoidRootPart.AssemblyLinearVelocity += HumanoidRootPart.CFrame.LookVector * 150;
	
	while task.wait(0.01) do
		if HumanoidRootPart.AssemblyLinearVelocity.Magnitude < 16.5 then break end
		if Humanoid.FloorMaterial ~= Enum.Material.Air then continue end
		HumanoidRootPart.AssemblyLinearVelocity *= 0.65; -- make the dash more slower while in the air
	end
	task.wait(1);
	CanDash = true;
end

function superDash()
	if not CanSuperDash then return end;
	CanSuperDash = false;
	HumanoidRootPart.AssemblyLinearVelocity += HumanoidRootPart.CFrame.LookVector * 250;

	while task.wait(0.01) do
		if HumanoidRootPart.AssemblyLinearVelocity.Magnitude < 22.5 then break end
		if Humanoid.FloorMaterial ~= Enum.Material.Air then continue end
		HumanoidRootPart.AssemblyLinearVelocity *= 0.83; -- make the dash more slower while in the air
	end
	task.wait(10);
	CanSuperDash = true;
end

function JumpDash()
	if not CanJumpDash then return end;
	CanJumpDash = false;
	HumanoidRootPart.AssemblyLinearVelocity += HumanoidRootPart.CFrame.LookVector * 150;
	HumanoidRootPart.AssemblyLinearVelocity += Vector3.new(0,50,0);
	task.wait(15);
	CanJumpDash = true;
end

function SuperJump()
	if not CanSuperJump then return end;
	CanSuperJump = false;
	HumanoidRootPart.AssemblyLinearVelocity += Vector3.new(0,100,0);
	task.wait(8);
	CanSuperJump = true;
end


Input.InputBegan:Connect(InputSystem);