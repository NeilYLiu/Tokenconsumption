# Claude Code 全局 agent 调用规则（开发 / 修复过程，额度优先）

这个仓库存放一套 Claude Code 的**用户级全局规则**，约束开发与 bug 修复过程中什么时候派子 agent、怎么派、主会话怎么用工具。
目标：**在保证完成任务的前提下，把额度（token）用量压到最低。**

规则正文是 [CLAUDE.md](CLAUDE.md)，安装后对所有项目生效。评审结论与每条规则的依据见 [REVIEW.md](REVIEW.md)。

## 评审前提

评审开始时本仓库为空，云端会话里也没有 `~/.claude/CLAUDE.md`，没有一份既有的规则文件可以逐条修改。
评审对象因此是 **Claude Code 在没有全局规则约束时的默认 agent 调用行为**（依据 2026-09-25 的官方文档），修正结果直接写成本仓库里的文件。
如果你本机已有一份全局规则，把它 push 到本仓库后可以再做逐条对照。

## 文件

| 文件 | 作用 | 安装位置 |
| --- | --- | --- |
| `CLAUDE.md` | 全局规则正文，72 行，每个会话都会加载 | `~/.claude/CLAUDE.md` |
| `agents/Explore.md` | 覆盖内置 Explore：只读搜索改用 haiku、低强度，限制轮数与返回长度 | `~/.claude/agents/Explore.md` |
| `agents/test-runner.md` | 跑测试或构建，只把失败与摘要带回主会话（sonnet） | `~/.claude/agents/test-runner.md` |
| `agents/reviewer.md` | 单个 reviewer 只查正确性，替代"多维度评审"（sonnet） | `~/.claude/agents/reviewer.md` |
| `settings/settings.snippet.json` | 子 agent 默认模型降为 sonnet、并发上限 3、挂上测试输出过滤 hook | 合并进 `~/.claude/settings.json` |
| `hooks/filter-test-output.sh` | PreToolUse hook：单纯的测试或构建命令只回传失败与摘要，完整日志落盘 | `~/.claude/hooks/filter-test-output.sh` |
| `REVIEW.md` | 评审报告：问题清单、额度影响、对应修正、有意不做的事 | 不需要安装 |

## 安装

```bash
git clone https://github.com/NeilYLiu/Tokenconsumption.git && cd Tokenconsumption
mkdir -p ~/.claude/agents ~/.claude/hooks
cp CLAUDE.md ~/.claude/CLAUDE.md            # 已有则手动合并
cp agents/*.md ~/.claude/agents/
cp hooks/filter-test-output.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/filter-test-output.sh
# 把 settings/settings.snippet.json 里的 env 与 hooks 两段合并进 ~/.claude/settings.json
```

hook 需要 bash 和 jq。验证：新开一个会话，`/context` 的 Memory files 里应列出 `~/.claude/CLAUDE.md`；
`/agents` 里应看到 Explore（haiku）、test-runner、reviewer；`/hooks` 的 PreToolUse 里应有 filter-test-output。

## 用户侧还要做的三件事（规则文件管不到）

1. **强度**：`/effort` 默认 medium，只在设计和疑难调试时调到 high 以上。思考 token 按输出计费；Opus 5.5 与 Fable 系列不能关闭思考，只能靠强度控制。
2. **模型**：主会话默认 sonnet，设计决策与复杂推理再用 `/model` 切到 opus 或 fable。子 agent 默认继承主会话模型，主会话越贵，每次派发越贵。
3. **会话**：无关任务之间 `/clear`（免费）；空闲超过 1 小时缓存失效，回来先做小事；定期看 `/usage` 的归因（subagent、MCP、skill 各占多少）和 `/context`。

## 适用范围

`CLAUDE.md` 第三到第六节的流程规则不依赖 Claude Code 特性，可以原样放进 `AGENTS.md` 供其他编码 agent（如 Codex）使用；
第一、二节和 `agents/`、`hooks/`、`settings/` 是 Claude Code 专有的。
