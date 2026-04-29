--[[
    EventSystem.lua

    Sistema encargado de:
    1. Iniciar eventos
    2. Controlar si hay un evento activo
    3. Finalizar eventos (por tiempo o condición)
]]

local MarkedEvent = require(script.Parent.Events.MarkedEvent)

local EventSystem = {}

local currentEvent = nil --Evento actual activo
local eventActive = false --Flag para evitar múltiples eventos a la vez

--Iniciar evento
function EventSystem.StartMarkedEvent(roundPlayers, onEventFinished)
	if eventActive then
		warn("Ya hay un evento activo")
		return
	end

	eventActive = true
	currentEvent = MarkedEvent

	--Ejecutar evento
	currentEvent.Start(roundPlayers, function(winner)
		eventActive = false
		currentEvent = nil

		if onEventFinished then
			onEventFinished(winner)
		end
	end)
end
--Finalzar por tiempo
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
