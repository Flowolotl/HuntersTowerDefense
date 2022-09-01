local Players = game:GetService("Players")

local runner = require(script.Runner)
local hunter = require(script.Hunter)
local round = require(script.Round)
local globals = require(script.Globals)
globals.Init()

local minPlayers = 1

Players.PlayerAdded:Connect(function(player)
	local currentPlayers = #Players:GetPlayers()
	if currentPlayers >= minPlayers then
		round.StartGame()
	else
		workspace.Info.Message.Value = "Waiting for " .. (minPlayers - currentPlayers) .. " more player(s)"
	end
end)

--round.StartGame()