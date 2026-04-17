# 插件仓库映射系统

## 概述

本系统将 WebUI 中的所有插件与对应的 GitHub 仓库地址进行映射，避免了编译时动态搜索仓库，提高了构建速度和可靠性。

## 文件结构

### 核心文件
- `plugin-repos.json` - 插件仓库映射数据库
- `.github/workflows/Custom-Build.yml` - 构建工作流（已集成映射系统）
- `scripts/find-plugin-repos.py` - 自动查找和添加映射的脚本
- `scripts/verify-mappings.py` - 验证映射覆盖率的脚本

### 工作原理

1. **构建时**：工作流读取 `plugin-repos.json`，根据插件名称查找对应的 GitHub 仓库地址
2. **直接映射**：如果插件有直接的仓库地址映射，直接使用该地址克隆
3. **通用模式**：如果没有直接映射，使用 `generic_patterns` 中的模式尝试克隆
4. **备用方案**：如果克隆失败，直接添加到 `.config` 文件，依赖 feeds 中的包

## 映射文件格式

```json
{
  "luci-app-homeproxy": "https://github.com/VIKINGYFY/homeproxy.git",
  "luci-app-openclash": "https://github.com/vernesong/OpenClash.git",
  // ... 更多映射
  "generic_patterns": [
    "https://github.com/sbwml/luci-app-{plugin}.git",
    "https://github.com/sirpdboy/luci-app-{plugin}.git",
    "https://github.com/kenzok8/luci-app-{plugin}.git",
    "https://github.com/xiaorouji/luci-app-{plugin}.git"
  ]
}
```

## 添加新插件映射

### 方法1：自动查找（推荐）
运行自动查找脚本，它会根据已知的作者模式自动添加映射：

```bash
python3 scripts/find-plugin-repos.py
```

### 方法2：手动添加
编辑 `plugin-repos.json` 文件，添加新的映射：

```bash
# 使用 jq 添加映射
jq --arg pkg "luci-app-newwidget" --arg repo "https://github.com/author/luci-app-newwidget.git" '. + {($pkg): $repo}' plugin-repos.json > plugin-repos.json.tmp && mv plugin-repos.json.tmp plugin-repos.json
```

### 方法3：更新通用模式
如果需要添加新的作者模式，编辑 `generic_patterns` 数组：

```json
"generic_patterns": [
  "https://github.com/sbwml/luci-app-{plugin}.git",
  "https://github.com/sirpdboy/luci-app-{plugin}.git",
  "https://github.com/kenzok8/luci-app-{plugin}.git",
  "https://github.com/xiaorouji/luci-app-{plugin}.git",
  "https://github.com/newauthor/luci-app-{plugin}.git"  // 新增
]
```

## 常用作者仓库

| 作者 | 仓库模式 | 包含插件 |
|------|----------|----------|
| sbwml | `https://github.com/sbwml/{plugin}.git` | Aria2、Qbittorrent、WebDAV、Samba4、Lucky 等 |
| sirpdboy | `https://github.com/sirpdboy/{plugin}.git` | DDNS-GO、Kucat主题、定时任务等 |
| kenzok8 | `https://github.com/kenzok8/{plugin}.git` | 多种主题、网络工具等 |
| xiaorouji | `https://github.com/xiaorouji/{plugin}.git` | PassWall 等代理工具 |
| jerrykuku | `https://github.com/jerrykuku/{plugin}.git` | Argon 主题 |

## 特殊插件处理

某些插件有特殊的仓库结构，需要特别处理：

| 插件 | 实际仓库 | 备注 |
|------|----------|------|
| luci-app-ssr-plus | `https://github.com/fw876/helloworld.git` | 仓库名不同 |
| luci-app-adguardhome | `https://github.com/rufengsuixing/luci-app-adguardhome.git` | 特殊作者 |
| luci-app-turboacc | `https://github.com/chenmozhijin/luci-app-turboacc.git` | 特殊作者 |
| 官方插件 | `https://github.com/openwrt/luci.git` | 包含在官方luci中 |

## 验证映射

运行验证脚本检查映射覆盖率：

```bash
python3 scripts/verify-mappings.py
```

## 当前状态

- ✅ **99个插件**全部有直接映射
- ✅ **13个主题**全部有映射
- ✅ **4个通用模式**覆盖常用作者
- ✅ **构建工作流**已集成映射系统

## 更新 WebUI 插件列表

如果 WebUI 添加了新插件 (`scripts/complete-plugins.js`)，需要更新映射：

1. 运行自动查找脚本
2. 验证映射覆盖率
3. 如果有特殊插件，手动添加映射

## 故障排除

### 问题1：插件克隆失败
**症状**：构建日志显示"克隆失败"
**解决**：
1. 检查映射地址是否正确
2. 检查仓库是否公开可用
3. 添加备用通用模式

### 问题2：插件不在映射中
**症状**：构建日志显示"插件不在数据库中"
**解决**：
1. 运行 `python3 scripts/find-plugin-repos.py`
2. 手动添加映射到 `plugin-repos.json`

### 问题3：主题无法安装
**症状**：主题未正确安装
**解决**：
1. 检查主题映射键是否正确 (`luci-theme-{name}`)
2. 验证仓库地址是否有效

## 优势

1. **速度**：无需动态搜索仓库，构建更快
2. **可靠性**：已知仓库地址，避免404错误
3. **维护性**：集中管理，易于更新
4. **扩展性**：支持通用模式，自动覆盖新插件

---

**最后更新**：2026-04-18  
**映射数量**：101个插件映射  
**覆盖率**：100%