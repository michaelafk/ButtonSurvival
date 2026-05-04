local MarketplaceService = game:GetService("MarketplaceService")
--[[
    CombatSystem.luau
    Sistema de control de combate
    Responsabilidades:
    - Aplicar daño a los jugadores(el marcado)
    - Validar que el atacante y el objetivo existen
    - Comprobar que el objetivo esta vivo
]]
local CombatSystem = {}
--Obtencion del Evento
local MarkedEvent = require(script.Parent.Events.MarkedEvent)
--Configuración del combate
local CombatConfig = require(script.Parent.Config.CombatConfig)
--Daño base del bate
local DEFAULT_DAMAGE = CombatConfig.DEFAULT_DAMAGE
--Funciones auxiliares
--Obtiene el Humanoid de un jugador
local function getHumanoidFromPlayer(player)
	if not player then
		return nil
	end
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end
--Comprueba si un jugador está vivo
local function isPlayerAlive(player)
	local humanoid = getHumanoidFromPlayer(player)
	return humanoid and humanoid.Health > 0
end
--Funcion principal de daño
function CombatSystem.ApplyDamage(targetPlayer, damage)
	local markedPlayer = MarkedEvent.GetMarkedPlayer()
	--Comprobar que el objetivo está vivo
	if not isPlayerAlive(targetPlayer) then
		warn("[CombatSystem] El objetivo no está vivo")
		return false
	end
	--Comprobar si hay jugador marcado
	if not markedPlayer then
		warn("[CombatSystem] No hay jugador marcado")
		return false
	end
	if targetPlayer ~= markedPlayer then
		warn("[CombatSystem] Solo se puede dañar al jugador marcado")
	end
	--Obtener humanoid del objetivo
	local targetHumanoid = getHumanoidFromPlayer(targetPlayer)
	if not targetHumanoid then
		warn("[CombatSystem] No se encontró Humanoid en el objetivo")
		return false
	end
	--Usar daño recibido o daño por defecto
	local finalDamage = damage or DEFAULT_DAMAGE
	--Aplicar daño
	targetHumanoid:TakeDamage(finalDamage)
	return true
end

return CombatSystem
