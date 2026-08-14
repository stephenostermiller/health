const config = window.dashboardConfig || {};

(function () {
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
      { label: 'Last 3 years', months: 36},
      { label: 'Last 5 years', months: 60 },
      { label: 'Last 10 years', months: 120, default: true },
      { label: 'Last 15 years', months: 180 },
      { label: 'Last 20 years', months: 240 },
      { label: 'Custom', custom: true },
    ],
    year: [
      { label: 'Last 5 years', years: 5 },
      { label: 'Last 10 years', years: 10 },
      { label: 'Last 15 years', years: 15 },
      { label: 'Last 20 years', years: 20 },
      { label: 'Last 25 years', years: 25 },
      { label: 'Last 30 years', years: 30 },
      { label: 'Last 40 years', years: 40 },
      { label: 'Last 50 years', years: 50 },
      { label: 'Last 60 years', years: 60 },
      { label: 'Last 70 years', years: 70 },
      { label: 'Last 80 years', years: 80 },
      { label: 'Last 90 years', years: 90 },
      { label: 'All data', allData: true, default: true },
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

  function updateSummary(payload, aggregation) {
    const container = byId('summary');
    container.innerHTML = '';

    let minValue, maxValue, avgValue, minDate, maxDate;

    if (payload.datasets && payload.datasets.length > 0) {
      let allValues = [];
      let allValuesByDate = {};

      payload.labels.forEach((date) => {
        allValuesByDate[date] = [];
      });

      payload.datasets.forEach((dataset) => {
        payload.labels.forEach((date, index) => {
          const value = dataset.data[index];
          if (value !== null && value !== undefined) {
            allValues.push(value);
            allValuesByDate[date].push(value);
          }
        });
      });

      if (allValues.length > 0) {
        minValue = Math.min(...allValues);
        maxValue = Math.max(...allValues);
        avgValue = allValues.reduce((a, b) => a + b, 0) / allValues.length;

        for (const date in allValuesByDate) {
          if (allValuesByDate[date].includes(minValue)) {
            minDate = date;
            break;
          }
        }
        for (const date in allValuesByDate) {
          if (allValuesByDate[date].includes(maxValue)) {
            maxDate = date;
            break;
          }
        }
      }
    }

    let difference = minValue !== undefined && maxValue !== undefined ? maxValue - minValue : undefined;

    const items = [
      ['Points', String(payload.labels.length)],
      ['Minimum', minValue !== undefined ? minValue.toFixed(2) + ' (' + minDate + ')' : 'N/A'],
      ['Maximum', maxValue !== undefined ? maxValue.toFixed(2) + ' (' + maxDate + ')' : 'N/A'],
      ['Difference', difference !== undefined ? difference.toFixed(2) : 'N/A'],
      ['Average', avgValue !== undefined ? avgValue.toFixed(2) : 'N/A'],
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

  function monthToTimestamp(monthStr) {
    // Parse month string like "2026-08-01"
    const [year, month, day] = monthStr.split('-').map(Number);
    // Add 1 month to align with data positioning
    let newMonth = month + 1;
    let newYear = year;
    if (newMonth > 12) {
      newMonth = 1;
      newYear = year + 1;
    }
    return Date.UTC(newYear, newMonth - 1, 1);
  }

  function dayToTimestamp(dateStr) {
    const [year, month, day] = dateStr.split('-').map(Number);
    let newDay = day + 1;
    let newMonth = month;
    let newYear = year;
    const daysInMonth = new Date(newYear, newMonth, 0).getDate();
    if (newDay > daysInMonth) {
      newDay = 1;
      newMonth += 1;
      if (newMonth > 12) {
        newMonth = 1;
        newYear += 1;
      }
    }
    return Date.UTC(newYear, newMonth - 1, newDay);
  }

  function yearToTimestamp(year) {
    // Parse year as a number to avoid type issues
    const yearNum = parseInt(year);
    // Use UTC to avoid timezone issues
    // Add 1 to the year to align with data positioning
    return Date.UTC(yearNum + 1, 0, 1);
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
      converter = monthToTimestamp;
      labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { year: 'numeric', month: 'short' });
    } else if (granularity === 'day') {
      converter = dayToTimestamp;
      labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
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
    let minTime = Math.min(...timestamps);
    let maxTime = Math.max(...timestamps);

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
                // For year granularity, find the matching year by x value
                if (granularity === 'year') {
                  const xValue = context[0].parsed.x;
                  // Find which year corresponds to this timestamp
                  for (let i = 0; i < payload.labels.length; i++) {
                    const yearTimestamp = converter(payload.labels[i]);
                    if (Math.abs(yearTimestamp - xValue) < 1000) { // Within 1 second
                      return String(payload.labels[i]);
                    }
                  }
                }
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
              ...(granularity === 'year' ? {
                stepSize: 1000 * 60 * 60 * 24 * 365.25, // One year in milliseconds
              } : granularity === 'month' ? {
                stepSize: 1000 * 60 * 60 * 24 * 30.44, // One month in milliseconds (365.25 / 12)
              } : granularity === 'week' ? {
                stepSize: 1000 * 60 * 60 * 24 * 7, // One week in milliseconds
              } : granularity === 'day' ? {
                stepSize: 1000 * 60 * 60 * 24, // One day in milliseconds
              } : {}),
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
      credentials: 'include',
    });
    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || 'Request failed');
    }
    applyRange(payload.range);
    renderChart(payload, granularity);
    updateSummary(payload, byId('aggregation').value);
    byId('chart-status').textContent = '';
  }

  function handleMetricChange(event) {
    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
  }

  function handleGranularityChange(event) {
    byId('start').value = '';
    byId('end').value = '';
    byId('range-error').textContent = '';
    const granularity = byId('granularity').value;
    populateTimePeriods(granularity);
    setDateInputVisibility(false);

    // Calculate date range for the new granularity's default time period
    const periodLabel = byId('time-period').value;
    const dateRange = calculateDateRange(granularity, periodLabel);
    if (dateRange) {
      byId('start').value = dateRange.start;
      byId('end').value = dateRange.end;
    }

    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
  }

  function handleAggregationChange(event) {
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
    if (!error && start && end) {
      loadSeries().catch((error) => {
        byId('chart-status').textContent = error.message;
      });
    }
  }


  document.addEventListener('DOMContentLoaded', function () {
    populateMetrics();
    const granularity = byId('granularity').value;
    populateTimePeriods(granularity);
    setDateInputVisibility(false);
    byId('metric').addEventListener('change', handleMetricChange);
    byId('granularity').addEventListener('change', handleGranularityChange);
    byId('aggregation').addEventListener('change', handleAggregationChange);
    byId('time-period').addEventListener('change', handleTimePeriodChange);
    byId('start').addEventListener('change', handleDateInputChange);
    byId('end').addEventListener('change', handleDateInputChange);

    setupMenu();
    setupModals();

    // Calculate date range for initial default time period before loading
    const periodLabel = byId('time-period').value;
    const dateRange = calculateDateRange(granularity, periodLabel);
    if (dateRange) {
      byId('start').value = dateRange.start;
      byId('end').value = dateRange.end;
    }

    loadSeries().catch((error) => {
      byId('chart-status').textContent = error.message;
    });
  });
})();

function logout() {
  document.cookie = 'auth=; path=/; max-age=0';
  window.location.reload();
}

function setupMenu() {
  const menuToggle = document.getElementById('menu-toggle');
  const menu = document.getElementById('menu');

  function closeMenu() {
    menuToggle.classList.remove('active');
    menu.classList.remove('active');
  }

  menuToggle.addEventListener('click', () => {
    menuToggle.classList.toggle('active');
    menu.classList.toggle('active');
  });

  document.addEventListener('click', (event) => {
    if (!event.target.closest('.menu-container')) {
      closeMenu();
    }
  });

  document.getElementById('menu-logout').addEventListener('click', () => {
    closeMenu();
    logout();
  });

  document.getElementById('menu-edit-name').addEventListener('click', () => {
    closeMenu();
    openEditNameModal();
  });

  document.getElementById('menu-edit-height').addEventListener('click', () => {
    closeMenu();
    openEditHeightModal();
  });
}

function openEditNameModal() {
  closeAllModals();
  const modal = document.getElementById('edit-name-modal');
  modal.classList.add('active');
  const nameInput = document.getElementById('new-name');
  if (config.userName) {
    nameInput.value = config.userName;
  }
  nameInput.focus();
  nameInput.select();
}

function openEditHeightModal() {
  closeAllModals();
  const modal = document.getElementById('edit-height-modal');
  modal.classList.add('active');

  // Populate height fields from stored value (in mm)
  const heightMm = parseInt(config.userHeight) || 0;

  const feetInput = document.getElementById('height-feet');
  const inchesInput = document.getElementById('height-inches');
  const metersInput = document.getElementById('height-meters');

  // Clear all fields first
  feetInput.value = '';
  inchesInput.value = '';
  metersInput.value = '';

  if (heightMm > 0) {
    // Convert to imperial
    const feet = Math.floor(heightMm / 304.8);
    const inches = (heightMm % 304.8) / 25.4;

    feetInput.value = feet || '';
    inchesInput.value = inches > 0 ? inches.toFixed(1) : '';
    metersInput.value = (heightMm / 1000).toFixed(2);
  }

  feetInput.focus();
}

function closeAllModals() {
  document.getElementById('edit-name-modal').classList.remove('active');
  document.getElementById('edit-height-modal').classList.remove('active');
}

function setupModals() {
  const nameModal = document.getElementById('edit-name-modal');
  const heightModal = document.getElementById('edit-height-modal');

  nameModal.querySelector('.close').addEventListener('click', closeAllModals);
  heightModal.querySelector('.close').addEventListener('click', closeAllModals);

  nameModal.addEventListener('click', (event) => {
    if (event.target === nameModal) closeAllModals();
  });

  heightModal.addEventListener('click', (event) => {
    if (event.target === heightModal) closeAllModals();
  });

  document.getElementById('edit-name-form').addEventListener('submit', updateUserName);
  document.getElementById('edit-height-form').addEventListener('submit', updateUserHeight);

  // Height unit switching
  const unitRadios = document.querySelectorAll('input[name="height-unit"]');
  unitRadios.forEach(radio => {
    radio.addEventListener('change', (event) => {
      const imperialInputs = document.getElementById('imperial-inputs');
      const metricInputs = document.getElementById('metric-inputs');
      if (event.target.value === 'imperial') {
        imperialInputs.style.display = 'flex';
        metricInputs.style.display = 'none';
      } else {
        imperialInputs.style.display = 'none';
        metricInputs.style.display = 'flex';
      }
    });
  });
}

async function updateUserName(event) {
  event.preventDefault();
  const newName = document.getElementById('new-name').value.trim();
  if (!newName) return;

  try {
    const response = await fetch('api/auth.cgi', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'update_user', field: 'name', value: newName }),
      credentials: 'include',
    });
    const data = await response.json();
    if (data.success) {
      config.userName = newName;
      document.querySelector('.hero p').textContent = 'Welcome, ' + newName;
      closeAllModals();
    } else {
      alert(data.error || 'Failed to update name');
    }
  } catch (error) {
    alert('Error: ' + error.message);
  }
}

async function updateUserHeight(event) {
  event.preventDefault();

  const unit = document.querySelector('input[name="height-unit"]:checked').value;
  let heightMm;

  if (unit === 'imperial') {
    const feet = parseFloat(document.getElementById('height-feet').value) || 0;
    const inches = parseFloat(document.getElementById('height-inches').value) || 0;

    if (feet === 0 && inches === 0) {
      alert('Please enter a height');
      return;
    }

    heightMm = Math.round((feet * 304.8) + (inches * 25.4));
  } else {
    const meters = parseFloat(document.getElementById('height-meters').value);

    if (!meters || meters === 0) {
      alert('Please enter a height');
      return;
    }

    heightMm = Math.round(meters * 1000);
  }

  try {
    const response = await fetch('api/auth.cgi', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'update_user', field: 'height_mm', value: heightMm }),
      credentials: 'include',
    });
    const data = await response.json();
    if (data.success) {
      config.userHeight = heightMm;
      closeAllModals();
      alert('Height updated successfully');
    } else {
      alert(data.error || 'Failed to update height');
    }
  } catch (error) {
    alert('Error: ' + error.message);
  }
}
