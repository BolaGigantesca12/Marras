local ArenaService = {}

local function makePart(parent, name, size, position, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = false
    part.CanQuery = true
    part.Size = size
    part.Position = position
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function ArenaService.Create(config)
    local existing = workspace:FindFirstChild("MarrasArena")
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "MarrasArena"
    folder.Parent = workspace

    local half = config.ARENA_SIZE / 2
    local wall = config.ARENA_WALL_THICKNESS
    local wallHeight = config.ARENA_WALL_HEIGHT

    makePart(
        folder,
        "Floor",
        Vector3.new(config.ARENA_SIZE, 2, config.ARENA_SIZE),
        Vector3.new(0, -1, 0),
        Color3.fromRGB(225, 225, 225),
        Enum.Material.SmoothPlastic
    )

    local wallColor = Color3.fromRGB(90, 90, 90)
    makePart(folder, "NorthWall", Vector3.new(config.ARENA_SIZE + wall * 2, wallHeight, wall), Vector3.new(0, wallHeight / 2, -half), wallColor)
    makePart(folder, "SouthWall", Vector3.new(config.ARENA_SIZE + wall * 2, wallHeight, wall), Vector3.new(0, wallHeight / 2, half), wallColor)
    makePart(folder, "WestWall", Vector3.new(wall, wallHeight, config.ARENA_SIZE), Vector3.new(-half, wallHeight / 2, 0), wallColor)
    makePart(folder, "EastWall", Vector3.new(wall, wallHeight, config.ARENA_SIZE), Vector3.new(half, wallHeight / 2, 0), wallColor)

    return folder
end

return ArenaService