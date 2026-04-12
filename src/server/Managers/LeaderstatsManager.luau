local LeaderstatsManager = {}
LeaderstatsManager._dataManager = nil

function LeaderstatsManager:Init(dataManager)
	self._dataManager = dataManager
end

function LeaderstatsManager:SetupPlayer(player: Player)
	local profile = self._dataManager:GetPlayerData(player)
	if not profile then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name = "Victorias"
	wins.Value = profile.Wins
	wins.Parent = folder

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = profile.Kills
	kills.Parent = folder
end

function LeaderstatsManager:SyncPlayer(player: Player)
	local profile = self._dataManager:GetPlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not profile or not leaderstats then
		return
	end

	local wins = leaderstats:FindFirstChild("Victorias")
	local kills = leaderstats:FindFirstChild("Kills")

	if wins then
		wins.Value = tonumber(profile.Wins) or 0
	end
	if kills then
		kills.Value = tonumber(profile.Kills) or 0
	end
end

return LeaderstatsManager
