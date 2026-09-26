# GRIWECOLOR AI Creative Production Loop

## 开发 Handoff（Project Router 的 Discovery 输入）

> Version: v1.1（v1.0 原文见 `original.md`，每处修订的理由见 `HANDOFF-REVIEW.md`）\
> Date: 2026-09-26\
> 核心：**WeCom In → Autonomous Creative Loop → WeCom Out**

# 0. 本文件怎么用

本项目是新项目，按 `GOVERNANCE.md` 第 0 节一律按 L 级走 Project Router。本文件是两份 Discovery 的**共同输入**（用户描述、约束、已有资料），不是冻结的需求或架构；冻结产物是用户裁决后形成的 `REQUIREMENTS.md` 与 `ARCHITECTURE.md`。

**角色与终端**（`GOVERNANCE.md` 第 2、17 节）：

| 角色 | 终端 | 在本项目里做什么 |
| --- | --- | --- |
| Fable | Claude Code | 独立 Discovery（`discovery/fable.md`）；Architecture Freeze 前复核一次；最终系统级验收 |
| GPT Astra | Codex | 独立 Discovery（`discovery/astra.md`）；合成 Conflict Matrix；裁决后写 `REQUIREMENTS.md`、`ARCHITECTURE.md`；写 `plans/` 并拆 Task；建立并维护 `ARTIFACT-BOARD.md`；最终验收 |
| Claude Sonnet | Claude Code | 按看板逐 Task 实现；执行 Mechanical Gate；更新看板 |
| Claude Opus + GPT 审核模型 | 各自终端 | 每个 Task 的对抗审核，各写 `reviews/T{id}-round{n}-opus.md`、`reviews/T{id}-round{n}-gpt.md`，写完前不读对方 |

v1.0 标题为"Codex 开发 Handoff"，让 Codex 审计、计划、实施一肩挑，与治理规则"Codex 只用 GPT 系模型、实现由 Sonnet 负责"冲突，已改为上表分工。用户若明确要求由 Codex 实现，以用户指令为准（`GOVERNANCE.md` 第 16 节优先级），但仍须过 Mechanical Gate 与 PASS Gate。

**约束与提案**：下文各节标注两种标签。
- 【约束】用户已决定的事项，直接进入冻结；Discovery 不重新评估，Conflict Matrix 不列。
- 【提案】作者的建议方案，两份 Discovery 独立评估；分歧进 Conflict Matrix 交用户裁决。

未标注的段落按【提案】处理。

**交接物**一律是仓库文件，每个终端只读本阶段需要的：`discovery/inventory.md`、`discovery/fable.md`、`discovery/astra.md`、`discovery/conflict-matrix.md`、`REQUIREMENTS.md`、`ARCHITECTURE.md`、`plans/`、`ARTIFACT-BOARD.md`、`reviews/`、`evidence/`、`docs/adr/`。

# 1. 第一性目标 【约束】

本项目不是 Midjourney 自动化脚本，而是企业 AI 创意生产系统。员工只通过企业微信提出需求、修改和选择方案；后台完成知识检索、创意规划、保密判断、生成、审核、迭代、归档和回传。

**第一性目标：把企微中的自然语言宣传需求，稳定转换为符合产品事实、品牌规范、保密要求和视觉质量要求的可用宣传资产，并通过企微闭环交付。**

不得为了 Agent 数量、模型对抗、Prompt 长度、架构复杂度或炫技 UI 牺牲稳定性和实际宣传效果。

# 2. 架构原则 【约束】 与主链 【提案】

原则（约束）：

1.  企业微信是普通员工唯一业务入口和出口。
2.  Workflow Engine 是控制中心；GPT、Claude、Jev 都是 Worker。
3.  Generator 必须 Provider 化：Midjourney Web、ComfyUI、GPT Image 及未来 Provider 可替换。
4.  Jev = Action Decision Layer；Playwright = Browser Executor。
5.  无限画布后续作为高级美工工作台，不作为主入口。
6.  模型不得替代确定性状态机。
7.  Security Router 管的是"任务内容出不出企业边界"，对象是所有把任务内容送到外部的调用（推理 Worker、Vision Review、Jev、Generator），不只是 Generator。
8.  用户选择是主链的一部分：候选先回企微，用户点选或修改后才进入成品制作。

主链（提案）：

``` text
WeCom → Gateway → Intent Router（本地规则 / 本地小模型，不出企业边界）→ Workflow Engine
  ├─ Security Classification（先于任何外部调用；每个 revision 重做，级别只升不降）
  ├─ Knowledge Retrieval（按保密级过滤）
  ├─ Creative Planner（Worker 按保密级选本地 / 外部）
  ↓
Creative Brief → Prompt Builder → Generator Router（受 Security Router 约束）
  ├─ Midjourney Web → Jev → Playwright   （外部；feature flag，默认关）
  ├─ ComfyUI → DGX Spark                 （本地）
  ├─ Fake Provider                       （测试与演练）
  └─ Other Provider
  ↓
Candidate Pool → Vision Review
  ├─ FAIL → Revision → 再生成（最多 3 轮）
  └─ PASS，或到达上限 → 候选回传 WeCom → 用户选择 / 修改
       ├─ 修改 → 新 revision → 重新分级 → 再生成
       └─ 采用 → Production Agent → Final Review（POST_PROCESSING 的退出条件）→ Synology/KB → WeCom
```

# 3. 企业微信交互

示例：

``` text
@AI美工
给 AN2-L810 做三张高铁轻量化宣传图。
重点体现减重和 NVH 性能，用于朋友圈，风格现代、工业化。
```

系统：

``` text
已建立任务 ART-20260926-0081
产品：AN2-L810
用途：朋友圈
主题：轻量化 + NVH
输出：3套
状态：正在生成
```

指令表（提案）：

| 用户说 | 系统动作 | 状态变化 |
| --- | --- | --- |
| `采用A` | 选定候选 A | WAITING_USER → APPROVED |
| `A背景亮一点`、`B列车环境更现代` | 以该候选为参照，只改点名的约束，其余沿用 | WAITING_USER → SECURITY_CLASSIFICATION → BRIEFING（revision + 1） |
| `重新生成` | 同一 Brief 换种子或换 Provider 再生成 | WAITING_USER → SECURITY_CLASSIFICATION → GENERATING（revision + 1） |
| `生成横版` | 同一 Brief 改 aspect_ratio | WAITING_USER → SECURITY_CLASSIFICATION → BRIEFING（revision + 1） |
| `查看任务`、`查看原图` | 只读查询 | 不变 |
| `停止任务` | 取消，已归档内容保留 | 任意状态 → CANCELLED |
| 无法识别 | 追问一次，列出可选动作 | 不变 |

绑定规则（约束）：每条入站消息按 `conversation_id + message_id` 找回 task_id 与当前 revision；一个会话里同时有多个未完成任务时，指令必须带任务号或候选号（Context.candidates 里的 id），否则追问一次。修改请求只改变用户点名的约束，其余从上一 revision 复制。

# 4. Workflow 状态机 【提案】

``` text
RECEIVED → PARSING → SECURITY_CLASSIFICATION → CONTEXT_RETRIEVAL → BRIEFING
→ PROVIDER_SELECTION → GENERATING → REVIEWING
     ├─ FAIL 且未达上限 → REVISION_REQUIRED → GENERATING
     └─ PASS，或达上限（附最佳候选与原因）→ CANDIDATES_READY → DELIVERING → WAITING_USER
WAITING_USER
     ├─ 采用 → APPROVED → POST_PROCESSING → ARCHIVING → PUBLISHING → COMPLETED
     ├─ 修改 / 重新生成 / 换比例 → SECURITY_CLASSIFICATION（revision + 1；新消息文本与新素材重新分级，级别只升不降）
     │      修改、换比例 → BRIEFING；重新生成 → GENERATING
     └─ 停止 → CANCELLED
```

v1.0 把 SECURITY_CLASSIFICATION 放在 BRIEFING 之后，但 CONTEXT_RETRIEVAL 与 BRIEFING 已经把产品事实送进外部模型，已前移。WAITING_USER 是主链上的正常状态，不只是异常。POST_PROCESSING 的退出条件是 Final Review 通过（第 12 节）；不通过回 Production Agent 修正，最多 2 次，仍不过 → PAUSED 转人工。

异常：`RETRYING / PAUSED / FAILED / CANCELLED`。任何状态可进 PAUSED（人工介入）与 FAILED（不可恢复错误，企微返回诊断摘要）。

所有状态与转换持久化（含触发原因、时间、执行者）；服务器、Worker、浏览器重启后从最后一个持久化状态恢复，不重复已完成的副作用（已提交的生成、已发送的企微消息、已写入的归档）。默认（可配）：

``` yaml
creative_review_max_loops: 3      # 运行时的创意审核轮数；与开发侧 Repair Loop 的 3 轮无关
candidates_per_revision: 3
browser_action_max_steps: 50
generator_retry: 2                # 同一 idempotency key，Provider 不得二次生成
publish_retry: 3
waiting_user_timeout_hours: 72    # 超时 → PAUSED 并提醒一次；不替用户选择
```

超过上限进入 WAITING_USER，企微返回最佳候选及原因，禁止无限 Loop。

# 5. Creative Context 【提案】

每个任务保存版本化 Context；每个 revision 是一个新版本，修改只覆盖用户点名的字段，其余从 `parent_revision` 复制：

``` json
{
 "task_id": "ART-20260926-0081",
 "trace_id": "…",
 "revision": 1,
 "parent_revision": null,
 "source": {"channel": "wecom", "conversation_id": "…", "message_id": "…", "requester_id": "…"},
 "security": {"level": "PUBLIC", "basis": ["product:AN2-L810:PUBLIC", "project:none"]},
 "product": "AN2-L810",
 "purpose": "WeCom Moments",
 "audience": "rail transit customer",
 "message": ["lightweight", "NVH performance"],
 "facts": [
  {"claim": "lightweight", "source_ref": "kb://product/AN2-L810#weight", "status": "VERIFIED"},
  {"claim": "NVH performance", "source_ref": null, "status": "UNKNOWN"}
 ],
 "visual_style": ["modern", "industrial"],
 "aspect_ratio": "4:5",
 "output_count": 3,
 "allowed_claims": [],
 "forbidden_claims": [],
 "reference_assets": [],
 "candidates": [{"id": "A", "revision": 1, "asset_id": "…", "review": "PASS"}],
 "selected_candidate": null
}
```

# 6. Knowledge Retrieval

生成前检索（提案）：
- Product：产品事实、可公开 / 禁止公开参数、应用、实拍、历史资料；
- Brand：Logo、VI、主色、字体、安全区、历史风格；
- Project：客户、项目、保密等级；
- Creative：历史 Prompt、成功 / 失败图片、Reject Reason、用户反馈。

事实规则（约束）：
- 性能数字、客户、项目、认证、减重比例、技术参数必须来自已验证知识源；无数据标记 `UNKNOWN`，禁止模型补全事实。
- 宣传主张所需事实为 `UNKNOWN` 时：不生成含该主张的画面与文案；进入 WAITING_USER，企微一次询问请求者补充或去掉该主张。`UNKNOWN` 不进 Prompt，不上文案。
- 任务保密级 = 所用知识条目的最高级别。用户要求的主张只能由更高级别的条目支撑时，任务升级，而不是把条目降级。

# 7. Security Router 【约束】

``` text
PUBLIC       → 外部与本地均可
INTERNAL     → 默认本地；外部仅限已签数据处理协议且不用于训练的服务，且 Brief 不含未公开参数
CONFIDENTIAL → 外部一律 DENY；本地 Worker + 本地 Generator
STRICT_LOCAL → 只在 DGX Spark / 本地；无本地能力的步骤转人工
```

- 级别 = max（产品、项目、参考素材、用户声明）；无法判定 → INTERNAL，不默认 PUBLIC。
- 管辖对象是所有外部调用：Creative Planner、Prompt Builder、Vision Review、Final Review、Jev、Generator。哪一步用了哪个模型、运行在哪，写入 task metadata。
- 分类发生在任何外部调用之前（状态机第 3 步），每个 revision 重做，级别只升不降。因此分类之前的 Intent Router 与 PARSING 只能用本地规则或本地小模型，不得调用外部服务。
- 降级只能由用户明确确认并留痕；系统不得自动降级。
- 未公开客户资料、配方、结构、内部测试数据不得未经判断上传第三方。

# 8. Generator Provider 【提案】

``` ts
interface GeneratorProvider {
 name: string;
 describe(): ProviderDescriptor;                       // 静态能力，供 Router 判断
 healthCheck(): Promise<ProviderHealth>;
 submit(req: GenerationRequest, idempotencyKey: string): Promise<GenerationJob>;
 getStatus(jobId: string): Promise<GenerationStatus>;
 getResults(jobId: string): Promise<GeneratedAsset[]>;
 cancel(jobId: string): Promise<void>;
}

interface ProviderDescriptor {
 locality: "local" | "external";
 supportedAspectRatios: string[];
 maxOutputsPerJob: number;
 supportsReferenceImages: boolean;
 costClass: "free" | "metered";
}
```

- Router 只看 `describe()` 与任务保密级做路由，不写死 Provider 名。
- 同一 `idempotencyKey` 重复 `submit` 必须返回同一 job，不得二次生成；没有原生幂等的 Provider（MJ Web）在自己内部用持久化的 key → job 表实现。
- 必须有 FakeProvider：确定性输出（固定图片）、可注入错误与延迟，用于 Workflow 测试、演练与 20 Job 验收。

标准错误：`AUTH_REQUIRED / RATE_LIMIT / UI_CHANGED / TIMEOUT / GENERATION_FAILED / POLICY_BLOCK / STORAGE_FAILED / UNKNOWN`。

# 9. Midjourney Web + Jev

``` text
Workflow Engine → MidjourneyWebProvider
→ Jev Controller → Playwright Browser Harness → Midjourney Web
```

Jev 的定义（提案）：Jev 是决定下一步浏览器动作的推理 Worker。输入是归一化后的页面快照与截图，输出是下面的受限动作。它背后的模型型号、托管位置（本地 / 外部）与单价在 Discovery 中确认并写入 `ARCHITECTURE.md`；它看得到 Prompt 与生成图，因此受 Security Router 约束，与 Generator 同级。

使用 persistent Chromium profile。支持登录保持、DOM/accessibility snapshot、截图、click/type/upload/scroll/wait/download、timeout、browser restart、session recovery。profile 目录含登录态，排除在日志、备份快照与仓库之外。

Jev 只能返回受限动作（约束）：

``` ts
type BrowserAction =
 | {type:"CLICK"; target:string}
 | {type:"TYPE"; target:string; text:string}
 | {type:"UPLOAD"; target:string; path:string}
 | {type:"SCROLL"; direction:"UP"|"DOWN"}
 | {type:"WAIT"; milliseconds:number}
 | {type:"VERIFY"; condition:string}
 | {type:"DONE"}
 | {type:"FAIL"; reason:string};
```

禁止 Jev 返回任意 shell/JS 直接执行。

Loop：`observe → normalize → Jev decide → validate → Playwright execute → verify`。validate 是确定性校验器：target 存在于当前快照、步数与超时未超、动作类型在白名单内；不通过即 FAIL，不让 Jev 重试。

Locator 优先：accessibility role/name → semantic text → stable attribute → Jev/visual → CSS fallback。所有 MJ-specific locator 只能存在 Provider 内（约束）。

第三方网站自动化可能受其服务条款限制。MidjourneyWebProvider 必须可禁用、可替换，系统不得依赖它才能运行（约束）；用 feature flag 控制，默认关闭，服务条款立场确认前不进生产。

# 10. ComfyUI / DGX Spark 【提案】

``` text
Workflow → ComfyUIProvider → ComfyUI API → DGX Spark → Synology
```

保密内容、内部项目、批量任务优先走本地。DGX Spark 是工作节点，不作为长期资产存储。ComfyUI 是 CONFIDENTIAL 与 STRICT_LOCAL 任务的唯一 Generator，所以在里程碑 M1 就接入，不留到保密路由之后。

# 11. 美工 Review Agent 【提案】

不得只给总分，必须输出：

``` json
{
 "pass": false,
 "checks": {
  "product_accuracy": "PASS",
  "industrial_plausibility": "PASS",
  "composition": "FAIL",
  "lighting": "PASS",
  "brand_consistency": "PASS",
  "publication_fit": "PASS",
  "text_safe_area": "FAIL",
  "fake_text_or_logo": "PASS",
  "confidentiality": "PASS",
  "ai_artifacts": "PASS"
 },
 "blocking": ["confidentiality", "fake_text_or_logo", "product_accuracy"],
 "reasons": ["右侧缺少文案安全区"],
 "revision_instruction": ["主体左移，右侧保留负空间"]
}
```

- 十项检查固定，不得少报。`blocking` 项 FAIL 的候选直接丢弃，不进候选池；非 blocking 项 FAIL 形成 `revision_instruction`。
- 每条 `revision_instruction` 必须映射到 Prompt Builder 的某个可改字段（构图、光线、比例、负面提示、参考图），否则算无效审核。
- Review 所用视觉模型受 Security Router 约束。
- 达到上限仍无 PASS：在 blocking 全 PASS 的候选里按非 blocking 通过数取最佳，附原因回传。

# 12. Production Agent

通过审核后负责（提案）：裁切、多比例、Logo/VI、准确文案、标题、副标题、必要 8K upscale、格式转换、企微预览、朋友圈 / PPT / 横版模板。

原则（约束）：**生成模型负责画面；Production Agent 负责准确文字和品牌元素。** Production Agent 是确定性流水线（模板 + 脚本），文案与参数只来自 Context.facts 中 `VERIFIED` 的条目，`UNKNOWN` 不上稿。

Final Review（提案）：POST_PROCESSING 的退出条件，由 Production Agent 流水线执行，两部分：确定性检查（文案每条数字可追溯到 `facts.source_ref`、尺寸与模板合规、Logo 与文字在安全区内）；对成品复跑一次第 11 节的 Vision Review，只看 blocking 三项（保密、伪文字/Logo、产品准确性）。不通过回 Production Agent 修正，最多 2 次，仍不过 → PAUSED 转人工。

# 13. Synology / Asset 【提案】

``` text
/CreativeAssets/YYYY/MM/<task_id>/
├── input/
├── references/
├── generations/r01/
├── approved/
├── final/
├── metadata/
├── task.json
├── brief.json
└── review.json
```

数据库只保存 metadata，NAS 保存二进制。记录 asset_id、task_id、revision、provider、prompt hash、checksum、confidentiality、review/publication state、每步所用模型与运行位置。

# 14. Knowledge Feedback 【提案】

任务完成后写回 task、brief、final prompt、provider、候选、采用 / 拒绝图片、reject reason、用户修改历史、final asset、publication target。允许未来复用"上次 L810 的风格"，但不得复制错误产品事实。写回按保密级分区，四级各一个分区；Knowledge Retrieval 只能读取级别不高于当前任务级别的分区，STRICT_LOCAL 分区只在本地节点可读。

# 15. 推荐工程结构 【提案】

``` text
apps/
  api/ worker/ wecom-gateway/ admin/
packages/
  workflow-engine/ task-domain/ creative-planner/
  knowledge-retrieval/ security-router/ prompt-engine/
  generator-router/
  providers/{midjourney-web,comfyui,gpt-image,fake}/
  jev-controller/ browser-harness/ vision-review/
  production-agent/ asset-manager/ synology-storage/
  knowledge-writer/ wecom-publisher/ observability/ shared/
infra/
  docker/ migrations/ monitoring/
docs/
  architecture/ runbooks/ adr/
```

优先沿用现有仓库已有的框架；候选为 NestJS、必要时 FastAPI、Next.js/React/TS、Playwright、PostgreSQL、Redis/BullMQ、Synology、DGX Spark + ComfyUI。M0 清单核对后写入 `ARCHITECTURE.md`。**不要引入 Kubernetes**（约束）。

# 16. Queue、幂等和恢复 【约束】

长任务禁止阻塞 HTTP：

``` text
WeCom webhook → API → Task DB → Queue → Worker → Provider
```

所有 webhook、retry、callback 必须幂等。幂等键按来源：

``` text
企微 webhook   : wecom + message_id + action + revision
Provider 回调  : provider + provider_job_id + event
内部重试       : task_id + state + attempt
企微发送       : task_id + revision + message_kind（状态 / 候选 / 成品）
```

必须测试：重复 webhook、知识库不可用、Provider 不可用、MJ 登录过期 / UI 改版、browser crash、generation timeout、NAS 断线、Review timeout、企微发送失败、server restart、WAITING_USER 期间重启、同一会话多任务并存。

Browser 错误保存 screenshot、DOM/accessibility snapshot、last action、URL、task_id、provider_job_id、timestamp。

# 17. Observability 【提案】

全链路字段：

``` text
task_id / trace_id / wecom_message_id / revision / security_level /
workflow_state / provider / provider_job_id /
browser_session_id / asset_id / model（每次调用）/ cost（token 或 credit）
```

指标：task_success_rate、generation_success_rate、average_generation_time、average_review_loops、provider_failure_rate、browser_recovery_rate、publish_success_rate、human_intervention_rate、cost_per_completed_task。

日志不得保存密码、完整 Token、Cookie、敏感配方（约束）。

# 18. 里程碑 【提案；顺序是主要待裁决项】

每个里程碑按 `WORKFLOW.md` 第 2 节以 M 级执行，轮数预算 50；由 Astra 拆成 Atomic + Testable + Reversible 的 Task，每个 Task 带 `GOVERNANCE.md` 第 4 节的 12 个字段。验收写成可执行的命令或可观察结果。

**M0 审计。** 不是实施里程碑，是 Discovery 的输入采集：搜索员（小模型）列出现有企微接入、知识库、Synology、Jev、DGX/ComfyUI 的入口文件与配置位置，写入 `discovery/inventory.md`，不超过 60 行。Fable 与 Astra 各自基于这份清单做 Discovery，不通读仓库，禁止先大改。

**M1 最小闭环（本地优先）。**

``` text
测试入口（代替企微：建任务，在 WAITING_USER 自动回复"采用A"）→ Workflow Engine（完整状态机，持久化）
→ Prompt → Generator Router → FakeProvider + ComfyUIProvider → 完成检测 → 图片 → Synology
M1 的 REVIEWING、POST_PROCESSING、PUBLISHING 为直通空实现，只记日志；M2 到 M5 逐个替换
```

验收：
- FakeProvider 连续 20 个 Job 全部走到 COMPLETED，无人工介入；进程在 GENERATING、WAITING_USER、ARCHIVING 各被 kill 一次后从持久化状态恢复并完成，不重复提交生成、不重复归档。
- ComfyUIProvider 连续 5 个 Job 完成，图片与 task_id、revision、checksum 正确绑定。
- 注入 TIMEOUT / GENERATION_FAILED / STORAGE_FAILED 各一次，任务进入 RETRYING 或 FAILED，诊断包完整。

**M1b MJ Web 可行性。** 与 M1 并行，互不依赖；flag 默认关。

``` text
Workflow → MidjourneyWebProvider → Jev → Playwright → MJ Web → 图片 → Synology
```

验收：连续 20 个 Job 无人工点击；登录过期、UI 改版（改一个 locator 模拟）、浏览器崩溃三种异常各恢复一次；每步动作经校验器；诊断包含 screenshot、快照、last action、URL、task_id、provider_job_id。

说明：v1.0 把 MJ Web 作为 Phase 1 唯一 Provider，与第 9 节"系统不得依赖它才能运行"、第 20 节"保密任务不会错误进入外部 Provider"矛盾，且 ComfyUI 在 v1.0 的任何 Phase 里都没有出现。改为本地优先、MJ 并行验证。若 DGX/ComfyUI 未就绪，由用户在 Conflict Matrix 裁决是否让 M1 先用 MJ Web。

**M2 WeCom In/Out。** 新任务、状态回复、候选与成品回传、conversation → task 映射、第 3 节指令表、WAITING_USER 与超时。验收：重复 webhook 不重复建任务；一个会话两个任务并存时指令正确路由；企微发送失败重试 3 次后 PAUSED 并留诊断。

**M3 Knowledge + Security Router。** 事实检索、`UNKNOWN` 处理、四级保密路由覆盖全部外部调用。验收：CONFIDENTIAL 任务从建立到完成没有任何外部网络调用（用出站代理日志证明）；`UNKNOWN` 主张触发一次询问，且不出现在 Prompt 与文案里。

**M4 Review Loop。** Vision Review、十项 checks、blocking 规则、`revision_instruction` 到字段的映射、最多 3 轮、最佳候选兜底。验收：构造一张缺文案安全区的图，系统给出可执行修订并在 3 轮内 PASS 或按规则兜底回传。

**M5 Production + Feedback。** VI/Logo/文案、多尺寸、8K、正式归档、经验写回（含分区）。验收：成品文案中每一条数字都能追溯到 `facts.source_ref`。

**M6 无限画布 / 高级管理端。** 最后实施，不得阻塞主链。

# 19. 开发规则（与治理规则对齐）

1.  先 Discovery，再冻结，再计划，再实施（`GOVERNANCE.md` 第 0 节）。
2.  计划在 `plans/`，每个 Task 有 `GOVERNANCE.md` 第 4 节的 12 个字段；看板是 `ARTIFACT-BOARD.md`，字段集见第 5 节。两者都由 Astra 建立维护。不用 `IMPLEMENTATION_PLAN.md`。
3.  每个 Task：Sonnet 实现 → Mechanical Gate（build、typecheck、lint、test，全部经 run-quiet）→ Opus 与 GPT 审核模型对抗审核 → PASS Gate。Repair Loop 最多 3 轮，仍有 Critical/High/Medium 即 BLOCKED，不得虚假 PASS。
4.  MJ DOM 逻辑不得散落业务代码。
5.  不得用"让 GPT 自己决定下一步"替代状态机。
6.  不得静默吞错。
7.  不得为局部修复重写无关模块；最小修改，回归测试才算范围内。
8.  新配置进入 `.env.example`，秘密不得入库。
9.  DB 变化必须 migration。
10. 关键架构决策写 ADR（`docs/adr/`）。改动已冻结的 `ARCHITECTURE.md` 走变更申请：回到 Conflict Matrix 对应行重新裁决，不在 Task 里悄悄改。
11. 每个里程碑可独立运行、验证和回滚。
12. 冲突时按 `GOVERNANCE.md` 第 16 节优先级：用户明确指令 → 安全及数据保护 → `REQUIREMENTS.md` → Acceptance Criteria → `ARCHITECTURE.md` 与已批准计划 → 看板 → Reviewer 建议 → 实现方便。第一性原则体现在 `REQUIREMENTS.md` 的非目标里，不作为绕过上级约束的理由。
13. 额度按 `AGENTS.md`：搜索定位不通读；只读行段；测试与构建输出经 run-quiet；同一问题两次修复无效即停止取证；回复只讲结论；密钥、Cookie、客户资料不进提示词、提交信息与回复。

# 20. Definition of Done

产品侧（约束）：
- 员工只用企微即可创建、修改、选择和接收任务，候选与成品都回到原企微上下文；
- Workflow 状态可持久化和恢复，重启不会丢失任务，也不重复副作用；
- Generator Provider 可替换，至少 FakeProvider 与一个本地 Provider 可用；
- Jev + Browser 局部 Loop 有步数、超时、错误恢复；
- 保密任务不会错误进入外部 Provider，也不进入外部推理 Worker；
- Review FAIL 可自动形成明确修订并重试，最多 3 轮后停止；
- 成品和元数据进入 Synology / 知识库；
- 全链路有 task_id/trace，失败可诊断；
- 普通员工不需要理解任何底层模型或浏览器自动化。

开发侧（`GOVERNANCE.md` 第 12、14 节）：每个 Task 同时满足 Implementation Completed、Acceptance Criteria Passed、Mechanical Gate Passed、Opus PASS、GPT PASS、Evidence Recorded；全部 Task PASS 后由 Fable + Astra 对照 `REQUIREMENTS.md` 与 `ARCHITECTURE.md` 做 FINAL SYSTEM REVIEW，通过才是 PROJECT DONE。

# 21. 首次执行指令（Project Router）

收到本文件后**不要立即编码**。按顺序：

1.  M0 清单：搜索员（小模型）产出 `discovery/inventory.md`，不超过 60 行。
2.  双 Discovery：Fable（Claude Code）写 `discovery/fable.md`；Astra（Codex）写 `discovery/astra.md`。输入相同（本文件 + inventory），互不看对方。固定格式：目标与非目标、需求清单、关键假设、架构提案、风险、未决问题。每项只写结论与依据，不贴源码。
3.  Conflict Matrix：Astra 合成 `discovery/conflict-matrix.md`，逐条标注一致 / 冲突 / 仅一方提出。一致项直接冻结；只有冲突项与高风险单方项交用户。下面的已知待裁决项预先列入。
4.  用户逐条裁决；未裁决的冲突项不得进入计划。
5.  Requirement Freeze → `REQUIREMENTS.md`；Architecture Freeze → `ARCHITECTURE.md`，Fable 复核一次。
6.  Astra 按第 18 节里程碑写 `plans/` 与 `ARTIFACT-BOARD.md`。
7.  Sonnet 按看板逐 Task 实施；每个 Task 过 Mechanical Gate → Opus ‖ GPT 审核 → PASS Gate；BLOCKED 交回 Astra。
8.  全部 Task PASS 后 FINAL SYSTEM REVIEW。

已知待裁决项（预填入 Conflict Matrix）：

1.  M1 真实 Provider：ComfyUI 优先（本文推荐）还是 MJ Web 优先。
2.  Jev 背后的模型与托管位置；是否允许它看到 INTERNAL 级内容。
3.  INTERNAL 级的外部服务白名单（哪些服务有数据处理协议）。
4.  MJ Web 自动化的服务条款立场：允许生产使用、仅内部试验、或禁用。
5.  技术栈：沿用现有仓库的框架，还是按第 15 节新建。
6.  是否允许 Codex（GPT）承担实现（默认 Sonnet）。

最终架构原则保持不变：

> **WeCom 是人机界面；Workflow Engine 是控制中心；GPT/Claude 是推理 Worker；Jev 是 Browser Action Worker；Playwright 是执行器；Midjourney/ComfyUI 是可替换 Generator；Synology/知识库是企业资产层；最终结果回到 WeCom。**

# 附：术语

| 术语 | 含义 |
| --- | --- |
| Fable / Astra / Sonnet / Opus / GPT 审核模型 | 开发侧的模型角色，见 `GOVERNANCE.md` 第 2 节；不出现在运行时 |
| Jev | 运行时的浏览器动作决策 Worker，见第 9 节 |
| Generator / Provider | 运行时的生图后端及其统一接口，见第 8 节 |
| Mechanical Gate / PASS Gate / Repair Loop | 开发侧每个 Task 的门禁，见 `GOVERNANCE.md` 第 7 到 11 节 |
| creative_review_max_loops | 运行时创意审核轮数上限，与 Repair Loop 无关 |
| run-quiet | `scripts/run-quiet.sh`，测试与构建输出裁剪 |
| DGX Spark / ComfyUI | 本地生图节点与其调度层 |
| Synology | NAS，二进制资产层 |
| WeCom | 企业微信 |
