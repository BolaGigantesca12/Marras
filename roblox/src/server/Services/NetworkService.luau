local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NetworkService = {}
NetworkService.__index = NetworkService

local function getOrCreate(parent, className, name)
    local object = parent:FindFirstChild(name)
    if object and object.ClassName == className then
        return object
    end
    if object then
        object:Destroy()
    end

    object = Instance.new(className)
    object.Name = name
    object.Parent = parent
    return object
end

function NetworkService.new(config, entityService)
    local self = setmetatable({}, NetworkService)
    self.Config = config
    self.EntityService = entityService
    self.LastInputAt = {}

    local folder = getOrCreate(ReplicatedStorage, "Folder", config.REMOTE_FOLDER)
    self.Remotes = folder
    self.Input = getOrCreate(folder, "RemoteEvent", config.INPUT_REMOTE)
    self.Snapshot = getOrCreate(folder, "RemoteEvent", config.SNAPSHOT_REMOTE)

    self.Input.OnServerEvent:Connect(function(player, packet)
        local now = os.clock()
        local last = self.LastInputAt[player.UserId] or 0
        if now - last < config.INPUT_MIN_INTERVAL then
            return
        end
        self.LastInputAt[player.UserId] = now

        if typeof(packet) ~= "table" then
            return
        end

        entityService:SetInput(player, packet)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.LastInputAt[player.UserId] = nil
    end)

    return self
end

function NetworkService:SendSnapshots()
    for _, player in ipairs(Players:GetPlayers()) do
        local snapshot = self.EntityService:CreateSnapshotFor(player)
        if snapshot then
            self.Snapshot:FireClient(player, snapshot)
        end
    end
end

return NetworkService