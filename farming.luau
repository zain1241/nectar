--!nonstrict
local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data, movement, convert
if loaded and loaded.data and loaded.movement and loaded.convert then
	data, movement, convert = loaded.data, loaded.movement, loaded.convert
else
	data = require(script.Parent:WaitForChild("data"))
	movement = require(script.Parent:WaitForChild("movement"))
	convert = require(script.Parent:WaitForChild("convert"))
end

local mod = { data = data, movement = movement, convert = convert }
local actives = data.actives

local find = {
	players = game:GetService("Players");
	player = game:GetService("Players").LocalPlayer;
	prerender = game:GetService("RunService").PreRender;
	contextactionservice = game:GetService("ContextActionService");
	random = Random.new();
}

local farming = {}
local noCollision, field, dig, walkSpeedLock
local sprinklerPlace = false; farmingActive = false
local lastConvertTime = tick()

local queue = {
	auto_farm = {},
	tokens = {},
}

function farming.Hive(...)
	--
end

function farming.conAF(...)
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

function farming.noClip(...)
	local a = {...}

	local parts = {
		HumanoidRootPart = true,
		UpperTorso = true,
		LowerTorso = true,
	}

	if a[1] then
		if noCollision then
			noCollision:Disconnect()
			noCollision = nil
		end
		noCollision = movement.conAF(
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

function farming.control(...)
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

function farming.sprinkler(...)
	local a = {...}
	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false
	end

	if actives["sprinkler"] ~= true then
		return false
	end

	if sprinklerPlace then
		return false
	end
	
	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local command = events:FindFirstChild("PlayerActivesCommand")
	if not events or not command then
		return false
	end
	
	sprinklerPlace = true
	
	local ok, err = pcall(function()
		command:FireServer({Name = "Sprinkler Builder"})
	end)
	
	if not ok then
		wait(err)
	end
	
	task.delay(1, function()
		sprinklerPlace = false
	end)
	
	return ok
end

function farming.getHive()
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

function farming.dig(...)
	local a = {...}
	
	if a[1] ~= true then
		return
	end
	
	if dig then
		dig:Disconnect()
		dig = nil
	end
	
	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local collect = events and events:FindFirstChild("ToolCollect")
	if not collect or not collect:IsA("RemoteEvent") then
		warn("tool is not find")
		return
	end
	
	dig = farming.conAF(
		find.prerender, 1,
		function(delta)
			if actives["dig"] then
				collect:FireServer()
			else
				if dig then
					dig:Disconnect()
					dig = nil
				end
			end
		end
	)
end

function farming.lockWalkSpeed()
	if walkSpeedLock then
		walkSpeedLock:Disconnect()
		walkSpeedLock = nil
	end
	
	walkSpeedLock = farming.conAF(
		find.prerender, 2,
		function(delta)
			if actives["fast_run"] then
				local character = find.player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not humanoid then return end

				local want = actives["walkspeed"]
				if type(want) ~= "number" then
					want = 16
				end

				if humanoid.WalkSpeed ~= want then
					humanoid.WalkSpeed = want
				end
			else
				if walkSpeedLock then
					walkSpeedLock:Disconnect()
					walkSpeedLock = nil
				end
			end
		end
	)
end

function farming.farm(...)
	local status = actives.auto_farm
	local walkspeed = actives.walkspeed
	
	actives.move = false
	if not status then
		actives.move = false
		return
	end
	
	lastConvertTime = lastConvertTime or tick()
	--if not status then
	--	return farming.noClip(status)
	--end --return if not active
	
	--farming.noClip(status)
	
	local hivePos, hiveId = farming.getHive()
	--print(hivePos, hiveId, "423")
	if hivePos == nil and hiveId == nil then
		print(hivePos, hiveId)
		mod.convert.autoHive()
		table.clear(queue["auto_farm"])
		table.clear(queue["tokens"])
		return
	end
	
	local field = actives["field"]
	local fields = workspace:FindFirstChild("FlowerZones")
	if not fields then
		return warn("not found")
	end
	
	local function randomTokens(...)
		local a = {...}
		local part = a[1]
		local cf, size, ix, ax

		if part == nil then
			return
		end

		if typeof(part) == "string" then
			local f = workspace:FindFirstChild("FlowerZones")
			part = f and f:FindFirstChild(part)
		end

		if not part then
			return warn("field not found")
		end

		if part:IsA("BasePart") then
			cf, size = part.CFrame, part.Size
		elseif part:IsA("Model") then
			cf, size = part:GetBoundingBox()
		else
			return warn("field is not BasePart/Model")
		end

		local h = .4
		local marginX = math.min(6, size.X * .15)
		local marginZ = math.min(6, size.Z * .15)
		local x = size.X / 2 - marginX
		local z = size.Z / 2 - marginZ
		local position = string.lower(mod.data.actives["position_field"] or "center")
		if position == "left" then
			ix = -x; ax = 0
		elseif position == "right" then
			ix = 0; ax = x
		else
			ix = -x / 3; ax = x / 3
		end

		local l = Vector3.new(find.random:NextNumber(ix, ax), size.Y / 2 + h, find.random:NextNumber(-z, z))
		return cf:PointToWorldSpace(l)
	end

	local function metod(...)
		if farmingActive then
			return
		end
		
		farmingActive = true
		
		local character = find.player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			return
		end
		
		actives["move"] = true

		local function isTokenInField(token, field)
			local p = field.CFrame:PointToObjectSpace(token.Position)
			local s = field.Size / 2
			return math.abs(p.X) <= s.X and math.abs(p.Z) <= s.Z and p.Y >= -3 and p.Y <= 15
		end
		
		local function isBubble(part)
			local n = part.Name
			return n == "Bubble" or n == "GoldBubble"
		end
		
		local function getPriority(obj)
			if isBubble(obj) then
				return (tonumber(actives["bubble_priority"]) or 0) * 0.2
			end

			local tp = actives["token_priorities"] or {}
			local dp = actives["drops_priorities"] or {}

			return tonumber(tp[obj.Name]) or tonumber(dp[obj.Name]) or 0
		end
		
		local lastField = nil
		while actives["auto_farm"] == true do
			
			if find.player.Character ~= character then
				break
			end
			if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
				break
			end
			
			local zones = workspace:FindFirstChild("FlowerZones")
			if actives["field"] == "" or actives["field"] == false or actives["field"] == nil then
				field = nil
			else
				field = zones:FindFirstChild(actives["field"])
			end
			
			if actives["field"] ~= lastField then
				lastField = actives["field"]
				table.clear(queue["auto_farm"])
				table.clear(queue["tokens"])
			end
			
			if not field then
				continue
			end
			
			if #queue["auto_farm"] == 0 then
				local pos = randomTokens(field)
				if not pos then
					task.wait(0.1)
					continue
				end
				table.insert(queue["auto_farm"], { targetPos = pos, speed = walkspeed })
			end
			
			local removeTable = table.remove(queue["auto_farm"], 1)
			local collectibles = workspace:FindFirstChild("Collectibles")
			
			if not collectibles or not zones then
				return print("collectibles or zones not found")
			end

			table.clear(queue["tokens"])
			
			if root and field then
				if collectibles then
					for _, v in pairs(collectibles:GetChildren()) do
						if v:IsA("BasePart") and v.Transparency <= 0 and isTokenInField(v, field) and (root.Position - v.Position).Magnitude > 2 then
							local prio = getPriority(v)
							if prio > 0 then
								table.insert(queue["tokens"], v)
							end
						end
					end
				end

				if actives["bubble"] then
					local particles = workspace:FindFirstChild("Particles")

					if particles then
						for _, v in pairs(particles:GetChildren()) do
							if v:IsA("BasePart") and isBubble(v) and v.Transparency < 1 and isTokenInField(v, field) and (root.Position - v.Position).Magnitude > 2 then

								local prio = getPriority(v)

								if prio > 0 then
									table.insert(queue["tokens"], v)
								end
							end
						end
					end
				end
			end

			--if collectibles and field then
			--	if root then
			--		for _, v in pairs(collectibles:GetChildren()) do
			--			if v:IsA("BasePart") and field and v.Transparency <= 0 and isTokenInField(v, field) and (root.Position - v.Position).Magnitude > 2 then
			--				table.insert(queue["tokens"], v)
			--			end
			--		end
			--	end
			--end

			if #queue["tokens"] > 0 then
				if not root then
					actives["move"] = false
					return
				end

				--local position = root.Position
				--local speed = removeTable.speed or actives["walkspeed"]
				--table.sort(queue["tokens"], function(x, y)
				--	return (position - x.Position).Magnitude < (position - y.Position).Magnitude
				--end)
				
				local position = root.Position
				local speed = removeTable.speed or actives["walkspeed"]
				--table.sort(queue["tokens"], function(x, y)
				--	local px, py = getPriority(x), getPriority(y)
				--	if px ~= py then
				--		return px > py
				--	end
				--	return (position - x.Position).Magnitude < (position - y.Position).Magnitude
				--end)
				table.sort(queue["tokens"], function(x, y)
					local px = getPriority(x)
					local py = getPriority(y)

					if px ~= py then
						return px > py
					end

					local dx = (position - x.Position).Magnitude
					local dy = (position - y.Position).Magnitude

					return dx < dy
				end)

				while actives["auto_farm"] and #queue["tokens"] > 0 do
					while #queue["tokens"] > 0 do
						local first = queue["tokens"][1]
						if first and first.Parent and first.Transparency <= 1 and isTokenInField(first, field) then
							break
						end
						table.remove(queue["tokens"], 1)
					end

					if #queue["tokens"] == 0 then
						break
					end

					local target = queue["tokens"][1]
					if not target then
						break
					end
					
					--local targetIsBubble = isBubble(target)
					--local targetDistance = (position - target.Position).Magnitude

					--if targetIsBubble and targetDistance > 25 then
					--	for i = 2, #queue["tokens"] do
					--		local candidate = queue["tokens"][i]

					--		if not isBubble(candidate) then
					--			local distance = (position - candidate.Position).Magnitude

					--			if distance <= 25 then
					--				target = candidate
					--				break
					--			end
					--		end
					--	end
					--end

					local tp = Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)
					local dist = (tp - root.Position).Magnitude

					if dist <= 2 then
						table.remove(queue["tokens"], 1)
						continue
					end
					
					humanoid:MoveTo(tp)
					find.prerender:Wait()
				end
			else
				if removeTable.targetPos and removeTable.speed then
					if humanoid and root then
						local start = tick()
						local targetPos = removeTable.targetPos

						while tick() - start < 15 do
							if not actives["auto_farm"] then
								break
							end

							--local hasToken = false
							--if collectibles and field then
							--	for _, v in pairs(collectibles:GetChildren()) do
							--		if v:IsA("BasePart") and field and isTokenInField(v, field) then
							--			hasToken = true
							--			break
							--		end
							--	end
							--end

							--if hasToken or not humanoid or not root then
							--	break
							--end
							
							if #queue["tokens"] > 0 then
								break
							end

							if not humanoid or not root then
								break
							end

							local flat = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
							if (flat - root.Position).Magnitude <= 1.5 then
								break
							end

							if humanoid then
								humanoid:MoveTo(flat)
								task.wait()
							end
						end
					end
				end
			end
			
			local info = mod.convert.get_pollen_info()
			local threshold = actives["backpack"] or 80
			local intervalMinutes = tonumber(actives["convert_interval"]) or 15
			local interval = intervalMinutes * 60

			local byBackpack = info and info.percent >= threshold and info.pollen > 0
			local byTime = (tick() - lastConvertTime) >= interval

			if byBackpack or byTime then
				local currentPos = select(1, farming.getHive())
				if not currentPos then
					farmingActive = false
					actives["move"] = false
					mod.convert.autoHive()
					return
				end

				lastConvertTime = tick()
				farmingActive = false
				actives["move"] = false
				movement.move("hive", actives["walkspeed"], currentPos, function()
					task.wait(1)
					mod.convert.convert()
				end)
				return
			end
			
			task.wait()
		end
		
		farmingActive = false
		actives["move"] = false
	end

	local function start(...)
		local a2 = {...}
		if not find.player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local pos = randomTokens(a2[1])
		table.insert(queue["auto_farm"], {targetPos = pos, speed = a2[2]})
		if not actives["move"] then
			task.spawn(metod)
		end
	end
	
	if hivePos ~= nil then
		mod.movement.move("go_to_field", walkspeed, field, function()
			if not actives["auto_farm"] then
				return
			end
			if not actives["move"] then
				task.spawn(metod)
			end
			
			if actives["mask"] ~= "None" then
				local mask = actives["mask"]
				mod.convert.equip_mask(mask)
			end

			if actives["sprinkler"] then
				farming.sprinkler(true)
			end

			--if actives["honey_mask"] then
			--	mod.convert.honey_mask()
			--end
		end) -- go to field
	end
end

print(44444)

task.spawn(function()
	task.wait(2)
	farming.lockWalkSpeed()
	if actives["auto_farm"] then
		farming.farm()
	end
	
	if actives["dig"] then
		farming.dig(true)
	end
	
end)

local function respawn(...)
	task.wait(.4)
	local a = {...}
	if a[1] then
		task.wait(1)
		
		if movement.stop then
			movement.stop()
		end
		
		farmingActive = false
		actives["move"] = false
		lastConvertTime = tick()
		
		table.clear(queue["auto_farm"])
		table.clear(queue["tokens"])
		
		if actives["auto_farm"] then
			farming.farm()
		end
		
		if actives["dig"] then
			farming.dig(true)
		end
	end
end

find.player.CharacterAdded:Connect(respawn)

if find.player.Character then
	task.spawn(function()
		task.wait(.4)
		respawn(find.player.Character)
	end)
end

return farming
