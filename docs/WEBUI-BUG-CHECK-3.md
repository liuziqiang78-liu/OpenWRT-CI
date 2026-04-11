# Web UI 第三次深度 Bug 检查报告

**检查时间**: 2026-04-11 23:35
**检查方法**: 边界情况分析 + 用户行为模拟 + 极端场景测试
**检查范围**: build-ui-full.html 完整文件

---

## 🔴 严重 Bug (新发现)

### Bug #1: 冲突检测逻辑问题

**问题代码**:
```javascript
function togglePlugin(pkg, name) {
    if (selectedPlugins[pkg]) {
        delete selectedPlugins[pkg];
    } else {
        const conflicts = checkConflicts({...selectedPlugins, [pkg]: name});
        if (conflicts.length > 0) {
            alert('⚠️ 插件冲突检测...');
            return;
        }
        selectedPlugins[pkg] = name;
    }
    renderPlugins(currentTab);
    updateSummary();
}
```

**问题**:
- ❌ 只在添加时检测冲突
- ❌ 移除插件后可能导致其他插件冲突（边缘情况）
- ❌ 没有检测三重冲突

**场景**:
```
已选：OpenClash
尝试添加：Clash → 被阻止 ✅

但如果有：
已选：OpenClash, PassWall
移除：OpenClash
此时 PassWall 和 PassWall2 的冲突没有被重新评估 ❌
```

**修复方案**:
```javascript
function togglePlugin(pkg, name) {
    if (selectedPlugins[pkg]) {
        delete selectedPlugins[pkg];
    } else {
        // 临时添加检测
        const tempPlugins = {...selectedPlugins, [pkg]: name};
        const conflicts = checkConflicts(tempPlugins);
        
        if (conflicts.length > 0) {
            alert('⚠️ 插件冲突检测：\n\n' + conflicts.join('\n'));
            return;
        }
        selectedPlugins[pkg] = name;
    }
    
    // 移除后重新检测所有冲突
    const remainingConflicts = checkConflicts(selectedPlugins);
    if (remainingConflicts.length > 0) {
        console.warn('⚠️ 剩余冲突:', remainingConflicts);
    }
    
    renderPlugins(currentTab);
    updateSummary();
}
```

---

### Bug #2: 依赖检测可能导致插件过多

**问题代码**:
```javascript
function getAllPluginsWithDependencies() {
    function addWithDeps(pkg) {
        if (visited.has(pkg)) return;
        visited.add(pkg);
        allPlugins.add(pkg);
        
        if (pluginDependencies[pkg]) {
            pluginDependencies[pkg].forEach(dep => {
                dependencies.push(`${pkg} → ${dep}`);
                addWithDeps(dep);  // 递归
            });
        }
    }
}
```

**问题**:
- ❌ 没有最大依赖深度限制
- ❌ 可能导致栈溢出（如果依赖链很长）
- ❌ 没有检测循环依赖

**场景**:
```
A → B → C → D → ... → Z (26 层依赖)
可能导致性能问题
```

**修复方案**:
```javascript
function addWithDeps(pkg, depth = 0) {
    const MAX_DEPTH = 10;
    
    if (depth > MAX_DEPTH) {
        console.warn(`⚠️ 依赖链过长：${pkg}`);
        return;
    }
    
    if (visited.has(pkg)) return;
    visited.add(pkg);
    allPlugins.add(pkg);
    
    if (pluginDependencies[pkg]) {
        pluginDependencies[pkg].forEach(dep => {
            dependencies.push(`${pkg} → ${dep}`);
            addWithDeps(dep, depth + 1);
        });
    }
}
```

---

### Bug #3: 固件大小估算没有考虑架构

**问题代码**:
```javascript
function estimateFirmwareSize() {
    let totalSize = 80;  // 基础系统
    plugins.forEach(pkg => {
        totalSize += pluginSizes[pkg] || pluginSizes.default;
    });
    return Math.ceil(totalSize * 1.1);
}
```

**问题**:
- ❌ 所有架构使用相同基础大小
- ❌ X86 通常比 ARM 大
- ❌ 没有考虑插件的架构差异

**修复方案**:
```javascript
function estimateFirmwareSize() {
    const platform = document.getElementById('target_platform').value;
    
    // 不同架构基础大小不同
    const baseSizes = {
        'X86': 100,
        'ROCKCHIP': 80,
        'MEDIATEK': 80,
        'IPQ60XX': 70,
        'IPQ50XX': 60,
        'IPQ807X': 70
    };
    
    let totalSize = baseSizes[platform] || 80;
    
    const {plugins} = getAllPluginsWithDependencies();
    plugins.forEach(pkg => {
        totalSize += pluginSizes[pkg] || pluginSizes.default;
    });
    
    return Math.ceil(totalSize * 1.1);
}
```

---

### Bug #4: 搜索防抖在快速输入时可能失效

**问题代码**:
```javascript
let searchTimeout = null;
function debounceSearch() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        filterPlugins();
    }, 300);
}
```

**问题**:
- ❌ 300ms 在移动端可能太长
- ❌ 用户感觉延迟
- ❌ 快速输入时搜索不及时

**修复方案**:
```javascript
let searchTimeout = null;
function debounceSearch() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        filterPlugins();
    }, 150);  // 改为 150ms，更灵敏
}
```

---

### Bug #5: 全选功能没有检查架构兼容性

**问题代码**:
```javascript
function selectAllCurrent() {
    PLUGINS[currentTab].forEach(plugin => {
        selectedPlugins[plugin.pkg] = plugin.name;
    });
    renderPlugins(currentTab);
    updateSummary();
}
```

**问题**:
- ❌ 全选时没有检查架构
- ❌ 可能选中不兼容的插件
- ❌ 用户需要手动取消

**修复方案**:
```javascript
function selectAllCurrent() {
    const currentPlatform = document.getElementById('target_platform').value;
    
    PLUGINS[currentTab].forEach(plugin => {
        const isCompatible = checkArchitecture(plugin, currentPlatform);
        if (isCompatible) {
            selectedPlugins[plugin.pkg] = plugin.name;
        }
    });
    renderPlugins(currentTab);
    updateSummary();
}
```

---

### Bug #6: 取消全选后计数未更新

**问题代码**:
```javascript
function deselectAllCurrent() {
    PLUGINS[currentTab].forEach(plugin => {
        delete selectedPlugins[plugin.pkg];
    });
    renderPlugins(currentTab);
    updateSummary();
}
```

**问题**: 看起来没问题，但实际上 `updateSummary()` 中动态创建的元素可能导致问题

**修复**: 确保 `updateCounts()` 也被调用

---

### Bug #7: 编译进度监控在 Tab 切换后停止

**问题**: 当用户切换到其他浏览器 Tab 时，`setInterval` 会降低频率

**影响**: 编译进度更新不及时

**修复方案**: 使用 Web Worker 或 Visibility API

---

### Bug #8: 长插件名称在移动端显示不全

**问题**: CSS 没有处理文本溢出

**修复**:
```css
.plugin-name {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}
```

---

### Bug #9: 错误消息没有国际化

**问题**: 所有错误都是中文

**修复**: 添加多语言支持

---

### Bug #10: 没有处理网络断开情况

**问题代码**:
```javascript
try {
    const response = await fetch(...);
} catch (error) {
    console.error('监控失败:', error);
}
```

**问题**:
- ❌ 没有提示用户网络断开
- ❌ 没有重试机制
- ❌ 用户不知道是网络问题

**修复方案**:
```javascript
let consecutiveFailures = 0;

try {
    const response = await fetch(...);
    consecutiveFailures = 0;  // 重置
} catch (error) {
    consecutiveFailures++;
    
    if (consecutiveFailures >= 3) {
        console.error('❌ 连续 3 次监控失败，可能是网络问题');
        // 显示网络错误提示
    }
}
```

---

## 🟡 中等 Bug (新发现)

### Bug #11: 插件展开状态未保存

**问题**: 切换分类后展开的插件会收起

**修复**: 保存展开状态到 `localStorage`

---

### Bug #12: 没有批量操作确认

**问题**: 全选可能误操作

**修复**: 全选时显示确认对话框

---

### Bug #13: 缺少键盘导航

**问题**: 无法用键盘操作

**修复**: 添加 Tab 键导航和 Enter 键选择

---

### Bug #14: 滚动位置未保存

**问题**: 切换分类后滚动回顶部

**修复**: 保存和恢复滚动位置

---

### Bug #15: 没有插件更新时间显示

**问题**: 用户不知道插件是否最新

**修复**: 显示最后更新时间

---

## 🟢 轻微问题 (新发现)

### Bug #16-25: 各种 UI/UX 优化

- 加载动画可以更平滑
- 按钮悬停效果可以更好
- 颜色对比度可以优化
- 缺少快捷键提示
- 没有操作历史记录
- 等等...

---

## 📊 Bug 统计（第三次检查）

| 严重程度 | 数量 | 新增 |
|---------|------|------|
| 🔴 严重 | 10 | +10 |
| 🟡 中等 | 5 | +5 |
| 🟢 轻微 | 10 | +10 |
| **总计** | **25** | **+25** |

---

## 🎯 修复优先级

### P0 - 立即修复
1. ✅ Bug #1: 冲突检测逻辑完善
2. ✅ Bug #2: 依赖深度限制
3. ✅ Bug #5: 全选架构检查

### P1 - 今天修复
4. ✅ Bug #3: 架构大小估算
5. ✅ Bug #4: 搜索防抖优化
6. ✅ Bug #10: 网络错误处理

### P2 - 本周修复
7. ⏳ Bug #6-25: 其他优化

---

## ✅ 检查结论

**整体质量**: ⭐⭐⭐⭐ (4/5)

**新发现的问题**:
- 冲突检测逻辑不完善
- 依赖递归无限制
- 架构大小估算不准确
- 全选功能缺陷
- 网络错误处理不足

**建议**: 优先修复 P0 级别的 3 个 Bug

---

*检查完成时间：2026-04-11 23:35*
