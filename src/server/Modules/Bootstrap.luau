local ServerScriptService = game:GetService("ServerScriptService")

local Managers = ServerScriptService:WaitForChild("Managers")
local Services = ServerScriptService:WaitForChild("Services")
local Systems = ServerScriptService:WaitForChild("Systems")

local Bootstrap = {}
Bootstrap._started = false

function Bootstrap:Start()
	if self._started then
		return
	end
	self._started = true

	local RemoteService = require(Services:WaitForChild("RemoteService"))
	local InventoryService = require(Services:WaitForChild("InventoryService"))
	local DataManager = require(Managers:WaitForChild("DataManager"))
	local PlayerManager = require(Managers:WaitForChild("PlayerManager"))
	local SpawnManager = require(Managers:WaitForChild("SpawnManager"))
	local InventoryManager = require(Managers:WaitForChild("InventoryManager"))
	local LeaderstatsManager = require(Managers:WaitForChild("LeaderstatsManager"))
	local EventSystem = require(Systems:WaitForChild("EventSystem"))
	local EliminationSystem = require(Systems:WaitForChild("EliminationSystem"))
	local RoundManager = require(Managers:WaitForChild("RoundManager"))
	local ButtonSystem = require(Systems:WaitForChild("ButtonSystem"))
	local GameStateSystem = require(Systems:WaitForChild("GameStateSystem"))
	local AdminSystem = require(Systems:WaitForChild("AdminSystem"))

	RemoteService:Init()
	DataManager:Init()
	InventoryManager:Init()
	LeaderstatsManager:Init(DataManager)
	PlayerManager:Init(DataManager, LeaderstatsManager, InventoryManager)
	SpawnManager:Init(PlayerManager, RoundManager)
	PlayerManager:SetSpawnManager(SpawnManager)
	EventSystem:Init()
	RoundManager:Init(PlayerManager, SpawnManager, EventSystem, EliminationSystem, DataManager, InventoryManager, LeaderstatsManager)
	EliminationSystem:Init(PlayerManager, RoundManager)
	InventoryService:Init(InventoryManager)
	ButtonSystem:Init(RoundManager, EventSystem)
	GameStateSystem:Init(PlayerManager, RoundManager)
	AdminSystem:Init(GameStateSystem, RoundManager, EventSystem)

	SpawnManager:Start()
	PlayerManager:Start()
	ButtonSystem:Start()
	AdminSystem:Start()
	GameStateSystem:Start()

	print("[Bootstrap] Sistemas iniciados")
end

return Bootstrap
