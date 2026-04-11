print("GAME MANAGER INICIADO")
--Obtenermos los servicios que vamos a usar,
--por un lado obtenemos todos los jugadores que estan en el juego
--y por otro lado obtenemos los modulos compartidos que estan en el replicatedstorage
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function startLobbyPhase()
	--Indicamos que ahora el juego esta en fase lobby
	GameState = "Lobby"
	print("Fase de lobby iniciada")

	--Enviamos a todos los jugadores al punto del lobby
	teleportAllPlayers(LobbySpawn)

	--Cuenta atras del lobby.
	--Empieza en el numero configurado en GameConfig
	--y va bajando hasta 1
	for i = GameConfig.LOBBY_WAIT_TIME, 1, -1 do
		print("La partida empieza en " .. i .. " segundos")
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
end

--Bucle principal del juego,
--de momento solo queremos probar una transicion simple:
--Lobby -> Mapa
while true do
	startLobbyPhase()
	startMatchPhase()
	--Este break hace que el bucle se ejecute una sola vez
	--lo dejamos asi ahora para probar la funcionalidad basica
	--sin que vuelva continuamente al lobby
	break
end
