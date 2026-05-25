--[[
    TsunamiEvent.luau

    Evento global: "Tsunami"

    Version ajustada:
    - La ola sigue matando al jugador si lo toca.
    - La destruccion queda limitada a piezas concretas, no a modelos completos.
    - Si una carpeta grande como "Ciudad" tiene DestroyInTsunami = true, no se rompe toda de golpe:
      se registran sus piezas internas y se rompen pocas por pasada.
    - Se reduce mucho la fuerza aplicada a los objetos para evitar muertes inevitables y destruccion exagerada.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local TsunamiEvent = {}

local CONFIG = {
	TRAVEL_TIME = 55,
	PLAYER_SPACING = 6,

	WAVE_WIDTH = 240,
	WAVE_HEIGHT = 28,
	WAVE_THICKNESS = 16,
	WAVE_COLOR = Color3.fromRGB(0, 140, 255),
	WAVE_FOAM_COLOR = Color3.fromRGB(235, 250, 255),
	WAVE_TRANSPARENCY = 0.35,
	WAVE_FOAM_TRANSPARENCY = 0.15,
	WAVE_FOAM_PARTS = 18,

	-- Destruccion controlada.
	DESTRUCTION_CHECK_INTERVAL = 0.14,
	MAX_PARTS_DESTROYED_PER_CHECK = 2,
	MAX_TOTAL_PARTS_DESTROYED = 70,

	-- Fuerza baja: visualmente se desplazan, pero no arrasan medio mapa.
	DESTRUCTION_PUSH_SPEED = 16,
	DESTRUCTION_UP_SPEED = 3,
	DESTRUCTION_ANGULAR_SPEED = 1.5,

	-- Para que no sea una muerte inevitable por objetos rebotando.
	ENABLE_DESTRUCTIBLE_DAMAGE = false,
	MIN_DESTRUCTIBLE_KILL_SPEED = 85,

	-- Evita romper piezas enormes como suelo, carretera o bloques base.
	MAX_PART_VOLUME_TO_BREAK = 6000,
	MAX_PART_AXIS_TO_BREAK = 90,
}

local DESTROY_ATTRIBUTE = "DestroyInTsunami"

local activeConnections = {}
local spawnedObjects = {}
local originalPartStates = {}
local destructibleParts = {}
local destructiblePartSet = {}
local destructedParts = {}
local totalDestroyedParts = 0
local activeMoveToken = 0
local eventActive = false

function TsunamiEvent.GetDuration()
	return CONFIG.TRAVEL_TIME
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

local function getSafeZones(eventObjects, finishZone)
	local safeZones = {}

	local safeZonesFolder = eventObjects and eventObjects:FindFirstChild("TsunamiSafeZones")
	if safeZonesFolder then
		for _, descendant in ipairs(safeZonesFolder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(safeZones, descendant)
			end
		end
	end

	if finishZone and finishZone:IsA("BasePart") then
		table.insert(safeZones, finishZone)
	end

	return safeZones
end

local function getMapReferences()
	local eventObjects = getEventObjectsFolder()
	if not eventObjects then
		warn("[TsunamiEvent] Falta la carpeta Workspace/EventObjects")
		return nil
	end

	local spawnPart = getPartFrom(eventObjects, "TsunamiSpawn") or workspace:FindFirstChild("MapSpawn")
	local startPart = getPartFrom(eventObjects, "TsunamiStart")
	local endPart = getPartFrom(eventObjects, "TsunamiEnd")
	local finishZone = getPartFrom(eventObjects, "TsunamiFinishZone")
	local destructibleRoot = getDestructibleRoot(eventObjects)
	local safeZones = getSafeZones(eventObjects, finishZone)

	if not spawnPart or not startPart or not endPart or not finishZone then
		warn("[TsunamiEvent] Faltan partes: EventObjects/TsunamiStart, EventObjects/TsunamiEnd, EventObjects/TsunamiFinishZone y TsunamiSpawn o MapSpawn")
		return nil
	end

	return {
		Spawn = spawnPart,
		Start = startPart,
		End = endPart,
		FinishZone = finishZone,
		SafeZones = safeZones,
		DestructibleRoot = destructibleRoot,
	}
end

local function isPlayerAlive(player)
	local humanoid = getHumanoid(player)
	return humanoid and humanoid.Health > 0
end

local function isPositionInsidePart(position, part)
	local relativePosition = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size / 2

	return math.abs(relativePosition.X) <= halfSize.X
		and math.abs(relativePosition.Y) <= halfSize.Y
		and math.abs(relativePosition.Z) <= halfSize.Z
end

local function isPlayerInSafeZone(player, safeZones)
	local rootPart = getRootPart(player)
	if not rootPart then
		return false
	end

	for _, safeZone in ipairs(safeZones) do
		if isPositionInsidePart(rootPart.Position, safeZone) then
			return true
		end
	end

	return false
end

local function getEventResult(players, safeZones)
	for _, player in ipairs(players) do
		if isPlayerAlive(player) and isPlayerInSafeZone(player, safeZones) then
			return "Survivors"
		end
	end

	return "Tsunami"
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

local function getTsunamiDirection(startPart, endPart)
	local direction = endPart.Position - startPart.Position
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)

	if horizontalDirection.Magnitude <= 0.01 then
		return Vector3.new(0, 0, -1)
	end

	return horizontalDirection.Unit
end

local function getWaveCFrame(markerPart, direction)
	local centerPosition = markerPart.Position + Vector3.new(0, CONFIG.WAVE_HEIGHT / 2, 0)
	return CFrame.lookAt(centerPosition, centerPosition + direction)
end

local function createWavePart(parent, name, className, size, offsetCFrame, color, transparency, material)
	local part = Instance.new(className)
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = material or Enum.Material.Neon
	part.Color = color
	part.Transparency = transparency
	part.Size = size
	part.CFrame = parent:GetPivot() * offsetCFrame
	part.Parent = parent
	return part
end

local function createTsunami(startPart, endPart)
	local direction = getTsunamiDirection(startPart, endPart)
	local startCFrame = getWaveCFrame(startPart, direction)

	local tsunamiModel = Instance.new("Model")
	tsunamiModel.Name = "ActiveTsunami"
	tsunamiModel:PivotTo(startCFrame)
	tsunamiModel.Parent = workspace

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = true
	hitbox.Transparency = 1
	hitbox.Size = Vector3.new(CONFIG.WAVE_WIDTH, CONFIG.WAVE_HEIGHT, CONFIG.WAVE_THICKNESS)
	hitbox.CFrame = startCFrame
	hitbox.Parent = tsunamiModel
	tsunamiModel.PrimaryPart = hitbox

	createWavePart(
		tsunamiModel,
		"WaterBody",
		"Part",
		Vector3.new(CONFIG.WAVE_WIDTH, CONFIG.WAVE_HEIGHT * 0.78, CONFIG.WAVE_THICKNESS * 0.9),
		CFrame.new(0, -CONFIG.WAVE_HEIGHT * 0.08, 0),
		CONFIG.WAVE_COLOR,
		CONFIG.WAVE_TRANSPARENCY,
		Enum.Material.Neon
	)

	createWavePart(
		tsunamiModel,
		"WaveFrontSlope",
		"WedgePart",
		Vector3.new(CONFIG.WAVE_WIDTH, CONFIG.WAVE_HEIGHT * 0.55, CONFIG.WAVE_THICKNESS * 0.8),
		CFrame.new(0, -CONFIG.WAVE_HEIGHT * 0.18, -CONFIG.WAVE_THICKNESS * 0.45) * CFrame.Angles(0, math.rad(180), 0),
		CONFIG.WAVE_COLOR,
		CONFIG.WAVE_TRANSPARENCY + 0.08,
		Enum.Material.Neon
	)

	local crest = createWavePart(
		tsunamiModel,
		"WaveCrest",
		"Part",
		Vector3.new(CONFIG.WAVE_HEIGHT * 0.42, CONFIG.WAVE_WIDTH, CONFIG.WAVE_HEIGHT * 0.42),
		CFrame.new(0, CONFIG.WAVE_HEIGHT * 0.38, -CONFIG.WAVE_THICKNESS * 0.42) * CFrame.Angles(0, 0, math.rad(90)),
		CONFIG.WAVE_COLOR,
		CONFIG.WAVE_TRANSPARENCY,
		Enum.Material.Neon
	)
	crest.Shape = Enum.PartType.Cylinder

	createWavePart(
		tsunamiModel,
		"FrontFoam",
		"Part",
		Vector3.new(CONFIG.WAVE_WIDTH, 2, 3),
		CFrame.new(0, CONFIG.WAVE_HEIGHT * 0.1, -CONFIG.WAVE_THICKNESS * 0.62),
		CONFIG.WAVE_FOAM_COLOR,
		CONFIG.WAVE_FOAM_TRANSPARENCY,
		Enum.Material.Neon
	)

	for index = 1, CONFIG.WAVE_FOAM_PARTS do
		local x = -CONFIG.WAVE_WIDTH / 2 + (CONFIG.WAVE_WIDTH / (CONFIG.WAVE_FOAM_PARTS + 1)) * index
		local y = CONFIG.WAVE_HEIGHT * (0.32 + math.random() * 0.2)
		local z = -CONFIG.WAVE_THICKNESS * (0.45 + math.random() * 0.25)
		local foamSize = math.random(3, 7)

		local foam = createWavePart(
			tsunamiModel,
			"Foam" .. index,
			"Part",
			Vector3.new(foamSize, foamSize, foamSize),
			CFrame.new(x, y, z),
			CONFIG.WAVE_FOAM_COLOR,
			CONFIG.WAVE_FOAM_TRANSPARENCY,
			Enum.Material.Neon
		)
		foam.Shape = Enum.PartType.Ball
	end

	return tsunamiModel, hitbox, direction
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

	if destructedParts[part] then
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
	totalDestroyedParts = 0

	if not destructibleRoot then
		warn("[TsunamiEvent] No hay carpeta EventObjects/Destructible. El tsunami no rompera objetos.")
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

	print("[TsunamiEvent] Piezas destructibles registradas:", #destructibleParts)

	if #destructibleParts == 0 then
		warn("[TsunamiEvent] No hay piezas validas con " .. DESTROY_ATTRIBUTE .. " = true dentro de EventObjects/Destructible.")
	end
end

local function connectDestructibleDamage(part)
	if not CONFIG.ENABLE_DESTRUCTIBLE_DAMAGE then
		return
	end

	local connection = part.Touched:Connect(function(hit)
		if not destructedParts[part] then
			return
		end

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

local function breakDestructiblePart(part, direction)
	if destructedParts[part] or not originalPartStates[part] then
		return false
	end

	if totalDestroyedParts >= CONFIG.MAX_TOTAL_PARTS_DESTROYED then
		return false
	end

	destructedParts[part] = true
	totalDestroyedParts += 1

	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.AssemblyLinearVelocity = direction * CONFIG.DESTRUCTION_PUSH_SPEED + Vector3.new(0, CONFIG.DESTRUCTION_UP_SPEED, 0)
	part.AssemblyAngularVelocity = Vector3.new(
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED,
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED,
		math.random() * CONFIG.DESTRUCTION_ANGULAR_SPEED
	)

	connectDestructibleDamage(part)
	return true
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

local function killPlayersInsideWave(players, waveHitbox)
	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)
		local rootPart = getRootPart(player)

		if humanoid and rootPart and humanoid.Health > 0 and isPositionInsidePart(rootPart.Position, waveHitbox) then
			humanoid.Health = 0
		end
	end
end

local function breakDestructiblesInsideWave(waveHitbox, direction, destructibleRoot)
	if not destructibleRoot then
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { destructibleRoot }
	overlapParams.RespectCanCollide = false

	local touchedParts = workspace:GetPartsInPart(waveHitbox, overlapParams)
	local destroyedThisCheck = 0

	for _, part in ipairs(touchedParts) do
		if destructiblePartSet[part] and not destructedParts[part] then
			local broke = breakDestructiblePart(part, direction)
			if broke then
				destroyedThisCheck += 1
			end
		end

		if destroyedThisCheck >= CONFIG.MAX_PARTS_DESTROYED_PER_CHECK then
			break
		end
	end
end

local function moveTsunami(tsunamiModel, waveHitbox, startCFrame, endCFrame, direction, players, destructibleRoot, onCompleted)
	activeMoveToken += 1
	local moveToken = activeMoveToken
	local startTime = os.clock()
	local lastDestructionCheck = 0

	task.spawn(function()
		while eventActive and activeMoveToken == moveToken do
			local elapsed = os.clock() - startTime
			local alpha = math.clamp(elapsed / CONFIG.TRAVEL_TIME, 0, 1)
			local currentCFrame = startCFrame:Lerp(endCFrame, alpha)

			tsunamiModel:PivotTo(currentCFrame)
			killPlayersInsideWave(players, waveHitbox)

			if elapsed - lastDestructionCheck >= CONFIG.DESTRUCTION_CHECK_INTERVAL then
				lastDestructionCheck = elapsed
				breakDestructiblesInsideWave(waveHitbox, direction, destructibleRoot)
			end

			if alpha >= 1 then
				break
			end

			RunService.Heartbeat:Wait()
		end

		if eventActive and activeMoveToken == moveToken then
			onCompleted()
		end
	end)
end

function TsunamiEvent.Start(players, onEventFinished)
	local mapReferences = getMapReferences()
	if not mapReferences then
		onEventFinished("NoWinner")
		return
	end

	eventActive = true
	print("[TsunamiEvent] Iniciando evento tsunami")

	registerDestructibleParts(mapReferences.DestructibleRoot)
	teleportPlayersToSpawn(players, mapReferences.Spawn)

	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)
		if humanoid then
			local connection = humanoid.Died:Connect(function()
				print("[TsunamiEvent] Jugador muerto:", player.Name)
			end)

			table.insert(activeConnections, connection)
		end
	end

	local activeTsunami, waveHitbox, tsunamiDirection = createTsunami(mapReferences.Start, mapReferences.End)
	table.insert(spawnedObjects, activeTsunami)

	for _, safeZone in ipairs(mapReferences.SafeZones) do
		local safeConnection = safeZone.Touched:Connect(function(hit)
			local player = getPlayerFromHit(hit)
			if player then
				print("[TsunamiEvent] Jugador en zona segura:", player.Name)
			end
		end)

		table.insert(activeConnections, safeConnection)
	end

	local startCFrame = getWaveCFrame(mapReferences.Start, tsunamiDirection)
	local endCFrame = getWaveCFrame(mapReferences.End, tsunamiDirection)

	moveTsunami(activeTsunami, waveHitbox, startCFrame, endCFrame, tsunamiDirection, players, mapReferences.DestructibleRoot, function()
		local result = getEventResult(players, mapReferences.SafeZones)
		print("[TsunamiEvent] Tsunami ha terminado su recorrido. Resultado:", result)
		TsunamiEvent.Cleanup(players)
		onEventFinished(result)
	end)
end

function TsunamiEvent.FinishByTime(players, onEventFinished)
	TsunamiEvent.Cleanup(players)
	onEventFinished("Survivors")
end

function TsunamiEvent.Cleanup(players)
	eventActive = false
	activeMoveToken += 1

	disconnectAllConnections()
	destroySpawnedObjects()
	restoreDestructibleParts()

	activeConnections = {}
	spawnedObjects = {}
end

return TsunamiEvent
