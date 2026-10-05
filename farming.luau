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
local noCollision, field
local sprinklerPlace = false

local queue = {
	auto_farm = {},
	tokens = {},
}

function farming.Hive(...)
	--
end

function movement.noClip(...)
	local a = {...}

	local parts = {
		HumanoidRootPart = true,
		UpperTorso = true,
		LowerTorso = true,
	}

	if a[1] then
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

function movement.control(...)
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

function movement.sprinkler(...)
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

function farming.farm(...)
	local status = actives.auto_farm
	local walkspeed = actives.walkspeed
	
	actives.move = false
	if not status then
		actives.move = false
		return
	end
	--if not status then
	--	return farming.noClip(status)
	--end --return if not active
	
	--farming.noClip(status)
	
	local hivePos = mod.convert.getHive()
	if not hivePos and actives["auto_hive"] then
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

		while actives["auto_farm"] == true do
			local zones = workspace:FindFirstChild("FlowerZones")
			if actives["field"] == "" or actives["field"] == false or actives["field"] == nil then
				field = nil
			else
				field = zones:FindFirstChild(actives["field"])
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

			if collectibles and field then
				if root then
					for _, v in pairs(collectibles:GetChildren()) do
						if v:IsA("BasePart") and v.Transparency <= 0 and isTokenInField(v, field) and (root.Position - v.Position).Magnitude > 2 then
							table.insert(queue["tokens"], v)
						end
					end
				end
			end

			if #queue["tokens"] > 0 then
				if not root then
					actives["move"] = false
					return
				end

				local position = root.Position
				local speed = removeTable.speed or actives["walkspeed"]
				table.sort(queue["tokens"], function(x, y)
					return (position - x.Position).Magnitude < (position - y.Position).Magnitude
				end)

				while actives["auto_farm"] and #queue["tokens"] > 0 do
					while #queue["tokens"] > 0 do
						local first = queue["tokens"][1]
						if first and first.Parent and first.Transparency <= 0 and isTokenInField(first, field) then
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

					local tp = Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)
					local dist = (tp - root.Position).Magnitude

					if dist <= 2 then
						table.remove(queue["tokens"], 1)
						continue
					end

					humanoid.WalkSpeed = speed
					humanoid:MoveTo(tp)
					task.wait()
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

							local hasToken = false
							if collectibles and field then
								for _, v in pairs(collectibles:GetChildren()) do
									if v:IsA("BasePart") and isTokenInField(v, field) then
										hasToken = true
										break
									end
								end
							end

							if hasToken or not humanoid or not root then
								break
							end

							local flat = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
							if (flat - root.Position).Magnitude <= 1.5 then
								break
							end

							if humanoid then
								humanoid.WalkSpeed = removeTable.speed
								humanoid:MoveTo(flat)
								task.wait()
							end
						end
					end
				end
			end
			task.wait()
		end

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
	
	mod.movement.move("go_to_field", walkspeed, field, function()
		if not actives["auto_farm"] then
			return
		end
		if not actives["move"] then
			task.spawn(metod)
		end
		
		if actives["sprinkler"] then
			movement.sprinkler(true)
		end
		
		--if actives["honey_mask"] then
		--	mod.convert.honey_mask()
		--end
	end) -- go to field
end

return farming
