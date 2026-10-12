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

local function resetCharacterState()
	local character = find.player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.PlatformStand = false
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
	task.wait(0.1)
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end)
	task.wait(0.1)
end

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
	if not events then
		return false
	end
	local command = events:FindFirstChild("PlayerActivesCommand")
	if not command then
		return false
	end

	local now = tick()
	if now - (farming.__lastSprinklerAt or 0) < 4 then
		return
	end
	farming.__lastSprinklerAt = now

	sprinklerPlace = true
	local ok, err = pcall(function()
		command:FireServer({Name = "Sprinkler Builder"})
	end)
	if not ok then
		warn("sprinkler failed", err)
	end

	task.delay(1, function() sprinklerPlace = false end)
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
		find.prerender, 2,
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

				local slider = actives["massles_slider"]
				if actives["massles"] then
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root then
						for _, part in ipairs(character:GetDescendants()) do
							if part:IsA("BasePart") and part ~= root then
								part.Massless = true
							end
						end
						local cur = root.CurrentPhysicalProperties
						root.CustomPhysicalProperties = PhysicalProperties.new(slider, cur.Friction, cur.Elasticity, cur.FrictionWeight, cur.ElasticityWeight)
					end
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

-- Shared token collector for Sprouts and Puffshrooms.
-- Uses the same token/drop/bubble priorities as normal AutoFarm, but only inside
-- the specified radius around the special object.
local function collectTokensNear(centerProvider, duration, shouldContinue, radius, emptyGrace)
	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or not root then
		return
	end

	duration = math.max(0, tonumber(duration) or 0)
	radius = math.max(1, tonumber(radius) or 40)
	local startedAt = tick()
	local endsAt = startedAt + duration
	local lastTokenSeenAt = startedAt
	local lastCenter
	local target
	local targetDistance = math.huge
	local lastProgressAt = startedAt
	local lastMoveCommandAt = 0
	local blockedUntil = setmetatable({}, { __mode = "k" })
	local bubbleNames = { Bubble = true, GoldBubble = true }

	local function isBubble(obj)
		return obj and bubbleNames[obj.Name] == true
	end

	local function getPriority(obj)
		local tokenPriorities = actives["token_priorities"]
		local dropPriorities = actives["drops_priorities"]
		if type(tokenPriorities) ~= "table" then tokenPriorities = {} end
		if type(dropPriorities) ~= "table" then dropPriorities = {} end

		if isBubble(obj) then
			return (tonumber(actives["bubble_priority"]) or 0) * 0.2
		end

		local namePriority = tonumber(tokenPriorities[obj.Name])
		if namePriority == nil then
			namePriority = tonumber(dropPriorities[obj.Name]) or 0
		end

		local isDrop = dropPriorities[obj.Name] ~= nil
		local categoryPriority = 0
		if isDrop then
			if not actives["no_priority_drops"] then
				categoryPriority = 100
			end
		else
			if not actives["no_priotiy_tokens"] then
				categoryPriority = 200
			end
		end

		return 1000 + categoryPriority + (namePriority or 0)
	end

	local function getCenter()
		local ok, center = pcall(centerProvider)
		if ok and typeof(center) == "Vector3" then
			lastCenter = center
		end
		return lastCenter
	end

	local function canUse(part, center, now, fromParticles)
		if not part or not part:IsA("BasePart") or not part.Parent then
			return false
		end
		if fromParticles and (not actives["bubble"] or not isBubble(part)) then
			return false
		end

		if fromParticles then
			if part.Transparency >= 1 then
				return false
			end
		elseif part.Transparency > 0 then
			return false
		end

		local blocked = blockedUntil[part]
		if blocked and blocked > now then
			return false
		elseif blocked then
			blockedUntil[part] = nil
		end

		if (part.Position - center).Magnitude > radius then
			return false
		end

		return getPriority(part) > 0
	end

	while tick() < endsAt do
		local keepGoing = false
		local okContinue, continueValue = pcall(shouldContinue)
		if okContinue and continueValue == true then
			keepGoing = true
		end
		if not keepGoing then
			break
		end
		if find.player.Character ~= character or not root.Parent or not humanoid.Parent or humanoid.Health <= 0 then
			break
		end

		local now = tick()
		local center = getCenter()
		if center then
			local candidates = {}
			local eligible = {}

			local function addCandidate(part, fromParticles)
				if eligible[part] or not canUse(part, center, now, fromParticles) then
					return
				end
				eligible[part] = true
				local flatPosition = Vector3.new(part.Position.X, root.Position.Y, part.Position.Z)
				local distance = (flatPosition - root.Position).Magnitude
				if distance <= 2 then
					return
				end
				table.insert(candidates, {
					part = part,
					priority = getPriority(part),
					distance = distance,
				})
			end

			local collectibles = workspace:FindFirstChild("Collectibles")
			if collectibles then
				for _, part in ipairs(collectibles:GetChildren()) do
					addCandidate(part, false)
				end
			end

			if actives["bubble"] then
				local particles = workspace:FindFirstChild("Particles")
				if particles then
					for _, part in ipairs(particles:GetChildren()) do
						addCandidate(part, true)
					end
				end
			end

			if #candidates > 0 then
				lastTokenSeenAt = now
			end

			if target and not eligible[target] then
				target = nil
				targetDistance = math.huge
				lastProgressAt = now
			end

			if target then
				local targetPosition = Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)
				local distance = (targetPosition - root.Position).Magnitude
				if distance <= 2 then
					blockedUntil[target] = now + 0.7
					target = nil
					targetDistance = math.huge
					lastProgressAt = now
				elseif distance < targetDistance - 0.25 then
					targetDistance = distance
					lastProgressAt = now
				elseif now - lastProgressAt >= 3 then
					-- Skip a token that the character cannot reach instead of looping forever.
					blockedUntil[target] = now + 3
					target = nil
					targetDistance = math.huge
					lastProgressAt = now
				else
					if now - lastMoveCommandAt >= 0.15 then
						lastMoveCommandAt = now
						pcall(function()
							humanoid:MoveTo(targetPosition)
						end)
					end
				end
			end

			if not target and #candidates > 0 then
				local best
				for _, candidate in ipairs(candidates) do
					if not best
						or candidate.priority > best.priority
						or (candidate.priority == best.priority and candidate.distance < best.distance)
					then
						best = candidate
					end
				end

				if best and best.part.Parent then
					target = best.part
					targetDistance = best.distance
					lastProgressAt = now
					if targetDistance <= 2 then
						blockedUntil[target] = now + 0.7
						target = nil
						targetDistance = math.huge
					else
						lastMoveCommandAt = now
						local targetPosition = Vector3.new(target.Position.X, root.Position.Y, target.Position.Z)
						pcall(function()
							humanoid:MoveTo(targetPosition)
						end)
					end
				end
			end
		end

		if emptyGrace and now - startedAt >= math.min(2.5, emptyGrace)
			and now - lastTokenSeenAt >= emptyGrace then
			break
		end

		task.wait(0.08)
	end
end

-- Wrap movement callbacks with a timeout so special farming cannot remain active forever
-- when a path request never completes. The failure handler owns cleanup/returning.
local function moveWithTimeout(mode, speed, destination, callback, timeout, onFailure, isOwner)
	local completed = false

	local function stillOwnsMovement()
		if type(isOwner) ~= "function" then return true end
		local ok, value = pcall(isOwner)
		return ok and value == true
	end

	local function finish(...)
		if completed then return end
		completed = true
		-- An old callback must not take control after the event was cancelled/replaced.
		if not stillOwnsMovement() then return end
		local ok, err = pcall(callback, ...)
		if not ok then
			warn("[special farm] movement callback error:", err)
			if onFailure and stillOwnsMovement() then
				local recovered, recoveryErr = pcall(onFailure, err)
				if not recovered then warn("[special farm] failure handler error:", recoveryErr) end
			end
		end
	end

	local function fail(reason)
		if completed then return end
		completed = true
		-- A timed-out old move must never stop a newer AutoFarm movement.
		if not stillOwnsMovement() then return end
		if movement.stop then pcall(movement.stop) end
		if onFailure then
			local ok, err = pcall(onFailure, reason)
			if not ok then warn("[special farm] failure handler error:", err) end
		else
			warn("[special farm] movement failed:", reason)
		end
	end

	task.delay(tonumber(timeout) or 60, function()
		if not completed then
			fail("movement callback timed out")
		end
	end)

	local ok, err = pcall(function()
		mod.movement.move(mode, speed, destination, finish)
	end)
	if not ok then
		fail(err)
	end
end

-- Hand field return back to the normal AutoFarm route.
-- This avoids competing movement callbacks and guarantees the main loop rebuilds its route.
local function requestFieldRecovery(reason)
	if actives["auto_farm"] ~= true then
		return
	end

	farming.__forceFieldReturn = true
	farming.__goingToHive = false
	if reason then
		warn("[special farm] requesting normal field recovery:", reason)
	end

	task.delay(2, function()
		if farming.__forceFieldReturn and actives["auto_farm"] == true and not farmingActive then
			farming.__forceFieldReturn = nil
			task.spawn(function()
				farming.farm()
			end)
		end
	end)
end

-- Wait until the converter's own completion callback has finished (including mask handling).
-- This prevents the special-farm movement from racing the conversion callback.
-- Wait for conversion to succeed, including retries, before resuming Sprout/Puffshroom.
local function convertAndWait(isCurrent, label)
	local converter = mod.convert
	if type(converter) ~= "table" or type(converter.convert) ~= "function" then
		warn("[" .. tostring(label) .. "] converter is unavailable")
		return false
	end

	local previousFinishedAt = tonumber(converter.__conversionFinishedAt) or 0

	if not converter.__running then
		local ok, err = pcall(function()
			converter.convert()
		end)
		if not ok then
			warn("[" .. tostring(label) .. "] conversion call failed:", err)
			return false
		end
	end

	-- Three attempts can each take up to 300 seconds, plus two retry delays.
	local deadline = tick() + 980
	while tick() < deadline do
		local okCurrent, current = pcall(isCurrent)
		if not okCurrent or current ~= true then
			return false
		end

		local finishedAt = tonumber(converter.__conversionFinishedAt) or 0
		if finishedAt > previousFinishedAt then
			previousFinishedAt = finishedAt

			if converter.__conversionSuccess == true then
				return true
			end

			if not converter.__running
				and not converter.__retryScheduled
				and (tonumber(converter.__retryCount) or 0) >= 2 then
				warn("[" .. tostring(label) .. "] conversion failed after all retries; staying at hive instead of returning with full pollen")
				return false
			end
		end

		task.wait(0.25)
	end

	warn("[" .. tostring(label) .. "] conversion wait exceeded its safety timeout; staying at hive")
	return false
end


function farming.sprout(...)
	local a = {...}
	if a[1] ~= true or farming.sproutActive then
		return
	end

	farming.__sproutId = farming.__sproutId or 0
	farming.__lastSproutTime = farming.__lastSproutTime or 0

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local sprout, position, resumed, lostPending
	if farming.__pendingSprout then
		if farming.__pendingSprout.Parent then
			sprout = farming.__pendingSprout
			resumed = true
			farming.__pendingSprout = nil
		else
			farming.__pendingSprout = nil
			position = farming.__sproutPosition
			resumed = true
			lostPending = position ~= nil
		end
	else
		if tick() - farming.__lastSproutTime >= 3 then
			local sprouts = workspace:FindFirstChild("Sprouts")
			if not sprouts then
				return
			end
			for _, obj in ipairs(sprouts:GetChildren()) do
				local skipUntil = farming.__sproutSkipUntil and farming.__sproutSkipUntil[obj]
				if skipUntil and skipUntil <= tick() then
					farming.__sproutSkipUntil[obj] = nil
					skipUntil = nil
				end
				if (not skipUntil) and (obj:IsA("Model") or obj:IsA("BasePart")) then
					sprout = obj
					break
				end
			end
		end
	end

	if sprout then
		local ok, pos = pcall(function()
			if sprout:IsA("Model") then
				return sprout:GetPivot().Position
			elseif sprout:IsA("BasePart") then
				return sprout.Position
			end
		end)
		if ok then
			position = pos
		end
	end

	if not position or typeof(position) ~= "Vector3" then
		if resumed then
			farming.sproutActive = false
			farming.__sproutStartTime = nil
			farming.__pendingSprout = nil
			farming.__sproutOrigField = nil
			farming.__sproutPosition = nil
		end
		return
	end

	if not resumed and not farming.__sproutOrigField then
		farming.__sproutOrigField = actives["field"]
	end

	farming.__sproutId += 1
	local sproutId = farming.__sproutId
	farming.__sproutPosition = position
	farming.sproutActive = true
	farming.__sproutStartTime = tick()
	farming.__lastSproutTime = tick()
	table.clear(queue["auto_farm"])
	table.clear(queue["tokens"])

	local function isCurrent()
		return sproutId == farming.__sproutId and actives["auto_farm"] == true
	end

	local function getPos()
		if sprout and sprout.Parent then
			if sprout:IsA("Model") then
				local part = sprout.PrimaryPart or sprout:FindFirstChildWhichIsA("BasePart", true)
				if part then return part.Position end
				local ok, pivot = pcall(function() return sprout:GetPivot() end)
				if ok then return pivot.Position end
			elseif sprout:IsA("BasePart") then
				return sprout.Position
			end
		end
		return position
	end

	local function getZone(pos)
		local zones = workspace:FindFirstChild("FlowerZones")
		if not zones then return nil end
		for _, zone in ipairs(zones:GetChildren()) do
			local cf, size
			if zone:IsA("BasePart") then
				cf, size = zone.CFrame, zone.Size
			elseif zone:IsA("Model") then
				local ok, boxCf, boxSize = pcall(function()
					return zone:GetBoundingBox()
				end)
				if ok then cf, size = boxCf, boxSize end
			end
			if cf and size then
				local localPos = cf:PointToObjectSpace(pos)
				if math.abs(localPos.X) <= size.X / 2 and math.abs(localPos.Z) <= size.Z / 2 then
					return zone.Name
				end
			end
		end
		return nil
	end

	local function moveToSpecialArea(onReached, failureLabel, onFailure)
		local targetFieldName = getZone(position)
		local zones = workspace:FindFirstChild("FlowerZones")
		local targetField = zones and targetFieldName and zones:FindFirstChild(targetFieldName)

		local currentCharacter = find.player.Character
		local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
		local currentFieldName = currentRoot and getZone(currentRoot.Position)

		local function fail(reason)
			warn("[sprout] " .. tostring(failureLabel or "special-area movement") .. " failed:", reason)
			if onFailure then onFailure(reason) end
		end

		local function moveExact()
			moveWithTimeout("move", actives["walkspeed"], position, function()
				if isCurrent() then onReached() end
			end, 90, fail, isCurrent)
		end

		if targetField and currentFieldName ~= targetFieldName then
			moveWithTimeout("go_to_field", actives["walkspeed"], targetField, function()
				if isCurrent() then moveExact() end
			end, 90, fail, isCurrent)
		else
			moveExact()
		end
	end

	local function clearSproutState()
		if sproutId ~= farming.__sproutId then return end
		farming.sproutActive = false
		farming.__sproutStartTime = nil
		farming.__pendingSprout = nil
		farming.__sproutOrigField = nil
		farming.__sproutPosition = nil
		table.clear(queue["auto_farm"])
		table.clear(queue["tokens"])
	end

	local function returnToField()
		if sproutId ~= farming.__sproutId then return end
		farming.__sproutStartTime = nil

		if actives["auto_farm"] ~= true then
			clearSproutState()
			return
		end

		local sproutField = getZone(position)
		local returnField = farming.__sproutOrigField or actives["field"] or sproutField
		if returnField then
			actives["field"] = returnField
		end

		-- Do not start a second go_to_field movement from this callback.
		-- Hand control back to the normal AutoFarm route, which owns its movement lifecycle.
		if movement.stop then pcall(movement.stop) end
		clearSproutState()
		requestFieldRecovery("Sprout collection finished; routing back to the selected field")
	end

	local function collectAtPosition()
		collectTokensNear(
			function() return getPos() or position end,
			20,
			isCurrent,
			40,
			nil
		)
		returnToField()
	end

	local function resumeAfterConversion()
		if sproutId ~= farming.__sproutId then return end
		if actives["auto_farm"] ~= true then
			clearSproutState()
			return
		end

		if sprout and sprout.Parent and actives["sprout"] == true then
			farming.__pendingSprout = sprout
			farming.__sproutPosition = position
			farming.__sproutStartTime = nil
			farming.sproutActive = false
			-- Перезапускаем metod, чтобы он подхватил __pendingSprout
			if not farmingActive then
				task.spawn(function()
					task.wait(0.2)
					farming.farm()
				end)
			end
			return
		end

		farming.__pendingSprout = nil
		farming.sproutActive = false
		farming.__sproutStartTime = tick()
		returnToField()
	end

	local function goConvertThenResume(hivePosition)
		farming.__pendingSprout = sprout
		farming.__goingToHive = true
		if movement.stop then pcall(movement.stop) end
		moveWithTimeout("hive", actives["walkspeed"], hivePosition, function()
			if sproutId ~= farming.__sproutId then return end
			actives["move"] = false
			local converted = convertAndWait(isCurrent, "sprout")
			if converted then
				resumeAfterConversion()
			else
				-- Keep the bot at the hive after failed conversion; never resume farming with a full backpack.
				farming.__pendingSprout = nil
				farming.sproutActive = false
				farming.__sproutStartTime = nil
			end
		end, 60, function(reason)
			warn("[sprout] movement to hive failed:", reason)
			farming.__goingToHive = false
			farming.__pendingSprout = nil
			returnToField()
		end, isCurrent)
	end

	local function onArrived()
		local ok, err = pcall(function()
			task.wait(0.25)
			if movement.stop then pcall(movement.stop) end
			if not isCurrent() then
				clearSproutState()
				return
			end

			if lostPending or not sprout or not sprout.Parent then
				collectAtPosition()
				return
			end

			if actives["sprinkler"] then pcall(function() farming.sprinkler(true) end) end
			local info = mod.convert.get_pollen_info()
			local threshold = tonumber(actives["backpack"]) or 80
			local failedAt = mod.convert.__failedAt
			local conversionCoolingDown = type(failedAt) == "number" and (tick() - failedAt) < 30
			if info and info.percent >= threshold and info.pollen > 0 and not conversionCoolingDown then
				local hivePosition = select(1, farming.getHive())
				if hivePosition then
					goConvertThenResume(hivePosition)
					return
				end
			end

			local state = humanoid:GetState()
			if humanoid.PlatformStand or state == Enum.HumanoidStateType.FallingDown
				or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
				humanoid.PlatformStand = false
				pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
			end

			local target
			local targetStartedAt = tick()
			local lastProgressPosition = root.Position
			local lastProgressAt = tick()
			local stuckRetargets = 0
			local lastMoveAt = 0
			local nextUptimeRefresh = tick() + 15

			while isCurrent() and sprout.Parent and actives["sprout"] do
				if find.player.Character ~= character or not root.Parent or humanoid.Health <= 0 then break end
				local sproutPos = getPos()
				if not sproutPos then break end

				local moved = (root.Position - lastProgressPosition).Magnitude
				if moved >= 0.4 then
					lastProgressPosition = root.Position
					lastProgressAt = tick()
					stuckRetargets = 0
				elseif tick() - lastProgressAt >= 3 then
					target = nil
					stuckRetargets += 1
					lastProgressAt = tick()
					lastProgressPosition = root.Position
					if stuckRetargets >= 5 then
						farming.__sproutSkipUntil = farming.__sproutSkipUntil or setmetatable({}, { __mode = "k" })
						farming.__sproutSkipUntil[sprout] = tick() + 30
						warn("[sprout] movement stalled; skipping this Sprout for 30 seconds")
						break
					end
				end

				if not target or (Vector3.new(target.X, root.Position.Y, target.Z) - root.Position).Magnitude < 1.5 then
					local angle = find.random:NextNumber(0, math.pi * 2)
					local radius = find.random:NextNumber(3, 15)
					target = Vector3.new(
						sproutPos.X + math.cos(angle) * radius,
						root.Position.Y,
						sproutPos.Z + math.sin(angle) * radius
					)
					targetStartedAt = tick()
				end

				if tick() - lastMoveAt >= 0.15 then
					lastMoveAt = tick()
					pcall(function() humanoid:MoveTo(target) end)
				end
				if tick() - targetStartedAt > 3 then
					target = nil
					targetStartedAt = tick()
				end
				if tick() >= nextUptimeRefresh then
					farming.__sproutStartTime = tick()
					nextUptimeRefresh = tick() + 15
				end
				task.wait(0.08)
			end

			if not isCurrent() then
				clearSproutState()
				return
			end
			collectAtPosition()
		end)

		if not ok then
			warn("[sprout] callback error:", err)
			if sproutId == farming.__sproutId then returnToField() end
		end
	end

	moveToSpecialArea(onArrived, lostPending and "movement to old token area" or "movement to Sprout", function()
		returnToField()
	end)
end

function farming.puffsrooms(...)
	local a = {...}
	if a[1] ~= true or farming.puffActive then
		return
	end

	farming.__puffId = farming.__puffId or 0
	farming.__lastPuffTime = farming.__lastPuffTime or 0

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local happenings = workspace:FindFirstChild("Happenings")
	local container = happenings and happenings:FindFirstChild("Puffshrooms")
	if not container then
		return
	end

	local rarityScore = { mythic = 5, legendary = 4, epic = 3, rare = 2, common = 1 }
	local function puffRarity(shroom)
		local name = string.lower(shroom.Name or "")
		for _, rarity in ipairs({ "mythic", "legendary", "epic", "rare", "common" }) do
			if string.find(name, rarity, 1, true) then
				return rarityScore[rarity]
			end
		end
		return rarityScore.common
	end

	local function listShrooms()
		local list = {}
		if not container.Parent then return list end
		for _, obj in ipairs(container:GetChildren()) do
			local skipUntil = farming.__puffSkipUntil and farming.__puffSkipUntil[obj]
			if skipUntil and skipUntil <= tick() then
				farming.__puffSkipUntil[obj] = nil
				skipUntil = nil
			end
			if (not skipUntil) and (obj:IsA("Model") or obj:IsA("BasePart")) then
				table.insert(list, obj)
			end
		end
		table.sort(list, function(x, y)
			local xr, yr = puffRarity(x), puffRarity(y)
			if xr ~= yr then return xr > yr end
			return x.Name < y.Name
		end)
		return list
	end

	local function getPos(shroom)
		if not shroom or not shroom.Parent then return nil end
		if shroom:IsA("Model") then
			local part = shroom.PrimaryPart or shroom:FindFirstChildWhichIsA("BasePart", true)
			if part then return part.Position end
			local ok, pivot = pcall(function() return shroom:GetPivot() end)
			if ok then return pivot.Position end
		elseif shroom:IsA("BasePart") then
			return shroom.Position
		end
		return nil
	end

	local function getZone(pos)
		local zones = workspace:FindFirstChild("FlowerZones")
		if not zones then return nil end
		for _, zone in ipairs(zones:GetChildren()) do
			local cf, size
			if zone:IsA("BasePart") then
				cf, size = zone.CFrame, zone.Size
			elseif zone:IsA("Model") then
				local ok, boxCf, boxSize = pcall(function() return zone:GetBoundingBox() end)
				if ok then cf, size = boxCf, boxSize end
			end
			if cf and size then
				local localPos = cf:PointToObjectSpace(pos)
				if math.abs(localPos.X) <= size.X / 2 and math.abs(localPos.Z) <= size.Z / 2 then
					return zone.Name
				end
			end
		end
		return nil
	end

	local shroom, position, resumed, lostPending
	if farming.__pendingPuff then
		if farming.__pendingPuff.Parent then
			shroom = farming.__pendingPuff
			resumed = true
			farming.__pendingPuff = nil
		else
			farming.__pendingPuff = nil
			position = farming.__puffPosition
			resumed = true
			lostPending = position ~= nil
		end
	else
		if tick() - farming.__lastPuffTime >= 1 then
			shroom = listShrooms()[1]
		end
	end

	if shroom then
		position = getPos(shroom)
	end
	if not position or typeof(position) ~= "Vector3" then
		farming.puffActive = false
		farming.__puffStartTime = nil
		farming.__puffWaiting = nil
		farming.__pendingPuff = nil
		farming.__puffOrigField = nil
		farming.__puffPosition = nil
		return
	end

	if not resumed and not farming.__puffOrigField then
		farming.__puffOrigField = actives["field"]
	end

	farming.__puffId += 1
	local puffId = farming.__puffId
	farming.__puffPosition = position
	farming.puffActive = true
	farming.__puffStartTime = tick()
	farming.__lastPuffTime = tick()
	farming.__puffWaiting = nil
	table.clear(queue["auto_farm"])
	table.clear(queue["tokens"])

	local function isCurrent()
		return puffId == farming.__puffId and actives["auto_farm"] == true
	end

	local function moveToSpecialArea(onReached, failureLabel, onFailure)
		local targetFieldName = getZone(position)
		local zones = workspace:FindFirstChild("FlowerZones")
		local targetField = zones and targetFieldName and zones:FindFirstChild(targetFieldName)

		local currentCharacter = find.player.Character
		local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
		local currentFieldName = currentRoot and getZone(currentRoot.Position)

		local function fail(reason)
			warn("[puff] " .. tostring(failureLabel or "special-area movement") .. " failed:", reason)
			if onFailure then onFailure(reason) end
		end

		local function moveExact()
			moveWithTimeout("move", actives["walkspeed"], position, function()
				if isCurrent() then onReached() end
			end, 90, fail, isCurrent)
		end

		if targetField and currentFieldName ~= targetFieldName then
			moveWithTimeout("go_to_field", actives["walkspeed"], targetField, function()
				if isCurrent() then moveExact() end
			end, 90, fail, isCurrent)
		else
			moveExact()
		end
	end

	local function clearPuffState()
		if puffId ~= farming.__puffId then return end
		farming.puffActive = false
		farming.__puffStartTime = nil
		farming.__puffWaiting = nil
		farming.__pendingPuff = nil
		farming.__puffOrigField = nil
		farming.__puffPosition = nil
		table.clear(queue["auto_farm"])
		table.clear(queue["tokens"])
	end

	local function returnToField()
		if puffId ~= farming.__puffId then return end
		farming.__puffStartTime = nil
		farming.__puffWaiting = nil

		if actives["auto_farm"] ~= true then
			clearPuffState()
			return
		end

		local puffField = getZone(position)
		local returnField = farming.__puffOrigField or actives["field"] or puffField
		if returnField then
			actives["field"] = returnField
		end

		-- Reuse AutoFarm's normal route instead of starting a competing move.
		-- This avoids waiting for an event-local go_to_field callback that may never fire.
		if movement.stop then pcall(movement.stop) end
		clearPuffState()
		requestFieldRecovery("Puffshroom collection finished; routing back to the selected field")
	end

	local function findNextShroom()
		for _, candidate in ipairs(listShrooms()) do
			if candidate ~= shroom then
				return candidate
			end
		end
		return nil
	end

	local function startNextShroom(nextShroom)
		if not nextShroom or not nextShroom.Parent or not isCurrent() then
			return false
		end
		local nextPosition = getPos(nextShroom)
		if not nextPosition then return false end
		farming.__pendingPuff = nextShroom
		farming.__puffPosition = nextPosition
		farming.puffActive = false
		farming.__puffStartTime = nil
		farming.puffsrooms(true)
		return true
	end

	local function finishAfterTokens()
		if puffId ~= farming.__puffId then return end
		farming.__puffStartTime = nil
		if not isCurrent() then
			clearPuffState()
			return
		end

		if actives["puffshrooms"] then
			local nextShroom = findNextShroom()
			if nextShroom and startNextShroom(nextShroom) then
				return
			end

			local maxWait = math.max(0, tonumber(actives["puff_wait_time"]) or 10)
			if maxWait > 0 then
				farming.__puffWaiting = true
				local waitStart = tick()
				while tick() - waitStart < maxWait and isCurrent() and actives["puffshrooms"] do
					task.wait(0.5)
					farming.__puffStartTime = tick()
					nextShroom = findNextShroom()
					if nextShroom and startNextShroom(nextShroom) then
						farming.__puffWaiting = nil
						return
					end
				end
				farming.__puffWaiting = nil
			end
		end

		returnToField()
	end

	local function collectAtPosition()
		collectTokensNear(
			function()
				local currentPosition = getPos(shroom)
				return currentPosition or position
			end,
			4,
			isCurrent,
			40,
			2.5
		)
		finishAfterTokens()
	end

	local function resumeAfterConversion()
		if puffId ~= farming.__puffId then return end
		if actives["auto_farm"] ~= true then
			clearPuffState()
			return
		end

		if shroom and shroom.Parent and actives["puffshrooms"] == true then
			farming.__pendingPuff = shroom
			farming.__puffPosition = position
			farming.__puffStartTime = nil
			farming.puffActive = false
			if not farmingActive then
				task.spawn(function()
					task.wait(0.2)
					farming.farm()
				end)
			end
			return
		end

		farming.__pendingPuff = nil
		farming.puffActive = false
		farming.__puffStartTime = tick()
		returnToField()
	end

	local function goConvertThenResume(hivePosition)
		farming.__pendingPuff = shroom or { missing = true }
		farming.__goingToHive = true
		if movement.stop then pcall(movement.stop) end
		moveWithTimeout("hive", actives["walkspeed"], hivePosition, function()
			if puffId ~= farming.__puffId then return end
			actives["move"] = false
			local converted = convertAndWait(isCurrent, "puffshroom")
			if converted then
				resumeAfterConversion()
			else
				-- Keep the bot at the hive after failed conversion; never resume farming with a full backpack.
				farming.__pendingPuff = nil
				farming.puffActive = false
				farming.__puffStartTime = nil
			end
		end, 60, function(reason)
			warn("[puffshroom] movement to hive failed:", reason)
			farming.__goingToHive = false
			farming.__pendingPuff = nil
			returnToField()
		end, isCurrent)
	end

	local function onArrived()
		local ok, err = pcall(function()
			task.wait(0.25)
			if movement.stop then pcall(movement.stop) end
			if not isCurrent() then
				clearPuffState()
				return
			end

			if lostPending or not shroom or not shroom.Parent then
				collectAtPosition()
				return
			end

			if actives["sprinkler"] then pcall(function() farming.sprinkler(true) end) end
			local info = mod.convert.get_pollen_info()
			local threshold = tonumber(actives["backpack"]) or 80
			local failedAt = mod.convert.__failedAt
			local conversionCoolingDown = type(failedAt) == "number" and (tick() - failedAt) < 30
			if info and info.percent >= threshold and info.pollen > 0 and not conversionCoolingDown then
				local hivePosition = select(1, farming.getHive())
				if hivePosition then
					goConvertThenResume(hivePosition)
					return
				end
			end

			local state = humanoid:GetState()
			if humanoid.PlatformStand or state == Enum.HumanoidStateType.FallingDown
				or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
				humanoid.PlatformStand = false
				pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
			end

			local target
			local lastProgressPosition = root.Position
			local lastProgressAt = tick()
			local lastMoveAt = 0
			local failedTargets = 0
			local nextUptimeRefresh = tick() + 15

			while isCurrent() and shroom.Parent and actives["puffshrooms"] do
				if find.player.Character ~= character or not root.Parent or humanoid.Health <= 0 then break end
				local shroomPos = getPos(shroom)
				if not shroomPos then break end

				local moved = (root.Position - lastProgressPosition).Magnitude
				if moved >= 0.4 then
					lastProgressPosition = root.Position
					lastProgressAt = tick()
					failedTargets = 0
				elseif tick() - lastProgressAt >= 3 then
					target = nil
					failedTargets += 1
					lastProgressAt = tick()
					lastProgressPosition = root.Position
					if failedTargets >= 5 then
						farming.__puffSkipUntil = farming.__puffSkipUntil or setmetatable({}, { __mode = "k" })
						farming.__puffSkipUntil[shroom] = tick() + 30
						warn("[puffshroom] movement stalled; skipping this mushroom for 30 seconds")
						break
					end
				end

				if not target or (Vector3.new(target.X, root.Position.Y, target.Z) - root.Position).Magnitude < 1.5 then
					local angle = find.random:NextNumber(0, math.pi * 2)
					local radius = find.random:NextNumber(3, 15)
					target = Vector3.new(
						shroomPos.X + math.cos(angle) * radius,
						root.Position.Y,
						shroomPos.Z + math.sin(angle) * radius
					)
				end

				if tick() - lastMoveAt >= 0.15 then
					lastMoveAt = tick()
					pcall(function() humanoid:MoveTo(target) end)
				end
				if tick() >= nextUptimeRefresh then
					farming.__puffStartTime = tick()
					nextUptimeRefresh = tick() + 15
				end
				task.wait(0.08)
			end

			if not isCurrent() then
				clearPuffState()
				return
			end
			collectAtPosition()
		end)

		if not ok then
			warn("[puffshroom] callback error:", err)
			if puffId == farming.__puffId then returnToField() end
		end
	end

	moveToSpecialArea(onArrived, lostPending and "movement to old token area" or "movement to Puffshroom", function()
		returnToField()
	end)
end

function farming.farm(...)
	local status = actives.auto_farm
	local walkspeed = actives.walkspeed

	-- Conversion owns the character while a hive balloon is being collected.
	-- Do not let any queued farm() call start a competing field route.
	if status == true and farming.__waitingForBalloon == true then
		return
	end

	if farming.__goingToHive
		and actives["convert"] ~= true
		and not (mod.convert and (mod.convert.__running or mod.convert.__retryScheduled)) then
		warn("[farming] stale __goingToHive detected, resetting to false")
		farming.__goingToHive = false
	end

	warn("[farm-call] goingToHive=", farming.__goingToHive,
		"convert=", actives["convert"],
		"running=", mod.convert and mod.convert.__running,
		"retrySched=", mod.convert and mod.convert.__retryScheduled,
		"farmingActive=", farmingActive,
		"fieldRoute=", farming.__fieldRouteInProgress)

	if not status then
		farming.__waitingForBalloon = false
		-- Invalidate any pending return-to-field movement when AutoFarm is disabled.
		farming.__fieldRouteId = (farming.__fieldRouteId or 0) + 1
		farming.__fieldRouteInProgress = false
		if farming.sproutActive or farming.__pendingSprout or farming.__sproutOrigField then
			farming.sproutActive = false
			farming.__sproutId = (farming.__sproutId or 0) + 1
			farming.__pendingSprout = nil
			farming.__sproutStartTime = nil
			farming.__sproutPosition = nil
			if farming.__sproutOrigField then
				actives["field"] = farming.__sproutOrigField
				farming.__sproutOrigField = nil
			end
		end
		if farming.puffActive or farming.__pendingPuff or farming.__puffOrigField then
			farming.puffActive = false
			farming.__puffId = (farming.__puffId or 0) + 1
			farming.__pendingPuff = nil
			farming.__puffStartTime = nil
			farming.__puffPosition = nil
			farming.__puffWaiting = nil
			if farming.__puffOrigField then
				actives["field"] = farming.__puffOrigField
				farming.__puffOrigField = nil
			end
		end
		table.clear(queue["auto_farm"])
		table.clear(queue["tokens"])
		farming.__forceFieldReturn = nil
		farming.__goingToHive = false
		if mod.convert then
			mod.convert.__retryCount = 0
			mod.convert.__retryScheduled = false
			mod.convert.__failedAt = nil
		end
		actives.move = false
		return
	end
	if farming.__goingToHive or actives["convert"] == true or (mod.convert and mod.convert.__running) then
		return
	end
	if farmingActive then
		return
	end

	if not actives["sprout"]
		and (farming.__pendingSprout or farming.sproutActive or farming.__sproutOrigField) then
		farming.sproutActive = false
		farming.__sproutId = (farming.__sproutId or 0) + 1
		farming.__pendingSprout = nil
		farming.__sproutStartTime = nil
		farming.__sproutPosition = nil
		if farming.__sproutOrigField then
			actives["field"] = farming.__sproutOrigField
			farming.__sproutOrigField = nil
		end
	end

	if not actives["puffshrooms"]
		and (farming.__pendingPuff or farming.puffActive or farming.__puffOrigField or farming.__puffWaiting) then
		farming.puffActive = false
		farming.__puffId = (farming.__puffId or 0) + 1
		farming.__pendingPuff = nil
		farming.__puffStartTime = nil
		farming.__puffPosition = nil
		farming.__puffWaiting = nil
		if farming.__puffOrigField then
			actives["field"] = farming.__puffOrigField
			farming.__puffOrigField = nil
		end
	end

	actives.move = false

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

		local fieldChanged = false

		local ok, err = pcall(function()
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
				local tp = actives["token_priorities"] or {}
				local dp = actives["drops_priorities"] or {}

				if isBubble(obj) then
					return (tonumber(actives["bubble_priority"]) or 0) * 0.2
				end

				local base = 1000
				local namePrio = tonumber(tp[obj.Name]) or tonumber(dp[obj.Name]) or 0
				local isDrop = dp[obj.Name] ~= nil

				local categoryPrio = 0
				if isDrop then
					if not actives["no_priority_drops"] then
						categoryPrio = 100
					end
				else
					if not actives["no_priotiy_tokens"] then
						categoryPrio = 200
					end
				end

				return base + categoryPrio + namePrio
			end

			local lastField = nil
			local lastRootPos = root.Position
			local stuckTicks = 0

			while actives["auto_farm"] == true do
				if farming.__forceFieldReturn then
					farming.__forceFieldReturn = nil
					fieldChanged = true
					break
				end

				actives["move"] = true

				if find.player.Character ~= character then
					break
				end
				if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
					break
				end

				if farming.__goingToHive or actives["convert"] == true or (mod.convert and mod.convert.__running) then
					actives["move"] = false
					task.wait(0.25)
					continue
				end

				if (root.Position - lastRootPos).Magnitude < 0.5 then
					stuckTicks += 1
				else
					stuckTicks = 0
				end
				lastRootPos = root.Position

				-- [FIX 1] Backpack-threshold hive trip: quickHive вместо currentPos + moveWithTimeout
				local quickInfo = mod.convert.get_pollen_info()
				local quickThr = tonumber(actives["backpack"]) or 80
				if quickInfo and quickInfo.percent >= quickThr and quickInfo.pollen > 0 then
					local now = tick()
					if mod.convert and mod.convert.__failedAt and (now - mod.convert.__failedAt) < 30 then
						task.wait(1)
						continue
					end

					local quickHive = select(1, farming.getHive())
					if quickHive then
						lastConvertTime = tick()
						farmingActive = false
						actives["move"] = false
						farming.__goingToHive = true
						farming.__hiveTripId = (farming.__hiveTripId or 0) + 1
						local hiveTripId = farming.__hiveTripId

						moveWithTimeout("hive", actives["walkspeed"], quickHive, function()
							task.wait(1)
							if hiveTripId ~= farming.__hiveTripId or actives["auto_farm"] ~= true then
								farming.__goingToHive = false
								return
							end
							local started = mod.convert.convert()
							if started == false and not mod.convert.__running then
								farming.__goingToHive = false
								task.delay(0.5, function()
									if actives["auto_farm"] == true and not farmingActive then
										farming.farm()
									end
								end)
							end
						end, 60, function(reason)
							if hiveTripId ~= farming.__hiveTripId then return end
							warn("[farming] backpack-threshold hive trip timed out:", reason)
							farming.__goingToHive = false
							actives["move"] = false
							farmingActive = false
							task.delay(1, function()
								if actives["auto_farm"] == true
									and not farming.__goingToHive
									and not (mod.convert and (mod.convert.__running or mod.convert.__retryScheduled)) then
									farming.farm()
								end
							end)
						end, function()
							return hiveTripId == farming.__hiveTripId and actives["auto_farm"] == true
						end)
						return
					end
				end

				if actives["move"] and not farming.__goingToHive then
					local currentState = humanoid:GetState()
					local onGround = (currentState == Enum.HumanoidStateType.Running  or currentState == Enum.HumanoidStateType.RunningNoPhysics or currentState == Enum.HumanoidStateType.Landed)

					if onGround then
						farming.__groundTicks = (farming.__groundTicks or 0) + 1
						if farming.__groundTicks > 300 then
							resetCharacterState()
							farming.__groundTicks = 0
						end
					else
						farming.__groundTicks = 0
					end
				else
					farming.__groundTicks = 0
				end

				if stuckTicks > 600 and (farming.sproutActive or farming.puffActive) and not (farming.__pendingSprout or farming.__pendingPuff) and not farming.__puffWaiting then
					farming.sproutActive = false
					farming.__pendingSprout = nil
					farming.__sproutId = (farming.__sproutId or 0) + 1
					farming.puffActive = false
					farming.__pendingPuff = nil
					farming.__puffId = (farming.__puffId or 0) + 1
					if movement.stop then pcall(movement.stop) end
					stuckTicks = 0
				end

				local state = humanoid:GetState()
				if humanoid.PlatformStand or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
					humanoid.PlatformStand = false
					pcall(function()
						humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					end)
				end

				if actives["puffshrooms"] and not farming.puffActive then
					local ok, err = pcall(farming.puffsrooms, true)
					if not ok then
						warn("puff", err)
						farming.puffActive       = false
						farming.__puffStartTime  = nil
						farming.__pendingPuff    = nil
					end
				end
				if farming.puffActive then
					if tick() - (farming.__puffStartTime or tick()) > 90 and not farming.__pendingPuff then
						if #queue["auto_farm"] == 0 and not farming.__puffWaiting then
							farming.puffActive      = false
							farming.__pendingPuff   = nil
							farming.__puffStartTime = nil
							farming.__puffId        = (farming.__puffId or 0) + 1
							actives["move"] = true
						end
					end
					task.wait(0.1)
					continue
				end

				if actives["sprout"] and not farming.sproutActive then
					local ok, err = pcall(farming.sprout, true)
					if not ok then
						warn("sprout", err)
						farming.sproutActive     = false
						farming.__sproutStartTime = nil
					end
				end

				if farming.sproutActive then
					if tick() - (farming.__sproutStartTime or tick()) > 90 and not farming.__pendingSprout then
						farming.sproutActive = false
						farming.__pendingSprout = nil
						farming.__sproutOrigField = nil
						farming.__sproutId = (farming.__sproutId or 0) + 1
						actives["move"] = true
					end
					task.wait(0.1)
					continue
				end

				local zones = workspace:FindFirstChild("FlowerZones")
				if actives["field"] == "" or actives["field"] == false or actives["field"] == nil then
					field = nil
				else
					field = zones:FindFirstChild(actives["field"])
				end

				if actives["field"] ~= lastField then
					local isRealChange = lastField ~= nil
					lastField = actives["field"]
					table.clear(queue["auto_farm"])
					table.clear(queue["tokens"])

					if isRealChange then
						fieldChanged = true
						break
					end
				end

				if not field then
					task.wait(.1)
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

				if #queue["tokens"] > 0 then
					if not root then
						actives["move"] = false
						return
					end

					local position = root.Position
					local speed = removeTable.speed or actives["walkspeed"]
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
				local threshold = tonumber(actives["backpack"]) or 80
				local intervalMinutes = tonumber(actives["convert_interval"]) or 15
				local interval = intervalMinutes * 60

				local byBackpack = info and info.percent >= threshold and info.pollen > 0
				local byTime = info and info.pollen > 0 and (tick() - lastConvertTime) >= interval

				if byBackpack or byTime then
					local now = tick()
					if mod.convert and mod.convert.__failedAt and (now - mod.convert.__failedAt) < 30 then
						task.wait(1)
						continue
					end

					local currentPos = select(1, farming.getHive())
					if not currentPos then
						farmingActive = false
						actives["move"] = false
						mod.convert.autoHive()
						return
					end

					-- [FIX 2] Interval hive trip: moveWithTimeout вместо сырого movement.move
					lastConvertTime = tick()
					farmingActive = false
					actives["move"] = false
					farming.__goingToHive = true
					farming.__hiveTripId = (farming.__hiveTripId or 0) + 1
					local hiveTripId = farming.__hiveTripId

					moveWithTimeout("hive", actives["walkspeed"], currentPos, function()
						task.wait(1)
						if hiveTripId ~= farming.__hiveTripId or actives["auto_farm"] ~= true then
							farming.__goingToHive = false
							return
						end
						local started = mod.convert.convert()
						if started == false and not mod.convert.__running then
							farming.__goingToHive = false
							task.delay(0.5, function()
								if actives["auto_farm"] == true and not farmingActive then
									farming.farm()
								end
							end)
						end
					end, 60, function(reason)
						if hiveTripId ~= farming.__hiveTripId then return end
						warn("[farming] interval hive trip timed out:", reason)
						farming.__goingToHive = false
						actives["move"] = false
						farmingActive = false
						task.delay(1, function()
							if actives["auto_farm"] == true
								and not farming.__goingToHive
								and not (mod.convert and (mod.convert.__running or mod.convert.__retryScheduled)) then
								farming.farm()
							end
						end)
					end, function()
						return hiveTripId == farming.__hiveTripId and actives["auto_farm"] == true
					end)
					return
				end

				task.wait()
			end
		end)

		farmingActive = false
		actives["move"] = false
		if not ok then
			warn("metod error:", err)
		end

		if fieldChanged and actives["auto_farm"] then
			task.spawn(function()
				task.wait()
				if actives["auto_farm"] and not farmingActive then
					farming.farm()
				end
			end)
		end
	end

	local function start(...)
		local a2 = {...}
		if not find.player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local pos = randomTokens(a2[1])
		table.insert(queue["auto_farm"], {targetPos = pos, speed = a2[2]})
		if not farmingActive then
			task.spawn(metod)
		end
	end

	if farming.__pendingSprout and farming.__pendingSprout.Parent then
		if not farmingActive then
			task.spawn(metod)
		end
		return
	end

	if farming.__pendingPuff and farming.__pendingPuff.Parent then
		if not farmingActive then
			task.spawn(metod)
		end
		return
	end

	if hivePos ~= nil or hiveId ~= nil then
		if not field then
			warn("[farming] cannot return to field: selected field was not found:",
				tostring(actives["field"]))
			return
		end
		if farming.__fieldRouteInProgress then
			return
		end

		resetCharacterState()
		farming.__fieldRouteId = (farming.__fieldRouteId or 0) + 1
		local routeId = farming.__fieldRouteId
		farming.__fieldRouteInProgress = true
		warn("[farming] returning to field:", tostring(actives["field"]))

		moveWithTimeout("go_to_field", walkspeed, field, function()
			if routeId ~= farming.__fieldRouteId then return end
			farming.__fieldRouteInProgress = false
			farming.__fieldRouteRetries = 0
			if not actives["auto_farm"] then
				return
			end
			warn("[farming] reached field; resuming AutoFarm")
			if not farmingActive then
				task.spawn(metod)
			end
			if actives["mask"] and actives["mask"] ~= "None" then
				local mask = actives["mask"]
				pcall(function() mod.convert.equip_mask(mask) end)
			end
			if actives["sprinkler"] then
				farming.sprinkler(true)
			end
		end, 30, function(reason)
			if routeId ~= farming.__fieldRouteId then return end
			farming.__fieldRouteInProgress = false
			farmingActive = false
			actives["move"] = false
			farming.__fieldRouteRetries = (farming.__fieldRouteRetries or 0) + 1
			warn("[farming] return-to-field route timed out; retry", farming.__fieldRouteRetries, "reason:", tostring(reason))
			task.delay(math.min(10, 2 + farming.__fieldRouteRetries), function()
				if routeId == farming.__fieldRouteId and actives["auto_farm"] == true
					and not farming.__goingToHive
					and not (mod.convert and (mod.convert.__running or mod.convert.__retryScheduled)) then
					farming.farm()
				end
			end)
		end, function()
			return routeId == farming.__fieldRouteId
		end)
	end
end

print(123123)

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

		farming.puffActive = false
		farming.__pendingPuff = nil
		farming.__puffOrigField = nil
		farming.__puffStartTime = nil
		farming.__puffWaiting = nil
		farming.__puffId = (farming.__puffId or 0) + 1
		farming.__goingToHive = nil
		farming.__waitingForBalloon = false
		farming.__forceFieldReturn = nil
		farming.__fieldRouteId = (farming.__fieldRouteId or 0) + 1
		farming.__fieldRouteInProgress = false
		farming.__fieldRouteRetries = 0
		farming.__groundTicks = 0
		farming.__watchdogPos = nil
		farming.__watchdogStuck = 0

		if mod.convert then
			mod.convert.__failedAt = nil
		end

		farming.sproutActive = false
		farming.__pendingSprout = nil
		farming.__sproutOrigField = nil
		farming.__sproutStartTime = nil
		farming.__sproutId = (farming.__sproutId or 0) + 1

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

farming.resetCharacterState = resetCharacterState

task.spawn(function()
	local cycle = 0
	while true do
		task.wait(5)
		cycle += 1

		-- Раз в 5 минут (60 циклов) чистим skip-таблицы
		if cycle % 60 == 0 then
			if farming.__sproutSkipUntil then table.clear(farming.__sproutSkipUntil) end
			if farming.__puffSkipUntil then table.clear(farming.__puffSkipUntil) end
		end

		local staleHiveLock = farming.__goingToHive == true
			and actives["convert"] ~= true
			and not (mod.convert and (mod.convert.__running or mod.convert.__retryScheduled))

		if staleHiveLock then
			farming.__goingToHive = false
			warn("[farming] watchdog: stale __goingToHive cleared")
		end

		local should_check = actives["auto_farm"] == true
			and not farmingActive
			and not farming.__goingToHive
			and not farming.__waitingForBalloon
			and not farming.__fieldRouteInProgress
			and not actives["convert"]

		if should_check then
			local character = find.player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root then
				if not farming.__watchdogPos then
					farming.__watchdogPos = root.Position
					farming.__watchdogStuck = 0
				else
					local moved = (root.Position - farming.__watchdogPos).Magnitude
					if moved < 3 then
						farming.__watchdogStuck = (farming.__watchdogStuck or 0) + 1
						if farming.__watchdogStuck >= 4 then
							warn("[farming] watchdog: bot stuck for 20s, restarting farm")
							warn("[watchdog-state] running=", farmingActive,
								"sprout=", farming.sproutActive,
								"puff=", farming.puffActive,
								"pendingS=", farming.__pendingSprout ~= nil,
								"pendingP=", farming.__pendingPuff ~= nil)
							farming.__watchdogStuck = 0
							farming.__watchdogPos = nil
							if farming.farm then farming.farm() end
						end
					else
						farming.__watchdogStuck = 0
						farming.__watchdogPos = root.Position
					end
				end
			end
		else
			farming.__watchdogPos = nil
			farming.__watchdogStuck = 0
		end
	end
end)

return farming
