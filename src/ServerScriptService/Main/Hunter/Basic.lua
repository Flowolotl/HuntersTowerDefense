local basic = {}
local Rep = game:GetService("ReplicatedStorage")
local events = Rep:WaitForChild("Events")
local animateHunterEvent = events:WaitForChild("AnimateHunter")

function basic.Ability(hunter, player)
    local config = hunter.Config
    config.Stunned.Changed:Connect(function()
        if config.Stunned.Value then
            print("changed")
            hunter.ResetStunned(hunter)
        end
    end)
	local target = _G.FindTarget(hunter, config.Range.Value, "Runners", config.TargetMode.Value)
	if target and not config.Stunned.Value then
		local targetCFrame = CFrame.lookAt(hunter.HumanoidRootPart.Position, target.HumanoidRootPart.Position)
		hunter.HumanoidRootPart.BodyGyro.CFrame = targetCFrame

		animateHunterEvent:FireAllClients(hunter, "Attack", target)
		target.Humanoid:TakeDamage(config.Damage.Value)
		if target.Humanoid.Health <= 0 then
			player.Gold.Value += (target.Humanoid.MaxHealth / 10)
			player.Kills.Value += 1
		end
		task.wait(config.Abilities.Basic.Value)
	end

	task.wait(.1)

	if hunter and hunter.Parent then
		hunter.Attack(hunter, player)
	end
end

function basic.Init(hunter, player)
    print("Basic ability loaded")

    coroutine.wrap(basic.Ability)(hunter, player)
end

return basic