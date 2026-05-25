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

local function getActiveEventMessage()
	local eventName = EventSystem.GetCurrentEventName()

	if eventName == "Tsunami" then
		return "Tsunami en curso"
	elseif eventName == "Earthquake" then
		return "Terremoto en curso"
	elseif eventName == "Marked" then
		return "Marcado en curso"
	end

	return "Evento en curso"
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
	PlayerManager.ResetEliminatedPlayers()
	setGameState(GameConfig.GameStates.Match)
	PlayerManager.TeleportAllPlayersToMap()
	ButtonSystem.SpawnButton()

	local searchTimeLeft = GameConfig.MATCH_DURATION

	while searchTimeLeft > 0 and not roundEnding do
		if ButtonSystem.WasPressed() and EventSystem.IsEventActive() then
			local eventTimeLeft = EventSystem.GetCurrentEventTimeLeft()

			if eventTimeLeft then
				-- Eventos con duracion propia, como Tsunami o Earthquake.
				-- El contador mostrado pasa a ser el tiempo restante del evento.
				updateUI(GameConfig.GameStates.Match, eventTimeLeft, getActiveEventMessage())
			else
				-- Eventos sin duracion propia, como Marked, siguen usando el tiempo restante de la ronda.
				updateUI(GameConfig.GameStates.Match, searchTimeLeft, getActiveEventMessage())
				searchTimeLeft -= 1

				if searchTimeLeft <= 0 then
					local roundPlayers = PlayerManager.GetAllPlayers()
					EventSystem.FinishCurrentEventByTime(roundPlayers)
				end
			end
		else
			updateUI(GameConfig.GameStates.Match, searchTimeLeft, GameConfig.UI.MatchMessage)
			searchTimeLeft -= 1
		end

		task.wait(1)
	end

	ButtonSystem.HideButton()
end
--Fase de cierre
local function runEnding()
	setGameState(GameConfig.GameStates.Ending)
	--limpiar cualquier evento activo
	local roundPlayers = PlayerManager.GetAllPlayers()
	EventSystem.CleanupCurrentEvent(roundPlayers)
	for i = GameConfig.ENDING_TIME, 1, -1 do
		updateUI(GameConfig.GameStates.Ending, i, GameConfig.UI.EndingMessage)
		task.wait(1)
	end
	PlayerManager.TeleportAllPlayersToLobby()
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
