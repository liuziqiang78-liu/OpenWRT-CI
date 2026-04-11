# 更新日志

## [Unreleased]

### Added

- 插件版本控制系统
  - Config/VERSIONS.txt 集中管理 32+ 插件版本
  - Scripts/version-check.sh 检查可更新插件
  - Scripts/version-update.sh 批量更新版本
  - Plugin-Version-Check.yml 每日自动检查
- 依赖监控系统
  - Scripts/dependency-monitor.sh 本地监控
  - Dependency-Monitor.yml GitHub Actions 定时检查
  - 监控 32 个外部依赖仓库健康状态
- 编译质量工具
  - Build-Notification.yml 编译失败通知
  - Security-Scan.yml ShellCheck 和 YAML 验证
  - Scripts/config-diff.sh 配置对比工具
- 文档体系
  - docs/VERSION-CONTROL.md 版本控制指南
  - OPTIMIZATION-PROPOSAL.md 优化建议
  - ADVANCED-OPTIMIZATIONS.md 进阶优化
  - IMPROVEMENT-SUMMARY.md 改进总结
  - THIRD-BATCH-OPTIMIZATIONS.md 第三批建议

### Changed

- WRT-CORE.yml 增强固件信息生成
  - 添加 SHA256/MD5 校验和
  - 生成 FIRMWARE_INFO.md 详细文档

### Fixed

- 修复 Argon 主题加载错误
- 修复 aria2 依赖问题

---

## 2026-04-11

### Added

- 初始版本
- 基础 CI/CD 流程
  - OWRT-ALL.yml 多平台编译
  - QCA-ALL.yml 高通平台编译
  - WRT-TEST.yml 手动测试编译
  - Auto-Clean.yml 自动清理
- 多平台支持
  - MEDIATEK (联发科) 30+ 设备
  - ROCKCHIP (瑞芯微) 20+ 设备
  - X86 通用平台
  - QUALCOMMAX (高通) IPQ50/60/80 系列
- 插件系统
  - Packages.sh 自动安装插件
  - Settings.sh 系统定制
  - Handles.sh 补丁和修复
- 配置系统
  - Config/GENERAL.txt 通用配置
  - Config/*.txt 平台配置

---

## 版本说明

### 版本编号规则

采用日期版本：YYYY-MM-DD

### 固件版本查询

```bash
cat /etc/openwrt_release
```

### 升级建议

1. 备份当前配置
2. 下载最新固件
3. 验证 SHA256/MD5
4. 刷入固件
5. 恢复配置
