local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remoteNames = require(remotes:WaitForChild("RemoteNames"))

local updateTimerEvent = remotes:WaitForChild(remoteNames.UpdateTimer)
local gameStateChangedEvent = remotes:WaitForChild(remoteNames.GameStateChanged)
local roundStartedEvent = remotes:WaitForChild(remoteNames.RoundStarted)
local roundEndedEvent = remotes:WaitForChild(remoteNames.RoundEnded)
local eventStartedEvent = remotes:WaitForChild(remoteNames.EventStarted)
local eventEndedEvent = remotes:WaitForChild(remoteNames.EventEnded)
local playerEliminatedEvent = remotes:WaitForChild(remoteNames.PlayerEliminated)
local getCurrentState = remotes:WaitForChild(remoteNames.GetCurrentState)

local screenGui = playerGui:FindFirstChild("GameUI")
if not screenGui then
	warn("[GameUIController] No se encontró StarterGui/GameUI. La UI es opcional.")
end

local function setText(name: string, value: string)
	if not screenGui then
		return
	end

	local label = screenGui:FindFirstChild(name)
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

local function syncInitialState()
	local ok, state, timeLeft = pcall(function()
		return getCurrentState:InvokeServer()
	end)

	if ok then
		setText("StateText", "Estado: " .. tostring(state))
		setText("TimerText", tostring(timeLeft))
	end
end

updateTimerEvent.OnClientEvent:Connect(function(timeLeft: number, stateName: string, message: string?)
	if message then
		setText("StatusText", message)
	end
	setText("TimerText", string.format("%s: %d", stateName, timeLeft))
end)

gameStateChangedEvent.OnClientEvent:Connect(function(newState: string)
	setText("StateText", "Estado: " .. newState)
end)

roundStartedEvent.OnClientEvent:Connect(function(mapName: string)
	setText("StatusText", "Ronda iniciada en: " .. mapName)
end)

roundEndedEvent.OnClientEvent:Connect(function(reason: string, winners: {string})
	local winnersText = #winners > 0 and table.concat(winners, ", ") or "Nadie"
	setText("StatusText", string.format("Ronda terminada (%s). Ganadores: %s", reason, winnersText))
end)

eventStartedEvent.OnClientEvent:Connect(function(eventName: string)
	setText("StatusText", "Evento: " .. eventName)
end)

eventEndedEvent.OnClientEvent:Connect(function(eventName: string)
	setText("StatusText", "Evento finalizado: " .. eventName)
end)

playerEliminatedEvent.OnClientEvent:Connect(function(playerName: string)
	setText("StatusText", playerName .. " ha sido eliminado")
end)

syncInitialState()
