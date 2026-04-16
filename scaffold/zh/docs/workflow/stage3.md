# Stage 3 — Implementation

> 回答：代码写完了吗？能通过验证吗？

## 执行步骤

### Step 1：先跑历史 issue 回归基线

```bash
bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<meta.issue_id>.sh
```

- FAIL → 先修复已有回归，再继续当前 issue
- 同一错误修复超过 3 次未解决 → 进入 **Failure Path A**

### Step 2：运行当前 issue 的测试脚本，确认基线

```bash
bash .agent-workflow/issue_test/<meta.issue_id>.sh
```

- 如果当前 issue 代表新增/修复行为，理想结果通常是“尚未通过”或明确暴露缺失行为
- 如果当前 issue 是重构、清理或非行为变更，允许脚本在实现前就通过，但必须能说明它在保护什么不变式
- 如果脚本失败但没有提供足够诊断信息，先补足测试脚本输出，再继续
- 若脚本结果与 issue 目标明显不符（例如应失败却通过，且看不出是在验证目标行为）→ 先修正测试脚本，再继续
- 无法判断脚本是否有效 → 进入 **Failure Path B**

### Step 3：实现代码

按 `.agent-workflow/docs/plan/current.md` 的步骤逐一实现，每完成一步立即勾选（`- [x]`）。

涉及敏感内容（认证、密钥、权限）时，先读 `.agent-workflow/docs/security.md`。

实现过程中如发现架构边界需要调整（新增模块、依赖关系变化、层级职责变化）：

1. 立即更新 `.agent-workflow/docs/architecture.md`，不要等到 Stage 6
2. 追加一条决策到 `.agent-workflow/docs/decisions.md`，说明为什么需要这个架构调整
3. 如果调整涉及 lint 规则，同步更新对应规则文件

实现过程中如发现新的环境事实或运行前提（例如必须走 Slurm、需要 `conda activate agent`、只能在 GPU/计算节点执行、需要特定模块/环境变量）：

1. 立即更新 `.agent-workflow/docs/environment.md`
2. 若该事实会改变团队默认执行方式或验证方式，追加一条决策到 `.agent-workflow/docs/decisions.md`
3. 在 `.agent-workflow/docs/run_log.md` 记录这次发现与更新

### Step 4：运行完整 issue 回归套件

```bash
bash .agent-workflow/scripts/run_issue_tests.sh
```

- FAIL → 修复并重跑，直到全部通过
- 同一错误修复超过 3 次未解决 → 进入 **Failure Path A**

### Step 4.5：记录实验结果（如有）

如果本阶段**实际执行了会产出结果的实验、评测、benchmark 或探索性 smoke test**：

- 结果目录固定为 `results/issue<meta.issue_id>/`
- 每次实际运行后，必须在 `results/issue<meta.issue_id>/SUMMARY.md` 追加一节总结
- 即使结果失败、结论不确定，或只是排除了一个假设，也必须写入
- 追加单次运行记录后，还要更新同文件中的 issue 级结论 / synthesis，说明这次结果如何改变了对当前 issue 实验问题的整体判断
- 每条总结至少包含：
  - 实验名称 / 时间
  - 实验目的或假设
  - 模型与关键设定
  - 工作流 / pipeline
  - input length、batch size、seed、数据切片等关键输入条件
  - 执行命令、环境、硬件或调度信息
  - 原始日志 / 产物路径
  - 主要结果与指标
  - 对结果的尝试分析（即使结果失败或暂时无法解释，也要写清）
- `SUMMARY.md` 只记录实验事实、结果与分析，不得写 Stage 流程复盘、分支切换、提交过程或一般开发过程；这些内容写入 `.agent-workflow/docs/run_log.md`

### Step 5：更新 stage.lock

```yaml
current: stage4
status: in_progress
previous: stage3
```

## Exit Checklist

- [ ] `.agent-workflow/docs/plan/current.md` 所有步骤已勾选
- [ ] `bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<meta.issue_id>.sh` 已通过
- [ ] `.agent-workflow/issue_test/<meta.issue_id>.sh` 已在实现前执行过，结果与 issue 目标一致，且失败时输出了足够诊断信息
- [ ] 架构边界有变化时，`.agent-workflow/docs/architecture.md` 已更新并追加 decisions.md
- [ ] 环境事实有变化时，`.agent-workflow/docs/environment.md` 已更新；若影响默认执行方式，已追加 decisions.md
- [ ] 若本 issue 实际执行了结果型实验、评测、benchmark 或探索性 smoke test，`results/issue<meta.issue_id>/SUMMARY.md` 已补齐每次运行的总结，且失败/不确定结果也已记录
- [ ] 若本 issue 实际执行了结果型实验、评测、benchmark 或探索性 smoke test，`results/issue<meta.issue_id>/SUMMARY.md` 已更新 issue 级结论 / synthesis，而不是只堆叠单次运行记录
- [ ] `bash .agent-workflow/scripts/run_issue_tests.sh` 输出 `ISSUE TESTS: PASS`
- [ ] `stage.lock` 已更新（current: stage4）
- [ ] `stage.lock` 已更新；若团队跟踪 `.agent-workflow/`，再按团队约定单独提交状态文件

## Failure Path

### Failure Path A：同一错误修复超过 3 次

- 写入 `.agent-workflow/docs/blockers.md`，明确记录：
  - 已尝试的修复思路
  - 最近一次失败命令与报错摘要
  - 需要人类确认的问题
- 更新 stage.lock（status: failed），停止，通知人类

### Failure Path B：当前 issue test 有效性无法判断

写入 `.agent-workflow/docs/blockers.md`，更新 stage.lock（status: failed），停止，通知人类确认。
