-- Initial non-combat unit definitions for the Roblox port.
-- Weapon, projectile, and damage mechanics are not part of this port.

local EntityDefinitions = {
    Basic = {
        label = "Basic",
        size = 17,
        movementSpeed = 58,
        acceleration = 9,
        color = Color3.fromRGB(80, 160, 255),
        nextClass = "Twin",
    },

    Twin = {
        label = "Twin",
        size = 18,
        movementSpeed = 54,
        acceleration = 9,
        color = Color3.fromRGB(80, 160, 255),
        nextClass = nil,
    },
}

return EntityDefinitions