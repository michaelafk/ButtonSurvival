--Servicios a usar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--Referencias
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = Shared:WaitForChild("Remotes")
local updateTimerEvent = Remotes:WaitForChild("UpdateTimer")
local getCurrentStateFunction = Remotes:WaitForChild("GetCurrentState")
local buttonAppearedEvent = Remotes:WaitForChild("ButtonAppeared")
--Referencias al jugador y su UI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
--Esperamos a que exista la UI
local screenGui = playerGui:WaitForChild("GameUI")
local timerText = screenGui:WaitForChild("TimerText")
local stateText = screenGui:WaitForChild("StateText")
local statusText = screenGui:WaitForChild("StatusText")
--Funciones de apoyo
local function formatTimer(state, timeLeft)
	if state == GameConfig.GameStates.Waiting then
		return "-"
	end
	return tostring(timeLeft)
end
local function updateStateColor(state)
	if state == GameConfig.GameStates.Waiting then
		stateText.TextColor3 = Color3.fromRGB(255, 204, 0)
	elseif state == GameConfig.GameStates.Intermission then
		stateText.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif state == GameConfig.GameStates.Match then
		stateText.TextColor3 = Color3.fromRGB(255, 80, 80)
	elseif state == GameConfig.GameStates.Ending then
		stateText.TextColor3 = Color3.fromRGB(80, 255, 120)
	end
end
local function updateUI(state, timeLeft, message)
	stateText.Text = "Estado: " .. tostring(state)
	timerText.Text = "Tiempo: " .. formatTimer(state, timeLeft)
	statusText.Text = tostring(message)

	updateStateColor(state)
end
local function syncInitialState()
	local success, state, timeLeft, message = pcall(function()
		return getCurrentStateFunction:InvokeServer()
	end)
	if success then
		updateUI(state, timeLeft, message)
	else
		warn("[TimerUI] No se pudo sincronizar el estado inicial.")
	end
end
--Eventos
updateTimerEvent.OnClientEvent:Connect(function(state, timeLeft, message)
	updateUI(state, timeLeft, message)
end)
buttonAppearedEvent.OnClientEvent:Connect(function(message)
	statusText.Text = message
end)
--Inicio
syncInitialState()
