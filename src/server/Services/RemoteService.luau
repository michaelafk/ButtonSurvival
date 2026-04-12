local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remoteNames = require(remotesFolder:WaitForChild("RemoteNames"))

local RemoteService = {}

local REMOTE_DEFINITIONS = {
	[remoteNames.UpdateTimer] = "RemoteEvent",
	[remoteNames.GameStateChanged] = "RemoteEvent",
	[remoteNames.RoundStarted] = "RemoteEvent",
	[remoteNames.RoundEnded] = "RemoteEvent",
	[remoteNames.PlayerEliminated] = "RemoteEvent",
	[remoteNames.ButtonPressed] = "RemoteEvent",
	[remoteNames.EventStarted] = "RemoteEvent",
	[remoteNames.EventEnded] = "RemoteEvent",
	[remoteNames.GetCurrentState] = "RemoteFunction",
}

function RemoteService:Init()
	for name, className in pairs(REMOTE_DEFINITIONS) do
		if not remotesFolder:FindFirstChild(name) then
			local remote = Instance.new(className)
			remote.Name = name
			remote.Parent = remotesFolder
		end
	end
end

return RemoteService
