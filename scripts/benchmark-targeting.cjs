// Deterministic AI scan workload; this is not a full game/server FPS benchmark.
const { performance } = require("node:perf_hooks");
const { ioTypes } = require("../server/miscFiles/controllers.js");
global.ran = { irandom: () => 0 };
global.util = {
    getDirection: (a, b) => Math.atan2(b.y - a.y, b.x - a.x),
    angleDifference: (a, b) => a - b,
    getDistance: (a, b) => Math.hypot(a.x - b.x, a.y - b.y),
    getDistanceSquared: (a, b) => (a.x - b.x) ** 2 + (a.y - b.y) ** 2
};
let seed = 12345;
const random = () => ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) / 2 ** 32);
global.walls = Array.from({ length: 60 }, () => ({
    x: random() * 4000 - 2000, y: random() * 4000 - 2000,
    hitboxRadius: Math.SQRT2 * 25,
    hitbox: [
        [{ x: -25, y: -25 }, { x: 25, y: -25 }],
        [{ x: 25, y: -25 }, { x: 25, y: 25 }],
        [{ x: 25, y: 25 }, { x: -25, y: 25 }],
        [{ x: -25, y: 25 }, { x: -25, y: -25 }]
    ]
}));
global.targetableEntities = new Map(Array.from({ length: 500 }, (_, id) => [id, {
    id, x: random() * 4000 - 2000, y: random() * 4000 - 2000, dangerValue: id % 5
}]));
const ai = new ioTypes.nearestDifferentMaster({
    x: 0, y: 0, aiSettings: { view360: false },
    firingArc: [0, Math.PI / 2], master: { master: {} }
});
// Isolate candidate selection and real wall intersection tests from entity setup.
ai.validate = () => true;
function measure() {
    const start = performance.now();
    for (let i = 0; i < 500; i++) ai.buildList(3000);
    return performance.now() - start;
}
measure(); // Warm up the JIT.
const samples = Array.from({ length: 7 }, measure).sort((a, b) => a - b);
console.log(`500 candidates, 60 walls: median ${(samples[3] / 500).toFixed(3)} ms per AI scan (7 samples of 500 scans).`);
