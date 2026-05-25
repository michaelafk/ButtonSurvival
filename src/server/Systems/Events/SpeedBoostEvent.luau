--[[
	SpeedBoostEvent.lua

	Evento individual: "Velocidad"
	Descripcion:
	1. Se aplica solo al jugador que pulsa el boton.
	2. Aumenta temporalmente su WalkSpeed.
	3. Al terminar, restaura su velocidad original.
]]

local SpeedBoostEvent = {}

local activeBoosts = {}

local DEFAULT_DURATION = 10
local DEFAULT_SPEED = 32

local function getHumanoid(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

function SpeedBoostEvent.Start(player, onEventFinished, config)
	config = config or {}

	if not player then
		warn("[SpeedBoostEvent] No se recibio jugador")
		if onEventFinished then
			onEventFinished("NoPlayer")
		end
		return
	end

	local humanoid = getHumanoid(player)
	if not humanoid or humanoid.Health <= 0 then
		warn("[SpeedBoostEvent] El jugador no tiene Humanoid valido")
		if onEventFinished then
			onEventFinished("InvalidPlayer")
		end
		return
	end

	local duration = config.Duration or DEFAULT_DURATION
	local boostSpeed = config.Speed or DEFAULT_SPEED

	if activeBoosts[player] then
		warn("[SpeedBoostEvent] El jugador ya tiene velocidad activa")
		if onEventFinished then
			onEventFinished("AlreadyActive")
		end
		return
	end

	local originalSpeed = humanoid.WalkSpeed

	activeBoosts[player] = {
		OriginalSpeed = originalSpeed,
		Humanoid = humanoid,
	}

	humanoid.WalkSpeed = boostSpeed

	print("[SpeedBoostEvent] Velocidad aplicada a:", player.Name)

	task.delay(duration, function()
		SpeedBoostEvent.Cleanup(player)

		if onEventFinished then
			onEventFinished("Finished")
		end
	end)
end

function SpeedBoostEvent.Cleanup(player)
	local boostData = activeBoosts[player]
	if not boostData then
		return
	end

	local humanoid = boostData.Humanoid

	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = boostData.OriginalSpeed
	end

	activeBoosts[player] = nil

	print("[SpeedBoostEvent] Velocidad restaurada para:", player.Name)
end

return SpeedBoostEvent