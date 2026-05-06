// @namespace: OpenWRT-CI
// ═══════════════════════════════════════
//  状态管理
// ═══════════════════════════════════════

const STORAGE_KEY = 'openwrt-ci-state';

let state = {
  sourceBranch: 'main-nss',
  target: 'qualcommax',
  subtarget: 'ipq807x',
  firewall: 'iptables',
  template: 'base',
  devices: new Set(),
  plugins: new Set(),
  customOpts: [],
};


// @namespace: OpenWRT-CI
// ═══════════════════════════════════════
//  全局状态管理
// ═══════════════════════════════════════

/* 平台分组配置 - 从 DEVICES 动态生成 */
const PLATFORM_GROUPS = (() => {
  const groupMap = {};
  const PLATFORM_META = {
    qualcommax: { name: 'Qualcomm IPQ', icon: '🔵' },
    qualcommbe: { name: 'Qualcomm BE', icon: '🟢' },
    ipq40xx: { name: 'IPQ40xx', icon: '🔵' },
    ipq806x: { name: 'IPQ806x', icon: '🔵' },
    mediatek: { name: 'MediaTek', icon: '🟣' },
    ath79: { name: 'Atheros MIPS', icon: '🟠' },
    ramips: { name: 'Ralink MIPS', icon: '🟡' },
    bcm53xx: { name: 'Broadcom', icon: '🔴' },
    bcm4908: { name: 'Broadcom', icon: '🔴' },
    mvebu: { name: 'Marvell Armada', icon: '⚪' },
    lantiq: { name: 'Lantiq', icon: '🟤' },
    airoha: { name: 'Airoha', icon: '🟧' },
    rockchip: { name: 'Rockchip', icon: '⬜' },
  };
  for (const key of Object.keys(DEVICES)) {
    const parts = key.split('-');
    const groupId = parts[0];
    if (!groupMap[groupId]) groupMap[groupId] = [];
    const subName = parts.length > 1 ? parts.slice(1).join('-') : groupId;
    groupMap[groupId].push({ k: key, n: subName });
  }
  return Object.keys(groupMap).map(id => {
    const meta = PLATFORM_META[id] || { name: id, icon: '⬜' };
    return { id, name: meta.name, icon: meta.icon, subs: groupMap[id] };
  });
})();

let currentPlatformGroup = 'qualcommax';
let currentSubKey = 'qualcommax-ipq807x';
let searchQuery = '';
let deviceLoadOffset = 0;
const DEVICE_PAGE_SIZE = 50;
let workflowCheckTimer = null;
let buildRetryCount = 0;
const MAX_RETRY = 2;

// ═══════════════════════════════════════
//  工具函数
// ═══════════════════════════════════════

/* debounce 工具函数 */
function debounce(fn, ms) {
  let t;
  return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); };
}

/* debounce 版本的 saveState (300ms) */
const debouncedSave = debounce(saveState, 300);

/* 转义 HTML 特殊字符 */
function escapeHtml(str) {
  return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* LAN IP 格式验证 */
function isValidLanIP(ip) {
  if (!ip) return true;
  const parts = ip.split('.');
  if (parts.length !== 4) return false;
  return parts.every(p => {
    const n = Number(p);
    if (isNaN(n) || n < 0 || n > 255) return false;
    return String(n) === p || (p.startsWith('0') && p.length === 1);
  });
}

/* GitHub Token 格式验证 */
function isValidToken(token) {
  return /^(ghp_|github_pat_)/.test(token);
}

// ═══════════════════════════════════════
//  持久化 (localStorage + sessionStorage for token)
// ═══════════════════════════════════════
function saveState() {
  const data = {
    sourceBranch: state.sourceBranch,
    target: state.target,
    subtarget: state.subtarget,
    firewall: state.firewall,
    template: state.template,
    devices: [...state.devices],
    plugins: [...state.plugins],
    customOpts: state.customOpts,
    currentPlatformGroup: currentPlatformGroup,
    currentSubKey: currentSubKey,
    ghRepo: document.getElementById('gh-repo').value,
    rootPw: document.getElementById('root-pw').value,
    lanIp: document.getElementById('lan-ip').value,
    wifiSsid: document.getElementById('wifi-ssid').value,
    wifiPassword: document.getElementById('wifi-password').value,
    customConfig: document.getElementById('custom-config').value,
    optCcache: document.getElementById('tog-ccache').classList.contains('on'),
    optUpload: document.getElementById('tog-upload').classList.contains('on'),
    customKey: document.getElementById('custom-key').value,
    customVal: document.getElementById('custom-val').value,
  };
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    // Token 单独用 sessionStorage 存储，关闭标签页即清除
    const tokenVal = document.getElementById('gh-token').value;
    if (tokenVal) {
      sessionStorage.setItem('openwrt-ci-token', tokenVal);
    } else {
      sessionStorage.removeItem('openwrt-ci-token');
    }
  } catch(e) {}
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    const data = JSON.parse(raw);
    state.sourceBranch = data.sourceBranch || 'main-nss';
    state.target = data.target || 'qualcommax';
    state.subtarget = data.subtarget || 'ipq807x';
    state.firewall = data.firewall || 'iptables';
    state.template = data.template || 'base';
    state.devices = new Set(data.devices || []);
    state.plugins = new Set(data.plugins || []);
    state.customOpts = data.customOpts || [];
    currentPlatformGroup = data.currentPlatformGroup || 'qualcommax';
    currentSubKey = data.currentSubKey || 'qualcommax-ipq807x';
    if (data.ghRepo) document.getElementById('gh-repo').value = data.ghRepo;
    // Token 从 sessionStorage 读取（更安全）
    const savedToken = sessionStorage.getItem('openwrt-ci-token');
    if (savedToken) document.getElementById('gh-token').value = savedToken;
    if (data.rootPw !== undefined) document.getElementById('root-pw').value = data.rootPw;
    if (data.lanIp) document.getElementById('lan-ip').value = data.lanIp;
    if (data.wifiSsid) document.getElementById('wifi-ssid').value = data.wifiSsid;
    if (data.wifiPassword) document.getElementById('wifi-password').value = data.wifiPassword;
    if (data.customConfig) document.getElementById('custom-config').value = data.customConfig;
    if (data.optCcache !== undefined) { const el = document.getElementById('tog-ccache'); el.classList.toggle('on', data.optCcache); el.querySelector('.tog-pill').textContent = data.optCcache ? '开' : '关'; }
    if (data.optUpload !== undefined) { const el = document.getElementById('tog-upload'); el.classList.toggle('on', data.optUpload); el.querySelector('.tog-pill').textContent = data.optUpload ? '开' : '关'; }
    if (data.customKey) document.getElementById('custom-key').value = data.customKey;
    if (data.customVal) document.getElementById('custom-val').value = data.customVal;
    restoreTabStates();
  } catch(e) { console.warn('Failed to load state:', e); }
}

function restoreTabStates() {
  document.querySelectorAll('#source-branch-tabs .tab').forEach(t => {
    t.classList.toggle('on', t.dataset.val === state.sourceBranch);
  });
  document.querySelectorAll('#template-tabs .tab').forEach(t => {
    t.classList.toggle('on', t.dataset.val === state.template);
  });
  document.getElementById('firewall-select').value = state.firewall;
}

// ═══════════════════════════════════════
//  初始化
// ═══════════════════════════════════════
function init() {
  try {
    loadState();
    initTabs();
    initPlatformTabs();
    initDevices();
    initPlugins();
    renderCustomOpts();
    updateSummary();
    initRepoInput();
    bindAutoSave();
  } catch(e) {
    console.error('Init error:', e);
  } finally {
    document.body.classList.add('loaded');
  }
}

function bindAutoSave() {
  ['gh-token','gh-repo','root-pw','lan-ip','wifi-ssid','wifi-password','custom-config','custom-key','custom-val'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('input', debouncedSave);
  });
  ['tog-ccache','tog-upload'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('click', saveState);
  });
  // 表单实时验证
  initFormValidation();
  // 键盘支持：toggle 行和平台标签
  initKeyboardSupport();
}

/* 表单实时验证 */
function initFormValidation() {
  // LAN IP 验证
  const lanIpInput = document.getElementById('lan-ip');
  if (lanIpInput) {
    const wrapper = lanIpInput.parentElement;
    let errMsg = wrapper.querySelector('.input-error-msg');
    if (!errMsg) {
      errMsg = document.createElement('div');
      errMsg.className = 'input-error-msg';
      wrapper.appendChild(errMsg);
    }
    const validateLanIp = () => {
      const val = lanIpInput.value.trim();
      if (val && !isValidLanIP(val)) {
        lanIpInput.classList.add('input-error');
        errMsg.textContent = '请输入有效的 IPv4 地址 (如 192.168.1.1)';
        errMsg.classList.add('show');
      } else {
        lanIpInput.classList.remove('input-error');
        errMsg.classList.remove('show');
      }
    };
    lanIpInput.addEventListener('input', validateLanIp);
    lanIpInput.addEventListener('blur', validateLanIp);
  }

  // WiFi 密码验证
  const wifiPwInput = document.getElementById('wifi-password');
  if (wifiPwInput) {
    const wrapper = wifiPwInput.parentElement;
    let errMsg = wrapper.querySelector('.input-error-msg');
    if (!errMsg) {
      errMsg = document.createElement('div');
      errMsg.className = 'input-error-msg';
      wrapper.appendChild(errMsg);
    }
    const validateWifiPw = () => {
      const val = wifiPwInput.value;
      if (val && val.length < 8) {
        wifiPwInput.classList.add('input-error');
        errMsg.textContent = 'WiFi 密码长度至少为 8 个字符';
        errMsg.classList.add('show');
      } else {
        wifiPwInput.classList.remove('input-error');
        errMsg.classList.remove('show');
      }
    };
    wifiPwInput.addEventListener('input', validateWifiPw);
    wifiPwInput.addEventListener('blur', validateWifiPw);
  }

  // Root 密码长度提示
  const rootPwInput = document.getElementById('root-pw');
  if (rootPwInput) {
    const wrapper = rootPwInput.parentElement;
    let errMsg = wrapper.querySelector('.input-error-msg');
    if (!errMsg) {
      errMsg = document.createElement('div');
      errMsg.className = 'input-error-msg';
      wrapper.appendChild(errMsg);
    }
    const validateRootPw = () => {
      const val = rootPwInput.value;
      if (val && val.length < 6) {
        rootPwInput.classList.add('input-error');
        errMsg.textContent = '密码建议至少 6 个字符以提高安全性';
        errMsg.classList.add('show');
      } else {
        rootPwInput.classList.remove('input-error');
        errMsg.classList.remove('show');
      }
    };
    rootPwInput.addEventListener('input', validateRootPw);
    rootPwInput.addEventListener('blur', validateRootPw);
  }
}

/* 键盘支持：为交互元素添加 Enter/Space 触发 */
function initKeyboardSupport() {
  // toggle 行的键盘支持
  document.querySelectorAll('.tog-row').forEach(el => {
    el.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        el.click();
      }
    });
  });
  // 平台分组标签的键盘支持
  document.querySelectorAll('.pgroup').forEach(el => {
    el.setAttribute('role', 'tab');
    el.setAttribute('tabindex', '0');
    el.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        el.click();
      }
    });
  });
}

/* 自动填充编译仓库 - 改进版：支持自定义域名 */
function initRepoInput() {
  const repoInput = document.getElementById('gh-repo');
  if (repoInput && !repoInput.value) {
    const host = window.location.hostname;
    let owner = '', repo = '';
    if (host.endsWith('.github.io')) {
      owner = host.replace('.github.io', '');
      const pathParts = window.location.pathname.split('/').filter(Boolean);
      repo = pathParts[0] || '';
    } else {
      const metaRepo = document.querySelector('meta[name="go-import"]');
      if (metaRepo) {
        const content = metaRepo.getAttribute('content') || '';
        const match = content.match(/github\.com\/([^\/]+)\/([^\/\s]+)/);
        if (match) { owner = match[1]; repo = match[2]; }
      }
      if (!owner) {
        const canonical = document.querySelector('link[rel="canonical"]');
        if (canonical) {
          const href = canonical.getAttribute('href') || '';
          const match = href.match(/github\.com\/([^\/]+)\/([^\/\s]+)/);
          if (match) { owner = match[1]; repo = match[2]; }
        }
      }
    }
    if (owner && repo) {
      repoInput.value = owner + '/' + repo;
    } else {
      const hint = repoInput.closest('.f')?.querySelector('.hint');
      if (hint) {
        hint.innerHTML = '⚠️ 无法自动检测仓库，请手动输入格式: <code>owner/repo</code>，例如 <code>LiBwrt/openwrt-6.x</code>';
        hint.style.background = 'rgba(251,191,36,.05)';
        hint.style.borderColor = 'rgba(251,191,36,.1)';
        hint.style.color = 'var(--amb)';
      }
    }
  }
}

// Tab 切换
function initTabs() {
  document.querySelectorAll('#source-branch-tabs .tab').forEach(t => {
    t.setAttribute('role', 'tab');
    t.setAttribute('tabindex', '0');
    t.addEventListener('click', () => {
      document.querySelectorAll('#source-branch-tabs .tab').forEach(x => x.classList.remove('on'));
      t.classList.add('on');
      state.sourceBranch = t.dataset.val;
      updateSummary(); saveState();
    });
    t.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); t.click(); }
    });
  });
  document.querySelectorAll('#template-tabs .tab').forEach(t => {
    t.setAttribute('role', 'tab');
    t.setAttribute('tabindex', '0');
    t.addEventListener('click', () => {
      document.querySelectorAll('#template-tabs .tab').forEach(x => x.classList.remove('on'));
      t.classList.add('on');
      state.template = t.dataset.val;
      updateSummary(); saveState();
    });
    t.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); t.click(); }
    });
  });
  document.getElementById('firewall-select').addEventListener('change', function() {
    state.firewall = this.value;
    for (const [cat, plugs] of Object.entries(PLUGIN_CATS)) {
      for (const [name, info] of Object.entries(plugs)) {
        const fw = typeof info === 'object' ? (info.fw !== undefined ? info.fw : 0) : 0;
        if (!isPluginCompatible(fw) && state.plugins.has(name)) {
          state.plugins.delete(name);
        }
      }
    }
    const active = document.querySelector('.pt.on');
    if (active) renderPlugins(active.dataset.cat);
    updatePlugCount(); updateSummary(); saveState();
  });
}

// ═══════════════════════════════════════
//  设备管理
// ═══════════════════════════════════════

function initPlatformTabs() {
  const container = document.getElementById('platform-tabs');
  container.innerHTML = PLATFORM_GROUPS.map(g => {
    const total = g.subs.reduce((a,s) => a + (DEVICES[s.k]||[]).length, 0);
    return `<div class="pgroup ${g.id===currentPlatformGroup?'on':''}" data-g="${g.id}" onclick="switchPlatformGroup('${g.id}')">${escapeHtml(g.icon)} ${escapeHtml(g.name)}<span class="cnt">${total}</span></div>`;
  }).join('');
  renderSubTabs();
}

function switchPlatformGroup(gid) {
  currentPlatformGroup = gid;
  const group = PLATFORM_GROUPS.find(g=>g.id===gid);
  currentSubKey = group.subs[0].k;
  const parts = currentSubKey.split('-');
  state.target = parts[0];
  state.subtarget = parts.slice(1).join('-') || '';
  document.querySelectorAll('.pgroup').forEach(t=>t.classList.toggle('on',t.dataset.g===gid));
  renderSubTabs();
  state.devices.clear();
  initDevices();
  updateSummary();
  saveState();
}

function renderSubTabs() {
  const group = PLATFORM_GROUPS.find(g=>g.id===currentPlatformGroup);
  const container = document.getElementById('target-tabs');
  container.innerHTML = group.subs.map(s => {
    const n = (DEVICES[s.k]||[]).length;
    return `<div class="tab ${s.k===currentSubKey?'on':''}" data-k="${s.k}" onclick="switchSubTab('${s.k}')">${escapeHtml(s.n)} (${n})</div>`;
  }).join('');
}

function switchSubTab(key) {
  currentSubKey = key;
  const parts = key.split('-');
  state.target = parts[0];
  state.subtarget = parts.slice(1).join('-') || '';
  document.querySelectorAll('#target-tabs .tab').forEach(t=>t.classList.toggle('on',t.dataset.k===key));
  state.devices.clear();
  initDevices();
  updateSummary();
  saveState();
}

/* 搜索设备 - 带自动切换平台提示 (防抖包装) */
const _searchDevicesRaw = function(q) {
  searchQuery = q.toLowerCase().trim();
  if (!searchQuery) { initDevices(); return; }
  for (const group of PLATFORM_GROUPS) {
    for (const sub of group.subs) {
      const devs = DEVICES[sub.k] || [];
      const match = devs.some(d => d.n.toLowerCase().includes(searchQuery) || d.id.toLowerCase().includes(searchQuery) || d.c.toLowerCase().includes(searchQuery));
      if (match) {
        showSearchSwitchHint(group.name, sub.n);
        if (currentPlatformGroup !== group.id) {
          currentPlatformGroup = group.id;
          document.querySelectorAll('.pgroup').forEach(t=>t.classList.toggle('on', t.dataset.g===group.id));
          renderSubTabs();
        }
        if (currentSubKey !== sub.k) {
          currentSubKey = sub.k;
          document.querySelectorAll('#target-tabs .tab').forEach(t=>t.classList.toggle('on', t.dataset.k===sub.k));
          const parts = sub.k.split('-');
          state.target = parts[0];
          state.subtarget = parts.slice(1).join('-') || '';
        }
        initDevices();
        return;
      }
    }
  }
  initDevices();
};
const searchDevices = debounce(_searchDevicesRaw, 250);

/* 搜索自动切换提示 */
function showSearchSwitchHint(groupName, subName) {
  const grid = document.getElementById('device-grid');
  const existing = document.getElementById('search-switch-hint');
  if (existing) existing.remove();
  const hint = document.createElement('div');
  hint.id = 'search-switch-hint';
  hint.style.cssText = 'grid-column:1/-1;padding:8px 12px;margin-bottom:4px;font-size:.75em;color:var(--cyan);background:var(--c-d);border-radius:var(--r2);border:1px solid rgba(56,189,248,.15);text-align:center';
  hint.textContent = `🔍 已自动切换到 ${groupName} / ${subName}`;
  grid.parentNode.insertBefore(hint, grid);
  setTimeout(() => { if (hint.parentNode) hint.remove(); }, 3000);
}

/* 设备列表渲染 - 带懒加载 (初始 50 个) */
function initDevices() {
  if (deviceObserver) { deviceObserver.disconnect(); deviceObserver = null; }
  deviceLoadOffset = 0;
  let devs = DEVICES[currentSubKey] || [];
  if (searchQuery) {
    devs = devs.filter(d => d.n.toLowerCase().includes(searchQuery) || d.id.toLowerCase().includes(searchQuery) || d.c.toLowerCase().includes(searchQuery));
  }
  const grid = document.getElementById('device-grid');
  if (devs.length === 0) {
    grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:40px;color:var(--t3);font-size:.85em">未找到匹配设备</div>';
  } else {
    const initialDevs = devs.slice(0, DEVICE_PAGE_SIZE);
    deviceLoadOffset = DEVICE_PAGE_SIZE;
    grid.innerHTML = renderDeviceGroupHTML(initialDevs);
    if (devs.length > DEVICE_PAGE_SIZE) {
      grid.innerHTML += `<div id="load-more-devices" style="grid-column:1/-1;text-align:center;padding:12px">
        <button class="bx" onclick="loadMoreDevices()" style="font-size:.8em">📱 加载更多设备 (${devs.length - DEVICE_PAGE_SIZE} 个剩余)</button>
      </div>`;
      setupDeviceLazyLoad(devs);
    }
  }
  updateDevCount();
  document.getElementById('dev-total').textContent = `共 ${devs.length} 个设备`;
}

function renderDeviceGroupHTML(devs) {
  const groups = {};
  devs.forEach(d => {
    if (!groups[d.c]) groups[d.c] = [];
    groups[d.c].push(d);
  });
  const cpuOrder = Object.keys(groups).sort();
  let html = '';
  cpuOrder.forEach(cpu => {
    const items = groups[cpu];
    html += `<div class="cpu-group" style="grid-column:1/-1;margin-top:8px">
      <div style="font-size:.72em;font-weight:800;color:var(--vio);padding:6px 0;border-bottom:1px solid var(--brd);margin-bottom:6px;letter-spacing:.04em">${escapeHtml(cpu)} <span style="color:var(--t3);font-weight:600">(${items.length})</span></div>
    </div>`;
    html += items.map(d => `
      <div class="dc ${state.devices.has(d.id)?'on':''}" data-id="${escapeHtml(d.id)}" onclick="toggleDevice(this,'${escapeHtml(d.id)}')">
        <div class="n">${escapeHtml(d.n)}</div>
        <div class="c">${escapeHtml(d.c)}</div>
        <div class="toggle-sw"></div>
      </div>
    `).join('');
  });
  return html;
}

function loadMoreDevices() {
  let devs = DEVICES[currentSubKey] || [];
  if (searchQuery) {
    devs = devs.filter(d => d.n.toLowerCase().includes(searchQuery) || d.id.toLowerCase().includes(searchQuery) || d.c.toLowerCase().includes(searchQuery));
  }
  const nextBatch = devs.slice(deviceLoadOffset, deviceLoadOffset + DEVICE_PAGE_SIZE);
  deviceLoadOffset += nextBatch.length;
  const grid = document.getElementById('device-grid');
  const loadMoreBtn = document.getElementById('load-more-devices');
  if (loadMoreBtn) {
    loadMoreBtn.insertAdjacentHTML('beforebegin', renderDeviceGroupHTML(nextBatch));
    if (deviceLoadOffset >= devs.length) {
      loadMoreBtn.remove();
    } else {
      loadMoreBtn.querySelector('button').textContent = `📱 加载更多设备 (${devs.length - deviceLoadOffset} 个剩余)`;
    }
  }
}

let deviceObserver = null;

function setupDeviceLazyLoad(allDevs) {
  if (deviceObserver) { deviceObserver.disconnect(); deviceObserver = null; }
  const sentinel = document.getElementById('load-more-devices');
  if (!sentinel) return;
  deviceObserver = new IntersectionObserver((entries) => {
    if (entries[0].isIntersecting) {
      loadMoreDevices();
    }
  }, { threshold: 0.1 });
  deviceObserver.observe(sentinel);
}

function toggleDevice(el, id) {
  if (state.devices.has(id)) { state.devices.delete(id); el.classList.remove('on'); }
  else { state.devices.add(id); el.classList.add('on'); }
  syncAllCheckbox(); updateDevCount(); updateSummary(); saveState();
}

/* 全选逻辑修复 - 根据当前是否全部选中决定操作 */
function toggleAllDevices() {
  let devs = DEVICES[currentSubKey] || [];
  if (searchQuery) devs = devs.filter(d => d.n.toLowerCase().includes(searchQuery) || d.id.toLowerCase().includes(searchQuery) || d.c.toLowerCase().includes(searchQuery));
  const el = document.getElementById('tog-dev-all');
  const allSelected = devs.length > 0 && devs.every(d => state.devices.has(d.id));
  if (allSelected) {
    devs.forEach(d => state.devices.delete(d.id));
  } else {
    devs.forEach(d => state.devices.add(d.id));
  }
  const nowAllSelected = devs.length > 0 && devs.every(d => state.devices.has(d.id));
  el.classList.toggle('on', nowAllSelected);
  el.querySelector('.tog-pill').textContent = nowAllSelected ? '全不选' : '全选';
  initDevices(); updateSummary(); saveState();
}

function syncAllCheckbox() {
  const devs = DEVICES[currentSubKey] || [];
  const el = document.getElementById('tog-dev-all');
  const allSelected = devs.length > 0 && devs.every(d => state.devices.has(d.id));
  el.classList.toggle('on', allSelected);
  el.querySelector('.tog-pill').textContent = allSelected ? '全不选' : '全选';
}

function updateDevCount() {
  document.getElementById('dev-count').textContent = state.devices.size + ' 已选';
}

// ═══════════════════════════════════════
//  通用开关
// ═══════════════════════════════════════

function toggleOpt(el) {
  const isOn = el.classList.toggle('on');
  const pill = el.querySelector('.tog-pill');
  if (pill) pill.textContent = isOn ? '开' : '关';
  el.setAttribute('aria-checked', isOn ? 'true' : 'false');
  updateSummary(); saveState();
}

// ═══════════════════════════════════════
//  插件管理
// ═══════════════════════════════════════

function initPlugins() {
  const tabs = document.getElementById('plug-tabs');
  const cats = Object.keys(PLUGIN_CATS);
  tabs.innerHTML = cats.map((c,i) => {
    const n = Object.keys(PLUGIN_CATS[c]).length;
    return `<div class="pt ${i===0?'on':''}" data-cat="${c}" onclick="switchPlugCat('${c}',this)">${c}<span class="nm">${n}</span></div>`;
  }).join('');
  document.getElementById('plug-total').textContent = '共 ' + Object.values(PLUGIN_CATS).reduce((a,c) => a + Object.keys(c).length, 0) + ' 个插件';
  renderPlugins(cats[0]);

  document.getElementById('plug-search').addEventListener('input', debounce(e => {
    const q = e.target.value.toLowerCase();
    if (!q) { const active = document.querySelector('.pt.on'); renderPlugins(active?.dataset.cat || cats[0]); return; }
    for (const cat of cats) {
      const plugs = PLUGIN_CATS[cat];
      const hasMatch = Object.entries(plugs).some(([name, info]) => {
        const desc = typeof info === 'string' ? info : info.d;
        const features = typeof info === 'string' ? '' : (info.f || '');
        return name.toLowerCase().includes(q) || desc.toLowerCase().includes(q) || features.toLowerCase().includes(q);
      });
      if (hasMatch) {
        document.querySelectorAll('.pt').forEach(t => t.classList.toggle('on', t.dataset.cat === cat));
        const filtered = {};
        for (const [name, info] of Object.entries(plugs)) {
          const desc = typeof info === 'string' ? info : info.d;
          const features = typeof info === 'string' ? '' : (info.f || '');
          if (name.toLowerCase().includes(q) || desc.toLowerCase().includes(q) || features.toLowerCase().includes(q)) {
            filtered[name] = info;
          }
        }
        renderGrid(filtered);
        return;
      }
    }
    const all = {};
    for (const [cat, plugs] of Object.entries(PLUGIN_CATS)) {
      for (const [name, info] of Object.entries(plugs)) {
        const desc = typeof info === 'string' ? info : info.d;
        const features = typeof info === 'string' ? '' : (info.f || '');
        if (name.toLowerCase().includes(q) || desc.toLowerCase().includes(q) || cat.toLowerCase().includes(q) || features.toLowerCase().includes(q)) {
          all[name] = info;
        }
      }
    }
    renderGrid(all);
  }, 250));
}

function switchPlugCat(cat, el) {
  document.querySelectorAll('.pt').forEach(t => t.classList.remove('on'));
  el.classList.add('on');
  document.getElementById('plug-search').value = '';
  renderPlugins(cat);
}

function renderPlugins(cat) {
  renderGrid(PLUGIN_CATS[cat] || {});
}

function getFirewallType() {
  const el = document.getElementById('firewall-select');
  return el ? el.value : 'iptables';
}

function isPluginCompatible(fw) {
  const current = getFirewallType();
  if (fw === undefined || fw === null) return true;
  if (fw === 0) return true;
  if (fw === 1 && current === 'iptables') return true;
  if (fw === 2 && current === 'nftables') return true;
  return false;
}

/* 获取防火墙兼容性文案 */
function getFirewallLabel(fw) {
  if (fw === 0) return '✅ 兼容 iptables 和 nftables';
  if (fw === 1) return '⚠️ 仅兼容 iptables 防火墙';
  if (fw === 2) return '⚠️ 仅兼容 nftables 防火墙';
  return '✅ 兼容 iptables 和 nftables';
}

function renderGrid(plugs) {
  const grid = document.getElementById('plug-grid');
  grid.innerHTML = Object.entries(plugs).map(([name, info]) => {
    const desc = typeof info === 'string' ? info : info.d;
    const features = typeof info === 'string' ? '' : (info.f || '');
    const fw = typeof info === 'string' ? 0 : (info.fw !== undefined ? info.fw : 0);
    const shortName = name.replace(/^(luci-app-|luci-proto-|luci-theme-|luci-mod-|luci-plugin-)/, '');
    const tags = features ? features.split('/').map(f => `<span class="pd-tag">${escapeHtml(f.trim())}</span>`).join('') : '';
    const compatible = isPluginCompatible(fw);
    const selected = state.plugins.has(name);
    const cls = ['pc', selected ? 'on' : '', !compatible ? 'fw-disabled' : ''].filter(Boolean).join(' ');
    return `
    <div class="${cls}" id="pc-${escapeHtml(name)}" onclick="togglePlug(this,'${escapeHtml(name)}')">
      <div class="pn">${escapeHtml(shortName)}</div>
      <div class="pd-brief">${escapeHtml(desc)}</div>
      <div class="pd-arrow" onclick="togglePlugDesc(event,'${escapeHtml(name)}')">▼</div>
      <div class="toggle-sw"></div>
    </div>`;
  }).join('');
  updatePlugCount();
}

/* 插件详情面板 - 动态创建和销毁 (懒创建) */
function togglePlugDesc(e, name) {
  e.stopPropagation();
  e.preventDefault();
  const pcEl = document.getElementById('pc-' + name);
  if (!pcEl) return;
  const arrow = pcEl.querySelector('.pd-arrow');
  let panel = document.getElementById('pd-' + name);
  const wasOpen = panel && panel.classList.contains('show');
  closeAllPlugDesc();
  if (wasOpen) {
    if (panel) { panel.remove(); }
    if (arrow) arrow.textContent = '▼';
    return;
  }
  let info = null;
  for (const plugs of Object.values(PLUGIN_CATS)) {
    if (plugs[name]) { info = plugs[name]; break; }
  }
  if (!info) return;
  const desc = typeof info === 'string' ? info : info.d;
  const features = typeof info === 'string' ? '' : (info.f || '');
  const fw = typeof info === 'string' ? 0 : (info.fw !== undefined ? info.fw : 0);
  const shortName = name.replace(/^(luci-app-|luci-proto-|luci-theme-|luci-mod-|luci-plugin-)/, '');
  const tags = features ? features.split('/').map(f => `<span class="pd-tag">${f.trim()}</span>`).join('') : '';
  const firewallLabel = getFirewallLabel(fw);

  panel = document.createElement('div');
  panel.className = 'pd-full show';
  panel.id = 'pd-' + name;
  panel.style.cssText = 'margin:0;padding:12px 16px;border-radius:var(--r2);background:rgba(6,10,22,.45);border:1px solid var(--brd)';
  panel.innerHTML = `
    <div class="pd-title">${escapeHtml(shortName)}</div>
    ${tags ? `<div class="pd-tags">${tags}</div>` : ''}
    <div class="pd-desc">${escapeHtml(desc)}</div>
    <div class="pd-pkg">包名: <code>${escapeHtml(name)}</code> | 防火墙: <code>${escapeHtml(firewallLabel)}</code></div>
  `;
  pcEl.insertAdjacentElement('afterend', panel);
  if (arrow) arrow.textContent = '▲';
}

function closeAllPlugDesc() {
  document.querySelectorAll('.pd-full.show').forEach(p => p.remove());
  document.querySelectorAll('.pc .pd-arrow').forEach(a => a.textContent = '▼');
}

/* 修复滚动误触：仅在滚动距离 > 10px 时关闭详情面板 */
let lastScrollY = window.scrollY;
document.addEventListener('scroll', () => {
  if (Math.abs(window.scrollY - lastScrollY) > 10) {
    closeAllPlugDesc();
    lastScrollY = window.scrollY;
  }
}, { passive: true });

let lastTouchY = 0;
document.addEventListener('touchmove', (e) => {
  const touch = e.touches[0];
  if (Math.abs(touch.clientY - lastTouchY) > 10) {
    closeAllPlugDesc();
  }
  lastTouchY = touch.clientY;
}, { passive: true });

function togglePlug(el, name) {
  let fw = 0;
  for (const plugs of Object.values(PLUGIN_CATS)) {
    if (plugs[name]) { fw = typeof plugs[name] === 'object' ? (plugs[name].fw !== undefined ? plugs[name].fw : 0) : 0; break; }
  }
  if (!isPluginCompatible(fw)) return;
  if (state.plugins.has(name)) { state.plugins.delete(name); el.classList.remove('on'); }
  else { state.plugins.add(name); el.classList.add('on'); }
  updatePlugCount(); updateSummary(); saveState();
}

function plugAll() {
  const fw = getFirewallType();
  for (const plugs of Object.values(PLUGIN_CATS)) {
    for (const [name, info] of Object.entries(plugs)) {
      const pluginFw = typeof info === 'object' ? (info.fw !== undefined ? info.fw : 0) : 0;
      if (!isPluginCompatible(pluginFw)) continue;
      state.plugins.add(name);
    }
  }
  refreshGrid(); updatePlugCount(); updateSummary(); saveState();
}
function plugNone() { state.plugins.clear(); refreshGrid(); updatePlugCount(); updateSummary(); saveState(); }
function plugInvert() {
  for (const plugs of Object.values(PLUGIN_CATS)) {
    for (const [name, info] of Object.entries(plugs)) {
      const pluginFw = typeof info === 'object' ? (info.fw !== undefined ? info.fw : 0) : 0;
      if (!isPluginCompatible(pluginFw)) continue;
      if (state.plugins.has(name)) state.plugins.delete(name); else state.plugins.add(name);
    }
  }
  refreshGrid(); updatePlugCount(); updateSummary(); saveState();
}
function refreshGrid() {
  document.querySelectorAll('.pc').forEach(el => {
    const name = el.id.replace('pc-', '');
    el.classList.toggle('on', state.plugins.has(name));
  });
}
function updatePlugCount() { document.getElementById('plug-count').textContent = state.plugins.size + ' 已选'; }

// ═══════════════════════════════════════
//  概览
// ═══════════════════════════════════════

function updateSummary() {
  document.getElementById('s-source-branch').textContent = state.sourceBranch;
  document.getElementById('s-target').textContent = state.target + '/' + state.subtarget;
  document.getElementById('s-devices').textContent = state.devices.size || '全部';
  document.getElementById('s-plugins').textContent = state.plugins.size;
  document.getElementById('s-firewall').textContent = state.firewall;
  document.getElementById('s-template').textContent = state.template === 'full' ? '增强版' : '基础版';
  document.getElementById('s-ccache').textContent = document.getElementById('tog-ccache').classList.contains('on') ? '开' : '关';
  document.getElementById('s-upload').textContent = document.getElementById('tog-upload').classList.contains('on') ? '开' : '关';
  document.getElementById('s-custom').textContent = state.customOpts.length || '0';
  const rootPw = document.getElementById('root-pw').value.trim();
  document.getElementById('s-rootpw').textContent = rootPw ? '已设置' : '无';
  document.getElementById('s-lanip').textContent = document.getElementById('lan-ip').value.trim() || '192.168.1.1';
  const wifiSsid = document.getElementById('wifi-ssid').value.trim();
  document.getElementById('s-wifi').textContent = wifiSsid || '默认';
  if (state.plugins.size > 0) {
    const catMap = {};
    for (const [cat, plugs] of Object.entries(PLUGIN_CATS)) {
      for (const name of Object.keys(plugs)) {
        if (state.plugins.has(name)) {
          const shortName = name.replace(/^(luci-app-|luci-proto-|luci-theme-|luci-mod-|luci-plugin-)/, '');
          if (!catMap[cat]) catMap[cat] = [];
          catMap[cat].push(shortName);
        }
      }
    }
    const html = Object.entries(catMap).map(([cat, names]) =>
      `<div style="margin-bottom:6px"><span style="color:var(--cyan);font-weight:700">${escapeHtml(cat)}</span> (${names.length})<br/><span style="color:var(--t2)">${names.map(n => escapeHtml(n)).join('、')}</span></div>`
    ).join('');
    document.getElementById('s-plugin-list').innerHTML = '已选插件:' + html;
  } else {
    document.getElementById('s-plugin-list').innerHTML = '';
  }
}

// ═══════════════════════════════════════
//  自定义选项
// ═══════════════════════════════════════

function addCustomOpt() {
  const keyEl = document.getElementById('custom-key');
  const valEl = document.getElementById('custom-val');
  const key = keyEl.value.trim();
  const val = valEl.value.trim();
  if (!key) { toast('提示', '请输入参数名', true); return; }
  if (state.customOpts.some(o => o.key === key)) { toast('提示', `参数 ${key} 已存在`, true); return; }
  state.customOpts.push({ key, val });
  keyEl.value = '';
  valEl.value = '';
  renderCustomOpts();
  updateSummary();
  saveState();
}

function removeCustomOpt(idx) {
  state.customOpts.splice(idx, 1);
  renderCustomOpts();
  updateSummary();
  saveState();
}

function renderCustomOpts() {
  const list = document.getElementById('custom-opts-list');
  const count = document.getElementById('custom-count');
  count.textContent = `${state.customOpts.length} 项`;
  if (!state.customOpts.length) {
    list.innerHTML = '<div style="font-size:.78em;color:var(--t3);padding:8px 0">暂无自定义选项</div>';
    return;
  }
  list.innerHTML = state.customOpts.map((o, i) => `
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px;padding:8px 12px;background:rgba(6,10,22,.5);border:1px solid var(--brd);border-radius:var(--r2);font-size:.82em">
      <code style="flex:1;color:var(--cyan);word-break:break-all">${escapeHtml(o.key)}${o.val ? '=' + escapeHtml(o.val) : ''}</code>
      <span style="cursor:pointer;color:var(--red);font-size:1.1em;flex-shrink:0" onclick="removeCustomOpt(${i})">✕</span>
    </div>
  `).join('');
}

function getCustomOptsString() {
  return state.customOpts.map(o => o.key + (o.val ? '=' + o.val : '')).join(' ');
}

// ═══════════════════════════════════════
//  触发编译 (含输入验证 + 重试 + 状态检查)
// ═══════════════════════════════════════

async function startBuild() {
  const token = document.getElementById('gh-token').value.trim();
  const repoInput = document.getElementById('gh-repo').value.trim();
  const btn = document.getElementById('btn-build');
  const logPanel = document.getElementById('log-panel');

  // 输入验证
  if (!token) { toast('错误', '请输入 GitHub Token', true); return; }
  if (!isValidToken(token)) {
    toast('错误', 'Token 格式不正确，必须以 ghp_ 或 github_pat_ 开头', true);
    return;
  }

  const lanIp = document.getElementById('lan-ip').value.trim();
  if (lanIp && !isValidLanIP(lanIp)) {
    toast('错误', 'LAN IP 格式不正确，必须是 x.x.x.x 格式 (每段 0-255)', true);
    return;
  }

  const wifiPw = document.getElementById('wifi-password').value.trim();
  if (wifiPw && wifiPw.length >= 8 && wifiPw.length <= 63) {
    const specialChars = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/;
    if (!specialChars.test(wifiPw)) {
      toast('提示', 'WiFi 密码建议包含特殊字符以提高安全性', false);
    }
  }

  let owner, repo;
  if (repoInput && repoInput.includes('/')) {
    [owner, repo] = repoInput.split('/');
  } else {
    const pathParts = window.location.pathname.split('/').filter(Boolean);
    owner = window.location.hostname.replace('.github.io', '');
    repo = pathParts[0] || '';
    if (!owner || !repo) {
      toast('错误', '无法自动检测仓库，请手动输入编译仓库 (owner/repo)', true);
      return;
    }
  }

  const plugins = [...state.plugins].join(' ');
  const customConfig = document.getElementById('custom-config').value.trim();
  const customB64 = customConfig ? btoa(unescape(encodeURIComponent(customConfig))) : '';

  const inputs = {
    source_branch: state.sourceBranch,
    target: state.target,
    subtarget: state.subtarget,
    firewall: state.firewall,
    template: state.template,
    profile: [...state.devices].join(' '),
    plugins: plugins,
    root_password: document.getElementById('root-pw').value.trim(),
    lan_ip: lanIp,
    wifi_ssid: document.getElementById('wifi-ssid').value.trim(),
    wifi_password: wifiPw,
    custom_config: customB64,
    enable_ccache: document.getElementById('tog-ccache').classList.contains('on') ? 'true' : 'false',
    upload_artifacts: document.getElementById('tog-upload').classList.contains('on') ? 'true' : 'false',
  };

  btn.disabled = true;
  btn.innerHTML = '<span class="spin"></span>正在触发编译...';
  logPanel.classList.add('show');
  if (buildRetryCount === 0) logPanel.innerHTML = '';

  log('info', '📡 正在连接 GitHub API...');
  log('info', `📦 仓库: ${owner}/${repo}`);
  log('info', `🌿 源码分支: ${inputs.source_branch}`);
  log('info', `🎯 目标: ${inputs.target}/${inputs.subtarget}`);
  log('info', `📦 模板: ${inputs.template === 'full' ? '增强版' : '基础版'}`);
  log('info', `🧩 插件: ${plugins || '(仅默认)'}`);
  log('info', `📱 设备: ${inputs.profile || '(全部)'}`);
  if (inputs.wifi_ssid) log('info', `📶 WiFi: ${inputs.wifi_ssid}`);

  try {
    log('info', '🔍 检查 workflow 文件...');
    const ctrl = new AbortController();
    const tid = setTimeout(() => ctrl.abort(), 30000);
    const [repoRes, workflowRes] = await Promise.all([
      fetch(`https://api.github.com/repos/${owner}/${repo}`, {
        signal: ctrl.signal,
        headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' }
      }),
      fetch(`https://api.github.com/repos/${owner}/${repo}/actions/workflows`, {
        signal: ctrl.signal,
        headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' }
      })
    ]);
    clearTimeout(tid);

    if (!repoRes.ok) {
      const err = await repoRes.json().catch(() => ({}));
      throw new Error(err.message || `仓库不存在或无权限 (HTTP ${repoRes.status})`);
    }
    const repoInfo = await repoRes.json();
    const defaultBranch = repoInfo.default_branch || 'main';
    log('info', `🌿 默认分支: ${defaultBranch}`);

    if (!workflowRes.ok) {
      const err = await workflowRes.json().catch(() => ({}));
      throw new Error(err.message || `HTTP ${workflowRes.status}`);
    }

    const workflows = await workflowRes.json();
    const buildWorkflow = workflows.workflows?.find(w =>
      w.name.includes('Build') || w.path?.includes('build-openwrt')
    );

    if (!buildWorkflow) {
      log('warn', '⚠️ 未找到 build-openwrt.yml，尝试直接触发...');
    } else {
      log('ok', `✅ 找到工作流: ${buildWorkflow.name}`);
    }

    log('info', '🚀 正在触发编译...');
    const ctrl2 = new AbortController();
    const tid2 = setTimeout(() => ctrl2.abort(), 30000);
    const dispatchRes = await fetch(
      `https://api.github.com/repos/${owner}/${repo}/actions/workflows/build-openwrt.yml/dispatches`,
      {
        method: 'POST',
        signal: ctrl2.signal,
        headers: {
          'Authorization': `token ${token}`,
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ ref: defaultBranch, inputs }),
      }
    );
    clearTimeout(tid2);

    if (dispatchRes.status === 204 || dispatchRes.ok) {
      log('ok', '✅ 编译任务已成功触发!');
      log('info', `🔗 前往查看: https://github.com/${owner}/${repo}/actions`);
      toast('成功', '编译任务已触发，正在排队中...');
      buildRetryCount = 0;
      startWorkflowCheck(token, owner, repo);
    } else {
      const err = await dispatchRes.json().catch(() => ({}));
      throw new Error(err.message || `HTTP ${dispatchRes.status}`);
    }
  } catch (e) {
    log('err', `❌ 错误: ${e.message}`);
    buildRetryCount++;
    if (buildRetryCount <= MAX_RETRY) {
      log('warn', `🔄 将在 3 秒后自动重试 (${buildRetryCount}/${MAX_RETRY})...`);
      btn.innerHTML = `<span class="spin"></span>重试中 (${buildRetryCount}/${MAX_RETRY})...`;
      setTimeout(() => startBuild(), 3000);
      return;
    } else {
      log('err', `❌ 已达到最大重试次数 (${MAX_RETRY})，请检查配置后手动重试`);
      logPanel.innerHTML += `<div style="margin-top:12px;text-align:center">
        <button class="bx" onclick="resetAndRetry()" style="font-size:.85em;padding:8px 20px">🔄 重试编译</button>
      </div>`;
      toast('失败', e.message + ' (点击日志面板中的重试按钮)', true);
      buildRetryCount = 0;
    }
  }

  btn.disabled = false;
  btn.innerHTML = '🚀 开始编译固件';
}

/* 重置重试计数并重新触发编译 */
function resetAndRetry() {
  buildRetryCount = 0;
  startBuild();
}

// ═══════════════════════════════════════
//  Workflow 状态实时检查 (每 30 秒)
// ═══════════════════════════════════════

function startWorkflowCheck(token, owner, repo) {
  if (workflowCheckTimer) clearInterval(workflowCheckTimer);
  let checkCount = 0;
  const maxChecks = 60;

  workflowCheckTimer = setInterval(async () => {
    checkCount++;
    if (checkCount > maxChecks) {
      clearInterval(workflowCheckTimer);
      log('info', '⏰ 已停止自动状态检查，请前往 GitHub Actions 查看');
      return;
    }
    try {
      const res = await fetch(
        `https://api.github.com/repos/${owner}/${repo}/actions/runs?per_page=1`,
        { headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' } }
      );
      if (!res.ok) return;
      const data = await res.json();
      const run = data.workflow_runs?.[0];
      if (!run) return;

      const statusMap = { 'queued': '⏳ 排队中', 'in_progress': '🔨 编译中', 'completed': '✅ 已完成' };
      const conclusionMap = { 'success': '🎉 成功', 'failure': '❌ 失败', 'cancelled': '⚠️ 已取消', 'timed_out': '⏰ 超时' };

      let statusText = statusMap[run.status] || run.status;
      if (run.status === 'completed' && run.conclusion) {
        statusText = conclusionMap[run.conclusion] || run.conclusion;
      }

      log('info', `📊 [${checkCount}] 状态: ${statusText} | ${run.display_title || ''}`);

      if (run.status === 'completed') {
        clearInterval(workflowCheckTimer);
        if (run.conclusion === 'success') {
          toast('编译完成', '固件编译成功！前往 GitHub Actions 下载');
        } else {
          toast('编译结束', `状态: ${run.conclusion}`, true);
        }
      }
    } catch (e) {
      // 静默失败
    }
  }, 30000);
}

// ═══════════════════════════════════════
//  日志和通知
// ═══════════════════════════════════════

function log(type, msg) {
  const logPanel = document.getElementById('log-panel');
  const cls = { info: 'log-info', ok: 'log-ok', err: 'log-err', warn: 'log-warn' }[type] || '';
  const div = document.createElement('div');
  div.className = `log-line ${cls}`;
  div.textContent = `${new Date().toLocaleTimeString()} ${msg}`;
  logPanel.appendChild(div);
  logPanel.scrollTop = logPanel.scrollHeight;
}

function toast(title, body, err) {
  const t = document.createElement('div');
  t.className = 'toast';
  t.style.borderColor = err ? 'rgba(248,113,113,.3)' : 'rgba(52,211,153,.3)';
  t.innerHTML = `<div class="tt" style="color:${err?'var(--red)':'var(--grn)'}">${escapeHtml(title)}</div><div class="tb">${escapeHtml(body)}</div>`;
  document.body.appendChild(t);
  setTimeout(() => t.remove(), 5000);
}

document.addEventListener('change', () => { updateSummary(); debouncedSave(); });
init();

