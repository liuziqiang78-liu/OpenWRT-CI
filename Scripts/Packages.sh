#!/bin/bash

# 安装和更新软件包
UPDATE_PACKAGE() {
    local PKG_NAME=$1
    local PKG_REPO=$2
    local PKG_BRANCH=$3
    local PKG_SPECIAL=$4
    local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
    local REPO_NAME=${PKG_REPO#*/}

    echo " "

    # 删除本地可能存在的不同名称的软件包
    for NAME in "${PKG_LIST[@]}"; do
        # 查找匹配的目录
        echo "Search directory: $NAME"
        local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

        # 删除找到的目录
        if [ -n "$FOUND_DIRS" ]; then
            while read -r DIR; do
                rm -rf "$DIR"
                echo "Delete directory: $DIR"
            done <<< "$FOUND_DIRS"
        else
            echo "Not found directory: $NAME"
        fi
    done

    # 克隆 GitHub 仓库
    git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	    # 处理克隆的仓库
	    if [[ "$PKG_SPECIAL" == "pkg" ]]; then
	        # 安全地复制匹配的目录到当前目录，避免路径遍历攻击
	        while IFS= read -r -d '' dir; do
	            cp -rf "$dir" ./ 
	        done < <(find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -print0)
	        rm -rf ./$REPO_NAME/
	    elif [[ "$PKG_SPECIAL" == "name" ]]; then
	        mv -f $REPO_NAME $PKG_NAME
	    fi
}

# 批量从合并仓库提取插件（一次性克隆，提取多个包）
EXTRACT_FROM_CONSOLIDATED() {
    local CONSOLIDATED_REPO=$1
    local CONSOLIDATED_BRANCH=$2
    shift 2
    local PACKAGES=("$@")
    local REPO_NAME=${CONSOLIDATED_REPO#*/}

    echo " "
    echo "=== 从合并仓库提取插件: $CONSOLIDATED_REPO ==="

    # 删除 feeds 中可能存在的同名包
    for PKG in "${PACKAGES[@]}"; do
        local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG*" 2>/dev/null)
        if [ -n "$FOUND_DIRS" ]; then
            while read -r DIR; do
                rm -rf "$DIR"
                echo "Delete feeds directory: $DIR"
            done <<< "$FOUND_DIRS"
        fi
    done

    # 一次性克隆合并仓库
    git clone --depth=1 --single-branch --branch $CONSOLIDATED_BRANCH "https://github.com/$CONSOLIDATED_REPO.git"

    # 提取每个包
    for PKG in "${PACKAGES[@]}"; do
        local FOUND=$(find ./$REPO_NAME/ -maxdepth 4 -type d -iname "$PKG" | head -1)
        if [ -n "$FOUND" ]; then
            cp -rf "$FOUND" ./
            echo "✅ 已提取: $PKG (来自 $FOUND)"
        else
            echo "⚠️  未找到: $PKG"
        fi
    done

    # 清理
    rm -rf ./$REPO_NAME/
    echo "=== 合并仓库处理完成 ==="
}

# 调用示例
# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"

# ============================================================
# 合并仓库批量提取 (2024-2025 sbwml 仓库整合)
# ============================================================

# sbwml/luci - 大量标准 LuCI 插件已合并到此仓库
EXTRACT_FROM_CONSOLIDATED "sbwml/luci" "main" \
    "luci-app-aria2" \
    "luci-app-acme" \
    "luci-app-ddns" \
    "luci-app-frpc" \
    "luci-app-frps" \
    "luci-app-hd-idle" \
    "luci-app-minidlna" \
    "luci-app-mwan3" \
    "luci-app-nlbwmon" \
    "luci-app-samba4" \
    "luci-app-smartdns" \
    "luci-app-snmpd" \
    "luci-app-transmission" \
    "luci-app-ttyd" \
    "luci-app-watchcat" \
    "luci-app-wifischedule"

# sbwml/openwrt_pkgs - 自定义插件包
EXTRACT_FROM_CONSOLIDATED "sbwml/openwrt_pkgs" "main" \
    "luci-app-adguardhome" \
    "luci-app-netdata" \
    "luci-app-socat" \
    "luci-app-vlmcsd" \
    "luci-app-vsftpd" \
    "luci-app-zerotier"

# sbwml/openwrt-package - 旧版兼容包
EXTRACT_FROM_CONSOLIDATED "sbwml/openwrt-package" "main" \
    "automount" \
    "luci-app-arpbind"

# ============================================================
# 单独仓库插件 (仍保持独立的仓库)
# ============================================================

UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"

UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

UPDATE_PACKAGE "luci-app-tailscale" "Tokisaki-Galaxy/luci-app-tailscale-community" "master"

UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "fancontrol" "rockjake/luci-app-fancontrol" "main"
UPDATE_PACKAGE "gecoosac" "laipeng668/luci-app-gecoosac" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "netspeedtest" "sirpdboy/luci-app-netspeedtest" "main" "" "homebox speedtest"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "luci-app-timewol luci-app-wolplus"
UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"
UPDATE_PACKAGE "lucky" "gdy666/luci-app-lucky" "main"
UPDATE_PACKAGE "ssr-plus" "fw876/helloworld" "main" "pkg"


# ============================================================
# 新发现的替代仓库 (原仓库已删除，找到新维护者)
# ============================================================

UPDATE_PACKAGE "bandix" "timsaya/luci-app-bandix" "main"
UPDATE_PACKAGE "wechatpush" "tty228/luci-app-wechatpush" "main"
UPDATE_PACKAGE "nekobox" "Thaolga/openwrt-nekobox" "main"
UPDATE_PACKAGE "subconverter" "0x2196f3/luci-app-subconverter" "main"
UPDATE_PACKAGE "kodexplorer" "danchexiaoyang/luci-app-kodexplorer" "master"
UPDATE_PACKAGE "qosmate" "hudra0/luci-app-qosmate" "main"
UPDATE_PACKAGE "cupsd" "sirpdboy/luci-app-cupsd" "main"
UPDATE_PACKAGE "alpha" "derisamedia/luci-theme-alpha" "main"
UPDATE_PACKAGE "design" "0x676e67/luci-theme-design" "main"
UPDATE_PACKAGE "material3" "KawaiiHachimi/luci-theme-material3" "main"

# ============================================================
# 已删除且无替代的插件 (不再可用)
# ============================================================
# 以下插件的源仓库已被作者删除，且在全网找不到替代:
# luci-app-clouddrive2, luci-app-fc, luci-app-homeassistant,
# luci-app-npc, luci-app-thunder, tvhelper, btop
# luci-theme-lightblue, luci-theme-routerich, luci-theme-spectra, luci-theme-teleofis
# 如需要请寻找替代方案或自行维护 fork

# 更新软件包版本
UPDATE_VERSION() {
    local PKG_NAME=$1
    local PKG_MARK=${2:-false}
    local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

    if [ -z "$PKG_FILES" ]; then
        echo "$PKG_NAME not found!"
        return
    fi

    echo -e "\n$PKG_NAME version update has started!"

    for PKG_FILE in $PKG_FILES; do
        local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
        local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

        local OLD_VER=$(grep -Po "PKG_VERSION:=\\K.*" "$PKG_FILE")
        local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\\K.*" "$PKG_FILE")
        local OLD_FILE=$(grep -Po "PKG_SOURCE:=\\K.*" "$PKG_FILE")
        local OLD_HASH=$(grep -Po "PKG_HASH:=\\K.*" "$PKG_FILE")

        local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

        local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
        local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
        local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

        echo "old version: $OLD_VER $OLD_HASH"
        echo "new version: $NEW_VER $NEW_HASH"

        if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
            sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
            sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
            echo "$PKG_FILE version has been updated!"
        else
            echo "$PKG_FILE version is already the latest!"
        fi
    done
}

# UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
UPDATE_VERSION "sing-box"
# UPDATE_VERSION "tailscale"
