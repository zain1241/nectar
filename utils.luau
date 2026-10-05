--!nonstrict
local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data, farming
if loaded and loaded.data and loaded.farming then
	data = loaded.data
	farming = loaded.farming
else
	data = require(script.Parent:WaitForChild("data"))
end

local mod = { data = data, farming = farming }
local actives = data.actives

local find = {
	players = game:GetService("Players");
	player = game:GetService("Players").LocalPlayer;
	prerender = game:GetService("RunService").PreRender;
}

local utils = {}

return utils
