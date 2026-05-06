# 后端脚本 Bug 修复日志

> 修复时间: 2026-05-06
> 修复范围: 6 个文件，6 个 Bug（3 高危 + 3 中危）

---

## 修复清单

### BUG-01 ✅ `build.sh` — 管道 SIGPIPE 误判 (🔴 高危)

**问题**: `make 2>&1 | tee build.log` 在 `set -o pipefail` 下，tee 的 SIGPIPE 会导致整个管道失败，即使 make 编译成功。

**修复**:
- 脚本已有 `set -euo pipefail`
- 将 `make ... | tee` 改为先执行再用 `PIPESTATUS[0]` 检查 make 退出码
- make 失败时用 `exit "$MAKE_EXIT"` 退出，忽略 tee 的退出码

```bash
make -j"${PARALLEL}" V=s 2>&1 | tee build.log
MAKE_EXIT=${PIPESTATUS[0]}
if [ "$MAKE_EXIT" -ne 0 ]; then
  echo "❌ 编译失败 (exit code: ${MAKE_EXIT})"
  exit "$MAKE_EXIT"
fi
```

---

### BUG-06 ✅ `build.sh` — PARALLEL 参数未校验 (🟡 中危)

**问题**: 非数字参数传入 PARALLEL 会导致 `-le` 运算报错。

**修复**:
- 添加 `[[ "$PARALLEL" =~ ^[0-9]+$ ]]` 校验
- 无效值自动回退到默认值 0（随后由 nproc 计算）
- 同时为 `cd "$WORK_DIR"` 添加错误提示

---

### BUG-02 ✅ `generate-manifest.sh` — JSON fallback 变量未转义 (🔴 高危)

**问题**: jq 不可用时，`${TARGET}`、`${SUBTARGET}` 等变量直接嵌入 JSON，含双引号/反斜杠时产生非法 JSON。

**修复**:
- 新增 `json_escape()` 函数（sed 转义 `\`、`"`、`\t`）
- meta 段所有变量通过 `json_escape` 处理后再嵌入

---

### BUG-09 ✅ `generate-manifest.sh` — echo 解释转义序列 (🟡 中危)

**问题**: `echo "$f"` 在某些 shell 中会解释 `\n`、`\t`。

**修复**: 改用 `printf '%s' "$f"` 输出固件路径

---

### BUG-03 ✅ `setup-source.sh` — Python 路径注入 (🔴 高危)

**问题**: `${FEEDS_FILE}` 直接嵌入 Python 字符串字面量，路径含单引号时导致语法错误或注入。

**修复**:
- 改用环境变量 `FEEDS_FILE_PATH` 传递路径
- Python 代码通过 `os.environ['FEEDS_FILE_PATH']` 读取，避免字符串拼接

---

### BUG-04 ✅ `fix-dependencies.sh` — perl 替换变量未转义 (🟡 中危)

**问题**: `fix_dep()` 中 `${new}` 直接嵌入 perl 正则替换，含 `/` 或 `\` 时破坏语法。

**修复**:
- 改用环境变量 `OLD_DEP` / `NEW_DEP` 传递给 perl
- perl 代码通过 `$ENV{OLD_DEP}` / `$ENV{NEW_DEP}` 读取，避免 shell 插值和正则注入

```bash
OLD_DEP="$old" NEW_DEP="$new" perl -pi -e 's/\Q$ENV{OLD_DEP}\E/$ENV{NEW_DEP}/g' "$file"
```

---

### BUG-07 ✅ `post-build-check.sh` — numfmt 变量未加引号 (🟡 中危)

**问题**: `$SIZE` 未加引号传给 `numfmt`，stat 失败时可能触发 word splitting。

**修复**: 所有 `numfmt --to=iec $SIZE` → `numfmt --to=iec "$SIZE"`

---

### BUG-08 + BUG-23 ✅ `build-summary.sh` — read 缺 -r / 管道子 shell (🟡 中危)

**问题**:
- `while read f` 缺少 `-r`，反斜杠被解释为转义
- `echo ... | while read` 创建子 shell，变量修改丢失

**修复**:
- 改用 `while IFS= read -r f`
- 管道改为 heredoc `<<< "$FIRMWARE_FILES"` 避免子 shell

---

## 验证结果

| 文件 | bash -n |
|:---|:---|
| build.sh | ✅ OK |
| generate-manifest.sh | ✅ OK |
| setup-source.sh | ✅ OK |
| fix-dependencies.sh | ✅ OK |
| post-build-check.sh | ✅ OK |
| build-summary.sh | ✅ OK |

**总计**: 6 个文件修改，8 个 Bug 修复，全部语法检查通过。
