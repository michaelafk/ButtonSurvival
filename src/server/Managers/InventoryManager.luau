local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local InventoryConfig = require(Configs:WaitForChild("InventoryConfig"))

local InventoryManager = {}
InventoryManager._inventories = {}

function InventoryManager:Init()
	self._inventories = {}
end

function InventoryManager:SetupPlayer(player: Player)
	local owned = {}
	for _, itemName in ipairs(InventoryConfig.DefaultItems) do
		owned[itemName] = true
	end

	self._inventories[player] = {
		Owned = owned,
		Equipped = nil,
	}
end

function InventoryManager:GrantItem(player: Player, itemName: string)
	local inventory = self._inventories[player]
	if not inventory or not InventoryConfig.ValidItems[itemName] then
		return false
	end

	inventory.Owned[itemName] = true
	return true
end

function InventoryManager:OwnsItem(player: Player, itemName: string)
	local inventory = self._inventories[player]
	return inventory ~= nil and inventory.Owned[itemName] == true
end

function InventoryManager:EquipItem(player: Player, itemName: string)
	local inventory = self._inventories[player]
	local itemConfig = InventoryConfig.ValidItems[itemName]
	if not inventory or not itemConfig then
		return false
	end

	if inventory.Owned[itemName] ~= true then
		return false
	end

	if itemConfig.Equippable ~= true then
		return false
	end

	inventory.Equipped = itemName
	return true
end

function InventoryManager:GetEquippedItem(player: Player)
	local inventory = self._inventories[player]
	return inventory and inventory.Equipped or nil
end

function InventoryManager:GetInventory(player: Player)
	return self._inventories[player]
end

function InventoryManager:ReleasePlayer(player: Player)
	self._inventories[player] = nil
end

return InventoryManager
