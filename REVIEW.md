# 评审报告：开发与修复过程中的全局 agent 调用规则

- 日期：2026-09-25
- 目标：在合理的开发与修复过程中，以完成任务为前提，压缩额度用量。
- 对象：Claude Code 在无全局规则约束时的默认 agent 调用与工具使用行为。本仓库评审开始时为空，云端会话也没有 `~/.claude/CLAUDE.md`，没有既有文件可逐条修改，因此把修正结果直接写成 `CLAUDE.md`、`agents/`、`settings/`、`hooks/`。
- 依据：Claude Code 官方文档 2026-09-25 版本的 sub-agents、costs、memory 三页。

## 额度的四个来源（评审框架）

1. **上下文重读**：每次请求都把整个对话（含所有工具输出）再发一次，命中缓存也按缓存价计费。放进上下文的东西，之后每一轮都在付费。
2. **输出 token**：单价是输入的数倍，思考 token 也按输出计费。冗长回复、反复试错、逐行手改都是输出。
3. **子 agent**：各有独立上下文，启动即加载自身提示词、用户和项目 CLAUDE.md（内置 Explore/Plan 除外）以及 git 状态快照；不指定模型就继承主会话模型；默认最多 20 个并发；agent teams 在 plan 模式下约为普通会话的 7 倍。
4. **返工**：方向错了再改，成本是探索、实现、验证整套重来。

## 问题清单与修正

| # | 问题（默认行为） | 额度影响 | 修正 |
| --- | --- | --- | --- |
| 1 | 子 agent 不指定模型时继承主会话模型，内置 Explore/Plan 也如此（Explore 最高到 Opus）。主会话用 Opus 或 Fable 时，连搜索都在最贵的模型上跑 | 高 | `agents/Explore.md` 把内置 Explore 覆盖为 haiku、effort low；`settings` 里 `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 作为兜底；`CLAUDE.md` 第二节的模型选择 |
| 2 | 派发无门槛：单一事实查询、栈追踪已指明位置、两三个文件的小改也派 agent。每次派发都是一份新的提示词加一次重新探索 | 高 | `CLAUDE.md` 第一节"三问"与"默认不派"清单 |
| 3 | 为"全面"并行多 agent：多维度评审（bug、性能、风格、安全各一个）、Workflow 或 ultracode 编排、agent teams；并发上限默认 20 | 高 | 禁止多维度评审，只派一个 reviewer 查正确性（`agents/reviewer.md`）；普通开发修复不用编排；`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS=3` 与规则"同时最多 3 个"互为保险 |
| 4 | 工具输出不裁剪：cat 整文件、无限制 grep、全量 diff、完整测试与日志输出，全部留在上下文里被之后每一轮重读 | 高 | `CLAUDE.md` 第三节；`hooks/filter-test-output.sh` 在模型看到之前把测试输出裁到失败与摘要，完整日志落盘 |
| 5 | 修复靠猜测和尝试循环：改一下跑一下，反复多次 | 高 | 第五节"两次失败即停"，先取新证据再改 |
| 6 | 强度与模型一刀切用最高档 | 高 | 用户侧设置，规则文件管不到，见 README"用户侧三件事" |
| 7 | 子 agent 提示词不自包含：不给路径、不给已知结论，子 agent 从零重新发现；报告没有长度限制，把省下的上下文又灌回主会话 | 中 | 第二节的提示词要求与返回上限；三个 agent 文件都写死返回格式与行数上限 |
| 8 | 派出后主会话又自己做同样的搜索 | 中 | 第二节"派出后不自己再做同样的搜索" |
| 9 | 修 bug 顺手重构、格式化无关代码，扩大读写与验证范围 | 中 | 第五节最小修改；第七节禁止 |
| 10 | 开工前不澄清需求、不做最小计划，方向错了整套返工 | 中 | 第四节澄清与计划的触发条件：有歧义才问，超过 3 个文件或方案不唯一才写计划 |
| 11 | 会话不分段：无关任务堆在一个会话里；compact 用得随意（compact 本身要读全部历史，是一次大请求；clear 免费） | 中 | 第六节；README 用户侧习惯 |
| 12 | 回复冗长：复述操作、贴已写入文件的代码 | 中 | 第三节末条 |
| 13 | 自定义子 agent 与 general-purpose 启动时默认加载用户和项目 CLAUDE.md 与 git 状态；覆盖内置 Explore 后也会如此 | 低 | 三个 agent 文件 `omitClaudeMd: true`，所需命令与路径由提示词给出 |
| 14 | 确定性工作（格式化、lint、批量重命名、脚手架）由模型逐行改 | 低 | 第三节交给命令 |
| 15 | 网页或文档整页拉进上下文 | 低 | 第三节 WebFetch 必须给提取目标 |
| 16 | 全局 CLAUDE.md 臃肿或混入项目说明，每个会话每一轮都在背 | 低 | `CLAUDE.md` 只有 72 行，只放每个会话都需要的规则；官方建议单文件 200 行以内 |

## 有意不做的事

- **不禁用 Explore 与 Plan**（`CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS`）：对中大型代码库，haiku 上的 Explore 比主模型直接通读更省，所以改为覆盖它的模型。
- **不强制所有子 agent 用 haiku**（`CLAUDE_CODE_SUBAGENT_MODEL_FORCE`）：需要推理的子任务用弱模型会返工，返工比模型差价贵。兜底设为 sonnet，搜索类显式 haiku。
- **不禁用 Agent 工具**：隔离大体量输出仍是省额度的正确手段，问题在门槛和方式。
- **不拆成多个 rules 文件**：一份短文件加载成本最低，也最不容易出现互相矛盾的规则。
- **不把项目信息写进全局文件**：那是项目 CLAUDE.md 的事。
- **hook 只改写单纯的测试或构建命令**：含管道、分号、重定向、变量展开的命令原样放行，避免误改和误放行。

## 规则之间的取舍

- "两次失败即停"不是放弃任务，是停止试变体、改为取证；取证后继续。
- "改动不超过 3 个文件自己做"与"超过 3 个文件才写计划"是同一条阈值的两面：小改直接做，大改先计划。
- test-runner 与 reviewer 用 sonnet 而不是 haiku：归纳失败和判断 bug 需要推理，弱模型漏报会让主会话重做。
- Explore 用 haiku：搜索定位是机械工作，提示词给足路径与目标即可；搜索质量不够时把 `agents/Explore.md` 的 `model` 改为 sonnet。

## 如何验证规则生效

- 新会话 `/context`：Memory files 含 `~/.claude/CLAUDE.md`，占用应明显小于 3k token。
- `/usage`（按周）：Attribution 里 subagent 占比应下降；Behavior flags 不应长期出现 long context。
- `/insights`：friction points 里"misunderstood requests"与"buggy code"应减少，这两项对应返工。
- 一次 bug 修复走完第五节流程后，检查会话里是否只有一次复现、一次定向验证、一次完整检查。
