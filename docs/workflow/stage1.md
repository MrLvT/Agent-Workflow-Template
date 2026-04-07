# Stage 1 — Context Loading / Router

> 回答：我现在应该去哪里？

## 执行步骤

按以下顺序执行，不得跳过：

### Step 0：准备 run_log

读取 `docs/run_log.md`：

- 若最新一条 run 记录的状态是 `in_progress`，继续复用该条
- 若不存在进行中的记录，新建一条 run 记录，至少写入：开始时间、状态 `in_progress`、目标 `待 Stage 2 明确` 或 `恢复当前 issue`
- 后续 Stage 必须持续补充同一条记录，不要为同一个 run 重复开新条目

### Step 1：读 stage.lock，优先路由

读取 `docs/stage.lock`，检查 `status` 字段：

- `status == failed` → **停止，通知人类**（说明上次执行失败，需要人工介入）
- `current == stage1 && status == done && previous == stage6` → **继续路由**
  - 说明刚完成一个完整 issue 闭环并从 Stage 6 回到了 Stage 1
  - 若没有 blocker，可在同一次 run 中继续领取 backlog 的下一个任务
- `status == in_progress` → **直接跳转到 `stage.lock.current` 指定的 Stage，不再继续下面的判断**
- `status == done` → 继续 Step 2

### Step 2：检查 blockers（仅 status==done 时执行）

读取 `docs/blockers.md`：

- 有未解决条目 → **停止，通知人类**（说明有阻塞需要解决）
- 无未解决条目 → 继续 Step 3

### Step 3：检查当前任务状态（仅 status==done 时执行）

读取 `docs/plan/current.md`：

- 有未完成步骤（存在未勾选的 `- [ ]`）→ 跳转 **Stage 3**
- 为空或所有步骤已完成 → 跳转 **Stage 2**

## Exit Checklist

- [ ] `stage.lock` 已读取
- [ ] 已确定本次 run 是“停止”还是“继续路由”
- [ ] 若继续路由：`stage.lock` 已更新（current 指向下一个 Stage，status: in_progress）
- [ ] 若继续路由：`stage.lock` 更新已单独 git commit（格式：`chore(stage): stage1 → <next> [done]`）
- [ ] 若继续路由：已正确处理 `current: stage1`、`status: done`、`previous: stage6` 的连续运行场景

## Failure Path

- `stage.lock` 文件不存在 → 停止，通知人类先运行 `init.sh` 或恢复默认 `stage.lock`
- `status == failed` → 停止，通知人类，不得自行修改 status
- `blockers.md` 有未解决条目 → 停止，通知人类
