local UserInputService = game:GetService("UserInputService")

local InputController = {}
InputController.__index = InputController

function InputController.new(remote)
    local self = setmetatable({}, InputController)
    self.Remote = remote
    self.Keys = {}
    self.Elapsed = 0
    self.SendInterval = 1 / 15

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.Keys[input.KeyCode] = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.Keys[input.KeyCode] = nil
        end
    end)

    return self
end

function InputController:_movement()
    local x = 0
    local y = 0

    if self.Keys[Enum.KeyCode.A] or self.Keys[Enum.KeyCode.Left] then x -= 1 end
    if self.Keys[Enum.KeyCode.D] or self.Keys[Enum.KeyCode.Right] then x += 1 end
    if self.Keys[Enum.KeyCode.W] or self.Keys[Enum.KeyCode.Up] then y -= 1 end
    if self.Keys[Enum.KeyCode.S] or self.Keys[Enum.KeyCode.Down] then y += 1 end

    local movement = Vector2.new(x, y)
    if movement.Magnitude > 1 then
        movement = movement.Unit
    end
    return movement
end

function InputController:Step(deltaTime)
    self.Elapsed += deltaTime
    if self.Elapsed < self.SendInterval then
        return
    end
    self.Elapsed %= self.SendInterval

    local movement = self:_movement()
    self.Remote:FireServer({
        moveX = movement.X,
        moveY = movement.Y,
    })
end

return InputController