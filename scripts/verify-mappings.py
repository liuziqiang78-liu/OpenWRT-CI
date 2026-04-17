#!/usr/bin/env python3
"""
验证插件映射覆盖率
检查WebUI中的所有插件是否都有对应的仓库映射
"""

import json
import re
from pathlib import Path

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

def load_repo_mappings():
    """加载仓库映射"""
    repo_file = Path("plugin-repos.json")
    if not repo_file.exists():
        print(f"错误: 找不到 {repo_file}")
        return {}
    
    with open(repo_file, 'r') as f:
        return json.load(f)

def check_coverage():
    """检查映射覆盖率"""
    plugins = extract_plugins_from_js()
    repo_map = load_repo_mappings()
    
    print(f"WebUI中共有 {len(plugins)} 个插件")
    print(f"映射文件中有 {len([k for k in repo_map.keys() if k != 'generic_patterns'])} 个插件映射")
    
    # 检查哪些插件没有直接映射
    missing_direct = []
    covered_direct = []
    
    for plugin in plugins:
        if plugin in repo_map:
            covered_direct.append(plugin)
        else:
            missing_direct.append(plugin)
    
    print(f"\n📊 直接映射覆盖率: {len(covered_direct)}/{len(plugins)} ({len(covered_direct)/len(plugins)*100:.1f}%)")
    
    # 检查哪些插件可以通过generic_patterns找到
    generic_patterns = repo_map.get("generic_patterns", [])
    missing_all = []
    
    for plugin in missing_direct:
        # 清理插件名称
        clean_plugin = plugin.replace("luci-app-", "").replace("luci-", "")
        
        # 检查是否可以通过generic_patterns匹配
        can_be_generic = False
        for pattern in generic_patterns:
            if "{plugin}" in pattern:
                can_be_generic = True
                break
        
        if not can_be_generic:
            missing_all.append(plugin)
    
    print(f"📊 通用模式可覆盖: {len(missing_direct) - len(missing_all)} 个插件")
    print(f"📊 完全缺失映射: {len(missing_all)} 个插件")
    
    if missing_all:
        print("\n❌ 以下插件完全缺失映射 (既无直接映射，也无法通过通用模式找到):")
        for plugin in missing_all[:20]:  # 只显示前20个
            print(f"  - {plugin}")
        
        if len(missing_all) > 20:
            print(f"  ... 还有 {len(missing_all) - 20} 个")
    
    # 按类别统计
    categories = {
        "代理": ["proxy", "clash", "passwall", "v2ray", "xray", "ssr", "vpn"],
        "存储": ["disk", "samba", "aria", "qbittorrent", "transmission", "file", "webdav"],
        "网络": ["ddns", "dns", "wireguard", "openvpn", "tailscale", "zerotier", "frp", "nat"],
        "系统": ["ttyd", "watchcat", "timed", "timewol", "task", "qos", "bandwidth", "access"],
        "主题": ["theme"]
    }
    
    print("\n📈 按类别统计:")
    for category, keywords in categories.items():
        category_plugins = [p for p in plugins if any(kw in p.lower() for kw in keywords)]
        category_covered = [p for p in category_plugins if p in repo_map]
        
        if category_plugins:
            coverage = len(category_covered) / len(category_plugins) * 100
            print(f"  {category}: {len(category_covered)}/{len(category_plugins)} ({coverage:.1f}%)")
    
    return len(missing_all) == 0

def main():
    print("🔍 验证插件映射覆盖率")
    print("=" * 50)
    
    fully_covered = check_coverage()
    
    print("\n" + "=" * 50)
    if fully_covered:
        print("✅ 所有插件都有映射或可以通过通用模式找到")
    else:
        print("⚠️  部分插件缺少映射，建议添加直接映射")
        print("\n💡 建议:")
        print("1. 运行 scripts/find-plugin-repos.py 自动添加映射")
        print("2. 手动添加缺失插件的仓库地址到 plugin-repos.json")
        print("3. 检查 generic_patterns 是否包含常用作者")

if __name__ == "__main__":
    main()