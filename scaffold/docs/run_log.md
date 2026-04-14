# Run Log

> 记录“本次 run 想解决什么、实际做了什么、最后结果如何”。
>
> 这是跨 issue 的运行日志，不替代 `.agent-workflow/docs/plan/archive/*.md`。

## 维护规则

1. 每次启动或继续执行同一个 run 时，优先复用最新一条 `状态：in_progress` 的记录；只有当上一条已经结束（`done` / `blocked` / `failed`）时，才新建一条。
2. Stage 2 负责把“本次 run 要解决什么”写清楚，至少写明当前 issue 或当前阻塞点。
3. Stage 4 和 Stage 6 负责持续补充“具体干了啥”和“实际结果”。
4. 若 run 因 blocker、失败、人工 handoff 或无任务可继续而停止，必须补齐“结束时间”“状态”“实际结果”。
5. 每条记录都要尽量写事实，不写空话；结果优先写可验证产物，例如 commit、测试结果、handoff。

## 记录模板

```markdown
## RUN-YYYYMMDD-HHMMSSZ

- 开始时间：YYYY-MM-DDTHH:MM:SSZ
- 结束时间：
- 状态：in_progress
- 目标：
  - 待 Stage 2 明确
- 具体执行：
  - 待后续 Stage 追加
- 实际结果：
  - 待后续 Stage 追加
```
