#!/system/bin/sh
# MiMo 配置工具 - 云端 API 模式
# 用法: mimo_config.sh

CONFIG_FILE="/data/adb/mimo/config/mimo_mode.json"
mkdir -p /data/adb/mimo/config

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m'
C='\033[0;36m' W='\033[1;37m' N='\033[0m'

echo ""
echo -e "${W}╔══════════════════════════════════════╗${N}"
echo -e "${W}║  MiMo v2.5 Pro 云端 API 配置         ║${N}"
echo -e "${W}╚══════════════════════════════════════╝${N}"
echo ""

if [ -f "$CONFIG_FILE" ]; then
    OLD_URL=$(grep -o '"url":"[^"]*"' "$CONFIG_FILE" | sed 's/"url":"//;s/"$//')
    OLD_TOKEN=$(grep -o '"token":"[^"]*"' "$CONFIG_FILE" | sed 's/"token":"//;s/"$//')
    echo -e "当前配置:"
    echo -e "  API:   ${C}${OLD_URL:-未配置}${N}"
    echo -e "  Token: ${C}${OLD_TOKEN:0:8}${OLD_TOKEN:+...}${N}"
    echo ""
fi

echo -e "获取 Token:"
echo -e "  1. 打开 ${B}https://model.mi.com${N}"
echo -e "  2. 登录小米账号"
echo -e "  3. API 管理 → 创建 Token"
echo -e "  4. 复制 Token"
echo ""
echo -ne "${W}API 地址 [默认: https://api.mi.com/v1]: ${N}"
read API_URL
API_URL="${API_URL:-https://api.mi.com/v1}"

echo ""
echo -ne "${W}粘贴 API Token: ${N}"
read API_TOKEN

if [ -z "$API_TOKEN" ]; then
    echo -e "${R}错误: Token 不能为空${N}"
    exit 1
fi

# 写入配置
cat > "$CONFIG_FILE" << EOF
{
    "mode": "cloud",
    "api": {
        "url": "$API_URL",
        "token": "$API_TOKEN",
        "model": "mimo-v2.5-pro"
    },
    "updated": "$(date -Iseconds)"
}
EOF

echo ""
echo -e "${G}✓ 配置完成${N}"
echo ""
echo -e "  API: ${C}${API_URL}${N}"
echo -e "  Token: ${C}${API_TOKEN:0:8}...${N}"
echo ""
echo -e "重启服务: ${Y}mimo restart${N}"
echo -e "打开 WebUI: ${Y}http://localhost:9081${N}"
echo ""
