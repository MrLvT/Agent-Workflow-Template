# Agent Workflow Template

基于 Harness Engineering 理念的 AI agent 开发模板框架。

---

## 核心理念

- 工程师的职责是**定义规则**，不是写代码。
- Agent 的职责是**执行、自我验证、自我修复**。
- Harness 的职责是**机械执行规则**，让 agent 无法忽略约束。

> 出现问题时，解决方案永远不是"再试一次"。而是问：缺少什么能力，怎么让它对 agent 可见且可执行？

---

## 文档结构

```
project/
├── AGENTS.md                  # 入口：文档索引 + 全局硬规则
├── issue_test/
│   └── README.md              # issue 级回归脚本约定
├── scripts/
│   ├── build_context.py       # 按当前 stage 组装需要读取的上下文文件
│   └── run_issue_tests.sh     # 执行 issue_test/*.sh 的累积回归入口
└── docs/
    ├── stage.lock             # 当前 Stage + 状态 + issue 元数据
    ├── workflow/
    │   ├── stage1.md          # Context Loading / Router
    │   ├── stage2.md          # Task Planning
    │   ├── stage3.md          # Implementation
    │   ├── stage4.md          # Delivery & Verification
    │   ├── stage5.md          # Reflection
    │   └── stage6.md          # Entropy Check
    ├── overview.md            # 项目是什么、不是什么
    ├── architecture.md        # 结构性约束（模块划分 + 依赖边界，由工具强制执行）
    ├── conventions.md         # 风格性约束（命名 + 代码风格 + git 规范，靠 agent 自觉）
    ├── decisions.md           # 时间线追加式设计决策日志（带 compaction 机制）
    ├── quality.md             # 什么叫做完 + 怎么验证做完了
    ├── security.md            # 敏感信息 + 安全边界
    ├── progress.md            # 项目快照（已完成、已知问题、技术债）
    ├── blockers.md            # agent 卡住时的记录（人类介入点）
    ├── wisdom.md              # 跨 issue 复用成功模式
    ├── antipatterns.md        # 跨 issue 失败模式
    └── plan/
        ├── backlog.md         # issue 队列
        ├── current.md         # 当前 issue 的执行步骤
        └── archive/           # 已完成 issue 的 plan 归档
```

---

## 文档设计原则

### 每个文档回答一个且仅一个问题

| 文档 | 回答的问题 |
|------|-----------|
| stage.lock + workflow/stage*.md | 我现在该做什么？下一步去哪？ |
| overview.md | 这个项目是什么？什么不做？ |
| architecture.md | 什么东西在哪里？什么能依赖什么？ |
| conventions.md | 代码长什么样？git 操作怎么做？ |
| decisions.md | 之前为什么这样决定的？ |
| quality.md | 怎么判断做完了？怎么验证？ |
| security.md | 什么不能碰？什么要小心？ |
| progress.md | 项目现在长什么样？ |
| blockers.md | agent 卡在哪里了？需要人类帮什么？ |
| plan/backlog.md | 还有哪些 issue 要做？ |
| plan/current.md | 当前 issue 怎么一步步执行？ |

### 解耦原则

- 文档之间不互相"补充"。每个文档自包含，读一个就够理解它负责的领域。
- 唯一的跨文档引用出现在 `docs/workflow/stage*.md`（状态机需要知道每个 Stage 该读哪个文档）和 AGENTS.md（入口索引）。
- 其他文档内部不得 reference 另一个文档的内容来完成自己的职责。

### architecture.md vs conventions.md 的分界线

分界标准：**这个项目是否实际用工具检查了这条规则？**

- 规则被 linter / CI 机械执行 → architecture.md
- 规则靠 agent 自觉遵守 → conventions.md

同一条规则（例如 commit message 格式）可能随项目演进从 conventions 迁移到 architecture（配了 commitlint 之后）。

---

## 文档变化频率

| 文档 | 频率 | 说明 |
|------|------|------|
| overview, architecture, conventions, security | 长期稳定 | 项目定了基本不动 |
| decisions | 只增不改 | 追加式日志，定期 compaction |
| quality | 中间地带 | 有新标准才改 |
| progress | 每个 PR 后更新 | 项目快照 |
| blockers | 事件驱动 | agent 卡住时写入，人类解决后清除 |
| plan/current | 每个 issue 期间实时更新 | 完成后归档 |
| plan/backlog | 取任务/完成任务时更新 | issue 队列 |

---

## Workflow 概览（6 Stage）

每个 Stage 都有三个组成部分：执行流程、Exit Checklist（不满足就不能离开）、Failure Path（卡住时的降级策略）。

运行模型：**单次 agent run 只完成一个 issue 闭环。**

- agent 从 `stage.lock.current` 开始
- 每个 Stage 结束后，都根据新的 `stage.lock` 继续进入下一个 Stage
- 当 Stage 6 以“路径 A”写回 `current: stage1`、`status: done`、`previous: stage6` 时，本次 run 成功结束
- 下一次启动才允许从 Stage 1 重新领取 backlog 中的下一个 issue

```
Stage 1: Context Loading     — 读项目状态，恢复上下文，检查 blockers
        ↓
Stage 2: Task Planning        — 取 issue，先写 issue_test/<issue_id>.sh，再写执行计划
        ↓
Stage 3: Implementation       — 跑历史回归 → 跑当前 issue test → 写代码 → 全量回归
        ↓
Stage 4: Delivery & Verification
                             — 最终全量回归 → 本地交付提交 → push/PR 或记录人工 handoff → 更新 progress → 归档 plan
        ↓
Stage 5: Reflection           — 沉淀经验为规则或决策
        ↓
Stage 6: Entropy Check        — 定期检查文档和代码是否同步 + decisions compaction
        ↓
Stage 1 (done)                — 单次 run 的成功终点，不继续领取下一个 issue
```

任何 Stage 的 Failure Path 触发后，agent 将问题写入 `docs/blockers.md` 并停止，等待人类介入。

若 Stage 4 只是受到网络、权限或 GitHub 可达性限制，模板允许记录“本地交付完成，等待人工推送/开 PR”的 handoff，而不是把整个 issue 回退为代码失败。

详细流程见 `docs/workflow/stage1.md` 到 `docs/workflow/stage6.md`。

---

## 可执行 Harness

模板提供一个上下文装载脚本和一套 issue 级回归约定。Agent 通过 `build_context.py` 机械加载上下文，通过 `issue_test/*.sh` + `run_issue_tests.sh` 获得确定性的 PASS/FAIL 结果，而非自我判断。

| 组件 | 用途 | 使用时机 |
|------|------|---------|
| `scripts/build_context.py` | 按当前 stage 输出必须加载的文档列表 | 每次启动时 |
| `issue_test/<issue_id>.sh` | 当前 issue 的独立回归脚本 | Stage 2 创建，Stage 3/4 执行 |
| `scripts/run_issue_tests.sh` | 执行 `issue_test/*.sh` 的累积回归套件 | Stage 3 和 Stage 4 |

工程师初始化项目时只需要安装 `PyYAML`。之后每开始一个新 issue，都由 agent 或工程师先创建 `issue_test/<issue_id>.sh`，再进入实现阶段。

---

## 职责边界

| 角色 | 职责 |
|------|------|
| **工程师** | 定义规则、写 docs、review PR、决定架构方向、解决 blockers、裁决是否允许修改历史 issue tests |
| **Agent** | 读 docs、为每个 issue 编写测试脚本、写代码、运行回归套件、自我验证、更新文档、开 PR、遇到阻塞时写 blockers 并停止 |
| **Harness** | `build_context.py` 机械装载上下文，`run_issue_tests.sh` 机械执行累积回归脚本，CI/静态检查可按项目需要追加 |

工程师只写 prompt，不写业务代码。Agent 自驱动整个循环。人介入的节点：PR review/merge + blockers 解决。

---

## Harness 的核心原则

**规则必须可执行，不能只写在文档里。**

- architecture.md 里定义 import boundary → 用 linter 强制执行
- quality.md 里定义质量标准 → 用 `issue_test/<issue_id>.sh` + `scripts/run_issue_tests.sh` 自动验证
- 每个 Stage 的 Exit Checklist → 包含累积回归脚本输出作为通过条件
- 若项目还有 lint/typecheck/原生测试，也可以继续追加，但不再作为模板初始化时必须生成的全局脚本

> 光写在文档里说"不许这样做"，agent 可能忽略。脚本返回 FAIL，agent 就必须修。

---

## 快速开始

```bash
# 1. 克隆模板
git clone <this-repo> my-project && cd my-project

# 2. 填写文档（工程师完成）
# 编辑 docs/overview.md      → 描述你的项目
# 编辑 docs/architecture.md  → 定义层级和 import boundary
# 编辑 docs/conventions.md   → 定义代码规范和 git 规范
# 编辑 docs/plan/backlog.md  → 列出第一批 issue

# 3. 阅读 issue_test 约定
# 查看 issue_test/README.md
# 查看 scripts/run_issue_tests.sh

# 4. 安装上下文装载依赖
python3 -m pip install pyyaml

# 5. 启动 agent
codex "读 AGENTS.md，然后开始工作。"
```

之后每做一个 issue，先创建 `issue_test/<issue_id>.sh`，实现完成后运行 `bash scripts/run_issue_tests.sh`。工程师主要负责 review PR、merge、以及解决 blockers。
