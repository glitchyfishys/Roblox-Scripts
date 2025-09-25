--[[ made by
	 ¦¦¦¦¦¦+ ¦¦+     ¦¦+¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦+¦¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+
	¦¦+----+ ¦¦¦     ¦¦¦+--¦¦+--+¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+¦¦¦¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+
	¦¦¦  ¦¦¦+¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦+  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦¦¦+
	¦¦¦   ¦¦¦¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦+--¦¦¦  +¦¦++  ¦¦+--+  ¦¦¦+----¦¦¦¦¦+--¦¦¦  +¦¦++  +----¦¦¦
	+¦¦¦¦¦¦++¦¦¦¦¦¦¦+¦¦¦   ¦¦¦   +¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦¦
	 +-----+ +------++-+   +-+    +-----++-+  +-+   +-+   +-+     +-++------++-+  +-+   +-+   +------+
]]

local Down = CFrame.lookAt(Vector3.new(0,1,0), Vector3.zero).LookVector;
local FrameCounter = 0;

local VECNEG = Vector3.new(5000,5000,5000) * -1;
local VEC = Vector3.new(5000,5000,5000);

local MD = {};

game.Players.PlayerRemoving:Connect(function(Player)
	MD[Player.UserId] = nil;
end)

game["Run Service"].Heartbeat:Connect(function()
	FrameCounter += 1;
	if FrameCounter % 5 == 0 then -- change the rate the anti cheat works
		local plrs = game.Players:GetPlayers();
		
		for _, p in ipairs(plrs) do
			if MD[p.UserId] == nil then
				MD[p.UserId] = {};
				MD[p.UserId].Fly = 0;
				MD[p.UserId].Fling = 0;
				MD[p.UserId].Cheats = 0;
			end
			local car = p.Character;
			
			if car then
				local hrp : Part = car:FindFirstChild("HumanoidRootPart");
				local hum : Humanoid = car:FindFirstChild("Humanoid");
				
				if hum.Health <= 0 then continue end;
				
				if hrp then
					-- check if they are moving really fast
					if math.abs(hrp.AssemblyLinearVelocity.Y) > 1050 then -- i could make this client side but who cares
						MD[p.UserId].Fling += 1;
						if MD[p.UserId].Fling > 3 then
							hrp.AssemblyLinearVelocity = Vector3.min(hrp.AssemblyLinearVelocity, VEC);
							hrp.AssemblyLinearVelocity = Vector3.max(hrp.AssemblyLinearVelocity, VECNEG);
							MD[p.UserId].Cheats += 1;
							print("speed name: "..p.Name.." id: "..p.UserId);
						end
					end
					-- check if they are flying
					if math.abs(hrp.AssemblyLinearVelocity.Y) < 0.001 then -- could just be standing still
						local Parms = RaycastParams.new();
						Parms.RespectCanCollide = true;
						Parms.FilterDescendantsInstances = {hrp.Parent};
						
						local RC = workspace:Raycast(hrp.Position, Down * 3, Parms); -- over 3 studs then they are flying
						local RCF = workspace:Raycast(hrp.Position + hrp.CFrame.LookVector, Down * 3, Parms); -- over 3 studs then they are flying
						local RCB = workspace:Raycast(hrp.Position - hrp.CFrame.LookVector, Down * 3, Parms); -- over 3 studs then they are flying
						
						local RCL = workspace:Raycast(hrp.Position + ((hrp.CFrame * CFrame.new(Vector3.one, Vector3.new(math.rad(-90)))).LookVector), Down * 3, Parms); -- over 3 studs then they are flying
						local RCR = workspace:Raycast(hrp.Position + ((hrp.CFrame * CFrame.new(Vector3.one, Vector3.new(math.rad(90)))).LookVector), Down * 3, Parms); -- over 3 studs then they are flying
						
						if RC or RCF or RCB or RCL or RCR then
							--they should be fine if they jumped
							MD[p.UserId].Fly = 0;
						else
							MD[p.UserId].Fly += 1;
							if MD[p.UserId].Fly > 5 then -- could have been lag
								MD[p.UserId].Fly = 0;
								MD[p.UserId].Cheats += 1;
								print("flying name: "..p.Name.." id: "..p.UserId);
							end
						end
						
					end
					
					local raycastParams = RaycastParams.new();
					raycastParams.FilterDescendantsInstances = {p.Character};
					
					-- just check forward and backwards
					local F = workspace:Raycast(hrp.CFrame.Position, hrp.CFrame.LookVector * 0.42, raycastParams);
					local B = workspace:Raycast(hrp.CFrame.Position, hrp.CFrame.LookVector * -0.42, raycastParams);
					
					if F and F.Instance.CanCollide then
						MD[p.UserId].Cheats += 1;
						print("flying name: "..p.Name.." id: "..p.UserId);
					elseif B and B.Instance.CanCollide then
						MD[p.UserId].Cheats += 1;
						print("flying name: "..p.Name.." id: "..p.UserId);
					end
					
				end
				
			end
			
			if MD[p.UserId].Cheats > 9 then
				p:Kick('My System Believes you have been cheating,\n Contact me "glitchyfishys" and/or the game owner if you were not. (server side)');
			end
			
		end
		
	end
end)

