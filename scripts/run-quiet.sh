#!/bin/bash
# 用法：run-quiet.sh <命令> [参数...]
# 运行命令，完整输出落盘，只打印失败行、末尾摘要和退出码。不依赖任何 agent 终端，Claude Code、Codex 等都可直接调用。
# 复合命令请用：run-quiet.sh bash -c "cd 目录 && npm test"
set -u
if [ $# -eq 0 ]; then echo "usage: run-quiet.sh <command> [args...]" >&2; exit 2; fi
log="${RUN_QUIET_LOG:-${TMPDIR:-/tmp}/run-quiet.log}"
"$@" >"$log" 2>&1; ec=$?
grep -nE -A 4 '(FAIL|FAILED|ERROR|Error|error\[|error:|panic:|Traceback|AssertionError|not ok)' "$log" | head -n 120
echo '--- tail ---'; tail -n 8 "$log"
echo "[exit=$ec] full output: $log"
exit $ec
