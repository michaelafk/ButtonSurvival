--Aqui guardamos la configuración basica del ciclo del juego--
local GameConfig = {}
--Configuracion general del ciclo de juego
GameConfig.INTERMISSION_TIME = 10
GameConfig.MATCH_DURATION = 30
GameConfig.MIN_PLAYERS = 2
GameConfig.ENDING_TIME = 5
--Estados del juego
GameConfig.GameStates = {
	Waiting = "Waiting",
	Intermission = "Intermission",
	Match = "Match",
	Ending = "Ending",
}
--Mensajes de UI
GameConfig.UI = {
	WaitingMessage = "Esperando jugadores...",
	IntermissionMessage = "Empieza en",
	MatchMessage = "Tiempo restante",
	EndingMessage = "Fin de ronda",
}
return GameConfig
