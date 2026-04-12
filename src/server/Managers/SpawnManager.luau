local Workspace = game:GetService("Workspace")

local SpawnManager = {}

local function getSpawnFromFolder(folderName: string, fallbackName: string)
	local folder = Workspace:FindFirstChild(folderName)
	if folder then
		local children = folder:GetChildren()
		if #children > 0 then
			return children[math.random(1, #children)]
		end
	end
	return Workspace:FindFirstChild(fallbackName)
end

local function teleportCharacter(character: Model, targetPart: BasePart)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	character:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
end

function SpawnManager:Init()
	math.randomseed(os.clock() * 1000)
end

function SpawnManager:GetLobbySpawn()
	return getSpawnFromFolder("LobbySpawns", "LobbySpawn")
end

function SpawnManager:GetRoundSpawn()
	return getSpawnFromFolder("RoundSpawns", "MapSpawn")
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
		warn("[SpawnManager] Falta Workspace/RoundSpawns o MapSpawn")
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

return SpawnManager
