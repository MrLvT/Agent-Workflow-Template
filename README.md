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
├── scripts/
│   ├── check_lint.sh          # lint 检查（输出 PASS/FAIL）
│   ├── check_tests.sh         # 测试检查（输出 PASS/FAIL）
│   └── check_quality.sh       # 组合质量门禁
└── docs/
    ├── workflow.md            # 6 Stage 状态机：何时做什么 + Exit Checklist + Failure Path
    ├── overview.md            # 项目是什么、不是什么
    ├── architecture.md        # 结构性约束（模块划分 + 依赖边界，由工具强制执行）
    ├── conventions.md         # 风格性约束（命名 + 代码风格 + git 规范，靠 agent 自觉）
    ├── decisions.md           # 时间线追加式设计决策日志（带 compaction 机制）
    ├── quality.md             # 什么叫做完 + 怎么验证做完了
    ├── security.md            # 敏感信息 + 安全边界
    ├── progress.md            # 项目快照（已完成、已知问题、技术债）
    ├── blockers.md            # agent 卡住时的记录（人类介入点）
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
| workflow.md | 我现在该做什么？下一步去哪？ |
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
- 唯一的跨文档引用出现在 workflow.md（状态机需要知道每个 Stage 该读哪个文档）和 AGENTS.md（入口索引）。
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

```
Stage 1: Context Loading     — 读项目状态，恢复上下文，检查 blockers
        ↓
Stage 2: Task Planning        — 取 issue，分析需求，拆步骤，写执行计划
        ↓
Stage 3: Implementation       — 写代码 → lint → test → 循环直到通过
        ↓
Stage 4: PR & Verification    — quality gate → git commit/push → 更新 progress → 归档 plan → 开 PR
        ↓
Stage 5: Reflection           — 沉淀经验为规则或决策
        ↓
Stage 6: Entropy Check        — 定期检查文档和代码是否同步 + decisions compaction
```

任何 Stage 的 Failure Path 触发后，agent 将问题写入 `docs/blockers.md` 并停止，等待人类介入。

详细流程见 [docs/workflow.md](docs/workflow.md)。

---

## 可执行检查（scripts/）

模板提供三个检查脚本，用于 Workflow Stage 3 和 Stage 4 的 Exit Checklist。Agent 通过运行脚本获得确定性的 PASS/FAIL 结果，而非自我判断。

| 脚本 | 用途 | 使用时机 |
|------|------|---------|
| `check_lint.sh` | 运行 lint 检查 | Stage 3 Exit |
| `check_tests.sh` | 运行测试 | Stage 3 Exit |
| `check_quality.sh` | 组合质量门禁（lint + test + 文档更新检查） | Stage 4 Entry |

工程师初始化项目时需要将脚本中的 `<lint-command>` 和 `<test-command>` 替换为实际命令。

---

## 职责边界

| 角色 | 职责 |
|------|------|
| **工程师** | 定义规则、写 docs、配置 scripts/、review PR、决定架构方向、解决 blockers |
| **Agent** | 读 docs、写代码、运行 scripts、自我验证、修复报错、更新文档、开 PR、遇到阻塞时写 blockers 并停止 |
| **Harness** | linter 机械执行架构规则、CI 自动验证、scripts/ 提供确定性检查结果 |

工程师只写 prompt，不写业务代码。Agent 自驱动整个循环。人介入的节点：PR review/merge + blockers 解决。

---

## Harness 的核心原则

**规则必须可执行，不能只写在文档里。**

- architecture.md 里定义 import boundary → 用 linter 强制执行
- quality.md 里定义质量标准 → 用 `scripts/check_quality.sh` 自动验证
- 每个 Stage 的 Exit Checklist → 包含脚本输出作为通过条件
- linter 的报错信息要写得清晰，因为 agent 会读报错来决定怎么修

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

# 3. 配置检查脚本
# 编辑 scripts/check_lint.sh  → 替换 <lint-command>
# 编辑 scripts/check_tests.sh → 替换 <test-command>

# 4. 启动 agent
codex "读 AGENTS.md，然后开始工作。"
```

之后你只需要 review PR、merge、以及解决 blockers。
