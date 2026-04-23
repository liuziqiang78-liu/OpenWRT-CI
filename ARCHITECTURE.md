# OpenWRT-CI 分层架构 v3

## 原则

- **零 inline 逻辑** — workflow / action 只调用脚本，不含任何 bash 逻辑
- **脚本独立可测** — 每个 `scripts/*.sh` 可脱离 CI 本地运行
- **数据驱动** — 平台/插件/模板全部外置
- **冗余扩展** — 新增能力只需添加脚本 + 配置

## 架构图

```
index.html (UI)
    │ workflow_dispatch (14 参数)
    ▼
build-openwrt.yml (纯编排, 0 逻辑)
    │
    ├─ scripts/setup-source.sh         L2: 克隆 + feeds
    ├─ .github/actions/generate-config L3: 配置生成
    │   ├─ scripts/generate-config.sh      拼装 .config
    │   ├─ scripts/apply-system-config.sh  密码/IP/WiFi
    │   └─ scripts/validate-config.sh      验证 .config
    ├─ scripts/config-summary.sh       L4: 配置摘要
    ├─ scripts/build.sh                L5: 下载+工具链+编译
    ├─ scripts/post-build-check.sh     L6: 编译后检查
    ├─ scripts/build-summary.sh        L7: 构建摘要
    ├─ scripts/generate-manifest.sh    L8: 固件清单
    └─ actions/upload-artifact@v4      L9: 上传

config/ (数据层)
    ├─ schema.yml                      平台配置规范
    ├─ platforms/*.yml                 平台定义
    ├─ plugins/firewall-compat.yml     插件兼容性
    └─ templates/*.config              .config 模板
```

## 文件清单 (22 files)

```
├── index.html                              UI (不变)
├── ARCHITECTURE.md                         本文档
│
├── config/                                 ── 数据层 ──
│   ├── schema.yml                          平台配置结构规范
│   ├── platforms/
│   │   ├── qualcommax.yml                  3 subtargets + NSS
│   │   ├── ipq40xx.yml                     3 subtargets
│   │   └── ipq806x.yml                     2 subtargets
│   ├── plugins/
│   │   └── firewall-compat.yml             兼容性 + 依赖
│   └── templates/
│       ├── base.config                     MULTI_PROFILE + LuCI
│       ├── nss.config                      NSS 硬件加速
│       ├── firewall-iptables.config        iptables 互斥
│       └── firewall-nftables.config        nftables 互斥
│
├── scripts/                                ── 逻辑层 ──
│   ├── setup-source.sh                     克隆 + feeds
│   ├── generate-config.sh                  .config 生成器
│   ├── apply-system-config.sh              密码/IP/WiFi
│   ├── validate-config.sh                  .config 验证 (6 项)
│   ├── config-summary.sh                   配置摘要
│   ├── build.sh                            编译流水线
│   ├── post-build-check.sh                 编译后检查 (4 项)
│   ├── build-summary.sh                    构建摘要
│   └── generate-manifest.sh                固件清单 JSON
│
└── .github/                                ── 编排层 ──
    ├── actions/generate-config/
    │   └── action.yml                      composite action (3 步全调脚本)
    └── workflows/
        └── build-openwrt.yml               主 workflow (9 步全调脚本)
```

## Workflow 步骤 (0 inline)

| Step | 调用 | 行数 |
|:---|:---|:---|
| 📦 Setup Source | `scripts/setup-source.sh` | 1 |
| ⚙️ Generate Config | `.github/actions/generate-config` (→ 3 scripts) | 0 |
| 📋 Config Summary | `scripts/config-summary.sh` | 1 |
| 🏗️ Build | `scripts/build.sh` | 1 |
| 🔍 Post-Build Check | `scripts/post-build-check.sh` | 1 |
| 📊 Build Summary | `scripts/build-summary.sh` | 1 |
| 📄 Generate Manifest | `scripts/generate-manifest.sh` | 1 |
| 📤 Upload | `actions/upload-artifact@v4` | 0 |

## 扩展场景

| 需求 | 操作 |
|:---|:---|
| 新增 target | 加 `config/platforms/x.yml` + workflow options |
| 新增插件规则 | 改 `config/plugins/firewall-compat.yml` |
| 新增配置模板 | 加 `config/templates/x.config` + 改 `generate-config.sh` |
| 新增验证规则 | 改 `scripts/validate-config.sh` |
| 新增编译后检查 | 改 `scripts/post-build-check.sh` |
| 新增构建报告 | 改 `scripts/build-summary.sh` |
| 本地测试 | `bash scripts/generate-config.sh --target qualcommax ...` |
