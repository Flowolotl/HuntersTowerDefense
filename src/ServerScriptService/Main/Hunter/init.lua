local Rep = game:GetService("ReplicatedStorage")
local PS = game:GetService("PhysicsService")

local events = Rep:WaitForChild("Events")
local animateHunterEvent = events:WaitForChild("AnimateHunter")
local functions = Rep:WaitForChild("Functions")
local requestHunterFunction = functions:WaitForChild("RequestHunter")
local spawnHunterFunction = functions:WaitForChild("SpawnHunter")
local sellHunterFunction = functions:WaitForChild("SellHunter")
local changeHunterFunction = functions:WaitForChild("ChangeHunterMode")

local maxHunters = 10
local hunter = {}

function hunter.FindTarget(newHunter, range, mode)
	local bestTarget = nil
	local bestWaypoint = nil
	local bestDistance = nil
	local bestHealth = nil
	local map = workspace.Map:FindFirstChildOfClass("Folder")
	
	for i, target in ipairs(workspace.Runners:GetChildren()) do
		local distanceToRunner = (target.HumanoidRootPart.Position - newHunter.HumanoidRootPart.Position).Magnitude
		local distanceToWaypoint = (target.HumanoidRootPart.Position - map.Points[target.MovingTo.Value].Position).Magnitude

		if distanceToRunner <= range then
			if mode == "Near" then
				bestTarget = target
				range = distanceToRunner
			elseif mode == "First" then
				if not bestWaypoint or target.MovingTo.Value >= bestWaypoint then
					bestWaypoint = target.MovingTo.Value

					if not bestDistance or distanceToWaypoint < bestDistance then
						bestDistance = distanceToWaypoint
						if target.Humanoid.Health > 0 then
							bestTarget = target
						end
					end
				end
			elseif mode == "Last" then
				if not bestWaypoint or target.MovingTo.Value <= bestWaypoint then
					bestWaypoint = target.MovingTo.Value

					if not bestDistance or distanceToWaypoint > bestDistance then
						bestDistance = distanceToWaypoint
						if target.Humanoid.Health > 0 then
							bestTarget = target
						end
					end
				end
			elseif mode == "Strong" then
				if not bestHealth or target.Humanoid.Health > bestHealth then
					bestHealth = target.Humanoid.Health
					if target.Humanoid.Health > 0 then
						bestTarget = target
					end
				end
			elseif mode == "Weak" then
				if not bestHealth or target.Humanoid.Health < bestHealth then
					bestHealth = target.Humanoid.Health
					if target.Humanoid.Health > 0 then
						bestTarget = target
					end
				end
			end
		end
	end
	return bestTarget
end

function hunter.Ability(hunter, player)
    local config = hunter.Config
    for i, target in ipairs(config.Abilities) do
        local module = require(script:FindFirstChild(target.Value))
        module.Init(hunter, player)
    end
end

function hunter.ResetStunned(hunter)
    task.wait(3)
    print("Resetting")
    hunter.Config.Stunned.Value = false
end

function hunter.Attack(newHunter, player)
	local config = newHunter.Config
    config.Stunned.Changed:Connect(function()
        if config.Stunned.Value then
            print("changed")
            hunter.ResetStunned(newHunter)
        end
    end)
	local target = hunter.FindTarget(newHunter, config.Range.Value, config.TargetMode.Value)
	if target and not config.Stunned.Value then
		local targetCFrame = CFrame.lookAt(newHunter.HumanoidRootPart.Position, target.HumanoidRootPart.Position)
		newHunter.HumanoidRootPart.BodyGyro.CFrame = targetCFrame

		animateHunterEvent:FireAllClients(newHunter, "Attack", target)
		target.Humanoid:TakeDamage(config.Damage.Value)
		if target.Humanoid.Health <= 0 then
			player.Gold.Value += (target.Humanoid.MaxHealth / 10)
			player.Kills.Value += 1
		end
		task.wait(config.Cooldown.Value)
	end

	task.wait(.1)

	if newHunter and newHunter.Parent then
		hunter.Attack(newHunter, player)
	end
end

function hunter.ChangeMode(player, model)
	if model and model:FindFirstChild("Config") then
		local targetMode = model.Config.TargetMode
		local modes = {"First", "Last", "Near", "Strong", "Weak"}
		local modeIndex = table.find(modes, targetMode.Value)
		if modeIndex < #modes then
			targetMode.Value = modes[modeIndex+1]
		else
			targetMode.Value = modes[1]
		end
		return true
	else
		warn("Unable to change hunter mode")
		return false
	end
end
changeHunterFunction.OnServerInvoke = hunter.ChangeMode

function hunter.Sell(player, model)
	if model and model:FindFirstChild("Config") then
		if model.Config.Owner.Value == player.Name then
			player.PlacedHunters.Value -= 1
			player.Gold.Value += model.Config.Price.Value
			model:Destroy()
			return true
		end
	end

	warn("Unable to sell hunter")
	return false
end
sellHunterFunction.OnServerInvoke = hunter.Sell

function hunter.Spawn(player, name, cframe, previous)
	local allowedSpawn = hunter.CheckSpawn(player, name, previous)

	if allowedSpawn then
		local newHunter 
		local oldMode = nil
		if previous then
			oldMode = previous.Config.TargetMode.Value
			previous:Destroy()
			newHunter = Rep.Hunters.Upgrades[name]:Clone()
		else
			newHunter = Rep.Hunters[name]:Clone()
			player.PlacedHunters.Value +=1
		end

		local ownerValue = Instance.new("StringValue")
		ownerValue.Name = "Owner"
		ownerValue.Value = player.Name
		ownerValue.Parent = newHunter.Config

		local targetMode = Instance.new("StringValue")
		targetMode.Name = "TargetMode"
		targetMode.Value = oldMode or "First"
		targetMode.Parent = newHunter.Config

		newHunter.HumanoidRootPart.CFrame = cframe
		newHunter.Parent = workspace.Hunters
		newHunter.HumanoidRootPart:SetNetworkOwner(nil)

		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		bodyGyro.D = 0
		bodyGyro.CFrame = newHunter.HumanoidRootPart.CFrame
		bodyGyro.Parent = newHunter.HumanoidRootPart

		for i, object in ipairs(newHunter:GetDescendants()) do
			if object:IsA("BasePart") then
				PS:SetPartCollisionGroup(object, "Hunter")
			end
		end

		player.Gold.Value -= newHunter.Config.Price.Value

		coroutine.wrap(hunter.Attack)(newHunter, player)

		return newHunter
	else
		warn("Hunter doesn't exist:", name)
		return false
	end
end

spawnHunterFunction.OnServerInvoke = hunter.Spawn

function hunter.CheckSpawn(player, name, previous)
	local hunterExists = Rep.Hunters:FindFirstChild(name, true)

	if hunterExists then
		if hunterExists.Config.Price.Value <= player.Gold.Value then
			if previous or player.PlacedHunters.Value < maxHunters then
				return true
			else
				warn("Player has reached max limit")
			end
		else
			warn("Player cannot afford")
		end
	else
		warn("Hunter does not exist")
	end
end

requestHunterFunction.OnServerInvoke = hunter.CheckSpawn

return hunter
