#!/system/bin/sh
# MiMo v2.5 Pro AI Module - post-fs-data

MODDIR=${0%/*}
MIMO_DIR="/data/adb/mimo"
MIMO_CACHE="/data/cache/mimo"

# 等待数据分区挂载
while [ ! -d /data/adb ]; do
    sleep 1
done

# 加载模块系统属性
if [ -f "$MIMO_DIR/config/system.prop" ]; then
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        case "$key" in
            \#*|"") continue ;;
        esac
        # 去除引号
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        [ -n "$key" ] && setprop "$key" "$value"
    done < "$MIMO_DIR/config/system.prop"
fi

# 确保缓存目录存在
mkdir -p "$MIMO_CACHE" 2>/dev/null
chmod 777 "$MIMO_CACHE" 2>/dev/null

# 设置 SELinux 上下文
chcon -R u:object_r:vendor_file:s0 "$MIMO_DIR" 2>/dev/null
chcon -R u:object_r:vendor_file:s0 "$MIMO_CACHE" 2>/dev/null
