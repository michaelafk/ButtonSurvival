--[[
	ShopUI.luau

	Responsabilidades:
	- Abrir/Cerrar ShopFrame
	- Refrescar botones segun puntos
]]
--Servicions a usar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Modulos a usar
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
--Remotes
local buyEvent = Remotes:WaitForChild("buyEvent")
--Interfaz jugador
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("GameUI")
--Referencias UI
--Tienda
local shopFrame = screenGui:WaitForChild("ShopFrame")
local shopBtn = screenGui:WaitForChild("Shop")
local closeBtn = shopFrame:WaitForChild("CloseShopMenubtn")
--Puntos del jugador leaderstats
local leaderstats = player:WaitForChild("leaderstats")
local pointsStat = leaderstats:WaitForChild("Points")

--Objetos de la tienda(Item1, Item2, Item3)
local ITEMS = {
	{
		slot = "Item1",
		name = "Knife",
		cost = 15,
		toolName = "Knife",
		btnName = "Item1btn",
	},
	{
		slot = "Item2",
		name = "Bloxycola",
		cost = 20,
		toolName = "Bloxy Cola",
		btnName = "Item2btn",
	},
	{
		slot = "Item3",
		name = "Sword",
		cost = 30,
		toolName = "ClassicSword",
		btnName = "Item3btn",
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
	local buyBtn = frame:FindFirstChild(item.btnName)
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
		local buyBtn = frame:FindFirstChild(item.btnName)
		if buyBtn then
			buyBtn.MouseButton1Click:Connect(function()
				buyItem(item)
			end)
		else
			warn("[ShopUI] no encontro el boton:  " .. item.btnName)
		end
	else
		warn("[ShopUI] no se encontro el frame: " .. item.slot)
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
-- Estado inicial
shopFrame.Visible = false
refreshShop()
