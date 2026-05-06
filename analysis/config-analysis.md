# OpenWRT-CI 配置系统分析报告

> 分析时间: 2026-05-06
> 分析范围: config/ 目录下所有配置文件
> 分析版本: v1

---

## 目录

1. [feeds.yml 第三方源分析](#1-feedsyml-第三方源分析)
2. [base-firmware.config 冲突分析](#2-base-firmwareconfig-冲突分析)
3. [平台包列表分析](#3-平台包列表分析)
4. [NSS 配置分析](#4-nss-配置分析)
5. [防火墙模板分析](#5-防火墙模板分析)
6. [设备配置完整性分析](#6-设备配置完整性分析)
7. [废弃配置项分析](#7-废弃配置项分析)
8. [隐式依赖分析](#8-隐式依赖分析)
9. [汇总表](#9-汇总表)

---

## 1. feeds.yml 第三方源分析

### [建议] 第三方源 URL 和分支验证

| 源 | URL | 分支 | 状态 |
|---|---|---|---|
| kenzo | `https://github.com/kenzok8/openwrt-packages` | master | ✅ 存在且活跃 |
| small | `https://github.com/kenzok8/small` | master | ✅ 存在且活跃 |
| kiddin9 | `https://github.com/kiddin9/op-packages` | main | ⚠️ 需确认 |

**问题 1-1 [建议]**: `kiddin9/op-packages` 仓库名变更
- **配置项**: `feeds.yml → kiddin9.url`
- **描述**: kiddin9 的主仓库已从 `op-packages` 更名为 `openwrt-packages`（与 kenzo 同名但不同仓库），或可能使用 `kiddin9/op-repo`。当前仓库名 `op-packages` 可能已过时。
- **修复建议**: 访问 `https://github.com/kiddin9/op-packages` 确认仓库是否存在。如已迁移，更新 URL。如仅作为备用源，可加注释说明。

**问题 1-2 [建议]**: 官方源使用 `main` 分支
- **配置项**: `feeds.yml → openwrt/luci/routing/telephony.branch`
- **描述**: OpenWrt 官方仓库已从 `openwrt-23.05` 等版本分支迁移到 `main`。当前配置使用 `main` 是正确的，但需注意 `main` 分支可能包含未稳定的代码。
- **修复建议**: 如果需要稳定构建，考虑固定到特定 tag（如 `v24.10.0`）或版本分支。如果跟随最新开发，保持 `main` 即可。

**问题 1-3 [建议]**: 缺少 feeds 优先级配置
- **配置项**: `feeds.yml` 全局
- **描述**: 当 kenzo/small 和官方源存在同名包时，没有定义优先级。OpenWrt feeds.conf.default 中默认顺序决定了包的解析优先级。
- **修复建议**: 在 schema 中增加 `priority` 字段，或在文档中说明 feeds 的加载顺序（建议: 官方源 > kiddin9 > kenzo > small）。

---

## 2. base-firmware.config 冲突分析

### [严重] iptables/nftables 混用冲突

**问题 2-1 [严重]**: base-firmware.config 中硬编码了 iptables 专用包
- **配置项**: `CONFIG_PACKAGE_iptables-mod-ipopt=y`
- **描述**: `base-firmware.config` 的 L3 网络基础部分直接启用了 `iptables-mod-ipopt`，这是一个 iptables 专用模块。当选择 `firewall-nftables.config` 时，此包会因缺少 iptables 依赖而编译失败，或产生运行时冲突。
- **修复建议**: 将 `iptables-mod-ipopt` 移至 `firewall-iptables.config`，或在 `firewall-nftables.config` 中添加对应的 nftables 等价包（如 `kmod-nft-compat`）。在 base-firmware.config 中用注释标注由防火墙模板覆盖。

**问题 2-2 [中等]**: base-firmware.config 注释标注与实际不一致
- **配置项**: L3 防火墙注释区域
- **描述**: 注释说 `# CONFIG_PACKAGE_firewall=y ← firewall-iptables.config`，但实际 base-firmware.config 的 L3 部分仍有 `iptables-mod-ipopt` 这个隐式 iptables 依赖。注释暗示 L3 完全由防火墙模板控制，但实际没有做到。
- **修复建议**: 要么将所有 iptables/nftables 相关包都移到防火墙模板，要么在 base-firmware.config 中明确标注哪些包是"双兼容"的、哪些是"防火墙特定"的。

### [中等] 重复包声明

**问题 2-3 [中等]**: full-firmware.config 与 base-firmware.config 存在重复声明
- **配置项**:
  - `CONFIG_PACKAGE_luci-app-attendedsysupgrade=y` — 同时出现在 base-firmware.config (L10) 和 full-firmware.config (E2)
  - `CONFIG_PACKAGE_luci-app-upnp=y` — full-firmware.config (E1) 声明，但防火墙模板也声明了 `miniupnpd-iptables` 或 `miniupnpd-nftables`
- **描述**: 虽然 OpenWrt 的 .config 合并时重复声明不会报错（后者覆盖前者），但这增加了维护负担，容易导致不一致。
- **修复建议**: 每个包只在一个模板中声明。`luci-app-attendedsysupgrade` 已在 base-firmware.config 中，从 full-firmware.config 中移除。

### [建议] wpad-openssl 与 hostapd-common 冗余

**问题 2-4 [建议]**: WiFi 包声明冗余
- **配置项**:
  - `CONFIG_PACKAGE_wpad-openssl=y`
  - `CONFIG_PACKAGE_hostapd-common=y`
- **描述**: `wpad-openssl` 已包含 hostapd 和 wpa_supplicant 的完整功能，`hostapd-common` 是其依赖项，会被自动拉入。显式声明虽无害但冗余。
- **修复建议**: 移除 `CONFIG_PACKAGE_hostapd-common=y`，保留 `wpad-openssl` 即可。

---

## 3. 平台包列表分析

### [严重] qualcommax 默认包对 ipq50xx 不适用

**问题 3-1 [严重]**: `ath11k-firmware-ipq807x` 被列为所有 qualcommax 子目标的默认包
- **配置项**: `qualcommax/_platform.yml → packages.default`
- **描述**: `packages.default` 包含 `ath11k-firmware-ipq807x`，但 qualcommax 平台包含三个子目标：ipq807x、ipq60xx、ipq50xx。ipq50xx 使用的是不同的 WiFi 芯片组，`ath11k-firmware-ipq807x` 对其不适用。同样，`kmod-ath11k-ahb` 和 `kmod-ath11k-pci` 在 ipq50xx 上可能不完全适用。
- **修复建议**: 将 `packages.default` 拆分为子目标级别，或使用条件包列表：
  ```yaml
  subtargets:
    ipq807x:
      extra_packages: [ath11k-firmware-ipq807x, kmod-ath11k, kmod-ath11k-ahb, kmod-ath11k-pci]
    ipq60xx:
      extra_packages: [ath11k-firmware-ipq60xx, kmod-ath11k, kmod-ath11k-ahb]
    ipq50xx:
      extra_packages: [ath11k-firmware-ipq50xx, kmod-ath11k, kmod-ath11k-ahb]
  ```

### [中等] ipq40xx 包含多个 WiFi 固件但设备可能只需一个

**问题 3-2 [中等]**: ipq40xx 默认包含双固件
- **配置项**: `ipq40xx/_platform.yml → packages.default`
- **描述**: 默认包包含 `ath10k-firmware-qca9984` 和 `ath10k-firmware-qca99x0`。大多数 ipq40xx 设备只需要其中一个（取决于具体芯片型号）。同时包含两个会增加固件体积。
- **修复建议**: 在设备级别或子目标级别指定需要的固件，而非全部包含。

### [中等] ipq806x 缺少 nss-firmware 包

**问题 3-3 [中等]**: ipq806x 平台 nss: false 但源码分支仍为 main-nss
- **配置项**: `ipq806x/_platform.yml → nss: false` + `source_branch: "main-nss"`
- **描述**: ipq806x 的 `nss` 标记为 `false`（正确，因为 IPQ806x 硬件上 NSS 支持有限），但 `source_branch` 仍然指向 `main-nss`。如果不需要 NSS，应该使用不含 NSS 补丁的纯净分支，避免不必要的代码引入。
- **修复建议**: 如果 ipq806x 不使用 NSS，将 `source_branch` 改为 `main` 或其他非 NSS 分支。或者如果 main-nss 对 ipq806x 也兼容（NSS 代码只是不启用），保持现状但加注释说明。

### [建议] ipq806x 缺少 NSS 相关的 kernel 模块

**问题 3-4 [建议]**: ipq806x 无 nss 包列表
- **配置项**: `ipq806x/_platform.yml → packages`
- **描述**: ipq806x 的 packages 部分只有 `default` 列表，没有 `nss` 列表。虽然 `nss: false` 表示不启用 NSS，但如果未来需要启用，缺少包定义。
- **修复建议**: 添加空的 `nss: []` 或带注释的 NSS 包列表，便于未来扩展。

---

## 4. NSS 配置分析

### [建议] nss.config 与 qualcommax nss 包列表一致性

**问题 4-1 [建议]**: nss.config 是 qualcommax nss 包的精确副本
- **配置项**: `nss.config` vs `qualcommax/_platform.yml → packages.nss`
- **描述**: `nss.config` 中的 13 个 kmod 包与 `qualcommax/_platform.yml → packages.nss` 完全一致。这意味着维护两份相同列表，修改一处容易忘记另一处。
- **修复建议**: 考虑让 `generate-config.sh` 从 `_platform.yml` 自动生成 `nss.config`，而非手动维护两份。或者在 `nss.config` 中加注释说明来源。

### [建议] NSS 模块列表可能缺少常用模块

**问题 4-2 [建议]**: 缺少部分常用 NSS 模块
- **配置项**: `nss.config` / `qualcommax → packages.nss`
- **描述**: 当前 NSS 包列表缺少以下常用模块（按需）：
  - `kmod-qca-nss-drv-qdisc` — QoS 流量控制
  - `kmod-qca-nss-drv-pptp` — PPTP 加速
  - `kmod-qca-nss-drv-ipsec` — IPSec 加速
  - `kmod-qca-nss-drv-dtls` — DTLS 加速
- **修复建议**: 根据用户场景添加可选 NSS 模块，或在 schema 中标注 `packages.nss_optional` 列表。

---

## 5. 防火墙模板分析

### [严重] 缺少 nftables 对应的 iptables-mod-ipopt 等价包

**问题 5-1 [严重]**: base-firmware.config 中的 `iptables-mod-ipopt` 在 nftables 模式下无替代
- **配置项**: `base-firmware.config → CONFIG_PACKAGE_iptables-mod-ipopt=y`
- **描述**: 当选择 nftables 防火墙时，`iptables-mod-ipopt` 无法使用。防火墙模板应覆盖此配置，但当前没有。
- **修复建议**: 在 `firewall-nftables.config` 中添加 `# CONFIG_PACKAGE_iptables-mod-ipopt is not set`，并在 base-firmware.config 中将其标注为由防火墙模板控制。

### [中等] UPnP 包依赖声明不完整

**问题 5-2 [中等]**: UPnP 的防火墙适配包声明分散
- **配置项**: `firewall-iptables.config → miniupnpd-iptables` / `firewall-nftables.config → miniupnpd-nftables`
- **描述**: 防火墙模板正确区分了 iptables/nftables 版本的 miniupnpd，但 `full-firmware.config` 也声明了 `luci-app-upnp=y`。如果 full-firmware.config 在防火墙模板之后叠加，`luci-app-upnp` 会被启用，但对应的 miniupnpd 变体可能已被防火墙模板的 `is set`/`is not set` 覆盖。
- **修复建议**: 确保模板叠加顺序正确：base → firewall → full。或者将 `luci-app-upnp` 也移入防火墙模板。

### [建议] 防火墙模板缺少 NAT 相关配置

**问题 5-3 [建议]**: 缺少 NAT 模块配置
- **配置项**: `firewall-*.config`
- **描述**: 两个防火墙模板都没有显式配置 NAT 相关模块。对于 iptables，`kmod-ipt-nat` 通常由 `firewall` 包自动依赖；对于 nftables，`kmod-nft-nat` 由 `firewall4` 自动依赖。但如果有特殊 NAT 需求（如 NAT66、fullcone NAT），需要显式声明。
- **修复建议**: 评估是否需要 `kmod-ipt-nat` / `kmod-nft-nat` 显式声明，以及是否需要 fullcone NAT 补丁包。

---

## 6. 设备配置完整性分析

### [中等] ipq40xx 和 ipq806x 缺少芯片组级别的设备列表

**问题 6-1 [中等]**: ipq40xx 和 ipq806x 使用 `generic` 作为 chip_group
- **配置项**: `ipq40xx/generic/_devices.yml` / `ipq806x/generic/_devices.yml`
- **描述**: ipq40xx 和 ipq806x 的设备列表都放在 `generic` chip_group 下，而 qualcommax 的子目标（ipq807x/ipq60xx/ipq50xx）有独立的 chip_group 目录。这种不一致可能导致：
  - 无法针对不同芯片组（如 ipq4018 vs ipq4019）做差异化配置
  - 生成脚本需要特殊处理两种目录结构
- **修复建议**: 统一目录结构。如果 ipq40xx 设备确实都使用同一套配置，保持 `generic` 可以接受，但在 schema 中明确说明。

### [中等] 设备列表可能不完整

**问题 6-2 [中等]**: 部分常见设备缺失
- **配置项**: 各 `_devices.yml`
- **描述**: 与 OpenWrt 官方支持列表对比，以下常见设备可能缺失：
  - **ipq50xx**: `xiaomi_ax3000`（小米 AX3000T 等常见型号）
  - **ipq807x**: 缺少部分中国市场常见设备（如京东云 BE6500）
  - **ipq60xx**: 缺少部分 GL.iNet 新型号
- **修复建议**: 定期与 OpenWrt 官方 `target/linux/qualcommax/image/` 目录对比，更新设备列表。

### [建议] 设备元数据不足

**问题 6-3 [建议]**: 设备配置缺少关键元数据
- **配置项**: `_devices.yml → devices`
- **描述**: 当前设备配置只包含 `id` 和 `name`，缺少以下有用信息：
  - `flash_size` — Flash 大小（影响 rootfs 分区方案）
  - `ram_size` — 内存大小（影响可安装包数量）
  - `wifi_bands` — WiFi 频段（2.4G/5G/6G）
  - `has_ethernet_switch` — 是否有交换芯片
  - `notes` — 特殊注意事项
- **修复建议**: 扩展 `_devices.yml` schema，增加可选元数据字段。

---

## 7. 废弃配置项分析

### [严重] `CONFIG_PACKAGE_opkg` 在 OpenWrt 24.10+ 已废弃

**问题 7-1 [严重]**: opkg 包管理器已废弃
- **配置项**: `base-firmware.config → CONFIG_PACKAGE_opkg=y`
- **描述**: OpenWrt 24.10+ 已将默认包管理器从 `opkg` 迁移到 `apk`（apk-tools）。`CONFIG_PACKAGE_opkg` 在新版本中可能不存在或产生警告。如果 `kernel_patchver: "6.12"` 对应 OpenWrt 24.10+，此配置项已过时。
- **修复建议**: 确认目标 OpenWrt 版本。如果是 24.10+，改用 `CONFIG_PACKAGE_apk-mbedtls=y` 或 `CONFIG_PACKAGE_apk-openssl=y`。如果仍支持 23.05，保留 opkg 但加版本条件注释。

### [中等] `CONFIG_PACKAGE_luci-app-sshd` 可能不存在

**问题 7-2 [中等]**: luci-app-sshd 包名可能不正确
- **配置项**: `full-firmware.config → CONFIG_PACKAGE_luci-app-sshd=y`
- **描述**: 在标准 OpenWrt 和常见第三方源中，SSH 管理的 LuCI 包名通常是 `luci-app-sshtunnel`（第三方）或通过 `luci-app-system` 管理。`luci-app-sshd` 不是标准包名，可能来自特定第三方源或已不存在。
- **修复建议**: 确认此包的来源。如果来自第三方源，在注释中标注来源。如果不存在，移除此行（SSH 通过 dropbear 已默认配置）。

### [中等] `CONFIG_PACKAGE_luci-app-cron` 可能不存在

**问题 7-3 [中等]**: luci-app-cron 包名可能不正确
- **配置项**: `full-firmware.config → CONFIG_PACKAGE_luci-app-cron=y`
- **描述**: OpenWrt 标准 LuCI 中没有 `luci-app-cron` 包。定时任务通常通过 `luci-app-system` 或 `luci-app-commands` 管理。此包名可能来自第三方源。
- **修复建议**: 确认此包来源。如来自第三方源，标注依赖关系。如不存在，移除。

### [中等] `CONFIG_PACKAGE_luci-app-syslog` 可能不存在

**问题 7-4 [中等]**: luci-app-syslog 包名可能不正确
- **配置项**: `full-firmware.config → CONFIG_PACKAGE_luci-app-syslog=y`
- **描述**: 标准 OpenWrt 中系统日志管理通过 `logd` 或 `syslog-ng` 实现，LuCI 界面通常集成在 `luci-app-system` 中。`luci-app-syslog` 不是标准包名。
- **修复建议**: 确认包来源。如果需要 syslog-ng 的 LuCI 界面，使用 `luci-app-syslog-ng`（如存在）或移除此行。

### [建议] `CONFIG_PACKAGE_speedtest-cli` 包名变更

**问题 7-5 [建议]**: speedtest-cli 包名可能已变更
- **配置项**: `full-firmware.config → CONFIG_PACKAGE_speedtest-cli=y`
- **描述**: `speedtest-cli` 是 Python 版本的速度测试工具，包名可能因源不同而异（有些源使用 `python3-speedtest-cli`）。
- **修复建议**: 确认包在使用的 feed 中是否存在。

---

## 8. 隐式依赖分析

### [严重] `CONFIG_PACKAGE_automount` 依赖未声明

**问题 8-1 [严重]**: automount 缺少依赖声明
- **配置项**: `base-firmware.config → CONFIG_PACKAGE_automount=y`
- **描述**: `automount` 包依赖 `block-mount`、`fstools` 以及文件系统 kmod。虽然 `block-mount` 已在同一文件中声明，但 `automount` 通常还需要 `kmod-fs-*` 系列内核模块。如果用户移除了某些文件系统支持但保留了 automount，可能产生运行时错误。
- **修复建议**: 在注释中标注 `automount` 的完整依赖链，或在 schema 中定义包依赖关系。

### [中等] `CONFIG_PACKAGE_luci-app-sqm` 依赖 `sqm-scripts`

**问题 8-2 [中等]**: SQM 依赖未显式声明
- **配置项**: `base-firmware.config → CONFIG_PACKAGE_luci-app-sqm=y`
- **描述**: `luci-app-sqm` 依赖 `sqm-scripts`，后者又依赖 `tc`（来自 `ip-full` 或 `tc` 包）和 `kmod-sched-*` 内核模块。`ip-full` 已声明，但 `sqm-scripts` 本身未显式声明。
- **修复建议**: 添加 `CONFIG_PACKAGE_sqm-scripts=y` 或在注释中说明依赖关系。

### [中等] `CONFIG_PACKAGE_f2fsck` 依赖 `f2fs-tools`

**问题 8-3 [中等]**: f2fsck 包名可能不正确
- **配置项**: `base-firmware.config → CONFIG_PACKAGE_f2fsck=y`
- **描述**: 在 OpenWrt 中，f2fs 文件系统工具通常打包在 `f2fs-tools` 中，`f2fsck` 可能不是独立包名。需确认实际包名。
- **修复建议**: 确认 `f2fsck` 是否为独立包，或是否应改为 `CONFIG_PACKAGE_f2fs-tools=y`（此文件中已有）。

### [中等] `CONFIG_PACKAGE_cpufreq` 包名可能不正确

**问题 8-4 [中等]**: cpufreq 包名可能不正确
- **配置项**: `base-firmware.config → CONFIG_PACKAGE_cpufreq=y`
- **描述**: OpenWrt 中 CPU 频率调节通常通过 `kmod-cpufreq-*` 系列内核模块实现，而非 `cpufreq` 包。LuCI 界面通过 `luci-app-cpufreq`（已在 plugins/system 中定义）提供。
- **修复建议**: 确认 `cpufreq` 是否为有效的包名。如不是，改为 `CONFIG_PACKAGE_kmod-cpufreq-ondemand=y` 或移除（由 `luci-app-cpufreq` 自动处理依赖）。

### [建议] `CONFIG_PACKAGE_luci-app-diskman` 依赖未声明

**问题 8-5 [建议]**: diskman 依赖未声明
- **配置项**: `base-firmware.config → CONFIG_PACKAGE_luci-app-diskman=y`
- **描述**: `luci-app-diskman` 通常依赖 `parted`、`e2fsprogs` 等磁盘工具。`e2fsprogs` 已声明，但 `parted` 未声明。
- **修复建议**: 添加 `CONFIG_PACKAGE_parted=y` 或确认 `luci-app-diskman` 是否自动拉取依赖。

---

## 9. 汇总表

| # | 严重级别 | 配置文件 | 问题摘要 |
|---|---------|---------|---------|
| 2-1 | 🔴 严重 | base-firmware.config | `iptables-mod-ipopt` 在 nftables 模式下冲突 |
| 3-1 | 🔴 严重 | qualcommax/_platform.yml | `ath11k-firmware-ipq807x` 对 ipq50xx 不适用 |
| 5-1 | 🔴 严重 | firewall-nftables.config | 缺少 iptables-mod-ipopt 的 nftables 等价/禁用声明 |
| 7-1 | 🔴 严重 | base-firmware.config | `opkg` 在 OpenWrt 24.10+ 已废弃 |
| 8-1 | 🔴 严重 | base-firmware.config | `automount` 依赖链未完整声明 |
| 2-2 | 🟡 中等 | base-firmware.config | 注释标注与实际内容不一致 |
| 2-3 | 🟡 中等 | full-firmware.config | 与 base-firmware.config 存在重复包声明 |
| 3-2 | 🟡 中等 | ipq40xx/_platform.yml | 默认包含双 WiFi 固件，增加体积 |
| 3-3 | 🟡 中等 | ipq806x/_platform.yml | nss:false 但 source_branch 仍为 main-nss |
| 5-2 | 🟡 中等 | firewall-*.config | UPnP 包依赖声明分散 |
| 6-1 | 🟡 中等 | ipq40xx/ipq806x | chip_group 使用 generic，结构不统一 |
| 6-2 | 🟡 中等 | 各 _devices.yml | 部分常见设备缺失 |
| 7-2 | 🟡 中等 | full-firmware.config | `luci-app-sshd` 包名可能不正确 |
| 7-3 | 🟡 中等 | full-firmware.config | `luci-app-cron` 包名可能不正确 |
| 7-4 | 🟡 中等 | full-firmware.config | `luci-app-syslog` 包名可能不正确 |
| 8-2 | 🟡 中等 | base-firmware.config | `luci-app-sqm` 依赖未显式声明 |
| 8-3 | 🟡 中等 | base-firmware.config | `f2fsck` 包名可能不正确 |
| 8-4 | 🟡 中等 | base-firmware.config | `cpufreq` 包名可能不正确 |
| 1-1 | 🔵 建议 | feeds.yml | kiddin9 仓库名可能已过时 |
| 1-2 | 🔵 建议 | feeds.yml | 官方源 main 分支稳定性风险 |
| 1-3 | 🔵 建议 | feeds.yml | 缺少 feeds 优先级配置 |
| 2-4 | 🔵 建议 | base-firmware.config | wpad-openssl 与 hostapd-common 冗余 |
| 3-4 | 🔵 建议 | ipq806x/_platform.yml | 缺少 nss 包列表（空列表也行） |
| 4-1 | 🔵 建议 | nss.config | 与 qualcommax nss 包列表重复维护 |
| 4-2 | 🔵 建议 | nss.config | 缺少部分常用 NSS 可选模块 |
| 5-3 | 🔵 建议 | firewall-*.config | 缺少 NAT 模块显式配置 |
| 6-3 | 🔵 建议 | _devices.yml | 设备元数据不足 |
| 7-5 | 🔵 建议 | full-firmware.config | `speedtest-cli` 包名可能变更 |
| 8-5 | 🔵 建议 | base-firmware.config | `diskman` 依赖未声明 |

### 统计

- 🔴 严重: **5** 项
- 🟡 中等: **12** 项
- 🔵 建议: **10** 项
- **总计: 27** 项

---

## 附录: 修复优先级建议

### 立即修复（构建会失败）

1. **问题 2-1 + 5-1**: 将 `iptables-mod-ipopt` 从 base-firmware.config 移入防火墙模板，或在 nftables 模板中显式禁用
2. **问题 7-1**: 确认目标 OpenWrt 版本，替换 `opkg` 为 `apk`（如适用）
3. **问题 3-1**: 为 qualcommax 子目标定义各自的 WiFi 固件包

### 短期修复（运行时可能出错）

4. **问题 7-2 ~ 7-4**: 验证 full-firmware.config 中的包名是否在目标 feed 中存在
5. **问题 8-3 ~ 8-4**: 验证 `f2fsck` 和 `cpufreq` 的正确包名
6. **问题 3-3**: 统一 ipq806x 的 source_branch 配置

### 长期优化（架构改进）

7. 从 `_platform.yml` 自动生成 `nss.config`，消除重复维护
8. 扩展设备元数据 schema
9. 建立包依赖声明机制（在 schema 中）
10. 统一目录结构（ipq40xx/ipq806x 的 chip_group 组织方式）
