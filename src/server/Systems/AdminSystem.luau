local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local EventConfig = require(Configs:WaitForChild("EventConfig"))
local AdminConfig = require(Configs:WaitForChild("AdminConfig"))

local AdminSystem = {}
AdminSystem._gameStateSystem = nil
AdminSystem._roundManager = nil
AdminSystem._eventSystem = nil

local function isAdmin(player: Player)
	for _, userId in ipairs(AdminConfig.UserIds) do
		if player.UserId == userId then
			return true
		end
	end
	return false
end

function AdminSystem:Init(gameStateSystem, roundManager, eventSystem)
	self._gameStateSystem = gameStateSystem
	self._roundManager = roundManager
	self._eventSystem = eventSystem
end

function AdminSystem:HandleCommand(player: Player, message: string)
	if not isAdmin(player) then
		return
	end

	local lower = string.lower(message)
	if lower == "!startround" then
		self._gameStateSystem:StartRoundNow()
	elseif lower == "!endround" then
		self._roundManager:ForceEnd("ForcedByAdmin")
	elseif lower == "!forceevent" then
		self._eventSystem:TriggerRandomEvent({ Activator = player, Source = "Admin" })
	elseif string.sub(lower, 1, 9) == "!loadmap " then
		warn("[AdminSystem] Cargar mapa específico queda como punto de extensión")
	end
end

function AdminSystem:Start()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			self:HandleCommand(player, message)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			self:HandleCommand(player, message)
		end)
	end
end

return AdminSystem
