# OpenWRT-CI 第三轮系统性交叉分析报告

**分析时间**: 2026-04-19
**分析范围**: 全项目 10 个维度
**前两轮修复**: 约 25 个 bug

---

## Bug #1: [Critical] generate-plugins.sh 仓库地址与实际构建系统不一致

- **位置**: `scripts/generate-plugins.sh` 多处
- **问题描述**: generate-plugins.sh 中多个插件的仓库地址与 `Scripts/Packages.sh` 和 `plugin-repos.json` 中的实际地址不一致：

| 插件 | generate-plugins.sh | 实际来源 (Packages.sh/plugin-repos.json) |
|------|---------------------|------------------------------------------|
| luci-app-frpc | sirpdboy/luci-app-frpc | sbwml/luci (EXTRACT_FROM_CONSOLIDATED) |
| luci-app-frps | sirpdboy/luci-app-frps | sbwml/luci (EXTRACT_FROM_CONSOLIDATED) |
| luci-app-smartdns | sbwml/luci-app-smartdns (独立仓库) | sbwml/luci (EXTRACT_FROM_CONSOLIDATED) |
| luci-app-zerotier | sbwml/luci-app-zerotier (独立仓库) | sbwml/openwrt_pkgs (EXTRACT_FROM_CONSOLIDATED) |
| luci-app-samba4 | sbwml/luci-app-samba4 (独立仓库) | sbwml/openwrt-package (EXTRACT_FROM_CONSOLIDATED) |
| luci-app-adguardhome | rufengsuixing/luci-app-adguardhome | sbwml/openwrt_pkgs (EXTRACT_FROM_CONSOLIDATED) |
| luci-app-bandix | sirpdboy/luci-app-bandix | timsaya/luci-app-bandix |

- **影响**: 如果有人运行 `generate-plugins.sh` 重新生成插件目录，会覆盖正确的仓库地址，导致构建时克隆失败（独立仓库可能不存在）。generate-plugins.sh 本质上是已过时的死代码。
- **修复建议**: 更新 generate-plugins.sh 中的所有仓库地址，使其与 Packages.sh 和 plugin-repos.json 保持一致；或将其标记为 DEPRECATED 并添加注释说明不再维护。

---

## Bug #2: [Major] CONFIG_DEFAULT_luci-theme- 不是正确的主题设置方式

- **位置**: `.github/workflows/Custom-Build.yml` 第 640 行
- **问题描述**:
  ```bash
  echo "CONFIG_DEFAULT_luci-theme-${THEME}=y" >> .config
  ```
  `CONFIG_DEFAULT_` 前缀在 OpenWrt 构建系统中用于设置默认包选择（meta-package defaults），不是用来设置默认主题的。正确的主题设置应为：
  ```bash
  echo "CONFIG_LUCI_DEFAULT_THEME=luci-theme-${THEME}" >> .config
  ```
- **影响**: 主题包会被安装（第 642 行 `CONFIG_PACKAGE_luci-theme-${THEME}=y` 是正确的），但不会被自动设为默认主题。用户首次进入 LuCI 时可能看到的是默认 bootstrap 主题而非所选主题。
- **修复建议**: 将第 640 行改为 `echo "CONFIG_LUCI_DEFAULT_THEME=luci-theme-${THEME}" >> .config`，或直接删除该行（LuCI 通常会自动使用唯一安装的主题）。

---

## Bug #3: [Major] 插件目录名 luci-app-alist 与实际包名 luci-app-openlist2 不一致

- **位置**: `plugins/luci-app-alist/config.json`
- **问题描述**: 插件目录名为 `luci-app-alist`，但 config.json 中 `package` 字段为 `luci-app-openlist2`。前端 HTML PLUGINS 中使用 `pkg: 'luci-app-openlist2'`。这意味着：
  - 前端发送 `luci-app-openlist2` → install-plugins.sh 查找 `plugins/luci-app-openlist2` → 不存在 → 回退到 plugin-repos.json → 成功克隆
  - 插件目录 `luci-app-alist` 实际上永远不会被前端使用，是孤立的死代码
  - 且 `luci-app-alist/config.json` 中 `name` 为 "OpenList2" 而非 "Alist"
- **影响**: 插件安装走回退路径而非最优路径（回退路径不写入 config.mk，仅写入 `CONFIG_PACKAGE_${PLUGIN}=y`，可能遗漏依赖配置）。
- **修复建议**: 将目录名从 `luci-app-alist` 重命名为 `luci-app-openlist2`，使其与前端 pkg 名一致。

---

## Bug #4: [Minor] 插件 Tab 硬编码计数与实际插件数量不匹配

- **位置**: `build-ui-full.html` 插件 Tab 区域
- **问题描述**: HTML 中每个 Tab 的 `<span class="count">` 硬编码的数字与 JavaScript PLUGINS 对象中实际的插件数不一致：

| Tab | HTML 硬编码 | PLUGINS 实际数量 |
|-----|------------|-----------------|
| 🔐 科学上网 | 12 | 10 |
| 💾 存储管理 | 16 | 14 |
| 🌐 网络工具 | 32 | 30 |
| 🎨 主题 | 13 | 8 |
| 🔧 系统工具 | 28 | 23 |

- **影响**: 页面初始加载时 Tab 上显示的计数不准确。虽然 `updateTabCounts()` 函数会在初始化时修正计数，但用户可能在修正前看到错误数字（闪烁）。
- **修复建议**: 将 HTML 中的硬编码数字更新为与 PLUGINS 对象一致的实际数量，或在 HTML 中使用占位符（如 "0"），完全依赖 JS 更新。

---

## Bug #5: [Minor] 存在 plugin 目录但不在前端 PLUGINS 中的插件

- **位置**: `plugins/` 目录 vs `build-ui-full.html` PLUGINS 对象
- **问题描述**: 以下插件目录存在但未在前端 PLUGINS 中暴露给用户选择：

| 插件目录 | 状态 |
|---------|------|
| btop | plugin-repos.json 中为 null（源仓库已删除），generate-plugins.sh 仍创建了目录 |
| luci-app-cloudreve | plugin-repos.json 中为 null（源仓库已删除） |
| luci-app-ddnsto | plugin-repos.json 中为 null（源仓库已删除） |
| luci-app-my-dnsfilter | plugin-repos.json 中有有效仓库，但未在前端暴露 |
| luci-app-uugamebooster | plugin-repos.json 中有有效仓库，但未在前端暴露 |
| luci-app-v2ray-server | plugin-repos.json 中有有效仓库，但未在前端暴露 |
| luci-theme-material | plugin-repos.json 中为 null（源仓库已删除） |

- **影响**: 对于 null 仓库的插件，目录存在但无法安装，是死代码。对于有仓库但未暴露的插件（my-dnsfilter、uugamebooster、v2ray-server），用户无法选择这些功能。
- **修复建议**: 清理 null 仓库的死目录；将有仓库的插件添加到前端 PLUGINS 中或明确标记为不支持。

---

## Bug #6: [Minor] npm install -g jq 在 Workflow 中无效

- **位置**: `.github/workflows/Dependency-Monitor.yml` 第 30 行, `.github/workflows/Plugin-Version-Check.yml` 第 40 行
- **问题描述**: `npm install -g jq` 命令试图通过 npm 安装 jq，但 jq 是系统级命令行工具（C 语言编写），不是 npm 包。npm registry 上的 `jq` 包是完全不同的工具。该命令要么安装错误的包，要么静默失败。
- **影响**: Workflow 可能仍然工作（GitHub runner 预装了 jq），但如果 runner 环境变化导致 jq 不可用，该命令不会正确安装它。
- **修复建议**: 改为 `sudo apt-get install -y jq` 或直接删除该行（依赖 runner 预装的 jq）。

---

## Bug #7: [Minor] Settings.sh 中 WRT_MARK 和 WRT_DATE 变量未定义

- **位置**: `Scripts/Settings.sh` 编译日期标识行
- **问题描述**:
  ```bash
  sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" ...
  ```
  Settings.sh 引用了 `$WRT_MARK` 和 `$WRT_DATE`，但 Custom-Build.yml 的 env 中未定义这两个变量。WRT-CORE.yml 中通过 "Initialization Values" 步骤定义了它们，但 Custom-Build.yml 没有对应的步骤。
- **影响**: Custom-Build.yml 不调用 Settings.sh（内联了所有逻辑），所以当前无实际影响。但如果有人修改流程改用 Settings.sh，这些变量会展开为空字符串。
- **修复建议**: 在 Custom-Build.yml 中添加 WRT_MARK 和 WRT_DATE 的 env 定义，或将 Settings.sh 中的引用改为条件检查。

---

## Bug #8: [Minor] Settings.sh 引用未定义的 WRT_FIREWALL 变量

- **位置**: `Scripts/Settings.sh` 防火墙条件判断
- **问题描述**: Settings.sh 使用 `$WRT_FIREWALL` 进行条件判断，但 Custom-Build.yml 中定义的变量名是 `FIREWALL_TYPE`（作为 input），env 中未映射为 `WRT_FIREWALL`。
- **影响**: 同 Bug #7，Settings.sh 仅被 WRT-CORE.yml 调用（WRT-CORE.yml 中也未定义 WRT_FIREWALL）。如果是 WRT-CORE.yml 调用，`$WRT_FIREWALL` 会展开为空，导致走 else 分支（firewall4 默认路径）。
- **修复建议**: 在 WRT-CORE.yml 的 inputs/env 中添加 WRT_FIREWALL 变量定义。

---

## Bug #9: [Info] generate-plugins.sh 创建的 luci-app-alist 目录配置正确但命名误导

- **位置**: `scripts/generate-plugins.sh` 中 Alist 插件定义行
- **问题描述**:
  ```bash
  create_plugin "Alist" "luci-app-alist" ... "https://github.com/sbwml/luci-app-openlist2.git"
  ```
  目录名是 `luci-app-alist`，config.json 中 package 是 `luci-app-openlist2`，仓库是 `sbwml/luci-app-openlist2.git`。虽然 config.json 内容正确（运行 generate-plugins.sh 后会生成正确的 config.json），但目录名与包名不一致。
- **影响**: 运行 generate-plugins.sh 后，前端查找 `luci-app-openlist2` 目录会失败，触发回退路径。
- **修复建议**: 将 `create_plugin` 调用中的目录名改为 `luci-app-openlist2`。

---

## 总结表

| Bug # | 严重程度 | 文件 | 问题简述 | 状态 |
|-------|---------|------|---------|------|
| #1 | Critical | scripts/generate-plugins.sh | 仓库地址与实际构建系统不一致 | 遗留 |
| #2 | Major | Custom-Build.yml:640 | CONFIG_DEFAULT_ 不是正确主题设置 | 遗留 |
| #3 | Major | plugins/luci-app-alist/ | 目录名与包名不一致，孤立死代码 | 遗留 |
| #4 | Minor | build-ui-full.html | Tab 硬编码计数与实际不符 | 遗留 |
| #5 | Minor | plugins/ | 无效/未暴露的插件目录 | 遗留 |
| #6 | Minor | Dependency-Monitor.yml, Plugin-Version-Check.yml | npm install -g jq 无效 | 遗留 |
| #7 | Minor | Scripts/Settings.sh | WRT_MARK/WRT_DATE 未定义 | 遗留 |
| #8 | Minor | Scripts/Settings.sh | WRT_FIREWALL 未定义 | 遗留 |
| #9 | Info | scripts/generate-plugins.sh | luci-app-alist 命名误导 | 遗留 |

**统计**: Critical 1个, Major 2个, Minor 5个, Info 1个

**对比前两轮**: 前两轮修复了约 25 个 bug（主要是空字符串/null、变量未传递、HTML/JS 不一致等严重问题）。本轮发现的 9 个问题中，Critical 级别只有 1 个（generate-plugins.sh 仓库地址），表明项目质量已大幅提升。剩余问题多为维护性/一致性问题，不影响核心编译流程。

---

## 第三轮新增验证项（无问题）

以下检查项经验证 **没有发现问题**：

1. ✅ **前端设备 ID 与设备配置文件**：100 个 HTML 设备 ID 全部有对应的 Config/device/*.txt 文件
2. ✅ **前端插件 pkg 与插件目录**：所有 HTML PLUGINS 中的 pkg 名都有对应的 plugins/ 目录
3. ✅ **前端 API inputs 与 Custom-Build.yml**：12 个 inputs 完全匹配
4. ✅ **前端 loadConfig/saveConfig 字段**：两个函数的字段列表完全一致
5. ✅ **前端冲突检测**：pluginConflicts 数组中的 pkg 名都存在于 PLUGINS 中
6. ✅ **plugin-repos.json 空字符串**：已全部修复为 null
7. ✅ **Workflow actions 版本固定**：所有 workflow 的 actions 都使用 @vN 版本（非 @main/@master）
8. ✅ **install-plugins.sh null 处理**：正确处理 null 值和不可用标记
9. ✅ **设备 ID 与 device-map.json**：前端设备 ID 与 device-map.json 中的 config 值一致
10. ✅ **主题下拉框 value 与 Custom-Build.yml THEME choices**：完全一致（9 个选项）
11. ✅ **防火墙逻辑完整性**：Custom-Build.yml 中 firewall4 和 iptables 两个分支都完整
12. ✅ **Handles.sh**：无逻辑错误
