local Math2D = {}

function Math2D.IsFinite(value)
    return typeof(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

function Math2D.ClampMagnitude(vector, maximum)
    local magnitude = vector.Magnitude
    if magnitude > maximum and magnitude > 0 then
        return vector.Unit * maximum
    end
    return vector
end

function Math2D.ClampToArena(position, halfSize, margin)
    local limit = math.max(0, halfSize - (margin or 0))
    return Vector2.new(
        math.clamp(position.X, -limit, limit),
        math.clamp(position.Y, -limit, limit)
    )
end

function Math2D.CirclesOverlap(aPosition, aRadius, bPosition, bRadius)
    local radius = aRadius + bRadius
    return (aPosition - bPosition).Magnitude <= radius
end

function Math2D.NormalizeOrZero(vector)
    if vector.Magnitude < 0.0001 then
        return Vector2.zero
    end
    return vector.Unit
end

return Math2D