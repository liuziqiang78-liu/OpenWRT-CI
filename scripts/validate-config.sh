#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
#  OpenWrt .config 验证器
#  检查 .config 是否与预期一致
#
#  用法: validate-config.sh [选项]
#    --config FILE          .config 文件 (默认: .config)
#    --expected-device DEV  期望设备
#    --expected-fw TYPE     期望防火墙类型
#    --strict               严格模式 (任何警告都失败)
# ═══════════════════════════════════════════════════════
set -euo pipefail

CONFIG_FILE=".config"
EXPECTED_DEVICE=""
EXPECTED_FW=""
STRICT=false
ERRORS=0
WARNINGS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)           CONFIG_FILE="$2"; shift 2 ;;
    --expected-device)  EXPECTED_DEVICE="$2"; shift 2 ;;
    --expected-fw)      EXPECTED_FW="$2"; shift 2 ;;
    --strict)           STRICT=true; shift ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

if [ ! -f "$CONFIG_FILE" ]; then
  echo "错误: .config 不存在: ${CONFIG_FILE}"
  exit 1
fi

error() { echo "::error::$1"; ((ERRORS++)); }
warn()  echo "::warning::$1"; ((WARNINGS++)); }

echo "═══════════════════════════════════════"
echo "  .config 验证报告"
echo "═══════════════════════════════════════"

# ── 检查 1: MULTI_PROFILE ──
if grep -q 'CONFIG_TARGET_MULTI_PROFILE=y' "$CONFIG_FILE"; then
  echo "✅ MULTI_PROFILE: 已启用"
else
  error "MULTI_PROFILE 未启用，设备选择可能回退"
fi

# ── 检查 2: 设备匹配 ──
ACTUAL_DEVICE=$(grep -oP 'CONFIG_TARGET.*DEVICE_\K[^=]+(?==y)' "$CONFIG_FILE" | head -1)
if [ -n "$EXPECTED_DEVICE" ]; then
  if [ "$ACTUAL_DEVICE" = "$EXPECTED_DEVICE" ]; then
    echo "✅ 设备匹配: ${ACTUAL_DEVICE}"
  else
    error "设备不匹配！期望: ${EXPECTED_DEVICE}，实际: ${ACTUAL_DEVICE:-'(未找到)'}"
  fi
else
  echo "ℹ️ 设备: ${ACTUAL_DEVICE:-'(未指定)'}"
fi

# ── 检查 3: 防火墙冲突 ──
FW3=$(grep -c 'CONFIG_PACKAGE_firewall=y' "$CONFIG_FILE" || true)
FW4=$(grep -c 'CONFIG_PACKAGE_firewall4=y' "$CONFIG_FILE" || true)
if [ "$FW3" -gt 0 ] && [ "$FW4" -gt 0 ]; then
  error "防火墙冲突: firewall3 + firewall4 同时启用"
elif [ "$FW3" -gt 0 ]; then
  ACTUAL_FW="iptables"
elif [ "$FW4" -gt 0 ]; then
  ACTUAL_FW="nftables"
else
  ACTUAL_FW="unknown"
  warn "未检测到防火墙配置"
fi

if [ -n "$EXPECTED_FW" ] && [ "$ACTUAL_FW" != "$EXPECTED_FW" ]; then
  error "防火墙不匹配！期望: ${EXPECTED_FW}，实际: ${ACTUAL_FW}"
else
  echo "✅ 防火墙: ${ACTUAL_FW}"
fi

# ── 检查 4: rootfs 类型 ──
SQUASHFS=$(grep -c 'CONFIG_TARGET_ROOTFS_SQUASHFS=y' "$CONFIG_FILE" || true)
EXT4=$(grep -c 'CONFIG_TARGET_ROOTFS_EXT4FS=y' "$CONFIG_FILE" || true)
echo "ℹ️ Rootfs: squashfs=${SQUASHFS} ext4=${EXT4}"

# ── 检查 5: 缺失包 ──
MISSING=$(grep -c 'is not set' "$CONFIG_FILE" || true)
if [ "$MISSING" -gt 10 ]; then
  warn "大量配置项被禁用 (${MISSING} 项)，可能有依赖问题"
fi

# ── 检查 6: 统计 ──
TOTAL_Y=$(grep -c '=y' "$CONFIG_FILE" || true)
TOTAL_M=$(grep -c '=m' "$CONFIG_FILE" || true)
echo "ℹ️ 统计: ${TOTAL_Y} 个 built-in，${TOTAL_M} 个 module"

# ── 结果 ──
echo ""
echo "═══════════════════════════════════════"
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ 验证失败: ${ERRORS} 个错误，${WARNINGS} 个警告"
  exit 1
elif [ "$STRICT" = true ] && [ "$WARNINGS" -gt 0 ]; then
  echo "⚠️ 严格模式: ${WARNINGS} 个警告"
  exit 1
else
  echo "✅ 验证通过 (${WARNINGS} 个警告)"
  exit 0
fi
