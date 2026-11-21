local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
    local self = setmetatable({}, CameraController)
    self.Target = Vector3.zero
    self.Position = Vector3.zero
    self.Height = 145
    self.Smoothing = 10
    return self
end

function CameraController:SetTarget(x, z)
    self.Target = Vector3.new(x, 0, z)
end

function CameraController:Step(deltaTime)
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 42

    local alpha = 1 - math.exp(-self.Smoothing * deltaTime)
    self.Position = self.Position:Lerp(self.Target, alpha)

    local cameraPosition = self.Position + Vector3.new(0, self.Height, 0)
    camera.CFrame = CFrame.lookAt(
        cameraPosition,
        self.Position,
        Vector3.new(0, 0, -1)
    )
end

return CameraController