local Config = require(script.Parent.Config)

local GameModes = {
    ffa = {
        label = "Free For All",
        teamCount = 0,
    },
    tdm = {
        label = "Team Deathmatch",
        teamCount = 2,
    },
    squads = {
        label = "Squads",
        teamCount = 4,
    },
}

function GameModes.Get(modeName)
    return GameModes[string.lower(modeName or "ffa")] or GameModes.ffa
end

function GameModes.GetTeam(modeName, joinOrder)
    local mode = GameModes.Get(modeName)
    if mode.teamCount <= 0 then
        return 0
    end

    return ((joinOrder - 1) % mode.teamCount) + 1
end

function GameModes.GetTeamColor(team)
    if team <= 0 then
        return Config.PLAYER_COLOR
    end

    return Config.TEAM_COLORS[team] or Config.PLAYER_COLOR
end

return GameModes