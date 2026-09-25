#!/bin/bash
# 用法：
#   ./install.sh                自动检测 ~/.claude 与 ~/.codex，各自安装（全局）
#   ./install.sh claude         只装 Claude Code 全局
#   ./install.sh codex          只装 Codex 全局
#   ./install.sh project [目录]  装到一个仓库里（默认当前目录）：AGENTS.md 与 .claude/{settings.json,agents,hooks}，云端或 Cowork 会话也能拿到强制层
# 行为：
#   - 规则正文以带标记的段落追加进已有的规则文件，再次安装时原位更新，不整体替换
#   - settings.json 用 jq 合并：env、model、effortLevel 缺键才写，hook 不重复追加；config.toml 缺键才追加，结果必须仍是合法 TOML
#   - 任何将被修改或覆盖的文件先备份为 <文件>.bak.<时间戳>
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-all}"
stamp="$(date +%Y%m%d%H%M%S)"
BEGIN='<!-- agent-rules:begin -->'
END='<!-- agent-rules:end -->'
enforced=()

need() { command -v "$1" >/dev/null 2>&1 || { echo "缺少 $1：$2" >&2; exit 2; }; }
backup() { if [ -f "$1" ]; then cp -p "$1" "$1.bak.$stamp"; echo "  备份 $1 -> $1.bak.$stamp"; fi; }
install_file() { # 源 目标 权限
  if [ -f "$2" ] && ! cmp -s "$1" "$2"; then backup "$2"; fi
  mkdir -p "$(dirname "$2")"; cp "$1" "$2"; chmod "$3" "$2"
}

write_rules() { # 目标文件 适配层...
  local t="$1"; shift
  local block; block=$(mktemp)
  { echo "$BEGIN"; cat "$here/AGENTS.md"; for a in "$@"; do cat "$here/adapters/$a/mapping.md"; done; echo "$END"; } > "$block"
  mkdir -p "$(dirname "$t")"
  if [ -f "$t" ]; then
    if grep -qF "$BEGIN" "$t" && grep -qF "$END" "$t"; then
      awk -v b="$BEGIN" -v e="$END" -v f="$block" '
        $0==b { while ((getline l < f) > 0) print l; skip=1; next }
        $0==e { skip=0; next }
        !skip { print }' "$t" > "$t.new"
      if cmp -s "$t.new" "$t"; then rm -f "$t.new" "$block"; echo "  $t 已是最新"; return; fi
      backup "$t"; mv "$t.new" "$t"; echo "  $t：已原位更新标记段落"
    else
      backup "$t"; { echo; cat "$block"; } >> "$t"
      echo "  $t：已在末尾追加标记段落，原有内容保留，请检查是否与本规则冲突"
    fi
  else
    cp "$block" "$t"; echo "  $t：已创建"
  fi
  rm -f "$block"
}

merge_settings() { # 文件 hook命令 是否写主会话档位(1/0)
  local f="$1" hook="$2" wm="$3" out
  mkdir -p "$(dirname "$f")"; [ -f "$f" ] || echo '{}' > "$f"
  out=$(mktemp)
  if ! jq --arg hook "$hook" --argjson wm "$wm" '
      .env = ({"CLAUDE_CODE_SUBAGENT_MODEL":"sonnet","CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS":"3"} + (.env // {}))
      | (if $wm == 1 then (.model //= "sonnet" | .effortLevel //= "medium") else . end)
      | .hooks = (.hooks // {})
      | .hooks.PreToolUse = ((.hooks.PreToolUse // [])
          | if any(.[]; ((.hooks // []) | any(.[]; .command == $hook))) then .
            else . + [{"matcher":"Bash","hooks":[{"type":"command","command":$hook}]}] end)
    ' "$f" > "$out" 2>/dev/null; then
    rm -f "$out"; echo "  $f 不是合法 JSON，未修改；请手动合并 adapters/claude-code/settings.snippet.json" >&2; return 1
  fi
  if cmp -s "$out" "$f"; then rm -f "$out"; echo "  $f 已是最新"; else backup "$f"; mv "$out" "$f"; echo "  $f：已合并 env、hook$([ "$wm" = 1 ] && echo '、model、effortLevel')，已有的值保留"; fi
}

merge_codex_config() { # 文件
  local f="$1"; mkdir -p "$(dirname "$f")"
  command -v python3 >/dev/null 2>&1 || { echo "  缺少 python3，未合并 $f；请手动合并 adapters/codex/config.snippet.toml" >&2; return 1; }
  python3 - "$f" "$stamp" <<'PY' || { echo "  未能合并 $f，请手动合并 adapters/codex/config.snippet.toml" >&2; return 1; }
import sys, re, os, shutil
try:
    import tomllib
except ImportError:
    print("  python3 缺少 tomllib（需要 3.11+）", file=sys.stderr); sys.exit(1)
path, stamp = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
cfg = tomllib.loads(text)
top = {"model_reasoning_effort": 'model_reasoning_effort = "medium"'}
tables = {
    "features": {"multi_agent": "multi_agent = true"},
    "agents": {"default_subagent_reasoning_effort": 'default_subagent_reasoning_effort = "medium"',
               "max_concurrent_threads_per_session": "max_concurrent_threads_per_session = 3",
               "max_depth": "max_depth = 1"},
}
lines = text.split("\n") if text else []
changed = []
missing_top = [v for k, v in top.items() if k not in cfg]
if missing_top:
    idx = next((i for i, l in enumerate(lines) if re.match(r"\s*\[", l)), len(lines))
    lines[idx:idx] = missing_top + ([""] if idx < len(lines) else [])
    changed += [v.split(" =")[0] for v in missing_top]
for tname, keys in tables.items():
    existing = cfg.get(tname)
    if existing is not None and not isinstance(existing, dict):
        print(f"  {tname} 不是表，跳过", file=sys.stderr); continue
    missing = [v for k, v in keys.items() if k not in (existing or {})]
    if not missing: continue
    hdr = next((i for i, l in enumerate(lines) if re.match(r"\s*\[" + tname + r"\]\s*(#.*)?$", l)), None)
    if hdr is None:
        if existing is not None:
            print(f"  {tname} 以非表头形式定义，无法安全追加，请手动加入：" + "; ".join(missing), file=sys.stderr); continue
        if lines and lines[-1].strip(): lines.append("")
        lines += [f"[{tname}]"] + missing
    else:
        lines[hdr + 1:hdr + 1] = missing
    changed += [f"{tname}.{v.split(' =')[0]}" for v in missing]
if not changed:
    print(f"  {path} 已是最新"); sys.exit(0)
new = "\n".join(lines)
if not new.endswith("\n"): new += "\n"
tomllib.loads(new)
if os.path.exists(path):
    shutil.copy2(path, f"{path}.bak.{stamp}"); print(f"  备份 {path} -> {path}.bak.{stamp}")
open(path, "w", encoding="utf-8").write(new)
print(f"  {path}：已追加 " + "、".join(changed))
PY
}

install_claude() {
  need jq "hook 与 settings.json 合并都需要它（macOS: brew install jq；Debian/Ubuntu: apt install jq）"
  echo "Claude Code（全局）："
  write_rules "$HOME/.claude/CLAUDE.md" claude-code
  for f in "$here"/adapters/claude-code/agents/*.md; do install_file "$f" "$HOME/.claude/agents/$(basename "$f")" 644; done
  install_file "$here/scripts/run-quiet.sh" "$HOME/.claude/hooks/run-quiet" 755
  install_file "$here/adapters/claude-code/hooks/filter-test-output.sh" "$HOME/.claude/hooks/filter-test-output.sh" 755
  echo "  已安装 agents：Explore(haiku)、test-runner、reviewer；hooks：filter-test-output、run-quiet"
  if merge_settings "$HOME/.claude/settings.json" "$HOME/.claude/hooks/filter-test-output.sh" 1; then
    enforced+=("Claude Code：主会话 model=sonnet、effortLevel=medium，子 agent 默认 sonnet，并发上限 3，测试/构建输出经 hook 裁剪（已有的设置值保留）")
  fi
}

install_codex() {
  echo "Codex CLI（全局）："
  write_rules "$HOME/.codex/AGENTS.md" codex
  for f in "$here"/adapters/codex/agents/*.toml; do install_file "$f" "$HOME/.codex/agents/$(basename "$f")" 644; done
  echo "  已安装 agents：explorer(low)、test-runner(medium)、reviewer(medium)"
  if merge_codex_config "$HOME/.codex/config.toml"; then
    enforced+=("Codex：主会话 medium，多 agent 开启，子 agent 默认 medium，并发 3，嵌套 1（缺键才写）")
  fi
}

install_project() {
  need jq "hook 与 settings.json 合并都需要它"
  local dir; dir="$(cd "${1:-.}" && pwd)"
  echo "项目（$dir）："
  write_rules "$dir/AGENTS.md" claude-code codex
  for f in "$here"/adapters/claude-code/agents/*.md; do install_file "$f" "$dir/.claude/agents/$(basename "$f")" 644; done
  install_file "$here/scripts/run-quiet.sh" "$dir/.claude/hooks/run-quiet" 755
  install_file "$here/adapters/claude-code/hooks/filter-test-output.sh" "$dir/.claude/hooks/filter-test-output.sh" 755
  if merge_settings "$dir/.claude/settings.json" '"$CLAUDE_PROJECT_DIR"/.claude/hooks/filter-test-output.sh' 0; then
    enforced+=("项目：.claude/settings.json 的 env 与 hook（主会话档位不写进团队共用的项目设置）")
  fi
  for f in "$here"/adapters/codex/agents/*.toml; do install_file "$f" "$dir/.codex/agents/$(basename "$f")" 644; done
  echo "  提示：项目级与全局二选一，两者都装时正文会被加载两次；Codex 项目级 config 请按 adapters/codex/config.snippet.toml 手动合并"
}

case "$target" in
  claude) install_claude ;;
  codex) install_codex ;;
  project) install_project "${2:-.}" ;;
  all)
    found=0
    if [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; then install_claude; found=1; fi
    if [ -d "$HOME/.codex" ] || command -v codex >/dev/null 2>&1; then install_codex; found=1; fi
    [ "$found" = 1 ] || { echo "没有检测到 ~/.claude 或 ~/.codex；指定目标：./install.sh claude | codex | project [目录]"; exit 1; }
    ;;
  *) echo "用法：./install.sh [claude|codex|project [目录]|all]" >&2; exit 2 ;;
esac

echo
echo "已由配置或脚本强制生效："
for e in ${enforced[@]+"${enforced[@]}"}; do echo "  - $e"; done
echo "仍只靠模型遵守提示词："
echo "  - 规则正文：派发门槛、两次失败即停、输出裁剪习惯、流程步骤、脱敏"
echo "注意：hook 会把清单内的单行测试/构建命令改写为经 run-quiet 执行并自动放行（permissionDecision=allow）。"
