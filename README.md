# ButtonSurvival

Base de arquitectura Roblox + Rojo con los sistemas implementados por código.

## Incluye
- Estructura base del proyecto
- Sistema de estado de partida
- Validación de jugadores mínimos
- Sistema de spawn de lobby y ronda
- Sistema de rondas
- Sistema del botón principal
- Base modular de eventos aleatorios
- Sistema de eliminación y supervivencia
- Leaderstats
- Guardado de datos
- Inventario/equipamiento base
- Comunicación servidor-cliente
- Administración básica

## Elementos que debes crear en Roblox Studio
- `Workspace/LobbySpawns` con Parts de spawn, o un `LobbySpawn`
- `Workspace/RoundSpawns` con Parts de spawn, o un `MapSpawn`
- `Workspace/Maps` con mapas opcionales
- `Workspace/MainButton` con `ProximityPrompt` o `ClickDetector` opcional
- `StarterGui/GameUI` con labels opcionales `TimerText`, `StateText`, `StatusText`

## Convenciones
- Managers: `XManager.luau`
- Systems: `XSystem.luau`
- Services: `XService.luau`
- Client controllers: `XController.client.luau`
- RemoteEvents: `RE_X`
- RemoteFunctions: `RF_X`
