--!nonstrict
-- Nectar Client Loader — optimized

local env = (getgenv and getgenv()) or _G

local loaded = rawget(env, "__NECTAR_MODULES")
local data, farming, menu, convert, movement, utils, toys

if loaded and loaded.data and loaded.farming and loaded.menu and loaded.convert and loaded.movement and loaded.utils and loaded.toys then
	data, farming, menu, convert, movement, utils, toys = loaded.data, loaded.farming, loaded.menu, loaded.convert, loaded.movement, loaded.utils, loaded.toys
else
	data = require(script:WaitForChild("data"))
	farming = require(script:WaitForChild("farming"))
	menu = require(script:WaitForChild("menu"))
	convert = require(script:WaitForChild("convert"))
	movement = require(script:WaitForChild("movement"))
	utils = require(script:WaitForChild("utils"))
	toys = require(script:WaitForChild("toys"))
end

assert(type(data) == "table" and type(data.actives) == "table", "client: data not loaded")
assert(type(farming) == "table", "client: farming not loaded")
assert(type(menu) == "table" and type(menu.client_menu) == "function", "client: menu.client_menu not loaded")
assert(type(convert) == "table", "client: convert not loaded")
assert(type(movement) == "table", "client: movement not loaded")
assert(type(utils) == "table", "client: utils not loaded")
assert(type(toys) == "table", "client: toys not loaded")

-- Cached services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Cached functions
local jsonEncode = HttpService.JSONEncode
local jsonDecode = HttpService.JSONDecode
local writefile = writefile
local readfile = readfile
local isfile = isfile
local random = math.random
local task_wait = task.wait
local task_spawn = task.spawn
local pcall = pcall

local CONFIG_FILE = "Nectar_config.json"

local actives = data.actives

local function saveConfig()
	if not writefile then return end

	local saveActives = {}
	for key, value in pairs(actives) do
		if key ~= "script_name" and key ~= "position_script" then
			saveActives[key] = value
		end
	end

	local ok, encoded = pcall(jsonEncode, HttpService, { actives = saveActives })
	if ok then
		pcall(writefile, CONFIG_FILE, encoded)
	end
end

local function loadConfig()
	if not isfile or not readfile then return end
	if not isfile(CONFIG_FILE) then return end

	local ok, content = pcall(readfile, CONFIG_FILE)
	if not ok or not content or content == "" then return end

	local ok2, decoded = pcall(jsonDecode, HttpService, content)
	if not ok2 or type(decoded) ~= "table" then return end

	local saved = decoded.actives
	if type(saved) == "table" then
		for key, value in pairs(saved) do
			if key ~= "script_name" and key ~= "position_script" then
				actives[key] = value
			end
		end
	end
end

loadConfig()
env.__NECTAR_SAVE = saveConfig

local mod = {
	data = data,
	farming = farming,
	menu = menu,
	convert = convert,
	movement = movement,
	utils = utils,
	toys = toys,
	save = saveConfig,
}

local WALKSPEED_KEY = "walkspeed"

local function characterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	humanoid.WalkSpeed = actives[WALKSPEED_KEY]
end

local ok, err = xpcall(menu.client_menu, debug.traceback)
if not ok then
	warn("er create menu:\n" .. tostring(err))
end

local playerCharacter = LocalPlayer.Character
if playerCharacter then
	task_spawn(characterAdded, playerCharacter)
end

LocalPlayer.CharacterAdded:Connect(characterAdded)

local prevConn = env.__NECTAR_ANTI_AFK_CONN
if prevConn then
	pcall(function() prevConn:Disconnect() end)
	env.__NECTAR_ANTI_AFK_CONN = nil
end

local ANTI_AFK_KEY = "anti_afk"
local JIGGLE_KEYS = { Enum.KeyCode.LeftShift, Enum.KeyCode.LeftControl, Enum.KeyCode.Tab }
local JIGGLE_N = #JIGGLE_KEYS
local LEFT_SHIFT = Enum.KeyCode.LeftShift
local emptyVec = Vector2.new()

local function jiggle()
	local dx = random(-3, 3)
	local dy = random(-3, 3)
	VirtualUser:SendMouseMoveEvent(dx, dy, true, game)
	task_wait(0.05)
	VirtualUser:SendMouseMoveEvent(-dx, -dy, true, game)
	task_wait(0.05)

	local key = JIGGLE_KEYS[random(JIGGLE_N)]
	VirtualUser:SendKeyEvent(true, key, false, game)
	task_wait(0.05)
	VirtualUser:SendKeyEvent(false, key, false, game)
end

env.__NECTAR_ANTI_AFK_CONN = LocalPlayer.Idled:Connect(function()
	if actives[ANTI_AFK_KEY] ~= true then return end

	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(emptyVec)
	end)
	task_wait(0.1)

	pcall(function()
		VirtualUser:SendMouseMoveEvent(random(-5, 5), random(-5, 5), true, game)
	end)
	task_wait(0.1)

	pcall(function()
		VirtualUser:SendKeyEvent(true, LEFT_SHIFT, false, game)
		task_wait(0.05)
		VirtualUser:SendKeyEvent(false, LEFT_SHIFT, false, game)
	end)
end)

if not env.__NECTAR_ANTI_AFK_WORKER then
	env.__NECTAR_ANTI_AFK_WORKER = true

	task_spawn(function()
		while LocalPlayer.Parent do
			task_wait(45)
			if actives[ANTI_AFK_KEY] == true then
				pcall(jiggle)
			end
		end
		env.__NECTAR_ANTI_AFK_WORKER = false
	end)
end

if writefile then
	task_spawn(function()
		while task_wait(10) do
			saveConfig()
		end
	end)
end

return mod
