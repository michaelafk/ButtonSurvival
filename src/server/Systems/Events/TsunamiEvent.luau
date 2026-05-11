--[[
    TsunamiEvent.luau

    Evento global: "Tsunami"

    Descripcion:
    1. Teletransporta a los jugadores al spawn del evento
    2. Crea una ola que avanza desde TsunamiStart hasta TsunamiEnd
    3. Si la ola toca a un jugador, el jugador muere al instante
    4. Si al terminar el recorrido hay jugadores vivos en la zona final, sobreviven
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local TsunamiEvent = {}

local CONFIG = {
	TRAVEL_TIME = 35,
	PLAYER_SPACING = 6,
	WAVE_SIZE = Vector3.new(180, 70, 12),
	WAVE_COLOR = Color3.fromRGB(0, 140, 255),
	WAVE_TRANSPARENCY = 0.35,
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
	local spawnPart = workspace:FindFirstChild("TsunamiSpawn") or workspace:FindFirstChild("MapSpawn")
	local startPart = workspace:FindFirstChild("TsunamiStart")
	local endPart = workspace:FindFirstChild("TsunamiEnd")
	local finishZone = workspace:FindFirstChild("TsunamiFinishZone") or workspace:FindFirstChild("FinishZone")

	if not spawnPart or not startPart or not endPart or not finishZone then
		warn("[TsunamiEvent] Faltan partes: TsunamiStart, TsunamiEnd, TsunamiFinishZone/FinishZone y MapSpawn o TsunamiSpawn")
		return nil
	end

	return {
		Spawn = spawnPart,
		Start = startPart,
		End = endPart,
		FinishZone = finishZone,
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

local function createTsunami(startPart, endPart)
	local tsunami = Instance.new("Part")
	tsunami.Name = "ActiveTsunami"
	tsunami.Anchored = true
	tsunami.CanCollide = false
	tsunami.CanTouch = true
	tsunami.Material = Enum.Material.Neon
	tsunami.Color = CONFIG.WAVE_COLOR
	tsunami.Transparency = CONFIG.WAVE_TRANSPARENCY
	tsunami.Size = CONFIG.WAVE_SIZE
	tsunami.CFrame = CFrame.lookAt(startPart.Position, endPart.Position)
	tsunami.Parent = workspace

	return tsunami
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
function TsunamiEvent.Start(players, onEventFinished)
	local mapReferences = getMapReferences()
	if not mapReferences then
		onEventFinished("NoWinner")
		return
	end

	print("[TsunamiEvent] Iniciando evento tsunami")

	teleportPlayersToSpawn(players, mapReferences.Spawn)

	--Conectar muertes de jugadores
	for _, player in ipairs(players) do
		local humanoid = getHumanoid(player)
		if humanoid then
			local connection = humanoid.Died:Connect(function()
				print("[TsunamiEvent] Jugador muerto:", player.Name)
			end)

			table.insert(activeConnections, connection)
		end
	end

	--Crear tsunami y conectar eventos
	local activeTsunami = createTsunami(mapReferences.Start, mapReferences.End)
	table.insert(spawnedObjects, activeTsunami)

	local connection = activeTsunami.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then
			local humanoid = getHumanoid(player)
			if humanoid then
				humanoid.Health = 0
			end
		end
	end)

	table.insert(activeConnections, connection)

	--Hacer que la zona de finish haga spawn a los jugadores seguros
	local finishConnection = mapReferences.FinishZone.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then
			print("[TsunamiEvent] Jugador en zona segura:", player.Name)
		end
	end)

	table.insert(activeConnections, finishConnection)

	--Animar tsunami
	local startCFrame = CFrame.lookAt(mapReferences.Start.Position, mapReferences.End.Position)
	local endCFrame = CFrame.lookAt(mapReferences.End.Position, mapReferences.End.Position + startCFrame.LookVector)

	local activeTween = TweenService:Create(
		activeTsunami,
		TweenInfo.new(CONFIG.TRAVEL_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = endCFrame }
	)

	activeTween:Play()

	task.spawn(function()
		local playbackState = activeTween.Completed:Wait()
		if playbackState ~= Enum.PlaybackState.Completed then
			return
		end

		print("[TsunamiEvent] Tsunami ha terminado su recorrido")
		TsunamiEvent.Cleanup(players)
		onEventFinished("Survivors")
	end)
end

--Fin por tiempo
function TsunamiEvent.FinishByTime(players, onEventFinished)
	TsunamiEvent.Cleanup(players)
	onEventFinished("Survivors")
end

--Limpieza del evento
function TsunamiEvent.Cleanup(players)
	disconnectAllConnections()
	destroySpawnedObjects()

	activeConnections = {}
	spawnedObjects = {}
end

return TsunamiEvent