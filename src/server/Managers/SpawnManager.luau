local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SpawnManager = {}
SpawnManager._playerManager = nil
SpawnManager._roundManager = nil
SpawnManager._boundPlayers = {}

local function getRandomChild(folder: Instance?)
	if not folder then
		return nil
	end
	local children = folder:GetChildren()
	if #children == 0 then
		return nil
	end
	return children[math.random(1, #children)]
end

local function teleportCharacter(character: Model, targetPart: BasePart)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	character:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
end

local function resolveMapSpawn(currentMap: Instance?)
	if currentMap then
		local roundSpawns = currentMap:FindFirstChild("RoundSpawns") or currentMap:FindFirstChild("SpawnPoints")
		local chosen = getRandomChild(roundSpawns)
		if chosen and chosen:IsA("BasePart") then
			return chosen
		end
	end

	local sharedFolder = Workspace:FindFirstChild("RoundSpawns")
	local fallback = getRandomChild(sharedFolder)
	if fallback and fallback:IsA("BasePart") then
		return fallback
	end

	local mapSpawn = Workspace:FindFirstChild("MapSpawn")
	if mapSpawn and mapSpawn:IsA("BasePart") then
		return mapSpawn
	end

	return nil
end

function SpawnManager:Init(playerManager, roundManager)
	self._playerManager = playerManager
	self._roundManager = roundManager
	self._boundPlayers = {}
	math.randomseed(os.clock() * 1000)
end

function SpawnManager:GetLobbySpawn()
	local folder = Workspace:FindFirstChild("LobbySpawns")
	local fromFolder = getRandomChild(folder)
	if fromFolder and fromFolder:IsA("BasePart") then
		return fromFolder
	end

	local fallback = Workspace:FindFirstChild("LobbySpawn")
	if fallback and fallback:IsA("BasePart") then
		return fallback
	end

	return nil
end

function SpawnManager:GetRoundSpawn()
	return resolveMapSpawn(self._roundManager and self._roundManager.CurrentMap or nil)
end

function SpawnManager:TeleportPlayerToLobby(player: Player)
	local target = self:GetLobbySpawn()
	if not target then
		warn("[SpawnManager] Falta Workspace/LobbySpawns o LobbySpawn")
		return
	end

	local character = player.Character
	if character then
		teleportCharacter(character, target)
	end
end

function SpawnManager:TeleportPlayerToRound(player: Player)
	local target = self:GetRoundSpawn()
	if not target then
		warn("[SpawnManager] Falta un spawn de ronda en el mapa o Workspace/RoundSpawns/MapSpawn")
		return
	end

	local character = player.Character
	if character then
		teleportCharacter(character, target)
	end
end

function SpawnManager:TeleportPlayersToLobby(players: {Player})
	for _, player in ipairs(players) do
		self:TeleportPlayerToLobby(player)
	end
end

function SpawnManager:TeleportPlayersToRound(players: {Player})
	for _, player in ipairs(players) do
		self:TeleportPlayerToRound(player)
	end
end

function SpawnManager:HandleCharacterSpawn(player: Player, character: Model)
	task.defer(function()
		character:WaitForChild("HumanoidRootPart", 5)
		if self._roundManager and self._roundManager.IsRoundActive and self._playerManager then
			if self._playerManager:IsParticipant(player) and self._playerManager:IsAlive(player) then
				self:TeleportPlayerToRound(player)
			else
				self:TeleportPlayerToLobby(player)
			end
		else
			self:TeleportPlayerToLobby(player)
		end
	end)
end

function SpawnManager:BindPlayer(player: Player)
	if self._boundPlayers[player] then
		return
	end

	self._boundPlayers[player] = player.CharacterAdded:Connect(function(character)
		self:HandleCharacterSpawn(player, character)
	end)

	if player.Character then
		self:HandleCharacterSpawn(player, player.Character)
	end
end

function SpawnManager:Start()
	Players.PlayerRemoving:Connect(function(player)
		local connection = self._boundPlayers[player]
		if connection then
			connection:Disconnect()
			self._boundPlayers[player] = nil
		end
	end)
end

return SpawnManager
