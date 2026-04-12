local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))

local roundStartedEvent = Remotes:WaitForChild(RemoteNames.RoundStarted)
local roundEndedEvent = Remotes:WaitForChild(RemoteNames.RoundEnded)

local RoundManager = {}
RoundManager._playerManager = nil
RoundManager._spawnManager = nil
RoundManager._eventSystem = nil
RoundManager._eliminationSystem = nil
RoundManager._dataManager = nil
RoundManager._inventoryManager = nil
RoundManager._leaderstatsManager = nil
RoundManager.IsRoundActive = false
RoundManager.CurrentMap = nil
RoundManager.ForcedMapName = nil
RoundManager.EndReason = nil
RoundManager.Winners = {}

function RoundManager:Init(playerManager, spawnManager, eventSystem, eliminationSystem, dataManager, inventoryManager, leaderstatsManager)
	self._playerManager = playerManager
	self._spawnManager = spawnManager
	self._eventSystem = eventSystem
	self._eliminationSystem = eliminationSystem
	self._dataManager = dataManager
	self._inventoryManager = inventoryManager
	self._leaderstatsManager = leaderstatsManager
end

function RoundManager:GetAvailableMaps()
	local mapsFolder = Workspace:FindFirstChild("Maps")
	if not mapsFolder then
		return {}
	end
	return mapsFolder:GetChildren()
end

function RoundManager:SetForcedMap(mapName: string)
	self.ForcedMapName = mapName
	return true
end

function RoundManager:ChooseMap()
	local maps = self:GetAvailableMaps()
	if #maps == 0 then
		self.CurrentMap = nil
		return "DefaultMap"
	end

	if self.ForcedMapName then
		for _, map in ipairs(maps) do
			if string.lower(map.Name) == string.lower(self.ForcedMapName) then
				self.CurrentMap = map
				self.ForcedMapName = nil
				return map.Name
			end
		end
		warn("[RoundManager] No se encontró el mapa forzado:", self.ForcedMapName)
		self.ForcedMapName = nil
	end

	self.CurrentMap = maps[math.random(1, #maps)]
	return self.CurrentMap.Name
end

function RoundManager:GetParticipants()
	return Players:GetPlayers()
end

function RoundManager:PrepareRound()
	local participants = self:GetParticipants()
	self._playerManager:SetParticipants(participants)
	self.Winners = {}
	self.EndReason = nil
	return participants
end

function RoundManager:StartRound()
	local participants = self:PrepareRound()
	local mapName = self:ChooseMap()
	self.IsRoundActive = true
	self._spawnManager:TeleportPlayersToRound(participants)
	self._eliminationSystem:BindParticipants(participants)

	for _, player in ipairs(participants) do
		self._inventoryManager:GrantItem(player, "DefaultButtonBadge")
	end

	roundStartedEvent:FireAllClients(mapName)
end

function RoundManager:HandlePlayerEliminated(player: Player, killer: Player?)
	if not self.IsRoundActive then
		return
	end

	self._playerManager:MarkEliminated(player)
	self._spawnManager:TeleportPlayerToLobby(player)

	if killer and killer ~= player then
		self._dataManager:AdjustStat(killer, "Kills", 1)
		self._leaderstatsManager:SyncPlayer(killer)
	end
	self._leaderstatsManager:SyncPlayer(player)
end

function RoundManager:GetEndReason()
	local aliveCount = self._playerManager:GetAliveCount()
	if aliveCount <= 0 then
		return "AllDead"
	end
	if aliveCount == 1 then
		return "LastPlayerStanding"
	end
	return nil
end

function RoundManager:FinishRound(reason: string)
	if not self.IsRoundActive then
		return
	end

	self.IsRoundActive = false
	self.EndReason = reason
	self._eventSystem:StopCurrentEvent()
	self._eliminationSystem:ClearBindings()

	self.Winners = self._playerManager:GetAlivePlayers()
	for _, winner in ipairs(self.Winners) do
		self._dataManager:AdjustStat(winner, "Wins", 1)
		self._leaderstatsManager:SyncPlayer(winner)
	end

	for _, player in ipairs(self._playerManager:GetPlayers()) do
		self._spawnManager:TeleportPlayerToLobby(player)
	end

	local winnerNames = {}
	for _, winner in ipairs(self.Winners) do
		table.insert(winnerNames, winner.Name)
	end

	self._playerManager:ClearRoundState()
	roundEndedEvent:FireAllClients(reason, winnerNames)
end

function RoundManager:ForceEnd(reason: string)
	self:FinishRound(reason)
end

return RoundManager
