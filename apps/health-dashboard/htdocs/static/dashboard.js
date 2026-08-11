(function () {
  const config = window.dashboardConfig;
  let chart;

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
      labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
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
    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
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
    byId('metric').addEventListener('change', handleContextChange);
    byId('granularity').addEventListener('change', handleContextChange);
    byId('aggregation').addEventListener('change', handleContextChange);
    byId('start').addEventListener('change', handleDateInputChange);
    byId('end').addEventListener('change', handleDateInputChange);
    byId('controls').addEventListener('submit', handleSubmit);
    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
  });
})();
