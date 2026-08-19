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
    auto: [
      { label: 'Last 7 days', days: 7 },
      { label: 'Last Month', months: 1 },
      { label: 'Last 3 Months', months: 3 },
      { label: 'Last 6 months', months: 6, default: true },
      { label: 'Last Year', years: 1 },
      { label: 'Last 2 years', years: 2 },
      { label: 'Last 3 years', years: 3 },
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
      { label: 'All data', allData: true },
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
    let endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    if (granularity === 'week') {
      const dayOfWeek = endDate.getDay();
      endDate.setDate(endDate.getDate() - dayOfWeek);
    } else if (granularity === 'month') {
      endDate = new Date(endDate.getFullYear(), endDate.getMonth(), 31);
    } else if (granularity === 'year') {
      endDate = new Date(endDate.getFullYear(), 11, 31);
    }

    let startDate = new Date(endDate);

    if (period.days) {
      startDate.setDate(startDate.getDate() - period.days);
    } else if (period.weeks) {
      startDate.setDate(startDate.getDate() - (period.weeks - 1) * 7);
    } else if (period.months) {
      const targetMonth = startDate.getMonth() - period.months + 1;
      const targetYear = startDate.getFullYear() + Math.floor(targetMonth / 12);
      startDate.setDate(1);
      startDate.setFullYear(targetYear);
      startDate.setMonth((targetMonth % 12 + 12) % 12);
    } else if (period.years) {
      startDate.setFullYear(startDate.getFullYear() - (period.years - 1));
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
    if (granularity === 'auto') return null;
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
      const strong = document.createElement('strong');
      strong.textContent = label;
      const span = document.createElement('span');
      span.textContent = value;
      item.appendChild(strong);
      item.appendChild(span);
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

  function weekToTimestamp(dateStr) {
    const [year, month, day] = dateStr.split('-').map(Number);
    return Date.UTC(year, month - 1, day);
  }

  function yearToTimestamp(year) {
    // Parse year as a number to avoid type issues
    const yearNum = parseInt(year);
    // Use UTC to avoid timezone issues
    // Add 1 to the year to align with data positioning
    return Date.UTC(yearNum + 1, 0, 1);
  }

  function timestampToDate(value, granularity, labels, isEndDate) {
    if (granularity === 'month') {
      const index = Math.round(value);
      if (index >= 0 && index < labels.length) {
        return labels[index];
      }
      return null;
    } else if (granularity === 'year') {
      let closestYear = null;
      let closestDistance = Infinity;

      for (const label of labels) {
        const labelYear = parseInt(label);
        const labelTimestamp = yearToTimestamp(label);
        const distance = Math.abs(labelTimestamp - value);
        if (distance < closestDistance) {
          closestDistance = distance;
          closestYear = labelYear;
        }
      }

      if (closestYear === null) {
        return null;
      }

      if (isEndDate) {
        return `${closestYear}-12-31`;
      }
      return `${closestYear}-01-01`;
    } else if (granularity === 'day') {
      const date = new Date(value);
      const year = date.getUTCFullYear();
      const month = String(date.getUTCMonth() + 1).padStart(2, '0');
      const day = String(date.getUTCDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    } else if (granularity === 'week') {
      const date = new Date(value);
      const year = date.getUTCFullYear();
      const month = String(date.getUTCMonth() + 1).padStart(2, '0');
      const day = String(date.getUTCDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    } else {
      const date = new Date(value);
      const year = date.getUTCFullYear();
      const month = String(date.getUTCMonth() + 1).padStart(2, '0');
      const day = String(date.getUTCDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    }
  }

  function setupChartDragSelection(canvas, granularity, labels) {
    let isSelecting = false;
    let startPixelX = null;
    let endPixelX = null;
    let selectionOverlay = null;

    function createSelectionOverlay() {
      if (selectionOverlay) selectionOverlay.remove();
      selectionOverlay = document.createElement('div');
      selectionOverlay.setAttribute('data-selection-overlay', 'true');
      selectionOverlay.style.position = 'absolute';
      selectionOverlay.style.pointerEvents = 'none';
      selectionOverlay.style.zIndex = '10';
      canvas.parentElement.style.position = 'relative';
      canvas.parentElement.appendChild(selectionOverlay);
      return selectionOverlay;
    }

    function updateSelectionOverlay(startX, endX) {
      if (!selectionOverlay) return;
      const canvasRect = canvas.getBoundingClientRect();
      const parentRect = canvas.parentElement.getBoundingClientRect();
      const left = Math.min(startX, endX);
      const width = Math.abs(endX - startX);
      const top = canvasRect.top - parentRect.top;
      selectionOverlay.style.top = top + 'px';
      selectionOverlay.style.left = left + 'px';
      selectionOverlay.style.width = width + 'px';
      selectionOverlay.style.height = canvasRect.height + 'px';
      selectionOverlay.style.backgroundColor = 'rgba(100, 150, 255, 0.2)';
      selectionOverlay.style.border = '2px solid rgba(100, 150, 255, 0.8)';
      selectionOverlay.style.cursor = 'col-resize';
    }

    function onDocumentMouseMove(e) {
      if (!isSelecting) return;
      const canvasRect = canvas.getBoundingClientRect();
      endPixelX = e.clientX - canvasRect.left;
      updateSelectionOverlay(startPixelX, endPixelX);
    }

    function onDocumentMouseUp(e) {
      if (!isSelecting) return;
      isSelecting = false;
      const canvasRect = canvas.getBoundingClientRect();
      endPixelX = e.clientX - canvasRect.left;
      canvas.style.cursor = 'default';
      document.removeEventListener('mousemove', onDocumentMouseMove);
      document.removeEventListener('mouseup', onDocumentMouseUp);

      if (selectionOverlay) {
        selectionOverlay.remove();
        selectionOverlay = null;
      }

      const minPixelX = Math.min(startPixelX, endPixelX);
      const maxPixelX = Math.max(startPixelX, endPixelX);

      if (Math.abs(endPixelX - startPixelX) < 10) return;

      const xScale = chart.scales.x;
      const minValue = xScale.getValueForPixel(Math.max(0, minPixelX));
      const maxValue = xScale.getValueForPixel(Math.min(canvas.offsetWidth, maxPixelX));

      const startDate = timestampToDate(minValue, granularity, labels, false);
      const endDate = timestampToDate(maxValue, granularity, labels, true);

      if (!startDate || !endDate) return;

      byId('time-period').value = 'Custom';
      const periodOption = Array.from(byId('time-period').options).find(opt => opt.dataset.custom === 'true');
      if (periodOption) {
        byId('time-period').value = periodOption.value;
      }

      byId('start').value = startDate;
      byId('end').value = endDate;
      setDateInputVisibility(true);
      byId('range-error').textContent = '';

      const error = validateSpan(granularity, startDate, endDate);
      byId('range-error').textContent = error || '';
      if (!error) {
        updateUrlHash();
      }
    }

    canvas.addEventListener('mousedown', (e) => {
      isSelecting = true;
      const canvasRect = canvas.getBoundingClientRect();
      startPixelX = e.clientX - canvasRect.left;
      endPixelX = startPixelX;
      createSelectionOverlay();
      updateSelectionOverlay(startPixelX, endPixelX);
      canvas.style.cursor = 'col-resize';
      document.addEventListener('mousemove', onDocumentMouseMove);
      document.addEventListener('mouseup', onDocumentMouseUp);
    });
  }

  function renderChart(payload, granularity) {
    let context = byId('health-chart');
    if (chart) {
      chart.destroy();
    }

    const parent = context.parentElement;

    const existingOverlays = parent.querySelectorAll('[data-selection-overlay]');
    existingOverlays.forEach(overlay => overlay.remove());

    const newCanvas = context.cloneNode(true);
    newCanvas.dataset.dragSetup = '';
    context.replaceWith(newCanvas);
    context = newCanvas;

    let labels = payload.labels;
    let datasets = payload.datasets;

    // For month granularity, fill in missing months with null values
    if (granularity === 'month' && labels.length > 1) {
      const allMonths = [];

      // Parse start and end dates directly from strings to avoid timezone issues
      const [startYear, startMonth] = labels[0].split('-').map(Number);
      const [endYear, endMonth] = labels[labels.length - 1].split('-').map(Number);

      // Generate all months in the range
      let year = startYear;
      let month = startMonth;
      while (year < endYear || (year === endYear && month <= endMonth)) {
        const dateStr = `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-01`;
        allMonths.push(dateStr);
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
      }

      // Create expanded datasets with nulls for missing months
      datasets = datasets.map(dataset => ({
        ...dataset,
        data: allMonths.map((month, i) => {
          const originalIndex = labels.indexOf(month);
          return originalIndex >= 0 ? dataset.data[originalIndex] : null;
        }),
      }));

      labels = allMonths;
    }

    let converter, labelFormatter;
    if (granularity === 'year') {
      converter = yearToTimestamp;
      labelFormatter = (value) => new Date(value).getFullYear().toString();
    } else if (granularity === 'month') {
      converter = (label, index) => index;
      labelFormatter = (value) => {
        const index = Math.round(value);
        if (index >= 0 && index < labels.length) {
          const labelStr = labels[index]; // "2026-03-01"
          const [year, month, day] = labelStr.split('-').map(Number);
          const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return `${monthNames[month - 1]} ${year}`;
        }
        return '';
      };
    } else if (granularity === 'day') {
      converter = dayToTimestamp;
      const years = labels.map(label => {
        const [year] = label.split('-').map(Number);
        return year;
      });
      const spansMultipleYears = Math.min(...years) !== Math.max(...years);
      if (spansMultipleYears) {
        labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
      } else {
        labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      }
    } else if (granularity === 'week') {
      converter = weekToTimestamp;
      const years = labels.map(label => {
        const [year] = label.split('-').map(Number);
        return year;
      });
      const spansMultipleYears = Math.min(...years) !== Math.max(...years);
      if (spansMultipleYears) {
        labelFormatter = (value) => {
          const date = new Date(value);
          const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return `${monthNames[date.getUTCMonth()]} ${date.getUTCDate()}, ${date.getUTCFullYear()}`;
        };
      } else {
        labelFormatter = (value) => {
          const date = new Date(value);
          const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return `${monthNames[date.getUTCMonth()]} ${date.getUTCDate()}`;
        };
      }
    } else {
      converter = dateToTimestamp;

      // Check if data spans multiple years
      const years = labels.map(label => new Date(label).getFullYear());
      const spansMultipleYears = Math.min(...years) !== Math.max(...years);

      if (spansMultipleYears) {
        labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
      } else {
        labelFormatter = (value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      }
    }

    timestamps = labels.map((label, index) => converter(label, index));
    let minTime = Math.min(...timestamps);
    let maxTime = Math.max(...timestamps);

    // When there's only one data point, add padding so the axis renders properly
    if (minTime === maxTime) {
      let padding;
      if (granularity === 'year') {
        padding = 1000 * 60 * 60 * 24 * 365.25; // 1 year
      } else if (granularity === 'month') {
        padding = 0.5; // 0.5 index units for month
      } else if (granularity === 'week') {
        padding = 1000 * 60 * 60 * 24 * 7; // 1 week
      } else {
        padding = 1000 * 60 * 60 * 24; // 1 day
      }
      minTime -= padding;
      maxTime += padding;
    }

    const transformedDatasets = datasets.map(dataset => ({
      ...dataset,
      spanGaps: granularity === 'month',
      data: labels.map((label, i) => ({
        x: converter(label, i),
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
                stepSize: 1,
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

    setupChartDragSelection(context, granularity, labels);
  }

  async function loadSeries() {
    try {
      const start = byId('start').value;
      const end = byId('end').value;
      const granularity = byId('granularity').value;
      const params = new URLSearchParams({
        metric: byId('metric').value,
        aggregation: byId('aggregation').value,
      });
      if (granularity !== 'auto') {
        params.append('granularity', granularity);
      }
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
      const renderGranularity = granularity === 'auto' ? payload.granularity : granularity;
      renderChart(payload, renderGranularity);
      updateSummary(payload, byId('aggregation').value);
      byId('chart-status').textContent = '';
    } catch (error) {
      if (chart) {
        chart.destroy();
        chart = null;
      }
      byId('chart-status').textContent = error.message;
    }
  }

  function handleMetricChange(event) {
    updateUrlHash();
    loadSeries();
  }

  function handleGranularityChange(event) {
    const granularity = byId('granularity').value;
    const prevStart = byId('start').value;
    const prevEnd = byId('end').value;

    byId('range-error').textContent = '';
    populateTimePeriods(granularity);
    setDateInputVisibility(false);

    if (prevStart && prevEnd) {
      byId('start').value = prevStart;
      byId('end').value = prevEnd;
      byId('time-period').value = 'Custom';
      const periodOption = Array.from(byId('time-period').options).find(opt => opt.dataset.custom === 'true');
      if (periodOption) {
        byId('time-period').value = periodOption.value;
      }
      setDateInputVisibility(true);
    } else {
      const periodLabel = byId('time-period').value;
      const dateRange = calculateDateRange(granularity, periodLabel);
      if (dateRange) {
        byId('start').value = dateRange.start;
        byId('end').value = dateRange.end;
      }
    }

    updateUrlHash();
    loadSeries();
  }

  function handleAggregationChange(event) {
    updateUrlHash();
    loadSeries();
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
      } else {
        byId('start').value = '';
        byId('end').value = '';
      }
      setDateInputVisibility(false);
      byId('range-error').textContent = '';
      updateUrlHash();
      loadSeries();
    }
  }

  function handleDateInputChange(event) {
    const granularity = byId('granularity').value;
    const start = byId('start').value;
    const end = byId('end').value;
    const error = validateSpan(granularity, start, end);
    byId('range-error').textContent = error || '';
    if (!error && start && end) {
      updateUrlHash();
      loadSeries();
    }
  }

  function updateUrlHash() {
    const metric = byId('metric').value;
    const granularity = byId('granularity').value;
    const aggregation = byId('aggregation').value;
    const timePeriod = byId('time-period').value;
    const start = byId('start').value;
    const end = byId('end').value;

    const params = new URLSearchParams();
    params.set('metric', metric);
    params.set('granularity', granularity);
    params.set('aggregation', aggregation);

    const periodElement = byId('time-period').selectedOptions[0];
    const isCustom = periodElement && periodElement.dataset.custom === 'true';

    if (isCustom) {
      if (start) params.set('start', start);
      if (end) params.set('end', end);
    } else {
      params.set('period', timePeriod);
    }

    window.location.hash = params.toString();
  }

  function restoreStateFromHash() {
    const hash = window.location.hash.slice(1);
    if (!hash) return false;

    const params = new URLSearchParams(hash);
    const metric = params.get('metric');
    const granularity = params.get('granularity');
    const aggregation = params.get('aggregation');
    const period = params.get('period');
    const start = params.get('start');
    const end = params.get('end');

    let stateChanged = false;

    if (metric && byId('metric').value !== metric) {
      byId('metric').value = metric;
      stateChanged = true;
    }

    if (granularity && byId('granularity').value !== granularity) {
      byId('granularity').value = granularity;
      populateTimePeriods(granularity);
      stateChanged = true;
    }

    if (aggregation && byId('aggregation').value !== aggregation) {
      byId('aggregation').value = aggregation;
      stateChanged = true;
    }

    if (period) {
      const periodOption = Array.from(byId('time-period').options).find(opt => opt.value === period);
      if (periodOption) {
        byId('time-period').value = period;
        byId('start').value = '';
        byId('end').value = '';
        setDateInputVisibility(false);
        const dateRange = calculateDateRange(granularity, period);
        if (dateRange) {
          byId('start').value = dateRange.start;
          byId('end').value = dateRange.end;
        }
        stateChanged = true;
      }
    } else if (start && end) {
      byId('time-period').value = 'Custom';
      const periodOption = Array.from(byId('time-period').options).find(opt => opt.dataset.custom === 'true');
      if (periodOption) {
        byId('time-period').value = periodOption.value;
      }
      byId('start').value = start;
      byId('end').value = end;
      setDateInputVisibility(true);
      stateChanged = true;
    }

    return stateChanged;
  }


  function handleHashChange() {
    const stateChanged = restoreStateFromHash();
    if (stateChanged) {
      loadSeries();
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

    window.addEventListener('hashchange', handleHashChange);

    setupMenu();
    setupModals();

    const hasHashState = restoreStateFromHash();

    if (!hasHashState) {
      // Calculate date range for initial default time period before loading
      const periodLabel = byId('time-period').value;
      const dateRange = calculateDateRange(granularity, periodLabel);
      if (dateRange) {
        byId('start').value = dateRange.start;
        byId('end').value = dateRange.end;
      }
    }

    loadSeries();
  });
})();

function logout() {
  fetch('api/auth.cgi', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ action: 'logout' }),
    credentials: 'include',
  }).then(() => {
    window.location.reload();
  }).catch((err) => {
    console.error('Logout error:', err);
    window.location.reload();
  });
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

  document.getElementById('menu-edit-user').addEventListener('click', () => {
    closeMenu();
    openEditUserModal();
  });
}

function openEditUserModal() {
  closeAllModals();
  const modal = document.getElementById('edit-user-modal');
  modal.classList.add('active');

  // Clear and populate all form fields
  const nameInput = document.getElementById('user-name');
  nameInput.value = config.userName || '';

  const usernameInput = document.getElementById('user-username');
  usernameInput.value = config.userUsername || '';

  const initialsInput = document.getElementById('user-initials');
  initialsInput.value = config.userInitials || '';

  const genderSelect = document.getElementById('user-gender');
  const gender = config.userGender || 'unknown';
  genderSelect.value = gender;

  const unitPreferenceSelect = document.getElementById('unit-preference');
  const unitPreference = config.userUnitPreference || 'imperial';
  unitPreferenceSelect.value = unitPreference;

  // Clear height fields
  const feetInput = document.getElementById('height-feet');
  const inchesInput = document.getElementById('height-inches');
  const metersInput = document.getElementById('height-meters');
  feetInput.value = '';
  inchesInput.value = '';
  metersInput.value = '';

  // Show/hide height inputs based on unit preference
  const imperialInputs = document.getElementById('imperial-inputs');
  const metricInputs = document.getElementById('metric-inputs');
  if (unitPreference === 'metric') {
    imperialInputs.style.display = 'none';
    metricInputs.style.display = 'flex';
  } else {
    imperialInputs.style.display = 'flex';
    metricInputs.style.display = 'none';
  }

  // Populate height fields from stored value (in mm)
  const heightMm = parseInt(config.userHeight) || 0;
  if (heightMm > 0) {
    // Convert to imperial
    const feet = Math.floor(heightMm / 304.8);
    const inches = (heightMm % 304.8) / 25.4;

    feetInput.value = feet || '';
    inchesInput.value = inches > 0 ? inches.toFixed(1) : '';
    metersInput.value = (heightMm / 1000).toFixed(2);
  }

  nameInput.focus();
  nameInput.select();
}

function closeAllModals() {
  document.getElementById('edit-user-modal').classList.remove('active');
}

function setupModals() {
  const userModal = document.getElementById('edit-user-modal');

  userModal.querySelector('.close').addEventListener('click', closeAllModals);

  userModal.addEventListener('click', (event) => {
    if (event.target === userModal) closeAllModals();
  });

  document.getElementById('edit-user-form').addEventListener('submit', updateUserProfile);

  // Unit preference switching
  const unitPreferenceSelect = document.getElementById('unit-preference');
  unitPreferenceSelect.addEventListener('change', (event) => {
    const imperialInputs = document.getElementById('imperial-inputs');
    const metricInputs = document.getElementById('metric-inputs');
    if (event.target.value === 'metric') {
      imperialInputs.style.display = 'none';
      metricInputs.style.display = 'flex';
    } else {
      imperialInputs.style.display = 'flex';
      metricInputs.style.display = 'none';
    }
  });
}

async function updateUserProfile(event) {
  event.preventDefault();

  const newName = document.getElementById('user-name').value.trim();
  const userName = document.getElementById('user-username').value.trim();
  const initials = document.getElementById('user-initials').value.trim();
  const genderValue = document.getElementById('user-gender').value;
  const unitPreference = document.getElementById('unit-preference').value;

  if (!newName) {
    alert('Please enter a name');
    return;
  }

  // Convert gender from display format (male/female) to storage format (M/F)
  const genderDbValue = genderValue === 'male' ? 'M' : genderValue === 'female' ? 'F' : 'unknown';

  let heightMm = null;

  if (unitPreference === 'imperial') {
    const feet = parseFloat(document.getElementById('height-feet').value) || 0;
    const inches = parseFloat(document.getElementById('height-inches').value) || 0;

    if (feet > 0 || inches > 0) {
      heightMm = Math.round((feet * 304.8) + (inches * 25.4));
    }
  } else {
    const meters = parseFloat(document.getElementById('height-meters').value);
    if (meters && meters > 0) {
      heightMm = Math.round(meters * 1000);
    }
  }

  try {
    const updates = [
      { field: 'name', value: newName },
      { field: 'gender', value: genderDbValue },
      { field: 'unit_preference', value: unitPreference },
    ];

    if (heightMm !== null) {
      updates.push({ field: 'height_mm', value: heightMm });
    }

    if (userName) {
      updates.push({ field: 'user_name', value: userName });
    }

    if (initials) {
      updates.push({ field: 'initials', value: initials });
    }

    for (const update of updates) {
      const response = await fetch('api/auth.cgi', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'update_user', field: update.field, value: update.value }),
        credentials: 'include',
      });
      const data = await response.json();
      if (!data.success) {
        alert(data.error || `Failed to update ${update.field}`);
        return;
      }
    }

    config.userName = newName;
    config.userGender = genderValue;
    config.userUnitPreference = unitPreference;
    config.userUsername = userName;
    config.userInitials = initials;
    if (heightMm !== null) {
      config.userHeight = heightMm;
    }

    document.querySelector('.hero p').textContent = 'Welcome, ' + newName;
    closeAllModals();
  } catch (error) {
    alert('Error: ' + error.message);
  }
}
