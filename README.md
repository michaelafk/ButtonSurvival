## Estado del proyecto
Actualmente el proyecto cuenta con:
- Sistema de ciclo de juego completo (Lobby → Intermission → Match → Ending)
- Sincronización cliente-servidor mediante `RemoteEvents` y `RemoteFunctions`
- Interfaz dinámica con actualización en tiempo real
- Arquitectura preparada para escalar mediante nuevas funcionalidades modulares

## Sistemas implementados
- Estructura base del proyecto con Rojo
- Sistema de estados de partida (Game State)
- Validación de jugadores mínimos
- Sistema de spawn (Lobby y ronda)
- Sistema de rondas básico
- Sistema del botón principal
- Base modular para eventos aleatorios
- Sistema de eliminación y supervivencia
- Leaderstats
- Persistencia de datos (DataStore)
- Inventario / equipamiento base
- Comunicación servidor-cliente validada
- Sistema de administración básico

## Eventos implementados
- 🌧️ Rain  
- 💥 Explosions  
- ⚡ Speed  
- 🧱 DisappearFloor
Todos los eventos tienen implementación jugable funcional.

##  Organización de código
- **Managers** → `XManager.luau`  
- **Systems** → `XSystem.luau`  
- **Services** → `XService.luau`  
- **Client Controllers** → `XController.client.luau`  
- **Shared enums/types** → `X.luau`  
- **Configs** → `XConfig.luau`  

## Flujo de desarrollo
El proyecto sigue un flujo basado en ramas *feature*:
## Reglas
- Cada funcionalidad se desarrolla en una rama independiente:
  - `feature/game-cycle`
  - `feature/game-cycle-refactor`
  - `feature/event-button`
  - etc.
- Las ramas se integran en `develop` mediante merge controlado

## Rama experimental
Esta es una rama de carácter **experimental/prototipo** que contiene múltiples sistemas avanzados implementados de forma conjunta.
## !!IMPORTANTE¡¡
Esta rama:
- NO forma parte del flujo principal de desarrollo  
- NO debe integrarse directamente en `develop`  
- NO sigue la filosofía de una feature por rama  
## Uso correcto
Se utiliza para:
- Analizar implementaciones avanzadas  
- Extraer fragmentos de código reutilizables  
- Inspirar futuras funcionalidades
