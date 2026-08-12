(function () {
  const config = window.dashboardConfig;
  let chart;

  const timePeriods = {
    day: [
      { label: 'Last 7 days', days: 7 },
      { label: 'Last 30 days', days: 30 },
      { label: 'Last 180 days', days: 180, default: true },
      { label: 'Last 365 days', days: 365 },
      { label: 'Last 2 years', days: 730 },
      { label: 'Custom', custom: true },
    ],
    week: [
      { label: 'Last 12 weeks', weeks: 12 },
      { label: 'Last 26 weeks', weeks: 26 },
      { label: 'Last 52 weeks', weeks: 52 },
      { label: 'Last 2 years', weeks: 104, default: true },
      { label: 'Last 3 years', weeks: 156 },
      { label: 'Last 4 years', weeks: 208 },
      { label: 'Custom', custom: true },
    ],
    month: [
      { label: 'Last 6 months', months: 6 },
      { label: 'Last 12 months', months: 12 },
      { label: 'Last 2 years', months: 24 },
      { label: 'Last 3 years', months: 36, default: true },
      { label: 'Last 5 years', months: 60 },
      { label: 'Last 10 years', months: 120 },
      { label: 'Custom', custom: true },
    ],
    year: [
      { label: 'All data', allData: true, default: true },
      { label: 'Last 5 years', years: 5 },
      { label: 'Last 10 years', years: 10 },
      { label: 'Custom', custom: true },
    ],
  };

  function byId(id) {
    return document.getElementById(id);
  }

  function populateMetrics() {
    const select = byId('metric');
    config.metrics.forEach((metric) => {
      const option = document.createElement('option');
      option.value = metric.metric;
      option.textContent = metric.label;
      if (metric.metric === config.defaultMetric) {
        option.selected = true;
      }
      select.appendChild(option);
    });
  }

  function populateTimePeriods(granularity) {
    const select = byId('time-period');
    select.innerHTML = '';
    const periods = timePeriods[granularity] || [];
    periods.forEach((period) => {
      const option = document.createElement('option');
      option.value = period.label;
      option.textContent = period.label;
      option.dataset.custom = period.custom ? 'true' : 'false';
      if (period.default) {
        option.selected = true;
      }
      select.appendChild(option);
    });
  }

  function calculateDateRange(granularity, periodLabel) {
    const periods = timePeriods[granularity] || [];
    const period = periods.find(p => p.label === periodLabel);
    if (!period || period.custom || period.allData) return null;

    const today = new Date();
    const endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    let startDate = new Date(endDate);

    if (period.days) {
      startDate.setDate(startDate.getDate() - period.days);
    } else if (period.weeks) {
      startDate.setDate(startDate.getDate() - period.weeks * 7);
    } else if (period.months) {
      startDate.setMonth(startDate.getMonth() - period.months);
    } else if (period.years) {
      startDate.setFullYear(startDate.getFullYear() - period.years);
    }

    const formatDate = (date) => date.toISOString().split('T')[0];
    return {
      start: formatDate(startDate),
      end: formatDate(endDate),
    };
  }

  function setDateInputVisibility(isCustom) {
    const dateControls = document.querySelectorAll('.date-control');
    if (isCustom) {
      dateControls.forEach(control => control.classList.add('visible'));
    } else {
      dateControls.forEach(control => control.classList.remove('visible'));
    }
  }

  function subtractCalendarMonths(ymd, n) {
    const [y, m, d] = ymd.split('-').map(Number);
    let newM = m - n, newY = y;
    while (newM < 1) { newM += 12; newY -= 1; }
    const daysInMonth = new Date(newY, newM, 0).getDate();
    const newD = Math.min(d, daysInMonth);
    return `${String(newY).padStart(4,'0')}-${String(newM).padStart(2,'0')}-${String(newD).padStart(2,'0')}`;
  }

  function validateSpan(granularity, start, end) {
    if (!start || !end) return null;
    if (start > end) return 'Start date must be on or before end date.';
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

  function applyRange(range) {
    if (!range) return;
    const s = byId('start'), e = byId('end');
    if (range.availableMin) { s.min = range.availableMin; e.min = range.availableMin; }
    if (range.availableMax) { s.max = range.availableMax; e.max = range.availableMax; }
    if (range.start) s.value = range.start;
    if (range.end) e.value = range.end;
  }

  function updateSummary(payload) {
    const container = byId('summary');
    container.innerHTML = '';
    const items = [
      ['Metric', payload.label],
      ['Granularity', payload.granularity],
      ['Points', String(payload.labels.length)],
      ['Unit', payload.unit || ''],
    ];

    items.forEach(([label, value]) => {
      const item = document.createElement('div');
      item.className = 'summary-item';
      item.innerHTML = '<strong>' + label + '</strong><span>' + value + '</span>';
      container.appendChild(item);
    });
  }

  function dateToTimestamp(dateStr) {
    return new Date(dateStr).getTime();
  }

  function yearToTimestamp(yearStr) {
    return new Date(yearStr + '-01-01').getTime();
  }

  function renderChart(payload, granularity) {
    const context = byId('health-chart');
    if (chart) {
      chart.destroy();
    }

    let converter, labelFormatter;
    if (granularity === 'year') {
      converter = yearToTimestamp;
      labelFormatter = (value) => new Date(value).getFullYear().toString();
    } else if (granularity === 'month') {
      converter = dateToTimestamp;
      labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { year: 'numeric', month: 'short' });
    } else {
      converter = dateToTimestamp;

      // Check if data spans multiple years
      const years = payload.labels.map(label => new Date(label).getFullYear());
      const spansMultipleYears = Math.min(...years) !== Math.max(...years);

      if (spansMultipleYears) {
        labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
      } else {
        labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      }
    }

    timestamps = payload.labels.map(converter);
    const minTime = Math.min(...timestamps);
    const maxTime = Math.max(...timestamps);

    const transformedDatasets = payload.datasets.map(dataset => ({
      ...dataset,
      data: payload.labels.map((label, i) => ({
        x: converter(label),
        y: dataset.data[i],
      })),
    }));

    chart = new Chart(context, {
      type: 'line',
      data: {
        datasets: transformedDatasets,
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          tooltip: {
            callbacks: {
              title: (context) => {
                if (!context.length) return '';
                const timestamp = context[0].parsed.x;
                return labelFormatter(timestamp);
              },
            },
          },
        },
        scales: {
          x: {
            type: 'linear',
            min: minTime,
            max: maxTime,
            ticks: {
              callback: labelFormatter,
            },
          },
          y: {
            title: {
              display: Boolean(payload.unit),
              text: payload.unit || '',
            },
          },
        },
      },
    });
  }

  async function loadSeries() {
    const start = byId('start').value;
    const end = byId('end').value;
    const granularity = byId('granularity').value;
    const params = new URLSearchParams({
      metric: byId('metric').value,
      granularity: granularity,
      aggregation: byId('aggregation').value,
    });
    if (start && end) {
      params.append('start', start);
      params.append('end', end);
    }
    byId('chart-status').textContent = 'Loading…';

    const response = await fetch('api/series.cgi?' + params.toString(), {
      headers: { Accept: 'application/json' },
    });
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || 'Request failed');
    }
    applyRange(payload.range);
    renderChart(payload, granularity);
    updateSummary(payload);
    byId('chart-status').textContent = '';
  }

  function handleContextChange(event) {
    byId('start').value = '';
    byId('end').value = '';
    byId('range-error').textContent = '';
    const granularity = byId('granularity').value;
    populateTimePeriods(granularity);
    setDateInputVisibility(false);
    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
  }

  function handleTimePeriodChange(event) {
    const periodLabel = byId('time-period').value;
    const granularity = byId('granularity').value;
    const isCustom = event.target.selectedOptions[0].dataset.custom === 'true';

    if (isCustom) {
      setDateInputVisibility(true);
    } else {
      const dateRange = calculateDateRange(granularity, periodLabel);
      if (dateRange) {
        byId('start').value = dateRange.start;
        byId('end').value = dateRange.end;
      }
      setDateInputVisibility(false);
      byId('range-error').textContent = '';
      loadSeries().catch((error) => {
        byId('chart-status').textContent = error.message;
      });
    }
  }

  function handleDateInputChange(event) {
    const granularity = byId('granularity').value;
    const start = byId('start').value;
    const end = byId('end').value;
    const error = validateSpan(granularity, start, end);
    byId('range-error').textContent = error || '';
  }

  async function handleSubmit(event) {
    event.preventDefault();
    const granularity = byId('granularity').value;
    const start = byId('start').value;
    const end = byId('end').value;
    const error = validateSpan(granularity, start, end);
    if (error) {
      byId('range-error').textContent = error;
      return;
    }
    byId('range-error').textContent = '';
    try {
      await loadSeries();
    } catch (error) {
      byId('chart-status').textContent = error.message;
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    populateMetrics();
    const granularity = byId('granularity').value;
    populateTimePeriods(granularity);
    setDateInputVisibility(false);
    byId('metric').addEventListener('change', handleContextChange);
    byId('granularity').addEventListener('change', handleContextChange);
    byId('aggregation').addEventListener('change', handleContextChange);
    byId('time-period').addEventListener('change', handleTimePeriodChange);
    byId('start').addEventListener('change', handleDateInputChange);
    byId('end').addEventListener('change', handleDateInputChange);
    byId('controls').addEventListener('submit', handleSubmit);
    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
  });
})();
