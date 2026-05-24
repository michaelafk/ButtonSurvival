--[[
    MarkedEvent.lua

    Evento: "El Marcado"
    
    Descripcion:
    1. Selecciona un jugador aleatorio vivo de la partida
    2. Lo marca con un contorno rojo
    3. Da armas al resto de jugadores
    3.1. Si el marcado muere, ganan los otros jugadores
    3.2. Si sobrevive el marcado al tiempo, gana el marcado
]]

local MarkedEvent = {}

--Obtenermos los servicios que vamos a usar
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
--Modulos a usar
local Server = ServerScriptService:WaitForChild("Server")
local Managers = Server:WaitForChild("Managers")
local PlayerManager = require(Managers:WaitForChild("PlayerManager"))
local ScoreManager = require(Managers:WaitForChild("ScoreManager"))
--Variables internas del evento
local activeConnections = {}
local markedPlayer = nil --Jugador que ha sido marcado

--Funciones auxiliares

--Selecciona un jugador aleatorio entre los vivos
local function chooseRandomPlayer(players)
	if #players == 0 then
		return nil
	end

	local randomIndex = math.random(1, #players)
	return players[randomIndex]
end

--Logica del evento
--Añade el contorno rojo al jugador marcado
local function addMarkedHighlight(player)
	local character = player.Character
	if not character then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "MarkedHighlight"

	-- Color rojo para identificar al marcado
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 0, 0)

	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0

	highlight.Parent = character
end

--Elimina el contorno del jugador marcado
local function removeMarkedHighlight(player)
	local character = player.Character
	if not character then
		return
	end

	local highlight = character:FindFirstChild("MarkedHighlight")
	if highlight then
		highlight:Destroy()
	end
end

--Gestion de armas

--Da un bate a todos los jugadores excepto al marcado
local function giveBatToHunters(players, marked)
	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	if not toolsFolder then
		warn("No existe ServerStorage/Tools")
		return
	end

	local bat = toolsFolder:FindFirstChild("Bat")
	if not bat then
		warn("No existe la herramienta Bat")
		return
	end

	for _, player in ipairs(players) do
		if player ~= marked then
			local backpack = player:FindFirstChild("Backpack")

			if backpack then
				local batClone = bat:Clone()
				batClone.Name = "HunterBat"
				batClone.Parent = backpack
			end
		end
	end
end

--Elimina todos los bates del evento
local function removeBats(players)
	for _, player in ipairs(players) do
		local backpack = player:FindFirstChild("Backpack")
		local character = player.Character

		--Eliminar del inventario
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item.Name == "HunterBat" then
					item:Destroy()
				end
			end
		end

		--Eliminar si lo tiene equipado
		if character then
			for _, item in ipairs(character:GetChildren()) do
				if item.Name == "HunterBat" then
					item:Destroy()
				end
			end
		end
	end
end
--Funcion para obtener el jugador "el marcado"
function MarkedEvent.GetMarkedPlayer()
	return markedPlayer
end
--Inicio del evento
function MarkedEvent.Start(players, onEventFinished, onResultUpdate)
	--Seleccionar jugador marcado
	markedPlayer = chooseRandomPlayer(players)

	if not markedPlayer then
		warn("No se pudo seleccionar jugador marcado")
		onEventFinished("NoWinner")
		return
	end

	print("Jugador marcado:", markedPlayer.Name)

	--Actualizar el evensystem con el marcado real
	if onResultUpdate then
		onResultUpdate({
			EventName = "The marked",
			MarkedPlayer = markedPlayer,
			Winner = nil,
		})
	end
	-- Aplicar efectos
	addMarkedHighlight(markedPlayer)
	giveBatToHunters(players, markedPlayer)

	for _, player in ipairs(players) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			local diedConnection = humanoid.Died:Connect(function()
				PlayerManager.PlayerEliminated(player)
				if player == markedPlayer then
					print("[MarkedEvent] El marcado ha muerto, ganan los cazadores")
					--Detectar quien matro al marcado
					local creator = humanoid:FindFirstChild("creator")
					if creator and creator.Value then
						ScoreManager.GiveKillMarkedPoints(creator.Value)
						print("[MarkedEvent] Puntos por matar al marcado dados a: ", creator.Value.Name)
					end
					MarkedEvent.Cleanup(players)
					onEventFinished("Hunters")
				else
					print(player.Name .. " cazador eliminado")
				end
			end)
			table.insert(activeConnections, diedConnection)
		end
	end
end
--Fin por tiempo
function MarkedEvent.FinishByTime(players, onEventFinished)
	if markedPlayer then
		print("El marcado sobrevivio, gana el marcado")

		MarkedEvent.Cleanup(players)
		onEventFinished("Marked")
	end
end
--Limpieza del evento
function MarkedEvent.Cleanup(players)
	--Quitar highlight
	if markedPlayer then
		removeMarkedHighlight(markedPlayer)
	end

	--Quitar armas
	removeBats(players)

	--Desconectar eventos (importante para evitar bugs/memory leaks)
	for _, connection in ipairs(activeConnections) do
		connection:Disconnect()
	end

	--Resetear estado
	activeConnections = {}
	markedPlayer = nil
end

return MarkedEvent
