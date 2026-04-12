local Players = game:GetService("Players")

local PlayerManager = {}
PlayerManager._dataManager = nil
PlayerManager._leaderstatsManager = nil
PlayerManager._inventoryManager = nil
PlayerManager._spawnManager = nil
PlayerManager.Participants = {}
PlayerManager.AlivePlayers = {}

function PlayerManager:Init(dataManager, leaderstatsManager, inventoryManager)
	self._dataManager = dataManager
	self._leaderstatsManager = leaderstatsManager
	self._inventoryManager = inventoryManager
	self.Participants = {}
	self.AlivePlayers = {}
end

function PlayerManager:SetSpawnManager(spawnManager)
	self._spawnManager = spawnManager
end

function PlayerManager:SetupPlayer(player: Player)
	self._dataManager:LoadPlayerData(player)
	self._inventoryManager:SetupPlayer(player)
	self._leaderstatsManager:SetupPlayer(player)
	self._leaderstatsManager:SyncPlayer(player)

	if self._spawnManager then
		self._spawnManager:BindPlayer(player)
	end
end

function PlayerManager:ReleasePlayer(player: Player)
	self.Participants[player] = nil
	self.AlivePlayers[player] = nil
	self._inventoryManager:ReleasePlayer(player)
end

function PlayerManager:Start()
	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:ReleasePlayer(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:SetupPlayer(player)
	end
end

function PlayerManager:GetPlayerCount()
	return #Players:GetPlayers()
end

function PlayerManager:GetPlayers()
	return Players:GetPlayers()
end

function PlayerManager:HasEnoughPlayers(minimumPlayers: number)
	return self:GetPlayerCount() >= minimumPlayers
end

function PlayerManager:SetParticipants(players: {Player})
	table.clear(self.Participants)
	table.clear(self.AlivePlayers)

	for _, player in ipairs(players) do
		self.Participants[player] = true
		self.AlivePlayers[player] = true
	end
end

function PlayerManager:ClearRoundState()
	table.clear(self.Participants)
	table.clear(self.AlivePlayers)
end

function PlayerManager:IsParticipant(player: Player)
	return self.Participants[player] == true
end

function PlayerManager:IsAlive(player: Player)
	return self.AlivePlayers[player] == true
end

function PlayerManager:MarkEliminated(player: Player)
	self.AlivePlayers[player] = nil
end

function PlayerManager:GetAlivePlayers()
	local alive = {}
	for player in pairs(self.AlivePlayers) do
		table.insert(alive, player)
	end
	return alive
end

function PlayerManager:GetAliveCount()
	local count = 0
	for _ in pairs(self.AlivePlayers) do
		count += 1
	end
	return count
end

return PlayerManager
