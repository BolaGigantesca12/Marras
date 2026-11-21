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
    self.Bullets = {}
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
    entity.position = self:_randomPosition(110)
    entity.velocity = Vector2.zero
    entity.health = entity.maxHealth
    entity.alive = true
    entity.respawnAt = 0
    entity.lastShotAt = 0
    entity.input = {
        move = Vector2.zero,
        aimX = entity.position.X + 1,
        aimY = entity.position.Y,
        fire = false,
    }
end

function EntityService:AddPlayer(player)
    local userId = player.UserId
    if self.Players[userId] then
        return self.Players[userId]
    end

    self.JoinOrder += 1
    local definition = self.Definitions.Basic
    local entity = {
        id = userId,
        userId = userId,
        name = string.sub(player.DisplayName or player.Name, 1, 20),
        className = "Basic",
        team = self.GameModes.GetTeam(self.Config.GAME_MODE, self.JoinOrder),
        position = Vector2.zero,
        velocity = Vector2.zero,
        angle = 0,
        health = definition.maxHealth,
        maxHealth = definition.maxHealth,
        score = 0,
        level = 1,
        xp = 0,
        alive = true,
        respawnAt = 0,
        lastShotAt = 0,
        input = {
            move = Vector2.zero,
            aimX = 1,
            aimY = 0,
            fire = false,
        },
    }

    self:_spawnPlayer(entity)
    self.Players[userId] = entity
    return entity
end

function EntityService:RemovePlayer(player)
    self.Players[player.UserId] = nil

    for index = #self.Bullets, 1, -1 do
        if self.Bullets[index].ownerId == player.UserId then
            table.remove(self.Bullets, index)
        end
    end
end

function EntityService:SetInput(player, packet)
    local entity = self.Players[player.UserId]
    if not entity or not entity.alive or typeof(packet) ~= "table" then
        return
    end

    local moveX = packet.moveX
    local moveY = packet.moveY
    local aimX = packet.aimX
    local aimY = packet.aimY

    if not Math2D.IsFinite(moveX) or not Math2D.IsFinite(moveY)
        or not Math2D.IsFinite(aimX) or not Math2D.IsFinite(aimY) then
        return
    end

    local move = Vector2.new(
        math.clamp(moveX, -self.Config.INPUT_MAX_AXIS, self.Config.INPUT_MAX_AXIS),
        math.clamp(moveY, -self.Config.INPUT_MAX_AXIS, self.Config.INPUT_MAX_AXIS)
    )
    entity.input.move = Math2D.ClampMagnitude(move, 1)
    entity.input.aimX = math.clamp(aimX, -self.Config.ARENA_SIZE, self.Config.ARENA_SIZE)
    entity.input.aimY = math.clamp(aimY, -self.Config.ARENA_SIZE, self.Config.ARENA_SIZE)
    entity.input.fire = packet.fire == true

    local aim = Vector2.new(entity.input.aimX, entity.input.aimY) - entity.position
    if aim.Magnitude > 0.001 then
        entity.angle = math.atan2(aim.Y, aim.X)
    end
end

function EntityService:_addExperience(entity, amount)
    entity.xp += amount
    entity.score += amount

    while entity.xp >= entity.level * 100 and entity.level < 45 do
        entity.xp -= entity.level * 100
        entity.level += 1
        entity.maxHealth += 4
        entity.health = math.min(entity.maxHealth, entity.health + 12)
    end
end

function EntityService:_fire(entity, now)
    local definition = self.Definitions[entity.className] or self.Definitions.Basic
    if now - entity.lastShotAt < definition.reload then
        return
    end

    entity.lastShotAt = now
    local direction = Vector2.new(math.cos(entity.angle), math.sin(entity.angle))
    local spawnPosition = entity.position + direction * (definition.size + definition.barrelLength * 0.7)

    table.insert(self.Bullets, {
        id = self:_nextId(),
        ownerId = entity.userId,
        team = entity.team,
        position = spawnPosition,
        velocity = direction * definition.bulletSpeed,
        damage = definition.bulletDamage,
        size = definition.bulletSize,
        bornAt = now,
        expiresAt = now + 1.8,
    })

    if #self.Bullets > 300 then
        table.remove(self.Bullets, 1)
    end
end

function EntityService:_canDamage(attacker, target)
    if attacker.userId == target.userId then
        return false
    end
    if attacker.team ~= 0 and attacker.team == target.team then
        return false
    end
    return true
end

function EntityService:_hitPlayer(attacker, target, now, damage)
    target.health -= damage
    if target.health > 0 then
        return
    end

    target.health = 0
    target.alive = false
    target.respawnAt = now + 3
    target.velocity = Vector2.zero
    target.input.fire = false

    if attacker and attacker.userId ~= target.userId then
        self:_addExperience(attacker, 100)
    end
end

function EntityService:Step(deltaTime, now)
    -- Replenish food gradually instead of creating the entire map in one frame.
    local missingFood = self.Config.FOOD_TARGET - #self.Foods
    for _ = 1, math.min(missingFood, self.Config.FOOD_SPAWN_PER_STEP) do
        self:_spawnFood()
    end

    local halfArena = self.Config.ARENA_SIZE / 2
    local playerList = {}

    for _, entity in pairs(self.Players) do
        table.insert(playerList, entity)

        if not entity.alive then
            if now >= entity.respawnAt then
                self:_spawnPlayer(entity)
            end
            continue
        end

        local definition = self.Definitions[entity.className] or self.Definitions.Basic
        local desiredVelocity = entity.input.move * definition.movementSpeed
        local blend = math.clamp(deltaTime * definition.acceleration, 0, 1)
        entity.velocity = entity.velocity:Lerp(desiredVelocity, blend)
        entity.position += entity.velocity * deltaTime
        entity.position = Math2D.ClampToArena(entity.position, halfArena, definition.size + 8)

        local aimVector = Vector2.new(entity.input.aimX, entity.input.aimY) - entity.position
        if aimVector.Magnitude > 0.001 then
            entity.angle = math.atan2(aimVector.Y, aimVector.X)
        end

        if entity.input.fire then
            self:_fire(entity, now)
        end

        for foodIndex = #self.Foods, 1, -1 do
            local food = self.Foods[foodIndex]
            if Math2D.CirclesOverlap(entity.position, definition.size, food.position, food.size * 0.7) then
                self:_addExperience(entity, food.value)
                table.remove(self.Foods, foodIndex)
            end
        end
    end

    -- Simple circle separation. Detailed Marras collision types are still to be migrated.
    for firstIndex = 1, #playerList do
        local first = playerList[firstIndex]
        if first.alive then
            local firstRadius = (self.Definitions[first.className] or self.Definitions.Basic).size
            for secondIndex = firstIndex + 1, #playerList do
                local second = playerList[secondIndex]
                if second.alive then
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
    end

    -- Projectile motion and server-side hit detection.
    for bulletIndex = #self.Bullets, 1, -1 do
        local bullet = self.Bullets[bulletIndex]
        bullet.position += bullet.velocity * deltaTime
        local removeBullet = now >= bullet.expiresAt
            or math.abs(bullet.position.X) > halfArena
            or math.abs(bullet.position.Y) > halfArena

        if not removeBullet then
            local attacker = self.Players[bullet.ownerId]
            for _, target in ipairs(playerList) do
                if target.alive and self:_canDamage(attacker or { userId = bullet.ownerId, team = bullet.team }, target) then
                    local targetSize = (self.Definitions[target.className] or self.Definitions.Basic).size
                    if Math2D.CirclesOverlap(bullet.position, bullet.size, target.position, targetSize) then
                        self:_hitPlayer(attacker, target, now, bullet.damage)
                        removeBullet = true
                        break
                    end
                end
            end
        end

        if removeBullet then
            table.remove(self.Bullets, bulletIndex)
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
        bullets = {},
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
            entity.health,
            entity.maxHealth,
            entity.team,
            entity.score,
            entity.level,
            entity.name,
            entity.alive,
        })
    end

    -- Always include the receiving player's own state first. Otherwise a
    -- busy server could fill the player cap before reaching this player,
    -- leaving their client without a camera target or HUD state.
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

    for _, bullet in ipairs(self.Bullets) do
        if #snapshot.bullets >= self.Config.MAX_BULLETS_IN_SNAPSHOT then
            break
        end
        if (bullet.position - viewer.position).Magnitude ^ 2 <= viewDistanceSquared then
            table.insert(snapshot.bullets, {
                bullet.id,
                bullet.position.X,
                bullet.position.Y,
                bullet.team,
            })
        end
    end

    return snapshot
end

return EntityService