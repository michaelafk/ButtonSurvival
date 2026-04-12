local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local InventoryConfig = require(Configs:WaitForChild("InventoryConfig"))
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))

local InventoryService = {}
InventoryService._inventoryManager = nil

function InventoryService:Init(inventoryManager)
	self._inventoryManager = inventoryManager

	local requestEquipItem = Remotes:WaitForChild(RemoteNames.RequestEquipItem)
	requestEquipItem.OnServerInvoke = function(player: Player, itemName: unknown)
		if type(itemName) ~= "string" then
			return false, "InvalidItemName"
		end

		if not InventoryConfig.ValidItems[itemName] then
			return false, "UnknownItem"
		end

		local success = self._inventoryManager:EquipItem(player, itemName)
		if not success then
			return false, "ItemNotOwnedOrNotEquippable"
		end

		return true, itemName
	end
end

return InventoryService
