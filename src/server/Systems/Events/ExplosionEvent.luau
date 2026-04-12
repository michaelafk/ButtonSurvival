local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ExplosionEvent = {}
ExplosionEvent.Name = "Explosions"
ExplosionEvent.Duration = 6
ExplosionEvent.Intensity = 2
ExplosionEvent._activeToken = 0
ExplosionEvent._explosionsFolder = nil

local function ensureFolder(self)
	if self._explosionsFolder and self._explosionsFolder.Parent then
		return self._explosionsFolder
	end

	local folder = Workspace:FindFirstChild("TemporaryExplosions")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TemporaryExplosions"
		folder.Parent = Workspace
	end

	self._explosionsFolder = folder
	return folder
end

local function getAliveRoots()
	local roots = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			table.insert(roots, root)
		end
	end
	return roots
end

local function getExplosionPosition(context)
	local aliveRoots = getAliveRoots()
	if #aliveRoots > 0 then
		local chosenRoot = aliveRoots[math.random(1, #aliveRoots)]
		return chosenRoot.Position + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
	end

	local currentMap = context and context.CurrentMap
	if currentMap and currentMap:IsA("Model") then
		return currentMap:GetPivot().Position
	end

	return Vector3.new(0, 5, 0)
end

local function applyDamageAt(position, radius, maxDamage)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local distance = (root.Position - position).Magnitude
			if distance <= radius then
				local alpha = 1 - math.clamp(distance / radius, 0, 1)
				local damage = math.max(10, math.floor(maxDamage * alpha))
				humanoid:TakeDamage(damage)
			end
		end
	end
end

function ExplosionEvent:_triggerExplosion(context)
	local position = getExplosionPosition(context)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 12 + (self.Intensity * 2)
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = ensureFolder(self)

	applyDamageAt(position, explosion.BlastRadius, 45 + (self.Intensity * 5))
end

function ExplosionEvent:Start(context)
	self._activeToken += 1
	local token = self._activeToken

	task.spawn(function()
		while self._activeToken == token do
			for _ = 1, self.Intensity do
				self:_triggerExplosion(context)
				task.wait(0.25)
			end
			task.wait(1.2)
		end
	end)

	print("[ExplosionEvent] Explosiones iniciadas")
end

function ExplosionEvent:Stop(_context)
	self._activeToken += 1
	print("[ExplosionEvent] Explosiones finalizadas")
end

return ExplosionEvent
