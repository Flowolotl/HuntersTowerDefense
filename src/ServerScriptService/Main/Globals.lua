local globals = {}

function globals.Init()
    _G.FindTarget = function(rq, range, tg, mode)
        local bestTarget = nil
	    local bestWaypoint = nil
	    local bestDistance = nil
	    local bestHealth = nil
	    local map = workspace.Map:FindFirstChildOfClass("Folder")
        local type = workspace:FindFirstChild(tg)
	    for i, target in ipairs(type:GetChildren()) do
	    	local distanceToRunner = (target.HumanoidRootPart.Position - rq.HumanoidRootPart.Position).Magnitude
            local distanceToWaypoint
            if tg == "Runners" then
                distanceToWaypoint = (target.HumanoidRootPart.Position - map.Points[target.MovingTo.Value].Position).Magnitude
            end

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
    _G.FindTargetsInRange = function(rq, range, tg)
        local targets = {}
        local type = workspace:FindFirstChild(tg)
        for i, target in ipairs(type:GetChildren()) do
           local dist = (target.HumanoidRootPart.Position - rq.HumanoidRootPart.Position).Magnitude
           if dist <= range then
              table.insert(targets, target)
           end
        end
        return targets
    end
end

return globals