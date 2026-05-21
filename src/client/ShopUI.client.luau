--Servicions a usar
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
--Espera a que el ScreenGui cargue
local screenGui = playerGui:WaitForChild("GameUI")
--Referencias principales
local shopFrame = screenGui:WaitForChild("ShopFrame")
local shopBtn = screenGui:WaitForChild("Shop")
local inventoryBtn = screenGui:WaitForChild("Inventory")
local pointsImage = screenGui:WaitForChild("Points")
local pointsLabel = pointsImage:WaitForChild("PointsLabel")
local closeBtn = shopFrame:WaitForChild("CloseShopMenubtn")

--Puntos del jugador
local leaderstats = player:WaitForChild("leaderstats")
local pointsStat = leaderstats:WaitForChild("Points")

--Objetos de la tienda(Item1, Item2, Item3)
local ITEMS = {
	{
		slot = "Item1",
		name = "Knife",
		cost = 15,
		toolName = "Knife", -- nombre exacto de la Tool en ServerStorage/ReplicatedStorage
	},
	{
		slot = "Item2",
		name = "Bloxycola",
		cost = 20,
		toolName = "Bloxy Cola",
	},
	{
		slot = "Item3",
		name = "Sword",
		cost = 30,
		toolName = "ClassicSword",
	},
}

--Inventario en memoria (se resetea al morir/rejoin), mas adelante se usara un datastore
--para guardar lo que se compra y no perderlo
local owned = {}

--Refresca el boton Buy de un item concreto
local function refreshItem(item)
	local frame = shopFrame:FindFirstChild(item.slot)
	if not frame then
		return
	end
	local buyBtn = frame:FindFirstChildWhichIsA("TextButton")
	if not buyBtn then
		return
	end

	if owned[item.slot] then
		buyBtn.Text = "Owned"
		buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		buyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
		buyBtn.Active = false
	elseif pointsStat.Value < item.cost then
		buyBtn.Text = "Buy"
		buyBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30) -- rojo = no puedes
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Active = false
	else
		buyBtn.Text = "Buy"
		buyBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50) -- verde = puedes
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Active = true
	end
end

--Refresca todos los items
local function refreshShop()
	for _, item in ipairs(ITEMS) do
		refreshItem(item)
	end
end

--Compra un item
local function buyItem(item)
	if owned[item.slot] then
		return
	end
	if pointsStat.Value < item.cost then
		return
	end
	--Descontar puntos en el servidor con un RemoteEvent
	local repStorage = game:GetService("ReplicatedStorage")
	local buyEvent = repStorage:WaitForChild("BuyItem")
	buyEvent:FireServer(item.slot, item.cost, item.toolName)

	owned[item.slot] = true
	refreshShop()
end
--Cuando los puntos cambien se actualiza el leaderstats
pointsStat:GetPropertyChangedSignal("Value"):Connect(function()
	refreshShop()
end)

--Conecta botones Buy de cada item
for _, item in ipairs(ITEMS) do
	local frame = shopFrame:FindFirstChild(item.slot)
	if frame then
		local buyBtn = frame:FindFirstChildWhichIsA("TextButton")
		if buyBtn then
			buyBtn.MouseButton1Click:Connect(function()
				buyItem(item)
			end)
		end
	end
end
--Abrir/cerrar tienda con el botón Shop
shopBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
	if shopFrame.Visible then
		refreshShop()
	end
end)
--Cerrar con la X roja
closeBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)
--Boton Inventory (de momento solo cierra la tienda)
inventoryBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
	--aqui se abriria el inventoryframe para guardar todo lo que se compra
end)
-- Estado inicial
shopFrame.Visible = false
refreshShop()
