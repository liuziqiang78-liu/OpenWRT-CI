# OpenWRT-CI 分层架构设计 v2

## 设计原则

1. **数据驱动** — 平台/插件/约束全部外置为 YAML 配置
2. **模板组装** — .config 从模板拼装，而非硬编码
3. **脚本复用** — 核心逻辑在 `scripts/` 中，workflow 和本地均可调用
4. **验证前置** — 编译前强制验证配置正确性
5. **冗余扩展** — 新增 target/插件/功能只需添加配置文件

## 架构总览

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Web UI (index.html)                           │
│  样式 + 交互不变，14 个参数 → workflow_dispatch          │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│  Layer 2: Orchestrator (build-openwrt.yml)              │
│  9 步流水线: checkout → clone → feeds →                 │
│              config-gen → validate →                    │
│              download → toolchain → build → upload      │
└──┬──────────┬──────────┬──────────┬────────────────────┘
   │          │          │          │
┌──▼───┐ ┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│  L3  │ │  L4   │ │ L5-7  │ │ L8-9  │
│Config│ │Valid- │ │Build  │ │Report │
│ Gen  │ │ ator  │ │       │ │       │
└──┬───┘ └───────┘ └───────┘ └───────┘
   │
┌──▼──────────────────────────────────────────┐
│  Layer 0: Configuration Data                │
│                                             │
│  config/                                    │
│  ├── schema.yml          ← 结构规范         │
│  ├── platforms/                               │
│  │   ├── qualcommax.yml  ← 平台定义         │
│  │   ├── ipq40xx.yml                        │
│  │   └── ipq806x.yml                        │
│  ├── plugins/                                │
│  │   └── firewall-compat.yml ← 兼容性规则   │
│  └── templates/                              │
│      ├── base.config     ← 基础模板         │
│      ├── nss.config      ← NSS 模板         │
│      ├── firewall-iptables.config            │
│      └── firewall-nftables.config            │
│                                             │
│  scripts/                                   │
│  ├── generate-config.sh  ← 配置生成器       │
│  └── validate-config.sh  ← 配置验证器       │
└─────────────────────────────────────────────┘
```

## 文件清单

```
OpenWRT-CI/
├── index.html                              # Layer 1: UI (不变)
├── ARCHITECTURE.md                         # 本文档
├── config/                                 # Layer 0: 配置数据
│   ├── schema.yml                          # 平台配置结构规范
│   ├── platforms/
│   │   ├── qualcommax.yml                  # Qualcomm WiFi 6 平台
│   │   ├── ipq40xx.yml                     # Qualcomm IPQ40xx 平台
│   │   └── ipq806x.yml                     # Qualcomm IPQ806x 平台
│   ├── plugins/
│   │   └── firewall-compat.yml             # 插件防火墙兼容性 + 依赖
│   └── templates/
│       ├── base.config                     # 基础 .config 模板
│       ├── nss.config                      # NSS 硬件加速模板
│       ├── firewall-iptables.config        # iptables 防火墙模板
│       └── firewall-nftables.config        # nftables 防火墙模板
├── scripts/                                # Layer 3-4: 可复用脚本
│   ├── generate-config.sh                  # 通用配置生成器
│   └── validate-config.sh                  # 通用配置验证器
└── .github/
    ├── actions/
    │   └── generate-config/
    │       └── action.yml                  # Composite action (调用脚本)
    └── workflows/
        └── build-openwrt.yml               # Layer 2: 主编排 workflow
```

## 各层职责

### Layer 0: 配置数据层

**平台配置** (`config/platforms/*.yml`):
- 遵循 `schema.yml` 规范
- 定义 subtargets、默认设备、SoC、特性、包列表、约束
- 新增平台只需添加 yml 文件

**插件注册表** (`config/plugins/*.yml`):
- 防火墙兼容性规则 (iptables_only / nftables_only / 双兼容)
- 插件依赖关系
- 与 Web UI 的 `PLUGIN_CATS` 保持一致

**配置模板** (`config/templates/*.config`):
- base — 所有平台共享的基础配置
- nss — Qualcomm NSS 硬件加速
- firewall — 防火墙互斥选择
- 未来可添加: wifi.config, vpn.config, docker.config 等

### Layer 1: Web UI

- 样式和交互逻辑不变
- 14 个标准化参数 → `workflow_dispatch`
- 未来优化: 设备列表可从 `platforms/*.yml` 动态加载

### Layer 2: 编排器 (`build-openwrt.yml`)

- 调度 9 步流水线
- 不包含任何配置生成逻辑
- 每步失败中止后续步骤
- Config Summary 从 `.config` 读取实际值

### Layer 3: 配置生成 (`scripts/generate-config.sh`)

核心逻辑:
1. 解析平台配置 (YAML)
2. 解析默认 subtarget
3. 验证 subtarget / 防火墙有效性
4. 按顺序拼装 .config: target → device → base → NSS → firewall → plugins → custom
5. 运行 `make defconfig`
6. 清理前导空格

扩展点:
- `config/templates/` 添加新模板
- `config/plugins/` 添加兼容性规则
- `config/platforms/` 添加新平台

### Layer 4: 验证器 (`scripts/validate-config.sh`)

检查项:
1. `CONFIG_TARGET_MULTI_PROFILE` 是否启用
2. 实际设备是否与期望匹配
3. 防火墙是否冲突 (firewall + firewall4 共存)
4. rootfs 类型
5. 配置项统计

支持严格模式 (`--strict`): 任何警告都视为失败。

### Layer 5-7: 编译流水线

- **L5**: `make download` (支持重试)
- **L6**: `make tools/install` + `make toolchain/install`
- **L7**: `make -j$(nproc+1)` 编译固件

### Layer 8-9: 打包与报告

- **L8**: 上传固件为 GitHub Actions Artifact
- **L9**: 生成构建报告 (实际设备、防火墙、错误数、固件文件)

## 扩展指南

### 新增 Target

1. 创建 `config/platforms/newtarget.yml` (遵循 schema)
2. 在 `build-openwrt.yml` 的 `inputs.target.options` 添加选项
3. 如有 subtarget，在 `inputs.subtarget.options` 添加
4. 在 `index.html` 设备列表添加对应设备

### 新增插件

1. 在 `config/plugins/firewall-compat.yml` 添加兼容性规则
2. 在 `index.html` 的 `PLUGIN_CATS` 添加分类

### 新增配置模板

1. 在 `config/templates/` 添加 `.config` 片段
2. 在 `scripts/generate-config.sh` 添加应用逻辑

### 新增验证规则

1. 在 `scripts/validate-config.sh` 添加检查函数
2. 在 `.github/actions/generate-config/action.yml` 调用

## 与原架构对比

| 方面 | 原架构 (v1) | 分层架构 (v2) |
|:---|:---|:---|
| 文件数 | 2 | 14 |
| 配置生成 | 硬编码在 workflow | 脚本 + 模板 |
| 平台数据 | 无 | YAML 配置 |
| MULTI_PROFILE | ❌ | ✅ 自动启用 |
| 防火墙 | ❌ 可能共存 | ✅ 互斥 + 模板 |
| root_password | ❌ 未实现 | ✅ SHA-512 |
| lan_ip | ❌ 未实现 | ✅ UCI 脚本 |
| WiFi 校验 | ❌ | ✅ ≥8 位 |
| 设备验证 | ❌ 显示 input | ✅ 从 .config 读取 |
| 插件兼容性 | ❌ | ✅ 规则引擎 |
| 本地可测试 | ❌ | ✅ 脚本独立运行 |
| 新增 target | 改多处 | 加 yml + 选项 |
| 冗余扩展 | 无 | 模板/规则/脚本 |
