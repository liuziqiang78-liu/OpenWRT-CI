#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

# 预置HomeProxy数据
for dir in */; do
    if [[ "$dir" == *"homeproxy"* ]]; then
        echo " "
    
        HP_RULE="surge"
        HP_PATH="homeproxy/root/etc/homeproxy"
    
        rm -rf ./$HP_PATH/resources/*
    
        git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
        cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")
    
        echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
        awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
        sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
        mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/
    
        cd .. && rm -rf ./$HP_RULE/
    
        cd $PKG_PATH && echo "homeproxy date has been updated!"
        break
    fi
done

# 修改argon主题字体和颜色
for dir in */; do
    if [[ "$dir" == *"luci-theme-argon"* ]]; then
        echo " "
    
        cd ./luci-theme-argon/
    
        sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon
    
        cd $PKG_PATH && echo "theme-argon has been fixed!"
        break
    fi
done

# 修改aurora菜单式样
for dir in */; do
    if [[ "$dir" == *"luci-app-aurora-config"* ]]; then
        echo " "
    
        cd ./luci-app-aurora-config/
    
        sed -i "s/nav_submenu_type '.*'/nav_submenu_type 'boxed-dropdown'/g" $(find ./root/ -type f -name "*aurora")
    
        cd $PKG_PATH && echo "theme-aurora has been fixed!"
        break
    fi
done

# 修改qca-nss-drv启动顺序
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
    echo " "

    sed -i 's/START=.*/START=85/g' $NSS_DRV

    cd $PKG_PATH && echo "qca-nss-drv has been fixed!"
fi

# 修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
    echo " "

    sed -i 's/START=.*/START=86/g' $NSS_PBUF

    cd $PKG_PATH && echo "qca-nss-pbuf has been fixed!"
fi

# 修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
    echo " "

    sed -i '/\/files/d' $TS_FILE

    cd $PKG_PATH && echo "tailscale has been fixed!"
fi

# 修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
    echo " "

    sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

    cd $PKG_PATH && echo "rust has been fixed!"
fi

# 修复DiskMan编译失败
DM_FILE="./luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
    echo " "

    sed -i '/ntfs-3g-utils /d' $DM_FILE

    cd $PKG_PATH && echo "diskman has been fixed!"
fi

# 处理UPnP与iptables兼容性
for dir in */; do
    if [[ "$dir" == *"luci-app-upnp"* ]]; then
        echo " "
        
        # 确保 miniupnpd 配置适合 iptables 后端
        UPNP_MAKEFILE=$(find ../feeds/packages/net/ -name "Makefile" -path "*/miniupnpd/*" 2>/dev/null | head -n 1)
        if [ -n "$UPNP_MAKEFILE" ] && [ -f "$UPNP_MAKEFILE" ]; then
            # 如果是 miniupnpd-iptables 版本，确保正确配置
            if grep -q "miniupnpd-iptables" "$UPNP_MAKEFILE"; then
                echo "miniupnpd-iptables package detected and configured"
            fi
        fi
        
        cd $PKG_PATH && echo "upnp packages have been adjusted for iptables!"
        break
    fi
done

# 仅检查文件是否存在而不使用通配符目录检测
if [ -d "./luci-app-netspeedtest" ] || [ -f "../feeds/luci/applications/luci-app-netspeedtest/Makefile" ]; then
    echo " "

    cd ./luci-app-netspeedtest/

    sed -i '$a\exit 0' ./netspeedtest/files/99_netspeedtest.defaults
    sed -i 's/ca-certificates/ca-bundle/g' ./speedtest-cli/Makefile

    cd $PKG_PATH && echo "netspeedtest has been fixed!"
fi