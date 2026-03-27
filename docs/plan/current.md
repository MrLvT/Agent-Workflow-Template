# Current Plan

## 任务元信息

- 任务名称：修复 init.sh 的容错、恢复、CLI 兼容、静态 scaffold 隔离、默认单次调用与模型参数配置
- 来源 issue：用户直接提出的 init.sh 缺陷修复
- 开始日期：2026-03-27
- 状态：In Progress

## 执行步骤

- [x] 审查 init.sh 当前流程，确认与工作流文档和现有脚本的约束是否冲突
- [x] 重构 init.sh 的初始化与自动填充流程，补齐 step 状态记录、断点恢复、目录切换、前置检查和最终验证
- [x] 将初始化骨架与当前测试仓库解耦，改为从独立 scaffold 目录复制静态模板
- [x] 为 `codex` 增加 `--single-call` 模式，避免多次独立调用重复加载仓库上下文
- [x] 将默认执行模式切换为单次调用，并把逐文件多次调用迁移为 `--ultra`
- [x] 为 `codex` 增加 `--model` 与 `--reasoning-effort` 参数，并将默认值设为 `gpt-5.4` / `xhigh`
- [x] 运行 lint、tests、quality 检查并根据结果修正脚本与文档记录

## 验证记录

- [x] `bash -n init.sh` 通过
- [x] `init.sh --skip-fill` 与 `init.sh --skip-fill --resume` 本地烟测通过
- [x] `codex` stub 回归通过：确认使用 `codex exec` 而非错误的 `-p`，且非 Git 仓库会追加 `--skip-git-repo-check`
- [x] `--single-call` 的 `codex` stub 回归通过：单次初始化只触发 1 次 `codex exec`，并保留最终审计报告
- [x] 默认模式与 `--ultra` 的命令分支验证
- [x] `--model` 与 `--reasoning-effort` 参数透传验证
- [x] 静态 scaffold 已恢复为空白模板，不再复制当前仓库的 `docs/plan/current.md` 和 `docs/decisions.md` 运行状态
- [ ] `./scripts/check_quality.sh` 通过

## 备注

- `./scripts/check_quality.sh` 当前失败，原因是仓库内的 `scripts/check_lint.sh` 与 `scripts/check_tests.sh` 仍保留模板占位符，并非本次 `init.sh` 改动引入。
- 完成后由 agent 归档到 `docs/plan/archive/`，然后清空本文件。
