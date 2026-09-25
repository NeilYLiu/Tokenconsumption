# 编码 agent 全局调用规则（开发 / 修复过程，额度优先）

一套**跨终端的全局规则**，约束编码 agent 在开发与 bug 修复过程中什么时候派子 agent、怎么派、主会话怎么用工具、怎么管会话。
目标：**在保证完成任务的前提下，把额度（token）用量压到最低。**
适用于 Claude Code、Codex CLI 以及其他读取 AGENTS.md 的编码 agent；规则正文不绑定任何一家供应商。

## 结构：一份通用正文，多个适配层

| 层 | 文件 | 内容 |
| --- | --- | --- |
| 通用正文 | `AGENTS.md` | 全部规则，只用通用说法（子 agent、小模型 / 中档模型 / 主模型、新开会话、压缩上下文），不含任何厂商的工具名、模型名、命令名 |
| 通用脚本 | `scripts/run-quiet.sh` | 跑测试或构建，完整输出落盘，只打印失败行、末尾摘要与退出码；任何终端都能调用 |
| Claude Code 适配 | `adapters/claude-code/` | `mapping.md` 术语映射；`agents/` 三个子 agent 定义（Explore 覆盖为 haiku 只读，test-runner、reviewer 用 sonnet）；`settings.snippet.json` 子 agent 默认 sonnet、并发上限 3、挂 hook；`hooks/filter-test-output.sh` 自动裁剪测试输出 |
| Codex 适配 | `adapters/codex/` | `mapping.md` 术语映射；`agents/explorer.toml` 只读低强度的探索角色；`config.snippet.toml` 推理强度与子 agent 并发、嵌套限制 |
| 安装 | `install.sh` | 把通用正文和对应终端的术语映射拼成该终端的全局规则文件，复制子 agent 定义与脚本；已有文件先备份 |
| 评审 | `REVIEW.md` | 评审前提、额度来源框架、问题清单与修正、有意不做的事、验证方法 |

规则正文只维护 `AGENTS.md` 这一份。改规则后重跑 `install.sh` 即可同步到各终端。

## 安装

```bash
git clone https://github.com/NeilYLiu/Tokenconsumption.git && cd Tokenconsumption
./install.sh            # 自动检测 ~/.claude 与 ~/.codex 并各自安装；也可 ./install.sh claude 或 ./install.sh codex
```

| 终端 | 安装后的全局规则文件 | 还需手动合并 |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` = `AGENTS.md` + Claude 映射 | `adapters/claude-code/settings.snippet.json` 的 env 与 hooks 两段 → `~/.claude/settings.json` |
| Codex CLI | `~/.codex/AGENTS.md` = `AGENTS.md` + Codex 映射 | `adapters/codex/config.snippet.toml` → `~/.codex/config.toml` |
| 其他终端 | 把 `AGENTS.md` 复制到该工具的全局指令文件，按需补一张术语映射表 | 无 |

项目级使用：把 `AGENTS.md` 放到仓库根目录即可，Claude Code 与 Codex 都会读取。hook 与脚本需要 bash、jq。

验证：Claude Code 里 `/context` 应列出 `~/.claude/CLAUDE.md`，`/agents` 应看到 Explore、test-runner、reviewer，`/hooks` 应有 filter-test-output；Codex 里 `/status` 可看到模型、推理强度与 token 用量。

## 评审前提

评审开始时本仓库为空，云端会话里也没有既有的全局规则文件，所以评审对象是各编码 agent 在没有全局规则时的默认行为，依据见 `REVIEW.md`。
如果你本机已有一份全局规则，push 上来后可以逐条对照。

## 用户侧还要做的三件事（规则文件管不到）

1. **强度**：默认中档，只在设计和疑难调试时调高。Claude Code 用 `/effort`；Codex 用 `model_reasoning_effort`。思考 token 按输出计费。
2. **模型**：主会话默认中档模型，设计决策与复杂推理再切高档。子 agent 默认继承主会话模型，主会话越贵，每次派发越贵。
3. **会话**：无关任务之间新开会话（Claude Code `/clear`，Codex `/new`）；空闲超过一小时缓存失效，回来先做小事；定期看额度归因与上下文占用（Claude Code `/usage`、`/context`，Codex `/status`）。
