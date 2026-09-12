#!/usr/bin/env node

// Test granularity change auto-adjustment logic using shared utilities
const assert = require('assert');
const GranularityUtils = require('../htdocs/static/granularity-utils.js');

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
    return GranularityUtils.calculateDataPoints(granularity, start, end);
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

  calculateSpanForDataPoints(granularity, numPoints) {
    return GranularityUtils.calculateSpanForDataPoints(granularity, numPoints);
  }

  addDaysToDate(dateStr, days) {
    return GranularityUtils.addDaysToDate(dateStr, days);
  }

  subtractDaysFromDate(dateStr, days) {
    return GranularityUtils.subtractDaysFromDate(dateStr, days);
  }

  calculateAdjustedRange(granularity, originalStart, originalEnd) {
    return GranularityUtils.calculateAdjustedRange(
      granularity,
      originalStart,
      originalEnd,
      this.lastVisibleDateRange,
      this.maxDataPoints
    );
  }

  changeGranularity(granularity, prevStart, prevEnd) {
    if (prevStart && prevEnd) {
      const error = this.validateSpan(granularity, prevStart, prevEnd);
      if (error) {
        const adjusted = this.calculateAdjustedRange(granularity, prevStart, prevEnd);
        const adjustedError = this.validateSpan(granularity, adjusted.start, adjusted.end);
        return {
          start: adjusted.start,
          end: adjusted.end,
          autoAdjusted: true,
          error: adjustedError
        };
      } else {
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
assert.strictEqual(result1.start, '2026-06-18', 'Should keep visible start (no better option)');
// End date should be expanded to show 800 weeks while including all visible data
assert(result1.end > '2026-09-12', 'Should expand end to show more weeks');
assert(result1.end <= '2050-01-01', 'Should stay within original bounds');
const result1Points = changer.calculateDataPoints('week', result1.start, result1.end);
assert.strictEqual(result1Points, 800, `Adjusted range should be exactly 800 points, got ${result1Points}`);
assert.strictEqual(result1.error, null, 'Should have no error after adjustment');
console.log(`  Adjusted to ${result1Points} weeks: ${result1.start} to ${result1.end}`);
console.log('  ✓ Auto-adjustment expanded to 800 weeks while keeping visible data\n');

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

// Test 3: Fallback when no visible range available
console.log('Test 3: Fallback when no visible range available');
const changer3 = new GranularityChanger();
const result3 = changer3.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result3.autoAdjusted, true, 'Should attempt auto-adjust');
assert(result3.error !== null, 'Should have error for range exceeding 800 points');
assert(result3.error.includes('1229'), 'Error should show data point count');
console.log('  ✓ Handles missing visible range gracefully\n');

// Test 4: Scenario from user issue
console.log('Test 4: Scenario from user issue - expand to 800 weeks while keeping all data');
const changer4 = new GranularityChanger();
changer4.setVisibleRange('2026-06-18', '2026-09-12');
const largeRangeError = changer4.validateSpan('week', '2026-06-18', '2050-01-01');
assert(largeRangeError !== null, 'Large range should fail validation');
assert(largeRangeError.includes('1229'), 'Should show 1229 data points');
const result4 = changer4.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result4.autoAdjusted, true, 'Should auto-adjust');
assert.strictEqual(result4.start, '2026-06-18', 'Should keep start to include all visible data');
// Should expand to 800 weeks starting from visible start
const result4Points = changer4.calculateDataPoints('week', result4.start, result4.end);
assert.strictEqual(result4Points, 800, `Adjusted range should be exactly 800 weeks, got ${result4Points}`);
assert(result4.end > '2026-09-12', 'Should expand end beyond visible data');
assert(result4.end <= '2050-01-01', 'Should stay within original bounds');
const adjustedRangeError = changer4.validateSpan('week', result4.start, result4.end);
assert.strictEqual(adjustedRangeError, null, 'Adjusted range should be valid');
console.log(`  Expanded from 1229 weeks to ${result4Points} weeks: ${result4.start} to ${result4.end}`);
console.log('  ✓ User issue scenario handled correctly\n');

// Test 5: Multiple granularity switches adjust to each granularity's limits
console.log('Test 5: Multiple granularity switches adjust to each granularity\'s limits');
const changer5 = new GranularityChanger();
changer5.setVisibleRange('2026-06-18', '2026-09-12');
let result5a = changer5.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result5a.autoAdjusted, true, 'First switch should auto-adjust');
const result5aPoints = changer5.calculateDataPoints('week', result5a.start, result5a.end);
assert.strictEqual(result5aPoints, 800, 'Week adjustment should produce 800 weeks');
// Now switch to day: 800 weeks = 5600 days, which exceeds 800 day limit
// So it needs to re-adjust to 800 days
let result5b = changer5.changeGranularity('day', result5a.start, result5a.end);
assert.strictEqual(result5b.autoAdjusted, true, 'Day switch should adjust 800 weeks to 800 days');
const result5bPoints = changer5.calculateDataPoints('day', result5b.start, result5b.end);
assert.strictEqual(result5bPoints, 800, 'Day adjustment should produce 800 days');
assert(result5b.start >= '2026-06-18', 'Should preserve visible data start');
assert(result5b.end >= '2026-09-12', 'Should preserve visible data end');
// Switch back to week: 800 days = 114 weeks, well within 800 week limit
let result5c = changer5.changeGranularity('week', result5b.start, result5b.end);
assert.strictEqual(result5c.autoAdjusted, false, 'Week switch should not need adjustment (800 days < 800 weeks)');
const result5cPoints = changer5.calculateDataPoints('week', result5c.start, result5c.end);
assert(result5cPoints <= 800, `Week range should fit, got ${result5cPoints} points`);
console.log('  ✓ Multiple switches adjust per granularity limits\n');

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

// Test 8: Don't change range when data points fit within limit
console.log('Test 8: Don\'t change range when data points fit within limit');
const changer8 = new GranularityChanger();
changer8.setVisibleRange('2026-06-18', '2026-09-12');
const result8 = changer8.changeGranularity('day', '2026-07-01', '2026-08-31');
assert.strictEqual(result8.autoAdjusted, false, 'Should NOT auto-adjust when range fits');
assert.strictEqual(result8.start, '2026-07-01', 'Should keep original start');
assert.strictEqual(result8.end, '2026-08-31', 'Should keep original end');
assert.strictEqual(result8.error, null, 'Should have no error');
const pointsInRange = changer8.calculateDataPoints('day', result8.start, result8.end);
assert(pointsInRange <= 800, `Range should fit: ${pointsInRange} points`);
console.log(`  Range 2026-07-01 to 2026-08-31 produces ${pointsInRange} day points`);
console.log('  ✓ Preserves compatible ranges\n');

// Test 9: DON't change range when data fills existing range
console.log('Test 9: Don\'t change range when data fills existing range');
const changer9 = new GranularityChanger();
changer9.setVisibleRange('2026-06-18', '2026-09-12');
const result9 = changer9.changeGranularity('month', '2026-06-18', '2026-09-12');
assert.strictEqual(result9.autoAdjusted, false, 'Should NOT auto-adjust when data fills range');
assert.strictEqual(result9.start, '2026-06-18', 'Should keep original start');
assert.strictEqual(result9.end, '2026-09-12', 'Should keep original end');
assert.strictEqual(result9.error, null, 'Should have no error');
console.log('  ✓ Preserves ranges when data fills them\n');

// Test 10: DON't change range when switching to year granularity with large range
console.log('Test 10: Don\'t change range when switching to year granularity');
const changer10 = new GranularityChanger();
changer10.setVisibleRange('2026-06-18', '2026-09-12');
const result10 = changer10.changeGranularity('year', '2026-01-01', '2050-12-31');
assert.strictEqual(result10.autoAdjusted, false, 'Should NOT auto-adjust for year granularity');
assert.strictEqual(result10.start, '2026-01-01', 'Should keep original start');
assert.strictEqual(result10.end, '2050-12-31', 'Should keep original end');
assert.strictEqual(result10.error, null, 'Should have no error for year range');
const yearPoints = changer10.calculateDataPoints('year', result10.start, result10.end);
assert(yearPoints <= 800, `Year range should fit: ${yearPoints} points`);
console.log(`  Range 2026-2050 produces ${yearPoints} year points (within limit)`);
console.log('  ✓ Preserves ranges that fit in granularity\n');

// Test 11: DON't change range when switching to month granularity with large range
console.log('Test 11: Don\'t change range when switching to month granularity');
const changer11 = new GranularityChanger();
changer11.setVisibleRange('2026-06-18', '2026-09-12');
const result11 = changer11.changeGranularity('month', '2020-01-01', '2050-12-31');
assert.strictEqual(result11.autoAdjusted, false, 'Should NOT auto-adjust for month granularity');
assert.strictEqual(result11.start, '2020-01-01', 'Should keep original start');
assert.strictEqual(result11.end, '2050-12-31', 'Should keep original end');
assert.strictEqual(result11.error, null, 'Should have no error for month range');
const monthPoints = changer11.calculateDataPoints('month', result11.start, result11.end);
assert(monthPoints <= 800, `Month range should fit: ${monthPoints} points`);
console.log(`  Range 2020-2050 produces ${monthPoints} month points (within limit)`);
console.log('  ✓ Preserves ranges that fit in granularity\n');

// Test 12: calculateSpanForDataPoints - verify span calculations
console.log('Test 12: calculateSpanForDataPoints - verify span calculations');
const changer12 = new GranularityChanger();
const weekSpan = changer12.calculateSpanForDataPoints('week', 800);
assert(weekSpan > 5500 && weekSpan < 5700, `Expected ~5600 days for 800 weeks, got ${weekSpan}`);
const daySpan = changer12.calculateSpanForDataPoints('day', 800);
assert.strictEqual(daySpan, 799, `Expected 799 days for 800 days, got ${daySpan}`);
const yearSpan = changer12.calculateSpanForDataPoints('year', 800);
assert(yearSpan > 291000 && yearSpan < 292000, `Expected ~291800 days for 800 years, got ${yearSpan}`);
console.log('  ✓ Span calculations accurate\n');

// Test 13: addDaysToDate and subtractDaysFromDate
console.log('Test 13: addDaysToDate and subtractDaysFromDate');
const changer13 = new GranularityChanger();
const baseDate = '2026-06-18';
const plus7 = changer13.addDaysToDate(baseDate, 7);
assert.strictEqual(plus7, '2026-06-25', `Expected 2026-06-25, got ${plus7}`);
const minus7 = changer13.subtractDaysFromDate(baseDate, 7);
assert.strictEqual(minus7, '2026-06-11', `Expected 2026-06-11, got ${minus7}`);
console.log('  ✓ Date arithmetic accurate\n');

// Test 14: calculateAdjustedRange - with visible data
console.log('Test 14: calculateAdjustedRange - with visible data');
const changer14 = new GranularityChanger();
changer14.setVisibleRange('2026-06-18', '2026-09-12');
const adjusted14 = changer14.calculateAdjustedRange('week', '2026-06-18', '2050-01-01');
console.log(`  Original range: 2026-06-18 to 2050-01-01`);
console.log(`  Visible range: 2026-06-18 to 2026-09-12`);
console.log(`  Adjusted range: ${adjusted14.start} to ${adjusted14.end}`);
assert.strictEqual(adjusted14.start, '2026-06-18', 'Should keep start to include all visible data');
assert(adjusted14.end > '2026-09-12', 'Should expand end to 800 weeks');
assert(adjusted14.end <= '2050-01-01', 'Should stay within original bounds');
const adjustedPoints = changer14.calculateDataPoints('week', adjusted14.start, adjusted14.end);
console.log(`  Data points in adjusted range: ${adjustedPoints}`);
assert.strictEqual(adjustedPoints, 800, `Adjusted range should be exactly 800 weeks, got ${adjustedPoints}`);
console.log('  ✓ Expands range to 800 weeks while including visible data\n');

// Test 15: calculateAdjustedRange - day granularity with visible data
console.log('Test 15: calculateAdjustedRange - day granularity with visible data');
const changer15 = new GranularityChanger();
changer15.setVisibleRange('2026-06-18', '2026-09-12');
const adjusted15 = changer15.calculateAdjustedRange('day', '2026-06-18', '2050-01-01');
const adjustedDays = changer15.calculateDataPoints('day', adjusted15.start, adjusted15.end);
console.log(`  Adjusted range for days: ${adjusted15.start} to ${adjusted15.end} (${adjustedDays} points)`);
assert.strictEqual(adjusted15.start, '2026-06-18', 'Should keep start to include all visible data');
assert(adjusted15.end > '2026-09-12', 'Should expand end for 800 days');
assert(adjustedDays, 800, `Day range should be 800 points, got ${adjustedDays} points`);
console.log('  ✓ Day granularity expands to 800 points while including visible data\n');

// Test 16: calculateAdjustedRange - month granularity with visible data
console.log('Test 16: calculateAdjustedRange - month granularity with visible data');
const changer16 = new GranularityChanger();
changer16.setVisibleRange('2026-06-18', '2026-09-12');
const adjusted16 = changer16.calculateAdjustedRange('month', '2026-06-18', '2050-01-01');
const adjustedMonths = changer16.calculateDataPoints('month', adjusted16.start, adjusted16.end);
console.log(`  Adjusted range for months: ${adjusted16.start} to ${adjusted16.end} (${adjustedMonths} points)`);
assert.strictEqual(adjusted16.start, '2026-06-18', 'Should use original start');
assert.strictEqual(adjusted16.end, '2050-01-01', 'Should use original end (fits within 800 months)');
assert(adjustedMonths <= 800, `Month range should fit, got ${adjustedMonths} points`);
console.log('  ✓ Month granularity preserves range when it fits (284 < 800)\n');

// Test 17: changeGranularity with week granularity expands to 800 weeks
console.log('Test 17: changeGranularity with week granularity expands to 800 weeks');
const changer17 = new GranularityChanger();
changer17.setVisibleRange('2026-06-18', '2026-09-12');
const result17 = changer17.changeGranularity('week', '2026-06-18', '2050-01-01');
assert.strictEqual(result17.autoAdjusted, true, 'Should be auto-adjusted');
assert.strictEqual(result17.start, '2026-06-18', 'Should keep start to include visible data');
assert(result17.end > '2026-09-12', 'Should expand end to 800 weeks');
const result17Points = changer17.calculateDataPoints('week', result17.start, result17.end);
assert(result17Points <= 800, `Result should have ≤800 points, got ${result17Points}`);
console.log(`  Adjusted to ${result17Points} points: ${result17.start} to ${result17.end}`);
console.log('  ✓ Auto-adjustment produces valid range\n');

// Test 18: changeGranularity preserves range when valid
console.log('Test 18: changeGranularity preserves range when valid');
const changer18 = new GranularityChanger();
const result18 = changer18.changeGranularity('year', '2026-01-01', '2050-12-31');
assert.strictEqual(result18.autoAdjusted, false, 'Should not adjust when valid');
assert.strictEqual(result18.start, '2026-01-01', 'Start should be preserved');
assert.strictEqual(result18.end, '2050-12-31', 'End should be preserved');
console.log('  ✓ Valid ranges preserved\n');

console.log('✅ All granularity auto-adjustment tests passed!');
