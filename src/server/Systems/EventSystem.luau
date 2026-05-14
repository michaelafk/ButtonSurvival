--[[
    EventSystem.lua

    Sistema encargado de:
    1. Iniciar eventos
    2. Controlar si hay un evento activo
	3. Guardr información del evento activo
    4. Finalizar eventos (por tiempo o condición)
]]

local MarkedEvent = require(script.Parent.Events.MarkedEvent)

local EventSystem = {}
--Evento actual activo
local currentEvent = nil
--Flag para evitar múltiples eventos a la vez
local eventActive = false
--Contexto del evento actual
local currentEventResult = nil
--Poner el resultado del evento
function EventSystem.SetCurrentEventResult(result)
	currentEventResult = result
end
--Obtener el resultado del evento
function EventSystem.GetCurrentEventResult()
	return currentEventResult
end
--Limpiar el resultado del evento
function EventSystem.ClearCurrentEventResult()
	currentEventResult = nil
end
--Iniciar evento
function EventSystem.StartMarkedEvent(roundPlayers, onEventFinished)
	if eventActive then
		warn("Ya hay un evento activo")
		return
	end

	eventActive = true
	currentEvent = MarkedEvent
	EventSystem.SetCurrentEventResult({
		EventName = "The Marked",
		MarkedPlayer = currentEvent.GetMarkedPlayer(),
		Winner = nil,
	})

	--Ejecutar evento
	currentEvent.Start(roundPlayers, function(winner, result)
		if result then
			currentEventResult = result
		else
			currentEventResult.Winner = winner
		end
		eventActive = false
		currentEvent = nil
		if onEventFinished then
			onEventFinished(winner, currentEventResult)
		end
	end, function(result)
		currentEventResult = result
	end)
end
--Finalizar por tiempo
function EventSystem.FinishCurrentEventByTime(roundPlayers, onEventFinished)
	if currentEvent and currentEvent.FinishByTime then
		currentEvent.FinishByTime(roundPlayers, function(winner, result)
			if result then
				currentEventResult = result
			elseif currentEventResult then
				currentEventResult.Winner = winner
			end
			eventActive = false
			currentEvent = nil
			if onEventFinished then
				onEventFinished(winner, currentEventResult)
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
	currentEventResult = nil
end

return EventSystem
