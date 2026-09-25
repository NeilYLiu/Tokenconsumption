# GLOBAL DEVELOPMENT & REPAIR GOVERNANCE RULES（修订版）

原文保留在 `docs/governance-original.md`；每处修订的理由见 `GOVERNANCE-REVIEW.md`。三份文件的分工：本文件回答"谁在什么阶段做什么、什么条件下放行"；`WORKFLOW.md` 是实施模型在开发/修复阶段内部的步骤；`AGENTS.md` 是每个模型在自己那一步里怎么少花额度，装进各终端。修订只加了三样东西：分级、模型档位与单价、跨终端的交接方式；原有的 Gate、DOUBLE PASS、看板、优先级全部保留。

## 1. 基本原则
所有开发、功能修改、Bug 修复、重构及重要配置变更，统一执行：

分级 → 审核 → 交叉确认 → 计划 → Artifact 看板 → 开发/修复 → 验证 → 对抗审核 → Gate → 下一任务 → 最终验收

任何模型不得绕过验证或 Gate 直接宣布任务完成。审核、交叉确认、计划、最终验收四个阶段按 1.1 的分级决定是否执行、由谁执行；被分级省略的阶段不算"绕过"，但验证与 Gate 任何级别都不得省略。

### 1.1 分级（新增）
接单的模型在开工前分级并写入看板，用户可随时改判。触及敏感面（输入处理、鉴权、并发、文件/网络/子进程调用、数据迁移）的改动至少按 M 处理。

| 级别 | 判定 | 审核与交叉确认 | 计划 | 对抗审核 | 最终验收 |
| --- | --- | --- | --- | --- | --- |
| S | 改动不超过 3 个文件，方案唯一，不触及敏感面 | 不做；Sonnet 自写 1 到 3 行 Acceptance Criteria 并写入看板 | 不写 | 单模型审核（Opus 或 GPT 审核模型二选一），最多 2 轮 | 不做，Task PASS 即 DONE |
| M | 超过 3 个文件，或方案不唯一，或触及敏感面 | Astra 独立审核并出计划；需求有歧义或风险为 High 以上时先请 Fable 审核 | Astra 写 Implementation Plan | 双模型对抗审核，最多 3 轮 | Astra 做系统级检查 |
| L | 跨模块、新子系统、迁移、外部契约变更 | 全流程：Fable 审核 → Astra 独立复核 → 交叉确认 | Astra 写计划并拆 Task | 双模型对抗审核，最多 3 轮 | Fable + Astra 最终系统级审核 |

## 2. 模型角色

### 2.1 Fable — Primary Reviewer（L 级必做，M 级按需）
最新版 Fable 负责第一阶段需求审核：理解原始需求；检查完整性；识别冲突与遗漏条件；检查现有架构影响；分析技术风险；判断是否有更合理的实现路径；明确验收条件；输出结构化审核结果。
Fable 原则上不负责正式代码实现，也不参与逐 Task 的对抗审核；它只出现在 L 级审核、M 级高风险审核和 L 级最终验收三处。

### 2.2 GPT Astra — Planning Authority
最新版 GPT Astra 负责：独立复核 Fable 的审核结果；发现遗漏、逻辑冲突和潜在风险；与 Fable 完成必要的意见收敛；制定正式开发/修复计划；拆解为可独立验证的 Task；定义依赖；为每个 Task 制定 Acceptance Criteria；建立并维护 Artifact 看板。M 级没有 Fable 审核时，Astra 独立完成审核与计划。
Astra 不应简单接受 Fable 的结论，必须独立判断。

### 2.3 Claude Sonnet — Implementer（新增）
最新版 Sonnet 负责开发、修复、基础验证、看板状态更新，默认中档推理强度。它在 Task 内部按 `WORKFLOW.md` 的开发轨道或修复轨道执行，按 `AGENTS.md` 约束搜索、读文件与输出裁剪。

### 2.4 Reviewers — Claude Opus + GPT 审核模型
现阶段示例：Claude Opus 5.5 + GPT-6 Sol。实际执行时使用当时配置的最新版模型。

### 2.5 模型档位与单价（新增）
以 sonnet 每 token 价格为 1：haiku 0.5、sonnet 1、opus 2.5（opus 5.5 为 2）、fable 5；思考 token 按输出价计，强度越高越贵。GPT 侧单价未核对，按同样的档位关系使用。原则：贵模型只做一次性的判断（审核、计划、验收），不做搬运；搜索、跑测试、归纳输出用 haiku 或脚本；同一份材料不让两个贵模型各读一遍整个仓库。

## 3. 审核阶段
流程：User Requirement → Fable Review（按分级）→ Astra Independent Review → Consensus Check。

审核输入固定为：需求原文、架构摘要（不超过 2 页）、相关文件清单。不是整个仓库；需要看代码时只读清单里的文件。
审核输出格式固定为八项：完整性、冲突、遗漏、架构影响、风险、更优路径、验收条件、结论。结论只有两种：REVIEW PASS，或争议项清单。

Astra 无异议：REVIEW PASS，进入计划阶段。
有异议：Astra → Fable → Astra，只讨论争议项清单里的条目，不重新审核全部需求。每轮是一次文件交换（`reviews/R-round{n}-fable.md`、`reviews/R-round{n}-astra.md`），最多 3 轮。
3 轮后仍无法一致：状态 BLOCKED — HUMAN DECISION REQUIRED，停止自动开发，向用户提交争议点、Fable 方案、Astra 方案、各自依据、风险差异、需要用户决定的问题。不得由任何模型擅自替用户作出高风险决策。

## 4. 开发/修复计划
审核通过后由 Astra 创建 Implementation Plan。每个 Task 至少包含：Task ID、Task Name、Objective、Scope、Files / Modules Affected、Dependencies、Implementation Steps、Acceptance Criteria、Validation Method、Risk Level、Rollback Strategy、Status。
Task 应保持 Atomic + Testable + Reversible：可独立完成、独立测试、独立审核、必要时独立回滚。
S 级不写计划；M 级的 Rollback Strategy 可写为"回滚本 Task 的提交"。

## 5. Artifact 看板
Astra 建立统一 Artifact Board，作为整个任务的唯一状态来源。看板是仓库里的文件 `ARTIFACT-BOARD.md`，所有终端读写同一份。
状态：TODO、READY、IN PROGRESS、IMPLEMENTED、REVIEWING、REVISION REQUIRED、PASS、BLOCKED、DONE。
每个 Task 记录：Task ID、Level（新增）、当前状态、实施模型、修改文件、验证结果、Opus Review、GPT Review、Review Round、Remaining Issues、Evidence、Commit / Diff Reference、各阶段轮数与 token（新增，可得时记录）。
任何任务不得仅因为"代码已经写完"而标记 DONE。

## 6. 开发/修复
审核和计划完成后，将具体 Task 交付给最新版 Claude Sonnet。Sonnet 严格按看板顺序执行，一次只处理一个可验证 Task。
不得未经批准：扩大 Task Scope；顺带重构无关代码；修改未授权模块；删除无法理解但当前正常工作的代码；绕过测试；修改 Acceptance Criteria。
发现计划有问题：不自行扩大范围，将 Task 标记 BLOCKED / PLAN REVISION REQUIRED，交回 Astra/Fable 判断。

### 6.1 止损与升档（新增）
同一 Task 连续两次"修改加验证"后复现仍失败：撤销无效修改，取一条新证据（加日志、缩小复现、读上游调用）。取证后仍定位不了：只把"定位"这一步升到 Opus，Task 范围不变，代码仍由 Sonnet 写。Opus 仍定位不了：标记 BLOCKED / PLAN REVISION REQUIRED，交回 Astra/Fable。升档在看板的 Review Round 旁记录。

## 7. 单任务验证
Sonnet 完成一个 Task 后先做基础验证：Build、Type Check、Lint、Unit Test、Integration Test、Regression Test、Runtime Verification，按项目实际情况取舍。
所有命令经 run-quiet 执行，Evidence 只记录失败行与摘要，完整日志路径写入看板。只有基础验证通过后才进入对抗审核。

## 8. 对抗审核
M、L 级每完成一个 Task，同时交付最新 Claude Opus 与最新 GPT 审核模型独立审核；S 级二选一。
审核输入是 Review Packet：看板里的 Task 条目、diff、测试清单与结果、Evidence。不是整个仓库；需要看上下文时只读 diff 涉及文件的相关行段。
独立性靠分文件保证：各自写入 `reviews/T{id}-round{n}-opus.md` 与 `reviews/T{id}-round{n}-gpt.md`，写完之前不读对方文件。

## 9. 对抗审核内容
两个 Reviewer 至少检查：Correctness、Completeness、Regression、Architecture、Security、Error Handling、Concurrency / State、Performance、Maintainability、Tests、Scope。
审核基于 Requirement + Plan + Diff + Tests + Runtime Evidence，不是只读修改后的代码。每一项只在有证据时写 Finding；返回不超过 40 行，超限落盘并给路径。

## 10. PASS Gate
每个 Reviewer 只能给出 PASS 或 FAIL。FAIL 必须提供 Finding ID、Severity（Critical / High / Medium / Low）、Evidence、File / Location、Reason、Required Fix。
只有 Opus = PASS 且 GPT = PASS 才是 DOUBLE PASS；S 级为单模型 PASS。

## 11. 最多三轮对抗
单个 Task 最多 3 个 Review/Fix Round（S 级 2 轮）。任何一轮拿到 DOUBLE PASS 立即结束。
第 2、3 轮只复核上一轮 FAIL 的 Finding 及其修复的 diff，不重新全量审核。
第 3 轮后仍有 Critical / High / Medium：BLOCKED — HUMAN REVIEW REQUIRED，不得继续自动修改，不得虚假 PASS。Low 可登记为 Technical Debt，不得静默忽略。

## 12. Task 完成
同时满足 Implementation Completed、Acceptance Criteria Passed、Required Tests Passed、Opus PASS、GPT PASS（S 级单模型）、Evidence Recorded，Task 才从 REVIEWING 变为 PASS，更新看板，进入下一 Task。

## 13. 顺序执行
Task 01 → Implement → Validate → Review → PASS → Board Update → Task 02 → …… 直到全部完成。
有依赖的 Task 不允许越级；只有 Astra 明确确认无依赖时才允许并行，且同时 IN PROGRESS 的 Task 不超过 3 个。

## 14. 最终系统级审核
所有 Task PASS 后不直接宣布完成，必须做 FINAL SYSTEM REVIEW：原始需求是否全部满足；Task 是否全部完成；Task 之间是否有集成问题；是否有跨模块 Regression；看板是否完整；是否有遗留 Blocker；是否有未记录 Technical Debt；文档是否同步；最终 Build/Test 是否通过。
执行者按分级：L 级 Fable + Astra；M 级 Astra；S 级不做。通过后 FINAL PASS，看板 PROJECT DONE。

## 15. 核心 Gate 规则
NO PASS → NO NEXT TASK（M、L 为 DOUBLE PASS）；NO FINAL SYSTEM PASS → NO PROJECT DONE（S 级以 Task PASS 为终点）。
任何模型不得：自行降低 Acceptance Criteria；删除失败测试以获得 PASS；隐藏 Reviewer Finding；将未解决问题标记为已解决；因 Review 次数达到上限而自动 PASS；为推进任务而绕过 Gate；将"代码已生成"等同于"任务已完成"；为省额度把 M、L 级改判为 S。

## 16. 优先级
发生冲突时依次为：用户明确指令；安全及数据保护要求；已确认需求；Acceptance Criteria；已批准 Implementation Plan；Artifact Board；Reviewer 建议；Implementation Convenience。任何模型不得为了实现方便而改变上一级约束。

## 17. 跨终端执行方式（新增）
Claude Code 只能派 Claude 系模型，Codex 只能用 GPT 系模型。Fable 与 Astra 的交叉确认、Opus 与 GPT 的双模型审核，必然跨两个终端。
交接物一律是仓库里的文件：`ARTIFACT-BOARD.md`、`plans/`、`reviews/`、`evidence/`。每个终端只读本阶段需要的文件，不重新探索仓库；每个阶段的模型在写完自己的文件后结束，不在同一会话里等待对方。
用户或一个轻量脚本负责在两个终端之间触发下一步；每次触发新开会话，不在长会话里堆积多个 Task。

## 18. 额度度量（新增）
看板按 Task 记录各阶段轮数与（可得时）token。每两周按 S、M、L 比较平均成本与 BLOCKED 次数：S 级成本明显高于"直接做"就收紧审核轮数；M、L 级返工多就放宽分级阈值。
