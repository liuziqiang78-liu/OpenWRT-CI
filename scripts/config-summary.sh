#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  从 .config 提取编译配置 → GITHUB_STEP_SUMMARY
#  用法: config-summary.sh <config_file> [source_branch]
# ═══════════════════════════════════════════
set -euo pipefail

CONFIG="${1:-.config}"
BRANCH="${2:-unknown}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

if [ ! -f "$CONFIG" ]; then
  echo "错误: .config 不存在: ${CONFIG}"
  exit 1
fi

# ── 从 .config 提取实际值 ──
ACTUAL_TARGET=$(grep -oP 'CONFIG_TARGET_\K[a-z0-9]+(?==y)' "$CONFIG" | head -1)
ACTUAL_SUBTARGET=$(grep -oP "CONFIG_TARGET_${ACTUAL_TARGET}_\\K[a-z0-9]+(?==y)" "$CONFIG" | head -1)
ACTUAL_DEVICE=$(grep -oP 'CONFIG_TARGET.*DEVICE_\K[^=]+(?==y)' "$CONFIG" | head -1)
FW_TYPE=$(grep -q 'CONFIG_PACKAGE_firewall4=y' "$CONFIG" && echo 'nftables' || echo 'iptables')
PLUGIN_COUNT=$(grep -c '=y' "$CONFIG" || echo 0)
CCACHE=$(grep -q 'CONFIG_CCACHE=y' "$CONFIG" && echo '开' || echo '关')
SQUASHFS=$(grep -q 'CONFIG_TARGET_ROOTFS_SQUASHFS=y' "$CONFIG" && echo '✅' || echo '❌')
EXT4=$(grep -q 'CONFIG_TARGET_ROOTFS_EXT4FS=y' "$CONFIG" && echo '✅' || echo '❌')
MULTI=$(grep -q 'CONFIG_TARGET_MULTI_PROFILE=y' "$CONFIG" && echo '✅' || echo '❌')

# ── 写入摘要 ──
cat >> "$SUMMARY" <<EOF
### 📋 编译配置
| 项目 | 值 |
|:---|:---|
| 源码分支 | \`${BRANCH}\` |
| Target | \`${ACTUAL_TARGET}\` |
| Subtarget | \`${ACTUAL_SUBTARGET}\` |
| 设备 | \`${ACTUAL_DEVICE:-'(全部)'}\` |
| 防火墙 | \`${FW_TYPE}\` |
| Multi Profile | ${MULTI} |
| 插件数 | \`${PLUGIN_COUNT}\` |
| ccache | \`${CCACHE}\` |
| Rootfs | squashfs=${SQUASHFS} ext4=${EXT4} |
EOF

# ── 终端输出 ──
echo "═══════════════════════════════════════"
echo "  配置摘要"
echo "  Target:     ${ACTUAL_TARGET}/${ACTUAL_SUBTARGET}"
echo "  设备:       ${ACTUAL_DEVICE:-'(全部)'}"
echo "  防火墙:     ${FW_TYPE}"
echo "  Multi Prof: ${MULTI}"
echo "  配置项:     ${PLUGIN_COUNT}"
echo "═══════════════════════════════════════"
