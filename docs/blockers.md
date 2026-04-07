# Blockers

> 本文档回答：agent 卡在哪里了？需要人类帮什么？
>
> Agent 遇到无法自行解决的问题时写入此文件，然后停止。人类解决后清除对应条目。

## 记录模板

```markdown
### B-00X 标题
- 日期：YYYY-MM-DD
- 卡在哪个 Stage：
- 问题描述：
- 已尝试的修复：
  - 尝试 1：结果
  - 尝试 2：结果
- 需要人类做什么：
```

## 当前阻塞

### B-001 stage3 缺少 issue_id
- 日期：2026-04-04
- 卡在哪个 Stage：stage3
- 问题描述：`docs/stage.lock` 已被路由到 `current: stage3`，但 `meta.issue_id` 仍为 `null`。按 `scripts/build_context.py --stage stage3` 的约束，缺少 issue_id 时会直接退出，导致 Stage 3 无法装载上下文，也无法安全执行 `issue_test/<meta.issue_id>.sh`。
- 已尝试的修复：
  - 尝试 1：按 Stage 1 路由规则继续进入 Stage 3。结果：`python3 scripts/build_context.py --stage stage3` 退出 1，报错 `stage3 but meta.issue_id is null in stage.lock`。
  - 尝试 2：回读 `docs/workflow/stage2.md`。结果：确认 Stage 2 的 Exit Checklist 明确要求写入 `stage.lock.meta.issue_id`，当前仓库状态缺少这一步，无法在 Stage 3 合法补救。
- 需要人类做什么：确认是否要先回到 Stage 2 补齐 issue 选择和 `meta.issue_id`，或者明确提供当前 issue_id 及对应的 `issue_test/<issue_id>.sh`，再重新开始本次 run。

## 维护规则

1. Agent 写入后必须停止工作，不得绕过 blocker 继续执行。
2. 人类解决后删除对应条目。
3. Stage 1 启动时必须检查此文件，有未解决条目则不得开始新任务。
