local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Configs = ReplicatedStorage:WaitForChild("Configs")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GameStates = require(Shared:WaitForChild("GameState"))
local RoundConfig = require(Configs:WaitForChild("RoundConfig"))
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))

local updateTimerEvent = Remotes:WaitForChild(RemoteNames.UpdateTimer)
local gameStateChangedEvent = Remotes:WaitForChild(RemoteNames.GameStateChanged)
local getCurrentState = Remotes:WaitForChild(RemoteNames.GetCurrentState)

local GameStateSystem = {}
GameStateSystem._playerManager = nil
GameStateSystem._roundManager = nil
GameStateSystem.CurrentState = GameStates.Lobby
GameStateSystem.TimeLeft = 0
GameStateSystem.IsRunning = false
GameStateSystem.ForceStartNextRound = false

function GameStateSystem:Init(playerManager, roundManager)
	self._playerManager = playerManager
	self._roundManager = roundManager

	getCurrentState.OnServerInvoke = function()
		return self.CurrentState, self.TimeLeft
	end
end

function GameStateSystem:SetState(newState: string, duration: number, message: string?)
	self.CurrentState = newState
	self.TimeLeft = duration
	gameStateChangedEvent:FireAllClients(newState, duration, message)
	updateTimerEvent:FireAllClients(duration, newState, message)
	print("[GameStateSystem] Estado:", newState, "Tiempo:", duration)
end

function GameStateSystem:RunCountdown(duration: number, stateName: string, messageBuilder)
	for i = duration, 1, -1 do
		self.TimeLeft = i
		local message = messageBuilder and messageBuilder(i) or nil
		updateTimerEvent:FireAllClients(i, stateName, message)
		task.wait(1)
	end
	self.TimeLeft = 0
end

function GameStateSystem:WaitForEnoughPlayers()
	self:SetState(GameStates.Lobby, 0, "Esperando jugadores...")
	while not self._playerManager:HasEnoughPlayers(RoundConfig.MinimumPlayers) and not self.ForceStartNextRound do
		updateTimerEvent:FireAllClients(0, GameStates.Lobby, "Esperando jugadores...")
		task.wait(1)
	end
end

function GameStateSystem:StartRoundNow()
	self.ForceStartNextRound = true
end

function GameStateSystem:Start()
	if self.IsRunning then
		return
	end
	self.IsRunning = true

	task.spawn(function()
		while self.IsRunning do
			self:WaitForEnoughPlayers()
			self.ForceStartNextRound = false

			self:SetState(GameStates.Intermission, RoundConfig.Durations.Intermission)
			self:RunCountdown(RoundConfig.Durations.Intermission, GameStates.Intermission, function(i)
				return "Intermission: " .. i
			end)

			if not self._playerManager:HasEnoughPlayers(RoundConfig.MinimumPlayers) then
				continue
			end

			self:SetState(GameStates.Starting, RoundConfig.Durations.Starting)
			self._roundManager:StartRound()
			self:RunCountdown(RoundConfig.Durations.Starting, GameStates.Starting, function(i)
				return "La ronda empieza en: " .. i
			end)

			self:SetState(GameStates.InGame, RoundConfig.Durations.InGame)
			local endedEarly = false
			for i = RoundConfig.Durations.InGame, 1, -1 do
				self.TimeLeft = i
				updateTimerEvent:FireAllClients(i, GameStates.InGame, "Tiempo restante: " .. i)

				local endReason = self._roundManager:GetEndReason()
				if endReason then
					self._roundManager:FinishRound(endReason)
					endedEarly = true
					break
				end

				task.wait(1)
			end

			if not endedEarly then
				self._roundManager:FinishRound("TimeUp")
			end

			self:SetState(GameStates.Ending, RoundConfig.Durations.Ending)
			self:RunCountdown(RoundConfig.Durations.Ending, GameStates.Ending, function(i)
				return "Volviendo al lobby en: " .. i
			end)
		end
	end)
end

return GameStateSystem
