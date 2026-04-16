# Conventions

> 本文档回答：代码长什么样？git 操作怎么做？
>
> 收录标准：本文档只收录**靠 agent 自觉遵守**的风格性约束。被 linter / CI 机械执行的结构性规则归 `architecture.md`。

## 命名规范（待填写）

- 文件名：`kebab-case` / `snake_case`（二选一并固定）
- 类名：`PascalCase`
- 变量和函数：`camelCase` 或 `snake_case`（与语言习惯一致）
- 常量：`UPPER_SNAKE_CASE`

## 函数契约（待填写）

1. 函数输入输出必须可预测，错误路径可测试。
2. 公共函数需声明参数、返回值、异常语义。
3. 禁止隐式全局状态修改。

## 错误处理模式（待填写）

- 错误表示方式：（异常 / Result 类型 / 错误码）
- 日志级别约定：
- 重试策略：

## Git 规范（待填写）

### Commit Message

- 格式：`<type>(<scope>): <subject>`
- type 枚举：`feat / fix / refactor / docs / test / chore`
- subject 语言：（中文 / 英文）

### Branch 命名

- 默认格式：`codex/<issue_id>`
- 示例：`codex/42-add-user-auth`
- 若团队已有统一前缀，可替换 `codex`，但必须保持“一个 issue 一个分支”
- 当上一个 issue 已完成、`stage.lock` 回到 `stage1/done/previous=stage6` 且工作区干净时，下一个 issue 可以直接从当前 HEAD 派生新分支，不强制先切回默认分支
- 若团队要求每次新 issue 都必须先回默认分支，请在本节明确写出，并优先遵守团队约定

### 交付记录规范

- 归档中的交付摘要至少包含：本地 commit hash、验证结论、必要时的人类下一步
- 若存在安全或发布风险，必须在归档或 handoff 记录中写明

## 实验结果约定

- 只有当前 issue **实际执行了会产出结果的实验、评测、benchmark 或探索性 smoke test**，才需要维护结果目录：`results/issue<issue_id>/`
- 目录示例：`results/issue1-smoke-test/`
- 若只是计划过实验、但最终没有实际执行，不要为了满足流程创建占位目录或空 `SUMMARY.md`
- 一旦实际执行过此类运行，无论结果成功、失败还是结论不确定，都必须维护：`results/issue<issue_id>/SUMMARY.md`
- 每次实验后都要在 `SUMMARY.md` 追加一节，至少包含：
  - 实验名称 / 时间
  - 目的或假设
  - 模型与关键设定
  - 工作流 / pipeline
  - input length、batch size、seed、数据切片等关键输入条件
  - 执行命令、环境、硬件或调度信息
  - 原始日志 / 产物路径
  - 主要结果与指标
  - 对结果的尝试分析（包括失败或不确定结论）
- `SUMMARY.md` 只记录实验事实、结果与分析；禁止把 Stage 流程、分支切换、提交过程或一般开发过程写成实验总结
- run / stage 级过程记录写入 `.agent-workflow/docs/run_log.md`；单 issue 的交付与反思写入 archive / `REFLECT-<issue_id>.md`
- `SUMMARY.md` 除了逐次运行记录外，还必须维护一个“当前 issue 级结论 / synthesis”区域：基于所有已执行实验，说明当前 issue 的核心假设得到了什么支持或反证、还剩哪些不确定性、下一步最有价值的实验是什么
- issue 级结论必须围绕“这个 issue 想回答什么实验问题”展开，不能退化成“本阶段修了什么、覆盖了什么、哪个 blocker 清了”这类 workflow 过程描述
- 同一 issue 的多次实验可以写入同一个 `SUMMARY.md`，原始日志、图表、JSON、CSV 等产物放在同目录或其子目录中

## 维护规则

1. 风格冲突时，以本文件为准。
2. 引入新模式前先补充本文件再推广。
3. 当某条规则被 linter 强制执行后，从本文件迁移到 `architecture.md`。
