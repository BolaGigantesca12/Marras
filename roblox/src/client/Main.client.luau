local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("MarrasShared")
local Config = require(shared.Config)
local remotes = ReplicatedStorage:WaitForChild(Config.REMOTE_FOLDER)

local Modules = script.Parent:WaitForChild("Modules")
local InputController = require(Modules.InputController)
local CameraController = require(Modules.CameraController)
local Renderer = require(Modules.Renderer)
local UIController = require(Modules.UIController)

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local input = InputController.new(remotes:WaitForChild(Config.INPUT_REMOTE))
local camera = CameraController.new()
local renderer = Renderer.new()
local ui = UIController.new()

remotes:WaitForChild(Config.SNAPSHOT_REMOTE).OnClientEvent:Connect(function(snapshot)
    if typeof(snapshot) ~= "table" then
        return
    end

    local localState = renderer:Update(snapshot)
    if localState then
        camera:SetTarget(localState.x, localState.z)
    end
    ui:Update(localState, snapshot)
end)

RunService.RenderStepped:Connect(function(deltaTime)
    input:Step(deltaTime)
    renderer:Step(deltaTime)
    camera:Step(deltaTime)
end)

script.Destroying:Connect(function()
    renderer:Destroy()
    ui:Destroy()
end)