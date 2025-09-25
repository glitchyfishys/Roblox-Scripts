--[[ made by
	 ¦¦¦¦¦¦+ ¦¦+     ¦¦+¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦+¦¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+
	¦¦+----+ ¦¦¦     ¦¦¦+--¦¦+--+¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+¦¦¦¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+
	¦¦¦  ¦¦¦+¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦+  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦¦¦+
	¦¦¦   ¦¦¦¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦+--¦¦¦  +¦¦++  ¦¦+--+  ¦¦¦+----¦¦¦¦¦+--¦¦¦  +¦¦++  +----¦¦¦
	+¦¦¦¦¦¦++¦¦¦¦¦¦¦+¦¦¦   ¦¦¦   +¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦¦
	 +-----+ +------++-+   +-+    +-----++-+  +-+   +-+   +-+     +-++------++-+  +-+   +-+   +------+
]]

Data = {
	Movement = require(script.Parent),
	MaxHeathByPass = false,
}

script:Destroy(); -- exploiters will have no idea.

--IsStudio = game["Run Service"]:IsStudio();

_G.Melee= require(game.ReplicatedStorage.Classes.Melee);
_G.Gun = require(game.ReplicatedStorage.Classes.Gun);
_G.Ability = require(game.ReplicatedStorage.Classes.Ability);
_G.Enum = require(game.ReplicatedStorage.Enum);

Events = {
	MaxHealth = game.ReplicatedStorage["AC Events"].MaxHealth,
}

--game.ReplicatedStorage["AC Events"]:Destroy();
game.ReplicatedStorage.Classes:Destroy();

-- this will break your game if you use names like, workspace.Part.
-- use game:GetService('Players') instead of game.Players.

function HASH() -- this will make the Explorer unable to search and break most scripts.
	for i, thing in ipairs(game:GetDescendants()) do
		pcall(function() -- somethings can't be changed and will cause errors if we try to change them.
			if thing.Parent.Name ~= game.Players.LocalPlayer.Name then
				if thing:IsA('Script') or thing:IsA('LocalScript') or thing:IsA('ModuleScript') then -- Handle must be unchanged.
					thing.Name = "";
				end
			end
		end)
		if i % 33 == 0 then -- don't freeze or slow the game.
			task.wait();
		end
	end
end

-- this is a fake value to make it harder to find the real one.
local L = Instance.new('IntValue', game.Players.LocalPlayer);
L.Name = "TimesCheated";


SentenalCount = 0;
SentenalDrain = 1;

if true then -- silly thing we can do
	local UI = game.Players.LocalPlayer.PlayerGui;
	local TimesCheated = 0;
	
	L:GetPropertyChangedSignal("Value"):Connect(function()
		TimesCheated += 1;
		HASH();
	end)
	
	local YMin = Vector3.new(-math.huge, 0, -math.huge);
	local YMax = Vector3.new(math.huge, 0, math.huge);
	
	local BanedStates = {
		Enum.HumanoidStateType.StrafingNoPhysics, -- no clip
		Enum.HumanoidStateType.Flying, -- i wonder what this could mean
		Enum.HumanoidStateType.Swimming,
		Enum.HumanoidStateType.RunningNoPhysics,
		Enum.HumanoidStateType.PlatformStanding,
		Enum.HumanoidStateType.Ragdoll,
	}
	
	local function Added(Car : Model)
		local Hum = Car:FindFirstChildWhichIsA('Humanoid');
		if Hum then
			
			Hum.RequiresNeck = false;
			Hum:GetPropertyChangedSignal('WalkSpeed'):Connect(function() -- add sprinting here
				if (Data.Movement.WalkSpeedByPass) then
					Data.Movement.WalkSpeedByPass = false;
					return;
				end;
				TimesCheated += 1;
				Hum.WalkSpeed = 16; -- 16 or watever the default is.
				print("Walk Speed Changed");
			end);
			Hum:GetPropertyChangedSignal('JumpPower'):Connect(function()
				if (Data.Movement.JumpHeightByPass) then
					Data.Movement.JumpHeightByPass = false;
					return;
				end;
				TimesCheated += 1;
				Hum.JumpPower = 50;
				print("Jump Power Changed");
			end);
			Hum:GetPropertyChangedSignal('JumpHeight'):Connect(function()
				if (Data.Movement.JumpHeightByPass) then
					Data.Movement.JumpHeightByPass = false;
					return;
				end;
				TimesCheated += 1;
				Hum.JumpPower = 7.2;
				print("Jump Hight Changed");
			end);
			
			local MaxHealthByPass = 0;
			
			local MHChanged = Events.MaxHealth.OnClientEvent:Connect(function(NewSentenal : boolean, diff : number, ID : number)
				SentenalDrain = diff;
				MaxHealthByPass += 1;
				if NewSentenal then
					SentenalCount += 1;
					Events.MaxHealth:FireServer(true, ID);
				else
					SentenalCount -= 1;
					Events.MaxHealth:FireServer(false, ID);
				end
			end)
			
			Hum:GetPropertyChangedSignal('MaxHealth'):Connect(function() -- need to add a case for sentenals
				if MaxHealthByPass > 0 then -- multiple Sentenals can be active at once
					print("Max Health Changed by Sentenal");
					MaxHealthByPass -= 1;
					return;
				end
				TimesCheated += 1;
				Hum.MaxHealth = 100 * SentenalDrain ^ SentenalCount;
				print("Max Health Changed");
			end);
			
			Hum.StateChanged:Connect(function(Old, New) -- may slow the game
				if table.find(BanedStates, New) then
					TimesCheated += 1;
					Hum:ChangeState(Old);
					print("Banned state: "..New);
				end
			end)
			
		end
		
		-- you have god mode without a humanoid
		Car.ChildRemoved:connect(function(Obj)
			if Obj:IsA("Humanoid") then
				local I = Instance.new('Humanoid', Car);
				TimesCheated += 1;
				task.delay(0.25, function() I.Health = 0 end);
				print("Destroyed Humanoid");
			end
		end)
		
		--Car.ChildAdded:connect(function(Obj)
		--	if Obj:IsA("HopperBin") then -- some tool or something
		--		TimesCheated += 1;
		--		Obj:Destroy();
		--		print("Whats a HopperBin?")
		--	end
		--end)
		
	end
	
	if game.Players.LocalPlayer.Character then -- if its allready loaded
		Added(game.Players.LocalPlayer.Character);
	end
	game.Players.LocalPlayer.CharacterAdded:Connect(Added);
	
	task.wait(1.5);
	task.spawn(HASH);
	
	while true do
		if TimesCheated > 9 then
			print("Get Kicked LOL")
			game:GetService('Players').LocalPlayer:Kick('My System Believes you have been cheating,\n Contact me "glitchyfishys" and/or the game owner if you were not. (player side)');
			break
		end
		task.wait(0.5);
	end
	
end
