#!/usr/bin/env node

// Test URL hash encoding/decoding for the health dashboard
// This demonstrates the URLSearchParams API used for hash state management

const assert = require('assert');

// Test 1: Encode preset period to hash
console.log('Test 1: Encode preset period to hash');
const params1 = new URLSearchParams();
params1.set('metric', 'weight');
params1.set('granularity', 'month');
params1.set('aggregation', 'avg');
params1.set('period', 'Last 12 months');
const hash1 = params1.toString();
assert.ok(hash1.includes('metric=weight'), 'Hash should include metric');
assert.ok(hash1.includes('granularity=month'), 'Hash should include granularity');
assert.ok(hash1.includes('aggregation=avg'), 'Hash should include aggregation');
assert.ok(hash1.includes('period='), 'Hash should include period');
console.log('✓ Preset period encoded correctly');
console.log('');

// Test 2: Encode custom date range to hash
console.log('Test 2: Encode custom date range to hash');
const params2 = new URLSearchParams();
params2.set('metric', 'weight');
params2.set('granularity', 'day');
params2.set('aggregation', 'sum');
params2.set('start', '2026-08-01');
params2.set('end', '2026-08-16');
const hash2 = params2.toString();
assert.ok(hash2.includes('metric=weight'), 'Hash should include metric');
assert.ok(hash2.includes('granularity=day'), 'Hash should include granularity');
assert.ok(hash2.includes('aggregation=sum'), 'Hash should include aggregation');
assert.ok(hash2.includes('start=2026-08-01'), 'Hash should include start date');
assert.ok(hash2.includes('end=2026-08-16'), 'Hash should include end date');
assert.ok(!hash2.includes('period='), 'Hash should not include period for custom dates');
console.log('✓ Custom date range encoded correctly');
console.log('');

// Test 3: Decode hash with preset period
console.log('Test 3: Decode hash with preset period');
const hashToRestore = 'metric=weight&granularity=month&aggregation=avg&period=Last%2012%20months';
const restoredParams = new URLSearchParams(hashToRestore);
assert.strictEqual(restoredParams.get('metric'), 'weight', 'Should restore metric');
assert.strictEqual(restoredParams.get('granularity'), 'month', 'Should restore granularity');
assert.strictEqual(restoredParams.get('aggregation'), 'avg', 'Should restore aggregation');
assert.strictEqual(restoredParams.get('period'), 'Last 12 months', 'Should restore period');
assert.strictEqual(restoredParams.get('start'), null, 'Should not have start date');
assert.strictEqual(restoredParams.get('end'), null, 'Should not have end date');
console.log('✓ Preset period decoded correctly');
console.log('');

// Test 4: Decode hash with custom dates
console.log('Test 4: Decode hash with custom dates');
const customHash = 'metric=weight&granularity=day&aggregation=sum&start=2026-08-01&end=2026-08-16';
const customParams = new URLSearchParams(customHash);
assert.strictEqual(customParams.get('metric'), 'weight', 'Should restore metric');
assert.strictEqual(customParams.get('granularity'), 'day', 'Should restore granularity');
assert.strictEqual(customParams.get('aggregation'), 'sum', 'Should restore aggregation');
assert.strictEqual(customParams.get('start'), '2026-08-01', 'Should restore start date');
assert.strictEqual(customParams.get('end'), '2026-08-16', 'Should restore end date');
assert.strictEqual(customParams.get('period'), null, 'Should not have period');
console.log('✓ Custom dates decoded correctly');
console.log('');

// Test 5: Empty hash returns null for all params
console.log('Test 5: Empty hash handling');
const emptyParams = new URLSearchParams('');
assert.strictEqual(emptyParams.get('metric'), null, 'Empty hash should return null');
assert.strictEqual(emptyParams.size, 0, 'Empty hash should have size 0');
console.log('✓ Empty hash handled correctly');
console.log('');

// Test 6: Verify all required parameters for preset period
console.log('Test 6: Required parameters validation (preset period)');
const presetParams = new URLSearchParams('metric=weight&granularity=month&aggregation=avg&period=Last+12+months');
assert.ok(presetParams.has('metric'), 'Preset period should have metric');
assert.ok(presetParams.has('granularity'), 'Preset period should have granularity');
assert.ok(presetParams.has('aggregation'), 'Preset period should have aggregation');
assert.ok(presetParams.has('period'), 'Preset period should have period');
console.log('✓ All required parameters present for preset period');
console.log('');

// Test 7: Verify all required parameters for custom dates
console.log('Test 7: Required parameters validation (custom dates)');
const customDateParams = new URLSearchParams('metric=weight&granularity=day&aggregation=sum&start=2026-08-01&end=2026-08-16');
assert.ok(customDateParams.has('metric'), 'Custom dates should have metric');
assert.ok(customDateParams.has('granularity'), 'Custom dates should have granularity');
assert.ok(customDateParams.has('aggregation'), 'Custom dates should have aggregation');
assert.ok(customDateParams.has('start'), 'Custom dates should have start');
assert.ok(customDateParams.has('end'), 'Custom dates should have end');
console.log('✓ All required parameters present for custom dates');
console.log('');

console.log('✅ All URL hash tests passed');
