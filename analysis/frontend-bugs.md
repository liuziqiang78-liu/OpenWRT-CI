# OpenWRT-CI 前端代码 Bug 分析报告

**分析时间**: 2026-05-06  
**分析范围**: index.html, styles.css, app.js, devices.js, nss-modules.js, plugins.js  
**Bug 总数**: 22 个

---

## 摘要

| 严重程度 | 数量 |
|---------|------|
| 🔴 致命 | 2 |
| 🟠 严重 | 6 |
| 🟡 中等 | 8 |
| 🔵 建议 | 6 |

---

## 🔴 致命 (Fatal)

### BUG-01: PLATFORM_GROUPS 遗漏大量平台，22+ 类设备完全不可选

**文件**: `app.js` 第 26-33 行  
**问题**: `PLATFORM_GROUPS` 仅包含 3 个平台组（qualcommax、ipq40xx、ipq806x），但 `DEVICES` 对象中定义了 27 个子平台 key。以下平台的设备**在 UI 中完全无法访问**：

- `qualcommbe-ipq95xx` (2 设备)
- `mediatek-filogic` (150+ 设备)
- `mediatek-mt7622` (26 设备)
- `mediatek-mt7623` (3 设备)
- `mediatek-mt7629` (5 设备)
- `ath79-generic` (200+ 设备)
- `ath79-tiny` (15 设备)
- `ath79-nand` (31 设备)
- `ath79-mikrotik` (22 设备)
- `ramips-mt7621` (250+ 设备)
- `ramips-mt7620` (80+ 设备)
- `ramips-mt76x8` (100+ 设备)
- `bcm53xx` (40+ 设备)
- `bcm4908` (7 设备)
- `mvebu-cortexa9` (33 设备)
- `mvebu-cortexa72` (12 设备)
- `mvebu-cortexa53` (11 设备)
- `lantiq-vr9` (26 设备)
- `lantiq-xway_legacy` (5 设备)
- `lantiq-falcon` (12 设备)
- `lantiq-danube` (14 设备)
- `airoha-en7523` (1 设备)
- `airoha-an7581` (5 设备)
- `airoha-an7583` (2 设备)
- `rockchip` (1 设备)

**影响**: 超过 1000 个设备在 UI 中完全不可见、不可选。用户无法编译这些平台的固件。

**修复代码**:
```javascript
// app.js 第 26 行，补全 PLATFORM_GROUPS
const PLATFORM_GROUPS = [
  {id:'qualcommax',name:'Qualcomm IPQ',icon:'🔵',subs:[{k:'qualcommax-ipq807x',n:'IPQ807x'},{k:'qualcommax-ipq60xx',n:'IPQ60xx'},{k:'qualcommax-ipq50xx',n:'IPQ50xx'}]},
  {id:'qualcommbe',name:'Qualcomm BE',icon:'🟢',subs:[{k:'qualcommbe-ipq95xx',n:'IPQ95xx'}]},
  {id:'ipq40xx',name:'IPQ40xx',icon:'🔵',subs:[{k:'ipq40xx',n:'IPQ40xx'}]},
  {id:'ipq806x',name:'IPQ806x',icon:'🔵',subs:[{k:'ipq806x',n:'IPQ806x'}]},
  {id:'mediatek',name:'MediaTek',icon:'🟣',subs:[{k:'mediatek-filogic',n:'Filogic'},{k:'mediatek-mt7622',n:'MT7622'},{k:'mediatek-mt7623',n:'MT7623'},{k:'mediatek-mt7629',n:'MT7629'}]},
  {id:'ath79',name:'Atheros MIPS',icon:'🟠',subs:[{k:'ath79-generic',n:'Generic'},{k:'ath79-tiny',n:'Tiny'},{k:'ath79-nand',n:'NAND'},{k:'ath79-mikrotik',n:'MikroTik'}]},
  {id:'ramips',name:'Ralink MIPS',icon:'🟡',subs:[{k:'ramips-mt7621',n:'MT7621'},{k:'ramips-mt7620',n:'MT7620'},{k:'ramips-mt76x8',n:'MT76x8'}]},
  {id:'broadcom',name:'Broadcom',icon:'🔴',subs:[{k:'bcm53xx',n:'BCM53xx'},{k:'bcm4908',n:'BCM4908'}]},
  {id:'mvebu',name:'Marvell Armada',icon:'⚪',subs:[{k:'mvebu-cortexa9',n:'Cortex-A9'},{k:'mvebu-cortexa72',n:'Cortex-A72'},{k:'mvebu-cortexa53',n:'Cortex-A53'}]},
  {id:'lantiq',name:'Lantiq',icon:'🟤',subs:[{k:'lantiq-vr9',n:'VR9'},{k:'lantiq-xway_legacy',n:'XWAY Legacy'},{k:'lantiq-falcon',n:'Falcon'},{k:'lantiq-danube',n:'Danube'}]},
  {id:'airoha',name:'Airoha',icon:'🟧',subs:[{k:'airoha-en7523',n:'EN7523'},{k:'airoha-an7581',n:'AN7581'},{k:'airoha-an7583',n:'AN7583'}]},
  {id:'other',name:'其他',icon:'⬜',subs:[{k:'rockchip',n:'Rockchip'}]},
];
```

---

### BUG-02: NSS_MODULES 定义但从未使用（死代码）

**文件**: `nss-modules.js` 全文 (第 1-10 行)  
**问题**: `NSS_MODULES` 数组定义了 13 个内核模块，但在 `app.js`、`devices.js`、`plugins.js` 中均无任何引用。HTML 中通过 `<script src="assets/nss-modules.js"></script>` 加载，但变量从未被读取。

**影响**: 如果这些模块应在编译时自动包含，则编译输出会缺少 NSS 内核模块，导致硬件加速失效。如果是遗留代码，则浪费带宽。

**修复代码**:
```javascript
// 方案 A：如果 NSS 模块应自动包含，在 app.js 的 startBuild() 中添加
// 在构建 inputs 对象时加入：
inputs.nss_modules = NSS_MODULES.join(' ');

// 方案 B：如果不再需要，删除 nss-modules.js 和 index.html 中的 script 标签
```

---

## 🟠 严重 (Critical)

### BUG-03: plugAll() 和 plugInvert() 绕过防火墙兼容性检查

**文件**: `app.js` 第 631-640 行  
**问题**: `plugAll()` 直接 `state.plugins.add(name)` 不检查 `isPluginCompatible()`。`plugInvert()` 同样不检查。当用户选择 nftables 防火墙时，`plugAll()` 会选中 `fw: 1`（仅 iptables）的插件，导致编译失败或功能异常。

受影响插件（fw:1，仅 iptables）：luci-app-privoxy、luci-app-banip、luci-app-fwknopd、luci-app-appfilter、luci-app-antiblock、luci-app-tinyproxy、luci-app-igmp-proxy、luci-app-syncdial、luci-app-pppoe-server、luci-app-eoip、luci-app-dcwapd、luci-app-omcproxy、luci-app-msd_lite、luci-app-wifischedule、luci-app-scutclient、luci-app-njitclient、luci-app-cd8021x、luci-app-sysuh3c、luci-app-ua2f、luci-app-coovachilli、luci-app-rp-pppoe-server。

**修复代码**:
```javascript
// app.js 第 631 行
function plugAll() {
  for (const plugs of Object.values(PLUGIN_CATS)) {
    for (const [name, info] of Object.entries(plugs)) {
      const fw = typeof info === 'object' ? (info.fw !== undefined ? info.fw : 0) : 0;
      if (isPluginCompatible(fw)) state.plugins.add(name);
    }
  }
  refreshGrid(); updatePlugCount(); updateSummary(); saveState();
}

function plugInvert() {
  for (const plugs of Object.values(PLUGIN_CATS)) {
    for (const [name, info] of Object.entries(plugs)) {
      const fw = typeof info === 'object' ? (info.fw !== undefined ? info.fw : 0) : 0;
      if (!isPluginCompatible(fw)) continue; // 跳过不兼容的插件
      if (state.plugins.has(name)) state.plugins.delete(name);
      else state.plugins.add(name);
    }
  }
  refreshGrid(); updatePlugCount(); updateSummary(); saveState();
}
```

---

### BUG-04: toggleAllDevices 搜索过滤条件与 initDevices 不一致

**文件**: `app.js` 第 425-440 行 vs 第 340-360 行  
**问题**: `toggleAllDevices()` 搜索过滤仅匹配 `d.n`：
```javascript
devs = devs.filter(d => d.n.toLowerCase().includes(searchQuery));
```
但 `initDevices()` 和 `searchDevices()` 过滤条件包含三个字段：
```javascript
d.n.toLowerCase().includes(searchQuery) || d.id.toLowerCase().includes(searchQuery) || d.c.toLowerCase().includes(searchQuery)
```

**影响**: 用户搜索 "IPQ8074" 时，`initDevices` 能匹配到所有 IPQ8074 设备，但 `toggleAllDevices` 只检查设备名称（n），不检查芯片型号（c），导致全选行为与显示不一致——用户看到的设备列表和全选操作的范围不同。

**修复代码**:
```javascript
// app.js 第 428 行
function toggleAllDevices() {
  let devs = DEVICES[currentSubKey] || [];
  if (searchQuery) devs = devs.filter(d =>
    d.n.toLowerCase().includes(searchQuery) ||
    d.id.toLowerCase().includes(searchQuery) ||
    d.c.toLowerCase().includes(searchQuery)
  );
  // ... 其余不变
}
```

---

### BUG-05: IntersectionObserver 内存泄漏

**文件**: `app.js` 第 407-415 行  
**问题**: `setupDeviceLazyLoad()` 创建 IntersectionObserver 但从不调用 `observer.disconnect()`。每次调用 `initDevices()`（切换平台、搜索、全选时）都会创建新 observer，旧 observer 仍持有对已移除 DOM 元素的引用。

```javascript
function setupDeviceLazyLoad(allDevs) {
  const sentinel = document.getElementById('load-more-devices');
  if (!sentinel) return;
  const observer = new IntersectionObserver((entries) => {
    if (entries[0].isIntersecting) loadMoreDevices();
  }, { threshold: 0.1 });
  observer.observe(sentinel);
  // ← 从未 disconnect
}
```

**修复代码**:
```javascript
// 在全局作用域添加
let deviceObserver = null;

function setupDeviceLazyLoad(allDevs) {
  // 清理旧 observer
  if (deviceObserver) { deviceObserver.disconnect(); deviceObserver = null; }
  const sentinel = document.getElementById('load-more-devices');
  if (!sentinel) return;
  deviceObserver = new IntersectionObserver((entries) => {
    if (entries[0].isIntersecting) loadMoreDevices();
  }, { threshold: 0.1 });
  deviceObserver.observe(sentinel);
}

// 在 initDevices() 开头也清理
function initDevices() {
  if (deviceObserver) { deviceObserver.disconnect(); deviceObserver = null; }
  // ... 其余不变
}
```

---

### BUG-06: innerHTML 未转义导致 XSS 风险

**文件**: `app.js` 多处  
**问题**: 以下位置使用 `innerHTML` 拼接字符串，其中数据未经过 `escapeHtml()` 处理：

1. **renderGrid()** 第 551-566 行: `name`、`desc`、`features`、`shortName` 直接拼入 HTML
2. **renderDeviceGroupHTML()** 第 364-386 行: `d.n`、`d.c`、`d.id` 直接拼入 HTML
3. **togglePlugDesc()** 第 597-607 行: `shortName`、`desc`、`features` 直接拼入 HTML
4. **updateSummary()** 第 678-683 行: `cat`、`shortName` 直接拼入 HTML
5. **renderCustomOpts()** 第 723-730 行: `o.key`、`o.val` 直接拼入 HTML

虽然当前数据来自硬编码的 `PLUGIN_CATS` 和 `DEVICES`（可信），但 `customOpts` 的 key/val 来自用户输入，存在 XSS 风险。

**修复代码**:
```javascript
// renderCustomOpts() 第 723 行 - 用户输入必须转义
list.innerHTML = state.customOpts.map((o, i) => `
  <div style="...">
    <code style="...">${escapeHtml(o.key)}${o.val ? '=' + escapeHtml(o.val) : ''}</code>
    <span style="..." onclick="removeCustomOpt(${i})">✕</span>
  </div>
`).join('');

// renderGrid() 第 551 行 - 防御性转义
grid.innerHTML = Object.entries(plugs).map(([name, info]) => {
  const desc = typeof info === 'string' ? info : info.d;
  const features = typeof info === 'string' ? '' : (info.f || '');
  const shortName = name.replace(/^(luci-app-|luci-proto-|luci-theme-|luci-mod-|luci-plugin-)/, '');
  // ... 使用 escapeHtml() 包裹所有动态值
  return `<div class="${cls}" id="pc-${escapeHtml(name)}" onclick="togglePlug(this,'${escapeHtml(name)}')">
    <div class="pn">${escapeHtml(shortName)}</div>
    <div class="pd-brief">${escapeHtml(desc)}</div>
    ...
  </div>`;
}).join('');
```

---

### BUG-07: searchDevices 输入无防抖，频繁触发 DOM 重绘

**文件**: `app.js` 第 297 行 + `index.html` 第 67 行  
**问题**: 搜索框使用 `oninput="searchDevices(this.value)"`，每次按键都直接调用 `searchDevices()`，该函数遍历所有平台组的所有设备（1000+ 条目），并调用 `initDevices()` 完整重绘 DOM。

**影响**: 用户快速输入时，每秒触发 5-10 次全量搜索和 DOM 重绘，造成明显卡顿，尤其在低端设备上。

**修复代码**:
```javascript
// app.js - 在全局区域添加防抖搜索
const debouncedSearchDevices = debounce((q) => searchDevices(q), 250);

// index.html 第 67 行修改
// <input type="text" id="dev-search" placeholder="搜索设备平台/品牌..." oninput="debouncedSearchDevices(this.value)">
```

---

### BUG-08: document 级 change 事件监听过于宽泛

**文件**: `app.js` 第 980 行  
**问题**:
```javascript
document.addEventListener('change', () => { updateSummary(); debouncedSave(); });
```
监听整个 document 的所有 change 事件，包括 select、input、checkbox 等。这会导致：
1. 任何子元素的 change 都触发 `updateSummary()` 和 `debouncedSave()`，包括不相关的元素
2. 与 `bindAutoSave()` 中已绑定的 input 事件形成重复触发
3. 如果页面中有第三方脚本触发 change 事件，也会意外触发保存

**修复代码**:
```javascript
// 移除全局 change 监听，改为在特定元素上绑定
// 删除第 980 行
// document.addEventListener('change', () => { updateSummary(); debouncedSave(); });

// 在 bindAutoSave() 中补充 firewall-select 的 change 事件（已有的可以保留）
function bindAutoSave() {
  // ... 现有代码 ...
  document.getElementById('firewall-select').addEventListener('change', () => {
    updateSummary(); debouncedSave();
  });
}
```

---

## 🟡 中等 (Medium)

### BUG-09: CSS mask-image 缺少 -webkit 前缀

**文件**: `styles.css` 第 20 行  
**问题**:
```css
mask-image: radial-gradient(ellipse 70% 60% at 50% 40%, #000, transparent)
```
Safari 浏览器（包括 iOS Safari）需要 `-webkit-mask-image` 前缀才能正常工作。当前在 Safari 上背景网格装饰将完全不可见。

**修复代码**:
```css
/* styles.css 第 20 行 */
.ambient::before {
  content: ''; position: absolute; inset: 0;
  background-image: linear-gradient(rgba(56,189,248,.025) 1px, transparent 1px),
                    linear-gradient(90deg, rgba(56,189,248,.025) 1px, transparent 1px);
  background-size: 80px 80px;
  -webkit-mask-image: radial-gradient(ellipse 70% 60% at 50% 40%, #000, transparent);
  mask-image: radial-gradient(ellipse 70% 60% at 50% 40%, #000, transparent);
}
```

---

### BUG-10: scroll/touchmove 全局关闭插件详情面板导致误触

**文件**: `app.js` 第 617-618 行  
**问题**:
```javascript
document.addEventListener('scroll', closeAllPlugDesc, { passive: true });
document.addEventListener('touchmove', closeAllPlugDesc, { passive: true });
```
任何滚动（包括页面滚动、设备列表滚动、日志面板滚动）都会关闭所有已展开的插件详情面板。用户在查看插件详情时如果误触滚动，面板立即消失。

**修复代码**:
```javascript
// 改为只在插件区域外滚动时关闭
document.addEventListener('scroll', debounce(() => {
  const plugGrid = document.getElementById('plug-grid');
  if (!plugGrid) return;
  const rect = plugGrid.getBoundingClientRect();
  // 如果插件区域不在视口中，才关闭
  if (rect.bottom < 0 || rect.top > window.innerHeight) {
    closeAllPlugDesc();
  }
}, 150), { passive: true });
```

---

### BUG-11: WiFi 密码长度验证不完整

**文件**: `app.js` 第 756-762 行  
**问题**:
```javascript
const wifiPw = document.getElementById('wifi-password').value.trim();
if (wifiPw && wifiPw.length >= 8 && wifiPw.length <= 63) {
  const specialChars = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/;
  if (!specialChars.test(wifiPw)) {
    toast('提示', 'WiFi 密码建议包含特殊字符以提高安全性', false);
  }
}
```
1. 密码长度 < 8 或 > 63 时不提示任何警告，但 WPA2/WPA3 要求 8-63 字符
2. 没有检查空格（WPA 密码可以包含空格，但用户可能误输入前后空格，已 trim）
3. 没有检查纯数字密码的弱密码提示

**修复代码**:
```javascript
const wifiPw = document.getElementById('wifi-password').value;
if (wifiPw) {
  if (wifiPw.length < 8) {
    toast('警告', 'WiFi 密码至少需要 8 个字符', true);
    return; // 阻止提交
  }
  if (wifiPw.length > 63) {
    toast('警告', 'WiFi 密码不能超过 63 个字符', true);
    return;
  }
}
```

---

### BUG-12: switchPlatformGroup 切换平台时清空所有已选设备

**文件**: `app.js` 第 260-273 行  
**问题**:
```javascript
function switchPlatformGroup(gid) {
  // ...
  state.devices.clear(); // ← 强制清空所有设备选择
  initDevices();
  // ...
}
```
如果用户先选了 qualcommax 平台的设备，再切换到 mediatek 平台查看设备，所有已选的 qualcommax 设备会被清空。用户无法跨平台选择设备。

**修复代码**:
```javascript
function switchPlatformGroup(gid) {
  currentPlatformGroup = gid;
  const group = PLATFORM_GROUPS.find(g=>g.id===gid);
  currentSubKey = group.subs[0].k;
  const parts = currentSubKey.split('-');
  state.target = parts[0];
  state.subtarget = parts.slice(1).join('-') || '';
  document.querySelectorAll('.pgroup').forEach(t=>t.classList.toggle('on',t.dataset.g===gid));
  renderSubTabs();
  // 不再清空 state.devices，只重新渲染当前平台的设备
  initDevices();
  updateSummary();
  saveState();
}
```
> 注意：此修复需同时调整编译逻辑，确保跨平台设备选择在提交时正确处理。

---

### BUG-13: log() 使用 innerHTML += 效率低下

**文件**: `app.js` 第 965-968 行  
**问题**:
```javascript
function log(type, msg) {
  const logPanel = document.getElementById('log-panel');
  const cls = { info: 'log-info', ok: 'log-ok', err: 'log-err', warn: 'log-warn' }[type] || '';
  logPanel.innerHTML += `<div class="log-line ${cls}">${new Date().toLocaleTimeString()} ${escapeHtml(msg)}</div>`;
  logPanel.scrollTop = logPanel.scrollHeight;
}
```
每次 `innerHTML +=` 都会：1) 序列化整个 DOM 子树为字符串，2) 拼接新内容，3) 解析完整 HTML 并重建所有 DOM 节点。日志条目越多，性能越差（O(n²)）。

**修复代码**:
```javascript
function log(type, msg) {
  const logPanel = document.getElementById('log-panel');
  const cls = { info: 'log-info', ok: 'log-ok', err: 'log-err', warn: 'log-warn' }[type] || '';
  const div = document.createElement('div');
  div.className = `log-line ${cls}`;
  div.textContent = `${new Date().toLocaleTimeString()} ${msg}`;
  logPanel.appendChild(div);
  logPanel.scrollTop = logPanel.scrollHeight;
}
```

---

### BUG-14: renderGrid() 中 plugin name 用于 id 和 onclick 拼接存在转义问题

**文件**: `app.js` 第 556-566 行  
**问题**:
```javascript
return `
<div class="${cls}" id="pc-${name}" onclick="togglePlug(this,'${name}')">
```
如果插件名称包含单引号或特殊字符（虽然当前数据没有，但属于防御性编程缺失），会导致 HTML 解析错误或 onclick 失效。同时 `id="pc-${name}"` 中如果 name 包含特殊字符会生成无效 id。

**修复代码**:
```javascript
// 使用 data 属性代替 onclick 内联
return `
<div class="${cls}" id="pc-${CSS.escape(name)}" data-name="${escapeHtml(name)}">
  ...
</div>`;

// 在 initPlugins 末尾添加事件委托
document.getElementById('plug-grid').addEventListener('click', (e) => {
  const pc = e.target.closest('.pc');
  if (!pc) return;
  const arrow = e.target.closest('.pd-arrow');
  if (arrow) {
    togglePlugDesc(e, pc.dataset.name);
  } else {
    togglePlug(pc, pc.dataset.name);
  }
});
```

---

### BUG-15: 仅有一个 CSS 响应式断点 (600px)

**文件**: `styles.css` 第 60 行、第 231 行  
**问题**: 只有 `@media(max-width:600px)` 一个断点。在 601px-1024px 的平板设备上：
- `.dg`（设备网格）保持 2 列，但设备卡片内容可能溢出
- `.sg`（概览网格）使用 `auto-fill` 在小平板上可能只有 2-3 列，显示不完整
- `.btn-go` 在平板竖屏时不够醒目

**修复代码**:
```css
/* 添加平板断点 */
@media(max-width:1024px) {
  .shell { padding: 0 16px 60px; }
  .card { padding: 22px; }
}

@media(min-width:601px) and (max-width:768px) {
  .dg { grid-template-columns: 1fr; }
  .sg { grid-template-columns: repeat(3, 1fr); }
}
```

---

### BUG-16: startBuild 中 buildRetryCount 在成功后不重置为 0 的时机问题

**文件**: `app.js` 第 870-900 行  
**问题**: `buildRetryCount` 在编译成功时重置为 0（第 870 行），但在 `catch` 块中（第 883 行）失败重试后，如果重试成功，`buildRetryCount` 已经是 2（MAX_RETRY），此时 `resetAndRetry()` 按钮已添加到日志面板。但成功后该按钮不会被移除，用户可能误点。

**修复代码**:
```javascript
if (dispatchRes.status === 204 || dispatchRes.ok) {
  log('ok', '✅ 编译任务已成功触发!');
  log('info', `🔗 前往查看: https://github.com/${owner}/${repo}/actions`);
  toast('成功', '编译任务已触发，正在排队中...');
  buildRetryCount = 0;
  // 移除可能存在的重试按钮
  const retryBtn = logPanel.querySelector('[onclick="resetAndRetry()"]');
  if (retryBtn) retryBtn.closest('div').remove();
  startWorkflowCheck(token, owner, repo);
}
```

---

### BUG-17: saveState 在 DOM 未就绪时可能抛出异常

**文件**: `app.js` 第 70-96 行  
**问题**: `saveState()` 直接调用 `document.getElementById('gh-token').value` 等。虽然当前调用时机在 `init()` 之后，但如果未来有代码在 DOM 就绪前调用 `saveState()`（如 `debouncedSave` 在异常路径中被触发），会抛出 `Cannot read properties of null`。

**修复代码**:
```javascript
function saveState() {
  const el = (id) => document.getElementById(id);
  const val = (id) => { const e = el(id); return e ? e.value : ''; };
  const hasClass = (id, cls) => { const e = el(id); return e ? e.classList.contains(cls) : false; };
  const data = {
    // ... 使用 val() 和 hasClass() 替代直接 .value 和 .classList.contains()
    ghToken: val('gh-token'),
    ghRepo: val('gh-repo'),
    // ...
  };
  // ...
}
```

---

## 🔵 建议 (Suggestions)

### BUG-18: 无 ARIA 无障碍属性

**文件**: `index.html` 全文  
**问题**: 整个页面没有任何 `aria-label`、`role`、`aria-expanded`、`aria-selected` 等无障碍属性。对于屏幕阅读器用户：
- 卡片标题没有 `role="heading"`
- 开关按钮没有 `role="switch"` 和 `aria-checked`
- 标签页没有 `role="tablist"` / `role="tab"`
- 设备/插件选择没有 `role="checkbox"` 和 `aria-checked`

**修复建议**: 为关键交互元素添加 ARIA 属性。

---

### BUG-19: 内联事件处理器（onclick/oninput）

**文件**: `index.html` 多处  
**问题**: 大量使用 `onclick="..."`、`oninput="..."` 等内联事件处理器（约 15 处）。这违反了内容安全策略（CSP），如果未来启用 CSP `script-src 'self'` 会全部失效。

**修复建议**: 逐步迁移到 `addEventListener` 或事件委托。

---

### BUG-20: GitHub Token 明文存储在 localStorage

**文件**: `app.js` 第 81 行  
**问题**:
```javascript
ghToken: document.getElementById('gh-token').value,
```
Token 被明文存储在 `localStorage` 中。任何能执行 JS 的攻击（XSS、恶意扩展）都能窃取 Token。虽然 BUG-06 已指出 XSS 风险，但即使修复了 XSS，localStorage 仍不安全。

**修复建议**: 至少添加警告提示，理想情况下使用 sessionStorage 或每次输入。

---

### BUG-21: 缺少语义化 HTML 元素

**文件**: `index.html` 全文  
**问题**: 页面没有 `<main>`、`<section>`、`<article>`、`<nav>` 等语义化标签。所有内容都在 `<div>` 中，不利于 SEO 和辅助技术。

**修复建议**:
```html
<body>
  <header class="hdr">...</header>
  <main class="shell">
    <section id="card-auth" class="card">...</section>
    <section id="card-build" class="card">...</section>
    <!-- ... -->
  </main>
</body>
```

---

### BUG-22: closeAllPlugDesc 移除元素而非隐藏

**文件**: `app.js` 第 612-615 行  
**问题**:
```javascript
function closeAllPlugDesc() {
  document.querySelectorAll('.pd-full.show').forEach(p => p.remove());
  document.querySelectorAll('.pc .pd-arrow').forEach(a => a.textContent = '▼');
}
```
使用 `p.remove()` 销毁 DOM 元素而非 `p.classList.remove('show')` 隐藏。这意味着每次关闭再打开详情面板都需要重新创建 DOM，增加不必要的 DOM 操作。

**修复建议**:
```javascript
function closeAllPlugDesc() {
  document.querySelectorAll('.pd-full.show').forEach(p => {
    p.classList.remove('show');
    p.style.display = 'none';
  });
  document.querySelectorAll('.pc .pd-arrow').forEach(a => a.textContent = '▼');
}
```

---

## 附录：按文件汇总

| 文件 | 致命 | 严重 | 中等 | 建议 |
|------|------|------|------|------|
| app.js | 2 | 5 | 6 | 2 |
| styles.css | 0 | 0 | 2 | 0 |
| index.html | 0 | 0 | 0 | 3 |
| devices.js | 0 | 0 | 0 | 0 |
| plugins.js | 0 | 0 | 0 | 0 |
| nss-modules.js | 0 | 1 (含在致命中) | 0 | 0 |

## 优先修复建议

1. **立即修复** (P0): BUG-01 (平台缺失) - 影响 1000+ 设备不可选
2. **立即修复** (P0): BUG-03 (插件全选绕过防火墙检查) - 可能导致编译失败
3. **尽快修复** (P1): BUG-02 (NSS 模块未使用)、BUG-04 (搜索过滤不一致)、BUG-05 (内存泄漏)、BUG-06 (XSS)
4. **计划修复** (P2): BUG-07 (搜索防抖)、BUG-08 (事件监听)、BUG-09-17
5. **长期改进** (P3): BUG-18-22
