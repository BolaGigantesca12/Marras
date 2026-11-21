local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local InputController = {}
InputController.__index = InputController

function InputController.new(remote)
    local self = setmetatable({}, InputController)
    self.Remote = remote
    self.Keys = {}
    self.FireHeld = false
    self.Elapsed = 0
    self.SendInterval = 1 / 15
    self.Player = Players.LocalPlayer

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.Keys[input.KeyCode] = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.FireHeld = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.Keys[input.KeyCode] = nil
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.FireHeld = false
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

function InputController:_mouseWorldPosition()
    local camera = workspace.CurrentCamera
    if not camera then
        return 1, 0
    end

    local mousePosition = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    if math.abs(ray.Direction.Y) < 0.0001 then
        return 1, 0
    end

    local distance = -ray.Origin.Y / ray.Direction.Y
    if distance < 0 then
        return 1, 0
    end

    local hit = ray.Origin + ray.Direction * distance
    return hit.X, hit.Z
end

function InputController:Step(deltaTime)
    self.Elapsed += deltaTime
    if self.Elapsed < self.SendInterval then
        return
    end
    self.Elapsed %= self.SendInterval

    local movement = self:_movement()
    local aimX, aimY = self:_mouseWorldPosition()

    self.Remote:FireServer({
        moveX = movement.X,
        moveY = movement.Y,
        aimX = aimX,
        aimY = aimY,
        fire = self.FireHeld,
    })
end

return InputController