print("GAME MANAGER INICIADO")
--Obtenermos los servicios que vamos a usar,
--por un lado obtenemos todos los jugadores que estan en el juego
--y por otro lado obtenemos los modulos compartidos que estan en el replicatedstorage
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local updateTimerEvent = Remotes:WaitForChild("UpdateTimer")

--Cargamos la configuracion compartida del juego
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

--Esperamos a que existan en el workspace las partes que usaremos como referencia
--para teletransportar a los jugadores.
local LobbySpawn = workspace:WaitForChild("LobbySpawn")
local MapSpawn = workspace:WaitForChild("MapSpawn")

--Variable que guarda en que fase esta el juego actualmente,
--de momento solo usaremos dos estados:
--"Lobby" -> jugadores esperando
--"Match" -> jugadores ya dentro del mapa
local GameState = "Lobby"

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
	humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
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

--Esta funcion define donde aparece un jugador
--cada vez que entra o reaparece
local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		--si el jugador entra se le llevara al lobby
		if GameState == "Match" then
			teleportCharacter(character, LobbySpawn)
		end
	end)
end

--Conectar jugadores nuevos
Players.PlayerAdded:Connect(setupPlayer)

--Conectar jugadores que ya estaban dentro al iniciar el script
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

local function startLobbyPhase()
	--Indicamos que ahora el juego esta en fase lobby
	GameState = "Lobby"
	print("Fase de lobby iniciada")

	--Enviamos a todos los jugadores al punto del lobby
	teleportAllPlayers(LobbySpawn)

	--Hasta que no haya un minimo de jugadores no se empieza la cuenta atras del lobby
	while #Players:GetPlayers() < GameConfig.MIN_PLAYERS do
		updateTimerEvent:FireAllClients("Esperando jugadores...")
		task.wait(1)
	end
	print("Suficientes jugadores, iniciando cuenta atras")
	--Cuenta atras del lobby.
	--Empieza en el numero configurado en GameConfig
	--y va bajando hasta 1
	for i = GameConfig.LOBBY_WAIT_TIME, 1, -1 do
		--si durante la cuenta atras un jugador se va y el numero de jugadores es
		--menor al minimo se para la cuenta atras
		if #Players:GetPlayers() < GameConfig.MIN_PLAYERS then
			updateTimerEvent:FireAllClients("Esperando jugadores...")
			return
		end
		updateTimerEvent:FireAllClients("Empieza en: " .. i)
		task.wait(1)
	end
end

--Esta funcion inicia la partida.
local function startMatchPhase()
	--Cambiamos el estado a partida en curso.
	GameState = "Match"
	print("La partida ha comenzado")
	--Enviamos a todos los jugadores al mapa.
	teleportAllPlayers(MapSpawn)
	for i = GameConfig.MATCH_DURATION, 1, -1 do
		updateTimerEvent:FireAllClients("Tiempo restante: " .. i)
		task.wait(1)
	end
end

--Bucle principal del juego,
--Lobby -> Mapa --> Lobby
while true do
	startLobbyPhase()
	startMatchPhase()
end
