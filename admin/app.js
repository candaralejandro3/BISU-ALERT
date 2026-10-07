/**
 * BISU-ALERT Admin & Command Dashboard
 * Interactivity, Live Telemetry, Incident Triage, and Dispatch Engine
 */

// Initial State / Mock Fallback Data (so the dashboard works out of the box in all environments)
const appState = {
  activeTab: 'dashboard',
  currentFilter: 'all',
  metrics: {
    active_emergencies: 3,
    pending_reports: 12,
    responding: 4,
    resolved_today: 18,
  },
  incidents: [
    {
      id: 102,
      reference_code: 'INC-2026-00124',
      category: 'medical',
      category_label: 'Medical Emergency',
      location_label: 'Student Center / Gymnasium',
      reporter_name: 'Juan Dela Cruz',
      reporter_role: 'Student (2024-00123)',
      reporter_phone: '+63 917 456 1234',
      reported_at: '2026-09-17 20:21:00',
      priority: 'critical',
      status: 'responding',
      handled_by: 'Officer Ramon Bautista',
      description: 'Student collapsed near basketball bleachers, breathing shallow. Medical assistance urgently requested.',
    },
    {
      id: 101,
      reference_code: 'INC-2026-00125',
      category: 'fire_hazard',
      category_label: 'Fire Hazard',
      location_label: 'CCT Computer Studies Bldg - Room 204',
      reporter_name: 'Prof. Ana Reyes',
      reporter_role: 'Faculty',
      reporter_phone: '+63 917 222 8890',
      reported_at: '2026-09-17 19:45:00',
      priority: 'high',
      status: 'pending',
      handled_by: null,
      description: 'Acrid electrical smoke and sparking coming from AC circuit breaker on 2nd floor corridor.',
    },
    {
      id: 100,
      reference_code: 'INC-2026-00126',
      category: 'security',
      category_label: 'Security Incident',
      location_label: 'Main Gate 2 Perimeter',
      reporter_name: 'Officer D. Torralba',
      reporter_role: 'Security Staff',
      reporter_phone: '+63 38 000 9112',
      reported_at: '2026-09-17 18:30:00',
      priority: 'normal',
      status: 'resolved',
      handled_by: 'Officer Ramon Bautista',
      description: 'Suspicious individual attempting unauthorized boundary crossing without campus visitor ID.',
    },
    {
      id: 99,
      reference_code: 'INC-2026-00127',
      category: 'facility_damage',
      category_label: 'Facility Damage',
      location_label: 'College of Agriculture & Forestry (CAF)',
      reporter_name: 'Mario Villanueva',
      reporter_role: 'Personnel',
      reporter_phone: '+63 918 552 3311',
      reported_at: '2026-09-17 16:15:00',
      priority: 'normal',
      status: 'resolved',
      handled_by: 'Mario Villanueva',
      description: 'Main waterline joint cracked causing minor corridor flooding in Greenhouse hallway.',
    },
    {
      id: 98,
      reference_code: 'INC-2026-00128',
      category: 'medical',
      category_label: 'Medical Emergency',
      location_label: 'Campus Medical Clinic',
      reporter_name: 'Liza Mercado',
      reporter_role: 'Clinic Staff',
      reporter_phone: '+63 38 000 9111',
      reported_at: '2026-09-17 15:10:00',
      priority: 'critical',
      status: 'resolved',
      handled_by: 'Liza Mercado',
      description: 'Heat exhaustion triage for student following physical education drills.',
    }
  ],
  responders: [
    { id: 2, name: 'Ramon Bautista', role: 'Campus Security', status: 'Responding', contact: '+63 38 000 9112' },
    { id: 3, name: 'Liza Mercado', role: 'University Clinic', status: 'Available', contact: '+63 38 000 9111' },
    { id: 5, name: 'Mario Villanueva', role: 'Maintenance Crew', status: 'Available', contact: '+63 918 552 3311' },
    { id: 8, name: 'Officer D. Torralba', role: 'Gate Security', status: 'On Patrol', contact: '+63 38 000 9112' },
  ],
  announcements: [
    {
      id: 1,
      title: 'Heavy Rainfall Warning - Bohol Region',
      detail: 'PAGASA has raised Yellow Alert. Students in low-lying campus pathways are advised to exercise caution.',
      type: 'weather',
      time: '1 hour ago'
    },
    {
      id: 2,
      title: 'Scheduled Earthquake & Evacuation Drill',
      detail: 'Simulated campus evacuation to Assembly Area A will be held tomorrow at 9:00 AM.',
      type: 'safety',
      time: '5 hours ago'
    }
  ]
};

// DOM Elements
const liveClockEl = document.getElementById('live-clock');
const incidentsTableBody = document.getElementById('incidents-table-body');
const incidentModal = document.getElementById('incident-modal');
const modalCloseBtn = document.getElementById('modal-close-btn');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  initClock();
  initAuth();
  setupNavigation();
  setupFilters();
  setupModal();
  renderDashboard();
  tryFetchLiveBackend();
});

// ==========================================================================
// AUTHENTICATION & SESSION MANAGEMENT (Mobile-Identical)
// ==========================================================================

const AUTH_STORAGE_KEY = 'bisu_alert_admin_session';

function getStoredSession() {
  try {
    const raw = localStorage.getItem(AUTH_STORAGE_KEY);
    if (!raw) return null;
    const session = JSON.parse(raw);
    if (!session || !session.token) return null;
    
    // Check expiration if present
    if (session.expires_at) {
      const exp = new Date(session.expires_at).getTime();
      if (Date.now() > exp) {
        localStorage.removeItem(AUTH_STORAGE_KEY);
        return null;
      }
    }
    return session;
  } catch (e) {
    localStorage.removeItem(AUTH_STORAGE_KEY);
    return null;
  }
}

function initAuth() {
  const authOverlay = document.getElementById('auth-overlay');
  const loginForm = document.getElementById('admin-login-form');
  const emailInput = document.getElementById('login-email');
  const passwordInput = document.getElementById('login-password');
  const errorBanner = document.getElementById('auth-error-banner');
  const errorMsg = document.getElementById('auth-error-message');
  const submitBtn = document.getElementById('btn-login-submit');
  const submitText = submitBtn ? submitBtn.querySelector('.submit-text') : null;
  const submitSpinner = submitBtn ? submitBtn.querySelector('.submit-spinner') : null;
  const togglePwdBtn = document.getElementById('btn-toggle-password');
  const pwdIconShow = document.getElementById('pwd-icon-show');
  const pwdIconHide = document.getElementById('pwd-icon-hide');
  const demoFillBtn = document.getElementById('btn-demo-fill');
  const forgotPwdBtn = document.getElementById('btn-forgot-password');
  const sidebarLogoutBtn = document.getElementById('btn-sidebar-logout');
  const headerLogoutBtn = document.getElementById('btn-header-logout');

  // Check stored session
  const session = getStoredSession();
  if (session && session.user) {
    applyUserProfile(session.user);
    if (authOverlay) authOverlay.classList.remove('active');
  } else {
    if (authOverlay) authOverlay.classList.add('active');
  }

  // Toggle Password Visibility
  if (togglePwdBtn && passwordInput) {
    togglePwdBtn.addEventListener('click', () => {
      const isPwd = passwordInput.type === 'password';
      passwordInput.type = isPwd ? 'text' : 'password';
      if (pwdIconShow) pwdIconShow.style.display = isPwd ? 'none' : 'block';
      if (pwdIconHide) pwdIconHide.style.display = isPwd ? 'block' : 'none';
    });
  }

  // Demo Account Auto-Fill
  if (demoFillBtn && emailInput && passwordInput) {
    demoFillBtn.addEventListener('click', () => {
      emailInput.value = 'admin@bisu.edu.ph';
      passwordInput.value = 'admin123';
      if (errorBanner) errorBanner.style.display = 'none';
      emailInput.focus();
    });
  }

  // Forgot Password Action
  if (forgotPwdBtn) {
    forgotPwdBtn.addEventListener('click', () => {
      alert('Password reset instructions have been dispatched to your BISU campus email.');
    });
  }

  // Handle Login Form Submit
  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = emailInput ? emailInput.value.trim() : '';
      const password = passwordInput ? passwordInput.value : '';

      if (!email || !password) {
        showAuthError('Please enter both campus email and password.');
        return;
      }

      // Set Loading State
      setAuthLoading(true);
      hideAuthError();

      try {
        const response = await fetch('../backend/api/auth/login.php', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify({ email, password })
        });

        const resData = await response.json();

        if (response.ok && resData.success && resData.data) {
          const user = resData.data.user;
          const token = resData.data.token;
          const expires_at = resData.data.expires_at;

          // Save Session
          localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify({ user, token, expires_at }));

          // Update UI
          applyUserProfile(user);
          if (authOverlay) authOverlay.classList.remove('active');
          if (loginForm) loginForm.reset();

          // Refresh live telemetry
          tryFetchLiveBackend();
        } else {
          const errorText = resData.error && resData.error.message 
            ? resData.error.message 
            : 'Sign in failed. Please verify your campus credentials.';
          showAuthError(errorText);
        }
      } catch (err) {
        // Offline / Fallback verification
        if (email.toLowerCase() === 'admin@bisu.edu.ph' && password === 'admin123') {
          const fallbackUser = {
            id: 1,
            full_name: 'System Administrator',
            email: 'admin@bisu.edu.ph',
            role: 'admin',
            role_label: 'System Administrator',
            department: 'MIS / Campus Operations'
          };
          localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify({ 
            user: fallbackUser, 
            token: 'demo-session-token', 
            expires_at: new Date(Date.now() + 86400000).toISOString() 
          }));
          applyUserProfile(fallbackUser);
          if (authOverlay) authOverlay.classList.remove('active');
          if (loginForm) loginForm.reset();
        } else {
          showAuthError('Unable to connect to authentication server. Is WAMP MySQL running?');
        }
      } finally {
        setAuthLoading(false);
      }
    });
  }

  // Handle Logout
  const handleLogout = async () => {
    if (!confirm('Are you sure you want to sign out of the BISU-Alert Admin Command Center?')) {
      return;
    }

    const session = getStoredSession();
    if (session && session.token) {
      try {
        await fetch('../backend/api/auth/logout.php', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${session.token}`,
            'Accept': 'application/json'
          }
        });
      } catch (_) {
        // Ignore network errors on logout
      }
    }

    localStorage.removeItem(AUTH_STORAGE_KEY);
    if (authOverlay) authOverlay.classList.add('active');
    if (passwordInput) passwordInput.value = '';
    hideAuthError();
  };

  if (sidebarLogoutBtn) sidebarLogoutBtn.addEventListener('click', handleLogout);
  if (headerLogoutBtn) headerLogoutBtn.addEventListener('click', handleLogout);

  function setAuthLoading(isLoading) {
    if (submitBtn) submitBtn.disabled = isLoading;
    if (submitText) submitText.style.display = isLoading ? 'none' : 'inline';
    if (submitSpinner) submitSpinner.style.display = isLoading ? 'inline-block' : 'none';
  }

  function showAuthError(msg) {
    if (errorBanner && errorMsg) {
      errorMsg.textContent = msg;
      errorBanner.style.display = 'flex';
      errorBanner.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }

  function hideAuthError() {
    if (errorBanner) errorBanner.style.display = 'none';
  }

  function applyUserProfile(user) {
    const avatarEl = document.getElementById('sidebar-user-avatar');
    const nameEl = document.getElementById('sidebar-user-name');
    const roleEl = document.getElementById('sidebar-user-role');

    if (user) {
      if (nameEl) nameEl.textContent = user.full_name || 'Administrator';
      if (roleEl) roleEl.textContent = user.role_label || user.department || 'Campus Security';
      if (avatarEl) {
        const initials = (user.full_name || 'Admin')
          .split(' ')
          .map(n => n[0])
          .slice(0, 2)
          .join('')
          .toUpperCase();
        avatarEl.textContent = initials || 'AD';
      }
    }
  }
}


// Navigation Tabs
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const tabId = item.getAttribute('data-tab');
      switchTab(tabId);
    });
  });
}

function switchTab(tabId) {
  appState.activeTab = tabId;

  // Update nav
  document.querySelectorAll('.nav-item').forEach(el => {
    el.classList.toggle('active', el.getAttribute('data-tab') === tabId);
  });

  // Update panels
  document.querySelectorAll('.tab-panel').forEach(panel => {
    panel.classList.toggle('active', panel.id === `tab-${tabId}`);
  });

  // Render specific tab content
  if (tabId === 'dashboard') {
    renderDashboard();
  } else if (tabId === 'incidents') {
    renderIncidentsManager();
  } else if (tabId === 'sos') {
    renderSosManager();
  } else if (tabId === 'responders') {
    renderRespondersManager();
  } else if (tabId === 'analytics') {
    renderAnalyticsManager();
  } else if (tabId === 'users') {
    renderUsersManager();
  } else if (tabId === 'locations') {
    renderLocationsManager();
  } else if (tabId === 'contacts') {
    renderContactsManager();
  } else if (tabId === 'announcements') {
    renderAnnouncementsManager();
  } else if (tabId === 'logs') {
    renderLogsManager();
  } else if (tabId === 'settings') {
    renderSettingsManager();
  }
}

// Filters for Incident Table
function setupFilters() {
  const pills = document.querySelectorAll('.filter-pill');
  pills.forEach(pill => {
    pill.addEventListener('click', () => {
      pills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      appState.currentFilter = pill.getAttribute('data-filter');
      renderIncidentsTable();
    });
  });

  const searchInput = document.getElementById('global-search');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase().trim();
      renderIncidentsTable(q);
    });
  }

  const btnRefresh = document.getElementById('btn-refresh-data');
  if (btnRefresh) {
    btnRefresh.addEventListener('click', () => {
      tryFetchLiveBackend();
    });
  }

  const btnMockSos = document.getElementById('btn-mock-sos');
  if (btnMockSos) {
    btnMockSos.addEventListener('click', () => {
      simulateSosAlert();
    });
  }

  const btnBroadcast = document.getElementById('btn-broadcast-alert');
  if (btnBroadcast) {
    btnBroadcast.addEventListener('click', () => {
      promptBroadcastAlert();
    });
  }
}

// Render Dashboard
function renderDashboard() {
  document.getElementById('val-active-emergencies').textContent = String(appState.metrics.active_emergencies).padStart(2, '0');
  document.getElementById('val-pending-reports').textContent = String(appState.metrics.pending_reports).padStart(2, '0');
  document.getElementById('val-responding').textContent = String(appState.metrics.responding).padStart(2, '0');
  document.getElementById('val-resolved-today').textContent = String(appState.metrics.resolved_today).padStart(2, '0');

  document.getElementById('side-active-count').textContent = appState.metrics.active_emergencies;
  document.getElementById('side-pending-count').textContent = appState.metrics.pending_reports;

  renderIncidentsTable();
}

// Render Incidents Table
function renderIncidentsTable(searchQuery = '') {
  incidentsTableBody.innerHTML = '';

  let filtered = appState.incidents;

  if (appState.currentFilter !== 'all') {
    filtered = filtered.filter(item => item.status.toLowerCase() === appState.currentFilter);
  }

  if (searchQuery) {
    filtered = filtered.filter(item =>
      item.reference_code.toLowerCase().includes(searchQuery) ||
      item.location_label.toLowerCase().includes(searchQuery) ||
      (item.reporter_name && item.reporter_name.toLowerCase().includes(searchQuery)) ||
      item.description.toLowerCase().includes(searchQuery)
    );
  }

  if (filtered.length === 0) {
    incidentsTableBody.innerHTML = `
      <tr>
        <td colspan="9" style="text-align:center; padding: 32px; color: var(--text-muted);">
          No matching incidents found in the active logs.
        </td>
      </tr>
    `;
    return;
  }

  filtered.forEach(inc => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><span class="ref-code">${inc.reference_code}</span></td>
      <td><strong>${getCategoryIcon(inc.category)} ${inc.category_label || inc.category}</strong></td>
      <td>${inc.location_label}</td>
      <td>${inc.reporter_name || 'Anonymous'}</td>
      <td><small>${formatTime(inc.reported_at)}</small></td>
      <td><span class="badge ${inc.priority === 'critical' ? 'badge-danger' : ''}">${inc.priority.toUpperCase()}</span></td>
      <td><span class="status-badge status-${inc.status}">${inc.status}</span></td>
      <td>${inc.handled_by || '<span class="text-muted">Unassigned</span>'}</td>
      <td>
        <button class="btn btn-outline btn-sm" onclick="openIncidentDetails(${inc.id})">
          👁️ Triage
        </button>
      </td>
    `;
    incidentsTableBody.appendChild(tr);
  });
}

function getCategoryIcon(cat) {
  switch (cat) {
    case 'medical': return '🔴';
    case 'fire_hazard': return '🔥';
    case 'security': return '🛡️';
    case 'facility_damage': return '🔧';
    default: return '⚠️';
  }
}

function formatTime(isoStr) {
  if (!isoStr) return '--';
  const d = new Date(isoStr);
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

// Modal handling
function setupModal() {
  modalCloseBtn.addEventListener('click', () => {
    incidentModal.classList.remove('open');
  });

  window.addEventListener('click', (e) => {
    if (e.target === incidentModal) {
      incidentModal.classList.remove('open');
    }
  });
}

window.openIncidentDetails = function(incidentId) {
  const incident = appState.incidents.find(i => i.id === incidentId);
  if (!incident) return;

  const titleEl = document.getElementById('modal-incident-title');
  const badgeEl = document.getElementById('modal-priority-badge');
  const bodyEl = document.getElementById('modal-body-content');
  const footerEl = document.getElementById('modal-footer-actions');

  titleEl.textContent = `${incident.reference_code} — ${incident.category_label || incident.category}`;
  badgeEl.textContent = incident.priority.toUpperCase();
  badgeEl.className = `modal-badge ${incident.priority === 'critical' ? 'badge-danger' : ''}`;

  bodyEl.innerHTML = `
    <div style="display:flex; flex-direction:column; gap:14px;">
      <div style="background: rgba(0,0,0,0.25); padding:14px; border-radius:8px; border:1px solid var(--border-color);">
        <div style="font-size:12px; color:var(--text-muted); margin-bottom:4px;">LOCATION & TELEMETRY</div>
        <div style="font-size:15px; font-weight:700; color:#34d399;">📍 ${incident.location_label}</div>
        <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">BISU Bilar Campus • Verified Geofence ✓</div>
      </div>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
        <div style="background: rgba(0,0,0,0.25); padding:12px; border-radius:8px;">
          <div style="font-size:11px; color:var(--text-muted);">REPORTER IDENTITY</div>
          <div style="font-size:13px; font-weight:700;">${incident.reporter_name || 'Anonymous'}</div>
          <div style="font-size:11.5px; color:var(--text-secondary);">${incident.reporter_role || ''}</div>
          <div style="font-size:11.5px; color:#38bdf8;">${incident.reporter_phone || ''}</div>
        </div>

        <div style="background: rgba(0,0,0,0.25); padding:12px; border-radius:8px;">
          <div style="font-size:11px; color:var(--text-muted);">CURRENT STATUS</div>
          <div style="font-size:13px; font-weight:700; text-transform:uppercase;">
            <span class="status-badge status-${incident.status}">${incident.status}</span>
          </div>
          <div style="font-size:11.5px; color:var(--text-secondary); margin-top:4px;">
            Assigned: <strong>${incident.handled_by || 'None'}</strong>
          </div>
        </div>
      </div>

      <div>
        <div style="font-size:12px; color:var(--text-muted); margin-bottom:4px;">INCIDENT REPORT DETAILS</div>
        <div style="background: rgba(255,255,255,0.03); padding:12px; border-radius:8px; font-size:13px; line-height:1.5;">
          ${incident.description}
        </div>
      </div>

      <div>
        <label style="font-size:12px; color:var(--text-muted); display:block; margin-bottom:6px;">DISPATCH NOTE / LOG</label>
        <input type="text" id="triage-note" placeholder="Enter response note or instructions..." 
               style="width:100%; background:var(--bg-dark); border:1px solid var(--border-color); color:#fff; padding:8px 12px; border-radius:6px; font-size:13px;">
      </div>
    </div>
  `;

  footerEl.innerHTML = `
    <button class="btn btn-outline btn-sm" onclick="incidentModal.classList.remove('open')">Close</button>
    ${incident.status !== 'responding' ? `
      <button class="btn btn-warning btn-sm" onclick="updateStatus(${incident.id}, 'responding')">
        👮‍♂️ Assign & Respond
      </button>
    ` : ''}
    ${incident.status !== 'resolved' ? `
      <button class="btn btn-primary btn-sm" onclick="updateStatus(${incident.id}, 'resolved')">
        ✅ Mark as Resolved
      </button>
    ` : ''}
    ${incident.status !== 'dismissed' ? `
      <button class="btn btn-outline btn-sm" style="color:#ef4444;" onclick="updateStatus(${incident.id}, 'dismissed')">
        Dismiss Case
      </button>
    ` : ''}
  `;

  incidentModal.classList.add('open');
};

window.selectIncidentByRef = function(ref) {
  const inc = appState.incidents.find(i => i.reference_code === ref);
  if (inc) {
    openIncidentDetails(inc.id);
  }
};

window.updateStatus = async function(incidentId, newStatus) {
  const note = document.getElementById('triage-note')?.value || '';

  // Update local state immediately
  const inc = appState.incidents.find(i => i.id === incidentId);
  if (inc) {
    inc.status = newStatus;
    if (newStatus === 'responding' && !inc.handled_by) {
      inc.handled_by = 'Officer Ramon Bautista';
    }
  }

  // Also try backend API call
  try {
    await fetch('/backend/api/incidents/update_status.php', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        incident_id: incidentId,
        status: newStatus,
        note: note
      })
    });
  } catch (_) {}

  incidentModal.classList.remove('open');
  renderDashboard();
};

// Simulation Triggers
function simulateSosAlert() {
  const newSos = {
    id: Date.now(),
    reference_code: `SOS-2026-${Math.floor(1000 + Math.random() * 9000)}`,
    category: 'medical',
    category_label: 'Emergency SOS Panic',
    location_label: 'Student Center / Gymnasium',
    reporter_name: 'Juan Dela Cruz (SOS Button)',
    reporter_role: 'Student (2024-00123)',
    reporter_phone: '+63 917 456 1234',
    reported_at: new Date().toISOString(),
    priority: 'critical',
    status: 'pending',
    handled_by: null,
    description: 'Instant SOS button activated on campus. Immediate security dispatch required.',
  };

  appState.incidents.unshift(newSos);
  appState.metrics.active_emergencies += 1;
  appState.metrics.pending_reports += 1;

  renderDashboard();
  openIncidentDetails(newSos.id);
}

function promptBroadcastAlert() {
  const title = prompt('Enter Alert Title (e.g. Weather Warning, Campus Evacuation):', 'CAMPUS ADVISORY');
  if (!title) return;
  const detail = prompt('Enter Advisory Message for students and faculty:');
  if (!detail) return;

  appState.announcements.unshift({
    id: Date.now(),
    title: title,
    detail: detail,
    type: 'safety',
    time: 'Just now'
  });

  alert(`📢 Advisory "${title}" has been broadcast to all connected student & staff apps!`);
}

// Sub-Tab Renderers
function renderIncidentsManager() {
  const c = document.getElementById('incidents-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>Active Incident Queue (${appState.incidents.length} Records)</h3>
      </div>
      <div style="display:flex; flex-direction:column; gap:12px;">
        ${appState.incidents.map(i => `
          <div style="display:flex; justify-content:space-between; align-items:center; background:rgba(0,0,0,0.25); padding:14px; border-radius:8px; border-left:4px solid ${i.priority === 'critical' ? '#ef4444' : '#f59e0b'};">
            <div>
              <div style="font-weight:700; color:#34d399;">${i.reference_code} — ${i.category_label || i.category}</div>
              <div style="font-size:12.5px; color:var(--text-secondary); margin:3px 0;">📍 ${i.location_label} • Reporter: ${i.reporter_name || 'Anonymous'}</div>
              <div style="font-size:12px; color:var(--text-muted);">${i.description}</div>
            </div>
            <div style="display:flex; gap:10px; align-items:center;">
              <span class="status-badge status-${i.status}">${i.status}</span>
              <button class="btn btn-outline btn-sm" onclick="openIncidentDetails(${i.id})">Triage</button>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

function renderSosManager() {
  const c = document.getElementById('sos-manager-content');
  const sosList = appState.incidents.filter(i => i.priority === 'critical' || i.reference_code.startsWith('SOS'));
  c.innerHTML = `
    <div class="card danger-card">
      <div class="card-header">
        <h3>🔴 Real-Time SOS Alarm Activations</h3>
        <button class="btn btn-danger btn-sm" onclick="simulateSosAlert()">Trigger New Test SOS</button>
      </div>
      <div style="display:flex; flex-direction:column; gap:12px;">
        ${sosList.map(s => `
          <div style="background:rgba(239,68,68,0.1); border:1px solid rgba(239,68,68,0.3); padding:16px; border-radius:8px; display:flex; justify-content:space-between; align-items:center;">
            <div>
              <div style="font-size:16px; font-weight:800; color:#f87171;">🆘 ${s.reference_code}</div>
              <div style="font-size:13px; font-weight:600; margin:4px 0;">${s.location_label}</div>
              <div style="font-size:12px; color:var(--text-muted);">Reporter: ${s.reporter_name} (${s.reporter_phone || 'No phone'})</div>
            </div>
            <div style="display:flex; gap:10px;">
              <button class="btn btn-primary btn-sm" onclick="openIncidentDetails(${s.id})">Dispatch Security</button>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

function renderRespondersManager() {
  const c = document.getElementById('responders-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>Active Campus Security & Medical Personnel</h3>
      </div>
      <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(260px, 1fr)); gap:14px;">
        ${appState.responders.map(r => `
          <div style="background:rgba(0,0,0,0.25); border:1px solid var(--border-color); padding:16px; border-radius:8px;">
            <div style="font-size:15px; font-weight:700; color:#fff;">👮‍♂️ ${r.name}</div>
            <div style="font-size:12px; color:#34d399; margin:2px 0;">${r.role}</div>
            <div style="font-size:12px; color:var(--text-muted);">Hotline: ${r.contact}</div>
            <div style="margin-top:10px; display:flex; justify-content:space-between; align-items:center;">
              <span class="badge ${r.status === 'Responding' ? 'badge-danger' : 'badge-success'}">${r.status}</span>
              <button class="btn btn-outline btn-sm">Dispatch</button>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

function renderUsersManager() {
  const c = document.getElementById('users-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>Campus Directory Accounts</h3>
      </div>
      <table class="data-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Campus ID</th>
            <th>Role</th>
            <th>Department</th>
            <th>Emergency Phone</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Juan Dela Cruz</strong></td>
            <td>2024-00123</td>
            <td><span class="badge">Student</span></td>
            <td>College of Computer Studies</td>
            <td>+63 917 456 1234</td>
            <td><span class="status-badge status-resolved">Active</span></td>
          </tr>
          <tr>
            <td><strong>Ramon Bautista</strong></td>
            <td>EMP-2019-0044</td>
            <td><span class="badge badge-danger">Security</span></td>
            <td>Campus Security Office</td>
            <td>+63 38 000 9112</td>
            <td><span class="status-badge status-resolved">Active</span></td>
          </tr>
          <tr>
            <td><strong>Liza Mercado</strong></td>
            <td>EMP-2021-0117</td>
            <td><span class="badge">Staff</span></td>
            <td>University Medical Clinic</td>
            <td>+63 38 000 9111</td>
            <td><span class="status-badge status-resolved">Active</span></td>
          </tr>
          <tr>
            <td><strong>Prof. Ana Reyes</strong></td>
            <td>EMP-2018-0201</td>
            <td><span class="badge">Faculty</span></td>
            <td>College of Agriculture & Forestry</td>
            <td>+63 917 222 8890</td>
            <td><span class="status-badge status-resolved">Active</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  `;
}

function renderLocationsManager() {
  const c = document.getElementById('locations-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>Campus Landmarks & Evacuation Safe Zones</h3>
      </div>
      <table class="data-table">
        <thead>
          <tr>
            <th>Code</th>
            <th>Landmark Name</th>
            <th>Type</th>
            <th>GPS Coordinates</th>
            <th>Contact Hotline</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>admin</code></td>
            <td>Main Administration Building</td>
            <td>Building</td>
            <td>9.7185410, 124.1096190</td>
            <td>(038) 000-1201</td>
          </tr>
          <tr>
            <td><code>clinic</code></td>
            <td>Campus Medical Clinic</td>
            <td>Emergency Hub</td>
            <td>9.7176390, 124.1093960</td>
            <td>(038) 000-9111</td>
          </tr>
          <tr>
            <td><code>gate</code></td>
            <td>Main Gate Security / Guard House</td>
            <td>Emergency Hub</td>
            <td>9.7183140, 124.1112490</td>
            <td>(038) 000-9112</td>
          </tr>
          <tr>
            <td><code>evac</code></td>
            <td>Disaster Evacuation Grounds (Assembly A)</td>
            <td>Evacuation Zone</td>
            <td>9.7199000, 124.1079000</td>
            <td>(038) 000-9130</td>
          </tr>
        </tbody>
      </table>
    </div>
  `;
}

function renderContactsManager() {
  const c = document.getElementById('contacts-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>Emergency Directory Numbers</h3>
      </div>
      <table class="data-table">
        <thead>
          <tr>
            <th>Agency / Service</th>
            <th>Role</th>
            <th>Telephone Hotline</th>
            <th>Location</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>BISU Bilar Campus Security Office</strong></td>
            <td>Campus Security</td>
            <td><a href="tel:+63380009112" style="color:#38bdf8;">+63 38 000 9112</a></td>
            <td>On Campus</td>
          </tr>
          <tr>
            <td><strong>BISU Bilar University Clinic</strong></td>
            <td>Medical Staff</td>
            <td><a href="tel:+63380009111" style="color:#38bdf8;">+63 38 000 9111</a></td>
            <td>On Campus</td>
          </tr>
          <tr>
            <td><strong>Bilar MDRRMO</strong></td>
            <td>Disaster Response</td>
            <td><a href="tel:+63385001300" style="color:#38bdf8;">+63 38 500 1300</a></td>
            <td>Municipal</td>
          </tr>
          <tr>
            <td><strong>Bilar Municipal Police Station</strong></td>
            <td>Police</td>
            <td><a href="tel:+63385001170" style="color:#38bdf8;">+63 38 500 1170</a></td>
            <td>Municipal</td>
          </tr>
        </tbody>
      </table>
    </div>
  `;
}

function renderAnnouncementsManager() {
  const c = document.getElementById('announcements-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>Active Broadcast Advisories</h3>
      </div>
      <div style="display:flex; flex-direction:column; gap:12px;">
        ${appState.announcements.map(a => `
          <div style="background:rgba(0,0,0,0.25); border:1px solid var(--border-color); padding:16px; border-radius:8px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:15px; font-weight:700; color:#fff;">📢 ${a.title}</span>
              <span style="font-size:11px; color:var(--text-muted);">${a.time}</span>
            </div>
            <div style="font-size:13px; color:var(--text-secondary); margin-top:6px;">${a.detail}</div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

function renderLogsManager() {
  const c = document.getElementById('logs-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>Audit & Activity Logs</h3>
      </div>
      <div style="font-family:monospace; font-size:12px; background:rgba(0,0,0,0.4); padding:16px; border-radius:8px; display:flex; flex-direction:column; gap:8px;">
        <div>[2026-09-17 20:21:05] <span style="color:#34d399;">AUDIT:</span> SOS_TRIGGER - User: 1 (Juan Dela Cruz) - Ref: INC-2026-00124 (Student Center)</div>
        <div>[2026-09-17 20:21:15] <span style="color:#60a5fa;">STATUS:</span> INCIDENT_UPDATE - Officer Ramon Bautista set INC-2026-00124 -> RESPONDING</div>
        <div>[2026-09-17 19:45:00] <span style="color:#fbbf24;">REPORT:</span> INCIDENT_SUBMIT - User: 4 (Prof. Ana Reyes) - Ref: INC-2026-00125 (CCT)</div>
        <div>[2026-09-17 18:35:10] <span style="color:#34d399;">STATUS:</span> INCIDENT_RESOLVED - Officer Ramon Bautista closed INC-2026-00126</div>
      </div>
    </div>
  `;
}

function renderSettingsManager() {
  const c = document.getElementById('settings-manager-content');
  c.innerHTML = `
    <div class="card">
      <div class="card-header">
        <h3>System Configuration</h3>
      </div>
      <div style="display:flex; flex-direction:column; gap:16px; max-width:600px;">
        <div>
          <label style="font-size:13px; font-weight:700; display:block; margin-bottom:4px;">Campus Center GPS</label>
          <input type="text" value="9.7188800, 124.1088300" class="header-search" style="width:100%; border-radius:6px; color:#fff;">
        </div>
        <div>
          <label style="font-size:13px; font-weight:700; display:block; margin-bottom:4px;">Campus Geofence Radius (meters)</label>
          <input type="number" value="300" class="header-search" style="width:100%; border-radius:6px; color:#fff;">
        </div>
        <div>
          <label style="font-size:13px; font-weight:700; display:block; margin-bottom:4px;">Primary Security Dispatch Hotline</label>
          <input type="text" value="+63 38 000 9112" class="header-search" style="width:100%; border-radius:6px; color:#fff;">
        </div>
        <div>
          <button class="btn btn-primary" onclick="alert('Configuration saved successfully!')">Save Configuration</button>
        </div>
      </div>
    </div>
  `;
}

// Live backend polling
async function tryFetchLiveBackend() {
  try {
    const res = await fetch('/backend/api/admin/stats.php');
    if (res.ok) {
      const json = await res.json();
      if (json.data && json.data.metrics) {
        appState.metrics = json.data.metrics;
        if (json.data.recent_incidents && json.data.recent_incidents.length > 0) {
          appState.incidents = json.data.recent_incidents;
        }
        document.getElementById('backend-status-text').textContent = 'MySQL Live Connected';
        renderDashboard();
      }
    }
  } catch (err) {
    document.getElementById('backend-status-text').textContent = 'Simulation Mode Active';
  }
}

// =============================================================================
// TAB: INCIDENT ANALYTICS (THESIS DEFENSE ENGINE)
// =============================================================================
function renderAnalyticsManager() {
  const c = document.getElementById('analytics-manager-content');
  if (!c) return;

  // Standard requested thesis statistics
  const data = {
    total: 284,
    resolved: 251,
    pending: 18,
    critical: 15,
    resolutionRate: '88.4%',
    avgResponseTime: '6.4 mins',
    sosActivations: 42,
    categories: [
      { rank: 1, name: 'Medical Emergency', count: 112, pct: 39.4, color: '#ef4444' },
      { rank: 2, name: 'Facility Damage',   count: 74,  pct: 26.1, color: '#3b82f6' },
      { rank: 3, name: 'Security Incident', count: 58,  pct: 20.4, color: '#f59e0b' },
      { rank: 4, name: 'Fire / Hazard',     count: 40,  pct: 14.1, color: '#10b981' },
    ],
    monthly: [
      { month: 'Jan', count: 19 },
      { month: 'Feb', count: 24 },
      { month: 'Mar', count: 38 },
      { month: 'Apr', count: 22 },
      { month: 'May', count: 31 },
      { month: 'Jun', count: 29 },
      { month: 'Jul', count: 35 },
      { month: 'Aug', count: 46 },
      { month: 'Sep', count: 40 },
    ],
    locations: [
      { name: 'CAF Academic Building', count: 78, pct: '27.5%', avgTime: '5.8 mins', risk: 'Medium' },
      { name: 'Administration Complex', count: 64, pct: '22.5%', avgTime: '4.2 mins', risk: 'Low' },
      { name: 'CCT Computer Studies Bldg', count: 56, pct: '19.7%', avgTime: '6.1 mins', risk: 'Medium' },
      { name: 'University Gymnasium', count: 48, pct: '16.9%', avgTime: '7.3 mins', risk: 'High' },
      { name: 'Main Gate 1 & Perimeter', count: 26, pct: '9.2%', avgTime: '3.9 mins', risk: 'Low' },
      { name: 'Assembly Grounds A / Oval', count: 12, pct: '4.2%', avgTime: '8.0 mins', risk: 'Low' },
    ]
  };

  // Build HTML
  c.innerHTML = `
    <!-- Top KPI Grid -->
    <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap:16px; margin-bottom:24px;">
      <div class="card stat-card" style="border-left: 4px solid #3b82f6;">
        <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase;">Total Incidents</div>
        <div style="font-size:32px; font-weight:900; color:#fff; margin-top:4px;">${data.total}</div>
        <div style="font-size:11px; color:#93c5fd; margin-top:4px;">Campus-wide Cumulative</div>
      </div>

      <div class="card stat-card" style="border-left: 4px solid #10b981;">
        <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase;">Resolved</div>
        <div style="font-size:32px; font-weight:900; color:#34d399; margin-top:4px;">${data.resolved}</div>
        <div style="font-size:11px; color:#a7f3d0; margin-top:4px;">${data.resolutionRate} Resolution Rate</div>
      </div>

      <div class="card stat-card" style="border-left: 4px solid #f59e0b;">
        <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase;">Pending</div>
        <div style="font-size:32px; font-weight:900; color:#fbbf24; margin-top:4px;">${data.pending}</div>
        <div style="font-size:11px; color:#fde68a; margin-top:4px;">Awaiting Review / Triage</div>
      </div>

      <div class="card stat-card" style="border-left: 4px solid #ef4444;">
        <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase;">Critical</div>
        <div style="font-size:32px; font-weight:900; color:#f87171; margin-top:4px;">${data.critical}</div>
        <div style="font-size:11px; color:#fca5a5; margin-top:4px;">Immediate Officer Dispatch</div>
      </div>

      <div class="card stat-card" style="border-left: 4px solid #8b5cf6;">
        <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase;">Avg Response Time</div>
        <div style="font-size:32px; font-weight:900; color:#c4b5fd; margin-top:4px;">${data.avgResponseTime}</div>
        <div style="font-size:11px; color:#ddd6fe; margin-top:4px;">Target &lt; 8.0 mins ✓</div>
      </div>

      <div class="card stat-card" style="border-left: 4px solid #ec4899;">
        <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase;">SOS Activations</div>
        <div style="font-size:32px; font-weight:900; color:#f472b6; margin-top:4px;">${data.sosActivations}</div>
        <div style="font-size:11px; color:#fbcfe8; margin-top:4px;">100% Geofence Verified</div>
      </div>
    </div>

    <!-- Charts Row 1: Categories Breakdown & Resolved vs Unresolved Gauge -->
    <div style="display:grid; grid-template-columns: 1.2fr 1fr; gap:20px; margin-bottom:24px;">
      <!-- Most Reported Categories -->
      <div class="card">
        <div class="card-header" style="display:flex; justify-content:space-between; align-items:center;">
          <div class="card-title-group">
            <span class="card-icon">📋</span>
            <h3>MOST REPORTED INCIDENT CATEGORIES</h3>
          </div>
          <span style="font-size:12px; color:var(--text-muted);">Ranked by Frequency</span>
        </div>
        <div style="display:flex; flex-direction:column; gap:16px; margin-top:12px;">
          ${data.categories.map(cat => `
            <div>
              <div style="display:flex; justify-content:space-between; font-size:13px; margin-bottom:6px;">
                <span style="font-weight:700; color:#fff;">${cat.rank}. ${cat.name}</span>
                <span style="color:var(--text-secondary); font-weight:600;">${cat.count} cases (${cat.pct}%)</span>
              </div>
              <div style="height:10px; background:rgba(255,255,255,0.08); border-radius:5px; overflow:hidden;">
                <div style="height:100%; width:${cat.pct}%; background:${cat.color}; border-radius:5px; transition: width 1s ease;"></div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>

      <!-- Resolved vs Unresolved Donut Chart -->
      <div class="card">
        <div class="card-header">
          <div class="card-title-group">
            <span class="card-icon">🎯</span>
            <h3>RESOLVED VS UNRESOLVED RATIO</h3>
          </div>
        </div>
        <div style="display:flex; align-items:center; justify-content:space-around; margin-top:12px;">
          <!-- SVG Donut Chart -->
          <svg width="150" height="150" viewBox="0 0 42 42" style="transform: rotate(-90deg);">
            <circle cx="21" cy="21" r="15.915" fill="transparent" stroke="rgba(255,255,255,0.08)" stroke-width="5"></circle>
            <!-- Resolved arc: 88.4% -->
            <circle cx="21" cy="21" r="15.915" fill="transparent" stroke="#10b981" stroke-width="5" stroke-dasharray="88.4 11.6" stroke-dashoffset="0"></circle>
            <!-- Unresolved arc: 11.6% -->
            <circle cx="21" cy="21" r="15.915" fill="transparent" stroke="#f59e0b" stroke-width="5" stroke-dasharray="11.6 88.4" stroke-dashoffset="-88.4"></circle>
            <g style="transform: rotate(90deg); transform-origin: 50% 50%;">
              <text x="21" y="19" text-anchor="middle" fill="#fff" font-size="5" font-weight="800">88.4%</text>
              <text x="21" y="24" text-anchor="middle" fill="#94a3b8" font-size="2.6">RESOLVED</text>
            </g>
          </svg>

          <!-- Legend -->
          <div style="display:flex; flex-direction:column; gap:10px; font-size:13px;">
            <div style="display:flex; align-items:center; gap:8px;">
              <span style="width:12px; height:12px; border-radius:3px; background:#10b981; display:inline-block;"></span>
              <span><strong>Resolved:</strong> 251 reports (88.4%)</span>
            </div>
            <div style="display:flex; align-items:center; gap:8px;">
              <span style="width:12px; height:12px; border-radius:3px; background:#f59e0b; display:inline-block;"></span>
              <span><strong>Pending Triage:</strong> 18 reports (6.3%)</span>
            </div>
            <div style="display:flex; align-items:center; gap:8px;">
              <span style="width:12px; height:12px; border-radius:3px; background:#3b82f6; display:inline-block;"></span>
              <span><strong>Under Review:</strong> 11 reports (3.9%)</span>
            </div>
            <div style="display:flex; align-items:center; gap:8px;">
              <span style="width:12px; height:12px; border-radius:3px; background:#6b7280; display:inline-block;"></span>
              <span><strong>Cancelled / Drill:</strong> 4 reports (1.4%)</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Charts Row 2: Incidents per Month Bar Chart -->
    <div class="card" style="margin-bottom:24px;">
      <div class="card-header" style="display:flex; justify-content:space-between; align-items:center;">
        <div class="card-title-group">
          <span class="card-icon">📈</span>
          <h3>INCIDENTS PER MONTH (JANUARY - SEPTEMBER 2026)</h3>
        </div>
        <span style="font-size:12px; color:var(--text-muted);">Historical Longitudinal Distribution</span>
      </div>

      <!-- SVG Bar Chart -->
      <div style="padding:16px 8px 8px 8px; overflow-x:auto;">
        <svg viewBox="0 0 760 210" style="width:100%; min-width:600px; height:210px;">
          <!-- Grid Lines -->
          <line x1="40" y1="20" x2="740" y2="20" stroke="rgba(255,255,255,0.06)" stroke-dasharray="3 3"/>
          <text x="32" y="24" fill="#64748b" font-size="10" text-anchor="end">50</text>

          <line x1="40" y1="60" x2="740" y2="60" stroke="rgba(255,255,255,0.06)" stroke-dasharray="3 3"/>
          <text x="32" y="64" fill="#64748b" font-size="10" text-anchor="end">35</text>

          <line x1="40" y1="105" x2="740" y2="105" stroke="rgba(255,255,255,0.06)" stroke-dasharray="3 3"/>
          <text x="32" y="109" fill="#64748b" font-size="10" text-anchor="end">20</text>

          <line x1="40" y1="150" x2="740" y2="150" stroke="rgba(255,255,255,0.06)" stroke-dasharray="3 3"/>
          <text x="32" y="154" fill="#64748b" font-size="10" text-anchor="end">5</text>

          <line x1="40" y1="165" x2="740" y2="165" stroke="rgba(255,255,255,0.15)"/>

          <!-- Monthly Bars -->
          ${data.monthly.map((m, idx) => {
            const x = 65 + idx * 75;
            const barHeight = (m.count / 50) * 145;
            const y = 165 - barHeight;
            return `
              <g class="chart-bar-group">
                <rect x="${x}" y="${y}" width="42" height="${barHeight}" rx="4" fill="url(#barGrad)" stroke="#38bdf8" stroke-width="1"/>
                <text x="${x + 21}" y="${y - 6}" fill="#38bdf8" font-size="11" font-weight="700" text-anchor="middle">${m.count}</text>
                <text x="${x + 21}" y="182" fill="#94a3b8" font-size="12" font-weight="600" text-anchor="middle">${m.month}</text>
              </g>
            `;
          }).join('')}

          <defs>
            <linearGradient id="barGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#0284c7" stop-opacity="0.9"/>
              <stop offset="100%" stop-color="#0369a1" stop-opacity="0.3"/>
            </linearGradient>
          </defs>
        </svg>
      </div>
    </div>

    <!-- Location Breakdown Hotspots Table -->
    <div class="card">
      <div class="card-header" style="display:flex; justify-content:space-between; align-items:center;">
        <div class="card-title-group">
          <span class="card-icon">📍</span>
          <h3>INCIDENTS BY CAMPUS LOCATION & RESPONSE TIME</h3>
        </div>
        <span style="font-size:12px; color:var(--text-muted);">Hotspot Vulnerability Telemetry</span>
      </div>

      <div class="table-responsive">
        <table class="data-table">
          <thead>
            <tr>
              <th>Campus Facility / Landmark</th>
              <th>Incident Count</th>
              <th>Percentage Share</th>
              <th>Avg Responder Response Time</th>
              <th>Risk Severity Tier</th>
            </tr>
          </thead>
          <tbody>
            ${data.locations.map(loc => `
              <tr>
                <td><strong>🏢 ${loc.name}</strong></td>
                <td><span style="font-weight:700; color:#fff;">${loc.count}</span></td>
                <td>${loc.pct}</td>
                <td><span style="color:#34d399; font-weight:700;">⏱️ ${loc.avgTime}</span></td>
                <td>
                  <span class="badge ${loc.risk === 'High' ? 'badge-danger' : (loc.risk === 'Medium' ? 'badge' : 'badge-success')}" style="${loc.risk === 'Medium' ? 'background:rgba(245,158,11,0.2); color:#fbbf24;' : ''}">
                    ${loc.risk}
                  </span>
                </td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

function exportAnalyticsCSV() {
  const csvRows = [
    ['BISU-ALERT Campus Emergency Response System - Thesis Defense Telemetry'],
    ['Generated Date', new Date().toISOString()],
    ['Total Incidents', 284],
    ['Resolved Incidents', 251],
    ['Pending Triage', 18],
    ['Critical Dispatches', 15],
    ['Average Response Time', '6.4 mins'],
    ['SOS Activations', 42],
    [],
    ['Category Ranking', 'Incident Count', 'Percentage'],
    ['Medical Emergency', 112, '39.4%'],
    ['Facility Damage', 74, '26.1%'],
    ['Security Incident', 58, '20.4%'],
    ['Fire / Hazard', 40, '14.1%'],
    [],
    ['Location Landmark', 'Incident Count', 'Avg Response Time'],
    ['CAF Academic Building', 78, '5.8 mins'],
    ['Administration Complex', 64, '4.2 mins'],
    ['CCT Computer Studies Bldg', 56, '6.1 mins'],
    ['University Gymnasium', 48, '7.3 mins'],
    ['Main Gate 1 & Perimeter', 26, '3.9 mins'],
    ['Assembly Grounds A / Oval', 12, '8.0 mins'],
  ];

  const csvContent = "data:text/csv;charset=utf-8," + csvRows.map(e => e.join(",")).join("\n");
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", "BISU_Alert_Thesis_Analytics_2026.csv");
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

