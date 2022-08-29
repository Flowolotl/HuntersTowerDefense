-- Services
local inputService = game:GetService("UserInputService")
local playerService = game:GetService("Players")

-- Objects
local plr = playerService.LocalPlayer
local char = plr.Character or plr.CharacterAdded:wait()
local settingsDir = script.Settings

function getSetting (name)
	return settingsDir and settingsDir:FindFirstChild(name) and settingsDir[name].Value
end

local normalSpeed = getSetting("Walking speed") or 18 -- The player's walking speed (Roblox default is 16)
local sprintSpeed = getSetting("Running speed") or 26 -- The player's speed while sprinting
local sprinting = false

inputService.InputBegan:Connect(function (key)
	if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
		running = true
		if char:FindFirstChild("Humanoid") then	
			char.Humanoid.WalkSpeed = sprintSpeed
		end
	end
end)

inputService.InputEnded:Connect(function (key)
	if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
		running = false
		if char:FindFirstChild("Humanoid") then	
			char.Humanoid.WalkSpeed = normalSpeed
		end
	end
end)