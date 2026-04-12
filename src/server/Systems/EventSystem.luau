local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Configs = ReplicatedStorage:WaitForChild("Configs")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EventConfig = require(Configs:WaitForChild("EventConfig"))
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))

local eventStartedEvent = Remotes:WaitForChild(RemoteNames.EventStarted)
local eventEndedEvent = Remotes:WaitForChild(RemoteNames.EventEnded)

local EventSystem = {}
EventSystem.Events = {}
EventSystem.CurrentEvent = nil
EventSystem.CurrentTask = nil

local function loadEventModules()
	local folder = ServerScriptService.Systems:WaitForChild("Events")
	local events = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			table.insert(events, require(child))
		end
	end
	return events
end

function EventSystem:Init()
	self.Events = loadEventModules()
end

function EventSystem:GetRandomEvent()
	if #self.Events == 0 then
		return nil
	end
	return self.Events[math.random(1, #self.Events)]
end

function EventSystem:StopCurrentEvent()
	if not self.CurrentEvent then
		return
	end

	local current = self.CurrentEvent
	self.CurrentEvent = nil
	if current.Stop then
		current:Stop({ Workspace = Workspace })
	end
	eventEndedEvent:FireAllClients(current.Name)
end

function EventSystem:TriggerRandomEvent(context)
	if self.CurrentEvent then
		self:StopCurrentEvent()
	end

	local eventModule = self:GetRandomEvent()
	if not eventModule then
		warn("[EventSystem] No hay eventos registrados")
		return nil
	end

	local duration = eventModule.Duration or EventConfig.DefaultDuration
	self.CurrentEvent = eventModule

	if eventModule.Start then
		eventModule:Start(context)
	end

	eventStartedEvent:FireAllClients(eventModule.Name)

	task.delay(duration, function()
		if self.CurrentEvent == eventModule then
			self:StopCurrentEvent()
		end
	end)

	return eventModule.Name
end

return EventSystem
