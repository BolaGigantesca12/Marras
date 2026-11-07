const { test } = require("node:test");
const assert = require("node:assert/strict");
const HashGrid = require("../server/lib/hashgrid.js");
const { ioTypes } = require("../server/miscFiles/controllers.js");

function makeEntities(count, offset = 0) {
    let seed = 12345;
    const random = () => ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) / 2 ** 32);
    return Array.from({ length: count }, (_, id) => {
        const x = random() * 4000 - 2000 + offset;
        const y = random() * 4000 - 2000 + offset;
        const size = 5 + random() * 200;
        return { id, minX: x - size, maxX: x + size, minY: y - size, maxY: y + size, bond: id % 17 === 0 };
    });
}

test("500-entity grid matches brute-force overlap queries across ticks", () => {
    const grid = new HashGrid(7);
    for (let tick = 0; tick < 8; tick++) {
        grid.clear();
        const entities = makeEntities(500, tick * 21);
        for (const e of entities) grid.insert(e, e.minX, e.minY, e.maxX, e.maxY);
        for (const box of entities) {
            const expected = entities.filter(e => !e.bond && e.minX < box.maxX && e.maxX > box.minX && e.minY < box.maxY && e.maxY > box.minY);
            assert.deepEqual(new Set(grid.query(box.minX, box.minY, box.maxX, box.maxY)), new Set(expected));
        }
    }
    grid.clear();
    assert.equal(grid.cells.size, 0);
    assert.equal(grid.query(-10000, -10000, 10000, 10000).size, 0);
});

for (const type of ["nearestDifferentMaster", "healTeamMasters"]) {
    test(`${type} checks each eligible candidate's line of sight once`, () => {
        global.ran = { irandom: () => 0 };
        global.util = { getDirection: (_, e) => e.angle, angleDifference: (a, b) => a - b };
        const candidates = Array.from({ length: 500 }, (_, id) => ({ id, dangerValue: id % 5, angle: id % 2 ? Math.PI : 0 }));
        global.targetableEntities = new Map(candidates.map(e => [e.id, e]));
        const body = { aiSettings: { view360: false, farm: false }, firingArc: [0, Math.PI / 2], master: { master: {} } };
        const ai = new ioTypes[type](body);
        ai.validate = e => e.id % 3 !== 0;
        let wallChecks = 0;
        ai.wouldHitWall = e => { wallChecks++; return e.id % 7 === 0; };
        const eligible = candidates.filter(e => e.id % 3 !== 0 && e.angle === 0);
        const clear = eligible.filter(e => e.id % 7 !== 0);
        const danger = Math.max(0, ...clear.map(e => e.dangerValue));
        ai.targetLock = clear.find(e => e.dangerValue === danger);
        const retained = ai.targetLock;
        assert.deepEqual(ai.buildList(1000), clear.filter(e => e.dangerValue === danger));
        assert.equal(wallChecks, eligible.length);
        assert.equal(ai.targetLock, retained);
        body.aiSettings.farm = true;
        assert.deepEqual(ai.buildList(1000), clear);
        ai.validate = () => false;
        assert.deepEqual(ai.buildList(1000), []);
        assert.equal(ai.targetLock, undefined);
    });
}
