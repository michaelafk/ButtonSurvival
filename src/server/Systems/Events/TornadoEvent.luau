--[[
	TornadoEvent.luau

	Evento global: "Tornado"

	Compatible con la estructura actual:
	Workspace
	├── MapSpawn
	└── EventObjects
	    └── Destructible

	Funcionamiento:
	1. Usa MapSpawn como centro del evento.
	2. Crea un tornado visible.
	3. El tornado se mueve aleatoriamente cerca del mapa.
	4. Crece con el tiempo.
	5. Atrae y daña jugadores.
	6. Destruye SOLO objetos dentro de Workspace.EventObjects.Destructible.
	7. Los objetos lanzados hacen daño al tocar jugadores.
	8. Termina cuando queda un superviviente o se acaba el tiempo.
]]

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local TornadoEvent = {}

local CONFIG = {
	DURATION = 45,

	START_RADIUS = 14,
	END_RADIUS = 65,

	START_HEIGHT = 30,
	END_HEIGHT = 110,

	DAMAGE_PER_SECOND = 16,
	INNER_KILL_RADIUS_MULTIPLIER = 0.18,

	PLAYER_PULL_FORCE = 90,
	PLAYER_UP_FORCE = 42,

	OBJECT_PULL_FORCE = 120,
	OBJECT_THROW_CHANCE = 0.035,
	OBJECT_THROW_MIN_POWER = 90,
	OBJECT_THROW_MAX_POWER = 160,

	PROJECTILE_MIN_SPEED = 35,
	PROJECTILE_MIN_DAMAGE = 10,
	PROJECTILE_MAX_DAMAGE = 75,
	PROJECTILE_DAMAGE_MULTIPLIER = 0.45,

	MOVE_SPEED = 22,
	TARGET_REACHED_DISTANCE = 10,
	RANDOM_MOVE_RANGE = 130,

	MAX_OBJECTS_PROCESSED_PER_FRAME = 40,

	SOLO_TEST_MODE = true,
}

local activeConnections = {}
local spawnedObjects = {}
local projectileConnections = {}
local dangerousObjects = {}
local eliminatedPlayers = {}

local eventRunning = false
local tornadoModel = nil
local currentPosition = nil
local currentTargetPosition = nil
local initialPlayerCount = 0

-- =========================
-- Helpers jugadores
-- =========================

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

local function markPlayerEliminated(player)
	eliminatedPlayers[player] = true
end

local function getAlivePlayers(players)
	local alivePlayers = {}

	for _, player in ipairs(players) do
		if not eliminatedPlayers[player] then
			local humanoid = getHumanoid(player)

			if humanoid and humanoid.Health > 0 then
				table.insert(alivePlayers, player)
			end
		end
	end

	return alivePlayers
end

-- =========================
-- Referencias mapa
-- =========================

local function getEventObjectsFolder()
	return workspace:FindFirstChild("EventObjects")
end

local function getDestructibleFolder()
	local eventObjects = getEventObjectsFolder()
	if not eventObjects then
		return nil
	end

	return eventObjects:FindFirstChild("Destructible")
end

local function getMapCenter()
	local mapSpawn = workspace:FindFirstChild("MapSpawn")

	if mapSpawn and mapSpawn:IsA("BasePart") then
		return mapSpawn.Position
	end

	local destructibleFolder = getDestructibleFolder()
	if destructibleFolder then
		local parts = {}

		for _, descendant in ipairs(destructibleFolder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end

		if #parts > 0 then
			return parts[math.random(1, #parts)].Position + Vector3.new(0, 12, 0)
		end
	end

	return Vector3.new(0, 20, 0)
end

local function getRandomPositionNearMap()
	local center = getMapCenter()

	local randomX = math.random(-CONFIG.RANDOM_MOVE_RANGE, CONFIG.RANDOM_MOVE_RANGE)
	local randomZ = math.random(-CONFIG.RANDOM_MOVE_RANGE, CONFIG.RANDOM_MOVE_RANGE)

	return Vector3.new(
		center.X + randomX,
		center.Y + 15,
		center.Z + randomZ
	)
end

local function updateRandomTarget()
	currentTargetPosition = getRandomPositionNearMap()
end

-- =========================
-- Visual tornado
-- =========================

local function createTornadoVisual(position)
	local model = Instance.new("Model")
	model.Name = "ActiveTornado"
	model.Parent = workspace

	local layers = 7

	for i = 1, layers do
		local alpha = i / layers

		local ring = Instance.new("Part")
		ring.Name = "WindRing_" .. i
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanTouch = false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.ForceField
		ring.Color = Color3.fromRGB(120, 120, 120)
		ring.Transparency = 0.35 + (alpha * 0.08)

		local ringRadius = CONFIG.START_RADIUS * (0.35 + alpha)
		local ringHeight = 2

		ring.Size = Vector3.new(ringRadius, ringHeight, ringRadius)
		ring.CFrame =
			CFrame.new(position + Vector3.new(0, alpha * CONFIG.START_HEIGHT, 0))
			* CFrame.Angles(0, 0, math.rad(90))

		ring.Parent = model
	end

	local dust = Instance.new("Part")
	dust.Name = "DustCloud"
	dust.Anchored = true
	dust.CanCollide = false
	dust.CanTouch = false
	dust.Shape = Enum.PartType.Ball
	dust.Material = Enum.Material.SmoothPlastic
	dust.Color = Color3.fromRGB(95, 95, 95)
	dust.Transparency = 0.65
	dust.Size = Vector3.new(CONFIG.START_RADIUS * 2.2, CONFIG.START_RADIUS * 0.6, CONFIG.START_RADIUS * 2.2)
	dust.Position = position
	dust.Parent = model

	model.PrimaryPart = dust

	table.insert(spawnedObjects, model)

	return model
end

local function updateTornadoVisual(radius, height)
	if not tornadoModel then
		return
	end

	for _, child in ipairs(tornadoModel:GetChildren()) do
		if child:IsA("BasePart") then
			if string.find(child.Name, "WindRing_") then
				local index = tonumber(string.match(child.Name, "%d+")) or 1
				local alpha = index / 7

				local ringRadius = radius * (0.25 + alpha)
				local yOffset = alpha * height

				child.Size = Vector3.new(ringRadius, 2, ringRadius)

				child.CFrame =
					CFrame.new(currentPosition + Vector3.new(0, yOffset, 0))
					* CFrame.Angles(
						0,
						os.clock() * (5 + index),
						math.rad(90)
					)

			elseif child.Name == "DustCloud" then
				child.Size = Vector3.new(radius * 2.4, radius * 0.45, radius * 2.4)
				child.Position = currentPosition
			end
		end
	end
end

-- =========================
-- Movimiento tornado
-- =========================

local function moveTornado(deltaTime)
	if not currentTargetPosition then
		updateRandomTarget()
	end

	local direction = currentTargetPosition - currentPosition
	local distance = direction.Magnitude

	if distance <= CONFIG.TARGET_REACHED_DISTANCE then
		updateRandomTarget()
		return
	end

	if distance > 0 then
		local movement = direction.Unit * CONFIG.MOVE_SPEED * deltaTime

		if movement.Magnitude >= distance then
			currentPosition = currentTargetPosition
		else
			currentPosition += movement
		end
	end
end

-- =========================
-- Daño proyectiles
-- =========================

local function makeObjectDangerous(part)
	if dangerousObjects[part] then
		return
	end

	dangerousObjects[part] = true
	part:SetAttribute("TornadoProjectile", true)

	local connection = part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player then
			return
		end

		local humanoid = getHumanoid(player)
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local speed = part.AssemblyLinearVelocity.Magnitude

		if speed < CONFIG.PROJECTILE_MIN_SPEED then
			return
		end

		local damage = math.clamp(
			speed * CONFIG.PROJECTILE_DAMAGE_MULTIPLIER,
			CONFIG.PROJECTILE_MIN_DAMAGE,
			CONFIG.PROJECTILE_MAX_DAMAGE
		)

		humanoid:TakeDamage(damage)
	end)

	projectileConnections[part] = connection

	Debris:AddItem(part, 20)
end

local function throwObject(part)
	local randomDirection = Vector3.new(
		math.random(-100, 100) / 100,
		math.random(35, 100) / 100,
		math.random(-100, 100) / 100
	)

	if randomDirection.Magnitude <= 0 then
		randomDirection = Vector3.new(0, 1, 0)
	end

	randomDirection = randomDirection.Unit

	local throwPower = math.random(
		CONFIG.OBJECT_THROW_MIN_POWER,
		CONFIG.OBJECT_THROW_MAX_POWER
	)

	part.AssemblyLinearVelocity = randomDirection * throwPower
	part.AssemblyAngularVelocity = Vector3.new(
		math.random(-12, 12),
		math.random(-12, 12),
		math.random(-12, 12)
	)

	makeObjectDangerous(part)
end

-- =========================
-- Objetos destruibles
-- =========================

local function processDestructibleObjects(radius, deltaTime)
	local destructibleFolder = getDestructibleFolder()

	if not destructibleFolder then
		warn("[TornadoEvent] No existe Workspace/EventObjects/Destructible")
		return
	end

	local processed = 0

	for _, descendant in ipairs(destructibleFolder:GetDescendants()) do
		if processed >= CONFIG.MAX_OBJECTS_PROCESSED_PER_FRAME then
			break
		end

		if descendant:IsA("BasePart") then
			local part = descendant
			local distance = (part.Position - currentPosition).Magnitude

			if distance <= radius then
				processed += 1

				if part.Anchored then
					part.Anchored = false
				end

				local directionToTornado = currentPosition - part.Position

				if directionToTornado.Magnitude > 0 then
					local pullDirection = directionToTornado.Unit

					part.AssemblyLinearVelocity += pullDirection * CONFIG.OBJECT_PULL_FORCE * deltaTime
					part.AssemblyLinearVelocity += Vector3.new(0, CONFIG.OBJECT_PULL_FORCE * 0.45 * deltaTime, 0)
				end

				if math.random() < CONFIG.OBJECT_THROW_CHANCE then
					throwObject(part)
				end
			end
		end
	end
end

-- =========================
-- Jugadores
-- =========================

local function processPlayers(players, radius, deltaTime)
	local killRadius = radius * CONFIG.INNER_KILL_RADIUS_MULTIPLIER

	for _, player in ipairs(getAlivePlayers(players)) do
		local humanoid = getHumanoid(player)
		local rootPart = getRootPart(player)

		if humanoid and rootPart then
			local distance = (rootPart.Position - currentPosition).Magnitude

			if distance <= killRadius then
				humanoid.Health = 0
				markPlayerEliminated(player)
			elseif distance <= radius then
				local directionToTornado = currentPosition - rootPart.Position

				if directionToTornado.Magnitude > 0 then
					local pullDirection = directionToTornado.Unit

					rootPart.AssemblyLinearVelocity += pullDirection * CONFIG.PLAYER_PULL_FORCE * deltaTime
					rootPart.AssemblyLinearVelocity += Vector3.new(0, CONFIG.PLAYER_UP_FORCE * deltaTime, 0)
				end

				humanoid:TakeDamage(CONFIG.DAMAGE_PER_SECOND * deltaTime)
			end
		end
	end
end

local function connectPlayerDeaths(players)
	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)

		if humanoid then
			local connection = humanoid.Died:Connect(function()
				print("[TornadoEvent] Jugador eliminado:", player.Name)
				markPlayerEliminated(player)
			end)

			table.insert(activeConnections, connection)
		end
	end
end

-- =========================
-- Limpieza
-- =========================

local function disconnectAllConnections()
	for _, connection in ipairs(activeConnections) do
		if connection then
			connection:Disconnect()
		end
	end

	activeConnections = {}

	for _, connection in pairs(projectileConnections) do
		if connection then
			connection:Disconnect()
		end
	end

	projectileConnections = {}
end

local function destroySpawnedObjects()
	for _, object in ipairs(spawnedObjects) do
		if object and object.Parent then
			object:Destroy()
		end
	end

	spawnedObjects = {}
end

function TornadoEvent.Cleanup()
	eventRunning = false

	disconnectAllConnections()
	destroySpawnedObjects()

	dangerousObjects = {}
	eliminatedPlayers = {}

	tornadoModel = nil
	currentPosition = nil
	currentTargetPosition = nil
	initialPlayerCount = 0

	print("[TornadoEvent] Tornado limpiado")
end

-- =========================
-- Inicio evento
-- =========================

function TornadoEvent.Start(players, onEventFinished)
	if eventRunning then
		warn("[TornadoEvent] Ya hay un tornado activo")
		if onEventFinished then
			onEventFinished("NoWinner")
		end
		return
	end

	if not players or #players == 0 then
		warn("[TornadoEvent] No hay jugadores para iniciar")
		if onEventFinished then
			onEventFinished("NoWinner")
		end
		return
	end

	print("[TornadoEvent] Iniciando tornado")

	eventRunning = true
	eliminatedPlayers = {}
	dangerousObjects = {}
	initialPlayerCount = #players

	currentPosition = getRandomPositionNearMap()
	updateRandomTarget()

	tornadoModel = createTornadoVisual(currentPosition)

	connectPlayerDeaths(players)

	local elapsed = 0
	local lastTime = os.clock()

	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not eventRunning then
			return
		end

		local now = os.clock()
		local deltaTime = now - lastTime
		lastTime = now

		elapsed += deltaTime

		local alpha = math.clamp(elapsed / CONFIG.DURATION, 0, 1)

		local currentRadius = CONFIG.START_RADIUS + ((CONFIG.END_RADIUS - CONFIG.START_RADIUS) * alpha)
		local currentHeight = CONFIG.START_HEIGHT + ((CONFIG.END_HEIGHT - CONFIG.START_HEIGHT) * alpha)

		moveTornado(deltaTime)
		updateTornadoVisual(currentRadius, currentHeight)

		processPlayers(players, currentRadius, deltaTime)
		processDestructibleObjects(currentRadius, deltaTime)

		local alivePlayers = getAlivePlayers(players)

		if initialPlayerCount > 1 then
			if #alivePlayers <= 1 then
				TornadoEvent.Cleanup()

				if onEventFinished then
					if #alivePlayers == 1 then
						onEventFinished(alivePlayers[1])
					else
						onEventFinished("NoWinner")
					end
				end

				return
			end
		elseif CONFIG.SOLO_TEST_MODE then
			-- En modo prueba con 1 jugador, no termina instantaneamente.
			-- Solo termina por tiempo o si el jugador muere.
			if #alivePlayers == 0 then
				TornadoEvent.Cleanup()

				if onEventFinished then
					onEventFinished("NoWinner")
				end

				return
			end
		end

		if elapsed >= CONFIG.DURATION then
			local survivors = getAlivePlayers(players)

			TornadoEvent.Cleanup()

			if onEventFinished then
				if #survivors == 1 then
					onEventFinished(survivors[1])
				elseif #survivors > 1 then
					onEventFinished(survivors)
				else
					onEventFinished("NoWinner")
				end
			end
		end
	end)

	table.insert(activeConnections, heartbeatConnection)
end

function TornadoEvent.FinishByTime(players, onEventFinished)
	local survivors = getAlivePlayers(players or {})

	TornadoEvent.Cleanup()

	if onEventFinished then
		if #survivors == 1 then
			onEventFinished(survivors[1])
		elseif #survivors > 1 then
			onEventFinished(survivors)
		else
			onEventFinished("NoWinner")
		end
	end
end

return TornadoEvent