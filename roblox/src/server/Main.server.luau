local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MarrasShared")
local Config = require(Shared.Config)
local EntityDefinitions = require(Shared.EntityDefinitions)
local GameModes = require(Shared.GameModes)

local Services = script.Parent:WaitForChild("Services")
local ArenaService = require(Services.ArenaService)
local EntityService = require(Services.EntityService)
local NetworkService = require(Services.NetworkService)
local SimulationService = require(Services.SimulationService)

-- The Roblox platform hosts this server. No Node process, localhost URL,
-- custom HTTP listener, TCP port, or WebSocket server is started here.
Players.CharacterAutoLoads = false

ArenaService.Create(Config)

local entities = EntityService.new(Config, EntityDefinitions, GameModes)
local network = NetworkService.new(Config, entities)
local simulation = SimulationService.new(Config, entities, network)

local function addPlayer(player)
    entities:AddPlayer(player)
    print("[Marras Roblox] Player joined:", player.Name, "mode:", Config.GAME_MODE)
end

local function removePlayer(player)
    entities:RemovePlayer(player)
    print("[Marras Roblox] Player left:", player.Name)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
end

simulation:Start()
print("[Marras Roblox] Server started. Roblox matchmaking and hosting are active.")