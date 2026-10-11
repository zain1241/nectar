--!nonstrict
local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data
if loaded and loaded.data then
	data = loaded.data
else
	data = require(script.Parent:WaitForChild("data"))
end

local find = {
	player = game:GetService("Players").LocalPlayer;
	replicatedstorage = game:GetService("ReplicatedStorage");
}

local actives = data.actives
local toys = {}

local INTERVAL = 3661

local timerStart = tick()

local function fire(name)
	local ok, err = pcall(function()
		local events = find.replicatedstorage:FindFirstChild("Events")
		if not events then
			return
		end
		local toy = events:FindFirstChild("ToyEvent")
		if not toy then
			return
		end
		toy:FireServer(name)
	end)
	if not ok then
		warn("fireServer failed:", name, err)
		return false
	end
	return true
end

local function fireBoosters()
	fire("Field Booster")
	fire("Blue Field Booster")
	fire("Red Field Booster")
end

task.spawn(function()
	while true do
		task.wait(1)

		local elapsed = tick() - timerStart
		if elapsed >= INTERVAL then
			local fired = false

			if actives["wealth"] then
				if fire("Wealth Clock") then
					print("wealth clock fired")
				end
				fired = true
			end

			if actives["boosters"] then
				fireBoosters()
				fired = true
			end
			
			if fired then
				timerStart = tick()
			end
		end
	end
end)

function toys.wealthClock(state)
	if state ~= nil then
		actives["wealth"] = state and true or false
	end
	return actives["wealth"]
end

function toys.boosters(state)
	if state ~= nil then
		actives["boosters"] = state and true or false
	end
	return actives["boosters"]
end

return toys
