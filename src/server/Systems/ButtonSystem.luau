local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))
local buttonPressedEvent = Remotes:WaitForChild(RemoteNames.ButtonPressed)

local ButtonSystem = {}
ButtonSystem._roundManager = nil
ButtonSystem._eventSystem = nil
ButtonSystem.IsLocked = false
ButtonSystem.LastActivator = nil
ButtonSystem.LockDuration = 1.5

function ButtonSystem:Init(roundManager, eventSystem)
	self._roundManager = roundManager
	self._eventSystem = eventSystem
end

function ButtonSystem:Press(player: Player)
	if self.IsLocked or not self._roundManager.IsRoundActive then
		return false
	end

	self.IsLocked = true
	self.LastActivator = player

	local eventName = self._eventSystem:TriggerRandomEvent({ Activator = player, Workspace = Workspace }) or "None"
	buttonPressedEvent:FireAllClients(player.Name, eventName)

	task.delay(self.LockDuration, function()
		self.IsLocked = false
	end)

	return true
end

function ButtonSystem:HookButton(buttonInstance: Instance)
	local prompt = buttonInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(player)
			self:Press(player)
		end)
		return
	end

	local clickDetector = buttonInstance:FindFirstChildWhichIsA("ClickDetector", true)
	if clickDetector then
		clickDetector.MouseClick:Connect(function(player)
			self:Press(player)
		end)
		return
	end

	warn("[ButtonSystem] MainButton no tiene ProximityPrompt ni ClickDetector")
end

function ButtonSystem:Start()
	local button = Workspace:FindFirstChild("MainButton")
	if not button then
		warn("[ButtonSystem] No se encontró Workspace/MainButton. El sistema queda listo pero sin botón físico.")
		return
	end
	self:HookButton(button)
end

return ButtonSystem
