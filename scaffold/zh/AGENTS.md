# AGENTS.md

## 启动协议

每次启动，进入以下循环，不得跳过，不得改变顺序：

> 前提：`.agent-workflow/docs/stage.lock` 必须已存在。它是初始化阶段生成的 bootstrap 文件；若缺失，说明仓库尚未初始化完成或文件已损坏，必须先由人类重新运行 `init.sh` 或手动恢复。

**Step 1：确认当前 Stage**

读取 `.agent-workflow/docs/stage.lock`，获取 `current` 字段。

**Step 2：调用 build_context.py**

> 前置条件：`build_context.py` 依赖 PyYAML。若尚未安装，先执行：
> ```bash
> python3 -m pip install pyyaml
> ```

```bash
python .agent-workflow/scripts/build_context.py --stage <current>
```

脚本成功时 exit 0，输出为当前 Stage 需要加载的文件列表，逐一读取所有文件。
脚本 exit 1 时表示必须文件缺失，不得继续执行，须写入 `.agent-workflow/docs/blockers.md` 后停止。

**Step 3：执行**

读取完所有文件后，按 `.agent-workflow/docs/workflow/<current>.md` 的指令执行。

**Step 4：判断是否继续**

每个 Stage 执行后，重新读取 `.agent-workflow/docs/stage.lock`：

- 若 `status == failed` → **停止**，等待人类处理 blocker
- 若 `current == stage1` 且 `status == done` 且 `previous == stage6`：
  - 若这是本次 session 第一次看到该状态 → **继续执行**，从 Stage 1 继续路由到下一个 issue
  - 若这是本次 session 完成一个 issue 闭环后再次回到该状态 → **停止当前 session**，交由 `scripts/start_agent.sh` 重新拉起一个全新的 Codex session，再领取下一个 issue
- 其他情况 → 回到 Step 1，继续下一个 Stage

---

## 文档索引

| 文档 | 职责 |
|------|------|
| `.agent-workflow/docs/workflow/stage1.md` | Stage 1 指令：Context Loading / Router |
| `.agent-workflow/docs/workflow/stage2.md` | Stage 2 指令：Task Planning |
| `.agent-workflow/docs/workflow/stage3.md` | Stage 3 指令：Implementation |
| `.agent-workflow/docs/workflow/stage4.md` | Stage 4 指令：Delivery & Verification |
| `.agent-workflow/docs/workflow/stage5.md` | Stage 5 指令：Reflection |
| `.agent-workflow/docs/workflow/stage6.md` | Stage 6 指令：Entropy Check |
| `.agent-workflow/docs/stage.lock` | 全局状态寄存器：当前 Stage + 状态 + meta |
| `.agent-workflow/docs/overview.md` | 项目目标与范围 |
| `.agent-workflow/docs/architecture.md` | 模块划分 + 依赖边界 |
| `.agent-workflow/docs/conventions.md` | 命名 + 代码风格 + git 规范 |
| `.agent-workflow/docs/environment.md` | 运行环境、调度器和前置步骤事实 |
| `.agent-workflow/docs/run_log.md` | 跨 issue 的 run 级执行日志 |
| `.agent-workflow/docs/decisions.md` | 时间线追加式设计决策日志 |
| `.agent-workflow/docs/quality.md` | Definition of Done + 验证方法 |
| `.agent-workflow/docs/security.md` | 敏感信息 + 安全边界 |
| `.agent-workflow/docs/progress.md` | 项目快照 |
| `.agent-workflow/docs/blockers.md` | Agent 阻塞记录（人类介入点） |
| `.agent-workflow/docs/wisdom.md` | 跨 issue 验证有效的可复用模式 |
| `.agent-workflow/docs/antipatterns.md` | 跨 issue 验证会失败的反模式 |
| `.agent-workflow/docs/plan/backlog.md` | issue 队列 |
| `.agent-workflow/docs/plan/current.md` | 当前 issue 执行步骤 |
| `.agent-workflow/issue_test/README.md` | issue 级回归脚本约定 |
| `.agent-workflow/scripts/run_issue_tests.sh` | 执行 `.agent-workflow/issue_test/*.sh` 的累积回归入口 |

---

## 全局硬规则

1. 启动协议三步必须执行，不得跳过。
2. Stage 判断不明确时，以 `stage.lock` 为准，不得自行猜测。
3. 每个 Stage 结束前必须完成该 Stage 的 Exit Checklist，不得跳过。
4. `.agent-workflow/` 默认作为本地工作流状态目录使用；`stage.lock`、`current.md`、`blockers.md`、archive、issue tests 与 workflow 文档默认不进入业务仓库 git 历史。若团队明确选择跟踪这些文件，才允许提交，且应与业务代码分开管理。
5. 架构边界违规必须先修复。若 `.agent-workflow/docs/architecture.md` 中标注"由静态检查或 CI 强制执行"，则以对应工具输出为准；若尚未配置自动检查，则依赖 agent 自觉遵守，并在 `.agent-workflow/docs/decisions.md` 记录该约束仍为手动执行状态。
6. 涉及凭据、认证、敏感文件前先读 `.agent-workflow/docs/security.md`。
7. 重要技术取舍必须追加到 `.agent-workflow/docs/decisions.md`（禁止覆写历史条目）。
8. 进入 Stage 3 前，必须存在当前 issue 对应的 `.agent-workflow/issue_test/<meta.issue_id>.sh`；后续 issue 不得删除、跳过或弱化历史 issue tests 来规避回归。
9. 连续运行多个 issue 时，默认由 `scripts/start_agent.sh` 负责在 issue 之间重启一个全新的 Codex session；同一个 session 里最多只完整闭环一个新 issue，避免上下文持续膨胀。
10. 遇到无法自行解决的问题，写入 `.agent-workflow/docs/blockers.md` 后停止，不得绕过阻塞继续执行。
11. Stage 4 负责形成可复现的本地交付状态并完成归档；Stage 6 负责文档与状态收口。workflow 到本地交付与状态收口即结束；若团队还有额外发布或同步动作，由人类在 workflow 之外自行处理。
12. `.agent-workflow/docs/run_log.md` 必须持续维护：Stage 2 写清目标，Stage 4/6 补具体执行与结果，run 停止时补齐结束时间与最终状态。run_log 用于 run / stage 级过程记录，不得拿 `results/.../SUMMARY.md` 代替。
13. 若后续 run 发现新的环境事实（如 Slurm、conda、CUDA、登录节点限制、必须通过调度器执行等），必须立即更新 `.agent-workflow/docs/environment.md`，不要只停留在聊天上下文。
14. 只有在 issue **实际执行了会产出结果的实验、评测、benchmark 或探索性 smoke test** 时，才必须维护 `results/issue<issue_id>/` 与 `results/issue<issue_id>/SUMMARY.md`。一旦执行过，无论成功、失败还是结论不确定，都必须逐次记录实验设定、模型/工作流、input length、结果与尝试分析。`SUMMARY.md` 只允许写实验结果与分析，不得写 Stage / process 复盘。
15. 当上一个 issue 已闭环、`stage.lock` 回到 `stage1/done/previous=stage6` 且工作区干净时，仍停留在上一个 issue 分支不算 blocker；Stage 2 可以从当前 HEAD 直接派生下一个 issue 分支。只有无关分支或脏工作区才视为分支阻塞。
