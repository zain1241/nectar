--!nonstrict
local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data
if loaded and loaded.data then
	data = loaded.data
else
	data = require(script.Parent:WaitForChild("data"))
end

local mod = { data = data }
local actives = data.actives

local find = {
	players = game:GetService("Players");
	player = game:GetService("Players").LocalPlayer;
	prerender = game:GetService("RunService").PreRender;
	contextactionservice = game:GetService("ContextActionService");
}

local movement = {}
local move, noCollision
local noclipEnabled = false

function movement.conAF(...)
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

function movement.jump(...)
	local a = {...}
	local humanoid = find.player.Character:WaitForChild("Humanoid")
	if not humanoid then
		return
	end

	if a[1] then
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.None)
		task.wait(.01)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		--print(1)
	else
		humanoid.Jump = false
		humanoid:ChangeState(Enum.HumanoidStateType.None)
		--print(2)
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

function movement.noClip(...)
	local enabled = (...) == true

	noclipEnabled = enabled

	if noCollision then
		noCollision:Disconnect()
		noCollision = nil
	end

	local function update()
		local character = find.player.Character
		if not character then
			return
		end

		for _, part in ipairs(character:GetDescendants()) do
			if not part:IsA("BasePart") then
				continue
			end
			
			if part:FindFirstAncestorOfClass("Accessory")
				or part:FindFirstAncestorOfClass("Tool") then
				continue
			end

			part.CanCollide = not enabled
		end
	end

	update()

	if enabled then
		noCollision = find.prerender:Connect(update)
	end
end

function movement.getHive(...)
	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local honeycombs = workspace:FindFirstChild("Honeycombs")
	
	if not humanoid or not honeycombs then
		return nil
	end
	
	for _, hive in ipairs(honeycombs:GetChildren()) do
		local owner = hive:FindFirstChild("Owner")
		if owner then
			local value = owner.Value
			if value == find.player.Name or value == find.player then
				local spawnPos = hive:FindFirstChild("SpawnPos")
				if spawnPos then
					if spawnPos:IsA("BasePart") then
						return spawnPos.Position
					elseif spawnPos:IsA("CFrameValue") then
						return spawnPos.Value.Position
					elseif spawnPos:IsA("Attachment") then
						return spawnPos.WorldPosition
					elseif spawnPos:IsA("Vector3Value") then
						return spawnPos.Value
					end
				end
			end
		end
	end
	
	return nil
end

function movement.findActivateButton()
	local pg = find.player.PlayerGui
	local sg = pg:FindFirstChild("ScreenGui")
	if sg then
		local b = sg:FindFirstChild("ActivateButton")
		if b then
			return b
		end
	end
	for _, gui in ipairs(pg:GetChildren()) do
		if gui:IsA("ScreenGui") or gui:IsA("Folder") then
			local b = gui:FindFirstChild("ActivateButton", true)
			if b then
				return b
			end
		end
	end
	return nil
end

local function activateButton(...)
	local button = movement.findActivateButton()
	if not button then
		warn("ActivateButton not found")
		return false
	end

	local waitStart = tick()
	while tick() - waitStart < 3 do
		if button.Visible and button.AbsoluteSize.X > 0 then break end
		task.wait(0.05)
		button = movement.findActivateButton() or button
	end

	local pos = button.AbsolutePosition
	local size = button.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		warn("ActivateButton has no size")
		return false
	end

	local cx = pos.X + (size.X / 2)
	local cy = pos.Y + (size.Y / 2)
	local inset = find.guiservice:GetGuiInset()
	local clickY = cy + inset.Y

	local VU = game:GetService("VirtualUser")
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, false, game, 1)
	end)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 1, false, game, 1)
	end)
	pcall(function()
		find.virtual:SendKeyEvent(false, Enum.KeyCode.ButtonR2, false, game)
	end)
	pcall(function()
		VU:Button1Up(Vector2.new(cx, clickY))
	end)

	pcall(function()
		VU:CaptureController()
	end)
	pcall(function()
		VU:ReleaseController(Vector2.new(cx, clickY))
	end)

	task.wait(0.05)

	pcall(function()
		find.virtual:SendMouseMoveEvent(cx, clickY, false, game)
	end)
	task.wait(0.08)

	pcall(function()
		VU:CaptureController()
		VU:ClickButton1(Vector2.new(cx, clickY))
	end)
	task.wait(0.05)

	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, true, game, 1)
	end)
	task.wait(0.05)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, false, game, 1)
	end)

	task.wait(0.1)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, true, game, 1)
	end)
	task.wait(0.05)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, false, game, 1)
	end)

	return true
end

function movement.stop()
	if move then
		move:Disconnect()
		move = nil
	end
	movement.noClip(false)
	actives["move"] = false
end

function movement.move(...)
	local a = {...}
	
	local function place_field(...)
		local a = {...}
		local field = a[1]
		local cfr; local siz
		if not field then
			return print("not field")
		end
		
		if typeof(field) == "string" then
			local zones = workspace:FindFirstChild("FlowerZones")
			field = zones and zones:FindFirstChild(field)
		end
		
		if not field then
			return print("not field x2")
		end
		
		if field:IsA("BasePart") then
			cfr, siz = field.CFrame, field.Size
		elseif field:IsA("Model") then
			cfr, siz = field:GetBoundingBox()
		else
			warn("field is not BasePart/Model")
			return
		end
		
		local h = .4; local marginX = math.min(6, siz.X * .15); local marginZ = math.min(6, siz.Z * .15)
		local x = siz.X / 2 - marginX; local z = siz.Z / 2 - marginZ; local spotX = 0
		
		local position = string.lower(mod.data.actives["position_field"] or "center")
		if position == "left" then 
			spotX = -x * 0.6
		elseif position == "right" then
			spotX = x * 0.6
		end
		
		local l = Vector3.new(spotX, siz.Y / 2 + h + 2, 0)
		return cfr:PointToWorldSpace(l)
	end
	
	local function fly(...)
		if move then
			move:Disconnect()
			move = nil
		end
		
		movement.noClip(true)
		
		local a = {...}
		if not find.player.Character:WaitForChild("Humanoid") then
			return
		end
		
		local character = find.player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			if a[4] then
				actives["move"] = false
				--movement.noClip(false)
				task.spawn(a[4])
			end
			return
		end
		
		local prevPlatformStand = humanoid.PlatformStand
		local states = {
			Enum.HumanoidStateType.Landed,
			Enum.HumanoidStateType.Running,
			Enum.HumanoidStateType.RunningNoPhysics,
			Enum.HumanoidStateType.Climbing,
			Enum.HumanoidStateType.Swimming,
		}

		local startRoot = root.CFrame.Rotation
		local distance = (root.Position - a[1]).Magnitude
		local flySpeed = math.clamp(math.max(distance, 16), 16, 100)
		local start = tick()
		local timeout = distance / flySpeed
		
		--movement.noClip(true)
		humanoid.PlatformStand = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		
		move = find.prerender:Connect(function(dt)
			local char = find.player.Character
			if not char then
				actives["move"] = false
				movement.noClip(false)
				if move then move:Disconnect() move = nil end
				if a[4] then task.spawn(a[4]) end
				return
			end
			
			local rootPart = find.player.Character:WaitForChild("HumanoidRootPart")
			if not rootPart then
				actives["move"] = false
				movement.noClip(false)
				move:Disconnect()
				if a[4] then
					task.spawn(a[4])
				end
				return
			end
			
			if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
			
			local dir = a[1] -  rootPart.Position
			local dist = dir.Magnitude
			if dist <= 2 or actives["auto_farm"] ~= true then		
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
				humanoid.PlatformStand = prevPlatformStand
				
				movement.noClip(false)
				actives["move"] = false
				move:Disconnect()
				if a[4] then
					task.spawn(a[4])
				end
				--print("moved end")
				return
			end
			
			local step = math.min(flySpeed * dt, dist)
			local newPos = rootPart.Position + dir.Unit * step
			rootPart.CFrame = CFrame.new(newPos) * startRoot
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end)
	end
	
	if a[1] == "go_to_field" then
		local zones = workspace:FindFirstChild("FlowerZones")
		if not zones or not actives["auto_farm"] then
			if a[4] then
				task.spawn(a[4])
			end
			return print("not fields or not auto farm or not humanoid")
		end
		
		local found = false
		for _, v in ipairs(zones:GetChildren()) do
			if v.Name == a[3] then
				found = true
				local position = place_field(v)
				--print(position)
				actives["move"] = true
				fly(position, tonumber(a[2]) or 40, a[3], a[4])
				break
			end
		end
		
		if not found and a[4] then
			task.spawn(a[4])
		end
		
		
	elseif a[1] == "hive" then
		
		local target = a[3]
		if typeof(target) ~= "Vector3" then
			return false
		end
		
		local character = find.player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		
		if not humanoid or not root then
			return false
		end
		
		--humanoid:MoveTo(root.Position)
		--humanoid:Move(Vector3.zero, false)
		actives["move"] = true
		actives["convert"] = false
		
		local hivePos = movement.getHive()
		
		if not hivePos then
			if not actives["auto_hive"] then
				return false
			end
			
			if a[5] == nil then
				actives["move"] = false
				return false
			end
			
			local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
			local claimHive = events and events:FindFirstChild("ClaimHive")
			
			if not claimHive then
				actives["move"] = false
				return false
			end
			
			local ok, err = pcall(function()
				claimHive:FireServer(a[5])
			end)
			
			if not ok then
				actives["move"] = false
				return false
			end
			
			local start = tick()
			while tick() - start < 3 do
				hivePos = movement.getHive()
				
				if hivePos then
					break
				end
				
				task.wait(.1)
			end
			
			if not hivePos then
				actives["move"] = false
				return false
			end
		end
		
		target = hivePos

		fly(target, tonumber(a[2]) or 40, "hive", a[4])

		return true
		--
	end
	
	return false
	--
end

return movement
