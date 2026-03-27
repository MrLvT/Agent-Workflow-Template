# Decisions

> 本文档回答：之前为什么这样决定的？
>
> 按时间线追加，不按领域分类。历史条目不可修改。

## 当前有效决策摘要

> 此区域由 Stage 6（Entropy Check）维护。当 Superseded 条目过多时，agent 将所有状态为 Accepted 的决策提炼为一句话摘要放在此处。Agent 日常只需读此摘要即可。

（项目初始化后由 Entropy Check 自动维护）

## 维护规则（强制）

1. **只追加，不修改**历史条目内容。
2. 若决策失效，新增一条"替代决策"，并引用旧编号，旧条目状态改为 `Superseded by D-0XX`。
3. 每条必须包含：背景、决策、原因、被拒绝方案。
4. **Compaction 规则**：当 Superseded 条目超过总条目的 30% 时，在 Stage 6 执行 compaction——将所有 Accepted 条目提炼为一句话摘要，更新到"当前有效决策摘要"区域。历史记录区域保持不变。

## 记录模板

```markdown
## D-00X 标题
- 日期：YYYY-MM-DD
- 状态：Proposed | Accepted | Superseded by D-0XX
- 背景：
- 决策：
- 原因：
- 被拒绝方案：
  - 方案 A：拒绝原因
  - 方案 B：拒绝原因
- 影响：
```

## 决策记录

## D-001 init.sh 使用可恢复的分步初始化
- 日期：2026-03-27
- 状态：Accepted
- 背景：`init.sh` 需要串行调用多个 AI step 填充文档，但原实现只要任一步失败就会直接退出，既不知道断点，也无法安全恢复，还可能在重跑时覆盖已生成内容。
- 决策：将 `init.sh` 重构为显式的 step 状态机，在目标仓库写入本地状态目录，按步骤记录完成状态、日志和最终审计结果，并通过 `--resume` 从失败点继续执行。
- 原因：文档填充步骤存在前后依赖，失败后直接从头重跑会破坏已产出的上下文；显式状态记录可以提供可审计性、错误定位和最小化重跑范围。
- 被拒绝方案：
  - 保留单次串行执行：失败后只能全量重跑，覆盖风险高
  - 只依赖 shell 的 `set -e` 报错：可以尽快停止，但不能提供断点恢复和产物校验
- 影响：后续 `init.sh` 的修改需要维护 step 状态兼容性、落盘校验和最终审计输出。

## D-002 init.sh 按 CLI 类型选择调用协议
- 日期：2026-03-27
- 状态：Accepted
- 背景：`claude` 与 `codex` 的命令行参数语义不同，`claude -p` 表示 prompt，但 `codex -p` 表示 profile，直接复用同一套调用方式会导致 `codex` 将 prompt 误解析为 profile。
- 决策：在 `init.sh` 中按 CLI 类型分派调用协议；`claude` 继续使用 `-p`，`codex` 改为 `codex exec --full-auto -C <repo> -`，通过 stdin 传入 prompt，并在非 Git 目录追加 `--skip-git-repo-check`。
- 原因：不同 CLI 的参数模型不兼容，适配层可以在不改变上层 step 流程的前提下兼容多种 agent CLI，并避免 shell 引号和长 prompt 参数误解析。
- 被拒绝方案：
  - 强制只支持 `claude`：无法满足主要使用 `codex` 的场景
  - 继续统一使用 `-p`：对 `codex` 会稳定失败，且错误信息不直观
- 影响：后续若支持新的 agent CLI，需要在适配层新增独立调用协议，而不是假定参数兼容。
