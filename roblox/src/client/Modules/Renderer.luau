local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("MarrasShared").Config)

local Renderer = {}
Renderer.__index = Renderer

local function newPart(parent, name, shape, size, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = shape
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function Renderer.new()
    local self = setmetatable({}, Renderer)
    self.Player = Players.LocalPlayer
    self.Folder = Instance.new("Folder")
    self.Folder.Name = "MarrasLocalVisuals"
    self.Folder.Parent = workspace
    self.PlayerVisuals = {}
    self.FoodVisuals = {}
    self.BulletVisuals = {}
    self.LocalState = nil
    return self
end

function Renderer:_playerVisual(id)
    local visual = self.PlayerVisuals[id]
    if visual then
        return visual
    end

    local body = newPart(
        self.Folder,
        "Tank_" .. tostring(id),
        Enum.PartType.Cylinder,
        Vector3.new(3, 34, 34),
        Config.PLAYER_COLOR
    )
    local barrel = newPart(
        self.Folder,
        "Barrel_" .. tostring(id),
        Enum.PartType.Block,
        Vector3.new(9, 4, 25),
        Color3.fromRGB(75, 75, 75)
    )

    visual = { body = body, barrel = barrel }
    self.PlayerVisuals[id] = visual
    return visual
end

function Renderer:_foodVisual(id, size, colorIndex, kind)
    local visual = self.FoodVisuals[id]
    if visual then
        return visual
    end

    local shape = kind == "Square" and Enum.PartType.Block or Enum.PartType.Ball
    local color = Config.FOOD_COLORS[colorIndex] or Config.FOOD_COLORS[1]
    visual = newPart(
        self.Folder,
        "Food_" .. tostring(id),
        shape,
        Vector3.new(size, 3, size),
        color
    )
    self.FoodVisuals[id] = visual
    return visual
end

function Renderer:_bulletVisual(id)
    local visual = self.BulletVisuals[id]
    if visual then
        return visual
    end

    visual = newPart(
        self.Folder,
        "Bullet_" .. tostring(id),
        Enum.PartType.Ball,
        Vector3.new(8, 5, 8),
        Color3.fromRGB(75, 75, 75)
    )
    self.BulletVisuals[id] = visual
    return visual
end

local function removeMissing(visuals, seen)
    for id, visual in pairs(visuals) do
        if not seen[id] then
            if typeof(visual) == "table" then
                for _, part in pairs(visual) do
                    part:Destroy()
                end
            else
                visual:Destroy()
            end
            visuals[id] = nil
        end
    end
end

function Renderer:Update(snapshot)
    local seenPlayers = {}
    local seenFood = {}
    local seenBullets = {}
    self.LocalState = nil

    for _, data in ipairs(snapshot.players or {}) do
        local id, x, z, angle, health, maxHealth, team, score, level, name, alive = table.unpack(data)
        seenPlayers[id] = true

        local visual = self:_playerVisual(id)
        local position = Vector3.new(x, 2, z)
        local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local target = position + direction

        visual.body.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
        visual.body.Transparency = alive and 0 or 0.75
        visual.barrel.Transparency = alive and 0 or 0.75
        visual.body.Color = team > 0 and (Config.TEAM_COLORS[team] or Config.PLAYER_COLOR) or Config.PLAYER_COLOR
        visual.barrel.CFrame = CFrame.lookAt(
            position + direction * 11 + Vector3.new(0, 1, 0),
            target + direction * 18 + Vector3.new(0, 1, 0)
        )

        if id == self.Player.UserId then
            self.LocalState = {
                x = x,
                z = z,
                health = health,
                maxHealth = maxHealth,
                score = score,
                level = level,
                name = name,
                alive = alive,
                team = team,
            }
        end
    end

    for _, data in ipairs(snapshot.foods or {}) do
        local id, x, z, size, colorIndex, kind = table.unpack(data)
        seenFood[id] = true
        local visual = self:_foodVisual(id, size, colorIndex, kind)
        visual.Position = Vector3.new(x, 1.5, z)
    end

    for _, data in ipairs(snapshot.bullets or {}) do
        local id, x, z, team = table.unpack(data)
        seenBullets[id] = true
        local visual = self:_bulletVisual(id)
        visual.Position = Vector3.new(x, 3, z)
        visual.Color = team > 0 and (Config.TEAM_COLORS[team] or Config.PLAYER_COLOR) or Color3.fromRGB(75, 75, 75)
    end

    removeMissing(self.PlayerVisuals, seenPlayers)
    removeMissing(self.FoodVisuals, seenFood)
    removeMissing(self.BulletVisuals, seenBullets)

    return self.LocalState
end

function Renderer:GetLocalState()
    return self.LocalState
end

function Renderer:Destroy()
    self.Folder:Destroy()
    table.clear(self.PlayerVisuals)
    table.clear(self.FoodVisuals)
    table.clear(self.BulletVisuals)
end

return Renderer