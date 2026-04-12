local RainEvent = {}
RainEvent.Name = "Rain"
RainEvent.Duration = 8
RainEvent.Intensity = 3

function RainEvent:Start(context)
	print("[RainEvent] Lluvia de objetos iniciada", context and context.Activator and context.Activator.Name)
end

function RainEvent:Stop(_context)
	print("[RainEvent] Lluvia finalizada")
end

return RainEvent
