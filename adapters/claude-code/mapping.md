
## 术语映射（Claude Code）
| 通用说法 | 在 Claude Code 中 |
| --- | --- |
| 子 agent | Agent 工具派出的 subagent；"多 agent 编排"指 Workflow、ultracode、agent teams |
| 小模型 / 中档 / 高档 / 最高档 | haiku 4.5 / sonnet 5（主会话默认：settings 的 model=sonnet、effortLevel=medium）/ opus 5 / fable 5.1 |
| 每 token 相对价格 | haiku 0.5、sonnet 1、opus 2.5（opus 5.5 为 2）、fable 5；思考 token 按输出价计，强度越高越贵 |
| 升档与回档 | 主会话用 /model 换模型、/effort 调强度；升档只在 L 级设计、止损后的疑难定位、安全敏感评审三处，用完切回 sonnet |
| 搜索定位的子 agent | Explore（已由 ~/.claude/agents/Explore.md 覆盖为 haiku、只读、低强度） |
| 跑测试、评审的子 agent | test-runner、reviewer（sonnet、中档强度）；评审触及鉴权、输入处理或 L 级时改派 opus |
| 继承完整对话历史的子 agent | fork |
| 搜索 / 读指定行段 / 编辑 / 抓网页 | Grep、Glob / Read（offset、limit） / Edit / WebFetch（必须带 prompt） |
| 新开会话 / 压缩上下文 | /clear / /compact 并注明保留重点 |
| 查看上下文占用与额度归因 | /context、/usage；强度用 /effort |
| run-quiet 脚本 | hook 生效且命令在清单内时自动经 run-quiet 执行；其他情况一律手动用 ~/.claude/hooks/run-quiet 包装 |
