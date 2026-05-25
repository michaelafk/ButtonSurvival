--[[
    EarthquakeEvent.luau

    Evento global: "Earthquake"

    Version ajustada:
    - No crea escombros externos que caen del cielo.
    - Las zonas rojas son el peligro real: solo mueres si estas dentro cuando impacta.
    - Cada temblor genera mas zonas rojas, con destruccion localizada en esas zonas.
    - Si una carpeta grande como "Ciudad" tiene DestroyInEarthquake = true, se registran sus piezas,
      pero cada temblor solo rompe pocas piezas en la zona marcada.
    - La vibracion fisica es leve; no debe matar por empujones ni por piezas rebotando.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local EarthquakeEvent = {}

local CONFIG = {
	EVENT_DURATION = 45,
	PLAYER_SPACING = 6,
	INITIAL_DELAY = 2,

	TREMOR_INTERVAL_MIN = 5,
	TREMOR_INTERVAL_MAX = 10,
	IMPACTS_PER_TREMOR_MIN = 3,
	IMPACTS_PER_TREMOR_MAX = 6,

	WARNING_TIME = 2.1,
	IMPACT_RADIUS = 15,
	IMPACT_KILL_HEIGHT = 20,

	-- Destruccion localizada y controlada.
	MAX_PARTS_DESTROYED_PER_IMPACT = 3,
	MAX_TOTAL_PARTS_DESTROYED = 110,

	-- Fuerza baja para que el mapa tiemble sin explotar.
	DESTRUCTION_PUSH_SPEED = 12,
	DESTRUCTION_UP_SPEED = 3.5,
	DESTRUCTION_ANGULAR_SPEED = 2.5,

	LOOSE_PART_REACTIVATION_SPEED = 5,
	LOOSE_PART_UP_SPEED = 1.5,
	LOOSE_PART_SHAKE_RADIUS = 8,

	-- Sacudida leve al jugador. El peligro real debe ser la zona roja.
	PLAYER_SHAKE_SPEED = 0.8,

	ENABLE_MOVING_PART_DAMAGE = false,
	MIN_DESTRUCTIBLE_KILL_SPEED = 85,

	FALLBACK_IMPACT_RANGE = 80,

	-- Evita romper piezas enormes como suelo, carretera o bloques base.
	MAX_PART_VOLUME_TO_BREAK = 12000,
	MAX_PART_AXIS_TO_BREAK = 125,
}

local DESTROY_ATTRIBUTE = "DestroyInEarthquake"

local activeConnections = {}
local spawnedObjects = {}
local originalPartStates = {}
local destructibleParts = {}
local destructiblePartSet = {}
local destructedParts = {}
local looseParts = {}
local loosePartSet = {}
local damageConnectedParts = {}
local totalDestroyedParts = 0
local activeToken = 0
local eventActive = false

function EarthquakeEvent.GetDuration()
	return CONFIG.EVENT_DURATION
end

-- Funciones auxiliares

local function getHumanoid(player)
	local character = player and player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function isPlayerAlive(player)
	local humanoid = getHumanoid(player)
	return humanoid and humanoid.Health > 0
end

local function getAlivePlayers(players)
	local alivePlayers = {}

	for _, player in ipairs(players) do
		if isPlayerAlive(player) then
			table.insert(alivePlayers, player)
		end
	end

	return alivePlayers
end

local function getEventObjectsFolder()
	return workspace:FindFirstChild("EventObjects")
end

local function getPartFrom(parent, partName)
	if not parent then
		return nil
	end

	local part = parent:FindFirstChild(partName)
	if part and part:IsA("BasePart") then
		return part
	end

	return nil
end

local function getDestructibleRoot(eventObjects)
	if not eventObjects then
		return nil
	end

	return eventObjects:FindFirstChild("Destructible")
end

local function getImpactPointsRoot(eventObjects)
	if not eventObjects then
		return nil
	end

	return eventObjects:FindFirstChild("EarthquakeImpactPoints")
end

local function getMapReferences()
	local eventObjects = getEventObjectsFolder()
	if not eventObjects then
		warn("[EarthquakeEvent] Falta la carpeta Workspace/EventObjects")
		return nil
	end

	local spawnPart = getPartFrom(eventObjects, "EarthquakeSpawn") or workspace:FindFirstChild("MapSpawn")
	local destructibleRoot = getDestructibleRoot(eventObjects)
	local impactPointsRoot = getImpactPointsRoot(eventObjects)

	if not spawnPart then
		warn("[EarthquakeEvent] Falta EventObjects/EarthquakeSpawn o Workspace/MapSpawn")
		return nil
	end

	return {
		Spawn = spawnPart,
		EventObjects = eventObjects,
		DestructibleRoot = destructibleRoot,
		ImpactPointsRoot = impactPointsRoot,
	}
end

local function teleportPlayersToSpawn(players, spawnPart)
	for index, player in ipairs(players) do
		local rootPart = getRootPart(player)
		if rootPart then
			local row = math.floor((index - 1) / 4)
			local column = (index - 1) % 4
			local offset = Vector3.new((column - 1.5) * CONFIG.PLAYER_SPACING, 4, row * CONFIG.PLAYER_SPACING)
			rootPart.CFrame = spawnPart.CFrame + offset
		end
	end
end

local function hasDestroyAttributeInAncestry(instance, destructibleRoot)
	local current = instance

	while current and current ~= destructibleRoot.Parent do
		if current:GetAttribute(DESTROY_ATTRIBUTE) == true then
			return true
		end

		if current == destructibleRoot then
			break
		end

		current = current.Parent
	end

	return false
end

local function isPartSizeSafeToBreak(part)
	local size = part.Size
	local maxAxis = math.max(size.X, size.Y, size.Z)
	local volume = size.X * size.Y * size.Z

	return maxAxis <= CONFIG.MAX_PART_AXIS_TO_BREAK and volume <= CONFIG.MAX_PART_VOLUME_TO_BREAK
end

local function isDestructiblePartCandidate(part, destructibleRoot)
	if not part:IsA("BasePart") then
		return false
	end

	if not hasDestroyAttributeInAncestry(part, destructibleRoot) then
		return false
	end

	if not isPartSizeSafeToBreak(part) then
		return false
	end

	return true
end

local function registerDestructibleParts(destructibleRoot)
	originalPartStates = {}
	destructibleParts = {}
	destructiblePartSet = {}
	destructedParts = {}
	looseParts = {}
	loosePartSet = {}
	damageConnectedParts = {}
	totalDestroyedParts = 0

	if not destructibleRoot then
		warn("[EarthquakeEvent] No hay carpeta EventObjects/Destructible. El terremoto usara impactos sin destruir piezas.")
		return
	end

	for _, descendant in ipairs(destructibleRoot:GetDescendants()) do
		if descendant:IsA("BasePart") and isDestructiblePartCandidate(descendant, destructibleRoot) then
			originalPartStates[descendant] = {
				CFrame = descendant.CFrame,
				Anchored = descendant.Anchored,
				CanCollide = descendant.CanCollide,
				CanTouch = descendant.CanTouch,
				CanQuery = descendant.CanQuery,
				Transparency = descendant.Transparency,
			}

			destructiblePartSet[descendant] = true
			table.insert(destructibleParts, descendant)
			descendant.CanQuery = true
		end
	end

	print("[EarthquakeEvent] Piezas destructibles registradas:", #destructibleParts)

	if #destructibleParts == 0 then
		warn("[EarthquakeEvent] No hay piezas validas con " .. DESTROY_ATTRIBUTE .. " = true dentro de EventObjects/Destructible.")
	end
end

local function getAvailableDestructibleParts()
	local availableParts = {}

	for _, part in ipairs(destructibleParts) do
		if part and part.Parent and not destructedParts[part] then
			table.insert(availableParts, part)
		end
	end

	return availableParts
end

local function getAvailableLooseParts()
	local availableParts = {}

	for _, part in ipairs(looseParts) do
		if part and part.Parent and not part.Anchored then
			table.insert(availableParts, part)
		end
	end

	return availableParts
end

local function getRandomLoosePart()
	local availableParts = getAvailableLooseParts()
	if #availableParts == 0 then
		return nil
	end

	return availableParts[math.random(1, #availableParts)]
end

local function getRandomImpactPointFromFolder(impactPointsRoot)
	if not impactPointsRoot then
		return nil
	end

	local points = {}
	for _, descendant in ipairs(impactPointsRoot:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(points, descendant)
		end
	end

	if #points == 0 then
		return nil
	end

	return points[math.random(1, #points)].Position
end

local function getGroundPosition(position, eventObjects)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { eventObjects }

	local rayOrigin = position + Vector3.new(0, 150, 0)
	local rayDirection = Vector3.new(0, -350, 0)
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if result then
		return result.Position
	end

	return Vector3.new(position.X, position.Y, position.Z)
end

local function getFallbackImpactPosition(spawnPart, impactPointsRoot)
	local impactPoint = getRandomImpactPointFromFolder(impactPointsRoot)
	if impactPoint then
		return impactPoint
	end

	local randomOffset = Vector3.new(
		math.random(-CONFIG.FALLBACK_IMPACT_RANGE, CONFIG.FALLBACK_IMPACT_RANGE),
		0,
		math.random(-CONFIG.FALLBACK_IMPACT_RANGE, CONFIG.FALLBACK_IMPACT_RANGE)
	)

	return spawnPart.Position + randomOffset
end

local function createImpactMarker(position)
	local marker = Instance.new("Part")
	marker.Name = "EarthquakeImpactMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.fromRGB(255, 45, 45)
	marker.Transparency = 0.35
	marker.Size = Vector3.new(CONFIG.IMPACT_RADIUS * 2, 0.25, CONFIG.IMPACT_RADIUS * 2)
	marker.CFrame = CFrame.new(position + Vector3.new(0, 0.18, 0))
	marker.Parent = workspace

	table.insert(spawnedObjects, marker)
	return marker
end

local function createWarningPulse(position)
	local pulse = Instance.new("Part")
	pulse.Name = "EarthquakeWarningPulse"
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanTouch = false
	pulse.CanQuery = false
	pulse.Material = Enum.Material.Neon
	pulse.Color = Color3.fromRGB(255, 130, 50)
	pulse.Transparency = 0.45
	pulse.Size = Vector3.new(CONFIG.IMPACT_RADIUS * 1.2, 0.15, CONFIG.IMPACT_RADIUS * 1.2)
	pulse.CFrame = CFrame.new(position + Vector3.new(0, 0.28, 0))
	pulse.Parent = workspace

	table.insert(spawnedObjects, pulse)

	local tween = TweenService:Create(
		pulse,
		TweenInfo.new(CONFIG.WARNING_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(CONFIG.IMPACT_RADIUS * 2.5, 0.15, CONFIG.IMPACT_RADIUS * 2.5),
			Transparency = 1,
		}
	)
	tween:Play()

	task.delay(CONFIG.WARNING_TIME, function()
		if pulse and pulse.Parent then
			pulse:Destroy()
		end
	end)
end

local function killPlayersInsideImpact(players, impactPosition)
	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)
		local rootPart = getRootPart(player)

		if humanoid and rootPart and humanoid.Health > 0 then
			local horizontalDistance = Vector3.new(
				rootPart.Position.X - impactPosition.X,
				0,
				rootPart.Position.Z - impactPosition.Z
			).Magnitude
			local verticalDistance = math.abs(rootPart.Position.Y - impactPosition.Y)

			if horizontalDistance <= CONFIG.IMPACT_RADIUS and verticalDistance <= CONFIG.IMPACT_KILL_HEIGHT then
				humanoid.Health = 0
			end
		end
	end
end

local function connectMovingPartDamage(part)
	if not CONFIG.ENABLE_MOVING_PART_DAMAGE then
		return
	end

	if damageConnectedParts[part] then
		return
	end

	damageConnectedParts[part] = true

	local connection = part.Touched:Connect(function(hit)
		if part.AssemblyLinearVelocity.Magnitude < CONFIG.MIN_DESTRUCTIBLE_KILL_SPEED then
			return
		end

		local player = getPlayerFromHit(hit)
		if player then
			local humanoid = getHumanoid(player)
			if humanoid then
				humanoid.Health = 0
			end
		end
	end)

	table.insert(activeConnections, connection)
end

local function registerLoosePart(part)
	if loosePartSet[part] then
		return
	end

	loosePartSet[part] = true
	table.insert(looseParts, part)
end

local function getRandomHorizontalDirection()
	local direction = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
	if direction.Magnitude <= 0.01 then
		direction = Vector3.new(1, 0, 0)
	end

	return direction.Unit
end

local function breakDestructiblePart(part, impactPosition)
	if not part or not part.Parent or destructedParts[part] or not originalPartStates[part] then
		return false
	end

	if totalDestroyedParts >= CONFIG.MAX_TOTAL_PARTS_DESTROYED then
		return false
	end

	destructedParts[part] = true
	totalDestroyedParts += 1

	local direction = part.Position - impactPosition
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)

	if horizontalDirection.Magnitude <= 0.01 then
		horizontalDirection = getRandomHorizontalDirection()
	else
		horizontalDirection = horizontalDirection.Unit
	end

	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.AssemblyLinearVelocity = horizontalDirection * CONFIG.DESTRUCTION_PUSH_SPEED + Vector3.new(0, CONFIG.DESTRUCTION_UP_SPEED, 0)
	part.AssemblyAngularVelocity = Vector3.new(
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED,
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED,
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED
	)

	connectMovingPartDamage(part)
	registerLoosePart(part)

	return true
end

local function shakeLoosePart(part, originPosition)
	if not part or not part.Parent then
		return
	end

	local direction = part.Position - originPosition
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
	if horizontalDirection.Magnitude <= 0.01 then
		horizontalDirection = getRandomHorizontalDirection()
	else
		horizontalDirection = horizontalDirection.Unit
	end

	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.AssemblyLinearVelocity = horizontalDirection * CONFIG.LOOSE_PART_REACTIVATION_SPEED
		+ Vector3.new(0, CONFIG.LOOSE_PART_UP_SPEED, 0)
	part.AssemblyAngularVelocity = Vector3.new(
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED,
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED,
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED
	)

	connectMovingPartDamage(part)
end

local function shakeLoosePartsAround(position)
	for _, part in ipairs(getAvailableLooseParts()) do
		local horizontalDistance = Vector3.new(
			part.Position.X - position.X,
			0,
			part.Position.Z - position.Z
		).Magnitude

		if horizontalDistance <= CONFIG.LOOSE_PART_SHAKE_RADIUS then
			shakeLoosePart(part, position)
		end
	end
end

local function shakePlayers(players)
	if CONFIG.PLAYER_SHAKE_SPEED <= 0 then
		return
	end

	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)
		local rootPart = getRootPart(player)

		if humanoid and rootPart and humanoid.Health > 0 then
			rootPart.AssemblyLinearVelocity += getRandomHorizontalDirection() * CONFIG.PLAYER_SHAKE_SPEED
		end
	end
end

local function getPartsAround(position, radius)
	local parts = {}

	for _, part in ipairs(getAvailableDestructibleParts()) do
		local horizontalDistance = Vector3.new(
			part.Position.X - position.X,
			0,
			part.Position.Z - position.Z
		).Magnitude

		if horizontalDistance <= radius then
			table.insert(parts, part)
		end
	end

	return parts
end

local function breakPartsAroundImpact(targetPart, impactPosition)
	local destroyedCount = 0

	if targetPart then
		if breakDestructiblePart(targetPart, impactPosition) then
			destroyedCount += 1
		end
	end

	local nearbyParts = getPartsAround(impactPosition, CONFIG.IMPACT_RADIUS)
	for _, part in ipairs(nearbyParts) do
		if destroyedCount >= CONFIG.MAX_PARTS_DESTROYED_PER_IMPACT then
			break
		end

		if part ~= targetPart and breakDestructiblePart(part, impactPosition) then
			destroyedCount += 1
		end
	end

	return destroyedCount
end

local function resolveImpact(impactData, players, token)
	if not eventActive or activeToken ~= token then
		return
	end

	if impactData.Marker and impactData.Marker.Parent then
		impactData.Marker:Destroy()
	end

	killPlayersInsideImpact(players, impactData.Position)

	if impactData.TargetPart then
		local destroyedCount = breakPartsAroundImpact(impactData.TargetPart, impactData.Position)
		print("[EarthquakeEvent] Piezas destruidas en impacto:", destroyedCount)
	elseif impactData.LoosePart then
		shakeLoosePartsAround(impactData.Position)
	else
		-- Si no quedan piezas nuevas ni piezas sueltas, solo queda el peligro de zona roja.
	end
end

local function createImpactWarning(impactData, players, token)
	local marker = createImpactMarker(impactData.Position)
	impactData.Marker = marker
	createWarningPulse(impactData.Position)

	task.delay(CONFIG.WARNING_TIME, function()
		resolveImpact(impactData, players, token)
	end)
end

local function chooseImpactData(mapReferences, reservedParts)
	local availableParts = getAvailableDestructibleParts()
	local targetPart = nil
	local loosePart = nil
	local position = nil

	if #availableParts > 0 then
		local attempts = 0

		while attempts < 20 do
			local candidate = availableParts[math.random(1, #availableParts)]
			if not reservedParts[candidate] then
				targetPart = candidate
				reservedParts[candidate] = true
				position = candidate.Position
				break
			end

			attempts += 1
		end

		if not targetPart then
			targetPart = availableParts[math.random(1, #availableParts)]
			position = targetPart.Position
		end
	else
		loosePart = getRandomLoosePart()
		if loosePart then
			position = loosePart.Position
		else
			position = getFallbackImpactPosition(mapReferences.Spawn, mapReferences.ImpactPointsRoot)
		end
	end

	if not position then
		position = getFallbackImpactPosition(mapReferences.Spawn, mapReferences.ImpactPointsRoot)
	end

	local groundPosition = getGroundPosition(position, mapReferences.EventObjects)

	return {
		TargetPart = targetPart,
		LoosePart = loosePart,
		Position = groundPosition,
	}
end

local function triggerTremor(mapReferences, players, token)
	print("[EarthquakeEvent] Temblor")
	shakePlayers(players)

	local impactCount = math.random(CONFIG.IMPACTS_PER_TREMOR_MIN, CONFIG.IMPACTS_PER_TREMOR_MAX)
	local reservedParts = {}

	for _ = 1, impactCount do
		local impactData = chooseImpactData(mapReferences, reservedParts)
		createImpactWarning(impactData, players, token)
	end
end

local function restoreDestructibleParts()
	for part, state in pairs(originalPartStates) do
		if part and part.Parent then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			part.Anchored = true
			part.CFrame = state.CFrame
			part.CanCollide = state.CanCollide
			part.CanTouch = state.CanTouch
			part.CanQuery = state.CanQuery
			part.Transparency = state.Transparency
			part.Anchored = state.Anchored
		end
	end

	originalPartStates = {}
	destructibleParts = {}
	destructiblePartSet = {}
	destructedParts = {}
	looseParts = {}
	loosePartSet = {}
	damageConnectedParts = {}
	totalDestroyedParts = 0
end

local function disconnectAllConnections()
	for _, connection in ipairs(activeConnections) do
		connection:Disconnect()
	end

	activeConnections = {}
end

local function destroySpawnedObjects()
	for _, object in ipairs(spawnedObjects) do
		if object and object.Parent then
			object:Destroy()
		end
	end

	spawnedObjects = {}
end

local function finishEvent(players, winner, onEventFinished, token)
	if not eventActive or activeToken ~= token then
		return
	end

	print("[EarthquakeEvent] Evento terminado. Resultado:", winner)
	EarthquakeEvent.Cleanup(players)
	onEventFinished(winner)
end

function EarthquakeEvent.Start(players, onEventFinished)
	local mapReferences = getMapReferences()
	if not mapReferences then
		onEventFinished("NoWinner")
		return
	end

	eventActive = true
	activeToken += 1
	local token = activeToken

	print("[EarthquakeEvent] Iniciando evento terremoto")

	registerDestructibleParts(mapReferences.DestructibleRoot)
	teleportPlayersToSpawn(players, mapReferences.Spawn)

	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)
		if humanoid then
			local connection = humanoid.Died:Connect(function()
				print("[EarthquakeEvent] Jugador muerto:", player.Name)
			end)

			table.insert(activeConnections, connection)
		end
	end

	task.spawn(function()
		local finishAt = os.clock() + CONFIG.EVENT_DURATION
		task.wait(CONFIG.INITIAL_DELAY)

		while eventActive and activeToken == token and os.clock() < finishAt do
			if #getAlivePlayers(players) == 0 then
				finishEvent(players, "Earthquake", onEventFinished, token)
				return
			end

			triggerTremor(mapReferences, players, token)

			local waitTime = math.random(CONFIG.TREMOR_INTERVAL_MIN, CONFIG.TREMOR_INTERVAL_MAX)
			local remainingTime = finishAt - os.clock()
			if remainingTime <= 0 then
				break
			end

			task.wait(math.min(waitTime, remainingTime))
		end

		if #getAlivePlayers(players) > 0 then
			finishEvent(players, "Survivors", onEventFinished, token)
		else
			finishEvent(players, "Earthquake", onEventFinished, token)
		end
	end)
end

function EarthquakeEvent.FinishByTime(players, onEventFinished)
	EarthquakeEvent.Cleanup(players)
	onEventFinished("Survivors")
end

function EarthquakeEvent.Cleanup(players)
	eventActive = false
	activeToken += 1

	disconnectAllConnections()
	destroySpawnedObjects()
	restoreDestructibleParts()

	activeConnections = {}
	spawnedObjects = {}
end

return EarthquakeEvent
