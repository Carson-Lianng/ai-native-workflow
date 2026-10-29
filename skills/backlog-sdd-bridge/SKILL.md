---
name: backlog-sdd-bridge
description: 在已使用 Backlog.md 的项目里，把 spec-driven development 的六个阶段与 backlog 命令串成一条可执行链路。当需要把需求落成 spec、拆解为任务、流转任务状态、标记验收断言、做独立审查或验收时使用。触发场景：在本项目里写 spec、拆票、更新任务状态、勾选验收断言、评审、发布验收、查看看板。
---

# Backlog × SDD 桥接技能

把「纪律层管怎么把事做对」与「Backlog.md 管做什么、做到哪、凭什么算完成」串成一条可执行链路。

## 职责

保证三处事实源一致、状态机可恢复、门禁可信：

- 事实源：`CONTEXT.md`（项目事实）> `backlog decision`（已做决定）> 对话。
- 状态机：只用 `backlog` CLI 流转状态，绝不手改 `backlog/` 任务文件。
- 门禁：DoD（`definition_of_done`）+ AC（`--ac`）+ 反证。

## 阶段映射

### 1. 澄清需求

- 先用 `interview-me` 技能：一次只问一个问题，逐轮追问到需求清晰。
- 追问覆盖：用户是谁、边界在哪、哪些明确不做、成功怎么判断、现有约束。
- 产出 spec 存 `docs/spec-<slug>.md`。
- 每个决定落地：`backlog decision create "<决定>" -s accepted`。
- 术语 / 约束 / 被否方案写回 `CONTEXT.md`。

### 2. 拆解

```bash
backlog milestone add "M1 <目标>"

backlog task create "<标题>" \
  -d "Touches: <允许修改的路径>" \
  --ac "<可证伪的验收断言>" \
  --ac "<…>" \
  --dep <前置任务ID> \
  --plan "1. … 2. …" \
  -l m1,needs-review --priority high
```

达标判据：**一个没参与讨论的执行 agent，拿到任务说明就能开始，并有办法证明自己做对了。**

并发准入：路径不相交 + 依赖满足 + 无共享资源冲突（数据库 / 测试账号 / 端口），否则串行。

### 3. 实现

```bash
backlog task edit <id> -s "In Progress" -a @me
```

遵守 TDD：先写失败测试 → 确认失败 → 最小实现 → 重构 → 提交。
**不重新定义需求，不因实现困难偷偷改验收标准。**

### 4. 验证

- 跑测试，并对每个关键检查做反证（正确输入通过 → 构造缺陷应失败 → 恢复通过）。
- 逐条标记（序号从 1 开始）：`backlog task edit <id> --check-ac 1 --check-ac 2`。

### 5. 审查

- 触发独立 persona（`code-reviewer` / `security-auditor` / `test-engineer`，装了对应技能才有），交叉审。
- **执行者不自批。**
- 通过：`backlog task edit <id> --add-label reviewed`；不过：`-s "In Progress"` 打回并写清问题。

> 追加标签一律用 `--add-label`；`-l` 会替换全部标签，冲掉里程碑与模块标签。

### 6. 验收与发布

- 真实界面 / CLI / API 走一遍，每条断言留证据（命令结果 / 截图 / 状态）。
- 复杂项目先做整体 Review：跨票影响、接口一致性、数据与状态流转、权限边界、性能、是否符合 `CONTEXT.md`。
- 全部 DoD 满足 + AC 全勾：`backlog task edit <id> -s "Done"`；周期清理 `backlog task archive <id>`。

## 硬规则

1. 绝不手改 `backlog/` 任务文件，一律 CLI / MCP / Web。
2. 事实源冲突时 `CONTEXT.md` 优先。
3. 关键检查必做反证，只看绿色退出码 / 全勾不可信。
4. 缺凭据 / 需人决策 → `-s "Blocked"`（需先声明该状态）或 `--add-label blocked`，并写清原因，不无限重试。
5. 多 persona 交叉审降低盲区，但最终验收由人拍板。
