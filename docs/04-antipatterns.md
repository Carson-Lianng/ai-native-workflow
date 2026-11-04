# 04 · 反模式与落地 Checklist

## 七条反模式

1. **超大上下文文件**
   别把 20+ 个 `SKILL.md` 全塞进 `AGENTS.md`。用技能的渐进披露：description 被发现 → 命中才加载 → 正文才执行。

2. **约束过重变噪音**
   模型变强后，旧的"请你务必""千万不要"会变成噪音。定期删掉无效提示词，只保留承担边界与证据的约束。

3. **把判断外包给模型**
   多个 persona 交叉审能降低盲区，但**最终验收由人拍板**。模型说不清"够不够好"，只有使用者知道。

4. **绿色退出码幻觉**
   全勾 ≠ 正确，CI 绿 ≠ 没坏。关键检查必做反证（见 `03-gates.md` §六）。

5. **执行者自批**
   写代码的 agent 审自己的代码，等于没有审查。审查必须是独立 persona 或人。

6. **手改任务文件**
   直接编辑 `backlog/tasks/*.md` 会破坏字段元数据与依赖链。一律走 `backlog` CLI / MCP / Web。

7. **一套约定两处重复**
   `AGENTS.md` 放"怎么操作"，`CONTEXT.md` 放"项目事实"，`backlog decision` 放"已做的决定"。同一信息写两处，必然漂移。

补充两条常见的效率反模式：

8. **票拆太大**：一张票跨三个模块、改十几处文件。判据是"一个没参与讨论的执行 agent 能否拿到说明就开始"。
9. **默认并行**：路径相交或共享数据库 / 测试账号 / 端口时并行，冲突成本高于串行等待。

---

## 落地 Checklist

新项目按顺序勾完即可上手：

- [ ] `npm i -g backlog.md`，`backlog --version` 可用
- [ ] 两个技能目录已复制到 agent 的技能目录（见 README 第 1 步）
- [ ] 在项目里说「初始化工作流」，或手动 `backlog init "项目名" --defaults --agent-instructions none`
- [ ] `AGENTS.md` 已就位（`skills/workflow-init/templates/AGENTS.md` 复制或合并）
- [ ] `CONTEXT.md` 已就位并填了目标 / 术语 / 约束
- [ ] `backlog/config.yml` 已按模式选好 `definition_of_done`（3 项或 5 项）
- [ ] 需要 `Blocked` 状态时，已把它写进 `statuses`
- [ ] 选定模式：轻量或完整，按 `02-modes.md` 走一遍
- [ ] 建立版本基线：`CONTEXT.md` + `backlog/` + `docs/` + agent 配置全部纳入 Git
- [ ] 第一条任务走完：建票 → In Progress → `--check-ac` → 写 `Evidence:` note → `--add-label reviewed` → Done

## 日常节奏

| 时机 | 动作 |
|---|---|
| 每次功能改动前 | 先更新 `CONTEXT.md`，再动代码 |
| 每个决定拍板后 | `backlog decision create "<决定>" -s accepted` |
| 每天开工 | `backlog board` 看现场，`backlog task list --json` 给脚本 |
| 每周 | `backlog task archive` 清理已完成；检查 `Blocked` 是否真的在等外部 |
| 换模型前 | 用同一批任务跑对比，只替换单个位置 |
