#!/usr/bin/env node

// Test granularity change auto-adjustment logic
const assert = require('assert');

// Simulate the visible date range storage and auto-adjust logic
class GranularityChanger {
  constructor() {
    this.lastVisibleDateRange = null;
    this.maxDataPoints = 800;
  }

  setVisibleRange(start, end) {
    this.lastVisibleDateRange = { start, end };
  }

  calculateDataPoints(granularity, start, end) {
    if (!start || !end) return 0;
    const [startYear, startMonth, startDay] = start.split('-').map(Number);
    const [endYear, endMonth, endDay] = end.split('-').map(Number);

    if (granularity === 'year') {
      return endYear - startYear + 1;
    } else if (granularity === 'month') {
      return (endYear - startYear) * 12 + (endMonth - startMonth) + 1;
    } else if (granularity === 'week') {
      const startDate = new Date(start + 'T00:00:00Z');
      const endDate = new Date(end + 'T00:00:00Z');
      const daysDiff = Math.floor((endDate - startDate) / 86400000);
      const days = daysDiff + 1;
      return Math.floor(days / 7) + 1;
    } else if (granularity === 'day') {
      const startDate = new Date(start + 'T00:00:00Z');
      const endDate = new Date(end + 'T00:00:00Z');
      const daysDiff = Math.floor((endDate - startDate) / 86400000);
      return daysDiff + 1;
    }
    return 0;
  }

  validateSpan(granularity, start, end) {
    if (!start || !end) return null;
    if (start > end) return 'Start date must be on or before end date.';
    if (granularity === 'auto') return null;

    const dataPoints = this.calculateDataPoints(granularity, start, end);
    if (dataPoints > this.maxDataPoints) {
      return `Selected range would produce ${dataPoints} data points, exceeding the maximum of ${this.maxDataPoints}`;
    }

    return null;
  }

  // Simulate handleGranularityChange logic
  changeGranularity(granularity, prevStart, prevEnd) {
    if (prevStart && prevEnd) {
      const error = this.validateSpan(granularity, prevStart, prevEnd);
      if (error && this.lastVisibleDateRange) {
        // Auto-adjust to visible range
        return {
          start: this.lastVisibleDateRange.start,
          end: this.lastVisibleDateRange.end,
          autoAdjusted: true,
          error: null
        };
      } else if (error) {
        // Error but no visible range to fall back to
        return {
          start: prevStart,
          end: prevEnd,
          autoAdjusted: false,
          error: error
        };
      } else {
        // No error, keep range
        return {
          start: prevStart,
          end: prevEnd,
          autoAdjusted: false,
          error: null
        };
      }
    }
    return { autoAdjusted: false, error: null };
  }
}

console.log('Testing granularity change auto-adjustment...\n');

// Test 1: Auto-adjust when changing to incompatible granularity
console.log('Test 1: Auto-adjust when changing to incompatible granularity');
const changer = new GranularityChanger();
changer.setVisibleRange('2026-06-18', '2026-09-12');
const result1 = changer.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result1.autoAdjusted, true, 'Should auto-adjust');
assert.strictEqual(result1.start, '2026-06-18', 'Should use visible start');
assert.strictEqual(result1.end, '2026-09-12', 'Should use visible end');
assert.strictEqual(result1.error, null, 'Should have no error after adjustment');
console.log('  ✓ Auto-adjustment triggered correctly\n');

// Test 2: Keep range when compatible
console.log('Test 2: Keep range when compatible');
const changer2 = new GranularityChanger();
changer2.setVisibleRange('2026-06-18', '2026-09-12');
const result2 = changer2.changeGranularity('year', '2026-01-01', '2026-12-31');
assert.strictEqual(result2.autoAdjusted, false, 'Should not auto-adjust');
assert.strictEqual(result2.start, '2026-01-01', 'Should keep original start');
assert.strictEqual(result2.end, '2026-12-31', 'Should keep original end');
assert.strictEqual(result2.error, null, 'Should have no error');
console.log('  ✓ Compatible ranges preserved\n');

// Test 3: Error when no visible range available
console.log('Test 3: Error when no visible range available');
const changer3 = new GranularityChanger();
// No visible range set
const result3 = changer3.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result3.autoAdjusted, false, 'Should not auto-adjust');
assert(result3.error !== null, 'Should have error due to range validation');
assert(result3.error.includes('1229'), 'Error should show data point count');
console.log('  ✓ Handles missing visible range gracefully\n');

// Test 4: Scenario from user issue
console.log('Test 4: Scenario from user issue - large range with small visible data');
const changer4 = new GranularityChanger();
changer4.setVisibleRange('2026-06-18', '2026-09-12');

// User starts with auto granularity and large range
const largeRangeError = changer4.validateSpan('week', '2026-06-18', '2050-01-01');
assert(largeRangeError !== null, 'Large range should fail validation');
assert(largeRangeError.includes('1229'), 'Should show 1229 data points');

// Then switches to week granularity
const result4 = changer4.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result4.autoAdjusted, true, 'Should auto-adjust');
assert.strictEqual(result4.start, '2026-06-18', 'Start should match visible range');
assert.strictEqual(result4.end, '2026-09-12', 'End should match visible range');

// Verify adjusted range is valid
const adjustedRangeError = changer4.validateSpan('week', result4.start, result4.end);
assert.strictEqual(adjustedRangeError, null, 'Adjusted range should be valid');
console.log('  ✓ User issue scenario handled correctly\n');

// Test 5: Multiple granularity switches
console.log('Test 5: Multiple granularity switches');
const changer5 = new GranularityChanger();
changer5.setVisibleRange('2026-06-18', '2026-09-12');

// Switch to week (auto-adjusts)
let result5a = changer5.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result5a.autoAdjusted, true, 'First switch should auto-adjust');

// Switch to day with adjusted range (compatible)
let result5b = changer5.changeGranularity('day', result5a.start, result5a.end);
assert.strictEqual(result5b.autoAdjusted, false, 'Should not need adjustment for day granularity');
assert.strictEqual(result5b.start, '2026-06-18', 'Should keep adjusted start');

// Switch back to week with adjusted range (still compatible)
let result5c = changer5.changeGranularity('week', result5b.start, result5b.end);
assert.strictEqual(result5c.autoAdjusted, false, 'Should not need adjustment');
console.log('  ✓ Multiple switches handled correctly\n');

// Test 6: Verify week calculation accuracy
console.log('Test 6: Verify week calculation accuracy');
const changer6 = new GranularityChanger();
const weeks1 = changer6.calculateDataPoints('week', '2026-06-18', '2026-09-12');
assert(weeks1 <= 15, `Expected 13-15 weeks for 3-month range, got ${weeks1}`);
assert(weeks1 >= 12, `Expected at least 12 weeks, got ${weeks1}`);
console.log(`  Weeks in 2026-06-18 to 2026-09-12: ${weeks1}`);
console.log('  ✓ Week calculation accurate\n');

// Test 7: Verify day calculation accuracy
console.log('Test 7: Verify day calculation accuracy');
const changer7 = new GranularityChanger();
const days1 = changer7.calculateDataPoints('day', '2026-06-18', '2026-09-12');
assert.strictEqual(days1, 87, `Expected 87 days, got ${days1}`);
console.log(`  Days in 2026-06-18 to 2026-09-12: ${days1}`);
console.log('  ✓ Day calculation accurate\n');

// Test 8: DON'T change range when data points fit within limit
console.log('Test 8: Don\'t change range when data points fit within limit');
const changer8 = new GranularityChanger();
changer8.setVisibleRange('2026-06-18', '2026-09-12');
// User requests a smaller range that fits within limit for day granularity
const result8 = changer8.changeGranularity('day', '2026-07-01', '2026-08-31');
assert.strictEqual(result8.autoAdjusted, false, 'Should NOT auto-adjust when range fits');
assert.strictEqual(result8.start, '2026-07-01', 'Should keep original start');
assert.strictEqual(result8.end, '2026-08-31', 'Should keep original end');
assert.strictEqual(result8.error, null, 'Should have no error');
const pointsInRange = changer8.calculateDataPoints('day', result8.start, result8.end);
assert(pointsInRange <= 800, `Range should fit: ${pointsInRange} points`);
console.log(`  Range 2026-07-01 to 2026-08-31 produces ${pointsInRange} day points`);
console.log('  ✓ Preserves compatible ranges\n');

// Test 9: DON'T change range when data fills existing range
console.log('Test 9: Don\'t change range when data fills existing range');
const changer9 = new GranularityChanger();
// Data range is exactly the same as requested range
changer9.setVisibleRange('2026-06-18', '2026-09-12');
// User requests month granularity for the same range
const result9 = changer9.changeGranularity('month', '2026-06-18', '2026-09-12');
assert.strictEqual(result9.autoAdjusted, false, 'Should NOT auto-adjust when data fills range');
assert.strictEqual(result9.start, '2026-06-18', 'Should keep original start');
assert.strictEqual(result9.end, '2026-09-12', 'Should keep original end');
assert.strictEqual(result9.error, null, 'Should have no error');
console.log('  ✓ Preserves ranges when data fills them\n');

// Test 10: DON'T change range when switching to year granularity with large range
console.log('Test 10: Don\'t change range when switching to year granularity');
const changer10 = new GranularityChanger();
changer10.setVisibleRange('2026-06-18', '2026-09-12');
// Year granularity can handle much larger ranges (only produces ~24 points for 24 years)
const result10 = changer10.changeGranularity('year', '2026-01-01', '2050-12-31');
assert.strictEqual(result10.autoAdjusted, false, 'Should NOT auto-adjust for year granularity');
assert.strictEqual(result10.start, '2026-01-01', 'Should keep original start');
assert.strictEqual(result10.end, '2050-12-31', 'Should keep original end');
assert.strictEqual(result10.error, null, 'Should have no error for year range');
const yearPoints = changer10.calculateDataPoints('year', result10.start, result10.end);
assert(yearPoints <= 800, `Year range should fit: ${yearPoints} points`);
console.log(`  Range 2026-2050 produces ${yearPoints} year points (within limit)`);
console.log('  ✓ Preserves ranges that fit in granularity\n');

// Test 11: DON'T change range when switching to month granularity with large range
console.log('Test 11: Don\'t change range when switching to month granularity');
const changer11 = new GranularityChanger();
changer11.setVisibleRange('2026-06-18', '2026-09-12');
// Month granularity can handle ~33+ years (only produces 400 points for 33 years)
const result11 = changer11.changeGranularity('month', '2020-01-01', '2050-12-31');
assert.strictEqual(result11.autoAdjusted, false, 'Should NOT auto-adjust for month granularity');
assert.strictEqual(result11.start, '2020-01-01', 'Should keep original start');
assert.strictEqual(result11.end, '2050-12-31', 'Should keep original end');
assert.strictEqual(result11.error, null, 'Should have no error for month range');
const monthPoints = changer11.calculateDataPoints('month', result11.start, result11.end);
assert(monthPoints <= 800, `Month range should fit: ${monthPoints} points`);
console.log(`  Range 2020-2050 produces ${monthPoints} month points (within limit)`);
console.log('  ✓ Preserves ranges that fit in granularity\n');

console.log('✅ All granularity auto-adjustment tests passed!');
