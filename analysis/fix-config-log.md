# OpenWRT-CI 配置系统修复日志

> 修复时间: 2026-05-06 13:07 GMT+8
> 基于报告: config-bugs.md, integration-bugs.md

---

## 修复清单

### ✅ Fix 1: subtarget 跨平台校验
**文件**: `scripts/generate-config.sh`
**问题**: subtarget 默认值 `ipq807x` 仅适用于 qualcommax，传给 ipq40xx/ipq806x 会导致构建失败
**修复**: 在解析 subtarget 前添加跨平台校验逻辑。当 target 不是 qualcommax 且 subtarget 为 ipq807x/ipq60xx/ipq50xx 时，清空 subtarget 让后续逻辑回退到平台默认值

### ✅ Fix 2: Actions 输入参数安全传递
**文件**: `.github/actions/generate-config/action.yml`
**问题**: `${{ inputs.xxx }}` 直接嵌入 shell 命令，含空格/特殊字符的值会被 shell 词拆分
**修复**: 所有输入通过 `env:` 块传递为环境变量，run 脚本中用 `"$ENV_VAR"` 引用（带双引号），防止词拆分和注入

### ✅ Fix 3: WiFi 密码长度校验
**文件**: `scripts/apply-system-config.sh`
**状态**: 已存在 — 脚本第 68 行已有 `if [ -n "$WIFI_PW" ] && [ ${#WIFI_PW} -lt 8 ]` 检查
**说明**: 无需额外修改，校验逻辑完整

### ✅ Fix 4: firewall-compat.yml 创建
**文件**: `config/plugins/firewall-compat.yml` (新建)
**问题**: 该文件不存在，导致插件防火墙兼容性过滤被静默跳过
**修复**: 创建文件，声明 `iptables_only` 和 `nftables_only` 插件列表。同时更新 `generate-config.sh` 增加 nftables_only 过滤逻辑（原来只过滤 iptables_only）

### ✅ Fix 5: validate-config.sh 多设备验证
**文件**: `scripts/validate-config.sh` + `.github/actions/generate-config/action.yml`
**问题**: 验证脚本只检查第一个设备，第 2-N 个设备的错误不会被发现
**修复**:
- `validate-config.sh`: 重写设备匹配逻辑，支持空格分隔的多设备列表，循环验证每个设备
- `action.yml`: 将完整 `profile` 列表传给验证脚本（不再只取第一个设备）
- 设备提取正则从贪婪 `.*` 改为非贪婪 `[^=]*`

### ✅ Fix 6: setup-source.sh fallback 补充 kiddin4
**文件**: `scripts/setup-source.sh`
**问题**: 当 python3/PyYAML 不可用时，fallback 硬编码只有 kenzo 和 small 两个源，缺少 kiddin4
**修复**: fallback 列表增加 `src-git kiddin4 https://github.com/kiddin9/op-packages main`

### ✅ Fix 7: concurrency group 修复
**文件**: `.github/workflows/build-openwrt.yml`
**问题**: subtarget 为空时 concurrency group 生成 `build-ipq40xx-`（尾部空段）
**修复**: 添加 `|| 'default'` fallback → `build-${{ inputs.target }}-${{ inputs.subtarget || 'default' }}`

### ✅ Fix 8: 敏感输入 add-mask 处理
**文件**: `.github/actions/generate-config/action.yml`
**问题**: 密码和 SSID 通过 `${{ }}` 直接嵌入可能在 Actions 日志中泄露
**修复**: 所有敏感参数（root_password, wifi_password, wifi_ssid）通过 `::add-mask::` 注册遮蔽，然后通过环境变量安全引用

---

## 验证结果

| 检查项 | 状态 |
|--------|------|
| action.yml YAML 语法 | ✅ valid |
| build-openwrt.yml YAML 语法 | ✅ valid |
| firewall-compat.yml YAML 语法 | ✅ valid |
| generate-config.sh bash 语法 | ✅ valid |
| validate-config.sh bash 语法 | ✅ valid |
| setup-source.sh bash 语法 | ✅ valid |
| apply-system-config.sh bash 语法 | ✅ valid |

## 影响分析

- **向后兼容**: 所有修改保持现有接口不变，仅增加内部校验
- **新增文件**: `config/plugins/firewall-compat.yml`（插件过滤规则）
- **行为变化**: 非 qualcommax 平台传入 qualcommax 专属 subtarget 时会自动修正而非报错
- **安全提升**: 所有用户输入通过环境变量+引号传递，敏感值通过 add-mask 遮蔽
