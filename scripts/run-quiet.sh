#!/bin/bash
# 用法：run-quiet <命令> [参数...]      复合命令：run-quiet bash -c "cd 目录 && npm test"
# 运行命令，完整输出落盘（mktemp，多个并行运行互不覆盖）。
# 输出不超过 80 行时原样打印（过滤再回读反而更贵）；否则只打印失败行（各带 4 行上下文，最多 120 行）、末尾 8 行与退出码。
# 不依赖任何 agent 终端，Claude Code、Codex 等都可直接调用；Claude Code 的 hook 也是调用本脚本。
set -u
if [ $# -eq 0 ]; then echo "usage: run-quiet <command> [args...]" >&2; exit 2; fi
log=$(mktemp "${TMPDIR:-/tmp}/run-quiet.XXXXXX") || exit 2
"$@" >"$log" 2>&1; ec=$?
total=$(wc -l <"$log" | tr -d ' ')
if [ "$total" -le "${RUN_QUIET_FULL_LINES:-80}" ]; then
  cat "$log"
else
  # 覆盖：go test/jest/vitest 的 FAIL，pytest 的 FAILED/E 行/Traceback，tsc 的 error TS，eslint 的 "行:列  error"，go build 的 file.go:行:列，
  # rust 的 error[E]/panicked，jest 的 Expected/Received，TAP 的 not ok，以及通用的 Error/ERROR/error:
  pat='(FAIL|FAILED|ERROR|Error|error\[|error:|error TS[0-9]+|^[^ :]+\.go:[0-9]+:[0-9]+:|^ *[0-9]+:[0-9]+ +error |panic|Traceback|AssertionError|^E {3}|Expected:|Received:|not ok)'
  matches=$(grep -nE -A 4 "$pat" "$log")
  mcount=$(printf '%s\n' "$matches" | grep -c .)
  if [ "$mcount" -gt 0 ]; then printf '%s\n' "$matches" | head -n 120; fi
  if [ "$mcount" -gt 120 ]; then echo "[匹配行共 $mcount 行，只显示前 120 行]"; fi
  echo '--- tail ---'; tail -n 8 "$log"
fi
echo "[exit=$ec] 共 $total 行，完整输出: $log"
exit $ec
