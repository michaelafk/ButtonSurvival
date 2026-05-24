--[[
	InventoryManager.luau

	Responsabilidades:
	- Guardar inventario de cada jugador en memoria
	- reentregar tools al respawnear
]]
--Servicios a usar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
--Modulos a usar
local toolsFolder = ServerStorage:WaitForChild("Tools")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes     = Shared:WaitForChild("Remotes")
local updateInventory = Remotes:WaitForChild("UpdateInventory")

local InventoryManager = {}
--Inventario del jugador: knife, sword, etc
local inventories = {}
--Inicializa el inventario del jugador y gestiona el respawn
Players.PlayerAdded:Connect(function(player)
    inventories[player] = {}
    player.CharacterAdded:Connect(function()
        --espera a que el backpack esté listo
        task.wait(1)
        for _, toolName in ipairs(inventories[player] or {}) do
            local tool = toolsFolder:FindFirstChild(toolName)
            if tool then
                tool:Clone().Parent = player.Backpack
            end
        end
        --sincronizar inventario visual con el cliente tras respawn
        for _, toolName in ipairs(inventories[player] or {}) do
            updateInventory:FireClient(player, toolName)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    inventories[player] = nil
end)

--Añade un item al inventario del jugador
function InventoryManager.AddItem(player, toolName)
    if not inventories[player] then return end
    table.insert(inventories[player], toolName)
end

--Comprueba si el jugador ya tiene un item
function InventoryManager.HasItem(player, toolName)
    if not inventories[player] then return false end
    for _, owned in ipairs(inventories[player]) do
        if owned == toolName then return true end
    end
    return false
end

--Devuelve todos los items del jugador
function InventoryManager.GetItems(player)
    return inventories[player] or {}
end

return InventoryManager