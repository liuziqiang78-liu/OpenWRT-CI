# OpenWRT-CI 配置系统 Bug 报告

> 生成时间: 2026-05-06 13:01 GMT+8
> 检查范围: workflow、composite action、feeds、schema、模板、平台配置

---

## 🔴 严重 (Critical)

### BUG-01: subtarget 跨平台选择未校验，可生成无效 .config

- **文件**: `.github/workflows/build-openwrt.yml` (行 22-29)
- **问题**: `subtarget` 输入默认值硬编码为 `ipq807x`，但该值仅适用于 `qualcommax` 平台。当用户选择 `target=ipq40xx` 或 `ipq806x` 时，若未手动修改 subtarget，workflow 会将 `ipq807x` 传给 generate-config.sh，后者在平台文件中找不到该 subtarget 导致构建失败。
- **严重程度**: 🔴 Critical — 用户正常操作即可触发构建失败
- **修复方案**:
  ```yaml
  # 方案 A: 在 Generate Config 步骤前添加 subtarget 自动修正
  - name: 🔧 Fix Subtarget
    if: inputs.target != 'qualcommax'
    run: echo "subtarget=generic" >> $GITHUB_ENV

  # 方案 B: 在 action.yml 中 fallback 到平台默认 subtarget
  # (generate-config.sh 已有此逻辑，但被 workflow 的默认值覆盖)
  # 修改 workflow 中 subtarget 传参:
  subtarget: ${{ inputs.target == 'qualcommax' && inputs.subtarget || '' }}
  ```

### BUG-02: NSS 包重复注入 (nss.config 模板 + 平台配置双写)

- **文件**: `scripts/generate-config.sh` (行 167-190), `config/templates/nss.config`, `config/platforms/qualcomm/qualcommax/_platform.yml`
- **问题**: 当 `nss: true` 时，脚本执行两个独立步骤：
  1. **Step 4**: 追加 `nss.config` 模板（13 个 NSS 包）
  2. **Step 5**: 读取 `packages.${SUBTARGET}` (如 `packages.ipq807x`)，注入子目标特定包
  
  但 `nss.config` 的 13 个包与 `_platform.yml` 中 `packages.nss` 的 13 个包**完全一致**。`packages.nss` 部分虽然存在于平台文件中，但脚本从未读取它（只读 `packages.default` 和 `packages.${SUBTARGET}`），形成**死代码**。
  
  当前不会导致构建错误（因为重复的 `CONFIG_PACKAGE_xxx=y` 在 .config 中无害），但会造成维护混乱：有人可能修改 `packages.nss` 以为生效，实际无效。
- **严重程度**: 🔴 Critical — 维护陷阱，配置变更可能被忽略
- **修复方案**:
  ```
  # 二选一：
  # A. 删除 nss.config 模板，改为在脚本中读取 packages.nss
  # B. 删除 _platform.yml 中的 packages.nss 部分，保留 nss.config 作为唯一来源
  # 推荐方案 B，因为 nss.config 是跨平台共享的
  ```

### BUG-03: ipq40xx 的 packages.nss 严重不完整

- **文件**: `config/platforms/qualcomm/ipq40xx/_platform.yml` (行 18-19)
- **问题**: ipq40xx 声明 `nss: true`，但其 `packages.nss` 仅列出 2 个包 (`kmod-qca-nss-drv`, `kmod-qca-nss-ecm`)，而完整的 NSS 驱动栈需要 13 个包。虽然当前因为 `nss.config` 模板会被应用（BUG-02 的"副作用"），实际构建不会缺包，但这是**脆弱的巧合**而非设计。
  
  如果未来重构为只读 `packages.nss`（修复 BUG-02 方案 A），ipq40xx 将严重缺包。
- **严重程度**: 🔴 Critical — 潜在的平台功能缺失
- **修复方案**:
  ```yaml
  # ipq40xx/_platform.yml - 补全 nss 包列表
  nss:
    - kmod-qca-nss-drv
    - kmod-qca-nss-ecm
    - kmod-qca-nss-dp
    - kmod-nss-ifb
    # ... 与 nss.config 保持一致
  ```

---

## 🟠 高 (High)

### BUG-04: firewall-compat.yml 不存在，插件兼容性检查被静默跳过

- **文件**: `scripts/generate-config.sh` (行 205-223), `config/plugins/firewall-compat.yml`
- **问题**: 脚本在处理用户插件时会检查 `config/plugins/firewall-compat.yml` 是否存在：
  ```bash
  if [ -f "$COMPAT_FILE" ]; then
    # 提取仅 iptables 的插件列表，进行兼容性过滤
  else
    # 无兼容性配置，直接添加
  fi
  ```
  该文件**不存在**，因此所有插件都会被直接添加，即使选择了 `nftables` 防火墙。如果用户添加了仅兼容 iptables 的插件（如某些旧版 luci-app），构建可能失败或运行时异常。
- **严重程度**: 🟠 High — 安全网缺失
- **修复方案**:
  ```yaml
  # 创建 config/plugins/firewall-compat.yml
  iptables_only:
    - luci-app-ssr-plus  # 示例，根据实际情况填写
    - luci-app-passwall   # 如果有仅 iptables 版本
  
  nftables_only:
    - luci-app-nft-qos
  ```

### BUG-05: feeds.yml 与 setup-source.sh fallback 不一致

- **文件**: `config/feeds.yml` (行 30-34), `scripts/setup-source.sh` (行 68-71)
- **问题**: `feeds.yml` 注册了 3 个第三方源：`kenzo`、`small`、`kiddin4`。但 `setup-source.sh` 的 fallback（当 python3 不可用时）硬编码只有 2 个：
  ```bash
  cat >> feeds.conf.default <<'EOF'
  src-git kenzo https://github.com/kenzok8/openwrt-packages
  src-git small https://github.com/kenzok8/small
  EOF
  ```
  `kiddin4` 源在 fallback 场景下丢失。
- **严重程度**: 🟠 High — 非 PyYAML 环境下源不完整
- **修复方案**:
  ```bash
  # 更新 fallback 部分
  cat >> feeds.conf.default <<'EOF'
  src-git kenzo https://github.com/kenzok8/openwrt-packages master
  src-git small https://github.com/kenzok8/small master
  src-git kiddin4 https://github.com/kiddin9/op-packages main
  EOF
  ```

### BUG-06: validate-config.sh 设备匹配正则过于贪婪

- **文件**: `scripts/validate-config.sh` (行 62)
- **问题**: 设备提取正则：
  ```bash
  ACTUAL_DEVICE=$(grep -oP 'CONFIG_TARGET.*DEVICE_\K[^=]+(?==y)' "$CONFIG_FILE" | head -1)
  ```
  `.*` 是贪婪匹配，会匹配到**最后一个** `DEVICE_`。如果 .config 中有形如 `CONFIG_TARGET_xxx_DEVICE_aaa_DEVICE_bbb=y` 的行（虽然罕见），会错误提取为 `bbb` 而非 `aaa`。
  
  实测验证：输入 `CONFIG_TARGET_qualcommax_ipq807x_DEVICE_dynalink_dl-wrx36_DEVICE_foo=y` 会返回 `foo`。
- **严重程度**: 🟠 High — 误报设备匹配成功
- **修复方案**:
  ```bash
  # 使用非贪婪匹配或锚定
  ACTUAL_DEVICE=$(grep -oP 'CONFIG_TARGET_[^=]*DEVICE_\K[^=]+(?==y)' "$CONFIG_FILE" | head -1)
  ```

---

## 🟡 中 (Medium)

### BUG-07: full-firmware.config 与 base-firmware.config 重复包

- **文件**: `config/templates/full-firmware.config` (行 50, 56)
- **问题**: 以下包在两个模板中重复设置：
  - `CONFIG_PACKAGE_luci-app-attendedsysupgrade=y` — base (行 109) + full (行 56)
  - `CONFIG_PACKAGE_luci-app-sqm=y` — base (行 101) + full (行 50)
  
  叠加时后出现的覆盖前者，虽然值相同不影响结果，但违反 DRY 原则，增加维护成本。
- **严重程度**: 🟡 Medium — 不影响构建，维护隐患
- **修复方案**:
  ```
  # 从 full-firmware.config 中删除重复行，添加注释：
  # CONFIG_PACKAGE_luci-app-attendedsysupgrade=y  ← 已在 base-firmware.config 中
  # CONFIG_PACKAGE_luci-app-sqm=y                 ← 已在 base-firmware.config 中
  ```

### BUG-08: concurrency group 不区分 ipq40xx 和 ipq806x 的 subtarget

- **文件**: `.github/workflows/build-openwrt.yml` (行 73-74)
- **问题**: 
  ```yaml
  concurrency:
    group: build-${{ inputs.target }}-${{ inputs.subtarget }}
  ```
  对于 `ipq40xx` 和 `ipq806x`，它们的 subtarget 都是 `generic`（唯一选项），但 workflow 的 subtarget 默认值是 `ipq807x`。如果用户不修改 subtarget 就选择 ipq40xx，concurrency key 变成 `build-ipq40xx-ipq807x`，与正确的 `build-ipq40xx-generic` 不同，不会取消冲突构建。
  
  同时，如果两个用户同时触发 `qualcommax/ipq807x` 和 `ipq40xx/generic`（假设 subtarget 被修正），它们不会互相取消，这是正确行为。但 `qualcommax/ipq807x` 和 `qualcommax/ipq60xx` 会正确区分。
- **严重程度**: 🟡 Medium — 与 BUG-01 关联，根因相同
- **修复方案**: 修复 BUG-01 后此问题自动解决

### BUG-09: base-firmware.config 硬编码 opkg，与新版 OpenWrt (apk) 不兼容

- **文件**: `config/templates/base-firmware.config` (行 30, 60)
- **问题**:
  ```
  CONFIG_PACKAGE_opkg=y          # 行 30
  CONFIG_PACKAGE_luci-app-opkg=y # 行 60
  ```
  OpenWrt 24.10+ 已切换到 `apk` 包管理器。如果 `source_branch` 使用 `25.12-nss`，这些配置项可能不存在或产生警告。
- **严重程度**: 🟡 Medium — 取决于目标分支版本
- **修复方案**:
  ```
  # 根据分支条件化，或改为通用写法：
  # CONFIG_PACKAGE_opkg=y              # 旧版 (23.x/24.x)
  # CONFIG_PACKAGE_apk=y               # 新版 (25.x+)
  # 让 make defconfig 自动处理依赖
  ```

### BUG-010: nss.config 缺少 CONFIG_TARGET 子目标选择

- **文件**: `config/templates/nss.config` (全部)
- **问题**: `nss.config` 模板仅包含 `CONFIG_PACKAGE_*` 行，没有 `CONFIG_TARGET_*_NSS=y` 或类似的子目标选择配置。在 OpenWrt 的 Kconfig 系统中，NSS 子目标通常需要显式选择才能编译 NSS 相关内核模块。当前依赖 `make defconfig` 自动推导，可能在某些边界情况下失败。
- **严重程度**: 🟡 Medium — 可能导致 NSS 模块未被选中
- **修复方案**:
  ```
  # 在 nss.config 头部添加（根据实际 Kconfig 结构）：
  # CONFIG_TARGET_QUALCOMMAX_NSS=y  # 示例，需验证实际配置项名
  ```

---

## 🔵 低 (Low)

### BUG-011: feeds.yml 的 bash fallback 解析器无法匹配实际 YAML 格式

- **文件**: `scripts/setup-source.sh` (行 47-58)
- **问题**: bash fallback 解析器查找 `- name:` 格式的列表项：
  ```bash
  _n=$(echo "$_line" | grep -oP '^\s+- name:\s*\K\S+' || true)
  ```
  但 `feeds.yml` 使用的是键值对格式 (`kenzo:`, `url:`, `branch:`)，不包含 `- name:` 模式。因此 bash fallback 永远解析不出任何 feed，会静默回退到硬编码的 2 个源。
  
  由于 GitHub Actions runner 通常有 python3 + PyYAML，此问题实际影响有限。
- **严重程度**: 🔵 Low — 仅在无 PyYAML 环境触发
- **修复方案**:
  ```bash
  # 重写 fallback 解析器以匹配实际 YAML 格式
  _cur=""
  while IFS= read -r _line; do
    # 匹配顶级 key: (如 "kenzo:")
    _n=$(echo "$_line" | grep -oP '^\s{2}\K[a-z0-9-]+(?=:)' || true)
    if [ -n "$_n" ]; then _cur="$_n"; continue; fi
    _u=$(echo "$_line" | grep -oP '\burl:\s*\K\S+' || true)
    if [ -n "$_u" ] && [ -n "$_cur" ]; then
      _b=$(echo "$_line" | grep -oP '\bbranch:\s*\K\S+' || true)
      echo "${_cur}|${_u}|${_b:-main}"
      _cur=""
    fi
  done < "$FEEDS_FILE" > "$FEED_LIST"
  ```

### BUG-012: 第三方 feeds 潜在包重叠

- **文件**: `config/feeds.yml` (行 23-34)
- **问题**: `kenzo` 和 `kiddin4` 两个第三方源都包含大量 OpenWrt 插件，存在包名重叠风险（如两个源都提供 `luci-app-passwall`）。OpenWrt 的 feeds 系统按 `feeds.conf.default` 中的顺序选择第一个匹配的包，但：
  1. 两个源的版本可能不同
  2. `small` 源是 `kenzo` 的精简依赖源，两者配合使用是设计意图，但 `kiddin4` 是独立源
- **严重程度**: 🔵 Low — 可能导致依赖版本不一致
- **修复方案**:
  ```
  # 在 setup-source.sh 中，确保 feeds 添加顺序合理：
  # 1. 官方源 (openwrt, luci, routing, telephony)
  # 2. small (依赖库，优先级高)
  # 3. kenzo (主插件源)
  # 4. kiddin4 (补充源，仅提供 kenzo 没有的包)
  ```

### BUG-013: _vendor.yml 的 platforms 列表包含 ipq50xx/ipq60xx，但无独立 _platform.yml

- **文件**: `config/platforms/qualcomm/_vendor.yml` (行 6-10)
- **问题**: `_vendor.yml` 声明了 5 个平台：
  ```yaml
  platforms:
    - ipq40xx
    - ipq50xx
    - ipq60xx
    - ipq806x
    - ipq807x
  ```
  但 `ipq50xx` 和 `ipq60xx` 没有独立的 `_platform.yml` 文件——它们是 `qualcommax/_platform.yml` 中的 subtarget，而非独立平台。这会造成文档误导。
- **严重程度**: 🔵 Low — 仅影响文档准确性
- **修复方案**:
  ```yaml
  # 修正 _vendor.yml
  platforms:
    - qualcommax   # 包含 ipq807x/ipq60xx/ipq50xx 子目标
    - ipq40xx
    - ipq806x
  ```

---

## 📊 汇总

| 严重程度 | 数量 | 编号 |
|---------|------|------|
| 🔴 Critical | 3 | BUG-01, BUG-02, BUG-03 |
| 🟠 High | 3 | BUG-04, BUG-05, BUG-06 |
| 🟡 Medium | 4 | BUG-07, BUG-08, BUG-09, BUG-010 |
| 🔵 Low | 3 | BUG-011, BUG-012, BUG-013 |
| **总计** | **13** | |

### 优先修复建议

1. **BUG-01** (subtarget 跨平台) — 最容易触发，用户操作即可复现
2. **BUG-02 + BUG-03** (NSS 包双写 + ipq40xx 缺包) — 一起修复，统一 NSS 包来源
3. **BUG-04** (firewall-compat.yml 缺失) — 创建文件即可，成本低
4. **BUG-05** (feeds fallback) — 更新 fallback 硬编码部分

### 安全性评估

- ✅ `root_password` 和 `wifi_password` 使用了 `::add-mask::` 遮蔽
- ✅ 密码通过 `openssl passwd -6` 哈希后写入 shadow 文件
- ✅ WiFi 配置使用 `printf` + `sed` 转义单引号，防注入
- ⚠️ `custom_config` 的 base64 解码后直接追加到 .config，理论上可注入 shell 命令（但 .config 是 Kconfig 格式，非 shell 脚本，实际风险极低）
- ⚠️ 未发现 token/密钥明文暴露问题
