# OpenWRT-CI 分层架构 v4

## 目录结构 (树形分层)

```
config/
├── schema.yml                              结构规范
├── platforms/                              ── 平台 (按厂商) ──
│   ├── qualcomm/
│   │   ├── _vendor.yml                     高通厂商元数据
│   │   └── ipq60xx/
│   │       ├── _platform.yml               平台配置 (subtargets/NSS/约束)
│   │       ├── ipq6000/
│   │       │   └── _devices.yml            15 个设备
│   │       ├── ipq6010/
│   │       │   └── _devices.yml            8 个设备
│   │       └── ipq6018/
│   │           └── _devices.yml            8 个设备
│   ├── mediatek/
│   │   └── filogic/mt7621/mt7622/...
│   ├── lantiq/
│   │   └── danube/vr9/xway/falcon/...
│   ├── broadcom/
│   │   └── bcm4908/bcm53xx/...
│   ├── marvell/
│   │   └── armada/
│   └── realtek/
│       └── en7523/
│
├── plugins/                                ── 插件 (按分类) ──
│   ├── network/
│   │   └── _category.yml                   VPN/代理/加速/广告拦截
│   ├── system/
│   │   └── _category.yml                   Docker/磁盘/终端/主题
│   ├── interface/
│   │   └── _category.yml                   主题/界面增强
│   └── monitoring/
│       └── _category.yml                   流量/系统/网络监控
│
└── templates/                              ── .config 模板 ──
    ├── base.config
    ├── nss.config
    ├── firewall-iptables.config
    └── firewall-nftables.config

scripts/                                    ── 逻辑层 ──
├── setup-source.sh                         克隆 + feeds
├── generate-config.sh                      .config 生成 (自动查找平台路径)
├── apply-system-config.sh                  密码/IP/WiFi
├── validate-config.sh                      .config 验证
├── config-summary.sh                       配置摘要
├── build.sh                                编译流水线
├── post-build-check.sh                     编译后检查
├── build-summary.sh                        构建摘要
└── generate-manifest.sh                    固件清单

.github/                                    ── 编排层 ──
├── actions/generate-config/action.yml      composite action
└── workflows/build-openwrt.yml             主 workflow
```

## 层级关系

```
厂商 (qualcomm/mediatek/lantiq/...)
  └── 平台 (ipq60xx/mt7981/...)
        └── 芯片组 (ipq6000/ipq6010/ipq6018/...)
              └── 设备 (jdcloud_re-cs-02/...)
```

## 扩展示例

### 新增厂商 + 平台 (如 MediaTek MT7981)

```
config/platforms/mediatek/
├── _vendor.yml
└── mt7981/
    ├── _platform.yml
    ├── mt7981/
    │   └── _devices.yml        ← Filogic 设备
    └── mt7986/
        └── _devices.yml        ← Filogic 高端设备
```

### 新增插件分类

```
config/plugins/
└── storage/
    └── _category.yml           ← 存储相关插件
```

### 新增验证规则

改 `scripts/validate-config.sh` — workflow 不动

### 新增构建报告

改 `scripts/build-summary.sh` — workflow 不动
