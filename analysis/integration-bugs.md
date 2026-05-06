# OpenWRT-CI 前后端集成 Bug 报告

> 生成时间: 2026-05-06
> 检查范围: 前端 (app.js / devices.js / plugins.js) → GitHub Actions workflow → 后端脚本

---

## Bug #1: 前端设备列表包含后端不存在的设备

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/devices.js` ↔ `config/platforms/qualcomm/qualcommax/ipq807x/_devices.yml` |
| **数据流方向** | 前端 → Actions → generate-config.sh |
| **严重程度** | 🔴 高 |
| **问题描述** | 前端 `qualcommax-ipq807x` 设备列表包含以下 5 个设备，但后端 `_devices.yml` 中不存在：`netgear_sxk80`、`redmi_ax6-stock`、`xiaomi_ax3600-stock`、`xiaomi_ax9000-stock`、`zte_mf269-stock`。用户选择这些设备后，前端会生成 `CONFIG_TARGET_DEVICE_qualcommax_ipq807x_DEVICE_netgear_sxk80=y`，但 `make defconfig` 会静默丢弃这些不存在的配置项，导致用户以为设备已选中但实际未编译。 |
| **修复方案** | 方案 A: 在后端 `_devices.yml` 中补充这些设备定义（如果 OpenWrt 源码支持）。方案 B: 从前端 `devices.js` 中移除这些设备。方案 C: 在 `validate-config.sh` 中增加对每个已选设备的验证（目前只验证第一个设备）。 |

---

## Bug #2: WiFi 密码长度验证缺失（前端不拦截，后端报错）

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/app.js` (startBuild) → `scripts/apply-system-config.sh` |
| **数据流方向** | 前端 → Actions → apply-system-config.sh |
| **严重程度** | 🔴 高 |
| **问题描述** | 前端对 WiFi 密码只检查是否包含特殊字符（建议性提示），不检查长度。当用户输入短于 8 位的密码（如 `"abc"`）时，前端允许提交。但后端 `apply-system-config.sh` 第 68 行执行 `if [ -n "$WIFI_PW" ] && [ ${#WIFI_PW} -lt 8 ]; then ... exit 1`，直接报错退出，导致整个编译任务失败。用户体验差：前端不提示，编译后才发现失败。 |
| **修复方案** | 在 `app.js` 的 `startBuild()` 函数中，WiFi 密码验证部分增加长度检查：`if (wifiPw && wifiPw.length < 8) { toast('错误', 'WiFi 密码长度不能少于 8 位 (WPA2 要求)', true); return; }` |

---

## Bug #3: Actions 输入参数未加引号，含空格/特殊字符的值会断裂

| 项目 | 内容 |
|------|------|
| **涉及文件** | `.github/actions/generate-config/action.yml` |
| **数据流方向** | Actions inputs → bash 命令行 |
| **严重程度** | 🔴 高 |
| **问题描述** | Action 中多处使用 `${{ inputs.xxx }}` 直接嵌入 shell 命令，未用引号包裹。当输入值包含空格或 shell 特殊字符时，会被 shell 词拆分。例如：WiFi SSID 为 `My Home WiFi` 时，action 中 `ARGS+=(--wifi-ssid ${{ inputs.wifi_ssid }})` 展开为 `ARGS+=(--wifi-ssid My Home WiFi)`，导致数组元素断裂。同样受影响的参数：`root_password`、`wifi_ssid`、`wifi_password`、`profile`、`plugins`、`custom_config`。`profile` 和 `plugins` 的空格分隔设计使问题更严重——多个设备名会被拆分为独立参数。 |
| **修复方案** | 对所有输入值加双引号：`ARGS+=(--wifi-ssid "${{ inputs.wifi_ssid }}")`。对于 `profile` 和 `plugins`，由于它们本身就是空格分隔的列表，需要在 action 中用引号包裹后传给脚本，脚本端再按空格拆分。 |

---

## Bug #4: validate-config.sh 只验证第一个设备

| 项目 | 内容 |
|------|------|
| **涉及文件** | `.github/actions/generate-config/action.yml` → `scripts/validate-config.sh` |
| **数据流方向** | Actions → validate-config.sh |
| **严重程度** | 🟡 中 |
| **问题描述** | Action 中调用验证脚本时：`FIRST_DEVICE=$(echo "${{ inputs.profile }}" | awk '{print $1}')`，只取第一个设备进行验证。如果用户选择了 5 个设备，其中第 2-5 个设备 ID 不存在或拼写错误，验证不会发现。`make defconfig` 会静默丢弃无效设备，最终固件只包含第一个设备。 |
| **修复方案** | 修改 `validate-config.sh` 支持多设备验证：接收空格分隔的设备列表，逐个检查 `.config` 中是否存在对应的 `CONFIG_TARGET_DEVICE_*_DEVICE_${dev}=y`。 |

---

## Bug #5: ipq40xx/ipq806x 的 subtarget 与 workflow choices 不匹配

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/app.js` (switchPlatformGroup) ↔ `.github/workflows/build-openwrt.yml` ↔ `scripts/generate-config.sh` |
| **数据流方向** | 前端 → workflow → generate-config.sh |
| **严重程度** | 🟡 中 |
| **问题描述** | 前端对 ipq40xx 和 ipq806x 平台设置 `state.subtarget = ''`（空字符串）。workflow 的 subtarget input 默认值为 `'ipq807x'`，选项只有 `ipq807x/ipq60xx/ipq50xx`。但 ipq40xx 的实际 subtarget 是 `generic`，ipq806x 也是 `generic`。前端发送空字符串时，GitHub Actions 会传空值给 action（不会用默认值），action 跳过 `--subtarget` 参数，脚本自动从 `_platform.yml` 提取第一个 subtarget（`generic`）。虽然最终结果正确，但这个流程是脆弱的：如果 `_platform.yml` 中 subtarget 的顺序改变，或 grep 提取逻辑出错，就会失败。 |
| **修复方案** | 在 workflow 的 subtarget input 中增加 `generic` 选项，并在前端根据平台自动选择正确的 subtarget。或者在 action 中对 subtarget 为空的情况做显式默认值处理。 |

---

## Bug #6: 前端插件防火墙兼容性过滤与后端不完全对齐

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/plugins.js` (PLUGIN_CATS) ↔ `scripts/generate-config.sh` (firewall-compat.yml) |
| **数据流方向** | 前端 ↔ 后端（双向过滤） |
| **严重程度** | 🟡 中 |
| **问题描述** | 前端通过 `fw` 属性（0=通用, 1=仅iptables, 2=仅nftables）过滤插件。后端通过 `config/plugins/firewall-compat.yml` 的 `iptables_only` 列表过滤。两套过滤系统独立维护，可能出现不一致：(1) 前端标记为 `fw:2`（仅nftables）的插件，后端可能不在过滤列表中；(2) 后端 `firewall-compat.yml` 可能不存在，此时后端跳过所有兼容性检查。例如：`luci-app-privoxy` 前端标记 `fw:1`（仅iptables），但后端是否在 `iptables_only` 列表中未知。 |
| **修复方案** | 统一过滤逻辑：方案 A: 后端生成 `firewall-compat.yml` 时读取前端的 `fw` 属性作为数据源。方案 B: 在 `generate-config.sh` 中增加对 `fw` 属性的检查。方案 C: 确保 `firewall-compat.yml` 始终存在且与前端 `PLUGIN_CATS` 同步。 |

---

## Bug #7: 前端包含后端 config 中不存在的插件

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/plugins.js` ↔ `config/plugins/` 目录 |
| **数据流方向** | 前端 → Actions → generate-config.sh |
| **严重程度** | 🟡 中 |
| **问题描述** | 前端 `PLUGIN_CATS` 中的多个插件在 `config/plugins/` 目录下没有对应的 `_plugin.yml` 定义。例如代理工具分类中的 `luci-app-gost`、`luci-app-microsocks` 等。虽然这些插件可能在 OpenWrt 源码的 feed 中存在，但缺少 `_plugin.yml` 意味着：(1) 没有 feed 源配置，`make defconfig` 可能找不到包；(2) 没有依赖声明，可能缺少依赖导致编译失败。用户选择这些插件后，编译可能静默跳过或失败。 |
| **修复方案** | 为前端所有插件在 `config/plugins/` 中创建对应的 `_plugin.yml`，或从前端移除没有后端支持的插件。至少在前端标注哪些插件需要额外 feed。 |

---

## Bug #8: localStorage 状态恢复后设备选择可能指向不存在的设备

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/app.js` (loadState / initDevices) |
| **数据流方向** | localStorage → state → UI |
| **严重程度** | 🟢 低 |
| **问题描述** | `loadState()` 从 localStorage 恢复 `state.devices`（Set of device IDs），然后 `initDevices()` 渲染设备列表。如果后端 `_devices.yml` 更新后移除了某些设备，localStorage 中仍保留旧的设备 ID。这些"幽灵设备"会存在于 `state.devices` 中但不在 UI 上显示。虽然不会导致编译错误（因为设备已不在列表中），但 `state.devices.size` 会显示不正确的已选数量，且用户无法取消选择这些不可见的设备。 |
| **修复方案** | 在 `initDevices()` 中增加过滤：`state.devices = new Set([...state.devices].filter(id => (DEVICES[currentSubKey]||[]).some(d => d.id === id)));` |

---

## Bug #9: Workflow 状态轮询可能检查到错误的 workflow run

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/app.js` (startWorkflowCheck) |
| **数据流方向** | 前端 → GitHub API |
| **严重程度** | 🟢 低 |
| **问题描述** | `startWorkflowCheck` 通过 `actions/runs?per_page=1` 获取最新的 workflow run。但获取的是仓库中所有 workflow 的最新 run，不仅仅是刚触发的 `build-openwrt` workflow。如果仓库有其他 workflow（如 CI 测试、自动发布等）在同时运行，可能会检查到错误的 run 状态，给用户显示不相关的编译状态。 |
| **修复方案** | 在 API 查询中增加 workflow 过滤：`actions/workflows/build-openwrt.yml/runs?per_page=1`，或在 response 中检查 `run.workflow_id` 是否匹配 build workflow。 |

---

## Bug #10: API 响应中 `workflow_runs` 数组为空时的静默失败

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/app.js` (startWorkflowCheck) |
| **数据流方向** | GitHub API → 前端 |
| **严重程度** | 🟢 低 |
| **问题描述** | 当 `data.workflow_runs` 为空数组 `[]` 时，`data.workflow_runs?.[0]` 返回 `undefined`，函数直接 `return`，不做任何提示。在新仓库或 workflow 从未运行过的情况下，用户会看到日志面板不再更新，但不知道原因。轮询会持续 60 次后停止，期间用户完全无反馈。 |
| **修复方案** | 在 `workflow_runs` 为空时记录日志：`if (!data.workflow_runs?.length) { log('info', '⏳ 暂无 workflow 运行记录，等待中...'); return; }` |

---

## Bug #11: `custom_config` 的 base64 编码在特殊字符场景下可能产生换行

| 项目 | 内容 |
|------|------|
| **涉及文件** | `assets/app.js` (startBuild) → `scripts/generate-config.sh` |
| **数据流方向** | 前端 → Actions → generate-config.sh |
| **严重程度** | 🟢 低 |
| **问题描述** | 前端使用 `btoa(unescape(encodeURIComponent(customConfig)))` 进行 base64 编码。`btoa` 产生的 base64 字符串不含换行符（这是好的）。但后端 `generate-config.sh` 使用 `echo "$CUSTOM_CONFIG" | base64 -d` 解码。如果 base64 字符串因 GitHub Actions 参数传递被截断或添加了不可见字符，`base64 -d` 会失败。此外，如果用户输入的 `.config` 内容包含 null 字节，`btoa` 会抛出异常但被外层 try-catch 吞掉，导致 `customB64` 为空字符串，编译使用空配置。 |
| **修复方案** | 前端增加 base64 编码失败的显式提示。后端增加 `base64 -d` 失败时的错误处理和日志。 |

---

## 总结

| 严重程度 | 数量 | Bug 编号 |
|----------|------|----------|
| 🔴 高 | 3 | #1, #2, #3 |
| 🟡 中 | 4 | #4, #5, #6, #7 |
| 🟢 低 | 4 | #8, #9, #10, #11 |

**优先修复建议**：
1. **Bug #3** (参数未加引号) — 影响所有含特殊字符的输入，修复成本低
2. **Bug #2** (WiFi 密码长度) — 前端加一行验证即可
3. **Bug #1** (幽灵设备) — 前后端数据同步问题，需要决定保留或移除
