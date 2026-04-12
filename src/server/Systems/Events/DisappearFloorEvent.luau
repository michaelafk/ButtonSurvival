local Workspace = game:GetService("Workspace")

local DisappearFloorEvent = {}
DisappearFloorEvent.Name = "DisappearFloor"
DisappearFloorEvent.Duration = 7
DisappearFloorEvent.Intensity = 1
DisappearFloorEvent._hiddenParts = {}

local function isFloorCandidate(instance: Instance)
	return instance:IsA("BasePart") and (instance.Name == "Floor" or instance:GetAttribute("IsEventFloor") == true)
end

function DisappearFloorEvent:Start(_context)
	self._hiddenParts = {}
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if isFloorCandidate(descendant) then
			self._hiddenParts[descendant] = {
				Transparency = descendant.Transparency,
				CanCollide = descendant.CanCollide,
			}
			descendant.Transparency = 1
			descendant.CanCollide = false
		end
	end
	print("[DisappearFloorEvent] Suelo desaparecido")
end

function DisappearFloorEvent:Stop(_context)
	for part, state in pairs(self._hiddenParts) do
		if part and part.Parent then
			part.Transparency = state.Transparency
			part.CanCollide = state.CanCollide
		end
	end
	table.clear(self._hiddenParts)
	print("[DisappearFloorEvent] Suelo restaurado")
end

return DisappearFloorEvent
