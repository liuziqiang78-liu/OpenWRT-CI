# OpenWRT-CI UX & 安全修复日志

**修复日期:** 2026-05-06
**修复范围:** `assets/app.js`, `assets/styles.css`, `index.html`

---

## 修复清单

### 1. Token 安全存储 (严重 → SEC-01)
**文件:** `assets/app.js`
**变更:**
- `saveState()`: 从 localStorage 数据中移除 `ghToken` 字段，改为单独用 `sessionStorage` 存储
- `loadState()`: 从 `sessionStorage.getItem('openwrt-ci-token')` 读取 token，而非 localStorage
- 效果：关闭浏览器标签页后 token 自动清除，防止同源 XSS 窃取长期有效的 token

### 2. CSP 内容安全策略 (严重 → SEC-06)
**文件:** `index.html`
**变更:**
- 在 `<head>` 中添加 `<meta http-equiv="Content-Security-Policy">` 标签
- 策略: `default-src 'self' 'unsafe-inline' 'unsafe-eval'; connect-src https://api.github.com https://github.com;`
- 效果：限制脚本和连接来源，防护外部脚本注入和数据外泄

### 3. 表单实时验证 (中等 → UX-02)
**文件:** `assets/app.js`, `assets/styles.css`
**变更:**
- 新增 `initFormValidation()` 函数，为以下字段添加 `input`/`blur` 实时验证：
  - **LAN IP**: 正则验证 IPv4 格式，格式错误时红色边框 + 提示文字
  - **WiFi 密码**: 长度 < 8 时提示，红色边框
  - **Root 密码**: 长度 < 6 时安全建议提示
- CSS 新增 `.input-error` (红色边框 + 红色阴影) 和 `.input-error-msg` (错误提示文字) 样式

### 4. Tab 键盘支持 (中等 → UX-04, UX-05)
**文件:** `assets/app.js`, `index.html`
**变更:**
- `initTabs()`: 为所有 tab 按钮添加 `role="tab"`、`tabindex="0"`、`keydown` 事件 (Enter/Space 触发)
- `toggleOpt()`: 添加 `aria-checked` 属性更新
- 新增 `initKeyboardSupport()` 函数：
  - 为 `.tog-row` 元素添加 Enter/Space 键盘触发
  - 为 `.pgroup` 平台标签添加 `role="tab"`、`tabindex="0"`、键盘事件
- HTML 中为以下元素添加 ARIA 属性：
  - `.tabs` 容器: `role="tablist"`
  - `.tog-row` 开关: `role="switch"`, `tabindex="0"`, `aria-checked`

### 5. 插件详情面板滚动关闭优化 (中等 → UX-10)
**文件:** `assets/app.js`
**变更:**
- 将 `closeAllPlugDesc` 的全局 `scroll` 监听改为阈值判断：
  - 记录 `lastScrollY`，仅在滚动距离 > 10px 时触发关闭
  - `touchmove` 事件同理，基于 `touch.clientY` 差值判断
- 效果：用户轻微滚动页面时不会误触关闭正在阅读的插件详情

### 6. innerHTML 转义 (中等 → SEC-02, SEC-03, SEC-04, SEC-05, UX-07)
**文件:** `assets/app.js`
**变更:** 以下函数中的动态内容全部通过 `escapeHtml()` 转义后插入 DOM：
- `renderDeviceGroupHTML()`: `d.n`、`d.c`、`d.id`
- `initPlatformTabs()`: `g.icon`、`g.name`
- `renderSubTabs()`: `s.n`
- `renderGrid()`: `name`、`shortName`、`desc`、`features`
- `togglePlugDesc()`: `shortName`、`desc`、`name`、`firewallLabel`
- `updateSummary()`: `cat`、插件名 `names`
- `renderCustomOpts()`: `o.key`、`o.val`

### 7. 外部链接安全 (低 → SEC-07)
**文件:** `index.html`
**变更:**
- GitHub Token 创建链接添加 `rel="noopener noreferrer"`
- 效果：防止旧版浏览器中 `window.opener` 被利用

---

## 影响评估

| 编号 | 修复项 | 安全等级 | 状态 |
|------|--------|----------|------|
| 1 | Token sessionStorage | 🔴 严重 | ✅ 已修复 |
| 2 | CSP meta 标签 | 🔴 高 | ✅ 已修复 |
| 3 | 表单实时验证 | 🟡 中 | ✅ 已修复 |
| 4 | Tab 键盘支持 | 🟡 中 | ✅ 已修复 |
| 5 | 滚动关闭优化 | 🟡 中 | ✅ 已修复 |
| 6 | innerHTML 转义 | 🟡 中 | ✅ 已修复 |
| 7 | 外部链接安全 | 🟢 低 | ✅ 已修复 |
