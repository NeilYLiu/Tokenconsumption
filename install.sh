#!/bin/bash
# 用法：./install.sh [claude|codex|all]    默认 all：只安装本机检测到的终端
# 做的事：把通用规则 AGENTS.md 与对应终端的术语映射拼成该终端的全局规则文件，复制子 agent 定义与脚本。
# 不自动改 settings.json / config.toml，避免覆盖你的设置；已有的规则文件先备份为 .bak.<时间戳>。
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
target="${1:-all}"
stamp="$(date +%Y%m%d%H%M%S)"

backup() { if [ -f "$1" ]; then cp "$1" "$1.bak.$stamp"; echo "已备份 $1 -> $1.bak.$stamp"; fi; }
assemble() { cat "$here/AGENTS.md"; cat "$here/adapters/$1/mapping.md"; }

install_shared() {
  mkdir -p ~/.local/bin
  cp "$here/scripts/run-quiet.sh" ~/.local/bin/run-quiet && chmod +x ~/.local/bin/run-quiet
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "提示：~/.local/bin 不在 PATH 里，run-quiet 需要加进 PATH 才能直接调用";; esac
}

install_claude() {
  mkdir -p ~/.claude/agents ~/.claude/hooks
  backup ~/.claude/CLAUDE.md
  assemble claude-code > ~/.claude/CLAUDE.md
  cp "$here"/adapters/claude-code/agents/*.md ~/.claude/agents/
  cp "$here/adapters/claude-code/hooks/filter-test-output.sh" ~/.claude/hooks/ && chmod +x ~/.claude/hooks/filter-test-output.sh
  echo "Claude Code：已写入 ~/.claude/CLAUDE.md、~/.claude/agents/、~/.claude/hooks/"
  echo "  还需手动：把 adapters/claude-code/settings.snippet.json 的 env 与 hooks 两段合并进 ~/.claude/settings.json"
}

install_codex() {
  mkdir -p ~/.codex/agents
  backup ~/.codex/AGENTS.md
  assemble codex > ~/.codex/AGENTS.md
  cp "$here"/adapters/codex/agents/*.toml ~/.codex/agents/
  echo "Codex：已写入 ~/.codex/AGENTS.md、~/.codex/agents/"
  echo "  还需手动：把 adapters/codex/config.snippet.toml 合并进 ~/.codex/config.toml"
}

install_shared
case "$target" in
  claude) install_claude ;;
  codex) install_codex ;;
  all)
    found=0
    if [ -d ~/.claude ] || command -v claude >/dev/null 2>&1; then install_claude; found=1; fi
    if [ -d ~/.codex ] || command -v codex >/dev/null 2>&1; then install_codex; found=1; fi
    [ "$found" = 1 ] || echo "没有检测到 ~/.claude 或 ~/.codex；指定目标：./install.sh claude 或 ./install.sh codex"
    ;;
  *) echo "用法：./install.sh [claude|codex|all]" >&2; exit 2 ;;
esac
