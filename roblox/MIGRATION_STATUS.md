# Roblox Porting Status

Last reviewed: 2026-11-21

This file records what has actually been added to \`roblox/\` and what remains. The source branch \`main\` is preserved.

## Source repository inventory

The current \`main\` tree contains 275 tracked files, including:

| Area | Files |
|---|---:|
| Browser client JavaScript | 12 |
| Server entity implementation | 10 |
| Entity-definition JavaScript files | 39 |
| Game-mode configurations | 44 |
| Game-mode scripts | 12 |
| Room definitions | 22 |
| Room tile definitions | 9 |
| Entity addon JavaScript files | 10 |

These numbers are file counts, not counts of individual tanks or features.

## Implemented in the Roblox branch

- Rojo project mapping from filesystem into Roblox services.
- Shared configuration, simple 2D math, a small sample of unit definitions, and initial FFA/TDM/Squads team assignment.
- Roblox-managed server entry point. It starts no Node.js process, HTTP listener, WebSocket listener, localhost address, or manually exposed game port.
- Arena floor and boundary parts.
- Server-owned player state and a fixed-step movement/collection simulation.
- Server validation and rate limiting for movement input.
- Food collection, score, experience, and level progression.
- Per-player state snapshots through Roblox RemoteEvents.
- Client-only top-down camera, simple visual entities, HUD, and leaderboard.

## Not yet ported

- The complete entity-definition and class tree.
- Detailed entity controllers, AI and targeting systems.
- All game-mode rules and their associated scripts.
- The complete room, tile, maze, and map-generation systems.
- Bosses, special entities, extensions, and all addon behavior.
- The full browser UI, editor, recorder, chat, moderation, server selector, and administrative systems.
- The original optimized visibility, delta synchronization, and binary protocol.
- Persistence and cross-server progression.

## Runtime differences

The browser game uses JavaScript, Node.js, HTTP, WebSockets, worker threads, and Canvas. Those runtime-specific systems are not copied into Roblox. Their responsibilities must be redesigned around Roblox services, Luau scripts, RemoteEvents, and the Roblox replication model.

Rojo's local connection is only a Studio development/synchronization workflow. It is not the public multiplayer server. Once the place is published, Roblox hosts the running experience.

## Testing status

The scripts have been written to the repository but have **not** been executed in Roblox Studio in this environment. The next required validation is to sync the project with Rojo, inspect the resulting Explorer hierarchy, and run Studio's server/client play test. Treat this as an initial port foundation rather than a complete or production-ready conversion.

## Scope note

This branch contains movement, arena, collection, progression, and presentation foundations. It does not implement the original combat systems.