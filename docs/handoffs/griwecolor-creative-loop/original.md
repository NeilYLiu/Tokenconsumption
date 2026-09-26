# GRIWECOLOR AI Creative Production Loop

## Codex 开发 Handoff

> Version: v1.0\
> Date: 2026-09-26\
> 核心：**WeCom In → Autonomous Creative Loop → WeCom Out**

# 1. 第一性目标

本项目不是 Midjourney 自动化脚本，而是企业 AI
创意生产系统。员工只通过企业微信提出需求、修改和选择方案；后台完成知识检索、创意规划、保密判断、生成、审核、迭代、归档和回传。

**第一性目标：把企微中的自然语言宣传需求，稳定转换为符合产品事实、品牌规范、保密要求和视觉质量要求的可用宣传资产，并通过企微闭环交付。**

不得为了 Agent 数量、模型对抗、Prompt 长度、架构复杂度或炫技 UI
牺牲稳定性和实际宣传效果。

# 2. 架构原则

1.  企业微信是普通员工唯一业务入口和出口。
2.  Workflow Engine 是控制中心；GPT、Claude、Jev 都是 Worker。
3.  Generator 必须 Provider 化：Midjourney Web、ComfyUI、GPT Image
    及未来 Provider 可替换。
4.  Jev = Action Decision Layer；Playwright = Browser Executor。
5.  无限画布后续作为高级美工工作台，不作为主入口。
6.  模型不得替代确定性状态机。

``` text
WeCom → Gateway → Intent Router → Workflow Engine
  ├─ Knowledge Retrieval
  ├─ Creative Planner
  ↓
Creative Brief → Prompt Builder → Security/Generator Router
  ├─ Midjourney Web → Jev → Playwright
  ├─ ComfyUI → DGX Spark
  └─ Other Provider
  ↓
Candidate Pool → Vision Review
  ├─ FAIL → Revision → 再生成（最多3轮）
  └─ PASS → Synology/KB → Production Agent
             → Final Review → WeCom
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

后续自然语言支持：`采用A`、`重新生成`、`A背景亮一点`、`B列车环境更现代`、`查看任务`、`停止任务`、`查看原图`、`生成横版`。

必须通过 conversation/message 找回 task_id 和
revision；修改请求只改变用户点名的约束。

# 4. Workflow 状态机

``` text
RECEIVED → PARSING → CONTEXT_RETRIEVAL → BRIEFING
→ SECURITY_CLASSIFICATION → PROVIDER_SELECTION → GENERATING
→ REVIEWING → REVISION_REQUIRED → GENERATING
→ APPROVED → POST_PROCESSING → ARCHIVING
→ PUBLISHING → COMPLETED
```

异常：`WAITING_USER / RETRYING / PAUSED / FAILED / CANCELLED`。

所有状态持久化；服务器、Worker、浏览器重启后可恢复。默认：

``` yaml
creative_review_max_loops: 3
browser_action_max_steps: 50
generator_retry: 2
publish_retry: 3
```

超过上限进入 WAITING_USER，企微返回最佳候选及原因，禁止无限 Loop。

# 5. Creative Context

每个任务保存版本化 Context：

``` json
{
 "task_id":"ART-20260926-0081",
 "product":"AN2-L810",
 "purpose":"WeCom Moments",
 "audience":"rail transit customer",
 "message":["lightweight","NVH performance"],
 "visual_style":["modern","industrial"],
 "aspect_ratio":"4:5",
 "output_count":3,
 "confidentiality":"PUBLIC",
 "allowed_claims":[],
 "forbidden_claims":[],
 "reference_assets":[],
 "revision":1
}
```

# 6. Knowledge Retrieval

生成前检索： -
Product：产品事实、可公开/禁止公开参数、应用、实拍、历史资料； -
Brand：Logo、VI、主色、字体、安全区、历史风格； -
Project：客户、项目、保密等级； - Creative：历史
Prompt、成功/失败图片、Reject Reason、用户反馈。

性能数字、客户、项目、认证、减重比例、技术参数必须来自已验证知识源；无数据标记
`UNKNOWN`，禁止模型补全事实。

# 7. Security Router

``` text
PUBLIC       → external/local allowed
INTERNAL     → policy routing
CONFIDENTIAL → external default DENY
STRICT_LOCAL → DGX Spark/local only
```

未公开客户资料、配方、结构、内部测试数据不得未经判断上传第三方。

# 8. Generator Provider

``` ts
interface GeneratorProvider {
 name: string;
 healthCheck(): Promise<ProviderHealth>;
 submit(req: GenerationRequest): Promise<GenerationJob>;
 getStatus(jobId: string): Promise<GenerationStatus>;
 getResults(jobId: string): Promise<GeneratedAsset[]>;
 cancel(jobId: string): Promise<void>;
}
```

标准错误：`AUTH_REQUIRED / RATE_LIMIT / UI_CHANGED / TIMEOUT / GENERATION_FAILED / POLICY_BLOCK / STORAGE_FAILED / UNKNOWN`。

# 9. Midjourney Web + Jev

``` text
Workflow Engine → MidjourneyWebProvider
→ Jev Controller → Playwright Browser Harness → Midjourney Web
```

使用 persistent Chromium profile。支持登录保持、DOM/accessibility
snapshot、截图、click/type/upload/scroll/wait/download、timeout、browser
restart、session recovery。

Jev 只能返回受限动作：

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

Loop：`observe → normalize → Jev decide → validate → Playwright execute → verify`。

Locator 优先：accessibility role/name → semantic text → stable attribute
→ Jev/visual → CSS fallback。所有 MJ-specific locator 只能存在 Provider
内。

第三方网站自动化可能受其服务条款限制；MidjourneyWebProvider
必须可禁用、可替换，系统不得依赖它才能运行。

# 10. ComfyUI / DGX Spark

``` text
Workflow → ComfyUIProvider → ComfyUI API → DGX Spark → Synology
```

保密内容、内部项目、批量任务优先走本地。DGX Spark
是工作节点，不作为长期资产存储。

# 11. 美工 Review Agent

不得只给总分，必须输出：

``` json
{
 "pass":false,
 "checks":{
  "product_accuracy":"PASS",
  "brand_consistency":"PASS",
  "composition":"FAIL",
  "industrial_plausibility":"PASS",
  "publication_fit":"PASS"
 },
 "reasons":["右侧缺少文案安全区"],
 "revision_instruction":["主体左移，右侧保留负空间"]
}
```

至少检查产品准确性、工业合理性、构图、光线、品牌一致性、发布适配、文字安全区、伪文字/Logo、保密性、明显
AI Artifact。FAIL 必须形成可执行 revision_instruction。

# 12. Production Agent

通过审核后负责：裁切、多比例、Logo/VI、准确文案、标题、副标题、必要 8K
upscale、格式转换、企微预览、朋友圈/PPT/横版模板。

原则：**生成模型负责画面；Production Agent 负责准确文字和品牌元素。**

# 13. Synology / Asset

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

数据库只保存 metadata，NAS 保存二进制。记录
asset_id、task_id、revision、provider、prompt
hash、checksum、confidentiality、review/publication state。

# 14. Knowledge Feedback

任务完成后写回 task、brief、final
prompt、provider、候选、采用/拒绝图片、reject
reason、用户修改历史、final asset、publication target。允许未来复用"上次
L810 的风格"，但不得复制错误产品事实。

# 15. 推荐工程结构

``` text
apps/
  api/ worker/ wecom-gateway/ admin/
packages/
  workflow-engine/ task-domain/ creative-planner/
  knowledge-retrieval/ security-router/ prompt-engine/
  generator-router/
  providers/{midjourney-web,comfyui,gpt-image}/
  jev-controller/ browser-harness/ vision-review/
  production-agent/ asset-manager/ synology-storage/
  knowledge-writer/ wecom-publisher/ observability/ shared/
infra/
  docker/ migrations/ monitoring/
docs/
  architecture/ runbooks/ adr/
```

优先沿用：NestJS、必要时
FastAPI、Next.js/React/TS、Playwright、PostgreSQL、Redis/BullMQ、Synology、DGX
Spark + ComfyUI。**不要引入 Kubernetes。**

# 16. Queue、幂等和恢复

长任务禁止阻塞 HTTP：

``` text
WeCom webhook → API → Task DB → Queue → Worker → Provider
```

所有 webhook、retry、callback 必须幂等。建议
key：`source + message_id + action + revision`。

必须测试：重复 webhook、知识库不可用、Provider 不可用、MJ 登录过期/UI
改版、browser crash、generation timeout、NAS 断线、Review
timeout、企微发送失败、server restart。

Browser 错误保存 screenshot、DOM/accessibility snapshot、last
action、URL、task_id、provider_job_id、timestamp。

# 17. Observability

全链路字段：

``` text
task_id / trace_id / wecom_message_id / revision /
workflow_state / provider / provider_job_id /
browser_session_id / asset_id
```

指标：task_success_rate、generation_success_rate、average_generation_time、average_review_loops、provider_failure_rate、browser_recovery_rate、publish_success_rate、human_intervention_rate。

日志不得保存密码、完整 Token、Cookie、敏感配方。

# 18. 实施阶段

**Phase 0：现有系统审计。** 确认企微、知识库、Synology、Jev、DGX/ComfyUI
和仓库结构，禁止先大改。

**Phase 1：最小 PoC。**

``` text
测试入口 → Workflow → Prompt → Jev+Browser
→ MJ Web → 完成检测 → 图片 → Synology
```

验收：连续 20 个 Job；无人工点击；图片与 task_id
正确绑定；浏览器异常可恢复；失败有诊断。

**Phase 2：WeCom In/Out。** 接入新任务、状态回复、图片回传、thread/task
映射、修改指令。

**Phase 3：Knowledge + Security Router。**
加产品/品牌知识、事实约束、保密路由。

**Phase 4：Review Loop。** 加 Vision Review、Failure
Classification、Prompt Revision、最多 3 轮。

**Phase 5：Production + Feedback。** 加 VI/Logo/文案、多尺寸、8K、正式
NAS 归档和经验写回。

**Phase 6：无限画布/高级管理端。** 最后实施，不得阻塞主链。

# 19. Codex 开发规则

1.  先审计，再计划，再实施。
2.  先创建 `IMPLEMENTATION_PLAN.md` 和任务看板。
3.  每个模块完成后运行测试、lint、typecheck。
4.  MJ DOM 逻辑不得散落业务代码。
5.  不得用"让 GPT 自己决定下一步"替代状态机。
6.  不得静默吞错。
7.  不得为局部修复重写无关模块。
8.  新配置进入 `.env.example`，秘密不得入库。
9.  DB 变化必须 migration。
10. 关键架构决策写 ADR。
11. 每个 Phase 可独立运行、验证和回滚。
12. 第一性原则优先于架构完美主义。

# 20. Definition of Done

完成必须满足： - 员工只用企微即可创建、修改、选择和接收任务； - Workflow
状态可持久化和恢复； - Generator Provider 可替换； - Jev+Browser 局部
Loop 有步数/超时/错误恢复； - 保密任务不会错误进入外部 Provider； -
Review FAIL 可自动形成明确修订并重试； - 最多 3 轮后停止； -
成品和元数据进入 Synology/知识库； - 最终结果返回原企微上下文； -
全链路有 task_id/trace； - 失败可诊断； - 重启不会丢失任务； -
普通员工不需要理解任何底层模型或浏览器自动化。

# 21. Codex 首次执行指令

Codex 收到本文件后，**不要立即编码**。先输出：

1.  当前仓库/部署环境审计结果；
2.  已有模块与本 Handoff 的映射；
3.  缺失依赖；
4.  风险和未知项；
5.  `IMPLEMENTATION_PLAN.md`；
6.  分 Phase 任务看板；
7.  Phase 1 PoC 的最小文件变更范围；
8.  测试与回滚方案。

待计划确认后再实施。

最终架构原则保持不变：

> **WeCom 是人机界面；Workflow Engine 是控制中心；GPT/Claude 是推理
> Worker；Jev 是 Browser Action Worker；Playwright
> 是执行器；Midjourney/ComfyUI 是可替换
> Generator；Synology/知识库是企业资产层；最终结果回到 WeCom。**
