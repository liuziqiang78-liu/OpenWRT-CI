# 批量添加 features 字段的脚本

由于文件较大，建议手动添加或使用以下方法：

1. 打开 build-ui-full.html
2. 找到 network 数组
3. 为每个插件添加 features 字段

示例：
```javascript
{name: 'Tailscale', pkg: 'luci-app-tailscale-community', desc: '虚拟组网', features: '异地组网、P2P 直连、加密传输、跨平台'},
```
