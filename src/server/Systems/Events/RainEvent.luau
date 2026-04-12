local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local RainEvent = {}
RainEvent.Name = "Rain"
RainEvent.Duration = 8
RainEvent.Intensity = 3
RainEvent._activeToken = 0
RainEvent._spawnedParts = {}

local function getAliveCharacters()
	local characters = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			table.insert(characters, character)
		end
	end
	return characters
end

local function getTargetPosition(context)
	local currentMap = context and context.CurrentMap
	if currentMap and currentMap:IsA("Model") then
		return currentMap:GetPivot().Position
	end

	local aliveCharacters = getAliveCharacters()
	if #aliveCharacters > 0 then
		local chosenCharacter = aliveCharacters[math.random(1, #aliveCharacters)]
		local root = chosenCharacter:FindFirstChild("HumanoidRootPart")
		if root then
			return root.Position
		end
	end

	local activator = context and context.Activator
	local activatorRoot = activator and activator.Character and activator.Character:FindFirstChild("HumanoidRootPart")
	if activatorRoot then
		return activatorRoot.Position
	end

	return Vector3.new(0, 20, 0)
end

local function tagAsRainPart(part)
	part.Name = "RainObject"
	part.Material = Enum.Material.Metal
	part.Size = Vector3.new(2, 2, 2)
	part.Shape = Enum.PartType.Ball
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = true
	part.Anchored = false
	part.Color = Color3.fromRGB(180, 180, 180)
end

function RainEvent:_spawnRainObject(context)
	local targetPosition = getTargetPosition(context)
	local fallingPart = Instance.new("Part")
	tagAsRainPart(fallingPart)
	fallingPart.CFrame = CFrame.new(
		targetPosition
			+ Vector3.new(
				math.random(-18, 18),
				math.random(28, 40),
				math.random(-18, 18)
			)
	)
	fallingPart.AssemblyLinearVelocity = Vector3.new(math.random(-2, 2), -math.random(45, 60), math.random(-2, 2))
	fallingPart.Parent = Workspace
	fallingPart:SetNetworkOwner(nil)

	self._spawnedParts[fallingPart] = true

	local touchedConnection
	touchedConnection = fallingPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(18)
		end

		if touchedConnection and touchedConnection.Connected then
			touchedConnection:Disconnect()
		end
		self._spawnedParts[fallingPart] = nil
		fallingPart:Destroy()
	end)

	Debris:AddItem(fallingPart, 6)
	task.delay(6, function()
		self._spawnedParts[fallingPart] = nil
		if touchedConnection and touchedConnection.Connected then
			touchedConnection:Disconnect()
		end
	end)
end

function RainEvent:Start(context)
	self._activeToken += 1
	local token = self._activeToken
	self._spawnedParts = {}

	task.spawn(function()
		while self._activeToken == token do
			for _ = 1, self.Intensity do
				self:_spawnRainObject(context)
			end
			task.wait(0.35)
		end
	end)

	print("[RainEvent] Lluvia de objetos iniciada")
end

function RainEvent:Stop(_context)
	self._activeToken += 1
	for part in pairs(self._spawnedParts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	table.clear(self._spawnedParts)
	print("[RainEvent] Lluvia finalizada")
end

return RainEvent
