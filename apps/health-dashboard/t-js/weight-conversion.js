#!/usr/bin/env node

const assert = require('assert');

// Simulate the conversion logic from loadSeries
function convertWeightPayload(payload, unitPreference) {
  if (payload.metric === 'weight' && unitPreference === 'metric') {
    const lbsToKgRatio = 2.20462;
    payload.unit = 'kilograms';
    payload.datasets.forEach(dataset => {
      dataset.data = dataset.data.map(value => value !== null && value !== undefined ? value / lbsToKgRatio : value);
    });
  }
  return payload;
}

// Test 1: Weight conversion when metric preference is set
console.log('Test 1: Weight conversion to kilograms');
const payload1 = {
  metric: 'weight',
  unit: 'pounds',
  datasets: [
    {
      label: 'Weight average',
      data: [200, 195, 190, 185]
    }
  ]
};
const converted = convertWeightPayload(JSON.parse(JSON.stringify(payload1)), 'metric');
assert.strictEqual(converted.unit, 'kilograms', 'Unit should be converted to kilograms');
assert.strictEqual(converted.datasets[0].data[0], 200 / 2.20462, 'First value should be converted from pounds to kg');
assert.strictEqual(converted.datasets[0].data[1], 195 / 2.20462, 'Second value should be converted from pounds to kg');
console.log('✓ Weight values correctly converted to kilograms');

// Test 2: No conversion when unit preference is imperial
console.log('\nTest 2: No conversion when unit preference is imperial');
const payload2 = {
  metric: 'weight',
  unit: 'pounds',
  datasets: [
    {
      label: 'Weight average',
      data: [200, 195, 190, 185]
    }
  ]
};
const unconverted = convertWeightPayload(JSON.parse(JSON.stringify(payload2)), 'imperial');
assert.strictEqual(unconverted.unit, 'pounds', 'Unit should remain as pounds');
assert.strictEqual(unconverted.datasets[0].data[0], 200, 'Value should not be converted');
console.log('✓ Values remain unchanged when unit preference is imperial');

// Test 3: No conversion for non-weight metrics
console.log('\nTest 3: No conversion for non-weight metrics');
const payload3 = {
  metric: 'body_fat',
  unit: 'percent',
  datasets: [
    {
      label: 'Body fat average',
      data: [25, 24, 23, 22]
    }
  ]
};
const bodyFatPayload = convertWeightPayload(JSON.parse(JSON.stringify(payload3)), 'metric');
assert.strictEqual(bodyFatPayload.unit, 'percent', 'Unit should remain as percent for body_fat metric');
assert.strictEqual(bodyFatPayload.datasets[0].data[0], 25, 'Body fat value should not be converted');
console.log('✓ Non-weight metrics are not converted');

// Test 4: Handle null values
console.log('\nTest 4: Handle null values');
const payload4 = {
  metric: 'weight',
  unit: 'pounds',
  datasets: [
    {
      label: 'Weight average',
      data: [200, null, 0, 185]
    }
  ]
};
const convertedWithNulls = convertWeightPayload(JSON.parse(JSON.stringify(payload4)), 'metric');
assert.strictEqual(convertedWithNulls.datasets[0].data[0], 200 / 2.20462, 'Non-null value should be converted');
assert.strictEqual(convertedWithNulls.datasets[0].data[1], null, 'Null value should remain null');
assert.strictEqual(convertedWithNulls.datasets[0].data[2], 0 / 2.20462, 'Zero value should be converted');
assert.strictEqual(convertedWithNulls.datasets[0].data[3], 185 / 2.20462, 'Last value should be converted');
console.log('✓ Null values handled correctly');

// Test 5: Multiple datasets conversion
console.log('\nTest 5: Multiple datasets conversion');
const payload5 = {
  metric: 'weight',
  unit: 'pounds',
  datasets: [
    {
      label: 'Weight maximum',
      data: [210, 205, 200]
    },
    {
      label: 'Weight average',
      data: [200, 195, 190]
    },
    {
      label: 'Weight minimum',
      data: [190, 185, 180]
    }
  ]
};
const multiConverted = convertWeightPayload(JSON.parse(JSON.stringify(payload5)), 'metric');
assert.strictEqual(multiConverted.datasets.length, 3, 'Should have 3 datasets');
for (let i = 0; i < multiConverted.datasets.length; i++) {
  for (let j = 0; j < multiConverted.datasets[i].data.length; j++) {
    const originalValue = payload5.datasets[i].data[j];
    const convertedValue = multiConverted.datasets[i].data[j];
    assert.strictEqual(convertedValue, originalValue / 2.20462, `Dataset ${i} value ${j} should be converted`);
  }
}
console.log('✓ All datasets converted correctly');

console.log('\n✅ All weight conversion tests passed');
