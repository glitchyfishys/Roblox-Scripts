local Ability = {};


local Code = ""; -- this can help reduce cheating
-- change the seed every release of the game
local Rand = Random.new(math.pi);
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

local Data = {
	CoolDown = 0,
	LastTick = 0,
	Name = "Cool Ability Name",
	UseButton = Enum.UserInputType.MouseButton1,
	
	Tick = function(self)
		self.CoolDown -= os.clock() - self.LastTick;
		
		self.LastTick = os.clock();
	end,
	
	TimeLeft = function(self)
		return self.CoolDown;
	end,
}

function Ability.new()
	local Class = setmetatable(table.clone(Data), Ability);

	return Class;
end

return Ability;
