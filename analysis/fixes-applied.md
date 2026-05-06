# OpenWRT-CI 构建脚本修复摘要

日期: 2026-05-06

## 修复的脚本及具体变更

### 1. `fix-dependencies.sh` — fix_dep()/remove_dep() 安全替换
- **问题**: `sed "s/$old/$new/g"` 做子串匹配，特殊字符（如 `+`、`*`、`.`）会被 sed 当正则解释
- **修复**: 改用 `perl -pi -e "s/\Q${old}\E/${new}/g"` — `\Q...\E` 做字面转义，避免子串误伤和正则注入
- `grep -q` 也改为 `grep -qF`（固定字符串匹配）

### 2. `build.sh` — 重试机制 + 统一 PARALLEL + 清理旧日志
- **问题**: `tools/install` 和 `toolchain/install` 失败无重试；混用 `$(nproc)` 和 `${PARALLEL}`
- **修复**:
  - 添加 `build_step()` 函数（最多重试 2 次，间隔 5 秒）
  - 所有 `make` 调用统一使用 `${PARALLEL}` 变量
  - 构建前执行 `rm -f build.log` 清理旧日志

### 3. `setup-source.sh` — trap cleanup EXIT
- **问题**: 脚本异常退出时 `FEED_LIST` 临时文件不会被清理
- **修复**: 脚本开头添加 `FEED_LIST=""` 初始化 + `trap cleanup EXIT`，确保任何退出路径都清理临时文件

### 4. `generate-manifest.sh` — jq 优先 + SAFE_PATH 转义增强
- **问题**: 手工拼接 JSON 不安全；SAFE_PATH 未处理 `\t`、`\n`、`\r`
- **修复**:
  - 优先使用 `jq` 构造 JSON（精确转义，最安全）
  - Fallback 路径增加 `\t`、`\n`、`\r` 的 sed 转义
  - 用 `<<< "$FIRMWARE_LIST"` 替代 `while ... done < <(find ...)` 避免管道子 shell 问题

### 5. `build-summary.sh` — 空固件列表 wc -l bug + 提取公共函数
- **问题**: `echo "" | wc -l` 返回 1 而非 0；固件查找逻辑与 post-build-check.sh 重复
- **修复**:
  - 提取 `find_firmware_files()` 函数到脚本顶部
  - 使用 `find_firmware_files | wc -l` 并设默认值 `FIRMWARE_COUNT="${FIRMWARE_COUNT:-0}"`
  - 替换原有内联 `find` 调用为函数调用

### 6. `post-build-check.sh` — 统一固件查找逻辑
- **问题**: 固件查找逻辑与 build-summary.sh 不一致
- **修复**:
  - 添加相同的 `find_firmware_files()` 函数
  - 所有 `find bin/targets/ ...` 调用改为 `find_firmware_files`
  - 修复空列表 `wc -l` bug（同 #5）

### 7. `apply-system-config.sh` — 密码哈希优先级 + LAN IP 校验
- **问题**: Python 3.13 已移除 `crypt` 模块，当前优先用 python3 会失败；LAN IP 无格式校验
- **修复**:
  - 优先使用 `openssl passwd -6`（SHA-512，所有平台可用）
  - Fallback 到 `python3 crypt`（兼容 Python < 3.13）
  - 添加 `validate_ipv4()` 函数，校验 IPv4 格式和每个 octet 范围 (0-255)

### 8. `validate-config.sh` — ACTUAL_FW 变量预初始化
- **问题**: `ACTUAL_FW` 在 if/elif/else 块之前未初始化，如果两个条件都不匹配，变量可能未定义
- **修复**: 在条件判断前添加 `ACTUAL_FW="unknown"` 初始化

### 9. `generate-config.sh` — find 替代 glob 查找
- **问题**: `"${CONFIG_DIR}/platforms/"*"/${TARGET}/_platform.yml"` glob 在某些 bash 设置下（如 nullglob）行为不可预测
- **修复**: 改用 `find "${CONFIG_DIR}/platforms" -path "*/${TARGET}/_platform.yml" -type f` 精确查找

## 语法检查结果

所有 9 个脚本均通过 `bash -n` 语法检查 ✅
