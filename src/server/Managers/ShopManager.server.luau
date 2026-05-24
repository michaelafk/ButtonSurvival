--[[
	ShopManager.luau

	Responsabilidades:
	- Validar compras
	- Descontar puntos
	- Dar la tool al inventario
	- avisar al inventorymanager y al cliente
]]
--Servicions a usar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
--Modulos a usar
local toolsFolder = ServerStorage:WaitForChild("Tools")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local Server = ServerScriptService:WaitForChild("Server")
local Managers = Server:WaitForChild("Managers")
--Eventos que se van a usar
local buyEvent = Remotes:WaitForChild("buyEvent")
local updateInventory = Remotes:WaitForChild("UpdateInventory")
--Archivos a usar
local InventoryManager = require(Managers:WaitForChild("InventoryManager"))

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

	if InventoryManager.HasItem(player, toolName) then
		return
	end
	points.Value = points.Value - cost
	InventoryManager.AddItem(player, toolName)
	--Dar la tool al backpack
	local tool = toolsFolder:FindFirstChild(toolName)
	if tool then
		local clone = tool:Clone()
		clone.Parent = player.Backpack
	end
	--Avisar al cliente
	updateInventory:FireClient(player, toolName)
end)
