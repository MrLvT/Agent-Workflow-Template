# Current Plan

## 当前状态

- 当前无进行中的 issue。
- 开始新任务时，再由 agent 或人类将本文件改写为具体任务计划，并先创建 `.agent-workflow/issue_test/<issue_id>.sh`。

## 启动新任务时需要补充

1. 任务名称、来源 issue、开始日期、状态
2. 当前 issue 对应的测试脚本路径与覆盖目标
3. 可逐步勾选的执行步骤
4. 对应的验证记录（至少包含历史回归基线和完整回归结果）
5. 若计划执行结果型实验、评测、benchmark 或探索性 smoke test：预留结果目录 `results/issue<issue_id>/` 与总结文件 `results/issue<issue_id>/SUMMARY.md`；若最终未实际执行，不需要创建占位目录

## 维护说明

- 该文件只记录当前正在执行的一个 issue。
- 对应测试脚本固定放在 `.agent-workflow/issue_test/<issue_id>.sh`，完成任务后继续保留在 `.agent-workflow/issue_test/` 中。
- 任务完成后，将本文件归档到 `.agent-workflow/docs/plan/archive/`，然后重置为“当前无进行中的 issue”状态。
