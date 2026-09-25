# 评审：GLOBAL DEVELOPMENT & REPAIR GOVERNANCE RULES

- 对象：`docs/governance-original.md`（作者 2026-09-25 提供的原文）。
- 目标：以完成任务为前提压缩额度。
- 结论：治理骨架是对的，应该保留；问题集中在"所有变更走同一条最贵的流水线"和"跨厂商编排没有落地方式"两处。修订版 `GOVERNANCE.md` 只加了分级、模型档位与单价、跨终端交接三样，原有的 Gate、DOUBLE PASS、看板、优先级一条没动。

## 先说保留的部分

- 验证与 Gate 不得绕过、不得自我认证、不得删测试换 PASS、达到轮数上限不自动 PASS：这是整套规则最有价值的部分。
- Task 原子化、可测试、可回滚，每个 Task 有 Acceptance Criteria 与 Evidence。
- 看板作为唯一状态来源；Low 问题登记为 Technical Debt 而不是静默忽略。
- 争议交给用户决定，模型不替用户做高风险决策；优先级表明确。
- 两个 Reviewer 独立、不先看对方结论。

## 问题清单与修订

| # | 问题 | 额度影响 | 修订 |
| --- | --- | --- | --- |
| 1 | 没有分级，一行修复和跨模块迁移走同一条流水线。按单价折算，一个 Task 的最低成本约为"Sonnet 直接做"的 7 倍，典型 10 到 15 倍：Fable 审需求、Astra 复核、最多 3 轮收敛、Astra 写计划、Sonnet 实现、Opus 与 GPT 各审一遍、最多 3 轮修复复审、Fable 加 Astra 最终验收 | 高 | 1.1 分级：S 级只保留验证与单模型 Gate；M 级由 Astra 一人审核出计划，双模型审核保留；L 级全流程。敏感面至少按 M |
| 2 | 最贵的模型放在最频繁的位置：Fable 审每一个需求、Fable 加 Astra 验收每一个项目、Opus 加 GPT 对每个 Task 最多 3 轮全量复审 | 高 | Fable 只在 L 级审核、M 级高风险审核、L 级验收三处；最终验收按分级；第 2、3 轮只复核上一轮 FAIL 的 Finding |
| 3 | 跨厂商编排在两个终端里都无法直接执行：Claude Code 派不出 GPT，Codex 派不出 Claude。"同时交付 Opus 与 GPT"和"Astra → Fable → Astra"在单个终端内做不到 | 高 | 第 17 节：交接物一律是仓库文件，独立性靠分文件写、写完前不读对方；每个阶段写完即结束会话，由用户或脚本触发下一步 |
| 4 | 审核输入没有限定。原文要求"基于 Requirement + Plan + Diff + Tests + Runtime Evidence"，但没说不能读整个仓库；两个贵模型各读一遍仓库是最大的隐性开销 | 中 | 第 3 节审核输入固定为需求、架构摘要、文件清单；第 8 节 Review Packet；第 9 节返回不超过 40 行 |
| 5 | 交叉确认 3 轮没有限定每轮的内容与载体，容易退化成整段重审 | 中 | 只讨论争议项清单，每轮一次文件交换 |
| 6 | 实现阶段没有止损与升档。Sonnet 修不好只能 BLOCKED 回计划，回计划的成本是 Astra 加 Fable 再走一遍 | 中 | 6.1：两次失败先撤销取证，再只把"定位"升到 Opus，仍不行才 BLOCKED |
| 7 | 验证阶段没有规定输出裁剪，测试全文会进入 Sonnet 与两个 Reviewer 的上下文 | 中 | 第 7 节所有命令经 run-quiet，Evidence 只放失败与摘要 |
| 8 | 看板没有 Level 与成本字段，无法知道规则有没有省到额度 | 低 | 第 5 节新增字段；第 18 节度量与调阈值 |
| 9 | Rollback Strategy 对每个 Task 都要求完整写法，S 级是负担 | 低 | S 级免，M 级可写"回滚本 Task 的提交" |
| 10 | 角色表没有 Sonnet 的档位与强度，也没有单价，模型选择无法核算 | 低 | 2.3、2.5 |
| 11 | "任何模型不得绕过审核、计划……阶段"与分级冲突，需要明确分级省略不算绕过；同时要防止模型为省额度把 M、L 改判成 S | 低 | 第 1 节改写；第 15 节加"不得为省额度降级" |

## 与本仓库其他文件的关系

- `WORKFLOW.md` 的开发轨道与修复轨道，就是第 6、7 节里 Sonnet 在一个 Task 内部的步骤；其中的"评审员"对应第 8 节的对抗审核（S 级单模型、M 和 L 级双模型）。
- `WORKFLOW.md` 原来把"opus 仍定位不了"升到 fable，与原文"Fable 不负责代码实现"冲突，已改为按 6.1 标记 BLOCKED 交回 Astra/Fable。
- `AGENTS.md` 是每个模型在自己那一步里的行为约束（搜索、读行段、输出裁剪、脱敏），三份文件不重复。

## 未采纳

- 没有把 Fable 从 Primary Reviewer 换成 Opus：需求审核是一次性的判断，输入小、输出小，用最强模型的绝对成本有限，且原文明确这是设计意图。分级已经把它限制在 L 级和 M 级高风险。
- 没有把双模型审核改成单模型：M、L 级的返工代价高于一次审核；只在 S 级改为单模型。

## 第二版设想（PROJECT ROUTER）的合并说明

作者第二版把流程改为：PROJECT ROUTER 分新项目与既有项目；新项目走 Fable Discovery 与 Astra Discovery、Conflict Matrix、User Decisions、Requirement Freeze、Architecture Freeze；既有项目走 Issue Analysis；汇合到 Artifact Board 后 Sonnet 实现，先过 Mechanical Gate 再进 Opus 与 GPT-6 Sol 审核，PASS 进下一 Task，FAIL 进 Repair Loop。已并入 `GOVERNANCE.md` 第 0、7、11 节。

| 项 | 处理 | 理由 |
| --- | --- | --- |
| Router 分新项目 / 既有项目 | 采纳 | 新项目的成本大头在需求与架构，值得前置投入；既有项目的成本大头在定位与返工，需要的是分级 |
| 双 Discovery 独立进行 | 采纳 | 一次性成本，两份独立视角比模型间对话更能暴露分歧；互不看对方避免趋同 |
| Conflict Matrix + User Decisions 替代模型间 3 轮收敛 | 采纳，并推广到 M 级审核分歧 | 3 轮模型对话每轮都是全上下文重读，矩阵由 Astra 一次合成、用户只裁决冲突项，更便宜也更可控。加了一条限制：矩阵必须逐条标注一致 / 冲突 / 仅一方提出，一致项直接冻结，只有冲突项和高风险单方项交用户，否则用户裁决量会失控 |
| Requirement Freeze / Architecture Freeze | 采纳，并写进优先级表 | 冻结后需求变更走变更申请，堵住"Task 里悄悄改需求"这一最常见的返工来源 |
| Mechanical Gate 前置 | 采纳 | 纯脚本、不消耗审核模型；机械门禁 FAIL 直接回 Sonnet，避免把编译不过的 diff 送给两个贵模型 |
| Repair Loop | 采纳，沿用 3 轮上限与只复核 FAIL 项 | 与第一版第 11 节一致 |
| 第二版图里没有的：分级、S 级单模型审核、最终验收、止损升档 | 保留修订版的做法 | Router 回答"是什么项目"，分级回答"这次改动多大"，两者正交；没有分级，既有项目的一行修复仍会走双模型审核 |
| Issue Analysis 由谁做 | 明确为：S 级 Sonnet，M 级 Astra，L 级对受影响范围跑 Discovery | 第二版图未标执行者 |

额度上的净效果：新项目前期多一份 Discovery（Fable 加 Astra 各一次），换掉最多 3 轮的模型间收敛，通常更省；Mechanical Gate 前置在每个 Task 上都省一次双模型审核的失败成本；冻结减少中途改需求的整套返工。既有项目的小修复仍靠分级省钱，Router 本身不解决这一点。
