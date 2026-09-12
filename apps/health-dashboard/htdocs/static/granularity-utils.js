// Shared granularity adjustment utilities for both browser and Node.js

const GranularityUtils = (function() {
  function calculateDataPoints(granularity, start, end) {
    if (!start || !end) return 0;
    const [startYear, startMonth] = start.split('-').map(Number);
    const [endYear, endMonth] = end.split('-').map(Number);

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

  function calculateSpanForDataPoints(granularity, numPoints) {
    if (granularity === 'year') {
      return (numPoints - 1) * 365.25;
    } else if (granularity === 'month') {
      return (numPoints - 1) * 30.44;
    } else if (granularity === 'week') {
      return (numPoints - 1) * 7;
    } else if (granularity === 'day') {
      return numPoints - 1;
    }
    return 0;
  }

  function addDaysToDate(dateStr, days) {
    const date = new Date(dateStr + 'T00:00:00Z');
    date.setUTCDate(date.getUTCDate() + days);
    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const day = String(date.getUTCDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function subtractDaysFromDate(dateStr, days) {
    return addDaysToDate(dateStr, -days);
  }

  function calculateAdjustedRange(granularity, originalStart, originalEnd, visibleRange, maxDataPoints) {
    maxDataPoints = maxDataPoints || 800;

    // Check if original range is already within limits
    const originalPoints = calculateDataPoints(granularity, originalStart, originalEnd);
    if (originalPoints <= maxDataPoints) {
      return { start: originalStart, end: originalEnd };
    }

    // If no visible range, we can't safely adjust without cutting data
    if (!visibleRange || !visibleRange.start || !visibleRange.end) {
      return { start: originalStart, end: originalEnd };
    }

    // Original range is too large, need to adjust to fit maxDataPoints
    // Calculate the span needed for maxDataPoints
    const requiredSpanDays = calculateSpanForDataPoints(granularity, maxDataPoints);

    // Try option 1: keep the end, adjust the start
    let newStart1 = subtractDaysFromDate(originalEnd, requiredSpanDays);
    if (newStart1 < originalStart) {
      newStart1 = originalStart;
    }
    let newEnd1 = originalEnd;

    // Check if this range includes all visible data
    if (newStart1 <= visibleRange.start && newEnd1 >= visibleRange.end) {
      return { start: newStart1, end: newEnd1 };
    }

    // Try option 2: keep the start, adjust the end
    let newStart2 = originalStart;
    let newEnd2 = addDaysToDate(originalStart, requiredSpanDays);
    if (newEnd2 > originalEnd) {
      newEnd2 = originalEnd;
    }

    // Check if this range includes all visible data
    if (newStart2 <= visibleRange.start && newEnd2 >= visibleRange.end) {
      return { start: newStart2, end: newEnd2 };
    }

    // Can't adjust without cutting data, return original
    return { start: originalStart, end: originalEnd };
  }

  return {
    calculateDataPoints: calculateDataPoints,
    calculateSpanForDataPoints: calculateSpanForDataPoints,
    addDaysToDate: addDaysToDate,
    subtractDaysFromDate: subtractDaysFromDate,
    calculateAdjustedRange: calculateAdjustedRange
  };
})();

// Export for Node.js/CommonJS
if (typeof module !== 'undefined' && module.exports) {
  module.exports = GranularityUtils;
}
