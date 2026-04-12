local InventoryManager = {}
InventoryManager._inventories = {}

function InventoryManager:Init()
	self._inventories = {}
end

function InventoryManager:SetupPlayer(player: Player)
	self._inventories[player] = {
		Owned = {},
		Equipped = nil,
	}
end

function InventoryManager:GrantItem(player: Player, itemName: string)
	local inventory = self._inventories[player]
	if not inventory then
		return
	end

	inventory.Owned[itemName] = true
end

function InventoryManager:EquipItem(player: Player, itemName: string)
	local inventory = self._inventories[player]
	if not inventory then
		return false
	end

	if not inventory.Owned[itemName] then
		return false
	end

	inventory.Equipped = itemName
	return true
end

function InventoryManager:GetEquippedItem(player: Player)
	local inventory = self._inventories[player]
	return inventory and inventory.Equipped or nil
end

function InventoryManager:ReleasePlayer(player: Player)
	self._inventories[player] = nil
end

return InventoryManager
