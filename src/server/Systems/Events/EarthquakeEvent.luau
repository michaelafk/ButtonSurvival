--[[
    EarthquakeEvent.luau

    Evento global: "Terremoto"

    Descripcion:
    1. Teletransporta a los jugadores al spawn del evento
    2. Genera temblores cada ciertos segundos con impactos
    3. Los impactos crean marcas de aviso y después escombros
    4. Si un escombro golpea a un jugador, muere
    5. Si al terminar el tiempo quedan jugadores vivos, sobreviven
]]

local Players = game:GetService("Players")

local EarthquakeEvent = {}

local CONFIG = {
	EVENT_DURATION = 45,
	PLAYER_SPACING = 6,
	TREMOR_INTERVAL_MIN = 5,
	TREMOR_INTERVAL_MAX = 10,
	IMPACTS_PER_TREMOR_MIN = 2,
	IMPACTS_PER_TREMOR_MAX = 4,
	WARNING_TIME = 1.5,
	IMPACT_RADIUS = 12,
	DEBRIS_HEIGHT = 75,
	DEBRIS_LIFETIME = 8,
}

local activeConnections = {}
local spawnedObjects = {}

--Funciones auxiliares

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

local function getMapReferences()
	local spawnPart = workspace:FindFirstChild("EarthquakeSpawn") or workspace:FindFirstChild("MapSpawn")

	if not spawnPart then
		warn("[EarthquakeEvent] Falta MapSpawn o EarthquakeSpawn")
		return nil
	end

	return {
		Spawn = spawnPart,
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

local function createFallingDebris(position, players)
	local debris = Instance.new("Part")
	debris.Name = "EarthquakeFallingDebris"
	debris.Anchored = false
	debris.CanCollide = true
	debris.CanTouch = true
	debris.Material = Enum.Material.Concrete
	debris.Color = Color3.fromRGB(100, 100, 100)
	local size = math.random(7, 13)
	debris.Size = Vector3.new(size, size, size)
	debris.CFrame = CFrame.new(position + Vector3.new(math.random(-5, 5), CONFIG.DEBRIS_HEIGHT, math.random(-5, 5)))
	debris.Parent = workspace
	debris.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))

	table.insert(spawnedObjects, debris)

	local connection = debris.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then
			local humanoid = getHumanoid(player)
			if humanoid then
				humanoid.Health = 0
			end
		end
	end)

	table.insert(activeConnections, connection)

	task.delay(CONFIG.DEBRIS_LIFETIME, function()
		if debris and debris.Parent then
			debris:Destroy()
		end
	end)
end

local function createImpactMarker(position)
	local marker = Instance.new("Part")
	marker.Name = "EarthquakeImpactMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.fromRGB(255, 70, 70)
	marker.Transparency = 0.45
	marker.Size = Vector3.new(CONFIG.IMPACT_RADIUS * 2, 0.2, CONFIG.IMPACT_RADIUS * 2)
	marker.CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0))
	marker.Parent = workspace

	table.insert(spawnedObjects, marker)
	return marker
end

local function triggerImpact(position, players)
	local marker = createImpactMarker(position)

	task.delay(CONFIG.WARNING_TIME, function()
		if marker and marker.Parent then
			marker:Destroy()
		end

		createFallingDebris(position, players)
	end)
end

local function triggerTremor(spawnPart, players)
	print("[EarthquakeEvent] Temblor")

	local impactCount = math.random(CONFIG.IMPACTS_PER_TREMOR_MIN, CONFIG.IMPACTS_PER_TREMOR_MAX)
	for _ = 1, impactCount do
		local randomOffset = Vector3.new(math.random(-60, 60), 0, math.random(-60, 60))
		local impactPosition = spawnPart.Position + randomOffset
		triggerImpact(impactPosition, players)
	end
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

--Inicio del evento
function EarthquakeEvent.Start(players, onEventFinished)
	local mapReferences = getMapReferences()
	if not mapReferences then
		onEventFinished("NoWinner")
		return
	end

	print("[EarthquakeEvent] Iniciando evento terremoto")

	teleportPlayersToSpawn(players, mapReferences.Spawn)

	--Conectar muertes de jugadores
	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)
		if humanoid then
			local connection = humanoid.Died:Connect(function()
				print("[EarthquakeEvent] Jugador muerto:", player.Name)
			end)

			table.insert(activeConnections, connection)
		end
	end

	--Generar temblores durante la duracion del evento
	task.spawn(function()
		local finishAt = os.clock() + CONFIG.EVENT_DURATION

		while os.clock() < finishAt do
			local waitTime = math.random(CONFIG.TREMOR_INTERVAL_MIN, CONFIG.TREMOR_INTERVAL_MAX)
			local remainingTime = finishAt - os.clock()
			if remainingTime <= 0 then
				break
			end

			task.wait(math.min(waitTime, remainingTime))

			triggerTremor(mapReferences.Spawn, players)
		end

		--Terminar evento
		EarthquakeEvent.Cleanup(players)
		onEventFinished("Survivors")
	end)
end

--Fin por tiempo
function EarthquakeEvent.FinishByTime(players, onEventFinished)
	EarthquakeEvent.Cleanup(players)
	onEventFinished("Survivors")
end

--Limpieza del evento
function EarthquakeEvent.Cleanup(players)
	disconnectAllConnections()
	destroySpawnedObjects()

	activeConnections = {}
	spawnedObjects = {}
end

return EarthquakeEvent