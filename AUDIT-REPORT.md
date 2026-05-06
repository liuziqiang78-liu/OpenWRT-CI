# OpenWRT-CI 交叉审计报告

## 审计总结

- **审计时间**: 2026-05-03 10:25:21 CST
- **未修复 bug**: 0

## 已修复的 bug

| # | 类别 | 文件 | 描述 | 状态 |
|:--|:-----|:-----|:-----|:-----|
| 1 | 后端 | validate-config.sh | warn() 缺少花括号 | ✅ 已修复 |
| 2 | 后端 | generate-config.sh | $candidate 变量未加引号 | ✅ 已修复 |
| 3 | 后端 | apply-system-config.sh | 密码注入风险 (sys.argv) | ✅ 已修复 |
| 4 | 后端 | apply-system-config.sh | WiFi SSID/密码单引号注入 | ✅ 已修复 |
| 5 | 后端 | post-build-check.sh | ((ERRORS++)) 在 set -e 下不安全 | ✅ 已修复 |
| 6 | 后端 | post-build-check.sh | 管道 while 中变量作用域 | ✅ 已修复 |
| 7 | 后端 | validate-config.sh | ((ERRORS/WARNINGS++)) 不安全 | ✅ 已修复 |
| 8 | 后端 | generate-manifest.sh | FIRST 变量在管道子 shell 失效 | ✅ 已修复 |
| 9 | 后端 | workflow | timeout 720→360 分钟 | ✅ 已修复 |
| 10 | 后端 | build.sh | nproc 无容错 | ✅ 已修复 |
| 11 | 前端 | index.html | API 调用无超时 (AbortController) | ✅ 已修复 |
| 12 | 前端 | index.html | 缺少 -webkit-backdrop-filter | ✅ 已修复 |
| 13 | 前端 | index.html | log() XSS (escapeHtml) | ✅ 已修复 |
| 14 | 前端 | index.html | 重复设备 ID (Default/netgear) | ✅ 已修复 |
| 15 | 前端 | index.html | fetch signal 参数位置错误 | ✅ 已修复 |

## 审计维度

- **后端**: Shell 语法安全、变量作用域、注入防护、错误处理
- **前端**: XSS 防护、浏览器兼容性、API 超时、数据完整性
- **一致性**: 前后端配置选项、默认值对齐
- **安全**: Token 处理、密码安全、HTTPS 使用
