# Current Plan

## 任务元信息

- 任务名称：修复模板在 adopt 模式下暴露出的规则冲突与误导性文档
- 来源 issue：BacktrackKV 重跑后的 docs review 发现模板层级冲突
- 开始日期：2026-03-27
- 状态：In Progress

## 执行步骤

- [x] 审查 BacktrackKV docs review，识别出属于模板而非目标仓库自身的问题
- [x] 将 repo 级 `check_*` 质量门替换为 `issue_test/` 累积回归机制
- [x] 将运行模型明确为“单次 run 完成一个 issue 闭环后停在 Stage 1”
- [x] 将 `init.sh` 调整为默认交互式向导，并保留 `--non-interactive` 与现有 flags
- [x] 修正 `scaffold/AGENTS.md` 与 `scaffold/docs/workflow/stage*.md`，切换到 `issue_test/` 累积回归机制
- [ ] 修正 `scaffold/docs/decisions.md` 的维护规则，消除“只追加”与“回写旧状态”的矛盾
- [x] 调整 `init.sh` 的生成 prompt 与本地审计，使其更好提示子模块未初始化、`issue_test/` 机制和 adopt 语义
- [ ] 重新在 BacktrackKV 中从头执行初始化，验证新的模板不再产出同类冲突
- [x] 记录决策并汇总残余问题

## 验证记录

- [x] `bash -n init.sh` 通过
- [x] `init.sh --skip-fill` 本地烟测通过
- [x] `codex` stub 回归通过：确认使用 `codex exec` 而非错误的 `-p`
- [x] `--single-call` 的 `codex` stub 回归通过：单次初始化只触发 1 次 `codex exec`，并保留最终审计报告
- [x] 默认模式与 `--ultra` 的命令分支验证
- [x] `--model` 与 `--reasoning-effort` 参数透传验证
- [x] 静态 scaffold 已恢复为空白模板，不再复制当前仓库的 `docs/plan/current.md` 和 `docs/decisions.md` 运行状态
- [x] 新增 adopt / greenfield 分支验证
- [x] 独立 docs review 触发与结果校验验证
- [x] BacktrackKV 重跑验证通过
- [x] 交互式向导烟测通过：TTY 下可选择 `adopt + skip-fill`
- [x] `bash scripts/run_issue_tests.sh` 通过
- [x] 临时 git 仓库中的 `init.sh --skip-fill --non-interactive` 烟测通过（已生成 `issue_test/README.md` 与 `scripts/run_issue_tests.sh`）
- [x] Stage 1 / Stage 6 终止语义已同步到 workflow 文档与 README
- [ ] 模板冲突修复后 BacktrackKV docs review 二次验证通过

## 备注

- 本轮迁移后，模板不再依赖 repo 级 `check_quality.sh`；后续验证入口改为 `bash scripts/run_issue_tests.sh`。
- 本轮完成后需要同步检查 `scaffold/` 中的模板语义是否仍偏向 greenfield。
- `BacktrackKV` 用新脚本从头重跑已完成，并额外产出 `docs-review.md`；该报告识别出了若干 repo 真实问题，例如假阳性质量门、未初始化子模块与文档事实不符、以及决策维护规则冲突。
- 这轮只修模板导致的误导；BacktrackKV 自身仓库事实问题仍可能继续出现在 review 中。
- 完成后由 agent 归档到 `docs/plan/archive/`，然后清空本文件。
