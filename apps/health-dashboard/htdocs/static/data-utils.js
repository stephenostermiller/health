// Shared data point and validation utilities for both browser and Node.js

const DataUtils = (function() {
  function calculateDataPoints(granularity, start, end) {
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

  function subtractCalendarMonths(ymd, n) {
    const [y, m, d] = ymd.split('-').map(Number);
    let newM = m - n, newY = y;
    while (newM < 1) { newM += 12; newY -= 1; }
    const daysInMonth = new Date(newY, newM, 0).getDate();
    const newD = Math.min(d, daysInMonth);
    return `${String(newY).padStart(4,'0')}-${String(newM).padStart(2,'0')}-${String(newD).padStart(2,'0')}`;
  }

  function validateSpan(granularity, start, end, configOrMaxDataPoints) {
    if (!start || !end) return null;
    if (start > end) return 'Start date must be on or before end date.';
    if (granularity === 'auto') return null;

    let config = {};
    let maxDataPoints = 800;

    if (typeof configOrMaxDataPoints === 'number') {
      maxDataPoints = configOrMaxDataPoints;
    } else if (configOrMaxDataPoints) {
      config = configOrMaxDataPoints;
      maxDataPoints = config.maxDataPoints || 800;
    }

    const dataPoints = calculateDataPoints(granularity, start, end);
    if (dataPoints > maxDataPoints) {
      return `Selected range would produce ${dataPoints} data points, exceeding the maximum of ${maxDataPoints}`;
    }

    const policy = (config.granularities && config.granularities[granularity]) || {};
    if (policy.maxSpanDays) {
      const days = (new Date(end) - new Date(start)) / 86400000;
      if (days > policy.maxSpanDays) {
        return `Selected range exceeds the maximum of ${policy.maxSpanDays} days for ${granularity} granularity.`;
      }
    } else if (policy.maxSpanMonths) {
      if (start < subtractCalendarMonths(end, policy.maxSpanMonths)) {
        return `Selected range exceeds the maximum of ${policy.maxSpanMonths} months for ${granularity} granularity.`;
      }
    }
    return null;
  }

  return {
    calculateDataPoints: calculateDataPoints,
    validateSpan: validateSpan
  };
})();

// Export for Node.js/CommonJS
if (typeof module !== 'undefined' && module.exports) {
  module.exports = DataUtils;
}
