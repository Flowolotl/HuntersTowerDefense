local Rep = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local TS = game:GetService("TeleportService")

local SafeTeleport = require(SS.SafeTeleport)

local events = Rep:WaitForChild("Events")
local exitEvent = events:WaitForChild("ExitGame")

local function Teleport(player)
	local placeId = 10726663672
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({
		["Gold"] = player.Gold.Value
	})
	SafeTeleport(placeId, {player}, options)
	print("teleporting")
	print(player)
end

exitEvent.OnServerEvent:Connect(Teleport)