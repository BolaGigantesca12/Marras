local Players = game:GetService("Players")

local UIController = {}
UIController.__index = UIController

local function makeLabel(parent, name, size, position, text, textSize, align)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
    label.BackgroundTransparency = 0.2
    label.BorderSizePixel = 0
    label.TextColor3 = Color3.fromRGB(245, 245, 245)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = textSize
    label.TextXAlignment = align or Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Text = text
    label.Parent = parent
    return label
end

function UIController.new()
    local self = setmetatable({}, UIController)
    local gui = Instance.new("ScreenGui")
    gui.Name = "MarrasHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    self.Gui = gui
    self.Stats = makeLabel(
        gui,
        "Stats",
        UDim2.fromOffset(300, 82),
        UDim2.fromOffset(18, 18),
        "Connecting to Marras...",
        17
    )
    self.Help = makeLabel(
        gui,
        "Help",
        UDim2.fromOffset(360, 34),
        UDim2.new(0.5, -180, 1, -48),
        "WASD / arrow keys: move   |   Collect shapes to level up",
        13,
        Enum.TextXAlignment.Center
    )
    self.Leaderboard = makeLabel(
        gui,
        "Leaderboard",
        UDim2.fromOffset(220, 210),
        UDim2.new(1, -238, 0, 18),
        "LEADERBOARD",
        14
    )
    self.Leaderboard.TextYAlignment = Enum.TextYAlignment.Top
    return self
end

function UIController:Update(localState, snapshot)
    if not localState then
        self.Stats.Text = "Connecting to the arena..."
    else
        local selfStatus = localState.alive and "ACTIVE" or "WAITING"
        self.Stats.Text = string.format(
            "MARRAS  |  %s\nLEVEL %d     SCORE %d\n%s",
            localState.name,
            localState.level,
            localState.score,
            selfStatus
        )
    end

    local rows = {}
    for _, data in ipairs((snapshot and snapshot.players) or {}) do
        table.insert(rows, {
            name = data[8],
            score = data[6],
        })
    end
    table.sort(rows, function(a, b)
        return a.score > b.score
    end)

    local lines = {"LEADERBOARD"}
    for index = 1, math.min(8, #rows) do
        table.insert(lines, string.format("%d. %s  %d", index, rows[index].name, rows[index].score))
    end
    self.Leaderboard.Text = table.concat(lines, "\n")
end

function UIController:Destroy()
    self.Gui:Destroy()
end

return UIController