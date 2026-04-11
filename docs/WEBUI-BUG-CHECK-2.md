# Web UI 第二次深度 Bug 检查报告

**检查时间**: 2026-04-11 23:31
**检查方法**: 代码逐行审查 + 边界情况分析
**检查范围**: build-ui-full.html 完整文件

---

## 🔴 严重 Bug (新发现)

### Bug #1: 插件数据中重复定义

**问题代码**:
```javascript
const pluginSizes = {
    'naiveproxy': 5,  // 第 1 次出现
    // ... 中间有其他插件
    'naiveproxy': 5,  // 第 2 次出现（重复）
    
    'luci-app-oaf': 5,  // 第 1 次出现
    // ...
    'luci-app-oaf': 5,  // 第 2 次出现（重复）
};
```

**影响**: 虽然 JavaScript 会覆盖，但说明数据维护有问题

**修复**: 删除重复项

---

### Bug #2: 插件分类标签计数未更新

**问题代码**:
```javascript
<div class="plugin-tab active" onclick="switchTab('proxy')">🔐 科学上网 (12)</div>
<div class="plugin-tab" onclick="switchTab('storage')">💾 存储管理 (16)</div>
<div class="plugin-tab" onclick="switchTab('network')">🌐 网络工具 (35)</div>
<div class="plugin-tab" onclick="switchTab('theme')">🎨 主题 (13)</div>
<div class="plugin-tab" onclick="switchTab('system')">🔧 系统工具 (28)</div>
```

**问题**:
- ❌ 数字是硬编码的
- ❌ 添加插件后没有更新
- ❌ 实际数量可能不匹配

**实际数量**:
```javascript
proxy: 12 个 ✅
storage: 16 个 ✅
network: 36 个 ❌ (显示 35)
theme: 13 个 ✅
system: 28 个 ✅
```

**修复方案**:
```javascript
// 动态计算数量
function updateTabCounts() {
    document.querySelectorAll('.plugin-tab').forEach(tab => {
        const category = tab.onclick.toString().match(/'(\w+)'/)[1];
        const count = PLUGINS[category].length;
        tab.innerHTML = tab.innerHTML.replace(/\(\d+\)/, `(${count})`);
    });
}
```

---

### Bug #3: 搜索功能在切换分类后失效

**问题代码**:
```javascript
function filterPlugins() {
    const search = document.getElementById('plugin-search').value.toLowerCase().trim();
    
    if (!search) {
        renderPlugins(currentTab);
        document.getElementById('category-count').textContent = `已选 ${PLUGINS[currentTab].filter(p => selectedPlugins[p.pkg]).length} 个`;
        return;
    }
    // ...
}
```

**问题**:
- ❌ 搜索后切换分类，搜索框内容还在
- ❌ 但搜索结果显示的是新分类
- ❌ 用户会困惑

**修复方案**:
```javascript
// 切换分类时清空搜索
function switchTab(category) {
    currentTab = category;
    document.getElementById('plugin-search').value = '';  // 清空搜索
    renderPlugins(category);
}
```

---

### Bug #4: 内存泄漏风险

**问题代码**:
```javascript
function startBuildMonitor() {
    buildMonitorInterval = setInterval(async () => {
        // ...
    }, 10000);
}
```

**问题**:
- ❌ setInterval 从未被清除
- ❌ 页面长时间运行会累积
- ❌ 用户离开页面后仍在运行

**修复方案**:
```javascript
// 页面卸载时清除
window.addEventListener('beforeunload', () => {
    if (buildMonitorInterval) {
        clearInterval(buildMonitorInterval);
    }
});

// 或者在编译完成后清除
if (conclusion === 'success' || conclusion === 'failure') {
    clearInterval(buildMonitorInterval);
    buildMonitorInterval = null;
}
```

---

### Bug #5: Token 安全存储问题

**问题代码**:
```javascript
const token = localStorage.getItem('github_token');
```

**问题**:
- ❌ Token 明文存储在 localStorage
- ❌ XSS 攻击可窃取 Token
- ❌ 没有加密

**修复方案**:
```javascript
// 简单加密
function encryptToken(token) {
    return btoa(token);  // Base64 编码（不是真正加密）
}

function decryptToken(encrypted) {
    return atob(encrypted);
}

// 存储时加密
localStorage.setItem('github_token', encryptToken(token));

// 读取时解密
const token = decryptToken(localStorage.getItem('github_token'));
```

**更好的方案**: 使用 IndexedDB + 加密库

---

## 🟡 中等 Bug (新发现)

### Bug #6: 插件大小数据可能过时

**问题**: 插件大小是估算值，实际可能不同

**影响**: 固件大小估算不准确

**修复**: 添加免责声明
```javascript
'💾 固件大小估算：${size} MB (仅供参考)'
```

---

### Bug #7: 确认对话框可能被浏览器拦截

**问题代码**:
```javascript
if (!confirm(confirmMsg)) {
    return;
}
```

**问题**: 某些浏览器会记住用户选择，自动拒绝

**修复**: 使用自定义模态框

---

### Bug #8: 长插件列表渲染性能问题

**问题**: 108 个插件同时渲染可能卡顿

**修复**: 虚拟滚动或分页
```javascript
// 只渲染可见区域
const visiblePlugins = PLUGINS[category].slice(startIndex, endIndex);
```

---

### Bug #9: 移动端输入框缩放问题

**问题代码**:
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
```

**问题**: `user-scalable=no` 在某些 iOS 版本会导致输入框放大

**修复**: 移除 `user-scalable=no`

---

### Bug #10: 编译进度弹窗位置问题

**问题代码**:
```javascript
progressElement.style.position = 'fixed';
progressElement.style.bottom = '20px';
progressElement.style.right = '20px';
```

**问题**: 移动端可能被浏览器 UI 遮挡

**修复**: 使用 `bottom: env(safe-area-inset-bottom)`

---

## 🟢 轻微问题 (新发现)

### Bug #11: 缺少快捷键支持

**建议**: 添加 Ctrl+S 保存配置等

---

### Bug #12: 没有暗黑模式

**建议**: 添加暗黑模式切换

---

### Bug #13: 缺少国际化

**建议**: 支持多语言

---

## 📊 Bug 统计（第二次检查）

| 严重程度 | 数量 | 新增 |
|---------|------|------|
| 🔴 严重 | 5 | +5 |
| 🟡 中等 | 5 | +5 |
| 🟢 轻微 | 3 | +3 |
| **总计** | **13** | **+13** |

---

## 🎯 修复优先级

### P0 - 立即修复
1. ✅ Bug #2: 分类计数动态更新
2. ✅ Bug #3: 搜索清空逻辑
3. ✅ Bug #4: 内存泄漏修复

### P1 - 今天修复
4. ✅ Bug #1: 删除重复数据
5. ✅ Bug #5: Token 简单加密

### P2 - 本周修复
6. ⏳ Bug #6-13: 其他优化

---

## 🔧 快速修复代码

### 修复 Bug #2 (分类计数)

```javascript
// 在 init() 中调用
function updateTabCounts() {
    const categories = ['proxy', 'storage', 'network', 'theme', 'system'];
    const icons = ['🔐', '💾', '🌐', '🎨', '🔧'];
    const names = ['科学上网', '存储管理', '网络工具', '主题', '系统工具'];
    
    categories.forEach((cat, i) => {
        const tab = document.querySelectorAll('.plugin-tab')[i];
        const count = PLUGINS[cat].length;
        tab.innerHTML = `${icons[i]} ${names[i]} (${count})`;
        tab.onclick = () => switchTab(cat);
    });
}
```

### 修复 Bug #3 (搜索清空)

```javascript
function switchTab(category) {
    currentTab = category;
    
    // 清空搜索
    document.getElementById('plugin-search').value = '';
    
    // 更新标签
    document.querySelectorAll('.plugin-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    event.target.classList.add('active');
    
    renderPlugins(category);
}
```

### 修复 Bug #4 (内存泄漏)

```javascript
// 页面卸载时清除
window.addEventListener('beforeunload', () => {
    if (buildMonitorInterval) {
        clearInterval(buildMonitorInterval);
        buildMonitorInterval = null;
        console.log('🧹 清理编译监控定时器');
    }
});

// 编译完成后清除
function showBuildProgress(run) {
    // ...
    if (conclusion === 'success' || conclusion === 'failure') {
        if (buildMonitorInterval) {
            clearInterval(buildMonitorInterval);
            buildMonitorInterval = null;
        }
    }
}
```

---

## ✅ 检查结论

**整体质量**: ⭐⭐⭐⭐ (4/5)

**新发现的问题**:
- 数据重复定义
- 计数未动态更新
- 搜索逻辑问题
- 内存泄漏风险
- Token 安全问题

**建议**: 优先修复 P0 级别的 3 个 Bug

---

*检查完成时间：2026-04-11 23:31*
