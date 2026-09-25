# 编码 agent 全局调用规则（开发 / 修复过程，额度优先）

一套**跨终端的全局规则**，约束编码 agent 在开发与 bug 修复过程中什么时候派子 agent、怎么派、主会话怎么用工具、怎么管会话。
目标：**在保证完成任务的前提下，把额度（token）用量压到最低。**
适用于 Claude Code、Codex CLI 以及其他读取 AGENTS.md 的编码 agent；规则正文不绑定任何一家供应商。

对这套工作方式本身的评价（六个视角独立评审、逐条对抗核验）见 [EVALUATION.md](EVALUATION.md)，评审依据见 [REVIEW.md](REVIEW.md)。
评价里指出的问题已按其修订清单修掉，记录在 EVALUATION.md 末尾。

## 结构：一份通用正文，多个适配层

| 层 | 文件 | 内容 |
| --- | --- | --- |
| 通用正文 | `AGENTS.md` | 全部规则，只用通用说法（子 agent、小模型 / 中档模型 / 主模型、新开会话、压缩上下文），不含任何厂商的工具名、模型名、命令名 |
| 通用脚本 | `scripts/run-quiet.sh` | 包装测试或构建命令：完整输出落盘，不超过 80 行原样打印，否则只打印失败行、末尾摘要与退出码。任何终端都能调用 |
| Claude Code 适配 | `adapters/claude-code/` | `mapping.md` 术语映射；`agents/` 三个子 agent（Explore 覆盖为 haiku 只读低强度，test-runner、reviewer 用 sonnet 中档）；`settings.snippet.json` 主会话 sonnet 与 medium、子 agent 默认 sonnet、并发上限 3、hook；`hooks/filter-test-output.sh` 把清单内的测试或构建命令改写为经 run-quiet 执行 |
| Codex 适配 | `adapters/codex/` | `mapping.md` 术语映射；`agents/` 三个角色（explorer 只读 low，test-runner、reviewer 用 medium）；`config.snippet.toml` 主会话 medium、开启多 agent、子 agent 默认 medium、并发 3、嵌套 1 |
| 安装 | `install.sh` | 把通用正文与术语映射以带标记的段落写进各终端的规则文件（已有文件只追加、再装原位更新），用 jq 合并 settings.json、按缺失键合并 config.toml，覆盖前一律备份，结尾打印哪些已强制生效 |
| 治理规则 | `GOVERNANCE.md`、`GOVERNANCE-REVIEW.md`、`docs/governance.svg` | 作者设想的修订版：Project Router（新项目双 Discovery、冲突矩阵、用户裁决、需求与架构冻结；既有项目 Issue Analysis 后分级）、模型角色与单价、看板、Mechanical Gate、双模型对抗审核、PASS Gate、Repair Loop、跨终端交接、度量；评审列出每处修订的理由 |
| 整体流程 | `WORKFLOW.md`、`docs/workflow.svg` | 把规则串成端到端流程：分级、开发轨道、修复轨道、共用收尾、角色档位、额度控制点、异常处理、度量；流程图见 docs/ |
| 评审与评价 | `REVIEW.md`、`EVALUATION.md` | 问题清单与修正依据；对工作方式的评价与修订记录 |

规则正文只维护 `AGENTS.md` 这一份。改规则后重跑 `install.sh` 即可同步到各终端。

三层文件的关系：`GOVERNANCE.md` 规定谁在什么阶段做什么、什么条件下放行（分级、Fable 审核、Astra 计划、Sonnet 实现、Opus 与 GPT 双模型对抗审核、Gate、最终验收）；`WORKFLOW.md` 是实施模型在一个 Task 内部的开发与修复步骤；`AGENTS.md` 是每个模型在自己那一步里怎么少花额度，装进各终端。治理规则的原文在 `docs/governance-original.md`，逐条评审在 `GOVERNANCE-REVIEW.md`，流程图在 `docs/governance.svg`。

## 第 0 步：先降主会话档位

额度里最大的一块是主会话的模型与推理强度，规则文本压不到它，所以安装脚本会替你写默认值（已有的设置不动）：

| 终端 | 安装脚本写入 | 说明 |
| --- | --- | --- |
| Claude Code | `settings.json` 的 `model: sonnet`、`effortLevel: medium` | 用户级 `effortLevel` 对 Opus 5.5 不生效，用 Opus 5.5 时要在 `modelSettings` 里按模型设 effort。设计决策与疑难调试时用 `/effort` 或 `/model` 临时调高 |
| Codex CLI | `config.toml` 的 `model_reasoning_effort = "medium"` | 需要时用 `/model` 临时调高 |

思考 token 按输出计费。不降档的话，规则只碰得到一小半成本。每一步具体用哪个模型见 `WORKFLOW.md` 第 6 节：默认 sonnet 中档，搜索用 haiku，只有 L 级设计和止损后的疑难定位升 opus，fable 只做最后一档。

## 安装

全局与项目级二选一，两者都装时正文会被加载两次。

```bash
git clone https://github.com/NeilYLiu/Tokenconsumption.git && cd Tokenconsumption
./install.sh                 # 全局：自动检测 ~/.claude 与 ~/.codex；也可 ./install.sh claude 或 ./install.sh codex
./install.sh project ~/src/某仓库   # 项目级：写入该仓库的 AGENTS.md 与 .claude/{settings.json,agents,hooks}，云端与 Cowork 会话也能拿到强制层
```

脚本做的事：规则正文以 `<!-- agent-rules:begin/end -->` 标记段落写入 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md` 或项目的 `AGENTS.md`，已有内容保留；`settings.json` 用 jq 合并，缺键才写，hook 不重复；`config.toml` 按缺失键追加并校验仍是合法 TOML；agents、hooks、run-quiet 覆盖前备份。需要 bash、jq，合并 TOML 需要 python3。

两点注意：hook 会把清单内的单行测试、构建、检查命令改写为经 run-quiet 执行并自动放行（`permissionDecision: allow`），等于对这些命令免审批；多行、含管道、分号、重定向、变量展开的命令原样走正常流程。清单在 hook 脚本里，可自行增删。

验证：Claude Code 里 `/context` 应列出全局规则文件，`/agents` 应看到 Explore、test-runner、reviewer，`/hooks` 应有 filter-test-output；Codex 里 `/status` 可看到推理强度与 token 用量，`/agents` 可看到三个角色。

## 使用习惯（规则文件管不到）

- 无关任务之间新开会话（Claude Code `/clear`，Codex `/new`）。
- 空闲超过一小时后，第一条请求会按全价重写整个上下文；上一任务已完成就新开会话，否则直接提正事，不要为"热身"多发一轮。
- 安装前先在 `/usage` 记下一周的总量与 subagent 占比作为基线；两周后比较。没有变化先查强制层是否生效（`/hooks`、`/agents`、`/context`），再改规则措辞。

## 评审前提

评审开始时本仓库为空，云端会话里也没有既有的全局规则文件，所以评审对象是各编码 agent 在没有全局规则时的默认行为，依据见 `REVIEW.md`。
如果你本机已有一份全局规则，push 上来后可以逐条对照；安装脚本也只会在它末尾追加本规则段落，不会替换。

## 维护约定

`AGENTS.md` 保持在 150 行以内，只放每个会话都需要的规则；项目说明放项目级说明文件，工作流细节放按需加载的技能或命令文件。适配层只放该终端专有的术语映射与配置，不复制正文。
