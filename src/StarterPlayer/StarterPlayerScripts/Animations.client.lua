local Rep = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Tween = game:GetService("TweenService")
local events = Rep:WaitForChild("Events")
local animateHunterEvent = events:WaitForChild("AnimateHunter")

local function fireProjectile(hunter, target)
	local projectile = hunter.Config.Projectile.Value:Clone()
	projectile:SetPrimaryPartCFrame(hunter.Head.CFrame)
	projectile.Parent = workspace.Camera
	for i, part in pairs(projectile:GetChildren()) do
		if part:IsA("BasePart") then
			-- Position = target.HumanoidRootPart.Position, Orientation = part.Orientation * Vector3.new(0,0,math.rad(180)), 
			local projectileTween = Tween:Create(part, TweenInfo.new(.65), {CFrame = CFrame.new(target:FindFirstChild("Left Leg").Position - Vector3.new(0,.5,0)) * CFrame.Angles(-math.rad(180),0,0)})
			projectileTween:Play()
		end
	end
	--local projectileTween = Tween:Create(projectile, TweenInfo.new(.5), {Position = target.HumanoidRootPart.Position})
	--projectileTween:Play()
	Debris:AddItem(projectile, .5)
end

local function setAnimation(object, animName)
	local humanoid = object:WaitForChild("Humanoid")
	local animationsFolder = object:WaitForChild("Animations")
	
	if humanoid and animationsFolder then
		local animationObject = animationsFolder:WaitForChild(animName)		
		if animationObject then
			local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
			
			local playingTracks = animator:GetPlayingAnimationTracks()
			for i, track in pairs(playingTracks) do
				if track.Name == animName then
					return track
				end
			end
			
			local animationTrack = animator:LoadAnimation(animationObject)
			return animationTrack
		end
	end
end

local function playAnimation(object, animName)
	local animationTrack = setAnimation(object, animName)
	if animationTrack then
		animationTrack:Play()
		animationTrack:AdjustSpeed(1)
	else
		warn("Animation track doesn't exist")
		return
	end
end

workspace.Runners.ChildAdded:Connect(function(object)
	playAnimation(object, "Walk")
end)

workspace.Hunters.ChildAdded:Connect(function(object)
	playAnimation(object, "Idle")
end)

animateHunterEvent.OnClientEvent:Connect(function(hunter, animName, target)
	playAnimation(hunter, animName)
	if target then
		fireProjectile(hunter, target)
	end
end)