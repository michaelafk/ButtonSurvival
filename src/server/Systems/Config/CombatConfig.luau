--[[
    CombatConfig.luau
    Configuración del sistema de combate
    Aquí definimos valores que pueden cambiar facilmente
    sin tocar la lógica del sistema
]]
local CombatConfig = {}

--Daño base del bate
CombatConfig.DEFAULT_DAMAGE = 20
--Cooldown del bate
CombatConfig.HIT_COOLDOWN = 1
--Permitir daño solo durante el evento
CombatConfig.ONLY_DAMAGE_DURING_EVENT = true

return CombatConfig
