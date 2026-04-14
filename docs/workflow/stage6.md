# Stage 6 — Entropy Check

> 回答：文档和代码还同步吗？

## 执行步骤

### Step 1：对比文档与代码

逐一检查 `docs/` 下的文档与代码实现，找出所有偏差：

- 文档描述的行为与代码实际行为不符
- 文档中的目录结构、模块划分与代码不符
- `docs/progress.md` 的已完成功能与代码不符
- `docs/environment.md` 中的运行环境定义与实际执行方式不符

### Step 2：处理偏差

**路径 A（只改文档或仅收口状态）：** 偏差是文档落后于代码，或只需补最终记录 → 更新文档以匹配代码

**路径 B（需改代码）：** 代码与文档记录的意图矛盾 → 修代码并补测试，同时在 stage.lock 标记：

```yaml
meta:
  code_changed: true
```

### Step 3：decisions.md compaction（按需执行）

检查 `docs/decisions.md`：

- Superseded 条目超过总条目的 30% → 执行 compaction
- 将所有 Accepted 条目提炼为一句话摘要，更新到"当前有效决策摘要"区域
- 历史记录区域保持不变（只追加，不修改）

### Step 4：更新 stage.lock

**路径 A（只改文档或仅收口状态）：**

```yaml
current: stage1
status: done
previous: stage6
meta:
  issue_id: null
  code_changed: null
```

- 写回后由 Stage 1 判断是继续领取 backlog，还是以本次结果结束当前 run

**路径 B（改了代码）：**

```yaml
current: stage3
status: in_progress
previous: stage6
meta:
  code_changed: null
  # issue_id 保留，走完整 S3 → S4 → S5 闭环
```

- 若团队跟踪 workflow 状态文件，可按团队约定单独提交；默认只更新本地状态即可

### Step 5：更新 run_log

在 `docs/run_log.md` 中追加当前 issue 的最终交付结果，至少包含：

- 最终交付状态：`DONE` / `LOCAL_HANDOFF` / `RETURN_TO_STAGE3`
- 可验证结果：commit hash、测试结论或 handoff 摘要
- 若本次 run 在这里结束，补齐结束时间与最终状态；若还要继续领取 backlog，则保持当前 run 记录为 `in_progress`

## Exit Checklist

- [ ] 文档与代码已对齐，无已知偏差
- [ ] `docs/environment.md` 与实际执行环境一致；新发现已补写
- [ ] `docs/decisions.md` 已处理（compaction 或确认不需要）
- [ ] `docs/run_log.md` 已补充本 issue 的最终交付结果
- [ ] `stage.lock` 已按路径 A 或路径 B 正确更新
- [ ] 若走路径 A：已回到 `stage1/done`，并将其视为本次 run 的成功终点
- [ ] `stage.lock` 已按路径更新；若团队跟踪 workflow 状态文件，再按团队约定提交
- [ ] 若走路径 A：归档中的本地交付摘要仍然准确，必要时已补充人工下一步
- [ ] 若走路径 B：本次 run 停留在本地收口，准备回到 Stage 3 继续闭环

## Failure Path

- 发现文档和代码的矛盾无法判断谁对 → 写入 `docs/blockers.md`，更新 stage.lock（status: failed），停止，通知人类
