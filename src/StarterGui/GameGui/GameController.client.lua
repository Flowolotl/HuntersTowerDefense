local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local PS = game:GetService("PhysicsService")
local Input = game:GetService("UserInputService")
local Rep = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local modules = Rep:WaitForChild("Modules")
local health = require(modules:WaitForChild("Health"))

local gold = Players.LocalPlayer:WaitForChild("Gold")
local functions = Rep:WaitForChild("Functions")
local requestHunterFunction = functions:WaitForChild("RequestHunter")
local hunters = Rep:WaitForChild("Hunters")
local spawnHunterFunction = functions:WaitForChild("SpawnHunter")
local sellHunterFunction = functions:WaitForChild("SellHunter")
local changeModeFunction = functions:WaitForChild("ChangeHunterMode")

local camera = workspace.CurrentCamera
local gui = script.Parent

local info = workspace:WaitForChild("Info")

local hoveredInstance = nil
local selectedHunter = nil
local hunterToSpawn = nil
local canPlace = false
local rotation = 0
local placedTowers = 0
local maxTowers = 10
local lastTouch = tick()

local function MouseRaycast(model)
	local mousePos = Input:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local rayParams = RaycastParams.new()
	
	local blacklist = camera:GetChildren()
	table.insert(blacklist, model)
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = blacklist
	local rayResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, rayParams)
	return rayResult
end

local function CreateRangeCircle(hunter, placeholder)
	local range = hunter.Config.Range.Value
	local height = (hunter.PrimaryPart.Size.Y / 2) + hunter:FindFirstChild("Left Leg").Size.Y
	local offset = CFrame.new(0, -height, 0)

	local p = Instance.new("Part")
	p.Name = "Range"
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Neon
	p.Transparency = .9
	p.Size = Vector3.new(2, range * 2, range * 2)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = hunter.PrimaryPart.CFrame * offset * CFrame.Angles(0,0,math.rad(90))
	p.CanCollide = false

	if placeholder then
		p.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = hunter.PrimaryPart
		weld.Parent = p
		p.Parent = hunter
	else
		p.Anchored = true
		p.Parent = workspace.Camera
	end
end

local function RemovePlaceholderHunter()
	if hunterToSpawn then
		hunterToSpawn:Destroy()
		hunterToSpawn = nil
		rotation = 0
		gui.Controls.Visible = true
	end
end

local function AddPlaceholderHunter(name)
	local hunterExists = hunters:FindFirstChild(name)
	if hunterExists then
		RemovePlaceholderHunter()
		hunterToSpawn = hunterExists:Clone()
		hunterToSpawn.Parent = workspace

		CreateRangeCircle(hunterToSpawn, true)

		for i, object in ipairs(hunterToSpawn:GetDescendants()) do
			if object:IsA("BasePart") then
				PS:SetPartCollisionGroup(object, "Runner")
				if object.Name ~= "Range" then
					object.Material = Enum.Material.ForceField
				end
			end
		end
		
		gui.Controls.Visible = true
	end
end

local function ColorPlaceholderHunter(color)
	for i, object in ipairs(hunterToSpawn:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Color = color
		end
	end
end

local function toggleHunterInfo()
	workspace.Camera:ClearAllChildren()
	gui.Hunters.Title.Text = "Hunters: " .. placedTowers .. "/" .. maxTowers

	if selectedHunter then
		CreateRangeCircle(selectedHunter)
		gui.Selection.Visible = true
		local config = selectedHunter.Config
		gui.Selection.Stats.Damage.Value.Text = config.Damage.Value
		gui.Selection.Stats.Range.Value.Text = config.Range.Value
		gui.Selection.Stats.Cooldown.Value.Text = config.Cooldown.Value
		gui.Selection.Title.HunterName.Text = selectedHunter.Name
		gui.Selection.Title.HunterIcon.Image = config.Icon.Texture
		gui.Selection.Title.OwnerName.Text = config.Owner.Value .. "'s"
		gui.Selection.Action.Target.Title.Text = "Target: " .. config.TargetMode.Value

		if config.Owner.Value == Players.LocalPlayer.Name then
			gui.Selection.Action.Visible = true

			local upgradeHunter = config:FindFirstChild("Upgrade")
			if upgradeHunter then
				gui.Selection.Action.Upgrade.Visible = true
				gui.Selection.Action.Upgrade.Title.Text = "Upgrade (" .. upgradeHunter.Value.Config.Price.Value .. ")"
			else
				gui.Selection.Action.Upgrade.Visible = false
			end
		else
			gui.Selection.Action.Visible = false
		end
	else
		gui.Selection.Visible = false
	end
end

local function SpawnNewTower()
	if canPlace then
		local placedHunter = spawnHunterFunction:InvokeServer(hunterToSpawn.Name, hunterToSpawn.PrimaryPart.CFrame)
		if placedHunter then
			placedTowers += 1
			gui.Hunters.Title.Text = "Hunters: " .. placedTowers .. "/" .. maxTowers
			RemovePlaceholderHunter()
			toggleHunterInfo()
		end
	end
end

gui.Controls.Cancel.Activated:Connect(RemovePlaceholderHunter)

gui.Selection.Action.Target.Activated:Connect(function()
	if selectedHunter then
		local modeChange = changeModeFunction:InvokeServer(selectedHunter)
		if modeChange then
			toggleHunterInfo()
		end
	end
end)

gui.Selection.Action.Upgrade.Activated:Connect(function()
	if selectedHunter then
		local upgradeHunter = selectedHunter.Config.Upgrade.Value
		local allowedToUpgrade = spawnHunterFunction:InvokeServer(upgradeHunter.Name, selectedHunter.PrimaryPart.CFrame, selectedHunter)
		if allowedToUpgrade then
			selectedHunter = allowedToUpgrade
			toggleHunterInfo()	
		end
	end
end)

gui.Selection.Action.Sell.Activated:Connect(function()
	if selectedHunter then
		local soldHunter = sellHunterFunction:InvokeServer(selectedHunter)
		if soldHunter then
			selectedHunter = nil
			placedTowers -= 1
			toggleHunterInfo()
		end
	end
end)

Input.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if hunterToSpawn then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			SpawnNewTower()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local timeSinceLastTouch = tick() - lastTouch
			if timeSinceLastTouch <= .25 then
				SpawnNewTower()
			end
			lastTouch = tick()
		elseif input.KeyCode == Enum.KeyCode.R then
			rotation += 90
		elseif input.KeyCode == Enum.KeyCode.X then
			RemovePlaceholderHunter()
		end
	elseif hoveredInstance and input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local model = hoveredInstance:FindFirstAncestorOfClass("Model")
		if model and model.Parent == workspace.Hunters then
			selectedHunter = model
		else
			selectedHunter = nil
		end

		toggleHunterInfo()
	end
end)

RS.RenderStepped:Connect(function()
	local result = MouseRaycast(hunterToSpawn)
	if result and result.Instance then
		if hunterToSpawn then
			hoveredInstance = nil
			if result.Instance.Parent.Name == "HunterArea" then
				ColorPlaceholderHunter(Color3.new(0,1,0))
				canPlace = true
			else
				ColorPlaceholderHunter(Color3.new(1,0,0))
				canPlace = false
			end
			local x = result.Position.X
			local y = result.Position.Y + .526 + (hunterToSpawn.PrimaryPart.Size.Y / 2)
			local z = result.Position.Z
			local cframe = CFrame.new(x,y,z) * CFrame.Angles(0, math.rad(rotation), 0)
			hunterToSpawn:SetPrimaryPartCFrame(cframe)
		else
			hoveredInstance = result.Instance

		end
	else
		hoveredInstance = nil
	end
end)

local function DisplayEndScreen(status)
	local screen = gui.EndScreen
	
	if status == "GAME OVER" then
		screen.Content.Title.TextColor3 = Color3.new(1,0,0)
		screen.Content.Subtitle.Text = "get good lol"
	elseif status == "VICTORY" then
		screen.Content.Title.TextColor3 = Color3.new(0,1,0)
		screen.Content.Subtitle.Text = "maybe try a harder difficulty"
	end
	
	screen.Content.Title.Text = status
	screen.Stats.Wave.Text = "Wave: " .. workspace.Info.Wave.Value
	screen.Stats.Gold.Text = "Gold: " .. Players.LocalPlayer.Gold.Value
	screen.Stats.Kills.Text = "Kills: " ..Players.LocalPlayer.Kills.Value
	
	screen.Size = UDim2.new(0,0,0,0)
	screen.Visible = true
	
	local tweenStyle = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
	local zoomTween = TS:Create(screen, tweenStyle, {Size = UDim2.new(1,0,1,0)})
	zoomTween:Play()
	
	local events = Rep:WaitForChild("Events")
	local exitEvent = events:WaitForChild("ExitGame")
	screen.Exit.Activated:Connect(function()
		screen.Visible = false
		exitEvent:FireServer()
	end)
end

local function SetupGameGui()
	if not info.GameRunning.Value then
		return
	end
	gui.Voting.Visible = false
	gui.Info.Health.Visible = true
	gui.Info.Stats.Visible = true
	gui.Hunters.Visible = true
	
	local map = workspace.Map:FindFirstChildOfClass("Folder")
	if map then
		health.Setup(map.Map:WaitForChild("Village"), gui.Info.Health)
	else
		workspace.Map.ChildAdded:Connect(function(newMap)
			health.Setup(newMap.Map:WaitForChild("Village"), gui.Info.Health)
		end)
	end

	workspace.Runners.ChildAdded:Connect(function(runner)
		health.Setup(runner)
	end)

	

	info.Wave.Changed:Connect(function(change)
		gui.Info.Stats.Wave.Text = "Wave: " .. change
	end)

	gold.Changed:Connect(function(changed)
		gui.Hunters.Gold.Text = "$" .. gold.Value
	end)
	gui.Hunters.Gold.Text = "$" .. gold.Value

	gui.Hunters.Title.Text = "Hunters: " .. placedTowers .. "/" .. maxTowers
	for i, hunter in pairs(hunters:GetChildren()) do
		if hunter:IsA("Model") then
			local button = gui.Hunters.Template:Clone()
			local config = hunter:WaitForChild("Config")
			button.Name = hunter.Name
			button.Image = config.Icon.Texture
			button.Visible = true
			button.LayoutOrder = config.Price.Value
			button.Price.Text = config.Price.Value

			button.Parent = gui.Hunters

			button.Activated:Connect(function()
				local allowedSpawn = requestHunterFunction:InvokeServer(hunter.Name)
				if allowedSpawn then
					AddPlaceholderHunter(hunter.Name)
				end
			end)
		end
	end
end

local function SetupVoteGui()
	if not info.Voting.Value then
		return
	end
	gui.Voting.Visible = true
	
	local events = Rep:WaitForChild("Events")
	local voteEvent = events:WaitForChild("VoteForMap")
	local voteCountUpdate = events:WaitForChild("UpdateVoteCount")
	local maps = gui.Voting.Maps:GetChildren()
	
	for i, button in ipairs(maps) do
		if button:IsA("ImageButton") then
			button.Activated:Connect(function()
				voteEvent:FireServer(button.Name)
			end)
		end
	end
	
	voteCountUpdate.OnClientEvent:Connect(function(mapScores)
		for name, voteInfo in pairs(mapScores) do
			local button = gui.Voting.Maps:FindFirstChild(name)
			if button then
				button.Vote.Text = #voteInfo
			end
		end
	end)
end

local function LoadGui()
	gui.Info.Message.Text = info.Message.Value
	info.Message.Changed:Connect(function(change)
		gui.Info.Message.Text = change
		if change == "" then
			gui.Info.Message.Visible = false
		else
			gui.Info.Message.Visible = true

			if change == "VICTORY" or change == "GAME OVER" then
				DisplayEndScreen(change)
			end
		end
	end)
	
	SetupVoteGui()
	SetupGameGui()
	info.GameRunning.Changed:Connect(SetupGameGui)
	info.Voting.Changed:Connect(SetupVoteGui)
end
	
LoadGui()