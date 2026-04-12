# Development documentation checklist

## 1. Estructura base del proyecto
Cumplido.
- `ServerScriptService/Managers`
- `ServerScriptService/Systems`
- `ServerScriptService/Services`
- `ServerScriptService/Modules`
- `ReplicatedStorage/Remotes`
- `ReplicatedStorage/Shared`
- `ReplicatedStorage/Configs`
- Convenciones de nombres definidas en `README.md`

## 2. Sistema de estado de partida
Cumplido.
Estados:
- Lobby
- Intermission
- Starting
- InGame
- Ending

Duraciones configurables en `RoundConfig`.
Cambio automático desde `GameStateSystem`.
Estado visible para cliente mediante `RF_GetCurrentState` y eventos de UI.

## 3. Sistema de jugadores
Cumplido.
`PlayerManager:HasEnoughPlayers` valida el mínimo requerido para arrancar ronda.

## 4. Sistema de spawn
Cumplido.
- Spawn al entrar en lobby
- Spawn al reaparecer según contexto de ronda
- Spawn de ronda al comenzar partida
- Retorno al lobby al terminar ronda o al quedar eliminado
- Separación entre lobby y ronda
- Soporte para spawns por mapa y fallback global

## 5. Sistema de rondas
Cumplido.
- Inicio automático cuando se cumplen condiciones
- Selección aleatoria de mapa o mapa forzado por admin
- Teletransporte de participantes
- Gestión de vivos/eliminados
- Final de ronda por último vivo, todos muertos o tiempo agotado
- Retorno al lobby al finalizar

## 6. Sistema del botón principal
Cumplido.
- Detecta `ProximityPrompt` o `ClickDetector`
- Tiene lock para evitar activaciones simultáneas no deseadas
- Ejecuta evento aleatorio asociado
- Registra último activador

## 7. Sistema de eventos aleatorios
Cumplido.
Base modular en `ServerScriptService/Systems/Events`.
Eventos incluidos:
- lluvia de objetos
- explosiones
- aumento de velocidad
- desaparición de suelo

Cada evento define como mínimo:
- `Name`
- `Duration`
- `Intensity`
- `Start(context)`
- `Stop(context)`

## 8. Sistema de eliminación y supervivencia
Cumplido.
- Detección de muerte con `Humanoid.Died`
- Marcado como eliminado
- Expulsión del flujo activo de ronda
- Supervivientes detectados al cierre
- Lista de ganadores generada y enviada al cliente

## 9. Sistema de leaderstats
Cumplido.
- `Victorias`
- `Kills`
- Sincronizados con `DataManager`
- Actualización al ganar o conseguir kills

## 10. Sistema de guardado de datos
Cumplido.
`DataManager` guarda:
- `Wins`
- `Kills`

Se guarda al salir y en `BindToClose`.

## 11. Sistema de inventario/equipamiento
Cumplido.
- Inventario base por jugador
- Validación de objetos válidos
- Equipamiento seguro por `RF_RequestEquipItem`

## 12. Comunicación servidor-cliente
Cumplido.
- Remotos creados y documentados en `docs/REMOTE_DOCUMENTATION.md`
- Validación del inventario al recibir datos del cliente
- Sin remotos inseguros para estados, eventos o estadísticas

## 13. Administración/moderación básica
Cumplido.
Comandos:
- iniciar ronda
- terminar ronda
- cargar mapa
- forzar evento

Restringidos a `AdminConfig.UserIds`.
