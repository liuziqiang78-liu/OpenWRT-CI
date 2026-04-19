# OpenWRT-CI 第二轮 Bug 分析报告

**分析时间**: 2026-04-19  
**分析范围**: 全项目交叉验证（前端、后端脚本、配置文件、CI 工作流）  
**第一轮修复**: 已确认修复，本轮不再重复报告

---

## Bug 汇总

### Bug #1: [Major] 前端 Tab 计数与 PLUGINS 数组长度严重不符

- **位置**: `build-ui-full.html` — plugin-tabs HTML 区域 vs PLUGINS JavaScript 对象
- **问题描述**: HTML 中硬编码的 `<span class="count">` 数字与 PLUGINS 对象中实际插件数量完全不一致：

  | 分类 | HTML 硬编码 | PLUGINS 实际 | 差异 |
  |------|------------|-------------|------|
  | proxy | 12 | 8 | 多报 4 |
  | storage | 16 | 13 | 多报 3 |
  | network | 32 | 27 | 多报 5 |
  | theme | 13 | 4 | 多报 9 |
  | system | 28 | 21 | 多报 7 |

  根本原因是 `updateTabCounts()` 函数虽然会用 `PLUGINS[cat].length` 覆盖 `.count` 的内容，但在页面 `init()` 时调用了 `renderPlugins('proxy')` 和 `updateSummary()`，但**没有调用 `updateTabCounts()`**，导致初始渲染时显示的是 HTML 硬编码的错误数字。用户切换 tab 后才会通过 `renderPlugins` 间接更新，但 `.count` 的初始值误导用户。

- **影响**: 用户看到的分类插件数量与实际可选数量不符，尤其 theme 标签显示 13 个但实际只有 4 个可选，造成困惑。
- **修复建议**: 在 `init()` 函数中添加 `updateTabCounts()` 调用。或者更彻底地，删除 HTML 中的硬编码数字，在 JS 初始化时动态计算。

---

### Bug #2: [Major] 前端 PLUGINS 对象遗漏了大量已配置的插件

- **位置**: `build-ui-full.html` — PLUGINS JavaScript 对象
- **问题描述**: `plugins/` 目录中有 90 个插件目录（含 config.json），但前端 PLUGINS 对象只包含 73 个。以下 17 个插件在 `plugins/` 中有完整配置但被前端遗漏：

  **有可用仓库的遗漏插件（用户无法通过 UI 选择）**:
  - `luci-app-bandix` — 流量监控（timsaya/luci-app-bandix）
  - `luci-app-cloudreve` — 私有云盘
  - `luci-app-ddnsto` — 内网穿透
  - `luci-app-dockerman` — Docker 管理
  - `luci-app-kodexplorer` — 可道云网盘
  - `luci-app-my-dnsfilter` — DNS 去广告
  - `luci-app-nekobox` — NekoBox 客户端
  - `luci-app-openlist2` — 文件列表（原 Alist）
  - `luci-app-subconverter` — 订阅转换
  - `luci-app-v2ray-server` — V2Ray 服务器
  - `luci-app-wechatpush` — 微信推送
  - `btop` — 性能监控
  - `naiveproxy` — 代理工具
  - `luci-theme-alpha` — Alpha 主题
  - `luci-theme-design` — Design 主题
  - `luci-theme-material` — Material 主题
  - `luci-theme-material3` — Material3 主题

  注意：`luci-app-uugamebooster` 被遗漏是合理的（源仓库已删除且标记不可用），但应在前端明确标注。

- **影响**: 用户无法通过 Web UI 选择这些插件，除非手动填写"其他插件"输入框。theme 标签计数偏差（13 vs 4）也主要由遗漏主题导致。
- **修复建议**: 将以上可用插件添加到前端 PLUGINS 对象的对应分类中，使 UI 与 plugins/ 目录保持一致。

---

### Bug #3: [Critical] luci-app-alist 与 luci-app-openlist2 指向同一仓库，产生命名冲突

- **位置**: `plugins/luci-app-alist/config.json` 和 `plugins/luci-app-openlist2/config.json`
- **问题描述**:
  - `luci-app-alist/config.json` 中 `"package": "luci-app-alist"`，但 `"repository": "https://github.com/sbwml/luci-app-openlist2.git"`
  - `luci-app-openlist2/config.json` 中 `"package": "luci-app-openlist2"`，仓库也是 `sbwml/luci-app-openlist2.git`
  - 两个不同的插件目录指向同一个 Git 仓库。当安装 `luci-app-alist` 时，会克隆 `luci-app-openlist2` 仓库到 `package/luci-app-alist`，但仓库内部的包名是 `luci-app-openlist2`，不是 `luci-app-alist`。
  - 同时 `config.mk` 写入 `CONFIG_PACKAGE_luci-app-alist=y`，但实际构建系统中包名是 `luci-app-openlist2`，导致 `make defconfig` 找不到此包。

- **影响**: 选择 Alist 插件时，配置错误，固件编译时 `make defconfig` 会报告找不到 `luci-app-alist` 包。
- **修复建议**: 删除 `luci-app-alist` 目录，保留 `luci-app-openlist2`；或修改 `luci-app-alist/config.json` 使其指向正确的 Alist 仓库并使用正确的 package 名。

---

### Bug #4: [Major] plugin-repos.json 中 4 个插件仓库地址为空字符串

- **位置**: `plugin-repos.json`
- **问题描述**: 以下插件的仓库值为空字符串 `""`：
  - `luci-app-cloudreve`: `""`
  - `luci-app-ddnsto`: `""`
  - `luci-app-linkease`: `""`
  - `luci-theme-material`: `""`

  当 install-plugins.sh 的回退逻辑（先查 plugins/，再查 plugin-repos.json）触发时，对于上述插件，`jq -r '.[$pkg]'` 返回空字符串。脚本中 `if [ -n "$repo" ] && [ "$repo" != "null" ]` 检查**会通过**（空字符串不是 "null"），随后执行 `git clone ""` 必然失败。

- **影响**: 如果用户通过"其他插件"输入框手动输入这些插件名，且它们不在 plugins/ 目录中（假设目录被删除或名称拼写有误），回退克隆会静默失败。linkease 的空值也会导致 generate-plugins.sh 处理异常。
- **修复建议**: 将这些条目的值改为 `null` 而非空字符串，或在 plugin-repos.json 中直接删除这些条目，让脚本正确走到"无仓库映射"分支。

---

### Bug #5: [Minor] device-map.json 中 ROCKCHIP 设备 key 使用连字符但 config 值使用下划线

- **位置**: `Config/device-map.json` — rockchip 部分
- **问题描述**: ROCKCHIP 部分中，设备 key 使用连字符（如 `nanopi-r2c`, `nanopi-r4s-enterprise`），但对应的 `"config"` 值使用下划线（如 `nanopi_r2c`, `nanopi_r4s-enterprise`）。其中部分 config 值也存在不一致：
  - key: `nanopi-r2c` → config: `nanopi_r2c` ✅ 文件存在
  - key: `nanopi-r2c-plus` → config: `nanopi_r2c-plus` ✅ 文件存在
  - key: `nanopi-r2s` → config: `nanopi_r2s` ✅ 文件存在
  - key: `nanopi-r3s` → config: `nanopi_r3s` ✅ 文件存在
  - key: `nanopi-r4s` → config: `nanopi_r4s` ✅ 文件存在
  - key: `nanopi-r4se` → config: `nanopi_r4se` ✅ 文件存在
  - key: `nanopi-r4s-enterprise` → config: `nanopi_r4s-enterprise` ✅ 文件存在
  - key: `nanopi-r5c` → config: `nanopi_r5c` ✅ 文件存在
  - key: `nanopi-r5s` → config: `nanopi_r5s` ✅ 文件存在
  - key: `nanopi-r6c` → config: `nanopi_r6c` ✅ 文件存在
  - key: `nanopi-r6s` → config: `nanopi_r6s` ✅ 文件存在
  - key: `nanopi-r76s` → config: `nanopi_r76s` ✅ 文件存在
  - key: `fastrhino-r66s` → config: `fastrhino_r66s` ✅ 文件存在
  - key: `fastrhino-r68s` → config: `fastrhino_r68s` ✅ 文件存在
  - key: `orangepi-5` → config: `orangepi_5` ✅ 文件存在
  - key: `orangepi-5-plus` → config: `orangepi_5-plus` ✅ 文件存在
  - key: `orangepi-r1-plus` → config: `orangepi_r1-plus` ✅ 文件存在
  - key: `orangepi-r1-plus-lts` → config: `orangepi_r1-plus-lts` ✅ 文件存在

  实际检查发现 config 值全部能对应到 Config/device/ 文件，但 key 的命名风格不统一（ROCKCHIP 用连字符，其他平台用下划线），如果外部脚本通过 key 而非 config 值去查找文件就会失败。

- **影响**: 当前 build-ui-full.html 直接使用 config 值（ID）作为 TARGET_DEVICE 参数，不受影响。但任何使用 device-map.json key 作为查找依据的外部脚本/工具会找不到文件。
- **修复建议**: 统一所有平台 key 的命名风格，建议全部使用下划线（与前端 DEVICES 对象和 Config/device/ 文件名一致）。

---

### Bug #6: [Major] Settings.sh 和 Custom-Build.yml 重复写入防火墙/主题配置可能导致冲突

- **位置**: `Scripts/Settings.sh` 和 `.github/workflows/Custom-Build.yml`（Generate Configuration 步骤）
- **问题描述**:
  
  Custom-Build.yml 的 "Generate Configuration" 步骤已经完整处理了：
  1. 防火墙配置（firewall4/iptables 切换）
  2. 主题配置（`CONFIG_PACKAGE_luci-theme-$THEME=y` 等）
  3. 中文语言配置

  但同一 workflow 的 "Generate Configuration" 步骤最后又对 QUALCOMMAX 平台做了额外配置。

  如果将来有人在 Custom-Build.yml 中调用 Settings.sh（如 WRT-CORE.yml 的模式），或复用 Settings.sh 脚本，会导致 `.config` 中出现重复的防火墙和主题条目。

  另外 Settings.sh 中的逻辑存在一个小问题：当 `$WRT_THEME` = "none" 时，`sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g"` 会被跳过（正确），但 `echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y"` 也会被跳过（正确）。然而 Settings.sh 仍然会写入 `CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y`，当 THEME=none 时变为 `CONFIG_PACKAGE_luci-app-none-config=y`，这在跳过分支中被 `if [ "$WRT_THEME" != "none" ]` 保护了，所以没有问题。

  但 Settings.sh 中防火墙配置没有做 "none" 或默认保护——它在 else 分支（firewall4）中写了 `CONFIG_PACKAGE_iptables-nft=y`，这意味着即使用户选了 firewall4，也会强制安装 iptables-nft 兼容层。这和 Custom-Build.yml 的逻辑一致（也是 firewall4 + iptables-nft），所以不是 bug，但值得注意。

- **影响**: 目前 Custom-Build.yml 不调用 Settings.sh，无直接影响。但如果将来合并两个流程，会重复写入配置。
- **修复建议**: 明确标记 Settings.sh 为 WRT-CORE.yml 专用，Custom-Build.yml 中不调用。或重构为共享库脚本。

---

### Bug #7: [Minor] generate-plugins.sh 中多个插件仓库地址与 plugin-repos.json 不一致

- **位置**: `scripts/generate-plugins.sh`
- **问题描述**: generate-plugins.sh 中定义了大量插件的仓库地址，其中多个与 plugin-repos.json 中的地址不一致：

  | 插件 | generate-plugins.sh | plugin-repos.json |
  |------|-------------------|-------------------|
  | luci-app-frpc | sirpdboy/luci-app-frpc.git | sbwml/luci.git |
  | luci-app-frps | sirpdboy/luci-app-frps.git | sbwml/luci.git |
  | luci-app-bandix | sirpdboy/luci-app-bandix.git | timsaya/luci-app-bandix.git |
  | luci-app-watchcat | (未定义) | sbwml/luci.git |
  | luci-theme-argon | jerrykuku/luci-theme-argon.git | sbwml/luci-theme-argon.git |
  | luci-theme-aurora | kenzok8/luci-theme-aurora.git | eamonxg/luci-theme-aurora.git |
  | luci-theme-kucat | kenzok8/luci-theme-kucat.git | sirpdboy/luci-theme-kucat.git |

  这些脚本用于不同场景（generate-plugins.sh 用于生成插件目录，plugin-repos.json 用于回退安装），地址不一致会导致：如果有人先用 generate-plugins.sh 生成插件目录，然后在 Custom-Build workflow 中安装，使用的仓库可能不同。

- **影响**: generate-plugins.sh 目前不被 CI workflow 直接调用，影响较小。但如果有人用它来重新生成 plugins/ 目录，仓库来源会发生变化。
- **修复建议**: 以 plugin-repos.json 为权威来源，同步更新 generate-plugins.sh 中的仓库地址。

---

### Bug #8: [Minor] Custom-Build.yml 中 "Install Custom Plugins" 步骤对主题安装存在冗余处理

- **位置**: `.github/workflows/Custom-Build.yml` — "Install Custom Plugins" 步骤
- **问题描述**: 
  ```yaml
  ALL_PLUGINS="$PLUGIN_LIST"
  if [ -n "$THEME" ]; then
    THEME_PKG="luci-theme-${THEME}"
    if [ -n "$ALL_PLUGINS" ]; then
      ALL_PLUGINS="$ALL_PLUGINS,$THEME_PKG"
    else
      ALL_PLUGINS="$THEME_PKG"
    fi
  fi
  ```
  这段代码将主题包名追加到插件列表中，然后用 install-plugins.sh 的逻辑安装。但随后 "Generate Configuration" 步骤又单独写了：
  ```bash
  echo "CONFIG_PACKAGE_luci-theme-${THEME}=y" >> .config
  echo "CONFIG_PACKAGE_luci-app-${THEME}-config=y" >> .config
  echo "CONFIG_DEFAULT_luci-theme-${THEME}=y" >> .config
  ```
  这导致主题包的 .config 条目被写了两次（install-plugins.sh 写一次 + Generate Configuration 写一次）。虽然重复写入 "=y" 不会导致错误，但 `CONFIG_DEFAULT_luci-theme-${THEME}=y` 在 Settings.sh 中不存在，是 Custom-Build.yml 独有的。另外 `luci-app-argon-config` 等主题配置包的处理也需要检查——install-plugins.sh 安装的是 `luci-theme-argon`（包含 config 包），但 Generate Configuration 又额外写了 `CONFIG_PACKAGE_luci-app-argon-config=y`。

- **影响**: 配置冗余，不影响编译但浪费资源（重复克隆同一仓库）。
- **修复建议**: 在 "Install Custom Plugins" 步骤中排除主题包，或在 "Generate Configuration" 步骤中不再重复写主题配置。

---

### Bug #9: [Minor] plugin-repos.json fallback 对 sbwml/luci 等合并仓库的克隆策略不正确

- **位置**: `plugin-repos.json` + `scripts/install-plugins.sh`（回退逻辑）
- **问题描述**: 大量插件映射到 `sbwml/luci.git` 这个合并仓库（如 frpc, frps, smartdns, mwan3, nlbwmon, hd-idle, transmission 等）。当这些插件不在 plugins/ 目录中，走回退逻辑时：
  1. `install-plugins.sh` 会 `git clone --depth=1 https://github.com/sbwml/luci.git "./package/$PLUGIN"`
  2. 这会把整个 sbwml/luci 仓库克隆到 `package/luci-app-frpc/` 目录
  3. 包实际上在仓库的子目录中，不在根目录

  虽然 Custom-Build.yml 的后续步骤会递归搜索 `./package/*/` 目录并启用找到的包，但 `make defconfig` 期望包 Makefile 在 `package/luci-app-frpc/Makefile`，而不是 `package/luci-app-frpc/applications/luci-app-frpc/Makefile`。不过实际上 Custom-Build.yml 的逻辑是：
  ```bash
  for DIR in ./package/*/; do
    PLUGIN_NAME=$(basename $DIR)
    echo "CONFIG_PACKAGE_${PLUGIN_NAME}=y" >> .config
  done
  ```
  它用的是目录名（`luci-app-frpc`）而非实际包名，所以如果仓库结构不是扁平的，`make defconfig` 会找不到包。

- **影响**: 目前不影响，因为所有前端 PLUGINS 对应的插件都在 plugins/ 目录中（有正确仓库），不会触发回退。但如果 plugins/ 目录被意外删除或损坏，回退逻辑会失败。
- **修复建议**: 对于指向合并仓库的插件，在 plugin-repos.json 中使用特定仓库地址而非合并仓库地址。或在 install-plugins.sh 中增加对合并仓库的特殊处理（克隆后搜索并提取目标目录）。

---

### Bug #10: [Minor] 前端 theme 下拉选项与 plugins/ 目录中的可用主题不完全匹配

- **位置**: `build-ui-full.html` — theme `<select>` 下拉框
- **问题描述**: 前端主题下拉框只提供 4 个选项（argon, aurora, kucat, none），但 plugins/ 目录中有 9 个可用主题：
  - luci-theme-alpha — 不在下拉框中
  - luci-theme-argon — ✅ 在下拉框中
  - luci-theme-aurora — ✅ 在下拉框中
  - luci-theme-design — 不在下拉框中
  - luci-theme-kucat — ✅ 在下拉框中
  - luci-theme-material — 不在下拉框中（且仓库为空）
  - luci-theme-material3 — 不在下拉框中
  - luci-theme-openwrt — 不在下拉框中
  - luci-theme-openwrt-2020 — 不在下拉框中

  同时 Custom-Build.yml 的 THEME choice 也只有 argon, aurora, kucat, none 四个选项。如果用户通过 API 直接传入其他主题名（如 "alpha"），workflow 不会拒绝，但前端 UI 无法选择。

- **影响**: 用户无法通过 UI 选择 alpha, design, material3, openwrt 等主题。但这些主题可以通过"其他插件"输入 `luci-theme-alpha` 等手动安装（只安装包，不会设置为默认主题）。
- **修复建议**: 如果想支持更多默认主题，扩展前端下拉框和 Custom-Build.yml 的 choice 列表。或者这是有意设计（只推荐稳定主题），则无需修改。

---

### Bug #11: [Minor] complete-plugins.js 包含大量不可用/不存在的插件定义

- **位置**: `scripts/complete-plugins.js`
- **问题描述**: complete-plugins.js 中定义了多个在 plugins/ 目录和 plugin-repos.json 中不存在或标记为不可用的插件：
  - `luci-app-momo` — 仓库 `nikkinikki-org/OpenWrt-momo` 不在 plugin-repos.json 中
  - `luci-app-fc` (FullCombo Shark!) — 源仓库已删除
  - `luci-app-clouddrive2` — 源仓库已删除
  - `luci-app-npc` — 源仓库已删除
  - `luci-app-thunder` — 源仓库已删除
  - `tvhelper` — 源仓库已删除
  - `btop` — 源仓库已删除（但在 plugin-repos.json 中有旧映射 `sbwml/btop.git`）
  - `luci-theme-spectra` — 不可用
  - `luci-theme-routerich` — 不可用
  - `luci-theme-lightblue` — 不可用
  - `luci-theme-teleofis` — 不可用
  - `luci-app-homeassistant` — 不可用
  - `luci-app-fastnet` — 不在 plugins/ 目录中

  此文件似乎是早期生成 plugins/ 目录的参考数据，但现在已经过时。

- **影响**: 如果有人基于 complete-plugins.js 重建插件系统，会包含大量无效插件。文件本身不被 CI workflow 使用，无直接影响。
- **修复建议**: 标记 complete-plugins.js 为废弃文件，或清理其中不可用的插件条目，与 plugins/ 目录保持同步。

---

### Bug #12: [Minor] 前端 pluginConflicts 定义了无意义的防火墙冲突检测

- **位置**: `build-ui-full.html` — `pluginConflicts` 数组
- **问题描述**: 
  ```javascript
  const pluginConflicts = [
      ...
      ['firewall4', 'iptables', '防火墙类型'],
  ];
  ```
  `firewall4` 和 `iptables` 是防火墙类型的值（来自 `<select id="firewall_type">`），不是插件 pkg 名。`checkConflicts()` 函数检查的是 `selectedPlugins` 的 key，而 selectedPlugins 中永远不会包含 `firewall4` 或 `iptables`（它们不是插件）。因此这条冲突规则永远不会触发。

- **影响**: 无实际影响，是死代码。如果有人想在冲突检测中加入防火墙逻辑，需要通过不同方式实现。
- **修复建议**: 删除这条无用的冲突规则，或重构为对防火墙选择的单独验证逻辑。

---

### Bug #13: [Minor] luci-app-v2ray-server 在 plugins/ 中但不被任何工作流使用

- **位置**: `plugins/luci-app-v2ray-server/`
- **问题描述**: 该插件目录存在于 plugins/ 中，config.json 指向 `https://github.com/openwrt/luci.git`（OpenWrt 官方仓库），但：
  1. 不在前端 PLUGINS 对象中（用户无法选择）
  2. 没有出现在 plugin-repos.json 中
  3. 没有出现在 generate-plugins.sh 中
  4. 只在 complete-plugins.js 中有定义

  该插件是死目录。

- **影响**: 占用空间，可能造成维护困惑。
- **修复建议**: 要么添加到前端 PLUGINS 对象中让用户可选，要么删除此目录。

---

## 总结表

| Bug # | 严重程度 | 文件 | 问题类型 | 状态 |
|-------|---------|------|---------|------|
| #1 | Major | build-ui-full.html | Tab 计数与 PLUGINS 数组不符 | init() 缺少 updateTabCounts() |
| #2 | Major | build-ui-full.html | 17 个插件在前端 PLUGINS 中遗漏 | UI 无法选择 |
| #3 | Critical | plugins/luci-app-alist/ | 与 openlist2 指向同一仓库，包名冲突 | 编译会失败 |
| #4 | Major | plugin-repos.json | 4 个插件仓库地址为空字符串 | 回退逻辑会用空URL克隆 |
| #5 | Minor | Config/device-map.json | ROCKCHIP key 命名风格不统一 | 间接引用可能失败 |
| #6 | Major | Settings.sh + Custom-Build.yml | 配置重复写入（潜在冲突） | 目前无影响，合并流程时会有 |
| #7 | Minor | scripts/generate-plugins.sh | 仓库地址与 plugin-repos.json 不一致 | 生成结果可能不同 |
| #8 | Minor | Custom-Build.yml | 主题安装冗余处理 | 重复克隆/写配置 |
| #9 | Minor | plugin-repos.json + install-plugins.sh | 合并仓库 fallback 策略错误 | 当前不触发 |
| #10 | Minor | build-ui-full.html | 主题下拉选项不全 | 设计决策问题 |
| #11 | Minor | scripts/complete-plugins.js | 包含大量不可用插件 | 数据过时 |
| #12 | Minor | build-ui-full.html | 无意义的防火墙冲突检测 | 死代码 |
| #13 | Minor | plugins/luci-app-v2ray-server/ | 存在但未被使用 | 死目录 |

**统计**: Critical 1 个 | Major 4 个 | Minor 8 个

**最需优先修复**: Bug #3（Alist 命名冲突会导致编译失败）、Bug #1（Tab 计数误导用户）、Bug #2（大量插件不可选）。
