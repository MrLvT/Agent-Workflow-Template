# Stage 4 — Delivery & Verification

> 回答：能交付了吗？

## 执行步骤

### Step 1：最终 issue 回归 Gate

```bash
bash .agent-workflow/scripts/run_issue_tests.sh
```

- 输出 `ISSUE TESTS: PASS` → 继续
- 输出 `ISSUE TESTS: FAIL` → 回到 **Stage 3** 修复（更新 stage.lock: current: stage3）

### Step 2：人工自查

对照 `.agent-workflow/docs/quality.md` 中无法脚本化的条目逐一自查，全部通过才继续。

### Step 3：本地交付提交

```bash
git add <相关文件>
git commit   # message 格式见 .agent-workflow/docs/conventions.md
```

- 若当前 issue 的业务改动已经在本地提交完成，不要制造空提交
- 本步骤的目标是确保存在一个可复现、可 handoff 的本地 commit

### Step 4：记录本地交付状态

在当前 issue 的归档信息里准备好本地交付摘要。至少要能回答：

- 当前可交付的本地 commit hash 是什么
- 本地验证结论是什么（至少包含 issue 回归结果）
- 如果需要人类继续推进，下一步动作是什么（例如人工验收、手工发布、手工同步到其他环境）

- workflow 到这里就视为“本地交付已形成”，不要把任何额外发布或同步动作作为 Stage 4 的硬门槛
- 若仓库团队自己还有后续动作，可由人类在 workflow 之外处理

### Step 5：更新 progress.md

在 `.agent-workflow/docs/progress.md` 中记录本次完成的功能/修复。

### Step 5.5：更新 run_log

在 `.agent-workflow/docs/run_log.md` 中给当前 run 追加本 issue 的执行事实，至少包含：

- 完成了哪个 issue / 修复
- 做了哪些关键动作（代码、测试、交付）
- 实际结果（测试通过、生成了本地 commit、本地交付摘要）

### Step 5.8：核对实验结果目录（如有）

如果当前 issue 运行过实验、评测或 smoke test：

- 确认结果目录为 `results/issue<meta.issue_id>/`
- 确认 `results/issue<meta.issue_id>/SUMMARY.md` 已存在
- 确认总结已覆盖每次实验，且包含设定、模型/工作流、input length、结果与尝试分析

### Step 6：归档 current.md

```bash
# 将 current.md 内容复制到 archive
cp .agent-workflow/docs/plan/current.md .agent-workflow/docs/plan/archive/<meta.issue_id>.md
```

- 归档内容中必须保留当前 issue 对应的测试脚本路径：`.agent-workflow/issue_test/<meta.issue_id>.sh`
- 归档内容中必须补充交付状态：
  - 本地 commit hash
  - 当前分支名（若存在独立 issue 分支）
  - 验证结论
  - 若需要人类继续推进：人工下一步
- 若当前 issue 运行过实验、评测或 smoke test：写明结果目录 `results/issue<meta.issue_id>/` 与 `SUMMARY.md` 路径
- 不要移动或删除 `.agent-workflow/issue_test/<meta.issue_id>.sh`；它必须留在 `.agent-workflow/issue_test/` 里参与后续回归

### Step 7：清理

- 清空 `.agent-workflow/docs/plan/current.md`
- 重置内容必须严格回到以下模板，不得自行省略或重复段落：

```markdown
# Current Plan

## 当前状态

- 当前无进行中的 issue。
- 开始新任务时，再由 agent 或人类将本文件改写为具体任务计划，并先创建 `.agent-workflow/issue_test/<issue_id>.sh`。

## 启动新任务时需要补充

1. 任务名称、来源 issue、开始日期、状态
2. 当前 issue 对应的测试脚本路径与覆盖目标
3. 可逐步勾选的执行步骤
4. 对应的验证记录（至少包含历史回归基线和完整回归结果）
5. 若包含实验、评测或 smoke test：结果目录 `results/issue<issue_id>/` 与总结文件 `results/issue<issue_id>/SUMMARY.md`

## 维护说明

- 该文件只记录当前正在执行的一个 issue。
- 对应测试脚本固定放在 `.agent-workflow/issue_test/<issue_id>.sh`，完成任务后继续保留在 `.agent-workflow/issue_test/` 中。
- 任务完成后，将本文件归档到 `.agent-workflow/docs/plan/archive/`，然后重置为“当前无进行中的 issue”状态。
```

- 在 `.agent-workflow/docs/plan/backlog.md` 中将对应条目标记为 `[x]`

### Step 8：更新 stage.lock

```yaml
current: stage5
status: in_progress
previous: stage4
```

## Exit Checklist

- [ ] `bash .agent-workflow/scripts/run_issue_tests.sh` 输出 `ISSUE TESTS: PASS`
- [ ] `.agent-workflow/docs/quality.md` 人工自查条目全部通过
- [ ] 已存在可交付的本地 commit
- [ ] 归档中已记录本地交付摘要（commit hash、验证结论，必要时附人工下一步）
- [ ] `.agent-workflow/docs/progress.md` 已更新
- [ ] `.agent-workflow/docs/run_log.md` 已追加本 issue 的执行事实与结果
- [ ] 若本 issue 运行了实验、评测或 smoke test，`results/issue<meta.issue_id>/SUMMARY.md` 已存在且内容完整
- [ ] `.agent-workflow/docs/plan/archive/<meta.issue_id>.md` 已创建
- [ ] `.agent-workflow/issue_test/<meta.issue_id>.sh` 仍保留在 `.agent-workflow/issue_test/` 中
- [ ] `.agent-workflow/docs/plan/current.md` 已清空
- [ ] `.agent-workflow/docs/plan/backlog.md` 对应条目已标记 `[x]`
- [ ] `stage.lock` 已更新（current: stage5）
- [ ] `stage.lock` 已更新；若团队跟踪 `.agent-workflow/`，再按团队约定单独提交状态文件

## Failure Path

- `.agent-workflow/scripts/run_issue_tests.sh` FAIL → 更新 stage.lock（current: stage3, status: in_progress），回到 Stage 3
- 无法形成可复现的本地交付提交 → 写入 `.agent-workflow/docs/blockers.md`，更新 stage.lock（status: failed），停止，通知人类
