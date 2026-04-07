# Issue Tests

每个 issue 都必须对应一个独立的回归脚本，放在 `.agent-workflow/issue_test/` 目录下。

## 命名规范

- 文件名：`.agent-workflow/issue_test/<issue_id>.sh`
- `issue_id` 与 `.agent-workflow/docs/plan/current.md`、`.agent-workflow/docs/plan/archive/<issue_id>.md` 保持一致

## 合约

1. 每个 issue 必须新增或明确绑定一个测试脚本，覆盖该 issue 的目标行为或交付结果。
2. 测试脚本必须可从仓库根目录直接执行，并以退出码表达结果：exit 0 表示 PASS，非 0 表示 FAIL。
3. 测试脚本失败时必须输出足够的诊断信息，至少包含“期望什么、实际发生了什么、失败时执行了哪个命令或检查”，不得只返回非零退出码而没有上下文。
4. 测试脚本必须 deterministic，不依赖人工交互；若依赖外部服务或特殊环境，必须在脚本内写清前置条件并尽量提供本地替代。
5. 测试脚本可以调用项目已有测试命令，但不能只做“命令存在”检查，必须对当前 issue 的目标行为给出可复现断言。
6. 历史 `.agent-workflow/issue_test/*.sh` 默认长期保留，后续 issue 必须全部通过；不得通过删除、跳过或弱化旧脚本来掩盖回归。
7. 若必须修改历史 issue test，必须在 `.agent-workflow/docs/plan/current.md` 记录原因；若修改会改变长期验证语义，需同步追加到 `.agent-workflow/docs/decisions.md`。

## 常用命令

```bash
# 运行全部 issue 回归脚本
bash .agent-workflow/scripts/run_issue_tests.sh

# 实现当前 issue 前，先跑历史回归基线
bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh
```

## 最小模板

```bash
#!/usr/bin/env bash
set -euo pipefail

# 验证 <issue_id> 的目标行为
# 失败时打印期望值、实际结果和相关命令，再退出非零
```
