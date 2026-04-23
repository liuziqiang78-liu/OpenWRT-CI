#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  应用系统配置: Root密码 / LAN IP / WiFi
#  用法: apply-system-config.sh [选项]
#    --root-password PW    Root 密码
#    --lan-ip IP           LAN IP 地址
#    --wifi-ssid SSID      WiFi SSID
#    --wifi-password PW    WiFi 密码
#    --work-dir DIR        工作目录
# ═══════════════════════════════════════════
set -euo pipefail

ROOT_PW=""
LAN_IP=""
WIFI_SSID=""
WIFI_PW=""
WORK_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root-password)  ROOT_PW="$2"; shift 2 ;;
    --lan-ip)         LAN_IP="$2"; shift 2 ;;
    --wifi-ssid)      WIFI_SSID="$2"; shift 2 ;;
    --wifi-password)  WIFI_PW="$2"; shift 2 ;;
    --work-dir)       WORK_DIR="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

cd "$WORK_DIR"

# ── Root 密码 ──
if [ -n "$ROOT_PW" ]; then
  echo "🔑 设置 Root 密码"
  mkdir -p files/etc
  HASHED_PW=$(python3 -c "import crypt; print(crypt.crypt('$ROOT_PW', crypt.mksalt(crypt.METHOD_SHA512)))" 2>/dev/null || \
               openssl passwd -6 "$ROOT_PW" 2>/dev/null || echo "")
  if [ -n "$HASHED_PW" ]; then
    printf "root:%s:19797:0:99999:7:::\n" "$HASHED_PW" > files/etc/shadow
    chmod 600 files/etc/shadow
    echo "  ✅ 密码已设置"
  else
    echo "::warning::密码加密失败，跳过"
  fi
fi

# ── LAN IP ──
if [ -n "$LAN_IP" ] && [ "$LAN_IP" != "192.168.1.1" ]; then
  echo "🌐 设置 LAN IP: ${LAN_IP}"
  mkdir -p files/etc/uci-defaults
  printf '#!/bin/sh\nuci set network.lan.ipaddr="%s"\nuci commit network\n' "$LAN_IP" \
    > files/etc/uci-defaults/99-lan-ip
  chmod 755 files/etc/uci-defaults/99-lan-ip
  echo "  ✅ LAN IP 已设置"
fi

# ── WiFi ──
if [ -n "$WIFI_SSID" ]; then
  # 密码校验
  if [ -n "$WIFI_PW" ] && [ ${#WIFI_PW} -lt 8 ]; then
    echo "::error::WiFi 密码长度不足 8 位 (WPA2 要求最少 8 字符)"
    exit 1
  fi

  echo "📶 设置 WiFi: ${WIFI_SSID}"
  mkdir -p files/etc/uci-defaults
  cat > files/etc/uci-defaults/99-wifi-setup <<WIFIEOF
#!/bin/sh
uci set wireless.@wifi-iface[0].ssid='${WIFI_SSID}'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='${WIFI_PW}'
uci commit wireless
WIFIEOF
  chmod 755 files/etc/uci-defaults/99-wifi-setup
  echo "  ✅ WiFi 已设置"
fi

echo "✅ 系统配置完成"
