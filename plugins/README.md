# 插件目录

每个插件独立一个文件夹，包含以下文件：

```
plugins/
├── README.md                    # 本文件
├── luci-app-homeproxy/          # 每个插件一个文件夹
│   ├── config.json              # 插件元数据 (名称、描述、仓库地址、分类)
│   └── config.mk                # OpenWRT 配置片段
├── luci-app-openclash/
│   ├── config.json
│   └── config.mk
└── ...
```

## 文件说明

### config.json
```json
{
    "name": "OpenClash",
    "package": "luci-app-openclash",
    "description": "Clash 客户端",
    "features": "规则代理、节点切换、流量统计",
    "category": "proxy",
    "repository": "https://github.com/vernesong/OpenClash.git"
}
```

### config.mk
```
CONFIG_PACKAGE_luci-app-openclash=y
```

## 分类

| 分类 | 目录数 | 说明 |
|------|--------|------|
| proxy | 12 | 科学上网 |
| storage | 15 | 存储管理 |
| network | 31 | 网络工具 |
| theme | 11 | 主题 |
| system | 27 | 系统工具 |

## 使用方式

### 编译时安装指定插件
```bash
# 安装单个插件
bash scripts/install-plugins.sh luci-app-homeproxy luci-app-openclash

# 安装某分类下所有插件
bash scripts/install-plugins.sh --category proxy
```

### 添加新插件
1. 在 `plugins/` 下创建新文件夹
2. 添加 `config.json` 和 `config.mk`
3. 编译时会自动识别
