--[[
	PlayerManager.luau

	Responsabilidades:
	- Gestionar jugadores conectados
	- Teletransportar jugadores
	- Detectar respawns
	- Controlar jugadores eliminados durante la ronda
]]
--Servicios a usar
local Players = game:GetService("Players")

local PlayerManager = {}

--Referencias que recibira desde GameManager
local lobbySpawn = nil
local mapSpawn = nil
--Funcion para consultar el estado actual del juego
local getCurrentStateCallback = nil
--Tabla de jugadores de la ronda
local roundPlayers = {}
--Tabla de jugadores eliminados durante la ronda
local eliminatedPlayers = {}
--Configuracion
function PlayerManager.Init(config)
	lobbySpawn = config.LobbySpawn
	mapSpawn = config.MapSpawn
	getCurrentStateCallback = config.GetCurrentState
	--Conectar jugadores nuevos
	Players.PlayerAdded:Connect(function(player)
		PlayerManager.SetupPlayer(player)
	end)
	--Conectar jugadores que ya estaban dentro
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerManager.SetupPlayer(player)
	end
end
--Crea la lista de jugadores que jugaran la partida
function PlayerManager.SetRoundPlayers(players)
	roundPlayers = {}
	for _, player in ipairs(players) do
		roundPlayers[player.UserId] = player
	end
end
--Devuelve la lista de jugadores de ronda
function PlayerManager.GetRoundPlayers()
	return roundPlayers
end
--Devuelve el numero total de jugadores conectados
function PlayerManager.GetPlayerCount()
	return #Players:GetPlayers()
end
--Devuelve una lista de los jugadores conectados
function PlayerManager.GetAllPlayers()
	return Players:GetPlayers()
end
--Devuelve una lista de los jugadores vivos de la ronda
function PlayerManager.GetAliveRoundPlayers()
	local alivePlayers = {}
	for userId, player in pairs(roundPlayers) do
		if player.Parent == Players and not eliminatedPlayers[userId] then
			table.insert(alivePlayers, player)
		end
	end
	return alivePlayers
end
--Funcion para decir que el jugador marcado ha sido eliminado
function PlayerManager.MarkPlayerEliminated(player)
	if not player then
		return
	end
	eliminatedPlayers[player.UserId] = true
end
--Funcion que me dice si un jugador ha sido eliminado
function PlayerManager.IsPlayerEliminated(player)
	if not player then
		return false
	end
	return eliminatedPlayers[player.UserId] == true
end
--Reset de jugadores eliminados
function PlayerManager.ResetEliminatedPlayers()
	eliminatedPlayers = {}
end
--Reset de jugadores de ronda
function PlayerManager.ResetRoundPlayers()
	roundPlayers = {}
end
--Teletransporte
--Esta funcion mueve un personaje concreto a una parte concreta.
--Recibe:
--  character: el personaje del jugador
--  targetPart: la parte a la que queremos moverlo
function PlayerManager.TeleportCharacter(character, targetPart)
	if not character or not targetPart then
		return
	end
	--Buscamos la parte principal del personaje, que se usa como referencia
	--para moverlo por el mapa
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	--Si no existe, no podemos teletransportarlo
	if not humanoidRootPart then
		return
	end
	--Cambiamos la posicion del personaje al CFrame de la parte destino,
	--sumamos Vector3.new(0, 3, 0) para que aparezca un poco por encima
	--y no se quede atrapado en el suelo
	local position = targetPart.Position + Vector3.new(0, 3, 0)
	humanoidRootPart.CFrame = CFrame.new(position)
end
--Esta funcion teletransporta a un jugador concreto
function PlayerManager.TeleportPlayer(player, targetPart)
	if not player or not player.Character then
		return
	end
	PlayerManager.TeleportCharacter(player.Character, targetPart)
end
--Esta funcion recorre todos los jugadores conectados
--y los mueve al destino que le indiquemos
function PlayerManager.TeleportAllPlayers(targetPart)
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerManager.TeleportPlayer(player, targetPart)
	end
end
function PlayerManager.TeleportRoundPlayers(targetPart)
	for _, player in pairs(roundPlayers) do
		PlayerManager.TeleportPlayer(player, targetPart)
	end
end
--Esta funcion hace que movamos a un jugador al lobby
function PlayerManager.TeleportPlayerToLobby(player)
	PlayerManager.TeleportPlayer(player, lobbySpawn)
end
function PlayerManager.TeleportAllPlayersToLobby()
	PlayerManager.TeleportAllPlayers(lobbySpawn)
end
function PlayerManager.TeleportRoundPlayersToLobby()
	PlayerManager.TeleportRoundPlayers(lobbySpawn)
end
function PlayerManager.TeleportAllPlayersToMap()
	PlayerManager.TeleportAllPlayers(mapSpawn)
end
function PlayerManager.TeleportRoundPlayersToMap()
	PlayerManager.TeleportRoundPlayers(mapSpawn)
end
--Gestion de jugadores
--Esta funcion define donde aparece un jugador
--cuando entra o reaparece
function PlayerManager.SetupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		local currentState = getCurrentStateCallback and getCurrentStateCallback()
		--Si el jugador reaparece durante una partida,
		--lo marcamos como eliminado y lo mandamos al lobby.
		if currentState == "Match" then
			PlayerManager.MarkPlayerEliminated(player)
			PlayerManager.TeleportCharacter(character, lobbySpawn)
			return
		end
		--Por defecto, todo jugador aparece en el lobby
		PlayerManager.TeleportCharacter(character, lobbySpawn)
	end)
end

return PlayerManager
