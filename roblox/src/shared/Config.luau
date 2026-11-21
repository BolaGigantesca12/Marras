local Config = {
    GAME_MODE = "ffa",

    TICK_RATE = 30,
    SNAPSHOT_RATE = 10,
    MAX_CATCH_UP_STEPS = 4,

    ARENA_SIZE = 1200,
    ARENA_WALL_HEIGHT = 36,
    ARENA_WALL_THICKNESS = 16,

    FOOD_TARGET = 90,
    FOOD_SPAWN_PER_STEP = 2,

    MAX_PLAYERS_IN_SNAPSHOT = 20,
    MAX_FOOD_IN_SNAPSHOT = 28,
    VIEW_DISTANCE = 760,

    INPUT_MIN_INTERVAL = 1 / 30,
    INPUT_MAX_AXIS = 1,

    PLAYER_COLOR = Color3.fromRGB(80, 160, 255),
    FOOD_COLORS = {
        Color3.fromRGB(255, 210, 80),
        Color3.fromRGB(255, 145, 70),
        Color3.fromRGB(100, 220, 180),
    },
    TEAM_COLORS = {
        Color3.fromRGB(230, 80, 80),
        Color3.fromRGB(80, 145, 245),
        Color3.fromRGB(100, 205, 120),
        Color3.fromRGB(220, 190, 70),
    },

    REMOTE_FOLDER = "MarrasRemotes",
    INPUT_REMOTE = "PlayerInput",
    SNAPSHOT_REMOTE = "EntitySnapshot",
}

return Config