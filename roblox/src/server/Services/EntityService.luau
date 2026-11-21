local Math2D = require(game:GetService("ReplicatedStorage"):WaitForChild("MarrasShared").Math2D)

local EntityService = {}
EntityService.__index = EntityService

function EntityService.new(config, definitions, gameModes)
    local self = setmetatable({}, EntityService)
    self.Config = config
    self.Definitions = definitions
    self.GameModes = gameModes
    self.Players = {}
    self.Foods = {}
    self.NextId = 0
    self.JoinOrder = 0
    self.Random = Random.new()
    return self
end

function EntityService:_nextId()
    self.NextId += 1
    return self.NextId
end

function EntityService:_randomPosition(margin)
    local half = self.Config.ARENA_SIZE / 2 - (margin or 70)
    return Vector2.new(
        self.Random:NextNumber(-half, half),
        self.Random:NextNumber(-half, half)
    )
end

function EntityService:_spawnFood()
    local kindRoll = self.Random:NextInteger(1, 3)
    local kind = ({"Egg", "Square", "Triangle"})[kindRoll]
    local size = kind == "Square" and 14 or (kind == "Triangle" and 12 or 10)

    table.insert(self.Foods, {
        id = self:_nextId(),
        position = self:_randomPosition(45),
        size = size,
        kind = kind,
        value = kind == "Square" and 30 or (kind == "Triangle" and 15 or 5),
        colorIndex = kindRoll,
    })
end

function EntityService:_spawnPlayer(entity)
    local definition = self.Definitions[entity.className] or self.Definitions.Basic
    entity.position = self:_randomPosition(110)
    entity.velocity = Vector2.zero
    entity.alive = true
    entity.input = Vector2.zero
    entity.angle = 0
    entity.respawnAt = 0
end

function EntityService:AddPlayer(player)
    local userId = player.UserId
    if self.Players[userId] then
        return self.Players[userId]
    end

    self.JoinOrder += 1
    local entity = {
        id = userId,
        userId = userId,
        name = string.sub(player.DisplayName or player.Name, 1, 20),
        className = "Basic",
        team = self.GameModes.GetTeam(self.Config.GAME_MODE, self.JoinOrder),
        position = Vector2.zero,
        velocity = Vector2.zero,
        angle = 0,
        score = 0,
        level = 1,
        xp = 0,
        alive = true,
        respawnAt = 0,
        input = Vector2.zero,
    }

    self:_spawnPlayer(entity)
    self.Players[userId] = entity
    return entity
end

function EntityService:RemovePlayer(player)
    self.Players[player.UserId] = nil
end

function EntityService:SetInput(player, packet)
    local entity = self.Players[player.UserId]
    if not entity or not entity.alive or typeof(packet) ~= "table" then
        return
    end

    local moveX = packet.moveX
    local moveY = packet.moveY
    if not Math2D.IsFinite(moveX) or not Math2D.IsFinite(moveY) then
        return
    end

    local movement = Vector2.new(
        math.clamp(moveX, -self.Config.INPUT_MAX_AXIS, self.Config.INPUT_MAX_AXIS),
        math.clamp(moveY, -self.Config.INPUT_MAX_AXIS, self.Config.INPUT_MAX_AXIS)
    )
    entity.input = Math2D.ClampMagnitude(movement, 1)
end

function EntityService:_addExperience(entity, amount)
    entity.xp += amount
    entity.score += amount

    while entity.xp >= entity.level * 100 and entity.level < 45 do
        entity.xp -= entity.level * 100
        entity.level += 1
    end

    if entity.level >= 15 and entity.className == "Basic" then
        entity.classReadyForUpgrade = true
    end
end

function EntityService:Step(deltaTime, now)
    local missingFood = self.Config.FOOD_TARGET - #self.Foods
    for _ = 1, math.min(missingFood, self.Config.FOOD_SPAWN_PER_STEP) do
        self:_spawnFood()
    end

    local halfArena = self.Config.ARENA_SIZE / 2
    local playerList = {}

    for _, entity in pairs(self.Players) do
        table.insert(playerList, entity)

        local definition = self.Definitions[entity.className] or self.Definitions.Basic
        local desiredVelocity = entity.input * definition.movementSpeed
        local blend = math.clamp(deltaTime * definition.acceleration, 0, 1)
        entity.velocity = entity.velocity:Lerp(desiredVelocity, blend)
        entity.position += entity.velocity * deltaTime
        entity.position = Math2D.ClampToArena(entity.position, halfArena, definition.size + 8)

        if entity.velocity.Magnitude > 0.1 then
            entity.angle = math.atan2(entity.velocity.Y, entity.velocity.X)
        end

        for foodIndex = #self.Foods, 1, -1 do
            local food = self.Foods[foodIndex]
            if Math2D.CirclesOverlap(entity.position, definition.size, food.position, food.size * 0.7) then
                self:_addExperience(entity, food.value)
                table.remove(self.Foods, foodIndex)
            end
        end
    end

    -- Non-combat body separation prevents player units from occupying the same spot.
    for firstIndex = 1, #playerList do
        local first = playerList[firstIndex]
        local firstRadius = (self.Definitions[first.className] or self.Definitions.Basic).size
        for secondIndex = firstIndex + 1, #playerList do
            local second = playerList[secondIndex]
            local secondRadius = (self.Definitions[second.className] or self.Definitions.Basic).size
            local offset = second.position - first.position
            local distance = offset.Magnitude
            local required = firstRadius + secondRadius
            if distance > 0 and distance < required then
                local push = offset.Unit * ((required - distance) * 0.5)
                first.position -= push
                second.position += push
            end
        end
    end
end

function EntityService:CreateSnapshotFor(player)
    local viewer = self.Players[player.UserId]
    if not viewer then
        return nil
    end

    local viewDistanceSquared = self.Config.VIEW_DISTANCE ^ 2
    local snapshot = {
        serverTime = workspace:GetServerTimeNow(),
        players = {},
        foods = {},
    }

    local function appendPlayer(entity)
        if #snapshot.players >= self.Config.MAX_PLAYERS_IN_SNAPSHOT then
            return
        end

        table.insert(snapshot.players, {
            entity.userId,
            entity.position.X,
            entity.position.Y,
            entity.angle,
            entity.team,
            entity.score,
            entity.level,
            entity.name,
            entity.alive,
        })
    end

    -- Always include the receiving player's state so their camera and HUD
    -- remain initialized even when the nearby-player list is at its cap.
    appendPlayer(viewer)

    for _, entity in pairs(self.Players) do
        if entity.userId ~= viewer.userId
            and (entity.position - viewer.position).Magnitude ^ 2 <= viewDistanceSquared then
            appendPlayer(entity)
        end
    end

    for _, food in ipairs(self.Foods) do
        if #snapshot.foods >= self.Config.MAX_FOOD_IN_SNAPSHOT then
            break
        end
        if (food.position - viewer.position).Magnitude ^ 2 <= viewDistanceSquared then
            table.insert(snapshot.foods, {
                food.id,
                food.position.X,
                food.position.Y,
                food.size,
                food.colorIndex,
                food.kind,
            })
        end
    end

    return snapshot
end

return EntityService