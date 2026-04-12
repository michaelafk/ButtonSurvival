# Remote documentation

## Convención
- `RE_` = `RemoteEvent` unidireccional del servidor al cliente.
- `RF_` = `RemoteFunction` con respuesta sincrónica y validación en servidor.

## Remotos implementados

### RE_UpdateTimer
Servidor -> Cliente.
Envía tiempo restante, nombre de estado y mensaje opcional para la UI.

### RE_GameStateChanged
Servidor -> Cliente.
Notifica un cambio global de estado de partida.

### RE_RoundStarted
Servidor -> Cliente.
Notifica el inicio de la ronda y el nombre del mapa actual.

### RE_RoundEnded
Servidor -> Cliente.
Notifica el fin de ronda, motivo de cierre y lista de ganadores.

### RE_PlayerEliminated
Servidor -> Cliente.
Informa qué jugador fue eliminado.

### RE_ButtonPressed
Servidor -> Cliente.
Informa qué jugador activó el botón principal y qué evento disparó.

### RE_EventStarted
Servidor -> Cliente.
Informa el nombre del evento, duración e intensidad.

### RE_EventEnded
Servidor -> Cliente.
Informa que el evento activo ya terminó.

### RF_GetCurrentState
Cliente -> Servidor.
Devuelve `CurrentState` y `TimeLeft`.
No acepta parámetros del cliente, así que no permite alterar estados.

### RF_RequestEquipItem
Cliente -> Servidor.
Recibe un `itemName` y solo equipa si:
- el parámetro es string
- el ítem existe en `InventoryConfig`
- el jugador ya posee el ítem
- el ítem es equipable

## Reglas de seguridad
- El cliente no puede cambiar estados de partida.
- El cliente no puede forzar eventos.
- El cliente no puede modificar kills o victorias.
- El cliente no puede terminar o iniciar rondas por remoto.
- Toda lógica crítica vive en `ServerScriptService`.
