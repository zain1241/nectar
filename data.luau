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

data.mask = {
	{name = "Diamond Mask", image = "rbxassetid://2557828875"},
	{name = "Demon Mask", image = "rbxassetid://2557829605"},
	{name = "Gummy Mask", image = "rbxassetid://2557830185"},
	{name = "Bubble Mask", image = "rbxassetid://2558166299"},
	{name = "Fire Mask", image = "rbxassetid://2558167630"},
	{name = "Honey Mask", image = "rbxassetid://2558166990"},
	{name = "None", image = "rbxassetid://1554410815"},
}

data.positions = {
	{name = "center", image = "rbxassetid://15617969456"},
	{name = "left", image = "rbxassetid://15617968922"},
	{name = "right", image = "rbxassetid://15617968590"},
}

data.token_priorities = {
	-- bears
	{ name = "Black Bear", image = "rbxassetid://1472491940", priority = 149 },
	{ name = "Brown Bear", image = "rbxassetid://1442859163", priority = 149 },
	{ name = "Gummy Bear", image = "rbxassetid://1837410537", priority = 149 },
	{ name = "Mother Bear", image = "rbxassetid://2032949183", priority = 149 },
	{ name = "Panda Bear", image = "rbxassetid://1472580249", priority = 149 },
	{ name = "Polar Bear", image = "rbxassetid://1472532912", priority = 149 },
	{ name = "Science Bear", image = "rbxassetid://1489734171", priority = 149 },

	-- top tokens
	{ name = "Balloon Blessing", image = "rbxassetid://8083443467", priority = 149 },
	{ name = "Balloon", image = "rbxassetid://8045544966", priority = 149 },
	{ name = "Focus", image = "rbxassetid://1629649299", priority = 149 },
	{ name = "White Boost", image = "rbxassetid://3877732821", priority = 149 },
	{ name = "Large White Flower", image = "rbxassetid://1442836863", priority = 149 },
	{ name = "Token Link", image = "rbxassetid://1629547638", priority = 149 },
	{ name = "Blue Boost", image = "rbxassetid://1442863423", priority = 149 },
	{ name = "Baby Love", image = "rbxassetid://1472256444", priority = 149 },
	{ name = "Bubble Bloat", image = "rbxassetid://5144723635", priority = 149 },
	{ name = "Flower Flip", image = "rbxassetid://4889486022", priority = 149 },
	{ name = "Summon Frog", image = "rbxassetid://4528414666", priority = 149 },
	{ name = "Buzz Bomb Plus", image = "rbxassetid://1442764904", priority = 99  },
	{ name = "Buzz Bomb", image = "rbxassetid://1442725244", priority = 99  },
	{ name = "Honey Mark", image = "rbxassetid://2499514197", priority = 99  },
	{ name = "Pollen Mark", image = "rbxassetid://2499540966", priority = 99  },
	{ name = "Star", image = "rbxassetid://2000457501", priority = 99  },
	{ name = "Blue Sync", image = "rbxassetid://1874692303", priority = 99  },
	{ name = "Fetch", image = "rbxassetid://2319100769", priority = 99  },
	{ name = "Fuzz Bombs", image = "rbxassetid://4889308332", priority = 99  },
	{ name = "Mark Surge", image = "rbxassetid://4528379338", priority = 99  },
	{ name = "Photon", image = "rbxassetid://1671281844", priority = 99  },

		-- normal tokens
	{ name = "Sigather", image = "rbxassetid://1999448629", priority = 49 },
	{ name = "Coconut Combo", image = "rbxassetid://17362698291", priority = 49 },
	{ name = "SCPR", image = "rbxassetid://8172536505", priority = 49 },
	{ name = "Inflate Balloon", image = "rbxassetid://8083436978", priority = 49 },
	{ name = "Flame Fuel", image = "rbxassetid://4528208186", priority = 49 },
	{ name = "Inferno", image = "rbxassetid://4519549299", priority = 49 },
	{ name = "Flame Heat", image = "rbxassetid://4097473201", priority = 49 },
	{ name = "Trail", image = "rbxassetid://2553784102", priority = 49 },
	{ name = "Impale", image = "rbxassetid://2319083910", priority = 49 },
	{ name = "Tornado", image = "rbxassetid://3582519526", priority = 49 },
	{ name = "Cloud Plus", image = "rbxassetid://3809516302", priority = 49 },
	{ name = "Cloud", image = "rbxassetid://3582501342", priority = 49 },
	{ name = "Red Sync", image = "rbxassetid://1874704640", priority = 49 },
	{ name = "Rage Ability", image = "rbxassetid://1442700745", priority = 49 },
	{ name = "Red Boost", image = "rbxassetid://1442859163", priority = 49 },
}

data.drops_priorities = {
	-- eggs
	{ name = "Mythic Egg", image = "rbxassetid://4520708982", priority = 249 },
	{ name = "Star Egg", image = "rbxassetid://2007771339", priority = 249 },
	{ name = "Diamond Star Egg", image = "rbxassetid://1987257040", priority = 249 },
	{ name = "Golden Star Egg", image = "rbxassetid://1987255318", priority = 249 },
	{ name = "Silver Star Egg", image = "rbxassetid://1987253833", priority = 249 },
	{ name = "Diamond Egg", image = "rbxassetid://1436943264", priority = 249 },
	{ name = "Golden Egg", image = "rbxassetid://1436922459", priority = 249 },
	{ name = "Silver Egg", image = "rbxassetid://1436888293", priority = 249 },
	{ name = "Basic Egg", image = "rbxassetid://1436887789", priority = 29  },
	
	-- top drops
	{ name = "Star Treat", image = "rbxassetid://2028603146", priority = 199 },
	{ name = "Star Jelly", image = "rbxassetid://2319943273", priority = 199 },
	{ name = "Magic Bean", image = "rbxassetid://2529092020", priority = 199 },
	{ name = "Festive Bean", image = "rbxassetid://2676715441", priority = 199 },
	{ name = "Atomic Treat", image = "rbxassetid://4520736128", priority = 199 },
	{ name = "Super Smoothie", image = "rbxassetid://5144657109", priority = 249 },
	{ name = "Purple Potion", image = "rbxassetid://4935580111", priority = 249 },
	{ name = "Turpentine", image = "rbxassetid://8310376128", priority = 249 },
	{ name = "Caustic Wax", image = "rbxassetid://8277781666", priority = 199 },
	{ name = "Hard Wax", image = "rbxassetid://8277780065", priority = 199 },
	{ name = "Soft Wax", image = "rbxassetid://8277778300", priority = 199 },
	{ name = "Glitter", image = "rbxassetid://2542899798", priority = 249 },
	{ name = "Enzyme", image = "rbxassetid://2584584968", priority = 199 },
	{ name = "Oil", image = "rbxassetid://2545746569", priority = 199 },
	{ name = "Blue Extract", image = "rbxassetid://2495936060", priority = 199 },
	{ name = "Glue", image = "rbxassetid://2504978518", priority = 249 },
	{ name = "Moon Charm", image = "rbxassetid://2306224708", priority = 199 },
	{ name = "Festive Planter", image = "rbxassetid://8310370747", priority = 249 },
	{ name = "Night Bell", image = "rbxassetid://2676671613", priority = 249 },
	{ name = "Tropical Drink", image = "rbxassetid://3835877932", priority = 249 },
	{ name = "Neon Berry", image = "rbxassetid://4483267595", priority = 199 },
	{ name = "Bitter Berry", image = "rbxassetid://4483230719", priority = 199 },
	{ name = "Gingerbread", image = "rbxassetid://6077173317", priority = 249 },
	{ name = "Snowflake", image = "rbxassetid://6087969886", priority = 249 },
	{ name = "Ticket", image = "rbxassetid://1674871631", priority = 249 },
	{ name = "Gumdrops", image = "rbxassetid://1838129169", priority = 249 },
	{ name = "Pineapple", image = "rbxassetid://1952796032", priority = 199 },
	{ name = "Strawberry", image = "rbxassetid://1952740625", priority = 199 },
	{ name = "Sunflower Seed", image = "rbxassetid://1952682401", priority = 199 },

	-- normal drops
	{ name = "Honey Drop", image = "rbxassetid://1472108387", priority = 0 },
	{ name = "Royal Jelly", image = "rbxassetid://1471882621", priority = 0 },
	{ name = "Treat", image = "rbxassetid://2028574353", priority = 0 },
	{ name = "Ant Pass", image = "rbxassetid://2060626811", priority = 29 },
	{ name = "Spike", image = "rbxassetid://2314214749", priority = 29 },
	{ name = "Micro Converter", image = "rbxassetid://2863122826", priority = 29 },
	{ name = "MB1", image = "rbxassetid://3027672238", priority = 29 },
	{ name = "Coconut", image = "rbxassetid://3012679515", priority = 29 },
	{ name = "Cloud Vial", image = "rbxassetid://3030569073", priority = 29 },
	{ name = "Honey Suckle", image = "rbxassetid://8277901755", priority = 29 },
	{ name = "Whirligig", image = "rbxassetid://8277898895", priority = 29 },
	{ name = "Honey Token", image = "rbxassetid://1472135114", priority = 0 },
}

--name -> { image, priority }
data.priority_lookup = {}
for _, v in ipairs(data.token_priorities) do
	data.priority_lookup[v.name] = v
end
for _, v in ipairs(data.drops_priorities) do
	data.priority_lookup[v.name] = v
end

data.actives = {
	--unit
	auto_farm = false,
	sprinkler = false,
	dig = false,
	
	move = false,
	convert = false,
	
	field = "Blue Flower Field",
	position_field = "center",
	
	--field
	bubble = false,
	bubble_priority = 1,
	no_priotiy_field = false,
	no_priority_drops = false,
	
	--converting honey
	honey_mask = false,
	balloon = false,
	backpack = 80,
	mask = "None",
	convert_interval = 15,
	
	--settings global
	anti_afk = true,
	walkspeed = 40,
	
	--utils
	auto_hive = true,
	fast_run = true,
	hive_choice = "Random",
	last_time_convert = 0,
	
	--other settings
	script_name = "Nectar 0005",
	position_script = UDim2.new(0.22, 0, 0.5, 0),
}

return data
