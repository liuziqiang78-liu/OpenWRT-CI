#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  生成固件清单 (manifest.json)
#  用法: generate-manifest.sh <work_dir> [output_file]
# ═══════════════════════════════════════════
set -euo pipefail

WORK_DIR="${1:-.}"
OUTPUT="${2:-manifest.json}"

# ── 去除 OUTPUT 中与 WORK_DIR 重复的前缀 (防御性) ──
if [[ "$OUTPUT" == "$WORK_DIR/"* ]]; then
  OUTPUT="${OUTPUT#"$WORK_DIR"/}"
fi

# ── 解析输出路径为绝对路径 (必须在 cd 之前，否则相对路径基准会变) ──
case "$OUTPUT" in
  /*) ;;  # 已经是绝对路径
  *)  OUTPUT="$(cd "$WORK_DIR" && pwd)/$OUTPUT" ;;
esac

cd "$WORK_DIR"

# ── 从 .config 提取元数据 ──
TARGET=$(grep -oP 'CONFIG_TARGET_\K[a-z0-9]+(?==y)' .config | head -1)
SUBTARGET=$(grep -oP "CONFIG_TARGET_${TARGET}_\\K[a-z0-9]+(?==y)" .config | head -1)
DEVICE=$(grep -oP 'CONFIG_TARGET.*DEVICE_\K[^=]+(?==y)' .config | head -1)
FIREWALL=$(grep -q 'CONFIG_PACKAGE_firewall4=y' .config && echo 'nftables' || echo 'iptables')
BRANCH=$(git -C "$(find . -name '.git' -maxdepth 2 -type d | head -1 | xargs dirname 2>/dev/null || echo .)" \
  rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT=$(git -C "$(find . -name '.git' -maxdepth 2 -type d | head -1 | xargs dirname 2>/dev/null || echo .)" \
  rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── 收集固件文件 ──
echo '{"firmware":[' > "$OUTPUT"
FIRST=true
while IFS= read -r f; do
  SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
  SHA256=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
  # JSON 转义路径中的特殊字符
  SAFE_PATH=$(echo "$f" | sed 's/\\/\\\\/g; s/"/\\"/g')
  [ "$FIRST" = true ] || echo ',' >> "$OUTPUT"
  FIRST=false
  cat >> "$OUTPUT" <<ENTRY
{"path":"${SAFE_PATH}","size":${SIZE},"sha256":"${SHA256}"}
ENTRY
done < <(find bin/targets/ -type f \( -name "*.bin" -o -name "*.itb" -o -name "*.img" \
  -o -name "*.ubi" -o -name "*.tar" \) 2>/dev/null | sort)

cat >> "$OUTPUT" <<EOF
],"meta":{"target":"${TARGET}","subtarget":"${SUBTARGET}","device":"${DEVICE:-all}","firewall":"${FIREWALL}","branch":"${BRANCH}","commit":"${COMMIT}","build_date":"${BUILD_DATE}"}}
EOF

echo "✅ 清单生成: ${OUTPUT}"
