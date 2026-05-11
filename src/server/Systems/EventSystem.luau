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
local eventActive = false --Flag para evitar múltiples eventos a la vez

local function startEvent(eventModule, eventName, roundPlayers, onEventFinished)
	if eventActive then
		warn("Ya hay un evento activo")
		return nil
	end

	eventActive = true
	currentEvent = eventModule

	print("[EventSystem] Iniciando evento:", eventName)

	currentEvent.Start(roundPlayers, function(winner)
		eventActive = false
		currentEvent = nil

		if onEventFinished then
			onEventFinished(winner)
		end
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

--Finalizar por tiempo
function EventSystem.FinishCurrentEventByTime(roundPlayers, onEventFinished)
	if currentEvent and currentEvent.FinishByTime then
		currentEvent.FinishByTime(roundPlayers, function(winner)
			eventActive = false
			currentEvent = nil

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
	currentEvent = nil
	eventActive = false
end

return EventSystem
