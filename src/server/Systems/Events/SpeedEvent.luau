local Players = game:GetService("Players")

local SpeedEvent = {}
SpeedEvent.Name = "Speed"
SpeedEvent.Duration = 10
SpeedEvent.Intensity = 2
SpeedEvent._originalSpeeds = {}

function SpeedEvent:Start(_context)
	self._originalSpeeds = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self._originalSpeeds[player] = humanoid.WalkSpeed
			humanoid.WalkSpeed = humanoid.WalkSpeed + 8
		end
	end
	print("[SpeedEvent] Velocidad aumentada")
end

function SpeedEvent:Stop(_context)
	for player, originalSpeed in pairs(self._originalSpeeds) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = originalSpeed
		end
	end
	table.clear(self._originalSpeeds)
	print("[SpeedEvent] Velocidad restaurada")
end

return SpeedEvent
