# OpenWRT-CI GitHub Actions 工作流分析报告

> 分析日期: 2026-05-06
> 分析文件:
> - `.github/workflows/build-openwrt.yml`
> - `.github/actions/generate-config/action.yml`

---

## 一、工作流结构问题

### 1. [中等] 步骤错误处理 — `Setup Source` 缺少 `if: always()` 或错误传播
- **位置**: `build-openwrt.yml` L2 `Setup Source` 步骤
- **问题**: 如果 `setup-source.sh` 失败，工作流会直接停止，但后续的 `Config Summary` 步骤设置了 `if: always()`，意味着即使源码拉取失败也会尝试运行配置摘要脚本，可能产生误导性输出。
- **修复方案**: 给 `Setup Source` 步骤加一个 `id`，后续步骤改为 `if: steps.setup-source.outcome == 'success'`，或者去掉 Config Summary 的 `always()` 使其正常失败传播。

### 2. [中等] Build 步骤时间戳写入时机
- **位置**: `build-openwrt.yml` L5 `Build` 步骤
- **问题**: `date +%s > openwrt/.build_start_time` 写在编译命令之前，但没有单独的步骤，如果 bash 脚本一开始就失败，时间戳已经写入但编译未开始，后续 `build-summary.sh` 可能计算出错误的编译时长。
- **修复方案**: 将时间戳写入拆为独立步骤，或在 `build.sh` 内部处理起始时间记录。

### 3. [建议] `Config Summary` 步骤位置过早
- **位置**: `build-openwrt.yml` L4
- **问题**: 配置摘要在编译前运行，此时 `.config` 可能还未经过完整的 `defconfig` 展开（取决于 `generate-config.sh` 是否已调用 `make defconfig`）。如果摘要脚本依赖最终展开后的配置，可能不准确。
- **修复方案**: 确认 `generate-config.sh` 已调用 `make defconfig`。如果已调用则无问题；否则将摘要移至编译之后或在脚本内补充 defconfig 调用。

### 4. [建议] `Post-Build Check` 和 `Build Summary` 均使用 `if: always()`
- **位置**: `build-openwrt.yml` L6-L7
- **问题**: 两个步骤都在 `always()` 条件下运行。如果编译失败，`post-build-check.sh` 和 `build-summary.sh` 可能因找不到编译产物而报错或产生误导性输出。
- **修复方案**: 改为 `if: success() || failure()`（排除 `cancelled` 的情况），或在脚本内部检查编译产物是否存在。

---

## 二、超时设置

### 5. [中等] 360 分钟超时偏高，无分级超时
- **位置**: `build-openwrt.yml` `jobs.build.timeout-minutes: 360`
- **问题**: 6 小时的全局超时对于单设备编译来说偏高。如果编译卡死（如网络下载依赖包挂起），会浪费大量 CI 时间。OpenWrt 编译通常在 60-120 分钟内完成（取决于设备和包数量），6 小时意味着可能浪费 4 小时。
- **修复方案**:
  - 将超时降为 180-240 分钟（3-4 小时），已留有充足余量。
  - 在 `build.sh` 内部对关键阶段（下载源码、编译内核、编译 packages）设置阶段超时。
  - 考虑使用 `timeout` 命令包裹 `make` 调用。

---

## 三、缓存策略（ccache）

### 6. [严重] 缺少 ccache 持久化缓存 — 每次编译从零开始
- **位置**: `build-openwrt.yml` 整个工作流，`inputs.enable_ccache`
- **问题**: 虽然 `enable_ccache` 选项存在，但工作流中**完全没有** `actions/cache` 或任何缓存恢复/保存步骤。ccache 只在单次构建内有效（runner 临时目录），每次 workflow_dispatch 运行时 ccache 都是空的，**等于没有缓存**。
- **修复方案**:
  ```yaml
  - name: 🗄️ Restore ccache
    if: inputs.enable_ccache == 'true'
    uses: actions/cache@v4
    with:
      path: ~/.ccache
      key: ccache-${{ inputs.target }}-${{ inputs.subtarget }}-${{ github.run_number }}
      restore-keys: |
        ccache-${{ inputs.target }}-${{ inputs.subtarget }}-

  - name: 💾 Save ccache
    if: inputs.enable_ccache == 'true'
    uses: actions/cache/save@v4
    with:
      path: ~/.ccache
      key: ccache-${{ inputs.target }}-${{ inputs.subtarget }}-${{ github.run_number }}
  ```
  同时需要在 `build.sh` 中确认 ccache 路径和 `CCACHE_DIR` 环境变量设置正确。

### 7. [建议] ccache 配置参数未显式设置
- **位置**: 工作流全局
- **问题**: ccache 的 `max_size`、`compression` 等关键参数未在工作流中设置。GitHub Actions cache 上限为 10GB，但 ccache 默认大小为 5GB，且默认不压缩。
- **修复方案**: 在编译步骤前添加：
  ```yaml
  - name: ⚙️ Configure ccache
    if: inputs.enable_ccache == 'true'
    run: |
      ccache --set-config=max_size=5G
      ccache --set-config=compression=true
      ccache --set-config=compression_level=6
      ccache --set-config=sloppiness=file_macro,locale,time_macros
      ccache -s  # 显示统计
  ```

---

## 四、上传 Artifact 配置

### 8. [中等] Artifact 名称中使用 `subtarget` 可能为空
- **位置**: `build-openwrt.yml` L9 `Upload Firmware` 步骤
- **问题**: `name: openwrt-${{ inputs.target }}-${{ inputs.subtarget }}-run${{ github.run_number }}` 中 `subtarget` 是 `required: false`，如果用户不填，artifact 名称会出现双横线 `openwrt-qualcommax--run123`。
- **修复方案**: 
  ```yaml
  name: openwrt-${{ inputs.target }}${{ inputs.subtarget && format('-{0}', inputs.subtarget) || '' }}-run${{ github.run_number }}
  ```
  或在 workflow_dispatch 中将 `subtarget` 设为 `required: true`（既然它是 choice 类型且有默认值）。

### 9. [建议] `if-no-files-found: warn` 过于宽松
- **位置**: `build-openwrt.yml` L9
- **问题**: 设置为 `warn` 意味着即使没有任何固件文件被找到，上传步骤也不会失败。这会掩盖编译失败导致无输出的情况，用户可能误以为构建成功但没有产物。
- **修复方案**: 改为 `if-no-files-found: error`，确保没有产物时明确报错。

### 10. [建议] Artifact 保留天数可优化
- **位置**: `build-openwrt.yml` `retention-days: 7`
- **问题**: 7 天的保留期对于固件来说可能偏短。如果用户需要回退到之前的固件版本，7 天后就无法下载了。
- **修复方案**: 考虑增加到 14-30 天，或提供选项让用户在 dispatch 时选择保留天数。

### 11. [建议] 未上传编译日志
- **位置**: `build-openwrt.yml` L9
- **问题**: 只上传了固件二进制文件和 manifest，没有上传编译日志。如果编译部分失败（如某些包编译失败但仍有部分产物），调试会很困难。
- **修复方案**: 在 `path` 中增加日志文件：
  ```yaml
  path: |
    openwrt/bin/targets/**/*.bin
    openwrt/bin/targets/**/*.itb
    openwrt/bin/targets/**/*.img
    openwrt/bin/targets/**/*.ubi
    openwrt/bin/targets/**/*.tar
    openwrt/manifest.json
    openwrt/logs/
    openwrt/.config
  ```

---

## 五、环境变量和密钥管理

### 12. [严重] `root_password` 以明文 input 形式传递
- **位置**: `build-openwrt.yml` `inputs.root_password`，`generate-config/action.yml` `inputs.root_password`
- **问题**: Root 密码通过 `workflow_dispatch` 的 `inputs` 传递，在 GitHub Actions 的日志中**可能被打印**（取决于脚本是否 echo 参数）。即使是 `type: string`，GitHub 也不会自动掩码非 secrets 的输入值。
- **修复方案**:
  - 将 `root_password` 改为使用 GitHub Secrets（`secrets.ROOT_PASSWORD`），或
  - 在脚本中确保密码参数不被 echo 到日志，并在 `generate-config/action.yml` 中使用 `::add-mask::` 命令：
    ```bash
    echo "::add-mask::${{ inputs.root_password }}"
    ```

### 13. [中等] `wifi_password` 同样存在明文暴露风险
- **位置**: `build-openwrt.yml` `inputs.wifi_password`
- **问题**: 与 `root_password` 相同的问题。WiFi 密码通过 input 传递，可能在日志中暴露。
- **修复方案**: 同 #12，使用 secrets 或 `::add-mask::`。

### 14. [建议] `custom_config` (base64) 缺少格式校验
- **位置**: `build-openwrt.yml` `inputs.custom_config`
- **问题**: 用户输入的 base64 编码配置没有在工作流层面验证是否是合法的 base64。如果输入错误的 base64 字符串，解码失败会在脚本内部报错，错误信息可能不够清晰。
- **修复方案**: 在 `generate-config` action 中增加 base64 解码验证步骤：
  ```bash
  if ! echo "${{ inputs.custom_config }}" | base64 -d > /dev/null 2>&1; then
    echo "::error::Invalid base64 in custom_config input"
    exit 1
  fi
  ```

---

## 六、遗漏或冗余步骤

### 15. [严重] 缺少编译依赖安装步骤
- **位置**: `build-openwrt.yml` 整个工作流
- **问题**: 工作流**没有**安装 OpenWrt 编译所需的系统依赖（如 `build-essential`, `libncurses-dev`, `gawk`, `git`, `unzip`, `python3`, `rsync`, `file`, `wget` 等）。虽然 `ubuntu-22.04` runner 预装了部分工具，但并非所有 OpenWrt 编译依赖都已预装。
- **修复方案**: 在 `Checkout` 之后、`Setup Source` 之前添加依赖安装步骤：
  ```yaml
  - name: 🛠️ Install Dependencies
    run: |
      sudo apt-get update
      sudo apt-get install -y build-essential clang flex bison g++ gawk \
        gcc-multilib g++-multilib gettext git libelf-dev libncurses-dev \
        libssl-dev python3 python3-distutils rsync unzip zlib1g-dev \
        file wget
  ```
  或者确认 `setup-source.sh` 内部已处理依赖安装。

### 16. [中等] 缺少磁盘空间检查
- **位置**: `build-openwrt.yml`
- **问题**: OpenWrt 编译需要大量磁盘空间（通常 30-50GB）。GitHub Actions runner 有 ~14GB 可用空间，如果没有清理预装软件，可能在编译中途因磁盘空间不足而失败。
- **修复方案**: 在编译前添加磁盘清理和检查步骤：
  ```yaml
  - name: 🧹 Free Disk Space
    run: |
      sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc
      sudo apt-get clean
      df -h
  ```

### 17. [建议] 缺少编译前的 `make defconfig` 确认步骤
- **位置**: `build-openwrt.yml` `Build` 步骤
- **问题**: 工作流假设 `generate-config.sh` 已经完成了 `make defconfig`，但没有显式验证。如果脚本遗漏了这一步，编译可能使用不完整的配置。
- **修复方案**: 在编译前添加一个轻量验证步骤：
  ```yaml
  - name: 🔎 Verify defconfig
    run: |
      cd openwrt
      make defconfig > /dev/null 2>&1
      if [ $? -ne 0 ]; then
        echo "::error::make defconfig failed"
        exit 1
      fi
  ```

### 18. [建议] 缺少编译产物的完整性校验
- **位置**: `build-openwrt.yml` `Upload Firmware` 步骤之前
- **问题**: 没有对编译产物（.bin, .img 等）进行基本的完整性检查（如文件大小 > 0、校验和）。
- **修复方案**: 在 `post-build-check.sh` 中或单独步骤中添加：
  ```bash
  find openwrt/bin/targets -name "*.bin" -size 0 -exec echo "::error::Empty firmware file: {}" \; -exec exit 1 \;
  ```

---

## 七、workflow_dispatch inputs 配置

### 19. [中等] `subtarget` 对非 qualcommax 平台不适用但仍可选
- **位置**: `build-openwrt.yml` `inputs.subtarget`
- **问题**: `subtarget` 描述为 "qualcommax 专用"，但 `target` 可以选择 `ipq40xx` 或 `ipq806x`，此时 `subtarget` 选项（`ipq807x`, `ipq60xx`, `ipq50xx`）完全不适用。用户可能误选导致配置错误。
- **修复方案**:
  - 在 `generate-config.sh` 中忽略非 qualcommax 平台的 subtarget 参数并给出警告。
  - 或在工作流层面通过条件逻辑禁用 subtarget（但 `workflow_dispatch` 不支持动态 inputs）。
  - 最低限度：在 subtarget 的 description 中明确说明 "仅 qualcommax 有效，其他平台请留空"。

### 20. [建议] `enable_ccache` 默认值在 action 与 workflow 间不一致
- **位置**: `build-openwrt.yml` `inputs.enable_ccache.default: 'true'` vs `generate-config/action.yml` `inputs.enable_ccache.default: 'false'`
- **问题**: 工作流默认启用 ccache，但 composite action 默认禁用。虽然工作流会传递值，但如果 action 被其他工作流复用，默认行为不一致可能导致困惑。
- **修复方案**: 统一默认值，建议都设为 `'true'`（因为 ccache 几乎总是有益的）。

### 21. [建议] `lan_ip` 缺少格式校验
- **位置**: `build-openwrt.yml` `inputs.lan_ip`
- **问题**: 用户可以输入任意字符串作为 LAN IP，如 `not-an-ip` 或 `999.999.999.999`，可能导致网络配置错误。
- **修复方案**: 在 `apply-system-config.sh` 中增加 IP 格式正则校验：
  ```bash
  if ! echo "$LAN_IP" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo "::error::Invalid LAN IP format: $LAN_IP"
    exit 1
  fi
  ```

---

## 八、GitHub Actions 版本

### 22. [建议] `actions/checkout@v4` — 版本最新，无问题
- **位置**: `build-openwrt.yml` L1
- **状态**: ✅ `actions/checkout@v4` 是当前最新稳定版，无需更新。

### 23. [建议] `actions/upload-artifact@v4` — 版本最新，无问题
- **位置**: `build-openwrt.yml` L9
- **状态**: ✅ `actions/upload-artifact@v4` 是当前最新稳定版，无需更新。

### 24. [建议] 缺少 `actions/cache` — 需要新增
- **位置**: 整个工作流
- **问题**: 如 #6 所述，缺少缓存步骤。如需添加，应使用 `actions/cache@v4`。
- **修复方案**: 参见 #6 的修复方案。

---

## 九、generate-config/action.yml 专项问题

### 25. [中等] Composite action 中 shell 变量拼接存在注入风险
- **位置**: `generate-config/action.yml` 所有 `run` 块
- **问题**: 使用 `${{ inputs.xxx }}` 直接插入 bash 脚本中，如果输入包含特殊字符（如 `; rm -rf /`），理论上存在命令注入风险。虽然 GitHub Actions 对 `${{ }}` 做了部分转义，但在 `run:` 块中直接拼接仍不安全。
- **修复方案**: 将所有 input 通过环境变量传递而非直接插值：
  ```yaml
  - name: ⚙️ Generate .config
    shell: bash
    env:
      INPUT_TARGET: ${{ inputs.target }}
      INPUT_SUBTARGET: ${{ inputs.subtarget }}
      INPUT_PROFILE: ${{ inputs.profile }}
      INPUT_FIREWALL: ${{ inputs.firewall }}
      INPUT_PLUGINS: ${{ inputs.plugins }}
      INPUT_ENABLE_CCACHE: ${{ inputs.enable_ccache }}
      INPUT_TEMPLATE: ${{ inputs.template }}
      INPUT_CUSTOM_CONFIG: ${{ inputs.custom_config }}
    run: |
      ARGS=(--target "$INPUT_TARGET" --firewall "$INPUT_FIREWALL" --config-dir "${REPO_ROOT}/config")
      [ -n "$INPUT_SUBTARGET" ] && ARGS+=(--subtarget "$INPUT_SUBTARGET")
      # ...
  ```

### 26. [中等] `root_password` 和 `wifi_password` 在 composite action 中同样以 `${{ }}` 拼接
- **位置**: `generate-config/action.yml` `Apply System Config` 步骤
- **问题**: 密码类敏感输入直接插值到 `run:` 块，可能在 debug 日志中泄露。
- **修复方案**: 同 #25，改用环境变量传递，并在脚本开头执行 `::add-mask::`。

### 27. [建议] `validate-config.sh` 仅校验第一个 profile
- **位置**: `generate-config/action.yml` `Validate .config` 步骤
- **问题**: `FIRST_DEVICE=$(echo "${{ inputs.profile }}" | awk '{print $1}')` 只取第一个设备进行验证。如果用户指定了多个设备 profile（空格分隔），后续设备不会被验证。
- **修复方案**: 循环验证所有 profile：
  ```bash
  for DEVICE in ${{ inputs.profile }}; do
    bash "${REPO_ROOT}/scripts/validate-config.sh" \
      --config .config --expected-device "$DEVICE" --expected-fw "${{ inputs.firewall }}"
  done
  ```

---

## 十、其他建议

### 28. [建议] Runner 版本可以升级
- **位置**: `build-openwrt.yml` `runs-on: ubuntu-22.04`
- **问题**: `ubuntu-22.04` 在 2025 年已接近 EOL。GitHub 推荐使用 `ubuntu-24.04` 或 `ubuntu-latest`。
- **修复方案**: 升级为 `ubuntu-24.04`（注意需测试编译兼容性）或 `ubuntu-latest`。

### 29. [建议] 缺少并发控制
- **位置**: `build-openwrt.yml`
- **问题**: 如果多人同时触发 workflow_dispatch，可能同时运行多个编译任务，浪费 runner 资源。
- **修复方案**: 添加 concurrency 配置：
  ```yaml
  concurrency:
    group: build-${{ inputs.target }}-${{ inputs.subtarget }}
    cancel-in-progress: true
  ```

### 30. [建议] 缺少构建状态通知机制
- **位置**: 整个工作流
- **问题**: 编译完成后没有通知机制（如 Slack、Discord、邮件）。用户需要手动检查 GitHub Actions 页面。
- **修复方案**: 添加通知步骤（可选）：
  ```yaml
  - name: 📢 Notify
    if: always()
    run: |
      # 可选: 发送 webhook 通知
      echo "Build ${{ job.status }}: ${{ inputs.target }}/${{ inputs.subtarget }}"
  ```

---

## 问题汇总

| # | 级别 | 类别 | 问题简述 |
|---|------|------|----------|
| 6 | 🔴 严重 | 缓存 | ccache 无持久化缓存，每次从零编译 |
| 12 | 🔴 严重 | 安全 | root_password 明文传递，日志可能泄露 |
| 15 | 🔴 严重 | 结构 | 缺少编译依赖安装步骤 |
| 5 | 🟡 中等 | 超时 | 360 分钟超时过高，无分级超时 |
| 8 | 🟡 中等 | Artifact | subtarget 为空时名称异常 |
| 13 | 🟡 中等 | 安全 | wifi_password 明文泄露风险 |
| 16 | 🟡 中等 | 结构 | 缺少磁盘空间检查 |
| 19 | 🟡 中等 | Inputs | subtarget 对非 qualcommax 平台不适用 |
| 25 | 🟡 中等 | 安全 | composite action 存在注入风险 |
| 26 | 🟡 中等 | 安全 | 密码参数直接插值到 run 块 |
| 1 | 🟡 中等 | 结构 | 错误处理条件不一致 |
| 2 | 🟡 中等 | 结构 | 时间戳写入时机 |
| 28 | 🟢 建议 | 环境 | Runner 版本可升级到 ubuntu-24.04 |
| 29 | 🟢 建议 | 结构 | 缺少并发控制 |
| 30 | 🟢 建议 | 结构 | 缺少构建通知机制 |
| 3 | 🟢 建议 | 结构 | Config Summary 位置过早 |
| 4 | 🟢 建议 | 结构 | always() 条件过宽 |
| 7 | 🟢 建议 | 缓存 | ccache 参数未显式设置 |
| 9 | 🟢 建议 | Artifact | if-no-files-found 应改为 error |
| 10 | 🟢 建议 | Artifact | 保留天数可优化 |
| 11 | 🟢 建议 | Artifact | 未上传编译日志 |
| 14 | 🟢 建议 | Inputs | custom_config 缺少 base64 校验 |
| 17 | 🟢 建议 | 结构 | 缺少 defconfig 验证步骤 |
| 18 | 🟢 建议 | 结构 | 缺少产物完整性校验 |
| 20 | 🟢 建议 | Inputs | enable_ccache 默认值不一致 |
| 21 | 🟢 建议 | Inputs | lan_ip 缺少格式校验 |
| 27 | 🟢 建议 | 验证 | 仅校验第一个 profile |

**统计**: 🔴 严重 3 项 | 🟡 中等 8 项 | 🟢 建议 15 项

---

## 优先修复建议

**立即修复（影响编译成功率和安全性）:**
1. 添加 ccache 持久化缓存（#6）— 可节省 50%+ 编译时间
2. 敏感输入改为 secrets 或添加 `::add-mask::`（#12, #13, #26）
3. 添加依赖安装和磁盘清理步骤（#15, #16）

**短期优化（提升健壮性）:**
4. 降低超时并添加阶段超时（#5）
5. 修复 artifact 命名和 if-no-files-found（#8, #9）
6. 环境变量替代直接插值（#25）

**长期改进（提升体验）:**
7. 添加并发控制（#29）
8. 升级 Runner 版本（#28）
9. 添加通知机制（#30）
