local Players = game:GetService("Players")

local health = {}

function health.Setup(model, screenGui)
	local newHealthBar = script.HealthGui:Clone()
	newHealthBar.Adornee = model:WaitForChild("Head")
	newHealthBar.Parent = Players.LocalPlayer.PlayerGui:WaitForChild("Billboards")
	
	if model.Name == "Village" then
		newHealthBar.MaxDistance = 55
		newHealthBar.Size = UDim2.new(0,200,0,25)
	else
		newHealthBar.MaxDistance = 25
		newHealthBar.Size = UDim2.new(0,100,0,25)		
	end
	
	health.UpdateHealth(newHealthBar, model)
	if screenGui then
		health.UpdateHealth(screenGui, model)
	end
	
	model.Humanoid.HealthChanged:Connect(function()
		health.UpdateHealth(newHealthBar, model)
		if screenGui then
			health.UpdateHealth(screenGui, model)
		end
	end)
	
	
end

function health.UpdateHealth(gui, model)
	local humanoid = model:WaitForChild("Humanoid")
	if humanoid and gui then
		local percent = humanoid.Health / humanoid.MaxHealth

		gui.CurrentHealth.Size = UDim2.new(math.max(percent,0), 0, 1, 0)

		if humanoid.Health <= 0 then
			if model.Name == "Village" then
				gui.Title.Text = model.Name .. " Destroyed"
			else
				gui.Title.Text = model.Name .. " Died"
				task.wait(0.5)
				gui:Destroy()
			end
			
		else
			gui.Title.Text = model.Name .. " : " .. humanoid.Health .. "/" .. humanoid.MaxHealth
		end
	end
end

return health
