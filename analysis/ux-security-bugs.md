# OpenWRT-CI UX & 安全审计报告

**审计日期:** 2026-05-06  
**审计范围:** `index.html`, `assets/styles.css`, `assets/app.js`, `assets/plugins.js`

---

## 一、UX 问题

### UX-01 | 加载屏幕遮挡逻辑不完整

- **位置:** `styles.css` (`.loading-screen`), `app.js` (`init()`)
- **问题:** 加载屏幕通过 `body.loaded` 类的 CSS `opacity: 0` 隐藏。但 CSS 中缺少 `visibility: hidden` 或 `display: none` 的后备方案。如果 `init()` 中途抛出异常（例如 `DEVICES` 变量未加载），加载屏幕将永远覆盖页面，用户看到无限旋转的加载动画且无法操作任何内容。
- **严重程度:** 🔴 高
- **修复方案:** 在 `init()` 中添加 `try...finally`，确保即使初始化失败也能移除加载屏幕；或在 CSS 中添加 `body.loaded .loading-screen { display: none; }` 作为后备。

### UX-02 | 表单无实时验证，错误提示不直观

- **位置:** `app.js` (`startBuild()`), `index.html` (所有 `.inp` 输入框)
- **问题:** 所有表单验证仅在点击"开始编译"时触发，以 toast 形式提示。用户无法在输入过程中得知格式是否正确。输入框没有 `error` 状态样式（如红色边框），也没有字段级别的错误提示文字。
- **严重程度:** 🟡 中
- **修复方案:** 为 `gh-token`、`gh-repo`、`lan-ip` 等字段添加 `input`/`blur` 事件的实时验证，通过 CSS 类切换边框颜色，并在字段下方显示内联错误提示。

### UX-03 | 自定义选项的"添加"按钮是 `<div>` 而非 `<button>`

- **位置:** `index.html` (自定义选项区域 `+ 添加`)
- **问题:** 使用 `<div class="tab on" onclick="addCustomOpt()">` 作为按钮。没有 `role="button"`、`tabindex`，键盘无法聚焦和触发。`<div>` 样式的按钮在语义上不正确，影响无障碍。
- **严重程度:** 🟡 中
- **修复方案:** 改为 `<button type="button" class="tab on" onclick="addCustomOpt()">+ 添加</button>`，并在 CSS 中添加 `button.tab { border: none; cursor: pointer; }`。

### UX-04 | Tab 组件无键盘支持

- **位置:** `app.js` (`initTabs()`), `styles.css` (`.tabs`, `.tab`)
- **问题:** 源码分支、固件模板等 Tab 组件使用 `div` 元素，没有 `role="tablist"` / `role="tab"` / `tabindex` 等 ARIA 属性。键盘用户无法通过 Tab 键聚焦，也无法用左右箭头键切换。
- **严重程度:** 🟡 中
- **修复方案:** 为 Tab 容器添加 `role="tablist"`，Tab 项添加 `role="tab"` 和 `tabindex`，并实现 `ArrowLeft`/`ArrowRight` 键盘导航。

### UX-05 | 开关/切换组件无键盘交互

- **位置:** `app.js` (`toggleOpt()`), `index.html` (所有 `.tog-row` 元素)
- **问题:** 所有开关行（ccache、上传固件、全选设备等）是 `<div onclick="...">` 实现。没有 `role="switch"`、`tabindex`、`aria-checked`，键盘用户完全无法操作。
- **严重程度:** 🟡 中
- **修复方案:** 为 `.tog-row` 添加 `tabindex="0"`、`role="switch"`、`aria-checked`，并监听 `keydown` 事件处理 Enter/Space。

### UX-06 | 移动端"开始编译"按钮 sticky 底部可能遮挡内容

- **位置:** `styles.css` (`@media(max-width:600px)` — `.btn-go`)
- **问题:** `position:sticky; bottom:0` 使得编译按钮始终固定在屏幕底部。但在移动端，日志面板展开后（最高 400px），按钮可能与日志内容重叠，且没有底部安全区域（`safe-area-inset-bottom`）处理。
- **严重程度:** 🟢 低
- **修复方案:** 添加 `padding-bottom: env(safe-area-inset-bottom)`，并在日志面板显示时临时取消 sticky 或增加 `margin-bottom`。

### UX-07 | 概览区插件列表用 innerHTML 渲染 HTML，未转义

- **位置:** `app.js` (`updateSummary()` — `s-plugin-list`)
- **问题:** 插件分类名直接拼接进 HTML 字符串（`${cat}`）。虽然分类名来自代码常量而非用户输入，但如果未来分类名包含 `<` 或 `"` 等字符，会导致 HTML 注入。这是一个潜在的 DOM 注入风险。
- **严重程度:** 🟡 中
- **修复方案:** 使用 `escapeHtml()` 对 `cat` 和 `names` 进行转义后再拼接。

### UX-08 | 设备网格 `grid-template-columns` 在移动端断点不生效

- **位置:** `styles.css` (`@media(max-width:600px)` — `.dg`)
- **问题:** 移动端 `.dg` 设置为 `grid-template-columns:1fr`，但 `.dg` 的默认样式为 `grid-template-columns:repeat(2,1fr)`。由于 CSS 媒体查询中 `.dg` 的优先级依赖于文件顺序，且 `.dc` 设备卡片在单列时宽度正确，但实际上 `.dg` 的 `max-height:400px` 在移动端可能太小，导致需要大量滚动。
- **严重程度:** 🟢 低
- **修复方案:** 移动端增大 `max-height` 至 `60vh` 或移除限制。

### UX-09 | 网络断开时无明确的离线提示

- **位置:** `app.js` (`startBuild()`)
- **问题:** `fetch()` 在网络断开时会抛出 `TypeError: Failed to fetch`，被 catch 捕获后显示通用错误信息。用户无法区分是网络问题、Token 无效还是仓库不存在。缺少 `navigator.onLine` 检查。
- **严重程度:** 🟢 低
- **修复方案:** 在 `startBuild()` 开始时检查 `navigator.onLine`，离线时直接提示"网络不可用"。对 fetch 错误进行分类处理。

### UX-10 | 插件详情面板关闭逻辑过于激进

- **位置:** `app.js` (`closeAllPlugDesc()` 监听 `scroll` 和 `touchmove`)
- **问题:** 全局 `scroll` 和 `touchmove` 事件会关闭所有已展开的插件详情面板。这意味着用户在阅读详情时稍微滚动页面（例如查看描述文字），面板就会立即关闭。
- **严重程度:** 🟡 中
- **修复方案:** 改为仅在滚动距离超过阈值（如 50px）时关闭，或改为点击面板外部区域关闭。

---

## 二、安全问题

### SEC-01 | GitHub Token 明文存储在 localStorage（高危）

- **位置:** `app.js` (`saveState()`, `loadState()`)
- **问题:** GitHub Personal Access Token 以明文形式存储在 `localStorage` 中（键名 `openwrt-ci-state`，字段 `ghToken`）。`localStorage` 对同源的任何 JavaScript 代码可读，包括第三方脚本、浏览器扩展、XSS 注入的代码。一旦有任何 XSS 漏洞，攻击者可以直接读取 Token 并获得仓库的完全控制权。
- **严重程度:** 🔴 严重
- **修复方案:**
  1. **首选方案：** 不持久化 Token，每次使用时要求用户输入（或仅在内存中保存当前会话）。
  2. **备选方案：** 使用 `sessionStorage` 替代 `localStorage`，关闭标签页即清除。
  3. **增强方案：** 实现后端代理，Token 仅在服务端使用，前端不接触 Token。

### SEC-02 | 设备名渲染存在 XSS 风险

- **位置:** `app.js` (`renderDeviceGroupHTML()`)
- **问题:** 设备数据 `d.n`（名称）和 `d.c`（CPU 型号）直接通过模板字符串插入 `innerHTML`，未经过 `escapeHtml()` 转义：
  ```js
  html += `<div class="n">${d.n}</div><div class="c">${d.c}</div>`;
  ```
  虽然当前数据来自 `devices.js` 静态文件，但如果该文件被篡改（供应链攻击）或未来支持用户自定义设备名，将导致存储型 XSS。
- **严重程度:** 🟡 中（当前数据源可信，但代码缺乏防御）
- **修复方案:** 使用 `escapeHtml(d.n)` 和 `escapeHtml(d.c)` 进行转义。

### SEC-03 | 平台分组 HTML 拼接存在 XSS 风险

- **位置:** `app.js` (`initPlatformTabs()`, `renderSubTabs()`)
- **问题:** `PLATFORM_GROUPS` 的 `name`、`icon`、`n` 属性通过模板字符串直接插入 `innerHTML`，未转义：
  ```js
  return `<div class="pgroup ...">${g.icon} ${g.name}<span class="cnt">${total}</span></div>`;
  ```
  同样，`renderSubTabs()` 中 `${s.n}` 也未转义。
- **严重程度:** 🟢 低（数据来源为代码常量，但缺乏防御性编程）
- **修复方案:** 统一使用 `escapeHtml()` 转义所有动态内容。

### SEC-04 | 插件名在 togglePlugDesc 中未转义即插入 innerHTML

- **位置:** `app.js` (`togglePlugDesc()`)
- **问题:** 插件名 `name` 被直接插入多个 `innerHTML` 位置（`pd-title`、`pd-pkg` 等），虽然通过 `getElementById('pc-' + name)` 间接使用了 ID，但插件名本身未转义。如果插件名包含恶意 HTML，将执行脚本。
- **严重程度:** 🟡 中
- **修复方案:** 对 `name`、`shortName`、`desc`、`features` 等所有变量使用 `escapeHtml()`。

### SEC-05 | `renderGrid` 中插件名通过 onclick 属性传递未转义

- **位置:** `app.js` (`renderGrid()`)
- **问题:** 
  ```js
  return `<div ... onclick="togglePlug(this,'${name}')">`;
  ```
  如果插件名包含单引号 `'`，将导致 onclick 属性注入，可执行任意 JavaScript。
- **严重程度:** 🟡 中
- **修复方案:** 改用事件委托（event delegation），在父容器上监听 click 事件，通过 `data-*` 属性传递插件名。

### SEC-06 | 无 CSP（内容安全策略）

- **位置:** `index.html`
- **问题:** 页面没有 `<meta http-equiv="Content-Security-Policy">` 标签，也没有通过 HTTP 头设置 CSP。这意味着：
  1. 内联脚本（`onclick` 等）可以执行。
  2. 如果页面被注入恶意脚本，没有任何防护。
  3. 没有限制 `connect-src`，页面可以向任意域名发送请求（包括外泄 Token）。
- **严重程度:** 🔴 高
- **修复方案:** 添加 CSP 策略：
  ```html
  <meta http-equiv="Content-Security-Policy" content="
    default-src 'self';
    script-src 'self';
    style-src 'self' 'unsafe-inline';
    connect-src https://api.github.com;
    img-src 'self' data:;
  ">
  ```
  注意：当前大量使用内联 `onclick`，需要先重构为事件委托才能去掉 `'unsafe-inline'`。

### SEC-07 | 外部链接无 `rel="noopener"` 防护

- **位置:** `index.html` (GitHub Token 创建链接)
- **问题:** `<a href="https://github.com/settings/tokens" target="_blank">` 没有 `rel="noopener noreferrer"`。虽然现代浏览器已默认添加 `noopener`，但旧版浏览器中 `window.opener` 可被恶意页面利用。
- **严重程度:** 🟢 低
- **修复方案:** 添加 `rel="noopener noreferrer"`。

### SEC-08 | 密码字段缺少 `autocomplete="new-password"`

- **位置:** `index.html` (`#root-pw`, `#wifi-password`)
- **问题:** Root 密码和 WiFi 密码字段没有设置 `autocomplete="new-password"`。浏览器可能会自动填充之前保存的密码，导致意外覆盖。更重要的是，Root 密码使用 `type="text"` 而非 `type="password"`，密码在屏幕上明文可见。
- **严重程度:** 🟢 低
- **修复方案:** Root 密码改为 `type="password"` 并添加 `autocomplete="new-password"`；WiFi 密码添加 `autocomplete="new-password"`。

### SEC-09 | 无 CSRF 防护（API 侧）

- **位置:** `app.js` (`startBuild()`)
- **问题:** 页面直接使用客户端 Token 调用 GitHub API。虽然 GitHub 的 Personal Access Token 本身提供了认证，但页面没有实现任何 CSRF 防护机制。如果用户在恶意网站上打开了此页面（通过 iframe 或诱导跳转），恶意脚本可以利用已存储的 Token 触发编译。
- **严重程度:** 🟡 中
- **修复方案:** 
  1. 结合 SEC-01，不在 localStorage 中存储 Token。
  2. 添加 `Referer` / `Origin` 检查（虽然不能完全依赖）。
  3. 考虑使用后端代理模式，前端不直接接触 Token。

### SEC-10 | Workflow 状态轮询无频率限制

- **位置:** `app.js` (`startWorkflowCheck()`)
- **问题:** 每 30 秒轮询一次 GitHub API，最多 60 次（30 分钟）。虽然有 `maxChecks` 限制，但如果用户多次触发编译，可能同时存在多个轮询定时器。此外，轮询使用的是存储在内存中的 Token，如果 Token 在 localStorage 中被篡改，可能被用于持续请求。
- **严重程度:** 🟢 低
- **修复方案:** 确保 `startWorkflowCheck` 开始前清除之前的定时器（当前已实现）；添加页面可见性检测（`document.visibilitychange`），页面不可见时暂停轮询。

### SEC-11 | `btoa(unescape(encodeURIComponent(...)))` 编码链可能产生非标准 Base64

- **位置:** `app.js` (`startBuild()` — `customConfig` 编码)
- **问题:** 使用 `btoa(unescape(encodeURIComponent(...)))` 来处理 UTF-8 内容的 Base64 编码。`unescape()` 是已废弃的函数，在某些特殊字符组合下可能产生意外结果。
- **严重程度:** 🟢 低
- **修复方案:** 使用标准方式：
  ```js
  const encoder = new TextEncoder();
  const bytes = encoder.encode(customConfig);
  const customB64 = btoa(String.fromCharCode(...bytes));
  ```

---

## 三、问题汇总

| 编号 | 类别 | 严重程度 | 简述 |
|------|------|----------|------|
| UX-01 | UX | 🔴 高 | 加载屏幕遮挡逻辑不完整 |
| UX-02 | UX | 🟡 中 | 表单无实时验证 |
| UX-03 | UX | 🟡 中 | 自定义选项按钮非语义化 |
| UX-04 | UX | 🟡 中 | Tab 组件无键盘支持 |
| UX-05 | UX | 🟡 中 | 开关组件无键盘交互 |
| UX-06 | UX | 🟢 低 | 移动端 sticky 按钮遮挡 |
| UX-07 | UX | 🟡 中 | 概览插件列表 innerHTML 未转义 |
| UX-08 | UX | 🟢 低 | 移动端设备网格高度限制 |
| UX-09 | UX | 🟢 低 | 网络断开无明确提示 |
| UX-10 | UX | 🟡 中 | 插件详情面板关闭过于激进 |
| SEC-01 | 安全 | 🔴 严重 | GitHub Token 明文存储 localStorage |
| SEC-02 | 安全 | 🟡 中 | 设备名 innerHTML 未转义 |
| SEC-03 | 安全 | 🟢 低 | 平台分组 HTML 未转义 |
| SEC-04 | 安全 | 🟡 中 | 插件名在详情面板未转义 |
| SEC-05 | 安全 | 🟡 中 | 插件名通过 onclick 属性注入风险 |
| SEC-06 | 安全 | 🔴 高 | 无 CSP 内容安全策略 |
| SEC-07 | 安全 | 🟢 低 | 外部链接缺少 noopener |
| SEC-08 | 安全 | 🟢 低 | 密码字段 autocomplete 和 type 问题 |
| SEC-09 | 安全 | 🟡 中 | 无 CSRF 防护 |
| SEC-10 | 安全 | 🟢 低 | Workflow 轮询无页面可见性优化 |
| SEC-11 | 安全 | 🟢 低 | 废弃函数 unescape 用于 Base64 编码 |

**统计:** 🔴 严重/高 3 个 | 🟡 中 10 个 | 🟢 低 8 个

---

## 四、优先修复建议

### 第一优先级（立即修复）
1. **SEC-01** — 停止将 Token 存入 `localStorage`，改用 `sessionStorage` 或仅内存存储
2. **SEC-06** — 添加 CSP 策略头
3. **UX-01** — 为 `init()` 添加 try/finally 确保加载屏幕始终被移除

### 第二优先级（短期修复）
4. **SEC-02 / SEC-04 / SEC-05 / UX-07** — 统一使用 `escapeHtml()` 转义所有 innerHTML 中的动态内容
5. **UX-02** — 添加表单实时验证和错误状态样式
6. **UX-04 / UX-05** — 为交互组件添加键盘支持和 ARIA 属性
7. **SEC-09** — 评估是否需要后端代理模式

### 第三优先级（持续改进）
8. **UX-03 / UX-06 / UX-08 / UX-09 / UX-10** — 各项 UX 细节优化
9. **SEC-03 / SEC-07 / SEC-08 / SEC-10 / SEC-11** — 防御性编程和最佳实践
