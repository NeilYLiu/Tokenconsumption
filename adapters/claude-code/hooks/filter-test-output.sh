#!/bin/bash
# PreToolUse hook（matcher: Bash）。
# 把"单纯的测试 / 构建命令"改写成：完整输出落盘，只把失败行与末尾摘要回传给模型。
# 只处理形如 [cd <dir> &&] <runner> [args] 的简单命令；含管道、分号、重定向、变量展开的命令原样放行。
# 依赖：bash、jq。把想过滤的命令加进下面的 runner 列表即可。
set -u
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$cmd" ]; then echo '{}'; exit 0; fi

prefix='^(cd [^;&|`$<>]+ && )?'
runner='(npm (test|run (test|build|lint|typecheck))|pnpm (test|build|lint)|yarn (test|build|lint)|npx (jest|vitest|tsc)|jest|vitest|tsc|pytest|python3? -m pytest|go (test|build|vet)|cargo (test|build|check|clippy)|mvn (test|package|verify)|(\./)?gradlew? (test|build)|make (test|check)|dotnet (test|build)|bundle exec rspec|rspec|phpunit)'
args='( [^;&|`$<>]*)?$'

if printf '%s\n' "$cmd" | grep -Eq "${prefix}${runner}${args}"; then
  log="${TMPDIR:-/tmp}/claude-cmd-out.log"
  filtered="( $cmd ) >\"$log\" 2>&1; ec=\$?; grep -nE -A 4 '(FAIL|FAILED|ERROR|Error|error\\[|error:|panic:|Traceback|AssertionError|not ok)' \"$log\" | head -n 120; echo '--- tail ---'; tail -n 8 \"$log\"; echo \"[exit=\$ec] full output: $log\"; exit \$ec"
  printf '%s' "$input" | jq -c --arg f "$filtered" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",updatedInput:(.tool_input + {command:$f})}}'
else
  echo '{}'
fi
