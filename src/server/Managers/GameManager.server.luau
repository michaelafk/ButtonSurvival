--Obtenermos los servicios que vamos a usar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Obtenemos los modulos y los remotos a usar
local Server = ServerScriptService:WaitForChild("Server")
local Systems = Server:WaitForChild("Systems")
local Managers = Server:WaitForChild("Managers")
local ButtonSystem = require(Systems:WaitForChild("ButtonSystem"))
local EventSystem = require(Systems:WaitForChild("EventSystem"))
local PlayerManager = require(Managers:WaitForChild("PlayerManager"))
local ScoreManager = require(Managers:WaitForChild("ScoreManager"))
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
local roundEnding = false
--Inicializar el PlayerManager
PlayerManager.Init({
	LobbySpawn = LobbySpawn,
	MapSpawn = MapSpawn,
	GetCurrentState = function()
		return currentGameState
	end,
})
--Inicializar el ScoreManager
ScoreManager.Init()
--Funciones de apoyo
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
--Sincronizacion inicial para jugadores nuevos
getCurrentStateFunction.OnServerInvoke = function()
	return currentGameState, currentTimeleft, currentStatusMessage
end
--Fases del juego
--Espera hasta que haya suficientes jugadores
local function waitForEnoughPlayers()
	setGameState(GameConfig.GameStates.Waiting)
	while PlayerManager.GetPlayerCount() < GameConfig.MIN_PLAYERS do
		updateUI(GameConfig.GameStates.Waiting, 0, GameConfig.UI.WaitingMessage)
		task.wait(1)
	end
end
--Cuenta atras antes de comenzar partida
local function runIntermission()
	setGameState(GameConfig.GameStates.Intermission)
	PlayerManager.TeleportAllPlayersToLobby()
	for i = GameConfig.INTERMISSION_TIME, 1, -1 do
		--si durante la cuenta atras un jugador se va y el numero de jugadores es
		--menor al minimo se para la cuenta atras
		if PlayerManager.GetPlayerCount() < GameConfig.MIN_PLAYERS then
			return false
		end
		updateUI(GameConfig.GameStates.Intermission, i, GameConfig.UI.IntermissionMessage)
		task.wait(1)
	end
	return true
end
--Fase de partida
local function runMatch()
	roundEnding = false
	--Limpiamos jugadores eliminados de la ronda anterior
	PlayerManager.ResetEliminatedPlayers()
	--Guardamos los jugdores que empiezan esta ronda
	local playerStartingRound = PlayerManager.GetAllPlayers()
	PlayerManager.SetRoundPlayers(playerStartingRound)
	--Ponemos el estado del juego en match
	setGameState(GameConfig.GameStates.Match)
	--Transportamos solo los jugadores de ronda
	PlayerManager.TeleportRoundPlayersToMap()
	ButtonSystem.SpawnButton()
	for i = GameConfig.MATCH_DURATION, 1, -1 do
		if roundEnding then
			break
		end
		updateUI(GameConfig.GameStates.Match, i, GameConfig.UI.MatchMessage)
		task.wait(1)
	end
	ButtonSystem.HideButton()
end
--Fase de cierre
local function runEnding()
	setGameState(GameConfig.GameStates.Ending)
	--obtener jugadores vivos antes de limpiar la ronda
	local alivePlayers = PlayerManager.GetAliveRoundPlayers()
	--obtener jugador marcado actual antes de limpiar el evento
	local eventResult = EventSystem.GetCurrentEventResult()
	local markedPlayer = eventResult and eventResult.MarkedPlayer
	--dar puntos por la ronda
	ScoreManager.GiveSurvivalPoints(alivePlayers, markedPlayer)
	--limpiar cualquier evento activo
	local roundPlayers = PlayerManager.GetAllPlayers()
	EventSystem.CleanupCurrentEvent(roundPlayers)
	for i = GameConfig.ENDING_TIME, 1, -1 do
		updateUI(GameConfig.GameStates.Ending, i, GameConfig.UI.EndingMessage)
		task.wait(1)
	end
	PlayerManager.TeleportRoundPlayersToLobby()
	--limpiar jugadores de ronda al terminar
	PlayerManager.ResetRoundPlayers()
end
--funcion para finalizar correctamente
local function endRound()
	if roundEnding then
		return
	end
	--Solo avisamos de que la ronda debe terminar
	roundEnding = true
	ButtonSystem.HideButton()
end
ButtonSystem.SetOnEventFinished(function(winner)
	print("[GameManager] Evento terminado. Ganador:", winner)
	endRound()
end)
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
