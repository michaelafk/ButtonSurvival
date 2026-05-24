--[[
	InventoryUI.luau

	Responsabilidades:
	- Abrir/Cerrrar InventoryFrame
	- Mostrar items comprados como cards
    - Gestionar equipar/desequipar (maximo 2)
]]
--Servicios a usar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Interfaz del jugador
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gameUI    = playerGui:WaitForChild("GameUI")
--Referencias UI
local inventoryFrame = gameUI:WaitForChild("InventoryFrame")
local scrollingFrame = inventoryFrame:WaitForChild("ScrollingFrame")
local closeInvBtn = inventoryFrame:WaitForChild("CloseShopMenubtn")
local inventoryBtn = gameUI:WaitForChild("Inventory")
--Template Item
local templates = gameUI:WaitForChild("Templates")
local templateItem = templates:WaitForChild("TemplateItem")
--Remotes
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local updateInventory = Remotes:WaitForChild("UpdateInventory")
--Datos visuales
local ITEM_DATA = {
    Knife = { image = "http://www.roblox.com/asset?id=155344898"},
    Bloxycola = {image = "http://www.roblox.com/asset/?id=10472127"},
    ClassicSword = {image = "rbxasset://Textures/Sword128.png"},
}
--Estado de equipado
local equipped = {}
local equippedCount = 0
local MAX_EQUIPPED = 2


local function equipItem(toolName)
    local backpack  = player.Backpack
    local character = player.Character

    if equipped[toolName] then
        --Desequipar: mover del character al backpack
        if character then
            local tool = character:FindFirstChild(toolName)
            if tool then
                tool.Parent = backpack
            end
        end
        equipped[toolName] = false
        equippedCount = equippedCount - 1
    else
        --Equipar
        if equippedCount >= MAX_EQUIPPED then
            warn("[InventoryUI] Máximo de items equipados alcanzado (2)")
            return
        end
        local tool = backpack:FindFirstChild(toolName)
        if tool then
            tool.Parent = character
            equipped[toolName] = true
            equippedCount = equippedCount + 1
        else
            warn("[InventoryUI] Tool no encontrada en backpack:", toolName)
        end
    end
end

local function addItemToInventory(toolName)
    local data = ITEM_DATA[toolName]
    if not data then
        warn("[InventoryUI] Item no reconocido:", toolName)
        return
    end

    --Evitar duplicados en la UI
    if scrollingFrame:FindFirstChild(toolName) then return end

    local card   = templateItem:Clone()
    card.Name    = toolName
    card.Visible = true
    card.Parent  = scrollingFrame

    local imgBtn = card:FindFirstChildWhichIsA("ImageButton")
    if imgBtn then
        imgBtn.Image = data.image
        imgBtn.MouseButton1Click:Connect(function()
            equipItem(toolName)
        end)
    end
end

--Recibe items comprados desde el servidor
updateInventory.OnClientEvent:Connect(function(toolName)
    addItemToInventory(toolName)
end)

--Al respawnear, resetear estado de equipados
player.CharacterAdded:Connect(function()
    equipped = {}
    equippedCount = 0
end)

inventoryBtn.MouseButton1Click:Connect(function()
    gameUI:WaitForChild("ShopFrame").Visible = false
    inventoryFrame.Visible = not inventoryFrame.Visible
end)

closeInvBtn.MouseButton1Click:Connect(function()
    inventoryFrame.Visible = false
end)

inventoryFrame.Visible = false