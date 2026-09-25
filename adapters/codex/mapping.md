
## 术语映射（Codex CLI）
| 通用说法 | 在 Codex 中 |
| --- | --- |
| 子 agent | 需在 ~/.codex/config.toml 开启多 agent 功能后由 spawn_agent 派出；未开启时第一、二节不适用。/agents、/subagents 查看 |
| 小模型 / 中档模型 / 主模型 | 角色文件里的 model 与 model_reasoning_effort：探索类角色 low，评审与测试归纳 medium，主会话按需（/model 可临时切换模型与强度） |
| 搜索定位的子 agent | explorer 角色（~/.codex/agents/explorer.toml，只读、低强度） |
| 继承完整对话历史的子 agent | /fork 或 /side 开出的分支会话；spawn_agent 派出的子 agent 一律用自包含提示词 |
| 搜索 / 读指定行段 / 编辑 / 抓网页 | shell 里 rg 或 grep（限制条数）、sed -n 读行段 / apply_patch / 联网查询带明确目标 |
| 新开会话 / 压缩上下文 | /new（/clear 同时清屏）/ /compact；/recap 只生成摘要，不替代 /compact |
| 查看上下文占用与额度 | /status 看会话配置与 token 用量；/usage 看账号额度 |
| run-quiet 脚本 | 测试与构建命令一律用 run-quiet 包装；Codex 的命令 hook 不能改写工具输入，所以没有自动裁剪 |
