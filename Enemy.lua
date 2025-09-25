--[[ made by
	 ¦¦¦¦¦¦+ ¦¦+     ¦¦+¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦+¦¦¦¦¦¦¦+¦¦+  ¦¦+¦¦+   ¦¦+¦¦¦¦¦¦¦+
	¦¦+----+ ¦¦¦     ¦¦¦+--¦¦+--+¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+¦¦¦¦¦+----+¦¦¦  ¦¦¦+¦¦+ ¦¦++¦¦+----+
	¦¦¦  ¦¦¦+¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦+  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦¦¦¦¦+
	¦¦¦   ¦¦¦¦¦¦     ¦¦¦   ¦¦¦   ¦¦¦     ¦¦+--¦¦¦  +¦¦++  ¦¦+--+  ¦¦¦+----¦¦¦¦¦+--¦¦¦  +¦¦++  +----¦¦¦
	+¦¦¦¦¦¦++¦¦¦¦¦¦¦+¦¦¦   ¦¦¦   +¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦¦
	 +-----+ +------++-+   +-+    +-----++-+  +-+   +-+   +-+     +-++------++-+  +-+   +-+   +------+
]]

local Enemy = {} -- only use on the server

local PathFinding = require(script.Pathfinding);
Enemy.Enum = {
	PathfindingType = {
		Melee = 1,
		Sniper = 2,
		Strafe = 3,
		RandomPoint = 4,
		MoveAway = 5,
	}
};

local function deepClone(original)
	local clone = table.clone(original);
	for key, value in original do
		if type(value) == "table" then
			clone[key] = deepClone(value);
		end
	end
	return clone;
end

local Data = {
	Health = 100,
	MaxHealth = 100,
	Shield = 0,
	MaxShield = 0,
	Damage = 100, -- use gun?
	AttackSpeed = 1, -- time it takes to attack
	AttackRange = 10, -- distance
	MoveSpeed = 10, -- distance per tick
	MoveRange = 100, -- distance from player
	IsStunned = false, -- cant be move
	IsBlocking = false, -- cant be attacked
	IsAttacking = false,
	IsMoving = false,
	AlwaysPointToTarget = true,
	PathfindType = Enemy.Enum.PathfindingType.Melee,
	
	-- adds humanoid automatically if it has one (Modal.Humanoid)
	HitBoxPoints = {
	
	},
	
	
	-- if a enemy has multiple hitbox points then the damage gets split between them
	EvenDamage = true,
	-- if a enemy has multiple hitbox points then you only need to destroy some of them
	DestroyXPointsToKill = 1,
	
	TotalHealth = function(self)
		local total = 0;
		for _, HBP in self.HitBoxPoints do
			if self.EvenDamage then
				total += HBP.Health; -- humanoids can have negitive health
			else
				total += math.max(HBP.Health, 0);
			end
		end
		return total;
	end,
	
	TotalMaxHealth = function(self)
		local total = 0;
		for _, HBP in self.HitBoxPoints do
			if self.EvenDamage then
				total += HBP.MaxHealth;
			else
				total += math.max(HBP.MaxHealth, 0);
			end
		end
		return total;
	end,
	
	IsDead = function(self) -- use this to check if the enemy is dead
		local count = 0;
		for _, HBP in self.HitBoxPoints do
			if HBP.Health <= 0 then
				count += 1;
			end
		end
		
		return count >= self.DestroyXPointsToKill;
	end,
	
	Pathfind = function(self)
		if self.IsStuned then return end;
		
		--debug.profilebegin('Pathfind '..self.Name); -- The Path:ComputeAsync breaks this for some reason
		
		if self.PathfindType == Enemy.Enum.PathfindingType.Melee then
			self.Path:TargetOrInRange();
		elseif self.PathfindType == Enemy.Enum.PathfindingType.Sniper then
			self.Path:Sniper();
		elseif self.PathfindType == Enemy.Enum.PathfindingType.RandomPoint then
			self.Path:GoToRandomPoint();
		elseif self.PathfindType == Enemy.Enum.PathfindingType.Strafe then
			self.Path:Strafe();
		elseif self.PathfindType == Enemy.Enum.PathfindingType.MoveAway then
			self.Path:MoveAwayFrom();
		else
			self.Path:TargetOrInRange();
		end
		
		--debug.profileend();
		
		if self.AlwaysPointToTarget then self.Path:PointToPlayer(); end;
	end,
	
}

function Enemy.New(Name : string, Modal : Model, MultiHumanoid : boolean?, DontSetOwner : boolean) -- make a new Enemy

	local Class = setmetatable(deepClone(Data), Enemy); -- base data and config
	Class.Name = Name or 'You forgot to name the enemy';
	
	if not Modal.PrimaryPart.Anchored and not DontSetOwner then -- can't use anchored models here
		for _, p in ipairs(Modal:GetDescendants()) do
			if p:IsA('Part') then
				p:SetNetworkOwner(nil); -- fixes some jittering
			end
		end
	end
	
	local HD = Modal:FindFirstChild('Humanoid');
	if HD and not MultiHumanoid then
		table.insert(Class.HitBoxPoints, HD);
	end
	
	Class.Path = PathFinding.new();  -- there is some quantum entanglement if this is used wrong
	Class.Path.Me = Modal;
	Class.Path.Target = workspace.Target;
	
	return Class;
end

return Enemy


--[[
	----- NOTES -----
	A multi humanoid enemy is a modal with multiple humanoids and you need to hit all of them or any of them to kill the enemy.
	For even speading out damage, humanoids must have a Neck or requires neck disabled.
	Use TotalHealth, TotalMaxHealth and/or IsDead to check if it is dead the way you want it to be.
	
	
]]