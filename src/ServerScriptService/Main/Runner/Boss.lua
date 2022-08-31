local boss = {}

function boss.TargetExists(runner, range)
   if #workspace.Hunters:GetChildren() > 0 then
      for i, target in ipairs(workspace.Hunters:GetChildren()) do
         local distanceToHunter = (target.HumanoidRootPart.Position - runner.HumanoidRootPart.Position).Magnitude
         if distanceToHunter <= range then
            return true
         end
      end
   end
   return false
end

function boss.TargetsInRange(runner, range)
   local targets = {}
   for i, target in ipairs(workspace.Hunters:GetChildren()) do
      local dist = (target.HumanoidRootPart.Position - runner.HumanoidRootPart.Position).Magnitude
      if dist <= range then
         table.insert(targets, target)
      end
   end
   return targets
end

function boss.Ability(runner, map)
   local target = boss.TargetExists(runner,20)
   if target then
      print("ability")
      target.Config.Stunned.Value = true
      task.wait(10)
   end

   task.wait(.1)

	if runner and runner.Parent then
		boss.Ability(runner, map)
	end
end

function boss.InitBoss(runner, map)
   print("Boss Runner: " .. runner.Name)

   coroutine.wrap(boss.Ability)(runner, map)
end

return boss