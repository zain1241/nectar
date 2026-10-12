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

local function getFarmingModule()
	if farming then return farming end
	local modules = rawget(env, "__NECTAR_MODULES")
	return modules and modules.farming or nil
end

local function hasPendingSpecial()
	local farmModule = getFarmingModule()
	if not farmModule then return false end
	local sproutBlocking = actives["sprout"] == true
		and (farmModule.__pendingSprout ~= nil or farmModule.sproutActive == true)
	local puffBlocking = actives["puffshrooms"] == true
		and (farmModule.__pendingPuff ~= nil or farmModule.puffActive == true)
	return sproutBlocking or puffBlocking
end

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
		if noCollision then
			noCollision:Disconnect()
			noCollision = nil
		end
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

local function isHiveFree(hiveId)
	local honeycombs = workspace:FindFirstChild("Honeycombs")
	if not honeycombs then return false end

	for _, hive in ipairs(honeycombs:GetChildren()) do
		local id = hive:FindFirstChild("HiveID")
		if id and id.Value == hiveId then
			local owner = hive:FindFirstChild("Owner")
			if not owner then return true end
			local v = owner.Value
			return v == nil or v == "" or v == "None"
		end
	end
	return false
end

function convert.autoHive(...)
	if convert.__running or convert.__retryScheduled then return end
	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local honeycombs = workspace:FindFirstChild("Honeycombs")

	if not humanoid or not root or not honeycombs then
		return
	end

	actives["convert"] = false

	convert.noClip(false)
	convert.control(false)

	local hivePos, hiveID = convert.getHive()
	if hivePos then
		local farmModule = getFarmingModule()
		if farmModule then farmModule.__goingToHive = true end
		movement.move("hive", actives["walkspeed"], hivePos, function()
			task.wait(1)
			convert.convert()
		end, hiveID)
		return
	end

	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local claimHive = events and events:FindFirstChild("ClaimHive")

	if not claimHive then
		warn("not claimHive")
		return
	end

	local hiveChoice = actives["hive_choice"] or "Random"
	local targetHiveId

	if hiveChoice == "Random" then
		local free = {}
		local honeycombs = workspace:FindFirstChild("Honeycombs")
		if honeycombs then
			for _, hive in ipairs(honeycombs:GetChildren()) do
				local id = hive:FindFirstChild("HiveID")
				if id and isHiveFree(id.Value) then
					table.insert(free, id.Value)
				end
			end
		end
		if #free == 0 then
			warn("not found free hive")
			return
		end
		targetHiveId = free[find.random:NextInteger(1, #free)]
	else
		targetHiveId = tonumber(tostring(hiveChoice):match("%d+"))
		if not targetHiveId or not isHiveFree(targetHiveId) then
			warn("hive", hiveChoice, "not free")
			return
		end
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

	--print(newPos)

	local farmModule = getFarmingModule()
	if farmModule then farmModule.__goingToHive = true end
	movement.move("hive", actives["walkspeed"], newPos, function()
		task.wait(1)
		convert.convert()
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
	-- Prevent overlapping conversion controllers. Multiple ToggleHoneyMaking calls
	-- can turn conversion off and spawn duplicate pollers that keep farming in a loop.
	if convert.__running or convert.__retryScheduled then
		return false
	end

	if actives["auto_farm"] ~= true then
		actives["convert"] = false
		return false
	end

	convert.__jobId = (convert.__jobId or 0) + 1
	local jobId = convert.__jobId
	convert.__running = true
	convert.__conversionSuccess = nil
	actives["convert"] = true
	actives["move"] = false

	local finished = false
	local farmModule = getFarmingModule()

	local function currentJob()
		return convert.__jobId == jobId
	end

	local function setGoingToHive(value)
		local fm = getFarmingModule()
		if fm then
			fm.__goingToHive = value
		end
	end

	local function getPollen()
		-- The HUD meter is the same source used by AutoFarm to decide when the
		-- backpack is full. Prefer it over CoreStats, which can lag/be fractional.
		local info = convert.get_pollen_info()
		if info and type(info.pollen) == "number" then
			return info.pollen
		end

		local coreStats = find.player:FindFirstChild("CoreStats")
		local pollen = coreStats and coreStats:FindFirstChild("Pollen")
		if pollen and (pollen:IsA("NumberValue") or pollen:IsA("IntValue")) then
			return pollen.Value
		end

		return nil
	end
	
	-- Проверяем есть ли сейчас hive-шарик (тот что появляется при конвертации)
	--local function hasHiveBalloon()
	--	local balloons = workspace:FindFirstChild("Balloons")
	--	if not balloons then return false end
	--	local hiveBalloons = balloons:FindFirstChild("HiveBalloons")
	--	if not hiveBalloons then return false end

	--	for _, obj in ipairs(hiveBalloons:GetChildren()) do
	--		if obj:IsA("Model") then
	--			local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
	--			if part and part.Transparency < 1 and part.Parent then
	--				return true
	--			end
	--		elseif obj:IsA("BasePart") then
	--			if obj.Transparency < 1 then
	--				return true
	--			end
	--		end
	--	end
	--	return false
	--end
	
	-- Находит свой улей (по Owner)
	local function getMyHive()
		local honeycombs = workspace:FindFirstChild("Honeycombs")
		if not honeycombs then return nil end

		local player = find.player
		for _, hive in ipairs(honeycombs:GetChildren()) do
			local owner = hive:FindFirstChild("Owner")
			if owner then
				local v = owner.Value
				if v == player or v == player.Name then
					return hive
				end
			end
		end
		return nil
	end

	-- В игровом файле HiveBalloonInstance имеет класс Folder, а не Model.
	-- Поэтому ищем BalloonRoot/BalloonBody внутри каждого контейнера независимо от его класса.
	local function getBalloonParts(obj)
		if not obj then return nil, nil end

		local root
		if obj:IsA("BasePart") and obj.Name == "BalloonRoot" then
			root = obj
		else
			root = obj:FindFirstChild("BalloonRoot", true)
		end

		local body
		if obj:IsA("BasePart") and obj.Name == "BalloonBody" then
			body = obj
		else
			body = obj:FindFirstChild("BalloonBody", true)
		end

		if root and not root:IsA("BasePart") then root = nil end
		if body and not body:IsA("BasePart") then body = nil end
		return root, body
	end

	local function getInstancePosition(obj)
		if not obj then return nil end
		if obj:IsA("BasePart") then
			return obj.Position
		elseif obj:IsA("Attachment") then
			return obj.WorldPosition
		elseif obj:IsA("Vector3Value") then
			return obj.Value
		elseif obj:IsA("CFrameValue") then
			return obj.Value.Position
		elseif obj:IsA("ObjectValue") and obj.Value then
			return getInstancePosition(obj.Value)
		end

		-- A HiveBalloonInstance in the supplied .rbxl is a Folder containing
		-- BalloonRoot and BalloonBody, so Model-only pivot lookup misses it.
		local root, body = getBalloonParts(obj)
		if root then return root.Position end
		if body then return body.Position end

		if obj:IsA("Model") then
			local ok, pivot = pcall(function() return obj:GetPivot() end)
			if ok then return pivot.Position end
		end
		return nil
	end

	-- Проверяем контейнеры в Workspace.Balloons.HiveBalloons и ищем BalloonRoot
	-- внутри Folder/Model. BalloonRoot находится у основания шарика над ульем.
	local function hasHiveBalloon()
		local balloons = workspace:FindFirstChild("Balloons")
		local hiveBalloons = balloons and balloons:FindFirstChild("HiveBalloons")
		if not hiveBalloons then return false end

		local hive = getMyHive()
		if not hive then return false end

		local spawnPos = hive:FindFirstChild("SpawnPos", true)
		local hivePos = getInstancePosition(spawnPos)
		if not hivePos then return false end

		for _, obj in ipairs(hiveBalloons:GetChildren()) do
			local root, body = getBalloonParts(obj)
			local pos = root and root.Position or (body and body.Position)
			if pos then
				local dx, dz = pos.X - hivePos.X, pos.Z - hivePos.Z
				local horizontalDistance = math.sqrt(dx * dx + dz * dz)
				warn(("[balloon-debug] candidate=%s class=%s root=%s horizontalDistance=%.1f"):format(
					obj:GetFullName(), obj.ClassName, root and root.Name or "none", horizontalDistance))
				if horizontalDistance <= 20 then
					return true
				end
			end
		end
		return false
	end

	-- Горизонтальная дистанция (без Y) — шарик висит высоко над ульем
	local function hasBalloonNearPlayer(radius)
		radius = tonumber(radius) or 30

		local character = find.player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return false end

		local balloons = workspace:FindFirstChild("Balloons")
		local hiveBalloons = balloons and balloons:FindFirstChild("HiveBalloons")
		if not hiveBalloons then return false end

		local pp = root.Position
		for _, obj in ipairs(hiveBalloons:GetChildren()) do
			local balloonRoot, balloonBody = getBalloonParts(obj)
			local pos = balloonRoot and balloonRoot.Position or (balloonBody and balloonBody.Position)
			if not pos and obj:IsA("BasePart") then pos = obj.Position end
			if pos then
				local dx, dz = pos.X - pp.X, pos.Z - pp.Z
				local horiz = math.sqrt(dx * dx + dz * dz)
				warn(("[balloon-debug] %s class=%s horiz=%.1f y=%.1f"):format(obj:GetFullName(), obj.ClassName, horiz, pos.Y - pp.Y))
				if horiz <= radius then return true end
			end
		end
		return false
	end

	-- Ждём появления + исчезновения
	local function waitForBalloonToDisappear(maxWait, appearWait)
		maxWait    = tonumber(maxWait)    or 60
		appearWait = tonumber(appearWait) or 60

		-- It may have appeared during conversion and disappeared before this check.
		local seen = hasHiveBalloon() or convert.__sawBalloonDuringConvert == true
		if not seen then
			print("[balloon] waiting for appear (max " .. appearWait .. "s)...")
			local appearDeadline = tick() + appearWait
			while tick() < appearDeadline
				and currentJob()
				and actives["auto_farm"] == true do
				if hasHiveBalloon() then seen = true break end
				task.wait(0.2)
			end
		end

		if not seen then
			warn("[balloon] NOT found within " .. appearWait .. "s; diagnostic follows")
			local balloons = workspace:FindFirstChild("Balloons")
			local hiveBalloons = balloons and balloons:FindFirstChild("HiveBalloons")
			local hive = getMyHive()
			local spawnPos = hive and hive:FindFirstChild("SpawnPos", true)
			local hivePos = getInstancePosition(spawnPos)
			warn("[balloon-debug] folder=", hiveBalloons and hiveBalloons:GetFullName() or "MISSING",
				"hive=", hive and hive:GetFullName() or "MISSING",
				"spawnPos=", spawnPos and spawnPos.ClassName or "MISSING",
				"hivePos=", hivePos and tostring(hivePos) or "MISSING")
			if hiveBalloons then
				local count = 0
				for _, obj in ipairs(hiveBalloons:GetChildren()) do
					local rootPart, bodyPart = getBalloonParts(obj)
					local pos = rootPart and rootPart.Position or (bodyPart and bodyPart.Position)
					if pos then
						local distance = "unknown"
						if hivePos then
							local dx, dz = pos.X - hivePos.X, pos.Z - hivePos.Z
							distance = string.format("%.1f", math.sqrt(dx * dx + dz * dz))
						end
						warn("[balloon-debug] container=", obj:GetFullName(), "class=", obj.ClassName,
							"root=", rootPart and rootPart:GetFullName() or "none",
							"body=", bodyPart and bodyPart:GetFullName() or "none",
							"pos=", tostring(pos), "horizontalDistance=", distance)
						count += 1
					end
				end
				warn("[balloon-debug] containers with BalloonRoot/BalloonBody=", count)
			end
			return false
		end

		print("[balloon] detected, waiting for disappear...")
		local start = tick()
		local warnedTimeout = false
		while currentJob() and actives["auto_farm"] == true do
			if not hasHiveBalloon() then
				print(("[balloon] gone after %.1fs"):format(tick() - start))
				return true
			end
			if not warnedTimeout and maxWait > 0 and tick() - start >= maxWait then
				warn(("[balloon] still present after %ds; continuing to wait"):format(maxWait))
				warnedTimeout = true
			end
			task.wait(0.2)
		end
		print("[balloon] wait cancelled because AutoFarm stopped or conversion job changed")
		return false
	end

	local function finish(success, reason)
		if finished or not currentJob() then
			return
		end
		finished = true

		if aconvert then
			aconvert:Disconnect()
			aconvert = nil
		end

		convert.__running = false
		convert.__conversionSuccess = success == true
		convert.__conversionFinishedAt = tick()
		actives["convert"] = false
		actives["move"] = false
		actives["last_time_convert"] = tick()

		farmModule = getFarmingModule()

		if success then
			convert.__failedAt = nil
			convert.__retryCount = 0
			convert.__retryScheduled = false

			-- Lock AutoFarm before yielding: otherwise the watchdog sees the player
			-- standing at the hive and starts a competing route back to the field.
			local shouldWaitForBalloon = actives["balloon"] == true and not hasPendingSpecial()
			if farmModule then
				farmModule.__waitingForBalloon = shouldWaitForBalloon
				if shouldWaitForBalloon then
					-- Invalidate any stale field-route callback from before conversion.
					farmModule.__fieldRouteId = (farmModule.__fieldRouteId or 0) + 1
					farmModule.__fieldRouteInProgress = false
					if movement.stop then pcall(movement.stop) end
				end
			end
			setGoingToHive(false)

			if actives["auto_farm"] == true then
				task.defer(function()
					task.wait(0.25)
					if not currentJob() or actives["auto_farm"] ~= true then
						farmModule = getFarmingModule()
						if farmModule then farmModule.__waitingForBalloon = false end
						setGoingToHive(false)
						return
					end

					if actives["mask"] and actives["mask"] ~= "None" then
						pcall(function() convert.equip_mask(actives["mask"]) end)
					end

					farmModule = getFarmingModule()
					if farmModule and farmModule.resetCharacterState then
						pcall(farmModule.resetCharacterState)
					end

					-- A special-event callback is waiting for __conversionFinishedAt
					-- and will resume its own target. Do not launch a competing field route.
					--if not hasPendingSpecial() then
					--	farmModule = getFarmingModule()
					--	if farmModule and type(farmModule.farm) == "function" then
					--		farmModule.farm()
					--	end
					--end
					
					if not hasPendingSpecial() then
						farmModule = getFarmingModule()
						if farmModule and type(farmModule.farm) == "function" then
							if actives["balloon"] == true then
								-- Re-assert the lock in case a special-event state changed during the defer.
								if farmModule.__waitingForBalloon ~= true then
									farmModule.__waitingForBalloon = true
									farmModule.__fieldRouteId = (farmModule.__fieldRouteId or 0) + 1
									farmModule.__fieldRouteInProgress = false
									if movement.stop then pcall(movement.stop) end
								end
								-- Give the balloon time to spawn, then wait until it vanishes.
								waitForBalloonToDisappear(300, 4)
							end
						end
						-- Always release the lock when the wait ends or is cancelled.
						if farmModule then farmModule.__waitingForBalloon = false end
						setGoingToHive(false)
						if currentJob() and actives["auto_farm"] == true
							and farmModule and type(farmModule.farm) == "function" then
							if farmModule.__fieldRouteInProgress then
								farmModule.__fieldRouteInProgress = false
							end
							farmModule.farm()
						end
					else
						if farmModule then farmModule.__waitingForBalloon = false end
						setGoingToHive(false)
					end
				end)
			else
				if farmModule then farmModule.__waitingForBalloon = false end
			end
			
				-- Safety net: если через 8 секунд после успешной конвертации бот всё ещё
				-- "висит" на улье (pollen=0, но идёт движение к полю), принудительно запускаем farm().
				--task.delay(8, function()
				--	if convert.__jobId ~= jobId then return end
				--	if actives["auto_farm"] ~= true then return end

				--	local fm = getFarmingModule()
				--	if not fm then return end

				--	local info = convert.get_pollen_info()
				--	if info and info.pollen > 0 then return end

				--	if (fm.__goingToHive or fm.__fieldRouteInProgress) and not hasHiveBalloon() then
				--		warn("[convert] safety net: bot stuck after conversion, forcing farm()")
				--		fm.__goingToHive = false
				--		fm.__fieldRouteInProgress = false
				--		fm.__fieldRouteId = (fm.__fieldRouteId or 0) + 1
				--		if type(fm.farm) == "function" then
				--			fm.farm()
				--		end
				--	end
			return
		end

		convert.__failedAt = tick()
		warn("[convert] conversion failed: " .. tostring(reason or "unknown reason"))

		if actives["auto_farm"] == true then
			-- Stay at the hive. Never send a full backpack back to the field,
			-- because it immediately trips the hive threshold again.
			setGoingToHive(true)

			local retries = tonumber(convert.__retryCount) or 0
			if retries < 2 then
				convert.__retryCount = retries + 1
				convert.__retryScheduled = true
				warn("[convert] retrying at the hive (attempt " .. tostring(convert.__retryCount + 1) .. "/3)")

				task.delay(8, function()
					if not currentJob() then
						return
					end
					convert.__retryScheduled = false

					if actives["auto_farm"] == true and not convert.__running then
						convert.convert()
					else
						setGoingToHive(false)
					end
				end)
			else
				-- Never leave AutoFarm permanently locked at the hive after 3 failures.
				-- Keep the character at the hive (the backpack may still be full),
				-- then start a fresh retry cycle after a short cooldown.
				convert.__retryCount = 0
				convert.__retryScheduled = true
				warn("[convert] 3 attempts failed; automatically retrying at the hive in 15 seconds")

				task.delay(15, function()
					if not currentJob() then
						return
					end
					convert.__retryScheduled = false

					if actives["auto_farm"] == true and not convert.__running then
						convert.convert()
					else
						setGoingToHive(false)
					end
				end)
			end
		else
			convert.__retryScheduled = false
			convert.__retryCount = 0
			setGoingToHive(false)
		end
	end

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local hiveCommand = events and events:FindFirstChild("PlayerHiveCommand")

	if not character or not humanoid or not root then
		finish(false, "character or HumanoidRootPart not found")
		return false
	end

	if not hiveCommand or not hiveCommand:IsA("RemoteEvent") then
		finish(false, "PlayerHiveCommand RemoteEvent not found")
		return false
	end

	local function isMakingHoney()
		local ok, button = pcall(function()
			return mod.movement.findActivateButton()
		end)
		if not ok or not button then
			return false
		end

		local textBox = button:FindFirstChild("TextBox", true)
		if textBox and (textBox:IsA("TextLabel") or textBox:IsA("TextButton")) then
			return string.find(string.lower(textBox.Text), "stop", 1, true) ~= nil
		end
		return false
	end

	if actives["honey_mask"] then
		pcall(function() convert.honey_mask() end)
		task.wait(0.5)
	end

	local beforePollen = getPollen()
	local makingHoney = isMakingHoney()

	if beforePollen ~= nil and beforePollen <= 0 and not makingHoney then
		finish(true)
		return true
	end

	-- Toggle only when honey-making is not already active. The old code always
	-- toggled, sometimes turning an active conversion off.
	if not makingHoney then
		local ok, err = pcall(function()
			hiveCommand:FireServer("ToggleHoneyMaking")
		end)
		if not ok then
			finish(false, "ToggleHoneyMaking failed: " .. tostring(err))
			return false
		end

		local confirmDeadline = tick() + 8
		local confirmed = false
		while tick() < confirmDeadline and actives["auto_farm"] == true and currentJob() do
			if isMakingHoney() then
				confirmed = true
				break
			end

			local currentPollen = getPollen()
			if beforePollen ~= nil and currentPollen ~= nil and currentPollen < beforePollen then
				confirmed = true
				break
			end
			task.wait(0.2)
		end

		if actives["auto_farm"] ~= true then
			finish(false, "AutoFarm disabled while starting conversion")
			return false
		end

		if not confirmed and not isMakingHoney() then
			finish(false, "honey-making did not start; check the hive prompt")
			return false
		end
	end
	
	-- Начинаем следить за шариком с самого старта конвертации.
	-- Он может появиться в любой момент, не только после pollen=0.
	convert.__sawBalloonDuringConvert = false
	convert.__balloonWatchJobId = jobId

	task.spawn(function()
		while convert.__jobId == jobId and not finished do
			if hasHiveBalloon() then
				convert.__sawBalloonDuringConvert = true
			end
			task.wait(0.2)
		end
	end)

	-- One polling loop per conversion. A successful conversion is confirmed by
	-- the backpack meter reaching zero and staying there briefly; balloon popping
	-- is deliberately not a prerequisite for returning to the field.
	task.spawn(function()
		local startTime = tick()
		local zeroSince = nil
		local timeout = 300

		while currentJob() and not finished do
			if actives["auto_farm"] ~= true then
				finish(false, "AutoFarm disabled during conversion")
				return
			end

			local pollen = getPollen()
			if pollen ~= nil and pollen <= 0 then
				zeroSince = zeroSince or tick()
				if tick() - zeroSince >= 2 then
					finish(true)
					return
				end
			else
				zeroSince = nil
			end

			if tick() - startTime >= timeout then
				finish(false, "pollen remained above zero for " .. tostring(timeout) .. " seconds")
				return
			end

			task.wait(0.25)
		end
	end)

	return true
end
print(123123)

function convert.equip_mask(name)
	--print(2)

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
	--print(2)

	return true
end

function convert.honey_mask()	
	return convert.equip_mask("Honey Mask")
end

return convert
