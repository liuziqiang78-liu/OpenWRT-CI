# 🐛 Web UI 深度交叉分析报告

**分析时间**: 2026-04-11
**分析方法**: Web UI + GitHub 工作流交叉验证

---

## 🔴 严重 Bug (必须修复)

### Bug #1: Web UI 发送的参数与工作流不匹配

**问题**:
```javascript
// Web UI 发送
PROXY_PLUGIN: 'homeproxy,openclash'
STORAGE_PLUGIN: 'diskman,samba4'
NETWORK_TOOL: 'tailscale,ddns-go'
```

**工作流期望**:
```yaml
# Custom-Build.yml 定义的参数
PROXY_PLUGIN: ✅ 匹配
STORAGE_PLUGIN: ✅ 匹配
NETWORK_TOOL: ✅ 匹配
```

**状态**: ✅ 已匹配 (之前修复过)

---

### Bug #2: 插件数据库不完整

**问题**:
```javascript
// Web UI 中 network 分类的插件没有 features 字段
network: [
    {name: 'Tailscale', pkg: 'luci-app-tailscale-community', desc: '虚拟组网'},
    // 缺少 features 字段!
]
```

**影响**: 展开详情时功能描述为空

**修复方案**: 为所有 network 插件添加 features 字段

---

### Bug #3: 主题插件未实现

**问题**:
```javascript
// Web UI 有主题分类
<div class="plugin-tab" onclick="switchTab('theme')">🎨 主题 (13)</div>

// 但 PLUGINS 对象中没有 theme 分类
const PLUGINS = {
    proxy: [...],
    storage: [...],
    network: [...],
    // theme: [] ← 缺失!
    system: [...]
};
```

**影响**: 点击"主题"标签会报错

**修复方案**: 添加 theme 分类到 PLUGINS 对象

---

### Bug #4: 系统工具插件未实现

**问题**:
```javascript
// Web UI 有系统工具分类
<div class="plugin-tab" onclick="switchTab('system')">🔧 系统工具 (20+)</div>

// PLUGINS 对象中 system 分类为空或缺失
```

**影响**: 点击"系统工具"标签会报错

**修复方案**: 添加完整的 system 分类数据

---

## 🟡 中等 Bug (建议修复)

### Bug #5: 搜索功能不完善

**问题**:
```javascript
function filterPlugins() {
    const search = document.getElementById('plugin-search').value.toLowerCase();
    const items = document.querySelectorAll('.plugin-item');
    
    items.forEach(item => {
        const name = item.querySelector('.plugin-name').textContent.toLowerCase();
        const desc = item.querySelector('.plugin-desc').textContent.toLowerCase();
        item.style.display = (name.includes(search) || desc.includes(search)) ? 'block' : 'none';
    });
}
```

**问题**:
1. 只搜索当前分类的插件
2. 搜索后计数不准确
3. 搜索后无法全选

**修复方案**: 
- 跨分类搜索
- 更新计数显示
- 优化全选逻辑

---

### Bug #6: 展开详情数据不完整

**问题**:
```javascript
// 只有部分插件有 features 字段
{name: 'HomeProxy', features: '支持多种协议...'}
{name: 'Tailscale'} // 没有 features!
```

**影响**: 展开后功能描述显示为空

**修复方案**: 为所有插件添加 features 字段

---

### Bug #7: 表单验证不完整

**问题**:
```javascript
function validateForm() {
    const required = ['github_token', 'wrt_source', 'wrt_branch', 'target_platform', 'theme'];
    for (const id of required) {
        if (!document.getElementById(id).value) {
            alert(`请填写必填项`); // 没有说明具体哪项
            return false;
        }
    }
}
```

**问题**:
1. 错误提示不明确
2. 没有验证插件选择（至少选 1 个）
3. 没有验证 Token 格式

**修复方案**:
```javascript
function validateForm() {
    // 验证 Token
    const token = document.getElementById('github_token').value.trim();
    if (!token) {
        alert('请填写 GitHub Token');
        document.getElementById('github_token').focus();
        return false;
    }
    if (!token.startsWith('ghp_')) {
        alert('Token 格式错误，应以 ghp_ 开头');
        return false;
    }
    
    // 验证至少选择 1 个插件
    if (Object.keys(selectedPlugins).length === 0) {
        alert('请至少选择 1 个插件');
        return false;
    }
    
    return true;
}
```

---

## 🟢 轻微问题 (可选修复)

### Bug #8: 移动端横向滚动优化

**问题**: 插件标签在部分设备上滚动不流畅

**修复方案**: 添加滚动优化 CSS

---

### Bug #9: 加载状态不明显

**问题**: 插件加载时没有 loading 提示

**修复方案**: 添加骨架屏或 loading 动画

---

### Bug #10: 错误处理不完善

**问题**:
```javascript
try {
    const response = await fetch(...);
} catch (error) {
    alert('❌ 触发失败：' + error.message);
}
```

**问题**: 
1. 没有网络错误提示
2. 没有超时处理
3. 没有重试机制

**修复方案**: 添加完善的错误处理

---

## 📊 Bug 统计

| 严重程度 | 数量 | 状态 |
|---------|------|------|
| 🔴 严重 | 4 | 待修复 |
| 🟡 中等 | 3 | 待修复 |
| 🟢 轻微 | 3 | 待修复 |
| **总计** | **10** | - |

---

## 🔧 修复优先级

### P0 - 立即修复
1. ✅ Bug #2: 完善 network 插件数据
2. ✅ Bug #3: 添加 theme 分类
3. ✅ Bug #4: 添加 system 分类

### P1 - 今天修复
4. ✅ Bug #5: 优化搜索功能
5. ✅ Bug #6: 完善 features 字段
6. ✅ Bug #7: 增强表单验证

### P2 - 本周修复
7. ⏳ Bug #8: 移动端优化
8. ⏳ Bug #9: 加载状态
9. ⏳ Bug #10: 错误处理

---

## 📝 修复计划

### 第一步：完善数据 (P0)
```javascript
// 添加 theme 分类
theme: [
    {name: 'Argon', pkg: 'luci-theme-argon', desc: '流行主题', version: 'v3.2.1', features: '毛玻璃效果、多种配色'},
    // ... 13 个主题
]

// 添加 system 分类
system: [
    {name: 'TTYD', pkg: 'luci-app-ttyd', desc: '网页终端', version: 'v1.0', features: 'SSH 访问、多会话'},
    // ... 25 个系统工具
]

// 完善 network 分类的 features
network: [
    {name: 'Tailscale', pkg: 'luci-app-tailscale-community', desc: '虚拟组网', version: 'v1.3.0', features: '异地组网、P2P 直连'},
    // ... 为所有插件添加 features
]
```

### 第二步：优化功能 (P1)
```javascript
// 优化搜索
function filterPlugins() {
    // 跨分类搜索
    // 更新计数
    // 优化显示
}

// 增强验证
function validateForm() {
    // Token 格式验证
    // 至少选 1 个插件
    // 明确错误提示
}
```

### 第三步：提升体验 (P2)
```javascript
// 加载状态
// 错误处理
// 移动端优化
```

---

*报告生成时间：2026-04-11*
