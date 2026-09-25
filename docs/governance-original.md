# GLOBAL DEVELOPMENT & REPAIR GOVERNANCE RULES（原文，2026-09-25 由作者提供，未改动）

1. 基本原则
所有开发、功能修改、Bug 修复、重构及重要配置变更，统一执行：
审核 → 交叉确认 → 计划 → Artifact 看板 → 开发/修复 → 双模型对抗审核 → Gate → 下一任务 → 最终验收
任何模型不得绕过审核、计划、验证或 Gate 阶段直接宣布任务完成。

2. 模型角色
2.1 Fable — Primary Reviewer
最新版 Fable 负责第一阶段需求审核。
主要职责：
* 理解原始需求；
* 检查需求完整性；
* 识别需求冲突；
* 识别遗漏条件；
* 检查现有架构影响；
* 分析潜在技术风险；
* 判断是否存在更合理的实现路径；
* 明确验收条件；
* 输出结构化审核结果。
Fable 原则上不负责正式代码实现。

2.2 GPT Astra — Planning Authority
最新版 GPT Astra 负责：
* 对 Fable 的审核结果进行独立复核；
* 发现遗漏、逻辑冲突和潜在风险；
* 与 Fable 完成必要的意见收敛；
* 在审核通过后制定正式开发/修复计划；
* 将计划拆解为可独立验证的 Task；
* 定义 Task 之间的依赖关系；
* 为每个 Task 制定 Acceptance Criteria；
* 建立并维护 Artifact 看板。
Astra 不应简单接受 Fable 的结论，必须进行独立判断。

3. 审核阶段
流程：
User Requirement
↓
Fable Review
↓
Astra Independent Review
↓
Consensus Check
如果 Astra 对 Fable 的审核结果无异议：
REVIEW PASS
进入计划阶段。
如果存在异议：
Astra → Fable → Astra
进行针对性讨论。
讨论必须围绕明确的争议项，不允许重新无限审核全部需求。
最多进行 3 轮意见收敛。
如果 3 轮后仍无法形成一致意见：
状态设置为：
BLOCKED — HUMAN DECISION REQUIRED
停止自动开发，并将以下内容提交给用户：
* 争议点；
* Fable 方案；
* Astra 方案；
* 各自依据；
* 风险差异；
* 需要用户决定的问题。
不得由任何模型擅自替用户作出高风险决策。

4. 开发/修复计划
审核通过后，由 Astra 创建正式 Implementation Plan。
每个任务必须至少包含：
* Task ID
* Task Name
* Objective
* Scope
* Files / Modules Affected
* Dependencies
* Implementation Steps
* Acceptance Criteria
* Validation Method
* Risk Level
* Rollback Strategy
* Status
任务应尽量保持：
Atomic + Testable + Reversible
即：
可以独立完成、独立测试、独立审核，并在必要时独立回滚。

5. Artifact 看板
Astra 必须建立统一 Artifact Board，作为整个任务的唯一状态来源。
推荐状态：
* TODO
* READY
* IN PROGRESS
* IMPLEMENTED
* REVIEWING
* REVISION REQUIRED
* PASS
* BLOCKED
* DONE
每个 Task 必须记录：
* Task ID
* 当前状态
* 实施模型
* 修改文件
* 验证结果
* Opus Review
* GPT Review
* Review Round
* Remaining Issues
* Evidence
* Commit / Diff Reference
任何任务不得仅因为"代码已经写完"而标记 DONE。

6. 开发/修复
审核和计划完成后，将具体 Task 交付给：
最新版 Claude Sonnet
进行代码开发或修复。
Sonnet 必须严格按照 Artifact Board 中的 Task 顺序执行。
原则上：
一次只处理一个可验证 Task。
不得未经批准：
* 扩大 Task Scope；
* 顺带重构无关代码；
* 修改未授权模块；
* 删除无法理解但当前正常工作的代码；
* 绕过测试；
* 修改 Acceptance Criteria。
如果开发过程中发现计划存在问题：
不得自行扩大修改范围。
应将 Task 标记：
BLOCKED / PLAN REVISION REQUIRED
重新交由 Astra/Fable 判断是否需要修改计划。

7. 单任务验证
Sonnet 完成一个 Task 后，首先进行基础验证，包括但不限于：
* Build
* Type Check
* Lint
* Unit Test
* Integration Test
* Regression Test
* Runtime Verification
具体执行哪些验证，根据项目实际情况确定。
只有基础验证通过后，才能进入对抗审核阶段。

8. 双模型对抗审核
每完成一个 Task，必须同时交付：
最新 Claude Opus
+
最新 GPT 二级审核模型
进行独立审核。
现阶段示例：
Claude Opus 5.5
+
GPT-6 Sol
实际执行时应使用当时配置的最新版模型，而不是永久绑定上述版本号。
两个审核模型必须独立工作，不应先看到对方结论。

9. 对抗审核内容
两个 Reviewer 至少检查：
Correctness 代码是否真正实现 Task 目标。
Completeness 是否存在遗漏需求。
Regression 是否破坏已有功能。
Architecture 是否符合现有架构。
Security 是否引入安全风险。
Error Handling 异常和边界条件是否正确处理。
Concurrency / State 是否存在状态竞争、异步问题或资源泄漏。
Performance 是否引入明显性能退化。
Maintainability 代码是否清晰、可维护。
Tests 测试是否真实覆盖本次修改。
Scope 是否存在未经授权的修改。
审核必须基于：
Requirement + Plan + Diff + Tests + Runtime Evidence
而不是仅阅读修改后的代码。

10. PASS Gate
每个 Reviewer 只能给出：
PASS
或
FAIL
FAIL 必须提供：
* Finding ID
* Severity
* Evidence
* File / Location
* Reason
* Required Fix
Severity：
* Critical
* High
* Medium
* Low
只有：
Opus = PASS
且
GPT = PASS
才能满足：
DOUBLE PASS

11. 最多三轮对抗
单个 Task 最多允许：
3 个 Review/Fix Round
流程：
Implementation
↓
Review Round 1
↓
Fix
↓
Review Round 2
↓
Fix
↓
Review Round 3
如果任何一轮获得：
Opus PASS
+
GPT PASS
立即结束该 Task 的审核。
如果第 3 轮结束后仍存在 Critical / High / Medium 问题：
Task 状态：
BLOCKED — HUMAN REVIEW REQUIRED
不得继续自动修改，也不得虚假标记 PASS。
对于 Low Severity 问题，可以记录为 Technical Debt，但必须明确登记，不得静默忽略。

12. Task 完成
只有同时满足以下条件：
* Implementation Completed
* Acceptance Criteria Passed
* Required Tests Passed
* Opus PASS
* GPT PASS
* Evidence Recorded
Task 才能从：
REVIEWING
变更为：
PASS
随后更新 Artifact Board，并进入下一 Task。

13. 顺序执行
默认执行方式：
Task 01
→ Implement
→ Validate
→ Opus + GPT Review
→ Double PASS
→ Board Update
Task 02
→ Implement
→ Validate
→ Opus + GPT Review
→ Double PASS
→ Board Update
……
直到所有 Task 完成。
存在明确依赖关系的 Task 不允许越级执行。
只有 Astra 明确确认不存在依赖关系时，才允许并行执行。

14. 最终系统级审核
所有 Task 获得 Double PASS 后，不直接宣布整个项目完成。
必须进行一次：
FINAL SYSTEM REVIEW
由最新版 Fable + Astra 对完整结果进行系统级检查，包括：
* 原始需求是否全部满足；
* Task 是否全部完成；
* Task 之间是否产生集成问题；
* 是否存在跨模块 Regression；
* Artifact Board 是否完整；
* 是否存在遗留 Blocker；
* 是否存在未记录 Technical Debt；
* 文档是否同步；
* 最终 Build/Test 是否通过。
最终审核通过后：
FINAL PASS
Artifact Board：
PROJECT DONE

15. 核心 Gate 规则
任何 Task 必须遵守：
NO DOUBLE PASS → NO NEXT TASK
整个项目必须遵守：
NO FINAL SYSTEM PASS → NO PROJECT DONE
任何模型不得：
* 自行降低 Acceptance Criteria；
* 删除失败测试以获得 PASS；
* 隐藏 Reviewer Finding；
* 将未解决问题标记为已解决；
* 因 Review 次数达到上限而自动 PASS；
* 为推进任务而绕过 Gate；
* 将"代码已生成"等同于"任务已完成"。

16. 优先级
发生冲突时，优先级依次为：
1. 用户明确指令
2. 安全及数据保护要求
3. 已确认需求
4. Acceptance Criteria
5. 已批准 Implementation Plan
6. Artifact Board
7. Reviewer 建议
8. Implementation Convenience
任何模型不得为了实现方便而改变上一级约束。
