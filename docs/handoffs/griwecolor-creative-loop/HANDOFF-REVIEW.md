# 审核：GRIWECOLOR AI Creative Production Loop 开发 Handoff

- 对象：`original.md`（v1.0，2026-09-26，作者提供）。
- 依据：`GOVERNANCE.md`（谁在什么阶段做什么、什么条件下放行）、`WORKFLOW.md`（Task 内步骤与模型档位）、`AGENTS.md`（额度）；以及文档自身各节之间的一致性。
- 结论：产品目标、架构原则、Provider 化、状态机、四级保密、结构化 Review 输出、幂等与恢复、DoD 这些骨架是对的，全部保留。问题集中在三处：开发流程与治理规则不一致（Codex 一肩挑、`IMPLEMENTATION_PLAN.md`、没有 Discovery / 冻结 / 看板 / Gate）；保密路由只管 Generator，而且排在外部模型调用之后；主链漏了用户选择环节，Phase 1 把系统押在文档自己说"不得依赖"的 Provider 上。修订版 `HANDOFF.md` v1.1 的处理如下。

## 先说保留的部分

- 第一性目标与"不为 Agent 数量、模型对抗、Prompt 长度炫技"的立场：原样保留并标为约束。
- 企微唯一入口、Workflow Engine 是控制中心、模型不替代状态机、Generator Provider 化、Jev 只返回受限动作、MJ Provider 可禁用：原样保留并标为约束。
- 事实必须来自已验证知识源、无数据标 `UNKNOWN`、禁止模型补全：保留并补了 `UNKNOWN` 之后怎么办。
- 状态机持久化、轮数上限、超限进 WAITING_USER：保留，补了前移分类与用户选择分支。
- Review 不得只给总分、FAIL 必须形成可执行修订：保留，补齐十项与阻断规则。
- 幂等、恢复测试清单、Browser 错误诊断包、Observability 字段、日志脱敏、不引入 Kubernetes：保留并小幅扩充。

## A. 与治理规则不一致（已处理）

| # | 原文位置 | 问题 | 处理 | 依据 |
| --- | --- | --- | --- | --- |
| A1 | 标题、§21 | "Codex 开发 Handoff"，让 Codex 审计、计划、实施一肩挑。治理规则里 Codex 只用 GPT 系模型，承担 Astra 的 Discovery、计划、看板与 GPT 审核；实现由 Sonnet 在 Claude Code 完成 | §0 角色与终端表；§21 改为 Project Router 八步；"是否让 Codex 实现"列为待裁决项 6 | GOVERNANCE 0、2.2、2.3、17 |
| A2 | §21 | 单模型"审计 → 计划 → 待确认 → 实施"，没有双 Discovery、Conflict Matrix、用户裁决、需求与架构冻结 | §21 步骤 2 到 5：`discovery/fable.md`、`discovery/astra.md` 互不看对方，Astra 合成矩阵，用户裁决，冻结为 `REQUIREMENTS.md` 与 `ARCHITECTURE.md` | GOVERNANCE 0；新项目一律 L 级 |
| A3 | §19.2 | `IMPLEMENTATION_PLAN.md` 加"任务看板"，文件名与所有者与治理规则不同 | `plans/` + `ARTIFACT-BOARD.md`，Astra 建立维护；Task 12 字段 | GOVERNANCE 4、5、17 |
| A4 | §18 | Phase 没有分级、轮数预算、Task 拆分与验收格式；只有 Phase 1 写了验收 | 每个里程碑按 M 级、预算 50 轮、Astra 拆 Task；每个里程碑的验收改成命令或可观察结果 | WORKFLOW 2；GOVERNANCE 1.1、4 |
| A5 | §19.3 | "每个模块完成后运行测试、lint、typecheck"，没有 Mechanical Gate、对抗审核、PASS Gate、Repair Loop 上限 | §19.3：每个 Task 过 Mechanical Gate（run-quiet）→ Opus ‖ GPT → PASS Gate；Repair Loop 3 轮，超限 BLOCKED | GOVERNANCE 7 到 11、15 |
| A6 | §19.10 | ADR 与冻结架构的关系未定，可能在 Task 里用 ADR 改架构 | ADR 记录决策；改冻结架构走变更申请，回 Conflict Matrix 对应行 | GOVERNANCE 0 Architecture Freeze、15 |
| A7 | §19.12 | 冲突时只有"第一性原则优先于架构完美主义"，与治理的优先级表不一致 | §19.12 引用 GOVERNANCE 16 的八级优先级 | GOVERNANCE 16 |
| A8 | §21.1 | "当前仓库/部署环境审计结果"等于让两个最贵的模型各通读一遍仓库 | M0 清单由搜索员（小模型）产出，不超过 60 行；Discovery 只读清单，不通读 | AGENTS 一、三；GOVERNANCE 2.5、3 |
| A9 | 全文 | 没有区分用户已定与作者提案，Discovery 会把已定项重新拿出来讨论，矩阵会失控 | 每节标【约束】或【提案】；约束直接冻结，不进矩阵 | GOVERNANCE 0（一致项直接冻结，只裁决冲突项） |
| A10 | §19 | 没有额度规则 | §19.13 引用 AGENTS.md：搜索不通读、run-quiet、两次失败即停、回复只讲结论、脱敏 | AGENTS 全文 |
| A11 | §20 | 只有产品侧 DoD，没有开发侧完成定义 | §20 加开发侧：每 Task 三 PASS 加 Evidence；全部 Task 后 Fable + Astra FINAL SYSTEM REVIEW | GOVERNANCE 12、14、15 |
| A12 | §21 | 原文要求的 8 项输出没有落点 | 映射：审计结果与模块映射 → inventory 与两份 Discovery 的架构提案；缺失依赖、风险、未知 → Discovery 的关键假设、风险、未决问题；`IMPLEMENTATION_PLAN.md` → `plans/`；看板 → `ARTIFACT-BOARD.md`；Phase 1 文件范围 → M1 各 Task 的 Files / Modules Affected；测试与回滚 → 各 Task 的 Validation Method 与 Rollback Strategy | GOVERNANCE 4、5 |

## B. 实际需求缺口（已处理）

| # | 原文位置 | 问题 | 处理 |
| --- | --- | --- | --- |
| B1 | §4 | SECURITY_CLASSIFICATION 排在 CONTEXT_RETRIEVAL 与 BRIEFING 之后，而这两步已经把产品事实送进 GPT/Claude 等外部 Worker，保密判断做晚了 | 前移到 PARSING 之后，任何外部调用之前；§2 主链同步 |
| B2 | §7 | 只路由 Generator。§2 明说 GPT、Claude、Jev 是 Worker，它们同样把 Brief、Prompt、截图、生成图送到外部 | 管辖对象扩为所有外部调用（意图解析、Planner、Prompt Builder、Vision Review、Jev、Generator）；每步所用模型与位置写入 metadata；§2 原则 7 |
| B3 | §7 | `INTERNAL → policy routing` 没有定义；无法判定级别时的默认值没有定义 | INTERNAL 默认本地，外部只限有数据处理协议且不训练的服务；无法判定 → INTERNAL；级别取产品、项目、素材、用户声明的最大值；降级只能由用户确认并留痕 |
| B4 | §2、§4 | 主链没有用户选择：§3 定义了`采用A`、`A背景亮一点`，但状态机从 REVIEWING 直接到 APPROVED，WAITING_USER 只是异常态 | 加 CANDIDATES_READY → DELIVERING → WAITING_USER，三条出边：采用、修改（revision + 1）、停止；§3 指令表逐条对应状态变化 |
| B5 | §18 | Phase 1 唯一 Provider 是 MJ Web，但 §9 要求"系统不得依赖它才能运行"，§20 要求"保密任务不会错误进入外部 Provider"；而唯一的本地 Provider（ComfyUI，§10）在所有 Phase 里都没有出现 | M1 本地优先：FakeProvider + ComfyUIProvider；M1b MJ Web 并行验证、flag 默认关；顺序列为待裁决项 1 |
| B6 | §8、§4 | `submit` 没有幂等键，`generator_retry: 2` 会让 MJ 这类 Provider 二次生成、二次计费 | `submit(req, idempotencyKey)`；同 key 必须返回同一 job；无原生幂等的 Provider 自建持久化 key → job 表 |
| B7 | §8 | Router 无法从接口得知 Provider 是本地还是外部、支持什么比例、能否用参考图，只能写死名字 | `describe(): ProviderDescriptor`（locality、比例、单次输出数、参考图、计费）；Router 只看描述符 |
| B8 | §11 | 正文列了十项检查，JSON 只有五项；没有区分哪些 FAIL 必须丢弃候选、哪些只需修订 | 十项固定；`blocking` 列表（保密、伪文字/Logo、产品准确性）FAIL 直接丢弃；每条修订指令必须映射到可改字段 |
| B9 | §6 | 标了 `UNKNOWN` 之后怎么办没有说，Prompt Builder 与 Production Agent 可能把 UNKNOWN 带进画面或文案 | 进 WAITING_USER 一次询问，或去掉该主张；UNKNOWN 不进 Prompt、不上文案；§12 成品文案只用 VERIFIED 条目 |
| B10 | §9 | Jev 没有定义：是什么模型、跑在哪、看得到什么。它看得到 Prompt 与生成图，是保密路由的对象 | §9 定义 Jev，模型与托管位置在 Discovery 确认；受 Security Router 约束；validate 明确为确定性校验器；待裁决项 2 |
| B11 | §3、§5 | 要求"通过 conversation/message 找回 task_id"，但 Context 没有来源字段；一个会话多个任务并存时怎么路由没有说 | Context 加 `source`、`trace_id`、`parent_revision`、`selected_candidate`、`security`、`facts`；多任务时指令带任务号或候选号，否则追问一次 |
| B12 | §16 | 幂等键只有企微一种；Provider 回调、内部重试、企微发送都没有键 | 四种键按来源列出；测试清单加"WAITING_USER 期间重启"与"同一会话多任务并存" |
| B13 | §14 | 经验写回不分保密级，CONFIDENTIAL 任务的 Prompt 与图可能被 PUBLIC 任务检索复用 | 写回按保密级分区 |
| B14 | §4 | WAITING_USER 没有超时；恢复没有说明不重复副作用（重启后可能重复提交生成或重复发企微） | `waiting_user_timeout_hours: 72` → PAUSED；恢复从最后持久化状态起，不重复已完成的副作用 |

## C. 优化（已处理）

| # | 位置 | 优化 |
| --- | --- | --- |
| C1 | §4、附录 | 运行时 `creative_review_max_loops: 3` 与开发侧 Repair Loop 的 3 轮容易混淆，加注释与术语表区分 |
| C2 | §8、§15、§18 | 增加 FakeProvider：确定性输出、可注入错误与延迟；20 Job 验收用它跑，不花真实 Provider 的钱与配额 |
| C3 | §9 | MJ Web 用 feature flag、默认关闭、服务条款确认前不进生产；persistent profile 目录排除在日志、备份与仓库之外 |
| C4 | §18 | 验收改成可执行：kill 进程后恢复且不重复归档、出站代理日志证明 CONFIDENTIAL 任务零外呼、成品数字可追溯到 `facts.source_ref` |
| C5 | §13、§17 | metadata 与全链路字段加 `security_level`、每次调用的 model、cost；指标加 cost_per_completed_task |
| C6 | §3 | 指令表逐条写明系统动作与状态变化，并规定无法识别时追问一次 |
| C7 | §21 | 预填六项待裁决项，用户裁决时不用从矩阵里自己找 |
| C8 | 附录 | 术语表：区分开发侧角色（Fable、Astra、Sonnet、Opus）与运行时组件（Jev、Provider） |

## D. 未改动与待用户裁决

- 保留原样：§1 第一性目标；§2 原则 1 到 6；§3 示例对话；§9 动作类型与 Locator 优先级；§12 职责清单；§13 目录结构；§15 目录结构；§17 指标列表；§21 末尾的架构原则。
- 文件名 `discovery/inventory.md`、`discovery/conflict-matrix.md` 是本次提案，治理规则只固定了 `discovery/fable.md` 与 `discovery/astra.md`；Astra 建矩阵时可改名，但要在 `ARTIFACT-BOARD.md` 里写明。
- 六项待裁决项见 `HANDOFF.md` §21，其中里程碑顺序（ComfyUI 优先还是 MJ Web 优先）影响最大：本文推荐本地优先，理由是 ComfyUI 是保密任务的唯一出口，且不受第三方服务条款约束；若 DGX/ComfyUI 未就绪，用户可裁决先用 MJ Web，M1 的其余验收不变。
- 朋友圈 4:5 比例、任务号格式、默认阈值数值：作为提案保留，由 Discovery 核对。

## 与本仓库其他文件的关系

- 本目录只放该项目的 Handoff 三件套（原文、修订版、审核）；治理规则本身没有改。
- 使用时把 `HANDOFF.md` 复制到目标项目仓库（建议放 `discovery/input.md`），随后按其 §21 执行；目标仓库需先用 `install.sh project <路径>` 装入规则正文与强制层。
