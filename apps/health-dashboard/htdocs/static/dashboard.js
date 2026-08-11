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

  function setDefaults() {
    const end = new Date();
    const start = new Date();
    start.setMonth(start.getMonth() - 6);
    byId('end').value = end.toISOString().slice(0, 10);
    byId('start').value = start.toISOString().slice(0, 10);
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

  function renderChart(payload) {
    const context = byId('health-chart');
    if (chart) {
      chart.destroy();
    }
    chart = new Chart(context, {
      type: 'line',
      data: {
        labels: payload.labels,
        datasets: payload.datasets,
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        scales: {
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
    const params = new URLSearchParams({
      metric: byId('metric').value,
      granularity: byId('granularity').value,
      start: byId('start').value,
      end: byId('end').value,
    });
    byId('chart-status').textContent = 'Loading…';

    const response = await fetch('api/series.cgi?' + params.toString(), {
      headers: { Accept: 'application/json' },
    });
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || 'Request failed');
    }
    renderChart(payload);
    updateSummary(payload);
    byId('chart-status').textContent = '';
  }

  async function handleSubmit(event) {
    event.preventDefault();
    try {
      await loadSeries();
    } catch (error) {
      byId('chart-status').textContent = error.message;
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    populateMetrics();
    setDefaults();
    byId('controls').addEventListener('submit', handleSubmit);
    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
  });
})();
