#!/usr/bin/env python3
"""
查找插件仓库地址的工具
从WebUI插件列表中提取所有插件，尝试找到对应的GitHub仓库
"""

import json
import subprocess
import re
from pathlib import Path

# 已知的作者和仓库模式
KNOWN_AUTHORS = {
    "sbwml": [
        "luci-app-aria2",
        "luci-app-qbittorrent", 
        "luci-app-webdav",
        "luci-app-lucky",
        "luci-app-samba4",
        "luci-app-aliyundrive-webdav",
        "luci-app-filebrowser",
        "luci-app-kodexplorer",
        "luci-app-linkease",
        "luci-app-rclone",
        "luci-app-mosdns",
        "luci-app-smartdns",
        "luci-theme-argon"
    ],
    "sirpdboy": [
        "luci-app-ddns-go",
        "luci-theme-kucat",
        "luci-app-timedreboot",
        "luci-app-watchcat",
        "luci-app-timewol",
        "luci-app-taskplan",
        "luci-app-frpc",
        "luci-app-frps",
        "luci-app-qosmate",
        "luci-app-bandix",
        "luci-app-eqosplus",
        "luci-app-fastnet"
    ],
    "lisaac": [
        "luci-app-diskman"
    ],
    "vernesong": [
        "luci-app-openclash"
    ],
    "Openwrt-Passwall": [
        "luci-app-passwall",
        "luci-app-passwall2"
    ],
    "VIKINGYFY": [
        "luci-app-homeproxy"
    ],
    "Tokisaki-Galaxy": [
        "luci-app-tailscale-community"
    ],
    "EasyTier": [
        "luci-app-easytier"
    ],
    "lmq8267": [
        "luci-app-vnt"
    ],
    "eamonxg": [
        "luci-theme-aurora"
    ]
}

# 通用模式
GENERIC_PATTERNS = [
    "https://github.com/sbwml/{plugin}.git",
    "https://github.com/sirpdboy/{plugin}.git",
    "https://github.com/kenzok8/{plugin}.git",
    "https://github.com/xiaorouji/{plugin}.git"
]

def extract_plugins_from_js():
    """从complete-plugins.js中提取插件列表"""
    js_file = Path("scripts/complete-plugins.js")
    if not js_file.exists():
        print(f"错误: 找不到 {js_file}")
        return []
    
    content = js_file.read_text()
    
    # 提取所有pkg字段
    pattern = r"pkg:\s*'([^']+)'"
    plugins = re.findall(pattern, content)
    
    return sorted(set(plugins))

def guess_repo_url(plugin):
    """猜测插件的GitHub仓库地址"""
    # 检查已知作者
    for author, plugin_list in KNOWN_AUTHORS.items():
        if plugin in plugin_list:
            return f"https://github.com/{author}/{plugin}.git"
    
    # 尝试通用模式
    for pattern in GENERIC_PATTERNS:
        url = pattern.replace("{plugin}", plugin)
        # 可以添加检查URL是否存在的逻辑
        return url
    
    return ""

def update_repo_map(plugins):
    """更新仓库映射文件"""
    repo_map_file = Path("plugin-repos.json")
    
    if repo_map_file.exists():
        with open(repo_map_file, 'r') as f:
            repo_map = json.load(f)
    else:
        repo_map = {}
    
    # 确保有generic_patterns字段
    if "generic_patterns" not in repo_map:
        repo_map["generic_patterns"] = GENERIC_PATTERNS
    
    # 添加新的插件映射
    added = 0
    for plugin in plugins:
        if plugin not in repo_map and not plugin.startswith("luci-theme-"):
            repo_url = guess_repo_url(plugin)
            if repo_url:
                repo_map[plugin] = repo_url
                added += 1
                print(f"添加: {plugin} -> {repo_url}")
    
    # 写回文件
    with open(repo_map_file, 'w') as f:
        json.dump(repo_map, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ 添加了 {added} 个插件映射")
    print(f"总计: {len([k for k in repo_map.keys() if not k.startswith('generic')])} 个插件映射")
    
    return repo_map

def main():
    print("🚀 开始更新插件仓库映射...")
    
    # 提取插件列表
    plugins = extract_plugins_from_js()
    print(f"找到 {len(plugins)} 个插件")
    
    # 更新映射文件
    repo_map = update_repo_map(plugins)
    
    # 保存为纯映射文件（无generic_patterns）
    simple_map = {k: v for k, v in repo_map.items() if k != "generic_patterns"}
    with open("plugin-repos-simple.json", 'w') as f:
        json.dump(simple_map, f, indent=2, ensure_ascii=False)
    
    print("\n📊 统计:")
    print(f"代理类插件: {len([k for k in simple_map.keys() if 'proxy' in k or 'passwall' in k or 'clash' in k])}")
    print(f"存储类插件: {len([k for k in simple_map.keys() if 'disk' in k or 'samba' in k or 'aria' in k])}")
    print(f"网络类插件: {len([k for k in simple_map.keys() if 'ddns' in k or 'dns' in k or 'vpn' in k])}")
    print(f"系统类插件: {len([k for k in simple_map.keys() if 'app-' in k and not any(x in k for x in ['proxy', 'disk', 'ddns', 'dns', 'vpn'])])}")
    print(f"主题类插件: {len([k for k in simple_map.keys() if 'theme' in k])}")
    
    print("\n✅ 完成!")

if __name__ == "__main__":
    main()