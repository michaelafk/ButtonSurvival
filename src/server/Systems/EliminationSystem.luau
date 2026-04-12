local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))
local playerEliminatedEvent = Remotes:WaitForChild(RemoteNames.PlayerEliminated)

local EliminationSystem = {}
EliminationSystem._playerManager = nil
EliminationSystem._roundManager = nil
EliminationSystem._connections = {}

local function getKillerFromHumanoid(humanoid: Humanoid)
	local creator = humanoid:FindFirstChild("creator")
	if creator and creator.Value and creator.Value:IsA("Player") then
		return creator.Value
	end
	return nil
end

function EliminationSystem:Init(playerManager, roundManager)
	self._playerManager = playerManager
	self._roundManager = roundManager
	self._connections = {}
end

function EliminationSystem:ClearBindings()
	for _, connection in ipairs(self._connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(self._connections)
end

function EliminationSystem:BindParticipants(players: {Player})
	self:ClearBindings()

	for _, player in ipairs(players) do
		local function bindCharacter(character: Model)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				return
			end

			table.insert(self._connections, humanoid.Died:Connect(function()
				if self._playerManager:IsAlive(player) then
					local killer = getKillerFromHumanoid(humanoid)
					self._roundManager:HandlePlayerEliminated(player, killer)
					playerEliminatedEvent:FireAllClients(player.Name)
				end
			end))
		end

		if player.Character then
			bindCharacter(player.Character)
		end

		table.insert(self._connections, player.CharacterAdded:Connect(function(character)
			bindCharacter(character)
		end))
	end
end

return EliminationSystem
