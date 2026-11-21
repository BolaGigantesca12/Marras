# Source-to-Roblox Migration Map

This map records the intended destination of the original Marras subsystems. A mapping entry is not evidence that the source feature has already been converted.

| Original Marras source | Roblox destination | Status |
|---|---|---|
| \`server/server.js\` | Roblox-managed experience lifecycle | Replaced for the Roblox runtime |
| \`server/game.js\` | \`src/server/Main.server.luau\` and services | Initial replacement |
| \`server/config.js\` | \`src/shared/Config.luau\` | Small initial subset |
| \`server/game/index.js\` | \`src/server/Services/SimulationService.luau\` + \`EntityService.luau\` | Movement/collection foundation only |
| \`server/game/entities/vector.js\` | \`src/shared/Math2D.luau\` | Partial helper subset |
| \`server/game/entities/entity.js\` | \`src/server/Services/EntityService.luau\` | Basic player/food records only |
| \`server/game/entities/skills.js\` | Future progression/skill service | Not ported |
| \`server/game/entities/gun.js\` | No Roblox equivalent in this port | Not migrated |
| \`server/game/entities/bulletEntity.js\` | No Roblox equivalent in this port | Not migrated |
| \`server/game/network/sockets.js\` | \`src/server/Services/NetworkService.luau\` | Basic movement and snapshots |
| \`public/client/protocol.js\` | Roblox RemoteEvents | Replaced; compact delta protocol not ported |
| \`public/client/socketinit.js\` | \`src/client/Main.client.luau\` + renderer | Initial synchronization subset |
| \`public/client/canvas.js\` | \`src/client/Modules/InputController.luau\` | Keyboard movement only |
| \`public/client/gameDraw.js\` | \`src/client/Modules/Renderer.luau\` | Basic local visual entities |
| Browser menu and HTML/CSS | Roblox ScreenGui | Basic HUD only |
| \`server/game/gamemodes/config/\` | \`src/shared/GameModes.luau\` | FFA/TDM/Squads team assignment only |
| \`server/game/gamemodes/scripts/\` | Future game-mode services | Not ported |
| \`server/game/roomSetup/rooms/\` | \`src/server/Services/ArenaService.luau\` | Rectangular starter arena only |
| \`server/game/roomSetup/tiles/\` | Future map/tile generator | Not ported |
| \`server/lib/definitions/groups/\` | \`src/shared/EntityDefinitions.luau\` | Basic/Twin sample only |
| \`server/lib/definitions/entityAddons/\` | Future addon modules | Not ported |
| \`server/game/addons/\` | Future server-side services | Not ported |
| \`server/game/debug/\` | Roblox server diagnostics | Not ported |
| HTTP APIs and server list | Roblox matchmaking/TeleportService if multiple places are needed | Not ported |

## Migration rules

1. Keep authoritative player progression and movement decisions on the server.
2. Keep transient visuals and camera behavior on the client.
3. Do not create one server-replicated Part for every moving visual entity; send state and render local-only visuals where appropriate.
4. Use RemoteEvents for actions and state changes that must arrive reliably. Consider UnreliableRemoteEvents only after snapshots are compacted, bounded, and measured against the documented payload limit.
5. Replace filesystem loaders and CommonJS imports with explicit ModuleScript dependencies.
6. Port each original subsystem as a behaviorally tested Luau module instead of mechanically translating syntax.

## Validation checklist

- [ ] Rojo sync into a test place.
- [ ] Inspect Script, LocalScript, and ModuleScript placement in Explorer.
- [ ] Test solo server and at least two clients using Studio's server/client test mode.
- [ ] Verify that clients cannot set their own position or score.
- [ ] Verify that player snapshots always include the receiving player.
- [ ] Profile server simulation and network traffic with increasing player/entity counts.
- [ ] Publish a private test build and confirm Roblox-hosted joining works.
