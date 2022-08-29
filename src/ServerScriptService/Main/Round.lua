local SS = game:GetService("ServerStorage")
local Rep = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
print("rojo test")

local events = Rep:WaitForChild("Events")

local runner = require(script.Parent.Runner)
local info = workspace.Info
local round = {}
local votes = {}

function round.StartGame()
	local map = round.LoadMap()
	info.GameRunning.Value = true
	for i=3, 0, -1 do
		info.Message.Value = "Game starting in..." .. i
		task.wait(1)
	end

	for wave=10, 10 do
		info.Wave.Value = wave
		info.Message.Value = ""

		round.GetWave(wave, map)

		repeat
			task.wait(1)
		until #workspace.Runners:GetChildren() == 0 or not info.GameRunning.Value

		if info.GameRunning.Value and wave == 10 then
			info.Message.Value = "VICTORY"
		elseif info.GameRunning.Value then
			local reward = 75 * wave
			for i, player in ipairs(Players:GetPlayers()) do
				player.Gold.Value += reward
			end
			info.Message.Value = "Wave cleared, +$" .. reward
			task.wait(2)
			for i=3, 0, -1 do
				info.Message.Value = "Next wave starting in..." .. i
				task.wait(1)
			end

		else
			break
		end
	end

end

function round.LoadMap()
	local votedMap = round.ToggleVoting()
	local mapFolder = SS.Maps:FindFirstChild(votedMap)
	if not mapFolder then
		mapFolder = SS.Maps.HiddenGrass
	end
	
	local newMap = mapFolder:Clone()
	newMap.Parent = workspace.Map
	
	workspace.SpawnBox.Floor.CanCollide = false
	
	newMap.Map.Village.Humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			info.GameRunning.Value = true
			info.Message.Value = "GAME OVER"
		end
	end)
	
	return newMap
end

function round.ToggleVoting()
	local maps = SS.Maps:GetChildren()
	votes = {}
	for i, map in ipairs(maps) do
		votes[map.Name] = {}
	end
	
	info.Voting.Value = true
	
	for i=10, 1, -1 do
		info.Message.Value = "Map voting (" .. i .. "s)"
		task.wait(1)
	end
	
	local winVote = nil
	local winScore = 0
	for name, map in pairs(votes) do
		if #map > winScore then
			winScore = #map
			winVote = name
		end
	end
	
	info.Voting.Value = false
	
	return winVote
end

function round.ProcessVote(player, vote)
	
	for name, mapVote in pairs(votes) do
		local oldVote = table.find(mapVote, player.UserId)
		if oldVote then
			table.remove(mapVote, oldVote)
			break
		end
	end
	
	table.insert(votes[vote], player.UserId)
	
	events:WaitForChild("UpdateVoteCount"):FireAllClients(votes)
end
events:WaitForChild("VoteForMap").OnServerEvent:Connect(round.ProcessVote)

function round.GetWave(wave, map)
	runner.Spawn("Zombie", 2, map)
	runner.Spawn("FastZombie", 2, map)
	runner.Spawn("SlowZombie", 2, map)
end

return round
