--Obtenermos los servicios que vamos a usar
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--Obtenemos los modulos y los remotos a usar
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local buttonAppearedEvent = Remotes:WaitForChild("ButtonAppeared")
local ButtonSystem = {}
--Obtenemos los modelos a usar
local buttonPart = workspace:WaitForChild("Button")
local topPart = buttonPart:WaitForChild("Top")
local buttonSpawnsFolder = workspace:WaitForChild("ButtonSpawns")
local proximityPrompt = buttonPart:WaitForChild("ProximityPrompt")
--Obtenemos el sistema de eventos
local EventSystem = require(script.Parent.EventSystem)
--Variables a usar
local buttonPressed = false
local onEventFinishedCallback = nil

-- Cambia este valor durante las pruebas: "Random", "Marked", "Tsunami" o "Earthquake"
local EVENT_TO_TEST = "Earthquake"

local function startConfiguredGlobalEvent(roundPlayers, callback)
	if EVENT_TO_TEST == "Marked" then
		return EventSystem.StartMarkedEvent(roundPlayers, callback)
	elseif EVENT_TO_TEST == "Tsunami" then
		return EventSystem.StartTsunamiEvent(roundPlayers, callback)
	elseif EVENT_TO_TEST == "Earthquake" then
		return EventSystem.StartEarthquakeEvent(roundPlayers, callback)
	end

	return EventSystem.StartRandomGlobalEvent(roundPlayers, callback)
end
--Devuelvetodos lo spuntos validos de spawn del boton
local function getButtonSpawns()
	local spawns = {}
	for _, child in ipairs(buttonSpawnsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(spawns, child)
		end
	end
	return spawns
end
--Elige un punto aleatorio
local function getRandomSpawn()
	local spawns = getButtonSpawns()
	if #spawns == 0 then
		warn("[ButtonSystem: No hay puntos de spawn para el boton")
		return nil
	end
	local randomIndex = math.random(1, #spawns)
	return spawns[randomIndex]
end
local function setModelVisibility(model, isvisible)
	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("UnionOperation") then
			descendant.Transparency = isvisible and 0 or 1
			descendant.CanCollide = isvisible
		end
	end
end
local function animateButtonPress()
	local originalCFrame = topPart.CFrame
	local pressedCFrame = originalCFrame * CFrame.new(0, -0.5, 0)

	local pressTween = TweenService:Create(
		topPart,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = pressedCFrame }
	)
	local releaseTween = TweenService:Create(
		topPart,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = originalCFrame }
	)
	pressTween:Play()
	pressTween.Completed:Wait()
	task.wait(0.05)
	releaseTween:Play()
end
--Permite que el GameManager registre que debe pasar cuando un evento termina
function ButtonSystem.SetOnEventFinished(callback)
	onEventFinishedCallback = callback
end
--Hace aparecer el boton en una posición aleatoria
function ButtonSystem.SpawnButton()
	local chosenSpawn = getRandomSpawn()
	if not chosenSpawn then
		return
	end
	buttonPressed = false

	buttonPart:PivotTo(chosenSpawn.CFrame + Vector3.new(0, 2, 0))
	setModelVisibility(buttonPart, true)
	proximityPrompt.Enabled = true

	buttonAppearedEvent:FireAllClients("¡un boton ha apareceido en el mapa")
end
--oculta el boton
function ButtonSystem.HideButton()
	setModelVisibility(buttonPart, false)
	proximityPrompt.Enabled = false
end
--Permite consultar si ya fue pulsado
function ButtonSystem.WasPressed()
	return buttonPressed
end
--Accion placeholder al pulsar
local function handleButtonPressed(player)
	if buttonPressed then
		return
	end
	buttonPressed = true
	proximityPrompt.Enabled = false

	animateButtonPress()

	print("[ButtonSystem] El jugador " .. player.Name .. " ha pulsado el boton")
	print("[ButtonSystem] Se va a ejecutar el evento configurado:", EVENT_TO_TEST)

	--Inicio del evento
	--Usaremos a todos los jugadores(luego se cambiara a solo los de la ronda)
	local roundPlayers = Players:GetPlayers()
	local startedEvent = startConfiguredGlobalEvent(roundPlayers, function(winner)
		print("[ButtonSystem] Resultado del evento:", winner)
		if winner == "Survivors" then
			print("[ButtonSystem] Algunos jugadores han sobrevivido al evento")
		elseif winner == "Tsunami" then
			print("[ButtonSystem] El tsunami ha eliminado a todos")
		elseif winner == "Earthquake" then
			print("[ButtonSystem] El terremoto ha eliminado a todos")
		elseif winner == "Marked" then
			print("[ButtonSystem] El marcado ha sobrevivido")
		elseif winner == "Hunters" then
			print("[ButtonSystem] Los cazadores han eliminado al marcado")
		end

		buttonPressed = false

		--Avisamos al GameManager de que el evento ha terminado
		if onEventFinishedCallback then
			onEventFinishedCallback(winner)
		end

		proximityPrompt.Enabled = true
	end)

	if not startedEvent then
		buttonPressed = false
		proximityPrompt.Enabled = true
	end
end

proximityPrompt.Triggered:Connect(handleButtonPressed)
return ButtonSystem
