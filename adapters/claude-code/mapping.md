
## 术语映射（Claude Code）
| 通用说法 | 在 Claude Code 中 |
| --- | --- |
| 子 agent | Agent 工具派出的 subagent；"多 agent 编排"指 Workflow、ultracode、agent teams |
| 小模型 / 中档模型 / 主模型 | haiku / sonnet / 当前会话模型（opus、fable） |
| 搜索定位的子 agent | Explore（已由 ~/.claude/agents/Explore.md 覆盖为 haiku、只读） |
| 跑测试、只读评审的子 agent | test-runner、reviewer（sonnet） |
| 继承完整对话历史的子 agent | fork |
| 搜索 / 读指定行段 / 编辑 / 抓网页 | Grep、Glob / Read（offset、limit） / Edit / WebFetch（必须带 prompt） |
| 新开会话 / 压缩上下文 | /clear / /compact 并注明保留重点 |
| 查看上下文占用与额度归因 | /context、/usage；强度用 /effort |
| run-quiet 脚本 | 单纯的测试与构建命令已由 PreToolUse hook 自动裁剪；其他长输出命令用 run-quiet |
