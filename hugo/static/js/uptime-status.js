(function() {
  'use strict';

  const CONFIG = {
    checkInterval: 1 * 60 * 1000, // 1 minute
    historyRetention: 7 * 24 * 60 * 60 * 1000, // 7 days
    storageKey: 'franklyn-uptime-history',
    services: [
      {
        id: 'franklyn-website',
        name: 'Website (Hugo)',
        url: 'https://franklyn.htl-leonding.ac.at/',
        path: '/'
      },
      {
        id: 'franklyn-proctor',
        name: 'Proctor',
        url: 'https://franklyn.htl-leonding.ac.at/proctor',
        path: '/proctor'
      },
      {
        id: 'franklyn-api',
        name: 'API',
        url: 'https://franklyn.htl-leonding.ac.at/api',
        path: '/api'
      },
      {
        id: 'franklyn-repo',
        name: 'APT Repository',
        url: 'https://franklyn.htl-leonding.ac.at/repo',
        path: '/repo'
      },
      {
        id: 'edufs-main',
        name: 'edufs Main',
        url: 'https://edufs.edu.htl-leonding.ac.at/',
        path: '/'
      }
    ]
  };

  let history = loadHistory();
  let checkIntervalId = null;

  function loadHistory() {
    try {
      const stored = localStorage.getItem(CONFIG.storageKey);
      if (stored) {
        const data = JSON.parse(stored);
        const cutoff = Date.now() - CONFIG.historyRetention;
        Object.keys(data).forEach(serviceId => {
          data[serviceId] = data[serviceId].filter(entry => entry.timestamp > cutoff);
        });
        return data;
      }
    } catch (e) {
      console.error('Error loading history:', e);
    }
    return {};
  }

  function saveHistory() {
    try {
      localStorage.setItem(CONFIG.storageKey, JSON.stringify(history));
    } catch (e) {
      console.error('Error saving history:', e);
    }
  }

  async function checkService(service) {
    const startTime = performance.now();
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout

      const response = await fetch(service.url, {
        method: 'HEAD',
        mode: 'no-cors',
        cache: 'no-store',
        signal: controller.signal
      });

      clearTimeout(timeoutId);
      const endTime = performance.now();
      const responseTime = Math.round(endTime - startTime);

      return {
        status: 'up',
        responseTime: responseTime,
        timestamp: Date.now()
      };
    } catch (error) {
      const endTime = performance.now();
      return {
        status: 'down',
        responseTime: Math.round(endTime - startTime),
        timestamp: Date.now(),
        error: error.message
      };
    }
  }

  async function checkAllServices() {
    const results = {};
    
    await Promise.all(CONFIG.services.map(async (service) => {
      const result = await checkService(service);
      results[service.id] = result;
      
      if (!history[service.id]) {
        history[service.id] = [];
      }
      history[service.id].push({
        timestamp: result.timestamp,
        status: result.status,
        responseTime: result.responseTime
      });
      
      updateServiceUI(service.id, result);
    }));

    saveHistory();
    updateOverallStatus(results);
    updateHistoryUI();
    updateIncidentLog();
    
    return results;
  }

  function updateServiceUI(serviceId, result) {
    const serviceItem = document.querySelector(`.service-item[data-service="${serviceId}"]`);
    if (!serviceItem) return;

    const indicator = serviceItem.querySelector('.service-indicator');
    const responseTime = serviceItem.querySelector('.response-time');
    const lastChecked = serviceItem.querySelector('.last-checked');

    serviceItem.classList.remove('status-up', 'status-down', 'status-checking');
    serviceItem.classList.add(`status-${result.status}`);

    responseTime.textContent = `${result.responseTime}ms`;

    const time = new Date(result.timestamp);
    lastChecked.textContent = `Last checked: ${time.toLocaleTimeString()}`;
  }

  function updateOverallStatus(results) {
    const banner = document.getElementById('overall-status');
    if (!banner) return;

    const allUp = Object.values(results).every(r => r.status === 'up');
    const allDown = Object.values(results).every(r => r.status === 'down');
    const someDown = Object.values(results).some(r => r.status === 'down');

    const icon = banner.querySelector('.status-icon');
    const text = banner.querySelector('.status-text');

    banner.classList.remove('status-operational', 'status-degraded', 'status-outage');

    if (allUp) {
      banner.classList.add('status-operational');
      icon.textContent = '✓';
      text.textContent = 'All Systems Operational';
    } else if (allDown) {
      banner.classList.add('status-outage');
      icon.textContent = '✕';
      text.textContent = 'Major Outage';
    } else if (someDown) {
      banner.classList.add('status-degraded');
      icon.textContent = '!';
      text.textContent = 'Partial System Outage';
    }
  }

  function updateHistoryUI() {
    const timeframeSelect = document.getElementById('history-timeframe');
    const hours = parseInt(timeframeSelect?.value || 24);
    const cutoff = Date.now() - (hours * 60 * 60 * 1000);

    CONFIG.services.forEach(service => {
      const historyItem = document.querySelector(`.history-item[data-service="${service.id}"]`);
      if (!historyItem) return;

      const timeline = historyItem.querySelector('.history-timeline');
      const uptimeSpan = historyItem.querySelector('.history-uptime');
      const serviceHistory = (history[service.id] || []).filter(e => e.timestamp > cutoff);

      if (serviceHistory.length > 0) {
        const upCount = serviceHistory.filter(e => e.status === 'up').length;
        const uptimePercent = ((upCount / serviceHistory.length) * 100).toFixed(2);
        uptimeSpan.textContent = `${uptimePercent}% uptime`;
      } else {
        uptimeSpan.textContent = 'No data';
      }

      renderTimeline(timeline, serviceHistory, hours);
    });
  }

  function renderTimeline(container, entries, hours) {
    container.innerHTML = '';
    
    if (entries.length === 0) {
      container.innerHTML = '<span class="no-data">No historical data available</span>';
      return;
    }

    const slotCount = Math.min(48, hours * 2);
    const slotDuration = (hours * 60 * 60 * 1000) / slotCount;
    const now = Date.now();
    const startTime = now - (hours * 60 * 60 * 1000);

    for (let i = 0; i < slotCount; i++) {
      const slotStart = startTime + (i * slotDuration);
      const slotEnd = slotStart + slotDuration;
      
      const slotEntries = entries.filter(e => e.timestamp >= slotStart && e.timestamp < slotEnd);
      
      const block = document.createElement('div');
      block.className = 'timeline-block';
      
      if (slotEntries.length === 0) {
        block.classList.add('no-data');
        block.title = `${new Date(slotStart).toLocaleString()} - No data`;
      } else {
        const upCount = slotEntries.filter(e => e.status === 'up').length;
        const ratio = upCount / slotEntries.length;
        
        if (ratio === 1) {
          block.classList.add('up');
        } else if (ratio >= 0.5) {
          block.classList.add('degraded');
        } else {
          block.classList.add('down');
        }
        
        const uptimePercent = (ratio * 100).toFixed(0);
        block.title = `${new Date(slotStart).toLocaleString()}\n${uptimePercent}% uptime (${slotEntries.length} checks)`;
      }
      
      container.appendChild(block);
    }
  }

  function updateIncidentLog() {
    const incidentLog = document.getElementById('incident-log');
    if (!incidentLog) return;

    const incidents = [];
    const now = Date.now();
    const last24h = now - (24 * 60 * 60 * 1000);

    CONFIG.services.forEach(service => {
      const serviceHistory = (history[service.id] || []).filter(e => e.timestamp > last24h);
      
      let inIncident = false;
      let incidentStart = null;
      
      serviceHistory.forEach((entry, index) => {
        if (entry.status === 'down' && !inIncident) {
          inIncident = true;
          incidentStart = entry.timestamp;
        } else if (entry.status === 'up' && inIncident) {
          incidents.push({
            service: service.name,
            start: incidentStart,
            end: entry.timestamp,
            duration: entry.timestamp - incidentStart
          });
          inIncident = false;
          incidentStart = null;
        }
      });
      
      if (inIncident && serviceHistory.length > 0) {
        incidents.push({
          service: service.name,
          start: incidentStart,
          end: null,
          duration: now - incidentStart,
          ongoing: true
        });
      }
    });

    incidents.sort((a, b) => b.start - a.start);

    if (incidents.length === 0) {
      incidentLog.innerHTML = '<p class="no-incidents">No incidents recorded in the last 24 hours</p>';
    } else {
      incidentLog.innerHTML = incidents.slice(0, 10).map(incident => {
        const startTime = new Date(incident.start).toLocaleString();
        const endTime = incident.ongoing ? 'Ongoing' : new Date(incident.end).toLocaleString();
        const duration = formatDuration(incident.duration);
        
        return `
          <div class="incident ${incident.ongoing ? 'ongoing' : 'resolved'}">
            <div class="incident-header">
              <span class="incident-service">${incident.service}</span>
              <span class="incident-badge">${incident.ongoing ? 'Ongoing' : 'Resolved'}</span>
            </div>
            <div class="incident-details">
              <span class="incident-time">Started: ${startTime}</span>
              ${!incident.ongoing ? `<span class="incident-time">Ended: ${endTime}</span>` : ''}
              <span class="incident-duration">Duration: ${duration}</span>
            </div>
          </div>
        `;
      }).join('');
    }
  }

  function formatDuration(ms) {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    
    if (hours > 0) {
      return `${hours}h ${minutes % 60}m`;
    } else if (minutes > 0) {
      return `${minutes}m ${seconds % 60}s`;
    } else {
      return `${seconds}s`;
    }
  }

  function init() {
    const timeframeSelect = document.getElementById('history-timeframe');
    if (timeframeSelect) {
      timeframeSelect.addEventListener('change', updateHistoryUI);
    }

    checkAllServices();

    checkIntervalId = setInterval(checkAllServices, CONFIG.checkInterval);

    updateHistoryUI();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
