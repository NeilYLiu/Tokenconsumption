#!/bin/bash
# PreToolUse hook（matcher: Bash）。把"单纯的测试 / 构建 / 检查命令"改写为经同目录的 run-quiet 执行：
# 完整输出落盘，模型只看到失败行与摘要（不超过 80 行的输出原样返回）。
# 只处理形如 [cd <目录> &&] <runner> [参数] 的单行简单命令；多行命令、含管道、分号、重定向、反引号、$ 展开的命令原样放行。
# 注意：被改写的命令会以 permissionDecision=allow 自动放行，等于对清单内的测试/构建命令免审批。
# 依赖：jq，以及与本脚本同目录的 run-quiet。缺任一项则原样放行并在 stderr 提示；install.sh 安装时会检查。
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rq="$here/run-quiet"
input=$(cat)
if ! command -v jq >/dev/null 2>&1; then echo "filter-test-output: 缺少 jq，本次未裁剪" >&2; echo '{}'; exit 0; fi
if [ ! -x "$rq" ]; then echo "filter-test-output: 找不到 $rq，本次未裁剪" >&2; echo '{}'; exit 0; fi
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$cmd" ]; then echo '{}'; exit 0; fi
case "$cmd" in *$'\n'*|*$'\r'*) echo '{}'; exit 0;; esac

prefix='^(cd [^;&|`$<>]+ && )?'
scripts='(test|build|lint|typecheck|check|ci|verify|e2e|coverage)[a-z0-9:_-]*'
runner="(npm (test|run $scripts)|(pnpm|yarn|bun) (test|run $scripts)|npx (jest|vitest|tsc|eslint|playwright test)|jest|vitest|tsc|eslint|(uv|poetry) run (pytest|ruff|mypy|pyright)|pytest|python3? -m pytest|ruff (check|format --check)|mypy|pyright|go (test|build|vet)|cargo (test|build|check|clippy)|mvn (test|package|verify)|(\./)?gradlew? (test|build|check)|make (test|check|lint)|dotnet (test|build)|bundle exec rspec|rspec|phpunit)"
args='( [^;&|`$<>]*)?$'

if printf '%s\n' "$cmd" | grep -Eq "${prefix}${runner}${args}"; then
  esc=${cmd//\'/\'\\\'\'}
  printf '%s' "$input" | jq -c --arg f "\"$rq\" bash -c '$esc'" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",updatedInput:(.tool_input + {command:$f})}}'
else
  echo '{}'
fi
