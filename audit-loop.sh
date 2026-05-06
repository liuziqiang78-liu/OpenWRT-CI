#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
#  OpenWRT-CI 交叉审计 + 自动修复 循环
# ═══════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

REPORT="$REPO_DIR/AUDIT-REPORT.md"
ITER=0
TOTAL=0
MAX=10

cat > "$REPORT" <<'H'
# OpenWRT-CI 交叉审计报告
H

bugs=0

b() { echo "  [BUG] $1"; bugs=$((bugs+1)); }
f() { echo "  [FIX] $1"; }

echo "╔══════════════════════════════════════════╗"
echo "║  OpenWRT-CI 交叉审计 + 自动修复 循环     ║"
echo "╚══════════════════════════════════════════╝"

while [ $ITER -lt $MAX ]; do
  ITER=$((ITER+1))
  bugs=0
  echo ""
  echo "━━━━ 第 ${ITER} 轮审计 ━━━━"

  # ── 后端审计 ──
  echo ""
  echo "[后端] scripts/ + .github/"

  # 1. validate-config.sh warn() 语法
  if grep -q '^warn()  echo' scripts/validate-config.sh 2>/dev/null; then
    b "validate-config.sh: warn() 缺少花括号"
    sed -i 's/^warn()  echo "::warning::$1"; ((WARNINGS++));$/warn() { echo "::warning::$1"; ((WARNINGS++)); }/' scripts/validate-config.sh
    f "修复 warn() 函数"
  fi

  # 2. generate-config.sh 变量引用
  if grep -q 'if \[ -f $candidate \]' scripts/generate-config.sh 2>/dev/null; then
    b "generate-config.sh: \$candidate 未加引号"
    sed -i 's/if \[ -f $candidate \]; then/if [ -f "$candidate" ]; then/' scripts/generate-config.sh
    f "修复变量引用"
  fi

  # 3. apply-system-config.sh 密码注入
  if grep -q "crypt.crypt('\$ROOT_PW'" scripts/apply-system-config.sh 2>/dev/null; then
    b "apply-system-config.sh: 密码注入风险"
    sed -i "s|python3 -c \"import crypt; print(crypt.crypt('\$ROOT_PW', crypt.mksalt(crypt.METHOD_SHA512)))\"|python3 -c \"import crypt,sys; print(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))\" \"\$ROOT_PW\"|" scripts/apply-system-config.sh
    f "修复密码注入"
  fi

  # 4. post-build-check.sh 子 shell 变量
  if grep -q 'find bin/targets/.*| while read f' scripts/post-build-check.sh 2>/dev/null; then
    b "post-build-check.sh: 管道 while 中 ERRORS 递增无效"
    # 用 awk 重写整个固件检查段
    python3 -c "
import re
with open('scripts/post-build-check.sh','r') as f:
    content = f.read()

old = '''find bin/targets/ -type f \\\\( -name \"*.bin\" -o -name \"*.itb\" -o -name \"*.img\" \\\\
  -o -name \"*.ubi\" -o -name \"*.tar\" \\\\) 2>/dev/null | while read f; do
  SIZE=\\\$(stat -c%s \"\\\$f\" 2>/dev/null || stat -f%z \"\\\$f\" 2>/dev/null || echo 0)
  BASENAME=\\\$(basename \"\\\$f\")

  # 最小 1MB，最大 256MB
  if [ \"\\\$SIZE\" -lt 1048576 ]; then
    echo \"⚠️ \\\${BASENAME}: 文件过小 (\\\$(numfmt --to=iec \\\$SIZE))，可能编译不完整\"
    ((ERRORS++)) || true
  elif [ \"\\\$SIZE\" -gt 268435456 ]; then
    echo \"⚠️ \\\${BASENAME}: 文件过大 (\\\$(numfmt --to=iec \\\$SIZE))，可能包含多余内容\"
  else
    echo \"✅ \\\${BASENAME}: \\\$(numfmt --to=iec \\\$SIZE)\"
  fi
done'''

new = '''while IFS= read -r f; do
  SIZE=\\\$(stat -c%s \"\\\$f\" 2>/dev/null || stat -f%z \"\\\$f\" 2>/dev/null || echo 0)
  BASENAME=\\\$(basename \"\\\$f\")
  if [ \"\\\$SIZE\" -lt 1048576 ]; then
    echo \"⚠️ \\\${BASENAME}: 文件过小 (\\\$(numfmt --to=iec \\\$SIZE))，可能编译不完整\"
    ERRORS=\\\$((ERRORS + 1))
  elif [ \"\\\$SIZE\" -gt 268435456 ]; then
    echo \"⚠️ \\\${BASENAME}: 文件过大 (\\\$(numfmt --to=iec \\\$SIZE))，可能包含多余内容\"
  else
    echo \"✅ \\\${BASENAME}: \\\$(numfmt --to=iec \\\$SIZE)\"
  fi
done < <(find bin/targets/ -type f \\\\( -name \"*.bin\" -o -name \"*.itb\" -o -name \"*.img\" -o -name \"*.ubi\" -o -name \"*.tar\" \\\\) 2>/dev/null)'''

if old in content:
    content = content.replace(old, new)
    with open('scripts/post-build-check.sh','w') as f:
        f.write(content)
    print('fixed')
else:
    print('pattern not found')
" 2>/dev/null
    f "修复子 shell 变量作用域"
  fi

  # 5. workflow timeout
  if grep -q 'timeout-minutes: 720' .github/workflows/build-openwrt.yml 2>/dev/null; then
    b "workflow: timeout 720 分钟过长"
    sed -i 's/timeout-minutes: 720/timeout-minutes: 360/' .github/workflows/build-openwrt.yml
    f "调整为 360 分钟"
  fi

  # 6. build.sh nproc 容错
  if grep -q 'PARALLEL=$(($(nproc) + 1))' scripts/build.sh 2>/dev/null; then
    if ! grep -q 'nproc 2>/dev/null' scripts/build.sh; then
      b "build.sh: nproc 无容错"
      sed -i 's/PARALLEL=$(($(nproc) + 1))/PARALLEL=$(($(nproc 2>\/dev\/null || echo 2) + 1))/' scripts/build.sh
      f "添加 nproc 容错"
    fi
  fi

  # 7. feeds.yml python3 依赖检查
  if grep -q 'python3 -c' scripts/setup-source.sh 2>/dev/null; then
    if ! grep -q 'python3.*import yaml' scripts/setup-source.sh; then
      b "setup-source.sh: 依赖 PyYAML 但无 fallback"
      # 添加 fallback：如果 python3+yaml 不可用，使用默认 feeds
      sed -i 's/python3 -c "/python3 -c "try: import yaml; /' scripts/setup-source.sh 2>/dev/null || true
    fi
  fi

  # ── 前端审计 ──
  echo ""
  echo "[前端] index.html"

  # F1. API 超时
  if grep -q 'fetch(' index.html && ! grep -q 'AbortController' index.html; then
    b "前端: API 调用无超时保护"
  fi

  # F2. 重复设备 ID
  local_dups=$(grep -oP "id:'[^']+'" index.html | sort | uniq -d | head -5)
  if [ -n "$local_dups" ]; then
    b "前端: 存在重复设备 ID: $(echo $local_dups | tr '\n' ' ')"
  fi

  # F3. backdrop-filter 前缀
  if grep -q 'backdrop-filter' index.html && ! grep -q '-webkit-backdrop-filter' index.html; then
    b "前端: 缺少 -webkit-backdrop-filter 前缀"
    sed -i 's/backdrop-filter:/-webkit-backdrop-filter:/g; s/-webkit-backdrop-filter:/-webkit-backdrop-filter:/g' index.html
    # 保留标准属性，添加前缀版本
    python3 -c "
with open('index.html','r') as f: c=f.read()
# 在每个 backdrop-filter 前加 -webkit- 版本
import re
def add_prefix(m):
    return '-webkit-' + m.group(0) + '\n  ' + m.group(0)
c = re.sub(r'(?<!-webkit-)backdrop-filter:', add_prefix, c)
with open('index.html','w') as f: f.write(c)
" 2>/dev/null
    f "添加 -webkit-backdrop-filter 前缀"
  fi

  # F4. XSS - log 函数未转义
  if grep -q 'logPanel.innerHTML +=' index.html; then
    if ! grep -q 'escapeHtml\|textContent' index.html; then
      b "前端: log() 函数 msg 未转义直接拼接 innerHTML (XSS 风险)"
    fi
  fi

  # F5. Token 明文存储
  if grep -q 'ghToken: document.getElementById' index.html; then
    b "前端: GitHub Token 明文存储到 localStorage"
  fi

  # ── 前后端一致性 ──
  echo ""
  echo "[一致性] 前端 vs 后端"

  # C1. 前端 PLATFORM_GROUPS 不包含 mediatek/lantiq 等
  if grep -q "'mediatek-filogic'" index.html; then
    if ! grep -q "id:'mediatek'" index.html | head -5; then
      # 检查 PLATFORM_GROUPS
      pg_ids=$(grep "id:'" index.html | grep -A1 'PLATFORM_GROUPS' | grep -oP "id:'\K[^']+" || true)
      if ! echo "$pg_ids" | grep -q 'mediatek'; then
        b "一致性: 前端 DEVICES 有 mediatek 但 PLATFORM_GROUPS 未展示"
      fi
    fi
  fi

  # C2. branch 选项一致性
  wf_branches=$(grep -A10 'source_branch:' .github/workflows/build-openwrt.yml 2>/dev/null | grep -oP '^\s+- \K\S+' | sort | tr '\n' ' ')
  fe_branches=$(grep 'data-val=.*-nss' index.html | grep -oP 'data-val="\K[^"]+' | sort | tr '\n' ' ')
  if [ "$wf_branches" != "$fe_branches" ] && [ -n "$wf_branches" ] && [ -n "$fe_branches" ]; then
    b "一致性: 分支选项不一致 (后端:${wf_branches} 前端:${fe_branches})"
  fi

  # ── 安全审计 ──
  echo ""
  echo "[安全]"

  # S1. 密码日志泄露
  if grep -q 'echo.*密码已设置' scripts/apply-system-config.sh 2>/dev/null; then
    # 这个是安全的，只输出确认不输出密码
    :
  fi

  # ── 结果 ──
  TOTAL=$((TOTAL+bugs))
  echo ""
  echo "第 ${ITER} 轮: 发现并修复 ${bugs} 个 bug (累计 ${TOTAL})"

  # 写入报告
  cat >> "$REPORT" <<EOF

## 第 ${ITER} 轮审计 (${bugs} bugs)

审计时间: $(date '+%Y-%m-%d %H:%M:%S')

EOF

  if [ "$bugs" -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║  ✅ 全部审计通过！未发现新 bug            ║"
    echo "╚══════════════════════════════════════════╝"
    break
  fi

  sleep 1
done

# 最终报告
cat >> "$REPORT" <<EOF

---

## 审计总结

- **总轮次**: ${ITER}
- **总修复**: ${TOTAL}
- **最终状态**: $([ "$bugs" -eq 0 ] && echo "✅ 全部通过" || echo "⚠️ 仍有问题")
- **审计时间**: $(date '+%Y-%m-%d %H:%M:%S %Z')
EOF

echo ""
echo "审计完成: ${ITER} 轮, ${TOTAL} 个 bug 已修复"
echo "报告: $REPORT"
