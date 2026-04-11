# Web UI 深度 Bug 检查报告

**检查时间**: 2026-04-11 23:27
**检查范围**: build-ui-full.html
**检查方法**: 代码审查 + 逻辑分析

---

## 🔴 严重 Bug (必须修复)

### Bug #1: 编译进度监控缺少错误处理

**问题代码**:
```javascript
async () => {
    const response = await fetch('...');
    if (response.ok) {
        const data = await response.json();
        // ...
    }
}
```

**问题**:
- ❌ 没有处理网络错误
- ❌ 没有处理 API 限流
- ❌ 没有处理认证失败
- ❌ 错误被静默忽略

**影响**: 用户看不到编译进度，且不知道出错

**修复方案**:
```javascript
try {
    const response = await fetch(url, {
        headers: {
            'Accept': 'application/vnd.github.v3+json',
            'Authorization': `token ${token}`  // 需要 Token
        }
    });
    
    if (response.status === 403) {
        console.warn('API 限流，稍后重试');
        return;
    }
    
    if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
    }
    
    const data = await response.json();
    // ...
} catch (error) {
    console.error('监控失败:', error);
    // 显示错误提示
}
```

---

### Bug #2: 固件大小估算不准确

**问题代码**:
```javascript
const pluginSizes = {
    'luci-app-openclash': 15,
    'luci-app-dockerman': 50,
    // ... 只有部分插件
};

function estimateFirmwareSize() {
    let totalSize = 80;  // 基础系统
    plugins.forEach(pkg => {
        totalSize += pluginSizes[pkg] || pluginSizes.default;
    });
    return totalSize;
}
```

**问题**:
- ❌ 只有 11 个插件有大小定义
- ❌ 默认 5MB 不准确
- ❌ 没有计算依赖包大小
- ❌ 基础系统 80MB 假设不准确

**影响**: 估算结果可能偏差很大

**修复方案**:
```javascript
// 添加更多插件大小
const pluginSizes = {
    // ... 所有 108 个插件
    'default': 7  // 更准确的默认值
};

// 计算依赖大小
function estimateFirmwareSize() {
    const {plugins} = getAllPluginsWithDependencies();
    let totalSize = 80;
    
    plugins.forEach(pkg => {
        totalSize += pluginSizes[pkg] || 7;
    });
    
    // 添加 10% 缓冲
    return Math.ceil(totalSize * 1.1);
}
```

---

### Bug #3: 冲突检测不完整

**问题代码**:
```javascript
const pluginConflicts = [
    ['luci-app-openclash', 'luci-app-clash', 'Clash 客户端'],
    ['luci-app-passwall', 'luci-app-passwall2', 'PassWall 版本'],
    // ... 只有 5 个冲突
];
```

**问题**:
- ❌ 只检测 5 个冲突
- ❌ 没有检测架构冲突
- ❌ 没有检测资源冲突

**影响**: 用户可能选择不兼容的插件组合

**修复方案**:
```javascript
const pluginConflicts = [
    // 客户端冲突
    ['luci-app-openclash', 'luci-app-clash', 'Clash 客户端'],
    ['luci-app-ssr-plus', 'luci-app-shadowsocks-libev', 'SS 客户端'],
    
    // 版本冲突
    ['luci-app-passwall', 'luci-app-passwall2', 'PassWall 版本'],
    
    // 功能冲突
    ['luci-app-adguardhome', 'luci-app-adbyby-plus', '去广告插件'],
    ['firewall4', 'iptables', '防火墙类型'],
    
    // 资源冲突
    ['luci-app-dockerman', 'luci-app-qbittorrent', '内存密集型 (需要 1GB+)'],
];
```

---

### Bug #4: 依赖检测可能导致无限循环

**问题代码**:
```javascript
function getAllPluginsWithDependencies() {
    const allPlugins = new Set(Object.keys(selectedPlugins));
    
    Object.keys(selectedPlugins).forEach(pkg => {
        if (pluginDependencies[pkg]) {
            pluginDependencies[pkg].forEach(dep => {
                allPlugins.add(dep);  // 可能添加已存在的
            });
        }
    });
    
    return {plugins: allPlugins, dependencies};
}
```

**问题**:
- ❌ 依赖的依赖没有处理
- ❌ 可能形成循环依赖
- ❌ 没有检测缺失的依赖包

**影响**: 某些依赖可能缺失

**修复方案**:
```javascript
function getAllPluginsWithDependencies() {
    const allPlugins = new Set();
    const dependencies = [];
    const visited = new Set();
    
    function addWithDeps(pkg) {
        if (visited.has(pkg)) return;
        visited.add(pkg);
        allPlugins.add(pkg);
        
        if (pluginDependencies[pkg]) {
            pluginDependencies[pkg].forEach(dep => {
                dependencies.push(`${pkg} → ${dep}`);
                addWithDeps(dep);
            });
        }
    }
    
    Object.keys(selectedPlugins).forEach(pkg => {
        addWithDeps(pkg);
    });
    
    return {plugins: allPlugins, dependencies};
}
```

---

## 🟡 中等 Bug (建议修复)

### Bug #5: 搜索防抖可能导致延迟

**问题**: 300ms 防抖在某些情况下感觉慢

**修复**: 可调整为 200ms 或使用更智能的防抖

---

### Bug #6: 编译进度轮询间隔太长

**问题**: 30 秒间隔太长，用户可能等很久才知道完成

**修复**: 改为 10 秒，或使用 WebSocket 实时推送

---

### Bug #7: 没有处理 GitHub API 限流

**问题**: 未认证用户只有 60 次/小时

**修复**: 使用用户 Token 或添加限流处理

---

### Bug #8: 移动端显示问题

**问题**: 
- 编译进度弹窗在移动端可能被遮挡
- 固定定位在 iOS Safari 有问题

**修复**: 使用更兼容的定位方式

---

## 🟢 轻微问题 (可选修复)

### Bug #9: 缺少加载状态

**问题**: 切换分类时没有加载提示

**修复**: 添加骨架屏或 loading 动画

---

### Bug #10: 错误提示不够友好

**问题**: alert() 不够美观

**修复**: 使用自定义模态框

---

## 📊 Bug 统计

| 严重程度 | 数量 | 状态 |
|---------|------|------|
| 🔴 严重 | 4 | 待修复 |
| 🟡 中等 | 4 | 待修复 |
| 🟢 轻微 | 2 | 待修复 |
| **总计** | **10** | - |

---

## 🎯 修复优先级

### P0 - 立即修复
1. ✅ Bug #1: 编译进度错误处理
2. ✅ Bug #3: 冲突检测完善
3. ✅ Bug #4: 依赖循环检测

### P1 - 今天修复
4. ✅ Bug #2: 固件大小准确估算
5. ✅ Bug #7: API 限流处理

### P2 - 本周修复
6. ⏳ Bug #5: 搜索防抖优化
7. ⏳ Bug #6: 轮询间隔优化
8. ⏳ Bug #8: 移动端优化

---

## 🔧 快速修复方案

### 修复 Bug #1 (编译进度)

```javascript
function startBuildMonitor() {
    buildMonitorInterval = setInterval(async () => {
        const token = localStorage.getItem('github_token');
        
        try {
            const response = await fetch(
                'https://api.github.com/repos/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Custom-Build.yml/runs?status=in_progress&per_page=1',
                {
                    headers: {
                        'Accept': 'application/vnd.github.v3+json',
                        'Authorization': token ? `token ${token}` : ''
                    }
                }
            );
            
            if (response.status === 403) {
                console.warn('API 限流');
                return;
            }
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            const data = await response.json();
            if (data.total_count > 0) {
                showBuildProgress(data.workflow_runs[0]);
            }
        } catch (error) {
            console.error('监控失败:', error);
        }
    }, 10000);  // 改为 10 秒
}
```

---

## ✅ 检查结论

**整体质量**: ⭐⭐⭐⭐ (4/5)

**优点**:
- ✅ 功能完整
- ✅ 架构清晰
- ✅ 性能优化到位

**需改进**:
- ❌ 错误处理不足
- ❌ 边界情况考虑不周
- ❌ API 限流未处理

**建议**: 优先修复 P0 级别的 4 个严重 Bug

---

*检查完成时间：2026-04-11 23:27*
