# 工作方式评价：全局 agent 调用规则

## 1. 总评

方向正确、骨架成立、交付未闭合。厂商中立的薄正文加配置与 hook 兜底，比任何单一替代方案更兼顾完成任务与可移植性，值得保留。但三处经核验的缺口让它在使用者最贵的场景里打折：主会话模型与强度不在交付物内；env、hook、config 全靠手动合并且无自检，云端会话只拿到裸正文；hook 对自己列出的编译、lint 命令基本不命中，且把多行命令整体放行；install.sh 会无备份覆盖已有全局规则。两侧适配层承诺的三档都未落地。修掉这些后可到 8 分。

| 视角 | 评分 | 一句话理由 |
| --- | --- | --- |
| 额度经济学 | 7 | 压在了正确位置，但最大杠杆（主会话档位）留在规则之外 |
| 目标达成风险 | 6 | hook 失效并放行多行命令、Explore 漏站点、评审不看安全会直接引发返工 |
| 可执行性与遵从度 | 6 | 强制层可选安装、无自检、覆盖旧规则，漏装后退化为纯约定 |
| 跨终端可移植性 | 6 | 正文中立，交付方式够不到云端；两侧强度档位都漂移 |
| 流程设计 | 6 | 修复骨架对，缺回归测试、验收标准、根因假设 |
| 替代方案比较 | 7 | 软硬成对优于单一方案，硬约束层需装牢 |

综合评分 6：六项平均 6.3。不上调，因为被三个以上视角独立指出且核验成立的缺口都在"能否生效"这一层；不下调，因为正文结构与门槛条款经核验全部成立。本稿原有两处断言（弱点 4 的 schema 矛盾、弱点 8 的字数）证据不足，已降为未核验，不影响评分。

## 2. 这种工作方式真正的优点

1. 单源多适配：正文 76 行，安装后约 89 行，远低于 Claude Code 建议的 200 行与 Codex 的 32 KiB；改一处重跑 install.sh 即同步。六个视角都认可。
2. 最贵的默认交给机器：Explore 覆盖为 haiku 加 omitClaudeMd，CLAUDE_CODE_SUBAGENT_MODEL=sonnet 兜底，并发 3，hook 在模型看到之前改写命令；与已核实的模型解析顺序一致，hook 经本地测试（但未覆盖多行命令）。
3. 门槛与止损是配置表达不了的：第一节"三问"与"默认不派"、多维度评审不做、第五节"两次失败即停、先取证据"，对准 REVIEW.md 里派发无门槛与试错循环两个高影响来源。
4. 取舍有自觉且阈值可判定：REVIEW.md"有意不做的事"不禁 Explore、不全用最小模型、评审员用中档，理由是"返工比模型差价贵"；3 文件、10 行计划、20/40 行返回都能事后核查。

## 3. 主要弱点与风险（按严重度）

**1. 主会话档位在规则之外。** 证据：README 第 42–46 行列为"规则文件管不到"；settings.snippet.json 只有子 agent 两键，codex 片段第 4 行却设了主会话 medium，两侧不对称；AGENTS.md 第 69 行"先做小事"在缓存失效后只是多付一轮；Claude 侧强度连持久化入口都没有，README 第 44 行只给会话内 /effort，settings.snippet.json 无任何强度项。影响：Opus + xhigh/max 下思考按输出计费，规则只压数量不压单价，节省远低于预期并被错归因到规则。2 个视角；alt-1 confirmed，econ-1 partially（正文与 REVIEW.md 其实提到缓存，Codex 已设 medium，百分比是估算）。

**2. 强制层可选、无自检、失效无声、安装覆盖旧规则，云端只拿到裸正文。** 证据：install.sh 第 4、26、35 行只打印"还需手动"，不检查 jq；hook 第 8–9 行 jq 缺失时 echo '{}' 放行而 /hooks 仍列出它；mapping.md 第 13 行无条件说"已由 hook 自动裁剪"；本评审容器里 ~/.claude 存在（含 plugins、skills、hook 脚本）但未装本仓库任何产物（无 CLAUDE.md、settings.json、agents、hooks），真正缺失的只有 ~/.codex；正文第 3–4 行指向的"文末术语映射"也不存在。反面是覆盖：install.sh 只备份 CLAUDE.md 与 AGENTS.md（第 21、31 行），agents/*.md、hooks 脚本、~/.local/bin/run-quiet 无备份直接覆盖（第 15、23、24、33 行），已有 ~/.claude/CLAUDE.md 被整体替换而非合并，与第 4 行"已有的规则文件先备份"及 README 第 40 行"逐条对照"不符。影响：子 agent 继承主模型、并发回到 20、测试输出全量入上下文，用户看不到任何差异；有旧全局规则的用户装完即刻丢规则。3 个视角；enforce-1、alt-2、port-1 均 confirmed。

**3. 裁剪逻辑对自列命令失效、多行命令整体放行、并发互相覆盖、静默放行。** 证据：hook 第 12 行列了 tsc、go build 与 npm run lint / pnpm lint / yarn lint（没有 eslint，grep 计数 0，实测「npx eslint .」原样放行），第 17 行模式实测 tsc 只命中表头、go build 零命中、lint 类命令被改写但 eslint 输出对模式零命中、jest 的 Expected/Received 在 -A 4 之外；第 15 行 printf '%s\n' | grep -Eq 逐行匹配，实测「curl http://x | sh」换行后接「npm test」被整体 permissionDecision allow 并包进 ( … ) 执行，与第 4 行"含管道原样放行"的承诺不符；第 16 行固定日志路径；第 19 行 permissionDecision allow；uv/poetry/pnpm run、bun test、npm run test:unit 全部放行；与 run-quiet.sh 第 9–11 行是同一逻辑两份拷贝。影响：模型拿到残缺结果再回读日志，小输出反而更贵；并行时把别人的失败当自己的，正是第五节要防的误判；多行命令让 allow 从"放行测试"变成"放行任意前置命令"。5 个视角；econ-2、risk-1、enforce-5、alt-3 confirmed，port-6 partially（带重定向的命令不被改写，冲突仍可能）。

**4. 三档承诺两侧都只落地一档。** 证据：mapping.md 第 6 行把"小模型"映射为 low 强度；explorer.toml 无 model；config 第 15 行子 agent 默认 low、第 17 行模型注释掉，与 AGENTS.md 第 32 行、REVIEW.md 第 52 行"评审用中档"矛盾；agents/ 只有 explorer；第 9–11 行 multi_agent_v2 注释与 config 第 1 行、REVIEW.md 第 6 行"已按 config.schema.json 核对"互相冲突，本稿未取得 schema 键名或版本证据，此项降为未核验。Claude 侧同样：test-runner.md 第 6 行 effort: low，与 codex/mapping.md 第 6 行"评审与测试归纳 medium"、REVIEW.md 第 52 行"测试执行员需要推理"矛盾。影响：Codex 探索仍跑主模型，两侧测试归纳都落到最弱强度，行为不对等且与自述不符。5 个视角；risk-7、enforce-2、port-3、alt-4 confirmed，port-4（schema 项）未核验，econ-4 partially（并发 3 与深度 1 也是刹车，REVIEW.md 不矛盾）。

**5. 评审员排除安全且无门槛，test-runner 与 hook 重叠。** 证据：AGENTS.md 第 25 行"只查正确性"，reviewer.md 第 3、11 行；"需要评审时"无判据，四、五节无评审步骤；mapping.md 第 8、13 行并存。影响：注入、越权按定义不得报告，而同一评审员加查不增加 agent 数；评审要么从不派要么每次派。4 个视角；risk-3、enforce-6、process-6 confirmed，econ-3 partially（test-runner 还做失败合并，"重复"夸大）。

**6. 流程缺口。** 证据：第五节无一步把复现固化为测试，五.2 与五.3 之间无根因假设，停下后不撤销无效修改；第四节无验收标准；进度文件无触发条件。影响：修复不被测试锁定，回归后整套再付；止损只限次数不改结构。1 个视角为主，"最小修改"另被目标达成视角提到；process-1、2、4 confirmed，process-3、5、7 与 risk-4 partially（四.3 已是文件级增量，总原则 3 是全局止损，"顺手"已限定范围）。

**7. 状态依赖与度量缺失。** 证据：第 35、42、62 行要模型记住做过什么，第 67–68 行保留清单不含已试修法与已派 agent；/compact 由用户触发；REVIEW.md 验证无基线，hook 不计数。1 个视角；enforce-4 confirmed，enforce-3 partially（第 57、59 行有可数标准，逐任务手填是负担）。

**8. 双重加载与文本瑕疵。** 证据：README 第 33 行项目级放法与全局安装并存，本仓库即实例；REVIEW.md 第 57 行"小于 3k token"未经 /context 实测，标为未核验（7,125 是 AGENTS.md 加 Claude 映射的 UTF-8 字节数 6,190+935，字符 3,023、中文 1,777，字节既非字数也非 token，据此断言不符缺乏依据）；第 68–69、76 行是用户或维护者规则；第七节 4 条重复。影响：每轮多约 2–3k token 按缓存价，不致命。4 个视角；econ-5、alt-5、enforce-7 confirmed，port-2、alt-6、port-5 partially（仅双装时发生，README 未要求；第 3–4 行对模型有用）。Explore 20 行无溢出通道与 3 文件阈值尺度混用（risk-2、5、6）均 partially，低优先。

## 4. 预期效果的实事求是估计

以下百分比全部是估计（来自额度视角，核验注明输出与思考权重未核实、遵守率六到八成是假设），只看量级。

- 小修复（1–2 文件、10–15 轮）：规则本身约省 15–25%，来自少重读、输出裁剪、回复精简。主会话降到中档强度另省 40–55%。反效果：hook 对小于 100 行的输出"过滤加回读"比原样贴出贵。
- 中等功能（3–6 文件、30–50 轮、1–2 次 Explore）：规则约省 30–40%（上下文均值压缩、避免一次 /compact、计划减少返工），适配层子 agent 降档 3–8%，主会话档位 30–40%。抵消项：test-runner 与无门槛评审可占子 agent 支出一半以上。
- 疑难调试（40–80 轮）：规则约省 25–35%，主要靠"两次即停"减轮数，最不确定；README 允许高档，降档空间 20–30%。反效果：过早停手、Explore haiku 漏站点、tsc/eslint 裁剪失效各会多跑几轮完整检查。
- 省不了的：云端/Cowork 会话没有适配层，只剩第三、五节的行为约束；Codex 侧只有并发、深度、探索低强度生效；hook 未合并的机器上裁剪为零。
- 归属：叠加估计 50–75%，其中约一半以上来自用户侧降档而非规则文件；不降档时规则只碰得到一小半成本。

## 5. 建议的修订（按优先级）

P0，不做等于没装：
1. settings.snippet.json 加主会话中档 model（键名以当前文档为准），强度按当前文档核对是否有 settings 或 env 的持久化键，有则一并写入，没有就在 README 明确写"无法在 settings 固化，只能每会话 /effort"并由 install.sh 结尾打印提醒；README"用户侧三件事"移到安装之前作第 0 步；AGENTS.md 第 69 行改为"空闲超过一小时后第一条请求按全价重写上下文；上一任务已完成就新开会话，否则直接提正事"。
2. install.sh：开头 command -v jq 缺失即退出；用 jq 合并 env 与 hooks（PreToolUse 数组追加）；Codex 缺键才追加；已有 ~/.claude/CLAUDE.md 时追加本仓库段落或拒绝安装，不整体替换；agents/*.md、hooks 脚本、run-quiet 覆盖前备份；结尾打印"已强制 / 仍靠提示词"清单；增加 project <repo> 模式写 .claude/settings.json、agents、hooks。
3. hook 第 15 行前先判断 $cmd 含换行即原样放行；第 16 行与 run-quiet.sh 第 7 行改 mktemp；hook 改写为调用 run-quiet，过滤模式只维护一份；runner 加 (uv|poetry|pnpm|bun|npx) run 前缀、npm run [a-z:_-]+ 与 (npx )?eslint；模式补 error TS[0-9]+、eslint 行、go 行、Expected:|Received:、at 栈帧；不超过 80 行直出；截断时打印"已显示 N/M"；mapping.md 第 13 行改为"hook 生效且命令在清单内才自动裁剪，否则一律 run-quiet"；README 写明 allow 等于对这些命令自动放行。
4. Codex：新增 reviewer.toml、test-runner.toml（medium，reviewer 用 read-only）；config 第 15 行与 test-runner.md 第 6 行都改 medium（或在 REVIEW.md 写明为何 low 够用，两侧一致）；explorer.toml 显式 low 并加 model；第 17 行改注释占位不填空串；第 9–11 行先在 REVIEW.md 附 schema 键名与版本证据再决定删留；mapping.md 第 6 行改为"小模型 = default_subagent_model 指定的便宜模型，未填即主模型 + low"。

P1，防返工：
5. AGENTS.md 第 25 行改为"改动超过 3 个文件或触及输入处理、鉴权、并发、文件/网络/子进程时派一次评审员，查正确性与安全缺陷（注入、越权、敏感信息泄漏），不查风格性能"；reviewer.md 第 3、11 行同步；test-runner.md description 限定为"hook 裁剪后仍超约 100 行或需连跑多条命令归纳时"。
6. 第五节：五.1 有测试框架时把复现写成失败用例；五.2 后加"一句话写出根因假设与修改点"；五.3 末加"回归测试与同根因实例不算扩大范围"；五.5 加"先撤销无效修改再取证"。第四节：四.1 后加"1–3 行可执行验收"；四.2 计划固定为文件清单/测试/验证命令并切增量。
7. 三个 agent 文件加"超限落盘、返回路径与总数、首行写共 M 项已列 N 项"；Explore 第 15–16 行改为"结论与搜索结果矛盾要指出；提示词含'所有/影响面/重命名'时不提前停止"。

P2，瘦身与度量：
8. README 第 33 行改二选一；正文移到 rules/ 并改 install.sh 第 11 行；REVIEW.md 第 57 行用 /context 实测 token 后填入，实测前标注未核验；第 3–4 行后半、68–69、76 行移到 README；第七节删重复 4 条。
9. 六节进度文件加"已试修法与失败证据、已派子 agent 及结论"，定义"一次失败"；hook 两分支记 hit/miss（不记命令原文）；REVIEW.md 写调整触发条件。

## 6. 与替代方案的比较

| 方案 | 结论 |
| --- | --- |
| A 只降主会话模型与强度 | 单位投入节省最高，当前缺失；吸收为安装第 0 步并写进 settings，规则在其后再省一层 |
| B 拆成按需技能 | 机制厂商专有，可移植性差；不采用，但进度模板、CI 步骤等工作流细节可放技能，第七节已允许 |
| C 只靠 hook 与配置 | 确定性强但表达不了门槛与止损，且不可移植；作为兜底保留，前提是装牢并自检 |
| D 会话卫生 | 已含于第六节与 README，由用户执行；管不到双重加载 |
| E 工具层输出限制（run-quiet） | 最可移植、不依赖遵守；应从兜底升为主力，hook 只负责把命令改写成调用它 |

保留：薄正文、映射表、子 agent 定义、install.sh 拼装的结构。补充：A 前置、E 主力、C 自检。

## 7. 结论

值得采用，但不是按现状装。采用方式：先降主会话档位，再装规则，把 env、hook、config 合并进安装并自检；修完 hook 的换行放行与 install.sh 的覆盖再装到有旧规则的机器，修完裁剪与两侧角色强度再推广到第二个终端。在此之前，装了等于只装了提示词约定，还会因 mapping.md 第 13 行的承诺让模型裸跑测试。应放弃或改造的情况：主要在云端/Cowork 工作且无法装适配层时，只保留正文并接受只省行为约束那一部分；两周内 /usage 的 subagent 占比与总量无变化、或返工明显增多时，先查强制层是否生效再改措辞；终端原生提供了子 agent 模型分档与输出裁剪时，适配层应退化为只保留正文与映射。

## 8. 修订记录（2026-09-25）

按第 5 节的修订清单逐项处理，结果如下。

| 项 | 处理 | 落点 |
| --- | --- | --- |
| P0-1 主会话档位 | 已做。settings 片段与安装脚本写入 `model: sonnet`、`effortLevel: medium`（缺键才写，已有值保留）；Codex 写入 `model_reasoning_effort = "medium"`；README 把档位设置提到安装之前作第 0 步，并注明 Opus 5.5 需用 `modelSettings`；原"先做小事"条款改为"不为热身多发一轮"并移入 README 使用习惯 | `adapters/claude-code/settings.snippet.json`、`install.sh`、`README.md` |
| P0-2 安装与强制层 | 已做。开头检查 jq；规则正文以标记段落追加进已有文件、再装原位更新，不整体替换；`settings.json` 用 jq 合并（env、model、effortLevel 缺键才写，hook 不重复追加）；`config.toml` 按缺失键插入并校验仍为合法 TOML；agents、hooks、run-quiet 覆盖前备份；结尾打印"已强制生效 / 仍靠提示词"；新增 `project` 模式写入仓库的 `AGENTS.md` 与 `.claude/{settings.json,agents,hooks}`，云端与 Cowork 会话可用 | `install.sh` |
| P0-3 裁剪逻辑 | 已做。多行命令一律放行；日志改用 mktemp，并行不冲突；hook 改为调用同目录的 run-quiet，过滤模式只维护一份；命令清单补 `npm/pnpm/yarn/bun run <test|build|lint|…>`、`uv/poetry run`、`eslint`、`ruff`、`mypy`、`pyright`、`playwright test`；模式补 `error TS`、eslint 行、go 行、`Expected/Received`、pytest 的 `E` 行；不超过 80 行原样返回；匹配超过 120 行时提示"共 N 行"；映射表改为"hook 生效且命令在清单内才自动裁剪"；README 写明 allow 等于对这些命令免审批。多行放行与新模式均已复现测试 | `scripts/run-quiet.sh`、`adapters/claude-code/hooks/filter-test-output.sh`、两份 `mapping.md` |
| P0-4 三档落地 | 已做。Codex 新增 `reviewer.toml`、`test-runner.toml`（medium，reviewer 只读沙箱）；子 agent 默认强度改为 medium，explorer 显式 low 并留出 `model` 占位；空串占位改为注释；Claude 侧 test-runner 强度改为 medium，与映射表一致。`multi_agent_v2` 一段保留：其键名来自仓库 config.schema.json，评审团未能核验是因为其环境无网络 | `adapters/codex/agents/*.toml`、`adapters/codex/config.snippet.toml`、`adapters/claude-code/agents/test-runner.md` |
| P1-5 评审员范围与判据 | 已做。正文第一节：改动超过 3 个文件或触及输入处理、鉴权、并发、文件/网络/子进程时派一次评审员，查正确性与安全缺陷；两侧 reviewer 同步；test-runner 限定为 hook 裁剪后仍超约 100 行或需连跑多条命令的情况 | `AGENTS.md`、两侧 reviewer 与 test-runner 定义 |
| P1-6 流程缺口 | 已做。五.1 复现写成失败用例；五.2 加根因假设；五.3 回归测试与同根因实例不算扩大范围；五.5 定义"一次失败"并先撤销无效修改；四.1 加验收标准；四.2 计划固定写文件、测试、验证命令 | `AGENTS.md` |
| P1-7 溢出通道 | 已做。三个角色超限时落盘并返回路径与总数，首行写"共 M 项已列 N 项"；Explore 遇"所有 / 影响面 / 调用方 / 重命名"不提前停止，结论与结果矛盾要指出。Explore 用 Write 而不是 Bash 落盘，保持只读 | 六个角色定义 |
| P2-8 瘦身 | 已做。README 写明全局与项目级二选一；REVIEW 的 3k token 改为估计并标注未实测；正文开头压成一行，第六节的用户侧条款移到 README，第七节整段删除（四条与前文重复，行数上限改为 README 的维护约定）。未把正文移到 rules/ 目录：单文件已足够短，多一层目录没有收益 | `AGENTS.md`、`README.md`、`REVIEW.md` |
| P2-9 状态与度量 | 部分。进度文件字段补"已试过且无效的修法及其证据、已派出的子 agent 及结论"，压缩保留清单同步，"一次失败"已定义；README 与 REVIEW 加基线做法（安装前记 `/usage` 一周数据，两周后比较）。未做 hook 的 hit/miss 计数：要落盘命令特征，收益小于隐私与维护成本 | `AGENTS.md`、`README.md`、`REVIEW.md` |

未采纳的一条：评价把"Codex 配置键名已按 schema 核对"降为未核验。那些键名是从 Codex 仓库当前的 `config.schema.json` 直接核对的，评审团无法复核只是因为其运行环境访问不了网络，因此保留。
