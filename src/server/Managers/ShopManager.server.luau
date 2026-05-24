--Servicions a usar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
--Modulos a usar
local toolsFolder = ServerStorage:WaitForChild("Tools")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
--Eventos que se van a usar
local buyEvent = Remotes:WaitForChild("buyEvent")

buyEvent.OnServerEvent:Connect(function(player, slot, cost, toolName)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local points = leaderstats:FindFirstChild("Points")
	if not points then
		return
	end

	--Validacion en servidor evita trampas
	if points.Value < cost then
		return
	end

	points.Value = points.Value - cost

	--Dar la tool al backpack
	local tool = toolsFolder:FindFirstChild(toolName)
	if tool then
		local clone = tool:Clone()
		clone.Parent = player.Backpack
	end
end)
