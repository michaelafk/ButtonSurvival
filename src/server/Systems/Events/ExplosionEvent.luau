local ExplosionEvent = {}
ExplosionEvent.Name = "Explosions"
ExplosionEvent.Duration = 6

function ExplosionEvent:Start(_context)
	print("[ExplosionEvent] Explosiones iniciadas")
end

function ExplosionEvent:Stop(_context)
	print("[ExplosionEvent] Explosiones finalizadas")
end

return ExplosionEvent
