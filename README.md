# ButtonSurvival

Base de arquitectura Roblox + Rojo con los sistemas principales implementados y preparados para servir como base de documentación de desarrollo.

## Incluye
- Estructura base del proyecto
- Sistema de estado de partida
- Validación de jugadores mínimos
- Sistema de spawn de lobby y ronda
- Sistema de rondas
- Sistema del botón principal
- Base modular de eventos aleatorios con efectos funcionales
- Sistema de eliminación y supervivencia
- Leaderstats
- Guardado de datos
- Inventario/equipamiento base
- Comunicación servidor-cliente validada
- Administración básica
- Los eventos Rain, Explosions, Speed y DisappearFloor tienen implementación jugable real

## Elementos que debes crear en Roblox Studio
- `Workspace/LobbySpawns` con Parts de spawn, o un `LobbySpawn`
- `Workspace/Maps` con mapas opcionales. Cada mapa puede incluir `RoundSpawns` o `SpawnPoints`
- `Workspace/RoundSpawns` o `MapSpawn` como fallback si el mapa no trae sus propios puntos
- `Workspace/MainButton` con `ProximityPrompt` o `ClickDetector` opcional
- `StarterGui/GameUI` con labels opcionales `TimerText`, `StateText`, `StatusText`
- Parts de suelo con nombre `Floor` o atributo `IsEventFloor = true` para el evento de desaparición de suelo

## Convenciones
- Managers: `XManager.luau`
- Systems: `XSystem.luau`
- Services: `XService.luau`
- Client controllers: `XController.client.luau`
- Shared enums/types: `X.luau`
- Configs: `XConfig.luau`
- RemoteEvents: `RE_X`
- RemoteFunctions: `RF_X`
- Modelos de remotos de Rojo: `RE_X.model.json` / `RF_X.model.json`

## Comandos de admin
- `!startround`
- `!endround`
- `!loadmap NombreDelMapa`
- `!forceevent`

## Documentación adicional
Consulta `docs/DEVELOPMENT_DOCUMENTATION.md` para el checklist completo por sistema y `docs/REMOTE_DOCUMENTATION.md` para el detalle de remotos.
