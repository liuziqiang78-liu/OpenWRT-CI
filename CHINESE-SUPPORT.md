# 中文语言支持指南

## 问题描述
固件编译成功后，在系统设置中设置了中文，但界面仍然显示英文。

## 根本原因
中文语言支持需要两个部分：
1. **语言设置** - 告诉系统使用中文（我们已经通过预配置文件设置）
2. **翻译文件** - 实际的中文翻译文件（可能没有安装）

## 解决方案

### 方案1：检查当前状态（推荐）
通过SSH连接到路由器，运行以下命令：

```bash
# 检查是否安装了中文语言包
opkg list-installed | grep -i "zh-cn\|zh_CN\|i18n"

# 检查语言设置
uci get luci.main.lang

# 查看首次启动脚本日志
cat /tmp/set-chinese-language.log 2>/dev/null || echo "日志不存在"

# 手动设置语言
uci set luci.main.lang=zh_cn
uci commit luci
/etc/init.d/uhttpd restart
```

### 方案2：手动安装中文语言包
如果检查发现没有中文语言包，手动安装：

```bash
# 更新软件包列表
opkg update

# 搜索可用的中文语言包
opkg list | grep -i "luci-i18n.*zh"

# 安装基础中文语言包（如果可用）
opkg install luci-i18n-base-zh-cn

# 或者尝试其他变体
opkg install luci-i18n-base-zh_Hans
```

### 方案3：通过Luci界面安装
1. 访问路由器管理界面（通常是 `192.168.1.1`）
2. 进入 **系统 (System)** → **软件包 (Software)**
3. 点击 **更新列表 (Update lists)**
4. 搜索 `luci-i18n`
5. 安装 `luci-i18n-base-zh-cn` 或类似的中文语言包

### 方案4：重新编译固件（包含中文语言包）
在WebUI中选择编译选项时：
1. 确保选择 **immortalwrt** 或 **openwrt** 官方源
2. 这些源更可能包含完整的中文语言包
3. 等待编译完成，重新刷写固件

## 诊断脚本
创建一个诊断脚本 `/tmp/check-chinese.sh`：

```bash
#!/bin/sh
echo "=== 中文语言支持诊断报告 ==="
echo "1. 系统语言设置:"
uci get luci.main.lang 2>/dev/null || echo "未设置"
echo ""
echo "2. 已安装的中文语言包:"
opkg list-installed | grep -i "zh-cn\|zh_CN\|i18n.*zh" 2>/dev/null || echo "无"
echo ""
echo "3. 可用的中文语言包:"
opkg list | grep -i "luci-i18n.*zh" 2>/dev/null | head -10 || echo "未找到"
echo ""
echo "4. 环境变量:"
env | grep -i "lang\|locale" | head -10
echo ""
echo "5. 当前区域设置:"
locale 2>/dev/null || echo "locale命令不可用"
echo "=== 诊断完成 ==="
```

运行诊断脚本：
```bash
chmod +x /tmp/check-chinese.sh
/tmp/check-chinese.sh
```

## 常见问题

### Q1: 为什么设置了中文但显示英文？
A: 设置了语言偏好但没有安装实际的翻译文件。就像有了中文菜单但没有中文内容。

### Q2: 如何知道固件是否包含中文语言包？
A: 编译日志中会显示：
- `✅ 发现 luci-i18n-base-zh-cn 语言包` - 包含中文包
- `⚠️  未找到中文语言包` - 不包含中文包

### Q3: 安装中文语言包需要网络吗？
A: 是的，需要通过 `opkg` 从软件源下载安装。确保路由器可以访问互联网。

### Q4: 中文语言包安装失败怎么办？
A: 可能的原因：
1. 网络连接问题 - 检查网络设置
2. 软件源不可用 - 尝试更换软件源
3. 架构不兼容 - 确保安装的包与CPU架构匹配

## 技术细节

### 预配置文件
固件包含以下预配置文件：
- `/etc/config/luci` - 预设置为中文界面
- `/etc/environment` - 设置中文环境变量  
- `/etc/uci-defaults/99-set-chinese-language` - 首次启动配置脚本

### 首次启动脚本功能
1. 设置语言为中文
2. 检查中文语言包是否安装
3. 尝试从网络安装缺失的包
4. 生成诊断日志 `/tmp/set-chinese-language.log`

### 编译时检测
工作流会尝试检测并包含中文语言包，但如果源中没有，则无法包含。

## 联系支持
如果问题仍然存在：
1. 提供诊断脚本输出
2. 提供 `/tmp/set-chinese-language.log` 内容
3. 说明使用的编译源和插件列表

---

**最后更新**: 2026-04-18  
**状态**: 动态检测 + 运行时安装  
**可靠性**: 中等（依赖源中的中文包可用性）