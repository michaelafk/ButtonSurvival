--[[
    EventSystem.lua

    Sistema encargado de:
    1. Iniciar eventos
    2. Controlar si hay un evento activo
    3. Finalizar eventos por tiempo o condición
]]

local MarkedEvent = require(script.Parent.Events.MarkedEvent)
local TsunamiEvent = require(script.Parent.Events.TsunamiEvent)
local EarthquakeEvent = require(script.Parent.Events.EarthquakeEvent)

local EventSystem = {}

local currentEvent = nil --Evento actual activo
local currentEventName = nil --Nombre del evento actual
local currentEventStartedAt = 0 --Momento en que empezo el evento
local currentEventDuration = nil --Duracion propia del evento, si la tiene
local currentOnEventFinished = nil --Callback original registrado al iniciar el evento
local eventActive = false --Flag para evitar multiples eventos a la vez

local function getEventDuration(eventModule)
	if eventModule and typeof(eventModule.GetDuration) == "function" then
		return eventModule.GetDuration()
	end

	return nil
end

local function clearCurrentEventState()
	currentEvent = nil
	currentEventName = nil
	currentEventStartedAt = 0
	currentEventDuration = nil
	currentOnEventFinished = nil
	eventActive = false
end

local function finishCurrentEvent(winner)
	local callback = currentOnEventFinished
	clearCurrentEventState()

	if callback then
		callback(winner)
	end
end

local function startEvent(eventModule, eventName, roundPlayers, onEventFinished)
	if eventActive then
		warn("Ya hay un evento activo")
		return nil
	end

	eventActive = true
	currentEvent = eventModule
	currentEventName = eventName
	currentEventStartedAt = os.clock()
	currentEventDuration = getEventDuration(eventModule)
	currentOnEventFinished = onEventFinished

	print("[EventSystem] Iniciando evento:", eventName)

	currentEvent.Start(roundPlayers, function(winner)
		finishCurrentEvent(winner)
	end)

	return eventName
end

function EventSystem.StartMarkedEvent(roundPlayers, onEventFinished)
	return startEvent(MarkedEvent, "Marked", roundPlayers, onEventFinished)
end

function EventSystem.StartTsunamiEvent(roundPlayers, onEventFinished)
	return startEvent(TsunamiEvent, "Tsunami", roundPlayers, onEventFinished)
end

function EventSystem.StartEarthquakeEvent(roundPlayers, onEventFinished)
	return startEvent(EarthquakeEvent, "Earthquake", roundPlayers, onEventFinished)
end

function EventSystem.StartRandomGlobalEvent(roundPlayers, onEventFinished)
	local availableEvents = {
		{ Name = "Marked", Module = MarkedEvent },
		{ Name = "Tsunami", Module = TsunamiEvent },
		{ Name = "Earthquake", Module = EarthquakeEvent },
	}

	local chosenEvent = availableEvents[math.random(1, #availableEvents)]
	return startEvent(chosenEvent.Module, chosenEvent.Name, roundPlayers, onEventFinished)
end

function EventSystem.IsEventActive()
	return eventActive
end

function EventSystem.GetCurrentEventName()
	return currentEventName
end

function EventSystem.GetCurrentEventDuration()
	return currentEventDuration
end

function EventSystem.GetCurrentEventTimeLeft()
	if not eventActive then
		return 0
	end

	if not currentEventDuration then
		return nil
	end

	local elapsed = os.clock() - currentEventStartedAt
	return math.max(math.ceil(currentEventDuration - elapsed), 0)
end

--Finalizar por tiempo
function EventSystem.FinishCurrentEventByTime(roundPlayers, onEventFinished)
	if currentEvent and currentEvent.FinishByTime then
		currentEvent.FinishByTime(roundPlayers, function(winner)
			finishCurrentEvent(winner)

			if onEventFinished then
				onEventFinished(winner)
			end
		end)
	end
end

function EventSystem.CleanupCurrentEvent(roundPlayers)
	if currentEvent and currentEvent.Cleanup then
		currentEvent.Cleanup(roundPlayers)
	end
	clearCurrentEventState()
end

return EventSystem
