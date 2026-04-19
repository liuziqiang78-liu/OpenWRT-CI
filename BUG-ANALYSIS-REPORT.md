# OpenWRT-CI 项目 Bug 交叉分析报告

**分析日期**: 2026-04-19  
**分析范围**: Web UI 前端 + 后端脚本 + 配置文件 + CI 工作流  
**项目路径**: /root/.openclaw/workspace/OpenWRT-CI

---

## 一、前端 Bug (build-ui-full.html)

### Bug #1: [严重程度: Critical]
- **位置**: build-ui-full.html — MEDIATEK DEVICES 数组
- **问题描述**: 前端设备 ID 使用 `xiaomi_mi-router-ax3000t` 格式，但 Config/device/ 目录中的配置文件名为 `xiaomi_ax3000t.txt`（缺少 `mi-router-` 前缀）。受影响设备包括：
  - `xiaomi_mi-router-ax3000t` → 实际文件: `xiaomi_ax3000t.txt`
  - `xiaomi_mi-router-ax3000t-ubootmod` → 实际文件不存在（仅有 `xiaomi_ax3000t.txt`）
  - `xiaomi_mi-router-wr30u-stock` → 实际文件: `xiaomi_wr30u-stock.txt`
  - `xiaomi_mi-router-wr30u-ubootmod` → 实际文件: `xiaomi_wr30u-ubootmod.txt`
  - `xiaomi_redmi-router-ax6000-stock` → 实际文件: `redmi_ax6000-stock.txt`
  - `xiaomi_redmi-router-ax6000-ubootmod` → 实际文件: `redmi_ax6000-ubootmod.txt`
- **影响**: 用户选择这些设备并触发编译后，Custom-Build.yml 的 `TARGET_DEVICE` 传入错误 ID，导致找不到 `Config/device/{id}.txt` 文件，编译直接失败退出。
- **修复建议**: 统一使用与 Config/device/ 文件名一致的 ID 格式，去掉 `mi-router-` 和 `redmi-router-` 等多余前缀。

### Bug #2: [严重程度: Critical]
- **位置**: build-ui-full.html — ROCKCHIP DEVICES 数组
- **问题描述**: ROCHIP 设备 ID 使用连字符格式（如 `friendlyarm_nanopi-r2s`、`xunlong_orangepi-5`），但 Config/device/ 中的配置文件使用下划线格式（如 `nanopi_r2s.txt`、`orangepi_5.txt`）。全部 ROCKCHIP 设备 ID 都不匹配。
- **影响**: 同 Bug #1，所有 ROCKCHIP 设备编译会失败。
- **修复建议**: 将 ROCKCHIP 设备 ID 改为与 Config/device/ 文件名一致的格式（去掉厂商前缀，统一使用下划线）。

### Bug #3: [严重程度: Critical]
- **位置**: build-ui-full.html — X86 DEVICES 数组
- **问题描述**: X86 设备 ID 为 `generic`，但 Config/device/ 中的配置文件名为 `x86_generic.txt`。
- **影响**: X86 编译会失败，找不到设备配置文件。
- **修复建议**: 将 ID 改为 `x86_generic` 或在 Custom-Build.yml 中添加逻辑适配。

### Bug #4: [严重程度: Major]
- **位置**: build-ui-full.html — PLUGINS.proxy 数组
- **问题描述**: `luci-app-v2raya` 插件的 `name` 字段为 `'luci-xray'`，这与 `luci-app-xray` 插件混淆，应该是 `'v2rayA'`（参考 complete-plugins.js）。同时 `V2Ray Server` 插件（`luci-app-v2ray-server`）在 plugins/ 目录和 generate-plugins.sh 中均不存在对应的配置。
- **影响**: 用户选择 V2Ray Server 插件后，后端无法找到对应仓库，安装失败。v2rayA 名称错误会造成用户困惑。
- **修复建议**: 将 v2rayA 的 name 改为 `'v2rayA'`；移除或标记 V2Ray Server 为不可用。

### Bug #5: [严重程度: Major]
- **位置**: build-ui-full.html — PLUGINS.system 数组
- **问题描述**: `luci-app-oaf` 插件同时出现在 `PLUGINS.network` 和 `PLUGINS.system` 两个分类中（重复定义）。
- **影响**: 用户可能困惑，且统计计数不准确。虽不会导致编译错误，但影响用户体验。
- **修复建议**: 从其中一个分类中移除重复项，保留 `PLUGINS.network`（参考 generate-plugins.sh 分类）。

### Bug #6: [严重程度: Minor]
- **位置**: build-ui-full.html — 插件 Tab 计数
- **问题描述**: HTML 中各 Tab 的 `.count` span 是硬编码数字：
  - proxy: 显示 `12`，实际 `9` 项（或 10 项含 V2Ray Server）
  - storage: 显示 `16`，实际 `15` 项
  - network: 显示 `32`，实际 `27` 项（或 28 项含 OAF）
  - theme: 显示 `13`，实际 `4` 项
  - system: 显示 `28`，实际 `23` 项
- **影响**: Tab 显示的插件数量与实际不符，误导用户。
- **修复建议**: 在 `updateTabCounts()` 中同时更新 HTML Tab 中的 `.count` span 内容。

### Bug #7: [严重程度: Minor]
- **位置**: build-ui-full.html — `startBuildMonitor()` 函数
- **问题描述**: 编译监控的 GitHub API 请求中，仓库地址硬编码为 `liuziqiang78-liu/OpenWRT-CI`，不支持 fork 仓库。
- **影响**: 如果用户 fork 了此仓库，监控功能会查询错误的仓库，无法检测到自己的编译状态。
- **修复建议**: 从 GitHub Token 或页面 URL 动态获取仓库路径，或添加配置项。

### Bug #8: [严重程度: Minor]
- **位置**: build-ui-full.html — PLUGINS.proxy 数组，SSR-Plus 对象
- **问题描述**: SSR-Plus 插件定义的末尾有一个多余逗号（trailing comma）：
  ```javascript
  {name: 'V2Ray Server', pkg: 'luci-app-v2ray-server', desc: 'V2Ray 服务器', features: '服务器管理、多协议'},
  ],
  ```
  多个分类数组末尾都有类似问题。
- **影响**: 现代浏览器引擎可容忍，但严格模式或旧版环境可能报语法错误。
- **修复建议**: 清除所有数组末尾的多余逗号。

### Bug #9: [严重程度: Minor]
- **位置**: build-ui-full.html — `theme` select 下拉框
- **问题描述**: 主题选项仅有 Argon、Aurora、Kucat、none 四个，但 generate-plugins.sh 中生成了 11 个主题（含 Material、Material3、Design、Alpha、Spectra、Routerich 等），complete-plugins.js 中有 13 个主题。
- **影响**: 用户无法通过 UI 选择其他主题，但后端支持更多主题。选项不完整。
- **修复建议**: 在下拉框中添加更多主题选项，或说明为什么仅显示这些。

### Bug #10: [严重程度: Major]
- **位置**: build-ui-full.html — 主题 `select` 下拉框中 `none` 选项
- **问题描述**: 当用户选择 `none` 时，Settings.sh 会执行 `sed -i "s/luci-theme-bootstrap/luci-theme-none/g"`，导致默认主题被设为不存在的 `luci-theme-none`。Custom-Build.yml 中也会写入 `CONFIG_PACKAGE_luci-theme-none=y`，这是一个不存在的包。
- **影响**: 选择"默认主题"会导致构建失败或固件启动后无主题。
- **修复建议**: 在 Settings.sh 和 Custom-Build.yml 中添加 `if [ "$THEME" != "none" ]` 条件判断，跳过无效主题配置。

---

## 二、后端脚本 Bug

### Bug #11: [严重程度: Critical]
- **位置**: Scripts/Settings.sh — 防火墙配置部分
- **问题描述**: 脚本无条件添加 `CONFIG_PACKAGE_firewall4=y`，完全忽略 `FIREWALL_TYPE` 用户选择。当用户选择 iptables 时，firewall4 仍会被强制启用。
- **影响**: 用户的防火墙选择被忽略，始终使用 firewall4。
- **修复建议**: 添加条件判断：
  ```bash
  if [ "$FIREWALL_TYPE" = "firewall4" ]; then
      echo "CONFIG_PACKAGE_firewall4=y" >> ./.config
  else
      echo "# CONFIG_PACKAGE_firewall4 is not set" >> ./.config
      echo "CONFIG_PACKAGE_firewall=y" >> ./.config
  fi
  ```

### Bug #12: [严重程度: Major]
- **位置**: Scripts/Settings.sh — 软件源替换部分
- **问题描述**: 硬编码使用 `24.10-SNAPSHOT` 作为软件源版本路径。但如果源码分支是 `openwrt-23.05` 或其他版本，软件源 URL 将不匹配。
- **影响**: 使用非 24.10 分支时，软件源配置错误，导致 opkg 安装包失败。
- **修复建议**: 从源码中动态检测 OpenWrt 版本号，替换到 URL 中。

### Bug #13: [严重程度: Major]
- **位置**: Scripts/Packages.sh — UPDATE_PACKAGE 函数中 `nikki` 的调用
- **问题描述**: `UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"` 使用了 `nikkinikki-org` 仓库，但 `scripts/generate-plugins.sh` 中 Nikki 插件的仓库指向 `sbwml/luci-app-nikki`（不存在的仓库）。
- **影响**: 通过 `install-plugins.sh` 安装 Nikki 插件会失败（仓库不存在），但通过 Packages.sh 安装可以成功。两条路径行为不一致。
- **修复建议**: 统一仓库地址为 `nikkinikki-org/OpenWrt-nikki`。

### Bug #14: [严重程度: Major]
- **位置**: Scripts/Packages.sh — nekobox 的 UPDATE_PACKAGE 调用
- **问题描述**: `UPDATE_PACKAGE "nekobox" "Thaolga/openwrt-nekobox" "main"` 使用 `Thaolga` 仓库，但 `scripts/generate-plugins.sh` 中 NeKoBox 指向 `sbwml/luci-app-nekobox`。同理 `qosmate` 使用 `hudra0/luci-app-qosmate`，但其他地方可能不同。
- **影响**: 插件安装路径不一致，某些路径会安装失败。
- **修复建议**: 统一所有地方的仓库地址。

### Bug #15: [严重程度: Minor]
- **位置**: Scripts/Packages.sh — `EXTRACT_FROM_CONSOLIDATED "sbwml/openwrt-package"`
- **问题描述**: 该函数中同时提取 `luci-app-samba4`，但之前已从 `sbwml/luci` 中提取过同名包。`luci-app-arpbind` 同样存在重复提取（也从 `sbwml/luci` 通过 generic 方式可获取）。
- **影响**: 可能导致 feeds 中的包被错误覆盖或编译冲突。
- **修复建议**: 去除重复提取的包名。

---

## 三、插件安装脚本 Bug

### Bug #16: [严重程度: Critical]
- **位置**: scripts/generate-plugins.sh — Nikki 插件
- **问题描述**: `create_plugin "Nikki" "luci-app-nikki" ... "https://github.com/sbwml/luci-app-nikki.git"` 引用的仓库 `sbwml/luci-app-nikki` 不存在（实际仓库为 `nikkinikki-org/OpenWrt-nikki`）。
- **影响**: 通过 install-plugins.sh 安装 Nikki 插件会 git clone 失败。
- **修复建议**: 改为 `https://github.com/nikkinikki-org/OpenWrt-nikki.git`。

### Bug #17: [严重程度: Major]
- **位置**: scripts/generate-plugins.sh — 多个主题插件
- **问题描述**: 多个主题插件的仓库地址指向 `kenzok8`（如 `luci-theme-material`、`luci-theme-spectra`、`luci-theme-routerich`、`luci-theme-lightblue`、`luci-theme-teleofis`），但这些仓库可能不存在，且在 plugin-repos.json 中对应条目为空字符串（`"luci-theme-material": ""`）。
- **影响**: 这些主题无法安装，但前端 complete-plugins.js 仍列出它们，用户选择后会安装失败。
- **修复建议**: 移除不可用的主题，或在 config.json 中标记 `note: "不可用"`。

### Bug #18: [严重程度: Major]
- **位置**: scripts/generate-plugins.sh — 多个已删除插件
- **问题描述**: `luci-app-momo`、`luci-app-fc`（FullCombo）、`luci-app-clouddrive2`、`luci-app-homeassistant`、`tvhelper`、`btop` 等插件的仓库 `sbwml/xxx` 可能不存在。Packages.sh 的注释明确说明这些插件"已删除且无替代"。
- **影响**: 用户在前端看到这些插件可选，选择后安装失败。
- **修复建议**: 在 config.json 中标记为不可用，在前端 UI 中显示为禁用/灰色状态。

### Bug #19: [严重程度: Minor]
- **位置**: scripts/install-plugins.sh — `install_plugin_generic` 函数
- **问题描述**: 函数从 `plugin-repos.json` 的 `generic_patterns` 中查找仓库。但这些 generic pattern（如 `https://github.com/sbwml/luci-app-{plugin}.git`）不一定对所有插件都有效。
- **影响**: 当直接映射不存在时，generic 模式可能 git clone 到不存在的仓库，浪费时间。
- **修复建议: 在尝试 generic clone 前先用 `git ls-remote` 检查仓库是否存在。

---

## 四、配置文件 Bug

### Bug #20: [严重程度: Major]
- **位置**: plugin-repos.json — 多个条目
- **问题描述**: 以下插件的仓库映射为空字符串：
  - `"luci-app-cloudreve": ""`
  - `"luci-app-ddnsto": ""`
  - `"luci-theme-material": ""`
- **影响**: 通过 plugin-repos.json 回退安装这些插件时，会得到空仓库地址，克隆失败。
- **修复建议**: 移除这些空映射条目，或添加 `note` 字段说明不可用。

### Bug #21: [严重程度: Minor]
- **位置**: plugin-repos.json — `luci-app-linkease`
- **问题描述**: 仓库映射为空字符串 `""`，但 generate-plugins.sh 中指向 `https://github.com/sbwml/luci-app-linkease.git`。
- **影响**: 通过 install-plugins.sh 安装 linkease 可成功（有 config.json），但通过 plugin-repos.json 回退安装会失败。
- **修复建议: 统一填写正确的仓库地址。

### Bug #22: [严重程度: Minor]
- **位置**: Config/device-map.json
- **问题描述**: device-map.json 中存在以下数据问题：
  1. ROCKCHIP 设备使用连字符（`nanopi-r2s`），与前端 ID（`friendlyarm_nanopi-r2s`）和 Config 文件（`nanopi_r2s.txt`）均不匹配
  2. MEDIATEK 设备中 `huasifei_wh3000-emmc` 的中文名写成 "华硕飞"（应为 "华飞"）
  3. MEDIATEK 中 `netcore_n60` 的中文名写成 "网件"（Netcore 应为 "网件" 或 "锐捷"，此处疑似错误）
- **影响**: 如果有代码使用 device-map.json 进行设备查找，会因 ID 不匹配而失败。中文名错误导致显示不准确。
- **修复建议**: 统一 ID 格式，修正中文名称。

---

## 五、CI 工作流 Bug

### Bug #23: [严重程度: Critical]
- **位置**: .github/workflows/Deploy-UI.yml
- **问题描述**: 工作流的触发路径为 `build-ui.html`，但实际文件名为 `build-ui-full.html`。因此当 build-ui-full.html 更新时，Deploy-UI 工作流不会被触发。
- **影响**: UI 更新后不会自动部署到 GitHub Pages。
- **修复建议**: 将触发路径改为 `build-ui-full.html`。

### Bug #24: [严重程度: Major]
- **位置**: .github/workflows/Plugin-Version-Check.yml — Check Plugin Versions step
- **问题描述**: 脚本尝试读取 `Config/VERSIONS.txt` 文件，但该文件在项目中不存在。
- **影响**: 工作流每次运行都会报错 `ENOENT: no such file or directory`，无法完成版本检查。
- **修复建议: 创建 `Config/VERSIONS.txt` 文件，或将脚本改为从 plugin-repos.json 读取。

### Bug #25: [严重程度: Minor]
- **位置**: .github/workflows/Plugin-Version-Check.yml — check_versions.js
- **问题描述**: 使用了已废弃的 GitHub Actions `set-output` 语法：
  ```javascript
  console.log(`::set-output name=has_updates::true`);
  ```
  该语法已被 GitHub 弃用，应使用 `$GITHUB_OUTPUT`。
- **影响**: 目前可能仍有警告，未来 GitHub 完全移除该语法后会导致工作流失败。
- **修复建议**: 改用 `fs.appendFileSync(process.env.GITHUB_OUTPUT, 'has_updates=true\n')` 语法。

### Bug #26: [严重程度: Minor]
- **位置**: .github/workflows/Custom-Build.yml — Generate Configuration step
- **问题描述**: 防火墙配置无条件写入 `CONFIG_PACKAGE_firewall4=y` 和 iptables 相关包，与用户选择的 `FIREWALL_TYPE` 无关。这与 Bug #11 是同一问题的前端和后端两面。
- **影响**: 用户的防火墙类型选择被忽略。
- **修复建议: 根据 `inputs.FIREWALL_TYPE` 条件写入不同的防火墙配置。

### Bug #27: [严重程度: Minor]
- **位置**: .github/workflows/WRT-CORE.yml — Check Scripts step
- **问题描述**: 使用 `actions/cache@main` 而非固定版本号（如 `actions/cache@v4`）。`@main` 可能引入不稳定的变更。
- **影响**: 潜在的缓存行为不一致或工作流中断。
- **修复建议: 使用固定版本号 `actions/cache@v4`。

---

## 六、交叉分析 Bug（前后端不一致）

### Bug #28: [严重程度: Critical]
- **位置**: 前端 build-ui-full.html ↔ 后端 Config/device/
- **问题描述**: 前端 MEDIATEK 设备中有约 10 个设备的 ID 与 Config/device/ 中的文件名不匹配（详见 Bug #1）。这是整个项目最严重的 cross-analysis bug，因为用户在 UI 中选择设备后，后端完全无法找到对应配置。
- **影响**: 所有使用错误 ID 的设备编译必然失败。
- **修复建议**: 建立单一数据源（如 device-map.json），前端和后脚本都从同一来源获取设备 ID。

### Bug #29: [严重程度: Major]
- **位置**: 前端 PLUGINS.theme ↔ 后端 Custom-Build.yml theme options
- **问题描述**: 前端下拉框和 Custom-Build.yml 的 theme 选项一致（argon/aurora/kucat/none），但 generate-plugins.sh 和 complete-plugins.js 中定义了更多主题（Material、Material3、Design、Alpha 等）。这些额外主题在 UI 中不可选。
- **影响**: 用户无法通过 Web UI 选择额外支持的主题。
- **修复建议**: 在前端下拉框中添加这些主题选项，保持前后端一致。

### Bug #30: [严重程度: Major]
- **位置**: 前端 `firewall_type` ↔ 后端 Settings.sh / Custom-Build.yml
- **问题描述**: 前端提供 firewall4 和 iptables 两个选项，但后端（Settings.sh 和 Custom-Build.yml）无条件写入 firewall4 配置，完全忽略用户选择。
- **影响**: 前端选项形同虚设，用户选择 iptables 也不会生效。
- **修复建议: 在 Settings.sh 和 Custom-Build.yml 中添加条件判断逻辑。

### Bug #31: [严重程度: Minor]
- **位置**: complete-plugins.js ↔ generate-plugins.sh
- **问题描述**: complete-plugins.js 中 Nikki 的描述为 "代理工具"，但 generate-plugins.sh 中为 "Mihomo 透明代理"，前端 build-ui-full.html 中为 "Mihomo 透明代理"。描述不一致。
- **影响**: 用户看到的插件描述不一致，造成困惑。
- **修复建议: 统一所有数据源中同一插件的描述。

### Bug #32: [严重程度: Minor]
- **位置**: complete-plugins.js ↔ generate-plugins.sh
- **问题描述**: complete-plugins.js 中 `luci-app-openlist2` 的 name 为 "OpenList2"，但 generate-plugins.sh 中为 "Alist"。两个不同插件（OpenList2 和 iStore/Store）的定位有混淆。
- **影响**: 用户可能无法区分 OpenList2 和 Alist/iStore 的区别。
- **修复建议: 统一名称和描述。

---

## 七、总结表

| 编号 | 严重程度 | 文件 | 类型 | 问题摘要 |
|------|----------|------|------|----------|
| #1 | Critical | build-ui-full.html | 前端 | MEDIATEK 设备 ID 与 Config 文件名不匹配 |
| #2 | Critical | build-ui-full.html | 前端 | ROCKCHIP 设备 ID 与 Config 文件名不匹配 |
| #3 | Critical | build-ui-full.html | 前端 | X86 设备 ID 与 Config 文件名不匹配 |
| #11 | Critical | Scripts/Settings.sh | 后端 | 防火墙类型选择被忽略 |
| #16 | Critical | scripts/generate-plugins.sh | 后端 | Nikki 仓库地址指向不存在的仓库 |
| #23 | Critical | Deploy-UI.yml | CI | 触发路径与实际文件名不匹配 |
| #28 | Critical | 前端 ↔ Config/ | 交叉 | 设备 ID 交叉引用完全失效 |
| #4 | Major | build-ui-full.html | 前端 | v2rayA 名称错误 + V2Ray Server 不存在 |
| #5 | Major | build-ui-full.html | 前端 | OAF 插件重复分类 |
| #10 | Major | build-ui-full.html | 前端 | 主题 "none" 选项导致构建失败 |
| #12 | Major | Scripts/Settings.sh | 后端 | 软件源版本硬编码 |
| #13 | Major | Scripts/Packages.sh | 后端 | Nikki 仓库不一致 |
| #14 | Major | Scripts/Packages.sh | 后端 | NeKoBox/QoS 仓库不一致 |
| #17 | Major | scripts/generate-plugins.sh | 后端 | 多个主题仓库不存在 |
| #18 | Major | scripts/generate-plugins.sh | 后端 | 已删除插件仍可选 |
| #20 | Major | plugin-repos.json | 配置 | 多个仓库映射为空字符串 |
| #24 | Major | Plugin-Version-Check.yml | CI | VERSIONS.txt 文件不存在 |
| #29 | Major | 前端 ↔ 后端 | 交叉 | 主题选项前后端不一致 |
| #30 | Major | 前端 ↔ 后端 | 交叉 | 防火墙选择前后端不一致 |
| #6 | Minor | build-ui-full.html | 前端 | Tab 插件计数不准确 |
| #7 | Minor | build-ui-full.html | 前端 | 编译监控仓库名硬编码 |
| #8 | Minor | build-ui-full.html | 前端 | JS 数组末尾多余逗号 |
| #9 | Minor | build-ui-full.html | 前端 | 主题下拉选项不完整 |
| #15 | Minor | Scripts/Packages.sh | 后端 | 重复提取同一包 |
| #19 | Minor | scripts/install-plugins.sh | 后端 | Generic clone 未验证仓库存在 |
| #21 | Minor | plugin-repos.json | 配置 | Linkease 映射为空 |
| #22 | Minor | Config/device-map.json | 配置 | ID 格式不一致 + 中文名错误 |
| #25 | Minor | Plugin-Version-Check.yml | CI | 废弃的 set-output 语法 |
| #26 | Minor | Custom-Build.yml | CI | 防火墙配置无条件写入 |
| #27 | Minor | WRT-CORE.yml | CI | 使用 actions/cache@main 不稳定版本 |
| #31 | Minor | complete-plugins.js ↔ generate-plugins.sh | 交叉 | 插件描述不一致 |
| #32 | Minor | complete-plugins.js ↔ generate-plugins.sh | 交叉 | 插件名称不一致 |

---

## 统计

| 严重程度 | 数量 |
|----------|------|
| Critical | 7 |
| Major | 13 |
| Minor | 12 |
| **总计** | **32** |

| 类型 | 数量 |
|------|------|
| 前端 Bug | 10 |
| 后端脚本 Bug | 9 |
| 配置文件 Bug | 3 |
| CI 工作流 Bug | 5 |
| 交叉分析 Bug | 5 |

---

## 优先修复建议

1. **最高优先级 (Critical)**: 统一设备 ID 格式。建议将 device-map.json 作为单一数据源，前端 DEVICES 对象和 Config/device/ 文件名都基于此生成。
2. **高优先级**: 修复防火墙选择逻辑（Settings.sh + Custom-Build.yml），使用户选择实际生效。
3. **高优先级**: 修复 Deploy-UI.yml 的触发路径。
4. **高优先级**: 统一所有插件的仓库地址，确保 generate-plugins.sh、Packages.sh、plugin-repos.json 三处一致。
5. **中优先级**: 修复主题 "none" 选项的处理逻辑。
6. **中优先级**: 创建 Config/VERSIONS.txt 或修改 Plugin-Version-Check.yml。
7. **低优先级**: 统一插件描述和名称，清理重复项，修复 Tab 计数。
