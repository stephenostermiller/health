#!/usr/bin/env node

// Test data point calculation logic
const assert = require('assert');
const DataUtils = require('../htdocs/static/data-utils.js');

console.log('Testing data point calculations and validation...\n');

// Test 1: calculateDataPoints - year granularity
console.log('Test 1: calculateDataPoints - year granularity');
const y1 = DataUtils.calculateDataPoints('year', '2020-01-01', '2020-01-01');
assert.strictEqual(y1, 1, 'Single year should be 1 point');
const y2 = DataUtils.calculateDataPoints('year', '2020-01-01', '2025-12-31');
assert.strictEqual(y2, 6, '2020-2025 should be 6 points');
console.log('  ✓ Year granularity calculations correct\n');

// Test 2: calculateDataPoints - month granularity
console.log('Test 2: calculateDataPoints - month granularity');
const m1 = DataUtils.calculateDataPoints('month', '2020-01-01', '2020-01-01');
assert.strictEqual(m1, 1, 'Single month should be 1 point');
const m2 = DataUtils.calculateDataPoints('month', '2020-01-15', '2020-12-15');
assert.strictEqual(m2, 12, '12 months should be 12 points');
const m3 = DataUtils.calculateDataPoints('month', '2020-01-15', '2022-03-15');
assert.strictEqual(m3, 27, '27 months should be 27 points');
console.log('  ✓ Month granularity calculations correct\n');

// Test 3: calculateDataPoints - week granularity
console.log('Test 3: calculateDataPoints - week granularity');
const w1 = DataUtils.calculateDataPoints('week', '2026-06-18', '2026-09-12');
assert.strictEqual(w1, 13, '3-month range should be ~13 weeks');
assert(w1 <= 800, 'Should be under limit');
const w2 = DataUtils.calculateDataPoints('week', '2026-06-18', '2050-01-01');
assert(w2 > 800, 'Large range should exceed 800 points');
assert.strictEqual(w2, 1229, 'Should be ~1229 weeks for 24-year range');
console.log('  ✓ Week granularity calculations correct\n');

// Test 4: calculateDataPoints - day granularity
console.log('Test 4: calculateDataPoints - day granularity');
const d1 = DataUtils.calculateDataPoints('day', '2026-06-18', '2026-06-18');
assert.strictEqual(d1, 1, 'Single day should be 1 point');
const d2 = DataUtils.calculateDataPoints('day', '2026-06-18', '2026-09-12');
assert.strictEqual(d2, 87, '3-month range should be 87 days');
const d3 = DataUtils.calculateDataPoints('day', '2026-06-18', '2050-01-01');
assert(d3 > 800, 'Large range should exceed 800 points');
console.log('  ✓ Day granularity calculations correct\n');

// Test 5: validateSpan - accepts valid ranges
console.log('Test 5: validateSpan - accepts valid ranges');
assert.strictEqual(DataUtils.validateSpan('week', '2026-06-18', '2026-09-12'), null, 'Valid week range should not error');
assert.strictEqual(DataUtils.validateSpan('month', '2020-01-15', '2022-03-15'), null, 'Valid month range should not error');
assert.strictEqual(DataUtils.validateSpan('year', '2020-01-01', '2050-12-31'), null, 'Valid year range should not error');
console.log('  ✓ Valid ranges pass validation\n');

// Test 6: validateSpan - rejects ranges exceeding limit
console.log('Test 6: validateSpan - rejects ranges exceeding limit');
const err1 = DataUtils.validateSpan('week', '2026-06-18', '2050-01-01');
assert(err1 !== null, 'Large week range should error');
assert(err1.includes('1229'), 'Error should mention actual point count');
assert(err1.includes('800'), 'Error should mention limit');
const err2 = DataUtils.validateSpan('day', '2026-06-18', '2050-01-01');
assert(err2 !== null, 'Large day range should error');
console.log('  ✓ Ranges exceeding limit are rejected\n');

// Test 7: validateSpan - respects auto granularity
console.log('Test 7: validateSpan - respects auto granularity');
assert.strictEqual(DataUtils.validateSpan('auto', '2020-01-01', '2050-12-31'), null, 'Auto granularity should always pass');
console.log('  ✓ Auto granularity bypass works\n');

// Test 8: validateSpan - validates date order
console.log('Test 8: validateSpan - validates date order');
const err3 = DataUtils.validateSpan('week', '2026-09-12', '2026-06-18');
assert(err3 !== null, 'Reversed dates should error');
assert(err3.includes('must be on or before'), 'Should have proper error message');
console.log('  ✓ Date order validation works\n');

// Test 9: validateSpan - handles empty dates
console.log('Test 9: validateSpan - handles empty dates');
assert.strictEqual(DataUtils.validateSpan('week', '', '2026-09-12'), null, 'Empty start should return null');
assert.strictEqual(DataUtils.validateSpan('week', '2026-06-18', ''), null, 'Empty end should return null');
console.log('  ✓ Empty date handling works\n');

// Test 10: validateSpan - respects custom limit
console.log('Test 10: validateSpan - respects custom limit');
const err4 = DataUtils.validateSpan('week', '2026-06-18', '2026-09-12', 5);
assert(err4 !== null, 'Should error if points exceed custom limit');
assert(err4.includes('5'), 'Error should mention custom limit');
console.log('  ✓ Custom limit respected\n');

console.log('✅ All data point calculation tests passed!');
