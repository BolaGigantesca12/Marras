-- Initial native Roblox definitions.
-- This is a small migration sample, not the complete Marras class tree.

local EntityDefinitions = {
    Basic = {
        label = "Basic",
        size = 17,
        maxHealth = 100,
        movementSpeed = 58,
        acceleration = 9,
        bulletSpeed = 250,
        bulletDamage = 18,
        bulletSize = 5,
        reload = 0.34,
        barrelLength = 23,
        barrelWidth = 9,
        color = Color3.fromRGB(80, 160, 255),
    },

    -- A second definition is included to establish how classes will be
    -- represented in Luau. The complete upgrade graph is still to be ported.
    Twin = {
        label = "Twin",
        size = 17,
        maxHealth = 100,
        movementSpeed = 54,
        acceleration = 9,
        bulletSpeed = 235,
        bulletDamage = 11,
        bulletSize = 4,
        reload = 0.22,
        barrelLength = 22,
        barrelWidth = 7,
        barrelCount = 2,
        color = Color3.fromRGB(80, 160, 255),
    },
}

return EntityDefinitions