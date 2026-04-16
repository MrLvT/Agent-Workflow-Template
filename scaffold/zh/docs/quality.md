# Quality

> 本文档回答：什么叫做完？怎么验证做完了？

## Definition of Done

### 代码质量

- [ ] 功能实现与 `.agent-workflow/docs/plan/current.md` 一致
- [ ] 无明显重复逻辑和死代码
- [ ] 涉及架构/安全/决策边界的变更已同步更新对应文档

### Issue 回归质量

- [ ] 当前 issue 对应的 `.agent-workflow/issue_test/<issue_id>.sh` 已存在并覆盖目标行为
- [ ] 实现前已运行历史回归基线：`bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh`
- [ ] 提交前已运行完整回归：`bash .agent-workflow/scripts/run_issue_tests.sh`
- [ ] 若修改了历史 `.agent-workflow/issue_test/*.sh`，已记录原因与影响范围

### 实验结果留痕

- [ ] 只有在本 issue **实际执行了会产出结果的实验、评测、benchmark 或探索性 smoke test** 时，才要求 `results/issue<issue_id>/`
- [ ] 若实际执行过上述运行，`results/issue<issue_id>/SUMMARY.md` 已存在，并且每次运行都有单独总结条目
- [ ] 每条实验总结至少记录：实验设定、模型/工作流、input length、关键输入条件、命令/环境、结果指标、原始产物路径、尝试分析
- [ ] 失败或结论不确定的实验也已记录，不允许只保留“成功样本”
- [ ] `SUMMARY.md` 内容聚焦实验结果与分析，不包含 Stage 流程复盘或一般开发过程
- [ ] `SUMMARY.md` 已维护 issue 级结论 / synthesis，能够基于全部已执行实验回答“当前 issue 的实验问题得到了什么结论”

### 文档同步

- [ ] 变更已同步到相关文档
- [ ] 重要决策已写入 `.agent-workflow/docs/decisions.md`
- [ ] `.agent-workflow/docs/progress.md` 已反映当前状态
- [ ] 已记录交付状态：归档中已有本地交付摘要（commit hash、验证结论，必要时附人工下一步）

### 安全

- [ ] 未泄漏敏感信息
- [ ] 认证/鉴权相关改动经过复核（如适用）
- [ ] 若存在安全影响，风险已写入归档或 handoff 记录

## issue_test 机制（固定）

- 目录：`.agent-workflow/issue_test/`
- 命名：`.agent-workflow/issue_test/<issue_id>.sh`
- 执行入口：`bash .agent-workflow/scripts/run_issue_tests.sh`
- 历史脚本策略：默认长期保留，后续 issue 必须全部通过

## 项目原生检查（待填写）

- 单元/集成测试框架：
- 静态检查工具：
- 其他交付前命令：

## 常用验证命令

```bash
# 运行全部 issue 回归
bash .agent-workflow/scripts/run_issue_tests.sh

# 实现当前 issue 前，先跑历史回归基线
bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh

# 项目原生检查（如有）
<command>
```

## 失败处理流程

1. 先修复 deterministic 的 issue 回归失败，再处理 flaky 场景。
2. 禁止通过删除、跳过或弱化历史 `.agent-workflow/issue_test/*.sh` 来"修复"失败。
3. 若需临时跳过，必须记录原因和恢复计划。

## 维护规则

1. 新的质量门槛必须先写入本文件，再纳入 CI。
2. 本文件是提交前强制自查列表，不应弱化。
3. 每个 issue 都必须新增或绑定一个可复现的 `.agent-workflow/issue_test/<issue_id>.sh`。
4. 只有在 issue 实际执行了结果型实验、评测、benchmark 或探索性 smoke test 时，才必须维护 `results/issue<issue_id>/SUMMARY.md`；一旦执行过，无论成功、失败或结论不确定都必须写入。
