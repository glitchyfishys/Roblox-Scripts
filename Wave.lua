--[[ made by
	 ¦¦¦¦¦¦+ ¦¦+     ¦¦+¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦+¦¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+
	¦¦+----+ ¦¦¦     ¦¦¦+--¦¦+--+¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+¦¦¦¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+
	¦¦¦  ¦¦¦+¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦+  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦¦¦+
	¦¦¦   ¦¦¦¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦+--¦¦¦  +¦¦++  ¦¦+--+  ¦¦¦+----¦¦¦¦¦+--¦¦¦  +¦¦++  +----¦¦¦
	+¦¦¦¦¦¦++¦¦¦¦¦¦¦+¦¦¦   ¦¦¦   +¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦¦
	 +-----+ +------++-+   +-+    +-----++-+  +-+   +-+   +-+     +-++------++-+  +-+   +-+   +------+
]]

local Wave = {};
local Rand = Random.new();

local EnemeyPath = game.ServerStorage.Gameplay.Enemies;
local SpawnPath = workspace["@Enemies"].Enemies;

-- add 
local function PartPos(s)
	local minX = s.position.X - s.size.X/2
	local maxX = s.position.X + s.size.X/2

	local minZ = s.position.Z - s.size.Z/2
	local maxZ = s.position.Z + s.size.Z/2

	local RX = Rand:NextInteger(minX, maxX);
	local RZ = Rand:NextInteger(minZ, maxZ);
	
	return Vector3.new(RX, 6, RZ);
end

local function deepClone(original)
	local clone = table.clone(original);
	for key, value in original do
		if type(value) == "table" then
			clone[key] = deepClone(value);
		end
	end
	return clone;
end




local data = {
	Wave = 1,
	OnlyUseLargeSpawnPoints = false,
	
	--[[
		store wave info here
		{
			Name = 'name',
			Amount = 5
		}
	]]
	Enemies = {
		
	},
	-- store parts here
	SpawnPoints = {
	
	},
	
	-- store modals here
	LargeEnemies = {
	
	},
	
	Bosses = {

	},
	
	-- store parts here
	LargeSpawnPoints = {
	
	},
	
	MaxOnField = 10,
	MinForMore = 5,
	
	Spawn = function(self, max : number)
		max = max or 0;
		if #self.SpawnPoints == 0 then
			warn('No Set SpawnPoint(s)');
			return false;
		end
		
		if not self.OnlyUseLargeSpawnPoints then
			if self.Enemies == nil or self.LargeEnemies == nil then return warn('No Enemies to spawn') end;
			while #self.Enemies > 0 do
				for _, s in self.SpawnPoints do -- do you want them to spawn evenly or in groups?
				local ID = Rand:NextInteger(1, #self.Enemies);
				local Enemy : Model = self.Enemies[ID];

				if Enemy then
						print(Enemy, self.Enemies)
					local E = EnemeyPath[Enemy.Name]:Clone();
					E.Parent = SpawnPath;
					E:PivotTo(CFrame.new(PartPos(s)));
				end
				
				Enemy.Amount -= 1;
				max -= 1;
				if Enemy.Amount == 0 then table.remove(self.Enemies, ID); end -- remove from list
				if #self.Enemies == 0 or max == 0 then break end;
				end
			end
		
		end
		
		if #self.LargeSpawnPoints == 0 then
			warn('No Set LargeSpawnPoint(s)');
			return false;
		end
		
		while #self.LargeEnemies > 0 or (self.OnlyUseLargeSpawnPoints and #self.Enemies > 0) do
			for _, s in self.LargeSpawnPoints do
				
				if #self.LargeEnemies == 0 and self.OnlyUseLargeSpawnPoints then
					local ID = Rand:NextInteger(1, #self.Enemies);
					local Enemy : Model = self.Enemies[ID];

					if Enemy then
						local E = EnemeyPath[Enemy.Name]:Clone();
						E.Parent = SpawnPath;
						E:PivotTo(CFrame.new(PartPos(s)));
					end

					max -= 1;
					Enemy.Amount -= 1;
					if Enemy.Amount == 0 then table.remove(self.Enemies, ID); end -- remove from list
				else
					local ID = Rand:NextInteger(1, #self.LargeEnemies);
					local Enemy : Model = self.LargeEnemies[ID];
					
					if Enemy then
						local E = EnemeyPath[Enemy.Name]:Clone(); 
						E.Parent = SpawnPath;
						E:PivotTo(CFrame.new(PartPos(s) + Vector3.new(0,10,0)));
					end
					
					max -= 1;
					Enemy.Amount -= 1;
					if Enemy.Amount == 0 then table.remove(self.LargeEnemies, ID); end -- remove from list
				end
				
				if (#self.LargeEnemies == 0 and #self.Enemies == 0) or max == 0 then break end;
			end
		end
		
		return true;
	end,
}

function Wave.new()
	local Class = setmetatable(data, Wave);
	
	return Class;
end

return Wave;
