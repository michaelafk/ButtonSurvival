--[[
	ScoreManager.luau

	Responsabilidades:
	- Gestionar los puntos ganados de los jugadores
	- otorgar puntos
	- mostrar puntos en leaderstats
]]
--Servicios a usar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Modulos a usar
local shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = shared:WaitForChild("Remotes")
--Remotes Events
local updateLeaderboardEvent = Remotes:WaitForChild("UpdateLeaderboard")
--Variables
local ScoreManager = {}
local scores = {}
local POINTS = {
	surviveround = 100,
	pressbutton = 20,
	killmarked = 80,
	markedsurvive = 200,
}
--Funciones internas
local function getLeaderboardData()
	local data = {}
	for player, score in pairs(scores) do
		if player and player.Parent == Players then
			table.insert(data, {
				Name = player.Name,
				DisplayName = player.DisplayName,
				Score = score,
			})
		end
	end
	table.sort(data, function(a, b)
		return a.Score > b.Score
	end)
	return data
end
local function updateLeaderboard()
	updateLeaderboardEvent:FireAllClients(getLeaderboardData())
end
--Funciones principales
function ScoreManager.Init()
	Players.PlayerAdded:Connect(function(player)
		scores[player] = 0

		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local points = Instance.new("IntValue")
		points.Name = "Points"
		points.Value = 0
		points.Parent = leaderstats
		updateLeaderboard()
	end)
	Players.PlayerRemoving:Connect(function(player)
		scores[player] = nil
		updateLeaderboard()
	end)
	for _, player in pairs(Players:GetPlayers()) do
		scores[player] = scores[player] or 0
	end
	updateLeaderboard()
end
function ScoreManager.AddPoints(player, amount)
	if not player then
		return
	end
	scores[player] = scores[player] or 0
	scores[player] += amount

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local points = leaderstats:FindFirstChild("Points")
		if points then
			points.Value = scores[player]
		end
	end
	updateLeaderboard()
end
function ScoreManager.GiveButtonPressPoints(player)
	ScoreManager.AddPoints(player, POINTS.pressbutton)
end

function ScoreManager.GiveKillMarkedPoints(player)
	ScoreManager.AddPoints(player, POINTS.killmarked)
end

function ScoreManager.GiveSurvivalPoints(alivePlayers, markedPlayer)
	for _, player in ipairs(alivePlayers) do
		if player == markedPlayer then
			ScoreManager.AddPoints(player, POINTS.markedsurvive)
		else
			ScoreManager.AddPoints(player, POINTS.surviveround)
		end
	end
end

return ScoreManager
