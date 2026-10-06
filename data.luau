local data = {}

data.zones = {
	{name = "Ant Field", image = "rbxassetid://15617807338"},
	{name = "Bamboo Field", image = "rbxassetid://15617807109"},
	{name = "Blue Flower Field", image = "rbxassetid://15617806925"},
	{name = "Cactus Field", image = "rbxassetid://15617806727"},
	{name = "Clover Field", image = "rbxassetid://15617806641"},
	{name = "Coconut Field", image = "rbxassetid://15617838168"},
	{name = "Dandelion Field", image = "rbxassetid://15617826387"},
	{name = "Mountain Top Field", image = "rbxassetid://15617806273"},
	{name = "Mushroom Field", image = "rbxassetid://15617806189"},
	{name = "Pepper Patch", image = "rbxassetid://15617806096"},
	{name = "Pine Tree Forest", image = "rbxassetid://15617805993"},
	{name = "Pineapple Patch", image = "rbxassetid://15617805930"},
	{name = "Pumpkin Patch", image = "rbxassetid://15617805864"},
	{name = "Rose Field", image = "rbxassetid://15617805712"},
	{name = "Spider Field", image = "rbxassetid://15617806534"},
	{name = "Strawberry Field", image = "rbxassetid://15617805499"},
	{name = "Stump Field", image = "rbxassetid://15617805381"},
	{name = "Sunflower Field", image = "rbxassetid://15617805255"},
}

data.actives = {
	--unit
	auto_farm = false,
	sprinkler = false,
	dig = false,
	
	move = false,
	convert = false,
	
	field = "Blue Flower Field",
	position_field = "center",
	
	--converting honey
	honey_mask = false,
	balloon = false,
	backpack = 80,
	mask = "None",
	
	--settings global
	anti_afk = true,
	walkspeed = 40,
	
	--utils
	auto_hive = true,
	hive_choice = "Random",
	last_time_convert = 0,
	
	--other settings
	script_name = "Nectar 0004",
	position_script = UDim2.new(0.22, 0, 0.5, 0),
}

return data
