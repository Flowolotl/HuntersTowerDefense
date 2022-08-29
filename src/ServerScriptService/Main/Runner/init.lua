local SS = game:GetService("ServerStorage")
local PS = game:GetService("PhysicsService")

local runner = {}

function runner.Move(runner, map)
	local humanoid = runner:WaitForChild("Humanoid")
		local waypoints = map.Points

	for waypoint=1, #waypoints:GetChildren() do
		runner.MovingTo.Value = waypoint
		humanoid:MoveTo(waypoints[waypoint].Position)
		humanoid.MoveToFinished:Wait()
	end

	runner:Destroy()

	map.Map.Village.Humanoid:TakeDamage(humanoid.MaxHealth / 10)
end

function runner.Spawn(name, quantity, map)
	local runnerExists = SS.Runners:FindFirstChild(name)

	if runnerExists then
		for i=1, quantity do
			task.wait(0.5)
			local newRunner = runnerExists:Clone()
			newRunner.HumanoidRootPart.CFrame = map.Start.CFrame
			newRunner.Parent = workspace.Runners
			newRunner.HumanoidRootPart:SetNetworkOwner(nil)

			local movingTo = Instance.new("IntValue")
			movingTo.Name = "MovingTo"
			movingTo.Parent = newRunner

			for i, object in ipairs(newRunner:GetDescendants()) do
				if object:IsA("BasePart") then
					PS:SetPartCollisionGroup(object, "Runner")
				end
			end

			newRunner.Humanoid.Died:Connect(function()
				task.wait(0.1)
				newRunner:Destroy()
			end)

            if newRunner.Config.Boss.Value then
                require(script.Boss).InitBoss(newRunner, map)
            end
			coroutine.wrap(runner.Move)(newRunner, map)
		end

	else
		warn("Mob doesn't exist: ", name)
	end
end

return runner
