local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataManager = {}
DataManager._store = nil
DataManager._session = {}

local DEFAULT_DATA = {
	Wins = 0,
	Kills = 0,
}

local function cloneDefaultData()
	return {
		Wins = DEFAULT_DATA.Wins,
		Kills = DEFAULT_DATA.Kills,
	}
end

function DataManager:Init()
	self._store = DataStoreService:GetDataStore("ButtonSurvival_PlayerData_v1")
end

function DataManager:LoadPlayerData(player: Player)
	local key = tostring(player.UserId)
	local loadedData = cloneDefaultData()

	local success, result = pcall(function()
		return self._store:GetAsync(key)
	end)

	if success and type(result) == "table" then
		loadedData.Wins = tonumber(result.Wins) or 0
		loadedData.Kills = tonumber(result.Kills) or 0
	elseif not success then
		warn("[DataManager] Error cargando datos de", player.Name, result)
	end

	self._session[player] = loadedData
	return loadedData
end

function DataManager:GetPlayerData(player: Player)
	return self._session[player]
end

function DataManager:AdjustStat(player: Player, statName: string, amount: number)
	local profile = self._session[player]
	if not profile then
		return
	end

	profile[statName] = (tonumber(profile[statName]) or 0) + amount
end

function DataManager:SavePlayerData(player: Player)
	local profile = self._session[player]
	if not profile then
		return
	end

	local key = tostring(player.UserId)
	local payload = {
		Wins = tonumber(profile.Wins) or 0,
		Kills = tonumber(profile.Kills) or 0,
	}

	local success, err = pcall(function()
		self._store:SetAsync(key, payload)
	end)

	if not success then
		warn("[DataManager] Error guardando datos de", player.Name, err)
	end
end

function DataManager:ReleasePlayer(player: Player)
	self:SavePlayerData(player)
	self._session[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	DataManager:ReleasePlayer(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataManager:SavePlayerData(player)
	end
end)

return DataManager
