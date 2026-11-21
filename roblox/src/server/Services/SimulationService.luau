local RunService = game:GetService("RunService")

local SimulationService = {}
SimulationService.__index = SimulationService

function SimulationService.new(config, entityService, networkService)
    local self = setmetatable({}, SimulationService)
    self.Config = config
    self.EntityService = entityService
    self.NetworkService = networkService
    self.Accumulator = 0
    self.SnapshotAccumulator = 0
    self.Connection = nil
    return self
end

function SimulationService:Start()
    if self.Connection then
        return
    end

    local step = 1 / self.Config.TICK_RATE
    local snapshotInterval = 1 / self.Config.SNAPSHOT_RATE

    self.Connection = RunService.Heartbeat:Connect(function(frameDelta)
        -- Avoid a huge catch-up spike after a pause or server stall.
        self.Accumulator += math.min(frameDelta, 0.25)

        local steps = 0
        while self.Accumulator >= step and steps < self.Config.MAX_CATCH_UP_STEPS do
            self.EntityService:Step(step, os.clock())
            self.Accumulator -= step
            steps += 1
        end

        if steps >= self.Config.MAX_CATCH_UP_STEPS then
            self.Accumulator = math.min(self.Accumulator, step)
        end

        self.SnapshotAccumulator += frameDelta
        if self.SnapshotAccumulator >= snapshotInterval then
            self.SnapshotAccumulator %= snapshotInterval
            self.NetworkService:SendSnapshots()
        end
    end)
end

function SimulationService:Stop()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

return SimulationService