# Marras Roblox Port

This folder is a Roblox/Luau reimplementation track for Marras. It is intentionally separate from the existing browser/Node.js game so the original project remains intact.

## Hosting: no localhost game server

A published Roblox experience runs on Roblox-managed servers. The Roblox version does **not** start the Node.js HTTP server, open port 3000, use WebSockets, or ask players to connect to a manually hosted address. Roblox creates and manages multiplayer server instances and connects players to them.

The only local development step is syncing this source tree into Roblox Studio. Rojo's local sync connection is a development tool, not the game's public server or player networking.

## Requirements

- Roblox Studio.
- Rojo 7.x and the Rojo Studio plugin.
- A Roblox experience/place where you have permission to publish.

## Open in Studio

1. Open the repository folder in a terminal.
2. Run \`rojo serve roblox/default.project.json\`.
3. Open the target place in Roblox Studio.
4. Connect the Rojo Studio plugin to the local Rojo session.
5. Confirm that the \`MarrasShared\`, \`MarrasServer\`, and client scripts appear in Explorer.
6. Press **Play** to test with one local client. Use Studio's **Server & Clients** test mode to test multiplayer.
7. Publish the place through Studio when you are ready to run it on Roblox's hosted servers.

Rojo is only used while developing. After publishing, players join through Roblox as usual.

## Current port status

This is the first playable foundation, not a claim that all 275 files in the web project have already been translated. It currently includes:

- A Roblox-native server entry point and a fixed 30 Hz authoritative simulation loop.
- Roblox RemoteEvents for validated input and an UnreliableRemoteEvent for transient state snapshots.
- A top-down arena, camera, local visuals, basic tank movement, aiming, firing, projectile collision, food collection, score, and level progression.
- Basic FFA, TDM, and four-team assignment foundations.

Still to port from the web codebase:

- The complete tank/class tree and all upgrade branches.
- All controllers, drones, turrets, traps, special projectiles, and their detailed behavior.
- All 44 game-mode configurations and their mode-specific scripts.
- Every room/tile layout, boss, food variant, addon, editor feature, chat/moderation feature, and admin tool.
- The original advanced collision, targeting, AI, visibility, and network-delta systems.

The web implementation uses JavaScript, Node.js, HTTP, WebSockets, worker threads, and Canvas. Those runtime pieces are not reusable inside Roblox. Their gameplay responsibilities must be reimplemented in Luau and Roblox services. The Roblox branch therefore keeps the old source untouched and adds a native Roblox project alongside it.

## Architecture

- \`src/shared\`: constants, tank definitions, and game-mode rules shared by client and server.
- \`src/server\`: authoritative game state, arena creation, entity simulation, and Roblox networking.
- \`src/client\`: input, top-down camera, local entity rendering, and HUD.

The server stores entities as Luau tables and sends compact snapshots. It does not create one replicated physical Part for every bullet or food item. The client creates local-only visuals from snapshots. This avoids using Roblox's general-purpose physics replication for every Arras entity.

## Security and networking notes

The server validates input types, numeric values, movement magnitude, and input rate. Clients do not decide their own health, score, position, damage, or upgrade results.

The snapshot event is unreliable because old visual snapshots are disposable. Important player actions and game-state changes should use reliable RemoteEvents in later migration steps. Snapshot payloads are intentionally capped and filtered to nearby entities; this is a starter transport, not yet a replacement for Marras's optimized visibility/delta protocol.

## Important limitation

This foundation has not been run inside Roblox Studio in this environment. It must be tested in Studio before publishing. Do not treat the current port as feature-equivalent to the web game yet.