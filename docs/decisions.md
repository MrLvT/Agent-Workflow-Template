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

## D-001 init.sh 将初始化产物落到本地状态目录
- 日期：2026-03-27
- 状态：Accepted
- 背景：`init.sh` 需要串行调用多个 AI step 填充文档，但原实现失败时只会直接退出，既难定位具体失败点，也不方便保留日志和最终审计结果。
- 决策：在目标仓库写入本地状态目录，集中保存日志、docs review 结果和最终审计报告；失败后直接停止，由用户修复环境或代码事实后重跑整次初始化。
- 原因：初始化流程仍然需要可审计的日志和产物，但断点恢复会显著增加状态复杂度，也更容易引入配置漂移和错误恢复路径。
- 被拒绝方案：
  - 完全不落盘任何状态：失败后难以定位原因，也无法保留独立审计结果
  - 引入断点恢复：状态机更复杂，且容易产生错误恢复语义
- 影响：后续 `init.sh` 的修改需要维护日志输出、落盘校验和最终审计输出，但不再需要维护恢复兼容性。

## D-002 init.sh 按 CLI 类型选择调用协议
- 日期：2026-03-27
- 状态：Accepted
- 背景：`claude` 与 `codex` 的命令行参数语义不同，`claude -p` 表示 prompt，但 `codex -p` 表示 profile，直接复用同一套调用方式会导致 `codex` 将 prompt 误解析为 profile。
- 决策：在 `init.sh` 中按 CLI 类型分派调用协议；`claude` 继续使用 `-p`，`codex` 改为 `codex exec --full-auto -C <repo> -`，通过 stdin 传入 prompt。
- 原因：不同 CLI 的参数模型不兼容，适配层可以在不改变上层 step 流程的前提下兼容多种 agent CLI，并避免 shell 引号和长 prompt 参数误解析。
- 被拒绝方案：
  - 强制只支持 `claude`：无法满足主要使用 `codex` 的场景
  - 继续统一使用 `-p`：对 `codex` 会稳定失败，且错误信息不直观
- 影响：后续若支持新的 agent CLI，需要在适配层新增独立调用协议，而不是假定参数兼容。

## D-003 init.sh 从独立 scaffold 复制静态模板
- 日期：2026-03-27
- 状态：Accepted
- 背景：`init.sh` 原先直接复制当前仓库根目录下的 `AGENTS.md`、`docs/` 和 `scripts/`，导致测试仓库里的运行时状态文件也会被带进目标项目，例如进行中的 `docs/plan/current.md` 和本仓库自己的决策记录。
- 决策：新增独立的 `scaffold/` 目录作为初始化骨架，`init.sh` 只从该目录复制模板文件，不再把当前工作仓库的 live 文档和脚本视为模板源。
- 原因：初始化产物必须稳定、可预测，不能受模板仓库当前任务状态、实验性改动或脏工作区影响；静态 scaffold 能将“模板定义”和“模板仓库自身运行状态”分离。
- 被拒绝方案：
  - 继续从仓库根目录复制：运行时状态会泄漏到目标项目
  - 仅在复制前重置个别文件：容易漏掉其他会漂移的 live 文件，维护成本高
- 影响：后续模板内容更新必须同步修改 `scaffold/`，而不是假设仓库根目录文件就是初始化骨架。

## D-004 init.sh 提供单次 AI 调用模式
- 日期：2026-03-27
- 状态：Accepted
- 背景：`codex exec` 这类非交互调用通常是独立会话，多次分步调用会重复加载仓库上下文，并在每一步重新解释工作流文档，导致初始化过程变慢且更容易在中途停下来询问流程冲突。
- 决策：默认使用单次 AI 调用完成文档填充和检查脚本更新；逐文件多次调用保留为 `--ultra` 模式。最终“人工补充清单”改为本地规则生成，避免为审计再发起额外 AI 会话。
- 原因：单次调用更符合 `codex` 的会话模型，能够减少重复扫描与流程漂移，同时保留现有的骨架复制、结果校验和独立审计机制。
- 被拒绝方案：
  - 继续仅支持多次分步调用：对 `codex` 的重复上下文加载成本高，且更容易被仓库内 workflow 重新分流
  - 将所有逻辑都塞进一次调用且继续用 AI 生成审计：会把最终审计也绑到单次会话成败上，降低可恢复性
- 影响：`init.sh` 现在默认走单次模式；若需要逐文件多次调用，必须显式传入 `--ultra`。

## D-005 init.sh 显式暴露 codex 模型参数
- 日期：2026-03-27
- 状态：Accepted
- 背景：`init.sh` 主要服务 `codex` 用户，而 `codex` 的默认模型与推理强度会影响初始化速度、稳定性和成本；如果脚本完全依赖本机 `~/.codex/config.toml`，行为会随环境漂移。
- 决策：在 `init.sh` 中新增 `--model` 和 `--reasoning-effort` 参数，并为 `codex` 路径设置默认值 `gpt-5.4` / `xhigh`，通过 `codex exec --model ... -c model_reasoning_effort=...` 显式传递。
- 原因：将模型选择收敛到脚本参数可以让初始化行为更稳定、可复现，也便于针对不同仓库按需覆盖。
- 被拒绝方案：
  - 完全依赖用户本地 `codex` 配置：不同机器的默认值可能不同，结果不可预测
  - 只暴露 `--model` 不暴露推理强度：无法控制同一模型下的推理成本与稳定性
- 影响：`codex` 初始化默认会使用 `gpt-5.4` 和 `xhigh`；若需改动，用户可在命令行显式覆盖。

## D-006 init.sh 默认按存量仓库 adopt 模式初始化，并在生成后做独立 docs review
- 日期：2026-03-27
- 状态：Accepted
- 背景：多数目标仓库并不是从第一天起就由 agent workflow 主导开发；如果初始化脚本默认按 greenfield 假设写文档，容易把理想流程误写成历史事实。同时，仅靠生成阶段自身做自检，难以及时发现跨文档矛盾、假阳性质量门和 checkout 状态偏差。
- 决策：将 `init.sh` 的默认模式切换为存量仓库接入（adopt），保留 `--greenfield` 作为显式选项；初始化完成后再启动一次独立的只读 docs review session，输出 `docs-review.md`，用于审查文档与代码事实、文档之间的一致性以及残留模板问题。
- 原因：adopt 模式能优先沉淀仓库当前事实，减少模板和历史资产的摩擦；独立 docs review 由第二个 agent session 执行，更容易发现生成阶段自身忽略的跨文档矛盾与误导性表述。
- 被拒绝方案：
  - 继续默认按 greenfield 初始化：会系统性高估既有流程成熟度，误导后续 agent
  - 只做本地占位符扫描，不做独立 review：能发现模板残留，但抓不到 workflow/quality/submodule 这类跨文件逻辑问题
- 影响：`init.sh` 现在默认更偏向“描述现状”，并会额外产出一份 AI 复核报告；若用户明确要初始化全新 agent-native 项目，需要传 `--greenfield`。

## D-007 模板将 sanity check 作为最低功能正确性验证要求
- 日期：2026-03-27
- 状态：Accepted
- 背景：仅要求“跑 tests”不足以覆盖存量仓库接入场景。很多项目在接入 workflow 时还没有统一自动化测试框架，但开发完成后仍然需要一次最低限度的功能正确性验证。
- 决策：在 `AGENTS.md`、`docs/workflow/stage*.md` 和 `docs/quality.md` 中显式加入 sanity check 要求：每次完成功能后，至少对主路径执行一次可复现的功能验证；如果缺少自动化测试框架，必须记录手工验证命令、脚本或步骤与结果。
- 原因：这能把“自动化测试理想态”和“当前仓库至少要验证功能是否正确”的最低要求区分开，减少仓库因为测试体系缺失而跳过功能验证。
- 被拒绝方案：
  - 仅要求自动化测试：对尚未建立测试框架的存量仓库过于理想化，执行时容易被绕过
  - 仅写“人工确认功能正常”：缺乏可复现性，不利于后续 agent 或 reviewer 复核
- 影响：后续模板用户即使暂时没有自动化测试，也需要留下可复现的 sanity check 记录；质量文档和 Stage 退出条件会把它当作必查项。

## D-008 init.sh 默认使用交互式向导补全关键初始化参数
- 日期：2026-03-27
- 状态：Accepted
- 背景：随着 `init.sh` 支持 `adopt/greenfield`、single-call/ultra、docs review、模型参数等多个维度，单靠命令行 flags 记忆和传参的成本越来越高，手动初始化仓库时容易忘记关键选项。
- 决策：`init.sh` 在交互式终端中默认启动一个简短向导，补全初始化模式、是否自动填充、CLI、执行方式、docs review 和 Codex 推荐配置；现有 flags 继续保留，并新增 `--non-interactive` 用于脚本化场景。
- 原因：交互式向导更符合“初始化工具”的使用心智模型，能降低首次使用门槛，同时保留 flags 和非交互模式，避免破坏自动化和批处理能力。
- 被拒绝方案：
  - 继续完全依赖 flags：对手动运行者不友好，选项增多后容易出错
  - 完全移除 flags、只保留交互：会破坏脚本化能力
- 影响：直接运行 `bash init.sh` 时通常会先看到交互式选择；如需稳定脚本化行为，可显式传入 flags 或 `--non-interactive`。

## D-009 模板改用 issue_test 累积回归机制
- 日期：2026-03-29
- 状态：Accepted
- 背景：原有 `check_lint.sh`、`check_tests.sh`、`check_sanity.sh`、`check_quality.sh` 方案要求模板在初始化阶段就为每个目标仓库猜测一组全局命令。这对异构仓库很脆弱，也会把验证重心放在“仓库级通用命令”上，而不是当前 issue 的验收目标。
- 决策：移除模板内固定的 repo 级 `check_*` 脚本，改为每个 issue 必须提供一个 `issue_test/<issue_id>.sh`；由 `scripts/run_issue_tests.sh` 统一执行所有历史 issue tests。Stage 2 先创建当前 issue test，Stage 3 先跑历史回归、再实现、最后跑完整回归，Stage 4 交付前再次跑完整回归。
- 原因：把验证脚本绑定到单个 issue，可以让验收条件和回归资产一起沉淀；历史 issue tests 自动形成累积式回归套件，比初始化时生成的通用 placeholder 脚本更贴近 Harness Engineering 的目标。
- 被拒绝方案：
  - 继续维护 repo 级 `check_*` 脚本：初始化时必须猜测项目级命令，容易生成脆弱或误导性的验证门
  - 只在 `docs/plan/current.md` 里临时写命令，不落成脚本：缺乏长期回归资产，后续 issue 无法机械复用
- 影响：后续模板仓库和初始化出来的项目都以 `issue_test/` 作为长期回归资产；若项目还有 lint/typecheck/native tests，可在 `docs/quality.md` 中记录，但不再由模板统一生成固定脚本。

## D-010 单次 run 只完成一个 issue 闭环
- 日期：2026-03-29
- 状态：Accepted
- 背景：原有 Stage 文档默认依赖 `stage.lock` 在各阶段之间跳转，但没有明确定义 agent 在切到下一 Stage 后是否应该继续执行，也没有定义 `stage6 -> stage1` 后是否应立即领取下一个 issue。这会导致不同 agent session 可能把模板理解成“只做一个 Stage 就停”或“无限连续处理 backlog”。
- 决策：将运行模型固定为“单次 run 完成一个 issue 闭环”。agent 在一次启动后持续执行 Stage 1 → 2 → 3 → 4 → 5 → 6；若 Stage 6 路径 A 写回 `current: stage1`、`status: done`、`previous: stage6`，则本次 run 成功结束，不得继续领取新的 backlog 任务。
- 原因：这让一次 agent run 的工作边界稳定可预测，既避免只做半个流程就停，也避免在无人确认的情况下连续处理多个 issue。
- 被拒绝方案：
  - 每执行完一个 Stage 就停：需要外层调度器频繁重启，且状态切换碎片化
  - 回到 Stage 1 后继续自动领取下一个 issue：会让单次 run 失去边界，增加意外修改多个任务的风险
- 影响：Stage 1 现在承担“成功终止点”的语义，Stage 6 路径 A 写回 `stage1/done` 后表示当前 issue 已完整闭环；下一次 run 才会处理下一个 issue。

## D-011 统一 Codex 为无交互审批启动方式
- 日期：2026-04-03
- 状态：Accepted
- 背景：仅使用 `codex --full-auto` 时，Codex CLI 仍可能沿用本机默认审批策略，导致 `git commit`、`git push` 等命令在不同环境里仍弹出人工确认，降低 workflow 的可预测性。
- 决策：`init.sh` 在 `codex exec` 路径下显式传入 `--ask-for-approval never --sandbox workspace-write`；同时在模板和 scaffold 中新增 `scripts/start_agent.sh`，作为日常启动 Codex agent 的统一入口。
- 原因：把审批策略固定在仓库提供的调用入口里，比依赖用户本地 `~/.codex/config.toml` 更稳定，也能减少“同一模板在不同机器上行为不同”的问题。
- 被拒绝方案：
  - 继续只依赖 `--full-auto`：审批行为仍可能受用户本机默认配置影响
  - 要求每个用户手工修改全局 Codex 配置：设置分散，难以在团队内复制
- 影响：使用模板推荐入口时，Codex 将默认不再为常见执行命令请求人工审批；若团队需要更严格审批，可自行改用其他 Codex 启动参数。

## D-012 Codex 默认保留独立 docs review
- 日期：2026-04-03
- 状态：Accepted
- 背景：模板此前对 `codex` 做了额外特判：若用户未显式传 `--docs-review` / `--no-docs-review`，就自动关闭独立 docs review。这与 D-006 中“初始化完成后默认追加一次独立 docs review”的基线决策不一致，也让 `codex` 和 `claude` 的默认行为产生了不必要差异。
- 决策：移除 `codex` 路径下自动关闭 docs review 的逻辑，恢复为统一默认值：独立 docs review 默认开启，只有显式传 `--no-docs-review` 时才关闭。
- 原因：独立 docs review 是初始化质量门的一部分，不应因 CLI 类型不同而静默失效；保持统一默认值也更符合 README 和决策文档的整体叙事。
- 被拒绝方案：
  - 保留 `codex` 特判：会继续制造不同 CLI 之间的隐式行为差异
  - 仅更新 README、不改脚本：文档与真实行为会继续不一致
- 影响：今后使用 `codex` 初始化时，即使默认切到 `--ultra`，也仍会执行独立 docs review；如更在意速度，可显式传 `--no-docs-review`。

## D-013 默认连续运行多个 issue 闭环
- 日期：2026-04-05
- 状态：Accepted
- 背景：D-010 将运行边界固定为“单次 run 只完成一个 issue 闭环”，虽然边界清晰，但会让无人值守场景频繁停在 Stage 1，必须等待人工重新触发下一轮 run。
- 决策：将默认运行模型改为“无错误且无 blocker 时连续运行”。当 Stage 6 路径 A 写回 `current: stage1`、`status: done`、`previous: stage6` 后，Stage 1 不再把它视为成功终止点，而是继续执行 blockers/current plan 检查，并在满足条件时自动路由到下一个 Stage 2 或 Stage 3。
- 原因：这样可以减少人工重启次数，让 agent 在 backlog 连续可处理时持续推进，同时保留 `status == failed`、blockers 与质量门作为人工介入边界。
- 被拒绝方案：
  - 继续保持单 issue run：批量推进效率低，人工重启成本高
  - 完全去掉 Stage 1 的统一路由入口：会削弱 blocker 检查和状态一致性
- 影响：默认行为更适合连续自动执行；若团队仍希望“一次 run 只做一个 issue”，需要在自定义约束中重新加回该限制。

## D-014 提供无重置历史的 workflow 规则升级脚本
- 日期：2026-04-13
- 状态：Accepted
- 背景：已有仓库在初始化后会逐步积累 `.agent-workflow/docs/stage.lock`、`run_log.md`、`plan/archive/*`、`results/` 等本地状态与历史。随着模板规则演进，仅靠重新运行 `init.sh` 会有覆盖这些运行痕迹的风险，也不适合已在运行中的 sidecar 仓库。
- 决策：新增 `scripts/upgrade_workflow_rules.sh`，用于把模板拥有的规则文件就地同步到目标仓库的 `.agent-workflow/`。脚本默认只覆盖 `AGENTS.md`、`docs/workflow/stage*.md`、`scripts/*`、`issue_test/README.md`、`docs/plan/archive/README.md`，仅在缺失时补 `environment.md` 与 `run_log.md`，同时保留 `stage.lock`、`blockers.md`、`plan/current.md`、archive、progress、decisions 与 `results/`。
- 原因：这能让历史仓库安全升级到新的协议、脚本和 stage 规则，而不打断当前 issue 状态，也不要求重建 workflow 历史。
- 被拒绝方案：
  - 重新运行 `init.sh`：容易覆盖或重置已有运行状态，不适合存量 sidecar
  - 直接整目录覆盖 `.agent-workflow/`：会误伤状态文件、归档和实验结果
- 影响：后续升级已有 workflow 时，推荐使用升级脚本而不是重新初始化；项目事实文档如 `conventions.md`、`quality.md`、`environment.md` 仍需按目标仓库实际情况人工复核。

## D-015 连续运行时按 issue 重启 fresh session
- 日期：2026-04-14
- 状态：Accepted
- 背景：D-013 允许无错误时连续处理多个 issue，但如果所有 issue 都在同一个长会话里串行完成，Codex 上下文会持续累积，后续 issue 更容易受早期无关上下文干扰，甚至触发上下文窗口膨胀问题。
- 决策：保留“默认连续运行多个 issue”的目标，但把实现改成“每个 issue 一个全新的 Codex session”。`scripts/start_agent.sh` 负责监督循环：当一个 issue 闭环结束并回到 `current: stage1`、`status: done`、`previous: stage6` 后，先结束当前 session，再拉起一个新的交互式 Codex session 处理下一个 issue；默认只输出最少的壳层日志，尽量保持原生 Codex 界面。
- 原因：这样既保留无人值守连续推进 backlog 的能力，又能在 issue 边界自动清空会话上下文，降低上下文爆炸和跨 issue 污染的风险。
- 被拒绝方案：
  - 继续在同一个长 session 内串行处理所有 issue：上下文会无限堆积
  - 改回每个 issue 都必须人工重启：人工成本高，失去自动连续运行能力
- 影响：今后的连续运行语义变成“同一次启动脚本调用可以连续处理多个 issue，但 issue 之间自动换新 session”；如只想跑一轮，可使用 `start_agent.sh --once`。
