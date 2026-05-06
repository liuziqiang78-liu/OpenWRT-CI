#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  修复 feeds 中缺失的依赖关系
#  在 feeds install 之后、make defconfig 之前运行
#
#  用法: fix-dependencies.sh <work_dir>
# ═══════════════════════════════════════════
set -euo pipefail

WORK_DIR="${1:-.}"
cd "$WORK_DIR"

echo ""
echo "🔧 修复缺失依赖关系"

PATCHED=0
SKIPPED=0

# ── 工具函数 ──
# 替换 Makefile 中的依赖名称（使用 perl 避免 sed 特殊字符问题，精确匹配单词边界）
fix_dep() {
  local file="$1" old="$2" new="$3"
  if [ -f "$file" ]; then
    if grep -qF "$old" "$file" 2>/dev/null; then
      # 使用 perl -pi 进行精确替换（转义特殊字符，避免子串误伤）
      perl -pi -e "s/\Q${old}\E/${new}/g" "$file"
      echo "  ✅ $(basename "$(dirname "$file")"): $old → $new"
      PATCHED=$((PATCHED + 1))
    fi
  fi
}

# 移除 Makefile 中的特定依赖
remove_dep() {
  local file="$1" dep="$2"
  if [ -f "$file" ]; then
    if grep -qF "$dep" "$file" 2>/dev/null; then
      # 处理 +dep 格式 (OpenWrt 标准)
      perl -pi -e "s/\+\Q${dep}\E//g" "$file"
      # 处理空的 DEPENDS 行
      perl -pi -e '/^\s*DEPENDS:=\s*$/ && $_ = ""' "$file"
      echo "  ✅ $(basename "$(dirname "$file")"): 移除 $dep"
      PATCHED=$((PATCHED + 1))
    fi
  fi
}

# ── 查找 feeds 中的包目录 ──
find_pkg_dir() {
  local pkg="$1"
  for dir in package/feeds/*/"$pkg"; do
    [ -d "$dir" ] && echo "$dir" && return 0
  done
  return 1
}

# ═══════════════════════════════════════════
#  修复 1: kismet — libpcre22 → libpcre2 (精确修复)
#  原始 Makefile 有 libpcre22 (typo)，需精确替换
# ═══════════════════════════════════════════
KISMET_DIR=$(find_pkg_dir "kismet" || true)
if [ -n "$KISMET_DIR" ]; then
  if [ -f "$KISMET_DIR/Makefile" ]; then
    # 先修复 typo: libpcre22 → libpcre2
    if grep -q 'libpcre22' "$KISMET_DIR/Makefile" 2>/dev/null; then
      sed -i 's/libpcre22/libpcre2/g' "$KISMET_DIR/Makefile"
      echo "  ✅ kismet: libpcre22 → libpcre2 (typo 修复)"
      PATCHED=$((PATCHED + 1))
    fi
    # 再处理标准的 libpcre → libpcre2 (精确匹配，不匹配 libpcre2)
    if grep -qP 'libpcre(?!2)' "$KISMET_DIR/Makefile" 2>/dev/null; then
      sed -i 's/+libpcre\b/+libpcre2/g' "$KISMET_DIR/Makefile"
      sed -i 's/libpcre\([^2]\)/libpcre2\1/g; s/libpcre$/libpcre2/' "$KISMET_DIR/Makefile"
      echo "  ✅ kismet: libpcre → libpcre2"
      PATCHED=$((PATCHED + 1))
    fi
  fi
fi

# ═══════════════════════════════════════════
#  修复 2: openwrt-dist-luci — ChinaDNS → chinadns-ng, dns-forwarder → dnsforwarder
# ═══════════════════════════════════════════
ODL_DIR=$(find_pkg_dir "openwrt-dist-luci" || true)
if [ -n "$ODL_DIR" ]; then
  fix_dep "$ODL_DIR/Makefile" "ChinaDNS" "chinadns-ng"
  fix_dep "$ODL_DIR/Makefile" "dns-forwarder" "dnsforwarder"
fi

# ═══════════════════════════════════════════
#  修复 3: 3ginfo — 移除 modemdata 依赖 (不存在)
# ═══════════════════════════════════════════
TGINFO_DIR=$(find_pkg_dir "3ginfo" || true)
if [ -n "$TGINFO_DIR" ]; then
  remove_dep "$TGINFO_DIR/Makefile" "modemdata"
fi

# ═══════════════════════════════════════════
#  修复 4: luci-app-dnscrypt-proxy2 — minisign 为可选
# ═══════════════════════════════════════════
DNSC_DIR=$(find_pkg_dir "luci-app-dnscrypt-proxy2" || true)
if [ -n "$DNSC_DIR" ]; then
  remove_dep "$DNSC_DIR/Makefile" "minisign"
fi

# ═══════════════════════════════════════════
#  修复 5: luci-app-gobinetmodem — 移除 kmod-gobinet 依赖
# ═══════════════════════════════════════════
GOBI_DIR=$(find_pkg_dir "luci-app-gobinetmodem" || true)
if [ -n "$GOBI_DIR" ]; then
  remove_dep "$GOBI_DIR/Makefile" "kmod-gobinet"
fi

# ═══════════════════════════════════════════
#  修复 6: luci-app-hotplug — hotplug 是系统内置的
# ═══════════════════════════════════════════
HP_DIR=$(find_pkg_dir "luci-app-hotplug" || true)
if [ -n "$HP_DIR" ]; then
  remove_dep "$HP_DIR/Makefile" "hotplug"
fi

# ═══════════════════════════════════════════
#  修复 7: luci-app-mjpg-streamer — mjpg-streamer 不存在
# ═══════════════════════════════════════════
MJPG_DIR=$(find_pkg_dir "luci-app-mjpg-streamer" || true)
if [ -n "$MJPG_DIR" ]; then
  remove_dep "$MJPG_DIR/Makefile" "mjpg-streamer"
fi

# ═══════════════════════════════════════════
#  修复 8: luci-app-nft-qos — nft-qos 不存在
# ═══════════════════════════════════════════
NFTQ_DIR=$(find_pkg_dir "luci-app-nft-qos" || true)
if [ -n "$NFTQ_DIR" ]; then
  remove_dep "$NFTQ_DIR/Makefile" "nft-qos"
fi

# ═══════════════════════════════════════════
#  修复 9: luci-app-pppwn — pppwn-cpp 不存在
# ═══════════════════════════════════════════
PPPWN_DIR=$(find_pkg_dir "luci-app-pppwn" || true)
if [ -n "$PPPWN_DIR" ]; then
  remove_dep "$PPPWN_DIR/Makefile" "pppwn-cpp"
fi

# ═══════════════════════════════════════════
#  修复 10: luci-app-shairplay — shairplay 不存在
# ═══════════════════════════════════════════
SHAIR_DIR=$(find_pkg_dir "luci-app-shairplay" || true)
if [ -n "$SHAIR_DIR" ]; then
  remove_dep "$SHAIR_DIR/Makefile" "shairplay"
fi

# ═══════════════════════════════════════════
#  修复 11: luci-app-spdmodem — kmod-sprd_pcie 不存在
# ═══════════════════════════════════════════
SPD_DIR=$(find_pkg_dir "luci-app-spdmodem" || true)
if [ -n "$SPD_DIR" ]; then
  remove_dep "$SPD_DIR/Makefile" "kmod-sprd_pcie"
fi

# ═══════════════════════════════════════════
#  修复 12: luci-app-ssrust — shadowsocks-rust-config
# ═══════════════════════════════════════════
SSRUST_DIR=$(find_pkg_dir "luci-app-ssrust" || true)
if [ -n "$SSRUST_DIR" ]; then
  # shadowsocks-rust-config 可能是 shadowsocks-rust 的子包
  # 先检查是否存在
  SSR_DIR=$(find_pkg_dir "shadowsocks-rust" || true)
  if [ -z "$SSR_DIR" ]; then
    remove_dep "$SSRUST_DIR/Makefile" "shadowsocks-rust-config"
  fi
fi

# ═══════════════════════════════════════════
#  修复 13: luci-app-tencentcloud-cos — vsftpd-alt → vsftpd
# ═══════════════════════════════════════════
TCOS_DIR=$(find_pkg_dir "luci-app-tencentcloud-cos" || true)
if [ -n "$TCOS_DIR" ]; then
  # vsftpd-alt 不存在，但 vsftpd 存在于 kiddin4
  VSFTPD_DIR=$(find_pkg_dir "vsftpd" || true)
  if [ -n "$VSFTPD_DIR" ]; then
    fix_dep "$TCOS_DIR/Makefile" "vsftpd-alt" "vsftpd"
  else
    remove_dep "$TCOS_DIR/Makefile" "vsftpd-alt"
  fi
fi

# ═══════════════════════════════════════════
#  修复 14: luci-app-webd — webd 二进制可选
# ═══════════════════════════════════════════
# webd 存在于 kiddin4，但可能编译失败
# LUCI_DEPENDS 中 webd 是条件包含 (PACKAGE_..._INCLUDE_WEBD_BINARY)
# 不需要修改

# ═══════════════════════════════════════════
#  修复 15: onionshare-cli — 移除不存在的 Python 依赖
# ═══════════════════════════════════════════
ONION_DIR=$(find_pkg_dir "onionshare-cli" || true)
if [ -n "$ONION_DIR" ]; then
  remove_dep "$ONION_DIR/Makefile" "python3-pysocks"
  remove_dep "$ONION_DIR/Makefile" "python3-unidecode"
fi

# ═══════════════════════════════════════════
#  修复 16: jool/openvswitch — kmod-nf-conntrack6
#  nf_conntrack v6 已合并到 nf_conntrack，依赖不存在
# ═══════════════════════════════════════════
for pkg in jool openvswitch; do
  PKG_DIR=$(find_pkg_dir "$pkg" || true)
  if [ -n "$PKG_DIR" ]; then
    remove_dep "$PKG_DIR/Makefile" "kmod-nf-conntrack6"
  fi
done

# ═══════════════════════════════════════════
#  修复 17: trojan-plus — boost-system → boost
#  boost 在官方 packages feed 的 libs/boost 中
# ═══════════════════════════════════════════
TROJAN_DIR=$(find_pkg_dir "trojan-plus" || true)
if [ -n "$TROJAN_DIR" ]; then
  fix_dep "$TROJAN_DIR/Makefile" "boost-system" "boost"
fi

# ═══════════════════════════════════════════
#  修复 18: luci-app-school — rkp-ipid 条件检查
# ═══════════════════════════════════════════
SCHOOL_DIR=$(find_pkg_dir "luci-app-school" || true)
if [ -n "$SCHOOL_DIR" ]; then
  RKP_DIR=$(find_pkg_dir "rkp-ipid" || true)
  if [ -z "$RKP_DIR" ]; then
    remove_dep "$SCHOOL_DIR/Makefile" "rkp-ipid"
  fi
fi

# ═══════════════════════════════════════════
#  修复 19: luci-app-webd — webd 条件检查
# ═══════════════════════════════════════════
WEBD_DIR=$(find_pkg_dir "luci-app-webd" || true)
if [ -n "$WEBD_DIR" ]; then
  WEBD_PKG=$(find_pkg_dir "webd" || true)
  if [ -z "$WEBD_PKG" ]; then
    remove_dep "$WEBD_DIR/Makefile" "webd"
  fi
fi

# ═══════════════════════════════════════════
#  修复 20: 全局 libpcre → libpcre2 迁移
#  OpenWrt 主线已移除 libpcre
# ═══════════════════════════════════════════
echo "  🔍 全局扫描 libpcre 残留引用..."
for makefile in $(grep -rlP 'libpcre(?!2)' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  if [[ "$pkg_name" != "libpcre2" && "$pkg_name" != "pcre2" ]]; then
    sed -i 's/+libpcre\b/+libpcre2/g' "$makefile"
    sed -i 's/libpcre\([^2]\)/libpcre2\1/g; s/libpcre$/libpcre2/' "$makefile"
    echo "  ✅ $pkg_name: libpcre → libpcre2 (全局扫描)"
    PATCHED=$((PATCHED + 1))
  fi
done

# ═══════════════════════════════════════════
#  修复 21: 全局 kmod-nf-conntrack6 移除
# ═══════════════════════════════════════════
echo "  🔍 全局扫描 kmod-nf-conntrack6 残留引用..."
for makefile in $(grep -rl 'kmod-nf-conntrack6' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  remove_dep "$makefile" "kmod-nf-conntrack6"
done

# ═══════════════════════════════════════════
#  修复 22: python3 包名变更
# ═══════════════════════════════════════════
echo "  🔍 扫描 python3 包名变更..."
for makefile in $(grep -rl 'python3-pysocks' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  remove_dep "$makefile" "python3-pysocks"
done

# ═══════════════════════════════════════════
#  修复 23: luci-app-ssrust 精确检查
# ═══════════════════════════════════════════
SSRUST_DIR=$(find_pkg_dir "luci-app-ssrust" || true)
if [ -n "$SSRUST_DIR" ]; then
  SSR_CONFIG_EXISTS=false
  for d in package/feeds/*/shadowsocks-rust; do
    if [ -d "$d" ] && grep -q 'Package/shadowsocks-rust-config' "$d/Makefile" 2>/dev/null; then
      SSR_CONFIG_EXISTS=true
      break
    fi
  done
  if [ "$SSR_CONFIG_EXISTS" = false ]; then
    remove_dep "$SSRUST_DIR/Makefile" "shadowsocks-rust-config"
  fi
fi

# ── 汇总 ──
echo ""
echo "═══════════════════════════════════════"
echo "  依赖修复完成"
echo "  已修补: ${PATCHED} 处"
echo "═══════════════════════════════════════"
