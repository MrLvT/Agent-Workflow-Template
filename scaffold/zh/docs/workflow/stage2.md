# Stage 2 — Task Planning

> 回答：下一个任务是什么？怎么拆解执行？

## 执行步骤

### Step 1：风险预判

读取 `.agent-workflow/docs/antipatterns.md`（如存在）：

- 对照当前要选的任务，检查是否触发已知失败模式
- 如有匹配，在 `current.md` 的计划中标注风险提示

### Step 2：选任务

读取 `.agent-workflow/docs/plan/backlog.md`，选择一个 `- [ ]` 任务：

- 按优先级从高到低选（P0 → P1 → P2）
- 需求不清晰时，停止，通知人类澄清，不得猜测

### Step 2.5：检查 overview.md 是否需要更新

对照选出的任务与 `.agent-workflow/docs/overview.md` 的 In Scope / Out of Scope：

- 任务在当前 scope 内 → 继续
- 任务超出当前 scope，或项目目标/范围需要扩展 → 先更新 `.agent-workflow/docs/overview.md`，再继续
- 范围变更必须同步追加一条决策到 `.agent-workflow/docs/decisions.md`

### Step 3：确定 issue_id

格式：`<number>-<short-description>`（例：`42-add-user-auth`）

- number 从 backlog 条目编号或自增序号取
- short-description 用 kebab-case，不超过 5 个词

### Step 3.5：创建或切换当前 issue 分支

默认工作分支名：`codex/<issue_id>`

- 当前已在 `codex/<issue_id>` → 继续
- 本地已存在 `codex/<issue_id>` → 执行 `git switch codex/<issue_id>`
- 当前在默认分支（优先按 `origin/HEAD` 推断，缺失时视为 `main`），且本地尚无 `codex/<issue_id>` → 执行 `git switch -c codex/<issue_id>`
- 当前仍停留在上一个已完成 issue 的 workflow 分支（同前缀、不同 issue_id），且 `stage.lock` 已回到 `stage1/done/previous=stage6`、工作区干净、本地尚无 `codex/<issue_id>` → 允许直接执行 `git switch -c codex/<issue_id>`，从当前 HEAD 派生下一个 issue 分支；这属于本地连续交付的正常路径，不算把两个 issue 混到同一分支
- 当前在与 workflow 无关的其他工作分支，或准备从上一个 issue 分支继续但工作区不干净 → 停止并通知人类，避免把未收口的改动混入新 issue
- 若团队已在 `.agent-workflow/docs/conventions.md` 定义等价前缀，可替换 `codex`，但必须保持“一 issue 一分支”

### Step 4：创建当前 issue 的测试脚本

创建 `.agent-workflow/issue_test/<issue_id>.sh`，要求：

- 从仓库根目录直接执行
- 使用退出码表示结果：exit 0 表示 PASS，非 0 表示 FAIL
- 失败时必须打印清晰诊断信息，至少说明期望结果、实际结果、失败命令或检查点
- 覆盖当前 issue 的目标行为或交付结果，不能只做空转占位
- 尽量 deterministic；若依赖外部服务或特殊环境，脚本内必须写清前置条件
- 非必要不得修改历史 `.agent-workflow/issue_test/*.sh`；若必须修改，需在 `current.md` 里记录原因

### Step 5：写 current.md

将执行步骤写入 `.agent-workflow/docs/plan/current.md`，格式要求：

- 使用 checkbox 格式（`- [ ]`）
- 步骤粒度：每步完成后可独立勾选
- 如有风险提示，写在步骤前的备注里
- 明确记录当前 issue 对应的测试脚本路径：`.agent-workflow/issue_test/<issue_id>.sh`
- 明确记录两次验证命令：
  - 实现前历史回归：`bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh`
  - 实现后完整回归：`bash .agent-workflow/scripts/run_issue_tests.sh`
- 若当前任务包含实验、评测或 smoke test，预先记录结果目录：`results/issue<issue_id>/`
- 若当前任务包含实验、评测或 smoke test，预先记录总结文件：`results/issue<issue_id>/SUMMARY.md`

### Step 6：记录技术决策（如有）

涉及重要技术选型时，追加到 `.agent-workflow/docs/decisions.md`（只追加，不修改历史）。

> 注意：overview.md 的范围变更也必须在此步骤追加到 decisions.md。

### Step 6.5：更新 run_log

更新 `.agent-workflow/docs/run_log.md` 中当前进行中的 run 记录，至少补充：

- 本次 run 当前要解决的 issue / 问题
- 新建或切换的工作分支
- 新建的 `.agent-workflow/issue_test/<issue_id>.sh`
- 已写入 `.agent-workflow/docs/plan/current.md` 的执行计划

### Step 7：更新 stage.lock

```yaml
current: stage3
status: in_progress
previous: stage2
meta:
  issue_id: "<确定的 issue_id>"
```

## Exit Checklist

- [ ] `.agent-workflow/docs/overview.md` 已检查，范围变更时已更新并追加 decisions.md
- [ ] 当前 issue 已切到独立工作分支（默认：`codex/<issue_id>`）
- [ ] `.agent-workflow/issue_test/<issue_id>.sh` 已创建，覆盖当前 issue 的目标行为，且失败时会输出诊断信息
- [ ] `.agent-workflow/docs/plan/current.md` 非空，有可勾选步骤
- [ ] `.agent-workflow/docs/plan/current.md` 已记录当前 issue 测试脚本路径和两次验证命令
- [ ] 若当前 issue 包含实验、评测或 smoke test，`.agent-workflow/docs/plan/current.md` 已记录 `results/issue<issue_id>/` 与 `SUMMARY.md`
- [ ] `.agent-workflow/docs/run_log.md` 已写清当前 run 的目标与计划动作
- [ ] `stage.lock.meta.issue_id` 已写入
- [ ] `stage.lock` 已更新（current: stage3）
- [ ] `stage.lock` 已更新；若团队跟踪 `.agent-workflow/`，再按团队约定单独提交状态文件

## Failure Path

- backlog 为空 → 更新 stage.lock（status: failed），在 `.agent-workflow/docs/run_log.md` 补齐结束时间、状态与“缺少可继续任务”的结果后停止，通知人类补充任务
- 需求不清晰无法拆解 → 更新 stage.lock（status: failed），在 `.agent-workflow/docs/run_log.md` 补齐结束时间、状态与澄清需求后停止，通知人类澄清
- 无法安全切换到当前 issue 的独立工作分支 → 更新 stage.lock（status: failed），在 `.agent-workflow/docs/run_log.md` 补齐结束时间、状态与分支问题后停止，通知人类处理分支状态
- 无法把需求表达为可执行的 `.agent-workflow/issue_test/<issue_id>.sh` → 更新 stage.lock（status: failed），在 `.agent-workflow/docs/run_log.md` 补齐结束时间、状态与验收标准问题后停止，通知人类澄清
