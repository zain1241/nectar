--!nonstrict
local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data, movement, farming
if loaded and loaded.data and loaded.movement and loaded.farming then
	data = loaded.data
	movement = loaded.movement
	farming = loaded.farming
else
	data = require(script.Parent:WaitForChild("data"))
	movement = require(script.Parent:WaitForChild("movement"))
end

local mod = { data = data, movement = movement }
local actives = data.actives

local find = {
	players = game:GetService("Players");
	player = game:GetService("Players").LocalPlayer;
	prerender = game:GetService("RunService").PreRender;
	contextactionservice = game:GetService("ContextActionService");
	random = Random.new();
}

local convert = {}
local noCollision, aconvert

function convert.conAF(...)
	local a = {...}
	local interval = 1 / a[2]
	local accumulated = 0

	return a[1]:Connect(function(delta)
		accumulated += delta
		if accumulated < interval then
			return
		end
		local elapsed = accumulated
		accumulated %= interval

		a[3](elapsed)
	end)
end

function convert.noClip(...)
	local a = {...}

	local parts = {
		HumanoidRootPart = true,
		UpperTorso = true,
		LowerTorso = true,
	}

	if a[1] then
		noCollision = convert.conAF(
			find.prerender, 4,
			function()
				local c = find.player.Character
				if not c then return end
				for _, v in ipairs(c:GetDescendants()) do
					if parts[v.Name] and v:IsA("BasePart") then
						v.CanCollide = false
					end
				end
			end
		)
	else
		if noCollision then
			noCollision:Disconnect()
			noCollision = nil
		end
		local character = find.player.Character
		if character then
			for _, v in ipairs(character:GetChildren()) do
				if parts[v.Name] and v:IsA("BasePart") then
					v.CanCollide = true
				end
			end
		end
	end
end

function convert.control(...)
	local a = {...}
	local humanoid = find.player.Character:FindFirstChildOfClass("Humanoid")
	local function block(...)
		return Enum.ContextActionResult.Sink
	end

	if a[1] == true then
		find.contextactionservice:BindActionAtPriority("BlockPlayerMovement", block, false, Enum.ContextActionPriority.High.Value + 1, Enum.PlayerActions.CharacterForward,
			Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
		if humanoid then
			humanoid.Jump = false; humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
	else
		find.contextactionservice:UnbindAction("BlockPlayerMovement")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end
end

local function getStats(...)
	local a = {...}
	local humanoid = find.player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	if not events then
		return nil
	end

	local ok, result = pcall(function()
		return events:WaitForChild("RetrievePlayerStats"):InvokeServer()
	end)

	if ok and type(result) == "table" then
		return result
	end
	return nil
end

function convert.getHive()
	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local honeycombs = workspace:FindFirstChild("Honeycombs")

	if not humanoid or not honeycombs then
		return nil, nil
	end

	for _, hive in ipairs(honeycombs:GetChildren()) do
		local owner = hive:FindFirstChild("Owner")
		if owner then
			local value = owner.Value
			if value == find.player.Name or value == find.player then
				local spawnPos = hive:FindFirstChild("SpawnPos")
				local hiveID = hive:FindFirstChild("HiveID")

				local pos = nil
				if spawnPos then
					if spawnPos:IsA("BasePart") then
						pos = spawnPos.Position
					elseif spawnPos:IsA("CFrameValue") then
						pos = spawnPos.Value.Position
					elseif spawnPos:IsA("Attachment") then
						pos = spawnPos.WorldPosition
					elseif spawnPos:IsA("Vector3Value") then
						pos = spawnPos.Value
					end
				end

				local id = hiveID and hiveID.Value or nil
				return pos, id
			end
		end
	end

	return nil, nil
end

print("load3")

function convert.autoHive(...)
	print(333)

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local honeycombs = workspace:FindFirstChild("Honeycombs")
	
	print(534534)

	if not humanoid or not root or not honeycombs then
		return
	end
	
	print("4")

	actives["convert"] = false

	convert.noClip(false)
	convert.control(false)
	
	local hivePos, hiveID = convert.getHive()
	if hivePos then
		print(1)
		movement.move("hive", actives["walkspeed"], hivePos, function()
			task.wait(1)
			convert.convert()
		end, hiveID)
		return
	end
	
	print(5)
	
	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local claimHive = events and events:FindFirstChild("ClaimHive")

	if not claimHive then
		warn("not claimHive")
		return
	end
	
	print(6)

	local hiveChoice = actives["hive_choice"] or "Random"
	local targetHiveId

	if hiveChoice == "Random" then
		targetHiveId = find.random:NextInteger(1, 6)
	end

	local ok, err = pcall(function()
		claimHive:FireServer(targetHiveId)
	end)

	if not ok then
		warn("claimHive failed:", err)
		return
	end
	
	local newPos, newId
	for _ = 1, 20 do
		task.wait(0.25)
		newPos, newId = convert.getHive()
		if newPos then
			break
		end
	end

	if not newPos then
		warn("not hive (id:", targetHiveId, ")")
		return
	end
	
	print(newPos)
	
	movement.move("hive", actives["walkspeed"], newPos, function()
		task.wait(1)
		convert.convert()
		print(7)
	end, newId)
end

function convert.get_pollen_info()
	local pg = find.player:FindFirstChild("PlayerGui")
	if not pg then return nil end

	local screenGui = pg:FindFirstChild("ScreenGui")
	local meterHud = screenGui and screenGui:FindFirstChild("MeterHUD")
	local pollenMeter = meterHud and meterHud:FindFirstChild("PollenMeter")
	local bar = pollenMeter and pollenMeter:FindFirstChild("Bar")
	local label = bar and bar:FindFirstChild("TextLabel")

	if not label or not label:IsA("TextLabel") then return nil end

	local current, max = string.match(label.Text, "([%d,]+)/([%d,]+)")
	if not current or not max then return nil end

	current = tonumber((string.gsub(current, ",", ""))) or 0
	max = tonumber((string.gsub(max, ",", ""))) or 0

	if max <= 0 then return nil end

	return {
		pollen = current,
		max = max,
		percent = (current / max) * 100,
	}
end

function convert.convert(...)
	local a = {...}
	
	if actives["honey_mask"] then
		convert.honey_mask()
		task.wait(.5)
	end
	
	local humanoid = find.player.Character:FindFirstChildOfClass("Humanoid")
	local root = find.player.Character:FindFirstChild("HumanoidRootPart")
	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local hiveCommand = events and events:FindFirstChild("PlayerHiveCommand")
	
	if not humanoid or not root then
		actives["convert"] = false
		actives["move"] = false
		return
	end
	
	if not hiveCommand or not hiveCommand:IsA("RemoteEvent") then
		warn("playerHiveCommand not found")
		actives["convert"] = false
		actives["move"] = false
		return
	end
	
	local function isMakingHoney()
		local button = mod.movement.findActivateButton()
		if not button then
			return false
		end

		local textBox = button:FindFirstChild("TextBox", true)

		if textBox and textBox:IsA("TextLabel") then
			return textBox.Text == "Stop Making Honey"
		end

		return false
	end
	
	local function getPollen()
		local coreStats = find.player:FindFirstChild("CoreStats")
		local pollen = coreStats and coreStats:FindFirstChild("Pollen")

		if pollen and pollen:IsA("NumberValue") then
			return pollen.Value
		end

		local info = convert.get_pollen_info()
		return info and info.pollen
	end
	
	local beforePollen = getPollen()
	local started = isMakingHoney()
	
	if not started then
		if not beforePollen or beforePollen <= 0 then
			actives["convert"] = false
			actives["move"] = false
			actives["last_time_convert"] = tick()
			task.defer(function()
				task.wait(1)
				if actives["auto_farm"] then
					if farming and farming.farm then
						farming.farm()
					end
				end
			end)
			return
		end
	end
	
	local ok, err = pcall(function()
		hiveCommand:FireServer("ToggleHoneyMaking")
	end)
	
	if not ok then
		actives["convert"] = false
		actives["move"] = false
		return
	end
	
	local start = tick()
	
	while tick() - start < 3 do
		if isMakingHoney() then
			started = true
			break
		end
		
		task.wait(.1)
	end	
	
	if not started then
		warn("make honey not started")
		
		actives["convert"] = false
		actives["move"] = false
		
		task.defer(function()
			task.wait(2)
			
			if actives["auto_farm"] then
				if farming and farming.farm then
					farming.farm()
				end
			end
		end)
		
		return
	end
	
	local startTime = tick()
	local pollenZeroSince = nil
	
	aconvert = farming.conAF(
		find.prerender,
		4,
		function(delta)
			if not actives["auto_farm"] then
				if aconvert then
					aconvert:Disconnect()
					aconvert = nil
				end
				
				actives["convert"] = false
				actives["move"] = false
				return
			end
			
			if tick() - startTime > 600 then
				if aconvert then
					aconvert:Disconnect()
					aconvert = nil
				end
				
				actives["last_time_convert"] = tick()
				actives["convert"] = false
				actives["move"] = false
				
				task.defer(function()
					task.wait(2)
					
					if actives["auto_farm"] then
						if farming and farming.farm then
							farming.farm()
						end
					end
				end)
				
				return
			end
			
			local pollen = getPollen()

			if pollen == nil then
				pollenZeroSince = nil
				return
			end

			if pollen <= 0 then
				pollenZeroSince = pollenZeroSince or tick()
			else
				pollenZeroSince = nil
			end

			if not pollenZeroSince then
				return
			end

			if tick() - pollenZeroSince < 3 then
				return
			end

			if aconvert then
				aconvert:Disconnect()
				aconvert = nil
			end
			
			task.spawn(function()
				local mask = actives["mask"]
				if mask then
					convert.equip_mask(mask)
					task.wait(.4)
				end
				
				actives["last_time_convert"] = tick()
				actives["convert"] = false
				actives["move"] = false
				
				if actives["auto_farm"] then
					if farming and farming.farm then
						farming.farm()
					end
				end
			end)
		end
	)
end

function convert.equip_mask(name)
	print(2)
	
	if type(name) ~= "string" or name == "" or name == "None" then
		return false
	end

	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	if not events then
		return false
	end

	local item = events:FindFirstChild("ItemPackageEvent")
	if not item then
		return false
	end
	
	item:InvokeServer("Equip", {Mute = false, Type = name, Category = "Accessory"})

	return true
end

function convert.honey_mask()	
	return convert.equip_mask("Honey Mask")
end

return convert
