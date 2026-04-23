#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
#  OpenWrt .config 生成器 (通用)
#  从平台配置 + 模板组装最终 .config
#
#  用法: generate-config.sh [选项]
#    --target TARGET        目标平台
#    --subtarget SUBTARGET  子目标 (留空=使用默认)
#    --profile PROFILE      设备型号 (空格分隔)
#    --firewall TYPE        防火墙 (iptables/nftables)
#    --plugins LIST         额外插件 (空格分隔)
#    --custom-config B64    自定义配置 (base64)
#    --enable-ccache        启用 ccache
#    --config-dir DIR       配置目录 (默认: config)
#    --output FILE          输出文件 (默认: .config)
# ═══════════════════════════════════════════════════════
set -euo pipefail

# ── 参数解析 ──
TARGET=""
SUBTARGET=""
PROFILE=""
FIREWALL="iptables"
PLUGINS=""
CUSTOM_CONFIG=""
ENABLE_CCACHE="false"
CONFIG_DIR="config"
OUTPUT=".config"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)       TARGET="$2"; shift 2 ;;
    --subtarget)    SUBTARGET="$2"; shift 2 ;;
    --profile)      PROFILE="$2"; shift 2 ;;
    --firewall)     FIREWALL="$2"; shift 2 ;;
    --plugins)      PLUGINS="$2"; shift 2 ;;
    --custom-config) CUSTOM_CONFIG="$2"; shift 2 ;;
    --enable-ccache) ENABLE_CCACHE="true"; shift ;;
    --config-dir)   CONFIG_DIR="$2"; shift 2 ;;
    --output)       OUTPUT="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

# ── 参数验证 ──
if [ -z "$TARGET" ]; then
  echo "错误: --target 必填"
  exit 1
fi

# 查找平台配置 (支持新旧两种路径)
PLATFORM_FILE=""
for candidate in \
  "${CONFIG_DIR}/platforms/"*"/${TARGET}/_platform.yml" \
  "${CONFIG_DIR}/platforms/${TARGET}.yml"; do
  if [ -f $candidate ]; then
    PLATFORM_FILE="$candidate"
    break
  fi
done

if [ -z "$PLATFORM_FILE" ]; then
  echo "错误: 平台配置不存在: ${TARGET}"
  echo "搜索路径: ${CONFIG_DIR}/platforms/*/${TARGET}/_platform.yml"
  exit 1
fi

echo "📂 平台配置: ${PLATFORM_FILE}"

# ── 工具函数 ──
# 简单的 YAML 值提取 (无需 yq)
yaml_get() {
  local file="$1" key="$2"
  grep -oP "^${key}:\s*\K.*" "$file" 2>/dev/null | head -1 | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
}

yaml_get_list() {
  local file="$1" prefix="$2"
  sed -n "/^${prefix}:/,/^[^ ]/{ s/^[[:space:]]*- //p; }" "$file" 2>/dev/null
}

# ── 解析默认 subtarget ──
if [ -z "$SUBTARGET" ]; then
  SUBTARGET=$(grep -oP '^\s+\K[a-z0-9]+(?=:)' "$PLATFORM_FILE" | head -1)
  echo "ℹ️ 使用默认 subtarget: ${SUBTARGET}"
fi

# ── 验证 subtarget 存在 ──
if ! grep -q "^  ${SUBTARGET}:" "$PLATFORM_FILE"; then
  echo "错误: subtarget '${SUBTARGET}' 不在 ${TARGET} 平台中"
  echo "可用: $(grep -oP '^\s+\K[a-z0-9]+(?=:)' "$PLATFORM_FILE" | tr '\n' ' ')"
  exit 1
fi

# ── 验证防火墙类型 ──
FW_VALID=$(sed -n '/^constraints:/,/^[a-z]/{ /^  firewall:/p; }' "$PLATFORM_FILE" | grep -o "$FIREWALL" || true)
if [ -z "$FW_VALID" ]; then
  echo "错误: ${TARGET} 不支持防火墙: ${FIREWALL}"
  exit 1
fi

echo "═══════════════════════════════════════"
echo "  生成 .config"
echo "  平台: ${TARGET}/${SUBTARGET}"
echo "  设备: ${PROFILE:-'(全部)'}"
echo "  防火墙: ${FIREWALL}"
echo "═══════════════════════════════════════"

# ═══════════════════════════════════════
#  Step 1: Target + Subtarget
# ═══════════════════════════════════════
cat > "$OUTPUT" <<EOF
CONFIG_TARGET_${TARGET}=y
CONFIG_TARGET_${TARGET}_${SUBTARGET}=y
EOF

# ═══════════════════════════════════════
#  Step 2: 设备 Profile
# ═══════════════════════════════════════
if [ -n "$PROFILE" ]; then
  echo "📱 设备: ${PROFILE}"
  for dev in $PROFILE; do
    echo "CONFIG_TARGET_DEVICE_${TARGET}_${SUBTARGET}_DEVICE_${dev}=y" >> "$OUTPUT"
  done
else
  echo "📱 全部设备"
  echo "CONFIG_TARGET_ALL_PROFILES=y" >> "$OUTPUT"
fi

# ═══════════════════════════════════════
#  Step 3: 基础模板
# ═══════════════════════════════════════
if [ -f "${CONFIG_DIR}/templates/base.config" ]; then
  echo "📋 应用基础模板"
  cat "${CONFIG_DIR}/templates/base.config" >> "$OUTPUT"
fi

# ═══════════════════════════════════════
#  Step 4: NSS (如果平台支持)
# ═══════════════════════════════════════
NSS_SUPPORT=$(sed -n "/^  ${SUBTARGET}:/,/^[a-z]/{ /nss:/p; }" "$PLATFORM_FILE" | grep -o 'true' || true)
if [ "$NSS_SUPPORT" = "true" ] && [ -f "${CONFIG_DIR}/templates/nss.config" ]; then
  echo "🔧 应用 NSS 模板"
  cat "${CONFIG_DIR}/templates/nss.config" >> "$OUTPUT"
fi

# ═══════════════════════════════════════
#  Step 5: 防火墙模板
# ═══════════════════════════════════════
FW_TEMPLATE="${CONFIG_DIR}/templates/firewall-${FIREWALL}.config"
if [ -f "$FW_TEMPLATE" ]; then
  echo "🛡️ 应用防火墙模板: ${FIREWALL}"
  cat "$FW_TEMPLATE" >> "$OUTPUT"
fi

# ═══════════════════════════════════════
#  Step 6: 用户插件
# ═══════════════════════════════════════
if [ -n "$PLUGINS" ]; then
  echo "🧩 插件: ${PLUGINS}"

  # 加载防火墙兼容性规则
  COMPAT_FILE="${CONFIG_DIR}/plugins/firewall-compat.yml"
  if [ -f "$COMPAT_FILE" ]; then
    # 提取仅 iptables 的插件列表
    IPT_ONLY=$(sed -n '/^  iptables_only:/,/^[a-z]/{ s/^[[:space:]]*- //p; }' "$COMPAT_FILE" 2>/dev/null)

    for pkg in $PLUGINS; do
      # 检查兼容性
      if [ "$FIREWALL" = "nftables" ] && echo "$IPT_ONLY" | grep -q "^${pkg}$"; then
        echo "  ⚠️ 跳过 ${pkg} (仅 iptables 兼容)"
        continue
      fi
      echo "CONFIG_PACKAGE_${pkg}=y" >> "$OUTPUT"
    done
  else
    # 无兼容性配置，直接添加
    for pkg in $PLUGINS; do
      echo "CONFIG_PACKAGE_${pkg}=y" >> "$OUTPUT"
    done
  fi
fi

# ═══════════════════════════════════════
#  Step 7: ccache
# ═══════════════════════════════════════
if [ "$ENABLE_CCACHE" = "true" ]; then
  echo "CONFIG_CCACHE=y" >> "$OUTPUT"
fi

# ═══════════════════════════════════════
#  Step 8: 自定义配置 (base64)
# ═══════════════════════════════════════
if [ -n "$CUSTOM_CONFIG" ]; then
  echo "📝 应用自定义配置"
  echo "$CUSTOM_CONFIG" | base64 -d >> "$OUTPUT"
fi

# ═══════════════════════════════════════
#  Step 9: make defconfig
# ═══════════════════════════════════════
echo "⚙️ 运行 make defconfig..."
make defconfig

# ═══════════════════════════════════════
#  Step 10: 清理前导空格 (防御性)
# ═══════════════════════════════════════
sed -i 's/^[[:space:]]*//' "$OUTPUT"

echo "✅ .config 生成完成: ${OUTPUT}"
echo "   配置项: $(grep -c '=y' "$OUTPUT")"
