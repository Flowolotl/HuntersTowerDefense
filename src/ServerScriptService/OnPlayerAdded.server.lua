local Players = game:GetService("Players")
local PS = game:GetService("PhysicsService")

Players.PlayerAdded:Connect(function(player)
	
	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = 25000
	gold.Parent = player
	
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = player
	
	local placedHunters = Instance.new("IntValue")
	placedHunters.Name = "PlacedHunters"
	placedHunters.Value = 0
	placedHunters.Parent = player
	
	player.CharacterAdded:Connect(function(char)
		for i, object in ipairs(char:GetDescendants()) do
			if object:IsA("BasePart") then
				PS:SetPartCollisionGroup(object, "Player")
			end
		end
	end)
end)