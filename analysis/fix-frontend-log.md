# 前端 Bug 修复日志

**修复时间**: 2026-05-06 13:07 GMT+8  
**修复文件**: `assets/app.js`  
**修复总数**: 8 个问题

---

## 修复清单

### ✅ FIX-01: PLATFORM_GROUPS 不完整 (致命)
**问题**: 仅定义 3 个平台组，DEVICES 有 27 个子平台，1000+ 设备不可选。  
**修复**: 将硬编码的 PLATFORM_GROUPS 改为从 DEVICES 对象动态生成。新增 PLATFORM_META 字典提供中文名和图标。所有 27 个子平台自动被提取到对应的平台组中。  
**影响**: 所有平台设备现在均可在 UI 中访问和选择。

### ✅ FIX-02: plugAll/plugInvert 绕过防火墙兼容性 (严重)
**问题**: `plugAll()` 和 `plugInvert()` 直接操作插件集合，不检查防火墙兼容性。当选择 nftables 时会选中仅 iptables 的插件，导致编译失败。  
**修复**: 在两个函数中添加 `isPluginCompatible(pluginFw)` 检查，跳过不兼容的插件。  
**代码位置**: `plugAll()` 和 `plugInvert()` 函数

### ✅ FIX-03: innerHTML XSS 风险 (严重)
**问题**: 多处 innerHTML 拼接未转义用户输入数据。  
**修复**:
- `renderCustomOpts()`: 用户输入的 `o.key` 和 `o.val` 使用 `escapeHtml()` 包裹
- `updateSummary()`: 插件列表中的 `cat` 和 `shortName` 使用 `escapeHtml()` 包裹
- `renderGrid()`: `name`、`shortName`、`desc` 使用 `escapeHtml()` 包裹
- `renderDeviceGroupHTML()`: `data-id` 属性使用 `escapeHtml()` 包裹，`cpu` 标签使用 `escapeHtml()` 包裹
- `togglePlugDesc()`: 已有 escapeHtml，无需修改

### ✅ FIX-04: IntersectionObserver 内存泄漏 (严重)
**问题**: 每次调用 `initDevices()` 都创建新 IntersectionObserver，旧的不清理，持有已移除 DOM 引用。  
**修复**:
- 新增全局变量 `deviceObserver`
- `setupDeviceLazyLoad()` 开头添加 `if (deviceObserver) { deviceObserver.disconnect(); deviceObserver = null; }`
- `initDevices()` 开头添加同样的清理逻辑
- 创建的 observer 赋值给 `deviceObserver`

### ✅ FIX-05: 搜索无防抖 (严重)
**问题**: 设备搜索和插件搜索每次按键直接触发全量遍历和 DOM 重绘（1000+ 条目）。  
**修复**:
- `searchDevices`: 重命名为 `_searchDevicesRaw`，外层用 `debounce(..., 250)` 包装
- 插件搜索: `addEventListener('input', ...)` 内部用 `debounce(..., 250)` 包装

### ✅ FIX-06: 加载屏幕异常保护 (严重)
**问题**: `init()` 中任何异常都会导致 loading screen 永远不消失。  
**修复**: 将 `init()` 函数体包裹在 `try-catch-finally` 中。`finally` 块中执行 `document.body.classList.add('loaded')` 确保 loading screen 始终被移除。异常时 `console.error` 记录错误。

### ✅ FIX-07: log() 函数 innerHTML+= 性能问题 (中等)
**问题**: `log()` 使用 `innerHTML +=` 导致 O(n²) DOM 操作，日志越多越慢。  
**修复**: 改用 `document.createElement('div')` + `textContent` + `appendChild()`。`textContent` 自动转义，无需手动 escapeHtml。DOM 操作从 O(n²) 降为 O(1)。

### ✅ FIX-08: toggleAllDevices 搜索过滤不一致 (严重)
**问题**: `toggleAllDevices()` 搜索仅匹配 `d.n` 和 `d.id`，但 `initDevices()` 还匹配 `d.c`（芯片型号）。  
**修复**: 添加 `d.c.toLowerCase().includes(searchQuery)` 条件，与 `initDevices()` 保持一致。

---

## 未修复的问题 (超出本次任务范围)

| 编号 | 问题 | 严重程度 | 说明 |
|------|------|---------|------|
| BUG-02 | NSS_MODULES 未使用 | 致命 | 需确认是否应自动包含 |
| BUG-08 | document 级 change 事件过于宽泛 | 严重 | 需重构事件绑定逻辑 |
| BUG-10 | scroll/touchmove 关闭插件详情 | 中等 | 需改为区域检测 |
| BUG-11 | WiFi 密码验证不完整 | 中等 | 需增加长度检查提示 |
| BUG-12 | 切换平台清空已选设备 | 中等 | 需同步调整编译逻辑 |
| BUG-18-22 | 无障碍/内联事件/Token 安全等 | 建议 | 长期改进项 |

## 验证

```bash
node --check assets/app.js
# ✅ 语法检查通过，无错误
```
