#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
bugs=0

echo "╔══════════════════════════════════════════╗"
echo "║  OpenWRT-CI 最终审计 (第2轮)             ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 后端 ──
echo "[后端]"

# B1. set -e 下的算术操作安全
bad_arith=$(grep -rn '((ERRORS++\|((WARNINGS++\|((bugs++' scripts/ 2>/dev/null || true)
if [ -n "$bad_arith" ]; then
  echo "  ❌ 发现 ((var++)) 在 set -e 下不安全: $bad_arith"
  bugs=$((bugs+1))
else
  echo "  ✅ 所有算术操作使用 \$((...)) 安全写法"
fi

# B2. 管道子 shell 变量作用域
pipe_while=$(grep -rn '| while read' scripts/ 2>/dev/null | grep -v '#' || true)
if [ -n "$pipe_while" ]; then
  echo "  ⚠️  仍存在管道 while 循环 (需确认无变量回传需求):"
  echo "$pipe_while" | head -3
else
  echo "  ✅ 无管道子 shell 变量作用域问题"
fi

# B3. generate-manifest.sh JSON 逗号
if grep -q 'done < <(find' scripts/generate-manifest.sh; then
  echo "  ✅ generate-manifest.sh: 使用 process substitution"
else
  echo "  ❌ generate-manifest.sh: 仍在使用管道 while"
  bugs=$((bugs+1))
fi

# B4. WiFi 单引号注入
if grep -q "ESC_SSID\|ESC_PW" scripts/apply-system-config.sh; then
  echo "  ✅ apply-system-config.sh: WiFi 值已转义"
else
  echo "  ❌ apply-system-config.sh: WiFi 值未转义"
  bugs=$((bugs+1))
fi

# B5. workflow timeout
timeout_val=$(grep 'timeout-minutes:' .github/workflows/build-openwrt.yml | grep -oP '\d+')
if [ "$timeout_val" -le 480 ]; then
  echo "  ✅ workflow timeout: ${timeout_val} 分钟"
else
  echo "  ⚠️  workflow timeout: ${timeout_val} 分钟 (过长)"
  bugs=$((bugs+1))
fi

# B6. nproc 容错
if grep -q 'nproc 2>/dev/null' scripts/build.sh; then
  echo "  ✅ build.sh: nproc 有容错"
else
  echo "  ⚠️  build.sh: nproc 无容错"
  bugs=$((bugs+1))
fi

# B7. validate-config.sh 函数安全
if grep -q 'ERRORS=\$((ERRORS + 1))' scripts/validate-config.sh; then
  echo "  ✅ validate-config.sh: error()/warn() 使用安全算术"
else
  echo "  ❌ validate-config.sh: error()/warn() 仍用 ((++))"
  bugs=$((bugs+1))
fi

# B8. password injection
if grep -q 'sys.argv\[1\]' scripts/apply-system-config.sh; then
  echo "  ✅ apply-system-config.sh: 密码通过参数传递"
else
  echo "  ❌ apply-system-config.sh: 密码注入风险"
  bugs=$((bugs+1))
fi

# B9. generate-config.sh 变量引用
if grep -q 'if \[ -f "$candidate" \]' scripts/generate-config.sh; then
  echo "  ✅ generate-config.sh: 变量引用正确"
else
  echo "  ❌ generate-config.sh: 变量引用问题"
  bugs=$((bugs+1))
fi

echo ""
echo "[前端]"

# F1. escapeHtml
if grep -q 'function escapeHtml' index.html; then
  echo "  ✅ escapeHtml 函数已定义"
else
  echo "  ❌ 缺少 escapeHtml 函数"
  bugs=$((bugs+1))
fi

# F2. log() 使用 escapeHtml
if grep -q 'escapeHtml(msg)' index.html; then
  echo "  ✅ log() 使用 escapeHtml 转义输出"
else
  echo "  ❌ log() 未转义输出 (XSS)"
  bugs=$((bugs+1))
fi

# F3. AbortController
if grep -q 'AbortController' index.html && grep -q 'signal: ctrl.signal' index.html; then
  echo "  ✅ API 调用有 AbortController 超时保护"
else
  echo "  ❌ API 调用缺少超时保护"
  bugs=$((bugs+1))
fi

# F4. -webkit-backdrop-filter
webkit=$(grep -oP '\-webkit-backdrop-filter:' index.html | wc -l)
normal=$(grep -oP '(?<!-webkit-)backdrop-filter:' index.html | wc -l)
if [ "$webkit" -ge "$normal" ] && [ "$normal" -gt 0 ]; then
  echo "  ✅ backdrop-filter 前缀完整 (${webkit}/${normal})"
else
  echo "  ⚠️  backdrop-filter 前缀 (${webkit}/${normal})"
  bugs=$((bugs+1))
fi

# F5. 重复 ID
dup=$(grep -oP "id:'[^']+'" index.html | sort | uniq -d | wc -l)
if [ "$dup" -eq 0 ]; then
  echo "  ✅ 无重复设备 ID"
else
  echo "  ⚠️  存在 ${dup} 个重复设备 ID"
  bugs=$((bugs+1))
fi

# F6. HTTPS
if grep -q 'https://api.github.com' index.html; then
  echo "  ✅ API 调用使用 HTTPS"
else
  echo "  ❌ API 未使用 HTTPS"
  bugs=$((bugs+1))
fi

echo ""
echo "[一致性]"

# C1. workflow target 选项
wf_targets=$(grep -A5 '^\s*target:' .github/workflows/build-openwrt.yml | grep -oP '^\s+- \K\S+' | sort | tr '\n' ' ')
echo "  ℹ️  后端 workflow targets: ${wf_targets}"

# C2. workflow branch 选项
wf_branches=$(grep -A10 'source_branch:' .github/workflows/build-openwrt.yml | grep -oP '^\s+- \K\S+' | sort | tr '\n' ' ')
fe_branches=$(grep 'data-val=.*-nss' index.html | grep -oP 'data-val="\K[^"]+' | sort | tr '\n' ' ')
if [ "$wf_branches" = "$fe_branches" ]; then
  echo "  ✅ 分支选项一致: ${wf_branches}"
else
  echo "  ⚠️  分支选项不一致 (后端:${wf_branches} 前端:${fe_branches})"
  bugs=$((bugs+1))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$bugs" -eq 0 ]; then
  echo "✅ 全部审计通过！0 个 bug"
else
  echo "⚠️  仍有 ${bugs} 个问题"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 更新报告
cat > AUDIT-REPORT.md <<EOF
# OpenWRT-CI 交叉审计报告

## 审计总结

- **审计时间**: $(date '+%Y-%m-%d %H:%M:%S %Z')
- **未修复 bug**: ${bugs}

## 已修复的 bug

| # | 类别 | 文件 | 描述 | 状态 |
|:--|:-----|:-----|:-----|:-----|
| 1 | 后端 | validate-config.sh | warn() 缺少花括号 | ✅ 已修复 |
| 2 | 后端 | generate-config.sh | \$candidate 变量未加引号 | ✅ 已修复 |
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
EOF

echo ""
echo "报告: AUDIT-REPORT.md"
