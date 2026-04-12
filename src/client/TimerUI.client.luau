local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--RemoteEvent
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local updateTimerEvent = Remotes:WaitForChild("UpdateTimer")

--Referencias al jugador y su UI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--Esperamos a que exista la UI
local screenGui = playerGui:WaitForChild("GameUI")
local timerText = screenGui:WaitForChild("TimerText")

--Escuchamos lo que envía el servidor
updateTimerEvent.OnClientEvent:Connect(function(message)
	timerText.Text = message
end)
