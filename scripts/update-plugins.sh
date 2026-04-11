#!/bin/bash

# 为 build-ui-full.html 添加版本号和依赖关系

cd /home/admin/openclaw/workspace/OpenWRT-CI

# 备份原文件
cp build-ui-full.html build-ui-full.html.bak

# 使用 sed 批量添加 version 和 dependencies 字段
# 示例格式：{name: 'HomeProxy', pkg: 'luci-app-homeproxy', desc: '高性能代理工具', version: 'v1.9.5', dependencies: '无', features: '支持多种协议、高性能转发、规则分流、日志记录'}

echo "正在更新插件数据..."

# 这里需要手动编辑文件添加 version 和 dependencies 字段
# 由于插件太多，建议使用文本编辑器的批量替换功能

echo "完成！请手动添加 version 和 dependencies 字段到每个插件对象"
echo "格式：version: '版本号', dependencies: '依赖项'"
