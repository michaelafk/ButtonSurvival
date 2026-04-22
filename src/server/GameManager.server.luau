print("GAME MANAGER INICIADO")
--Obtenermos los servicios que vamos a usar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Obtenemos los modulos y los remotos a usar
local Server = ServerScriptService:WaitForChild("Server")
local Systems = Server:WaitForChild("Systems")
local ButtonSystem = require(Systems:WaitForChild("ButtonSystem"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local updateTimerEvent = Remotes:WaitForChild("UpdateTimer")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local getCurrentStateFunction = Remotes:WaitForChild("GetCurrentState")
--Referencias del mapa
local LobbySpawn = workspace:WaitForChild("LobbySpawn")
local MapSpawn = workspace:WaitForChild("MapSpawn")
--Estado actual del juego
local currentGameState = GameConfig.GameStates.Waiting
local currentTimeleft = 0
local currentStatusMessage = GameConfig.UI.WaitingMessage
--Funciones de apoyo
--Devuelve el numero actual de jugadores conectados
local function getPlayerCount()
	return #Players:getPlayers()
end
--Cambia el estado actual del juego
local function setGameState(newState)
	currentGameState = newState
end
--Guarda el tiempo restante actual
local function setTimeLeft(timeLeft)
	currentTimeleft = timeLeft
end
--Guarda el mensaje actual de estado
local function setStatusMessge(message)
	currentStatusMessage = message
end
--Envia  todos los clientes la informacion actual de UI
local function broadcastUI(state, timeLeft, message)
	updateTimerEvent:FireAllClients(state, timeLeft, message)
end
--Actualiza las variables internas y además lo envia a la UI
local function updateUI(state, timeLeft, message)
	setGameState(state)
	setTimeLeft(timeLeft)
	setStatusMessge(message)
	broadcastUI(state, timeLeft, message)
end
--Teletransporte
--Esta funcion mueve un personaje concreto a una parte concreta.
--Recibe:
--  character: el personaje del jugador
--  targetPart: la parte a la que queremos moverlo
local function teleportCharacter(character, targetPart)
	--Buscamos la parte principal del personaje, que se usa como referencia
	--para moverlo por el mapa
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	--Si no existe, no podemos teletransportarlo.
	if not humanoidRootPart then
		return
	end
	--Cambiamos la posicion del personaje al CFrame de la parte destino,
	--sumamos Vector3.new(0, 3, 0) para que aparezca un poco por encima
	--y no se quede atrapado en el suelo
	local position = targetPart.Position + Vector3.new(0, 3, 0)
	humanoidRootPart.CFrame = CFrame.new(position)
end
--Esta funcion teletransporta a un jugador concreto.
--Primero comprueba que el jugador tenga personaje cargado.
local function teleportPlayer(player, targetPart)
	if not player.Character then
		return
	end
	teleportCharacter(player.Character, targetPart)
end
--Esta funcion recorre todos los jugadores conectados
--y los mueve al destino que le indiquemos
local function teleportAllPlayers(targetPart)
	for _, player in ipairs(Players:GetPlayers()) do
		teleportPlayer(player, targetPart)
	end
end
--Gestion de jugadores
--Esta funcion define donde aparece un jugador
--cuando entra o reaparece
local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		--si el jugador entra se le llevara al lobby
		if currentGameState == GameConfig.GameStates.Match then
			teleportCharacter(character, LobbySpawn)
			return
		end
		teleportCharacter(character, LobbySpawn)
	end)
end
--Conectar jugadores nuevos
Players.PlayerAdded:Connect(setupPlayer)
--Conectar jugadores que ya estaban dentro al iniciar el script
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
--Sincronizacion inicial para jugadores nuevos
getCurrentStateFunction.OnServerInvoke = function()
	return currentGameState, currentTimeleft, currentStatusMessage
end
--Fases del juego
--Espera hasta que haya suficientes jugadores
local function waitForEnoughPlayers()
	setGameState(GameConfig.GameStates.Waiting)
	while getPlayerCount() < GameConfig.MIN_PLAYERS do
		updateUI(GameConfig.GameStates.Waiting, 0, GameConfig.UI.WaitingMessage)
		task.wait(1)
	end
end
--Cuenta atras antes de comenzar partida
local function runIntermission()
	setGameState(GameConfig.GameStates.Intermission)
	teleportAllPlayers(LobbySpawn)
	for i = GameConfig.INTERMISSION_TIME, 1, -1 do
		--si durante la cuenta atras un jugador se va y el numero de jugadores es
		--menor al minimo se para la cuenta atras
		if getPlayerCount() < GameConfig.MIN_PLAYERS then
			return false
		end
		updateUI(GameConfig.GameStates.Intermission, i, GameConfig.UI.IntermissionMessage)
		task.wait(1)
	end
	return true
end
--Fase de partida
local function runMatch()
	setGameState(GameConfig.GameStates.Match)
	teleportAllPlayers(MapSpawn)
	ButtonSystem.SpawnButton()
	for i = GameConfig.MATCH_DURATION, 1, -1 do
		updateUI(GameConfig.GameStates.Match, i, GameConfig.UI.MatchMessage)
		task.wait(1)
	end
	ButtonSystem.HideButton()
end
--Fase de cierre
local function runEnding()
	setGameState(GameConfig.GameStates.Ending)
	for i = GameConfig.ENDING_TIME, 1, -1 do
		updateUI(GameConfig.GameStates.Ending, i, GameConfig.UI.EndingMessage)
		task.wait(1)
	end
	teleportAllPlayers(LobbySpawn)
end
--Bucle principal del juego,
--Espera minima de jugadores --> Lobby --> Partida -->Fin de partida --> Lobby
while true do
	waitForEnoughPlayers()
	local intermissionCompleted = runIntermission()
	if intermissionCompleted then
		runMatch()
		runEnding()
	end
end
