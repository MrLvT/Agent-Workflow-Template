# Archive

已完成 issue 的 plan 存档。纯历史记录。

`run_log.md` 负责记录整次 run 的目标、执行与结果；本目录只保留单个 issue 的归档与反思。

## 命名规范

- `001-feature-name.md`
- `002-fix-xxx.md`

## 归档流程

1. 复制 `docs/plan/current.md` 内容到新归档文件。
2. 在归档文件中补充以下内容：
   - 本地 commit hash
   - 当前分支名（若存在）
   - 验证结论
   - 若需要人类继续推进：补充人工下一步
   - 若当前 issue 运行过实验、评测或 smoke test：补充结果目录 `results/issue<issue_id>/` 与 `SUMMARY.md` 路径
   - 最终结论
   - 对应测试脚本路径（`issue_test/<issue_id>.sh`）
3. 清空并重置 `docs/plan/current.md`。
4. 不要移动或删除 `issue_test/<issue_id>.sh`；历史 issue test 必须继续保留用于后续回归。
