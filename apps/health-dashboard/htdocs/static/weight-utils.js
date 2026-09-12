// Shared weight conversion utilities for both browser and Node.js

const WeightUtils = (function() {
  function convertWeightPayload(payload, unitPreference, roundValueFn) {
    if (payload.metric === 'weight' && unitPreference === 'metric') {
      const lbsToKgRatio = 2.20462;
      payload.unit = 'kilograms';
      payload.datasets.forEach(dataset => {
        dataset.data = dataset.data.map(value => {
          if (value === null || value === undefined) return value;
          const converted = value / lbsToKgRatio;
          return roundValueFn ? roundValueFn(converted, 'kilograms', 'weight') : converted;
        });
      });
    }
    return payload;
  }

  return {
    convertWeightPayload: convertWeightPayload
  };
})();

// Export for Node.js/CommonJS
if (typeof module !== 'undefined' && module.exports) {
  module.exports = WeightUtils;
}
